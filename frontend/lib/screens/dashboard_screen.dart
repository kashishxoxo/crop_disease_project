import 'package:flutter/material.dart';

import '../models/user_profile_model.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import 'about_screen.dart';
import 'alerts_screen.dart';
import 'community_hub_screen.dart';
import 'history_screen.dart';
import 'profile_edit_screen.dart';
import 'reminders_screen.dart';
import 'scan_screen.dart';
import 'voice_assistant_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F4EC),
      body: Stack(
        children: [
          Positioned(
            top: -120,
            right: -40,
            child: _GlowOrb(
              size: 240,
              color: const Color(0x2B2E7D32),
            ),
          ),
          Positioned(
            top: 240,
            left: -70,
            child: _GlowOrb(
              size: 180,
              color: const Color(0x26C68D4A),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _HeaderSection(),
                  const SizedBox(height: 18),
                  _ScanCard(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ScanScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Workspace',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Everything you need for diagnosis, follow-up, and crop monitoring.',
                    style: TextStyle(
                      color: Color(0xFF5F7362),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 14),
                  GridView.count(
                    crossAxisCount: 2,
                    childAspectRatio: 1.05,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    children: [
                      _DashboardCard(
                        title: 'Disease History',
                        subtitle: 'Past scan records',
                        icon: Icons.history,
                        colors: const [Color(0xFF2676CC), Color(0xFF184A93)],
                        accent: 'Track trends',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const HistoryScreen(),
                            ),
                          );
                        },
                      ),
                      _DashboardCard(
                        title: 'Alerts',
                        subtitle: 'Outbreak alerts',
                        icon: Icons.warning_amber_rounded,
                        colors: const [Color(0xFFE6A23C), Color(0xFFB55A12)],
                        accent: 'Risk watch',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AlertsScreen(),
                            ),
                          );
                        },
                      ),
                      _DashboardCard(
                        title: 'Voice Assistant',
                        subtitle: 'Speak symptoms',
                        icon: Icons.keyboard_voice_rounded,
                        colors: const [Color(0xFF2F9B75), Color(0xFF1B6B51)],
                        accent: 'Hindi + English',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const VoiceAssistantScreen(),
                            ),
                          );
                        },
                      ),
                      _DashboardCard(
                        title: 'Reminders',
                        subtitle: 'Treatment follow-up',
                        icon: Icons.notifications_active_outlined,
                        colors: const [Color(0xFFD35D7F), Color(0xFF8F2D56)],
                        accent: 'Stay on schedule',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RemindersScreen(),
                            ),
                          );
                        },
                      ),
                      _DashboardCard(
                        title: 'About Project',
                        subtitle: 'Model & system',
                        icon: Icons.info_outline,
                        colors: const [Color(0xFF7B68C4), Color(0xFF49379B)],
                        accent: 'See the stack',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AboutScreen()),
                          );
                        },
                      ),
                      _DashboardCard(
                        title: 'Community Hub',
                        subtitle: 'Ask and share',
                        icon: Icons.groups_rounded,
                        colors: const [Color(0xFF2D7A85), Color(0xFF184B63)],
                        accent: 'Peer insights',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CommunityHubScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderSection extends StatelessWidget {
  const _HeaderSection();

  @override
  Widget build(BuildContext context) {
    final uid = AuthService.currentUser()?.uid;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF14361B), Color(0xFF25562B), Color(0xFF3B7A44)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 26,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -38,
            right: -12,
            child: Container(
              width: 128,
              height: 128,
              decoration: const BoxDecoration(
                color: Color(0x22FFFFFF),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -46,
            left: 84,
            child: Container(
              width: 140,
              height: 140,
              decoration: const BoxDecoration(
                color: Color(0x16FFFFFF),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: uid == null
                    ? const _HeaderText(name: 'Farmer', crop: '')
                    : StreamBuilder<UserProfileModel?>(
                        stream: UserService.profileStream(uid),
                        builder: (context, snapshot) {
                          final profile = snapshot.data;
                          final name = (profile?.name.trim().isNotEmpty ?? false)
                              ? profile!.name.trim()
                              : 'Farmer';
                          final crop = profile?.cropType ?? '';
                          final soil = profile?.soilType ?? '';
                          return _HeaderText(
                            name: name,
                            crop: crop,
                            soil: soil,
                          );
                        },
                      ),
              ),
              PopupMenuButton<String>(
                color: const Color(0xFFFFFCF7),
                onSelected: (value) async {
                  if (value == 'edit_profile') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ProfileEditScreen(),
                      ),
                    );
                  }
                  if (value == 'logout') {
                    final shouldLogout = await showDialog<bool>(
                      context: context,
                      builder: (dialogContext) {
                        return AlertDialog(
                          title: const Text('Logout'),
                          content: const Text('Are you sure you want to logout?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dialogContext, false),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(dialogContext, true),
                              child: const Text('Logout'),
                            ),
                          ],
                        );
                      },
                    );
                    if (shouldLogout == true) {
                      await AuthService.signOut();
                    }
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'edit_profile',
                    child: Text('Edit Profile'),
                  ),
                  PopupMenuItem(
                    value: 'logout',
                    child: Text('Logout'),
                  ),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0x22FFFFFF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0x33FFFFFF)),
                  ),
                  child: const Icon(Icons.tune, color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderText extends StatelessWidget {
  const _HeaderText({
    required this.name,
    required this.crop,
    this.soil = '',
  });

  final String name;
  final String crop;
  final String soil;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome, $name',
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xD8FFFFFF),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Crop Health\nCommand Center',
          style: TextStyle(
            fontSize: 32,
            height: 1.05,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Scan faster, catch earlier, and keep your treatment follow-up organized.',
          style: TextStyle(
            fontSize: 13,
            height: 1.4,
            color: Color(0xD6FFFFFF),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (crop.trim().isNotEmpty)
              _StatusPill(icon: Icons.grass, label: crop),
            if (soil.trim().isNotEmpty)
              _StatusPill(icon: Icons.landscape_outlined, label: soil),
            const _StatusPill(icon: Icons.radar, label: 'AI + AR Ready'),
          ],
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0x18FFFFFF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0x26FFFFFF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanCard extends StatelessWidget {
  const _ScanCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Ink(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF33691E), Color(0xFF1C3E15), Color(0xFF0F2410)],
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 24,
                offset: Offset(0, 14),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -24,
                top: -8,
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: const BoxDecoration(
                    color: Color(0x14FFFFFF),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Color(0x20FFFFFF),
                    child: Icon(
                      Icons.document_scanner,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _MiniBadge(label: 'LIVE CAMERA + QUALITY CHECK'),
                        SizedBox(height: 10),
                        Text(
                          'Scan Crop',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Capture a leaf, validate quality, and get advisory in one flow.',
                          style: TextStyle(
                            color: Color(0xE6FFFFFF),
                            fontSize: 14,
                            height: 1.35,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_rounded, color: Colors.white),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.colors,
    required this.accent,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> colors;
  final String accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -12,
                top: -16,
                child: Container(
                  width: 82,
                  height: 82,
                  decoration: const BoxDecoration(
                    color: Color(0x12FFFFFF),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.18),
                          ),
                        ),
                        child: Icon(icon, color: Colors.white, size: 22),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.north_east_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  _MiniBadge(label: accent),
                  const SizedBox(height: 10),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xECFFFFFF),
                      fontSize: 13,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0x16FFFFFF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0x28FFFFFF)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}
