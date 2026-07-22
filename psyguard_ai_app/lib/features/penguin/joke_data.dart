class JokeData {
  // 每則笑話同時提供中英文版本，依 App 語言設定顯示對應版本。
  static const List<Map<String, String>> jokes = [
    {'q_zh': '為什麼超人要穿緊身衣？', 'a_zh': '因為救人要緊', 'q_en': 'Why did the bicycle fall over?', 'a_en': 'Because it was two-tired!'},
    {'q_zh': '熊剪了指甲變成？', 'a_zh': '能', 'q_en': 'What do you call a bear with no teeth?', 'a_en': 'A gummy bear!'},
    {'q_zh': '鯊魚吃下綠豆變成？', 'a_zh': '綠豆沙', 'q_en': 'What do you call a fish with no eyes?', 'a_en': 'A fsh!'},
    {'q_zh': '什麼刀最長？', 'a_zh': '屠龍刀，Too Long…', 'q_en': 'What did one wall say to the other wall?', 'a_en': "I'll meet you at the corner!"},
    {'q_zh': '一塊三分熟的牛排和一塊五分熟的牛排在大街上遇到了，為什麼沒打招呼？', 'a_zh': '他們都不熟...', 'q_en': 'Why did the steak refuse to fight?', 'a_en': "It wasn't well done!"},
    {'q_zh': '皮卡丘站起來？', 'a_zh': '皮卡兵', 'q_en': 'What do you call a Pokemon that stands up straight?', 'a_en': 'Pika-CHU! (attention!)'},
    {'q_zh': '什麼水永遠用不完？', 'a_zh': '口水', 'q_en': 'What kind of water never freezes?', 'a_en': 'Hot water!'},
    {'q_zh': '哪一個月有二十八天？', 'a_zh': '每個月都有28天', 'q_en': 'Which month has 28 days?', 'a_en': 'All of them do!'},
    {'q_zh': '一個人從飛機上掉下來，為什麼沒摔死？', 'a_zh': '飛機停在地上', 'q_en': 'Why did the man fall off the plane unharmed?', 'a_en': 'The plane was parked on the ground!'},
    {'q_zh': '牙醫靠什麼吃飯？', 'a_zh': '嘴巴', 'q_en': "What did the dentist say to the computer?", 'a_en': "This won't hurt a byte!"},
    {'q_zh': '七日不見如隔多久？', 'a_zh': '如隔一周', 'q_en': 'How long is a week?', 'a_en': 'Exactly seven days — no more, no less!'},
    {'q_zh': '恭喜你...', 'a_zh': '被我恭喜了', 'q_en': 'Congratulations!', 'a_en': "You've just been congratulated!"},
    {'q_zh': '身為一個過來人，我給的建議是？', 'a_zh': '別過來', 'q_en': "What's my advice as someone who's been there?", 'a_en': "Don't go there!"},
    {'q_zh': '24小時過去後？', 'a_zh': '一天就過去了', 'q_en': 'What happens after 24 hours?', 'a_en': 'A whole day has passed!'},
    {'q_zh': '小蛇問大蛇：我們有沒有毒？', 'a_zh': '因為牠剛把自己舌頭咬到了', 'q_en': 'Why did the snake ask if it was venomous?', 'a_en': 'It just bit its own tongue!'},
    {'q_zh': '為什麼很少看到蜜蜂的便便？', 'a_zh': '因為牠便蜜', 'q_en': 'Why do bees have sticky hair?', 'a_en': 'Because they use honeycombs!'},
    {'q_zh': '葡萄點名...', 'a_zh': '葡萄柚', 'q_en': 'What did the grape say when it got stepped on?', 'a_en': 'Nothing, it just let out a little wine!'},
    {'q_zh': '小馬的哥哥叫什麼？', 'a_zh': '歐巴馬', 'q_en': "What's a baby horse's favorite president?", 'a_en': "Neigh-buraham Lincoln!"},
    {'q_zh': '學海無涯...', 'a_zh': '回頭是岸', 'q_en': 'The sea of learning has no end...', 'a_en': "...but turning back gets you to shore!"},
    {'q_zh': '在哪裡跌倒？', 'a_zh': '就在那裡哭', 'q_en': 'Where should you fall down?', 'a_en': 'Right where you can cry about it!'},
  ];

  static String lazyResponse(int index, {required bool isZh, required String petNameZh, required String petNameEn}) {
    final listZh = ['$petNameZh嘆了口氣...🐧', '$petNameZh：算了，直接給你看吧 -_-', '$petNameZh搖搖頭，決定不評論你的懶惰', '$petNameZh：懶得理你，但還是給你答案'];
    final listEn = ['The $petNameEn sighs...🐧', "$petNameEn: Fine, I'll just show you -_-", "The $petNameEn shakes its head, choosing not to comment on your laziness", "$petNameEn: Can't be bothered, but here's the answer anyway"];
    final list = isZh ? listZh : listEn;
    return list[index % list.length];
  }

  static String correctResponse(int index, {required bool isZh, required String petNameZh, required String petNameEn}) {
    final listZh = ['哇你好聰明！$petNameZh決定多給你一條魚🐟', '答對了！$petNameZh開心地跳了一下🎉', '$petNameZh對你點點頭，表示讚許👏', '正確！$petNameZh：我就知道你可以的！'];
    final listEn = ["Wow, you're so smart! The $petNameEn decides to give you an extra fish🐟", "Correct! The $petNameEn happily hops with joy🎉", "The $petNameEn nods at you approvingly👏", "Correct! $petNameEn: I knew you could do it!"];
    final list = isZh ? listZh : listEn;
    return list[index % list.length];
  }

  static String wrongResponse(int index, {required bool isZh, required String petNameZh, required String petNameEn}) {
    final listZh = ['嗯...$petNameZh看了你一眼，決定假裝沒看見😶', '$petNameZh：？？？我看你是餓壞了', '不對！但$petNameZh還是愛你的🐧', '$petNameZh搖搖頭，輕輕嘆了口氣...'];
    final listEn = ["Hmm... the $petNameEn glances at you and decides to pretend it didn't see that😶", "$petNameEn: ??? You must be really hungry", "Nope! But the $petNameEn still loves you🐧", "The $petNameEn shakes its head with a soft sigh..."];
    final list = isZh ? listZh : listEn;
    return list[index % list.length];
  }

  static const List<String> inspirationalQuotes = [
    '幸福就像香水，灑給別人也一定會感染自己。',
    '生活是一面鏡子。你對它笑，它就對你笑。',
    '命運就像自己的掌紋，雖然彎彎曲曲，卻永遠掌握在自己手中。',
    '快樂不是因為擁有的多，而是因為計較的少。',
    '心簡單，世界就簡單，幸福才會生長。',
    '人生就像衛生紙，沒事的時候儘量少扯！',
    '活著一天，就是有福氣，就該珍惜。',
    '真正的快樂來源於寬容和幫助。',
  ];
}
