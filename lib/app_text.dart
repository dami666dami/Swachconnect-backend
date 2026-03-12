import 'package:shared_preferences/shared_preferences.dart';

class AppText {
  static String current = "en";

  static Future loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    current = prefs.getString("lang") ?? "en";
  }

  static Future setLanguage(String lang) async {
    current = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("lang", lang);
  }

  static final Map<String, Map<String, String>> _data = {

    "en": {

      "login": "Login",
      "email": "Email",
      "password": "Password",
      "forgot": "Forgot Password?",
      "forgotPassword": "Forgot Password",
      "register": "Register",
      "name": "Name",
      "confirmPassword": "Confirm Password",
      "sendOtp": "Send OTP",

      "welcome": "Welcome",
      "logout": "Logout",
      "confirmLogout": "Do you want to log out?",
      "cancel": "Cancel",
      "yes": "Yes",

      "registerComplaint": "Register Complaint",
      "myComplaints": "My Complaints",

      "noAccount": "Don't have an account?",
      "registerPrompt": "Don't have an account? REGISTER",

      "invalidEmail": "Enter valid email",
      "enterEmail": "Enter email",
      "enterPassword": "Enter password",
      "enterName": "Enter name",

      "passwordMin": "Minimum 6 characters",
      "passwordMismatch": "Passwords do not match",

      "registrationFailed": "Registration failed",
      "networkError": "Network error",
      "invalidLogin": "Invalid email or password",

      /// ===== OTP PAGE KEYS =====
      "verifyOtp": "Verify OTP",
      "otpVerification": "OTP Verification",
      "enterOtpSent": "Enter the OTP sent to",
      "enterOtp": "Enter OTP",
      "invalidOtp": "Invalid OTP",
      "resendOtp": "Resend OTP",
      "resendIn": "Resend OTP in",
      "otpSentAgain": "OTP sent again",
      "otpFailed": "Failed to resend OTP",

      /// Complaint History
      "deleteComplaint": "Delete Complaint",
      "deleteConfirm": "This action cannot be undone. Do you want to delete this complaint?",
      "delete": "Delete",
      "deleteSuccess": "Complaint deleted successfully",
      "deleteFailed": "Delete failed",

      "escalateComplaint": "Escalate Complaint",
      "currentAuthority": "Current Authority",
      "deadlinePassed": "The deadline has passed",
      "wait": "Wait",
      "escalate": "Escalate",

      "escalationConfirmed": "Escalation Confirmed",
      "escalationSuccess": "Your complaint has been escalated successfully.",
      "escalationFailed": "Escalation failed",

      "ok": "OK",
      "noComplaints": "No complaints found",

      "authority": "Authority",
      "progress": "Progress",
      "shareAwareness": "Share for awareness",
      "anonymous": "Anonymous"
    },

    "ml": {

      "login": "ലോഗിൻ",
      "email": "ഇമെയിൽ",
      "password": "പാസ്‌വേഡ്",
      "forgot": "പാസ്‌വേഡ് മറന്നോ?",
      "forgotPassword": "പാസ്‌വേഡ് മറന്നു",
      "register": "രജിസ്റ്റർ",

      "name": "പേര്",
      "confirmPassword": "പാസ്‌വേഡ് സ്ഥിരീകരിക്കുക",
      "sendOtp": "OTP അയയ്ക്കുക",

      "welcome": "സ്വാഗതം",
      "logout": "ലോഗ് ഔട്ട്",

      "confirmLogout": "ലോഗ് ഔട്ട് ചെയ്യണോ?",
      "cancel": "റദ്ദാക്കുക",
      "yes": "അതെ",

      "registerComplaint": "പരാതി രജിസ്റ്റർ ചെയ്യുക",
      "myComplaints": "എന്റെ പരാതികൾ",

      "noAccount": "അക്കൗണ്ട് ഇല്ലേ?",
      "registerPrompt": "അക്കൗണ്ട് ഇല്ലേ? രജിസ്റ്റർ ചെയ്യൂ",

      "invalidEmail": "സാധുവായ ഇമെയിൽ നൽകുക",
      "enterEmail": "ഇമെയിൽ നൽകുക",
      "enterPassword": "പാസ്‌വേഡ് നൽകുക",
      "enterName": "പേര് നൽകുക",

      "passwordMin": "കുറഞ്ഞത് 6 അക്ഷരങ്ങൾ",
      "passwordMismatch": "പാസ്‌വേഡുകൾ പൊരുത്തപ്പെടുന്നില്ല",

      "registrationFailed": "രജിസ്ട്രേഷൻ പരാജയപ്പെട്ടു",
      "networkError": "നെറ്റ്‌വർക്ക് പിശക്",
      "invalidLogin": "തെറ്റായ ഇമെയിൽ അല്ലെങ്കിൽ പാസ്‌വേഡ്",

      /// OTP
      "verifyOtp": "OTP സ്ഥിരീകരിക്കുക",
      "otpVerification": "OTP സ്ഥിരീകരണം",
      "enterOtpSent": "ഈ ഇമെയിലിലേക്ക് അയച്ച OTP നൽകുക",
      "enterOtp": "OTP നൽകുക",
      "invalidOtp": "തെറ്റായ OTP",
      "resendOtp": "OTP വീണ്ടും അയയ്ക്കുക",
      "resendIn": "OTP വീണ്ടും അയയ്ക്കാൻ",
      "otpSentAgain": "OTP വീണ്ടും അയച്ചു",
      "otpFailed": "OTP വീണ്ടും അയയ്ക്കാൻ കഴിഞ്ഞില്ല",

      /// Complaint
      "deleteComplaint": "പരാതി ഇല്ലാതാക്കുക",
      "deleteConfirm": "ഈ നടപടി തിരികെ മാറ്റാൻ കഴിയില്ല. ഇല്ലാതാക്കണോ?",
      "delete": "ഇല്ലാതാക്കുക",
      "deleteSuccess": "പരാതി വിജയകരമായി ഇല്ലാതാക്കി",
      "deleteFailed": "ഇല്ലാതാക്കൽ പരാജയപ്പെട്ടു",

      "escalateComplaint": "പരാതി ഉയർത്തുക",
      "currentAuthority": "നിലവിലെ അധികാരം",
      "deadlinePassed": "സമയപരിധി കഴിഞ്ഞു",

      "wait": "കാത്തിരിക്കുക",
      "escalate": "ഉയർത്തുക",

      "escalationConfirmed": "എസ്‌കലേഷൻ സ്ഥിരീകരിച്ചു",
      "escalationSuccess": "നിങ്ങളുടെ പരാതി അടുത്ത അധികാരിക്ക് അയച്ചു",
      "escalationFailed": "എസ്‌കലേഷൻ പരാജയം",

      "ok": "ശരി",
      "noComplaints": "പരാതികളില്ല",

      "authority": "അധികാരം",
      "progress": "പുരോഗതി",
      "shareAwareness": "അറിയിപ്പ് പങ്കിടുക",
      "anonymous": "അജ്ഞാതം"
    },

    "hi": {

      "login": "लॉगिन",
      "email": "ईमेल",
      "password": "पासवर्ड",
      "forgot": "पासवर्ड भूल गए?",
      "forgotPassword": "पासवर्ड भूल गए",
      "register": "रजिस्टर",

      "name": "नाम",
      "confirmPassword": "पासवर्ड की पुष्टि करें",
      "sendOtp": "OTP भेजें",

      "welcome": "स्वागत है",
      "logout": "लॉग आउट",

      "confirmLogout": "क्या आप लॉग आउट करना चाहते हैं?",
      "cancel": "रद्द करें",
      "yes": "हाँ",

      "registerComplaint": "शिकायत दर्ज करें",
      "myComplaints": "मेरी शिकायतें",

      "noAccount": "खाता नहीं है?",
      "registerPrompt": "खाता नहीं है? रजिस्टर करें",

      "invalidEmail": "मान्य ईमेल दर्ज करें",
      "enterEmail": "ईमेल दर्ज करें",
      "enterPassword": "पासवर्ड दर्ज करें",
      "enterName": "नाम दर्ज करें",

      "passwordMin": "कम से कम 6 अक्षर",
      "passwordMismatch": "पासवर्ड मेल नहीं खाते",

      "registrationFailed": "पंजीकरण विफल",
      "networkError": "नेटवर्क त्रुटि",
      "invalidLogin": "गलत ईमेल या पासवर्ड",

      /// OTP
      "verifyOtp": "OTP सत्यापित करें",
      "otpVerification": "OTP सत्यापन",
      "enterOtpSent": "भेजा गया OTP दर्ज करें",
      "enterOtp": "OTP दर्ज करें",
      "invalidOtp": "अमान्य OTP",
      "resendOtp": "OTP फिर भेजें",
      "resendIn": "OTP फिर भेजें",
      "otpSentAgain": "OTP फिर भेजा गया",
      "otpFailed": "OTP भेजने में विफल",

      /// Complaint
      "deleteComplaint": "शिकायत हटाएँ",
      "deleteConfirm": "क्या आप इस शिकायत को हटाना चाहते हैं?",
      "delete": "हटाएँ",
      "deleteSuccess": "शिकायत सफलतापूर्वक हटाई गई",
      "deleteFailed": "हटाना विफल",

      "escalateComplaint": "शिकायत बढ़ाएँ",
      "currentAuthority": "वर्तमान प्राधिकरण",
      "deadlinePassed": "समय सीमा समाप्त",

      "wait": "रुकें",
      "escalate": "बढ़ाएँ",

      "escalationConfirmed": "शिकायत बढ़ा दी गई",
      "escalationSuccess": "आपकी शिकायत अगले प्राधिकरण को भेज दी गई है",
      "escalationFailed": "शिकायत बढ़ाना विफल",

      "ok": "ठीक है",
      "noComplaints": "कोई शिकायत नहीं मिली",

      "authority": "प्राधिकरण",
      "progress": "प्रगति",
      "shareAwareness": "जागरूकता के लिए साझा करें",
      "anonymous": "गुमनाम"
    },

    "ta": {
      "login": "உள்நுழை",
      "email": "மின்னஞ்சல்",
      "password": "கடவுச்சொல்",
      "forgot": "கடவுச்சொல் மறந்துவிட்டதா?",
      "forgotPassword": "கடவுச்சொல் மறந்துவிட்டது",
      "register": "பதிவு",
      "name": "பெயர்",
      "confirmPassword": "கடவுச்சொல்லை உறுதிப்படுத்து",
      "sendOtp": "OTP அனுப்பு",

      "verifyOtp": "OTP சரிபார்",
      "otpVerification": "OTP சரிபார்ப்பு",
      "enterOtpSent": "அனுப்பப்பட்ட OTP ஐ உள்ளிடவும்",
      "enterOtp": "OTP உள்ளிடவும்",
      "invalidOtp": "தவறான OTP",
      "resendOtp": "OTP மீண்டும் அனுப்பு",
      "resendIn": "மீண்டும் அனுப்ப",
      "otpSentAgain": "OTP மீண்டும் அனுப்பப்பட்டது",
      "otpFailed": "OTP அனுப்ப முடியவில்லை",

      "welcome": "வரவேற்கிறோம்",
      "logout": "வெளியேறு",
      "confirmLogout": "வெளியேற விரும்புகிறீர்களா?",
      "cancel": "ரத்து செய்",
      "yes": "ஆம்",

      "registerComplaint": "புகார் பதிவு",
      "myComplaints": "என் புகார்கள்",
      "noAccount": "கணக்கு இல்லையா?",
      "registerPrompt": "கணக்கு இல்லையா? பதிவு செய்யவும்",

      "invalidEmail": "சரியான மின்னஞ்சல்",
      "enterEmail": "மின்னஞ்சல் உள்ளிடவும்",
      "enterPassword": "கடவுச்சொல் உள்ளிடவும்",
      "enterName": "பெயர் உள்ளிடவும்",

      "passwordMin": "குறைந்தது 6 எழுத்துகள்",
      "passwordMismatch": "கடவுச்சொற்கள் பொருந்தவில்லை",

      "registrationFailed": "பதிவு தோல்வி",
      "networkError": "நெட்வொர்க் பிழை",
      "invalidLogin": "தவறான மின்னஞ்சல் அல்லது கடவுச்சொல்",

      "deleteComplaint": "புகாரை நீக்கு",
      "deleteConfirm": "இந்த புகாரை நீக்க விரும்புகிறீர்களா?",
      "delete": "நீக்கு",
      "deleteSuccess": "புகார் நீக்கப்பட்டது",
      "deleteFailed": "நீக்க முடியவில்லை",

      "escalateComplaint": "புகாரை உயர்த்து",
      "currentAuthority": "தற்போதைய அதிகாரம்",
      "deadlinePassed": "காலக்கெடு முடிந்தது",
      "wait": "காத்திரு",
      "escalate": "உயர்த்து",

      "escalationConfirmed": "உயர்த்தல் உறுதி செய்யப்பட்டது",
      "escalationSuccess": "உங்கள் புகார் அடுத்த அதிகாரிக்கு அனுப்பப்பட்டது",
      "escalationFailed": "உயர்த்தல் தோல்வி",

      "ok": "சரி",
      "noComplaints": "புகார்கள் இல்லை",
      "authority": "அதிகாரம்",
      "progress": "முன்னேற்றம்",
      "shareAwareness": "பகிரவும்",
      "anonymous": "அடையாளமற்றது"
    },

    "te": {
      "login": "లాగిన్",
      "email": "ఈమెయిల్",
      "password": "పాస్‌వర్డ్",
      "forgot": "పాస్‌వర్డ్ మర్చిపోయారా?",
      "forgotPassword": "పాస్‌వర్డ్ మర్చిపోయారు",
      "register": "నమోదు",
      "name": "పేరు",
      "confirmPassword": "పాస్‌వర్డ్ నిర్ధారించండి",
      "sendOtp": "OTP పంపండి",

      "verifyOtp": "OTP ధృవీకరించండి",
      "otpVerification": "OTP ధృవీకరణ",
      "enterOtpSent": "పంపిన OTP నమోదు చేయండి",
      "enterOtp": "OTP నమోదు చేయండి",
      "invalidOtp": "చెల్లని OTP",
      "resendOtp": "OTP మళ్లీ పంపండి",
      "resendIn": "మళ్లీ పంపడానికి",
      "otpSentAgain": "OTP మళ్లీ పంపబడింది",
      "otpFailed": "OTP పంపడం విఫలమైంది",

      "welcome": "స్వాగతం",
      "logout": "లాగ్ అవుట్",
      "confirmLogout": "లాగ్ అవుట్ కావాలా?",
      "cancel": "రద్దు",
      "yes": "అవును",

      "registerComplaint": "ఫిర్యాదు నమోదు",
      "myComplaints": "నా ఫిర్యాదులు",
      "noAccount": "ఖాతా లేదా?",
      "registerPrompt": "ఖాతా లేదా? నమోదు చేయండి",

      "invalidEmail": "సరైన ఈమెయిల్ ఇవ్వండి",
      "enterEmail": "ఈమెయిల్ ఇవ్వండి",
      "enterPassword": "పాస్‌వర్డ్ ఇవ్వండి",
      "enterName": "పేరు ఇవ్వండి",

      "passwordMin": "కనీసం 6 అక్షరాలు",
      "passwordMismatch": "పాస్‌వర్డ్లు సరిపోలలేదు",

      "registrationFailed": "నమోదు విఫలమైంది",
      "networkError": "నెట్‌వర్క్ లోపం",
      "invalidLogin": "తప్పు ఈమెయిల్ లేదా పాస్‌వర్డ్",

      "deleteComplaint": "ఫిర్యాదు తొలగించు",
      "deleteConfirm": "ఈ ఫిర్యాదును తొలగించాలా?",
      "delete": "తొలగించు",
      "deleteSuccess": "ఫిర్యాదు తొలగించబడింది",
      "deleteFailed": "తొలగింపు విఫలమైంది",

      "escalateComplaint": "ఫిర్యాదు పెంచు",
      "currentAuthority": "ప్రస్తుత అధికార సంస్థ",
      "deadlinePassed": "గడువు ముగిసింది",
      "wait": "ఆగండి",
      "escalate": "పెంచు",

      "escalationConfirmed": "ఎస్కలేషన్ నిర్ధారించబడింది",
      "escalationSuccess": "మీ ఫిర్యాదు తదుపరి అధికారికి పంపబడింది",
      "escalationFailed": "ఎస్కలేషన్ విఫలమైంది",

      "ok": "సరే",
      "noComplaints": "ఫిర్యాదులు లేవు",
      "authority": "అధికార సంస్థ",
      "progress": "పురోగతి",
      "shareAwareness": "అవగాహన కోసం పంచుకోండి",
      "anonymous": "అజ్ఞాత"
    },

    "kn": {
      "login": "ಲಾಗಿನ್",
      "email": "ಇಮೇಲ್",
      "password": "ಪಾಸ್ವರ್ಡ್",
      "forgot": "ಪಾಸ್ವರ್ಡ್ ಮರೆತಿರಾ?",
      "forgotPassword": "ಪಾಸ್ವರ್ಡ್ ಮರೆತಿರಿ",
      "register": "ನೋಂದಣಿ",
      "name": "ಹೆಸರು",
      "confirmPassword": "ಪಾಸ್ವರ್ಡ್ ದೃಢೀಕರಿಸಿ",
      "sendOtp": "OTP ಕಳುಹಿಸಿ",

      "verifyOtp": "OTP ಪರಿಶೀಲಿಸಿ",
      "otpVerification": "OTP ಪರಿಶೀಲನೆ",
      "enterOtpSent": "ಕಳುಹಿಸಿದ OTP ನಮೂದಿಸಿ",
      "enterOtp": "OTP ನಮೂದಿಸಿ",
      "invalidOtp": "ತಪ್ಪಾದ OTP",
      "resendOtp": "OTP ಮತ್ತೆ ಕಳುಹಿಸಿ",
      "resendIn": "ಮತ್ತೆ ಕಳುಹಿಸಲು",
      "otpSentAgain": "OTP ಮತ್ತೆ ಕಳುಹಿಸಲಾಗಿದೆ",
      "otpFailed": "OTP ಕಳುಹಿಸಲು ವಿಫಲವಾಗಿದೆ",

      "welcome": "ಸ್ವಾಗತ",
      "logout": "ಲಾಗ್ ಔಟ್",
      "confirmLogout": "ಲಾಗ್ ಔಟ್ ಮಾಡಲು ಬಯಸುವಿರಾ?",
      "cancel": "ರದ್ದು",
      "yes": "ಹೌದು",

      "registerComplaint": "ದೂರು ನೋಂದಣಿ",
      "myComplaints": "ನನ್ನ ದೂರುಗಳು",
      "noAccount": "ಖಾತೆ ಇಲ್ಲವೇ?",
      "registerPrompt": "ಖಾತೆ ಇಲ್ಲವೇ? ನೋಂದಣಿ ಮಾಡಿ",

      "invalidEmail": "ಸರಿಯಾದ ಇಮೇಲ್ ನೀಡಿ",
      "enterEmail": "ಇಮೇಲ್ ನೀಡಿ",
      "enterPassword": "ಪಾಸ್ವರ್ಡ್ ನೀಡಿ",
      "enterName": "ಹೆಸರು ನೀಡಿ",

      "passwordMin": "ಕನಿಷ್ಠ 6 ಅಕ್ಷರಗಳು",
      "passwordMismatch": "ಪಾಸ್ವರ್ಡ್ ಹೊಂದಿಕೆಯಾಗಲಿಲ್ಲ",

      "registrationFailed": "ನೋಂದಣಿ ವಿಫಲವಾಗಿದೆ",
      "networkError": "ನೆಟ್‌ವರ್ಕ್ ದೋಷ",
      "invalidLogin": "ತಪ್ಪಾದ ಇಮೇಲ್ ಅಥವಾ ಪಾಸ್‌ವರ್ಡ್",

      "deleteComplaint": "ದೂರು ಅಳಿಸಿ",
      "deleteConfirm": "ಈ ದೂರನ್ನು ಅಳಿಸಲು ಬಯಸುವಿರಾ?",
      "delete": "ಅಳಿಸಿ",
      "deleteSuccess": "ದೂರು ಯಶಸ್ವಿಯಾಗಿ ಅಳಿಸಲಾಗಿದೆ",
      "deleteFailed": "ಅಳಿಸುವುದು ವಿಫಲವಾಗಿದೆ",

      "escalateComplaint": "ದೂರು ಹೆಚ್ಚಿಸಿ",
      "currentAuthority": "ಪ್ರಸ್ತುತ ಅಧಿಕಾರ",
      "deadlinePassed": "ಗಡುವು ಮುಗಿದಿದೆ",
      "wait": "ನಿರೀಕ್ಷಿಸಿ",
      "escalate": "ಹೆಚ್ಚಿಸಿ",

      "escalationConfirmed": "ಎಸ್ಕಲೇಶನ್ ದೃಢಪಡಿಸಲಾಗಿದೆ",
      "escalationSuccess": "ನಿಮ್ಮ ದೂರು ಮುಂದಿನ ಅಧಿಕಾರಿಗೆ ಕಳುಹಿಸಲಾಗಿದೆ",
      "escalationFailed": "ಎಸ್ಕಲೇಶನ್ ವಿಫಲವಾಗಿದೆ",

      "ok": "ಸರಿ",
      "noComplaints": "ಯಾವುದೇ ದೂರುಗಳು ಇಲ್ಲ",
      "authority": "ಅಧಿಕಾರ",
      "progress": "ಪ್ರಗತಿ",
      "shareAwareness": "ಜಾಗೃತಿ ಹಂಚಿಕೆ",
      "anonymous": "ಅನಾಮಧೇಯ"
    }
  };

  static String t(String key) {
    return _data[current]?[key] ?? _data["en"]![key] ?? key;
  }
}