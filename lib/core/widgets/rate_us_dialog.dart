import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lotto_app/core/utils/responsive_helper.dart';

class RateUsDialog extends StatefulWidget {
  final VoidCallback? onNotNow;
  final VoidCallback? onContinue;
  
  const RateUsDialog({
    super.key,
    this.onNotNow,
    this.onContinue,
  });

  @override
  State<RateUsDialog> createState() => _RateUsDialogState();
}

class _RateUsDialogState extends State<RateUsDialog> {
  int _selectedStars = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppResponsive.spacing(context, 16)),
      ),
      child: Padding(
        padding: EdgeInsets.all(AppResponsive.spacing(context, 20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Text(
              'rate_us_title'.tr(),
              style: TextStyle(
                fontSize: AppResponsive.fontSize(context, 20),
                fontWeight: FontWeight.bold,
                color: theme.textTheme.titleLarge?.color,
              ),
            ),
            SizedBox(height: AppResponsive.spacing(context, 16)),
            
            // Message
            Text(
              'rate_us_message'.tr(),
              style: TextStyle(
                fontSize: AppResponsive.fontSize(context, 14),
                color: theme.textTheme.bodyMedium?.color,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppResponsive.spacing(context, 20)),
            
            // Star Rating
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedStars = index + 1;
                    });
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppResponsive.spacing(context, 4),
                    ),
                    child: Icon(
                      index < _selectedStars ? Icons.star : Icons.star_border,
                      color: index < _selectedStars 
                          ? Colors.amber 
                          : theme.iconTheme.color?.withValues(alpha: 0.3),
                      size: AppResponsive.fontSize(context, 32),
                    ),
                  ),
                );
              }),
            ),
            SizedBox(height: AppResponsive.spacing(context, 24)),
            
            // Buttons
            Row(
              children: [
                // Not Now Button
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      widget.onNotNow?.call();
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        vertical: AppResponsive.spacing(context, 12),
                      ),
                    ),
                    child: Text(
                      'later'.tr(),
                      style: TextStyle(
                        fontSize: AppResponsive.fontSize(context, 14),
                        color: theme.textTheme.bodyMedium?.color,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: AppResponsive.spacing(context, 12)),
                
                // Continue Button
                Expanded(
                  child: ElevatedButton(
                    onPressed: _selectedStars > 0 ? () => _handleContinue() : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      padding: EdgeInsets.symmetric(
                        vertical: AppResponsive.spacing(context, 12),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppResponsive.spacing(context, 8),
                        ),
                      ),
                    ),
                    child: Text(
                      'rate_now'.tr(),
                      style: TextStyle(
                        fontSize: AppResponsive.fontSize(context, 14),
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleContinue() {
    Navigator.of(context).pop();
    widget.onContinue?.call();
    _launchPlayStore();
  }

  Future<void> _launchPlayStore() async {
    const url = 'https://play.google.com/store/apps/details?id=app.solidapps.lotto';
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(
          Uri.parse(url),
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      // Handle error silently
    }
  }
}