// 語義—情緒不一致偵測（藍宥欣設計）
// 偵測冷靜語氣下的隱藏危機

class IncongruenceDetector {
  // 代名詞密度偵測（「我」出現頻率異常升高）
  double getPronounDensity(String text) {
    final words = text.split('');
    final zhCount = RegExp(r'我').allMatches(text).length;
    // 英文以單字為單位算，再換算成跟中文相近的密度
    final enWords = text.toLowerCase().split(RegExp(r'[^a-z]+'))
        .where((w) => w.isNotEmpty).toList();
    final enCount =
        enWords.where((w) => w == 'i' || w == 'me' || w == 'my' ||
            w == 'myself' || w == "i'm").length;
    if (enWords.length >= 5) {
      return enCount / enWords.length * 100;
    }
    return words.isEmpty ? 0 : zhCount / words.length * 100;
  }

  // 認知僵化標記
  static const List<String> rigidityMarkers = [
    '一定', '必須', '絕對', '不可能', '永遠', '從來',
    '沒有人', '沒有用', '不行', '不可以', '只有',
  ];

  static const List<String> rigidityMarkersEn = [
    'always', 'never', 'must', 'have to', 'impossible',
    'everyone', 'no one', 'nobody', 'nothing', 'useless',
    'completely', 'totally', 'absolutely',
  ];

  int getRigidityScore(String text) {
    final lowered = text.toLowerCase();
    return rigidityMarkers.where((m) => text.contains(m)).length +
        rigidityMarkersEn.where((m) => lowered.contains(m)).length;
  }

  // 事件嚴重程度評估
  static const List<String> severeEventKeywords = [
    '被罵', '失敗', '被拒絕', '分手', '死', '消失',
    '沒有意義', '放棄', '撐不住', '太累', '不想',
    '沒朋友', '沒人在乎', '家人', '吵架', '打',
  ];

  static const List<String> severeEventKeywordsEn = [
    'yelled at', 'shouted at', 'failed', 'rejected', 'broke up',
    'disappear', 'meaningless', 'pointless', 'give up',
    'exhausted', 'so tired', 'no friends', 'nobody cares',
    'no one cares', 'argument', 'fight', 'hit me', 'left me',
  ];

  int getSeverityScore(String text) {
    final lowered = text.toLowerCase();
    return severeEventKeywords.where((k) => text.contains(k)).length +
        severeEventKeywordsEn.where((k) => lowered.contains(k)).length;
  }

  // 情緒強度評估（低強度詞彙）
  static const List<String> lowEmotionMarkers = [
    '沒關係', '還好', '算了', '無所謂', '隨便',
    '都可以', '沒事', '不重要', '習慣了',
  ];

  static const List<String> lowEmotionMarkersEn = [
    "it's fine", 'its fine', "i'm fine", 'im fine', "it's okay",
    'whatever', 'never mind', 'nevermind', 'no big deal',
    "doesn't matter", 'does not matter', 'used to it',
    "i'm used to it", 'no worries',
  ];

  int getLowEmotionScore(String text) {
    final lowered = text.toLowerCase();
    return lowEmotionMarkers.where((m) => text.contains(m)).length +
        lowEmotionMarkersEn.where((m) => lowered.contains(m)).length;
  }

  // 主要偵測函式
  IncongruenceResult analyze(String text) {
    final severity = getSeverityScore(text);
    final lowEmotion = getLowEmotionScore(text);
    final rigidity = getRigidityScore(text);
    final pronounDensity = getPronounDensity(text);

    // 不一致：事件很嚴重 + 語氣很平靜
    final isIncongruent = severity >= 2 && lowEmotion >= 1;
    // 認知僵化
    final isRigid = rigidity >= 2;
    // 代名詞密度過高
    final highPronoun = pronounDensity > 5;

    final riskScore = (severity * 2) + (lowEmotion * 3) + (rigidity * 2) +
        (highPronoun ? 3 : 0);

    return IncongruenceResult(
      isIncongruent: isIncongruent,
      isRigid: isRigid,
      highPronounDensity: highPronoun,
      riskScore: riskScore,
      severityScore: severity,
      lowEmotionScore: lowEmotion,
    );
  }
}

class IncongruenceResult {
  final bool isIncongruent;
  final bool isRigid;
  final bool highPronounDensity;
  final int riskScore;
  final int severityScore;
  final int lowEmotionScore;

  const IncongruenceResult({
    required this.isIncongruent,
    required this.isRigid,
    required this.highPronounDensity,
    required this.riskScore,
    required this.severityScore,
    required this.lowEmotionScore,
  });

  bool get needsAttention => riskScore >= 5;

  String get alertMessage => alertMessageFor(true);

  String alertMessageFor(bool isZh) {
    if (isIncongruent) {
      return isZh
          ? 'LUNA 注意到你描述的事情很重要，但你說「沒關係」——你真的還好嗎>///< ？'
          : 'LUNA noticed that what you described sounds heavy, but you said it is fine — are you really okay >///< ?';
    }
    if (isRigid) {
      return isZh
          ? '你說了很多「一定」和「不可能」——有時候事情沒有那麼絕對，我們可以一起看看？'
          : 'You used a lot of "always" and "impossible" — things are not always that absolute. Shall we look at it together?';
    }
    return isZh
        ? 'LUNA 在聽，你可以多說一點嗎O_O/ ？'
        : 'LUNA is listening. Would you like to say a bit more O_O/ ?';
  }
}
