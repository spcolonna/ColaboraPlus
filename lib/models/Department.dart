import 'Neighborhood.dart';

class Department {
  final String name;
  final List<Neighborhood> neighborhoods;
  Department(this.name, this.neighborhoods);

  factory Department.fromJson(Map<String, dynamic> json) {
    final neighborhoodsList = json['neighborhoods'] as List<dynamic>? ?? [];
    return Department(
      json['name'] ?? '',
      neighborhoodsList.map((n) => Neighborhood.fromJson(n)).toList(),
    );
  }
}
