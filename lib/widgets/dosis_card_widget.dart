import 'package:flutter/material.dart';
import 'package:alburdat_dashboard/models/device_status.dart';
import 'package:alburdat_dashboard/theme/theme.dart';
import 'package:google_fonts/google_fonts.dart';

class DosisCardWidget extends StatelessWidget {
  final DeviceStatus? status;

  const DosisCardWidget({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final dosis = status?.gramasi ?? 0.0;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(color: AppTheme.borderColor),
        color: AppTheme.surfaceLight,
      ),
      padding: const EdgeInsets.all(AppTheme.spacingXL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingMD),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryBlueLight, AppTheme.primaryBlue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                ),
                child: const Icon(Icons.scale, color: Colors.white, size: 20),
              ),
              const SizedBox(width: AppTheme.spacingLG),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dosis Saat Ini',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Text(
                      'Alat Presisi',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingXL),

          // Value
          Center(
            child: Column(
              children: [
                Text(
                  dosis.toStringAsFixed(2),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 48,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryBlue,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingSM),
                Text(
                  'gram',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppTheme.textGrey),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacingXL),

          // Status indicator
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingMD,
              vertical: AppTheme.spacingSM,
            ),
            decoration: BoxDecoration(
              color:
                  (_isStatusActive(dosis)
                          ? AppTheme.successColor
                          : AppTheme.textGrey)
                      .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusSM),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle,
                  size: 14,
                  color: _isStatusActive(dosis)
                      ? AppTheme.successColor
                      : AppTheme.textGrey,
                ),
                const SizedBox(width: AppTheme.spacingSM),
                Text(
                  _isStatusActive(dosis) ? 'Aktif' : 'Idle',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: _isStatusActive(dosis)
                        ? AppTheme.successColor
                        : AppTheme.textGrey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _isStatusActive(double dosis) => dosis > 0;
}
