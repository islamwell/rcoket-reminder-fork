import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'dart:math';
import 'dart:async';

import '../../../core/app_export.dart';

class AudioDeleteDialog extends StatefulWidget {
  final Map<String, dynamic> audioFile;
  final Future<void> Function() onConfirm;
  final VoidCallback? onCancel;

  const AudioDeleteDialog({
    super.key,
    required this.audioFile,
    required this.onConfirm,
    this.onCancel,
  });

  @override
  State<AudioDeleteDialog> createState() => _AudioDeleteDialogState();
}

class _AudioDeleteDialogState extends State<AudioDeleteDialog>
    with TickerProviderStateMixin {
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  
  String? _errorMessage;
  bool _isProcessing = false;
  bool _showUndoOption = false;
  Timer? _undoTimer;
  int _undoCountdown = 5;

  @override
  void initState() {
    super.initState();
    
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
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _undoTimer?.cancel();
    super.dispose();
  }

  void _triggerShakeAnimation() {
    _shakeController.reset();
    _shakeController.forward();
  }

  Future<void> _handleDelete() async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      // Check if this audio is currently playing and stop it
      final audioPlayerService = AudioPlayerService.instance;
      final audioId = widget.audioFile['id'] as String;
      
      if (audioPlayerService.currentlyPlayingId == audioId) {
        await audioPlayerService.stopAudio();
      }

      // Perform the deletion
      await widget.onConfirm();
      
      if (mounted) {
        // Show undo option
        setState(() {
          _isProcessing = false;
          _showUndoOption = true;
          _undoCountdown = 5;
        });
        
        // Start countdown timer
        _startUndoCountdown();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to delete audio file. Please try again.';
          _isProcessing = false;
        });
        _triggerShakeAnimation();
      }
    }
  }

  void _startUndoCountdown() {
    _undoTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _undoCountdown--;
        });
        
        if (_undoCountdown <= 0) {
          timer.cancel();
          if (mounted) {
            Navigator.of(context).pop(true); // Return true to indicate successful deletion
          }
        }
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _handleUndo() async {
    _undoTimer?.cancel();
    
    try {
      // Restore the audio file
      await AudioStorageService.instance.saveAudioFile(widget.audioFile);
      
      if (mounted) {
        Navigator.of(context).pop(false); // Return false to indicate undo
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to restore audio file.';
          _showUndoOption = false;
        });
        _triggerShakeAnimation();
      }
    }
  }

  void _handleCancel() {
    _undoTimer?.cancel();
    if (widget.onCancel != null) {
      widget.onCancel!();
    }
    Navigator.of(context).pop(false);
  }

  String _formatFileSize() {
    final size = widget.audioFile['size'] as String? ?? '0 B';
    return size;
  }

  String _getFileType() {
    final filename = widget.audioFile['filename'] as String;
    final extension = filename.split('.').last.toUpperCase();
    return '$extension Audio';
  }

  bool _isDefaultAudio() {
    return widget.audioFile['type'] == 'default';
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
                  if (_showUndoOption)
                    _buildUndoSection()
                  else ...[
                    _buildHeader(),
                    SizedBox(height: 4.h),
                    _buildFileDetails(),
                    if (_isDefaultAudio()) ...[
                      SizedBox(height: 3.h),
                      _buildDefaultAudioWarning(),
                    ],
                    if (_errorMessage != null) ...[
                      SizedBox(height: 3.h),
                      _buildErrorMessage(),
                    ],
                    SizedBox(height: 4.h),
                    _buildActionButtons(),
                  ],
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
                color: AppTheme.lightTheme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(AppTheme.smallRadius),
              ),
              child: CustomIconWidget(
                iconName: 'delete',
                color: AppTheme.lightTheme.colorScheme.error,
                size: 20,
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Text(
                'Delete Audio',
                style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 2.h),
        Text(
          'Are you sure you want to delete this audio file? This action cannot be undone.',
          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildFileDetails() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomIconWidget(
                iconName: 'music_note',
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 20,
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  widget.audioFile['filename'] as String,
                  style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              _buildDetailItem('access_time', widget.audioFile['duration'] as String),
              SizedBox(width: 4.w),
              _buildDetailItem('folder_open', _formatFileSize()),
              SizedBox(width: 4.w),
              _buildDetailItem('audiotrack', _getFileType()),
            ],
          ),
          if (widget.audioFile['description'] != null) ...[
            SizedBox(height: 2.h),
            Text(
              widget.audioFile['description'] as String,
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailItem(String iconName, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomIconWidget(
          iconName: iconName,
          color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
          size: 14,
        ),
        SizedBox(width: 1.w),
        Text(
          text,
          style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildDefaultAudioWarning() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(AppTheme.smallRadius),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.tertiary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          CustomIconWidget(
            iconName: 'info',
            color: AppTheme.lightTheme.colorScheme.tertiary,
            size: 16,
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
              'This is a default audio file. It will be restored when you restart the app.',
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onTertiaryContainer,
              ),
            ),
          ),
        ],
      ),
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
          onPressed: _isProcessing ? null : _handleDelete,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.lightTheme.colorScheme.error,
            foregroundColor: AppTheme.lightTheme.colorScheme.onError,
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
                      AppTheme.lightTheme.colorScheme.onError,
                    ),
                  ),
                )
              : Text(
                  'Delete',
                  style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildUndoSection() {
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
                iconName: 'check_circle',
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 20,
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Text(
                'Audio Deleted',
                style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 3.h),
        Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.colorScheme.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
            border: Border.all(
              color: AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  CustomIconWidget(
                    iconName: 'info',
                    color: AppTheme.lightTheme.colorScheme.primary,
                    size: 16,
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      'The audio file "${widget.audioFile['filename']}" has been deleted.',
                      style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 2.h),
              Text(
                'This dialog will close automatically in $_undoCountdown seconds.',
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 4.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () {
                _undoTimer?.cancel();
                Navigator.of(context).pop(true);
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
              ),
              child: Text(
                'Close',
                style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            SizedBox(width: 2.w),
            ElevatedButton.icon(
              onPressed: _handleUndo,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.lightTheme.colorScheme.tertiary,
                foregroundColor: AppTheme.lightTheme.colorScheme.onTertiary,
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
                ),
              ),
              icon: CustomIconWidget(
                iconName: 'undo',
                color: AppTheme.lightTheme.colorScheme.onTertiary,
                size: 16,
              ),
              label: Text(
                'Undo ($_undoCountdown)',
                style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}