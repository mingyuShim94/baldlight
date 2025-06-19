import 'package:flutter/material.dart';
import '../services/bald_style_service.dart';
import '../services/counting_service.dart';

/// 대머리 보관함 화면
///
/// 이 화면은 다음 기능을 제공합니다:
/// - 해금된 대머리 스타일 목록 표시
/// - 잠긴 스타일은 자물쇠와 해금 조건 표시
/// - 스타일 선택 및 적용
/// - 현재 선택된 스타일 하이라이트
class CollectionScreen extends StatefulWidget {
  const CollectionScreen({super.key});

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  final BaldStyleService _baldStyleService = BaldStyleService();
  final CountingService _countingService = CountingService();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text(
          'Bald Collection',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더 정보
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: colorScheme.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current Count: ${_countingService.currentCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _countingService.countToNextUnlock > 0 
                                ? 'To next unlock: ${_countingService.countToNextUnlock} (${_countingService.nextUnlockStyleName})'
                                : 'All styles unlocked!',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 스타일 목록 제목
              const Text(
                'Bald Style List',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              // 스타일 그리드
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: _baldStyleService.availableStyles.length,
                  itemBuilder: (context, index) {
                    final style = _baldStyleService.availableStyles[index];
                    final isSelected = style.id == _baldStyleService.selectedStyle.id;
                    final isUnlocked = style.isUnlocked;

                    return _buildStyleCard(
                      style: style,
                      isSelected: isSelected,
                      isUnlocked: isUnlocked,
                      colorScheme: colorScheme,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 스타일 카드 위젯 생성
  Widget _buildStyleCard({
    required BaldStyle style,
    required bool isSelected,
    required bool isUnlocked,
    required ColorScheme colorScheme,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected 
              ? colorScheme.primary
              : isUnlocked 
                  ? Colors.white.withValues(alpha: 0.3)
                  : Colors.grey.withValues(alpha: 0.3),
          width: isSelected ? 3 : 1,
        ),
        color: isSelected 
            ? colorScheme.primary.withValues(alpha: 0.2)
            : Colors.grey.withValues(alpha: 0.1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: isUnlocked ? () => _selectStyle(style) : null,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                // 스타일 이미지
                Expanded(
                  flex: 3,
                  child: Stack(
                    children: [
                      // 배경 이미지 (선택된 스타일은 on, 나머지는 off)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          isSelected ? style.onImagePath : style.offImagePath,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          color: isUnlocked ? null : Colors.black.withValues(alpha: 0.6),
                          colorBlendMode: isUnlocked ? null : BlendMode.darken,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.grey.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.image_not_supported,
                                  color: Colors.white54,
                                  size: 32,
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      // 잠금 오버레이
                      if (!isUnlocked)
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.lock,
                                  color: Colors.white,
                                  size: 32,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${style.unlockCount}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Text(
                                  'counts needed',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // 선택됨 표시
                      if (isSelected)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // 스타일 정보
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      Text(
                        style.name,
                        style: TextStyle(
                          color: isUnlocked ? Colors.white : Colors.white54,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isUnlocked 
                            ? (isSelected ? 'In Use' : 'Tap to Select')
                            : 'Locked',
                        style: TextStyle(
                          color: isUnlocked 
                              ? (isSelected ? colorScheme.primary : Colors.white70)
                              : Colors.white54,
                          fontSize: 11,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 스타일 선택 처리
  Future<void> _selectStyle(BaldStyle style) async {
    try {
      final success = await _baldStyleService.selectStyle(style.id);
      
      if (!mounted) return;
      
      if (success) {
        setState(() {
          // UI 업데이트를 위한 setState
        });

        // 선택 완료 피드백
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${style.name} has been selected!'),
              backgroundColor: Theme.of(context).colorScheme.primary,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (mounted) {
          _showErrorDialog('Failed to select style.');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('An error occurred while selecting style: $e');
      }
    }
  }

  /// 에러 메시지 다이얼로그 표시
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}