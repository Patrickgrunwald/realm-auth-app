import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Tab bar with "Für dich" and "Folge ich" tabs.
/// Must be used inside a [DefaultTabController].
class FeedTabBar extends StatelessWidget implements PreferredSizeWidget {
  const FeedTabBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(44);

  @override
  Widget build(BuildContext context) {
    return TabBar(
      labelColor: AppColors.textPrimary,
      unselectedLabelColor: AppColors.textSecondary,
      labelStyle: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w400,
      ),
      indicatorColor: AppColors.accent,
      indicatorWeight: 2.5,
      indicatorSize: TabBarIndicatorSize.label,
      dividerColor: Colors.transparent,
      tabs: const [
        Tab(text: 'Für dich'),
        Tab(text: 'Folge ich'),
      ],
    );
  }
}
