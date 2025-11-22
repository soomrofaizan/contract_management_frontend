import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_services.dart';
import 'project_details_screen.dart';
import 'add_item_screen.dart';

class EditProjectDialog extends StatefulWidget {
  final Project project;
  final List<ProjectStatus> statuses;

  const EditProjectDialog({
    super.key,
    required this.project,
    required this.statuses,
  });

  @override
  State<EditProjectDialog> createState() => _EditProjectDialogState();
}

class _EditProjectDialogState extends State<EditProjectDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _costController;
  late DateTime _startDate;
  late DateTime _endDate;
  late ProjectStatus _selectedStatus;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.project.title);
    _costController = TextEditingController(
      text: widget.project.cost.toString(),
    );
    _startDate = widget.project.startDate;
    _endDate = widget.project.endDate;
    _selectedStatus = widget.statuses.firstWhere(
      (status) => status.id == widget.project.status.id,
      orElse: () =>
          widget.statuses.first, // Fallback to first status if not found
    );
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        if (_endDate.isBefore(picked)) {
          _endDate = picked.add(const Duration(days: 30));
        }
      });
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Project'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Project Title'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a project title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Safe status dropdown
              if (widget.statuses.isEmpty)
                const Column(
                  children: [
                    Text('Loading statuses...'),
                    SizedBox(height: 10),
                    CircularProgressIndicator(),
                  ],
                )
              else
                DropdownButtonFormField<ProjectStatus>(
                  value: _selectedStatus,
                  items: widget.statuses.map((status) {
                    return DropdownMenuItem<ProjectStatus>(
                      value: status,
                      child: Text(_formatStatusDisplay(status.name)),
                    );
                  }).toList(),
                  onChanged: (ProjectStatus? value) {
                    setState(() {
                      _selectedStatus = value!;
                    });
                  },
                  decoration: const InputDecoration(labelText: 'Status'),
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a status';
                    }
                    return null;
                  },
                ),

              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Start Date'),
                        TextButton(
                          onPressed: _selectStartDate,
                          child: Text(_formatDate(_startDate)),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('End Date'),
                        TextButton(
                          onPressed: _selectEndDate,
                          child: Text(_formatDate(_endDate)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _costController,
                decoration: const InputDecoration(labelText: 'Cost (Rs)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a cost';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final updatedProject = Project(
                id: widget.project.id,
                title: _titleController.text,
                status: _selectedStatus,
                startDate: _startDate,
                endDate: _endDate,
                cost: double.parse(_costController.text),
              );
              Navigator.of(context).pop(updatedProject);
            }
          },
          child: const Text('Update'),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatStatusDisplay(String status) {
    return status
        .toLowerCase()
        .split('_')
        .map((word) {
          return word[0].toUpperCase() + word.substring(1);
        })
        .join(' ');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _costController.dispose();
    super.dispose();
  }
}

class ProjectsScreen extends StatefulWidget {
  final String? filterStatus;
  final bool showFAB;

  const ProjectsScreen({super.key, this.filterStatus, this.showFAB = true});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  List<Project> _projects = [];
  // ignore: unused_field
  List<Project> _filteredProjects = [];
  bool _isLoading = true;
  List<ProjectStatus> _statuses = [];
  ProjectStatus? _selectedStatus;
  String _selectedSort = 'None';

  @override
  void initState() {
    super.initState();
    _loadProjects();
    _loadStatuses();
  }

  Future<void> _editProject(Project project) async {
    final result = await showDialog<Project>(
      context: context,
      builder: (context) =>
          EditProjectDialog(project: project, statuses: _statuses),
    );

    if (result != null) {
      try {
        setState(() {
          _isLoading = true;
        });
        await ApiService.updateProject(result);
        await _loadProjects();
        _showSuccessSnackBar('Project updated successfully!');
      } catch (e) {
        _showErrorSnackBar('Failed to update project: $e');
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  String _formatStatusDisplay(String status) {
    return status
        .toLowerCase()
        .split('_')
        .map((word) {
          return word[0].toUpperCase() + word.substring(1);
        })
        .join(' ');
  }

  Future<void> _loadStatuses() async {
    try {
      final statuses = await ApiService.getProjectStatuses(activeOnly: true);
      setState(() {
        _statuses = statuses;
      });
    } catch (e) {
      print('Failed to load statuses: $e');
      // Fallback to default statuses
      setState(() {
        _statuses = [
          ProjectStatus(
            id: 1,
            name: 'Completed',
            description: 'Project is completed',
            isActive: true,
          ),
          ProjectStatus(
            id: 2,
            name: 'Running',
            description: 'Project is in progress',
            isActive: true,
          ),
        ];
      });
    }
  }

  Future<void> _loadProjects() async {
    try {
      final int? statusFilter = _selectedStatus?.id;
      final String? sortBy = _selectedSort == 'None'
          ? null
          : _selectedSort.toLowerCase();

      final projects = await ApiService.getProjects(
        statusId: statusFilter,
        sortBy: sortBy,
      );

      List<Project> filtered = projects;
      if (widget.filterStatus != null) {
        filtered = projects.where((project) {
          return project.status.name.toUpperCase() ==
              widget.filterStatus!.toUpperCase();
        }).toList();
      }
      setState(() {
        _projects = projects;
        _filteredProjects = filtered;
        _isLoading = false;
      });
    } catch (e) {
      _showErrorSnackBar('Failed to load projects: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getAppBarTitle() {
    if (widget.filterStatus == 'Completed') {
      return 'Completed Projects';
    } else if (widget.filterStatus == 'Running') {
      return 'In Progress Projects';
    } else {
      return 'All Projects';
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  // ignore: unused_element
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Filter & Sort Projects'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Status filter
                const Text(
                  'Filter by Status:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                DropdownButton<ProjectStatus>(
                  value: _selectedStatus,
                  isExpanded: true,
                  items: [
                    DropdownMenuItem<ProjectStatus>(
                      value: null,
                      child: Text('All Statuses'),
                    ),
                    ..._statuses.map((ProjectStatus status) {
                      return DropdownMenuItem<ProjectStatus>(
                        value: status,
                        child: Text(_formatStatusDisplay(status.name)),
                      );
                    }).toList(),
                  ],
                  onChanged: (ProjectStatus? newValue) {
                    setState(() {
                      _selectedStatus = newValue;
                    });
                  },
                ),
                const SizedBox(height: 20),
                // Sort options (unchanged)
                const Text(
                  'Sort by:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                DropdownButton<String>(
                  value: _selectedSort,
                  isExpanded: true,
                  items:
                      [
                        'None',
                        'Title',
                        'Status',
                        'Start Date',
                        'End Date',
                        'Cost',
                      ].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedSort = newValue!;
                    });
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _loadProjects(); // Reload with new filters
                },
                child: const Text('Apply'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _addProject() async {
    final result = await showDialog<Project>(
      context: context,
      builder: (context) => AddProjectDialog(statuses: _statuses),
    );

    if (result != null) {
      try {
        setState(() {
          _isLoading = true;
        });
        await ApiService.createProject(result);
        await _loadProjects();
      } catch (e) {
        _showErrorSnackBar('Failed to add project: $e');
      }
    }
  }

  Future<void> _deleteProject(Project project) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Project'),
        content: Text('Are you sure you want to delete "${project.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && project.id != null) {
      try {
        setState(() {
          _isLoading = true;
        });
        await ApiService.deleteProject(project.id!);
        await _loadProjects();
      } catch (e) {
        _showErrorSnackBar('Failed to delete project: $e');
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToProjectDetails(Project project) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProjectDetailsScreen(project: project),
      ),
    ).then((_) => _loadProjects());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Projects'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _projects.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.folder_open, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    widget.filterStatus == 'Completed'
                        ? 'No completed projects found.'
                        : widget.filterStatus == 'Running'
                        ? 'No in-progress projects found.'
                        : 'No projects found.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _filteredProjects.length,
              itemBuilder: (context, index) {
                final project = _filteredProjects[index];
                return ProjectCard(
                  project: project,
                  onTap: () => _navigateToProjectDetails(project),
                  onEdit: () => _editProject(project),
                  onDelete: () => _deleteProject(project),
                );
              },
            ),
      floatingActionButton: widget.showFAB
          ? FloatingActionButton(
              onPressed: _addProject,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

class ProjectCard extends StatelessWidget {
  final Project project;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ProjectCard({
    super.key,
    required this.project,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        onTap: onTap,
        title: Text(
          project.title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Status: ${project.status.name}'),
            Text('Start: ${_formatDate(project.startDate)}'),
            Text('End: ${_formatDate(project.endDate)}'),
            Text('Cost: Rs ${project.cost.toStringAsFixed(2)}'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

class AddProjectDialog extends StatefulWidget {
  final List<ProjectStatus> statuses;

  const AddProjectDialog({super.key, required this.statuses});

  @override
  State<AddProjectDialog> createState() => _AddProjectDialogState();
}

class _AddProjectDialogState extends State<AddProjectDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _costController = TextEditingController();
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));
  late ProjectStatus _selectedStatus;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.statuses.first;
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        if (_endDate.isBefore(picked)) {
          _endDate = picked.add(const Duration(days: 30));
        }
      });
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Project'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Project Title'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a project title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<ProjectStatus>(
                value: _selectedStatus,
                items: widget.statuses.map((status) {
                  return DropdownMenuItem<ProjectStatus>(
                    value: status,
                    child: Text(_formatStatusDisplay(status.name)),
                  );
                }).toList(),
                onChanged: (ProjectStatus? value) {
                  setState(() {
                    _selectedStatus = value!;
                  });
                },
                decoration: const InputDecoration(labelText: 'Status'),
                validator: (value) {
                  if (value == null) {
                    return 'Please select a status';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Start Date'),
                        TextButton(
                          onPressed: _selectStartDate,
                          child: Text(_formatDate(_startDate)),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('End Date'),
                        TextButton(
                          onPressed: _selectEndDate,
                          child: Text(_formatDate(_endDate)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _costController,
                decoration: const InputDecoration(labelText: 'Cost'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a cost';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final project = Project(
                title: _titleController.text,
                status: _selectedStatus,
                startDate: _startDate,
                endDate: _endDate,
                cost: double.parse(_costController.text),
              );
              Navigator.of(context).pop(project);
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatStatusDisplay(String status) {
    return status
        .toLowerCase()
        .split('_')
        .map((word) {
          return word[0].toUpperCase() + word.substring(1);
        })
        .join(' ');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _costController.dispose();
    super.dispose();
  }
}
