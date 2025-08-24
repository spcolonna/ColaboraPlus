
// Esta clase simple nos ayuda a combinar los datos para la UI.
import 'package:colabora_plus/models/raffle_model.dart';

class RaffleParticipation {
  final RaffleModel raffle;
  final List<int> userNumbers;

  RaffleParticipation({
    required this.raffle,
    required this.userNumbers,
  });
}
