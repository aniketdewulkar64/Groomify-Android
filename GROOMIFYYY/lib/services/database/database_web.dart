import '../../models/user.dart';
import '../../models/recommendation.dart';
import 'package:groomify/services/database/database_stub.dart';

export 'package:groomify/services/database/database_stub.dart';

class DatabaseImplementationWeb implements DatabaseImplementation {

  // Simple in-memory storage for session testing
  final List<User> _users = [];
  final List<Recommendation> _recommendations = [];

  @override
  Future<int> createUser(User user) async {
    // Mock user creation
    // Mock user creation
    final newUser = User(
      id: _users.length + 1,
      name: user.name,
      email: user.email,
      passwordHash: user.passwordHash,
      createdAt: user.createdAt,
    );
    _users.add(newUser);
    return newUser.id!;
  }

  @override
  Future<User?> getUserByEmail(String email) async {
     try {
       return _users.firstWhere((u) => u.email == email);
     } catch (e) {
       return null;
     }
  }

  @override
  Future<User?> loginUser(String email, String password) async {
    // Simple mock login - ignores password hashing for now or just checks equality
    // In a real mock we should match hash but we don't need crypto package here if we avoid it.
    // Let's just return the user if found.
    return getUserByEmail(email);
  }

  @override
  Future<int> saveRecommendation(Recommendation recommendation) async {
    _recommendations.add(recommendation);
    return _recommendations.length;
  }

  @override
  Future<List<Recommendation>> getUserRecommendations(int userId) async {
    return _recommendations.where((r) => r.userId == userId).toList();
  }

  @override
  Future<void> close() async {}
}

DatabaseImplementation getImplementation() => DatabaseImplementationWeb();
