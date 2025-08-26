import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InAppReviewWidget extends StatefulWidget {
  final int viewThreshold;
  final int daysAfterInstall;
  
  const InAppReviewWidget({
    super.key,
    this.viewThreshold = 3,
    this.daysAfterInstall = 7,
  });

  @override
  State<InAppReviewWidget> createState() => _InAppReviewWidgetState();
}

class _InAppReviewWidgetState extends State<InAppReviewWidget> {
  static const String _prefKeyViewCount = 'result_view_count';
  static const String _prefKeyFirstInstall = 'first_install_date';
  static const String _prefKeyLastReviewRequest = 'last_review_request';
  
  final InAppReview _inAppReview = InAppReview.instance;
  bool _hasCheckedReview = false;
  
  @override
  void initState() {
    super.initState();
    // Delay the review check to ensure user has completed viewing the result
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _checkAndShowReview();
      }
    });
  }

  Future<void> _checkAndShowReview() async {
    if (_hasCheckedReview) return;
    _hasCheckedReview = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Initialize first install date if not set
      if (!prefs.containsKey(_prefKeyFirstInstall)) {
        await prefs.setString(_prefKeyFirstInstall, DateTime.now().toIso8601String());
        return;
      }

      final firstInstallDate = DateTime.parse(prefs.getString(_prefKeyFirstInstall)!);
      final daysSinceInstall = DateTime.now().difference(firstInstallDate).inDays;
      
      // Check if enough days have passed since install
      if (daysSinceInstall < widget.daysAfterInstall) {
        return;
      }

      // Increment view count
      final viewCount = (prefs.getInt(_prefKeyViewCount) ?? 0) + 1;
      await prefs.setInt(_prefKeyViewCount, viewCount);

      // Check if view threshold is met
      if (viewCount < widget.viewThreshold) {
        return;
      }

      // Check if we've already asked for review recently (respect platform quotas)
      final lastReviewRequest = prefs.getString(_prefKeyLastReviewRequest);
      if (lastReviewRequest != null) {
        final lastRequestDate = DateTime.parse(lastReviewRequest);
        final daysSinceLastRequest = DateTime.now().difference(lastRequestDate).inDays;
        if (daysSinceLastRequest < 90) {
          return;
        }
      }

      // Check if review is available on the platform
      if (await _inAppReview.isAvailable()) {
        await prefs.setString(_prefKeyLastReviewRequest, DateTime.now().toIso8601String());
        _requestReview();
      }
    } catch (e) {
      // Silently handle errors
    }
  }


  Future<void> _requestReview() async {
    try {
      await _inAppReview.requestReview();
    } catch (e) {
      // If in-app review fails, fallback to store listing
      _openStoreListing();
    }
  }

  Future<void> _openStoreListing() async {
    try {
      await _inAppReview.openStoreListing();
    } catch (e) {
      // Handle error silently
    }
  }



  @override
  Widget build(BuildContext context) {
    // This widget is invisible and only handles logic
    return const SizedBox.shrink();
  }
}