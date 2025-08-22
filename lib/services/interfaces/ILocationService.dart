
abstract class ILocationService {
  Future<List<String>> getAvailableCountries();
  Future<List<String>> getDepartments(String countryName);
  Future<List<String>> getNeighborhoods(String countryName, String departmentName);
}
