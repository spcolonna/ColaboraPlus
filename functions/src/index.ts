import {onDocumentWritten} from "firebase-functions/v2/firestore";
import {onSchedule} from "firebase-functions/v2/scheduler";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

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
export const performDraws =
    onSchedule("every 5 minutes", async (_event) => {
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
          const numberOwners: {[key: number]:
              {userId: string, userName: string}} = {};

          ticketsSnapshot.forEach((ticketDoc) => {
            const ticketData = ticketDoc.data();
            const numbers = ticketData.ticketNumbers || [];
            for (const num of numbers) {
              numberPool.push(num);
              numberOwners[num] = {
                userId: ticketData.userId,
                userName: ticketData.userName,
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
            const winnerInfo = numberOwners[winningNumber];

            let winnerEmail = "No disponible";
            let winnerPhoneNumber = "No disponible";

            try {
              const userDoc =
                  await db.collection("users").doc(winnerInfo.userId).get();
              if (userDoc.exists) {
                const userData = userDoc.data();
                winnerEmail = userData?.email ?? "No disponible";
                winnerPhoneNumber = userData?.phoneNumber ?? "No disponible";
              }
            } catch (userError) {
              logger.error(`Could not fetch user profile for 
              ${winnerInfo.userId}`);
            }

            // 2. Guardamos la información de contacto en el objeto del ganador
            winners.push({
              prizePosition: prize.position,
              prizeDescription: prize.description,
              winningNumber: winningNumber,
              winnerUserId: winnerInfo.userId,
              winnerName: winnerInfo.userName,
              winnerEmail: winnerEmail, // <-- Dato añadido
              winnerPhoneNumber: winnerPhoneNumber, // <-- Dato añadido
            });
          }

          return raffleDoc.ref.update({
            status: "finished",
            winners: winners,
          });
        } catch (error) {
          logger.error(
            `Failed to process draw for raffle ${raffleId}:`,
            error,
          );
          return raffleDoc.ref.update({status: "error_drawing"});
        }
      });

      await Promise.all(drawPromises);
      logger.log(`Finished processing ${dueRaffles.size} draws.`);
    });
