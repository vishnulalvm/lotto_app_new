import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:scratcher/widgets.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:confetti/confetti.dart';

class ScratchCardResultScreen extends StatefulWidget {
  final String barcodeValue;

  const ScratchCardResultScreen({
    super.key,
    required this.barcodeValue,
  });

  @override
  State<ScratchCardResultScreen> createState() =>
      _ScratchCardResultScreenState();
}

class _ScratchCardResultScreenState extends State<ScratchCardResultScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  // final _scratcherController = ScratcherController(); // Use ScratcherController

  // Scratch progress tracking
  double scratchProgress = 0.0;
  bool _showResult = false;
  bool _showConfetti = false;
  late ConfettiController _confettiController;

  // Prize details
  late String _prizeAmount;
  late String _prizeNumber;
  late String _drawName;

  @override
  void initState() {
    super.initState();

    // Setup animation
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    // Setup confetti
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 5),
    );

    // Generate random prize details based on barcode
    _generatePrizeDetails();

    // Start the entrance animation
    Future.delayed(const Duration(milliseconds: 500), () {
      _animationController.forward();
    });
  }

  void _generatePrizeDetails() {
    // In a real app, you would fetch these details from an API
    // Here we're generating some sample data
    final random = Random();

    // Prize possibilities
    final prizes = ['₹1,000', '₹5,000', '₹10,000', '₹50,000', '₹1,00,000'];

    final drawNames = [
      'Akshaya AK-620',
      'Win Win W-754',
      'Nirmal NR-352',
      'Karunya KR-613'
    ];

    // Generate ticket number based on barcode value
    String ticketPrefix = widget.barcodeValue.length > 2
        ? widget.barcodeValue.substring(0, 2).toUpperCase()
        : 'AB';

    String ticketNumber = '';
    for (int i = 0; i < 6; i++) {
      ticketNumber += random.nextInt(10).toString();
    }

    _prizeAmount = prizes[random.nextInt(prizes.length)];
    _prizeNumber = '$ticketPrefix $ticketNumber';
    _drawName = drawNames[random.nextInt(drawNames.length)];
  }

  @override
  void dispose() {
    _animationController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _onScratchUpdate(double progress) {
    setState(() {
      scratchProgress = progress;
      // Reveal when 50% scratched
      if (progress >= 0.5 && !_showResult) {
        _showResult = true;
        _confettiController.play();
        _showConfetti = true;
        // Auto reveal the rest
        // Future.delayed(Duration(milliseconds: 300), () {
        //   _scratcherController.reveal(duration: Duration(milliseconds: 500));
        // });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        title: Text(
          'Prize Result',
          style: theme.textTheme.titleLarge?.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: theme.appBarTheme.iconTheme?.color,
          ),
          onPressed: () => context.go('/'),
        ),
      ),
      body: Stack(
        children: [
          // Main content
          Column(
            children: [
              Expanded(
                child: Center(
                  child: ScaleTransition(
                    scale: _animation,
                    child: _buildScratchCard(theme),
                  ),
                ),
              ),
              _buildBottomSheet(theme),
            ],
          ),

          // Confetti overlay
          if (_showConfetti)
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                particleDrag: 0.05,
                emissionFrequency: 0.05,
                numberOfParticles: 20,
                gravity: 0.1,
                colors: [
                  Colors.red,
                  Colors.blue,
                  Colors.green,
                  Colors.yellow,
                  Colors.purple,
                  Colors.orange,
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScratchCard(ThemeData theme) {
    return Container(
      width: 300,
      height: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Scratcher(
        brushSize: 40, // Brush size for scratching
        threshold: 50, // 50% threshold to trigger onThreshold
        color: Colors.grey, // Light grey overlay matching the design
        image: Image.asset(
            'assets/images/scrachcard.png'), // Optional: for texture
        onChange: (value) => _onScratchUpdate(value / 100),
        onThreshold: () {
          // This is called when the threshold is reached
          if (!_showResult) {
            setState(() {
              _showResult = true;
              _showConfetti = true;
              _confettiController.play();
            });
          }
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Prize background with icons
              Container(
                decoration: BoxDecoration(
                  color: Colors.blue[500],
                ),
                child: Stack(
                  children: [
                    // Background pattern of icons
                    _buildBackgroundIcons(),

                    // Prize result (will be revealed)
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.emoji_events,
                              color: Colors.white,
                              size: 40,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Congratulations!',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _prizeAmount,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Ticket: $_prizeNumber',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Draw: $_drawName',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
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

// Helper method to create the background pattern of prize-related icons
  Widget _buildBackgroundIcons() {
    return Stack(
      children: [
        // Trophy icon
        Positioned(
          bottom: 40,
          left: 30,
          child: Icon(
            Icons.emoji_events_outlined,
            color: Colors.blue[300],
            size: 40,
          ),
        ),
        // Gift icon
        Positioned(
          top: 60,
          right: 40,
          child: Icon(
            Icons.card_giftcard_outlined,
            color: Colors.blue[300],
            size: 40,
          ),
        ),
        // Badge icon
        Positioned(
          top: 100,
          left: 50,
          child: Icon(
            Icons.workspace_premium_outlined,
            color: Colors.blue[300],
            size: 40,
          ),
        ),
        // Star icon
        Positioned(
          bottom: 80,
          right: 60,
          child: Icon(
            Icons.star_outline,
            color: Colors.blue[300],
            size: 30,
          ),
        ),
        // Circle decoration
        Positioned(
          top: 30,
          left: 100,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blue[300],
            ),
          ),
        ),
        // Small circles scattered around
        ...List.generate(10, (index) {
          final random = Random();
          return Positioned(
            top: 20 + random.nextDouble() * 260,
            left: 20 + random.nextDouble() * 260,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue[300],
              ),
            ),
          );
        }),
        // Curved shapes
        ...List.generate(5, (index) {
          final random = Random();
          return Positioned(
            top: random.nextDouble() * 280,
            left: random.nextDouble() * 280,
            child: Transform.rotate(
              angle: random.nextDouble() * 2 * pi,
              child: Icon(
                Icons.brightness_1_outlined,
                color: Colors.blue[300],
                size: 20,
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildBottomSheet(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: theme.cardColor, // Keeping original theme color
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            spreadRadius: 0,
            offset: const Offset(0, -3),
          ),
        ],
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag indicator
          Container(
            height: 4,
            width: 40,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          // Congratulations text
          Text(
            'Congratulations!',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),

          // Prize amount
          Text(
            _prizeAmount,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.primaryColor,
            ),
          ),
          const SizedBox(height: 4),

          // Win details
          Text(
            'Ticket: $_prizeNumber · $_drawName',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodySmall?.color,
            ),
          ),

          const SizedBox(height: 24),

          // Button 1: Claim Reward
          ElevatedButton(
            onPressed: () => context.go('/claim'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.celebration_outlined),
                SizedBox(width: 8),
                Text(
                  'Claim Reward',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Button 2: See Full Results
          OutlinedButton(
            onPressed: () => context.go('/result-details'),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.primaryColor,
              minimumSize: const Size(double.infinity, 48),
              side: BorderSide(color: theme.primaryColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.list_alt_outlined),
                SizedBox(width: 8),
                Text(
                  'See Full Results',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Divider
          Divider(color: Colors.grey[300]),

          const SizedBox(height: 12),

          // Kerala Lottery Logo and text
          GestureDetector(
            onTap: _launchKeralaLotteryWebsite,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.verified,
                  size: 18,
                  color: theme.primaryColor,
                ),
                SizedBox(width: 8),
                Text(
                  'Kerala State Lotteries',
                  style: TextStyle(
                    color: theme.textTheme.bodyMedium?.color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchKeralaLotteryWebsite() async {
    final Uri url = Uri.parse('https://statelottery.kerala.gov.in/index.php');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }
}
