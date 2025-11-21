import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class ApiService {
  static const String baseUrl =
      'http://10.0.2.2:8080/api'; // For Android emulator
  // static const String baseUrl = 'http://localhost:8080/api'; // For iOS simulator
  // static const String baseUrl = 'http://your-ip-address:8080/api'; // For physical device

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

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => ProjectStatus.fromJson(json)).toList();
      } else {
        throw Exception(
          'Failed to load project statuses: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Failed to load project statuses: $e');
    }
  }

  static Future<List<Project>> getProjects({
    int? statusId,
    String? sortBy,
  }) async {
    try {
      final Map<String, String> queryParams = {};
      if (statusId != null) {
        queryParams['statusId'] = statusId.toString();
      }
      if (sortBy != null && sortBy.isNotEmpty) {
        queryParams['sortBy'] = sortBy;
      }

      final Uri uri = Uri.parse(
        '$baseUrl/projects',
      ).replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Project.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load projects: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load projects: $e');
    }
  }

  static Future<Project> createProject(Project project) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/projects'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(project.toJson()),
      );

      if (response.statusCode == 201) {
        return Project.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to create project: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to create project: $e');
    }
  }

  static Future<void> deleteProject(int projectId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/projects/$projectId'),
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
      final response = await http.get(
        Uri.parse('$baseUrl/projects/$projectId/items'),
        headers: {'Content-Type': 'application/json'},
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
      final response = await http.post(
        Uri.parse('$baseUrl/projects/$projectId/items'),
        headers: {'Content-Type': 'application/json'},
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
      final response = await http.delete(
        Uri.parse('$baseUrl/projects/$projectId/items/$itemId'),
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
      final response = await http.put(
        Uri.parse('$baseUrl/projects/${project.id}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(project.toJson()),
      );

      if (response.statusCode == 200) {
        return Project.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to update project: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to update project: $e');
    }
  }
}
