import 'Department.dart';

class Country {
  final String name;
  final List<Department> departments;
  Country(this.name, this.departments);

  factory Country.fromJson(Map<String, dynamic> json) {
    final departmentsList = json['departments'] as List<dynamic>? ?? [];
    return Country(
      json['name'] ?? '',
      departmentsList.map((d) => Department.fromJson(d)).toList(),
    );
  }
}
