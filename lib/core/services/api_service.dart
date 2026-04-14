import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/structure_model.dart';

class ApiService {
  // Base URL for the API
  static String get baseUrl {
    // In Flutter Web, we can use the current origin
    // For local development, it might be localhost:3000
    // In AI Studio preview, it will be the cloud URL
    try {
      final origin = Uri.base.origin;
      if (origin.contains('localhost')) {
        // If the app is served from a different port (e.g. 55338), 
        // we still want to hit the backend on port 3000
        return 'http://localhost:3000/api';
      }
      return '$origin/api';
    } catch (e) {
      // Fallback for non-web or errors
      return 'http://localhost:3000/api';
    }
  }

  static String get fullUrl {
    try {
      final origin = Uri.base.origin;
      if (origin.contains('localhost')) {
        return 'http://localhost:3000';
      }
      return origin;
    } catch (e) {
      return 'http://localhost:3000';
    }
  }

  // Helper: Handle Response
  dynamic _handleResponse(http.Response response) {
    final data = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    } else if (response.statusCode == 403 && data['error'] != null && data['error'].toString().contains('bloqué')) {
      // Auto logout on blocked account
      logout();
      throw data;
    } else {
      throw data;
    }
  }

  // Auth: Login
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    final data = _handleResponse(response);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', data['token']);
    await prefs.setString('user', jsonEncode(data['user']));
    return data;
  }

  // Auth: Register
  Future<void> register(String email, String password, String name, String phone) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email, 
        'password': password, 
        'name': name,
        'phone': phone,
      }),
    );

    if (response.statusCode != 201) {
      _handleResponse(response); // This will throw
    }
  }

  // Structures: Fetch all
  Future<List<StructureModel>> getStructures() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    
    final response = await http.get(
      Uri.parse('$baseUrl/structures'),
      headers: token != null ? {'Authorization': 'Bearer $token'} : {},
    );

    final data = _handleResponse(response);
    if (data is List) {
      return data.map((json) => StructureModel.fromJson(json)).toList();
    }
    return [];
  }

  // Routing: Get real route from OSRM
  Future<List<Map<String, double>>> getRoute(double startLat, double startLng, double endLat, double endLng) async {
    try {
      final url = 'https://router.project-osrm.org/route/v1/driving/$startLng,$startLat;$endLng,$endLat?overview=full&geometries=geojson';
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final coordinates = data['routes'][0]['geometry']['coordinates'] as List;
          return coordinates.map((c) => {
            'lat': (c[1] as num).toDouble(),
            'lng': (c[0] as num).toDouble(),
          }).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching route: $e');
      return [];
    }
  }

  // Structures: Create
  Future<StructureModel> createStructure(StructureModel structure) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.post(
      Uri.parse('$baseUrl/structures'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(structure.toJson()),
    );

    final data = _handleResponse(response);
    return StructureModel.fromJson(data);
  }

  // Structures: Update
  Future<StructureModel> updateStructure(String id, Map<String, dynamic> updates) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.put(
      Uri.parse('$baseUrl/structures/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(updates),
    );

    final data = _handleResponse(response);
    return StructureModel.fromJson(data);
  }

  // Structures: Delete
  Future<void> deleteStructure(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.delete(
      Uri.parse('$baseUrl/structures/$id'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    _handleResponse(response);
  }

  // Structures: Block/Unblock
  Future<StructureModel> blockStructure(String id, bool isBlocked) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.patch(
      Uri.parse('$baseUrl/structures/$id/block'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'isBlocked': isBlocked}),
    );

    final data = _handleResponse(response);
    return StructureModel.fromJson(data);
  }

  // Users: Fetch all
  Future<List<UserModel>> getUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('$baseUrl/users'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    final data = _handleResponse(response);
    if (data is List) {
      return data.map((json) => UserModel.fromJson(json)).toList();
    }
    return [];
  }

  // Users: Fetch admins
  Future<List<UserModel>> getAdmins() async {
    final users = await getUsers();
    return users.where((u) => u.role == 'admin').toList();
  }

  // Users: Block/Unblock
  Future<UserModel> blockUser(String id, bool isBlocked) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.patch(
      Uri.parse('$baseUrl/users/$id/block'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'isBlocked': isBlocked}),
    );

    final data = _handleResponse(response);
    return UserModel.fromJson(data);
  }

  // Activities: Fetch all
  Future<List<dynamic>> getActivities() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('$baseUrl/activities'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    return _handleResponse(response);
  }

  // Activities: Fetch recent
  Future<List<dynamic>> getRecentActivities() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('$baseUrl/activities/recent'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    return _handleResponse(response);
  }

  // Profile: Fetch
  Future<UserModel> getProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('$baseUrl/auth/profile'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    final data = _handleResponse(response);
    final user = UserModel.fromJson(data);
    await prefs.setString('user', jsonEncode(user.toJson()));
    return user;
  }

  // Profile: Update
  Future<UserModel> updateProfile(String name, String email, {String? phone, String? profilePicture}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.put(
      Uri.parse('$baseUrl/auth/profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'name': name, 
        'email': email,
        'phone': phone,
        'profilePicture': profilePicture,
      }),
    );

    if (response.statusCode == 200) {
      final user = UserModel.fromJson(jsonDecode(response.body));
      await prefs.setString('user', jsonEncode(user.toJson()));
      return user;
    } else {
      throw Exception('Failed to update profile');
    }
  }

  // Profile: Change Password
  Future<void> changePassword(String oldPassword, String newPassword) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.post(
      Uri.parse('$baseUrl/auth/change-password'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'oldPassword': oldPassword, 'newPassword': newPassword}),
    );

    _handleResponse(response);
  }

  // Users: Create
  Future<void> createUser(String email, String password, String name, String role, {String? phone, String? profilePicture}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.post(
      Uri.parse('$baseUrl/users'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'email': email,
        'password': password,
        'name': name,
        'role': role,
        'phone': phone,
        'profilePicture': profilePicture,
      }),
    );

    _handleResponse(response);
  }

  // Users: Update
  Future<UserModel> updateUser(String id, Map<String, dynamic> updates) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.put(
      Uri.parse('$baseUrl/users/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(updates),
    );

    final data = _handleResponse(response);
    return UserModel.fromJson(data);
  }

  // Users: Delete
  Future<void> deleteUser(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.delete(
      Uri.parse('$baseUrl/users/$id'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    _handleResponse(response);
  }

  // Subscriptions: Fetch all
  Future<List<dynamic>> getSubscriptions() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('$baseUrl/subscriptions'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    return _handleResponse(response);
  }

  // Subscriptions: Create
  Future<void> createSubscription(String structureId, String type, int durationInDays) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.post(
      Uri.parse('$baseUrl/subscriptions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'structureId': structureId,
        'type': type,
        'durationInDays': durationInDays,
      }),
    );

    _handleResponse(response);
  }

  // Comments: Add
  Future<void> addComment(String structureId, String text) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.post(
      Uri.parse('$baseUrl/structures/$structureId/comments'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'text': text}),
    );

    _handleResponse(response);
  }

  // Comments: Fetch
  Future<List<dynamic>> getComments(String structureId) async {
    final response = await http.get(Uri.parse('$baseUrl/structures/$structureId/comments'));
    return _handleResponse(response);
  }

  // Stats: Fetch
  Future<Map<String, dynamic>> getStats() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('$baseUrl/stats'),
      headers: token != null ? {'Authorization': 'Bearer $token'} : {},
    );

    return _handleResponse(response);
  }

  // Subscriptions: Update
  Future<void> updateSubscription(String id, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.put(
      Uri.parse('$baseUrl/subscriptions/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );

    _handleResponse(response);
  }

  // Notifications: Fetch
  Future<List<dynamic>> getNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('$baseUrl/notifications'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    return _handleResponse(response);
  }

  // Notifications: Create
  Future<void> createNotification(String title, String message, {String? userId, String? targetRole}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.post(
      Uri.parse('$baseUrl/notifications'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'title': title,
        'message': message,
        'userId': userId,
        'targetRole': targetRole,
      }),
    );

    _handleResponse(response);
  }

  // AI: Intelligent Search
  Future<Map<String, dynamic>> aiSearch(String query) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.post(
      Uri.parse('$baseUrl/ai/search'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'query': query}),
    );

    return _handleResponse(response);
  }

  // AI: Image Analysis (Vision)
  Future<Map<String, dynamic>> analyzeImage(String base64Image, String type) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.post(
      Uri.parse('$baseUrl/ai/analyze-image'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'image': base64Image,
        'type': type,
      }),
    );

    return _handleResponse(response);
  }

  // AI: Assistant Chat (RAG)
  Future<String> aiChat(String message) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.post(
      Uri.parse('$baseUrl/ai/chat'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'message': message}),
    );

    final data = _handleResponse(response);
    return data['reply'];
  }

  // Upload: Image
  Future<String> uploadImage(List<int> bytes, String fileName) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/uploads'));
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.files.add(http.MultipartFile.fromBytes(
      'image',
      bytes,
      filename: fileName,
    ));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['url']; // Returns something like "/uploads/image-123.jpg"
    } else {
      throw Exception('Failed to upload image');
    }
  }

  // Helper: Logout
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
  }

  // Helper: Get current user
  Future<UserModel?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');
    if (userJson != null) {
      return UserModel.fromJson(jsonDecode(userJson));
    }
    return null;
  }
}
