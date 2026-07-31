import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../risk_engine/risk_models.dart';
import 'safety_models.dart';

final safetyFlowServiceProvider = Provider<SafetyFlowService>((ref) {
  return SafetyFlowService();
});

class SafetyFlowService {
  SafetyPlan getPlan({required RiskLevel riskLevel, required String locale}) {
    if (locale.toLowerCase().startsWith('en')) {
      return _englishPlan(riskLevel);
    }

    final steps = switch (riskLevel) {
      RiskLevel.high => const [
        SafetyStep(
          title: 'Step 0｜先確保立即安全',
          content: '如果你現在有立即危險或身邊有危險物品，請立刻遠離並撥打 110 或 119。',
        ),
        SafetyStep(
          title: 'Step A｜先穩定呼吸',
          content: '吸氣 4 秒、停 2 秒、吐氣 6 秒，重複 3 次，先讓身體降速。',
        ),
        SafetyStep(
          title: 'Step B｜選擇一位真人協助',
          content: '你不需要一個人撐著，請優先聯絡信任的大人或校內輔導窗口。',
        ),
        SafetyStep(
          title: 'Step C｜複製求助訊息',
          content: '把需求說清楚，讓對方知道你現在需要陪伴與安全協助。',
        ),
      ],
      RiskLevel.medium => const [
        SafetyStep(
          title: 'Step A｜先穩定呼吸',
          content: '吸氣 4 秒、停 2 秒、吐氣 6 秒，重複 3 次，先讓身體降速。',
        ),
        SafetyStep(
          title: 'Step B｜找一位可以說的人',
          content: '如果你願意，選一位信任的大人或朋友，先讓對方知道你最近壓力變大。',
        ),
        SafetyStep(
          title: 'Step C｜安排下一個小行動',
          content: '把下一步縮到最小：喝水、洗臉、走到明亮處、或把手機交給信任的人。',
        ),
      ],
      _ => const [
        SafetyStep(
          title: 'Step A｜先穩定呼吸',
          content: '吸氣 4 秒、停 2 秒、吐氣 6 秒，重複 3 次，先讓身體降速。',
        ),
        SafetyStep(
          title: 'Step B｜把感受寫下來',
          content: '用一句話描述「我現在最難受的是什麼」，再寫下一個你可以做到的小照顧。',
        ),
        SafetyStep(
          title: 'Step C｜需要時就求助',
          content: '如果感覺變得更難承受，請優先聯絡校內輔導資源或 1925。',
        ),
      ],
    };

    final copyTemplate = switch (riskLevel) {
      RiskLevel.high => '我現在情緒很不穩，擔心自己會做出危險行為。請你現在陪我，並協助我聯絡輔導老師或 1925。',
      RiskLevel.medium => '我最近壓力很大、情緒不太穩，想找你聊聊並請你陪我一起想想怎麼做比較安全。',
      _ => '我最近心情不太好，想找你聊聊，請你聽我說一下就好。',
    };

    return SafetyPlan(
      riskLevel: riskLevel,
      steps: steps,
      resources: const [
        SafetyResource(
          name: '校內輔導室',
          contact: '04-2233-4105',
          description: '優先聯絡導師、輔導老師或學務處（範例，可換成貴校輔導室電話）。',
        ),
        SafetyResource(
          name: '安心專線 · 24 小時',
          contact: '1925',
          description: '衛福部免費心理支持與自殺防治專線。',
        ),
        SafetyResource(
          name: '生命線',
          contact: '1995',
          description: '24 小時情緒支持與危機協談。',
        ),
        SafetyResource(
          name: '張老師',
          contact: '1980',
          description: '心理諮詢輔導（週一至六 09:00–21:00）。',
        ),
        SafetyResource(
          name: '緊急救護／報警',
          contact: '119 · 110',
          description: '有立即危險時撥打（119 救護、110 報警）。',
        ),
      ],
      copyTemplate: copyTemplate,
      disclaimer: '本應用非醫療診斷工具，不能取代心理師與醫療專業。若有立即危險請立刻撥打 110/119。',
    );
  }

  SafetyPlan _englishPlan(RiskLevel riskLevel) {
    final steps = switch (riskLevel) {
      RiskLevel.high => const [
        SafetyStep(
          title: 'Step 0 | Get immediate safety first',
          content:
              'If you are in immediate danger or near anything you could use to hurt yourself, move away and call local emergency services now.',
        ),
        SafetyStep(
          title: 'Step A | Slow your breathing',
          content:
              'Inhale for 4 seconds, hold for 2, and exhale for 6. Repeat 3 times to help your body slow down.',
        ),
        SafetyStep(
          title: 'Step B | Choose one real person',
          content:
              'You do not have to hold this alone. Contact a trusted adult, counselor, teacher, or local support line first.',
        ),
        SafetyStep(
          title: 'Step C | Copy a support message',
          content:
              'Make your need clear so the other person knows you need company and safety support now.',
        ),
      ],
      RiskLevel.medium => const [
        SafetyStep(
          title: 'Step A | Slow your breathing',
          content:
              'Inhale for 4 seconds, hold for 2, and exhale for 6. Repeat 3 times to help your body slow down.',
        ),
        SafetyStep(
          title: 'Step B | Tell one safe person',
          content:
              'If you can, choose a trusted adult or friend and let them know your stress has been rising.',
        ),
        SafetyStep(
          title: 'Step C | Pick one tiny next action',
          content:
              'Make the next step small: drink water, wash your face, move to a brighter place, or hand your phone to someone you trust.',
        ),
      ],
      _ => const [
        SafetyStep(
          title: 'Step A | Slow your breathing',
          content:
              'Inhale for 4 seconds, hold for 2, and exhale for 6. Repeat 3 times to help your body slow down.',
        ),
        SafetyStep(
          title: 'Step B | Write the feeling down',
          content:
              'Use one sentence: "The hardest part right now is..." Then write one small care action you can do.',
        ),
        SafetyStep(
          title: 'Step C | Ask for help when needed',
          content:
              'If things feel harder to carry, contact a school counselor, trusted adult, or local support line.',
        ),
      ],
    };

    final copyTemplate = switch (riskLevel) {
      RiskLevel.high =>
        'I feel emotionally unsafe and I am worried I may do something dangerous. Please stay with me now and help me contact a counselor or emergency support.',
      RiskLevel.medium =>
        'I have been under a lot of stress and feel unstable. Could you talk with me and help me think through a safer next step?',
      _ =>
        'I have not been feeling well lately. Could you listen to me for a little while?',
    };

    return SafetyPlan(
      riskLevel: riskLevel,
      steps: steps,
      resources: const [
        SafetyResource(
          name: 'School counseling office',
          contact: '04-2233-4105',
          description:
              'Reach out to your teacher, counselor, or student affairs office first (sample number — replace with your school).',
        ),
        SafetyResource(
          name: 'Careline · 24h (TW)',
          contact: '1925',
          description:
              'Free mental-health and suicide-prevention line (Taiwan).',
        ),
        SafetyResource(
          name: 'Lifeline (TW)',
          contact: '1995',
          description:
              '24-hour emotional support and crisis counseling (Taiwan).',
        ),
        SafetyResource(
          name: '988 Suicide & Crisis Lifeline (US)',
          contact: '988',
          description:
              'Call or text 988 — free, confidential, 24/7 (United States).',
        ),
        SafetyResource(
          name: 'Crisis Text Line (US)',
          contact: 'Text HOME to 741741',
          description:
              'Free, confidential text support, 24/7 (United States).',
        ),
        SafetyResource(
          name: 'Emergency',
          contact: '119 · 110 (TW) / 911 (US)',
          description:
              'Immediate danger — Taiwan: 119 ambulance, 110 police. United States: 911.',
        ),
      ],
      copyTemplate: copyTemplate,
      disclaimer:
          'This app is not a medical diagnostic tool and does not replace licensed mental health or medical professionals. If you are in immediate danger, call local emergency services now.',
    );
  }
}
