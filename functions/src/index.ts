import {onDocumentWritten} from "firebase-functions/v2/firestore";
import {onSchedule} from "firebase-functions/v2/scheduler";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import {onCall, HttpsError} from "firebase-functions/v2/https";
import axios from "axios";
import {SecretManagerServiceClient} from "@google-cloud/secret-manager";

admin.initializeApp();
const db = admin.firestore();

interface Prize {
    position: number;
    description: string;
}

/**
 * Función 1: Actualizar contador de boletos
 */
export const onTicketWrite = onDocumentWritten(
  "raffles/{raffleId}/tickets/{ticketId}",
  (event) => {
    const raffleId = event.params.raffleId;
    const raffleRef = db.collection("raffles").doc(raffleId);

    const change = event.data;
    if (!change) {
      logger.warn("Event had no data change. Exiting function.");
      return;
    }

    const dataBefore = change.before.data();
    const dataAfter = change.after.data();

    logger.debug("Ticket change detected", {
      raffleId,
      before: dataBefore,
      after: dataAfter,
    });

    const wasPaidBefore = dataBefore?.isPaid === true;
    const isPaidAfter = dataAfter?.isPaid === true;

    let incrementValue = 0;
    const ticketsBefore = dataBefore?.ticketNumbers?.length ?? 0;
    const ticketsAfter = dataAfter?.ticketNumbers?.length ?? 0;

    if (!wasPaidBefore && isPaidAfter) {
      incrementValue = ticketsAfter;
    } else if (wasPaidBefore && !isPaidAfter) {
      incrementValue = -ticketsBefore;
    }

    logger.debug("Increment calculation", {
      wasPaidBefore,
      isPaidAfter,
      ticketsBefore,
      ticketsAfter,
      incrementValue,
    });

    if (incrementValue === 0) {
      logger.debug("No change in sold tickets count. Exiting.");
      return;
    }

    return raffleRef.update({
      soldTicketsCount: admin.firestore.FieldValue.increment(incrementValue),
    }).catch((err) => {
      logger.error("Failed to update raffle document:", err);
    });
  },
);

/**
 * Función 2: Realizar Sorteos Programados
 */
export const performDraws = onSchedule("every 5 minutes", async (_event) => {
  const now = admin.firestore.Timestamp.now();
  logger.log("Running scheduled draw function at:", now.toDate());

  const query = db.collection("raffles")
    .where("drawDate", "<=", now)
    .where("status", "==", "active");

  const dueRaffles = await query.get();

  if (dueRaffles.empty) {
    logger.log("No raffles are due for a draw.");
    return;
  }

  const drawPromises = dueRaffles.docs.map(async (raffleDoc) => {
    const raffleId = raffleDoc.id;
    const raffleData = raffleDoc.data();
    logger.log(`Processing draw for raffle: ${raffleId}`);
    logger.debug("Raffle data", raffleData);

    try {
      await raffleDoc.ref.update({status: "processing"});

      const ticketsSnapshot = await db.collection("raffles")
        .doc(raffleId).collection("tickets")
        .where("isPaid", "==", true).get();

      if (ticketsSnapshot.empty) {
        logger.log(`Raffle ${raffleId} has no paid tickets. Finishing it.`);
        return raffleDoc.ref.update({status: "finished"});
      }

      const numberPool: number[] = [];
      const numberOwners: {[key: number]: {
                    userId: string,
                    customData: {[key: string]: string},
                    adminNotes: string | null,
                }} = {};

      ticketsSnapshot.forEach((ticketDoc) => {
        const ticketData = ticketDoc.data();
        const numbers = ticketData.ticketNumbers || [];
        for (const num of numbers) {
          numberPool.push(num);
          numberOwners[num] = {
            userId: ticketData.userId,
            customData: ticketData.customData || {},
            adminNotes: ticketData.adminNotes || null,
          };
        }
      });

      logger.debug("Number pool generated", {count: numberPool.length});

      const winners = [];
      const prizes: Prize[] = [...raffleData.prizes]
        .sort((a: Prize, b: Prize) => a.position - b.position);

      for (const prize of prizes) {
        if (numberPool.length === 0) break;
        const randomIndex = Math.floor(Math.random() * numberPool.length);
        const winningNumber = numberPool.splice(randomIndex, 1)[0];
        const winnerTicketInfo = numberOwners[winningNumber];

        logger.debug("Prize assignment", {
          prize,
          winningNumber,
          winnerTicketInfo,
        });

        let winnerName = "Usuario Anónimo";
        let winnerEmail = "No disponible";
        let winnerPhoneNumber = "No disponible";

        try {
          const userDoc = await db.collection("users")
            .doc(winnerTicketInfo.userId).get();
          if (userDoc.exists) {
            const userData = userDoc.data();
            winnerName = userData?.name || "Usuario Anónimo";
            winnerEmail = userData?.email ||
                            userData?.mail || "No disponible";
            winnerPhoneNumber = userData?.phoneNumber ?? "No disponible";
          }
        } catch (userError) {
          logger.error(
            `Could not fetch user profile for ${winnerTicketInfo.userId}`,
          );
        }

        winners.push({
          prizePosition: prize.position,
          prizeDescription: prize.description,
          winningNumber,
          winnerUserId: winnerTicketInfo.userId,
          winnerName,
          winnerEmail,
          winnerPhoneNumber,
          adminNotes: winnerTicketInfo.adminNotes,
          customData: winnerTicketInfo.customData,
        });
      }

      logger.debug("Winners generated", winners);

      return raffleDoc.ref.update({
        status: "finished",
        winners,
      });
    } catch (error) {
      logger.error(`Failed to process draw for raffle ${raffleId}:`, error);
      return raffleDoc.ref.update({status: "error_drawing"});
    }
  });

  await Promise.all(drawPromises);
  logger.log(`Finished processing ${dueRaffles.size} draws.`);
});

/**
 * Función 3: Crear preferencia de pago en MercadoPago
 */
export const createPaymentPreference = onCall(async (request) => {
  // YA NO USAMOS {secrets: [...]}
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Debes iniciar sesión.");
  }

  const {raffleId, raffleTitle, quantity, unitPrice} = request.data;
  if (!raffleId || !raffleTitle || !quantity || !unitPrice) {
    throw new HttpsError("invalid-argument", "Faltan datos para el pago.");
  }

  // --- NUEVA LÓGICA PARA LEER EL SECRETO EN TIEMPO DE EJECUCIÓN ---
  let accessToken = "";
  try {
    const client = new SecretManagerServiceClient();
    const name = "projects/736305070285/secrets/MERCADOPAGO_ACCESS_TOKEN/versions/latest";

    const [version] = await client.accessSecretVersion({name: name});
    accessToken = version.payload?.data?.toString() ?? "";
    if (!accessToken) {
      throw new Error("El valor del secreto está vacío.");
    }
  } catch (error) {
    logger.error("Error al acceder al secreto de MercadoPago:", error);
    throw new HttpsError("internal", "No se pudo configurar el pago.");
  }

  const preference = {
    items: [
      {
        id: raffleId,
        title: `Boleto(s) para: ${raffleTitle}`,
        description: `Compra de ${quantity} boleto(s).`,
        quantity,
        currency_id: "UYU",
        unit_price: unitPrice,
      },
    ],
    back_urls: {
      success: "https://colaboraplus.com/success",
      failure: "https://colaboraplus.com/failure",
      pending: "https://colaboraplus.com/pending",
    },
    auto_return: "approved",
  };

  logger.debug("Preference payload", preference);

  try {
    const response = await axios.post(
      "https://api.mercadopago.com/checkout/preferences",
      preference,
      {
        headers: {
          "Content-Type": "application/json",
          "Authorization": `Bearer ${accessToken}`,
        },
      },
    );

    const preferenceId = response.data.id;
    logger.info("Preferencia creada:", preferenceId);
    return {preferenceId};
  } catch (error: any) {
    logger.error(
      "Error al crear la preferencia de pago:",
      error.response?.data || error.message,
    );
    throw new HttpsError("internal", "No se pudo crear el link de pago.");
  }
},
);
