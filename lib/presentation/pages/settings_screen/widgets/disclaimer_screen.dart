import 'package:flutter/material.dart';

class DisclaimerScreen extends StatelessWidget {
  const DisclaimerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Disclaimer'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: Colors.grey[200],
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildCard(
            icon: Icons.info_outline,
            title: 'Disclaimer',
            content: "Ponkudam App does not represent any government entity. "
                "We are not affiliated with any government organization. "
                "and do not facilitate government services through this app. "
                "Our source of information is publicly available data, including official government websites. "
                "Users are advised to cross-check all information, including potential winnings, with the official government gazette for confirmation. "
                "Please note, this app does not sell lottery tickets and only displays lottery-related data.",
          ),
          const SizedBox(height: 16),
          _buildCard(
            icon: Icons.lightbulb_outline,
            title: 'Prediction',
            content:
                "Our app offers lottery predictions based on past data and analysis. "
                "However, lottery results are random, and no prediction can guarantee a win. "
                "Use our predictions as a guide, but play responsibly and understand that winning is based on chance. "
                "Our aim is to enhance your lottery experience with useful data and insights.",
          ),
        ],
      ),
    );
  }

  Widget _buildCard(
      {required IconData icon,
      required String title,
      required String content}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.blue),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue)),
            ],
          ),
          const SizedBox(height: 8),
          Text(content, style: const TextStyle(fontSize: 14, height: 1.4)),
        ],
      ),
    );
  }
}
