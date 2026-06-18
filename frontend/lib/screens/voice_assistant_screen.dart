import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../models/user_profile_model.dart';
import '../services/advisory_service.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';

class VoiceAssistantScreen extends StatefulWidget {
  const VoiceAssistantScreen({super.key});

  @override
  State<VoiceAssistantScreen> createState() => _VoiceAssistantScreenState();
}

class _VoiceAssistantScreenState extends State<VoiceAssistantScreen> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final TextEditingController _transcriptController = TextEditingController();

  static const List<Map<String, String>> _languageOptions = [
    {'label': 'English', 'locale': 'en_US'},
    {'label': 'Hindi', 'locale': 'hi_IN'},
  ];

  bool _isListening = false;
  bool _isLoading = false;
  String _selectedLocale = 'en_US';
  String _transcript = '';
  String? _error;
  Map<String, dynamic>? _advisoryResult;
  late final Future<UserProfileModel?> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _loadProfile();
  }

  Future<UserProfileModel?> _loadProfile() async {
    final uid = AuthService.currentUser()?.uid;
    if (uid == null) return null;
    return UserService.getProfile(uid);
  }

  UserProfileModel _advisoryProfile(UserProfileModel? profile, String? uid) {
    final language = _selectedLocale == 'hi_IN' ? 'Hindi' : 'English';
    return UserProfileModel(
      uid: profile?.uid ?? uid ?? '',
      name: profile?.name ?? '',
      phone: profile?.phone ?? '',
      cropType: profile?.cropType ?? '',
      location: profile?.location ?? '',
      language: language,
      soilType: profile?.soilType ?? 'Loam',
      cropStage: profile?.cropStage ?? 'Vegetative',
    );
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _speech.stop();
      if (!mounted) return;
      setState(() {
        _isListening = false;
      });
      return;
    }

    final available = await _speech.initialize(
      onError: (error) {
        if (!mounted) return;
        setState(() {
          _isListening = false;
          _error = 'Voice recognition error. Please try again.';
        });
      },
      onStatus: (status) {
        if (!mounted) return;
        if (status == 'done' || status == 'notListening') {
          setState(() {
            _isListening = false;
          });
        }
      },
    );

    if (!available) {
      setState(() {
        _error = 'Speech service unavailable on this device.';
      });
      return;
    }

    setState(() {
      _error = null;
      _isListening = true;
    });

    await _speech.listen(
      onResult: (result) {
        if (!mounted) return;
        setState(() {
          _transcript = result.recognizedWords.trim();
          _transcriptController.text = _transcript;
          _transcriptController.selection = TextSelection.fromPosition(
            TextPosition(offset: _transcriptController.text.length),
          );
        });
      },
      // ignore: deprecated_member_use
      listenMode: stt.ListenMode.dictation,
      // ignore: deprecated_member_use
      partialResults: true,
      localeId: _selectedLocale,
    );
  }

  Future<void> _submitTranscript() async {
    final text = _transcript.trim();
    if (text.isEmpty) {
      setState(() {
        _error = 'Please speak symptoms first.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final uid = AuthService.currentUser()?.uid;
      final response = await ApiService.getVoiceAdvisory(
        transcript: text,
        uid: uid,
      );
      if (!mounted) return;
      setState(() {
        _advisoryResult = response;
      });
    } on TimeoutException {
      setState(() {
        _error = 'Request timed out. Try again.';
      });
    } on SocketException {
      setState(() {
        _error = 'Backend unreachable. Check Flask server.';
      });
    } on HttpException catch (e) {
      setState(() {
        _error = e.message;
      });
    } catch (_) {
      setState(() {
        _error = 'Unable to get voice advisory.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _speech.cancel();
    _transcriptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = AuthService.currentUser()?.uid;
    final rawSeverity = _advisoryResult?['severity']?.toString() ?? '';
    final predictedClass = _advisoryResult?['predicted_class']?.toString();
    final confidence = (_advisoryResult?['confidence'] as num?)?.toDouble();
    final rawAdvice = List<String>.from(
      (_advisoryResult?['advice'] as List<dynamic>?) ?? const <dynamic>[],
    );
    final rawPrevention = List<String>.from(
      (_advisoryResult?['prevention'] as List<dynamic>?) ?? const <dynamic>[],
    );
    final entities = Map<String, dynamic>.from(
      (_advisoryResult?['entities'] as Map<String, dynamic>?) ??
          const <String, dynamic>{},
    );
    final profileContext = Map<String, dynamic>.from(
      (_advisoryResult?['profile_context'] as Map<String, dynamic>?) ??
          const <String, dynamic>{},
    );
    final evidence = List<String>.from(
      (_advisoryResult?['evidence'] as List<dynamic>?) ?? const <dynamic>[],
    );

    return FutureBuilder<UserProfileModel?>(
      future: _profileFuture,
      builder: (context, profileSnapshot) {
        final profile = profileSnapshot.data;
        final advisoryProfile = _advisoryProfile(profile, uid);
        final personalizedAdvisory = predictedClass == null
            ? null
            : AdvisoryService.getAdvisory(
                predictedClass,
                profile: advisoryProfile,
              );
        final language =
            personalizedAdvisory?['language']?.toString() ?? advisoryProfile.language;
        final isHindi = language.toLowerCase().contains('hindi');
        final displayName = personalizedAdvisory?['display_name']?.toString() ??
            predictedClass ??
            (isHindi ? 'स्पष्ट नहीं' : 'Not clear');
        final severityValue =
            personalizedAdvisory?['severity']?.toString() ??
                (rawSeverity.isEmpty ? 'moderate' : rawSeverity);
        final advice = personalizedAdvisory == null
            ? rawAdvice
            : List<String>.from(
                personalizedAdvisory['advice'] as List<dynamic>? ??
                    const <dynamic>[],
              );
        final prevention = personalizedAdvisory == null
            ? rawPrevention
            : List<String>.from(
                personalizedAdvisory['prevention'] as List<dynamic>? ??
                    const <dynamic>[],
              );
        final contextNotes = personalizedAdvisory == null
            ? const <String>[]
            : List<String>.from(
                personalizedAdvisory['context_notes'] as List<dynamic>? ??
                    const <dynamic>[],
              );
        final severityColor = AdvisoryService.severityColor(severityValue);

        return Scaffold(
          backgroundColor: const Color(0xFFF6F4EC),
          appBar: AppBar(
            title: Text(isHindi ? 'वॉइस असिस्टेंट' : 'Voice Assistant'),
          ),
          body: Stack(
            children: [
              const Positioned(
                top: -60,
                right: -20,
                child: _SoftGlow(
                  size: 220,
                  color: Color(0x223A7A42),
                ),
              ),
              const Positioned(
                top: 220,
                left: -50,
                child: _SoftGlow(
                  size: 170,
                  color: Color(0x1BC68D4A),
                ),
              ),
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _VoiceHeroCard(
                      isHindi: isHindi,
                      isListening: _isListening,
                      profile: profile,
                    ),
                    const SizedBox(height: 16),
                    _CardFrame(
                      child: Column(
                        children: [
                          Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: _isListening
                                    ? const [
                                        Color(0xFFE55C5C),
                                        Color(0xFFB3261E),
                                      ]
                                    : const [
                                        Color(0xFF4FAE63),
                                        Color(0xFF1F6B2B),
                                      ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: (_isListening
                                          ? const Color(0xFFE55C5C)
                                          : const Color(0xFF4FAE63))
                                      .withValues(alpha: 0.32),
                                  blurRadius: 20,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: Icon(
                              _isListening ? Icons.graphic_eq : Icons.mic_none,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _isListening
                                ? (isHindi ? 'सुन रहा है...' : 'Listening...')
                                : (isHindi
                                    ? 'लक्षण बोलने के लिए टैप करें'
                                    : 'Tap to speak symptoms'),
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              color: Color(0xFF203726),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            isHindi
                                ? 'हम आपकी आवाज़ को टेक्स्ट में बदलकर रोग-आधारित सलाह देंगे।'
                                : 'We convert your speech into symptom text, then generate disease-based guidance.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFF667768),
                              height: 1.45,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: _isLoading ? null : _toggleListening,
                            icon: Icon(_isListening ? Icons.stop : Icons.mic),
                            label: Text(
                              _isListening
                                  ? (isHindi
                                      ? 'सुनना बंद करें'
                                      : 'Stop Listening')
                                  : (isHindi ? 'आवाज़ शुरू करें' : 'Start Voice'),
                            ),
                          ),
                          const SizedBox(height: 14),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedLocale,
                            decoration: InputDecoration(
                              labelText:
                                  isHindi ? 'आवाज़ की भाषा' : 'Voice Language',
                            ),
                            items: _languageOptions
                                .map(
                                  (opt) => DropdownMenuItem<String>(
                                    value: opt['locale'],
                                    child: Text(opt['label']!),
                                  ),
                                )
                                .toList(),
                            onChanged: _isListening
                                ? null
                                : (value) {
                                    if (value == null) return;
                                    setState(() {
                                      _selectedLocale = value;
                                    });
                                  },
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            minLines: 4,
                            maxLines: 6,
                            readOnly: _isListening,
                            controller: _transcriptController,
                            decoration: InputDecoration(
                              labelText: isHindi
                                  ? 'लक्षण ट्रांसक्रिप्ट'
                                  : 'Symptom transcript',
                              hintText: isHindi
                                  ? 'उदाहरण: टमाटर की पत्तियों पर भूरे धब्बे हैं और जल्दी फैल रहे हैं'
                                  : 'Example: Tomato leaves have dark spots and spreading quickly',
                            ),
                            onChanged: (value) {
                              _transcript = value;
                            },
                          ),
                          const SizedBox(height: 12),
                          if (profile != null)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3F0E6),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Text(
                                isHindi
                                    ? 'प्रोफाइल संदर्भ: ${profile.cropType} • ${profile.soilType} • ${profile.cropStage}'
                                    : 'Profile context: ${profile.cropType} • ${profile.soilType} • ${profile.cropStage}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF607D66),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          if (profile != null) const SizedBox(height: 12),
                          FilledButton.tonalIcon(
                            onPressed: _isLoading ? null : _submitTranscript,
                            icon: const Icon(Icons.auto_awesome),
                            label: Text(
                              isHindi ? 'सलाह प्राप्त करें' : 'Get Advisory',
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_isLoading) ...[
                      const SizedBox(height: 14),
                      const Center(child: CircularProgressIndicator()),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: 14),
                      _InlineAlert(message: _error!),
                    ],
                    if (_advisoryResult != null) ...[
                      const SizedBox(height: 16),
                      _CardFrame(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        predictedClass == null
                                            ? (isHindi
                                                ? 'अनुमानित वर्ग: स्पष्ट नहीं'
                                                : 'Predicted Class: Not clear')
                                            : (isHindi
                                                ? 'अनुमानित वर्ग: $displayName'
                                                : 'Predicted Class: $displayName'),
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF1F3824),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          _InfoPill(
                                            icon: Icons.verified_outlined,
                                            label:
                                                AdvisoryService.severityLabel(
                                              severityValue,
                                              language: language,
                                            ),
                                            color: severityColor,
                                          ),
                                          if (confidence != null)
                                            _InfoPill(
                                              icon: Icons.speed_rounded,
                                              label:
                                                  '${(confidence * 100).toStringAsFixed(0)}% ${isHindi ? 'विश्वास' : 'confidence'}',
                                              color: const Color(0xFF356B8A),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: severityColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: Icon(
                                    Icons.record_voice_over_rounded,
                                    color: severityColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (contextNotes.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _BulletCard(
                          title:
                              isHindi ? 'कस्टम सुझाव' : 'Personalized Notes',
                          items: contextNotes,
                          icon: Icons.tune,
                        ),
                      ],
                      const SizedBox(height: 12),
                      _BulletCard(
                        title: isHindi ? 'सलाह' : 'Advice',
                        items: advice,
                        icon: Icons.healing_outlined,
                      ),
                      const SizedBox(height: 12),
                      _BulletCard(
                        title: isHindi ? 'रोकथाम' : 'Prevention',
                        items: prevention,
                        icon: Icons.shield_moon_outlined,
                      ),
                      if (profileContext.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _ProfileContextCard(
                          profileContext: profileContext,
                          isHindi: isHindi,
                        ),
                      ],
                      if (evidence.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _BulletCard(
                          title: isHindi
                              ? 'यह सलाह क्यों चुनी गई'
                              : 'Why this advisory was chosen',
                          items: evidence,
                          icon: Icons.psychology_alt_outlined,
                        ),
                      ],
                      if (entities.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _EntityCard(
                          entities: entities,
                          isHindi: isHindi,
                        ),
                      ],
                    ],
                    if (uid != null) ...[
                      const SizedBox(height: 18),
                      Text(
                        isHindi ? 'हाल की वॉइस क्वेरी' : 'Recent Voice Queries',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E3524),
                        ),
                      ),
                      const SizedBox(height: 8),
                      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: UserService.voiceQueryStream(uid),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                            return Text(
                              isHindi
                                  ? 'अभी तक कोई वॉइस क्वेरी नहीं है।'
                                  : 'No voice queries yet.',
                            );
                          }
                          final docs = snapshot.data!.docs;
                          return Column(
                            children: docs.map((doc) {
                              final data = doc.data();
                              final transcript =
                                  data['transcript']?.toString() ?? '';
                              final predicted =
                                  data['predictedClass']?.toString() ?? '-';
                              return Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFFCF7),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: const Color(0xFFE3E7DA),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _InfoPill(
                                      icon: Icons.history_toggle_off_rounded,
                                      label: predicted,
                                      color: const Color(0xFF2D6D4A),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      transcript,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        height: 1.45,
                                        color: Color(0xFF435848),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _VoiceHeroCard extends StatelessWidget {
  const _VoiceHeroCard({
    required this.isHindi,
    required this.isListening,
    required this.profile,
  });

  final bool isHindi;
  final bool isListening;
  final UserProfileModel? profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF183420), Color(0xFF27503A), Color(0xFF3E6D59)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 22,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0x18FFFFFF),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  isListening ? Icons.hearing_rounded : Icons.mic_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isHindi ? 'वॉइस सलाह' : 'Voice Advisory',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            isHindi
                ? 'लक्षण बोलिए, हम उन्हें टेक्स्ट, रोग संकेत, और इलाज सलाह में बदल देंगे।'
                : 'Speak the symptoms. We turn them into text, disease clues, and treatment guidance.',
            style: const TextStyle(
              color: Color(0xD9FFFFFF),
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _HeroChip(
                label: isHindi ? 'हिंदी + English' : 'Hindi + English',
              ),
              _HeroChip(
                label: isListening
                    ? (isHindi ? 'अभी सुन रहा है' : 'Listening now')
                    : (isHindi ? 'मैनुअल टेक्स्ट भी' : 'Manual text too'),
              ),
              if (profile != null)
                _HeroChip(
                  label:
                      '${profile!.cropType.isEmpty ? 'Crop' : profile!.cropType} • ${profile!.cropStage}',
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0x16FFFFFF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0x22FFFFFF)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _InlineAlert extends StatelessWidget {
  const _InlineAlert({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF1C2C2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFC62828)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF7F2222),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileContextCard extends StatelessWidget {
  const _ProfileContextCard({
    required this.profileContext,
    this.isHindi = false,
  });

  final Map<String, dynamic> profileContext;
  final bool isHindi;

  @override
  Widget build(BuildContext context) {
    final items = <String>[
      if ((profileContext['crop_type']?.toString().isNotEmpty ?? false))
        isHindi
            ? 'प्रोफाइल फसल: ${profileContext['crop_type']}'
            : 'Profile crop: ${profileContext['crop_type']}',
      if ((profileContext['soil_type']?.toString().isNotEmpty ?? false))
        isHindi
            ? 'मिट्टी का प्रकार: ${profileContext['soil_type']}'
            : 'Soil type: ${profileContext['soil_type']}',
      if ((profileContext['language']?.toString().isNotEmpty ?? false))
        isHindi
            ? 'पसंदीदा भाषा: ${profileContext['language']}'
            : 'Preferred language: ${profileContext['language']}',
      if ((profileContext['location']?.toString().isNotEmpty ?? false))
        isHindi
            ? 'स्थान: ${profileContext['location']}'
            : 'Location: ${profileContext['location']}',
    ];

    if (items.isEmpty) return const SizedBox.shrink();
    return _BulletCard(
      title: isHindi ? 'किसान संदर्भ उपयोग किया गया' : 'Farmer Context Used',
      items: items,
      icon: Icons.person_outline_rounded,
    );
  }
}

class _CardFrame extends StatelessWidget {
  const _CardFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE3E7DA)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _BulletCard extends StatelessWidget {
  const _BulletCard({
    required this.title,
    required this.items,
    this.icon = Icons.checklist_rounded,
  });

  final String title;
  final List<String> items;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return _CardFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F2E8),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 18, color: const Color(0xFF2E7D32)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1F3824),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle,
                    size: 18,
                    color: Color(0xFF2E7D32),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(item)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EntityCard extends StatelessWidget {
  const _EntityCard({
    required this.entities,
    this.isHindi = false,
  });

  final Map<String, dynamic> entities;
  final bool isHindi;

  @override
  Widget build(BuildContext context) {
    final rows = <String>[];
    for (final entry in entities.entries) {
      if (entry.value is! List) continue;
      final values = List<String>.from(entry.value as List<dynamic>);
      if (values.isNotEmpty) {
        rows.add('${entry.key}: ${values.join(', ')}');
      }
    }

    return _CardFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAE6F4),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.hub_outlined,
                  size: 18,
                  color: Color(0xFF6750A4),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                isHindi
                    ? 'निकाले गए लक्षण (NLP)'
                    : 'Extracted Symptoms (NLP)',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (rows.isEmpty)
            Text(
              isHindi
                  ? 'वर्तमान ट्रांसक्रिप्ट से कोई स्पष्ट एंटिटी नहीं मिली।'
                  : 'No clear entities detected from current transcript.',
            )
          else
            ...rows.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.label_outline,
                      size: 18,
                      color: Color(0xFF6750A4),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(item)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SoftGlow extends StatelessWidget {
  const _SoftGlow({
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
