import 'package:flutter/material.dart';
import 'api_service.dart';

class EventTypesPage extends StatefulWidget {
  const EventTypesPage({super.key});

  @override
  State<EventTypesPage> createState() => _EventTypesPageState();
}

class _EventTypesPageState extends State<EventTypesPage>
    with SingleTickerProviderStateMixin {
  // =============================================================================
  // CONSTANTS & CONTROLLERS
  // =============================================================================

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // =============================================================================
  // STATE VARIABLES
  // =============================================================================

  List<EventType> _eventTypes = [];
  bool _isLoading = false;
  bool _isSubmitting = false;
  int? _editingId;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadEventTypes();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // =============================================================================
  // INITIALIZATION
  // =============================================================================

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  // =============================================================================
  // DATA MANAGEMENT
  // =============================================================================

  Future<void> _loadEventTypes() async {
    if (!mounted) return;
    
    setState(() => _isLoading = true);
    
    try {
      final eventTypesData = await ApiService.getEventTypes();
      final eventTypes = eventTypesData
          .map((data) => EventType.fromJson(data))
          .toList();
      
      if (mounted) {
        setState(() {
          _eventTypes = eventTypes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        _showMessage('Failed to load event types: ${e.toString()}', isError: true);
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveEventType() async {
    if (!_formKey.currentState!.validate() || _isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      final eventTypeData = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
      };

      final success = _editingId != null
          ? await ApiService.updateEventType(_editingId!, eventTypeData)
          : await ApiService.addEventType(eventTypeData);

      if (mounted) {
        if (success) {
          _showMessage('Event type ${_editingId != null ? 'updated' : 'created'} successfully!');
          _clearForm();
          await _loadEventTypes();
        } else {
          _showMessage('Failed to save event type. Please try again.', isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        _showMessage('An error occurred: ${e.toString()}', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _deleteEventType(EventType eventType) async {
    final confirmed = await _showDeleteConfirmation(eventType.name);
    if (!confirmed || !mounted) return;

    try {
      final success = await ApiService.deleteEventType(eventType.id);
      if (mounted) {
        if (success) {
          _showMessage('Event type deleted successfully!');
          await _loadEventTypes();
        } else {
          _showMessage('Failed to delete event type.', isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        _showMessage('An error occurred: ${e.toString()}', isError: true);
      }
    }
  }

  // =============================================================================
  // UI HELPERS
  // =============================================================================

  void _clearForm() {
    _formKey.currentState?.reset();
    _nameController.clear();
    _descriptionController.clear();
    setState(() => _editingId = null);
  }

  void _editEventType(EventType eventType) {
    setState(() {
      _editingId = eventType.id;
      _nameController.text = eventType.name;
      _descriptionController.text = eventType.description;
    });
    
    // Scroll to form
    Scrollable.ensureVisible(
      context,
      alignment: 0.0,
      duration: const Duration(milliseconds: 300),
    );
  }

  List<EventType> get _filteredEventTypes {
    if (_searchQuery.isEmpty) return _eventTypes;
    
    return _eventTypes.where((eventType) {
      return eventType.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             eventType.description.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<bool> _showDeleteConfirmation(String name) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 12),
            Text('Delete Event Type'),
          ],
        ),
        content: Text('Are you sure you want to delete "$name"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    ) ?? false;
  }

  // =============================================================================
  // BUILD METHODS
  // =============================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPageHeader(),
              const SizedBox(height: 24),
              _buildEventTypeForm(),
              const SizedBox(height: 32),
              _buildEventTypesList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF8B1538).withOpacity(0.1),
            const Color(0xFF8B1538).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF8B1538).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.category, color: Color(0xFF8B1538), size: 32),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Event Types Management',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                    Text(
                      'Create and manage different types of events',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B1538).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_eventTypes.length} Event Types',
                  style: const TextStyle(
                    color: Color(0xFF8B1538),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              if (_editingId != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.edit, size: 12, color: Colors.orange),
                      const SizedBox(width: 4),
                      Text(
                        'Editing Mode',
                        style: TextStyle(
                          color: Colors.orange[700],
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEventTypeForm() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B1538).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _editingId != null ? Icons.edit : Icons.add,
                      color: const Color(0xFF8B1538),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _editingId != null ? 'Edit Event Type' : 'Create New Event Type',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF333333),
                          ),
                        ),
                        Text(
                          _editingId != null 
                              ? 'Update the event type information below'
                              : 'Fill in the details to create a new event type',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildFormFields(),
              const SizedBox(height: 24),
              _buildFormActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Event Type Name',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            hintText: 'e.g., Beauty Pageant, Talent Show, Academic Quiz',
            prefixIcon: Icon(Icons.title),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter an event type name';
            }
            if (value.trim().length < 2) {
              return 'Name must be at least 2 characters long';
            }
            return null;
          },
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 20),
        const Text(
          'Description',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _descriptionController,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Describe what this event type is about, its purpose, and any special characteristics...',
            prefixIcon: Icon(Icons.description),
            alignLabelWithHint: true,
          ),
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _saveEventType(),
        ),
      ],
    );
  }

  Widget _buildFormActions() {
    return Row(
      children: [
        ElevatedButton(
          onPressed: _isSubmitting ? null : _saveEventType,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_editingId != null ? Icons.update : Icons.add),
                    const SizedBox(width: 8),
                    Text(_editingId != null ? 'Update Event Type' : 'Create Event Type'),
                  ],
                ),
        ),
        if (_editingId != null) ...[
          const SizedBox(width: 16),
          OutlinedButton(
            onPressed: _isSubmitting ? null : _clearForm,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cancel_outlined),
                SizedBox(width: 8),
                Text('Cancel'),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEventTypesList() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildListHeader(),
          if (_isLoading) _buildLoadingIndicator(),
          if (!_isLoading && _filteredEventTypes.isEmpty) _buildEmptyState(),
          if (!_isLoading && _filteredEventTypes.isNotEmpty) _buildEventTypeItems(),
        ],
      ),
    );
  }

  Widget _buildListHeader() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.list, color: Color(0xFF8B1538)),
              SizedBox(width: 12),
              Text(
                'Existing Event Types',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
            ],
          ),
          if (_eventTypes.isNotEmpty) ...[
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                hintText: 'Search event types...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
                isDense: true,
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Padding(
      padding: EdgeInsets.all(48),
      child: Center(
        child: Column(
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B1538)),
            ),
            SizedBox(height: 16),
            Text(
              'Loading event types...',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(48),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Icon(
                Icons.category_outlined,
                size: 40,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _eventTypes.isEmpty ? 'No event types yet' : 'No matching event types',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _eventTypes.isEmpty 
                  ? 'Create your first event type using the form above'
                  : 'Try adjusting your search terms',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventTypeItems() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: _filteredEventTypes.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final eventType = _filteredEventTypes[index];
        final isEditing = _editingId == eventType.id;
        
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isEditing ? const Color(0xFF8B1538).withOpacity(0.05) : Colors.white,
            border: Border.all(
              color: isEditing ? const Color(0xFF8B1538) : Colors.grey[200]!,
              width: isEditing ? 2 : 1,
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF8B1538).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.category,
                color: Color(0xFF8B1538),
              ),
            ),
            title: Text(
              eventType.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF333333),
              ),
            ),
            subtitle: eventType.description.isNotEmpty
                ? Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      eventType.description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  )
                : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => _editEventType(eventType),
                  icon: Icon(
                    Icons.edit,
                    color: isEditing ? const Color(0xFF8B1538) : Colors.blue,
                  ),
                  tooltip: 'Edit Event Type',
                ),
                IconButton(
                  onPressed: () => _deleteEventType(eventType),
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: 'Delete Event Type',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// =============================================================================
// DATA MODELS
// =============================================================================

class EventType {
  final int id;
  final String name;
  final String description;

  const EventType({
    required this.id,
    required this.name,
    required this.description,
  });

  factory EventType.fromJson(Map<String, dynamic> json) {
    return EventType(
      id: json['id'] ?? 0,
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
    };
  }
}
