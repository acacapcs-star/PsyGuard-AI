class DailyQuote {
  final String content;
  final String contentEn;
  final String author;
  final String authorEn;
  final String category;

  const DailyQuote({
    required this.content,
    this.contentEn = '',
    this.author = '自我慈悲引導',
    this.authorEn = 'Self-compassion guide',
    this.category = 'support',
  });

  /// 英文版沒填時退回中文，不會出現空白。
  String contentFor(bool isZh) =>
      (isZh || contentEn.isEmpty) ? content : contentEn;

  String authorFor(bool isZh) => isZh ? author : authorEn;
}

const List<DailyQuote> kSelfCompassionQuotes = [
  DailyQuote(
    content: '即使今天感覺很糟，我也不需要透過自我懲罰來讓自己好過一點。',
    contentEn:
        'Even if today feels awful, I do not need to punish myself to feel better.',
    category: 'self_care',
  ),
  DailyQuote(
    content: '這個情緒是暫時的，它像雲一樣會飄過來，也會飄走。',
    contentEn:
        'This feeling is temporary. Like a cloud, it drifts in and it drifts away.',
    category: 'mindfulness',
  ),
  DailyQuote(
    content: '我有權利休息，有權利說不，有權利照顧自己的需求。',
    contentEn:
        'I have the right to rest, the right to say no, and the right to care for my own needs.',
    category: 'boundaries',
  ),
  DailyQuote(
    content: '做得不完美也沒關係，我正在學習的過程中。',
    contentEn: 'It is okay to be imperfect. I am still learning.',
    category: 'growth',
  ),
  DailyQuote(
    content: '我所感受到的痛苦，證明了我是一個有血有肉、擁有同理心的人。',
    contentEn:
        'The pain I feel is proof that I am a real, feeling person with empathy.',
    category: 'validation',
  ),
  DailyQuote(
    content: '不需要每件事都想通，只要專注在下一個小小的步驟就好。',
    contentEn:
        'I do not need to figure everything out. I only need the next small step.',
    category: 'action',
  ),
  DailyQuote(
    content: '這是一個困難的時刻，而每個人都會經歷困難的時刻。願我能給自己一些慈悲。',
    contentEn:
        'This is a hard moment, and hard moments come to everyone. May I offer myself some kindness.',
    category: 'compassion',
  ),
  DailyQuote(
    content: '我的價值不取決於我的生產力或是別人的評價。',
    contentEn:
        'My worth is not measured by my productivity or by what others think of me.',
    category: 'worth',
  ),
  DailyQuote(
    content: '深呼吸。我在這裡。我是安全的。',
    contentEn: 'Breathe deeply. I am here. I am safe.',
    category: 'grounding',
  ),
  DailyQuote(
    content: '對自己說話時，試著像對最好的朋友說話一樣溫柔。',
    contentEn:
        'When I speak to myself, let me be as gentle as I would be with my closest friend.',
    category: 'friendship',
  ),
  DailyQuote(
    content: '允許自己感到脆弱，這是一種勇敢的表現。',
    contentEn: 'Letting myself feel vulnerable is its own kind of courage.',
    category: 'courage',
  ),
  DailyQuote(
    content: '今天能做到這樣，已經很棒了。',
    contentEn: 'What I managed today is already enough.',
    category: 'affirmation',
  ),
  DailyQuote(
    content: '接受現況不代表放棄改變，而是停止與現實對抗，將力氣花在照顧自己。',
    contentEn:
        'Accepting things as they are is not giving up on change. It is choosing to stop fighting reality and spend that energy on caring for myself.',
    category: 'acceptance',
  ),
  DailyQuote(
    content: '我不必時刻保持堅強，崩潰一下也是可以的。',
    contentEn: 'I do not have to be strong every moment. Falling apart is allowed.',
    category: 'permission',
  ),
  DailyQuote(
    content: '所有發生的一切，都是為了教會我某件事。',
    contentEn: 'Everything that happens has something to teach me.',
    category: 'meaning',
  ),
  DailyQuote(
    content: '愛自己不是一種感覺，而是一個具體的行動。',
    contentEn: 'Loving myself is not a feeling. It is something I do.',
    category: 'action',
  ),
  DailyQuote(
    content: '每一次的深呼吸，都是給身心的一次擁抱。',
    contentEn: 'Every deep breath is a small hug for my body and mind.',
    category: 'body',
  ),
  DailyQuote(
    content: '過去的錯誤定義不了我，每一刻都是新的開始。',
    contentEn: 'Past mistakes do not define me. Every moment is a fresh start.',
    category: 'future',
  ),
  DailyQuote(
    content: '我不需要為了被愛而改變原本的樣子。',
    contentEn: 'I do not need to change who I am in order to be loved.',
    category: 'relationship',
  ),
  DailyQuote(
    content: '平靜不是沒有混亂，而是在混亂中找到內心的安寧。',
    contentEn:
        'Peace is not the absence of chaos. It is finding stillness inside it.',
    category: 'peace',
  ),
];
