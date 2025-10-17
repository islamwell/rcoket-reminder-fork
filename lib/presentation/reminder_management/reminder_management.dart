import 'dart:async';
import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../create_reminder/create_reminder.dart';
import '../common/widgets/notification_status_banner.dart';
import 'widgets/countdown_display_widget.dart';

class ReminderManagement extends StatefulWidget {
  const ReminderManagement({super.key});

  @override
  State<ReminderManagement> createState() => _ReminderManagementState();
}

class _ReminderManagementState extends State<ReminderManagement> {
  final TextEditingController _searchController = TextEditingController();

  // Simple state management
  String _searchQuery = '';
  bool _isActiveExpanded = true;
  bool _isPausedExpanded = true;
  bool _isCompletedExpanded = false;

  // Reminders data
  List<Map<String, dynamic>> _allReminders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReminders();
    _initializeNotificationService();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadReminders() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final reminders = await ReminderStorageService.instance.getReminders();

      if (!mounted) return;

      setState(() {
        _allReminders = reminders;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading reminders: $e')),
        );
      }
    }
  }







  Future<void> _initializeNotificationService() async {
    try {
      await NotificationService.instance.initialize(context);
      print('Notification service initialized successfully');

      // Set up a timer to refresh the reminder list periodically
      Timer.periodic(Duration(seconds: 30), (timer) {
        if (mounted) {
          _loadReminders();
        } else {
          timer.cancel();
        }
      });
    } catch (e) {
      print('Error initializing notification service: $e');
    }
  }

  List<Map<String, dynamic>> get _filteredReminders {
    if (_searchQuery.isEmpty) {
      return _allReminders;
    }

    final query = _searchQuery.toLowerCase();
    return _allReminders.where((reminder) {
      final title = (reminder["title"] as String? ?? "").toLowerCase();
      final category = (reminder["category"] as String? ?? "").toLowerCase();
      final description =
          (reminder["description"] as String? ?? "").toLowerCase();

      return title.contains(query) ||
          category.contains(query) ||
          description.contains(query);
    }).toList();
  }

  List<Map<String, dynamic>> get _activeReminders {
    final activeList = _filteredReminders
        .where((r) => (r["status"] as String? ?? "active") == "active")
        .toList();
    
    // Sort by most recent first (by creation date)
    activeList.sort((a, b) {
      final aCreated = DateTime.tryParse(a['createdAt'] ?? '') ?? DateTime.now();
      final bCreated = DateTime.tryParse(b['createdAt'] ?? '') ?? DateTime.now();
      return bCreated.compareTo(aCreated); // Most recent first
    });
    
    return activeList;
  }

  List<Map<String, dynamic>> get _pausedReminders {
    final pausedList = _filteredReminders
        .where((r) => (r["status"] as String? ?? "active") == "paused")
        .toList();
    
    // Sort by most recent first (by creation date)
    pausedList.sort((a, b) {
      final aCreated = DateTime.tryParse(a['createdAt'] ?? '') ?? DateTime.now();
      final bCreated = DateTime.tryParse(b['createdAt'] ?? '') ?? DateTime.now();
      return bCreated.compareTo(aCreated); // Most recent first
    });
    
    return pausedList;
  }

  List<Map<String, dynamic>> get _snoozedReminders {
    final snoozedList = _filteredReminders
        .where((r) => (r["status"] as String? ?? "active") == "snoozed")
        .toList();
    
    // Sort by most recent first (by snooze date, then creation date)
    snoozedList.sort((a, b) {
      final aSnoozed = DateTime.tryParse(a['snoozedAt'] ?? '') ?? 
                      DateTime.tryParse(a['createdAt'] ?? '') ?? DateTime.now();
      final bSnoozed = DateTime.tryParse(b['snoozedAt'] ?? '') ?? 
                      DateTime.tryParse(b['createdAt'] ?? '') ?? DateTime.now();
      return bSnoozed.compareTo(aSnoozed); // Most recent first
    });
    
    return snoozedList;
  }

  List<Map<String, dynamic>> get _completedReminders {
    final completedList = _filteredReminders
        .where((r) => (r["status"] as String? ?? "active") == "completed")
        .toList();
    
    // Sort by most recent first (by completion date, then creation date)
    completedList.sort((a, b) {
      final aCompleted = DateTime.tryParse(a['completedAt'] ?? a['lastCompleted'] ?? '') ?? 
                        DateTime.tryParse(a['createdAt'] ?? '') ?? DateTime.now();
      final bCompleted = DateTime.tryParse(b['completedAt'] ?? b['lastCompleted'] ?? '') ?? 
                        DateTime.tryParse(b['createdAt'] ?? '') ?? DateTime.now();
      return bCompleted.compareTo(aCompleted); // Most recent first
    });
    
    return completedList;
  }

  int get _activeReminderCount {
    return _allReminders
        .where((r) => (r["status"] as String? ?? "active") == "active")
        .length;
  }

  Future<void> _handleRefresh() async {
    await _loadReminders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Reminders',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey[900],
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/create-reminder'),
            icon: Icon(Icons.add, color: Colors.grey[800]),
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            icon: Icon(Icons.more_vert, color: Colors.grey[800]),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings, size: 20, color: Colors.grey[800]),
                    SizedBox(width: 12),
                    Text('Settings', style: TextStyle(color: Colors.grey[800])),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          NotificationStatusBanner(),
          // Search bar
          Padding(
            padding: EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (query) => setState(() => _searchQuery = query),
              decoration: InputDecoration(
                hintText: 'Search reminders...',
                hintStyle: TextStyle(color: Colors.grey[600]),
                prefixIcon: Icon(Icons.search, color: Colors.grey[700]),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                        icon: Icon(Icons.clear, color: Colors.grey[700]),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppTheme.lightTheme.colorScheme.primary),
                ),
              ),
              style: TextStyle(color: Colors.grey[900]),
            ),
          ),
          // Content
          Expanded(
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'Loading reminders...',
                          style: TextStyle(color: Colors.grey[800]),
                        ),
                      ],
                    ),
                  )
                : _allReminders.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.notifications_none, size: 64, color: Colors.grey[600]),
                            SizedBox(height: 16),
                            Text(
                              'No reminders yet',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Create your first reminder to get started',
                              style: TextStyle(color: Colors.grey[600]),
                            ),

                          ],
                        ),
                      )
                    : ListView(
                        padding: EdgeInsets.only(bottom: 20),
                        children: [
                          if (_activeReminders.isNotEmpty)
                            _buildSimpleSection('Active', _activeReminders, Colors.green),
                          if (_pausedReminders.isNotEmpty)
                            _buildSimpleSection('Paused', _pausedReminders, Colors.orange),
                          if (_snoozedReminders.isNotEmpty)
                            _buildSimpleSection('Snoozed', _snoozedReminders, Colors.purple),
                          if (_completedReminders.isNotEmpty)
                            _buildSimpleSection('Completed', _completedReminders, Colors.blue),
                        ],
                      ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/create-reminder'),
        child: Icon(Icons.add),
        backgroundColor: AppTheme.lightTheme.colorScheme.primary,
      ),
    );
  }

  Widget _buildSimpleSection(String title, List<Map<String, dynamic>> reminders, Color color) {
    return Card(
      margin: EdgeInsets.all(8),
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        initiallyExpanded: title == 'Active',
        title: Text(
          '$title (${reminders.length})',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey[900],
            fontSize: 16,
          ),
        ),
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            title == 'Active' ? Icons.play_circle : 
            title == 'Paused' ? Icons.pause_circle : 
            title == 'Snoozed' ? Icons.snooze : Icons.check_circle,
            color: color,
            size: 24,
          ),
        ),
        children: reminders.asMap().entries.map((entry) {
          final index = entry.key;
          final reminder = entry.value;
          final isEven = index % 2 == 0;
          
          return Container(
            decoration: BoxDecoration(
              color: isEven 
                ? Colors.grey[50] 
                : Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey[200]!,
                  width: 0.5,
                ),
              ),
            ),
            child: ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              title: Text(
                reminder['title'] ?? 'Unknown',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[900],
                  fontSize: 16,
                ),
              ),
              subtitle: Padding(
                padding: EdgeInsets.only(top: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: color.withOpacity(0.3)),
                          ),
                          child: Text(
                            reminder['category'] ?? 'Unknown',
                            style: TextStyle(
                              color: color,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.withOpacity(0.3)),
                          ),
                          child: Text(
                            _getFrequencyDisplayText(reminder['frequency']),
                            style: TextStyle(
                              color: Colors.blue[700],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 16,
                          color: color,
                        ),
                        SizedBox(width: 4),
                        CountdownDisplayWidget(
                          reminder: reminder,
                          textStyle: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              trailing: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: PopupMenuButton(
                  icon: Icon(Icons.more_vert, color: Colors.grey[700]),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 4,
            itemBuilder: (context) => [
              // Manual completion option for active reminders
              if (reminder['status'] == 'active')
                PopupMenuItem(
                  value: 'complete',
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green[700]),
                      SizedBox(width: 8),
                      Text('Mark Complete', style: TextStyle(color: Colors.green[700])),
                    ],
                  ),
                ),
              PopupMenuItem(
                value: 'toggle',
                child: Row(
                  children: [
                    Icon(
                      reminder['status'] == 'active' ? Icons.pause : Icons.play_arrow,
                      color: Colors.grey[800],
                    ),
                    SizedBox(width: 8),
                    Text(
                      reminder['status'] == 'active' ? 'Pause' : 'Activate',
                      style: TextStyle(color: Colors.grey[800]),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, color: Colors.grey[800]),
                    SizedBox(width: 8),
                    Text('Edit', style: TextStyle(color: Colors.grey[800])),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red[700]),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: Colors.red[700])),
                  ],
                ),
              ),
            ],
                  onSelected: (value) => _handleReminderAction(value as String, reminder),
                ),
              ),
              onTap: () => _showReminderDetails(reminder),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return CustomBottomBar(
      currentIndex: 2, // Reminders is index 2
      onTap: (index) {
        // Handle navigation based on index
        switch (index) {
          case 0:
            Navigator.pushReplacementNamed(context, '/dashboard');
            break;
          case 1:
            Navigator.pushReplacementNamed(context, '/audio-library');
            break;
          case 2:
            // Already on reminders, do nothing
            break;
          case 3:
            Navigator.pushReplacementNamed(context, '/completion-celebration');
            break;
        }
      },
    );
  }

  void _handleMenuAction(String action) async {
    switch (action) {
      case 'settings':
        Navigator.pushNamed(context, '/settings');
        break;
    }
  }

  void _handleReminderAction(String action, Map<String, dynamic> reminder) async {
    switch (action) {
      case 'complete':
        try {
          final id = reminder['id']; // Don't cast - can be int or string
          await ReminderStorageService.instance.completeReminderManually(id);
          await _loadReminders();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Reminder marked as completed!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error completing reminder: $e')),
          );
        }
        break;
      case 'toggle':
        try {
          final id = reminder['id']; // Don't cast - can be int or string
          await ReminderStorageService.instance.toggleReminderStatus(id);
          await _loadReminders();
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error toggling reminder: $e')),
          );
        }
        break;
      case 'edit':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CreateReminder(reminderToEdit: reminder),
          ),
        ).then((_) => _loadReminders());
        break;
      case 'delete':
        _showDeleteDialog(reminder);
        break;
    }
  }

  void _showReminderDetails(Map<String, dynamic> reminder) {
    final status = reminder['status'] as String? ?? 'active';
    final statusColor = status == 'active' ? Colors.green : 
                       status == 'paused' ? Colors.orange : 
                       status == 'snoozed' ? Colors.purple : Colors.blue;
    
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 8,
        child: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Colors.grey[50]!,
              ],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with title and status
              Row(
                children: [
                  Expanded(
                    child: Text(
                      reminder['title'] ?? 'Reminder',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[900],
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          status == 'active' ? Icons.play_circle : 
                          status == 'paused' ? Icons.pause_circle : 
                          status == 'snoozed' ? Icons.snooze : Icons.check_circle,
                          color: statusColor,
                          size: 16,
                        ),
                        SizedBox(width: 4),
                        Text(
                          status.toUpperCase(),
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 20),
              
              // Details section
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildElegantDetailRow(
                      Icons.category, 
                      'Category', 
                      reminder['category'] ?? 'Unknown',
                      Colors.blue,
                    ),
                    _buildElegantDetailRow(
                      Icons.repeat, 
                      'Frequency', 
                      _getFrequencyDisplayText(reminder['frequency']),
                      Colors.purple,
                    ),
                    _buildElegantDetailRow(
                      Icons.schedule, 
                      'Next Occurrence', 
                      reminder['nextOccurrence'] ?? 'Unknown',
                      statusColor,
                    ),
                    _buildElegantDetailRow(
                      Icons.calendar_today, 
                      'Date Created', 
                      _formatCreationDate(reminder['createdAt']),
                      Colors.grey[600]!,
                    ),
                    if (reminder['description'] != null && (reminder['description'] as String).isNotEmpty)
                      _buildElegantDetailRow(
                        Icons.description, 
                        'Description', 
                        reminder['description'] as String,
                        Colors.grey[700]!,
                      ),
                  ],
                ),
              ),
              
              SizedBox(height: 24),
              
              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (status == 'active')
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _handleReminderAction('complete', reminder);
                      },
                      icon: Icon(Icons.check_circle, color: Colors.green),
                      label: Text(
                        'Mark Complete',
                        style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
                      ),
                    ),
                  SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _handleReminderAction('edit', reminder);
                    },
                    icon: Icon(Icons.edit, color: Colors.blue),
                    label: Text(
                      'Edit',
                      style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w600),
                    ),
                  ),
                  SizedBox(width: 8),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Close',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildElegantDetailRow(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatCreationDate(String? createdAt) {
    if (createdAt == null) return 'Unknown';
    
    try {
      final date = DateTime.parse(createdAt);
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays == 0) {
        return 'Today at ${_formatTime(date)}';
      } else if (difference.inDays == 1) {
        return 'Yesterday at ${_formatTime(date)}';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  String _getFrequencyDisplayText(Map<String, dynamic>? frequency) {
    if (frequency == null) return 'Unknown frequency';
    
    // Handle both 'type' and 'id' fields for backward compatibility
    final type = (frequency['type'] ?? frequency['id']) as String?;
    switch (type) {
      case 'daily':
        return 'Daily';
      case 'weekly':
        final selectedDays = frequency['selectedDays'] as List<dynamic>?;
        if (selectedDays == null || selectedDays.isEmpty) {
          return 'Weekly';
        }
        final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        final dayStrings = selectedDays.map((day) {
          final dayIndex = (day as int) - 1; // Convert 1-7 to 0-6
          return dayIndex >= 0 && dayIndex < 7 ? dayNames[dayIndex] : 'Unknown';
        }).toList();
        return 'Weekly (${dayStrings.join(', ')})';
      case 'hourly':
        return 'Hourly';
      case 'monthly':
        final dayOfMonth = frequency['dayOfMonth'] as int?;
        return dayOfMonth != null ? 'Monthly (${dayOfMonth}th)' : 'Monthly';
      case 'once':
        return 'One-time';
      case 'custom':
        final interval = frequency['interval'] ?? frequency['intervalValue'];
        final unit = frequency['unit'] ?? frequency['intervalUnit'];
        if (interval != null && unit != null) {
          return 'Every $interval $unit';
        }
        return 'Custom';
      case 'test':
        return 'Test reminder';
      default:
        return 'Custom frequency';
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(Map<String, dynamic> reminder) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Reminder',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey[900],
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${reminder['title']}"?',
          style: TextStyle(color: Colors.grey[700]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final id = reminder['id']; // Don't cast - can be int or string
                await ReminderStorageService.instance.deleteReminder(id);
                await _loadReminders();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Reminder deleted')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error deleting reminder: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }
}