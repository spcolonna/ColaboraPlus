import '../../models/House.dart';
import '../../models/SearchFilterModel.dart';
import '../../models/UserModel.dart';

abstract class IProfileService {
  Future<UserModel> getUserProfile();
  Future<void> createUserProfile(UserModel user);

  Future<List<House>> getMyHouses();
  Future<void> createHouse(House house);
  Future<void> updateHouse(House house);
  Future<void> deleteHouse(String houseId);

  Future<List<House>> getFavoriteHouses();
  Future<void> addFavorite(String houseId);
  Future<void> removeFavorite(String houseId);

  Future<void> saveFilters(SearchFilterModel filters);
  Future<SearchFilterModel> getUserFilters();
}
