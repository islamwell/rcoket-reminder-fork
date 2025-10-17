import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/audio_card_widget.dart';
import './widgets/search_bar_widget.dart';
import './widgets/error_recovery_widget.dart';
import './controllers/audio_library_controller.dart';

class AudioLibrarySelection extends StatefulWidget {
  const AudioLibrarySelection({super.key});

  @override
  State<AudioLibrarySelection> createState() => _AudioLibrarySelectionState();
}

class _AudioLibrarySelectionState extends State<AudioLibrarySelection> {
  late AudioLibraryController _controller;
  Map<String, dynamic>? _selectedAudio;

  @override
  void initState() {
    super.initState();
    _controller = AudioLibraryController();
    _controller.addListener(_onControllerStateChanged);
  }

  void _onControllerStateChanged() {
    if (mounted) {
      setState(() {});
      
      // Show error messages if any
      if (_controller.errorMessage != null) {
        _showErrorSnackBar(_controller.errorMessage!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          await _onWillPop();
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _controller.isLoading
                    ? _buildLoadingState()
                    : _controller.audioFiles.isEmpty
                        ? _buildEmptyState()
                        : _buildAudioList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.lightTheme.colorScheme.surface,
            AppTheme.lightTheme.colorScheme.surface.withValues(alpha: 0.95),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color:
                AppTheme.lightTheme.colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () async {
                  if (await _onWillPop()) {
                    Navigator.pop(context);
                  }
                },
                child: Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: AppTheme.lightTheme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.lightTheme.colorScheme.outline
                          .withValues(alpha: 0.3),
                    ),
                  ),
                  child: CustomIconWidget(
                    iconName: 'arrow_back',
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'Select Audio',
                      style:
                          AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Choose audio for your reminder',
                      style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12.w), // Balance the back button
            ],
          ),
          SizedBox(height: 2.h),
          SearchBarWidget(
            onChanged: (query) => _controller.updateSearchQuery(query),
            showClearButton: _controller.searchQuery.isNotEmpty,
            onClear: () => _controller.clearSearch(),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 2.h),
          Text(
            'Loading audio files...',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'music_off',
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              size: 48,
            ),
            SizedBox(height: 2.h),
            Text(
              _controller.searchQuery.isNotEmpty ? 'No matching audio files' : 'No audio files found',
              style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              _controller.searchQuery.isNotEmpty 
                  ? 'Try searching with different keywords'
                  : 'Go to the Audio Library to add some audio files first.',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (_controller.searchQuery.isEmpty) ...[
              SizedBox(height: 3.h),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/audio-library');
                },
                icon: CustomIconWidget(
                  iconName: 'library_music',
                  color: AppTheme.lightTheme.colorScheme.onPrimary,
                  size: 16,
                ),
                label: Text('Go to Audio Library'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAudioList() {
    return RefreshIndicator(
      onRefresh: () => _controller.refreshAudioFiles(),
      child: Column(
        children: [
          // Show global error if any
          if (_controller.errorMessage != null)
            ErrorRecoveryWidget(
              message: _controller.errorMessage!,
              onRetry: () => _controller.refreshAudioFiles(),
              onDismiss: () => _controller.clearAllErrors(),
            ),
          
          // Show playback error if any
          if (_controller.playbackController.errorMessage != null)
            ErrorRecoveryWidget(
              message: _controller.playbackController.errorMessage!,
              isInline: true,
              icon: Icons.play_arrow,
              onDismiss: () => _controller.playbackController.clearError(),
            ),
          
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(4.w),
              itemCount: _controller.audioFiles.length,
              itemBuilder: (context, index) {
                final audioFile = _controller.audioFiles[index];
                final audioId = audioFile['id'] as String;
                
                return Column(
                  children: [
                    // Show operation-specific errors
                    ..._buildOperationErrors(audioId),
                    
                    Container(
                      margin: EdgeInsets.only(bottom: 2.h),
                      child: AnimatedContainer(
                        duration: Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
                          border: _selectedAudio?['id'] == audioId
                              ? Border.all(
                                  color: AppTheme.lightTheme.colorScheme.primary,
                                  width: 2,
                                )
                              : null,
                        ),
                        child: AudioCardWidget(
                          audioFile: audioFile,
                          isPlaying: _controller.playbackController.isAudioPlaying(audioId),
                          isFavorite: audioFile['isFavorite'] as bool,
                          onPlay: () => _playAudio(audioId),
                          onPause: () => _pauseAudio(),
                          onDelete: null, // Disable delete in selection mode
                          onRename: (newName) => _renameAudioFile(audioId, newName),
                          onSetDefault: null, // Disable set default in selection mode
                          onShare: null, // Disable share in selection mode
                          onFavorite: () => _toggleFavorite(audioId),
                          onSelect: () => _selectAudio(audioFile),
                          showSelectionMode: true,
                          isProcessing: _controller.isProcessing(audioId) || 
                                       _controller.playbackController.isAudioLoading(audioId),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildOperationErrors(String audioId) {
    final errors = <Widget>[];
    
    // Check for rename error
    final renameError = _controller.getOperationError(audioId, 'rename');
    if (renameError != null) {
      errors.add(
        OperationErrorWidget(
          audioId: audioId,
          operation: 'rename',
          message: renameError,
          onRetry: () async {
            // For rename, we can't retry without the new name
            // This should be handled by showing the rename dialog again
            return false;
          },
          onDismiss: () => _controller.clearOperationError(audioId, 'rename'),
        ),
      );
    }
    
    // Check for favorite error
    final favoriteError = _controller.getOperationError(audioId, 'favorite');
    if (favoriteError != null) {
      errors.add(
        OperationErrorWidget(
          audioId: audioId,
          operation: 'favorite',
          message: favoriteError,
          onRetry: () => _controller.retryOperation(audioId, 'favorite'),
          onDismiss: () => _controller.clearOperationError(audioId, 'favorite'),
        ),
      );
    }
    
    return errors;
  }

  Future<void> _playAudio(String audioId) async {
    final audioFile = _controller.getAudioFile(audioId);
    if (audioFile != null) {
      final audioPath = audioFile['path'] as String;
      await _controller.playbackController.playAudio(audioId, audioPath);
    }
  }

  Future<void> _pauseAudio() async {
    await _controller.playbackController.pauseAudio();
  }

  Future<void> _renameAudioFile(String audioId, String newName) async {
    final success = await _controller.renameAudioFile(audioId, newName);
    if (success) {
      _showSuccessSnackBar('Audio renamed to "$newName"');
    } else {
      final error = _controller.getOperationError(audioId, 'rename');
      _showErrorSnackBar(error ?? 'Failed to rename audio file');
    }
  }

  Future<void> _toggleFavorite(String audioId) async {
    final audioFile = _controller.getAudioFile(audioId);
    if (audioFile == null) return;
    
    final currentFavoriteStatus = audioFile['isFavorite'] as bool;
    final success = await _controller.toggleFavorite(audioId);
    
    if (success) {
      final message = !currentFavoriteStatus 
          ? 'Added to favorites' 
          : 'Removed from favorites';
      _showSuccessSnackBar(message);
    } else {
      final error = _controller.getOperationError(audioId, 'favorite');
      _showErrorSnackBar(error ?? 'Failed to update favorite status');
    }
  }

  void _selectAudio(Map<String, dynamic> audioFile) {
    // Prevent selection if audio is being processed
    final audioId = audioFile['id'] as String;
    if (_controller.isProcessing(audioId)) {
      _showErrorSnackBar('Please wait for the current operation to complete');
      return;
    }
    
    // Validate audio file still exists and is accessible
    if (!_isAudioFileValid(audioFile)) {
      _showErrorSnackBar('Selected audio file is no longer available');
      _controller.refreshAudioFiles(); // Refresh to remove invalid files
      return;
    }
    
    // Provide visual feedback before navigation
    setState(() {
      _selectedAudio = audioFile;
    });
    
    // Show selection feedback
    _showSuccessSnackBar('Selected: ${audioFile['filename']}');
    
    // Brief delay for visual feedback
    Future.delayed(Duration(milliseconds: 300), () {
      if (mounted) {
        _navigateWithSelectedAudio(audioFile);
      }
    });
  }

  void _navigateWithSelectedAudio(Map<String, dynamic> audioFile) {
    try {
      // Stop any playing audio before navigation
      if (_controller.playbackController.isPlaying) {
        _controller.playbackController.stopAudio();
      }
      
      // Prepare audio data for return
      final selectedAudioData = {
        'id': audioFile['id'],
        'name': audioFile['filename'],
        'duration': audioFile['duration'],
        'type': audioFile['type'] ?? 'library',
        'description': audioFile['description'] ?? 'Audio from library',
        'path': audioFile['path'],
        'size': audioFile['size'],
        'category': audioFile['category'],
        'isFavorite': audioFile['isFavorite'],
      };
      
      // Return the selected audio file to the previous screen
      Navigator.pop(context, selectedAudioData);
      
    } catch (e) {
      // Handle navigation errors gracefully
      _showErrorSnackBar('Failed to select audio: ${e.toString()}');
      setState(() {
        _selectedAudio = null;
      });
    }
  }

  bool _isAudioFileValid(Map<String, dynamic> audioFile) {
    // Check if required fields are present
    final requiredFields = ['id', 'filename', 'path', 'duration'];
    for (final field in requiredFields) {
      if (!audioFile.containsKey(field) || audioFile[field] == null) {
        return false;
      }
    }
    
    // Check if filename is not empty
    final filename = audioFile['filename'] as String?;
    if (filename == null || filename.trim().isEmpty) {
      return false;
    }
    
    // Check if path is not empty
    final path = audioFile['path'] as String?;
    if (path == null || path.trim().isEmpty) {
      return false;
    }
    
    return true;
  }

  /// Handle back navigation without selection
  Future<bool> _onWillPop() async {
    // Stop any playing audio before going back
    if (_controller.playbackController.isPlaying) {
      await _controller.playbackController.stopAudio();
    }
    
    // Clear any selected audio state
    if (_selectedAudio != null) {
      setState(() {
        _selectedAudio = null;
      });
    }
    
    return true; // Allow navigation
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppTheme.lightTheme.colorScheme.primary,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppTheme.lightTheme.colorScheme.error,
          duration: Duration(seconds: 3),
          action: SnackBarAction(
            label: 'Dismiss',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerStateChanged);
    _controller.dispose();
    super.dispose();
  }
}