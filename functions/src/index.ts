import {onDocumentWritten} from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

admin.initializeApp();
const db = admin.firestore();

/**
 * Se activa cada vez que un documento de boleto es creado o actualizado.
 * Mantiene el contador 'soldTicketsCount' de la rifa sincronizado.
 */
export const onTicketWrite = onDocumentWritten(
  "raffles/{raffleId}/tickets/{ticketId}",
  (event) => {
    const raffleId = event.params.raffleId;
    const raffleRef = db.collection("raffles").doc(raffleId);

    const change = event.data;
    if (!change) {
      logger.warn("Event had no data change. Exiting function.");
      return null;
    }

    const dataBefore = change.before.data();
    const dataAfter = change.after.data();

    logger.log(`Function triggered for raffle ${raffleId}.`);
    logger.log("Data Before:", JSON.stringify(dataBefore || {}));
    logger.log("Data After:", JSON.stringify(dataAfter || {}));

    const wasPaidBefore = dataBefore?.isPaid === true;
    const isPaidAfter = dataAfter?.isPaid === true;

    logger.log(
      `Status check: wasPaidBefore=${wasPaidBefore}, 
      isPaidAfter=${isPaidAfter}`,
    );

    let incrementValue = 0;
    const ticketsBefore = dataBefore?.ticketNumbers?.length ?? 0;
    const ticketsAfter = dataAfter?.ticketNumbers?.length ?? 0;

    if (!wasPaidBefore && isPaidAfter) {
      incrementValue = ticketsAfter;
    } else if (wasPaidBefore && !isPaidAfter) {
      incrementValue = -ticketsBefore;
    }

    if (incrementValue === 0) {
      logger.log("No relevant change in 'isPaid' status. No update needed.");
      return null;
    }

    logger.log(
      `Attempting to update soldTicketsCount by ${incrementValue}`,
      ` for raffle ${raffleId}`,
    );
    return raffleRef.update({
      soldTicketsCount: admin.firestore.FieldValue.increment(incrementValue),
    }).catch((err) => {
      logger.error("Failed to update raffle document:", err);
    });
  },
);
