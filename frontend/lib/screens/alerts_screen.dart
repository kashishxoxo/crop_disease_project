import 'package:flutter/material.dart';

import '../models/user_profile_model.dart';
import '../services/alert_service.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  final TextEditingController _temperatureController = TextEditingController();
  final TextEditingController _humidityController = TextEditingController();
  final TextEditingController _rainfallController = TextEditingController();
  final TextEditingController _leafWetnessController = TextEditingController();

  Future<Map<String, dynamic>>? _riskFuture;
  String _soilType = 'Loam';
  UserProfileModel? _profile;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final uid = AuthService.currentUser()?.uid;
    if (uid == null) return;
    final profile = await UserService.getProfile(uid);
    if (!mounted) return;
    setState(() {
      _profile = profile;
      _soilType =
          (profile?.soilType.trim().isNotEmpty ?? false) ? profile!.soilType : 'Loam';
      _riskFuture = _fetchRisk();
    });
  }

  Future<Map<String, dynamic>> _fetchRisk() {
    final uid = AuthService.currentUser()?.uid;
    if (uid == null) {
      throw Exception('Please login to view alerts.');
    }
    return ApiService.getOutbreakRisk(
      uid: uid,
      soilType: _soilType,
      weather: {
        if (_temperatureController.text.trim().isNotEmpty)
          'temperature_c': double.tryParse(_temperatureController.text.trim()),
        if (_humidityController.text.trim().isNotEmpty)
          'humidity_pct': double.tryParse(_humidityController.text.trim()),
        if (_rainfallController.text.trim().isNotEmpty)
          'rainfall_mm': double.tryParse(_rainfallController.text.trim()),
        if (_leafWetnessController.text.trim().isNotEmpty)
          'leaf_wetness_hours':
              double.tryParse(_leafWetnessController.text.trim()),
      },
    );
  }

  void _refreshForecast() {
    setState(() {
      _riskFuture = _fetchRisk();
    });
  }

  @override
  void dispose() {
    _temperatureController.dispose();
    _humidityController.dispose();
    _rainfallController.dispose();
    _leafWetnessController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = AuthService.currentUser()?.uid;
    if (uid == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Outbreak Alerts')),
        body: const Center(child: Text('Please login to view alerts.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Outbreak Alerts')),
      body: _riskFuture == null
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<Map<String, dynamic>>(
        future: _riskFuture,
        builder: (context, riskSnapshot) {
          final riskCard = _buildRiskCard(riskSnapshot);
          return StreamBuilder(
            stream: AlertService.alertStream(uid),
            builder: (context, alertSnapshot) {
              if (alertSnapshot.connectionState == ConnectionState.waiting &&
                  riskSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final hasAlerts = alertSnapshot.hasData &&
                  alertSnapshot.data != null &&
                  alertSnapshot.data!.docs.isNotEmpty;

              final children = <Widget>[
                _ForecastInputCard(
                  profile: _profile,
                  temperatureController: _temperatureController,
                  humidityController: _humidityController,
                  rainfallController: _rainfallController,
                  leafWetnessController: _leafWetnessController,
                  soilType: _soilType,
                  onSoilChanged: (value) {
                    setState(() {
                      _soilType = value;
                    });
                  },
                  onRefreshForecast: _refreshForecast,
                ),
                const SizedBox(height: 12),
                riskCard,
              ];

              if (!hasAlerts) {
                children.add(
                  const Padding(
                    padding: EdgeInsets.only(top: 20),
                    child: Center(
                      child: Text(
                        'No alerts yet.\nHigh/Moderate scan results will appear here.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                );
              } else {
                for (final doc in alertSnapshot.data!.docs) {
                  final item = doc.data();
                  final level = item['level']?.toString() ?? 'Moderate Risk';
                  final title = item['title']?.toString() ?? 'Alert';
                  final detail = item['detail']?.toString() ?? '';
                  children.add(
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: _AlertCard(
                        level: level,
                        title: title,
                        detail: detail,
                      ),
                    ),
                  );
                }
              }

              return ListView(
                padding: const EdgeInsets.all(16),
                children: children,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildRiskCard(AsyncSnapshot<Map<String, dynamic>> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const _RiskCardLoading();
    }
    if (snapshot.hasError || !snapshot.hasData) {
      return const _RiskCardError();
    }

    final data = snapshot.data!;
    final level = data['risk_level']?.toString() ?? 'low';
    final score = (data['risk_score'] as num?)?.toDouble() ?? 0;
    final reasons = List<String>.from(data['reasons'] as List<dynamic>? ?? []);
    final stats = Map<String, dynamic>.from(
      data['stats'] as Map<String, dynamic>? ?? <String, dynamic>{},
    );
    final featureBreakdown = Map<String, dynamic>.from(
      data['feature_breakdown'] as Map<String, dynamic>? ??
          const <String, dynamic>{},
    );
    final weatherContext = Map<String, dynamic>.from(
      data['weather_context'] as Map<String, dynamic>? ??
          const <String, dynamic>{},
    );
    final profileContext = Map<String, dynamic>.from(
      data['profile_context'] as Map<String, dynamic>? ??
          const <String, dynamic>{},
    );
    final recommendedActions = List<String>.from(
      data['recommended_actions'] as List<dynamic>? ?? const <dynamic>[],
    );

    final color = switch (level) {
      'high' => const Color(0xFFC62828),
      'moderate' => const Color(0xFFEF6C00),
      _ => const Color(0xFF2E7D32),
    };
    final label = switch (level) {
      'high' => 'High Outbreak Risk',
      'moderate' => 'Moderate Outbreak Risk',
      _ => 'Low Outbreak Risk',
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.45)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insights, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Risk Score: ${(score * 100).toStringAsFixed(0)}%',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          ...reasons.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('• $r'),
              )),
          const SizedBox(height: 10),
          Text(
            'Scans(14d): ${stats['total_scans_14d'] ?? 0}  '
            'High: ${stats['high_cases_14d'] ?? 0}  '
            'Moderate: ${stats['moderate_cases_14d'] ?? 0}',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF607D66),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(
                label:
                    'Crop: ${(profileContext['crop_type']?.toString().isNotEmpty ?? false) ? profileContext['crop_type'] : 'Not set'}',
              ),
              _InfoChip(
                label:
                    'Soil: ${(weatherContext['soil_type']?.toString().isNotEmpty ?? false) ? weatherContext['soil_type'] : 'Not set'}',
              ),
              _InfoChip(
                label:
                    'Humidity: ${weatherContext['humidity_pct']?.toString() ?? '-'}%',
              ),
              _InfoChip(
                label:
                    'Rainfall: ${weatherContext['rainfall_mm']?.toString() ?? '-'} mm',
              ),
            ],
          ),
          if (featureBreakdown.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Forecast Factors',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            ...featureBreakdown.entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '• ${entry.key.replaceAll('_', ' ')}: ${entry.value}',
                ),
              ),
            ),
          ],
          if (recommendedActions.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Recommended Actions',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            ...recommendedActions.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('• $item'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ForecastInputCard extends StatelessWidget {
  const _ForecastInputCard({
    required this.profile,
    required this.temperatureController,
    required this.humidityController,
    required this.rainfallController,
    required this.leafWetnessController,
    required this.soilType,
    required this.onSoilChanged,
    required this.onRefreshForecast,
  });

  final UserProfileModel? profile;
  final TextEditingController temperatureController;
  final TextEditingController humidityController;
  final TextEditingController rainfallController;
  final TextEditingController leafWetnessController;
  final String soilType;
  final ValueChanged<String> onSoilChanged;
  final VoidCallback onRefreshForecast;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD9E9DA)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Forecast Inputs',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            'Use your saved profile plus weather/soil conditions to calculate a stronger outbreak forecast.',
            style: TextStyle(
              color: Colors.grey.shade700,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(
                label:
                    'Profile Crop: ${(profile?.cropType.trim().isNotEmpty ?? false) ? profile!.cropType : 'Not set'}',
              ),
              _InfoChip(
                label:
                    'Location: ${(profile?.location.trim().isNotEmpty ?? false) ? profile!.location : 'Not set'}',
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: temperatureController,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Temperature (°C)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: humidityController,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Humidity (%)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: rainfallController,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Rainfall (mm)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: leafWetnessController,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Leaf Wetness (hours)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: soilType,
            decoration: const InputDecoration(
              labelText: 'Soil Type',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'Loam', child: Text('Loam')),
              DropdownMenuItem(value: 'Clay', child: Text('Clay')),
              DropdownMenuItem(value: 'Sandy', child: Text('Sandy')),
              DropdownMenuItem(value: 'Silty', child: Text('Silty')),
              DropdownMenuItem(value: 'Black', child: Text('Black')),
              DropdownMenuItem(value: 'Red', child: Text('Red')),
            ],
            onChanged: (value) {
              if (value == null) return;
              onSoilChanged(value);
            },
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onRefreshForecast,
            icon: const Icon(Icons.refresh),
            label: const Text('Update Forecast'),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F8F2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF42614A),
        ),
      ),
    );
  }
}

class _RiskCardLoading extends StatelessWidget {
  const _RiskCardLoading();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD9E9DA)),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2.2),
          ),
          SizedBox(width: 10),
          Text('Calculating outbreak risk...'),
        ],
      ),
    );
  }
}

class _RiskCardError extends StatelessWidget {
  const _RiskCardError();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFCCBC)),
      ),
      child: const Text(
        'Could not fetch outbreak analytics right now.',
        style: TextStyle(color: Color(0xFFB23B23)),
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({
    required this.level,
    required this.title,
    required this.detail,
  });

  final String level;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final bool isHigh = level.toLowerCase().contains('high');
    final Color color = isHigh ? const Color(0xFFC62828) : const Color(0xFFEF6C00);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.warning_amber_rounded, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  level,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(detail, style: const TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
