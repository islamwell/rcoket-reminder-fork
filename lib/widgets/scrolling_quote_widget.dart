import 'dart:async';
import 'package:flutter/material.dart';

class ScrollingQuoteWidget extends StatefulWidget {
  final List<String> quotes;
  final Duration scrollDuration;
  final Duration displayDuration;
  final TextStyle? textStyle;

  const ScrollingQuoteWidget({
    super.key,
    required this.quotes,
    this.scrollDuration = const Duration(milliseconds: 800),
    this.displayDuration = const Duration(seconds: 4),
    this.textStyle,
  });

  @override
  State<ScrollingQuoteWidget> createState() => _ScrollingQuoteWidgetState();
}

class _ScrollingQuoteWidgetState extends State<ScrollingQuoteWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  int _currentQuoteIndex = 0;
  String _currentQuote = '';
  Timer? _displayTimer;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: widget.scrollDuration,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    if (widget.quotes.isNotEmpty) {
      _currentQuote = widget.quotes[0];
      _startQuoteRotation();
    }
  }

  @override
  void dispose() {
    _displayTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _startQuoteRotation() {
    if (!mounted) return;
    
    _animationController.forward();
    
    _displayTimer?.cancel();
    _displayTimer = Timer(widget.displayDuration, () {
      if (mounted) {
        _animationController.reverse().then((_) {
          if (mounted) {
            setState(() {
              _currentQuoteIndex = (_currentQuoteIndex + 1) % widget.quotes.length;
              _currentQuote = widget.quotes[_currentQuoteIndex];
            });
            _startQuoteRotation();
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Text(
          _currentQuote,
          style: widget.textStyle ?? TextStyle(
            fontSize: 18,
            color: Colors.white.withValues(alpha: 0.9),
            fontWeight: FontWeight.w400,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}