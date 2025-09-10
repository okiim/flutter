import 'package:flutter/material.dart';
import 'api_service.dart';

class CompetitionsPage extends StatefulWidget {
  const CompetitionsPage({super.key});

  @override
  State<CompetitionsPage> createState() => _CompetitionsPageState();
}

class _CompetitionsPageState extends State<CompetitionsPage> {
  static const Color primaryColor = Color(0xFF8B1538);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color errorColor = Color(0xFFF44336);
  static const Color infoColor = Color(0xFF2196F3);

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _dateController = TextEditingController();
  
  List<Map<String, dynamic>> _competitions = [];
  List<Map<String, dynamic>> _eventTypes = [];
  bool _isLoading = false;
  int? _editingId;
  String? _selectedEventType;

  @override
  void initState() {
    super.initState();
    _loadCompetitions();
    _loadEventTypes();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  void _safeSetState(VoidCallback fn) {
    if (mounted) {
      setState(fn);
    }
  }

  Future<void> _loadEventTypes() async {
    try {
      final eventTypes = await ApiService.getData('event-types');
      if (mounted) {
        _safeSetState(() => _eventTypes = eventTypes);
      }
    } catch (e) {
      print('Error loading event types: $e');
      if (mounted) {
        _showMessage('Failed to load event types', isError: true);
      }
    }
  }

  Future<void> _loadCompetitions() async {
    _safeSetState(() => _isLoading = true);
    try {
      final competitions = await ApiService.getCompetitions();
      if (mounted) {
        _safeSetState(() => _competitions = competitions);
      }
    } catch (e) {
      if (mounted) {
        _showMessage('Failed to load competitions', isError: true);
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
    _dateController.clear();
    _safeSetState(() {
      _editingId = null;
      _selectedEventType = null;
    });
  }

  void _editCompetition(Map<String, dynamic> competition) {
    _safeSetState(() {
      _editingId = competition['id'];
      _nameController.text = competition['name'] ?? '';
      _descriptionController.text = competition['description'] ?? '';
      _dateController.text = competition['date'] ?? '';
      _selectedEventType = competition['event_type'];
    });
  }

  Future<void> _saveCompetition() async {
    if (!_formKey.currentState!.validate()) return;

    final competitionData = {
      'name': _nameController.text.trim(),
      'description': _descriptionController.text.trim(),
      'date': _dateController.text.trim(),
      'event_type': _selectedEventType,
    };

    try {
      bool success;
      if (_editingId != null) {
        success = await ApiService.updateCompetition(_editingId!, competitionData);
      } else {
        success = await ApiService.addCompetition(competitionData);
      }

      if (mounted) {
        if (success) {
          _showMessage('Competition ${_editingId != null ? 'updated' : 'added'} successfully!');
          _clearForm();
          _loadCompetitions();
        } else {
          _showMessage('Failed to save competition. Please try again.', isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        _showMessage('An error occurred. Please try again.', isError: true);
      }
    }
  }

  Future<void> _deleteCompetition(int id, String name) async {
    final confirmed = await _showDeleteConfirmation(name);
    if (!confirmed || !mounted) return;

    try {
      final success = await ApiService.deleteCompetition(id);
      if (mounted) {
        if (success) {
          _showMessage('Competition deleted successfully!');
          _loadCompetitions();
        } else {
          _showMessage('Failed to delete competition.', isError: true);
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
        title: const Text('Delete Competition'),
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
              'Manage Competitions',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 20),
            _buildCompetitionForm(),
            const SizedBox(height: 20),
            Expanded(child: _buildCompetitionsList()),
          ],
        ),
      ),
    );
  }

  Widget _buildCompetitionForm() {
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
                _editingId != null ? 'Edit Competition' : 'Add New Competition',
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
                  labelText: 'Competition Name*',
                  hintText: 'Enter competition name',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter competition name';
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
                  labelText: 'Description*',
                  hintText: 'Enter description',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _dateController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Date',
                        hintText: 'YYYY-MM-DD',
                      ),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (date != null) {
                          _dateController.text = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedEventType,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Event Type*',
                        hintText: 'Select event type',
                      ),
                      items: _eventTypes.map<DropdownMenuItem<String>>((eventType) {
                        return DropdownMenuItem<String>(
                          value: eventType['name'],
                          child: Text(
                            eventType['name'] ?? 'Unnamed Event Type',
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        _safeSetState(() {
                          _selectedEventType = newValue;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select an event type';
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
                    onPressed: _saveCompetition,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(_editingId != null ? 'Update Competition' : 'Add Competition'),
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

  Widget _buildCompetitionsList() {
    return Card(
      elevation: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'Existing Competitions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _competitions.isEmpty
                    ? const Center(
                        child: Text(
                          'No competitions found',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _competitions.length,
                        itemBuilder: (context, index) {
                          final competition = _competitions[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: primaryColor,
                                child: Icon(Icons.emoji_events, color: Colors.white),
                              ),
                              title: Text(competition['name'] ?? 'Unnamed Competition'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (competition['description'] != null)
                                    Text(competition['description']),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      if (competition['date'] != null)
                                        Text('Date: ${competition['date']}'),
                                      const SizedBox(width: 20),
                                      if (competition['event_type'] != null)
                                        Expanded(
                                          child: Text(
                                            'Type: ${competition['event_type']}',
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
                                    onPressed: () => _editCompetition(competition),
                                    tooltip: 'Edit Competition',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: errorColor),
                                    onPressed: () => _deleteCompetition(
                                      competition['id'],
                                      competition['name'] ?? 'Unnamed Competition',
                                    ),
                                    tooltip: 'Delete Competition',
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