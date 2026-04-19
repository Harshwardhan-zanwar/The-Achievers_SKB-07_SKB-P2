import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/language_provider.dart';

class MoreView extends StatelessWidget {
  const MoreView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1E24),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileCard(),
                  const SizedBox(height: 30),
                  _buildSectionTitle("Settings Options"),
                  const SizedBox(height: 12),
                  _buildSettingsSection(),
                  const SizedBox(height: 30),
                  _buildSectionTitle("Other Options"),
                  const SizedBox(height: 12),
                  _buildOtherOptionsSection(),
                  const SizedBox(height: 100), // Space for bottom nav
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return const SliverAppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      floating: true,
      centerTitle: true,
      title: Text(
        "More Options",
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.greenAccent.withOpacity(0.15), Colors.transparent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.greenAccent.withOpacity(0.2),
            child: const Icon(Icons.person, size: 40, color: Colors.greenAccent),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Ayush Askar",
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Text(
                  "ayush@pashurakshak.com",
                  style: TextStyle(color: Colors.white60, fontSize: 14),
                ),
                const SizedBox(height: 4),
                const Text(
                  "+91 98765 43210",
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent.withOpacity(0.1),
                    foregroundColor: Colors.greenAccent,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    minimumSize: const Size(100, 36),
                  ),
                  child: const Text("Edit Profile", style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildSettingsSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          _buildListTile(
            Icons.language, 
            AppLocalizations.of(context)!.language, 
            Provider.of<LanguageProvider>(context).languageName,
            onTap: () => _showLanguageDialog(context),
          ),
          _buildListTile(Icons.dark_mode_outlined, "Appearance", "Dark Mode"),
          _buildListTile(Icons.lock_outline, "Change Password", ""),
          _buildListTile(Icons.notifications_none, "Notifications", "On", isLast: true),
        ],
      ),
    );
  }

  Widget _buildOtherOptionsSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          _buildListTile(Icons.help_outline, "FAQs", ""),
          _buildListTile(Icons.support_agent, "Contact Support", ""),
          _buildListTile(Icons.share_outlined, "Share App", ""),
          _buildListTile(Icons.star_outline, "Rate App", ""),
          _buildListTile(Icons.lightbulb_outline, "Request Feature", ""),
          _buildListTile(Icons.history, "Delete History", "", isLast: true, color: Colors.redAccent.withOpacity(0.7)),
        ],
      ),
    );
  }

  Widget _buildListTile(IconData icon, String title, String subtitle, {bool isLast = false, Color color = Colors.white70, VoidCallback? onTap}) {
    return Container(
      decoration: BoxDecoration(
        border: isLast ? null : Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: ListTile(
        leading: Icon(icon, color: color, size: 22),
        title: Text(title, style: TextStyle(color: color, fontSize: 15)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (subtitle.isNotEmpty)
              Text(subtitle, style: const TextStyle(color: Colors.white24, fontSize: 13)),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios, color: Colors.white10, size: 14),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        final lp = Provider.of<LanguageProvider>(context, listen: false);
        final l10n = AppLocalizations.of(context)!;
        return AlertDialog(
          backgroundColor: const Color(0xFF1A2F36),
          title: Text(l10n.selectLanguage, style: const TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLanguageOption(context, l10n.english, const Locale('en'), lp),
              _buildLanguageOption(context, l10n.hindi, const Locale('hi'), lp),
              _buildLanguageOption(context, l10n.marathi, const Locale('mr'), lp),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageOption(BuildContext context, String title, Locale locale, LanguageProvider lp) {
    final isSelected = lp.currentLocale.languageCode == locale.languageCode;
    return ListTile(
      title: Text(title, style: TextStyle(color: isSelected ? Colors.greenAccent : Colors.white)),
      trailing: isSelected ? const Icon(Icons.check, color: Colors.greenAccent) : null,
      onTap: () {
        lp.setLocale(locale);
        Navigator.pop(context);
      },
    );
  }
}
