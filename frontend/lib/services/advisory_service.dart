import 'package:flutter/material.dart';

import '../models/user_profile_model.dart';

class AdvisoryService {
  static const Map<String, Map<String, dynamic>> advisoryData = {
    'Tomato_Early_blight': {
      'severity': 'moderate',
      'display_name_en': 'Tomato Early Blight',
      'display_name_hi': 'टमाटर अर्ली ब्लाइट',
      'advice_en': [
        'Remove infected leaves immediately.',
        'Apply preventive fungicide as per local guidance.',
        'Monitor plants every 2-3 days for spread.',
      ],
      'advice_hi': [
        'संक्रमित पत्तियों को तुरंत हटा दें।',
        'स्थानीय सलाह के अनुसार फफूंदनाशी का प्रयोग करें।',
        'हर 2-3 दिन में पौधों की निगरानी करें।',
      ],
      'prevention_en': [
        'Maintain plant spacing for airflow.',
        'Avoid overhead irrigation late in the day.',
        'Follow crop rotation to reduce pathogen load.',
      ],
      'prevention_hi': [
        'हवा के प्रवाह के लिए पौधों के बीच दूरी रखें।',
        'शाम के बाद ऊपर से सिंचाई करने से बचें।',
        'रोग दबाव कम करने के लिए फसल चक्र अपनाएं।',
      ],
    },
    'Tomato_Late_blight': {
      'severity': 'high',
      'display_name_en': 'Tomato Late Blight',
      'display_name_hi': 'टमाटर लेट ब्लाइट',
      'advice_en': [
        'Isolate affected plants quickly.',
        'Start targeted fungicide treatment immediately.',
        'Remove severely infected plants to control outbreak.',
      ],
      'advice_hi': [
        'प्रभावित पौधों को जल्दी अलग करें।',
        'तुरंत लक्षित फफूंदनाशी उपचार शुरू करें।',
        'अधिक संक्रमित पौधों को हटाकर फैलाव नियंत्रित करें।',
      ],
      'prevention_en': [
        'Use resistant varieties when available.',
        'Reduce prolonged leaf wetness and humidity.',
        'Sanitize tools after field operations.',
      ],
      'prevention_hi': [
        'उपलब्ध होने पर प्रतिरोधी किस्मों का उपयोग करें।',
        'पत्तों की नमी और अधिक आर्द्रता कम रखें।',
        'खेत के काम के बाद औजारों को साफ करें।',
      ],
    },
    'Tomato_Bacterial_spot': {
      'severity': 'moderate',
      'display_name_en': 'Tomato Bacterial Spot',
      'display_name_hi': 'टमाटर बैक्टीरियल स्पॉट',
      'advice_en': [
        'Remove badly infected leaves from the lower canopy.',
        'Avoid touching healthy plants after wet infected leaves.',
        'Use a suitable copper-based spray if locally recommended.',
      ],
      'advice_hi': [
        'नीचे की अधिक संक्रमित पत्तियों को हटा दें।',
        'गीली संक्रमित पत्तियों के बाद स्वस्थ पौधों को छूने से बचें।',
        'स्थानीय सलाह होने पर कॉपर आधारित स्प्रे का उपयोग करें।',
      ],
      'prevention_en': [
        'Use clean seedlings and sanitize tools often.',
        'Avoid overhead irrigation during humid periods.',
        'Improve drainage around the crop bed.',
      ],
      'prevention_hi': [
        'स्वच्छ रोपाई का उपयोग करें और औजार बार-बार साफ करें।',
        'अधिक आर्द्रता में ऊपर से सिंचाई न करें।',
        'क्यारियों में जल निकास अच्छा रखें।',
      ],
    },
    'Tomato_Leaf_Mold': {
      'severity': 'moderate',
      'display_name_en': 'Tomato Leaf Mold',
      'display_name_hi': 'टमाटर लीफ मोल्ड',
      'advice_en': [
        'Reduce humidity around the tomato canopy.',
        'Prune crowded foliage to improve ventilation.',
        'Apply a recommended fungicide if the mold is spreading.',
      ],
      'advice_hi': [
        'टमाटर की पत्तियों के आसपास की आर्द्रता कम करें।',
        'घनी पत्तियों की छंटाई करके हवा का प्रवाह बढ़ाएँ।',
        'फैलाव होने पर अनुशंसित फफूंदनाशी का उपयोग करें।',
      ],
      'prevention_en': [
        'Avoid prolonged wet leaves after irrigation.',
        'Maintain good spacing in dense crop rows.',
        'Remove old infected leaf debris from the field.',
      ],
      'prevention_hi': [
        'सिंचाई के बाद पत्तियों पर लंबे समय तक नमी न रहने दें।',
        'घनी कतारों में पर्याप्त दूरी बनाए रखें।',
        'पुरानी संक्रमित पत्तियों का अवशेष खेत से हटाएँ।',
      ],
    },
    'Tomato_Septoria_leaf_spot': {
      'severity': 'moderate',
      'display_name_en': 'Tomato Septoria Leaf Spot',
      'display_name_hi': 'टमाटर सेप्टोरिया लीफ स्पॉट',
      'advice_en': [
        'Remove infected lower leaves first.',
        'Use protective fungicide where disease is increasing.',
        'Mulch the base to reduce splash spread.',
      ],
      'advice_hi': [
        'सबसे पहले नीचे की संक्रमित पत्तियों को हटाएँ।',
        'रोग बढ़ने पर सुरक्षात्मक फफूंदनाशी का उपयोग करें।',
        'छींटों से फैलाव कम करने के लिए मल्चिंग करें।',
      ],
      'prevention_en': [
        'Rotate crops after harvest.',
        'Keep foliage dry during irrigation.',
        'Remove crop residue after the season.',
      ],
      'prevention_hi': [
        'कटाई के बाद फसल चक्र अपनाएँ।',
        'सिंचाई के दौरान पत्तियाँ सूखी रखने की कोशिश करें।',
        'मौसम के बाद फसल अवशेष हटाएँ।',
      ],
    },
    'Tomato_Spider_mites_Two_spotted_spider_mite': {
      'severity': 'moderate',
      'display_name_en': 'Tomato Spider Mites',
      'display_name_hi': 'टमाटर स्पाइडर माइट्स',
      'advice_en': [
        'Inspect the underside of leaves for mite colonies.',
        'Use a locally approved miticide or strong water wash if appropriate.',
        'Remove heavily infested leaves when infestation is localized.',
      ],
      'advice_hi': [
        'पत्तियों के नीचे माइट्स की कॉलोनी की जाँच करें।',
        'स्थानीय सलाह अनुसार माइटनाशी या तेज पानी से धुलाई करें।',
        'यदि संक्रमण सीमित हो तो अधिक प्रभावित पत्तियाँ हटाएँ।',
      ],
      'prevention_en': [
        'Reduce plant stress and dust buildup.',
        'Scout crops more often in hot dry weather.',
        'Keep weeds and alternate hosts under control.',
      ],
      'prevention_hi': [
        'पौधों पर तनाव और धूल जमाव कम रखें।',
        'गर्म और सूखे मौसम में अधिक निगरानी करें।',
        'खरपतवार और वैकल्पिक होस्ट पर नियंत्रण रखें।',
      ],
    },
    'Tomato__Target_Spot': {
      'severity': 'moderate',
      'display_name_en': 'Tomato Target Spot',
      'display_name_hi': 'टमाटर टारगेट स्पॉट',
      'advice_en': [
        'Remove affected foliage and monitor nearby plants.',
        'Use recommended fungicide at the proper interval.',
        'Improve canopy ventilation and reduce leaf wetness.',
      ],
      'advice_hi': [
        'प्रभावित पत्तियाँ हटाएँ और पास के पौधों की निगरानी करें।',
        'अनुशंसित अंतराल पर फफूंदनाशी का प्रयोग करें।',
        'कैनोपी में हवा का प्रवाह बढ़ाएँ और पत्ती नमी कम करें।',
      ],
      'prevention_en': [
        'Avoid dense crop canopies.',
        'Remove diseased debris after harvest.',
        'Schedule scouting after humid spells.',
      ],
      'prevention_hi': [
        'बहुत घनी फसल कैनोपी से बचें।',
        'कटाई के बाद संक्रमित अवशेष हटा दें।',
        'आर्द्र मौसम के बाद निगरानी बढ़ाएँ।',
      ],
    },
    'Tomato__Tomato_YellowLeaf__Curl_Virus': {
      'severity': 'high',
      'display_name_en': 'Tomato Yellow Leaf Curl Virus',
      'display_name_hi': 'टमाटर येलो लीफ कर्ल वायरस',
      'advice_en': [
        'Remove severely infected plants to reduce virus spread.',
        'Control whitefly population quickly.',
        'Avoid moving from infected to healthy plants without sanitation.',
      ],
      'advice_hi': [
        'वायरस फैलाव कम करने के लिए अधिक संक्रमित पौधे हटा दें।',
        'व्हाइटफ्लाई पर जल्दी नियंत्रण करें।',
        'सफाई के बिना संक्रमित पौधों से स्वस्थ पौधों में न जाएँ।',
      ],
      'prevention_en': [
        'Use resistant varieties when possible.',
        'Install vector control measures early.',
        'Remove alternate weed hosts around the field.',
      ],
      'prevention_hi': [
        'संभव हो तो प्रतिरोधी किस्मों का उपयोग करें।',
        'कीट नियंत्रण उपाय जल्दी शुरू करें।',
        'खेत के आसपास वैकल्पिक खरपतवार होस्ट हटाएँ।',
      ],
    },
    'Tomato__Tomato_mosaic_virus': {
      'severity': 'high',
      'display_name_en': 'Tomato Mosaic Virus',
      'display_name_hi': 'टमाटर मोज़ेक वायरस',
      'advice_en': [
        'Remove highly symptomatic plants from the field.',
        'Disinfect tools and hands frequently.',
        'Avoid tobacco contamination while handling plants.',
      ],
      'advice_hi': [
        'ज्यादा लक्षण वाले पौधों को खेत से हटा दें।',
        'औजार और हाथ बार-बार कीटाणुरहित करें।',
        'पौधों को छूते समय तंबाकू संदूषण से बचें।',
      ],
      'prevention_en': [
        'Use clean seed and resistant varieties where available.',
        'Avoid mechanical spread through workers and tools.',
        'Control weed hosts near the crop.',
      ],
      'prevention_hi': [
        'स्वच्छ बीज और उपलब्ध होने पर प्रतिरोधी किस्मों का उपयोग करें।',
        'कर्मचारियों और औजारों से यांत्रिक फैलाव रोकें।',
        'फसल के पास खरपतवार होस्ट नियंत्रित करें।',
      ],
    },
    'Tomato_healthy': {
      'severity': 'healthy',
      'display_name_en': 'Tomato Healthy',
      'display_name_hi': 'स्वस्थ टमाटर',
      'advice_en': [
        'Crop appears healthy, continue monitoring.',
        'Maintain current irrigation and nutrition schedule.',
      ],
      'advice_hi': [
        'फसल स्वस्थ दिख रही है, निगरानी जारी रखें।',
        'वर्तमान सिंचाई और पोषण प्रबंधन जारी रखें।',
      ],
      'prevention_en': [
        'Weekly scouting for early symptoms.',
        'Keep field sanitation and weed control regular.',
      ],
      'prevention_hi': [
        'हर सप्ताह शुरुआती लक्षणों की जाँच करें।',
        'खेत की सफाई और खरपतवार नियंत्रण नियमित रखें।',
      ],
    },
    'Potato___Early_blight': {
      'severity': 'moderate',
      'display_name_en': 'Potato Early Blight',
      'display_name_hi': 'आलू अर्ली ब्लाइट',
      'advice_en': [
        'Remove affected foliage and monitor nearby plants.',
        'Use recommended fungicide at proper interval.',
        'Improve canopy ventilation.',
      ],
      'advice_hi': [
        'प्रभावित पत्तियाँ हटाएँ और आसपास के पौधों की निगरानी करें।',
        'अनुशंसित अंतराल पर फफूंदनाशी का उपयोग करें।',
        'कैनोपी वेंटिलेशन बेहतर करें।',
      ],
      'prevention_en': [
        'Use disease-free seed tubers.',
        'Rotate with non-host crops.',
        'Avoid moisture stress during growth.',
      ],
      'prevention_hi': [
        'रोग-मुक्त बीज कंद का उपयोग करें।',
        'गैर-होस्ट फसलों के साथ फसल चक्र अपनाएँ।',
        'विकास के दौरान नमी तनाव से बचें।',
      ],
    },
    'Potato___Late_blight': {
      'severity': 'high',
      'display_name_en': 'Potato Late Blight',
      'display_name_hi': 'आलू लेट ब्लाइट',
      'advice_en': [
        'Remove severely infected foliage immediately.',
        'Start a blight-specific fungicide program without delay.',
        'Increase field scouting in nearby rows.',
      ],
      'advice_hi': [
        'अधिक संक्रमित पत्तियाँ तुरंत हटा दें।',
        'लेट ब्लाइट के लिए विशेष फफूंदनाशी कार्यक्रम शुरू करें।',
        'पास की कतारों में खेत निगरानी बढ़ाएँ।',
      ],
      'prevention_en': [
        'Avoid standing moisture in the canopy.',
        'Destroy infected volunteer plants and debris.',
        'Use preventive sprays before long wet spells.',
      ],
      'prevention_hi': [
        'कैनोपी में लंबे समय तक नमी न रहने दें।',
        'संक्रमित स्वयं उगे पौधे और अवशेष नष्ट करें।',
        'लंबे गीले मौसम से पहले सुरक्षात्मक स्प्रे करें।',
      ],
    },
    'Potato___healthy': {
      'severity': 'healthy',
      'display_name_en': 'Potato Healthy',
      'display_name_hi': 'स्वस्थ आलू',
      'advice_en': [
        'No visible disease signs detected.',
        'Continue preventive management practices.',
      ],
      'advice_hi': [
        'कोई स्पष्ट रोग लक्षण नहीं दिखे।',
        'निवारक प्रबंधन जारी रखें।',
      ],
      'prevention_en': [
        'Regular scouting and sanitation.',
        'Balanced fertilization and irrigation.',
      ],
      'prevention_hi': [
        'नियमित निगरानी और स्वच्छता बनाए रखें।',
        'संतुलित उर्वरक और सिंचाई करें।',
      ],
    },
    'Pepper__bell___Bacterial_spot': {
      'severity': 'moderate',
      'display_name_en': 'Pepper Bacterial Spot',
      'display_name_hi': 'शिमला मिर्च बैक्टीरियल स्पॉट',
      'advice_en': [
        'Remove infected leaves and avoid overhead irrigation.',
        'Use a copper-based spray if locally recommended.',
        'Avoid field work when foliage is wet.',
      ],
      'advice_hi': [
        'संक्रमित पत्तियाँ हटाएँ और ऊपर से सिंचाई से बचें।',
        'स्थानीय सलाह अनुसार कॉपर स्प्रे का उपयोग करें।',
        'गीली पत्तियों के समय खेत का काम कम करें।',
      ],
      'prevention_en': [
        'Use clean seed and disease-free transplants.',
        'Disinfect tools and avoid working in wet fields.',
        'Improve drainage in pepper beds.',
      ],
      'prevention_hi': [
        'स्वच्छ बीज और रोग-मुक्त पौध उपयोग करें।',
        'औजार साफ रखें और गीले खेत में काम से बचें।',
        'मिर्च की क्यारियों में अच्छा जल निकास रखें।',
      ],
    },
    'Pepper__bell___healthy': {
      'severity': 'healthy',
      'display_name_en': 'Pepper Healthy',
      'display_name_hi': 'स्वस्थ शिमला मिर्च',
      'advice_en': [
        'No disease pattern detected in the crop.',
        'Continue balanced irrigation and nutrition.',
      ],
      'advice_hi': [
        'फसल में कोई रोग पैटर्न नहीं मिला।',
        'संतुलित सिंचाई और पोषण जारी रखें।',
      ],
      'prevention_en': [
        'Weekly scouting and weed management.',
        'Keep the field clean and well ventilated.',
      ],
      'prevention_hi': [
        'साप्ताहिक निगरानी और खरपतवार प्रबंधन करें।',
        'खेत साफ और हवादार रखें।',
      ],
    },
  };

  static Map<String, dynamic> getAdvisory(
    String predictedClass, {
    UserProfileModel? profile,
    List<Map<String, dynamic>> recentScans = const [],
  }) {
    final base = advisoryData[predictedClass] ?? _fallbackAdvisory(predictedClass);
    final language = (profile?.language.trim().isNotEmpty ?? false)
        ? profile!.language
        : 'English';
    final isHindi = language.toLowerCase().contains('hindi');
    final advice = List<String>.from(
      isHindi ? base['advice_hi'] as List<dynamic> : base['advice_en'] as List<dynamic>,
    );
    final prevention = List<String>.from(
      isHindi
          ? base['prevention_hi'] as List<dynamic>
          : base['prevention_en'] as List<dynamic>,
    );

    final severity = base['severity'] as String? ?? 'moderate';
    final recurringCount = recentScans.where((scan) {
      final disease = scan['predictedClass']?.toString() ?? '';
      return disease == predictedClass;
    }).length;

    final contextNotes = <String>[
      ..._stageNotes(
        cropStage: profile?.cropStage ?? 'Vegetative',
        severity: severity,
        isHindi: isHindi,
      ),
      ..._soilNotes(
        soilType: profile?.soilType ?? 'Loam',
        severity: severity,
        isHindi: isHindi,
      ),
      ..._recurrenceNotes(
        recurringCount: recurringCount,
        isHindi: isHindi,
      ),
      ..._locationNotes(
        location: profile?.location ?? '',
        isHindi: isHindi,
      ),
    ];

    advice.addAll(contextNotes.take(2));
    prevention.addAll(contextNotes.skip(2));

    final reminderDays = switch (severity) {
      'high' => [1, 2, 5],
      'healthy' => [7],
      _ => [2, 5, 9],
    };

    return {
      'severity': severity,
      'advice': advice,
      'prevention': prevention,
      'display_name': isHindi
          ? (base['display_name_hi'] ?? predictedClass)
          : (base['display_name_en'] ?? predictedClass),
      'language': language,
      'context_notes': contextNotes,
      'recurring_count': recurringCount,
      'reminder_days': reminderDays,
    };
  }

  static Map<String, dynamic> _fallbackAdvisory(String predictedClass) {
    if (predictedClass.contains('Offline_Field_Review')) {
      final cropName = predictedClass
          .replaceAll('_Offline_Field_Review', '')
          .replaceAll('_', ' ')
          .trim();
      final titledCrop = cropName.isEmpty ? 'Crop' : cropName;
      return {
        'severity': 'moderate',
        'display_name_en': '$titledCrop Offline Field Review',
        'display_name_hi': '$titledCrop ऑफ़लाइन फील्ड रिव्यू',
        'advice_en': [
          'Network is weak or unavailable, so this is an offline field review instead of a full model-confirmed diagnosis.',
          'Reconnect and rescan the same leaf when signal improves for a verified AI result.',
          'Until then, isolate visibly affected leaves and monitor spread closely.',
        ],
        'advice_hi': [
          'नेटवर्क उपलब्ध नहीं है, इसलिए यह पूर्ण एआई निदान के बजाय ऑफ़लाइन फील्ड रिव्यू है।',
          'सिग्नल बेहतर होने पर उसी पत्ती को फिर से स्कैन करें ताकि सत्यापित एआई परिणाम मिल सके।',
          'तब तक, संक्रमित दिखने वाली पत्तियों को अलग रखें और फैलाव पर नजर रखें।',
        ],
        'prevention_en': [
          'Capture the next image in brighter light and keep the leaf centered.',
          'Avoid overhead irrigation until the diagnosis is confirmed.',
          'Record weather and symptom changes so the next scan has stronger context.',
        ],
        'prevention_hi': [
          'अगली तस्वीर अच्छी रोशनी में लें और पत्ती को बीच में रखें।',
          'निदान की पुष्टि होने तक ऊपर से सिंचाई करने से बचें।',
          'अगले स्कैन के लिए मौसम और लक्षणों के बदलाव नोट करें।',
        ],
      };
    }

    return {
      'severity': 'moderate',
      'display_name_en': predictedClass.replaceAll('_', ' '),
      'display_name_hi': predictedClass.replaceAll('_', ' '),
      'advice_en': [
        'Diagnosis is outside the curated advisory map. Review with a local agronomist.',
      ],
      'advice_hi': [
        'यह निदान मानक सलाह सूची में नहीं है। स्थानीय कृषि विशेषज्ञ से सलाह लें।',
      ],
      'prevention_en': [
        'Continue sanitation and close monitoring.',
      ],
      'prevention_hi': [
        'स्वच्छता और नियमित निगरानी जारी रखें।',
      ],
    };
  }

  static List<String> _stageNotes({
    required String cropStage,
    required String severity,
    required bool isHindi,
  }) {
    final stage = cropStage.toLowerCase();
    if (stage == 'seedling') {
      return [
        isHindi
            ? 'नर्सरी या शुरुआती अवस्था में संक्रमित पौध जल्दी अलग करें।'
            : 'At seedling stage, remove infected plants quickly to avoid spread.',
      ];
    }
    if (stage == 'flowering' || stage == 'fruiting') {
      return [
        isHindi
            ? 'फूल/फल अवस्था में रोग नियंत्रण में देरी से उत्पादन पर असर पड़ सकता है।'
            : 'During flowering or fruiting, delayed treatment can reduce yield quickly.',
      ];
    }
    if (severity == 'healthy') {
      return [
        isHindi
            ? 'वर्तमान अवस्था में नियमित निगरानी पर्याप्त है।'
            : 'At this crop stage, routine scouting is enough for now.',
      ];
    }
    return [
      isHindi
          ? 'वर्तमान फसल अवस्था के अनुसार पत्तियों की नियमित जाँच करें।'
          : 'Adjust scouting frequency to the current crop stage.',
    ];
  }

  static List<String> _soilNotes({
    required String soilType,
    required String severity,
    required bool isHindi,
  }) {
    final soil = soilType.toLowerCase();
    if (soil.contains('clay') || soil.contains('black')) {
      return [
        isHindi
            ? 'भारी मिट्टी में नमी अधिक रुक सकती है, इसलिए जल निकास बेहतर रखें।'
            : 'Heavy soils can retain moisture longer, so improve drainage carefully.',
      ];
    }
    if (soil.contains('sandy')) {
      return [
        isHindi
            ? 'रेतीली मिट्टी में पौधों को नमी तनाव से बचाएँ और पोषण संतुलित रखें।'
            : 'Sandy soil can stress plants quickly, so avoid moisture stress and keep nutrition balanced.',
      ];
    }
    if (severity == 'high') {
      return [
        isHindi
            ? 'मिट्टी की नमी और पत्तियों की नमी दोनों पर ध्यान दें।'
            : 'Manage both soil moisture and canopy wetness aggressively during high-risk disease.',
      ];
    }
    return [];
  }

  static List<String> _recurrenceNotes({
    required int recurringCount,
    required bool isHindi,
  }) {
    if (recurringCount >= 2) {
      return [
        isHindi
            ? 'यह रोग हाल की स्कैन हिस्ट्री में बार-बार दिखा है, इसलिए स्वच्छता और निगरानी बढ़ाएँ।'
            : 'This disease has appeared repeatedly in recent scans, so increase sanitation and follow-up monitoring.',
      ];
    }
    return [];
  }

  static List<String> _locationNotes({
    required String location,
    required bool isHindi,
  }) {
    if (location.trim().isEmpty) return [];
    return [
      isHindi
          ? 'स्थान: $location के अनुसार मौसम और नमी की स्थिति पर ध्यान दें।'
          : 'Location: $location. Adjust treatment timing according to local moisture and weather conditions.',
    ];
  }

  static String severityLabel(String severity, {String language = 'English'}) {
    final isHindi = language.toLowerCase().contains('hindi');
    switch (severity) {
      case 'high':
        return isHindi ? 'उच्च जोखिम' : 'High Risk';
      case 'healthy':
        return isHindi ? 'स्वस्थ' : 'Healthy';
      default:
        return isHindi ? 'मध्यम जोखिम' : 'Moderate Risk';
    }
  }

  static Color severityColor(String severity) {
    switch (severity) {
      case 'high':
        return const Color(0xFFC62828);
      case 'healthy':
        return const Color(0xFF2E7D32);
      default:
        return const Color(0xFFEF6C00);
    }
  }
}
