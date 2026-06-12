import 'package:flutter/widgets.dart';

class AppLocalizations {
  final Locale locale;

  const AppLocalizations(this.locale);

  static const supportedLocales = [Locale('en'), Locale('ka')];

  static const delegate = _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    final localizations = Localizations.of<AppLocalizations>(
      context,
      AppLocalizations,
    );
    assert(localizations != null, 'AppLocalizations is not configured.');
    return localizations!;
  }

  bool get isGeorgian => locale.languageCode == 'ka';

  String t(String key) {
    final language = isGeorgian ? _ka : _en;
    return language[key] ?? _en[key] ?? key;
  }

  String peopleNearby(int count) {
    return isGeorgian ? '$count ადამიანი ახლოს' : '$count people nearby';
  }

  String enterCodeSentTo(String phoneNumber) {
    return isGeorgian
        ? 'შეიყვანე კოდი, რომელიც გაიგზავნა ნომერზე $phoneNumber'
        : 'Enter the code sent to $phoneNumber';
  }

  String temporaryConnectionUntil(String time) {
    return isGeorgian
        ? 'დროებითი კავშირი აქტიურია $time-მდე'
        : 'Temporary connection until $time';
  }

  String revealValue(String type, String value) {
    return isGeorgian ? '$type: $value' : '$type: $value';
  }

  String approveReveal(String type) {
    return isGeorgian
        ? 'დავადასტუროთ $type-ის გაზიარება?'
        : 'Approve $type reveal?';
  }

  String revealStatus(String type, String status) {
    return isGeorgian ? '$type გაზიარება: $status' : '$type reveal: $status';
  }

  String optionTitle(String typeName, String fallback) {
    return t('option.$typeName') == 'option.$typeName'
        ? fallback
        : t('option.$typeName');
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales.any(
      (supported) => supported.languageCode == locale.languageCode,
    );
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    final languageCode = isSupported(locale) ? locale.languageCode : 'en';
    return AppLocalizations(Locale(languageCode));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

const _en = {
  'app.name': 'Nearo',
  'app.tagline': 'The social layer of real life.',
  'common.cancel': 'Cancel',
  'common.done': 'Done',
  'nav.home': 'Home',
  'nav.nearby': 'Nearby',
  'nav.spots': 'Spots',
  'nav.profile': 'Profile',
  'spots.search': 'Search spots',
  'spots.empty': 'No spots found.',
  'spots.error': 'Could not load spots.',
  'spots.filter.nearMe': 'Near Me',
  'spots.filter.oneKm': '1km',
  'spots.filter.threeKm': '3km',
  'spots.filter.trending': 'Trending',
  'spots.filter.jazz': 'Jazz',
  'spots.filter.chill': 'Chill',
  'spots.filter.lively': 'Lively',
  'spots.filter.romantic': 'Romantic',
  'spots.filter.party': 'Party',
  'status.openToConnect': 'Open to Connect',
  'status.invisible': 'Invisible',
  'visibility.visibleNearby': 'Visible Nearby',
  'visibility.visibleToNearby': 'Visible to nearby people',
  'visibility.subtitle':
      'Turn this off when you do not want to appear in Nearby.',
  'home.matchSubtitle':
      'Choose Meet Now, Easy Start, Fun Game, or contact reveal.',
  'home.activeMatches': 'active matches',
  'home.peopleOpen': 'Open',
  'home.matchesTonight': 'Matches',
  'home.visible': 'Visible',
  'auth.phoneHelp':
      'Enter your phone number to connect with people who are actually nearby.',
  'auth.phoneNumber': 'Phone number',
  'auth.phoneValidation': 'Use international format, e.g. +995...',
  'auth.sendSmsCode': 'Send SMS code',
  'auth.continueDemo': 'Continue in demo mode',
  'auth.demoNotice':
      'Firebase credentials are placeholders. Any SMS code works in demo mode.',
  'auth.verifyPhone': 'Verify phone',
  'auth.smsCode': 'SMS code',
  'auth.verifyAndContinue': 'Verify and continue',
  'auth.resendCode': 'Resend code',
  'nearby.incomingSparks': 'Incoming Sparks',
  'nearby.refreshWifi': 'Refresh Wi-Fi proximity',
  'nearby.title': 'Nearby',
  'nearby.visibleSubtitle':
      'People open to connect on your current venue signal',
  'nearby.invisibleSubtitle': 'Turn visibility on to appear nearby',
  'nearby.empty': 'No visible users found at your current venue.',
  'nearby.error': 'Could not load nearby users.',
  'nearby.bioFallback': 'Open to a calm conversation.',
  'nearby.sent': 'Sent',
  'nearby.sendSpark': 'Send Spark',
  'filter.all': 'All',
  'filter.openToMeet': 'Open to Meet',
  'filter.easyStart': 'Easy Start',
  'filter.partyMood': 'Party Mood',
  'filter.chill': 'Chill',
  'profile.title': 'Profile',
  'profile.signOut': 'Sign out',
  'profile.noProfile': 'No profile loaded.',
  'profile.signalsSent': 'Signals sent',
  'profile.matches': 'Matches',
  'profile.demoMode': 'Demo mode',
  'profile.yes': 'Yes',
  'profile.no': 'No',
  'profile.safety': 'Safety',
  'profile.safetyText':
      'Meet in public places, respect boundaries, and use reporting tools if someone behaves inappropriately.',
  'profile.safetyTools':
      'Report and block tools are available from match actions',
  'profile.safetyBlockTitle': 'Block',
  'profile.safetyBlockText':
      'Blocked people are hidden from Nearby and cannot continue interaction with you.',
  'profile.safetyReportTitle': 'Report',
  'profile.safetyReportText':
      'Reports create a moderation record for unsafe or inappropriate behavior.',
  'profile.safetyRevealTitle': 'Mutual contact reveal',
  'profile.safetyRevealText':
      'Phone and social details are shown only after mutual approval.',
  'profile.loadError': 'Could not load profile.',
  'language.title': 'Language',
  'language.english': 'English',
  'language.georgian': 'ქართული',
  'onboarding.title': 'Create your Nearo profile',
  'onboarding.subtitle': 'Low-pressure, real-world connections.',
  'onboarding.nickname': 'Nickname',
  'onboarding.nicknameRequired': 'Nickname is required.',
  'onboarding.age': 'Age',
  'onboarding.ageRequired': 'Nearo is 18+ for nightlife safety.',
  'onboarding.mood': 'Mood',
  'onboarding.bio': 'Bio',
  'onboarding.optionalSocials': 'Optional socials',
  'onboarding.safetyAgreement':
      'I agree to respectful conduct, privacy-first contact reveal, and real-world safety rules.',
  'onboarding.safetyRequired': 'Safety agreement is required.',
  'onboarding.enter': 'Enter Nearo',
  'onboarding.photoRequired': 'Profile photo is required.',
  'onboarding.saveError': 'Could not save profile. Please try again.',
  'onboarding.profilePhoto': 'Profile photo',
  'onboarding.photoUrlAdded': 'Photo URL added',
  'onboarding.addClearPhoto': 'Add a clear profile photo',
  'onboarding.choosePhoto': 'Choose photo',
  'onboarding.pastePhotoUrl': 'Or paste photo URL',
  'match.title': "It's a Match",
  'match.you': 'You',
  'match.match': 'Match',
  'match.chat': 'Match chat',
  'match.block': 'Block',
  'match.report': 'Report',
  'match.reportSubmitted': 'Report submitted for moderation.',
  'match.meetNowSaved': 'Meet Now intent saved. No exact location is shared.',
  'match.chooseSocial': 'Choose social to reveal',
  'chat.typeMessage': 'Type a message...',
  'chat.sendError': 'Could not send message.',
  'chat.quickPrompts': 'Quick prompts',
  'chat.actions': 'Conversation actions',
  'chat.promptCoffee': 'Coffee?',
  'chat.promptFun': 'Say something fun',
  'chat.promptEasyStart': 'Easy Start',
  'reveal.decline': 'Decline',
  'reveal.approve': 'Approve',
  'option.meetNow': 'Meet Now',
  'option.easyStart': 'Easy Start',
  'option.funGame': 'Fun Game',
  'option.leaveSocial': 'Leave Social',
  'option.leaveNumber': 'Leave Number',
  'option.openChat': 'Open Chat',
};

const _ka = {
  'app.name': 'Nearo',
  'app.tagline': 'რეალური ცხოვრების სოციალური ფენა.',
  'common.cancel': 'გაუქმება',
  'common.done': 'დასრულება',
  'nav.home': 'მთავარი',
  'nav.nearby': 'ახლოს',
  'nav.spots': 'ადგილები',
  'nav.profile': 'პროფილი',
  'spots.search': 'Spots-ის ძებნა',
  'spots.empty': 'ადგილი ვერ მოიძებნა.',
  'spots.error': 'ადგილების ჩატვირთვა ვერ მოხერხდა.',
  'spots.filter.nearMe': 'ჩემთან ახლოს',
  'spots.filter.oneKm': '1კმ',
  'spots.filter.threeKm': '3კმ',
  'spots.filter.trending': 'ტრენდული',
  'spots.filter.jazz': 'ჯაზი',
  'spots.filter.chill': 'მშვიდი',
  'spots.filter.lively': 'ცოცხალი',
  'spots.filter.romantic': 'რომანტიკული',
  'spots.filter.party': 'Party',
  'status.openToConnect': 'კონტაქტისთვის ღია',
  'status.invisible': 'უხილავი',
  'visibility.visibleNearby': 'ახლოს გამოჩენა',
  'visibility.visibleToNearby': 'ახლომყოფებისთვის ხილული',
  'visibility.subtitle': 'გამორთე, როცა Nearo-ში გამოჩენა არ გინდა.',
  'home.matchSubtitle':
      'აირჩიე Meet Now, Easy Start, Fun Game ან კონტაქტის გაზიარება.',
  'home.activeMatches': 'აქტიური match',
  'home.peopleOpen': 'ღია',
  'home.matchesTonight': 'Match',
  'home.visible': 'ხილული',
  'auth.phoneHelp':
      'შეიყვანე ტელეფონის ნომერი, რომ დაუკავშირდე რეალურად ახლომყოფ ადამიანებს.',
  'auth.phoneNumber': 'ტელეფონის ნომერი',
  'auth.phoneValidation': 'გამოიყენე საერთაშორისო ფორმატი, მაგ. +995...',
  'auth.sendSmsCode': 'SMS კოდის გაგზავნა',
  'auth.continueDemo': 'დემო რეჟიმით გაგრძელება',
  'auth.demoNotice':
      'Firebase მონაცემები placeholder-ებია. დემო რეჟიმში ნებისმიერი SMS კოდი იმუშავებს.',
  'auth.verifyPhone': 'ტელეფონის დადასტურება',
  'auth.smsCode': 'SMS კოდი',
  'auth.verifyAndContinue': 'დადასტურება და გაგრძელება',
  'auth.resendCode': 'კოდის ხელახლა გაგზავნა',
  'nearby.incomingSparks': 'შემოსული Sparks',
  'nearby.refreshWifi': 'Wi-Fi proximity-ის განახლება',
  'nearby.title': 'ახლოს',
  'nearby.visibleSubtitle':
      'ადამიანები, რომლებიც შენს venue signal-ზე კონტაქტისთვის ღია არიან',
  'nearby.invisibleSubtitle': 'ჩართე ხილვადობა, რომ ახლოს გამოჩნდე',
  'nearby.empty': 'ამჟამად ამ სივრცეში ხილული მომხმარებელი არ მოიძებნა.',
  'nearby.error': 'ახლომყოფების ჩატვირთვა ვერ მოხერხდა.',
  'nearby.bioFallback': 'ღიაა მშვიდი საუბრისთვის.',
  'nearby.sent': 'გაგზავნილია',
  'nearby.sendSpark': 'Spark-ის გაგზავნა',
  'filter.all': 'ყველა',
  'filter.openToMeet': 'შეხვედრისთვის ღია',
  'filter.easyStart': 'მარტივი დაწყება',
  'filter.partyMood': 'Party mood',
  'filter.chill': 'მშვიდი',
  'profile.title': 'პროფილი',
  'profile.signOut': 'გასვლა',
  'profile.noProfile': 'პროფილი არ ჩაიტვირთა.',
  'profile.signalsSent': 'გაგზავნილი Signals',
  'profile.matches': 'Matches',
  'profile.demoMode': 'დემო რეჟიმი',
  'profile.yes': 'კი',
  'profile.no': 'არა',
  'profile.safety': 'უსაფრთხოება',
  'profile.safetyText':
      'შეხვდით საჯარო ადგილებში, პატივი ეცით საზღვრებს და საჭიროებისას გამოიყენეთ report/block ფუნქციები.',
  'profile.safetyTools': 'Report და Block ხელმისაწვდომია match action-ებიდან',
  'profile.safetyBlockTitle': 'დაბლოკვა',
  'profile.safetyBlockText':
      'დაბლოკილი მომხმარებლები Nearby-დან ქრება და შენთან ინტერაქციას ვერ აგრძელებს.',
  'profile.safetyReportTitle': 'Report',
  'profile.safetyReportText':
      'Report ქმნის moderation ჩანაწერს არასაფრთხო ან შეუფერებელი ქცევისთვის.',
  'profile.safetyRevealTitle': 'ორმხრივი კონტაქტის გაზიარება',
  'profile.safetyRevealText':
      'ტელეფონი და სოციალური კონტაქტები ჩანს მხოლოდ ორმხრივი დადასტურების შემდეგ.',
  'profile.loadError': 'პროფილის ჩატვირთვა ვერ მოხერხდა.',
  'language.title': 'ენა',
  'language.english': 'English',
  'language.georgian': 'ქართული',
  'onboarding.title': 'Nearo პროფილის შექმნა',
  'onboarding.subtitle': 'დაბალი წნევის, რეალური კავშირები.',
  'onboarding.nickname': 'ნიკნეიმი',
  'onboarding.nicknameRequired': 'ნიკნეიმი აუცილებელია.',
  'onboarding.age': 'ასაკი',
  'onboarding.ageRequired': 'Nightlife უსაფრთხოებისთვის Nearo არის 18+.',
  'onboarding.mood': 'განწყობა',
  'onboarding.bio': 'ბიო',
  'onboarding.optionalSocials': 'არასავალდებულო socials',
  'onboarding.safetyAgreement':
      'ვეთანხმები პატივისცემას, privacy-first კონტაქტის გაზიარებას და რეალური სამყაროს უსაფრთხოების წესებს.',
  'onboarding.safetyRequired': 'უსაფრთხოების შეთანხმება აუცილებელია.',
  'onboarding.enter': 'Nearo-ში შესვლა',
  'onboarding.photoRequired': 'პროფილის ფოტო აუცილებელია.',
  'onboarding.saveError': 'პროფილის შენახვა ვერ მოხერხდა. სცადე თავიდან.',
  'onboarding.profilePhoto': 'პროფილის ფოტო',
  'onboarding.photoUrlAdded': 'ფოტოს URL დამატებულია',
  'onboarding.addClearPhoto': 'დაამატე მკაფიო პროფილის ფოტო',
  'onboarding.choosePhoto': 'ფოტოს არჩევა',
  'onboarding.pastePhotoUrl': 'ან ჩასვი ფოტოს URL',
  'match.title': 'Match შედგა',
  'match.you': 'შენ',
  'match.match': 'Match',
  'match.chat': 'Match ჩატი',
  'match.block': 'დაბლოკვა',
  'match.report': 'Report',
  'match.reportSubmitted': 'Report გაგზავნილია მოდერაციაზე.',
  'match.meetNowSaved':
      'Meet Now განზრახვა შენახულია. ზუსტი მდებარეობა არ ზიარდება.',
  'match.chooseSocial': 'აირჩიე გასაზიარებელი სოციალური ქსელი',
  'chat.typeMessage': 'დაწერე შეტყობინება...',
  'chat.sendError': 'შეტყობინების გაგზავნა ვერ მოხერხდა.',
  'chat.quickPrompts': 'სწრაფი ფრაზები',
  'chat.actions': 'ჩატის მოქმედებები',
  'chat.promptCoffee': 'ყავა?',
  'chat.promptFun': 'თქვი რამე სახალისო',
  'chat.promptEasyStart': 'მარტივი დაწყება',
  'reveal.decline': 'უარყოფა',
  'reveal.approve': 'დადასტურება',
  'option.meetNow': 'Meet Now',
  'option.easyStart': 'Easy Start',
  'option.funGame': 'Fun Game',
  'option.leaveSocial': 'Social-ის დატოვება',
  'option.leaveNumber': 'ნომრის დატოვება',
  'option.openChat': 'ჩატის გახსნა',
};
