
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_bottom_bar.dart';
import './widgets/audio_card_widget.dart';
import './widgets/audio_delete_dialog.dart';
import './widgets/empty_state_widget.dart';
import './widgets/search_bar_widget.dart';
import './widgets/storage_indicator_widget.dart';
import './widgets/upload_bottom_sheet_widget.dart';
import './widgets/recording_widget.dart';

class AudioLibrary extends StatefulWidget {
  const AudioLibrary({super.key});

  @override
  State<AudioLibrary> createState() => _AudioLibraryState();
}

class _AudioLibraryState extends State<AudioLibrary>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  String? _currentlyPlayingId;
  List<Map<String, dynamic>> _audioFiles = [];
  bool _isLoading = true;

  List<Map<String, dynamic>> get _filteredAudioFiles {
    if (_searchQuery.isEmpty) {
      return _audioFiles;
    }
    return _audioFiles.where((file) {
      final filename = (file['filename'] as String).toLowerCase();
      final category = (file['category'] as String).toLowerCase();
      final query = _searchQuery.toLowerCase();
      return filename.contains(query) || category.contains(query);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAudioFiles();
    _setupAudioPlayerListeners();
  }

  void _setupAudioPlayerListeners() {
    AudioPlayerService.instance.playingStream.listen((audioId) {
      if (mounted) {
        setState(() {
          _currentlyPlayingId = audioId;
        });
      }
    });
  }

  Future<void> _loadAudioFiles() async {
    try {
      final files = await AudioStorageService.instance.getAudioFiles();
      if (mounted) {
        setState(() {
          _audioFiles = files;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading audio files: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAllAudioTab(),
                  _buildFavoritesTab(),
                  _buildCategoriesTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Audio Library',
                      style:
                          AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${_audioFiles.length} audio files',
                      style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              _buildUploadButton(),
            ],
          ),
          SizedBox(height: 2.h),
          SearchBarWidget(
            onChanged: (query) {
              setState(() {
                _searchQuery = query;
              });
            },
            showClearButton: _searchQuery.isNotEmpty,
            onClear: () {
              setState(() {
                _searchQuery = '';
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUploadButton() {
    return GestureDetector(
      onTap: _showUploadBottomSheet,
      child: Container(
        width: 12.w,
        height: 12.w,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.lightTheme.colorScheme.primary,
              AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.8),
            ],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppTheme.lightTheme.colorScheme.primary
                  .withValues(alpha: 0.3),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: CustomIconWidget(
            iconName: 'add',
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color:
                AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomIconWidget(
                  iconName: 'library_music',
                  size: 16,
                  color: AppTheme.lightTheme.colorScheme.primary,
                ),
                SizedBox(width: 2.w),
                Text('All'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomIconWidget(
                  iconName: 'favorite',
                  size: 16,
                  color: AppTheme.lightTheme.colorScheme.tertiary,
                ),
                SizedBox(width: 2.w),
                Text('Favorites'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomIconWidget(
                  iconName: 'category',
                  size: 16,
                  color: AppTheme.lightTheme.colorScheme.secondary,
                ),
                SizedBox(width: 2.w),
                Text('Categories'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllAudioTab() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_filteredAudioFiles.isEmpty && _searchQuery.isNotEmpty) {
      return _buildNoSearchResults();
    }

    if (_audioFiles.isEmpty) {
      return EmptyStateWidget(
        onUploadPressed: _showUploadBottomSheet,
      );
    }

    return Column(
      children: [
        StorageIndicatorWidget(
          usedStorage: 12.4 * 1024 * 1024, // 12.4 MB
          totalStorage: 100 * 1024 * 1024, // 100 MB
          fileCount: _audioFiles.length,
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refreshAudioLibrary,
            child: ListView.builder(
              padding: EdgeInsets.only(bottom: 2.h),
              itemCount: _filteredAudioFiles.length,
              itemBuilder: (context, index) {
                final audioFile = _filteredAudioFiles[index];
                return Dismissible(
                  key: Key(audioFile['id'] as String),
                  background: _buildSwipeBackground(isLeft: true),
                  secondaryBackground: _buildSwipeBackground(isLeft: false),
                  onDismissed: (direction) {
                    if (direction == DismissDirection.startToEnd) {
                      _deleteAudioFile(audioFile['id'] as String);
                    } else {
                      _toggleFavorite(audioFile['id'] as String);
                    }
                  },
                  child: AudioCardWidget(
                    audioFile: audioFile,
                    isPlaying: _currentlyPlayingId == audioFile['id'],
                    isFavorite: audioFile['isFavorite'] as bool,
                    onPlay: () => _playAudio(audioFile['id'] as String),
                    onPause: () => _pauseAudio(),
                    onDelete: () => _deleteAudioFile(audioFile['id'] as String),
                    onRename: (newName) => _renameAudioFile(audioFile['id'] as String, newName),
                    onSetDefault: () =>
                        _setAsDefault(audioFile['id'] as String),
                    onShare: () => _shareAudioFile(audioFile['id'] as String),
                    onFavorite: () =>
                        _toggleFavorite(audioFile['id'] as String),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFavoritesTab() {
    final favoriteFiles =
        _audioFiles.where((file) => file['isFavorite'] as bool).toList();

    if (favoriteFiles.isEmpty) {
      return _buildEmptyFavorites();
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(vertical: 1.h),
      itemCount: favoriteFiles.length,
      itemBuilder: (context, index) {
        final audioFile = favoriteFiles[index];
        return AudioCardWidget(
          audioFile: audioFile,
          isPlaying: _currentlyPlayingId == audioFile['id'],
          isFavorite: true,
          onPlay: () => _playAudio(audioFile['id'] as String),
          onPause: () => _pauseAudio(),
          onDelete: () => _deleteAudioFile(audioFile['id'] as String),
          onRename: (newName) => _renameAudioFile(audioFile['id'] as String, newName),
          onSetDefault: () => _setAsDefault(audioFile['id'] as String),
          onShare: () => _shareAudioFile(audioFile['id'] as String),
          onFavorite: () => _toggleFavorite(audioFile['id'] as String),
        );
      },
    );
  }

  Widget _buildCategoriesTab() {
    final categories = <String, List<Map<String, dynamic>>>{};

    for (final file in _audioFiles) {
      final category = file['category'] as String;
      categories.putIfAbsent(category, () => []).add(file);
    }

    return ListView.builder(
      padding: EdgeInsets.all(4.w),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories.keys.elementAt(index);
        final files = categories[category]!;

        return _buildCategorySection(category, files);
      },
    );
  }

  Widget _buildCategorySection(
      String category, List<Map<String, dynamic>> files) {
    return Container(
      margin: EdgeInsets.only(bottom: 3.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.lightTheme.colorScheme.surface,
            AppTheme.lightTheme.colorScheme.surface.withValues(alpha: 0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(4.w),
            child: Row(
              children: [
                Container(
                  width: 10.w,
                  height: 10.w,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.lightTheme.colorScheme.primary,
                        AppTheme.lightTheme.colorScheme.primary
                            .withValues(alpha: 0.8),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: CustomIconWidget(
                      iconName: _getCategoryIcon(category),
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category,
                        style:
                            AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${files.length} ${files.length == 1 ? 'file' : 'files'}',
                        style:
                            AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color:
                              AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ...files
              .map((file) => Padding(
                    padding: EdgeInsets.symmetric(horizontal: 2.w),
                    child: AudioCardWidget(
                      audioFile: file,
                      isPlaying: _currentlyPlayingId == file['id'],
                      isFavorite: file['isFavorite'] as bool,
                      onPlay: () => _playAudio(file['id'] as String),
                      onPause: () => _pauseAudio(),
                      onDelete: () => _deleteAudioFile(file['id'] as String),
                      onRename: (newName) => _renameAudioFile(file['id'] as String, newName),
                      onSetDefault: () => _setAsDefault(file['id'] as String),
                      onShare: () => _shareAudioFile(file['id'] as String),
                      onFavorite: () => _toggleFavorite(file['id'] as String),
                    ),
                  ))
              .toList(),
        ],
      ),
    );
  }

  Widget _buildSwipeBackground({required bool isLeft}) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isLeft
              ? [
                  AppTheme.errorLight,
                  AppTheme.errorLight.withValues(alpha: 0.8)
                ]
              : [
                  AppTheme.lightTheme.colorScheme.tertiary,
                  AppTheme.lightTheme.colorScheme.tertiary
                      .withValues(alpha: 0.8)
                ],
        ),
        borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
      ),
      child: Align(
        alignment: isLeft ? Alignment.centerLeft : Alignment.centerRight,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 6.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomIconWidget(
                iconName: isLeft ? 'delete' : 'favorite',
                color: Colors.white,
                size: 24,
              ),
              SizedBox(height: 0.5.h),
              Text(
                isLeft ? 'Delete' : 'Favorite',
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoSearchResults() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'search_off',
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              size: 48,
            ),
            SizedBox(height: 2.h),
            Text(
              'No results found',
              style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Try searching with different keywords or check your spelling.',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyFavorites() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'favorite_border',
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              size: 48,
            ),
            SizedBox(height: 2.h),
            Text(
              'No Favorites Yet',
              style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Mark audio files as favorites to see them here.',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return CustomBottomBar(
      currentIndex: 1, // Audio is index 1
      onTap: (index) {
        // Handle navigation based on index
        switch (index) {
          case 0:
            Navigator.pushReplacementNamed(context, '/dashboard');
            break;
          case 1:
            // Already on audio library, do nothing
            break;
          case 2:
            Navigator.pushReplacementNamed(context, '/reminder-management');
            break;
          case 3:
            Navigator.pushReplacementNamed(context, '/completion-celebration');
            break;
        }
      },
    );
  }

  void _showUploadBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => UploadBottomSheetWidget(
        onRecordNew: _recordNewAudio,
        onChooseFromFiles: _chooseFromFiles,
        onBrowseCollection: _browseCollection,
      ),
    );
  }

  Future<void> _recordNewAudio() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (context) => RecordingWidget(
        onRecordingComplete: () async {
          Navigator.pop(context);
          await _loadAudioFiles();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Recording saved successfully!')),
          );
        },
        onCancel: () {
          Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _chooseFromFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'm4a', 'wav', 'aac'],
        allowMultiple: true,
      );

      if (result != null) {
        for (final file in result.files) {
          if (file.path != null) {
            // Copy file to app directory
            final filename = file.name;
            final copiedPath = await AudioStorageService.instance
                .copyFileToAppDirectory(file.path!, filename);

            // Get file size
            final fileSize = await AudioStorageService.instance.getFileSize(copiedPath);

            final audioFile = {
              "id": DateTime.now().millisecondsSinceEpoch.toString(),
              "filename": filename,
              "duration": "Unknown", // Would need audio analysis to get real duration
              "size": AudioStorageService.instance.formatFileSize(fileSize),
              "uploadDate": DateTime.now().toString().split(' ')[0],
              "isFavorite": false,
              "category": "Uploaded",
              "path": copiedPath,
              "type": "uploaded",
              "description": "Uploaded audio file",
            };

            await AudioStorageService.instance.saveAudioFile(audioFile);
          }
        }

        // Reload audio files
        await _loadAudioFiles();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  '${result.files.length} file(s) uploaded successfully!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('File upload failed: ${e.toString()}')),
      );
    }
  }

  void _browseCollection() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Islamic audio collection coming soon!')),
    );
  }

  Future<void> _refreshAudioLibrary() async {
    await Future.delayed(Duration(seconds: 1));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Audio library refreshed')),
    );
  }

  Future<void> _playAudio(String audioId) async {
    try {
      final audioFile = _audioFiles.firstWhere((file) => file['id'] == audioId);
      final audioPath = audioFile['path'] as String;
      
      await AudioPlayerService.instance.playAudio(audioId, audioPath);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Playing: ${audioFile['filename']}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to play audio: ${e.toString()}')),
      );
    }
  }

  Future<void> _pauseAudio() async {
    try {
      await AudioPlayerService.instance.pauseAudio();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Audio paused')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pause audio')),
      );
    }
  }

  Future<void> _deleteAudioFile(String audioId) async {
    final audioFile = _audioFiles.firstWhere((file) => file['id'] == audioId);

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AudioDeleteDialog(
        audioFile: audioFile,
        onConfirm: () async {
          // The dialog will handle the actual deletion
          await AudioStorageService.instance.deleteAudioFile(audioId);
        },
        onCancel: () => Navigator.of(context).pop(false),
      ),
    );

    // If deletion was successful (not undone), reload the list
    if (result == true) {
      await _loadAudioFiles();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Audio file deleted successfully'),
            backgroundColor: AppTheme.lightTheme.colorScheme.primary,
          ),
        );
      }
    } else if (result == false) {
      // Undo was performed, reload the list to show restored file
      await _loadAudioFiles();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Audio file restored'),
            backgroundColor: AppTheme.lightTheme.colorScheme.tertiary,
          ),
        );
      }
    }
  }

  Future<void> _renameAudioFile(String audioId, String newName) async {
    try {
      // Stop audio if it's currently playing
      if (_currentlyPlayingId == audioId) {
        await AudioPlayerService.instance.pauseAudio();
      }

      // Update the audio file name in storage
      await AudioStorageService.instance.updateAudioFile(
        audioId, 
        {'filename': newName}
      );
      
      // Reload audio files to reflect changes
      await _loadAudioFiles();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Audio renamed to "$newName"'),
            backgroundColor: AppTheme.lightTheme.colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to rename audio file'),
            backgroundColor: AppTheme.lightTheme.colorScheme.error,
          ),
        );
      }
      rethrow; // Re-throw to let the dialog handle the error
    }
  }

  void _setAsDefault(String audioId) {
    final audioFile = _audioFiles.firstWhere((file) => file['id'] == audioId);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(
              '${audioFile['filename']} set as default notification sound')),
    );
  }

  void _shareAudioFile(String audioId) {
    final audioFile = _audioFiles.firstWhere((file) => file['id'] == audioId);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Sharing ${audioFile['filename']}')),
    );
  }

  Future<void> _toggleFavorite(String audioId) async {
    try {
      final audioFile = _audioFiles.firstWhere((file) => file['id'] == audioId);
      final newFavoriteStatus = !(audioFile['isFavorite'] as bool);
      
      await AudioStorageService.instance.updateAudioFile(
        audioId, 
        {'isFavorite': newFavoriteStatus}
      );
      
      await _loadAudioFiles(); // Reload to reflect changes

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newFavoriteStatus
              ? 'Added to favorites'
              : 'Removed from favorites'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update favorite status')),
      );
    }
  }

  String _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'duas':
        return 'favorite';
      case 'quran':
        return 'menu_book';
      case 'personal':
        return 'person';
      case 'health':
        return 'fitness_center';
      case 'charity':
        return 'volunteer_activism';
      case 'uploaded':
        return 'cloud_upload';
      default:
        return 'folder';
    }
  }


}
