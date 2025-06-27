import 'package:flutter/material.dart';

/// 손바닥 오버레이 위젯
///
/// 대머리를 탭할 때 손바닥 이미지를 0.2초간 표시하는 위젯입니다.
class HandOverlay extends StatefulWidget {
  final Offset position;
  final VoidCallback? onAnimationComplete;
  final String imagePath;

  const HandOverlay({
    super.key,
    required this.position,
    this.onAnimationComplete,
    this.imagePath = 'assets/images/hand_palm.png',
  });

  @override
  State<HandOverlay> createState() => _HandOverlayState();
}

class _HandOverlayState extends State<HandOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 400), // 0.4초로 증가
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
    ));

    // 애니메이션 시작
    _controller.forward().then((_) {
      widget.onAnimationComplete?.call();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.position.dx - 52, // 손바닥 크기의 절반 (104/2 = 52)
      top: widget.position.dy - 52,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: _opacityAnimation.value,
              child: Container(
                width: 104, // 30% 증가 (80 * 1.3 = 104)
                height: 104,
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withValues(alpha: 0.5),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Image.asset(
                  widget.imagePath,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    // PNG 파일이 없을 경우 fallback으로 아이콘 사용
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.8),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withValues(alpha: 0.5),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.pan_tool,
                        color: Colors.white,
                        size: 52, // 30% 증가 (40 * 1.3 = 52)
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 다중 손바닥 오버레이 관리 위젯
///
/// 피버타임 중에 여러 개의 손바닥을 동시에 표시할 때 사용됩니다.
class MultiHandOverlay extends StatefulWidget {
  final List<Offset> positions;
  final VoidCallback? onAnimationComplete;
  final List<String> imagePaths;

  const MultiHandOverlay({
    super.key,
    required this.positions,
    this.onAnimationComplete,
    this.imagePaths = const [],
  });

  @override
  State<MultiHandOverlay> createState() => _MultiHandOverlayState();
}

class _MultiHandOverlayState extends State<MultiHandOverlay> {
  int _completedAnimations = 0;

  void _onSingleAnimationComplete() {
    _completedAnimations++;
    if (_completedAnimations >= widget.positions.length) {
      widget.onAnimationComplete?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: List.generate(widget.positions.length, (index) {
        final position = widget.positions[index];
        final imagePath =
            widget.imagePaths.isNotEmpty && index < widget.imagePaths.length
                ? widget.imagePaths[index]
                : 'assets/images/hand_palm.png';

        return HandOverlay(
          position: position,
          imagePath: imagePath,
          onAnimationComplete: _onSingleAnimationComplete,
        );
      }),
    );
  }
}
