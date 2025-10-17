import 'dart:async';
import 'package:flutter/foundation.dart';

import '../../../core/services/audio_storage_service.dart';
import 'audio_playback_controller.dart';

/// Centralized controller for managing all audio library operations
/// Handles optimistic UI updates, error recovery, and state coordination
class AudioLibraryController extends ChangeNotifier {
  final AudioStorageService _storageService = AudioStorageService.instance;
  final AudioPlaybackController _playbackController = AudioPlaybackController();
  
  List<Map<String, dynamic>> _audioFiles = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';
  
  // Processing states for optimistic updates
  final Set<String> _processingOperations = <String>{};
  final Map<String, Map<String, dynamic>> _optimisticUpdates = {};
  final Map<String, String> _operationErrors = {};

  // Getters
  List<Map<String, dynamic>> get audioFiles => _getFilteredAudioFiles();
  List<Map<String, dynamic>> get allAudioFiles => _audioFiles;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  AudioPlaybackController get playbackController => _playbackController;
  
  /// Get filtered audio files based on search query with optimistic updates applied
  List<Map<String, dynamic>> _getFilteredAudioFiles() {
    List<Map<String, dynamic>> files = _audioFiles.map((file) {
      final audioId = file['id'] as String;
      
      // Apply optimistic updates if any
      if (_optimisticUpdates.containsKey(audioId)) {
        return {...file, ..._optimisticUpdates[audioId]!};
      }
      
      return file;
    }).toList();
    
    // Apply search filter
    if (_searchQuery.isEmpty) {
      return files;
    }
    
    return files.where((file) {
      final filename = (file['filename'] as String).toLowerCase();
      final category = (file['category'] as String).toLowerCase();
      final query = _searchQuery.toLowerCase();
      return filename.contains(query) || category.contains(query);
    }).toList();
  }
  
  /// Check if an operation is currently processing
  bool isProcessing(String audioId, [String? operation]) {
    if (operation != null) {
      return _processingOperations.contains('${audioId}_$operation');
    }
    return _processingOperations.any((op) => op.startsWith('${audioId}_'));
  }
  
  /// Get error for a specific operation
  String? getOperationError(String audioId, String operation) {
    return _operationErrors['${audioId}_$operation'];
  }

  AudioLibraryController() {
    _playbackController.addListener(_onPlaybackStateChanged);
    loadAudioFiles();
  }

  void _onPlaybackStateChanged() {
    // Propagate playback state changes
    notifyListeners();
  }

  /// Load all audio files from storage
  Future<void> loadAudioFiles() async {
    try {
      _setLoading(true);
      _clearError();
      
      final files = await _storageService.getAudioFiles();
      _audioFiles = files;
      
    } catch (e) {
      _setError('Failed to load audio files: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// Refresh audio files (pull-to-refresh)
  Future<void> refreshAudioFiles() async {
    await loadAudioFiles();
  }

  /// Update search query and filter results
  void updateSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Clear search query
  void clearSearch() {
    updateSearchQuery('');
  }

  /// Rename audio file with optimistic update and rollback capability
  Future<bool> renameAudioFile(String audioId, String newName) async {
    final operationKey = '${audioId}_rename';
    
    try {
      // Validate new name
      if (newName.trim().isEmpty) {
        throw Exception('Name cannot be empty');
      }
      
      // Check for duplicates (excluding current file)
      final existingNames = _audioFiles
          .where((file) => file['id'] != audioId)
          .map((file) => file['filename'] as String)
          .toList();
      
      if (existingNames.contains(newName.trim())) {
        throw Exception('A file with this name already exists');
      }
      
      // Start processing
      _startProcessing(operationKey);
      
      // Apply optimistic update
      _applyOptimisticUpdate(audioId, {'filename': newName.trim()});
      
      // Stop audio if it's currently playing
      if (_playbackController.isAudioPlaying(audioId)) {
        await _playbackController.stopAudio();
      }
      
      // Perform actual update
      await _storageService.updateAudioFile(audioId, {'filename': newName.trim()});
      
      // Update local state with actual data
      final index = _audioFiles.indexWhere((file) => file['id'] == audioId);
      if (index != -1) {
        _audioFiles[index]['filename'] = newName.trim();
      }
      
      // Clear optimistic update
      _clearOptimisticUpdate(audioId);
      
      return true;
      
    } catch (e) {
      // Rollback optimistic update
      _clearOptimisticUpdate(audioId);
      _setOperationError(operationKey, e.toString());
      return false;
      
    } finally {
      _stopProcessing(operationKey);
    }
  }

  /// Toggle favorite status with optimistic update
  Future<bool> toggleFavorite(String audioId) async {
    final operationKey = '${audioId}_favorite';
    
    try {
      final audioFile = _audioFiles.firstWhere((file) => file['id'] == audioId);
      final currentFavoriteStatus = audioFile['isFavorite'] as bool;
      final newFavoriteStatus = !currentFavoriteStatus;
      
      // Start processing
      _startProcessing(operationKey);
      
      // Apply optimistic update
      _applyOptimisticUpdate(audioId, {'isFavorite': newFavoriteStatus});
      
      // Perform actual update
      await _storageService.updateAudioFile(audioId, {'isFavorite': newFavoriteStatus});
      
      // Update local state
      final index = _audioFiles.indexWhere((file) => file['id'] == audioId);
      if (index != -1) {
        _audioFiles[index]['isFavorite'] = newFavoriteStatus;
      }
      
      // Clear optimistic update
      _clearOptimisticUpdate(audioId);
      
      return true;
      
    } catch (e) {
      // Rollback optimistic update
      _clearOptimisticUpdate(audioId);
      _setOperationError(operationKey, e.toString());
      return false;
      
    } finally {
      _stopProcessing(operationKey);
    }
  }

  /// Delete audio file with confirmation and undo capability
  Future<bool> deleteAudioFile(String audioId) async {
    final operationKey = '${audioId}_delete';
    
    try {
      // Start processing
      _startProcessing(operationKey);
      
      // Stop audio if it's currently playing
      if (_playbackController.isAudioPlaying(audioId)) {
        await _playbackController.stopAudio();
      }
      
      // Store original file for potential undo (future enhancement)
      // final originalFile = _audioFiles.firstWhere((file) => file['id'] == audioId);
      
      // Remove from UI immediately (optimistic update)
      _audioFiles.removeWhere((file) => file['id'] == audioId);
      notifyListeners();
      
      // Perform actual deletion
      await _storageService.deleteAudioFile(audioId);
      
      return true;
      
    } catch (e) {
      // Rollback by reloading files
      await loadAudioFiles();
      _setOperationError(operationKey, e.toString());
      return false;
      
    } finally {
      _stopProcessing(operationKey);
    }
  }

  /// Get audio file by ID (with optimistic updates applied)
  Map<String, dynamic>? getAudioFile(String audioId) {
    final file = _audioFiles.firstWhere(
      (file) => file['id'] == audioId,
      orElse: () => <String, dynamic>{},
    );
    
    if (file.isEmpty) return null;
    
    // Apply optimistic updates if any
    if (_optimisticUpdates.containsKey(audioId)) {
      return {...file, ..._optimisticUpdates[audioId]!};
    }
    
    return file;
  }

  /// Retry a failed operation
  Future<bool> retryOperation(String audioId, String operation) async {
    _clearOperationError('${audioId}_$operation');
    
    switch (operation) {
      case 'rename':
        // For rename, we need the new name - this should be handled by the UI
        return false;
      case 'favorite':
        return await toggleFavorite(audioId);
      case 'delete':
        return await deleteAudioFile(audioId);
      default:
        return false;
    }
  }

  /// Clear all errors
  void clearAllErrors() {
    _operationErrors.clear();
    _clearError();
    notifyListeners();
  }

  /// Clear error for specific operation
  void clearOperationError(String audioId, String operation) {
    _clearOperationError('${audioId}_$operation');
  }

  // Private helper methods
  void _startProcessing(String operationKey) {
    _processingOperations.add(operationKey);
    _clearOperationError(operationKey);
    notifyListeners();
  }

  void _stopProcessing(String operationKey) {
    _processingOperations.remove(operationKey);
    notifyListeners();
  }

  void _applyOptimisticUpdate(String audioId, Map<String, dynamic> updates) {
    _optimisticUpdates[audioId] = {..._optimisticUpdates[audioId] ?? {}, ...updates};
    notifyListeners();
  }

  void _clearOptimisticUpdate(String audioId) {
    _optimisticUpdates.remove(audioId);
    notifyListeners();
  }

  void _setOperationError(String operationKey, String error) {
    _operationErrors[operationKey] = error;
    notifyListeners();
  }

  void _clearOperationError(String operationKey) {
    _operationErrors.remove(operationKey);
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _playbackController.removeListener(_onPlaybackStateChanged);
    _playbackController.dispose();
    super.dispose();
  }
}