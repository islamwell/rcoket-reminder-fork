import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'dart:math';

import '../../../core/app_export.dart';

class AudioRenameDialog extends StatefulWidget {
  final String currentName;
  final List<String> existingNames;
  final Function(String) onRename;
  final VoidCallback? onCancel;

  const AudioRenameDialog({
    super.key,
    required this.currentName,
    required this.existingNames,
    required this.onRename,
    this.onCancel,
  });

  @override
  State<AudioRenameDialog> createState() => _AudioRenameDialogState();
}

class _AudioRenameDialogState extends State<AudioRenameDialog>
    with TickerProviderStateMixin {
  late TextEditingController _textController;
  late FocusNode _focusNode;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  
  String? _errorMessage;
  bool _isProcessing = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize controllers
    _textController = TextEditingController(text: _getFilenameWithoutExtension());
    _focusNode = FocusNode();
    
    // Initialize shake animation for error feedback
    _shakeController = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.elasticIn,
    ));

    // Add listener for real-time validation
    _textController.addListener(_onTextChanged);
    
    // Auto-focus and select text
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      _textController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _textController.text.length,
      );
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  String _getFilenameWithoutExtension() {
    final filename = widget.currentName;
    final lastDotIndex = filename.lastIndexOf('.');
    if (lastDotIndex > 0) {
      return filename.substring(0, lastDotIndex);
    }
    return filename;
  }

  String _getFileExtension() {
    final filename = widget.currentName;
    final lastDotIndex = filename.lastIndexOf('.');
    if (lastDotIndex > 0 && lastDotIndex < filename.length - 1) {
      return filename.substring(lastDotIndex);
    }
    return '.mp3'; // Default extension
  }

  void _onTextChanged() {
    final newText = _textController.text.trim();
    final hasChanges = newText != _getFilenameWithoutExtension();
    
    if (hasChanges != _hasChanges) {
      setState(() {
        _hasChanges = hasChanges;
      });
    }

    // Real-time validation
    _validateInput(newText, showError: false);
  }

  String? _validateInput(String input, {bool showError = true}) {
    final trimmedInput = input.trim();
    
    // Check for empty name
    if (trimmedInput.isEmpty) {
      final error = 'Audio name cannot be empty';
      if (showError) {
        setState(() {
          _errorMessage = error;
        });
        _triggerShakeAnimation();
      }
      return error;
    }

    // Check for invalid characters
    final invalidChars = RegExp(r'[<>:"/\\|?*]');
    if (invalidChars.hasMatch(trimmedInput)) {
      final error = 'Name contains invalid characters';
      if (showError) {
        setState(() {
          _errorMessage = error;
        });
        _triggerShakeAnimation();
      }
      return error;
    }

    // Check for duplicate names
    final newFullName = trimmedInput + _getFileExtension();
    final isDuplicate = widget.existingNames.any((name) => 
        name.toLowerCase() == newFullName.toLowerCase() && 
        name.toLowerCase() != widget.currentName.toLowerCase()
    );
    
    if (isDuplicate) {
      final error = 'An audio file with this name already exists';
      if (showError) {
        setState(() {
          _errorMessage = error;
        });
        _triggerShakeAnimation();
      }
      return error;
    }

    // Clear error if validation passes
    if (showError && _errorMessage != null) {
      setState(() {
        _errorMessage = null;
      });
    }

    return null;
  }

  void _triggerShakeAnimation() {
    _shakeController.reset();
    _shakeController.forward();
  }

  Future<void> _handleRename() async {
    final input = _textController.text.trim();
    
    // Validate input
    final validationError = _validateInput(input, showError: true);
    if (validationError != null) {
      return;
    }

    // Check if there are actually changes
    if (!_hasChanges) {
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final newFullName = input + _getFileExtension();
      await widget.onRename(newFullName);
      
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to rename audio file. Please try again.';
          _isProcessing = false;
        });
        _triggerShakeAnimation();
      }
    }
  }

  void _handleCancel() {
    if (widget.onCancel != null) {
      widget.onCancel!();
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: AnimatedBuilder(
        animation: _shakeAnimation,
        builder: (context, child) {
          final shakeOffset = sin(_shakeAnimation.value * 3.14159 * 4) * 5;
          return Transform.translate(
            offset: Offset(shakeOffset, 0),
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 5.w),
              padding: EdgeInsets.all(6.w),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.surface,
                borderRadius: BorderRadius.circular(AppTheme.largeRadius),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.lightTheme.colorScheme.shadow.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  SizedBox(height: 4.h),
                  _buildTextField(),
                  if (_errorMessage != null) ...[
                    SizedBox(height: 2.h),
                    _buildErrorMessage(),
                  ],
                  SizedBox(height: 4.h),
                  _buildActionButtons(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(AppTheme.smallRadius),
              ),
              child: CustomIconWidget(
                iconName: 'edit',
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 20,
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Text(
                'Rename Audio',
                style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 2.h),
        Text(
          'Enter a new name for your audio file',
          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Audio Name',
          style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 1.h),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
            border: Border.all(
              color: _errorMessage != null
                  ? AppTheme.lightTheme.colorScheme.error
                  : _focusNode.hasFocus
                      ? AppTheme.lightTheme.colorScheme.primary
                      : AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.5),
              width: _focusNode.hasFocus || _errorMessage != null ? 2 : 1,
            ),
          ),
          child: TextField(
            controller: _textController,
            focusNode: _focusNode,
            enabled: !_isProcessing,
            maxLength: 50,
            decoration: InputDecoration(
              hintText: 'Enter audio name',
              hintStyle: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
              suffixText: _getFileExtension(),
              suffixStyle: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 3.h),
              counterText: '',
            ),
            style: AppTheme.lightTheme.textTheme.bodyLarge,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _handleRename(),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(AppTheme.smallRadius),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.error.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          CustomIconWidget(
            iconName: 'error',
            color: AppTheme.lightTheme.colorScheme.error,
            size: 16,
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
              _errorMessage!,
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: _isProcessing ? null : _handleCancel,
          style: TextButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
          ),
          child: Text(
            'Cancel',
            style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        SizedBox(width: 2.w),
        ElevatedButton(
          onPressed: _isProcessing || !_hasChanges || _errorMessage != null 
              ? null 
              : _handleRename,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.lightTheme.colorScheme.primary,
            foregroundColor: AppTheme.lightTheme.colorScheme.onPrimary,
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
            ),
          ),
          child: _isProcessing
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppTheme.lightTheme.colorScheme.onPrimary,
                    ),
                  ),
                )
              : Text(
                  'Rename',
                  style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ],
    );
  }
}