import {onDocumentWritten} from "firebase-functions/v2/firestore";
import {onSchedule} from "firebase-functions/v2/scheduler";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

import {onCall, HttpsError} from "firebase-functions/v2/https";
import axios from "axios";

admin.initializeApp();
const db = admin.firestore();

// --- Definición de Tipo para los Premios (para corregir el error de 'any') ---
interface Prize {
    position: number;
    description: string;
}

// --- Función 1: Actualizar contador de boletos (SIN CAMBIOS) ---
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

    if (incrementValue === 0) {
      return;
    }

    return raffleRef.update({
      soldTicketsCount: admin.firestore.FieldValue.increment(incrementValue),
    }).catch((err) => {
      logger.error("Failed to update raffle document:", err);
    });
  },
);


// --- Función 2: Realizar Sorteos Programados (CORREGIDA) ---
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
                    // Guardamos los datos extra del boleto
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

      const winners = [];
      const prizes: Prize[] = [...raffleData.prizes]
        .sort((a: Prize, b: Prize) => a.position - b.position);

      for (const prize of prizes) {
        if (numberPool.length === 0) break;
        const randomIndex = Math.floor(Math.random() * numberPool.length);
        const winningNumber = numberPool.splice(randomIndex, 1)[0];
        const winnerTicketInfo = numberOwners[winningNumber];

        // --- LÓGICA MEJORADA AQUÍ ---
        let winnerName = "Usuario Anónimo";
        let winnerEmail = "No disponible";
        let winnerPhoneNumber = "No disponible";

        try {
          const userDoc =
                        await db.collection("users").doc(winnerTicketInfo.userId).get();
          if (userDoc.exists) {
            const userData = userDoc.data();
            // Priorizamos el nombre del perfil, si no existe, usamos el email
            winnerName = userData?.name || userData?.email || "Usuario Anónimo";
            winnerEmail = userData?.email ?? "No disponible";
            winnerEmail = userData?.email || userData?.mail || "No disponible";
            winnerPhoneNumber = userData?.phoneNumber ?? "No disponible";
          }
        } catch (userError) {
          logger.error(`Could not fetch user profile for 
          ${winnerTicketInfo.userId}`);
        }

        // 2. Guardamos toda la información en el objeto del ganador
        winners.push({
          prizePosition: prize.position,
          prizeDescription: prize.description,
          winningNumber: winningNumber,
          winnerUserId: winnerTicketInfo.userId,
          winnerName: winnerName, // <-- Ahora es el nombre real
          winnerEmail: winnerEmail, // <-- Ahora es el email real
          winnerPhoneNumber: winnerPhoneNumber, // <-- Teléfono
          adminNotes: winnerTicketInfo.adminNotes, // <-- Nota del admin
          customData: winnerTicketInfo.customData, // <-- Datos personalizados
        });
      }

      return raffleDoc.ref.update({
        status: "finished",
        winners: winners,
      });
    } catch (error) {
      logger.error(`Failed to process draw for raffle ${raffleId}:`, error);
      return raffleDoc.ref.update({status: "error_drawing"});
    }
  });

  await Promise.all(drawPromises);
  logger.log(`Finished processing ${dueRaffles.size} draws.`);
});

export const createPaymentPreference = onCall(
  {secrets: ["MERCADOPAGO_ACCESS_TOKEN"]},
  async (request) => {
    logger.info("Función createPaymentPreference llamada.");

    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Debes iniciar sesión.");
    }

    const {raffleId, raffleTitle, quantity, unitPrice} = request.data;
    if (!raffleId || !raffleTitle || !quantity || !unitPrice) {
      throw new HttpsError("invalid-argument", "Faltan datos para el pago.");
    }

    // Accedemos al secreto inyectado como variable de entorno. ¡Mucho más simple!
    const accessToken = process.env.MERCADOPAGO_ACCESS_TOKEN;
    if (!accessToken) {
      logger.error("El secreto MERCADOPAGO_ACCESS_TOKEN no fue encontrado.");
      throw new HttpsError("internal", "No se pudo configurar el pago.");
    }

    const preference = {
      items: [
        {
          id: raffleId,
          title: `Boleto(s) para: ${raffleTitle}`,
          description: `Compra de ${quantity} boleto(s).`,
          quantity: quantity,
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

    try {
      logger.info("Creando preferencia de pago en Mercado Pago...");
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
      logger.info("Preferencia creada con éxito:", preferenceId);
      return {preferenceId: preferenceId};
    } catch (error: unknown) {
      if (axios.isAxiosError(error) && error.response) {
        logger.error("Error de MercadoPago:", error.response.data);
      } else {
        logger.error("Error desconocido al crear preferencia:", error);
      }
      throw new HttpsError("internal", "No se pudo crear el link de pago.");
    }
  });
