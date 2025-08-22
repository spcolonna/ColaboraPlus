class Neighborhood {
  final String name;
  Neighborhood(this.name);

  factory Neighborhood.fromJson(Map<String, dynamic> json) {
    return Neighborhood(json['name'] ?? '');
  }
}
