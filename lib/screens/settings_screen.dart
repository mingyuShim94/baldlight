import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../services/counting_service.dart';

/// 설정 화면
///
/// 이 화면은 다음 기능을 제공합니다:
/// - 진동 설정 토글
/// - 앱 평가하기 링크
/// - 앱 정보 표시
/// - 개발자 정보
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final CountingService _countingService = CountingService();
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  /// 앱 버전 정보 로드
  Future<void> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion = packageInfo.version;
      });
    } catch (e) {
      // 버전 정보를 가져올 수 없는 경우 기본값 사용
      setState(() {
        _appVersion = '1.0.1';
      });
    }
  }

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
          'Settings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 앱 정보 섹션
              _buildSectionCard(
                title: 'App Info',
                children: [
                  _buildInfoTile(
                    icon: Icons.flash_on,
                    title: 'Bald Clicker',
                    subtitle: _appVersion.isNotEmpty 
                        ? 'Bald Clicker Game v$_appVersion' 
                        : 'Bald Clicker Game',
                    trailing: null,
                  ),
                  _buildInfoTile(
                    icon: Icons.analytics,
                    title: 'Total Count',
                    subtitle: '${_countingService.currentCount} counts',
                    trailing: null,
                  ),
                  _buildInfoTile(
                    icon: Icons.video_library,
                    title: 'Ads Watched',
                    subtitle: '${_countingService.totalAdsWatched} ads',
                    trailing: null,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // 환경설정 섹션
              _buildSectionCard(
                title: 'Preferences',
                children: [
                  _buildInfoTile(
                    icon: Icons.vibration,
                    title: 'Vibration Feedback',
                    subtitle: 'Vibrate when tapping the bald',
                    trailing: Switch.adaptive(
                      value: _countingService.vibrationEnabled,
                      onChanged: (value) async {
                        await _countingService.toggleVibration();
                        setState(() {
                          // UI 업데이트
                        });
                      },
                      activeColor: colorScheme.primary,
                    ),
                  ),
                  _buildInfoTile(
                    icon: Icons.dark_mode,
                    title: 'Dark Mode',
                    subtitle: 'Follow system settings',
                    trailing: const Icon(
                      Icons.phone_android,
                      color: Colors.white54,
                    ),
                  ),
                  _buildInfoTile(
                    icon: Icons.restore,
                    title: 'Reset Game Data',
                    subtitle: 'Reset all counts and unlock progress',
                    trailing: const Icon(
                      Icons.warning,
                      color: Colors.red,
                    ),
                    onTap: _showResetDialog,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // 지원 섹션
              _buildSectionCard(
                title: 'Support',
                children: [
                  _buildInfoTile(
                    icon: Icons.star_rate,
                    title: 'Rate App',
                    subtitle: 'Leave a review on the App Store',
                    trailing: const Icon(
                      Icons.open_in_new,
                      color: Colors.white54,
                    ),
                    onTap: _launchAppStore,
                  ),
                  _buildInfoTile(
                    icon: Icons.feedback,
                    title: 'Send Feedback',
                    subtitle: 'Report bugs or suggestions',
                    trailing: const Icon(
                      Icons.open_in_new,
                      color: Colors.white54,
                    ),
                    onTap: _launchFeedback,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // 개발자 정보 섹션
              _buildSectionCard(
                title: 'Developer Info',
                children: [
                  _buildInfoTile(
                    icon: Icons.code,
                    title: 'Made with Flutter',
                    subtitle: 'Cross-platform development',
                    trailing: null,
                  ),
                  _buildInfoTile(
                    icon: Icons.favorite,
                    title: 'Developer',
                    subtitle: 'GgugguLab',
                    trailing: null,
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // 버전 정보 (하단)
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.flash_on,
                      color: colorScheme.primary,
                      size: 48,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Bald Clicker',
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _appVersion.isNotEmpty
                          ? 'Version $_appVersion'
                          : 'Version 1.0.1',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Fun Bald Clicker Game',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
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
    );
  }

  /// 섹션 카드 위젯 생성
  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 섹션 제목
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              title,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // 섹션 내용
          ...children,
        ],
      ),
    );
  }

  /// 정보 타일 위젯 생성
  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // 아이콘
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: Colors.white70,
                  size: 20,
                ),
              ),

              const SizedBox(width: 16),

              // 텍스트 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              // 우측 위젯
              if (trailing != null) trailing,
            ],
          ),
        ),
      ),
    );
  }

  /// 앱스토어 링크 열기
  Future<void> _launchAppStore() async {
    try {
      // Google Play Store URL
      const String url = 'https://play.google.com/store/apps/details?id=com.gguggulab.baldlight'; // 실제 플레이스토어 URL로 변경 필요

      final Uri uri = Uri.parse(url);

      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        _showErrorDialog('Unable to open App Store.');
      }
    } catch (e) {
      _showErrorDialog('An error occurred while opening App Store link: $e');
    }
  }

  /// 피드백 이메일 열기
  Future<void> _launchFeedback() async {
    try {
      const String email = 'gguggulab@gmail.com'; // 실제 이메일 주소로 변경 필요
      const String subject = 'Bald Clicker App Feedback';
      const String body = 'Hello! Please leave your feedback about the Bald Clicker app.\n\n';

      final Uri emailUri = Uri(
        scheme: 'mailto',
        path: email,
        query:
            'subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}',
      );

      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        _showErrorDialog('Unable to open email app.');
      }
    } catch (e) {
      _showErrorDialog('An error occurred while opening email: $e');
    }
  }

  /// 게임 데이터 초기화 확인 다이얼로그 표시
  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Row(
          children: [
            Icon(
              Icons.warning,
              color: Colors.red,
              size: 28,
            ),
            const SizedBox(width: 12),
            const Text(
              'Reset Game Data',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This action will permanently delete:',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 12),
            Text(
              '• All your tap counts',
              style: TextStyle(color: Colors.white60, fontSize: 14),
            ),
            Text(
              '• All unlocked bald styles',
              style: TextStyle(color: Colors.white60, fontSize: 14),
            ),
            Text(
              '• Ads watched statistics',
              style: TextStyle(color: Colors.white60, fontSize: 14),
            ),
            SizedBox(height: 16),
            Text(
              'This action cannot be undone!',
              style: TextStyle(
                color: Colors.red,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _resetGameData();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text(
              'Reset',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  /// 게임 데이터 초기화 실행
  Future<void> _resetGameData() async {
    if (!mounted) return;
    
    try {
      // 로딩 다이얼로그 표시
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.grey[900],
          content: const Row(
            children: [
              CircularProgressIndicator(color: Colors.orange),
              SizedBox(width: 16),
              Text(
                'Resetting game data...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );

      // 카운팅 서비스 리셋 실행
      await _countingService.resetCount();

      // mounted 체크 후 context 사용
      if (!mounted) return;

      // 로딩 다이얼로그 닫기
      Navigator.of(context).pop();

      // UI 업데이트
      setState(() {});

      // 성공 메시지 표시 후 메인 화면으로 복귀
      _showSuccessDialog('Game data has been reset successfully!', returnToMain: true);
    } catch (e) {
      // mounted 체크 후 context 사용
      if (!mounted) return;
      
      // 로딩 다이얼로그 닫기
      Navigator.of(context).pop();
      
      // 에러 메시지 표시
      _showErrorDialog('Failed to reset game data: $e');
    }
  }

  /// 성공 메시지 다이얼로그 표시
  void _showSuccessDialog(String message, {bool returnToMain = false}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 28,
            ),
            const SizedBox(width: 12),
            const Text(
              'Success',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // 다이얼로그 닫기
              if (returnToMain) {
                // 설정 화면을 닫고 메인 화면으로 복귀
                Navigator.of(context).pop();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text(returnToMain ? 'Back to Game' : 'OK'),
          ),
        ],
      ),
    );
  }

  /// 에러 메시지 다이얼로그 표시
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Error',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'OK',
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }
}
