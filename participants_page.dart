import 'package:flutter/material.dart';
import 'api_service.dart';

class ParticipantsPage extends StatefulWidget {
  const ParticipantsPage({super.key});

  @override
  State<ParticipantsPage> createState() => _ParticipantsPageState();
}

class _ParticipantsPageState extends State<ParticipantsPage> {
  static const Color primaryColor = Color(0xFF8B1538);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color errorColor = Color(0xFFF44336);
  static const Color infoColor = Color(0xFF2196F3);

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _courseController = TextEditingController();
  final _contactController = TextEditingController();
  final _ageController = TextEditingController();
  final _yearLevelController = TextEditingController();
  
  List<Map<String, dynamic>> _participants = [];
  List<Map<String, dynamic>> _competitions = [];
  bool _isLoading = false;
  int? _editingId;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _loadParticipants();
    _loadCompetitions();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _courseController.dispose();
    _contactController.dispose();
    _ageController.dispose();
    _yearLevelController.dispose();
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

  Future<void> _loadParticipants() async {
    _safeSetState(() => _isLoading = true);
    try {
      final participants = await ApiService.getParticipants();
      if (mounted) {
        _safeSetState(() => _participants = participants);
      }
    } catch (e) {
      if (mounted) {
        _showMessage('Failed to load participants', isError: true);
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
    _courseController.clear();
    _contactController.clear();
    _ageController.clear();
    _yearLevelController.clear();
    _safeSetState(() {
      _editingId = null;
      _selectedCategory = null;
    });
  }

  void _editParticipant(Map<String, dynamic> participant) {
    _safeSetState(() {
      _editingId = participant['id'];
      _nameController.text = participant['name'] ?? '';
      _courseController.text = participant['course'] ?? participant['school'] ?? '';
      _contactController.text = participant['contact'] ?? '';
      _ageController.text = participant['age']?.toString() ?? '';
      _yearLevelController.text = participant['year_level'] ?? participant['grade_level'] ?? '';
      _selectedCategory = participant['category'];
    });
  }

  Future<void> _saveParticipant() async {
    if (!_formKey.currentState!.validate()) return;

    final participantData = {
      'name': _nameController.text.trim(),
      'course': _courseController.text.trim(),
      'category': _selectedCategory,
      'contact': _contactController.text.trim(),
      'age': _ageController.text.isNotEmpty ? int.tryParse(_ageController.text) : null,
      'year_level': _yearLevelController.text.trim(),
      'status': 'active',
    };

    try {
      bool success;
      if (_editingId != null) {
        success = await ApiService.updateParticipant(_editingId!, participantData);
      } else {
        success = await ApiService.addParticipant(participantData);
      }

      if (mounted) {
        if (success) {
          _showMessage('Participant ${_editingId != null ? 'updated' : 'added'} successfully!');
          _clearForm();
          _loadParticipants();
        } else {
          _showMessage('Failed to save participant. Please try again.', isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        _showMessage('An error occurred. Please try again.', isError: true);
      }
    }
  }

  Future<void> _deleteParticipant(int id, String name) async {
    final confirmed = await _showDeleteConfirmation(name);
    if (!confirmed || !mounted) return;

    try {
      final success = await ApiService.deleteParticipant(id);
      if (mounted) {
        if (success) {
          _showMessage('Participant deleted successfully!');
          _loadParticipants();
        } else {
          _showMessage('Failed to delete participant.', isError: true);
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
        title: const Text('Delete Participant'),
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
              'Manage Participants',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 20),
            _buildParticipantForm(),
            const SizedBox(height: 20),
            Expanded(child: _buildParticipantsList()),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantForm() {
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
                _editingId != null ? 'Edit Participant' : 'Add New Participant',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),
              // Row 1: Name and Year Level
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Participant Name*',
                        hintText: 'Enter participant name',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter participant name';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _yearLevelController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Year Level',
                        hintText: 'e.g., 1st Year, 2nd Year',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Row 2: Course and Competition Category
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _courseController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Course*',
                        hintText: 'e.g., Computer Science, Engineering',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter course';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Competition Category',
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
                          _selectedCategory = newValue;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Row 3: Contact and Age
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _contactController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Contact Information',
                        hintText: 'Phone/Email',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _ageController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Age',
                        hintText: 'Enter age',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: _saveParticipant,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(_editingId != null ? 'Update Participant' : 'Add Participant'),
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

  Widget _buildParticipantsList() {
    return Card(
      elevation: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'Existing Participants',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _participants.isEmpty
                    ? const Center(
                        child: Text(
                          'No participants found',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _participants.length,
                        itemBuilder: (context, index) {
                          final participant = _participants[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: primaryColor,
                                child: Text(
                                  (participant['name'] ?? 'P')[0].toUpperCase(),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text(participant['name'] ?? 'Unnamed Participant'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Course: ${participant['course'] ?? participant['school'] ?? 'Not specified'}'),
                                  if (participant['category'] != null && participant['category'].isNotEmpty)
                                    Text('Category: ${participant['category']}'),
                                  if (participant['age'] != null)
                                    Text('Age: ${participant['age']}'),
                                  if ((participant['year_level'] ?? participant['grade_level']) != null && 
                                      (participant['year_level'] ?? participant['grade_level']).toString().isNotEmpty)
                                    Text('Year Level: ${participant['year_level'] ?? participant['grade_level']}'),
                                  if (participant['contact'] != null && participant['contact'].isNotEmpty)
                                    Text('Contact: ${participant['contact']}'),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: infoColor),
                                    onPressed: () => _editParticipant(participant),
                                    tooltip: 'Edit Participant',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: errorColor),
                                    onPressed: () => _deleteParticipant(
                                      participant['id'],
                                      participant['name'] ?? 'Unnamed Participant',
                                    ),
                                    tooltip: 'Delete Participant',
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