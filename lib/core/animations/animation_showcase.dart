import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../app_export.dart';
import '../../presentation/audio_library/widgets/animated_play_button.dart';
import '../../presentation/audio_library/widgets/loading_overlay.dart';

/// Animation showcase widget for testing and demonstrating all animation components
/// 
/// This widget is primarily for development and testing purposes to ensure
/// all animation components work correctly and provide visual feedback.
/// 
/// Features demonstrated:
/// - Button feedback animations
/// - State transition animations
/// - Loading indicators
/// - Waveform visualizations
/// - Color transitions
/// - Scale animations
/// - Selection indicators
/// 
/// Requirements implemented: 7.1, 7.2, 7.6

class AnimationShowcase extends StatefulWidget {
  const AnimationShowcase({super.key});

  @override
  State<AnimationShowcase> createState() => _AnimationShowcaseState();
}

class _AnimationShowcaseState extends State<AnimationShowcase>
    with TickerProviderStateMixin {
  bool _isPlaying = false;
  bool _isFavorite = false;
  bool _isSelected = false;
  bool _showLoading = false;
  bool _showSuccess = false;
  bool _showError = false;
  LoadingType _currentLoadingType = LoadingType.circular;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Animation Showcase'),
        backgroundColor: AppTheme.lightTheme.colorScheme.surface,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Button Animations'),
            _buildButtonAnimationsSection(),
            SizedBox(height: 4.h),
            
            _buildSectionTitle('Play Button Variations'),
            _buildPlayButtonSection(),
            SizedBox(height: 4.h),
            
            _buildSectionTitle('Loading Indicators'),
            _buildLoadingSection(),
            SizedBox(height: 4.h),
            
            _buildSectionTitle('Waveform Animations'),
            _buildWaveformSection(),
            SizedBox(height: 4.h),
            
            _buildSectionTitle('State Transitions'),
            _buildStateTransitionSection(),
            SizedBox(height: 4.h),
            
            _buildSectionTitle('Feedback Overlays'),
            _buildOverlaySection(),
            SizedBox(height: 4.h),
            
            _buildSectionTitle('Progress Indicators'),
            _buildProgressSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 2.h),
      child: Text(
        title,
        style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: AppTheme.lightTheme.colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildButtonAnimationsSection() {
    return Wrap(
      spacing: 3.w,
      runSpacing: 2.h,
      children: [
        AnimatedActionButton(
          iconName: 'play_arrow',
          onTap: () {},
          color: AppTheme.lightTheme.colorScheme.primary,
          backgroundColor: AppTheme.lightTheme.colorScheme.primaryContainer,
          tooltip: 'Play button',
        ),
        AnimatedActionButton(
          iconName: 'edit',
          onTap: () {},
          color: AppTheme.lightTheme.colorScheme.secondary,
          backgroundColor: AppTheme.lightTheme.colorScheme.secondaryContainer,
          tooltip: 'Edit button',
        ),
        AnimatedActionButton(
          iconName: 'delete',
          onTap: () {},
          color: AppTheme.lightTheme.colorScheme.error,
          backgroundColor: AppTheme.lightTheme.colorScheme.errorContainer,
          tooltip: 'Delete button',
        ),
        AnimatedActionButton(
          iconName: 'share',
          onTap: () {},
          isLoading: true,
          tooltip: 'Loading button',
        ),
        AnimatedActionButton(
          iconName: 'download',
          onTap: null,
          isDisabled: true,
          tooltip: 'Disabled button',
        ),
      ],
    );
  }

  Widget _buildPlayButtonSection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            AnimatedPlayButton(
              isPlaying: _isPlaying,
              onPlay: () => setState(() => _isPlaying = true),
              onPause: () => setState(() => _isPlaying = false),
              size: 15.w,
              showPulse: true,
            ),
            AnimatedPlayButton(
              isPlaying: false,
              isLoading: true,
              size: 12.w,
            ),
            AnimatedPlayButton(
              isPlaying: _isPlaying,
              onPlay: () => setState(() => _isPlaying = true),
              onPause: () => setState(() => _isPlaying = false),
              size: 10.w,
              primaryColor: AppTheme.lightTheme.colorScheme.tertiary,
              showPulse: false,
            ),
          ],
        ),
        SizedBox(height: 2.h),
        AnimatedFavoriteButton(
          isFavorite: _isFavorite,
          onToggle: () => setState(() => _isFavorite = !_isFavorite),
          size: 24,
        ),
      ],
    );
  }

  Widget _buildLoadingSection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: LoadingType.values.map((type) {
            return Column(
              children: [
                AnimatedLoadingIndicator(
                  type: type,
                  color: AppTheme.lightTheme.colorScheme.primary,
                  size: 8.w,
                ),
                SizedBox(height: 1.h),
                Text(
                  type.name,
                  style: AppTheme.lightTheme.textTheme.bodySmall,
                ),
              ],
            );
          }).toList(),
        ),
        SizedBox(height: 3.h),
        ElevatedButton(
          onPressed: () => setState(() => _showLoading = !_showLoading),
          child: Text(_showLoading ? 'Hide Loading' : 'Show Loading'),
        ),
        if (_showLoading)
          LoadingOverlay(
            isVisible: _showLoading,
            message: 'Processing audio file...',
            loadingType: _currentLoadingType,
            progress: 0.65,
            onCancel: () => setState(() => _showLoading = false),
          ),
      ],
    );
  }

  Widget _buildWaveformSection() {
    return Column(
      children: [
        AnimatedWaveform(
          isPlaying: _isPlaying,
          width: 80.w,
          height: 8.h,
          color: AppTheme.lightTheme.colorScheme.primary,
          barCount: 30,
          showGlow: true,
        ),
        SizedBox(height: 2.h),
        AnimatedWaveform(
          isPlaying: _isPlaying,
          width: 60.w,
          height: 6.h,
          color: AppTheme.lightTheme.colorScheme.tertiary,
          barCount: 20,
          strokeWidth: 3.0,
          showGlow: false,
        ),
        SizedBox(height: 2.h),
        AnimatedWaveform(
          isPlaying: _isPlaying,
          width: 40.w,
          height: 4.h,
          color: AppTheme.lightTheme.colorScheme.secondary,
          barCount: 15,
          strokeWidth: 1.5,
          showGlow: true,
        ),
      ],
    );
  }

  Widget _buildStateTransitionSection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            AnimatedSelectionIndicator(
              isSelected: _isSelected,
              selectedColor: AppTheme.lightTheme.colorScheme.primary,
              size: 12.w,
            ),
            AnimatedStateTransition(
              trigger: _isSelected,
              animationType: AnimationType.scale,
              child: Container(
                width: 12.w,
                height: 12.w,
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.colorScheme.secondary,
                  borderRadius: BorderRadius.circular(AppTheme.smallRadius),
                ),
                child: const Icon(Icons.star, color: Colors.white),
              ),
            ),
            AnimatedStateTransition(
              trigger: _isSelected,
              animationType: AnimationType.fade,
              child: Container(
                width: 12.w,
                height: 12.w,
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.colorScheme.tertiary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white),
              ),
            ),
          ],
        ),
        SizedBox(height: 3.h),
        ElevatedButton(
          onPressed: () => setState(() => _isSelected = !_isSelected),
          child: Text(_isSelected ? 'Deselect' : 'Select'),
        ),
      ],
    );
  }

  Widget _buildOverlaySection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: () => setState(() => _showSuccess = true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.lightTheme.colorScheme.tertiary,
              ),
              child: const Text('Success'),
            ),
            ElevatedButton(
              onPressed: () => setState(() => _showError = true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.lightTheme.colorScheme.error,
              ),
              child: const Text('Error'),
            ),
          ],
        ),
        if (_showSuccess)
          SuccessOverlay(
            isVisible: _showSuccess,
            message: 'Audio file saved successfully!',
            onComplete: () => setState(() => _showSuccess = false),
          ),
        if (_showError)
          ErrorOverlay(
            isVisible: _showError,
            message: 'Failed to process audio file. Please try again.',
            actionText: 'Retry',
            onAction: () => setState(() => _showError = false),
            onDismiss: () => setState(() => _showError = false),
          ),
      ],
    );
  }

  Widget _buildProgressSection() {
    return Column(
      children: [
        AnimatedProgressIndicator(
          progress: 0.3,
          color: AppTheme.lightTheme.colorScheme.primary,
          backgroundColor: AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.3),
          height: 6,
          showGlow: true,
        ),
        SizedBox(height: 2.h),
        AnimatedProgressIndicator(
          progress: 0.7,
          color: AppTheme.lightTheme.colorScheme.secondary,
          backgroundColor: AppTheme.lightTheme.colorScheme.secondary.withValues(alpha: 0.3),
          height: 8,
          borderRadius: BorderRadius.circular(4),
        ),
        SizedBox(height: 2.h),
        AnimatedProgressIndicator(
          progress: 0.9,
          color: AppTheme.lightTheme.colorScheme.tertiary,
          backgroundColor: AppTheme.lightTheme.colorScheme.tertiary.withValues(alpha: 0.3),
          height: 4,
        ),
      ],
    );
  }
}