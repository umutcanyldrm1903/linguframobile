/// Guidebook (dilbilgisi rehberi) statik içeriği. Backend endpoint'i yoksa
/// kullanılır; ileride `/practice/guidebook` eklenirse aynı şekille beslenebilir.
class GuidebookKeyPhrase {
  const GuidebookKeyPhrase({required this.phrase, required this.meaning});
  final String phrase;
  final String meaning;
}

class GuidebookUnit {
  const GuidebookUnit({
    required this.unit,
    required this.title,
    required this.tipTitle,
    required this.tip,
    required this.phrases,
  });

  final String unit;
  final String title;
  final String tipTitle;
  final String tip;
  final List<GuidebookKeyPhrase> phrases;
}

const List<GuidebookUnit> practiceGuidebook = [
  GuidebookUnit(
    unit: '1. Ünite',
    title: 'Tanışma ve selamlaşma',
    tipTitle: '"to be" fiili (am / is / are)',
    tip:
        'İngilizcede özneyle birlikte "to be" fiili değişir: I am, you are, he/she/it is, we/they are. '
        'Olumsuzda "not" eklenir (I am not), soruda fiil başa gelir (Are you...?).',
    phrases: [
      GuidebookKeyPhrase(phrase: 'Hello, how are you?', meaning: 'Merhaba, nasılsın?'),
      GuidebookKeyPhrase(phrase: 'I am fine, thanks.', meaning: 'İyiyim, teşekkürler.'),
      GuidebookKeyPhrase(phrase: 'What is your name?', meaning: 'Adın ne?'),
      GuidebookKeyPhrase(phrase: 'Nice to meet you.', meaning: 'Tanıştığımıza memnun oldum.'),
    ],
  ),
  GuidebookUnit(
    unit: '2. Ünite',
    title: 'Günlük ifadeler',
    tipTitle: 'Belirsiz artikel (a / an)',
    tip:
        'Tekil sayılabilen isimlerin önüne "a" gelir; sesli harfle başlayan kelimelerden önce "an" kullanılır '
        '(a coffee, an apple). Çoğullarda artikel kullanılmaz.',
    phrases: [
      GuidebookKeyPhrase(phrase: 'I would like a coffee.', meaning: 'Bir kahve istiyorum.'),
      GuidebookKeyPhrase(phrase: 'Can I have the menu?', meaning: 'Menüyü alabilir miyim?'),
      GuidebookKeyPhrase(phrase: 'How much is it?', meaning: 'Ne kadar?'),
    ],
  ),
  GuidebookUnit(
    unit: '3. Ünite',
    title: 'Seyahat',
    tipTitle: 'Kibar sorular (Could / Would)',
    tip:
        'Ricalarda "Could you...?" ve "Would you...?" daha kibardır. '
        'Yön sorarken "Where is...?" / "How do I get to...?" kalıpları kullanılır.',
    phrases: [
      GuidebookKeyPhrase(phrase: 'Where is the station?', meaning: 'İstasyon nerede?'),
      GuidebookKeyPhrase(phrase: 'Could you help me?', meaning: 'Bana yardım edebilir misin?'),
      GuidebookKeyPhrase(phrase: 'I have a reservation.', meaning: 'Rezervasyonum var.'),
    ],
  ),
  GuidebookUnit(
    unit: '4. Ünite',
    title: 'İş ve iletişim',
    tipTitle: 'Şimdiki ve geniş zaman',
    tip:
        'Geniş zaman alışkanlıkları anlatır (I work...). Şimdiki zaman "am/is/are + -ing" '
        'ile o an olanı anlatır (I am working...).',
    phrases: [
      GuidebookKeyPhrase(phrase: 'Can we discuss this?', meaning: 'Bunu konuşabilir miyiz?'),
      GuidebookKeyPhrase(phrase: 'Thank you for your message.', meaning: 'Mesajınız için teşekkürler.'),
      GuidebookKeyPhrase(phrase: 'I will send it today.', meaning: 'Bugün göndereceğim.'),
    ],
  ),
];
