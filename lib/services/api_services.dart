import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';
import 'auth_service.dart';

class ApiService {
  static const String baseUrl =
      'http://10.0.2.2:8080/api'; // For Android emulator
  // static const String baseUrl = 'http://localhost:8080/api'; // For iOS simulator
  // static const String baseUrl = 'http://your-ip-address:8080/api'; // For physical device

  static Future<Map<String, String>> _getHeaders() async {
    final token = await AuthService.getToken();
    final headers = {'Content-Type': 'application/json'};

    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
      print(
        'Adding Authorization header with token: ${token.substring(0, 20)}...',
      );
    } else {
      print('WARNING: No token found for Authorization header');
    }

    return headers;
  }

  static Future<List<ProjectStatus>> getProjectStatuses({
    bool activeOnly = true,
  }) async {
    try {
      final Map<String, String> queryParams = {};
      if (activeOnly) {
        queryParams['activeOnly'] = 'true';
      }

      final Uri uri = Uri.parse(
        '$baseUrl/project-statuses',
      ).replace(queryParameters: queryParams);

      // Get headers with authorization token
      final headers = await _getHeaders();

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => ProjectStatus.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        throw Exception('Authentication required to load project statuses');
      } else {
        throw Exception(
          'Failed to load project statuses: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error loading project statuses: $e');
      throw Exception('Failed to load project statuses: $e');
    }
  }

  static Future<List<Project>> getProjects({
    int? statusId,
    String? sortBy,
  }) async {
    try {
      final headers = await _getHeaders();
      final Map<String, String> queryParams = {};
      if (statusId != null) {
        queryParams['statusId'] = statusId.toString();
      }
      if (sortBy != null && sortBy.isNotEmpty) {
        queryParams['sortBy'] = sortBy;
      }

      final uri = Uri.parse(
        '$baseUrl/projects',
      ).replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Project.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        throw Exception('Authentication required');
      } else {
        throw Exception('Failed to load projects: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load projects: $e');
    }
  }

  static Future<Project> createProject(Project project) async {
    try {
      final headers = await _getHeaders();

      final response = await http.post(
        Uri.parse('$baseUrl/projects'),
        headers: headers,
        body: json.encode(project.toJson()),
      );

      if (response.statusCode == 201) {
        return Project.fromJson(json.decode(response.body));
      } else if (response.statusCode == 401) {
        throw Exception('Authentication required');
      } else {
        throw Exception('Failed to create project: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to create project: $e');
    }
  }

  static Future<void> deleteProject(int projectId) async {
    try {
      final headers = await _getHeaders();

      final response = await http.delete(
        Uri.parse('$baseUrl/projects/$projectId'),
        headers: headers,
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete project: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to delete project: $e');
    }
  }

  static Future<List<ProjectItem>> getProjectItems(int projectId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/projects/$projectId/items'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => ProjectItem.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load project items: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load project items: $e');
    }
  }

  static Future<ProjectItem> addProjectItem(
    int projectId,
    ProjectItem item,
  ) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/projects/$projectId/items'),
        headers: headers,
        body: json.encode(item.toJson()),
      );

      if (response.statusCode == 201) {
        return ProjectItem.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to add project item: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to add project item: $e');
    }
  }

  static Future<void> deleteProjectItem(int projectId, int itemId) async {
    try {
      final headers = await _getHeaders();

      final response = await http.delete(
        Uri.parse('$baseUrl/projects/$projectId/items/$itemId'),
        headers: headers,
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception(
          'Failed to delete project item: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Failed to delete project item: $e');
    }
  }

  static Future<Project> updateProject(Project project) async {
    try {
      final headers = await _getHeaders();

      final response = await http.put(
        Uri.parse('$baseUrl/projects/${project.id}'),
        headers: headers,
        body: json.encode(project.toJson()),
      );

      if (response.statusCode == 200) {
        return Project.fromJson(json.decode(response.body));
      } else if (response.statusCode == 401) {
        throw Exception('Authentication required');
      } else {
        throw Exception('Failed to update project: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to update project: $e');
    }
  }
}
