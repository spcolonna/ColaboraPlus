class SearchFilterModel {
  String? country;
  String? department;
  String? neighborhood;
  double minPrice;
  double maxPrice;
  int bedrooms;
  int bathrooms;
  int area;

  SearchFilterModel({
    this.country = 'Uruguay',
    this.department,
    this.neighborhood,
    this.minPrice = 0,
    this.maxPrice = 500000,
    this.bedrooms = 0,
    this.bathrooms = 0,
    this.area = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'country': country,
      'department': department,
      'neighborhood': neighborhood,
      'minPrice': minPrice,
      'maxPrice': maxPrice,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'area': area,
    };
  }

  factory SearchFilterModel.fromMap(Map<String, dynamic> map) {
    return SearchFilterModel(
      country: map['country'],
      department: map['department'],
      neighborhood: map['neighborhood'],
      minPrice: (map['minPrice'] as num?)?.toDouble() ?? 0,
      maxPrice: (map['maxPrice'] as num?)?.toDouble() ?? 500000,
      bedrooms: map['bedrooms'] as int? ?? 0,
      bathrooms: map['bathrooms'] as int? ?? 0,
      area: map['area'] as int? ?? 0,
    );
  }
}
