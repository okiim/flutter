import 'package:flutter/material.dart';
import 'api_service.dart';

class EventTypesPage extends StatefulWidget {
  const EventTypesPage({super.key});

  @override
  State<EventTypesPage> createState() => _EventTypesPageState();
}

class _EventTypesPageState extends State<EventTypesPage> {
  static const Color primaryColor = Color(0xFF8B1538);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color errorColor = Color(0xFFF44336);
  static const Color infoColor = Color(0xFF2196F3);

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
 
  
  List<Map<String, dynamic>> _eventTypes = [];
  bool _isLoading = false;
  int? _editingId;

  @override
  void initState() {
    super.initState();
    print('EventTypesPage initialized');
    _loadEventTypes();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _safeSetState(VoidCallback fn) {
    if (mounted) {
      setState(fn);
    }
  }

  Future<void> _loadEventTypes() async {
    print('Loading event types...');
    _safeSetState(() => _isLoading = true);
    
    try {
      final eventTypes = await ApiService.getData('event-types');
      print('Loaded ${eventTypes.length} event types');
      
      if (mounted) {
        _safeSetState(() => _eventTypes = eventTypes);
      }
    } catch (e) {
      print('Error loading event types: $e');
      if (mounted) {
        _showMessage('Failed to load event types', isError: true);
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
    _safeSetState(() => _editingId = null);
  }

  void _editEventType(Map<String, dynamic> eventType) {
    _safeSetState(() {
      _editingId = eventType['id'];
      _nameController.text = eventType['name'] ?? '';
      _descriptionController.text = eventType['description'] ?? '';
    
    });
  }

  Future<void> _saveEventType() async {
    if (!_formKey.currentState!.validate()) return;

    final eventTypeData = {
      'name': _nameController.text.trim(),
      'description': _descriptionController.text.trim(),
     
    };

    print('Saving event type: $eventTypeData');

    try {
      bool success;
      if (_editingId != null) {
        success = await ApiService.putData('event-types', _editingId!, eventTypeData);
      } else {
        success = await ApiService.postData('event-types', eventTypeData);
      }

      if (mounted) {
        if (success) {
          _showMessage('Event type ${_editingId != null ? 'updated' : 'added'} successfully!');
          _clearForm();
          _loadEventTypes();
        } else {
          _showMessage('Failed to save event type. Please try again.', isError: true);
        }
      }
    } catch (e) {
      print('Error saving event type: $e');
      if (mounted) {
        _showMessage('An error occurred. Please try again.', isError: true);
      }
    }
  }

  Future<void> _deleteEventType(int id, String name) async {
    final confirmed = await _showDeleteConfirmation(name);
    if (!confirmed || !mounted) return;

    try {
      final success = await ApiService.deleteData('event-types', id);
      
      if (mounted) {
        if (success) {
          _showMessage('Event type deleted successfully!');
          _loadEventTypes();
        } else {
          _showMessage('Failed to delete event type.', isError: true);
        }
      }
    } catch (e) {
      print('Error deleting event type: $e');
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
        title: const Text('Delete Event Type'),
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
    print('Building EventTypesPage widget');
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildEventTypeForm(),
              const SizedBox(height: 30),
              SizedBox(
                height: 400,
                child: _buildEventTypesList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventTypeForm() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryColor, width: 2),
      ),
      padding: const EdgeInsets.all(30),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _editingId != null ? 'Edit Event Type' : 'Create New Event Type',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 30),
            
            // Event Type Name
            const Text(
              'Event Type Name:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameController,
              style: const TextStyle(fontSize: 16),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'e.g., Beauty Pageant, Talent Show, etc.',
                hintStyle: TextStyle(color: Colors.grey),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                filled: true,
                fillColor: Colors.white,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter event type name';
                }
                return null;
              },
            ),
            const SizedBox(height: 25),
            
            // Description
            const Text(
              'Description:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              maxLines: 5,
              style: const TextStyle(fontSize: 16),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Describe what this event type is about...',
                hintStyle: TextStyle(color: Colors.grey),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                alignLabelWithHint: true,
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 25),
            
           
      
            const SizedBox(height: 30),
            
            // Action Buttons
            Row(
              children: [
                ElevatedButton(
                  onPressed: _saveEventType,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    _editingId != null ? 'Update Event Type' : 'Create Event Type',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                if (_editingId != null) ...[
                  const SizedBox(width: 15),
                  OutlinedButton(
                    onPressed: _clearForm,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryColor,
                      side: const BorderSide(color: primaryColor, width: 2),
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventTypesList() {
    return Card(
      elevation: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'Existing Event Types',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                    ),
                  )
                : _eventTypes.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.category, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No event types found',
                              style: TextStyle(color: Colors.grey, fontSize: 16),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Add your first event type above',
                              style: TextStyle(color: Colors.grey, fontSize: 14),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _eventTypes.length,
                        itemBuilder: (context, index) {
                          final eventType = _eventTypes[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: primaryColor,
                                child: Icon(Icons.category, color: Colors.white),
                              ),
                              title: Text(
                                eventType['name'] ?? 'Unnamed Event Type',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (eventType['description'] != null && 
                                      eventType['description'].toString().isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(eventType['description']),
                                    ),
                                 
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: infoColor),
                                    onPressed: () => _editEventType(eventType),
                                    tooltip: 'Edit Event Type',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: errorColor),
                                    onPressed: () => _deleteEventType(
                                      eventType['id'],
                                      eventType['name'] ?? 'Unnamed Event Type',
                                    ),
                                    tooltip: 'Delete Event Type',
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