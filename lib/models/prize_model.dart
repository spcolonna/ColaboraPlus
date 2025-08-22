class PrizeModel {
  final int position;      // 1 para 1er premio, 2 para 2do, etc.
  final String description; // Ej: "TV 50'", "Celular Samsung S25"

  PrizeModel({
    required this.position,
    required this.description,
  });

  // Convierte un Mapa (como los que se guardan en Firestore) a un objeto PrizeModel
  factory PrizeModel.fromMap(Map<String, dynamic> map) {
    return PrizeModel(
      position: map['position'] ?? 0,
      description: map['description'] ?? 'Sin descripción',
    );
  }

  // Convierte un objeto PrizeModel a un Mapa para guardarlo en Firestore
  Map<String, dynamic> toMap() {
    return {
      'position': position,
      'description': description,
    };
  }
}
