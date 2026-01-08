import 'dart:async' as async; // "as async" diyerek çakışmayı önlüyoruz
import 'dart:ui';
import 'dart:math';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flame/components.dart' hide Matrix4;
import 'package:flame/game.dart' hide Matrix4;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // --- EKRANI DİKEY KİLİTLEME KODU ---
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await MobileAds.instance.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
    );
  }
}

// --- SPLASH SCREEN (Jöle Animasyonlu) ---
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    // Dış çemberin nefes alma efekti
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _initApp();
  }

  Future<void> _initApp() async {
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const WelcomePage(),
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 280),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFE1F5FE),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00B0FF).withOpacity(0.4),
                  blurRadius: 50,
                  spreadRadius: 10,
                ),
              ],
            ),
            // --- DEĞİŞİKLİK BURADA ---
            // Eski sabit Icon yerine hareketli Jöle ikonunu koyduk
            child: const SizedBox(
              width: 100,
              height: 100,
              child: MorphingJellyIcon(color: Color(0xFF00B0FF), size: 100),
            ),
          ),
        ),
      ),
    );
  }
}

// --- JELLY BUTON ---
class JellyButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final Color color;
  final bool isDarkMode;
  final double width;
  final IconData? icon;

  const JellyButton({
    super.key,
    required this.text,
    required this.onPressed,
    required this.color,
    required this.isDarkMode,
    this.width = 200,
    this.icon,
  });

  @override
  State<JellyButton> createState() => _JellyButtonState();
}

class _JellyButtonState extends State<JellyButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    _controller.value = 0.0;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    HapticFeedback.lightImpact();
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    Future.delayed(const Duration(milliseconds: 100), widget.onPressed);
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          double scaleValue = 1.0 - (_controller.value * 0.1);

          return Transform.scale(
            scale: scaleValue,
            child: Container(
              width: widget.width,
              height: 70,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(35),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [widget.color.withOpacity(0.9), widget.color],
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withOpacity(0.5),
                    blurRadius: 15,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 5,
                    left: 20,
                    right: 20,
                    height: 25,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withOpacity(0.4),
                            Colors.white.withOpacity(0.0),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.icon != null) ...[
                          Icon(widget.icon, color: Colors.white, size: 28),
                          const SizedBox(width: 10),
                        ],
                        Text(
                          widget.text,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                            shadows: [
                              Shadow(
                                color: Colors.black26,
                                offset: Offset(1, 2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// --- JELLY STAT KUTUSU ---
class JellyStatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isDarkMode;

  const JellyStatBox({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.grey[100],
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: color.withOpacity(0.5), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white70 : Colors.grey[600],
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// --- GÜNCELLENMİŞ REKLAM YÖNETİCİSİ ---
class AdManager {
  RewardedAd? _rewardedAd;
  InterstitialAd? _interstitialAd;
  bool isRewardedAdLoaded = false;
  bool isInterstitialAdLoaded = false;

  static int menuReturnCounter = 0;

  final String _rewardedAdUnitId = Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/5224354917'
      : 'ca-app-pub-5955635115080708/1693780996';
  final String _interstitialAdUnitId = Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/1033173712'
      : 'ca-app-pub-5955635115080708/6761101382';
  BannerAd? _bannerAd;
  bool isBannerAdLoaded = false;

  final String _bannerAdUnitId = Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/6300978111' // Android Standart Test ID
      : 'ca-app-pub-5955635115080708/7876045962'; // iOS Standart Test ID
  // --- BANNER REKLAM YÜKLEME ---
  void loadBannerAd(VoidCallback onAdLoaded) {
    // AdManager içindeki loadBannerAd veya loadRewardedAd içine:

    _bannerAd = BannerAd(
      adUnitId: _bannerAdUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          isBannerAdLoaded = true;
          onAdLoaded();
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          isBannerAdLoaded = false;
          print('Banner yüklenemedi: $error');
        },
      ),
    );
    _bannerAd!.load();
  }

  // Banner nesnesine erişmek için getter
  BannerAd? get bannerAd => _bannerAd;

  // Bellek temizliği için dispose metoduna ekle
  void dispose() {
    _bannerAd?.dispose();
    _rewardedAd?.dispose();
    _interstitialAd?.dispose();
  }

  // --- ÖDÜLLÜ REKLAM YÜKLEME ---
  void loadRewardedAd() {
    RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          isRewardedAdLoaded = true;
        },
        onAdFailedToLoad: (LoadAdError error) {
          _rewardedAd = null;
          isRewardedAdLoaded = false;
          Future.delayed(const Duration(seconds: 5), () => loadRewardedAd());
        },
      ),
    );
  }

  // --- GEÇİŞ REKLAMI YÜKLEME (Hata Veren Kısım Buydu) ---
  void loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          isInterstitialAdLoaded = true;
        },
        onAdFailedToLoad: (LoadAdError error) {
          _interstitialAd = null;
          isInterstitialAdLoaded = false;
          Future.delayed(
            const Duration(seconds: 10),
            () => loadInterstitialAd(),
          );
        },
      ),
    );
  }

  // --- ÖDÜLLÜ REKLAM GÖSTERME ---
  void showRewardedAd({
    required Function onRewardEarned,
    required Function onAdDismissed,
  }) {
    if (_rewardedAd == null) {
      loadRewardedAd();
      onAdDismissed();
      return;
    }
    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        loadRewardedAd();
        onAdDismissed();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        loadRewardedAd();
        onAdDismissed();
      },
    );
    _rewardedAd!.show(onUserEarnedReward: (ad, reward) => onRewardEarned());
    _rewardedAd = null;
    isRewardedAdLoaded = false;
  }

  // --- GEÇİŞ REKLAMI GÖSTERME ---
  void showInterstitialAd({VoidCallback? onAdDismissed}) {
    if (_interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          loadInterstitialAd();
          if (onAdDismissed != null) onAdDismissed();
        },
        onAdFailedToShowFullScreenContent: (ad, err) {
          ad.dispose();
          loadInterstitialAd();
          if (onAdDismissed != null) onAdDismissed();
        },
      );
      _interstitialAd!.show();
      _interstitialAd = null;
      isInterstitialAdLoaded = false;
    } else {
      loadInterstitialAd();
      if (onAdDismissed != null) onAdDismissed();
    }
  }
}

// --- KARŞILAMA EKRANI ---
class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});
  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  bool isDarkMode = false;
  int bestScore = 0;
  int maxLevel = 0;
  final AdManager _adManager = AdManager();
  BannerAd? _banner;

  @override
  void initState() {
    super.initState();
    _loadData();

    // --- BANNER YÜKLE ---
    _adManager.loadBannerAd(() {
      if (mounted) {
        setState(() {
          _banner = _adManager.bannerAd;
        });
      }
    });
  }

  @override
  void dispose() {
    // Sayfadan çıkınca reklamı temizle
    _adManager.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      bestScore = prefs.getInt('bestScore') ?? 0;
      maxLevel = prefs.getInt('maxLevel') ?? 1;
    });
  }

  void _showHowToPlayDialog(BuildContext context, Color themeColor) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (ctx) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(20),
            child: Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    isDarkMode
                        ? const Color(0xFF2E0249).withOpacity(0.9)
                        : Colors.white.withOpacity(0.95),
                    isDarkMode
                        ? Colors.black.withOpacity(0.9)
                        : const Color(0xFFE1F5FE).withOpacity(0.95),
                  ],
                ),
                border: Border.all(
                  color: themeColor.withOpacity(0.5),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: themeColor.withOpacity(0.4),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "HOW TO PLAY",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: themeColor,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildInstructionRow(
                    Icons.touch_app_rounded,
                    "Drag anywhere to reshape.",
                    themeColor,
                  ),
                  const SizedBox(height: 15),
                  _buildInstructionRow(
                    Icons.crop_square_rounded,
                    "Match the hole shape.",
                    themeColor,
                  ),
                  const SizedBox(height: 15),
                  _buildInstructionRow(
                    Icons.timer_rounded,
                    "Survive 30s to Level Up!",
                    themeColor,
                  ),
                  const SizedBox(height: 30),
                  JellyButton(
                    text: "GOT IT!",
                    width: 160,
                    color: themeColor,
                    isDarkMode: isDarkMode,
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInstructionRow(IconData icon, String text, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white70 : Colors.black87,
              letterSpacing: 1.0,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    Color bgColor = isDarkMode ? const Color(0xFF1A1A2E) : Colors.white;
    Color textColor = isDarkMode
        ? const Color(0xFFFF00CC)
        : const Color(0xFF37474F);
    Color subTextColor = isDarkMode ? Colors.cyanAccent : Colors.grey[600]!;
    Color buttonColor = isDarkMode
        ? const Color(0xFFFF00CC)
        : const Color(0xFF00B0FF);
    Color secondaryButtonColor = isDarkMode
        ? Colors.cyanAccent
        : const Color(0xFFFF7043);
    Color iconBgColor = isDarkMode
        ? const Color(0xFF16213E)
        : const Color(0xFFE1F5FE);
    Color iconColor = isDarkMode ? Colors.cyanAccent : const Color(0xFF00B0FF);

    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          Expanded(
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: iconBgColor,
                          boxShadow: [
                            BoxShadow(
                              color: iconColor.withOpacity(0.3),
                              blurRadius: 30,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        child: // ... WelcomePage build metodu içinde ...
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: iconBgColor,
                            boxShadow: [
                              BoxShadow(
                                color: iconColor.withOpacity(0.3),
                                blurRadius: 30,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          // ESKİ KOD:
                          // child: Icon(
                          // Icons.change_history_rounded,
                          // size: 80,
                          // color: iconColor,
                          // ),

                          // YENİ KOD (Jöle Animasyonlu İkon):
                          child: SizedBox(
                            width: 80,
                            height: 80,
                            child: MorphingJellyIcon(
                              color: iconColor,
                              size: 80,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      Text(
                        "JELLY\nSPRINT",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          height: 1.0,
                          color: textColor,
                          letterSpacing: 2.0,
                          shadows: isDarkMode
                              ? [Shadow(blurRadius: 10, color: textColor)]
                              : [],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Fit the shape to survive!",
                        style: TextStyle(
                          fontSize: 18,
                          color: subTextColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          JellyStatBox(
                            label: "BEST SCORE",
                            value: "$bestScore",
                            color: textColor,
                            isDarkMode: isDarkMode,
                          ),
                          const SizedBox(width: 20),
                          JellyStatBox(
                            label: "MAX LEVEL",
                            value: "$maxLevel",
                            color: secondaryButtonColor,
                            isDarkMode: isDarkMode,
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.black26 : Colors.grey[100],
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: iconColor.withOpacity(0.5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.wb_sunny,
                              color: isDarkMode ? Colors.grey : Colors.orange,
                            ),
                            const SizedBox(width: 10),
                            Switch(
                              value: isDarkMode,
                              activeColor: const Color(0xFFFF00CC),
                              onChanged: (val) {
                                setState(() {
                                  isDarkMode = val;
                                });
                              },
                            ),
                            const SizedBox(width: 10),
                            Icon(
                              Icons.nightlight_round,
                              color: isDarkMode
                                  ? Colors.cyanAccent
                                  : Colors.grey,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                      JellyButton(
                        text: "PLAY",
                        color: buttonColor,
                        isDarkMode: isDarkMode,
                        width: 240,
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (context) =>
                                  DoughGamePage(isDarkMode: isDarkMode),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      JellyButton(
                        text: "HOW TO PLAY",
                        color: secondaryButtonColor,
                        isDarkMode: isDarkMode,
                        width: 240,
                        onPressed: () {
                          _showHowToPlayDialog(context, buttonColor);
                        },
                      ),
                      const SizedBox(height: 20),
                      JellyButton(
                        // <<< Bu butonu güncelliyoruz
                        text: "TUTORIAL", // <<< GÜNCELLENDİ: "TUTORIAL"
                        color: secondaryButtonColor,
                        isDarkMode: isDarkMode,
                        width: 240,
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  TutorialPage(isDarkMode: isDarkMode),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // 2. Banner Reklam Alanı (En Altta)
          if (_adManager.isBannerAdLoaded && _banner != null)
            SafeArea(
              top: false,
              child: // Reklam alanını sarmalayan Container'ı bul ve rengini saydam yap
              Container(
                alignment: Alignment.center,
                color: Colors.transparent, // Arka planı tamamen saydam yapar
                width: _banner!.size.width.toDouble(),
                height: _banner!.size.height.toDouble(),
                child: AdWidget(ad: _banner!),
              ),
            ),
        ],
      ),
    );
  }
}

class TutorialPage extends StatelessWidget {
  final bool isDarkMode;
  const TutorialPage({super.key, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    final bgColor = isDarkMode ? const Color(0xFF1A1A2E) : Colors.white;
    final textColor = isDarkMode ? Colors.white : const Color(0xFF37474F);
    final mainColor = isDarkMode
        ? const Color(0xFFFF00CC)
        : const Color(0xFF00B0FF);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "TUTORIAL",
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: mainColor,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "• Drag anywhere to reshape\n"
                  "• Match the hole shape\n"
                  "• Survive to level up",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: textColor.withOpacity(0.9),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                JellyButton(
                  text: "START TUTORIAL",
                  width: 260,
                  color: mainColor,
                  isDarkMode: isDarkMode,
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => DoughGamePage(
                          isDarkMode: isDarkMode,
                          isTutorial: true,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 14),
                JellyButton(
                  text: "BACK",
                  width: 260,
                  color: Colors.grey,
                  isDarkMode: isDarkMode,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- JÖLE ŞEKİL DEĞİŞTİRİCİ WIDGET ---
enum JellyShapeType { triangle, square, rectangle, circle }

class MorphingJellyIcon extends StatefulWidget {
  final Color color;
  final double size;

  const MorphingJellyIcon({super.key, required this.color, required this.size});

  @override
  State<MorphingJellyIcon> createState() => _MorphingJellyIconState();
}

class _MorphingJellyIconState extends State<MorphingJellyIcon>
    with TickerProviderStateMixin {
  late AnimationController _morphController;
  late Animation<double> _elasticAnimation;
  int _currentIndex = 0;
  final List<JellyShapeType> _shapes = [
    JellyShapeType.triangle,
    JellyShapeType.square,
    JellyShapeType.rectangle,
    JellyShapeType.circle, // <<-- YENİ
  ];

  // DEĞİŞİKLİK BURADA: 'async.Timer' kullanıyoruz
  async.Timer? _timer;

  @override
  void initState() {
    super.initState();
    _morphController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _elasticAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _morphController,
        curve: Curves.elasticOut,
        reverseCurve: Curves.easeIn,
      ),
    );

    _morphController.forward(from: 0.0);

    // DEĞİŞİKLİK BURADA: 'async.Timer.periodic' kullanıyoruz
    _timer = async.Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        // mounted kontrolü eklemek de iyi bir pratiktir
        setState(() {
          _currentIndex = (_currentIndex + 1) % _shapes.length;
        });
        _morphController.reset();
        _morphController.forward();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _morphController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _elasticAnimation,
      builder: (context, child) {
        double scaleX = 1.0 + (_elasticAnimation.value - 1.0) * 0.3;
        double scaleY = 1.0 - (_elasticAnimation.value - 1.0) * 0.3;

        return Transform.scale(
          scaleX: scaleX,
          scaleY: scaleY,
          child: CustomPaint(
            size: Size(widget.size, widget.size),
            painter: JellyShapePainter(
              color: widget.color,
              shapeType: _shapes[_currentIndex],
              wobbleAmount: (1.0 - _elasticAnimation.value) * 10.0,
            ),
          ),
        );
      },
    );
  }
}

// --- ŞEKİLLERİ ÇİZEN PAINTER ---
class JellyShapePainter extends CustomPainter {
  final Color color;
  final JellyShapeType shapeType;
  final double wobbleAmount;

  JellyShapePainter({
    required this.color,
    required this.shapeType,
    required this.wobbleAmount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    // Jöle etkisi için kenarları yumuşat
    paint.maskFilter = const MaskFilter.blur(BlurStyle.solid, 3.0);

    Path path = Path();
    Offset center = Offset(size.width / 2, size.height / 2);

    // Hafif bir rastgelelik ekleyerek kenarların titremesini sağla (opsiyonel)
    // double noise() => (Random().nextDouble() - 0.5) * wobbleAmount;

    switch (shapeType) {
      case JellyShapeType.triangle:
        // Yuvarlatılmış Üçgen
        double side = size.width * 0.8;
        double height = side * sqrt(3) / 2;
        path.moveTo(center.dx, center.dy - height / 2 - wobbleAmount);
        path.lineTo(
          center.dx - side / 2 - wobbleAmount,
          center.dy + height / 2,
        );
        path.lineTo(
          center.dx + side / 2 + wobbleAmount,
          center.dy + height / 2,
        );
        path.close();
        // Köşeleri yumuşatmak için path'i tekrar işle
        path = Path.from(path);
        canvas.drawPath(
          path,
          paint
            ..strokeWidth = 15.0
            ..style = PaintingStyle.stroke,
        );
        canvas.drawPath(path, paint..style = PaintingStyle.fill);
        break;

      case JellyShapeType.square:
        // Yuvarlatılmış Kare
        double side = size.width * 0.65;
        Rect rect = Rect.fromCenter(
          center: center,
          width: side + wobbleAmount,
          height: side - wobbleAmount,
        );
        path.addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(20)));
        canvas.drawPath(path, paint);
        break;

      case JellyShapeType.rectangle:
        // Yuvarlatılmış Dikdörtgen (Daha geniş)
        double width = size.width * 0.8;
        double height = size.height * 0.5;
        Rect rect = Rect.fromCenter(
          center: center,
          width: width - wobbleAmount,
          height: height + wobbleAmount,
        );
        path.addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(20)));
        canvas.drawPath(path, paint);
        break;

      case JellyShapeType.circle: // <<-- YENİ
        double radius = size.width * 0.4;
        Rect rect = Rect.fromCircle(
          center: center,
          radius: radius - wobbleAmount * 0.5,
        );
        path.addOval(rect);
        canvas.drawPath(path, paint);
        break; // <<-- YENİ
    }
  }

  @override
  bool shouldRepaint(covariant JellyShapePainter oldDelegate) {
    return oldDelegate.shapeType != shapeType ||
        oldDelegate.wobbleAmount != wobbleAmount;
  }
}

// --- OYUN MANTIĞI (DoughGame) ---
class DoughGame extends FlameGame {
  // ✅ Tutorial'da daire geldiğinde "buraya bas" işaretçisi için
  final ValueNotifier<bool> showCircleHint = ValueNotifier(false);
  final ValueNotifier<bool> showSquareHint = ValueNotifier(false);

  final ValueNotifier<bool> showRectWideHint = ValueNotifier(false);
  final ValueNotifier<bool> showRectTallHint = ValueNotifier(false);

  // ✅ Triangle hint
  final ValueNotifier<bool> showTriangleHint = ValueNotifier(false);

  // RİTİM PARAMETRELERİ (Drum Or Bass için)
  final double gameBPM = 170.0; // DnB için tahmini yüksek BPM
  late final double rhythmDuration = 60.0 / gameBPM; // Yaklaşık 0.353 saniye
  final bool isTutorial; // ✅ YENİ

  // ÇAKIŞMA ÖNLEME AYARI
  final double minSpawnDistanceY =
      400.0; // KRİTİK: Fiziksel mesafe kuralı 400 birim

  // OYUN HIZI DEĞİŞKENLERİ
  double currentGameSpeed = 40.0; // BAŞLANGIÇ HIZI YÜKSELTİLDİ
  double baseSpeed = 50.0; // Başlangıç hızını biraz daha yukarı çekebilirsin
  final double maxSpeed =
      350.0; // Oyunun ulaşılabilecek maksimum hızı (limit koymak iyidir)
  final double speedGrowthFactor = 5.0;
  double rhythmTimer = 0.0;
  final double rhythmBoost = 15.0;
  final double speedIncreaseRate = .1; // Hızlanma oranı 1.5'e çıkarıldı

  // RİTMİK SPAWN PARAMETRELERİ
  double lastSpawnTime = 0.0;
  double minRhythmBeats = 4.0;
  double maxRhythmBeats = 12.0;
  double currentSpawnInterval = 6.0;
  final double minSpawnInterval = 2.5;
  final double intervalDecreaseRate = 0.02;

  // MÜZİK SENKRONİZASYON DEĞİŞKENLERİ
  int triangleProbability = 1; // Başlangıçta 1/4 = %25 şans
  bool isSynced = false;
  final double syncDelay = 2.0;

  final AudioPlayer _audioPlayer = AudioPlayer();

  final double elasticity = 0.15;
  List<MoldObstacle> molds = [];
  double touchDownTimer = 0.0;
  Offset? initialTouchPosition;
  bool isCircleCandidate = false;
  final double longPressDuration = .5;
  final double centerTolerance = 50.0;
  bool isTouchingDough = false;

  int score = 0;
  double playerBounceTimer = 0.0;
  double playerBounceOffsetY = 0.0;
  final bool isDarkMode;
  final List<DoughPoint> points = [];
  late List<Vector2> shapeSquare,
      shapeTriangle,
      shapeRectWide,
      shapeRectTall,
      shapeCircle;
  String currentShapeName = "Square";
  late Color baseDoughColor;
  late Color obstacleColor;
  late Color feedbackSuccessColor;
  late Color feedbackFailColor;
  final double interactionRadius = 120.0;
  final double sensitivity = 3.5;

  int currentLevel = 1;
  double levelTimer = 0.0;
  bool isLevelingUp = false;
  double levelUpTransitionTimer = 0.0;
  late Vector2 doughCenterPos;
  late double horizonY;
  double shakeTimer = 0.0;
  double shakeIntensity = 0.0;

  bool isGameOver = false;
  final AdManager adManager = AdManager();
  int lossCounter = 0;

  final Random _rnd = Random();

  bool tutorialCompleted = false;
  // ✅ Tutorial sırası: Circle -> Rect Wide -> Rect Tall -> Square -> Triangle
  final List<String> tutorialSequence = const [
    "Circle",
    "Rect Wide",
    "Rect Tall",
    "Square",
    "Triangle",
  ];
  int tutorialStep = 0;
  // DoughGame sınıfı içinde bu metodu bul ve değiştir:
  void cleanup() async {
    try {
      // Nesne zaten kapandıysa veya null ise hata vermemesi için kontrol
      if (_audioPlayer.state != PlayerState.disposed) {
        await _audioPlayer.stop();
        await _audioPlayer.dispose();
      }
    } catch (e) {
      debugPrint("Ses temizlenirken hata oluştu: $e");
    }
  }

  void finishTutorial() {
    if (tutorialCompleted) return;
    tutorialCompleted = true;

    showCircleHint.value = false;
    showSquareHint.value = false;
    showRectWideHint.value = false;
    showRectTallHint.value = false;

    // ✅ YENİ
    showTriangleHint.value = false;

    pauseEngine();
    overlays.remove('tutorialSquareHint');
    overlays.remove('tutorialRectWideHint');
    overlays.remove('tutorialRectTallHint');
    overlays.remove('tutorialCircleHint');
    overlays.remove('tutorialControls');

    // ✅ YENİ
    overlays.remove('tutorialTriangleHint');

    overlays.add('tutorialEnd');
  }

  DoughGame({
    required this.isDarkMode,
    this.isTutorial = false, // ✅ default: normal oyun
  });
  void _updateTutorialCircleHint() {
    if (!isTutorial) return;

    // Kullanıcı zaten doğru şekilde basılı tutuyorsa ipucu kapansın
    if (isCircleCandidate) {
      if (showCircleHint.value) showCircleHint.value = false;
      return;
    }

    // Oyuncuya en yakın (currentY en büyük) engeli bul
    MoldObstacle? nearest;
    for (final m in molds) {
      if (m.isFilled || m.hasPassed) continue;
      if (nearest == null || m.currentY > nearest.currentY) nearest = m;
    }

    if (nearest == null) {
      if (showCircleHint.value) showCircleHint.value = false;
      return;
    }

    // Circle engeli yaklaşıyorsa göster
    final double wallHitPoint = doughCenterPos.y - 40;
    final double distToWall =
        wallHitPoint - nearest.currentY; // >0: daha yukarıda

    final bool shouldShow =
        nearest.targetShapeName == "Circle" && distToWall < 700; // erken göster

    if (showCircleHint.value != shouldShow) {
      showCircleHint.value = shouldShow;
    }
  }

  @override
  Future<void> onLoad() async {
    adManager.loadRewardedAd();
    adManager.loadInterstitialAd();
    _audioPlayer.setReleaseMode(ReleaseMode.loop); // Sonsuz döngü
    await _audioPlayer.play(AssetSource('audio/level1_music.mp3'));
    adManager.loadBannerAd(() {
      // Banner yüklendiğinde yapılacaklar (isteğe bağlı)
    });
    if (isDarkMode) {
      baseDoughColor = const Color(0xFFFF00CC);
      obstacleColor = const Color(0xFFFFD700);
      feedbackSuccessColor = const Color(0xFF00FF00);
      feedbackFailColor = const Color(0xFFFF0000);
    } else {
      baseDoughColor = const Color(0xFF00B0FF);
      obstacleColor = const Color(0xFFFF7043);
      feedbackSuccessColor = const Color(0xFF00E676);
      feedbackFailColor = const Color(0xFFFF3D00);
    }
    doughCenterPos = Vector2(size.x / 2, size.y * 0.70);
    horizonY = size.y * 0.25;

    int totalPoints = 40;
    // KARE: 220x220 (Yarıçap ~110)
    shapeSquare = generateRectPath(doughCenterPos, 220, 220, totalPoints);

    shapeRectWide = generateRectPath(doughCenterPos, 350, 100, totalPoints);
    shapeRectTall = generateRectPath(doughCenterPos, 100, 350, totalPoints);
    shapeTriangle = generateTrianglePath(doughCenterPos, 220, 220, totalPoints);

    // DAİRE YOLUNU BÜYÜTÜYORUZ: 100'den 180'e (Yarıçapı Kare'ye yaklaştırdık)
    shapeCircle = generateCirclePath(
      doughCenterPos,
      280, // <-- GÜNCELLENDİ (Daha büyük daire yolu)
      totalPoints,
    );

    for (var pos in shapeSquare) {
      points.add(DoughPoint(pos.clone()));
    }
    if (isTutorial) {
      triangleProbability = 0;

      isSynced = true;
      levelTimer = 0.0;
      lastSpawnTime = 0.0;
      rhythmTimer = 0.0;

      overlays.add('tutorialCircleHint');
      overlays.add('tutorialSquareHint');
      overlays.add('tutorialRectWideHint');
      overlays.add('tutorialRectTallHint');

      // ✅ YENİ
      overlays.add('tutorialTriangleHint');

      overlays.add('tutorialControls');
    }
  }

  @override
  void update(double dt) {
    // 1. OYUNCU 2 KERE SEKME ANİMASYONU (GAME OVER DURUMU)
    if (isGameOver && playerBounceTimer > 0) {
      playerBounceTimer -= dt;
      double t = 1.0 - (playerBounceTimer / 0.6);
      if (t < 0.5) {
        double localT = t * 2;
        playerBounceOffsetY = 180.0 * sin(localT * pi);
      } else {
        double localT = (t - 0.5) * 2;
        playerBounceOffsetY = 80.0 * sin(localT * pi);
      }
      if (t >= 1.0) playerBounceOffsetY = 0;
    }

    if (isGameOver) return;
    super.update(dt);

    // **********************************************
    // 2. MÜZİK SENKRONİZASYONU VE TEMEL HIZ GÜNCELLEMESİ
    if (!isSynced) {
      levelTimer += dt;
      if (levelTimer >= syncDelay) {
        isSynced = true;
        levelTimer = 0.0;
        lastSpawnTime = 0.0;
        rhythmTimer = 0.0;
      }
    }

    if (isSynced) {
      // SÜREKLİ ZORLUK ARTIŞI (baseSpeed zamanla yavaşça artar)
      if (!isLevelingUp && !isTutorial) {
        // Sadece maksimum hıza ulaşana kadar çok küçük bir artış (Saniyede 0.2 birim)
        if (baseSpeed < maxSpeed) {
          baseSpeed += dt * 0.2;
        }
      }

      // RİTMİK HIZ TİTREŞİMİ (Müziğe göre)
      rhythmTimer += dt;
      if (rhythmTimer >= rhythmDuration) {
        rhythmTimer -= rhythmDuration;
      }
      double boost =
          rhythmBoost * (1.0 - cos(rhythmTimer / rhythmDuration * 2 * pi)) / 2;

      // ANA OYUN HIZI = Artan Temel Hız + Ritmik Titreşim
      currentGameSpeed = baseSpeed + boost;
    }
    // **********************************************

    // 3. OYUNCU GİRİŞİ VE ŞEKİL ANALİZİ
    if (initialTouchPosition != null) {
      touchDownTimer += dt;
      Vector2 touchVec = Vector2(
        initialTouchPosition!.dx,
        initialTouchPosition!.dy,
      );
      double distanceToCenter = touchVec.distanceTo(doughCenterPos);

      if (touchDownTimer >= longPressDuration &&
          distanceToCenter <= centerTolerance) {
        isCircleCandidate = true;
      } else {
        isCircleCandidate = false;
      }
    } else {
      touchDownTimer = 0.0;
      isCircleCandidate = false;
    }

    // LEVEL/SÜRE KONTROLÜ
    // LEVEL/SÜRE KONTROLÜ (Tutorial'da level up yok)
    if (!isTutorial) {
      if (!isLevelingUp) {
        levelTimer += dt;
        if (levelTimer >= 30.0) startLevelUp();
      } else {
        levelUpTransitionTimer += dt;
        if (levelUpTransitionTimer >= 3.0) finishLevelUp();
      }
    }

    if (points.isEmpty) return;

    // Titreme (Shake) Kontrolü
    if (shakeTimer > 0) {
      shakeTimer -= dt;
      if (shakeTimer <= 0) shakeIntensity = 0;
    }

    ShapeAnalysis analysis = analyzeCurrentShape();
    List<Vector2> targetShape = decideTargetShape(analysis);

    for (int i = 0; i < points.length; i++) {
      points[i].pos =
          points[i].pos + (targetShape[i] - points[i].pos) * elasticity;
    }
    void spawnRandomMold({String? forcedType}) {
      // ✅ Normal oyun: random
      // ✅ Tutorial: forcedType ile sıradaki şekil
      String randomType;

      if (forcedType != null) {
        randomType = forcedType;
      } else {
        List<String> types = ["Square", "Rect Wide", "Rect Tall", "Circle"];
        randomType = types[_rnd.nextInt(types.length)];

        // Üçgen olasılığı (normal oyun)
        if (_rnd.nextInt(4) < triangleProbability) {
          randomType = "Triangle";
        }
      }

      List<Vector2> moldPath;
      Vector2 center = Vector2(size.x / 2, 0);

      switch (randomType) {
        case "Triangle":
          moldPath = generateTrianglePath(center, 220, 220, 40);
          break;
        case "Rect Wide":
          moldPath = generateRectPath(center, 350, 100, 40);
          break;
        case "Rect Tall":
          moldPath = generateRectPath(center, 100, 350, 40);
          break;
        case "Circle":
          moldPath = generateCirclePath(center, 200, 40);
          break;
        default: // Square
          moldPath = generateRectPath(center, 200, 200, 40);
          break;
      }

      molds.add(
        MoldObstacle(
          randomType,
          moldPath,
          size.x,
          horizonY,
          speed: currentGameSpeed,
          baseColor: obstacleColor,
          isDarkMode: isDarkMode,
        ),
      );
    }

    void spawnTutorialMold() {
      if (tutorialStep >= tutorialSequence.length) {
        finishTutorial();
        return;
      }

      final nextType = tutorialSequence[tutorialStep];
      spawnRandomMold(forcedType: nextType);
    }

    // **********************************************
    // 4. RİTMİK ENGEL ATMA MANTIĞI VE ÜST ÜSTE BİNME KONTROLÜ
    if (isTutorial) {
      // ✅ Tutorial: tek tek ve sırayla gelsin
      if (isSynced &&
          !tutorialCompleted &&
          molds.isEmpty &&
          tutorialStep < tutorialSequence.length) {
        spawnTutorialMold();
      }
    } else {
      if (isSynced && !isLevelingUp && levelTimer < 30.0) {
        double elapsedTimeSinceLastSpawn = levelTimer - lastSpawnTime;
        double targetTime = currentSpawnInterval * rhythmDuration;

        // ÜST ÜSTE BİNMEYİ ENGELLEYEN KRİTİK EŞİK (Ritmik Zaman Kuralı)
        final double minSafeBeats = 1.8;
        final double minTargetTime = minSafeBeats * rhythmDuration;

        double distanceToLastMold = 0.0;
        if (molds.isNotEmpty) {
          MoldObstacle lastMold = molds.last;
          // Engel, tam olarak hamurun geldiği yerden ne kadar yukarıda?
          distanceToLastMold = doughCenterPos.y - lastMold.currentY;
        }

        // Engel atma koşulu:
        // YENİ: distanceToLastMold'u 400.0 ile kontrol ediyoruz.
        bool canSpawn =
            molds.isEmpty ||
            (elapsedTimeSinceLastSpawn >= targetTime &&
                distanceToLastMold >= minSpawnDistanceY && // 400.0 mesafesi
                elapsedTimeSinceLastSpawn >= minTargetTime);

        if (canSpawn) {
          spawnRandomMold();
          lastSpawnTime = levelTimer;

          // Sonraki spawn aralığını rastgele seç ve seviyeye göre kısalt
          double randomBeats =
              minRhythmBeats +
              (maxRhythmBeats - minRhythmBeats) * _rnd.nextDouble();
          currentSpawnInterval =
              randomBeats - (currentLevel * intervalDecreaseRate);

          // Alt sınırı garanti et (2 vuruştan kısa olmasın)
          if (currentSpawnInterval < 2.0) {
            currentSpawnInterval = 2.0;
          }
        }
      }
    }
    // **********************************************

    // 5. BARİYER VE ÇARPIŞMA KONTROLLERİ (HAREKET ETME)
    for (int i = molds.length - 1; i >= 0; i--) {
      MoldObstacle mold = molds[i];

      // --- YENİ DİNAMİK SAYDAMLIK KONTROLÜ ---
      if (i > 0) {
        // i-1: bu engelden bir önceki atılan engeldir (Y ekseninde daha geride/yukarıda).
        MoldObstacle previousMold = molds[i - 1];

        // Bu engel (mold) ile daha gerideki engel (previousMold) arasındaki Y mesafesi
        // Molds listesi spawn sırasına göre değil, render ve update sırasına göre olmalı, bu döngüde tersten gittiğimiz için:
        // molds[i] = en yakın engel
        // molds[i-1] = bir önceki engel (daha uzakta)
        // Eğer spawnRandomMold listenin sonuna ekliyorsa, i=molds.length-1 en yakın engel OLMALI.
        // Ama Y koordinatına göre bakmak daha güvenli:

        // Bu engelin (i) Y koordinatından, bir önceki engelin (i-1) Y koordinatını çıkarırsak
        // (yeni y - eski y). Bu değer, engeller arası boşluğu verir.
        double gapY = mold.currentY - previousMold.currentY;

        // Saydamlık eşikleri
        final double maxGapForFade =
            350.0; // Bu mesafeye kadar saydamlık tam (1.0)
        final double minGapForFade =
            100.0; // Bu mesafeden sonra saydamlık minimuma (0.4) düşecek

        if (gapY < maxGapForFade) {
          double normalizedGap =
              (gapY - minGapForFade) / (maxGapForFade - minGapForFade);

          // 0 ile 1 arasında kalmasını sağla.
          normalizedGap = normalizedGap.clamp(0.0, 1.0);

          // gapY azaldıkça (yaklaştıkça) normalizedGap 0'a yaklaşır, opaklık 0.4'e düşer.
          mold.opacity = 0.4 + (0.6 * normalizedGap);
        } else {
          mold.opacity = 1.0;
        }
      } else {
        // En arkadaki engel (veya tek engel) tam opak başlar
        mold.opacity = 1.0;
      }
      // --- DİNAMİK SAYDAMLIK KONTROLÜ SONU ---

      if (!mold.isStopped) {
        // Hız, sync olduktan sonra artan baseSpeed'i kullanır.
        mold.speed = currentGameSpeed;
        mold.update(dt);
      }

      double wallHitPoint = doughCenterPos.y - 40;
      double barrierHitPoint = wallHitPoint - 100.0;
      double distanceToBarrier = barrierHitPoint - mold.currentY;

      if (distanceToBarrier > -50 && distanceToBarrier < 300) {
        if (currentShapeName != mold.targetShapeName) {
          mold.showBarrier = true;
        } else {
          mold.showBarrier = false;
        }
      }

      // ERKEN ÇARPIŞMA (BARİYER)
      if (!mold.hasPassed &&
          !mold.isStopped &&
          currentShapeName != mold.targetShapeName &&
          mold.currentY >= barrierHitPoint) {
        mold.currentY = barrierHitPoint;
        mold.showBarrier = true;
        checkMatch(mold, false);
      }
      // NORMAL GEÇİŞ (DUVAR)
      else if (!mold.hasPassed &&
          !mold.isStopped &&
          currentShapeName == mold.targetShapeName &&
          mold.currentY >= wallHitPoint) {
        mold.hasPassed = true;
        mold.showBarrier = false;
        checkMatch(mold, true);
      }

      if (mold.opacity <= 0 || mold.currentY > size.y + 200) {
        molds.removeAt(i);
      }
    }
    // ✅ Tutorial daire ipucunu güncelle
    _updateTutorialCircleHint();
    _updateTutorialSquareHint();
    _updateTutorialRectWideHint();
    _updateTutorialRectTallHint();

    _updateTutorialTriangleHint();
  }

  void _updateTutorialTriangleHint() {
    if (!isTutorial) return;

    final bool isStep =
        tutorialStep < tutorialSequence.length &&
        tutorialSequence[tutorialStep] == "Triangle";

    if (!isStep) {
      if (showTriangleHint.value) showTriangleHint.value = false;
      return;
    }

    // Kullanıcı zaten doğru şekildiyse ipucunu kapat
    if (currentShapeName == "Triangle") {
      if (showTriangleHint.value) showTriangleHint.value = false;
      return;
    }

    if (molds.isEmpty) {
      if (showTriangleHint.value) showTriangleHint.value = false;
      return;
    }

    final MoldObstacle nearest = molds.last;

    final double wallHitPoint = doughCenterPos.y - 40;
    final double distToWall = wallHitPoint - nearest.currentY;

    final bool shouldShow =
        nearest.targetShapeName == "Triangle" &&
        distToWall < 850 &&
        distToWall > 120;

    if (showTriangleHint.value != shouldShow) {
      showTriangleHint.value = shouldShow;
    }
  }

  void _updateTutorialRectWideHint() {
    if (!isTutorial) return;

    final bool isStep =
        tutorialStep < tutorialSequence.length &&
        tutorialSequence[tutorialStep] == "Rect Wide";

    if (!isStep) {
      if (showRectWideHint.value) showRectWideHint.value = false;
      return;
    }

    // Kullanıcı zaten doğru şekildiyse ipucunu kapat
    if (currentShapeName == "Rect Wide") {
      if (showRectWideHint.value) showRectWideHint.value = false;
      return;
    }

    if (molds.isEmpty) {
      if (showRectWideHint.value) showRectWideHint.value = false;
      return;
    }

    final MoldObstacle nearest = molds.last;

    final double wallHitPoint = doughCenterPos.y - 40;
    final double distToWall = wallHitPoint - nearest.currentY;

    final bool shouldShow =
        nearest.targetShapeName == "Rect Wide" &&
        distToWall < 950 &&
        distToWall > 120;

    if (showRectWideHint.value != shouldShow) {
      showRectWideHint.value = shouldShow;
    }
  }

  void _updateTutorialRectTallHint() {
    if (!isTutorial) return;

    final bool isStep =
        tutorialStep < tutorialSequence.length &&
        tutorialSequence[tutorialStep] == "Rect Tall";

    if (!isStep) {
      if (showRectTallHint.value) showRectTallHint.value = false;
      return;
    }

    // Kullanıcı zaten doğru şekildiyse ipucunu kapat
    if (currentShapeName == "Rect Tall") {
      if (showRectTallHint.value) showRectTallHint.value = false;
      return;
    }

    if (molds.isEmpty) {
      if (showRectTallHint.value) showRectTallHint.value = false;
      return;
    }

    final MoldObstacle nearest = molds.last;

    final double wallHitPoint = doughCenterPos.y - 40;
    final double distToWall = wallHitPoint - nearest.currentY;

    final bool shouldShow =
        nearest.targetShapeName == "Rect Tall" &&
        distToWall < 950 &&
        distToWall > 120;

    if (showRectTallHint.value != shouldShow) {
      showRectTallHint.value = shouldShow;
    }
  }

  void _updateTutorialSquareHint() {
    if (!isTutorial) return;

    // Şu an tutorial hedefimiz Square mı?
    final bool isSquareStep =
        tutorialStep < tutorialSequence.length &&
        tutorialSequence[tutorialStep] == "Square";

    if (!isSquareStep) {
      if (showSquareHint.value) showSquareHint.value = false;
      return;
    }

    // ekranda engel yoksa kapat
    if (molds.isEmpty) {
      if (showSquareHint.value) showSquareHint.value = false;
      return;
    }

    // tek engel olduğu için nearest = aktif engel
    final MoldObstacle nearest = molds.last;

    // Square engeli yaklaşırken göster
    final double wallHitPoint = doughCenterPos.y - 40;
    final double distToWall = wallHitPoint - nearest.currentY;

    final bool shouldShow =
        nearest.targetShapeName == "Square" &&
        distToWall < 850 && // erken göster
        distToWall > 120; // çok geç kalmasın

    if (showSquareHint.value != shouldShow) {
      showSquareHint.value = shouldShow;
    }
  }

  bool checkMatch(MoldObstacle mold, bool success) {
    if (success) {
      mold.isFilled = true; // Yeşile boyanıp dolması için işaretle
      mold.isStopped = false; // <<< KRİTİK: Başarılı geçişte durmayacak!
      mold.successTimer = mold.holdDuration;
      score += 10;
      if (isTutorial) {
        tutorialStep++;
        if (tutorialStep >= tutorialSequence.length) {
          finishTutorial();
        }
      }

      if (score % 50 == 0 && triangleProbability < 1) {
        triangleProbability++; // Max 2 olacak (50/50 şans)
      }
      baseDoughColor = feedbackSuccessColor;
      mold.color = feedbackSuccessColor;

      HapticFeedback.lightImpact();
      triggerShake(5.0, 0.2); // Hafif bir titretme (başarı hissi)

      Future.delayed(const Duration(milliseconds: 300), () {
        if (!isGameOver) {
          baseDoughColor = isDarkMode
              ? const Color(0xFFFF00CC)
              : const Color(0xFF00B0FF);
        }
      });
      return true;
    } else {
      // --- OYUNU KAYBETME (BAŞARISIZLIK) ---
      baseDoughColor = Colors.red;
      mold.color = Colors.red;

      mold.speed = 0;
      mold.isStopped = true; // Sadece burada duracak (Fail durumu)

      // Oyuncu geri sekme animasyonu
      playerBounceTimer = 0.6;
      playerBounceOffsetY = 0;

      isGameOver = true;
      triggerShake(100.0, 0.6);
      HapticFeedback.heavyImpact();
      checkSaveData();

      _audioPlayer.pause(); // 👈 MÜZİĞİ DURDUR

      Future.delayed(const Duration(milliseconds: 700), () {
        overlays.add('gameOver');
      });
      return false;
    }
  }

  // --- HAMUR ÇİZİMİNDE SEKME ETKİSİ ---
  // Sadece bu fonksiyonu değiştiriyoruz ki hamur aşağı kaysın
  void drawDynamicDough(Canvas canvas) {
    canvas.save(); // Kaydet

    // Eğer oyuncu sekiyorsa (Game Over anı), canvas'ı aşağı kaydır
    if (isGameOver) {
      canvas.translate(0, playerBounceOffsetY);
    }

    final path = Path();
    var p0 = points.last.pos;
    var p1 = points.first.pos;
    path.moveTo((p0.x + p1.x) / 2, (p0.y + p1.y) / 2);
    for (int i = 0; i < points.length; i++) {
      var current = points[i].pos;
      var next = points[(i + 1) % points.length].pos;
      path.quadraticBezierTo(
        current.x,
        current.y,
        (current.x + next.x) / 2,
        (current.y + next.y) / 2,
      );
    }

    // Gölge ve Hamur Rengi
    canvas.drawShadow(
      path,
      isDarkMode
          ? Colors.cyanAccent.withOpacity(0.4)
          : Colors.black.withOpacity(0.25),
      isDarkMode ? 20.0 : 10.0,
      true,
    );
    Rect bounds = path.getBounds();
    final Paint doughPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.3),
        radius: 0.8,
        colors: [
          baseDoughColor.withOpacity(0.8),
          baseDoughColor,
          baseDoughColor
              .withRed((baseDoughColor.red * 0.7).toInt())
              .withGreen((baseDoughColor.green * 0.7).toInt())
              .withBlue((baseDoughColor.blue * 0.7).toInt()),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(bounds);
    canvas.drawPath(path, doughPaint);
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withOpacity(isDarkMode ? 0.6 : 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    canvas.restore(); // Geri yükle (Diğer çizimler kaymasın)
  }

  // --- Render ve Diğer Metodlar Aynen Kalıyor (Tekrar kopyalamana gerek yok, yukarıdaki update ve checkMatch'i değiştirmen yeterli) ---
  // Ancak eksiklik olmaması için Render'ı da ekliyorum:

  @override
  void render(Canvas canvas) {
    if (shakeIntensity > 0 && !isGameOver) {
      double dx = (_rnd.nextDouble() - 0.5) * shakeIntensity;
      double dy = (_rnd.nextDouble() - 0.5) * shakeIntensity;
      canvas.save();
      canvas.translate(dx, dy);
    }

    final Rect bgRect = Rect.fromLTWH(0, 0, size.x, size.y);
    List<Color> baseBgColors;
    if (isDarkMode) {
      baseBgColors = [const Color(0xFF2E0249), const Color(0xFF000000)];
    } else {
      baseBgColors = [const Color(0xFFE1F5FE), const Color(0xFFFFFFFF)];
    }

    final Paint bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        stops: const [0.0, 0.8],
        colors: baseBgColors,
      ).createShader(bgRect);
    canvas.drawRect(bgRect, bgPaint);

    drawDynamicRoad(canvas);

    // Z-SORTING
    // 1. Arka Duvarlar
    for (var mold in molds) {
      if (!mold.isCollided && mold.currentY < doughCenterPos.y - 60) {
        mold.renderBackground(canvas, horizonY, doughCenterPos.y);
      }
    }

    // 2. Hamur
    if (points.isNotEmpty) {
      drawDynamicDough(canvas);
    }

    // 3. Ön Duvarlar (Çarpanlar)
    for (var mold in molds) {
      // Çarpan duvarları daima önde çiziyoruz
      if (mold.isCollided || mold.currentY >= doughCenterPos.y - 60) {
        mold.renderForeground(canvas, horizonY, doughCenterPos.y);
      }
    }

    if (shakeIntensity > 0 && !isGameOver) {
      canvas.restore();
    }
    drawUI(canvas);
  }

  // --- Helper Metodlar (Değişmedi) ---
  void startLevelUp() {
    isLevelingUp = true;
    levelUpTransitionTimer = 0.0;
    molds.clear();
  }

  void finishLevelUp() {
    isLevelingUp = false;
    levelTimer = 0.0;
    currentLevel++;

    // Eskiden: baseSpeed += 50.0; (Çok sertti)
    // Yeni: Seviye arttıkça artış miktarı azalır (Logaritmik smooth artış)
    double increase = speedGrowthFactor * (1.0 / sqrt(currentLevel));
    if (baseSpeed < maxSpeed) {
      baseSpeed += 15.0 + increase; // Daha küçük ve kontrollü bir adım
    }

    currentGameSpeed = baseSpeed;

    // Engel aralığını da çok sert daraltma
    if (currentSpawnInterval > minSpawnInterval) {
      currentSpawnInterval -= 0.15; // Küçük adımlarla daralt
    }
  }

  void revive() {
    isGameOver = false;
    molds.clear();
    overlays.remove('gameOver');
    baseDoughColor = isDarkMode
        ? const Color(0xFFFF00CC)
        : const Color(0xFF00B0FF);
    resumeEngine();
  }

  void resetGame() {
    score = 0;
    currentLevel = 1;
    currentGameSpeed = 40.0;
    levelTimer = 0.0;
    isLevelingUp = false;
    molds.clear();
    isGameOver = false;
    baseDoughColor = isDarkMode
        ? const Color(0xFFFF00CC)
        : const Color(0xFF00B0FF);
    shakeIntensity = 0;
    overlays.remove('gameOver');
    resumeEngine();
  }

  void triggerShake(double intensity, double duration) {
    shakeIntensity = intensity;
    shakeTimer = duration;
  }

  Future<void> checkSaveData() async {
    final prefs = await SharedPreferences.getInstance();
    int currentBest = prefs.getInt('bestScore') ?? 0;
    int maxLvl = prefs.getInt('maxLevel') ?? 1;
    if (score > currentBest) await prefs.setInt('bestScore', score);
    if (currentLevel > maxLvl) await prefs.setInt('maxLevel', currentLevel);
  }

  // Kodun geri kalan metodları (drawDynamicRoad vb.) önceki kodunla aynı.
  void drawDynamicRoad(Canvas canvas) {
    final pathRoad = Path();
    double topW = 20.0;
    pathRoad.moveTo(size.x / 2 - topW, horizonY);
    pathRoad.lineTo(size.x / 2 + topW, horizonY);
    pathRoad.lineTo(size.x, size.y);
    pathRoad.lineTo(0, size.y);
    pathRoad.close();

    if (!isLevelingUp && levelTimer > 25.0) {
      double progress = (levelTimer - 25.0) / 5.0;
      double perspectiveProgress = progress * progress;
      double greenFrontY = horizonY + (size.y - horizonY) * perspectiveProgress;

      final greenZonePath = Path();
      greenZonePath.moveTo(size.x / 2 - topW, horizonY);
      greenZonePath.lineTo(size.x / 2 + topW, horizonY);

      double currentWidth = 40.0 + (size.x - 40.0) * perspectiveProgress;

      greenZonePath.lineTo(size.x / 2 + currentWidth / 2, greenFrontY);
      greenZonePath.lineTo(size.x / 2 - currentWidth / 2, greenFrontY);
      greenZonePath.close();

      final greenPaint = Paint()
        ..shader =
            LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.greenAccent.withOpacity(0.5),
                Colors.green.shade900,
              ],
            ).createShader(
              Rect.fromLTWH(0, horizonY, size.x, greenFrontY - horizonY),
            );

      canvas.drawPath(greenZonePath, greenPaint);
    }

    if (isLevelingUp) {
      final fullGreenPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.greenAccent.withOpacity(0.5), Colors.green.shade900],
        ).createShader(Rect.fromLTWH(0, horizonY, size.x, size.y - horizonY));
      canvas.drawPath(pathRoad, fullGreenPaint);
    } else {
      List<Color> roadColors;
      if (isDarkMode) {
        roadColors = [const Color(0xFF1A0B2E), const Color(0xFF000000)];
      } else {
        roadColors = [const Color(0xFFF5F5F5), const Color(0xFFEEEEEE)];
      }
      final Paint roadPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: roadColors,
        ).createShader(Rect.fromLTWH(0, horizonY, size.x, size.y - horizonY));
      canvas.drawPath(pathRoad, roadPaint);

      if (levelTimer > 25.0) {
        double progress = (levelTimer - 25.0) / 5.0;
        double perspectiveProgress = progress * progress;
        double greenFrontY =
            horizonY + (size.y - horizonY) * perspectiveProgress;
        final greenZonePath = Path();
        greenZonePath.moveTo(size.x / 2 - topW, horizonY);
        greenZonePath.lineTo(size.x / 2 + topW, horizonY);

        double currentWidth = 40.0 + (size.x - 40.0) * perspectiveProgress;

        greenZonePath.lineTo(size.x / 2 + currentWidth / 2, greenFrontY);
        greenZonePath.lineTo(size.x / 2 - currentWidth / 2, greenFrontY);
        greenZonePath.close();

        final greenPaint = Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.greenAccent.withOpacity(0.8),
              Colors.green.shade800,
            ],
          ).createShader(Rect.fromLTWH(0, horizonY, size.x, size.y));
        canvas.drawPath(greenZonePath, greenPaint);
      }
    }

    if (isDarkMode || isLevelingUp) {
      final gridPaint = Paint()
        ..color = isLevelingUp
            ? Colors.white.withOpacity(0.5)
            : Colors.cyanAccent.withOpacity(0.3)
        ..strokeWidth = 2;
      canvas.drawLine(
        Offset(size.x / 2, horizonY),
        Offset(size.x / 2, size.y),
        gridPaint,
      );
      canvas.drawLine(
        Offset(size.x / 2 - topW, horizonY),
        Offset(0, size.y),
        gridPaint,
      );
      canvas.drawLine(
        Offset(size.x / 2 + topW, horizonY),
        Offset(size.x, size.y),
        gridPaint,
      );
      for (int i = 0; i < 10; i++) {
        double t = i / 10;
        double y = horizonY + (size.y - horizonY) * (t * t);
        canvas.drawLine(Offset(0, y), Offset(size.x, y), gridPaint);
      }
    }
  }

  void drawUI(Canvas canvas) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    final scoreStyle = TextStyle(
      color: isLevelingUp
          ? Colors.white
          : (isDarkMode ? Colors.white : const Color(0xFF37474F)),
      fontSize: 24,
      fontWeight: FontWeight.w800,
    );
    textPainter.text = TextSpan(text: "SCORE: $score", style: scoreStyle);
    textPainter.layout();
    textPainter.paint(canvas, const Offset(30, 50));

    final levelStyle = TextStyle(
      color: isLevelingUp
          ? Colors.yellowAccent
          : (isDarkMode ? Colors.cyanAccent : const Color(0xFF00B0FF)),
      fontSize: 24,
      fontWeight: FontWeight.w900,
    );
    textPainter.text = TextSpan(
      text: "LEVEL: $currentLevel",
      style: levelStyle,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.x - textPainter.width - 30, 50));

    if (isLevelingUp) {
      textPainter.text = const TextSpan(
        text: "LEVEL UP!",
        style: TextStyle(
          color: Colors.white,
          fontSize: 48,
          fontWeight: FontWeight.w900,
          letterSpacing: 2.0,
          shadows: [Shadow(blurRadius: 20, color: Colors.greenAccent)],
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(size.x / 2 - textPainter.width / 2, size.y * 0.2),
      );
    } else {
      double progress = levelTimer / 30.0;
      double barWidth = 200.0;
      double barHeight = 10.0;
      Offset barPos = Offset(size.x / 2 - barWidth / 2, 130);

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(barPos.dx, barPos.dy, barWidth, barHeight),
          const Radius.circular(5),
        ),
        Paint()..color = Colors.grey.withOpacity(0.5),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            barPos.dx,
            barPos.dy,
            barWidth * (1 - progress),
            barHeight,
          ),
          const Radius.circular(5),
        ),
        Paint()..color = isDarkMode ? Colors.cyanAccent : Colors.orange,
      );
    }
  }

  // --- ŞEKİL ÜRETME MANTIĞI ---
  void spawnRandomMold() {
    List<String> types = ["Square", "Rect Wide", "Rect Tall", "Circle"];
    String randomType = types[_rnd.nextInt(types.length)];

    // YENİ: Üçgen Olasılığı Kontrolü (Zorluk)
    if (_rnd.nextInt(4) < triangleProbability) {
      randomType = "Triangle";
    }

    List<Vector2> moldPath;
    Vector2 center = Vector2(size.x / 2, 0);

    switch (randomType) {
      case "Triangle":
        moldPath = generateTrianglePath(center, 220, 220, 40);
        break;
      case "Rect Wide":
        moldPath = generateRectPath(center, 350, 100, 40);
        break;
      case "Rect Tall":
        moldPath = generateRectPath(center, 100, 350, 40);
        break;
      case "Circle":
        moldPath = generateCirclePath(center, 200, 40);
        break;
      default: // Square
        moldPath = generateRectPath(center, 200, 200, 40);
        break;
    }

    molds.add(
      MoldObstacle(
        randomType,
        moldPath,
        size.x,
        horizonY,
        speed: currentGameSpeed,
        baseColor: obstacleColor,
        isDarkMode: isDarkMode,
      ),
    );
  }

  void deform(Offset touchPosition, Offset delta) {
    final touchVec = Vector2(touchPosition.dx, touchPosition.dy);
    final moveVec = Vector2(delta.dx, delta.dy);
    for (var point in points) {
      double dist = point.pos.distanceTo(touchVec);
      if (dist < interactionRadius) {
        double strength = (1 - (dist / interactionRadius));
        strength = strength * strength;
        point.pos += moveVec * (strength * sensitivity);
      }
    }
  }

  // DoughGame sınıfı içinde:

  ShapeAnalysis analyzeCurrentShape() {
    double minX = double.infinity, maxX = -double.infinity;
    double minY = double.infinity, maxY = -double.infinity;

    double totalDistance = 0.0; // <<-- YENİ
    Vector2 center = doughCenterPos; // Oyuncunun hamurunun merkezi

    for (var p in points) {
      if (p.pos.x < minX) minX = p.pos.x;
      if (p.pos.x > maxX) maxX = p.pos.x;
      if (p.pos.y < minY) minY = p.pos.y;
      if (p.pos.y > maxY) maxY = p.pos.y;

      totalDistance += p.pos.distanceTo(center); // <<-- YENİ: Uzaklığı topla
    }

    double avgDist = totalDistance / points.length; // <<-- YENİ: Ortalamayı bul

    return ShapeAnalysis(
      maxX - minX,
      maxY - minY,
      points[0].pos.distanceTo(points[9].pos),
      points[20].pos.distanceTo(points[29].pos),
      avgDist, // <<-- YENİ METRİK: avgDist
    );
  } // DoughGame sınıfı içinde:
  // DoughGame sınıfı içinde, decideTargetShape metodu:

  List<Vector2> decideTargetShape(ShapeAnalysis s) {
    // --- 1. YENİ DAİRE MEKANİĞİ: ADAY KONTROLÜ ---
    if (isCircleCandidate) {
      currentShapeName = "Circle";
      return shapeCircle;
    }

    // --- 2. DİKDÖRTGEN KONTROLLERİ ---
    // ... (Dikdörtgen ve Üçgen kontrolleri aynı kalsın) ...
    if (s.width > s.height * 1.3) {
      currentShapeName = "Rect Wide";
      return shapeRectWide;
    }
    if (s.height > s.width * 1.3) {
      currentShapeName = "Rect Tall";
      return shapeRectTall;
    }

    // --- 3. ÜÇGEN KONTROLÜ ---
    if (s.topWidth < s.bottomWidth * 0.6) {
      currentShapeName = "Triangle";
      return shapeTriangle;
    }

    // --- 4. VARSAYILAN: KARE ---
    currentShapeName = "Square";
    return shapeSquare;
  }

  List<Vector2> generateRectPath(
    Vector2 center,
    double w,
    double h,
    int total,
  ) {
    List<Vector2> l = [];
    int p = total ~/ 4;
    for (int i = 0; i < p; i++) {
      l.add(Vector2(center.x - w / 2 + (w * (i / p)), center.y - h / 2));
    }
    for (int i = 0; i < p; i++) {
      l.add(Vector2(center.x + w / 2, center.y - h / 2 + (h * (i / p))));
    }
    for (int i = 0; i < p; i++) {
      l.add(Vector2(center.x + w / 2 - (w * (i / p)), center.y + h / 2));
    }
    for (int i = 0; i < p; i++) {
      l.add(Vector2(center.x - w / 2, center.y + h / 2 - (h * (i / p))));
    }
    return l;
  }

  List<Vector2> generateTrianglePath(
    Vector2 center,
    double w,
    double h,
    int total,
  ) {
    List<Vector2> l = [];
    int p = total ~/ 4;
    for (int i = 0; i < p; i++) {
      double t = i / p;
      l.add(Vector2(center.x - 20 + (40 * t), center.y - h / 2));
    }
    for (int i = 0; i < p; i++) {
      double t = i / p;
      l.add(
        Vector2(center.x + 20 + ((w / 2 - 20) * t), center.y - h / 2 + (h * t)),
      );
    }
    for (int i = 0; i < p; i++) {
      double t = i / p;
      l.add(Vector2(center.x + w / 2 - (w * t), center.y + h / 2));
    }
    for (int i = 0; i < p; i++) {
      double t = i / p;
      l.add(
        Vector2(
          center.x - w / 2 + ((w / 2 - 20) * t),
          center.y + h / 2 - (h * t),
        ),
      );
    }
    return l;
  }

  List<Vector2> generateCirclePath(Vector2 center, double radius, int total) {
    List<Vector2> l = [];
    double angleIncrement = (2 * pi) / total;
    for (int i = 0; i < total; i++) {
      double angle = angleIncrement * i;
      double x = center.x + radius * cos(angle);
      double y = center.y + radius * sin(angle);
      l.add(Vector2(x, y));
    }
    return l;
  }
}

// --- DUVAR MANTIĞI (GÜNCELLENDİ) ---
class MoldObstacle {
  final String targetShapeName;
  final List<Vector2> originalPath;
  final double screenWidth;
  final double startY;
  final bool isDarkMode;

  double currentY = 0;
  double speed;

  bool hasPassed = false;
  double opacity = 1.0;
  Color color;

  bool isFilled = false;
  bool isStopped = false;
  bool isCollided = false;

  bool showBarrier = false;

  // YENİ: Başarılı geçiş sonrası kaybolma zamanlayıcısı
  double successTimer = 0.0;

  // ✅ Yeşil olduktan sonra 1 saniye beklesin
  final double holdDuration = 1.0;

  double get fadeSpeed => 0.5;

  MoldObstacle(
    this.targetShapeName,
    this.originalPath,
    this.screenWidth,
    this.startY, {
    required this.speed,
    required Color baseColor,
    required this.isDarkMode,
  }) : color = baseColor {
    currentY = startY;
  }

  void update(double dt) {
    // 1) Fail durumunda sabit kal
    if (isStopped && !isFilled) {
      return;
    }

    if (isFilled) {
      currentY += speed * dt;

      if (successTimer > 0) {
        successTimer -= dt;
        opacity = 1.0; // 1 saniye tam opak kalsın
      } else {
        opacity = 0.0; // ✅ süre bitince direkt yok olsun
      }
      return;
    }

    // 3) Normal hareket
    currentY += speed * dt;
  }

  void renderBackground(Canvas canvas, double horizonY, double maxDepthY) {
    if (opacity <= 0) return;
    double totalDistance = maxDepthY - horizonY;
    double currentDistance = currentY - horizonY;
    double progress = currentDistance / totalDistance;
    if (progress < 0.0) return;
    _drawWall(canvas, progress);
  }

  void renderForeground(Canvas canvas, double horizonY, double maxDepthY) {
    if (opacity <= 0) return;
    double totalDistance = maxDepthY - horizonY;
    double currentDistance = currentY - horizonY;
    double progress = currentDistance / totalDistance;
    if (progress < 0.0) return;
    _drawWall(canvas, progress);
  }

  void _drawWall(Canvas canvas, double progress) {
    double scale = 0.05 + (0.95 * progress);
    final holePath = Path();
    if (originalPath.isNotEmpty) {
      Vector2 start = transformPoint(originalPath[0], scale, screenWidth);
      holePath.moveTo(start.x, start.y);
      for (int i = 1; i < originalPath.length; i++) {
        Vector2 p = transformPoint(originalPath[i], scale, screenWidth);
        holePath.lineTo(p.x, p.y);
      }
      holePath.close();
    }

    double roadTopWidth = 20.0;
    double currentRoadWidth =
        roadTopWidth + (screenWidth - roadTopWidth) * progress;
    double drawWidth = currentRoadWidth * 1.5;

    Rect holeBounds = holePath.getBounds();
    double slabHeight = holeBounds.height + (300 * scale);
    Rect slabRect = Rect.fromCenter(
      center: holeBounds.center,
      width: drawWidth,
      height: slabHeight,
    );

    Path wallPath = Path()..addRect(slabRect);
    Path finalWallPath = Path.combine(
      PathOperation.difference,
      wallPath,
      holePath,
    );

    final wallPaint = Paint()
      ..color = color
          .withOpacity(opacity) // DÜZELTME: Opaklık değeri kullanılıyor
      ..style = PaintingStyle.fill;

    canvas.drawShadow(
      finalWallPath,
      Colors.black.withOpacity(0.2 * opacity),
      5,
      true,
    );
    canvas.drawPath(finalWallPath, wallPaint);

    final depthPaint = Paint()
      ..color = Colors.black.withOpacity(0.3 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10 * scale;
    canvas.drawPath(holePath, depthPaint);

    // --- ENGEL VEYA DOLGU ÇİZİMİ ---
    if (isFilled) {
      // Başarılı geçiş sonrası yeşil dolgu
      final fillPaint = Paint()
        ..color = color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;
      canvas.drawPath(holePath, fillPaint);
    } else if (showBarrier) {
      // TEHLİKE! Kırmızı bariyer
      final barrierPaint = Paint()
        ..color = Colors.red
            .withOpacity(0.6 * opacity) // Yarı saydam kırmızı
        ..style = PaintingStyle.fill;

      canvas.drawPath(holePath, barrierPaint);

      // Çarpı
      final crossPaint = Paint()
        ..color = Colors.white.withOpacity(0.8 * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5 * scale;

      Rect b = holePath.getBounds();
      canvas.drawLine(b.topLeft, b.bottomRight, crossPaint);
      canvas.drawLine(b.topRight, b.bottomLeft, crossPaint);
    } else {
      final borderPaint = Paint()
        ..color = (isDarkMode ? Colors.white : Colors.black).withOpacity(
          0.1 * opacity,
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3 * scale;
      canvas.drawPath(holePath, borderPaint);
    }
  }

  Vector2 transformPoint(Vector2 original, double scale, double screenWidth) {
    double ox = original.x;
    double oy = original.y;
    double centerX = screenWidth / 2;
    double finalX = (ox - centerX) * scale + centerX;
    double finalY = (oy * scale) + currentY - (originalPath[0].y * scale);
    return Vector2(finalX, finalY);
  }
}

class DoughGamePage extends StatefulWidget {
  final bool isDarkMode;
  final bool isTutorial;

  const DoughGamePage({
    super.key,
    required this.isDarkMode,
    this.isTutorial = false,
  });
  @override
  State<DoughGamePage> createState() => _DoughGamePageState();
}

class _DoughGamePageState extends State<DoughGamePage> {
  late DoughGame _game;
  BannerAd? _banner;

  @override
  void initState() {
    super.initState();
    _game = DoughGame(
      isDarkMode: widget.isDarkMode,
      isTutorial: widget.isTutorial, // ✅
    );
    // Banner'ı yükle ve yüklendiğinde sayfayı yenile
    _game.adManager.loadBannerAd(() {
      if (mounted) {
        setState(() {
          _banner = _game.adManager.bannerAd;
        });
      }
    });
  }

  @override
  void dispose() {
    _game.cleanup(); // ✅ müzik vs kapat
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.isDarkMode ? Colors.black : Colors.white,
      body: Column(
        children: [
          Expanded(
            child: Listener(
              // 1. Dokunma Başladı (Parmak Bastırıldı)
              onPointerDown: (event) {
                if (!_game.isGameOver) {
                  // İlk dokunma pozisyonunu ve zamanlayıcıyı başlat
                  _game.initialTouchPosition = event.localPosition;
                  _game.touchDownTimer = 0.0; // Zamanlayıcıyı sıfırla
                }
              },

              // 2. Parmak Hareket Ediyor (Deformasyon)
              onPointerMove: (event) {
                if (!_game.isGameOver) {
                  // Hamuru deforme et (Dikdörtgen veya Üçgen yapmaya çalış)
                  _game.deform(event.localPosition, event.delta);

                  // ÖNEMLİ: Eğer parmak merkezden uzaklaşırsa, ilk dokunma pozisyonunu sil (Daire adayı olamaz)
                  if (_game.initialTouchPosition != null) {
                    Vector2 currentTouchVec = Vector2(
                      event.localPosition.dx,
                      event.localPosition.dy,
                    );
                    Vector2 initialTouchVec = Vector2(
                      _game.initialTouchPosition!.dx,
                      _game.initialTouchPosition!.dy,
                    );

                    // İlk pozisyondan 30 birimden fazla kayarsa, daire adaylığını iptal et
                    if (currentTouchVec.distanceTo(initialTouchVec) > 30.0) {
                      _game.initialTouchPosition = null;
                    }
                  }
                }
              },

              // 3. Dokunma Bitti (Parmak Kaldırıldı)
              onPointerUp: (event) {
                if (!_game.isGameOver) {
                  // Tüm daire mekaniği değişkenlerini sıfırla
                  _game.initialTouchPosition = null;
                  _game.touchDownTimer = 0.0;
                  _game.isCircleCandidate = false;
                }
              },

              child: GameWidget(
                game: _game,
                overlayBuilderMap: {
                  'gameOver': (context, game) => GameOverMenu(
                    game: game as DoughGame,
                    isDarkMode: widget.isDarkMode,
                  ),

                  'tutorialCircleHint': (context, game) =>
                      TutorialCircleHintOverlay(
                        game: game as DoughGame,
                        isDarkMode: widget.isDarkMode,
                      ),
                  'tutorialSquareHint': (context, game) =>
                      TutorialSquareHintOverlay(
                        game: game as DoughGame,
                        isDarkMode: widget.isDarkMode,
                      ),
                  'tutorialControls': (context, game) =>
                      TutorialControlsOverlay(
                        game: game as DoughGame,
                        isDarkMode: widget.isDarkMode,
                      ),
                  'tutorialRectWideHint': (context, game) =>
                      TutorialRectWideHintOverlay(
                        game: game as DoughGame,
                        isDarkMode: widget.isDarkMode,
                      ),
                  'tutorialRectTallHint': (context, game) =>
                      TutorialRectTallHintOverlay(
                        game: game as DoughGame,
                        isDarkMode: widget.isDarkMode,
                      ),
                  'tutorialTriangleHint': (context, game) =>
                      TutorialTriangleHintOverlay(
                        game: game as DoughGame,
                        isDarkMode: widget.isDarkMode,
                      ),

                  'tutorialEnd': (context, game) => TutorialEndMenu(
                    game: game as DoughGame,
                    isDarkMode: widget.isDarkMode,
                  ),
                },
              ),
            ),
          ),
          if (_game.adManager.isBannerAdLoaded && _banner != null)
            Container(
              alignment: Alignment.center,
              width: _banner!.size.width.toDouble(),
              height: _banner!.size.height.toDouble(),
              child: AdWidget(ad: _banner!),
            ),
        ],
      ),
    );
  }
}

class GameOverMenu extends StatelessWidget {
  final DoughGame game;
  final bool isDarkMode;
  const GameOverMenu({super.key, required this.game, required this.isDarkMode});
  @override
  Widget build(BuildContext context) {
    Color bgColor = isDarkMode ? const Color(0xFF16213E) : Colors.white;
    Color textColor = isDarkMode ? Colors.white : const Color(0xFF37474F);
    Color scoreColor = isDarkMode
        ? const Color(0xFFFF00CC)
        : const Color(0xFF00B0FF);
    Color buttonColor = isDarkMode
        ? const Color(0xFFFF00CC)
        : const Color(0xFF00B0FF);
    return Center(
      child: Container(
        padding: const EdgeInsets.all(30),
        margin: const EdgeInsets.symmetric(horizontal: 40),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(25),
          border: isDarkMode ? Border.all(color: scoreColor, width: 2) : null,
          boxShadow: [
            BoxShadow(
              color: isDarkMode
                  ? scoreColor.withOpacity(0.4)
                  : Colors.black.withOpacity(0.1),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "GAME OVER",
              style: TextStyle(
                color: textColor,
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 15),
            Text(
              "SCORE: ${game.score}",
              style: TextStyle(
                color: scoreColor,
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "LEVEL: ${game.currentLevel}",
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: JellyButton(
                text: "REVIVE",
                width: double.infinity,
                color: Colors.green,
                isDarkMode: isDarkMode,
                icon: Icons.play_circle_filled,
                // GameOverMenu içindeki Revive butonu onPressed kısmı:
                onPressed: () {
                  if (game.adManager.isRewardedAdLoaded) {
                    game.adManager.showRewardedAd(
                      onRewardEarned: () {
                        game.revive();
                      },
                      onAdDismissed: () {},
                    );
                  } else {
                    // Reklam henüz dolmadıysa kullanıcıya uyarı göster
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "Ad is loading, please try again in a moment.",
                        ),
                      ),
                    );
                    game.adManager.loadRewardedAd(); // Tekrar yüklemeyi tetikle
                  }
                },
              ),
            ),
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              child: JellyButton(
                text: "RETRY",
                width: double.infinity,
                color: buttonColor,
                isDarkMode: isDarkMode,
                onPressed: () => game.resetGame(),
              ),
            ),
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              child: JellyButton(
                text: "MAIN MENU",
                width: double.infinity,
                color: isDarkMode ? Colors.grey[800]! : Colors.grey[400]!,
                isDarkMode: isDarkMode,
                onPressed: () {
                  // 1. Sayacı arttır
                  AdManager.menuReturnCounter++;

                  // 2. Navigasyon Fonksiyonu (Tekrar tekrar yazmamak için)
                  void goToMainMenu() {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const WelcomePage(),
                      ),
                    );
                  }

                  // 3. Kontrol Et: Her 3 dönüşte 1 reklam göster
                  if (AdManager.menuReturnCounter % 3 == 0) {
                    // Reklamı göster, KAPANDIĞINDA menüye git
                    game.adManager.showInterstitialAd(
                      onAdDismissed: () {
                        goToMainMenu();
                      },
                    );
                  } else {
                    // Reklam sırası değilse direkt git
                    goToMainMenu();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ShapeAnalysis {
  final double avgDistToCenter; // <<-- YENİ: Merkeze olan ortalama uzaklık
  final double w, h, tw, bw;
  double get width => w;
  double get height => h;
  double get topWidth => tw;
  double get bottomWidth => bw;
  double get averageDistanceToCenter => avgDistToCenter; // <<-- YENİ GETTER
  ShapeAnalysis(this.w, this.h, this.tw, this.bw, this.avgDistToCenter);
}

class DoughPoint {
  Vector2 pos;
  DoughPoint(this.pos);
}

class TutorialControlsOverlay extends StatelessWidget {
  final DoughGame game;
  final bool isDarkMode;
  const TutorialControlsOverlay({
    super.key,
    required this.game,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final c = isDarkMode ? const Color(0xFFFF00CC) : const Color(0xFF00B0FF);

    void goMenu() {
      game.cleanup();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const WelcomePage()),
        (route) => false,
      );
    }

    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 100),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              JellyButton(
                text: "EXIT",
                width: 140,
                color: Colors.grey,
                isDarkMode: isDarkMode,
                onPressed: goMenu,
              ),
              JellyButton(
                text: "SKIP",
                width: 140,
                color: c,
                isDarkMode: isDarkMode,
                onPressed: () {
                  game.finishTutorial();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TutorialEndMenu extends StatelessWidget {
  final DoughGame game;
  final bool isDarkMode;
  const TutorialEndMenu({
    super.key,
    required this.game,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDarkMode ? const Color(0xFF16213E) : Colors.white;
    final main = isDarkMode ? const Color(0xFFFF00CC) : const Color(0xFF00B0FF);
    final text = isDarkMode ? Colors.white : const Color(0xFF37474F);

    return Center(
      child: Container(
        padding: const EdgeInsets.all(26),
        margin: const EdgeInsets.symmetric(horizontal: 30),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: main.withOpacity(0.6), width: 2),
          boxShadow: [
            BoxShadow(
              color: main.withOpacity(0.25),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "TUTORIAL\nCOMPLETED!",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: text,
                fontSize: 28,
                fontWeight: FontWeight.w900,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 18),
            JellyButton(
              text: "PLAY",
              width: double.infinity,
              color: main,
              isDarkMode: isDarkMode,
              onPressed: () {
                game.cleanup();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => DoughGamePage(isDarkMode: isDarkMode),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            JellyButton(
              text: "MAIN MENU",
              width: double.infinity,
              color: Colors.grey,
              isDarkMode: isDarkMode,
              onPressed: () {
                game.cleanup();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const WelcomePage()),
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class TutorialCircleHintOverlay extends StatefulWidget {
  final DoughGame game;
  final bool isDarkMode;

  const TutorialCircleHintOverlay({
    super.key,
    required this.game,
    required this.isDarkMode,
  });

  @override
  State<TutorialCircleHintOverlay> createState() =>
      _TutorialCircleHintOverlayState();
}

class _TutorialCircleHintOverlayState extends State<TutorialCircleHintOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.isDarkMode
        ? const Color(0xFFFF00CC)
        : const Color(0xFF00B0FF);

    return IgnorePointer(
      child: ValueListenableBuilder<bool>(
        valueListenable: widget.game.showCircleHint,
        builder: (context, show, _) {
          if (!show) return const SizedBox.shrink();

          final dx = widget.game.doughCenterPos.x;
          final dy = widget.game.doughCenterPos.y;

          return Stack(
            children: [
              // Pulsing hedef (hamurun merkezi)
              Positioned(
                left: dx - 80,
                top: dy - 80,
                child: AnimatedBuilder(
                  animation: _pulse,
                  builder: (context, _) {
                    final t = _pulse.value; // 0..1
                    final scale = 1.0 + (t * 0.18);

                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: c.withOpacity(0.95),
                            width: 4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: c.withOpacity(0.35),
                              blurRadius: 30,
                              spreadRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Merkez noktası
              Positioned(
                left: dx - 10,
                top: dy - 10,
                child: Stack(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: c,
                        boxShadow: [
                          BoxShadow(
                            color: c.withOpacity(0.6),
                            blurRadius: 18,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),

                    Icon(
                      Icons.touch_app_rounded,
                      color: Colors.orange,
                      size: 44,
                    ),
                  ],
                ),
              ),
              Positioned(
                left: dx - 10,
                top: dy - 50,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.deepOrange, width: 1.5),
                  ),
                  child: const Text(
                    "HOLD HERE",
                    style: TextStyle(
                      color: Colors.deepOrange,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class TutorialSquareHintOverlay extends StatefulWidget {
  final DoughGame game;
  final bool isDarkMode;

  const TutorialSquareHintOverlay({
    super.key,
    required this.game,
    required this.isDarkMode,
  });

  @override
  State<TutorialSquareHintOverlay> createState() =>
      _TutorialSquareHintOverlayState();
}

class _TutorialSquareHintOverlayState extends State<TutorialSquareHintOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.isDarkMode
        ? const Color(0xFFFF00CC)
        : const Color(0xFF00B0FF);

    return IgnorePointer(
      child: ValueListenableBuilder<bool>(
        valueListenable: widget.game.showSquareHint,
        builder: (context, show, _) {
          if (!show) return const SizedBox.shrink();

          final dx = widget.game.doughCenterPos.x;
          final dy = widget.game.doughCenterPos.y;

          return AnimatedBuilder(
            animation: _pulse,
            builder: (context, _) {
              final t = _pulse.value; // 0..1
              final slide = 10.0 + (t * 10.0); // küçük “çekme” animasyonu

              return Stack(
                children: [
                  // hedef kare çerçeve
                  Positioned(
                    left: dx - 95,
                    top: dy - 95,
                    child: Container(
                      width: 190,
                      height: 190,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: Colors.deepOrange, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: c.withOpacity(0.25),
                            blurRadius: 28,
                            spreadRadius: 6,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // sol ok (dışarı çek)
                  Positioned(
                    left: dx - 145 - slide,
                    top: dy - 22,
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 44,
                      color: Colors.deepOrange,
                    ),
                  ),

                  // sağ ok (dışarı çek)
                  Positioned(
                    left: dx + 110 + slide,
                    top: dy - 22,
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 44,
                      color: Colors.deepOrange,
                    ),
                  ),

                  // açıklama etiketi
                  Positioned(
                    left: dx - 110,
                    top: dy + 110,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.55),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: c.withOpacity(0.7),
                          width: 1.5,
                        ),
                      ),
                      child: const Text(
                        "PULL SIDES A LITTLE",
                        style: TextStyle(
                          color: Colors.deepOrange,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.1,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class TutorialRectWideHintOverlay extends StatefulWidget {
  final DoughGame game;
  final bool isDarkMode;

  const TutorialRectWideHintOverlay({
    super.key,
    required this.game,
    required this.isDarkMode,
  });

  @override
  State<TutorialRectWideHintOverlay> createState() =>
      _TutorialRectWideHintOverlayState();
}

class _TutorialRectWideHintOverlayState
    extends State<TutorialRectWideHintOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.isDarkMode
        ? const Color(0xFFFF00CC)
        : const Color(0xFF00B0FF);

    return IgnorePointer(
      child: ValueListenableBuilder<bool>(
        valueListenable: widget.game.showRectWideHint,
        builder: (context, show, _) {
          if (!show) return const SizedBox.shrink();

          final dx = widget.game.doughCenterPos.x;
          final dy = widget.game.doughCenterPos.y;

          return AnimatedBuilder(
            animation: _pulse,
            builder: (context, _) {
              final t = _pulse.value;
              final slide = 22.0 + (t * 28.0); // ✅ "çok çek" hissi

              return Stack(
                children: [
                  // geniş dikdörtgen çerçeve
                  Positioned(
                    left: dx - 150,
                    top: dy - 70,
                    child: Container(
                      width: 300,
                      height: 140,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(color: c.withOpacity(0.9), width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: c.withOpacity(0.25),
                            blurRadius: 28,
                            spreadRadius: 6,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // sol ok (dışarı çok çek)
                  Positioned(
                    left: dx - 90 - slide,
                    top: dy - 22,
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 46,
                      color: Colors.deepOrange,
                    ),
                  ),

                  // sağ ok (dışarı çok çek)
                  Positioned(
                    left: dx + 50 + slide,
                    top: dy - 22,
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 46,
                      color: Colors.deepOrange,
                    ),
                  ),

                  // yazı
                  Positioned(
                    left: dx - 145,
                    top: dy + 90,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.55),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: c.withOpacity(0.7),
                          width: 1.5,
                        ),
                      ),
                      child: const Text(
                        "PULL LEFT/RIGHT A LOT",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.1,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class TutorialRectTallHintOverlay extends StatefulWidget {
  final DoughGame game;
  final bool isDarkMode;

  const TutorialRectTallHintOverlay({
    super.key,
    required this.game,
    required this.isDarkMode,
  });

  @override
  State<TutorialRectTallHintOverlay> createState() =>
      _TutorialRectTallHintOverlayState();
}

class _TutorialRectTallHintOverlayState
    extends State<TutorialRectTallHintOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.isDarkMode
        ? const Color(0xFFFF00CC)
        : const Color(0xFF00B0FF);

    return IgnorePointer(
      child: ValueListenableBuilder<bool>(
        valueListenable: widget.game.showRectTallHint,
        builder: (context, show, _) {
          if (!show) return const SizedBox.shrink();

          final dx = widget.game.doughCenterPos.x;
          final dy = widget.game.doughCenterPos.y;

          return AnimatedBuilder(
            animation: _pulse,
            builder: (context, _) {
              final t = _pulse.value;
              final slide = 22.0 + (t * 28.0); // ✅ "çok çek" hissi

              return Stack(
                children: [
                  // uzun dikdörtgen çerçeve
                  Positioned(
                    left: dx - 70,
                    top: dy - 150,
                    child: Container(
                      width: 140,
                      height: 300,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(color: c.withOpacity(0.9), width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: c.withOpacity(0.25),
                            blurRadius: 28,
                            spreadRadius: 6,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // üst ok (yukarı çok çek)
                  Positioned(
                    left: dx - 22,
                    top: dy - 190 - slide,
                    child: Icon(
                      Icons.arrow_upward_rounded,
                      size: 54,
                      color: c.withOpacity(0.95),
                    ),
                  ),

                  // alt ok (aşağı çok çek)
                  Positioned(
                    left: dx - 22,
                    top: dy + 150 + slide,
                    child: Icon(
                      Icons.arrow_downward_rounded,
                      size: 54,
                      color: c.withOpacity(0.95),
                    ),
                  ),

                  // yazı
                  Positioned(
                    left: dx - 140,
                    top: dy + 170,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.55),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: c.withOpacity(0.7),
                          width: 1.5,
                        ),
                      ),
                      child: const Text(
                        "PULL UP/DOWN A LOT",
                        style: TextStyle(
                          color: Colors.deepOrange,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.1,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class TutorialTriangleHintOverlay extends StatefulWidget {
  final DoughGame game;
  final bool isDarkMode;

  const TutorialTriangleHintOverlay({
    super.key,
    required this.game,
    required this.isDarkMode,
  });

  @override
  State<TutorialTriangleHintOverlay> createState() =>
      _TutorialTriangleHintOverlayState();
}

class _TutorialTriangleHintOverlayState
    extends State<TutorialTriangleHintOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.isDarkMode
        ? const Color(0xFFFF00CC)
        : const Color(0xFF00B0FF);

    return IgnorePointer(
      child: ValueListenableBuilder<bool>(
        valueListenable: widget.game.showTriangleHint,
        builder: (context, show, _) {
          if (!show) return const SizedBox.shrink();

          final dx = widget.game.doughCenterPos.x;
          final dy = widget.game.doughCenterPos.y;

          return AnimatedBuilder(
            animation: _pulse,
            builder: (context, _) {
              final t = _pulse.value; // 0..1
              final slide = 10.0 + (t * 12.0);

              return Stack(
                children: [
                  // referans kare çerçeve
                  Positioned(
                    left: dx - 95,
                    top: dy - 95,
                    child: Container(
                      width: 190,
                      height: 190,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: c.withOpacity(0.9), width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: c.withOpacity(0.25),
                            blurRadius: 28,
                            spreadRadius: 6,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ✅ sol üst köşe -> merkeze "sıkıştır"
                  Positioned(
                    left: dx - 120 + slide,
                    top: dy - 120 + slide,
                    child: Transform.rotate(
                      angle: 0.75, // diagonal
                      child: Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 44,
                        color: Colors.deepOrange,
                      ),
                    ),
                  ),

                  // ✅ sağ üst köşe -> merkeze "sıkıştır"
                  Positioned(
                    left: dx + 85 - slide,
                    top: dy - 120 + slide,
                    child: Transform.rotate(
                      angle: 2.35, // diagonal
                      child: Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 44,
                        color: Colors.deepOrange,
                      ),
                    ),
                  ),

                  // açıklama etiketi (karenin köşesini sıkıştır)
                  Positioned(
                    left: dx - 130,
                    top: dy + 110,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.55),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: c.withOpacity(0.7),
                          width: 1.5,
                        ),
                      ),
                      child: const Text(
                        "SQUEEZE THE SQUARE'S CORNER",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.05,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
