import 'package:flutter/material.dart';
import 'api_service.dart';

class CriteriaTemplatesPage extends StatefulWidget {
  const CriteriaTemplatesPage({super.key});

  @override
  State<CriteriaTemplatesPage> createState() => _CriteriaTemplatesPageState();
}

class _CriteriaTemplatesPageState extends State<CriteriaTemplatesPage> {
  static const Color primaryColor = Color(0xFF8B1538);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color errorColor = Color(0xFFF44336);
  static const Color infoColor = Color(0xFF2196F3);

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _maxScoreController = TextEditingController();
  
  List<Map<String, dynamic>> _criteria = [];
  List<Map<String, dynamic>> _competitions = [];
  bool _isLoading = false;
  int? _editingId;
  String? _selectedCompetition;

  @override
  void initState() {
    super.initState();
    _loadCriteria();
    _loadCompetitions();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _maxScoreController.dispose();
    super.dispose();
  }

  void _safeSetState(VoidCallback fn) {
    if (mounted) {
      setState(fn);
    }
  }

  Future<void> _loadCompetitions() async {
    try {
      final competitions = await ApiService.getData('competitions');
      if (mounted) {
        _safeSetState(() => _competitions = competitions);
      }
    } catch (e) {
      print('Error loading competitions: $e');
      if (mounted) {
        _showMessage('Failed to load competitions', isError: true);
      }
    }
  }

  Future<void> _loadCriteria() async {
    _safeSetState(() => _isLoading = true);
    try {
      final criteria = await ApiService.getData('criteria');
      if (mounted) {
        _safeSetState(() => _criteria = criteria);
      }
    } catch (e) {
      if (mounted) {
        _showMessage('Failed to load criteria', isError: true);
      }
    } finally {
      if (mounted) {
        _safeSetState(() => _isLoading = false);
      }
    }
  }

  void _clearForm() {
    _formKey.currentState?.reset();
    _nameController.clear();
    _descriptionController.clear();
    _maxScoreController.clear();
    _safeSetState(() {
      _editingId = null;
      _selectedCompetition = null;
    });
  }

  void _editCriteria(Map<String, dynamic> criteria) {
    _safeSetState(() {
      _editingId = criteria['id'];
      _nameController.text = criteria['name'] ?? '';
      _descriptionController.text = criteria['description'] ?? '';
      _maxScoreController.text = criteria['max_score']?.toString() ?? '';
      _selectedCompetition = criteria['competition'];
    });
  }

  Future<void> _saveCriteria() async {
    if (!_formKey.currentState!.validate()) return;

    final criteriaData = {
      'name': _nameController.text.trim(),
      'description': _descriptionController.text.trim(),
      'max_score': int.tryParse(_maxScoreController.text) ?? 100,
      'competition': _selectedCompetition,
    };

    try {
      bool success;
      if (_editingId != null) {
        success = await ApiService.putData('criteria', _editingId!, criteriaData);
      } else {
        success = await ApiService.postData('criteria', criteriaData);
      }

      if (mounted) {
        if (success) {
          _showMessage('Criteria ${_editingId != null ? 'updated' : 'added'} successfully!');
          _clearForm();
          _loadCriteria();
        } else {
          _showMessage('Failed to save criteria. Please try again.', isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        _showMessage('An error occurred. Please try again.', isError: true);
      }
    }
  }

  Future<void> _deleteCriteria(int id, String name) async {
    final confirmed = await _showDeleteConfirmation(name);
    if (!confirmed || !mounted) return;

    try {
      final success = await ApiService.deleteData('criteria', id);
      if (mounted) {
        if (success) {
          _showMessage('Criteria deleted successfully!');
          _loadCriteria();
        } else {
          _showMessage('Failed to delete criteria.', isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        _showMessage('An error occurred. Please try again.', isError: true);
      }
    }
  }

  Future<bool> _showDeleteConfirmation(String name) async {
    if (!mounted) return false;
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Criteria'),
        content: Text('Are you sure you want to delete "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: errorColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    ) ?? false;
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? errorColor : successColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Manage Criteria Templates',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 20),
            _buildCriteriaForm(),
            const SizedBox(height: 20),
            Expanded(child: _buildCriteriaList()),
          ],
        ),
      ),
    );
  }

  Widget _buildCriteriaForm() {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _editingId != null ? 'Edit Criteria' : 'Add New Criteria',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Criteria Name*',
                  hintText: 'e.g., Accuracy, Creativity, Presentation',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter criteria name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Description',
                  hintText: 'Describe what this criteria measures',
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _maxScoreController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Max Score*',
                        hintText: 'Enter maximum score (limit: 100)',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter max score';
                        }
                        final score = int.tryParse(value);
                        if (score == null) {
                          return 'Please enter a valid number';
                        }
                        if (score <= 0) {
                          return 'Score must be greater than 0';
                        }
                        if (score > 100) {
                          return 'Score cannot exceed 100 points';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedCompetition,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Competition*',
                        hintText: 'Select competition',
                      ),
                      items: _competitions.map<DropdownMenuItem<String>>((competition) {
                        return DropdownMenuItem<String>(
                          value: competition['name'],
                          child: Text(
                            competition['name'] ?? 'Unnamed Competition',
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        _safeSetState(() {
                          _selectedCompetition = newValue;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a competition';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: _saveCriteria,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(_editingId != null ? 'Update Criteria' : 'Add Criteria'),
                  ),
                  if (_editingId != null) ...[
                    const SizedBox(width: 10),
                    TextButton(
                      onPressed: _clearForm,
                      child: const Text('Cancel'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCriteriaList() {
    return Card(
      elevation: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'Existing Criteria Templates',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _criteria.isEmpty
                    ? const Center(
                        child: Text(
                          'No criteria templates found',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _criteria.length,
                        itemBuilder: (context, index) {
                          final criteria = _criteria[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: primaryColor,
                                child: Icon(Icons.rule, color: Colors.white),
                              ),
                              title: Text(criteria['name'] ?? 'Unnamed Criteria'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (criteria['description'] != null && criteria['description'].toString().isNotEmpty)
                                    Text(criteria['description']),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      if (criteria['max_score'] != null)
                                        Text('Max Score: ${criteria['max_score']}'),
                                      const SizedBox(width: 20),
                                      if (criteria['competition'] != null)
                                        Expanded(
                                          child: Text(
                                            'Competition: ${criteria['competition']}',
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: infoColor),
                                    onPressed: () => _editCriteria(criteria),
                                    tooltip: 'Edit Criteria',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: errorColor),
                                    onPressed: () => _deleteCriteria(
                                      criteria['id'],
                                      criteria['name'] ?? 'Unnamed Criteria',
                                    ),
                                    tooltip: 'Delete Criteria',
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}