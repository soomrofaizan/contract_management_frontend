import 'package:flutter/material.dart';
import 'projects_screen.dart';
import 'add_item_screen.dart';
import '../models/models.dart';
import '../services/api_services.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<ProjectStatus> _statuses = [];
  bool _isLoadingStatuses = true;

  @override
  void initState() {
    super.initState();
    _loadStatuses();
  }

  Future<void> _loadStatuses() async {
    try {
      final statuses = await ApiService.getProjectStatuses(activeOnly: true);
      setState(() {
        _statuses = statuses;
        _isLoadingStatuses = false;
      });
    } catch (e) {
      print('Failed to load statuses: $e');
      // Fallback to default statuses
      setState(() {
        _statuses = [
          ProjectStatus(
            id: 1,
            name: 'COMPLETED',
            description: 'Project is completed',
            isActive: true,
          ),
          ProjectStatus(
            id: 2,
            name: 'RUNNING',
            description: 'Project is in progress',
            isActive: true,
          ),
        ];
        _isLoadingStatuses = false;
      });
    }
  }

  Future<void> _createProject() async {
    if (_isLoadingStatuses) {
      // Show a snackbar that we are still loading
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Loading statuses, please wait...'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final result = await showDialog<Project>(
      context: context,
      builder: (context) => AddProjectDialog(statuses: _statuses),
    );

    if (result != null) {
      // Project created, you can show a success message or navigate to the project
      try {
        await ApiService.createProject(result);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Project created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create project: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Project Management'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 1. Create Project Button (NEW)
            ElevatedButton.icon(
              onPressed: _createProject,
              icon: const Icon(Icons.create),
              label: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Create Project', style: TextStyle(fontSize: 18)),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 20),

            // 2. Add Item Button
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddItemScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Add Item', style: TextStyle(fontSize: 18)),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 20),

            // 3. View Completed Projects Button
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProjectsScreen(
                      filterStatus: 'COMPLETED',
                      showFAB: false,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.check_circle),
              label: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'View Completed Projects',
                  style: TextStyle(fontSize: 18),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 20),

            // 4. View In Progress Projects Button
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ProjectsScreen(filterStatus: 'Running', showFAB: true),
                  ),
                );
              },
              icon: const Icon(Icons.build),
              label: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'View Running Projects',
                  style: TextStyle(fontSize: 18),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
