// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Malayalam (`ml`).
class AppLocalizationsMl extends AppLocalizations {
  AppLocalizationsMl([String locale = 'ml']) : super(locale);

  @override
  String get appTitle => 'TextData';

  @override
  String get actionCancel => 'റദ്ദാക്കുക';

  @override
  String get actionSave => 'സംരക്ഷിക്കുക';

  @override
  String get actionOk => 'ശരി';

  @override
  String get actionCopy => 'പകർത്തുക';

  @override
  String get actionRemove => 'നീക്കം ചെയ്യുക';

  @override
  String get actionClearAll => 'എല്ലാം മായ്ക്കുക';

  @override
  String get actionContinue => 'തുടരുക';

  @override
  String get actionOpenFile => 'ഒരു ഫയൽ തുറക്കുക';

  @override
  String get actionNewDocument => 'പുതിയ ഡോക്യുമെന്റ്';

  @override
  String get newDocumentChooseFormat => 'ഒരു ഡോക്യുമെന്റ് തരം തിരഞ്ഞെടുക്കുക';

  @override
  String get newDocumentTxt => 'വാചകം (TXT)';

  @override
  String get newDocumentMarkdown => 'മാർക്ക്ഡൗൺ (MD)';

  @override
  String get newDocumentCsv => 'പട്ടിക (CSV)';

  @override
  String get newDocumentJson => 'ഡാറ്റ (JSON)';

  @override
  String get newDocumentXml => 'ഡാറ്റ (XML)';

  @override
  String get actionUndo => 'പഴയപടിയാക്കുക';

  @override
  String get actionRedo => 'വീണ്ടും ചെയ്യുക';

  @override
  String get actionFind => 'കണ്ടെത്തുക';

  @override
  String get actionFindReplace => 'കണ്ടെത്തി മാറ്റുക';

  @override
  String get actionShare => 'പങ്കിടുക';

  @override
  String get actionShareZip => 'സിപ്പായി പങ്കിടുക';

  @override
  String get actionPrint => 'പ്രിന്റ് ചെയ്യുക';

  @override
  String get actionExport => 'കയറ്റുമതി…';

  @override
  String get actionFileInfo => 'ഫയൽ വിവരം';

  @override
  String get actionGo => 'പോകുക';

  @override
  String get actionSaveAsCopy => 'ഒരു പകർപ്പായി സംരക്ഷിക്കുക';

  @override
  String get actionRestore => 'പുനഃസ്ഥാപിക്കുക';

  @override
  String get actionDiscard => 'ഉപേക്ഷിക്കുക';

  @override
  String get actionRetry => 'വീണ്ടും ശ്രമിക്കുക';

  @override
  String get draftBannerText =>
      'മുൻ സെഷനിലെ സംരക്ഷിക്കാത്ത മാറ്റങ്ങൾ കണ്ടെത്തി.';

  @override
  String get failCantOpenTitle => 'ഈ ഫയൽ തുറക്കാൻ കഴിയുന്നില്ല';

  @override
  String get failCannotOpen => 'ഈ ഫയൽ തുറക്കാൻ കഴിഞ്ഞില്ല.';

  @override
  String get readAloud => 'ഉറക്കെ വായിക്കുക';

  @override
  String get readAloudStop => 'വായന നിർത്തുക';

  @override
  String get readAloudUnavailable => 'ഉറക്കെ വായിക്കൽ ഇപ്പോൾ ലഭ്യമല്ല.';

  @override
  String get actionSplit => 'വിഭജിക്കുക';

  @override
  String get actionNext => 'അടുത്തത്';

  @override
  String splitStopped(int done, int total) {
    return '$total-ൽ $done ഭാഗങ്ങൾ സംരക്ഷിച്ചശേഷം നിർത്തി.';
  }

  @override
  String splitSaved(int count) {
    return '$count ഭാഗങ്ങൾ സംരക്ഷിച്ചു.';
  }

  @override
  String mergedReview(String name) {
    return '$name ലയിപ്പിച്ചു. അവലോകനം ചെയ്ത് സംരക്ഷിക്കുക.';
  }

  @override
  String get labelEncoding => 'എൻകോഡിംഗ്';

  @override
  String get labelLineEnding => 'വരി അവസാനം';

  @override
  String get labelDelimiter => 'വേർതിരിക്കൽ അടയാളം';

  @override
  String get commonYes => 'അതെ';

  @override
  String get commonNo => 'അല്ല';

  @override
  String get infoSize => 'വലുപ്പം';

  @override
  String get infoModified => 'പരിഷ്കരിച്ചത്';

  @override
  String get infoTitle => 'ഫയൽ വിവരം';

  @override
  String get saveOptionsTitle => 'സംരക്ഷണ ഓപ്ഷനുകൾ';

  @override
  String get saveDone => 'സംരക്ഷിച്ചു.';

  @override
  String saveCopyDone(String name) {
    return 'ഒരു പകർപ്പ് സംരക്ഷിച്ചു: $name.';
  }

  @override
  String get saveNewFile => 'പുതിയ ഫയൽ';

  @override
  String get saveCouldNot => 'സംരക്ഷിക്കാൻ കഴിഞ്ഞില്ല.';

  @override
  String get saveReadOnly => 'ഈ ഫയൽ വായിക്കാൻ മാത്രമുള്ളതാണ്.';

  @override
  String get saveFailed => 'ഫയൽ സംരക്ഷിക്കാൻ കഴിഞ്ഞില്ല.';

  @override
  String get exportSheetTitle => 'കയറ്റുമതി';

  @override
  String get exportAsTitle => 'ഇങ്ങനെ കയറ്റുമതി ചെയ്യുക';

  @override
  String get exportAllRows => 'എല്ലാ വരികളും';

  @override
  String get exportFilteredRows => 'അരിച്ചത്';

  @override
  String get exportSelectedRows => 'തിരഞ്ഞെടുത്തത്';

  @override
  String exportCreated(String name) {
    return '$name സൃഷ്ടിച്ചു';
  }

  @override
  String get exportSaveCopy => 'ഒരു പകർപ്പ് സംരക്ഷിക്കുക';

  @override
  String get outShareFileFailed => 'ഫയൽ പങ്കിടാൻ കഴിഞ്ഞില്ല.';

  @override
  String get outShareZipFailed => 'സിപ്പ് പങ്കിടാൻ കഴിഞ്ഞില്ല.';

  @override
  String get outPrintFailed => 'ഫയൽ പ്രിന്റ് ചെയ്യാൻ കഴിഞ്ഞില്ല.';

  @override
  String get outExportFailed => 'കയറ്റുമതി സൃഷ്ടിക്കാൻ കഴിഞ്ഞില്ല.';

  @override
  String get outShareExportFailed => 'കയറ്റുമതി പങ്കിടാൻ കഴിഞ്ഞില്ല.';

  @override
  String outSaved(String name) {
    return '$name സംരക്ഷിച്ചു.';
  }

  @override
  String get homeTitle => 'സമീപകാല ഫയലുകൾ';

  @override
  String get homeEmptyTitle => 'സമീപകാല ഫയലുകളൊന്നുമില്ല';

  @override
  String get homeClearAllTitle => 'സമീപകാല ഫയലുകൾ മായ്ക്കണോ?';

  @override
  String get homeClearAllBody =>
      'ഇത് പട്ടിക മാത്രമേ നീക്കം ചെയ്യൂ. നിങ്ങളുടെ ഫയലുകൾ ഇല്ലാതാക്കില്ല.';

  @override
  String get homeUnavailable =>
      'ലഭ്യമല്ല — ഫയൽ നീക്കി, ഇല്ലാതാക്കി, അല്ലെങ്കിൽ പ്രവേശനം റദ്ദാക്കി';

  @override
  String get homeClearConfirm => 'മായ്ക്കുക';

  @override
  String get homeRemoveTooltip => 'നീക്കം ചെയ്യുക';

  @override
  String get homeClearAllTooltip => 'എല്ലാം മായ്ക്കുക';

  @override
  String get homeEmptyBody =>
      'തുടങ്ങാൻ ഒരു വാചക അല്ലെങ്കിൽ ഡാറ്റ ഫയൽ തുറക്കുക. അടുത്ത തവണ അത് ഇവിടെ കാണിക്കും.';

  @override
  String get homeLoadError => 'സമീപകാല ഫയലുകൾ ലോഡ് ചെയ്യാൻ കഴിഞ്ഞില്ല';

  @override
  String get navHome => 'ഹോം';

  @override
  String get navEditor => 'എഡിറ്റർ';

  @override
  String get navSettings => 'ക്രമീകരണങ്ങൾ';

  @override
  String get tabClose => 'അടയ്ക്കുക';

  @override
  String get tabCloseOthers => 'മറ്റുള്ളവ അടയ്ക്കുക';

  @override
  String get tabCloseAll => 'എല്ലാം അടയ്ക്കുക';

  @override
  String get tabNoDocuments => 'തുറന്ന ഡോക്യുമെന്റുകളൊന്നുമില്ല';

  @override
  String get tabOpenFromHome => 'തുടങ്ങാൻ ഹോമിൽ നിന്ന് ഒരു ഫയൽ തുറക്കുക.';

  @override
  String get tabCouldNotSave =>
      'സംരക്ഷിക്കാൻ കഴിഞ്ഞില്ല; ടാബ് തുറന്നിരിക്കുന്നു.';

  @override
  String get unsavedTitle => 'മാറ്റങ്ങൾ സംരക്ഷിക്കണോ?';

  @override
  String unsavedBody(String fileName) {
    return '\"$fileName\"-ൽ സംരക്ഷിക്കാത്ത മാറ്റങ്ങളുണ്ട്. നിങ്ങൾ എന്തു ചെയ്യാൻ ആഗ്രഹിക്കുന്നു?';
  }

  @override
  String get unsavedKeepEditing => 'എഡിറ്റിംഗ് തുടരുക';

  @override
  String get degradedPrevPage => 'മുൻ പേജ്';

  @override
  String get degradedNextPage => 'അടുത്ത പേജ്';

  @override
  String get degradedPageLabel => 'പേജ്';

  @override
  String degradedOfCount(int count) {
    return '$count-ൽ';
  }

  @override
  String get degradedLargeBanner =>
      'ഈ ഫയൽ വലുതാണ്. ഇത് വായിക്കാൻ മാത്രമുള്ള മോഡിൽ തുറന്നിരിക്കുന്നു; എഡിറ്റിംഗ് ഓഫാണ്.';

  @override
  String get degradedTryAgain => 'വീണ്ടും ശ്രമിക്കുക';

  @override
  String get placeholderComingSoon =>
      'ഈ ഫയൽ തരത്തിനുള്ള വ്യൂവർ പിന്നീടൊരു ഘട്ടത്തിൽ വരും.';

  @override
  String get placeholderOpenedFile => 'തുറന്ന ഫയൽ';

  @override
  String get overwriteTitle => 'ഫയൽ മാറ്റിയെഴുതണോ?';

  @override
  String get overwriteBody =>
      'ഇത് നിങ്ങളുടെ മാറ്റങ്ങൾ കൊണ്ട് യഥാർത്ഥ ഫയലിനെ പകരം വയ്ക്കുന്നു. ക്രമീകരണങ്ങൾ › എഡിറ്റർ എന്നതിൽ ഈ പരിശോധന ഓഫാക്കാം.';

  @override
  String get overwriteConfirm => 'മാറ്റിയെഴുതുക';

  @override
  String shellTabsSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'സംരക്ഷിച്ച $count ടാബുകൾ വീണ്ടും തുറക്കാൻ കഴിഞ്ഞില്ല (ഫയൽ നീക്കി, ഇല്ലാതാക്കി, അല്ലെങ്കിൽ പ്രവേശനം റദ്ദാക്കി).',
      one:
          'സംരക്ഷിച്ച 1 ടാബ് വീണ്ടും തുറക്കാൻ കഴിഞ്ഞില്ല (ഫയൽ നീക്കി, ഇല്ലാതാക്കി, അല്ലെങ്കിൽ പ്രവേശനം റദ്ദാക്കി).',
    );
    return '$_temp0';
  }

  @override
  String get onboardingSkip => 'ഒഴിവാക്കുക';

  @override
  String get onboardingNext => 'അടുത്തത്';

  @override
  String get onboardingGetStarted => 'തുടങ്ങുക';

  @override
  String get onboarding1Title =>
      'നിങ്ങളുടെ ഫയലുകൾ വായിക്കുകയും എഡിറ്റ് ചെയ്യുകയും ചെയ്യുക';

  @override
  String get onboarding1Body =>
      'TXT, മാർക്ക്ഡൗൺ, CSV, JSON, XML ഫയലുകൾ തുറക്കുക — അവ കാണുക, എഡിറ്റ് ചെയ്യുക, മാറ്റങ്ങൾ സുരക്ഷിതമായി തിരികെ സംരക്ഷിക്കുക.';

  @override
  String get onboarding2Title => 'സ്വകാര്യവും ഓഫ്‌ലൈനും';

  @override
  String get onboarding2Body =>
      'എല്ലാം ഓഫ്‌ലൈനിൽ പ്രവർത്തിക്കുന്നു. ഫയലുകൾ സിസ്റ്റം പിക്കർ വഴി മാത്രമേ തുറക്കൂ, അതിനാൽ ആപ്പ് സ്വയം നിങ്ങളുടെ സ്റ്റോറേജ് പരതില്ല.';

  @override
  String get onboarding3Title => 'ഉപകരണങ്ങൾക്കിടയിൽ പങ്കിടുക';

  @override
  String get onboarding3Body =>
      'ഒരേ വൈ-ഫൈയിലുള്ള രണ്ട് ഉപകരണങ്ങൾക്കിടയിൽ നിങ്ങളുടെ ആപ്പ് ഡാറ്റ നീക്കുക — സെർവറോ ഇന്റർനെറ്റോ ആവശ്യമില്ല.';

  @override
  String get securitySectionTitle => 'സുരക്ഷ';

  @override
  String get securityCardSubtitle =>
      'ആപ്പ് പ്രവേശനവും സ്വകാര്യ ഡാറ്റയും സംരക്ഷിക്കുക.';

  @override
  String get securityAppLockTitle => 'ആപ്പ് ലോക്ക്';

  @override
  String get securityAppLockSubtitle =>
      'ആപ്പ് തുറക്കാൻ ഒരു പിൻ (അല്ലെങ്കിൽ ബയോമെട്രിക്) ആവശ്യപ്പെടുക.';

  @override
  String get securityChangePin => 'പിൻ മാറ്റുക';

  @override
  String get securityShowNewRecovery => 'ഒരു പുതിയ വീണ്ടെടുക്കൽ കോഡ് കാണിക്കുക';

  @override
  String get securityShowNewRecoverySubtitle =>
      'പഴയത് പകരം വയ്ക്കുന്നു. വീണ്ടെടുക്കൽ കോഡ് നഷ്ടപ്പെട്ടാൽ ഉപയോഗിക്കുക.';

  @override
  String get securityBiometricTitle => 'ബയോമെട്രിക് അൺലോക്ക്';

  @override
  String get securityBiometricSubtitle =>
      'ഉപകരണം പിന്തുണയ്ക്കുമ്പോൾ അൺലോക്ക് ചെയ്യാൻ വിരലടയാളമോ മുഖമോ ഉപയോഗിക്കുക.';

  @override
  String get securityScreenshotTitle =>
      'പെയറിംഗ് സ്ക്രീനിൽ സ്ക്രീൻഷോട്ടുകൾ തടയുക';

  @override
  String get securityScreenshotSubtitle =>
      'സ്ക്രീൻഷോട്ടുകളിൽ നിന്നും സ്ക്രീൻ റെക്കോർഡിംഗിൽ നിന്നും ആപ്പ് മറയ്ക്കുന്നു. പെയറിംഗ് കോഡ് / QR സ്ക്രീൻ എപ്പോഴും സംരക്ഷിതമാണ്.';

  @override
  String get securitySetPinTitle => 'ഒരു ആപ്പ്-ലോക്ക് പിൻ സജ്ജമാക്കുക';

  @override
  String get securitySetPinSubtitle =>
      'ആപ്പ് തുറക്കാൻ നിങ്ങൾക്ക് ഈ പിൻ ആവശ്യമാണ്.';

  @override
  String get securityTurnOffTitle => 'ആപ്പ് ലോക്ക് ഓഫാക്കണോ?';

  @override
  String get securityTurnOffBody =>
      'ഇത് നിങ്ങളുടെ പിന്നും വീണ്ടെടുക്കൽ കോഡും നീക്കം ചെയ്യുന്നു. അൺലോക്ക് ചെയ്യാതെ ആപ്പ് തുറക്കും.';

  @override
  String get securityTurnOff => 'ഓഫാക്കുക';

  @override
  String get securityPinChanged => 'പിൻ മാറ്റി';

  @override
  String get lockEnterPin => 'നിങ്ങളുടെ പിൻ നൽകുക';

  @override
  String get lockPinLabel => 'പിൻ';

  @override
  String get lockUnlock => 'അൺലോക്ക് ചെയ്യുക';

  @override
  String get lockUseBiometric => 'ബയോമെട്രിക് ഉപയോഗിക്കുക';

  @override
  String get lockForgotPin => 'പിൻ മറന്നോ?';

  @override
  String get lockWrongPin => 'തെറ്റായ പിൻ. വീണ്ടും ശ്രമിക്കുക.';

  @override
  String get lockEnterRecoveryTitle => 'വീണ്ടെടുക്കൽ കോഡ് നൽകുക';

  @override
  String get lockRecoveryHint => 'ABCD-EFGH-JKMN';

  @override
  String get lockRecoveryWrong => 'ആ വീണ്ടെടുക്കൽ കോഡ് ശരിയല്ല.';

  @override
  String get lockSetNewPinTitle => 'ഒരു പുതിയ പിൻ സജ്ജമാക്കുക';

  @override
  String get lockSetNewPinSubtitle =>
      'നിങ്ങളുടെ വീണ്ടെടുക്കൽ കോഡ് സ്വീകരിച്ചു. ഒരു പുതിയ പിൻ തിരഞ്ഞെടുക്കുക.';

  @override
  String get lockBiometricReason => 'TextData അൺലോക്ക് ചെയ്യുക';

  @override
  String get setPinTitle => 'ഒരു പിൻ സജ്ജമാക്കുക';

  @override
  String get setPinSubtitle =>
      'കുറഞ്ഞത് 4 അക്കങ്ങളുള്ള ഒരു പിൻ തിരഞ്ഞെടുക്കുക.';

  @override
  String get setPinConfirmLabel => 'പിൻ സ്ഥിരീകരിക്കുക';

  @override
  String get setPinSave => 'പിൻ സംരക്ഷിക്കുക';

  @override
  String setPinTooShort(int min) {
    return 'കുറഞ്ഞത് $min അക്കങ്ങൾ ഉപയോഗിക്കുക.';
  }

  @override
  String get setPinMismatch => 'രണ്ട് പിന്നുകളും പൊരുത്തപ്പെടുന്നില്ല.';

  @override
  String get recoveryTitle => 'നിങ്ങളുടെ വീണ്ടെടുക്കൽ കോഡ് സംരക്ഷിക്കുക';

  @override
  String get recoveryBody =>
      'നിങ്ങൾ പിൻ മറന്നാൽ, ഈ വീണ്ടെടുക്കൽ കോഡാണ് തിരികെ പ്രവേശിക്കാനുള്ള ഏക വഴി. ഇത് എഴുതി സുരക്ഷിതമായ സ്ഥലത്ത് സൂക്ഷിക്കുക. ഇത് ഒരിക്കൽ മാത്രമേ കാണിക്കൂ.';

  @override
  String get recoveryCopied => 'വീണ്ടെടുക്കൽ കോഡ് പകർത്തി';

  @override
  String get recoverySaved => 'ഞാൻ ഇത് സംരക്ഷിച്ചു';

  @override
  String get settingsTitle => 'ക്രമീകരണങ്ങൾ';

  @override
  String get appearSectionTitle => 'രൂപഭാവം';

  @override
  String get appearCardSubtitle => 'തീം, വാചക വലുപ്പം, ഫോണ്ട്, വരി അകലം.';

  @override
  String get appearTheme => 'തീം';

  @override
  String get appearFontSize => 'ഫോണ്ട് വലുപ്പം';

  @override
  String get appearFontFamily => 'ഫോണ്ട് കുടുംബം';

  @override
  String get appearMalayalamFontFamily => 'മലയാളം ഫോണ്ട്';

  @override
  String get appearLineSpacing => 'വരി അകലം';

  @override
  String get appearWordWrapTitle => 'വാക്ക് പൊതിയൽ';

  @override
  String get appearWordWrapSubtitle =>
      'വാചക ഫയലുകളിൽ സ്ഥിരമായി നീണ്ട വരികൾ പൊതിയുക.';

  @override
  String get appearLanguage => 'ഭാഷ';

  @override
  String get languageSystem => 'സിസ്റ്റം';

  @override
  String get languageEnglish => 'ഇംഗ്ലീഷ്';

  @override
  String get languageMalayalam => 'മലയാളം';

  @override
  String get editorSectionTitle => 'എഡിറ്റർ';

  @override
  String get editorCardSubtitle =>
      'സംരക്ഷണം, വരി അവസാനങ്ങൾ, എഡിറ്റിംഗ് സ്ഥിരസ്ഥിതികൾ.';

  @override
  String get editorDefaultEncoding => 'സംരക്ഷിക്കുമ്പോൾ സ്ഥിര എൻകോഡിംഗ്';

  @override
  String get editorPreserveEncoding =>
      'നിലനിർത്തുക എന്നത് ഫയലിന്റെ സ്വന്തം എൻകോഡിംഗ് സൂക്ഷിക്കുന്നു.';

  @override
  String get editorDefaultLineEnding => 'സംരക്ഷിക്കുമ്പോൾ സ്ഥിര വരി അവസാനം';

  @override
  String get editorPreserveLineEnding =>
      'നിലനിർത്തുക എന്നത് ഫയലിന്റെ സ്വന്തം വരി അവസാനം സൂക്ഷിക്കുന്നു.';

  @override
  String get editorConfirmOverwrite =>
      'മാറ്റിയെഴുതുന്നതിന് മുമ്പ് സ്ഥിരീകരിക്കുക';

  @override
  String get editorConfirmOverwriteSub =>
      'സംരക്ഷിക്കുമ്പോൾ യഥാർത്ഥ ഫയൽ പകരം വയ്ക്കുന്നതിന് മുമ്പ് ചോദിക്കുക.';

  @override
  String get editorOpenReadOnly =>
      'ഫയലുകൾ സ്ഥിരമായി വായിക്കാൻ മാത്രമായി തുറക്കുക';

  @override
  String get editorOpenReadOnlySub =>
      'പുതിയ ടാബുകൾ ലോക്ക് ചെയ്ത നിലയിൽ ആരംഭിക്കുന്നു; എഡിറ്റ് ചെയ്യാൻ അൺലോക്ക് ചെയ്യുക.';

  @override
  String get editorAutoSaveLabel => 'ഡ്രാഫ്റ്റ് ഓട്ടോ-സേവ് ചെയ്യുന്ന ഇടവേള';

  @override
  String get editorAutoSaveOff => 'ഓഫ്';

  @override
  String editorAutoSaveValue(int seconds) {
    return '$seconds സെ';
  }

  @override
  String get filesTabsSectionTitle => 'ഫയലുകളും ടാബുകളും';

  @override
  String get filesTabsCardSubtitle => 'ടാബ് പരിധികളും പുനഃസ്ഥാപന സ്വഭാവവും.';

  @override
  String get filesAuto => 'സ്വയമേവ';

  @override
  String filesAutoCap(int cap) {
    String _temp0 = intl.Intl.pluralLogic(
      cap,
      locale: localeName,
      other: 'സ്വയമേവ — $cap ടാബുകൾ',
      one: 'സ്വയമേവ — 1 ടാബ്',
    );
    return '$_temp0';
  }

  @override
  String get filesAutoLimit => 'സ്വയമേവയുള്ള ടാബ് പരിധി';

  @override
  String filesChosenFromMemory(String label) {
    return 'ഉപകരണ മെമ്മറിയിൽ നിന്ന് തിരഞ്ഞെടുത്തത് ($label).';
  }

  @override
  String get filesUsingFixed => 'ഒരു നിശ്ചിത പരിധി ഉപയോഗിക്കുന്നു.';

  @override
  String get filesMaxOpenTabs => 'പരമാവധി തുറന്ന ടാബുകൾ';

  @override
  String get filesWhenLimitReached => 'പരിധി എത്തുമ്പോൾ';

  @override
  String get filesRestoreOnRelaunch =>
      'വീണ്ടും തുറക്കുമ്പോൾ ടാബുകൾ പുനഃസ്ഥാപിക്കുക';

  @override
  String get filesRestoreSub =>
      'ആപ്പ് വീണ്ടും ആരംഭിക്കുമ്പോൾ നിങ്ങൾ തുറന്നിരുന്ന ഫയലുകൾ വീണ്ടും തുറക്കുക.';

  @override
  String get speechSectionTitle => 'സംസാരം (ഉറക്കെ വായിക്കൽ)';

  @override
  String get speechCardSubtitle => 'ഭാഷകളും ടെക്സ്റ്റ്-ടു-സ്പീച്ച് ശബ്ദങ്ങളും.';

  @override
  String get speechEnglish => 'ഇംഗ്ലീഷ്';

  @override
  String get speechEnglishSub => 'ഉള്ളടക്കം ഇംഗ്ലീഷിൽ ഉറക്കെ വായിക്കുക.';

  @override
  String get speechMalayalam => 'മലയാളം';

  @override
  String get speechMalayalamSub =>
      'ഈ ഉപകരണത്തിൽ മലയാളം ശബ്ദം ഇൻസ്റ്റാൾ ചെയ്യേണ്ടതുണ്ട്.';

  @override
  String get speechChecking => 'മലയാളം ശബ്ദം പരിശോധിക്കുന്നു…';

  @override
  String get speechMlReady => 'മലയാളം ശബ്ദം തയ്യാറാണ്.';

  @override
  String get speechMlNeedsInstall =>
      'മലയാളം ശബ്ദം ഇതുവരെ ഇൻസ്റ്റാൾ ചെയ്തിട്ടില്ല. ശബ്ദ ഡാറ്റ ഇൻസ്റ്റാൾ ചെയ്ത ശേഷം വീണ്ടും പരിശോധിക്കുക.';

  @override
  String get speechInstallVoice => 'ശബ്ദ ഡാറ്റ ഇൻസ്റ്റാൾ ചെയ്യുക';

  @override
  String get speechOpenTtsSettings => 'TTS ക്രമീകരണങ്ങൾ തുറക്കുക';

  @override
  String get speechCheckAgain => 'വീണ്ടും പരിശോധിക്കുക';

  @override
  String get speechNoEngine =>
      'ഈ ഉപകരണത്തിൽ ടെക്സ്റ്റ്-ടു-സ്പീച്ച് എൻജിൻ ലഭ്യമല്ല.';

  @override
  String get speechCouldNotOpen =>
      'ശബ്ദ ഇൻസ്റ്റാൾ സ്ക്രീൻ തുറക്കാൻ കഴിഞ്ഞില്ല.';

  @override
  String get syncSectionTitle => 'സമന്വയം';

  @override
  String get syncCardSubtitle =>
      'ഉപകരണങ്ങൾക്കിടയിൽ എന്ത് പങ്കിടണമെന്ന് തിരഞ്ഞെടുക്കുക.';

  @override
  String get syncDefaultCategories =>
      'സ്ഥിരമായി പങ്കിടേണ്ട വിഭാഗങ്ങൾ. ഓരോ തവണ അയയ്ക്കുമ്പോഴും നിങ്ങൾക്ക് ഈ തിരഞ്ഞെടുപ്പ് മാറ്റാം.';

  @override
  String get syncLocalNote =>
      'സമന്വയം നിങ്ങളുടെ ലോക്കൽ നെറ്റ്‌വർക്കിൽ തന്നെ നിലനിൽക്കുന്നു. നിങ്ങളുടെ ഡിസ്‌പ്ലേ ക്രമീകരണങ്ങളും മുകളിലുള്ള വിഭാഗങ്ങളും മാത്രമേ പങ്കിടൂ — ഒരിക്കലും പാസ്‌വേഡുകൾ, കീകൾ, അല്ലെങ്കിൽ പെയറിംഗ് കോഡ് അല്ല.';

  @override
  String get syncOpenSync => 'സമന്വയം തുറക്കുക';

  @override
  String get helpSectionTitle => 'സഹായം';

  @override
  String get helpCardSubtitle =>
      'ആപ്പ് സവിശേഷതകൾ എങ്ങനെ പ്രവർത്തിക്കുന്നു എന്ന് അറിയുക.';

  @override
  String get helpSplitArrayTitle => 'അറേ വിഭജിക്കുക';

  @override
  String get helpSplitArrayBody =>
      'JSON ഫയലിന്റെ ഏറ്റവും മുകൾ തലം ഒരു അറേ ആയിരിക്കുമ്പോൾ അറേ വിഭജനം പ്രവർത്തിക്കുന്നു. ഓരോ ഭാഗത്തിലും എത്ര ഇനങ്ങൾ വേണമെന്ന് തിരഞ്ഞെടുക്കുക. ആപ്പ് പിന്നീട് name.part1.json പോലുള്ള നമ്പറിട്ട ഫയലുകൾ സൃഷ്ടിക്കുകയും ഓരോന്നും എവിടെ സംരക്ഷിക്കണമെന്ന് ചോദിക്കുകയും ചെയ്യുന്നു. അവസാന ഭാഗത്തിൽ കുറച്ച് ഇനങ്ങൾ മാത്രമേ ഉണ്ടാകൂ. നിങ്ങളുടെ യഥാർത്ഥ ഫയൽ മാറ്റില്ല.';

  @override
  String get aboutSectionTitle => 'കുറിച്ച്';

  @override
  String get aboutCardSubtitle =>
      'ആപ്പ് പതിപ്പ്, രചയിതാവ്, ലൈസൻസ് വിശദാംശങ്ങൾ.';

  @override
  String get aboutLoading => 'ആപ്പ് വിശദാംശങ്ങൾ ലോഡ് ചെയ്യുന്നു…';

  @override
  String get aboutUnavailable => 'ആപ്പ് വിശദാംശങ്ങൾ ലഭ്യമല്ല.';

  @override
  String get aboutVersion => 'പതിപ്പ്';

  @override
  String aboutVersionValue(String version, String build) {
    return '$version (ബിൽഡ് $build)';
  }

  @override
  String get aboutAuthor => 'രചയിതാവ്';

  @override
  String get aboutContact => 'ബന്ധപ്പെടുക';

  @override
  String get aboutLicenses => 'ലൈസൻസുകൾ';

  @override
  String get aboutLinkPrivacy => 'സ്വകാര്യതാ നയം';

  @override
  String get aboutLinkSupport => 'പിന്തുണ';

  @override
  String get aboutLinkSource => 'സോഴ്സ് കോഡ്';

  @override
  String get linkCouldNotOpen => 'ലിങ്ക് തുറക്കാൻ കഴിഞ്ഞില്ല.';

  @override
  String get syncStatusWaiting => 'ഒരു ഉപകരണത്തിനായി കാത്തിരിക്കുന്നു…';

  @override
  String get syncStatusConnected => 'ഉപകരണം കണക്റ്റ് ചെയ്തു';

  @override
  String get syncStatusWrongCode => 'തെറ്റായ കോഡ്';

  @override
  String get syncStatusError => 'എന്തോ കുഴപ്പം സംഭവിച്ചു';

  @override
  String get syncStatusStopped => 'നിർത്തി';

  @override
  String get syncTitle => 'മറ്റൊരു ഉപകരണവുമായി സമന്വയിപ്പിക്കുക';

  @override
  String get syncIntro =>
      'ഒരേ വൈ-ഫൈയിലുള്ള രണ്ട് ഉപകരണങ്ങൾക്കിടയിൽ നിങ്ങളുടെ പ്രിയപ്പെട്ടവ, ബുക്ക്‌മാർക്കുകൾ, സമീപകാല ഫയലുകൾ, ഡിസ്‌പ്ലേ ക്രമീകരണങ്ങൾ എന്നിവ നീക്കുക. ഇന്റർനെറ്റ് ഉപയോഗിക്കുന്നില്ല, മറ്റേ ഉപകരണത്തിൽ ഒന്നും ഒരിക്കലും മാറ്റിയെഴുതില്ല.';

  @override
  String get syncSend => 'അയയ്ക്കുക';

  @override
  String get syncSendSubtitle => 'ഈ ഉപകരണത്തിന്റെ ഡാറ്റ പങ്കിടുക';

  @override
  String get syncReceive => 'സ്വീകരിക്കുക';

  @override
  String get syncReceiveSubtitle => 'മറ്റൊരു ഉപകരണത്തിൽ നിന്ന് ഡാറ്റ നേടുക';

  @override
  String get syncComplete => 'സമന്വയം പൂർത്തിയായി';

  @override
  String syncAddedKept(int added, int kept) {
    return '$added ചേർത്തു · $kept നിലനിർത്തി';
  }

  @override
  String syncAppliedKept(int applied, int kept) {
    return '$applied പ്രയോഗിച്ചു · $kept നിലനിർത്തി';
  }

  @override
  String get syncCatFavorites => 'പ്രിയപ്പെട്ടവ';

  @override
  String get syncCatBookmarks => 'ബുക്ക്‌മാർക്കുകൾ';

  @override
  String get syncCatRecents => 'സമീപകാല ഫയലുകൾ';

  @override
  String get syncDisplaySettings => 'ഡിസ്‌പ്ലേ ക്രമീകരണങ്ങൾ';

  @override
  String get syncHostTitle => 'ഒരു ഉപകരണത്തിലേക്ക് അയയ്ക്കുക';

  @override
  String get syncClientTitle => 'ഒരു ഉപകരണത്തിൽ നിന്ന് സ്വീകരിക്കുക';

  @override
  String syncCouldNotStart(String error) {
    return 'ആരംഭിക്കാൻ കഴിഞ്ഞില്ല: $error';
  }

  @override
  String get syncTabConnection => 'കണക്ഷൻ';

  @override
  String get syncTabWhatToShare => 'എന്ത് പങ്കിടണം';

  @override
  String get syncDataSent =>
      'ഡാറ്റ അയച്ചു. നിങ്ങൾക്ക് വീണ്ടും അയയ്ക്കാം അല്ലെങ്കിൽ നിർത്താം.';

  @override
  String get syncNoWifi =>
      'വൈ-ഫൈ വിലാസം കണ്ടെത്തിയില്ല. രണ്ട് ഉപകരണങ്ങളും ഒരേ വൈ-ഫൈയിലേക്ക് കണക്റ്റ് ചെയ്ത ശേഷം മറ്റേ ഉപകരണത്തിൽ കോഡ്, വിലാസം, പോർട്ട് എന്നിവ ടൈപ്പ് ചെയ്യുക.';

  @override
  String get syncPairingCode => 'പെയറിംഗ് കോഡ്';

  @override
  String get syncAddress => 'വിലാസം';

  @override
  String get syncPort => 'പോർട്ട്';

  @override
  String get syncStop => 'നിർത്തുക';

  @override
  String get syncConnecting => 'കണക്റ്റ് ചെയ്യുന്നു…';

  @override
  String get syncConnectedWaiting =>
      'കണക്റ്റ് ചെയ്തു — അയയ്ക്കുന്നയാൾ എന്ത് അയയ്ക്കണമെന്ന് തിരഞ്ഞെടുക്കാൻ കാത്തിരിക്കുന്നു…';

  @override
  String get syncApplying => 'ലഭിച്ച ഡാറ്റ പ്രയോഗിക്കുന്നു…';

  @override
  String get syncFailedGeneric => 'സമന്വയം പരാജയപ്പെട്ടു.';

  @override
  String get syncFailed => 'സമന്വയം പരാജയപ്പെട്ടു';

  @override
  String get syncScanQr => 'QR കോഡ് സ്കാൻ ചെയ്യുക';

  @override
  String get syncOrTypeDetails => 'അല്ലെങ്കിൽ വിശദാംശങ്ങൾ ടൈപ്പ് ചെയ്യുക';

  @override
  String get syncAddressHint => 'ഉദാ. 192.168.1.5';

  @override
  String get syncConnect => 'കണക്റ്റ് ചെയ്യുക';

  @override
  String get syncScanTitle => 'QR കോഡ് സ്കാൻ ചെയ്യുക';

  @override
  String get syncScanSemantics =>
      'ക്യാമറ വ്യൂഫൈൻഡർ. മറ്റേ ഉപകരണത്തിലെ പെയറിംഗ് QR കോഡിലേക്ക് ചൂണ്ടുക. നിങ്ങൾക്ക് തിരികെ പോയി കോഡ് ടൈപ്പ് ചെയ്യാനും കഴിയും.';

  @override
  String get syncFreshDevice => 'പുതിയ ഉപകരണം';

  @override
  String get syncFreshDeviceBody =>
      'ഇതുവരെ ഡാറ്റയില്ലാത്ത ഒരു ഉപകരണത്തിലേക്ക് എല്ലാം (പ്രിയപ്പെട്ടവ, ബുക്ക്‌മാർക്കുകൾ, സമീപകാല ഫയലുകൾ, ഡിസ്‌പ്ലേ ക്രമീകരണങ്ങൾ) അയയ്ക്കുക.';

  @override
  String get syncFullSync => 'പൂർണ്ണ സമന്വയം';

  @override
  String get syncChooseWhatToShare => 'എന്ത് പങ്കിടണമെന്ന് തിരഞ്ഞെടുക്കുക';

  @override
  String get syncWontOverride =>
      'ഇത് മറ്റേ ഉപകരണത്തിൽ ഇതിനകം ഉള്ളതൊന്നും മാറ്റിയെഴുതില്ല; വൈരുദ്ധ്യമുണ്ടെങ്കിൽ മറ്റേ ഉപകരണം അതിന്റെ ഡാറ്റ നിലനിർത്തുന്നു.';

  @override
  String get syncSendSelected => 'തിരഞ്ഞെടുത്തവ അയയ്ക്കുക';

  @override
  String get findFind => 'കണ്ടെത്തുക';

  @override
  String get findReplace => 'മാറ്റുക';

  @override
  String get findReplaceAll => 'എല്ലാം മാറ്റുക';

  @override
  String get findReplaceWith => 'ഇതുകൊണ്ട് മാറ്റുക';

  @override
  String get findMatchCase => 'അക്ഷരവലുപ്പം പൊരുത്തപ്പെടുത്തുക';

  @override
  String get findUseRegex => 'റെഗുലർ എക്സ്പ്രഷൻ ഉപയോഗിക്കുക';

  @override
  String get findToggleReplace => 'മാറ്റൽ ടോഗിൾ ചെയ്യുക';

  @override
  String get findClose => 'കണ്ടെത്തൽ അടയ്ക്കുക';

  @override
  String get findNextMatch => 'അടുത്ത പൊരുത്തം';

  @override
  String get findPreviousMatch => 'മുൻ പൊരുത്തം';

  @override
  String get findNoResults => 'ഫലങ്ങളൊന്നുമില്ല';

  @override
  String get txtFind => 'കണ്ടെത്തുക';

  @override
  String get txtReplace => 'മാറ്റുക';

  @override
  String get txtReplaceAll => 'എല്ലാം മാറ്റുക';

  @override
  String get txtReplaceWith => 'ഇതുകൊണ്ട് മാറ്റുക';

  @override
  String get txtMatchCase => 'അക്ഷരവലുപ്പം പൊരുത്തപ്പെടുത്തുക';

  @override
  String get txtUseRegex => 'റെഗുലർ എക്സ്പ്രഷൻ ഉപയോഗിക്കുക';

  @override
  String get txtToggleReplace => 'മാറ്റൽ ടോഗിൾ ചെയ്യുക';

  @override
  String get txtCloseFind => 'കണ്ടെത്തൽ അടയ്ക്കുക';

  @override
  String get txtNextMatch => 'അടുത്ത പൊരുത്തം';

  @override
  String get txtPreviousMatch => 'മുൻ പൊരുത്തം';

  @override
  String get txtNoResults => 'ഫലങ്ങളൊന്നുമില്ല';

  @override
  String get txtCancel => 'റദ്ദാക്കുക';

  @override
  String get txtLinksTitle => 'ലിങ്കുകൾ';

  @override
  String get txtNoLinksFound => 'ലിങ്കുകളൊന്നും കണ്ടെത്തിയില്ല';

  @override
  String get txtNoLinksBody => 'ഈ ഫയലിൽ വെബ് ലിങ്കുകളൊന്നുമില്ല.';

  @override
  String get txtCopyLink => 'ലിങ്ക് പകർത്തുക';

  @override
  String get txtOpenInBrowser => 'ബ്രൗസറിൽ തുറക്കുക';

  @override
  String get txtLinkWarningTitle => 'ഈ ലിങ്ക് തുറക്കണോ?';

  @override
  String get txtLinkWarningBody =>
      'ഇത് നിങ്ങളുടെ ബ്രൗസറിൽ ഒരു ബാഹ്യ ലിങ്ക് തുറക്കുന്നു. നിങ്ങൾ വിശ്വസിക്കുന്ന ലിങ്കുകൾ മാത്രം തുറക്കുക.';

  @override
  String get txtInfoTitle => 'ഫയൽ വിവരം';

  @override
  String get txtInfoSize => 'വലുപ്പം';

  @override
  String get txtInfoModified => 'പരിഷ്കരിച്ചത്';

  @override
  String get txtInfoWords => 'വാക്കുകൾ';

  @override
  String get txtInfoCharacters => 'അക്ഷരങ്ങൾ';

  @override
  String get txtInfoCharactersNoLineBreaks => 'അക്ഷരങ്ങൾ (വരി മുറിവുകളില്ലാതെ)';

  @override
  String get txtInfoLines => 'വരികൾ';

  @override
  String get txtEncoding => 'എൻകോഡിംഗ്';

  @override
  String get txtEncodingSheetTitle => 'വാചക എൻകോഡിംഗ്';

  @override
  String get txtLineEnding => 'വരി അവസാനം';

  @override
  String get txtBinaryWarning =>
      'ഈ ഫയൽ വാചകം പോലെ തോന്നുന്നില്ല. ഇത് അതേപടി കാണിക്കുന്നു, കുഴഞ്ഞുമറിഞ്ഞതായി തോന്നാം.';

  @override
  String get txtLinkCopied => 'ലിങ്ക് ക്ലിപ്ബോർഡിലേക്ക് പകർത്തി.';

  @override
  String get txtSplitFile => 'ഫയൽ വിഭജിക്കുക';

  @override
  String get txtSplitByLines => 'വരി എണ്ണം അനുസരിച്ച്';

  @override
  String get txtSplitBySize => 'വലുപ്പം അനുസരിച്ച് (KB)';

  @override
  String get txtLinesPerPart => 'ഓരോ ഭാഗത്തിലും വരികൾ';

  @override
  String get txtKbPerPart => 'ഓരോ ഭാഗത്തിലും കിലോബൈറ്റുകൾ';

  @override
  String get txtSplitOnePart => 'ഫയൽ ഒരു ഭാഗത്തിൽ ഒതുങ്ങാൻ മാത്രം ചെറുതാണ്.';

  @override
  String get txtViewMode => 'കാഴ്ച മോഡ്';

  @override
  String get txtEditMode => 'എഡിറ്റ് മോഡ്';

  @override
  String get txtWordWrapOn => 'വാക്ക് പൊതിയൽ: ഓൺ';

  @override
  String get txtWordWrapOff => 'വാക്ക് പൊതിയൽ: ഓഫ്';

  @override
  String get txtJumpToLine => 'വരിയിലേക്ക് പോകുക';

  @override
  String get txtLineNumber => 'വരി നമ്പർ';

  @override
  String get txtAppendFile => 'ഒരു ഫയൽ ചേർക്കുക';

  @override
  String get mdShowRendered => 'റെൻഡർ ചെയ്തത്';

  @override
  String get mdShowSource => 'സോഴ്സ്';

  @override
  String get mdEdit => 'എഡിറ്റ്';

  @override
  String get mdPreview => 'പ്രിവ്യൂ';

  @override
  String get mdLivePreviewOn => 'ലൈവ് പ്രിവ്യൂ ഓൺ';

  @override
  String get mdLivePreviewOff => 'ലൈവ് പ്രിവ്യൂ ഓഫ്';

  @override
  String get mdSave => 'സംരക്ഷിക്കുക';

  @override
  String get mdUndo => 'പഴയപടിയാക്കുക';

  @override
  String get mdRedo => 'വീണ്ടും ചെയ്യുക';

  @override
  String get mdFind => 'കണ്ടെത്തുക';

  @override
  String get mdContents => 'ഉള്ളടക്കം';

  @override
  String get mdDraftFound => 'സംരക്ഷിക്കാത്ത ഡ്രാഫ്റ്റ് കണ്ടെത്തി';

  @override
  String get mdRestore => 'പുനഃസ്ഥാപിക്കുക';

  @override
  String get mdDiscard => 'ഉപേക്ഷിക്കുക';

  @override
  String get mdCantOpenTitle => 'ഈ ഫയൽ തുറക്കാൻ കഴിയുന്നില്ല';

  @override
  String get mdCannotOpenFile => 'ഈ ഫയൽ തുറക്കാൻ കഴിഞ്ഞില്ല.';

  @override
  String get mdRetry => 'വീണ്ടും ശ്രമിക്കുക';

  @override
  String get mdSplitByHeading => 'തലക്കെട്ട് അനുസരിച്ച് വിഭജിക്കുക';

  @override
  String get mdAppendFile => 'ഒരു ഫയൽ ചേർക്കുക';

  @override
  String get mdBold => 'കട്ടിയുള്ളത്';

  @override
  String get mdItalic => 'ചരിഞ്ഞത്';

  @override
  String get mdStrikethrough => 'വെട്ടിയത്';

  @override
  String get mdBulletList => 'ബുള്ളറ്റ് പട്ടിക';

  @override
  String get mdNumberedList => 'നമ്പറിട്ട പട്ടിക';

  @override
  String get mdTaskList => 'ടാസ്ക് പട്ടിക';

  @override
  String get mdQuote => 'ഉദ്ധരണി';

  @override
  String get mdInlineCode => 'ഇൻലൈൻ കോഡ്';

  @override
  String get mdCodeBlock => 'കോഡ് ബ്ലോക്ക്';

  @override
  String get mdLink => 'ലിങ്ക്';

  @override
  String get mdTable => 'പട്ടിക';

  @override
  String get mdHeading => 'തലക്കെട്ട്';

  @override
  String get mdHeading1 => 'തലക്കെട്ട് 1';

  @override
  String get mdHeading2 => 'തലക്കെട്ട് 2';

  @override
  String get mdHeading3 => 'തലക്കെട്ട് 3';

  @override
  String get mdLinkWarningBody =>
      'ഈ ലിങ്ക് ഓൺലൈനിലേക്ക് പോകുകയും ആപ്പിന് പുറത്ത് തുറക്കുകയും ചെയ്യുന്നു. നിങ്ങൾ വിശ്വസിക്കുന്ന ലിങ്കുകൾ മാത്രം തുറക്കുക.';

  @override
  String get mdNoHeadings => 'ഈ ഡോക്യുമെന്റിൽ തലക്കെട്ടുകളൊന്നുമില്ല.';

  @override
  String get mdInfoWords => 'വാക്കുകൾ';

  @override
  String get mdInfoHeadings => 'തലക്കെട്ടുകൾ';

  @override
  String get mdInfoLinks => 'ലിങ്കുകൾ';

  @override
  String get mdInfoLines => 'വരികൾ';

  @override
  String get mdInfoTitleField => 'ശീർഷകം';

  @override
  String get mdInfoAuthorField => 'രചയിതാവ്';

  @override
  String get mdInfoTags => 'ടാഗുകൾ';

  @override
  String get mdNoTopHeadings => 'വിഭജിക്കാൻ മുകൾ തല തലക്കെട്ടുകളൊന്നുമില്ല.';

  @override
  String get jsonReadAloud => 'ഉറക്കെ വായിക്കുക';

  @override
  String get jsonStopReading => 'വായന നിർത്തുക';

  @override
  String get jsonReadAloudUnavailable => 'ഉറക്കെ വായിക്കൽ ലഭ്യമല്ല';

  @override
  String get jsonViewMinified => 'ചുരുക്കിയത്';

  @override
  String get jsonPathQuery => 'JSONPath ചോദ്യം';

  @override
  String get jsonCompareFile => 'ഒരു ഫയലുമായി താരതമ്യം ചെയ്യുക';

  @override
  String get jsonSplitArray => 'അറേ വിഭജിക്കുക';

  @override
  String get jsonNotValidTree =>
      'ഈ ഡോക്യുമെന്റ് സാധുവായ JSON അല്ല. ശരിയാക്കാൻ എഡിറ്റർ തുറക്കുക.';

  @override
  String get jsonCopyValue => 'മൂല്യം പകർത്തുക';

  @override
  String get jsonCopyJson => 'JSON പകർത്തുക';

  @override
  String get jsonEditValue => 'മൂല്യം എഡിറ്റ് ചെയ്യുക';

  @override
  String get jsonEditKey => 'കീ എഡിറ്റ് ചെയ്യുക';

  @override
  String get jsonValueCopied => 'മൂല്യം പകർത്തി.';

  @override
  String get jsonJsonCopied => 'JSON പകർത്തി.';

  @override
  String get jsonValueHint => 'ഒരു JSON മൂല്യം, ഉദാ. \"text\", 42, true';

  @override
  String get jsonInvalidValue => 'അത് സാധുവായ JSON മൂല്യമല്ല.';

  @override
  String get jsonNewKey => 'പുതിയ കീ';

  @override
  String get jsonMemberKeyHint => 'അംഗ കീ';

  @override
  String get jsonNewValue => 'പുതിയ മൂല്യം';

  @override
  String get jsonPathTitle => 'JSONPath';

  @override
  String get jsonPathHint => 'ഉദാ. \$.data.users[*].name';

  @override
  String get jsonNotValidDoc => 'ഡോക്യുമെന്റ് സാധുവായ JSON അല്ല.';

  @override
  String get jsonWellFormed => 'നന്നായി രൂപപ്പെട്ട JSON.';

  @override
  String jsonNotValidWithLine(int line, String error) {
    return 'സാധുവായ JSON അല്ല (വരി $line): $error';
  }

  @override
  String jsonNotValidNoLine(String error) {
    return 'സാധുവായ JSON അല്ല: $error';
  }

  @override
  String get jsonValidateAgainstSchema => 'ഒരു സ്കീമയ്ക്കെതിരെ പരിശോധിക്കുക…';

  @override
  String get jsonFixErrorsFirst => 'ആദ്യം JSON പിഴവുകൾ ശരിയാക്കുക.';

  @override
  String get jsonValidAgainstSchema => 'സ്കീമയ്ക്കെതിരെ സാധുവാണ്.';

  @override
  String get jsonSchemaReadError => 'ആ സ്കീമ ഫയൽ വായിക്കാൻ കഴിഞ്ഞില്ല.';

  @override
  String jsonSchemaErrors(int count) {
    return '$count സ്കീമ പിഴവ്(കൾ):';
  }

  @override
  String get jsonFixBeforeCompare =>
      'താരതമ്യം ചെയ്യുന്നതിന് മുമ്പ് JSON പിഴവുകൾ ശരിയാക്കുക.';

  @override
  String get jsonOtherNotValid => 'മറ്റേ ഫയൽ സാധുവായ JSON അല്ല.';

  @override
  String jsonDiffWith(String name) {
    return '$name-മായി വ്യത്യാസം';
  }

  @override
  String get jsonIdentical => 'രണ്ട് ഡോക്യുമെന്റുകളും ഒരുപോലെയാണ്.';

  @override
  String jsonDiffSummary(int added, int removed, int changed) {
    return '$added ചേർത്തു · $removed നീക്കി · $changed മാറ്റി';
  }

  @override
  String get jsonDiffAdded => 'ചേർത്തത്';

  @override
  String get jsonDiffRemoved => 'നീക്കിയത്';

  @override
  String get jsonDiffChanged => 'മാറ്റിയത്';

  @override
  String jsonDiffSection(String title, int count) {
    return '$title ($count)';
  }

  @override
  String get jsonNothingToSplit =>
      'വിഭജിക്കാൻ ഒന്നുമില്ല — വളരെ കുറച്ച് ഇനങ്ങൾ.';

  @override
  String get jsonItemsPerPart => 'ഓരോ ഭാഗത്തിലും ഇനങ്ങൾ';

  @override
  String get jsonInfoValid => 'സാധുവായ JSON';

  @override
  String get jsonInfoTopType => 'മുകൾ തല തരം';

  @override
  String get jsonInfoTopItems => 'മുകൾ തല ഇനങ്ങൾ';

  @override
  String get jsonInfoKeys => 'കീകൾ';

  @override
  String get jsonInfoArrays => 'അറേകൾ';

  @override
  String get jsonInfoLargestArray => 'ഏറ്റവും വലിയ അറേ';

  @override
  String get jsonInfoTypes => 'തരങ്ങൾ';

  @override
  String get jsonNotValidYet => 'ഇതുവരെ സാധുവായ JSON അല്ല';

  @override
  String jsonProblemNearLine(int line) {
    return 'വരി $line-ന് സമീപം ഒരു പ്രശ്നമുണ്ട്. ശരിയാക്കാൻ എഡിറ്റർ തുറക്കുക.';
  }

  @override
  String get jsonOpenEditorToFix => 'JSON ശരിയാക്കാൻ എഡിറ്റർ തുറക്കുക.';

  @override
  String jsonNdjsonBanner(int count) {
    return 'ന്യൂലൈൻ-ഡിലിമിറ്റഡ് JSON — $count റെക്കോർഡുകൾ.';
  }

  @override
  String get jsonLenientBanner =>
      'അയഞ്ഞ രീതിയിൽ വായിച്ചു (കമന്റുകൾ / ട്രെയിലിംഗ് കോമകൾ). സംരക്ഷിക്കുന്നത് കർശനമായ JSON എഴുതുന്നു.';

  @override
  String get jsonMakeStrict => 'കർശനമാക്കുക';

  @override
  String get jsonTreeFilterHint => 'കീ അല്ലെങ്കിൽ മൂല്യം അനുസരിച്ച് അരിക്കുക';

  @override
  String get jsonReformatStrict =>
      'സംരക്ഷിക്കുന്നതിന് മുമ്പ് കർശനമായ JSON ആയി പുനഃക്രമീകരിക്കുക';

  @override
  String mdByAuthor(String author) {
    return '$author എഴുതിയത്';
  }

  @override
  String get xmlTreeFilterHint =>
      'ടാഗ്, ആട്രിബ്യൂട്ട്, അല്ലെങ്കിൽ വാചകം അനുസരിച്ച് അരിക്കുക';

  @override
  String get xmlViewPretty => 'ഭംഗിയായത്';

  @override
  String get xmlViewTree => 'ട്രീ';

  @override
  String get xmlViewRaw => 'അസംസ്കൃതം';

  @override
  String get xmlStopEditing => 'എഡിറ്റിംഗ് നിർത്തുക';

  @override
  String get xmlEditSource => 'സോഴ്സ് എഡിറ്റ് ചെയ്യുക';

  @override
  String get xmlExpandAll => 'എല്ലാം വികസിപ്പിക്കുക';

  @override
  String get xmlCollapseAll => 'എല്ലാം ചുരുക്കുക';

  @override
  String get xmlFormat => 'ഫോർമാറ്റ്';

  @override
  String get xmlMinify => 'ചുരുക്കുക';

  @override
  String get xmlValidate => 'പരിശോധിക്കുക';

  @override
  String get xmlXPathQuery => 'XPath ചോദ്യം';

  @override
  String get xmlInsightsInfo => 'ഉൾക്കാഴ്ചകളും വിവരവും';

  @override
  String get xmlSplitByElement => 'എലമെന്റ് അനുസരിച്ച് വിഭജിക്കുക';

  @override
  String get xmlMergeFile => 'ഒരു ഫയൽ ലയിപ്പിക്കുക';

  @override
  String get xmlCopyAll => 'എല്ലാം പകർത്തുക';

  @override
  String get xmlCopyMinified => 'ചുരുക്കിയത് പകർത്തുക';

  @override
  String get xmlInfoWellFormed => 'നന്നായി രൂപപ്പെട്ട XML';

  @override
  String get xmlInfoRoot => 'റൂട്ട് എലമെന്റ്';

  @override
  String get xmlInfoElements => 'എലമെന്റുകൾ';

  @override
  String get xmlInfoMaxDepth => 'പരമാവധി ആഴം';

  @override
  String get xmlInfoAttributes => 'ആട്രിബ്യൂട്ടുകൾ';

  @override
  String get xmlInfoCommonTags => 'സാധാരണ ടാഗുകൾ';

  @override
  String get xmlInfoNamespaces => 'നെയിംസ്പേസുകൾ';

  @override
  String get xmlFixErrorsBeforeSplit =>
      'വിഭജിക്കുന്നതിന് മുമ്പ് XML പിഴവുകൾ ശരിയാക്കുക.';

  @override
  String get xmlNothingToSplit =>
      'വിഭജിക്കാൻ ഒന്നുമില്ല — വളരെ കുറച്ച് എലമെന്റുകൾ.';

  @override
  String get xmlRepeatedChildElement => 'ആവർത്തിക്കുന്ന ചൈൽഡ് എലമെന്റ്';

  @override
  String get xmlElementsPerPart => 'ഓരോ ഭാഗത്തിലും എലമെന്റുകൾ';

  @override
  String get xmlNewWrapperName => 'പുതിയ റാപ്പർ എലമെന്റ് പേര്';

  @override
  String get xmlPickFile => 'ഫയൽ തിരഞ്ഞെടുക്കുക';

  @override
  String get xmlIndentation => 'ഇൻഡന്റേഷൻ (പുനഃക്രമീകരിക്കുമ്പോൾ)';

  @override
  String get xmlReformat =>
      'സംരക്ഷിക്കുന്നതിന് മുമ്പ് പുനഃക്രമീകരിക്കുക (ഭംഗിയായി രൂപപ്പെടുത്തുക)';

  @override
  String get xmlNotWellFormedTree =>
      'ഈ ഡോക്യുമെന്റ് നന്നായി രൂപപ്പെട്ട XML അല്ല. ശരിയാക്കാൻ എഡിറ്റർ തുറക്കുക.';

  @override
  String get xmlNoMatches => 'പൊരുത്തങ്ങളൊന്നുമില്ല.';

  @override
  String get xmlNodeActions => 'നോഡ് പ്രവർത്തനങ്ങൾ';

  @override
  String get xmlCopyPath => 'പാത്ത് പകർത്തുക';

  @override
  String get xmlCopyText => 'വാചകം പകർത്തുക';

  @override
  String get xmlCopyXml => 'XML പകർത്തുക';

  @override
  String get xmlEditText => 'വാചകം എഡിറ്റ് ചെയ്യുക';

  @override
  String get xmlSetAttribute => 'ആട്രിബ്യൂട്ട് സജ്ജമാക്കുക';

  @override
  String get xmlRemoveAttribute => 'ആട്രിബ്യൂട്ട് നീക്കം ചെയ്യുക';

  @override
  String get xmlRename => 'പേരുമാറ്റുക';

  @override
  String get xmlAddChild => 'ചൈൽഡ് ചേർക്കുക';

  @override
  String get xmlMoveUp => 'മുകളിലേക്ക് നീക്കുക';

  @override
  String get xmlMoveDown => 'താഴേക്ക് നീക്കുക';

  @override
  String get xmlDelete => 'ഇല്ലാതാക്കുക';

  @override
  String get xmlPathCopied => 'പാത്ത് പകർത്തി.';

  @override
  String get xmlTextCopied => 'വാചകം പകർത്തി.';

  @override
  String get xmlXmlCopied => 'XML പകർത്തി.';

  @override
  String get xmlEditTextTitle => 'വാചകം എഡിറ്റ് ചെയ്യുക';

  @override
  String get xmlAttributeName => 'ആട്രിബ്യൂട്ട് പേര്';

  @override
  String get xmlAttributeValue => 'ആട്രിബ്യൂട്ട് മൂല്യം';

  @override
  String get xmlNoAttributes => 'ഈ എലമെന്റിന് ആട്രിബ്യൂട്ടുകളൊന്നുമില്ല.';

  @override
  String get xmlRenameElementTitle => 'എലമെന്റ് പേരുമാറ്റുക';

  @override
  String get xmlNewChildElement => 'പുതിയ ചൈൽഡ് എലമെന്റ്';

  @override
  String get xmlTextOptional => 'വാചകം (ഐച്ഛികം)';

  @override
  String get xmlRemoveWhichAttribute => 'ഏത് ആട്രിബ്യൂട്ട് നീക്കം ചെയ്യണം?';

  @override
  String get xmlXPathTitle => 'XPath';

  @override
  String get xmlXPathHint => 'ഉദാ. //book/title';

  @override
  String get xmlRun => 'പ്രവർത്തിപ്പിക്കുക';

  @override
  String get xmlNotWellFormedDoc => 'ഡോക്യുമെന്റ് നന്നായി രൂപപ്പെട്ട XML അല്ല.';

  @override
  String xmlMatchCount(int count) {
    return '$count പൊരുത്തം(ങ്ങൾ)';
  }

  @override
  String get xmlWellFormedYes => 'നന്നായി രൂപപ്പെട്ട XML.';

  @override
  String xmlNotWellFormedWithLine(int line, String error) {
    return 'നന്നായി രൂപപ്പെട്ടിട്ടില്ല (വരി $line): $error';
  }

  @override
  String xmlNotWellFormedNoLine(String error) {
    return 'നന്നായി രൂപപ്പെട്ടിട്ടില്ല: $error';
  }

  @override
  String get xmlXsdComing => 'XSD സ്കീമ പരിശോധന പിന്നീടൊരു അപ്‌ഡേറ്റിൽ വരും.';

  @override
  String get xmlNotWellFormedYet => 'ഇതുവരെ നന്നായി രൂപപ്പെട്ട XML അല്ല';

  @override
  String xmlProblemNearLine(int line) {
    return 'വരി $line-ന് സമീപം ഒരു പ്രശ്നമുണ്ട്. ശരിയാക്കാൻ എഡിറ്റർ തുറക്കുക.';
  }

  @override
  String get xmlOpenEditorToFix => 'XML ശരിയാക്കാൻ എഡിറ്റർ തുറക്കുക.';

  @override
  String get openTooManyTabs =>
      'വളരെയധികം ടാബുകൾ തുറന്നിരിക്കുന്നു. ആദ്യം ഒന്ന് അടച്ച ശേഷം വീണ്ടും തുറക്കുക.';

  @override
  String get csvShowRawText => 'അസംസ്കൃത വാചകം കാണിക്കുക';

  @override
  String get csvShowTable => 'പട്ടിക കാണിക്കുക';

  @override
  String get csvFilterRows => 'വരികൾ അരിക്കുക';

  @override
  String get csvFilterRowsHint => 'വരികൾ അരിക്കുക…';

  @override
  String get csvJumpToRow => 'വരിയിലേക്ക് പോകുക';

  @override
  String get csvColumnsView => 'കോളങ്ങളും കാഴ്ചയും';

  @override
  String get csvInsights => 'ഉൾക്കാഴ്ചകൾ';

  @override
  String csvRowNumberLabel(int max) {
    return 'വരി നമ്പർ (1–$max)';
  }

  @override
  String get csvRemoveDuplicates => 'ആവർത്തിക്കുന്ന വരികൾ നീക്കം ചെയ്യുക';

  @override
  String get csvSplitByRows => 'വരികൾ അനുസരിച്ച് വിഭജിക്കുക';

  @override
  String get csvAppendFile => 'ഒരു ഫയൽ ചേർക്കുക';

  @override
  String get csvMatchDuplicatesBy =>
      'ഇത് അനുസരിച്ച് ആവർത്തനങ്ങൾ പൊരുത്തപ്പെടുത്തുക';

  @override
  String get csvWholeRow => 'മുഴുവൻ വരി';

  @override
  String csvColumnN(int n) {
    return 'കോളം $n';
  }

  @override
  String get csvNoDuplicates => 'ആവർത്തിക്കുന്ന വരികളൊന്നും കണ്ടെത്തിയില്ല.';

  @override
  String csvRemovedDuplicates(int count) {
    return '$count ആവർത്തന വരി(കൾ) നീക്കം ചെയ്തു.';
  }

  @override
  String get csvInfoTitle => 'ഫയൽ വിവരം';

  @override
  String get csvInfoRows => 'വരികൾ';

  @override
  String get csvInfoColumns => 'കോളങ്ങൾ';

  @override
  String get csvInfoDelimiter => 'വേർതിരിക്കൽ അടയാളം';

  @override
  String get csvInfoHeaderRow => 'തലക്കെട്ട് വരി';

  @override
  String get csvInfoEncoding => 'എൻകോഡിംഗ്';

  @override
  String get csvInfoLineEnding => 'വരി അവസാനം';

  @override
  String get csvInfoSize => 'വലുപ്പം';

  @override
  String get csvInfoModified => 'പരിഷ്കരിച്ചത്';

  @override
  String get csvYes => 'അതെ';

  @override
  String get csvNo => 'അല്ല';

  @override
  String get csvFreezeHeader => 'തലക്കെട്ട് വരി ഫ്രീസ് ചെയ്യുക';

  @override
  String get csvFreezeFirstColumn => 'ആദ്യ കോളം ഫ്രീസ് ചെയ്യുക';

  @override
  String get csvFirstRowHeader => 'ആദ്യ വരി ഒരു തലക്കെട്ടാണ്';

  @override
  String get csvShowColumns => 'കോളങ്ങൾ കാണിക്കുക';

  @override
  String get csvNoColumns => 'വിശകലനം ചെയ്യാൻ കോളങ്ങളൊന്നുമില്ല.';

  @override
  String get csvDataInsights => 'ഡാറ്റ ഉൾക്കാഴ്ചകൾ';

  @override
  String get csvColumnLabel => 'കോളം';

  @override
  String get csvStatType => 'തരം';

  @override
  String get csvStatValues => 'മൂല്യങ്ങൾ';

  @override
  String get csvStatEmpty => 'ശൂന്യം';

  @override
  String get csvStatUnique => 'അതുല്യം';

  @override
  String get csvStatMin => 'കുറഞ്ഞത്';

  @override
  String get csvStatMax => 'കൂടിയത്';

  @override
  String get csvStatSum => 'തുക';

  @override
  String get csvStatAverage => 'ശരാശരി';

  @override
  String get csvSplitOnePart => 'ഫയൽ ഒരു ഭാഗത്തിൽ ഒതുങ്ങാൻ മാത്രം ചെറുതാണ്.';

  @override
  String csvSplitStopped(int done, int total) {
    return '$total-ൽ $done ഭാഗങ്ങൾ സംരക്ഷിച്ചശേഷം നിർത്തി.';
  }

  @override
  String csvSplitSaved(int count) {
    return '$count ഭാഗങ്ങൾ സംരക്ഷിച്ചു.';
  }

  @override
  String csvMerged(String name) {
    return '$name ലയിപ്പിച്ചു. അവലോകനം ചെയ്ത് സംരക്ഷിക്കുക.';
  }

  @override
  String get csvRowsPerPart => 'ഓരോ ഭാഗത്തിലും വരികൾ';

  @override
  String get csvSplitAction => 'വിഭജിക്കുക';

  @override
  String get csvAddRow => 'വരി ചേർക്കുക';

  @override
  String csvEditCell(String name) {
    return '\"$name\" എഡിറ്റ് ചെയ്യുക';
  }

  @override
  String get csvCellFallback => 'സെൽ';

  @override
  String get csvRenameColumn => 'കോളം പേരുമാറ്റുക';

  @override
  String get csvInsertColumnLeft => 'ഇടത്ത് കോളം ചേർക്കുക';

  @override
  String get csvInsertColumnRight => 'വലത്ത് കോളം ചേർക്കുക';

  @override
  String get csvHideColumn => 'കോളം മറയ്ക്കുക';

  @override
  String get csvDeleteColumn => 'കോളം ഇല്ലാതാക്കുക';

  @override
  String get csvInsertRowAbove => 'മുകളിൽ വരി ചേർക്കുക';

  @override
  String get csvInsertRowBelow => 'താഴെ വരി ചേർക്കുക';

  @override
  String get csvMoveUp => 'മുകളിലേക്ക് നീക്കുക';

  @override
  String get csvMoveDown => 'താഴേക്ക് നീക്കുക';

  @override
  String get csvDeleteRow => 'വരി ഇല്ലാതാക്കുക';
}
