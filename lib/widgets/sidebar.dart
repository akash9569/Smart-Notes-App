import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app_theme.dart';
import '../main.dart';

// Sidebar widget for the Smart Notes application
class Sidebar extends StatelessWidget {
  final String activeTab;
  final Function(String) onTabChanged;
  final String userEmail;
  final String userName;
  final String? profileImage;

  const Sidebar({
    super.key,
    required this.activeTab,
    required this.onTabChanged,
    required this.userEmail,
    required this.userName,
    this.profileImage,
  });

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double sidebarWidth = screenWidth > 600 ? 240 : 200;

    return Container(
      width: sidebarWidth,
      decoration: BoxDecoration(
        color: context.themeSidebarBackground,
        border: Border(right: BorderSide(color: context.themeTextPrimary.withValues(alpha: 0.1), width: 1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 45),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Account Switcher
          InkWell(
            onTap: () => _showSwitchAccountDialog(context),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.themeCardBackground.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.themeTextPrimary.withValues(alpha: 0.1)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.accentBlue.withValues(alpha: 0.2),
                    backgroundImage: getAvatarProvider(profileImage),
                    child: profileImage == null
                        ? Text(
                            userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                            style: const TextStyle(color: AppColors.accentBlue, fontSize: 14, fontWeight: FontWeight.bold),
                          )
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(userName.isNotEmpty ? userName : 'User',
                            style: TextStyle(color: context.themeTextPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis),
                        Text(userEmail,
                            style: const TextStyle(color: AppColors.iconGrey, fontSize: 10),
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  const Icon(Icons.unfold_more_rounded, size: 16, color: AppColors.iconGrey),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Search Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: context.themeCardBackground.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: context.themeTextPrimary.withValues(alpha: 0.1)),
            ),
            child: const Row(
              children: [
                Icon(Icons.search_rounded, size: 18, color: AppColors.iconGrey),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Search...', 
                    style: TextStyle(color: AppColors.iconGrey, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // New Note Button
          InkWell(
            onTap: () => onTabChanged('Notes'),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.accentBlue, AppColors.accentPurple],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_rounded, color: context.themeTextPrimary, size: 20),
                  const SizedBox(width: 6),
                  Text('New Note', style: TextStyle(fontWeight: FontWeight.bold, color: context.themeTextPrimary, fontSize: 14)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildSmallActionButton(context, Icons.check_circle_outline_rounded, 'Task', () => onTabChanged('Tasks'))),
              const SizedBox(width: 8),
              Expanded(child: _buildSmallActionButton(context, Icons.calendar_today_rounded, 'Event', () => onTabChanged('Calendar'))),
            ],
          ),
          const SizedBox(height: 24),
          Text('MAIN MENU', style: TextStyle(color: AppColors.iconGrey.withValues(alpha: 0.5), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildNavItem(context, Icons.grid_view_rounded, 'Home'),
                _buildNavItem(context, Icons.description_outlined, 'Notes'),
                _buildNavItem(context, Icons.task_alt_rounded, 'Tasks'),
                _buildNavItem(context, Icons.calendar_month_rounded, 'Calendar'),
                const SizedBox(height: 20),
                Text('TOOLS', style: TextStyle(color: AppColors.iconGrey.withValues(alpha: 0.5), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                const SizedBox(height: 8),
                _buildNavItem(context, Icons.sticky_note_2_outlined, 'Sticky Notes', trailing: _buildNewBadge()),
                _buildNavItem(context, Icons.auto_stories_outlined, 'Journal', trailing: _buildNewBadge()),
                _buildNavItem(context, Icons.account_balance_wallet_outlined, 'Expenses'),
                _buildNavItem(context, Icons.track_changes_rounded, 'Habit Tracker'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallActionButton(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: context.themeCardBackground.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: context.themeTextPrimary.withValues(alpha: 0.1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: AppColors.iconGrey),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, IconData icon, String label, {Widget? trailing}) {
    final bool isActive = activeTab == label;
    return InkWell(
      onTap: () => onTabChanged(label),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: isActive
            ? AppTheme.premiumDecoration(context: context, radius: 10).copyWith(
                color: AppColors.accentBlue.withValues(alpha: 0.15),
                border: Border.all(color: AppColors.accentBlue.withValues(alpha: 0.3)),
              )
            : BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: isActive ? AppColors.accentBlue : AppColors.iconGrey),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      color: isActive ? context.themeTextPrimary : AppColors.iconGrey,
                      fontSize: 13,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildNewBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: AppColors.accentBlue.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text('NEW',
          style: TextStyle(color: AppColors.accentBlue, fontSize: 7, fontWeight: FontWeight.bold)),
    );
  }

  Future<void> _showSwitchAccountDialog(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> users = prefs.getStringList('all_users') ?? [userEmail];
    
    if (!context.mounted) return;
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.sidebarBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Switch Account', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final isCurrent = user == userEmail;
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.accentBlue.withValues(alpha: 0.2),
                  child: Text(user[0].toUpperCase(), style: const TextStyle(color: AppColors.accentBlue)),
                ),
                title: Text(user, style: const TextStyle(color: Colors.white)),
                trailing: isCurrent ? const Icon(Icons.check_circle_rounded, color: AppColors.accentBlue) : null,
                onTap: () async {
                   Navigator.pop(ctx);
                   if (!isCurrent) {
                      await prefs.setString('last_user_email', user);
                      if (context.mounted) {
                         Navigator.of(context).pushAndRemoveUntil(
                           MaterialPageRoute(builder: (_) => MainScreen(userEmail: user)),
                           (route) => false,
                         );
                      }
                   }
                },
              );
            },
          ),
        ),
        actions: [
           TextButton(
             onPressed: () => Navigator.pop(ctx),
             child: const Text('Cancel', style: TextStyle(color: AppColors.iconGrey)),
           ),
           TextButton(
             onPressed: () async {
               Navigator.pop(ctx);
               await prefs.remove('last_user_email');
               if (context.mounted) {
                 Navigator.of(context).pushAndRemoveUntil(
                   MaterialPageRoute(builder: (_) => const AuthWrapper()),
                   (route) => false,
                 );
               }
             },
             child: const Text('Add Account', style: TextStyle(color: AppColors.accentBlue, fontWeight: FontWeight.bold)),
           ),
        ],
      ),
    );
  }
}
