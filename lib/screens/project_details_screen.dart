import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_services.dart';
import '../services/local_storage.dart';

class ProjectDetailsScreen extends StatefulWidget {
  final Project project;

  const ProjectDetailsScreen({super.key, required this.project});

  @override
  State<ProjectDetailsScreen> createState() => _ProjectDetailsScreenState();
}

class _ProjectDetailsScreenState extends State<ProjectDetailsScreen> {
  List<ProjectItem> _items = [];
  bool _isLoading = true;
  List<String> _itemSuggestions = [];

  @override
  void initState() {
    super.initState();
    _loadItems();
    _loadSuggestions();
  }

  Future<void> _loadItems() async {
    try {
      if (widget.project.id != null) {
        final items = await ApiService.getProjectItems(widget.project.id!);
        setState(() {
          _items = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      _showErrorSnackBar('Failed to load items: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadSuggestions() async {
    final suggestions = await LocalStorageService.getItemSuggestions();
    setState(() {
      _itemSuggestions = suggestions;
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _addItem() async {
    final result = await showDialog<ProjectItem>(
      context: context,
      builder: (context) => AddItemDialog(suggestions: _itemSuggestions),
    );

    if (result != null && widget.project.id != null) {
      try {
        setState(() {
          _isLoading = true;
        });
        await ApiService.addProjectItem(widget.project.id!, result);
        await LocalStorageService.addItemSuggestion(result.item);
        await _loadItems();
        await _loadSuggestions();
      } catch (e) {
        _showErrorSnackBar('Failed to add item: $e');
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteItem(ProjectItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Are you sure you want to delete "${item.item}"?'),
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

    if (confirmed == true && item.id != null && widget.project.id != null) {
      try {
        setState(() {
          _isLoading = true;
        });
        await ApiService.deleteProjectItem(widget.project.id!, item.id!);
        await _loadItems();
      } catch (e) {
        _showErrorSnackBar('Failed to delete item: $e');
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.project.title),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Project Summary
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.project.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Status: ${widget.project.status.name}'),
                  Text('Start Date: ${_formatDate(widget.project.startDate)}'),
                  Text('End Date: ${_formatDate(widget.project.endDate)}'),
                  Text(
                    'Total Cost: Rs ${widget.project.cost.toStringAsFixed(2)}',
                  ),
                ],
              ),
            ),
          ),
          // Items List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty
                ? const Center(
                    child: Text(
                      'No items found.\nTap the + button to add one.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return ItemCard(
                        item: item,
                        onDelete: () => _deleteItem(item),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addItem,
        child: const Icon(Icons.add),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

class ItemCard extends StatelessWidget {
  final ProjectItem item;
  final VoidCallback onDelete;

  const ItemCard({super.key, required this.item, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  item.item,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                  onPressed: onDelete,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Date: ${_formatDate(item.date)}'),
            Text('Rate: Rs ${item.rate.toStringAsFixed(2)}'),
            Text('Quantity: ${item.quantity}'),
            Text('Rent: Rs ${item.rent.toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            Text(
              'Total Amount: Rs ${item.totalAmount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
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

class AddItemDialog extends StatefulWidget {
  final List<String> suggestions;

  const AddItemDialog({super.key, required this.suggestions});

  @override
  State<AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<AddItemDialog> {
  final _formKey = GlobalKey<FormState>();
  final _itemController = TextEditingController();
  final _rateController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _rentController = TextEditingController(text: '0.0');
  DateTime _date = DateTime.now();
  double _totalAmount = 0.0;

  @override
  void initState() {
    super.initState();
    _calculateTotal();
  }

  void _calculateTotal() {
    final rate = double.tryParse(_rateController.text) ?? 0;
    final quantity = int.tryParse(_quantityController.text) ?? 0;
    final rent = double.tryParse(_rentController.text) ?? 0;
    final total = (rate * quantity) + rent;

    if (_formKey.currentState != null) {
      setState(() {
        _totalAmount = total;
      });
    }
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

  @override
  Widget build(BuildContext context) {
    //  final rate = double.tryParse(_rateController.text) ?? 0;
    //  final quantity = int.tryParse(_quantityController.text) ?? 0;
    //  final rent = double.tryParse(_rentController.text) ?? 0;
    //  final total = (rate * quantity) + rent;

    return AlertDialog(
      title: const Text('Add New Item'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Autocomplete<String>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    return const Iterable<String>.empty();
                  }
                  return widget.suggestions.where((String option) {
                    return option.toLowerCase().contains(
                      textEditingValue.text.toLowerCase(),
                    );
                  });
                },
                onSelected: (String selection) {
                  _itemController.text = selection;
                },
                fieldViewBuilder:
                    (
                      context,
                      textEditingController,
                      focusNode,
                      onFieldSubmitted,
                    ) {
                      textEditingController.text = _itemController.text;
                      return TextFormField(
                        controller: textEditingController,
                        focusNode: focusNode,
                        decoration: const InputDecoration(
                          labelText: 'Item Name',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter an item name';
                          }
                          return null;
                        },
                        onChanged: (value) {
                          _itemController.text = value;
                        },
                      );
                    },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Date'),
                        TextButton(
                          onPressed: _selectDate,
                          child: Text(_formatDate(_date)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _rateController,
                decoration: const InputDecoration(labelText: 'Rate'),
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
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(labelText: 'Quantity'),
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
              TextFormField(
                controller: _rentController,
                decoration: const InputDecoration(labelText: 'Rent'),
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
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Amount:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Rs ${_totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
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
              final item = ProjectItem(
                date: _date,
                item: _itemController.text,
                rate: double.parse(_rateController.text),
                quantity: int.parse(_quantityController.text),
                rent: double.parse(_rentController.text),
                totalAmount: _totalAmount,
              );
              Navigator.of(context).pop(item);
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

  @override
  void dispose() {
    _itemController.dispose();
    _rateController.dispose();
    _quantityController.dispose();
    _rentController.dispose();
    super.dispose();
  }
}
