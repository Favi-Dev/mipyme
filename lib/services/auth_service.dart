enum UserRole { client, pyme, admin }

class AuthService {
  // Mock authentication
  static Future<UserRole?> login(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay

    if (email == 'admin@soypyme.cl' && password == 'admin123') {
      return UserRole.admin;
    } else if (email.contains('pyme') && password == 'pyme123') {
      return UserRole.pyme;
    } else if (password == 'user123') {
      return UserRole.client;
    }
    
    // For demo purposes, allow any login as client if password is '123456'
    if (password == '123456') {
      return UserRole.client;
    }

    return null; // Login failed
  }

  static Future<bool> register(String email, String password, String name, UserRole role) async {
    await Future.delayed(const Duration(seconds: 1));
    return true; // Registration successful
  }
}
