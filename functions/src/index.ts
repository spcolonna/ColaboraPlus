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
export const performDraws = onSchedule("every 5 minutes", async () => {
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
        await raffleDoc.ref.update({status: "finished"});
        return;
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

      const winners: any[] = [];
      const prizes: Prize[] = [...raffleData.prizes]
        .sort((a: Prize, b: Prize) => a.position - b.position);

      for (const prize of prizes) {
        if (numberPool.length === 0) break;
        const randomIndex = Math.floor(Math.random() * numberPool.length);
        const winningNumber = numberPool.splice(randomIndex, 1)[0];
        const winnerTicketInfo = numberOwners[winningNumber];

        let winnerName = "Usuario Anónimo";
        let winnerEmail = "No disponible";
        let winnerPhoneNumber = "No disponible";
        try {
          const userDoc = await db.collection("users").doc(winnerTicketInfo.userId).get();
          if (userDoc.exists) {
            const userData = userDoc.data();
            winnerName = userData?.name || userData?.email || userData?.mail || "Usuario Anónimo";
            winnerEmail = userData?.email || userData?.mail || "No disponible";
            winnerPhoneNumber = userData?.phoneNumber ?? "No disponible";
          }
        } catch (e) {
          logger.error(`Could not fetch user profile for ${winnerTicketInfo.userId}`, e);
        }

        winners.push({
          prizePosition: prize.position,
          prizeDescription: prize.description,
          winningNumber: winningNumber,
          winnerUserId: winnerTicketInfo.userId,
          winnerName: winnerName,
          winnerEmail: winnerEmail,
          winnerPhoneNumber: winnerPhoneNumber,
          adminNotes: winnerTicketInfo.adminNotes,
          customData: winnerTicketInfo.customData,
        });
      }

      await raffleDoc.ref.update({
        status: "finished",
        winners: winners,
      });
      logger.log(`Raffle ${raffleId} finished and winners saved.`);

      const notificationPromises = [];
      const adminDoc = await db.collection("users").doc(raffleData.creatorId).get();
      const adminTokens = adminDoc.data()?.fcmTokens?.filter((t: string) => t) || [];
      if (adminTokens.length > 0) {
        const message = {
          notification: {
            title: "¡Sorteo Finalizado!",
            body: `Tu rifa "${raffleData.title}" ha finalizado. ¡Revisa los ganadores!`,
          },
          tokens: adminTokens,
        };
        notificationPromises.push(admin.messaging().sendEachForMulticast(message));
      }

      for (const winner of winners) {
        const winnerDoc = await db.collection("users").doc(winner.winnerUserId).get();
        const winnerTokens = winnerDoc.data()?.fcmTokens?.filter((t: string) => t) || [];
        if (winnerTokens.length > 0) {
          const message = {
            notification: {
              title: "🎉 ¡Felicidades, has ganado! 🎉",
              body: `Ganaste en la rifa "${raffleData.title}": ${winner.prizeDescription}.`,
            },
            tokens: winnerTokens,
          };
          notificationPromises.push(admin.messaging().sendEachForMulticast(message));
        }
      }

      await Promise.all(notificationPromises);
      logger.log(`Notification send process completed for raffle ${raffleId}.`);
      return;
    } catch (error) {
      logger.error(`Failed to process draw for raffle ${raffleId}:`, error);
      await raffleDoc.ref.update({status: "error_drawing"});
      return;
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
      const initPoint = response.data.sandbox_init_point;

      logger.info("Preferencia creada:", preferenceId);
      return {preferenceId: preferenceId, initPoint: initPoint};
    } catch (error: unknown) {
      if (axios.isAxiosError(error) && error.response) {
        logger.error("Error de MercadoPago:", error.response.data);
      } else {
        logger.error("Error desconocido al crear preferencia:", error);
      }
      throw new HttpsError("internal", "No se pudo crear el link de pago.");
    }
  });

export const mercadoPagoWebhook = onCall(
  {secrets: ["MERCADOPAGO_ACCESS_TOKEN"]},
  async (request) => {
    // El cuerpo de la notificación viene en request.data
    const notification = request.data;
    logger.info("Webhook de Mercado Pago recibido:", notification);

    // Verificamos que sea una notificación de pago
    if (notification?.type === "payment" && notification.data?.id) {
      const paymentId = notification.data.id;
      logger.info(`Procesando ID de pago: ${paymentId}`);

      try {
        const accessToken = process.env.MERCADOPAGO_ACCESS_TOKEN;
        if (!accessToken) {
          throw new HttpsError("internal", "Access Token no configurado.");
        }

        // 1. Buscamos los detalles completos del pago en la API de Mercado Pago
        //    para verificar que sea un pago real y aprobado.
        const paymentResponse = await axios.get(
          `https://api.mercadopago.com/v1/payments/${paymentId}`,
          {headers: {"Authorization": `Bearer ${accessToken}`}},
        );

        const paymentData = paymentResponse.data;
        const preferenceId = paymentData.preference_id;
        const paymentStatus = paymentData.status;

        logger.info(`Pago encontrado. PreferenceId: ${preferenceId}, Status: ${paymentStatus}`);

        // 2. Si el pago está aprobado, buscamos el boleto en nuestra base de datos
        if (paymentStatus === "approved") {
          const ticketsQuery = await db.collectionGroup("tickets")
            .where("paymentPreferenceId", "==", preferenceId)
            .limit(1)
            .get();

          if (ticketsQuery.empty) {
            logger.warn(`No se encontró ningún boleto para la preferencia de pago: ${preferenceId}`);
            return {status: "error", message: "Boleto no encontrado."};
          }

          // 3. Actualizamos el estado del boleto a 'pagado'
          const ticketDoc = ticketsQuery.docs[0];
          await ticketDoc.ref.update({isPaid: true});

          logger.info(`Boleto ${ticketDoc.id} marcado como pagado.`);
          return {status: "success", message: "Boleto actualizado."};
        } else {
          logger.warn(`El pago ${paymentId} no está aprobado. Estado: ${paymentStatus}`);
          return {status: "ignored", message: "Pago no aprobado."};
        }
      } catch (error) {
        logger.error(`Error procesando el pago ${paymentId}:`, error);
        throw new HttpsError("internal", "Error al procesar el webhook.");
      }
    }

    // Si la notificación no es de pago, la ignoramos.
    return {status: "ignored", message: "Notificación no relevante."};
  },
);
