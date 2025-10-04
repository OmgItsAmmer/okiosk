import 'dart:async';
import 'package:flutter/material.dart';
import 'package:okiosk/utils/constants/colors.dart';

/// Typewriter Animation Widget for Search Hint Text
///
/// Features:
/// - Typewriter effect that writes out complete lines character by character
/// - Cycles through multiple hint lines in a loop
/// - Smooth transitions between different hint texts
class TypewriterHintText extends StatefulWidget {
  final List<String> hintTexts;
  final TextStyle? textStyle;
  final Duration typingSpeed;
  final Duration pauseBetweenLines;
  final Duration pauseBetweenCycles;

  const TypewriterHintText({
    super.key,
    required this.hintTexts,
    this.textStyle,
    this.typingSpeed = const Duration(milliseconds: 100),
    this.pauseBetweenLines = const Duration(milliseconds: 1500),
    this.pauseBetweenCycles = const Duration(milliseconds: 2000),
  });

  @override
  State<TypewriterHintText> createState() => _TypewriterHintTextState();
}

class _TypewriterHintTextState extends State<TypewriterHintText> {
  int _currentLineIndex = 0;
  int _currentCharIndex = 0;
  String _displayedText = '';
  Timer? _typingTimer;
  Timer? _pauseTimer;
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    _startTypingAnimation();
  }

  void _startTypingAnimation() {
    if (widget.hintTexts.isEmpty) return;

    _typingTimer = Timer.periodic(widget.typingSpeed, (timer) {
      if (!mounted) return;

      if (!_isPaused && _currentLineIndex < widget.hintTexts.length) {
        _typeNextCharacter();
      }
    });
  }

  void _typeNextCharacter() {
    if (widget.hintTexts.isEmpty) return;
    if (_currentLineIndex >= widget.hintTexts.length) return;
    final currentLine = widget.hintTexts[_currentLineIndex];

    if (_currentCharIndex < currentLine.length) {
      setState(() {
        _displayedText = currentLine.substring(0, _currentCharIndex + 1);
        _currentCharIndex++;
      });
    } else {
      // Line is complete, pause before next line
      _pauseBeforeNextLine();
    }
  }

  void _pauseBeforeNextLine() {
    _isPaused = true;
    _pauseTimer = Timer(widget.pauseBetweenLines, () {
      if (!mounted) return;

      setState(() {
        // Move to next line; allow it to temporarily exceed length, but guard reads elsewhere
        _currentLineIndex++;
        _currentCharIndex = 0;
        _displayedText = '';
        _isPaused = false;
      });

      // If we've completed all lines, restart the cycle
      if (_currentLineIndex >= widget.hintTexts.length) {
        _restartCycle();
      }
    });
  }

  void _restartCycle() {
    _pauseTimer = Timer(widget.pauseBetweenCycles, () {
      if (!mounted) return;

      setState(() {
        _currentLineIndex = 0;
        _currentCharIndex = 0;
        _displayedText = '';
        _isPaused = false;
      });
    });
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _pauseTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool hasLines = widget.hintTexts.isNotEmpty;
    final int safeIndex = hasLines
        ? (_currentLineIndex.clamp(0, widget.hintTexts.length - 1))
        : 0;
    final String currentLine = hasLines ? widget.hintTexts[safeIndex] : '';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _displayedText,
          style: widget.textStyle ??
              Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: TColors.lightModeSecondaryText,
                  ),
        ),
        // Blinking cursor effect
        if (_isPaused || _currentCharIndex < currentLine.length)
          AnimatedOpacity(
            opacity: _isPaused ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 500),
            child: Container(
              width: 1,
              height: 16,
              color: TColors.lightModeSecondaryText,
              margin: const EdgeInsets.only(left: 1),
            ),
          ),
      ],
    );
  }
}
