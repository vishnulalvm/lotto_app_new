import 'package:flutter/material.dart';
import 'package:lotto_app/core/utils/responsive_helper.dart';
import 'package:lotto_app/data/services/admob_service.dart';
import 'package:lotto_app/data/services/user_service.dart';
import 'package:url_launcher/url_launcher.dart';

class CashbackClaimDialog extends StatefulWidget {
  final Map<String, dynamic> reward;
  final VoidCallback? onClaimed;

  const CashbackClaimDialog({
    super.key,
    required this.reward,
    this.onClaimed,
  });

  @override
  State<CashbackClaimDialog> createState() => _CashbackClaimDialogState();
}

class _CashbackClaimDialogState extends State<CashbackClaimDialog> {
  final AdMobService _adMobService = AdMobService.instance;
  final UserService _userService = UserService();
  bool _isLoadingAd = false;

  @override
  void initState() {
    super.initState();
    // Load rewarded ad when dialog opens
    _loadRewardedAd();
  }

  Future<void> _loadRewardedAd() async {
    setState(() => _isLoadingAd = true);
    await _adMobService.loadCashbackClaimRewardedAd();
    if (mounted) {
      setState(() => _isLoadingAd = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic _) {
        if (didPop) return;
        Navigator.of(context).pop();
      },
      child: AlertDialog(
        backgroundColor: theme.dialogTheme.backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppResponsive.spacing(context, 16)),
        ),
        title: Row(
          children: [
            Icon(
              Icons.redeem,
              color: theme.primaryColor,
              size: AppResponsive.fontSize(context, 24),
            ),
            SizedBox(width: AppResponsive.spacing(context, 8)),
            Text(
              'Claim Cashback',
              style: theme.textTheme.titleLarge?.copyWith(
                fontSize: AppResponsive.fontSize(context, 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Claim your ₹${widget.reward['amount']} cashback reward?',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: AppResponsive.fontSize(context, 14),
              ),
            ),
            if (widget.reward['cashbackId'] != null) ...[
              SizedBox(height: AppResponsive.spacing(context, 8)),
              Container(
                padding: AppResponsive.padding(context, horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.cardColor.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(AppResponsive.spacing(context, 8)),
                  border: Border.all(
                    color: theme.dividerColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: AppResponsive.fontSize(context, 16),
                      color: theme.primaryColor,
                    ),
                    SizedBox(width: AppResponsive.spacing(context, 8)),
                    Expanded(
                      child: Text(
                        'ID: ${widget.reward['cashbackId']}',
                        style: TextStyle(
                          fontSize: AppResponsive.fontSize(context, 12),
                          color: theme.textTheme.bodySmall?.color,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (_isLoadingAd) ...[
              SizedBox(height: AppResponsive.spacing(context, 12)),
              Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
                    ),
                  ),
                  SizedBox(width: AppResponsive.spacing(context, 8)),
                  Text(
                    'Loading reward ad...',
                    style: TextStyle(
                      fontSize: AppResponsive.fontSize(context, 12),
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontSize: AppResponsive.fontSize(context, 14),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: _isLoadingAd ? null : () {
              Navigator.of(context).pop();
              _showRewardedAdForClaim();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Claim',
              style: TextStyle(
                fontSize: AppResponsive.fontSize(context, 14),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRewardedAdForClaim() {
    // Show the rewarded ad
    _adMobService.showRewardedAd(
      'cashback_claim_rewarded',
      onRewardEarned: () {
        // User completed the ad - show confirmation dialog
        _showCashbackClaimedDialog();
      },
      onDismissed: () {
        // User dismissed the ad without completing it
        // Do nothing - they didn't earn the reward
      },
      onFailed: (error) {
        // Ad failed to show - show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not load reward ad. Please try again later.'),
            ),
          );
        }
      },
    );
  }

  void _showCashbackClaimedDialog() {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      useRootNavigator: false,
      builder: (BuildContext context) {
        return PopScope(
          canPop: true,
          child: AlertDialog(
            backgroundColor: theme.dialogTheme.backgroundColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppResponsive.spacing(context, 16)),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: AppResponsive.fontSize(context, 24),
                ),
                SizedBox(width: AppResponsive.spacing(context, 8)),
                Text(
                  'Cashback Claimed!',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontSize: AppResponsive.fontSize(context, 18),
                  ),
                ),
              ],
            ),
            content: Text(
              'Congratulations! You have successfully claimed ₹${widget.reward['amount']} cashback.',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: AppResponsive.fontSize(context, 14),
              ),
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Launch WhatsApp with claim request
                  _launchWhatsAppClaimRequest();
                  // Notify parent that claim was successful
                  widget.onClaimed?.call();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  'Great!',
                  style: TextStyle(
                    fontSize: AppResponsive.fontSize(context, 14),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _launchWhatsAppClaimRequest() async {
    try {
      // Get user ID from user service
      final phoneNumber = await _userService.getPhoneNumber();
      final userId = phoneNumber ?? 'Unknown';

      // Format the claim message
      final message = '''🎉 *Cashback Claim Request*

👤 *User ID:* $userId
💰 *Amount:* ₹${widget.reward['amount']}
📋 *Cashback ID:* ${widget.reward['cashbackId'] ?? 'N/A'}
📅 *Date:* ${widget.reward['date']}

Please process my cashback claim. I have completed the required ad and am eligible for this reward.

Thank you! 🙏''';

      // WhatsApp number (with country code, no + sign)
      const whatsappNumber = '916238970003';

      // Create WhatsApp URL
      final encodedMessage = Uri.encodeComponent(message);
      final whatsappUrl = 'https://wa.me/$whatsappNumber?text=$encodedMessage';

      // Launch WhatsApp
      final Uri url = Uri.parse(whatsappUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        // Fallback - show error
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open WhatsApp. Please make sure WhatsApp is installed.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Handle any errors
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening WhatsApp: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}