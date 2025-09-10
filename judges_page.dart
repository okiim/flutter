import 'package:flutter/material.dart';
import 'api_service.dart';

class JudgesPage extends StatefulWidget {
  const JudgesPage({super.key});

  @override
  State<JudgesPage> createState() => _JudgesPageState();
}

class _JudgesPageState extends State<JudgesPage> {
  static const Color primaryColor = Color(0xFF8B1538);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color errorColor = Color(0xFFF44336);
  static const Color infoColor = Color(0xFF2196F3);

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _expertiseController = TextEditingController();
  final _phoneController = TextEditingController();
  
  List<Map<String, dynamic>> _judges = [];
  bool _isLoading = false;
  int? _editingId;

  @override
  void initState() {
    super.initState();
    print('JudgesPage initialized');
    _loadJudges();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _expertiseController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _safeSetState(VoidCallback fn) {
    if (mounted) {
      setState(fn);
    }
  }

  Future<void> _loadJudges() async {
    print('Loading judges...');
    _safeSetState(() => _isLoading = true);
    try {
      final judges = await ApiService.getJudges();
      print('Loaded ${judges.length} judges');
      if (mounted) {
        _safeSetState(() => _judges = judges);
      }
    } catch (e) {
      print('Error loading judges: $e');
      if (mounted) {
        _showMessage('Failed to load judges', isError: true);
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
    _emailController.clear();
    _expertiseController.clear();
    _phoneController.clear();
    _safeSetState(() => _editingId = null);
  }

  void _editJudge(Map<String, dynamic> judge) {
    print('Editing judge: ${judge['name']}');
    _safeSetState(() {
      _editingId = judge['id'];
      _nameController.text = judge['name'] ?? '';
      _emailController.text = judge['email'] ?? '';
      _expertiseController.text = judge['expertise'] ?? '';
      _phoneController.text = judge['phone'] ?? '';
    });
  }

  Future<void> _saveJudge() async {
    if (!_formKey.currentState!.validate()) return;

    final judgeData = {
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'expertise': _expertiseController.text.trim(),
      'phone': _phoneController.text.trim(),
      'status': 'active',
    };

    print('Saving judge: $judgeData');

    try {
      bool success;
      if (_editingId != null) {
        success = await ApiService.updateJudge(_editingId!, judgeData);
        print('Update result: $success');
      } else {
        success = await ApiService.addJudge(judgeData);
        print('Add result: $success');
      }

      if (mounted) {
        if (success) {
          _showMessage('Judge ${_editingId != null ? 'updated' : 'added'} successfully!');
          _clearForm();
          _loadJudges();
        } else {
          _showMessage('Failed to save judge. Please try again.', isError: true);
        }
      }
    } catch (e) {
      print('Error saving judge: $e');
      if (mounted) {
        _showMessage('An error occurred. Please try again.', isError: true);
      }
    }
  }

  Future<void> _deleteJudge(int id, String name) async {
    final confirmed = await _showDeleteConfirmation(name);
    if (!confirmed || !mounted) return;

    print('Deleting judge: $name (ID: $id)');

    try {
      final success = await ApiService.deleteJudge(id);
      print('Delete result: $success');
      
      if (mounted) {
        if (success) {
          _showMessage('Judge deleted successfully!');
          _loadJudges();
        } else {
          _showMessage('Failed to delete judge.', isError: true);
        }
      }
    } catch (e) {
      print('Error deleting judge: $e');
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
        title: const Text('Delete Judge'),
        content: Text('Are you sure you want to delete "$name"?\n\nThis action cannot be undone.'),
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
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print('Building JudgesPage widget');
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPageHeader(),
            const SizedBox(height: 20),
            _buildJudgeForm(),
            const SizedBox(height: 20),
            Expanded(child: _buildJudgesList()),
          ],
        ),
      ),
    );
  }

  Widget _buildPageHeader() {
    return Row(
      children: [
        const Icon(Icons.person, size: 32, color: primaryColor),
        const SizedBox(width: 12),
        const Text(
          'Manage Judges',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),
        const Spacer(),
        Text(
          '${_judges.length} ${_judges.length == 1 ? 'judge' : 'judges'}',
          style: const TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildJudgeForm() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _editingId != null ? Icons.edit : Icons.add,
                    color: primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _editingId != null ? 'Edit Judge' : 'Add New Judge',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildFormFields(),
              const SizedBox(height: 20),
              _buildFormButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormFields() {
    return Column(
      children: [
        // Name field
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Judge Name*',
            hintText: 'Enter judge full name',
            prefixIcon: Icon(Icons.person_outline),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter judge name';
            }
            if (value.trim().length < 2) {
              return 'Name must be at least 2 characters';
            }
            return null;
          },
        ),
        const SizedBox(height: 15),
        
        // Email field
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Email Address*',
            hintText: 'Enter email address',
            prefixIcon: Icon(Icons.email_outlined),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter email address';
            }
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
              return 'Please enter a valid email address';
            }
            return null;
          },
        ),
        const SizedBox(height: 15),
        
        // Row with expertise and phone
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _expertiseController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Area of Expertise',
                  hintText: 'e.g., Mathematics, Science',
                  prefixIcon: Icon(Icons.school_outlined),
                ),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Phone Number',
                  hintText: 'Enter phone number',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFormButtons() {
    return Row(
      children: [
        ElevatedButton.icon(
          onPressed: _saveJudge,
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          icon: Icon(_editingId != null ? Icons.update : Icons.add),
          label: Text(_editingId != null ? 'Update Judge' : 'Add Judge'),
        ),
        if (_editingId != null) ...[
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: _clearForm,
            icon: const Icon(Icons.cancel_outlined),
            label: const Text('Cancel'),
          ),
        ],
        const Spacer(),
        if (_editingId != null)
          Text(
            'Editing: ${_nameController.text}',
            style: const TextStyle(
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
          ),
      ],
    );
  }

  Widget _buildJudgesList() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Icon(Icons.list, color: primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Existing Judges',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (_isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                        ),
                        SizedBox(height: 16),
                        Text('Loading judges...'),
                      ],
                    ),
                  )
                : _judges.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_off, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No judges found',
                              style: TextStyle(color: Colors.grey, fontSize: 16),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Add your first judge using the form above',
                              style: TextStyle(color: Colors.grey, fontSize: 14),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _judges.length,
                        itemBuilder: (context, index) {
                          final judge = _judges[index];
                          return _buildJudgeListItem(judge, index);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildJudgeListItem(Map<String, dynamic> judge, int index) {
    final isActive = judge['status'] == 'active';
    final isCurrentlyEditing = _editingId == judge['id'];
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: isCurrentlyEditing ? 4 : 1,
      color: isCurrentlyEditing ? primaryColor.withOpacity(0.05) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: isCurrentlyEditing 
            ? const BorderSide(color: primaryColor, width: 2)
            : BorderSide.none,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: isActive ? primaryColor : Colors.grey,
          radius: 25,
          child: Text(
            (judge['name'] ?? 'J')[0].toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                judge['name'] ?? 'Unnamed Judge',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isActive ? Colors.black : Colors.grey,
                ),
              ),
            ),
            if (!isActive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Inactive',
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.email, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    judge['email'] ?? 'No email',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
            if (judge['expertise'] != null && judge['expertise'].toString().isNotEmpty) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  const Icon(Icons.school, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Expertise: ${judge['expertise']}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ],
            if (judge['phone'] != null && judge['phone'].toString().isNotEmpty) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  const Icon(Icons.phone, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      judge['phone'],
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                Icons.edit,
                color: isCurrentlyEditing ? primaryColor : infoColor,
              ),
              onPressed: () => _editJudge(judge),
              tooltip: 'Edit Judge',
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: errorColor),
              onPressed: () => _deleteJudge(
                judge['id'],
                judge['name'] ?? 'Unnamed Judge',
              ),
              tooltip: 'Delete Judge',
            ),
          ],
        ),
      ),
    );
  }
}