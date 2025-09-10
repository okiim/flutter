import 'package:flutter/material.dart';
import 'competitions_page.dart';
import 'judges_page.dart';
import 'participants_page.dart';
import 'criteria_templates_page.dart';
import 'event_types_page.dart';
import 'summary_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({
    super.key,
    this.currentSection = 'dashboard',
  });

  final String currentSection;

  static const Color primaryColor = Color(0xFF8B1538);
  static const Color primaryDarkColor = Color(0xFFA91B47);
  static const Color textPrimaryColor = Color(0xFF333333);

  void _navigateToSection(BuildContext context, String section) {
    print('MENU BAR: $section');
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => DashboardPage(currentSection: section),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      drawer: _buildNavigationDrawer(context),
      body: _getCurrentSectionWidget(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text(
                'JS',
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Judging System",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Section: $currentSection',
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, primaryDarkColor],
              ),
            ),
            child: Text(
              'Navigation Menu',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _buildDrawerItem(context, 'Dashboard', Icons.dashboard, 'dashboard'),
          _buildDrawerItem(context, 'Event Types', Icons.category, 'eventTypes'),
          _buildDrawerItem(context, 'Competitions', Icons.emoji_events, 'competitions'),
          _buildDrawerItem(context, 'Judges', Icons.person, 'judges'),
          _buildDrawerItem(context, 'Participants', Icons.people, 'participants'),
          _buildDrawerItem(context, 'Criteria Templates', Icons.rule, 'criteria'),
          _buildDrawerItem(context, 'Summary', Icons.analytics, 'summary'),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(BuildContext context, String title, IconData icon, String section) {
    final isActive = currentSection == section;
    
    return ListTile(
      leading: Icon(
        icon,
        color: isActive ? primaryColor : Colors.grey,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isActive ? primaryColor : Colors.black,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        _navigateToSection(context, section);
      },
    );
  }

  Widget _getCurrentSectionWidget() {
    print('Loading section: $currentSection');
    
    switch (currentSection) {
      case 'competitions':
        return const CompetitionsPage();
      case 'judges':
        return const JudgesPage();
      case 'participants':
        return const ParticipantsPage();
      case 'eventTypes':
        return const EventTypesPage();
      case 'criteria':
        return const CriteriaTemplatesPage();
      case 'summary':
        return const SummaryPage();
      default:
        return _buildDashboardContent();
    }
  }

  Widget _buildDashboardContent() {
    return Builder(
      builder: (context) => SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Judging System Dashboard',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: textPrimaryColor,
              ),
            ),
            const SizedBox(height: 30),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 1,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              children: [
                _buildDashboardCard(context, 'Event Types', 'Manage custom event categories', Icons.category, 'eventTypes'),
                _buildDashboardCard(context, 'Criteria Templates', 'Create reusable judging criteria', Icons.rule, 'criteria'),
                _buildDashboardCard(context, 'Competitions', 'Create and manage competitions', Icons.emoji_events, 'competitions'),
                _buildDashboardCard(context, 'Judges', 'Manage judge information', Icons.person, 'judges'),
                _buildDashboardCard(context, 'Participants', 'Manage participants', Icons.people, 'participants'),
                _buildDashboardCard(context, 'Summary', 'View system overview and statistics', Icons.analytics, 'summary'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard(BuildContext context, String title, String description, IconData icon, String section) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: () => _navigateToSection(context, section),
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: primaryColor),
              const SizedBox(height: 15),
              Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                description,
                style: const TextStyle(color: Colors.grey, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}