import 'package:flutter/material.dart';
import '../../../utils/constants/colors.dart';

/// Expandable Text Widget - Handles long text content with expand/collapse functionality
///
/// This widget provides an alternative to ellipsis overflow by allowing users to
/// expand and collapse long text content. It automatically detects if text is
/// overflowing and only shows expand/collapse controls when needed.
///
/// Features:
/// - Automatic overflow detection
/// - Smooth expand/collapse animation
/// - Customizable styling
/// - Accessibility support
/// - Responsive design
class TExpandableText extends StatefulWidget {
  const TExpandableText({
    super.key,
    required this.text,
    this.style,
    this.maxLines = 2,
    this.expandText = 'Show more',
    this.collapseText = 'Show less',
    this.expandTextStyle,
    this.collapseTextStyle,
    this.textAlign = TextAlign.left,
    this.onTextTapped,
    this.showExpandButton = true,
  });

  final String text;
  final TextStyle? style;
  final int maxLines;
  final String expandText;
  final String collapseText;
  final TextStyle? expandTextStyle;
  final TextStyle? collapseTextStyle;
  final TextAlign textAlign;
  final VoidCallback? onTextTapped;
  final bool showExpandButton;

  @override
  State<TExpandableText> createState() => _TExpandableTextState();
}

class _TExpandableTextState extends State<TExpandableText>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  bool _isTextOverflowing = false;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _checkTextOverflow(constraints.maxWidth);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main text content
            GestureDetector(
              onTap: widget.onTextTapped,
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return Text(
                    widget.text,
                    style: widget.style,
                    maxLines: _isExpanded ? null : widget.maxLines,
                    overflow: _isExpanded ? null : TextOverflow.ellipsis,
                    textAlign: widget.textAlign,
                  );
                },
              ),
            ),

            // Expand/Collapse button
            if (widget.showExpandButton && _isTextOverflowing)
              _buildExpandButton(),
          ],
        );
      },
    );
  }

  /// Checks if text is overflowing the available width
  void _checkTextOverflow(double maxWidth) {
    final textSpan = TextSpan(
      text: widget.text,
      style: widget.style,
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      maxLines: widget.maxLines,
    );

    textPainter.layout(maxWidth: maxWidth);
    _isTextOverflowing = textPainter.didExceedMaxLines;
  }

  /// Builds the expand/collapse button
  Widget _buildExpandButton() {
    return GestureDetector(
      onTap: _toggleExpanded,
      child: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          _isExpanded ? widget.collapseText : widget.expandText,
          style: (widget.expandTextStyle ?? widget.collapseTextStyle) ??
              Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: TColors.primary,
                    fontWeight: FontWeight.w600,
                  //  decoration: TextDecoration.underline,
                  ),
        ),
      ),
    );
  }

  /// Toggles the expanded state with animation
  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });

    if (_isExpanded) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }
}

/// Tooltip Text Widget - Shows full text in tooltip on long press
///
/// Alternative solution for handling long text by showing the full content
/// in a tooltip when the user long presses on the text.
class TTooltipText extends StatelessWidget {
  const TTooltipText({
    super.key,
    required this.text,
    this.style,
    this.maxLines = 2,
    this.textAlign = TextAlign.left,
    this.tooltipText,
    this.showTooltip = true,
    this.onTextTapped,
  });

  final String text;
  final TextStyle? style;
  final int maxLines;
  final TextAlign textAlign;
  final String? tooltipText;
  final bool showTooltip;
  final VoidCallback? onTextTapped;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isOverflowing = _isTextOverflowing(constraints.maxWidth);
        final tooltipContent = tooltipText ?? text;

        Widget textWidget = Text(
          text,
          style: style,
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
          textAlign: textAlign,
        );

        if (onTextTapped != null) {
          textWidget = GestureDetector(
            onTap: onTextTapped,
            child: textWidget,
          );
        }

        if (showTooltip && isOverflowing) {
          return Tooltip(
            message: tooltipContent,
            preferBelow: false,
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
            child: textWidget,
          );
        }

        return textWidget;
      },
    );
  }

  /// Checks if text is overflowing
  bool _isTextOverflowing(double maxWidth) {
    final textSpan = TextSpan(
      text: text,
      style: style,
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      maxLines: maxLines,
    );

    textPainter.layout(maxWidth: maxWidth);
    return textPainter.didExceedMaxLines;
  }
}
