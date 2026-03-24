import '../../models/user.dart';
import '../../models/recommendation.dart';

abstract class DatabaseImplementation {
  Future<int> createUser(User user);
  Future<User?> getUserByEmail(String email);
  Future<User?> loginUser(String email, String password);
  Future<int> saveRecommendation(Recommendation recommendation);
  Future<List<Recommendation>> getUserRecommendations(int userId);
  Future<void> close();
}

DatabaseImplementation getImplementation() => throw UnimplementedError();
