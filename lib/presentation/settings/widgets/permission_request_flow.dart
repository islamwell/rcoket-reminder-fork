import 'package:flutter/material.dart';
import '../../../core/services/notification_service.dart';

class PermissionRequestFlow extends StatefulWidget {
  final VoidCallback? onPermissionGranted;
  final VoidCallback? onPermissionDenied;

  const PermissionRequestFlow({
    super.key,
    this.onPermissionGranted,
    this.onPermissionDenied,
  });

  @override
  State<PermissionRequestFlow> createState() => _PermissionRequestFlowState();
}

class _PermissionRequestFlowState extends State<PermissionRequestFlow> {
  int _currentStep = 0;
  bool _isLoading = false;

  final List<PermissionStep> _steps = [
    PermissionStep(
      title: 'Why We Need Permissions',
      description: 'To ensure your reminders work reliably, we need notification permissions.',
      icon: Icons.info_outline,
      content: [
        'Reminders will work even when the app is closed',
        'Background notifications keep you on track',
        'No missed reminders due to power-saving modes',
        'Seamless experience across all app states',
      ],
    ),
    PermissionStep(
      title: 'Grant Notification Access',
      description: 'Allow the app to send you notifications for your reminders.',
      icon: Icons.notifications_active,
      content: [
        'Tap "Allow" when prompted',
        'This enables background notifications',
        'You can change this later in device settings',
        'Required for full reminder functionality',
      ],
    ),
    PermissionStep(
      title: 'Optimize Battery Settings',
      description: 'Ensure the app can run in the background for reliable reminders.',
      icon: Icons.battery_saver,
      content: [
        'Disable battery optimization for this app',
        'Add to "Never sleeping apps" list',
        'Enable background app refresh (iOS)',
        'This prevents the system from stopping reminders',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.7,
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Setup Permissions',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[900],
                  ),
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onPermissionDenied?.call();
                      },
                      child: Text(
                        'Skip',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
            
            SizedBox(height: 20),
            
            // Progress indicator
            _buildProgressIndicator(),
            
            SizedBox(height: 30),
            
            // Step content
            Expanded(
              child: _buildStepContent(),
            ),
            
            SizedBox(height: 20),
            
            // Navigation buttons
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      children: List.generate(_steps.length, (index) {
        final isActive = index == _currentStep;
        final isCompleted = index < _currentStep;
        
        return Expanded(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 4),
            height: 4,
            decoration: BoxDecoration(
              color: isCompleted || isActive 
                  ? Color(0xFF667EEA) 
                  : Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildStepContent() {
    final step = _steps[_currentStep];
    
    return Column(
      children: [
        // Step icon
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Color(0xFF667EEA).withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            step.icon,
            size: 40,
            color: Color(0xFF667EEA),
          ),
        ),
        
        SizedBox(height: 24),
        
        // Step title
        Text(
          step.title,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.grey[900],
          ),
          textAlign: TextAlign.center,
        ),
        
        SizedBox(height: 12),
        
        // Step description
        Text(
          step.description,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
        
        SizedBox(height: 24),
        
        // Step content
        Expanded(
          child: ListView.builder(
            itemCount: step.content.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Color(0xFF667EEA).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF667EEA),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        step.content[index],
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    return Row(
      children: [
        if (_currentStep > 0) ...[
          Expanded(
            child: OutlinedButton(
              onPressed: _isLoading ? null : _previousStep,
              child: Text('Previous'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Color(0xFF667EEA),
                side: BorderSide(color: Color(0xFF667EEA)),
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          SizedBox(width: 12),
        ],
        Expanded(
          flex: _currentStep > 0 ? 1 : 2,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleNextStep,
            child: _isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(_getNextButtonText()),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF667EEA),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _getNextButtonText() {
    if (_currentStep == _steps.length - 1) {
      return 'Complete Setup';
    } else if (_currentStep == 1) {
      return 'Grant Permission';
    } else {
      return 'Next';
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  Future<void> _handleNextStep() async {
    if (_currentStep == 1) {
      // Request permission step
      await _requestPermission();
    } else if (_currentStep == _steps.length - 1) {
      // Complete setup
      Navigator.pop(context);
      widget.onPermissionGranted?.call();
    } else {
      // Regular next step
      setState(() {
        _currentStep++;
      });
    }
  }

  Future<void> _requestPermission() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final granted = await NotificationService.instance.requestPermissions();
      
      setState(() {
        _isLoading = false;
      });

      if (granted) {
        setState(() {
          _currentStep++;
        });
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Permission granted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Show permission denied dialog
        _showPermissionDeniedDialog();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to request permission: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Permission Denied'),
        content: Text(
          'Notification permission was denied. You can still use the app, but reminders may not work when the app is closed.\n\n'
          'To enable permissions later, go to your device settings and allow notifications for this app.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              widget.onPermissionDenied?.call();
            },
            child: Text('Continue Anyway'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _requestPermission();
            },
            child: Text('Try Again'),
          ),
        ],
      ),
    );
  }
}

class PermissionStep {
  final String title;
  final String description;
  final IconData icon;
  final List<String> content;

  PermissionStep({
    required this.title,
    required this.description,
    required this.icon,
    required this.content,
  });
}