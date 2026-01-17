import 'package:flutter/material.dart';

/// App localizations wrapper.
/// 
/// This is a simplified localization setup. In production,
/// use Flutter's intl package with ARB files for full i18n support.
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('en'), // English
    Locale('hi'), // Hindi
    Locale('gu'), // Gujarati
    Locale('es'), // Spanish
    Locale('fr'), // French
    Locale('de'), // German
    Locale('zh'), // Chinese
    Locale('ar'), // Arabic
    Locale('pt'), // Portuguese
    Locale('bn'), // Bengali
    Locale('ru'), // Russian
    Locale('ur'), // Urdu
  ];

  // Translations map
  static final Map<String, Map<String, String>> _translations = {
    'en': {
      // App
      'appName': 'Truth or Dare',
      'tagline': 'The Ultimate Party Game',
      
      // Home
      'play': 'Play',
      'settings': 'Settings',
      'howToPlay': 'How to Play',
      'share': 'Share',
      'home': 'Home',
      'addTruthDare': 'Add Truth/Dare',
      
      // Turn mode selection
      'howDoYouWantToPlay': 'How do you want to play?',
      'spinTheBottle': 'Spin the Bottle',
      'spinToPickNextPlayer': 'Spin to pick the next player',
      'autoNext': 'Auto Next',
      'playersInOrder': 'Players take turns in order',
      'randomPlayer': 'Randomly pick the next player',
      'swipeToSpin': 'or swipe to spin manually',
      
      // Game modes
      'selectGameMode': 'Select Game Mode',
      'selectAgeGroup': 'Select Age Group',
      'chooseAdventureLevel': 'Choose your adventure level',
      'classic': 'Classic',
      'party': 'Party',
      'couples': 'Couples',
      'friends': 'Friends',
      'kids': 'Kids',
      'teen': 'Teen',
      'teens': 'Teens',
      'adults': 'Adults',
      'adult': 'Adult',
      'mature': 'Mature (18+)',
      'kidsDesc': 'Fun and safe for children',
      'teenDesc': 'Exciting challenges for teens',
      'teensDesc': 'Exciting challenges for teens',
      'adultDesc': 'Spicy content for adults',
      'adultsDesc': 'Spicy content for adults',
      'matureDesc': 'Very spicy - adults only!',
      
      // Player setup
      'addPlayers': 'Add Players',
      'playerName': 'Player Name',
      'addPlayer': 'Add Player',
      'minPlayersError': 'Minimum 2 players required',
      'maxPlayersError': 'Maximum 16 players allowed',
      'continue': 'Continue',
      'startGame': 'Start Game',
      'players': 'Players',
      'round': 'Round',
      'currentTurn': 'Current Turn',
      
      // Categories
      'selectCategories': 'Select Categories',
      'category': 'Category',
      'selectAll': 'Select All',
      'deselectAll': 'Deselect All',
      'categoryConsentRequired': 'This category requires consent',
      'minCategoryError': 'Select at least one category',
      'pleaseSelectCategory': 'Please select a category',
      'errorLoadingCategories': 'Error loading categories',
      
      // Game
      'truth': 'Truth',
      'dare': 'Dare',
      'random': 'Random',
      'chooseOption': 'Choose your option',
      'timeRemaining': 'Time Remaining',
      'done': 'Done',
      'forfeit': 'Forfeit',
      'nextPlayer': 'Next Player',
      'spinBottle': 'Spin the Bottle',
      'passAndPlay': 'Pass & Play',
      'randomTurn': 'Random Turn',
      'tapToSpin': 'Tap or swipe to spin',
      'spinBottleDesc': 'Spin the bottle to choose the next player',
      'passAndPlayDesc': 'Pass the phone to the next player',
      'randomTurnDesc': 'Random player is selected each turn',
      
      // Timer
      'timer': 'Timer',
      'timerPaused': 'Paused',
      'timeUp': 'Time\'s Up!',
      'defaultTimer': 'Default Timer',
      
      // Scoreboard
      'scoreboard': 'Scoreboard',
      'winner': 'Winner!',
      'gameComplete': 'Game Complete!',
      'points': 'Points',
      'totalTasks': 'Total',
      'completed': 'Completed',
      'forfeited': 'Forfeited',
      'mvp': 'MVP',
      'score': 'Score',
      'truths': 'Truths',
      'dares': 'Dares',
      'forfeits': 'Forfeits',
      'streak': 'Streak',
      'endGame': 'End Game',
      'playAgain': 'Play Again',
      'noGameSession': 'No game in progress',
      
      // Settings
      'language': 'Language',
      'appLanguage': 'App Language',
      'theme': 'Theme',
      'sound': 'Sound',
      'soundEffects': 'Sound Effects',
      'playGameSounds': 'Play sounds during gameplay',
      'haptics': 'Haptics',
      'hapticFeedback': 'Haptic Feedback',
      'vibrationOnActions': 'Vibrate on button press',
      'bottleSkin': 'Bottle Skin',
      'resetSettings': 'Reset Settings',
      'gameDefaults': 'Game Defaults',
      'soundAndHaptics': 'Sound & Haptics',
      'appearance': 'Appearance',
      'data': 'Data',
      'about': 'About',
      'syncData': 'Sync Data',
      'fetchLatestContent': 'Fetch latest categories and tasks',
      'clearLocalData': 'Clear Local Data',
      'removeOfflineData': 'Remove all offline cached data',
      'clearDataWarning': 'This will delete all locally stored data including custom tasks. Continue?',
      'clear': 'Clear',
      'dataSynced': 'Data synced successfully',
      'dataCleared': 'Local data cleared',
      'syncingData': 'Syncing data...',
      'selectCategory': 'Select a category',
      'version': 'Version',
      'privacyPolicy': 'Privacy Policy',
      'termsOfService': 'Terms of Service',
      'licenses': 'Open Source Licenses',
      'defaultAgeGroup': 'Default Age Group',
      
      // Theme
      'systemTheme': 'System',
      'lightTheme': 'Light',
      'darkTheme': 'Dark',
      
      // Age groups
      'ageGroup': 'Age Group',
      
      // Turn mode
      'turnMode': 'Turn Mode',
      'sequential': 'Sequential',
      'spinBottleTurn': 'Spin Bottle',
      
      // Consent
      'adultConsentTitle': 'Age Verification',
      'adultConsentMessage': 'This mode contains adult content. Please confirm you are 18 or older.',
      'consentRequired': 'Consent Required',
      'accept': 'Accept',
      'decline': 'Decline',
      'confirm': 'I am 18+',
      'cancel': 'Cancel',
      
      // Errors
      'error': 'Error',
      'noTasksAvailable': 'No tasks available for this selection',
      'tryAgain': 'Try Again',
      
      // How to Play
      'howToPlayTitle': 'How to Play',
      'gameOverview': 'Game Overview',
      'gameOverviewDesc': 'Truth or Dare is a classic party game where players take turns answering questions honestly or completing fun challenges.',
      'gameModes': 'Game Modes',
      'howToPlaySteps': 'How to Play',
      'step1Title': 'Add Players',
      'step1Desc': 'Add 2-16 players with custom names and avatars',
      'step2Title': 'Choose Mode',
      'step2Desc': 'Select age-appropriate game mode',
      'step3Title': 'Pick Categories',
      'step3Desc': 'Choose which categories to include',
      'step4Title': 'Spin or Pass',
      'step4Desc': 'Spin the bottle or pass the phone',
      'step5Title': 'Choose',
      'step5Desc': 'Pick Truth or Dare',
      'scoring': 'Scoring',
      'completeTruth': 'Complete a Truth',
      'completeDare': 'Complete a Dare',
      'forfeitTask': 'Forfeit a task',
      'tips': 'Tips',
      'tip1': 'Be creative and have fun!',
      'tip2': 'Keep tasks age-appropriate',
      'tip3': 'Everyone should feel comfortable',
      'tip4': 'Respect boundaries - it\'s okay to skip!',
      
      // Add custom
      'addCustom': 'Add Custom',
      'addNew': 'Add New',
      'myTasks': 'My Tasks',
      'taskType': 'Task Type',
      'taskText': 'Task Text',
      'truthPlaceholder': 'What is your most embarrassing moment?',
      'darePlaceholder': 'Do 10 push-ups right now!',
      'preview': 'Preview',
      'addTask': 'Add Task',
      'pleaseEnterText': 'Please enter task text',
      'textTooShort': 'Text is too short (min 10 characters)',
      'taskAdded': 'Task added successfully!',
      'addAnother': 'Add Another',
      'noCustomTasks': 'No Custom Tasks',
      'addFirstTask': 'Add your first custom truth or dare',
    },
    'hi': {
      // App
      'appName': 'सच या हिम्मत',
      'tagline': 'अल्टीमेट पार्टी गेम',
      
      // Home
      'play': 'खेलें',
      'settings': 'सेटिंग्स',
      'howToPlay': 'कैसे खेलें',
      'share': 'शेयर करें',
      'home': 'होम',
      'addTruthDare': 'सच/हिम्मत जोड़ें',
      
      // Turn mode selection
      'howDoYouWantToPlay': 'आप कैसे खेलना चाहते हैं?',
      'spinTheBottle': 'बोतल घुमाएं',
      'spinToPickNextPlayer': 'अगला खिलाड़ी चुनने के लिए घुमाएं',
      'autoNext': 'ऑटो अगला',
      'playersInOrder': 'खिलाड़ी क्रम में बारी लेते हैं',
      'randomPlayer': 'यादृच्छिक रूप से अगला खिलाड़ी चुनें',
      'swipeToSpin': 'या स्वाइप करके घुमाएं',
      
      // Game modes
      'selectGameMode': 'गेम मोड चुनें',
      'selectAgeGroup': 'आयु समूह चुनें',
      'chooseAdventureLevel': 'अपना साहसिक स्तर चुनें',
      'classic': 'क्लासिक',
      'party': 'पार्टी',
      'couples': 'जोड़े',
      'friends': 'दोस्त',
      'kids': 'बच्चे',
      'teen': 'किशोर',
      'teens': 'किशोर',
      'adults': 'वयस्क',
      'adult': 'वयस्क',
      'mature': 'परिपक्व (18+)',
      'kidsDesc': 'बच्चों के लिए मज़ेदार और सुरक्षित',
      'teenDesc': 'किशोरों के लिए रोमांचक चुनौतियां',
      'teensDesc': 'किशोरों के लिए रोमांचक चुनौतियां',
      'adultDesc': 'वयस्कों के लिए मसालेदार सामग्री',
      'adultsDesc': 'वयस्कों के लिए मसालेदार सामग्री',
      'matureDesc': 'बहुत मसालेदार - केवल वयस्कों के लिए!',
      
      // Player setup
      'addPlayers': 'खिलाड़ी जोड़ें',
      'playerName': 'खिलाड़ी का नाम',
      'addPlayer': 'खिलाड़ी जोड़ें',
      'minPlayersError': 'कम से कम 2 खिलाड़ी आवश्यक',
      'maxPlayersError': 'अधिकतम 16 खिलाड़ी अनुमत',
      'continue': 'जारी रखें',
      'startGame': 'खेल शुरू करें',
      'players': 'खिलाड़ी',
      'round': 'राउंड',
      'currentTurn': 'वर्तमान बारी',
      
      // Categories
      'selectCategories': 'श्रेणियां चुनें',
      'category': 'श्रेणी',
      'selectAll': 'सभी चुनें',
      'deselectAll': 'सभी अचयनित करें',
      'categoryConsentRequired': 'इस श्रेणी के लिए सहमति आवश्यक',
      'minCategoryError': 'कम से कम एक श्रेणी चुनें',
      'pleaseSelectCategory': 'कृपया एक श्रेणी चुनें',
      'errorLoadingCategories': 'श्रेणियां लोड करने में त्रुटि',
      
      // Game
      'truth': 'सच',
      'dare': 'हिम्मत',
      'random': 'यादृच्छिक',
      'chooseOption': 'अपना विकल्प चुनें',
      'timeRemaining': 'शेष समय',
      'done': 'पूर्ण',
      'forfeit': 'छोड़ें',
      'nextPlayer': 'अगला खिलाड़ी',
      'spinBottle': 'बोतल घुमाएं',
      'passAndPlay': 'पास और खेलें',
      'randomTurn': 'यादृच्छिक बारी',
      'tapToSpin': 'घुमाने के लिए टैप करें',
      'spinBottleDesc': 'अगला खिलाड़ी चुनने के लिए बोतल घुमाएं',
      'passAndPlayDesc': 'फोन अगले खिलाड़ी को दें',
      'randomTurnDesc': 'हर बारी यादृच्छिक खिलाड़ी चुना जाता है',
      
      // Timer
      'timer': 'टाइमर',
      'timerPaused': 'रुका हुआ',
      'timeUp': 'समय समाप्त!',
      'defaultTimer': 'डिफ़ॉल्ट टाइमर',
      
      // Scoreboard
      'scoreboard': 'स्कोरबोर्ड',
      'winner': 'विजेता!',
      'gameComplete': 'खेल पूरा!',
      'points': 'अंक',
      'totalTasks': 'कुल',
      'completed': 'पूर्ण',
      'forfeited': 'छोड़ा गया',
      'mvp': 'एमवीपी',
      'score': 'स्कोर',
      'truths': 'सच',
      'dares': 'हिम्मत',
      'forfeits': 'छोड़े गए',
      'streak': 'लगातार',
      'endGame': 'खेल समाप्त',
      'playAgain': 'फिर से खेलें',
      'noGameSession': 'कोई खेल चालू नहीं',
      
      // Settings
      'language': 'भाषा',
      'appLanguage': 'ऐप भाषा',
      'theme': 'थीम',
      'sound': 'ध्वनि',
      'soundEffects': 'ध्वनि प्रभाव',
      'playGameSounds': 'खेल के दौरान ध्वनि बजाएं',
      'haptics': 'हैप्टिक्स',
      'hapticFeedback': 'हैप्टिक फीडबैक',
      'vibrationOnActions': 'बटन दबाने पर कंपन',
      'bottleSkin': 'बोतल स्किन',
      'resetSettings': 'सेटिंग्स रीसेट करें',
      'gameDefaults': 'गेम डिफ़ॉल्ट',
      'soundAndHaptics': 'ध्वनि और हैप्टिक्स',
      'appearance': 'दिखावट',
      'data': 'डेटा',
      'about': 'के बारे में',
      'syncData': 'डेटा सिंक करें',
      'fetchLatestContent': 'नवीनतम श्रेणियां और कार्य प्राप्त करें',
      'clearLocalData': 'स्थानीय डेटा साफ़ करें',
      'removeOfflineData': 'सभी ऑफ़लाइन कैश डेटा हटाएं',
      'clearDataWarning': 'यह सभी स्थानीय डेटा हटा देगा। जारी रखें?',
      'clear': 'साफ़ करें',
      'dataSynced': 'डेटा सफलतापूर्वक सिंक हुआ',
      'dataCleared': 'स्थानीय डेटा साफ़ हुआ',
      'syncingData': 'डेटा सिंक हो रहा है...',
      'selectCategory': 'एक श्रेणी चुनें',
      'version': 'संस्करण',
      'privacyPolicy': 'गोपनीयता नीति',
      'termsOfService': 'सेवा की शर्तें',
      'licenses': 'ओपन सोर्स लाइसेंस',
      'defaultAgeGroup': 'डिफ़ॉल्ट आयु समूह',
      
      // Theme
      'systemTheme': 'सिस्टम',
      'lightTheme': 'लाइट',
      'darkTheme': 'डार्क',
      
      // Age groups
      'ageGroup': 'आयु समूह',
      
      // Turn mode
      'turnMode': 'बारी मोड',
      'sequential': 'क्रमिक',
      'spinBottleTurn': 'बोतल घुमाएं',
      
      // Consent
      'adultConsentTitle': 'आयु सत्यापन',
      'adultConsentMessage': 'इस मोड में वयस्क सामग्री है। कृपया पुष्टि करें कि आप 18+ हैं।',
      'consentRequired': 'सहमति आवश्यक',
      'accept': 'स्वीकार करें',
      'decline': 'अस्वीकार करें',
      'confirm': 'मैं 18+ हूं',
      'cancel': 'रद्द करें',
      
      // Errors
      'error': 'त्रुटि',
      'noTasksAvailable': 'इस चयन के लिए कोई कार्य उपलब्ध नहीं',
      'tryAgain': 'पुनः प्रयास करें',
      
      // How to Play
      'howToPlayTitle': 'कैसे खेलें',
      'gameOverview': 'खेल अवलोकन',
      'gameOverviewDesc': 'सच या हिम्मत एक क्लासिक पार्टी गेम है जहां खिलाड़ी बारी-बारी से सवालों का जवाब देते हैं या मजेदार चुनौतियां पूरी करते हैं।',
      'gameModes': 'गेम मोड',
      'howToPlaySteps': 'कैसे खेलें',
      'step1Title': 'खिलाड़ी जोड़ें',
      'step1Desc': '2-16 खिलाड़ी जोड़ें',
      'step2Title': 'मोड चुनें',
      'step2Desc': 'आयु-उपयुक्त गेम मोड चुनें',
      'step3Title': 'श्रेणियां चुनें',
      'step3Desc': 'कौन सी श्रेणियां शामिल करें चुनें',
      'step4Title': 'घुमाएं या पास करें',
      'step4Desc': 'बोतल घुमाएं या फोन पास करें',
      'step5Title': 'चुनें',
      'step5Desc': 'सच या हिम्मत चुनें',
      'scoring': 'स्कोरिंग',
      'completeTruth': 'सच पूरा करें',
      'completeDare': 'हिम्मत पूरी करें',
      'forfeitTask': 'कार्य छोड़ें',
      'tips': 'सुझाव',
      'tip1': 'रचनात्मक बनें और मज़े करें!',
      'tip2': 'कार्य आयु-उपयुक्त रखें',
      'tip3': 'सभी को सहज महसूस होना चाहिए',
      'tip4': 'सीमाओं का सम्मान करें - छोड़ना ठीक है!',
      
      // Add custom
      'addCustom': 'कस्टम जोड़ें',
      'addNew': 'नया जोड़ें',
      'myTasks': 'मेरे कार्य',
      'taskType': 'कार्य प्रकार',
      'taskText': 'कार्य टेक्स्ट',
      'truthPlaceholder': 'आपका सबसे शर्मनाक पल क्या है?',
      'darePlaceholder': 'अभी 10 पुश-अप करें!',
      'preview': 'पूर्वावलोकन',
      'addTask': 'कार्य जोड़ें',
      'pleaseEnterText': 'कृपया कार्य टेक्स्ट दर्ज करें',
      'textTooShort': 'टेक्स्ट बहुत छोटा है (न्यूनतम 10 अक्षर)',
      'taskAdded': 'कार्य सफलतापूर्वक जोड़ा गया!',
      'addAnother': 'एक और जोड़ें',
      'noCustomTasks': 'कोई कस्टम कार्य नहीं',
      'addFirstTask': 'अपना पहला कस्टम सच या हिम्मत जोड़ें',
    },
    'gu': {
      // App
      'appName': 'સત્ય કે હિંમત',
      'tagline': 'અલ્ટીમેટ પાર્ટી ગેમ',
      
      // Home
      'play': 'રમો',
      'settings': 'સેટિંગ્સ',
      'howToPlay': 'કેવી રીતે રમવું',
      'share': 'શેર કરો',
      'home': 'હોમ',
      'addTruthDare': 'સત્ય/હિંમત ઉમેરો',
      
      // Turn mode selection
      'howDoYouWantToPlay': 'તમે કેવી રીતે રમવા માંગો છો?',
      'spinTheBottle': 'બોટલ ફેરવો',
      'spinToPickNextPlayer': 'આગલો ખેલાડી પસંદ કરવા ફેરવો',
      'autoNext': 'ઓટો આગળ',
      'playersInOrder': 'ખેલાડીઓ ક્રમમાં વારો લે છે',
      'randomPlayer': 'રેન્ડમ રીતે આગલો ખેલાડી પસંદ કરો',
      'swipeToSpin': 'અથવા ફેરવવા માટે સ્વાઇપ કરો',
      
      // Game modes
      'selectGameMode': 'ગેમ મોડ પસંદ કરો',
      'selectAgeGroup': 'વય જૂથ પસંદ કરો',
      'chooseAdventureLevel': 'તમારું સાહસ સ્તર પસંદ કરો',
      'classic': 'ક્લાસિક',
      'party': 'પાર્ટી',
      'couples': 'જોડીઓ',
      'friends': 'મિત્રો',
      'kids': 'બાળકો',
      'teen': 'કિશોર',
      'teens': 'કિશોરો',
      'adults': 'પુખ્ત',
      'adult': 'પુખ્ત',
      'mature': 'પરિપક્વ (18+)',
      'kidsDesc': 'બાળકો માટે મજેદાર અને સલામત',
      'teenDesc': 'કિશોરો માટે રોમાંચક પડકારો',
      'teensDesc': 'કિશોરો માટે રોમાંચક પડકારો',
      'adultDesc': 'પુખ્ત લોકો માટે મસાલેદાર સામગ્રી',
      'adultsDesc': 'પુખ્ત લોકો માટે મસાલેદાર સામગ્રી',
      'matureDesc': 'ખૂબ મસાલેદાર - ફક્ત પુખ્તો માટે!',
      
      // Player setup
      'addPlayers': 'ખેલાડીઓ ઉમેરો',
      'playerName': 'ખેલાડીનું નામ',
      'addPlayer': 'ખેલાડી ઉમેરો',
      'minPlayersError': 'ઓછામાં ઓછા 2 ખેલાડીઓ જરૂરી',
      'maxPlayersError': 'મહત્તમ 16 ખેલાડીઓ માન્ય',
      'continue': 'ચાલુ રાખો',
      'startGame': 'ગેમ શરૂ કરો',
      'players': 'ખેલાડીઓ',
      'round': 'રાઉન્ડ',
      'currentTurn': 'વર્તમાન વારો',
      
      // Categories
      'selectCategories': 'શ્રેણીઓ પસંદ કરો',
      'category': 'શ્રેણી',
      'selectAll': 'બધા પસંદ કરો',
      'deselectAll': 'બધા અપસંદ કરો',
      'categoryConsentRequired': 'આ શ્રેણી માટે સંમતિ જરૂરી છે',
      'minCategoryError': 'ઓછામાં ઓછી એક શ્રેણી પસંદ કરો',
      'pleaseSelectCategory': 'કૃપા કરીને એક શ્રેણી પસંદ કરો',
      'errorLoadingCategories': 'શ્રેણીઓ લોડ કરવામાં ભૂલ',
      
      // Game
      'truth': 'સત્ય',
      'dare': 'હિંમત',
      'random': 'રેન્ડમ',
      'chooseOption': 'તમારો વિકલ્પ પસંદ કરો',
      'timeRemaining': 'બાકી સમય',
      'done': 'પૂર્ણ',
      'forfeit': 'છોડો',
      'nextPlayer': 'આગળનો ખેલાડી',
      'spinBottle': 'બોટલ ફેરવો',
      'passAndPlay': 'પાસ અને રમો',
      'randomTurn': 'રેન્ડમ વારો',
      'tapToSpin': 'ફેરવવા માટે ટેપ કરો',
      'spinBottleDesc': 'આગળનો ખેલાડી પસંદ કરવા બોટલ ફેરવો',
      'passAndPlayDesc': 'ફોન આગળના ખેલાડીને આપો',
      'randomTurnDesc': 'દરેક વખતે રેન્ડમ ખેલાડી પસંદ થાય છે',
      
      // Timer
      'timer': 'ટાઈમર',
      'timerPaused': 'રોકેલું',
      'timeUp': 'સમય પૂરો!',
      'defaultTimer': 'ડિફોલ્ટ ટાઈમર',
      
      // Scoreboard
      'scoreboard': 'સ્કોરબોર્ડ',
      'winner': 'વિજેતા!',
      'gameComplete': 'ગેમ પૂર્ણ!',
      'points': 'પોઈન્ટ્સ',
      'totalTasks': 'કુલ',
      'completed': 'પૂર્ણ',
      'forfeited': 'છોડેલા',
      'mvp': 'એમવીપી',
      'score': 'સ્કોર',
      'truths': 'સત્ય',
      'dares': 'હિંમત',
      'forfeits': 'છોડેલા',
      'streak': 'સ્ટ્રીક',
      'endGame': 'ગેમ સમાપ્ત',
      'playAgain': 'ફરીથી રમો',
      'noGameSession': 'કોઈ ગેમ ચાલુ નથી',
      
      // Settings
      'language': 'ભાષા',
      'appLanguage': 'એપ ભાષા',
      'theme': 'થીમ',
      'sound': 'અવાજ',
      'soundEffects': 'અવાજ ઇફેક્ટ્સ',
      'playGameSounds': 'ગેમ દરમિયાન અવાજ વગાડો',
      'haptics': 'હેપ્ટિક્સ',
      'hapticFeedback': 'હેપ્ટિક ફીડબેક',
      'vibrationOnActions': 'બટન દબાવતા કંપન',
      'bottleSkin': 'બોટલ સ્કિન',
      'resetSettings': 'સેટિંગ્સ રીસેટ',
      'gameDefaults': 'ગેમ ડિફોલ્ટ્સ',
      'soundAndHaptics': 'અવાજ અને હેપ્ટિક્સ',
      'appearance': 'દેખાવ',
      'data': 'ડેટા',
      'about': 'વિશે',
      'syncData': 'ડેટા સિંક કરો',
      'fetchLatestContent': 'નવીનતમ શ્રેણીઓ અને કાર્યો મેળવો',
      'clearLocalData': 'સ્થાનિક ડેટા સાફ કરો',
      'removeOfflineData': 'બધા ઓફલાઈન કેશ ડેટા દૂર કરો',
      'clearDataWarning': 'આ બધો સ્થાનિક ડેટા કાઢી નાખશે. ચાલુ રાખવું?',
      'clear': 'સાફ કરો',
      'dataSynced': 'ડેટા સફળતાપૂર્વક સિંક થયો',
      'dataCleared': 'સ્થાનિક ડેટા સાફ થયો',
      'syncingData': 'ડેટા સિંક થઈ રહ્યો છે...',
      'selectCategory': 'એક શ્રેણી પસંદ કરો',
      'version': 'સંસ્કરણ',
      'privacyPolicy': 'ગોપનીયતા નીતિ',
      'termsOfService': 'સેવાની શરતો',
      'licenses': 'ઓપન સોર્સ લાઇસન્સ',
      'defaultAgeGroup': 'ડિફોલ્ટ વય જૂથ',
      
      // Theme
      'systemTheme': 'સિસ્ટમ',
      'lightTheme': 'લાઇટ',
      'darkTheme': 'ડાર્ક',
      
      // Age groups
      'ageGroup': 'વય જૂથ',
      
      // Turn mode
      'turnMode': 'વારો મોડ',
      'sequential': 'ક્રમિક',
      'spinBottleTurn': 'બોટલ ફેરવો',
      
      // Consent
      'adultConsentTitle': 'વય ચકાસણી',
      'adultConsentMessage': 'આ મોડમાં પુખ્ત સામગ્રી છે. કૃપા કરીને ખાતરી કરો કે તમે 18+ છો.',
      'consentRequired': 'સંમતિ જરૂરી',
      'accept': 'સ્વીકારો',
      'decline': 'નકારો',
      'confirm': 'હું 18+ છું',
      'cancel': 'રદ',
      
      // Errors
      'error': 'ભૂલ',
      'noTasksAvailable': 'આ પસંદગી માટે કોઈ કાર્યો ઉપલબ્ધ નથી',
      'tryAgain': 'ફરી પ્રયાસ કરો',
      
      // How to Play
      'howToPlayTitle': 'કેવી રીતે રમવું',
      'gameOverview': 'ગેમ ઝાંખી',
      'gameOverviewDesc': 'સત્ય કે હિંમત એક ક્લાસિક પાર્ટી ગેમ છે જ્યાં ખેલાડીઓ વારાફરતી પ્રશ્નોના જવાબ આપે છે અથવા મજેદાર પડકારો પૂર્ણ કરે છે.',
      'gameModes': 'ગેમ મોડ્સ',
      'howToPlaySteps': 'કેવી રીતે રમવું',
      'step1Title': 'ખેલાડીઓ ઉમેરો',
      'step1Desc': '2-16 ખેલાડીઓ ઉમેરો',
      'step2Title': 'મોડ પસંદ કરો',
      'step2Desc': 'વય-યોગ્ય ગેમ મોડ પસંદ કરો',
      'step3Title': 'શ્રેણીઓ પસંદ કરો',
      'step3Desc': 'કઈ શ્રેણીઓ સામેલ કરવી તે પસંદ કરો',
      'step4Title': 'ફેરવો અથવા પાસ કરો',
      'step4Desc': 'બોટલ ફેરવો અથવા ફોન પાસ કરો',
      'step5Title': 'પસંદ કરો',
      'step5Desc': 'સત્ય અથવા હિંમત પસંદ કરો',
      'scoring': 'સ્કોરિંગ',
      'completeTruth': 'સત્ય પૂર્ણ કરો',
      'completeDare': 'હિંમત પૂર્ણ કરો',
      'forfeitTask': 'કાર્ય છોડો',
      'tips': 'ટિપ્સ',
      'tip1': 'સર્જનાત્મક બનો અને મજા કરો!',
      'tip2': 'કાર્યો વય-યોગ્ય રાખો',
      'tip3': 'દરેકને આરામદાયક લાગવું જોઈએ',
      'tip4': 'સીમાઓનો આદર કરો - છોડવું ઠીક છે!',
      
      // Add custom
      'addCustom': 'કસ્ટમ ઉમેરો',
      'addNew': 'નવું ઉમેરો',
      'myTasks': 'મારા કાર્યો',
      'taskType': 'કાર્ય પ્રકાર',
      'taskText': 'કાર્ય ટેક્સ્ટ',
      'truthPlaceholder': 'તમારી સૌથી શરમજનક ક્ષણ કઈ છે?',
      'darePlaceholder': 'અત્યારે 10 પુશ-અપ્સ કરો!',
      'preview': 'પૂર્વાવલોકન',
      'addTask': 'કાર્ય ઉમેરો',
      'pleaseEnterText': 'કૃપા કરીને કાર્ય ટેક્સ્ટ દાખલ કરો',
      'textTooShort': 'ટેક્સ્ટ ખૂબ ટૂંકો છે (ન્યૂનતમ 10 અક્ષરો)',
      'taskAdded': 'કાર્ય સફળતાપૂર્વક ઉમેરાયો!',
      'addAnother': 'બીજું ઉમેરો',
      'noCustomTasks': 'કોઈ કસ્ટમ કાર્યો નથી',
      'addFirstTask': 'તમારું પ્રથમ કસ્ટમ સત્ય કે હિંમત ઉમેરો',
    },
    'es': {
      // App
      'appName': 'Verdad o Reto',
      'tagline': 'El Juego de Fiesta Definitivo',
      
      // Home
      'play': 'Jugar',
      'settings': 'Ajustes',
      'howToPlay': 'Cómo Jugar',
      'share': 'Compartir',
      'home': 'Inicio',
      'addTruthDare': 'Agregar Verdad/Reto',
      
      // Turn mode selection
      'howDoYouWantToPlay': '¿Cómo quieres jugar?',
      'spinTheBottle': 'Girar la Botella',
      'spinToPickNextPlayer': 'Gira para elegir el siguiente jugador',
      'autoNext': 'Siguiente Auto',
      'playersInOrder': 'Los jugadores turnan en orden',
      'randomPlayer': 'Elegir jugador aleatoriamente',
      'swipeToSpin': 'o desliza para girar manualmente',
      
      // Game modes
      'selectGameMode': 'Seleccionar Modo de Juego',
      'selectAgeGroup': 'Seleccionar Grupo de Edad',
      'chooseAdventureLevel': 'Elige tu nivel de aventura',
      'classic': 'Clásico',
      'party': 'Fiesta',
      'couples': 'Parejas',
      'friends': 'Amigos',
      'kids': 'Niños',
      'teen': 'Adolescente',
      'teens': 'Adolescentes',
      'adults': 'Adultos',
      'adult': 'Adulto',
      'mature': 'Maduro (18+)',
      'kidsDesc': 'Divertido y seguro para niños',
      'teenDesc': 'Desafíos emocionantes para adolescentes',
      'teensDesc': 'Desafíos emocionantes para adolescentes',
      'adultDesc': 'Contenido picante para adultos',
      'adultsDesc': 'Contenido picante para adultos',
      'matureDesc': 'Muy picante - ¡solo adultos!',
      
      // Player setup
      'addPlayers': 'Agregar Jugadores',
      'playerName': 'Nombre del Jugador',
      'addPlayer': 'Agregar Jugador',
      'minPlayersError': 'Mínimo 2 jugadores requeridos',
      'maxPlayersError': 'Máximo 16 jugadores permitidos',
      'continue': 'Continuar',
      'startGame': 'Iniciar Juego',
      'players': 'Jugadores',
      'round': 'Ronda',
      'currentTurn': 'Turno Actual',
      
      // Categories
      'selectCategories': 'Seleccionar Categorías',
      'category': 'Categoría',
      'selectAll': 'Seleccionar Todo',
      'deselectAll': 'Deseleccionar Todo',
      'categoryConsentRequired': 'Esta categoría requiere consentimiento',
      'minCategoryError': 'Seleccione al menos una categoría',
      'pleaseSelectCategory': 'Por favor seleccione una categoría',
      'errorLoadingCategories': 'Error al cargar categorías',
      
      // Game
      'truth': 'Verdad',
      'dare': 'Reto',
      'random': 'Aleatorio',
      'chooseOption': 'Elige tu opción',
      'timeRemaining': 'Tiempo Restante',
      'done': 'Hecho',
      'forfeit': 'Pasar',
      'nextPlayer': 'Siguiente Jugador',
      'spinBottle': 'Girar la Botella',
      'passAndPlay': 'Pasar y Jugar',
      'randomTurn': 'Turno Aleatorio',
      'tapToSpin': 'Toca para girar',
      'spinBottleDesc': 'Gira la botella para elegir el siguiente jugador',
      'passAndPlayDesc': 'Pasa el teléfono al siguiente jugador',
      'randomTurnDesc': 'Se selecciona un jugador aleatorio cada turno',
      
      // Timer
      'timer': 'Temporizador',
      'timerPaused': 'Pausado',
      'timeUp': '¡Se acabó el tiempo!',
      'defaultTimer': 'Temporizador Predeterminado',
      
      // Scoreboard
      'scoreboard': 'Marcador',
      'winner': '¡Ganador!',
      'gameComplete': '¡Juego Completo!',
      'points': 'Puntos',
      'totalTasks': 'Total',
      'completed': 'Completado',
      'forfeited': 'Pasado',
      'mvp': 'MVP',
      'score': 'Puntuación',
      'truths': 'Verdades',
      'dares': 'Retos',
      'forfeits': 'Pasados',
      'streak': 'Racha',
      'endGame': 'Terminar Juego',
      'playAgain': 'Jugar de Nuevo',
      'noGameSession': 'No hay juego en progreso',
      
      // Settings
      'language': 'Idioma',
      'appLanguage': 'Idioma de la App',
      'theme': 'Tema',
      'sound': 'Sonido',
      'soundEffects': 'Efectos de Sonido',
      'playGameSounds': 'Reproducir sonidos durante el juego',
      'haptics': 'Hápticos',
      'hapticFeedback': 'Retroalimentación Háptica',
      'vibrationOnActions': 'Vibrar al presionar botones',
      'bottleSkin': 'Diseño de Botella',
      'resetSettings': 'Restablecer Ajustes',
      'gameDefaults': 'Valores Predeterminados',
      'soundAndHaptics': 'Sonido y Hápticos',
      'appearance': 'Apariencia',
      'data': 'Datos',
      'about': 'Acerca de',
      'syncData': 'Sincronizar Datos',
      'fetchLatestContent': 'Obtener últimas categorías y tareas',
      'clearLocalData': 'Borrar Datos Locales',
      'removeOfflineData': 'Eliminar todos los datos en caché',
      'clearDataWarning': 'Esto eliminará todos los datos locales. ¿Continuar?',
      'clear': 'Borrar',
      'dataSynced': 'Datos sincronizados exitosamente',
      'dataCleared': 'Datos locales borrados',
      'syncingData': 'Sincronizando datos...',
      'selectCategory': 'Seleccionar una categoría',
      'version': 'Versión',
      'privacyPolicy': 'Política de Privacidad',
      'termsOfService': 'Términos de Servicio',
      'licenses': 'Licencias de Código Abierto',
      'defaultAgeGroup': 'Grupo de Edad Predeterminado',
      
      // Theme
      'systemTheme': 'Sistema',
      'lightTheme': 'Claro',
      'darkTheme': 'Oscuro',
      
      // Age groups
      'ageGroup': 'Grupo de Edad',
      
      // Turn mode
      'turnMode': 'Modo de Turno',
      'sequential': 'Secuencial',
      'spinBottleTurn': 'Girar Botella',
      
      // Consent
      'adultConsentTitle': 'Verificación de Edad',
      'adultConsentMessage': 'Este modo contiene contenido para adultos. Por favor confirme que tiene 18 años o más.',
      'consentRequired': 'Consentimiento Requerido',
      'accept': 'Aceptar',
      'decline': 'Rechazar',
      'confirm': 'Tengo 18+',
      'cancel': 'Cancelar',
      
      // Errors
      'error': 'Error',
      'noTasksAvailable': 'No hay tareas disponibles para esta selección',
      'tryAgain': 'Intentar de Nuevo',
      
      // How to Play
      'howToPlayTitle': 'Cómo Jugar',
      'gameOverview': 'Resumen del Juego',
      'gameOverviewDesc': 'Verdad o Reto es un juego clásico de fiesta donde los jugadores responden preguntas honestamente o completan desafíos divertidos.',
      'gameModes': 'Modos de Juego',
      'howToPlaySteps': 'Cómo Jugar',
      'step1Title': 'Agregar Jugadores',
      'step1Desc': 'Agrega 2-16 jugadores',
      'step2Title': 'Elegir Modo',
      'step2Desc': 'Selecciona modo apropiado para la edad',
      'step3Title': 'Elegir Categorías',
      'step3Desc': 'Elige qué categorías incluir',
      'step4Title': 'Girar o Pasar',
      'step4Desc': 'Gira la botella o pasa el teléfono',
      'step5Title': 'Elegir',
      'step5Desc': 'Elige Verdad o Reto',
      'scoring': 'Puntuación',
      'completeTruth': 'Completar una Verdad',
      'completeDare': 'Completar un Reto',
      'forfeitTask': 'Pasar una tarea',
      'tips': 'Consejos',
      'tip1': '¡Sé creativo y diviértete!',
      'tip2': 'Mantén las tareas apropiadas para la edad',
      'tip3': 'Todos deben sentirse cómodos',
      'tip4': 'Respeta los límites - ¡está bien pasar!',
      
      // Add custom
      'addCustom': 'Agregar Personalizado',
      'addNew': 'Agregar Nuevo',
      'myTasks': 'Mis Tareas',
      'taskType': 'Tipo de Tarea',
      'taskText': 'Texto de la Tarea',
      'truthPlaceholder': '¿Cuál es tu momento más vergonzoso?',
      'darePlaceholder': '¡Haz 10 flexiones ahora mismo!',
      'preview': 'Vista Previa',
      'addTask': 'Agregar Tarea',
      'pleaseEnterText': 'Por favor ingrese el texto de la tarea',
      'textTooShort': 'El texto es muy corto (mínimo 10 caracteres)',
      'taskAdded': '¡Tarea agregada exitosamente!',
      'addAnother': 'Agregar Otro',
      'noCustomTasks': 'Sin Tareas Personalizadas',
      'addFirstTask': 'Agrega tu primera verdad o reto personalizado',
    },
    'fr': {
      // App
      'appName': 'Action ou Vérité',
      'tagline': 'Le Jeu de Fête Ultime',
      
      // Home
      'play': 'Jouer',
      'settings': 'Paramètres',
      'howToPlay': 'Comment Jouer',
      'share': 'Partager',
      'home': 'Accueil',
      'addTruthDare': 'Ajouter Vérité/Action',
      
      // Turn mode selection
      'howDoYouWantToPlay': 'Comment voulez-vous jouer?',
      'spinTheBottle': 'Tourner la Bouteille',
      'spinToPickNextPlayer': 'Tournez pour choisir le prochain joueur',
      'autoNext': 'Auto Suivant',
      'playersInOrder': 'Les joueurs jouent dans l\'ordre',
      'randomPlayer': 'Choisir un joueur aléatoirement',
      'swipeToSpin': 'ou balayez pour tourner manuellement',
      
      // Game modes
      'selectGameMode': 'Sélectionner Mode de Jeu',
      'selectAgeGroup': 'Sélectionner Groupe d\'Âge',
      'chooseAdventureLevel': 'Choisissez votre niveau d\'aventure',
      'classic': 'Classique',
      'party': 'Fête',
      'couples': 'Couples',
      'friends': 'Amis',
      'kids': 'Enfants',
      'teen': 'Ado',
      'teens': 'Ados',
      'adults': 'Adultes',
      'adult': 'Adulte',
      'mature': 'Mature (18+)',
      'kidsDesc': 'Amusant et sûr pour les enfants',
      'teenDesc': 'Défis excitants pour les ados',
      'teensDesc': 'Défis excitants pour les ados',
      'adultDesc': 'Contenu pimenté pour adultes',
      'adultsDesc': 'Contenu pimenté pour adultes',
      'matureDesc': 'Très pimenté - adultes seulement!',
      
      // Player setup
      'addPlayers': 'Ajouter Joueurs',
      'playerName': 'Nom du Joueur',
      'addPlayer': 'Ajouter Joueur',
      'minPlayersError': 'Minimum 2 joueurs requis',
      'maxPlayersError': 'Maximum 16 joueurs autorisés',
      'continue': 'Continuer',
      'startGame': 'Commencer le Jeu',
      'players': 'Joueurs',
      'round': 'Manche',
      'currentTurn': 'Tour Actuel',
      
      // Categories
      'selectCategories': 'Sélectionner Catégories',
      'category': 'Catégorie',
      'selectAll': 'Tout Sélectionner',
      'deselectAll': 'Tout Désélectionner',
      'categoryConsentRequired': 'Cette catégorie nécessite un consentement',
      'minCategoryError': 'Sélectionnez au moins une catégorie',
      'pleaseSelectCategory': 'Veuillez sélectionner une catégorie',
      'errorLoadingCategories': 'Erreur lors du chargement des catégories',
      
      // Game
      'truth': 'Vérité',
      'dare': 'Action',
      'random': 'Aléatoire',
      'chooseOption': 'Choisissez votre option',
      'timeRemaining': 'Temps Restant',
      'done': 'Fait',
      'forfeit': 'Passer',
      'nextPlayer': 'Joueur Suivant',
      'spinBottle': 'Tourner la Bouteille',
      'passAndPlay': 'Passer et Jouer',
      'randomTurn': 'Tour Aléatoire',
      'tapToSpin': 'Touchez pour tourner',
      'spinBottleDesc': 'Tournez la bouteille pour choisir le prochain joueur',
      'passAndPlayDesc': 'Passez le téléphone au joueur suivant',
      'randomTurnDesc': 'Un joueur aléatoire est sélectionné à chaque tour',
      
      // Timer
      'timer': 'Minuteur',
      'timerPaused': 'En Pause',
      'timeUp': 'Temps Écoulé!',
      'defaultTimer': 'Minuteur par Défaut',
      
      // Scoreboard
      'scoreboard': 'Tableau des scores',
      'winner': 'Gagnant!',
      'gameComplete': 'Jeu Terminé!',
      'points': 'Points',
      'totalTasks': 'Total',
      'completed': 'Complété',
      'forfeited': 'Passé',
      'mvp': 'MVP',
      'score': 'Score',
      'truths': 'Vérités',
      'dares': 'Actions',
      'forfeits': 'Passés',
      'streak': 'Série',
      'endGame': 'Terminer le Jeu',
      'playAgain': 'Rejouer',
      'noGameSession': 'Aucun jeu en cours',
      
      // Settings
      'language': 'Langue',
      'appLanguage': 'Langue de l\'App',
      'theme': 'Thème',
      'sound': 'Son',
      'soundEffects': 'Effets Sonores',
      'playGameSounds': 'Jouer des sons pendant le jeu',
      'haptics': 'Haptique',
      'hapticFeedback': 'Retour Haptique',
      'vibrationOnActions': 'Vibrer lors de l\'appui',
      'bottleSkin': 'Apparence Bouteille',
      'resetSettings': 'Réinitialiser Paramètres',
      'gameDefaults': 'Paramètres par Défaut',
      'soundAndHaptics': 'Son et Haptique',
      'appearance': 'Apparence',
      'data': 'Données',
      'about': 'À Propos',
      'syncData': 'Synchroniser Données',
      'fetchLatestContent': 'Récupérer les dernières catégories et tâches',
      'clearLocalData': 'Effacer Données Locales',
      'removeOfflineData': 'Supprimer toutes les données en cache',
      'clearDataWarning': 'Cela supprimera toutes les données locales. Continuer?',
      'clear': 'Effacer',
      'dataSynced': 'Données synchronisées avec succès',
      'dataCleared': 'Données locales effacées',
      'syncingData': 'Synchronisation des données...',
      'selectCategory': 'Sélectionner une catégorie',
      'version': 'Version',
      'privacyPolicy': 'Politique de Confidentialité',
      'termsOfService': 'Conditions d\'Utilisation',
      'licenses': 'Licences Open Source',
      'defaultAgeGroup': 'Groupe d\'Âge par Défaut',
      
      // Theme
      'systemTheme': 'Système',
      'lightTheme': 'Clair',
      'darkTheme': 'Sombre',
      
      // Age groups
      'ageGroup': 'Groupe d\'Âge',
      
      // Turn mode
      'turnMode': 'Mode de Tour',
      'sequential': 'Séquentiel',
      'spinBottleTurn': 'Tourner Bouteille',
      
      // Consent
      'adultConsentTitle': 'Vérification d\'Âge',
      'adultConsentMessage': 'Ce mode contient du contenu adulte. Veuillez confirmer que vous avez 18 ans ou plus.',
      'consentRequired': 'Consentement Requis',
      'accept': 'Accepter',
      'decline': 'Refuser',
      'confirm': 'J\'ai 18+',
      'cancel': 'Annuler',
      
      // Errors
      'error': 'Erreur',
      'noTasksAvailable': 'Aucune tâche disponible pour cette sélection',
      'tryAgain': 'Réessayer',
      
      // How to Play
      'howToPlayTitle': 'Comment Jouer',
      'gameOverview': 'Aperçu du Jeu',
      'gameOverviewDesc': 'Action ou Vérité est un jeu de fête classique où les joueurs répondent honnêtement aux questions ou accomplissent des défis amusants.',
      'gameModes': 'Modes de Jeu',
      'howToPlaySteps': 'Comment Jouer',
      'step1Title': 'Ajouter Joueurs',
      'step1Desc': 'Ajoutez 2-16 joueurs',
      'step2Title': 'Choisir Mode',
      'step2Desc': 'Sélectionnez un mode adapté à l\'âge',
      'step3Title': 'Choisir Catégories',
      'step3Desc': 'Choisissez quelles catégories inclure',
      'step4Title': 'Tourner ou Passer',
      'step4Desc': 'Tournez la bouteille ou passez le téléphone',
      'step5Title': 'Choisir',
      'step5Desc': 'Choisissez Vérité ou Action',
      'scoring': 'Score',
      'completeTruth': 'Compléter une Vérité',
      'completeDare': 'Compléter une Action',
      'forfeitTask': 'Passer une tâche',
      'tips': 'Conseils',
      'tip1': 'Soyez créatif et amusez-vous!',
      'tip2': 'Gardez les tâches adaptées à l\'âge',
      'tip3': 'Tout le monde doit se sentir à l\'aise',
      'tip4': 'Respectez les limites - passer est ok!',
      
      // Add custom
      'addCustom': 'Ajouter Personnalisé',
      'addNew': 'Ajouter Nouveau',
      'myTasks': 'Mes Tâches',
      'taskType': 'Type de Tâche',
      'taskText': 'Texte de la Tâche',
      'truthPlaceholder': 'Quel est votre moment le plus gênant?',
      'darePlaceholder': 'Faites 10 pompes maintenant!',
      'preview': 'Aperçu',
      'addTask': 'Ajouter Tâche',
      'pleaseEnterText': 'Veuillez entrer le texte de la tâche',
      'textTooShort': 'Le texte est trop court (min 10 caractères)',
      'taskAdded': 'Tâche ajoutée avec succès!',
      'addAnother': 'Ajouter Autre',
      'noCustomTasks': 'Pas de Tâches Personnalisées',
      'addFirstTask': 'Ajoutez votre première vérité ou action personnalisée',
    },
    'de': {
      // App
      'appName': 'Wahrheit oder Pflicht',
      'tagline': 'Das Ultimative Partyspiel',
      
      // Home
      'play': 'Spielen',
      'settings': 'Einstellungen',
      'howToPlay': 'Spielanleitung',
      'share': 'Teilen',
      'home': 'Startseite',
      'addTruthDare': 'Wahrheit/Pflicht hinzufügen',
      
      // Turn mode selection
      'howDoYouWantToPlay': 'Wie möchtest du spielen?',
      'spinTheBottle': 'Flasche Drehen',
      'spinToPickNextPlayer': 'Drehe um den nächsten Spieler zu wählen',
      'autoNext': 'Auto Nächster',
      'playersInOrder': 'Spieler sind der Reihe nach dran',
      'randomPlayer': 'Wähle zufällig den nächsten Spieler',
      'swipeToSpin': 'oder wische zum manuellen Drehen',
      
      // Game modes
      'selectGameMode': 'Spielmodus wählen',
      'selectAgeGroup': 'Altersgruppe wählen',
      'chooseAdventureLevel': 'Wähle dein Abenteuerlevel',
      'classic': 'Klassisch',
      'party': 'Party',
      'couples': 'Paare',
      'friends': 'Freunde',
      'kids': 'Kinder',
      'teen': 'Teenager',
      'teens': 'Teenager',
      'adults': 'Erwachsene',
      'adult': 'Erwachsener',
      'mature': 'Reif (18+)',
      'kidsDesc': 'Lustig und sicher für Kinder',
      'teenDesc': 'Spannende Herausforderungen für Teenager',
      'teensDesc': 'Spannende Herausforderungen für Teenager',
      'adultDesc': 'Pikanter Inhalt für Erwachsene',
      'adultsDesc': 'Pikanter Inhalt für Erwachsene',
      'matureDesc': 'Sehr pikant - nur für Erwachsene!',
      
      // Player setup
      'addPlayers': 'Spieler hinzufügen',
      'playerName': 'Spielername',
      'addPlayer': 'Spieler hinzufügen',
      'minPlayersError': 'Mindestens 2 Spieler erforderlich',
      'maxPlayersError': 'Maximal 16 Spieler erlaubt',
      'continue': 'Weiter',
      'startGame': 'Spiel starten',
      'players': 'Spieler',
      'round': 'Runde',
      'currentTurn': 'Aktueller Zug',
      
      // Categories
      'selectCategories': 'Kategorien wählen',
      'category': 'Kategorie',
      'selectAll': 'Alle auswählen',
      'deselectAll': 'Alle abwählen',
      'categoryConsentRequired': 'Diese Kategorie erfordert Zustimmung',
      'minCategoryError': 'Wählen Sie mindestens eine Kategorie',
      'pleaseSelectCategory': 'Bitte wählen Sie eine Kategorie',
      'errorLoadingCategories': 'Fehler beim Laden der Kategorien',
      
      // Game
      'truth': 'Wahrheit',
      'dare': 'Pflicht',
      'random': 'Zufällig',
      'chooseOption': 'Wähle deine Option',
      'timeRemaining': 'Verbleibende Zeit',
      'done': 'Fertig',
      'forfeit': 'Aufgeben',
      'nextPlayer': 'Nächster Spieler',
      'spinBottle': 'Flasche drehen',
      'passAndPlay': 'Weitergeben und spielen',
      'randomTurn': 'Zufälliger Zug',
      'tapToSpin': 'Tippen zum Drehen',
      'spinBottleDesc': 'Drehe die Flasche um den nächsten Spieler zu wählen',
      'passAndPlayDesc': 'Gib das Handy an den nächsten Spieler',
      'randomTurnDesc': 'Jede Runde wird ein zufälliger Spieler gewählt',
      
      // Timer
      'timer': 'Timer',
      'timerPaused': 'Pausiert',
      'timeUp': 'Zeit abgelaufen!',
      'defaultTimer': 'Standard-Timer',
      
      // Scoreboard
      'scoreboard': 'Punktestand',
      'winner': 'Gewinner!',
      'gameComplete': 'Spiel beendet!',
      'points': 'Punkte',
      'totalTasks': 'Gesamt',
      'completed': 'Abgeschlossen',
      'forfeited': 'Aufgegeben',
      'mvp': 'MVP',
      'score': 'Punktzahl',
      'truths': 'Wahrheiten',
      'dares': 'Pflichten',
      'forfeits': 'Aufgegeben',
      'streak': 'Serie',
      'endGame': 'Spiel beenden',
      'playAgain': 'Nochmal spielen',
      'noGameSession': 'Kein Spiel läuft',
      
      // Settings
      'language': 'Sprache',
      'appLanguage': 'App-Sprache',
      'theme': 'Design',
      'sound': 'Ton',
      'soundEffects': 'Soundeffekte',
      'playGameSounds': 'Töne während des Spiels abspielen',
      'haptics': 'Haptik',
      'hapticFeedback': 'Haptisches Feedback',
      'vibrationOnActions': 'Bei Tastendruck vibrieren',
      'bottleSkin': 'Flaschen-Design',
      'resetSettings': 'Einstellungen zurücksetzen',
      'gameDefaults': 'Spielstandards',
      'soundAndHaptics': 'Ton und Haptik',
      'appearance': 'Aussehen',
      'data': 'Daten',
      'about': 'Über',
      'syncData': 'Daten synchronisieren',
      'fetchLatestContent': 'Neueste Kategorien und Aufgaben abrufen',
      'clearLocalData': 'Lokale Daten löschen',
      'removeOfflineData': 'Alle zwischengespeicherten Daten entfernen',
      'clearDataWarning': 'Dies löscht alle lokalen Daten. Fortfahren?',
      'clear': 'Löschen',
      'dataSynced': 'Daten erfolgreich synchronisiert',
      'dataCleared': 'Lokale Daten gelöscht',
      'syncingData': 'Daten werden synchronisiert...',
      'selectCategory': 'Kategorie auswählen',
      'version': 'Version',
      'privacyPolicy': 'Datenschutzrichtlinie',
      'termsOfService': 'Nutzungsbedingungen',
      'licenses': 'Open-Source-Lizenzen',
      'defaultAgeGroup': 'Standard-Altersgruppe',
      
      // Theme
      'systemTheme': 'System',
      'lightTheme': 'Hell',
      'darkTheme': 'Dunkel',
      
      // Age groups
      'ageGroup': 'Altersgruppe',
      
      // Turn mode
      'turnMode': 'Zugmodus',
      'sequential': 'Sequentiell',
      'spinBottleTurn': 'Flasche drehen',
      
      // Consent
      'adultConsentTitle': 'Altersverifizierung',
      'adultConsentMessage': 'Dieser Modus enthält Inhalte für Erwachsene. Bitte bestätigen Sie, dass Sie 18 oder älter sind.',
      'consentRequired': 'Zustimmung erforderlich',
      'accept': 'Akzeptieren',
      'decline': 'Ablehnen',
      'confirm': 'Ich bin 18+',
      'cancel': 'Abbrechen',
      
      // Errors
      'error': 'Fehler',
      'noTasksAvailable': 'Keine Aufgaben für diese Auswahl verfügbar',
      'tryAgain': 'Erneut versuchen',
      
      // How to Play
      'howToPlayTitle': 'Spielanleitung',
      'gameOverview': 'Spielübersicht',
      'gameOverviewDesc': 'Wahrheit oder Pflicht ist ein klassisches Partyspiel, bei dem Spieler abwechselnd Fragen ehrlich beantworten oder lustige Herausforderungen meistern.',
      'gameModes': 'Spielmodi',
      'howToPlaySteps': 'Spielanleitung',
      'step1Title': 'Spieler hinzufügen',
      'step1Desc': 'Füge 2-16 Spieler hinzu',
      'step2Title': 'Modus wählen',
      'step2Desc': 'Wähle altersgerechten Spielmodus',
      'step3Title': 'Kategorien wählen',
      'step3Desc': 'Wähle welche Kategorien einbezogen werden',
      'step4Title': 'Drehen oder Weitergeben',
      'step4Desc': 'Drehe die Flasche oder gib das Handy weiter',
      'step5Title': 'Wählen',
      'step5Desc': 'Wähle Wahrheit oder Pflicht',
      'scoring': 'Punktevergabe',
      'completeTruth': 'Eine Wahrheit abschließen',
      'completeDare': 'Eine Pflicht abschließen',
      'forfeitTask': 'Eine Aufgabe aufgeben',
      'tips': 'Tipps',
      'tip1': 'Sei kreativ und hab Spaß!',
      'tip2': 'Halte Aufgaben altersgerecht',
      'tip3': 'Jeder sollte sich wohl fühlen',
      'tip4': 'Respektiere Grenzen - Aufgeben ist ok!',
      
      // Add custom
      'addCustom': 'Eigene hinzufügen',
      'addNew': 'Neu hinzufügen',
      'myTasks': 'Meine Aufgaben',
      'taskType': 'Aufgabentyp',
      'taskText': 'Aufgabentext',
      'truthPlaceholder': 'Was ist dein peinlichster Moment?',
      'darePlaceholder': 'Mach jetzt 10 Liegestütze!',
      'preview': 'Vorschau',
      'addTask': 'Aufgabe hinzufügen',
      'pleaseEnterText': 'Bitte Aufgabentext eingeben',
      'textTooShort': 'Text ist zu kurz (min. 10 Zeichen)',
      'taskAdded': 'Aufgabe erfolgreich hinzugefügt!',
      'addAnother': 'Weitere hinzufügen',
      'noCustomTasks': 'Keine eigenen Aufgaben',
      'addFirstTask': 'Füge deine erste eigene Wahrheit oder Pflicht hinzu',
    },
  };

  String translate(String key) {
    return _translations[locale.languageCode]?[key] ?? 
           _translations['en']?[key] ?? 
           key;
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales
        .map((l) => l.languageCode)
        .contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

/// Extension for easy access to translations.
extension AppLocalizationsExtension on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
  String tr(String key) => l10n.translate(key);
}
