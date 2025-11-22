import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_services.dart';

class AddItemScreen extends StatefulWidget {
  const AddItemScreen({super.key});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _itemController = TextEditingController();
  final _rateController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _rentController = TextEditingController(text: '0.0');
  DateTime _date = DateTime.now();
  double _totalAmount = 0.0;
  List<Project> _projects = [];
  Project? _selectedProject;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProjects();
    _calculateTotal();
  }

  Future<void> _loadProjects() async {
    try {
      // Get all projects first
      final allProjects = await ApiService.getProjects();

      // Filter to only show IN_PROGRESS projects
      final inProgressProjects = allProjects.where((project) {
        return project.status.name.toUpperCase() == 'RUNNING';
      }).toList();

      setState(() {
        _projects = inProgressProjects;
        if (_projects.isNotEmpty) {
          _selectedProject = _projects.first;
        } else {
          _selectedProject = null;
        }
        _isLoading = false;
      });

      // Show warning if no in-progress projects found
      if (inProgressProjects.isEmpty) {
        _showWarningSnackBar(
          'No running projects found. Please create a project first.',
        );
      }
    } catch (e) {
      _showErrorSnackBar('Failed to load projects: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showWarningSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 5), // Longer duration for warnings
      ),
    );
  }

  void _calculateTotal() {
    final rate = double.tryParse(_rateController.text) ?? 0;
    final quantity = int.tryParse(_quantityController.text) ?? 0;
    final rent = double.tryParse(_rentController.text) ?? 0;
    final total = (rate * quantity) + rent;

    setState(() {
      _totalAmount = total;
    });
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _date = picked;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate() && _selectedProject != null) {
      try {
        final item = ProjectItem(
          date: _date,
          item: _itemController.text,
          rate: double.parse(_rateController.text),
          quantity: int.parse(_quantityController.text),
          rent: double.parse(_rentController.text),
          totalAmount: _totalAmount,
        );

        await ApiService.addProjectItem(_selectedProject!.id!, item);
        _showSuccessSnackBar('Item added successfully!');
        Navigator.of(context).pop();
      } catch (e) {
        _showErrorSnackBar('Failed to add item: $e');
      }
    } else if (_selectedProject == null) {
      _showErrorSnackBar('Please select a project');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Item to Project'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    // Project Dropdown
                    if (_projects.isEmpty)
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Project',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'No in-progress projects available. Please create a project first.',
                            style: TextStyle(
                              color: Colors.orange,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      )
                    else
                      DropdownButtonFormField<Project>(
                        value: _selectedProject,
                        items: _projects.map((Project project) {
                          return DropdownMenuItem<Project>(
                            value: project,
                            child: Text(project.title),
                          );
                        }).toList(),
                        onChanged: (Project? value) {
                          setState(() {
                            _selectedProject = value;
                          });
                        },
                        decoration: const InputDecoration(
                          labelText: 'Project',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null) {
                            return 'Please select a project';
                          }
                          return null;
                        },
                      ),
                    const SizedBox(height: 20),

                    // Only show the form fields if projects are available
                    if (_projects.isNotEmpty) ...[
                      // Item Name
                      TextFormField(
                        controller: _itemController,
                        decoration: const InputDecoration(
                          labelText: 'Item Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter an item name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Date
                      Row(
                        children: [
                          const Text(
                            'Date',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 20),
                          TextButton(
                            onPressed: _selectDate,
                            child: Text(
                              _formatDate(_date),
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Rate
                      TextFormField(
                        controller: _rateController,
                        decoration: const InputDecoration(
                          labelText: 'Rate (Rs)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (_) => _calculateTotal(),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a rate';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Quantity
                      TextFormField(
                        controller: _quantityController,
                        decoration: const InputDecoration(
                          labelText: 'Quantity',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (_) => _calculateTotal(),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a quantity';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Rent
                      TextFormField(
                        controller: _rentController,
                        decoration: const InputDecoration(
                          labelText: 'Rent (Rs)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (_) => _calculateTotal(),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter rent amount';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Total Amount Display
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total Amount:',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Rs ${_totalAmount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],

                    // Submit Button
                    ElevatedButton(
                      onPressed: _projects.isEmpty ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _projects.isEmpty
                            ? Colors.grey
                            : Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        _projects.isEmpty
                            ? 'No Projects Available'
                            : 'Add Item',
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _itemController.dispose();
    _rateController.dispose();
    _quantityController.dispose();
    _rentController.dispose();
    super.dispose();
  }
}
