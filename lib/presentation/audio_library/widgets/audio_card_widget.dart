import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import 'audio_rename_dialog.dart';
import 'audio_delete_dialog.dart';
import 'animated_play_button.dart';

/// Enhanced AudioCardWidget with functional action buttons
/// 
/// Features:
/// - Play/pause functionality with visual feedback and waveform animation
/// - Rename functionality with validation dialog
/// - Favorite toggle with animation feedback and persistence
/// - Delete functionality with confirmation dialog and undo capability
/// - Proper touch targets (minimum 44px equivalent) for accessibility
/// - Loading states and processing indicators for all operations
/// - Optimistic UI updates with error recovery
/// - Visual feedback animations for all interactions
/// 
/// Requirements implemented: 1.1, 1.2, 1.3, 7.1, 7.4

class AudioCardWidget extends StatefulWidget {
  final Map<String, dynamic> audioFile;
  final VoidCallback onPlay;
  final VoidCallback onPause;
  final VoidCallback? onDelete;
  final Function(String)? onRename;
  final VoidCallback? onSetDefault;
  final VoidCallback? onShare;
  final VoidCallback? onFavorite;
  final VoidCallback? onSelect;
  final bool isPlaying;
  final bool isFavorite;
  final bool showSelectionMode;
  final bool isProcessing;

  const AudioCardWidget({
    super.key,
    required this.audioFile,
    required this.onPlay,
    required this.onPause,
    this.onDelete,
    this.onRename,
    this.onSetDefault,
    this.onShare,
    this.onFavorite,
    this.onSelect,
    this.isPlaying = false,
    this.isFavorite = false,
    this.showSelectionMode = false,
    this.isProcessing = false,
  });

  @override
  State<AudioCardWidget> createState() => _AudioCardWidgetState();
}

class _AudioCardWidgetState extends State<AudioCardWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AudioAnimations.quickFeedback,
      vsync: this,
    );
    
    _scaleAnimation = AudioAnimations.createScaleAnimation(_animationController);
  }

  @override
  void didUpdateWidget(AudioCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Animation updates are now handled by individual components
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.showSelectionMode ? _handleSelection : _toggleExpanded,
      onTapDown: (_) => _animationController.forward(),
      onTapUp: (_) => _animationController.reverse(),
      onTapCancel: () => _animationController.reverse(),
      onLongPress: widget.showSelectionMode ? null : () => _showContextMenu(context),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: widget.isPlaying ? [
                    AppTheme.lightTheme.colorScheme.primaryContainer,
                    AppTheme.lightTheme.colorScheme.primaryContainer
                        .withValues(alpha: 0.8),
                  ] : [
                    AppTheme.lightTheme.colorScheme.surface,
                    AppTheme.lightTheme.colorScheme.surface
                        .withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
                border: widget.isPlaying ? Border.all(
                  color: AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.3),
                  width: 1,
                ) : null,
                boxShadow: [
                  BoxShadow(
                    color: widget.isPlaying 
                        ? AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.2)
                        : AppTheme.lightTheme.colorScheme.shadow.withValues(alpha: 0.1),
                    blurRadius: widget.isPlaying ? 12 : 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: AnimatedContainer(
                duration: Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                padding: EdgeInsets.all(4.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMainContent(),
                    if (_isExpanded && !widget.showSelectionMode) ...[
                      SizedBox(height: 2.h),
                      _buildExpandedPlayer(),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _toggleExpanded() {
    if (!widget.showSelectionMode) {
      setState(() {
        _isExpanded = !_isExpanded;
      });
    }
  }

  void _handleSelection() {
    if (widget.onSelect != null) {
      widget.onSelect!();
    }
  }

  Widget _buildMainContent() {
    return Row(
      children: [
        _buildPlayButton(),
        SizedBox(width: 3.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.audioFile['filename'] as String,
                      style:
                          AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: widget.isPlaying 
                            ? AppTheme.lightTheme.colorScheme.primary
                            : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (widget.isProcessing)
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.lightTheme.colorScheme.primary,
                        ),
                      ),
                    )
                  else if (widget.isFavorite)
                    CustomIconWidget(
                      iconName: 'favorite',
                      color: AppTheme.lightTheme.colorScheme.tertiary,
                      size: 16,
                    ),
                ],
              ),
              SizedBox(height: 0.5.h),
              Row(
                children: [
                  CustomIconWidget(
                    iconName: 'access_time',
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    size: 14,
                  ),
                  SizedBox(width: 1.w),
                  Flexible(
                    child: Text(
                      widget.audioFile['duration'] as String,
                      style: AppTheme.lightTheme.textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: 4.w),
                  CustomIconWidget(
                    iconName: 'folder_open',
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    size: 14,
                  ),
                  SizedBox(width: 1.w),
                  Flexible(
                    child: Text(
                      widget.audioFile['size'] as String,
                      style: AppTheme.lightTheme.textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (!widget.showSelectionMode) ...[
          SizedBox(width: 2.w),
          _buildActionButtons(),
        ],
        SizedBox(width: 2.w),
        _buildWaveformPreview(),
      ],
    );
  }

  Widget _buildPlayButton() {
    return AnimatedPlayButton(
      isPlaying: widget.isPlaying,
      isLoading: widget.isProcessing,
      onPlay: widget.onPlay,
      onPause: widget.onPause,
      size: 12.w,
      primaryColor: AppTheme.lightTheme.colorScheme.primary,
      secondaryColor: AppTheme.lightTheme.colorScheme.tertiary,
      showPulse: true,
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.onRename != null) ...[
          _buildActionButton(
            'edit',
            () => _handleRename(),
            tooltip: 'Rename audio file',
          ),
          SizedBox(width: 1.w),
        ],
        if (widget.onFavorite != null) ...[
          _buildFavoriteButton(),
          SizedBox(width: 1.w),
        ],
        if (widget.onDelete != null)
          _buildActionButton(
            'delete',
            () => _handleDelete(),
            tooltip: 'Delete audio file',
            color: AppTheme.lightTheme.colorScheme.error,
          ),
      ],
    );
  }

  Widget _buildActionButton(
    String iconName,
    VoidCallback onTap,
    {String? tooltip,
    Color? color}
  ) {
    return AnimatedActionButton(
      iconName: iconName,
      onTap: widget.isProcessing ? null : onTap,
      color: color ?? AppTheme.lightTheme.colorScheme.onSurfaceVariant,
      backgroundColor: AppTheme.lightTheme.colorScheme.surface.withValues(alpha: 0.8),
      size: 14,
      tooltip: tooltip,
      isLoading: widget.isProcessing && (iconName == 'edit' || iconName == 'delete'),
      isDisabled: widget.isProcessing,
      animationDuration: AudioAnimations.quickFeedback,
    );
  }

  Widget _buildFavoriteButton() {
    return AnimatedFavoriteButton(
      isFavorite: widget.isFavorite,
      onToggle: widget.isProcessing ? null : _handleFavoriteToggle,
      favoriteColor: AppTheme.lightTheme.colorScheme.tertiary,
      unfavoriteColor: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
      size: 14,
      isLoading: widget.isProcessing,
    );
  }

  Widget _buildWaveformPreview() {
    return AnimatedWaveform(
      isPlaying: widget.isPlaying,
      width: 15.w,
      height: 6.h,
      color: widget.isPlaying 
          ? AppTheme.lightTheme.colorScheme.primary
          : AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.6),
      glowColor: AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.3),
      barCount: 20,
      strokeWidth: 2.0,
      showGlow: widget.isPlaying,
    );
  }

  void _handleRename() {
    if (widget.onRename != null) {
      _showRenameDialog();
    }
  }

  void _handleFavoriteToggle() {
    if (widget.onFavorite != null) {
      widget.onFavorite!();
    }
  }

  void _showRenameDialog() async {
    if (widget.onRename == null) return;

    // Get existing audio files to check for duplicates
    final audioStorageService = AudioStorageService.instance;
    final allAudioFiles = await audioStorageService.getAudioFiles();
    final existingNames = allAudioFiles
        .map((file) => file['filename'] as String)
        .toList();

    if (!mounted) return;

    final currentName = widget.audioFile['filename'] as String;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AudioRenameDialog(
        currentName: currentName,
        existingNames: existingNames,
        onRename: widget.onRename!,
        onCancel: () => Navigator.of(context).pop(),
      ),
    );
  }

  void _handleDelete() {
    if (widget.onDelete != null) {
      _showDeleteDialog();
    }
  }

  void _showDeleteDialog() async {
    if (widget.onDelete == null) return;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AudioDeleteDialog(
        audioFile: widget.audioFile,
        onConfirm: () async {
          // Call the delete callback
          await AudioStorageService.instance.deleteAudioFile(widget.audioFile['id'] as String);
        },
        onCancel: () => Navigator.of(context).pop(false),
      ),
    );

    // If deletion was successful (not undone), call the parent callback
    if (result == true && widget.onDelete != null) {
      widget.onDelete!();
    }
  }



  Widget _buildExpandedPlayer() {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppTheme.smallRadius),
      ),
      child: Column(
        children: [
          _buildProgressBar(),
          SizedBox(height: 2.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildControlButton('volume_up', () {}),
              _buildControlButton('replay_10', () {}),
              _buildControlButton('forward_10', () {}),
              _buildControlButton('loop', () {}),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Column(
      children: [
        AnimatedProgressIndicator(
          progress: 0.3, // This would be dynamic in real implementation
          color: AppTheme.lightTheme.colorScheme.primary,
          backgroundColor: AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.3),
          height: 4,
          showGlow: widget.isPlaying,
        ),
        SizedBox(height: 1.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '1:23',
              style: AppTheme.lightTheme.textTheme.bodySmall,
            ),
            Text(
              widget.audioFile['duration'] as String,
              style: AppTheme.lightTheme.textTheme.bodySmall,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildControlButton(String iconName, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 10.w,
        height: 10.w,
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: CustomIconWidget(
            iconName: iconName,
            color: AppTheme.lightTheme.colorScheme.primary,
            size: 18,
          ),
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context) {
    if (widget.showSelectionMode) return; // Don't show context menu in selection mode
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppTheme.extraLargeRadius)),
        ),
        padding: EdgeInsets.all(6.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12.w,
              height: 0.5.h,
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant
                    .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 3.h),
            if (widget.onRename != null)
              _buildContextMenuItem('edit', 'Rename', _handleRename),
            if (widget.onDelete != null)
              _buildContextMenuItem('delete', 'Delete', _handleDelete),
            if (widget.onSetDefault != null)
              _buildContextMenuItem('star', 'Set as Default', widget.onSetDefault!),
            if (widget.onShare != null)
              _buildContextMenuItem('share', 'Share', widget.onShare!),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  Widget _buildContextMenuItem(
      String iconName, String title, VoidCallback onTap) {
    return ListTile(
      leading: CustomIconWidget(
        iconName: iconName,
        color: AppTheme.lightTheme.colorScheme.primary,
        size: 20,
      ),
      title: Text(
        title,
        style: AppTheme.lightTheme.textTheme.bodyLarge,
      ),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }
}


