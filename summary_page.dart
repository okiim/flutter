import 'package:flutter/material.dart';
import 'api_service.dart';

class SummaryPage extends StatefulWidget {
  const SummaryPage({super.key});

  @override
  State<SummaryPage> createState() => _SummaryPageState();
}

class _SummaryPageState extends State<SummaryPage> {
  static const Color primaryColor = Color(0xFF8B1538);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color infoColor = Color(0xFF2196F3);
  static const Color warningColor = Color(0xFFFF9800);

  List<Map<String, dynamic>> _eventTypes = [];
  List<Map<String, dynamic>> _competitions = [];
  List<Map<String, dynamic>> _participants = [];
  List<Map<String, dynamic>> _judges = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  void _safeSetState(VoidCallback fn) {
    if (mounted) {
      setState(fn);
    }
  }

  Future<void> _loadAllData() async {
    _safeSetState(() => _isLoading = true);
    
    try {
      final results = await Future.wait([
        ApiService.getData('event-types'),
        ApiService.getData('competitions'),
        ApiService.getParticipants(),
        ApiService.getJudges(),
      ]);

      if (mounted) {
        _safeSetState(() {
          _eventTypes = results[0];
          _competitions = results[1];
          _participants = results[2];
          _judges = results[3];
        });
      }
    } catch (e) {
      print('Error loading summary data: $e');
    } finally {
      if (mounted) {
        _safeSetState(() => _isLoading = false);
      }
    }
  }

  Map<String, List<Map<String, dynamic>>> _getParticipantsByCompetition() {
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var participant in _participants) {
      final category = participant['category'] ?? 'Unassigned';
      if (!grouped.containsKey(category)) {
        grouped[category] = [];
      }
      grouped[category]!.add(participant);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              ),
              SizedBox(height: 16),
              Text('Loading summary data...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'System Summary',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 30),
            
            // Overview Cards
            _buildOverviewSection(),
            const SizedBox(height: 30),
            
            // Event Types Summary
            _buildEventTypesSection(),
            const SizedBox(height: 30),
            
            // Competitions Summary
            _buildCompetitionsSection(),
            const SizedBox(height: 30),
            
            // Participants by Competition
            _buildParticipantsSection(),
            const SizedBox(height: 30),
            
            // Judges Summary
            _buildJudgesSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Overview',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),
        const SizedBox(height: 15),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: MediaQuery.of(context).size.width > 800 ? 4 : 2,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
          childAspectRatio: 1.5,
          children: [
            _buildStatCard('Event Types', _eventTypes.length.toString(), Icons.category, successColor),
            _buildStatCard('Competitions', _competitions.length.toString(), Icons.emoji_events, primaryColor),
            _buildStatCard('Participants', _participants.length.toString(), Icons.people, infoColor),
            _buildStatCard('Judges', _judges.length.toString(), Icons.person, warningColor),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String count, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              count,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventTypesSection() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.category, color: successColor),
                const SizedBox(width: 8),
                const Text(
                  'Event Types',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_eventTypes.length} total',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 15),
            _eventTypes.isEmpty
                ? const Text('No event types created yet')
                : Column(
                    children: _eventTypes.map((eventType) {
                      return ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: successColor,
                          radius: 20,
                          child: Icon(Icons.category, color: Colors.white, size: 20),
                        ),
                        title: Text(eventType['name'] ?? 'Unnamed'),
                        subtitle: eventType['description'] != null && eventType['description'].toString().isNotEmpty
                            ? Text(eventType['description'])
                            : const Text('No description'),
                        contentPadding: const EdgeInsets.symmetric(vertical: 4),
                      );
                    }).toList(),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompetitionsSection() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.emoji_events, color: primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Competitions',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_competitions.length} total',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 15),
            _competitions.isEmpty
                ? const Text('No competitions created yet')
                : Column(
                    children: _competitions.map((competition) {
                      return ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: primaryColor,
                          radius: 20,
                          child: Icon(Icons.emoji_events, color: Colors.white, size: 20),
                        ),
                        title: Text(competition['name'] ?? 'Unnamed'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (competition['description'] != null)
                              Text(competition['description']),
                            Row(
                              children: [
                                if (competition['date'] != null)
                                  Text('Date: ${competition['date']}'),
                                const SizedBox(width: 10),
                                if (competition['event_type'] != null)
                                  Text('Type: ${competition['event_type']}'),
                              ],
                            ),
                          ],
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 4),
                      );
                    }).toList(),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantsSection() {
    final participantsByCompetition = _getParticipantsByCompetition();
    
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.people, color: infoColor),
                const SizedBox(width: 8),
                const Text(
                  'Participants by Competition',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_participants.length} total',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 15),
            participantsByCompetition.isEmpty
                ? const Text('No participants registered yet')
                : Column(
                    children: participantsByCompetition.entries.map((entry) {
                      final competitionName = entry.key;
                      final participants = entry.value;
                      
                      return ExpansionTile(
                        leading: CircleAvatar(
                          backgroundColor: infoColor,
                          radius: 20,
                          child: Text(
                            participants.length.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          competitionName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text('${participants.length} participants'),
                        children: participants.map((participant) {
                          return ListTile(
                            leading: const Icon(Icons.person, size: 20),
                            title: Text(participant['name'] ?? 'Unnamed'),
                            subtitle: Text(
                              'Course: ${participant['course'] ?? participant['school'] ?? 'Not specified'}',
                            ),
                            dense: true,
                          );
                        }).toList(),
                      );
                    }).toList(),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildJudgesSection() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person, color: warningColor),
                const SizedBox(width: 8),
                const Text(
                  'Judges',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_judges.length} total',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 15),
            _judges.isEmpty
                ? const Text('No judges registered yet')
                : Column(
                    children: _judges.map((judge) {
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: warningColor,
                          radius: 20,
                          child: Text(
                            (judge['name'] ?? 'J')[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(judge['name'] ?? 'Unnamed'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (judge['email'] != null)
                              Text('Email: ${judge['email']}'),
                            if (judge['expertise'] != null && judge['expertise'].toString().isNotEmpty)
                              Text('Expertise: ${judge['expertise']}'),
                          ],
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 4),
                      );
                    }).toList(),
                  ),
          ],
        ),
      ),
    );
  }
}