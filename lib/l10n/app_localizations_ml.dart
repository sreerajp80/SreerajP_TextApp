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
  String get actionSaveAs => 'ഇങ്ങനെ സംരക്ഷിക്കുക…';

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
  String get fileChangedBanner => 'ഈ ഫയൽ ഡിസ്കിൽ മാറിയിട്ടുണ്ട്.';

  @override
  String get fileChangedReload => 'വീണ്ടും ലോഡ് ചെയ്യുക';

  @override
  String get fileChangedDismiss => 'അവഗണിക്കുക';

  @override
  String get fileChangedReloadFailed => 'ഫയൽ വീണ്ടും ലോഡ് ചെയ്യാൻ കഴിഞ്ഞില്ല.';

  @override
  String get fileChangedConfirmTitle =>
      'വീണ്ടും ലോഡ് ചെയ്ത് മാറ്റങ്ങൾ ഒഴിവാക്കണോ?';

  @override
  String fileChangedConfirmBody(String fileName) {
    return '\"$fileName\"-ൽ സംരക്ഷിക്കാത്ത മാറ്റങ്ങളുണ്ട്. വീണ്ടും ലോഡ് ചെയ്താൽ ഡിസ്കിലുള്ള ഫയൽ വരും, ആ മാറ്റങ്ങൾ നഷ്ടപ്പെടും.';
  }

  @override
  String get fileChangedConfirmReload => 'ലോഡ് ചെയ്ത് ഒഴിവാക്കുക';

  @override
  String get fileChangedConfirmCancel => 'റദ്ദാക്കുക';

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
  String get helpSearchFilterHint => 'സഹായ വിഷയങ്ങൾ തിരയുക…';

  @override
  String get helpNoTopicsFound =>
      'പൊരുത്തപ്പെടുന്ന സഹായ വിഷയങ്ങളൊന്നും കണ്ടെത്തിയില്ല.';

  @override
  String get helpP2pSyncTitle => 'LAN സിങ്കും ലൈവ് ഡിഫും';

  @override
  String get helpP2pSyncSubtitle =>
      'Wi-Fi വഴി ഡാറ്റ സമന്വയിപ്പിക്കുകയും ഡോക്യുമെന്റുകൾ താരതമ്യം ചെയ്യുകയും ചെയ്യുക.';

  @override
  String get helpP2pSyncBody =>
      'ഇന്റർനെറ്റോ ബാഹ്യ സെർവറുകളോ ഇല്ലാതെ നിങ്ങളുടെ ലോക്കൽ Wi-Fi നെറ്റ്‌വർക്കിലുള്ള ഉപകരണങ്ങളിലുടനീളം പ്രിയപ്പെട്ടവ, ബുക്ക്‌മാർക്കുകൾ, സമീപകാല ഫയലുകൾ, ഡിസ്‌പ്ലേ ക്രമീകരണങ്ങൾ എന്നിവ സമന്വയിപ്പിക്കുക.\n\n• ലൈവ് ഡിഫും ഡെൽറ്റ സിങ്കും: ഏത് ഡോക്യുമെന്റും തുറന്ന് മെനുവിൽ നിന്ന് ലൈവ് ഡിഫ് തിരഞ്ഞെടുത്ത് അടുത്തുള്ള ഉപകരണവുമായി ബന്ധിപ്പിക്കുക. വർണ്ണ-കോഡ് ചെയ്ത വ്യത്യാസങ്ങൾ വരി തോറും കാണുകയും മാറ്റങ്ങൾ നേരിട്ട് ലയിപ്പിക്കുകയും ചെയ്യുക.\n• സുരക്ഷ: എല്ലാ സിങ്ക് ആശയവിനിമയങ്ങളും താൽക്കാലിക പെയറിംഗ് കോഡ് ഉപയോഗിച്ച് AES-256-GCM എൻക്രിപ്ഷൻ വഴി സംരക്ഷിക്കപ്പെടുന്നു. ഒന്നും ഇന്റർനെറ്റിലേക്ക് അയയ്ക്കില്ല.';

  @override
  String get helpQrSharingTitle => 'ഒപ്റ്റിക്കൽ QR പങ്കിടൽ (AirQR)';

  @override
  String get helpQrSharingSubtitle =>
      'Wi-Fi, ബ്ലൂടൂത്ത് അല്ലെങ്കിൽ കേബിളുകൾ ഇല്ലാതെ വിഷ്വൽ ആയി ഫയലുകൾ അയയ്ക്കുക.';

  @override
  String get helpQrSharingBody =>
      'നെറ്റ്‌വർക്ക് കണക്ഷൻ ഇല്ലാതെ ആനിമേറ്റഡ് ഹൈ-ഡെൻസിറ്റി QR കോഡുകളും ക്യാമറ സ്കാനിംഗും ഉപയോഗിച്ച് ഉപകരണങ്ങൾ തമ്മിൽ ഡോക്യുമെന്റുകൾ അയയ്ക്കുക.\n\n• എങ്ങനെ അയയ്ക്കാം: ഒരു ഡോക്യുമെന്റ് തുറന്ന് മെനുവിൽ നിന്ന് \"QR വഴി അയയ്ക്കുക\" അല്ലെങ്കിൽ \"തിരഞ്ഞെടുപ്പ് QR വഴി അയയ്ക്കുക\" തിരഞ്ഞെടുക്കുക. ആവശ്യമെങ്കിൽ വേഗതയും സാന്ദ്രതയും ക്രമീകരിക്കുക.\n• എങ്ങനെ സ്വീകരിക്കാം: സ്വീകരിക്കുന്ന ഉപകരണത്തിൽ AirQR സ്ക്രീൻ തുറന്ന് ക്യാമറ അയയ്ക്കുന്ന സ്ക്രീനിലേക്ക് ചൂണ്ടുക.\n• എൻക്രിപ്ഷൻ: AES-256 സെഷൻ പാസ്‌ഫ്രെയ്‌സ് ഉപയോഗിച്ച് കൈമാറ്റം സംരക്ഷിക്കാൻ എൻക്രിപ്ഷൻ ഓണാക്കുക.';

  @override
  String get helpPrivacyShieldTitle => 'പ്രൈവസി ഷീൽഡും PII സ്‌ക്രബ്ബറും';

  @override
  String get helpPrivacyShieldSubtitle =>
      'വ്യക്തിഗത വിവരങ്ങൾ പൂർണ്ണമായും ഓഫ്‌ലൈനായി കണ്ടെത്തി മായ്ക്കുക.';

  @override
  String get helpPrivacyShieldBody =>
      'പങ്കിടുന്നതിനോ സംരക്ഷിക്കുന്നതിനോ മുൻപ് സ്വകാര്യ വിവരങ്ങൾ പരിരക്ഷിക്കുക.\n\n• ഓട്ടോമാറ്റിക് ഡിറ്റക്ഷൻ: ഇമെയിൽ വിലാസങ്ങൾ, ഫോൺ നമ്പറുകൾ, ക്രെഡിറ്റ് കാർഡ് നമ്പറുകൾ, IPv4/IPv6 വിലാസങ്ങൾ, ഐഡന്റിറ്റി നമ്പറുകൾ (SSN/ആധാർ), രഹസ്യ API കീകൾ എന്നിവയ്ക്കായി ടെക്സ്റ്റ് ഓഫ്‌ലൈനായി സ്കാൻ ചെയ്യുന്നു.\n• തിരുത്തലും മാസ്കിംഗും: കണ്ടെത്തിയ വിവരങ്ങൾ പരിശോധിച്ച്, സാധാരണ റീഡാക്ഷൻ ടോക്കണുകൾ ([EMAIL], [PHONE]) അല്ലെങ്കിൽ ചിഹ്നങ്ങൾ ഉപയോഗിച്ച് മാറ്റിസ്ഥാപിക്കുക.\n• പൂജ്യം നെറ്റ്‌വർക്ക് ചോർച്ച: എല്ലാ സ്കാനിംഗും നിങ്ങളുടെ ഉപകരണത്തിൽ പൂർണ്ണമായും ഓഫ്‌ലൈനായി നടക്കുന്നു.';

  @override
  String get helpVaultBackupTitle =>
      'ഡോക്യുമെന്റ് വോൾട്ടും എൻക്രിപ്റ്റ് ചെയ്ത ബാക്കപ്പുകളും';

  @override
  String get helpVaultBackupSubtitle =>
      'രഹസ്യ ഫയലുകൾ സുരക്ഷിത വോൾട്ടിൽ സൂക്ഷിക്കുകയും .txdata ബാക്കപ്പുകൾ നിർമ്മിക്കുകയും ചെയ്യുക.';

  @override
  String get helpVaultBackupBody =>
      'ഹാർഡ്‌വെയർ-പിന്തുണയുള്ള എൻക്രിപ്ഷൻ ഉപയോഗിച്ച് രഹസ്യ ഫയലുകൾ സുരക്ഷിതമായി സൂക്ഷിക്കുക.\n\n• ഡോക്യുമെന്റ് വോൾട്ട്: നിങ്ങളുടെ ആപ്പ് പിൻ അല്ലെങ്കിൽ ബയോമെട്രിക് ലോക്ക് ഉപയോഗിച്ച് പരിരക്ഷിച്ചിരിക്കുന്ന AES-256-GCM എൻക്രിപ്റ്റ് ചെയ്ത വോൾട്ടിൽ സ്വകാര്യ ഫയലുകൾ സൂക്ഷിക്കുക.\n• എൻക്രിപ്റ്റ് ചെയ്ത ബാക്കപ്പുകൾ (.txdata): ഒന്നിലധികം ഡോക്യുമെന്റുകളും ക്രമീകരണങ്ങളും പാസ്‌വേഡ് പരിരക്ഷിത .txdata ആർക്കൈവ് ഫയലുകളായി എക്സ്പോർട്ട് ചെയ്യുക.\n• പുനഃസ്ഥാപിക്കൽ: ആർക്കൈവ് പാസ്‌വേഡ് ഉപയോഗിച്ച് ഏത് സമയത്തും .txdata ബാക്കപ്പുകൾ ഇമ്പോർട്ട് ചെയ്യുക.';

  @override
  String get helpSqlQueryTitle => 'SQL ക്വറി എഞ്ചിൻ';

  @override
  String get helpSqlQuerySubtitle =>
      'CSV, JSON, XML ഫയലുകളിൽ നേരിട്ട് ലോക്കൽ SQL ക്വറികൾ പ്രവർത്തിപ്പിക്കുക.';

  @override
  String get helpSqlQueryBody =>
      'നിങ്ങളുടെ ഉപകരണത്തിൽ നേരിട്ട് സാധാരണ SQL സിന്റാക്സ് ഉപയോഗിച്ച് ഡാറ്റ വിശകലനം ചെയ്യുകയും പരിവർത്തനം ചെയ്യുകയും ചെയ്യുക.\n\n• പിന്തുണയ്ക്കുന്ന ഫോർമാറ്റുകൾ: CSV, JSON, XML ഡോക്യുമെന്റുകളിൽ ക്വറികൾ പ്രവർത്തിപ്പിക്കുക.\n• ശേഷികൾ: SELECT, WHERE, GROUP BY, HAVING, ORDER BY, ടാബുകൾക്കിടയിലുള്ള JOIN എന്നിവ ഉൾപ്പെടെയുള്ള പൂർണ്ണ SQL കമാൻഡുകൾ.\n• എക്സ്പോർട്ട്: ഫലങ്ങൾ നേരിട്ട് പുതിയ CSV അല്ലെങ്കിൽ JSON ഫയലുകളായി സംരക്ഷിക്കുക.';

  @override
  String get helpMultiCursorTitle => 'മൾട്ടി-കഴ്‌സറും കോളം എഡിറ്റിംഗും';

  @override
  String get helpMultiCursorSubtitle =>
      'ഒരേ സമയം ഒന്നിലധികം വരികൾ എഡിറ്റ് ചെയ്യുകയും ലംബമായി സെലക്ട് ചെയ്യുകയും ചെയ്യുക.';

  @override
  String get helpMultiCursorBody =>
      'ഒരേ രീതിയിലുള്ള ടെക്സ്റ്റ് ഫോർമാറ്റിംഗും മാറ്റങ്ങളും വേഗത്തിലാക്കുക.\n\n• മൾട്ടി-കഴ്‌സർ: എഡിറ്ററിൽ ഒന്നിലധികം കഴ്‌സറുകൾ സ്ഥാപിക്കാൻ അമർത്തിപ്പിടിക്കുക. എല്ലാ കഴ്‌സറുകളും ഒരേ സമയം ടൈപ്പ് ചെയ്യുകയും ഡിലീറ്റ് ചെയ്യുകയും ചെയ്യുന്നു.\n• കോളം സെലക്ഷൻ: ഒന്നിലധികം വരികളിലായി ലംബമായ ടെക്സ്റ്റ് സെലക്ട് ചെയ്ത് എളുപ്പത്തിൽ പ്രിഫിക്സുകളോ സഫിക്സുകളോ ചേർക്കുക.';

  @override
  String get helpSearchTitle => 'തിരയലും വർക്ക്‌സ്‌പേസ് ഇൻഡക്‌സും';

  @override
  String get helpSearchSubtitle =>
      'ഡോക്യുമെന്റുകളിലോ എല്ലാ ഫയലുകളിലുമോ അതിവേഗം ടെക്സ്റ്റ് കണ്ടെത്തുക.';

  @override
  String get helpSearchBody =>
      'നിങ്ങളുടെ എല്ലാ ഫയലുകളിലും ടെക്സ്റ്റ് അതിവേഗം കണ്ടെത്തുക:\n\n• ഡോക്യുമെന്റ് തിരയൽ: കേസ് സെൻസിറ്റിവിറ്റി, പൂർണ്ണ വാക്ക്, റെഗുലർ എക്സ്പ്രഷനുകൾ എന്നിവ ഉപയോഗിച്ച് Find & Replace ഉപയോഗിക്കുക.\n• ഗ്ലോബൽ വർക്ക്‌സ്‌പേസ് സെർച്ച്: സമീപകാല, പ്രിയപ്പെട്ട എല്ലാ ഫയലുകളിലും അതിവേഗ SQLite FTS5 ഇൻഡക്സ് തിരയാൻ ഹോം സ്ക്രീനിലെ സെർച്ച് ഐക്കൺ ടാപ്പ് ചെയ്യുക.\n• 100% സ്വകാര്യം: എല്ലാ തിരയലുകളും നിങ്ങളുടെ ഉപകരണത്തിൽ മാത്രം നടക്കുന്നു.';

  @override
  String get helpAuditLogTitle => 'ഓഡിറ്റ് ലോഗും സമഗ്രതാ പരിശോധനയും';

  @override
  String get helpAuditLogSubtitle =>
      'SHA-256 ഹാഷ് ചെയിനുകൾ ഉപയോഗിച്ച് ഫയലുകളുടെ സമഗ്രത പരിശോധിക്കുക.';

  @override
  String get helpAuditLogBody =>
      'ഡോക്യുമെന്റ് പ്രവർത്തനങ്ങളുടെ മാറ്റമില്ലാത്ത രേഖകൾ സൂക്ഷിക്കുക.\n\n• ഹാഷ് ചെയിനിംഗ്: എല്ലാ ഫയൽ തുറക്കൽ, എഡിറ്റ്, സേവ്, വോൾട്ട് പ്രവർത്തനങ്ങളും SHA-256 ചെക്ക്‌സമ്മുകൾ ഉപയോഗിച്ച് ക്രിപ്റ്റോഗ്രാഫിക്കലായി രേഖപ്പെടുത്തുന്നു.\n• സമഗ്രതാ പരിശോധന: ലോഗുകളോ ഫയലുകളോ മാറ്റം വരുത്തിയിട്ടില്ലെന്ന് തെളിയിക്കാൻ ക്രമീകരണങ്ങൾ → ഓഡിറ്റ് ലോഗിൽ നിന്ന് പരിശോധന നടത്തുക.';

  @override
  String get helpFormatToolsTitle => 'പ്രത്യേക ഫോർമാറ്റ് ടൂളുകൾ';

  @override
  String get helpFormatToolsSubtitle =>
      'JSON, Markdown, CSV, XML, TXT എന്നിവയ്ക്കുള്ള പ്രത്യേക ടൂളുകൾ.';

  @override
  String get helpFormatToolsBody =>
      'ഓരോ ഫയൽ തരത്തിനും അനുയോജ്യമായ പ്രത്യേക വിഷ്വൽ ടൂളുകൾ TextData നൽകുന്നു:\n\n• JSON: ഇന്ററാക്ടീവ് ട്രീ വ്യൂവർ, JSONPath ക്വറികൾ, സ്കീമ വാലിഡേറ്റർ, അറേ സ്പ്ലിറ്റർ, ഫോർമാറ്റർ.\n• Markdown: ലൈവ് സ്പ്ലിറ്റ് പ്രിവ്യൂ, വിഷ്വൽ ടേബിൾ ബിൽഡർ, YAML ഫ്രണ്ട്-മാറ്റർ എഡിറ്റർ, ഹെഡിംഗ് സ്പ്ലിറ്റർ.\n• CSV: ഇന്ററാക്ടീവ് സ്പ്രെഡ്ഷീറ്റ് ഗ്രിഡ്, സോർട്ടിംഗ്, ഫോർമുലകൾ (SUM, AVG മുതലായവ), ഡിലിമിറ്റർ കൺവെർട്ടർ.\n• XML: ട്രീ വ്യൂ, XPath ക്വറികൾ, XSD സ്കീമ വാലിഡേഷൻ, ബ്യൂട്ടിഫയർ.\n• TXT: ലൈൻ വിഭജനം, വേഡ് റാപ്പ്, ലൈനിലേക്ക് ചാടൽ, വെബ് ലിങ്ക് ഡിറ്റക്ടർ.';

  @override
  String get helpSpeechTitle => 'വായനയും സംസാരവും (Read Aloud)';

  @override
  String get helpSpeechSubtitle =>
      'ഡോക്യുമെന്റുകൾ ഇംഗ്ലീഷിലും മലയാളത്തിലും ഉറക്കെ വായിച്ചു കേൾക്കുക.';

  @override
  String get helpSpeechBody =>
      'നിങ്ങളുടെ ഉപകരണത്തിലെ ടെക്സ്റ്റ്-ടു-സ്പീച്ച് എഞ്ചിൻ ഉപയോഗിച്ച് ഡോക്യുമെന്റുകൾ കേൾക്കുക.\n\n• പിന്തുണയ്ക്കുന്ന ഭാഷകൾ: ഇംഗ്ലീഷ്, മലയാളം.\n• നിയന്ത്രണങ്ങൾ: പ്ലേ, പോസ്, സ്റ്റോപ്പ്, ഒപ്പം ക്രമീകരണങ്ങൾ → സ്പീച്ച് വഴി വേഗതയും ഭാഷയും ക്രമീകരിക്കാം.';

  @override
  String get helpSplitArrayTitle => 'അറേ വിഭജിക്കുക';

  @override
  String get helpSplitArraySubtitle =>
      'ഒരു JSON അറേ ചെറിയ നമ്പറിട്ട ഫയലുകളായി വിഭജിക്കുക.';

  @override
  String get helpSplitArrayBody =>
      'JSON ഫയലിന്റെ ഏറ്റവും മുകൾ തലം ഒരു അറേ ആയിരിക്കുമ്പോൾ അറേ വിഭജനം പ്രവർത്തിക്കുന്നു. ഓരോ ഭാഗത്തിലും എത്ര ഇനങ്ങൾ വേണമെന്ന് തിരഞ്ഞെടുക്കുക. ആപ്പ് പിന്നീട് name.part1.json പോലുള്ള നമ്പറിട്ട ഫയലുകൾ സൃഷ്ടിക്കുകയും ഓരോന്നും എവിടെ സംരക്ഷിക്കണമെന്ന് ചോദിക്കുകയും ചെയ്യുന്നു. അവസാന ഭാഗത്തിൽ കുറച്ച് ഇനങ്ങൾ മാത്രമേ ഉണ്ടാകൂ. നിങ്ങളുടെ യഥാർത്ഥ ഫയൽ മാറ്റില്ല.';

  @override
  String get helpBackupTitle => 'ബാക്കപ്പ് & എക്സ്പോർട്ട്';

  @override
  String get helpBackupSubtitle =>
      'നിങ്ങളുടെ ഫയലുകളുടെ പകർപ്പുകൾ മറ്റ് ഫോർമാറ്റുകളിലോ ലൊക്കേഷനുകളിലോ സുരക്ഷിതമായി സൂക്ഷിക്കുക.';

  @override
  String get helpBackupBody =>
      'എക്സ്പോർട്ടും സേവ് എ കോപ്പിയും ഉപയോഗിച്ച് നിങ്ങളുടെ ഫയലുകളുടെ പകർപ്പുകൾ സുരക്ഷിതമായി സൂക്ഷിക്കുക. ഏതെങ്കിലും ഡോക്യുമെന്റ് തുറന്ന് \"എക്സ്പോർട്ട്\" കണ്ടെത്താൻ മെനു ടാപ്പ് ചെയ്യുക — ഇത് നിങ്ങളുടെ ഫയൽ PDF അല്ലെങ്കിൽ പ്ലെയിൻ ടെക്സ്റ്റ് പോലുള്ള മറ്റൊരു ഫോർമാറ്റിലേക്ക് മാറ്റുന്നു. യഥാർത്ഥ ഫയൽ മാറ്റാതെ പുതിയ ലൊക്കേഷനിൽ സംരക്ഷിക്കാൻ \"സേവ് എ കോപ്പി\" ഉപയോഗിക്കുക. അധിക സുരക്ഷയ്ക്ക്, പ്രധാനപ്പെട്ട ഫയലുകൾ പതിവായി എക്സ്പോർട്ട് ചെയ്ത് ക്ലൗഡ് ഫോൾഡർ, SD കാർഡ്, അല്ലെങ്കിൽ LAN സിങ്ക് അല്ലെങ്കിൽ QR പങ്കിടൽ വഴി മറ്റൊരു ഉപകരണം പോലുള്ള സുരക്ഷിതമായ സ്ഥലത്ത് പകർപ്പുകൾ സൂക്ഷിക്കുക.';

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
  String get mdTableBuilder => 'പട്ടിക നിർമ്മാതാവ്';

  @override
  String get mdTableBuilderHelp =>
      'സെല്ലുകൾ പൂരിപ്പിക്കുക; പൈപ്പ് ചിഹ്നങ്ങൾ നിങ്ങൾക്കായി ക്രമീകരിക്കും.';

  @override
  String get mdTableHeaderCell => 'തലക്കെട്ട്';

  @override
  String get mdTableAddRow => 'വരി ചേർക്കുക';

  @override
  String get mdTableAddColumn => 'കോളം ചേർക്കുക';

  @override
  String get mdTableRemoveRow => 'ഈ വരി നീക്കുക';

  @override
  String get mdTableRemoveColumn => 'ഈ കോളം നീക്കുക';

  @override
  String get mdTablePreview => 'മാർക്ക്ഡൗൺ';

  @override
  String get mdTableInsert => 'പട്ടിക ചേർക്കുക';

  @override
  String get mdTableAlignDefault => 'സ്ഥിരം';

  @override
  String get mdTableAlignLeft => 'ഇടത്';

  @override
  String get mdTableAlignCenter => 'മധ്യം';

  @override
  String get mdTableAlignRight => 'വലത്';

  @override
  String get mdFrontMatterTitle => 'ഫ്രണ്ട് മാറ്റർ';

  @override
  String get mdFrontMatterHelp =>
      'താഴെയുള്ള ഫീൽഡുകൾ എഡിറ്റ് ചെയ്യുക. ഈ ഫോം കാണിക്കാത്തതെല്ലാം അതേപടി നിലനിർത്തും.';

  @override
  String get mdFrontMatterNone =>
      'ഈ ഫയലിൽ ഇതുവരെ ഫ്രണ്ട് മാറ്റർ ഇല്ല. ഒന്ന് ചേർക്കാൻ ഒരു ഫീൽഡ് പൂരിപ്പിക്കുക.';

  @override
  String get mdFrontMatterAddField => 'ഫീൽഡ് ചേർക്കുക';

  @override
  String get mdFrontMatterFieldName => 'ഫീൽഡിന്റെ പേര്';

  @override
  String get mdFrontMatterAdd => 'ചേർക്കുക';

  @override
  String get mdFrontMatterAddTag => 'ഒരു ടാഗ് ടൈപ്പ് ചെയ്ത് എന്റർ അമർത്തുക';

  @override
  String get mdFrontMatterPickDate => 'തീയതി തിരഞ്ഞെടുക്കുക';

  @override
  String get mdFrontMatterApply => 'മാറ്റങ്ങൾ പ്രയോഗിക്കുക';

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
  String get jsonViewAsTable => 'പട്ടികയായി കാണുക';

  @override
  String get jsonTableNothingToShow =>
      'പട്ടികയായി കാണിക്കാൻ ഈ ഡോക്യുമെന്റിൽ റെക്കോർഡുകളുടെ അറേ ഇല്ല.';

  @override
  String jsonTableSummary(String path, int rows, int columns) {
    return '$path · $rows വരികൾ · $columns കോളങ്ങൾ';
  }

  @override
  String get jsonTableWholeDocument => 'മുഴുവൻ ഡോക്യുമെന്റ്';

  @override
  String get jsonTableCopied => 'മൂല്യം പകർത്തി';

  @override
  String get jsonQueryBuilderTitle => 'ക്വറി ബിൽഡർ';

  @override
  String get jsonQueryGoInto => 'ഇതിലേക്ക് പോകുക';

  @override
  String get jsonQueryAtAnyDepth => 'ഏത് ആഴത്തിലും';

  @override
  String get jsonQueryMatchesHeading => 'പൊരുത്തങ്ങൾ';

  @override
  String get jsonQueryNoMatches =>
      'ഇതുവരെ ഒന്നും പൊരുത്തപ്പെടുന്നില്ല. പിന്നോട്ട് പോയി മറ്റൊരു പാത പരീക്ഷിക്കുക.';

  @override
  String get jsonQueryNothingDeeper =>
      'ഇവിടെ നിന്ന് കൂടുതൽ ആഴത്തിൽ പോകാൻ ഒന്നുമില്ല.';

  @override
  String get jsonQueryStepBack => 'പിന്നോട്ട്';

  @override
  String get jsonQueryStartOver => 'പുതുതായി തുടങ്ങുക';

  @override
  String get jsonQueryUse => 'ഈ ക്വറി ഉപയോഗിക്കുക';

  @override
  String get jsonQuickFixes => 'പെട്ടെന്നുള്ള പരിഹാരങ്ങൾ';

  @override
  String get jsonFixEverything => 'എല്ലാം ശരിയാക്കുക';

  @override
  String get jsonFixQuoteKeys => 'കീകൾക്ക് ഉദ്ധരണി ചിഹ്നം ചേർക്കുക';

  @override
  String get jsonFixDoubleQuotes => 'ഇരട്ട ഉദ്ധരണി ചിഹ്നം ഉപയോഗിക്കുക';

  @override
  String get jsonFixTrailingCommas => 'അധിക കോമകൾ നീക്കുക';

  @override
  String get jsonFixRemoveComments => 'കമന്റുകൾ നീക്കുക';

  @override
  String get jsonFixPythonLiterals => 'true, false, null ഉപയോഗിക്കുക';

  @override
  String get xmlQueryBuilderTitle => 'XPath ബിൽഡർ';

  @override
  String get xmlFixCloseTags => 'തുറന്ന ടാഗുകൾ അടയ്ക്കുക';

  @override
  String get xmlFixEscapeAmpersands => '& ചിഹ്നങ്ങൾ എസ്കേപ്പ് ചെയ്യുക';

  @override
  String get xmlFixWrapRoot => 'ഒറ്റ റൂട്ടിൽ പൊതിയുക';

  @override
  String get xmlFixTrimJunk => 'ആദ്യ ടാഗിന് മുൻപുള്ള വാചകം നീക്കുക';

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
  String get csvSortLevels => 'ക്രമീകരണ തലങ്ങൾ';

  @override
  String get csvSortNoLevels =>
      'ഇതുവരെ ക്രമീകരണമില്ല. ഒന്നിലധികം കോളങ്ങൾ പ്രകാരം ക്രമീകരിക്കാൻ ഒരു തലം ചേർക്കുക.';

  @override
  String get csvSortAddLevel => 'തലം ചേർക്കുക';

  @override
  String get csvSortApply => 'ക്രമീകരണം പ്രയോഗിക്കുക';

  @override
  String get csvSortClear => 'മായ്ക്കുക';

  @override
  String get csvSortFirstBy => 'ഇത് പ്രകാരം ക്രമീകരിക്കുക';

  @override
  String get csvSortThenBy => 'പിന്നെ ഇത് പ്രകാരം';

  @override
  String get csvSortAscending => 'A → Z';

  @override
  String get csvSortDescending => 'Z → A';

  @override
  String get csvSortMoveUp => 'ഈ തലം മുകളിലേക്ക് നീക്കുക';

  @override
  String get csvSortMoveDown => 'ഈ തലം താഴേക്ക് നീക്കുക';

  @override
  String get csvSetFormula => 'ഫോർമുല സജ്ജമാക്കുക…';

  @override
  String get csvEditFormula => 'ഫോർമുല എഡിറ്റ് ചെയ്യുക…';

  @override
  String csvFormulaTitle(String name) {
    return '\"$name\"-നുള്ള ഫോർമുല';
  }

  @override
  String get csvFormulaHelp =>
      'ഈ വരിക്ക് കോളം അക്ഷരങ്ങൾ (A, B), ഒരു നിശ്ചിത സെല്ലിന് വരി നമ്പർ (B2), അല്ലെങ്കിൽ SUM, AVG, MIN, MAX, COUNT, PRODUCT എന്നിവയ്ക്കുള്ളിൽ ഒരു ശ്രേണി ഉപയോഗിക്കുക.';

  @override
  String get csvFormulaLabel => 'ഫോർമുല';

  @override
  String get csvFormulaColumnLetters => 'ഉപയോഗിക്കാവുന്ന കോളങ്ങൾ';

  @override
  String get csvFormulaPreview => 'ആദ്യ വരികൾ';

  @override
  String get csvFormulaApply => 'പ്രയോഗിക്കുക';

  @override
  String get csvFormulaRemove => 'ഫോർമുല നീക്കം ചെയ്യുക';

  @override
  String get csvHighlightRules => 'ഹൈലൈറ്റ് നിയമങ്ങൾ';

  @override
  String get csvNoHighlightRules =>
      'ഇതുവരെ നിയമങ്ങളില്ല. സെല്ലുകൾ സ്വയമേവ നിറം നൽകാൻ ഒന്ന് ചേർക്കുക.';

  @override
  String get csvAddHighlightRule => 'നിയമം ചേർക്കുക';

  @override
  String get csvRuleEveryColumn => 'എല്ലാ കോളങ്ങളും';

  @override
  String get csvRuleWhen => 'മൂല്യം എപ്പോൾ';

  @override
  String get csvRuleValue => 'ഇതുമായി താരതമ്യം ചെയ്യുക';

  @override
  String get csvRuleHighlight => 'ഈ നിറത്തിൽ ഹൈലൈറ്റ് ചെയ്യുക';

  @override
  String get csvConditionLessThan => 'ഇതിലും കുറവാണ്';

  @override
  String get csvConditionGreaterThan => 'ഇതിലും കൂടുതലാണ്';

  @override
  String get csvConditionEqualTo => 'ഇതിന് തുല്യമാണ്';

  @override
  String get csvConditionNotEqualTo => 'ഇതിന് തുല്യമല്ല';

  @override
  String get csvConditionContains => 'ഇത് അടങ്ങിയിരിക്കുന്നു';

  @override
  String get csvConditionIsEmpty => 'ശൂന്യമാണ്';

  @override
  String get csvConditionIsDuplicate => 'അതിന്റെ കോളത്തിൽ ആവർത്തിക്കുന്നു';

  @override
  String get csvHighlightRed => 'ചുവപ്പ്';

  @override
  String get csvHighlightYellow => 'മഞ്ഞ';

  @override
  String get csvHighlightGreen => 'പച്ച';

  @override
  String get csvHighlightBlue => 'നീല';

  @override
  String get csvChartTitle => 'ചാർട്ട്';

  @override
  String get csvOpenFullChart => 'പൂർണ്ണ ചാർട്ട് തുറക്കുക';

  @override
  String get csvChartBar => 'ബാർ';

  @override
  String get csvChartLine => 'ലൈൻ';

  @override
  String get csvChartPie => 'പൈ';

  @override
  String get csvChartValueColumn => 'മൂല്യങ്ങൾ ഇവിടെ നിന്ന്';

  @override
  String get csvChartLabelColumn => 'ലേബലുകൾ ഇവിടെ നിന്ന്';

  @override
  String get csvChartRowNumbers => 'വരി നമ്പറുകൾ';

  @override
  String get csvChartVisibleRowsOnly => 'സ്ക്രീനിലുള്ള വരികൾ മാത്രം';

  @override
  String get csvChartNoNumericColumns =>
      'ചാർട്ട് ചെയ്യാൻ ഈ ഫയലിൽ സംഖ്യാ കോളങ്ങളില്ല.';

  @override
  String get csvChartNothingToDraw => 'ഈ കോളത്തിന് ചാർട്ട് ചെയ്യാൻ ഒന്നുമില്ല.';

  @override
  String get csvChartOther => 'മറ്റുള്ളവ';

  @override
  String csvChartShowingFirst(int count) {
    return 'ആദ്യത്തെ $count മൂല്യങ്ങൾ കാണിക്കുന്നു.';
  }

  @override
  String csvChartSkippedNegative(int count) {
    return '$count നെഗറ്റീവ് മൂല്യങ്ങൾ പൈയിൽ നിന്ന് ഒഴിവാക്കി.';
  }

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

  @override
  String get airqrTitle => 'എയർ-ഗ്യാപ് കൈമാറ്റം (QR)';

  @override
  String get airqrIntro =>
      'സ്ക്രീനും ക്യാമറയും മാത്രം ഉപയോഗിച്ച് ഒരു ഡോക്യുമെന്റോ കുറച്ച് ടെക്സ്റ്റോ മറ്റൊരു ഉപകരണത്തിലേക്ക് അയയ്ക്കുക. വൈ-ഫൈ, ബ്ലൂടൂത്ത്, ഇന്റർനെറ്റ് വഴി ഒന്നും അയയ്ക്കുന്നില്ല.';

  @override
  String get airqrReceive => 'സ്വീകരിക്കുക';

  @override
  String get airqrReceiveSubtitle =>
      'മറ്റേ ഉപകരണത്തിന്റെ സ്ക്രീനിലേക്ക് ക്യാമറ ചൂണ്ടുക';

  @override
  String get airqrHowToSend => 'എങ്ങനെ അയയ്ക്കാം';

  @override
  String get airqrHowToSendBody =>
      'അയയ്ക്കേണ്ട ഡോക്യുമെന്റ് തുറന്ന്, അതിന്റെ മെനുവിൽ നിന്ന് \"QR വഴി അയയ്ക്കുക\" തിരഞ്ഞെടുക്കുക. ഒരു ഭാഗം മാത്രം അയയ്ക്കാൻ, ആദ്യം ടെക്സ്റ്റ് തിരഞ്ഞെടുക്കുക.';

  @override
  String get airqrSpeedNoteTitle => 'ഇത് മനഃപൂർവം സാവധാനമാണ്';

  @override
  String get airqrSpeedNoteBody =>
      'ക്യാമറ ലിങ്ക് സെക്കൻഡിൽ ഏകദേശം 15 KB മാത്രം കൊണ്ടുപോകുന്നു. ചെറിയ കുറിപ്പുകൾക്ക് കുറച്ച് സെക്കൻഡ് മതി; വലിയ ഫയലിന് മിനിറ്റുകൾ എടുക്കാം. വലിയ ഫയലുകൾക്ക് LAN സിങ്ക് ഉപയോഗിക്കുക.';

  @override
  String get airqrSendTitle => 'QR വഴി അയയ്ക്കുന്നു';

  @override
  String get airqrSendByQr => 'QR വഴി അയയ്ക്കുക';

  @override
  String get airqrSendSelectionByQr => 'തിരഞ്ഞെടുത്തത് QR വഴി അയയ്ക്കുക';

  @override
  String get airqrHoldSteady =>
      'മറ്റേ ഉപകരണത്തിന് എല്ലാ ഫ്രെയിമുകളും ലഭിക്കുന്നതുവരെ രണ്ട് ഉപകരണങ്ങളും ഇളകാതെ പിടിക്കുക. അതുവരെ കോഡ് ആവർത്തിക്കും.';

  @override
  String get airqrCodeLabel => 'സെഷൻ കോഡ്';

  @override
  String get airqrCodeHint =>
      'ഈ കോഡ് മറ്റെയാളോട് പറയുക. ഇത് QR കോഡിനുള്ളിൽ ഇല്ല, അതിനാൽ സ്ക്രീൻ റെക്കോർഡ് ചെയ്യുന്നവർക്കും ഇതില്ലാതെ നിങ്ങളുടെ ഡാറ്റ വായിക്കാനാവില്ല.';

  @override
  String get airqrUnsealedWarning =>
      'ഈ കൈമാറ്റം സുരക്ഷിതമല്ല. ഈ സ്ക്രീൻ കാണാൻ കഴിയുന്ന ആർക്കും ഡാറ്റ വായിക്കാം.';

  @override
  String airqrFrameCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ഫ്രെയിമുകൾ',
      one: '1 ഫ്രെയിം',
    );
    return '$_temp0';
  }

  @override
  String airqrPassCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count റൗണ്ടുകൾ പൂർത്തിയായി',
      one: '1 റൗണ്ട് പൂർത്തിയായി',
      zero: 'ആദ്യ റൗണ്ട്',
    );
    return '$_temp0';
  }

  @override
  String airqrOnePassTakes(int seconds) {
    return 'ഒരു പൂർണ്ണ റൗണ്ടിന് ഏകദേശം $seconds സെക്കൻഡ് എടുക്കും.';
  }

  @override
  String airqrSpeedLabel(int fps) {
    return 'വേഗത: സെക്കൻഡിൽ $fps ഫ്രെയിം';
  }

  @override
  String get airqrSpeedHelp =>
      'മറ്റേ ഉപകരണത്തിന് ഫ്രെയിമുകൾ നഷ്ടപ്പെടുന്നെങ്കിൽ ഇത് കുറയ്ക്കുക.';

  @override
  String airqrDensityLabel(int bytes) {
    return 'വിശദാംശം: ഫ്രെയിമിന് $bytes ബൈറ്റ്';
  }

  @override
  String get airqrDensityHelp =>
      'പഴയ ക്യാമറയിൽ എളുപ്പത്തിൽ സ്കാൻ ചെയ്യാൻ ഇത് കുറയ്ക്കുക. കൂടുതൽ ഫ്രെയിമുകൾ വേണ്ടിവരും.';

  @override
  String get airqrReceiveTitle => 'QR വഴി സ്വീകരിക്കുന്നു';

  @override
  String get airqrScanSemantics =>
      'ആനിമേറ്റഡ് QR കോഡ് സ്വീകരിക്കാനുള്ള ക്യാമറ വ്യൂഫൈൻഡർ';

  @override
  String get airqrLookingForStream => 'ഒരു കൈമാറ്റം തിരയുന്നു…';

  @override
  String airqrFramesProgress(int received, int total) {
    return '$total-ൽ $received ഫ്രെയിമുകൾ';
  }

  @override
  String airqrFps(String rate) {
    return 'സെക്കൻഡിൽ $rate ഫ്രെയിം';
  }

  @override
  String airqrRemaining(int seconds) {
    return 'ഏകദേശം $seconds സെക്കൻഡ് ബാക്കി';
  }

  @override
  String airqrStillMissing(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ഫ്രെയിമുകൾ കൂടി കാത്തിരിക്കുന്നു',
      one: 'ഒരു ഫ്രെയിം കൂടി കാത്തിരിക്കുന്നു',
    );
    return '$_temp0';
  }

  @override
  String get airqrAssembling => 'ഡാറ്റ പരിശോധിച്ച് പുനർനിർമ്മിക്കുന്നു…';

  @override
  String get airqrAllFramesReceived => 'എല്ലാ ഫ്രെയിമുകളും ലഭിച്ചു';

  @override
  String get airqrEnterCodePrompt =>
      'അയയ്ക്കുന്ന ഉപകരണത്തിൽ കാണിക്കുന്ന സെഷൻ കോഡ് നൽകുക.';

  @override
  String get airqrUnlock => 'അൺലോക്ക് ചെയ്യുക';

  @override
  String get airqrStartOver => 'വീണ്ടും തുടങ്ങുക';

  @override
  String get airqrReceivedTitle => 'കൈമാറ്റം പൂർത്തിയായി';

  @override
  String airqrCharacterCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count അക്ഷരങ്ങൾ',
      one: '1 അക്ഷരം',
    );
    return '$_temp0';
  }

  @override
  String get airqrPreview => 'പ്രിവ്യൂ';

  @override
  String get airqrCopyText => 'ടെക്സ്റ്റ് പകർത്തുക';

  @override
  String get airqrCopied => 'ക്ലിപ്പ്ബോർഡിലേക്ക് പകർത്തി';

  @override
  String get airqrUseThis => 'ഫയലായി സേവ് ചെയ്യുക';

  @override
  String get airqrFailedGeneric => 'കൈമാറ്റം പൂർത്തിയാക്കാൻ കഴിഞ്ഞില്ല.';

  @override
  String airqrSavedAs(String name) {
    return '$name ആയി സേവ് ചെയ്തു';
  }

  @override
  String get airqrInsertedIntoDocument =>
      'തുറന്ന ഡോക്യുമെന്റിൽ ടെക്സ്റ്റ് ചേർത്തു';

  @override
  String get airqrTooLargeTitle => 'QR കൈമാറ്റത്തിന് വളരെ വലുതാണ്';

  @override
  String airqrTooLargeBody(String size, String limit) {
    return 'ഇത് $size ആണ്, QR കൈമാറ്റത്തിന്റെ പരിധി $limit ആണ്. ക്യാമറ വേഗതയിൽ ഇതിന് വളരെ അധികം സമയം എടുക്കും. പകരം LAN സിങ്ക് ഉപയോഗിക്കുക.';
  }

  @override
  String get airqrSlowTitle => 'ഇതിന് കുറച്ച് സമയം എടുക്കും';

  @override
  String airqrSlowBody(String size, String duration) {
    return 'ഇത് $size ആണ്, QR കോഡ് വഴി $duration എടുക്കും. അത്രയും നേരം രണ്ട് ഉപകരണങ്ങളും ഇളകാതെ പിടിക്കണം. LAN സിങ്ക് വളരെ വേഗത്തിലാകും.';
  }

  @override
  String get airqrSendAnyway => 'എന്നാലും അയയ്ക്കുക';

  @override
  String airqrAboutMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'ഏകദേശം $minutes മിനിറ്റ്',
      one: 'ഏകദേശം 1 മിനിറ്റ്',
    );
    return '$_temp0';
  }

  @override
  String airqrAboutSeconds(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: 'ഏകദേശം $seconds സെക്കൻഡ്',
      one: 'ഏകദേശം 1 സെക്കൻഡ്',
    );
    return '$_temp0';
  }

  @override
  String get airqrNothingToSend => 'അയയ്ക്കാൻ ഒന്നുമില്ല.';

  @override
  String get searchWorkspaceTitle => 'എല്ലാ ഫയലുകളിലും തിരയുക';

  @override
  String get searchWorkspaceTooltip => 'എല്ലാ ഫയലുകളിലും തിരയുക';

  @override
  String get searchWorkspaceHint => 'സമീപകാല, പ്രിയപ്പെട്ട ഫയലുകളിൽ തിരയുക';

  @override
  String get searchWorkspaceStartTitle => 'നിങ്ങളുടെ ഫയലുകൾക്കുള്ളിൽ തിരയുക';

  @override
  String get searchWorkspaceStartBody =>
      'നിങ്ങൾ തുറന്നതോ പ്രിയപ്പെട്ടതായി അടയാളപ്പെടുത്തിയതോ ആയ ഫയലുകളിൽ ഒരു വാക്ക് കണ്ടെത്താൻ അത് ടൈപ്പ് ചെയ്യുക. തിരയൽ ഈ ഉപകരണത്തിൽ മാത്രം നടക്കുന്നു.';

  @override
  String get searchWorkspaceNoResults => 'പൊരുത്തങ്ങളൊന്നും കണ്ടെത്തിയില്ല';

  @override
  String get searchWorkspaceNoResultsBody =>
      'ചെറിയ ഒരു വാക്ക് പരീക്ഷിക്കുക, അല്ലെങ്കിൽ ഫയൽ ഒരിക്കൽ തുറക്കുക, അപ്പോൾ അത് സൂചികയിൽ ചേരും.';

  @override
  String get searchWorkspaceOffTitle => 'വർക്ക്‌സ്‌പേസ് തിരയൽ ഓഫാണ്';

  @override
  String get searchWorkspaceOffBody =>
      'ഫയലുകളിലുടനീളം തിരയാൻ ക്രമീകരണങ്ങൾ › ഫയലുകളും ടാബുകളും എന്നതിൽ ഇത് ഓണാക്കുക.';

  @override
  String get searchWorkspaceClear => 'തിരയൽ മായ്ക്കുക';

  @override
  String get searchWorkspaceAll => 'എല്ലാം';

  @override
  String get searchWorkspacePartial =>
      'വലിയ ഫയൽ — ആദ്യ ഭാഗം മാത്രമേ തിരയുന്നുള്ളൂ';

  @override
  String get searchWorkspaceUnavailable =>
      'ഫയൽ ലഭ്യമല്ല — തിരയലിൽ നിന്ന് നീക്കുക';

  @override
  String searchWorkspaceResults(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ഫയലുകൾ',
      one: '1 ഫയൽ',
    );
    return '$_temp0';
  }

  @override
  String get filesIndexTitle => 'വർക്ക്‌സ്‌പേസ് തിരയൽ സൂചിക';

  @override
  String get filesIndexOn =>
      'നിങ്ങൾ തുറക്കുന്ന ഫയലുകൾ ഈ ഉപകരണത്തിൽ സൂചികയിൽ ചേർക്കും, അതിനാൽ എല്ലാത്തിലും തിരയാം.';

  @override
  String get filesIndexOff =>
      'പുതിയ ഫയലുകൾ സൂചികയിൽ ചേർക്കുന്നില്ല. നേരത്തെ സംഭരിച്ചത് മാത്രമേ തിരയലിൽ കാണൂ.';

  @override
  String filesIndexCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ഫയലുകൾ സൂചികയിലുണ്ട്',
      one: '1 ഫയൽ സൂചികയിലുണ്ട്',
      zero: 'ഫയലുകളൊന്നും സൂചികയിലില്ല',
    );
    return '$_temp0';
  }

  @override
  String get filesIndexClear => 'തിരയൽ സൂചിക മായ്ക്കുക';

  @override
  String get filesIndexClearBody =>
      'ഇത് സൂചികയിലുള്ള ഓരോ ഫയലിന്റെയും സംഭരിച്ച വാചകം ഇല്ലാതാക്കും. ഫയലുകൾക്ക് ഒന്നും സംഭവിക്കില്ല.';

  @override
  String get filesIndexCleared => 'തിരയൽ സൂചിക മായ്ച്ചു';

  @override
  String get filesIndexRebuild => 'തിരയൽ സൂചിക വീണ്ടും നിർമ്മിക്കുക';

  @override
  String get filesIndexRebuilding => 'തിരയൽ സൂചിക വീണ്ടും നിർമ്മിക്കുന്നു…';

  @override
  String filesIndexRebuilt(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ഫയലുകൾ സൂചികയിൽ ചേർത്തു',
      one: '1 ഫയൽ സൂചികയിൽ ചേർത്തു',
      zero: 'പുതുതായി ഒന്നും സൂചികയിൽ ചേർത്തില്ല',
    );
    return '$_temp0';
  }

  @override
  String ephemeralBadgeTimerTooltip(String time) {
    return 'ഈ ടാബ് $time കഴിഞ്ഞ് സ്വയം ഇല്ലാതാകും';
  }

  @override
  String get ephemeralBadgeOutputTooltip =>
      'അടുത്ത കയറ്റുമതിക്കോ പങ്കിടലിനോ ശേഷം ഈ ടാബ് സ്വയം ഇല്ലാതാകും';

  @override
  String get ephemeralSheetTitle => 'ഈ ടാബ് സ്വയം ഇല്ലാതാകട്ടെ';

  @override
  String get ephemeralSheetWhatIsWiped =>
      'ഇല്ലാതാകുമ്പോൾ ആപ്പ് ഈ രേഖ മറക്കും: സ്വയം സേവ് ഡ്രാഫ്റ്റ്, സമീപകാല പട്ടികയിലെ വരി, പ്രിയപ്പെട്ടവ, ബുക്ക്‌മാർക്കുകൾ, വായന സ്ഥാനം, തിരയൽ സൂചികയിലെ അതിന്റെ വാചകം.';

  @override
  String get ephemeralSheetFileKept =>
      'നിങ്ങളുടെ ഫയൽ ഇല്ലാതാക്കില്ല. ആപ്പ് അതിനെക്കുറിച്ച് സൂക്ഷിക്കുന്നത് മാത്രമേ മായ്ക്കൂ.';

  @override
  String get ephemeralSheetUnsavedWarning =>
      'ഈ ടാബിലെ സേവ് ചെയ്യാത്ത മാറ്റങ്ങൾ വീണ്ടും ചോദിക്കാതെ നഷ്ടപ്പെടും.';

  @override
  String get ephemeralSheetTimerLabel => 'എത്ര സമയത്തിനു ശേഷം ഇല്ലാതാകണം';

  @override
  String get ephemeralSheetCustomMinutes => 'മിനിറ്റുകൾ';

  @override
  String get ephemeralSheetBurnAfterOutput =>
      'കയറ്റുമതിക്കോ പങ്കിടലിനോ ശേഷം ഇല്ലാതാക്കുക';

  @override
  String get ephemeralSheetBurnAfterOutputHint =>
      'ആദ്യത്തെ വിജയകരമായ കയറ്റുമതി, പങ്കിടൽ അല്ലെങ്കിൽ പ്രിന്റ് ടാബ് ഇല്ലാതാക്കും. റദ്ദാക്കിയതോ പരാജയപ്പെട്ടതോ ഇല്ലാതാക്കില്ല.';

  @override
  String get ephemeralSheetNothingChosen =>
      'ഒരു സമയം തിരഞ്ഞെടുക്കുക, അല്ലെങ്കിൽ കയറ്റുമതിക്കു ശേഷം ഇല്ലാതാക്കൽ ഓണാക്കുക, അല്ലെങ്കിൽ രണ്ടും.';

  @override
  String get ephemeralSheetConfirm => 'സ്വയം ഇല്ലാതാകുന്നതാക്കുക';

  @override
  String get ephemeralDuration15Minutes => '15 മിനിറ്റ്';

  @override
  String get ephemeralDuration1Hour => '1 മണിക്കൂർ';

  @override
  String get ephemeralDuration4Hours => '4 മണിക്കൂർ';

  @override
  String get ephemeralDuration24Hours => '24 മണിക്കൂർ';

  @override
  String get ephemeralDurationCustom => 'സ്വന്തം സമയം';

  @override
  String get ephemeralDurationNone => 'സമയപരിധി ഇല്ല';

  @override
  String get tabMakeEphemeral => 'സ്വയം ഇല്ലാതാകുന്നതാക്കുക…';

  @override
  String get tabChangeEphemeral => 'സ്വയം ഇല്ലാതാകൽ മാറ്റുക…';

  @override
  String get tabCancelEphemeral => 'ഈ ടാബ് നിലനിർത്തുക';

  @override
  String get tabBurnNow => 'ഇപ്പോൾ ഇല്ലാതാക്കുക';

  @override
  String ephemeralMarked(String name) {
    return '$name സ്വയം ഇല്ലാതാകും';
  }

  @override
  String ephemeralCancelled(String name) {
    return '$name വീണ്ടും ഒരു സാധാരണ ടാബ് ആണ്';
  }

  @override
  String ephemeralBurned(String name) {
    return '$name ഇല്ലാതാക്കി';
  }

  @override
  String ephemeralBurnedPartly(String name) {
    return '$name അടച്ചു, പക്ഷേ സൂക്ഷിച്ച ചില വിവരങ്ങൾ നീക്കാനായില്ല';
  }

  @override
  String get ephemeralBurnNowTitle => 'ഈ ടാബ് ഇല്ലാതാക്കണോ?';

  @override
  String get ephemeralBurnNowBody =>
      'ടാബ് അടയ്ക്കും, ആപ്പ് ഈ രേഖ മറക്കും. സേവ് ചെയ്യാത്ത മാറ്റങ്ങൾ നഷ്ടപ്പെടും. നിങ്ങളുടെ ഫയൽ ഇല്ലാതാക്കില്ല.';

  @override
  String get actionBurn => 'ഇല്ലാതാക്കുക';

  @override
  String get ephemeralOpenAsEphemeral => 'സ്വയം ഇല്ലാതാകുന്ന ടാബായി തുറക്കുക…';

  @override
  String get ephemeralSettingsTitle => 'സ്വയം ഇല്ലാതാകുന്ന രേഖകൾ';

  @override
  String get ephemeralSettingsDefaultDuration => 'സ്ഥിര സമയപരിധി';

  @override
  String get ephemeralSettingsBurnAfterOutput =>
      'കയറ്റുമതിക്കു ശേഷം ഇല്ലാതാക്കൽ സ്ഥിരമായി തിരഞ്ഞെടുക്കുക';

  @override
  String get ephemeralSettingsBurnAfterOutputHint =>
      'ഇത് ഷീറ്റിലെ സ്വിച്ച് മുൻകൂട്ടി ഓണാക്കുന്നു. ഇത് സ്വയം ഒരു ടാബിനെയും മാറ്റില്ല.';

  @override
  String get ephemeralSettingsBurnAll =>
      'സ്വയം ഇല്ലാതാകുന്ന എല്ലാ ടാബുകളും ഇപ്പോൾ ഇല്ലാതാക്കുക';

  @override
  String ephemeralSettingsOpenCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'സ്വയം ഇല്ലാതാകുന്ന $count ടാബുകൾ തുറന്നിട്ടുണ്ട്',
      one: 'സ്വയം ഇല്ലാതാകുന്ന 1 ടാബ് തുറന്നിട്ടുണ്ട്',
      zero: 'സ്വയം ഇല്ലാതാകുന്ന ടാബുകളൊന്നും തുറന്നിട്ടില്ല',
    );
    return '$_temp0';
  }

  @override
  String ephemeralSettingsBurnAllDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ടാബുകൾ ഇല്ലാതാക്കി',
      one: '1 ടാബ് ഇല്ലാതാക്കി',
      zero: 'ഇല്ലാതാക്കാൻ ഒന്നുമില്ല',
    );
    return '$_temp0';
  }

  @override
  String get ephemeralSettingsWipeNote =>
      'ഇല്ലാതാക്കുമ്പോൾ ആപ്പ് സൂക്ഷിച്ച പകർപ്പിനെ പൂജ്യങ്ങൾ കൊണ്ട് മായ്ച്ചശേഷമാണ് നീക്കുന്നത്. ഫ്ലാഷ് സംഭരണത്തിൽ ഇത് ശക്തമായ ഒരു അധിക നടപടിയാണ്, ഉറപ്പല്ല — യഥാർത്ഥ സംരക്ഷണം Android-ന്റെ സ്വന്തം ആപ്പ് എൻക്രിപ്ഷനാണ്.';

  @override
  String get sqlMenuAction => 'SQL ചോദ്യം പ്രവർത്തിപ്പിക്കുക…';

  @override
  String get sqlQueryTitle => 'SQL ചോദ്യം';

  @override
  String get sqlQueryHint => 'SELECT * FROM data LIMIT 100';

  @override
  String get sqlRunAction => 'പ്രവർത്തിപ്പിക്കുക';

  @override
  String get sqlRunning => 'പ്രവർത്തിക്കുന്നു…';

  @override
  String get sqlLoadingData => 'വിവരങ്ങൾ ലോഡ് ചെയ്യുന്നു…';

  @override
  String get sqlTablesHeading => 'പട്ടികകൾ';

  @override
  String sqlTableSummary(int rows, int columns) {
    return '$rows വരികൾ · $columns നിരകൾ';
  }

  @override
  String sqlColumnRenamed(String original) {
    return 'മുമ്പ് “$original”';
  }

  @override
  String get sqlColumnBlankName => '(ശൂന്യം)';

  @override
  String sqlRowsCapped(int count) {
    return 'ഈ ഫയലിലെ ആദ്യത്തെ $count വരികൾ മാത്രമാണ് ലോഡ് ചെയ്തത്.';
  }

  @override
  String get sqlAddTable => 'പട്ടിക ചേർക്കുക';

  @override
  String get sqlAddTableTitle => 'തുറന്നിരിക്കുന്ന മറ്റൊരു രേഖ ചേർക്കുക';

  @override
  String get sqlAddTableEmpty =>
      'മറ്റൊരു CSV അല്ലെങ്കിൽ JSON ടാബ് തുറന്നിട്ടില്ല.';

  @override
  String sqlAddTableFailed(String name) {
    return '$name എന്നതിൽ പട്ടികയായി ലോഡ് ചെയ്യാൻ ഒന്നുമില്ല.';
  }

  @override
  String sqlTableAdded(String name, String table) {
    return '$name ഇപ്പോൾ $table എന്ന പട്ടികയാണ്.';
  }

  @override
  String get sqlRemoveTable => 'നീക്കുക';

  @override
  String get sqlPresetsHeading => 'തുടങ്ങാനുള്ള ചോദ്യങ്ങൾ';

  @override
  String get sqlPresetSelectAll => 'ആദ്യ വരികൾ കാണിക്കുക';

  @override
  String get sqlPresetCountRows => 'വരികൾ എണ്ണുക';

  @override
  String get sqlPresetGroupCount => 'ഗ്രൂപ്പ് ചെയ്ത് ആകെ കണക്കാക്കുക';

  @override
  String get sqlPresetOrderBy => 'വലിയ മൂല്യങ്ങൾ ആദ്യം';

  @override
  String get sqlPresetJoin => 'രണ്ട് പട്ടികകൾ ചേർക്കുക';

  @override
  String sqlResultSummary(int rows, int ms) {
    return '$rows വരികൾ, $ms മില്ലിസെക്കൻഡിൽ';
  }

  @override
  String sqlResultTruncated(int count) {
    return 'ഫലത്തിലെ ആദ്യത്തെ $count വരികൾ കാണിക്കുന്നു.';
  }

  @override
  String get sqlResultEmpty =>
      'ചോദ്യം പ്രവർത്തിച്ചു, പക്ഷേ ഒരു വരിയും ചേർന്നില്ല.';

  @override
  String get sqlResultPlaceholder =>
      'ഒരു ചോദ്യം എഴുതി പ്രവർത്തിപ്പിക്കുക, അല്ലെങ്കിൽ തുടങ്ങാനുള്ള ഒരു ചോദ്യം തിരഞ്ഞെടുക്കുക.';

  @override
  String get sqlCopyResult => 'ഫലം CSV ആയി പകർത്തുക';

  @override
  String get sqlCopiedResult => 'ഫലം CSV ആയി പകർത്തി';

  @override
  String get sqlSaveResult => 'ഫലം CSV ഫയലായി സംരക്ഷിക്കുക…';

  @override
  String sqlSavedResult(String name) {
    return '$name സംരക്ഷിച്ചു';
  }

  @override
  String get sqlNoResultYet => 'സംരക്ഷിക്കാൻ ഇതുവരെ ഫലമില്ല.';

  @override
  String get sqlReloadData => 'വിവരങ്ങൾ വീണ്ടും എടുക്കുക';

  @override
  String get sqlReloadedData =>
      'തുറന്ന രേഖകളിൽ നിന്ന് വിവരങ്ങൾ വീണ്ടും എടുത്തു.';

  @override
  String get sqlSnapshotNote =>
      'ഈ സ്ക്രീൻ തുറന്നപ്പോൾ എടുത്ത പകർപ്പിലാണ് ചോദ്യങ്ങൾ പ്രവർത്തിക്കുന്നത്. രേഖ തിരുത്തിയ ശേഷം വീണ്ടും എടുക്കുക.';

  @override
  String get sqlNoData => 'ഈ രേഖയിൽ പട്ടികയായി ചോദിക്കാവുന്ന ഒന്നുമില്ല.';

  @override
  String get sqlLoadFailed => 'ചോദ്യത്തിനായി വിവരങ്ങൾ ലോഡ് ചെയ്യാനായില്ല.';

  @override
  String get sqlErrorEmpty => 'ആദ്യം ഒരു ചോദ്യം എഴുതുക.';

  @override
  String get sqlErrorNotSelect =>
      'SELECT അല്ലെങ്കിൽ WITH കൊണ്ട് തുടങ്ങുന്ന ചോദ്യം മാത്രമേ ഇവിടെ പ്രവർത്തിക്കൂ.';

  @override
  String get sqlErrorMultiple => 'ഒരു പ്രസ്താവന മാത്രം എഴുതുക.';

  @override
  String sqlErrorForbidden(String keyword) {
    return '“$keyword” അനുവദനീയമല്ല — ഈ സ്ക്രീൻ വിവരങ്ങൾ വായിക്കുക മാത്രമേ ചെയ്യൂ.';
  }

  @override
  String get sqlReadOnlyNote =>
      'ഇത് നിങ്ങളുടെ വിവരങ്ങളുടെ വായന-മാത്രം പകർപ്പാണ്. ഒരു ചോദ്യത്തിനും നിങ്ങളുടെ ഫയൽ മാറ്റാനോ ഇല്ലാതാക്കാനോ കഴിയില്ല.';

  @override
  String get auditSectionTitle => 'ഓഡിറ്റ് ലോഗ്';

  @override
  String get auditCardSubtitle => 'പ്രവർത്തനങ്ങളുടെ SHA-256 ചെയിൻ ലോഗ്';

  @override
  String get auditEnableTitle => 'ഓഡിറ്റ് ലോഗ് രേഖപ്പെടുത്തുക';

  @override
  String get auditEnableSubtitle =>
      'രേഖകൾ തിരുത്തൽ, എക്സ്പോർട്ട്, സിങ്ക്, സുരക്ഷാ മാറ്റങ്ങൾ എന്നിവയുടെ ഹാഷ് സൂക്ഷിക്കുന്നു.';

  @override
  String get auditChainStatusLabel => 'ചെയിൻ സ്ഥിതി';

  @override
  String get auditViewLogTitle => 'ഓഡിറ്റ് ലോഗ് കാണുക';

  @override
  String auditEntryCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count രേഖകളുണ്ട്',
      one: '1 രേഖയുണ്ട്',
      zero: 'രേഖകളൊന്നുമില്ല',
    );
    return '$_temp0';
  }

  @override
  String get auditLogTitle => 'ഓഡിറ്റ് ലോഗ്';

  @override
  String get auditVerifyAction => 'പരിശോധിക്കുക';

  @override
  String get auditExportAction => 'സർട്ടിഫിക്കറ്റ് എക്സ്പോർട്ട് ചെയ്യുക';

  @override
  String get auditExportSubject => 'TextData ഓഡിറ്റ് സർട്ടിഫിക്കറ്റ്';

  @override
  String get auditExportFailed => 'ഓഡിറ്റ് സർട്ടിഫിക്കറ്റ് തയ്യാറാക്കാനായില്ല.';

  @override
  String get auditClearAction => 'ഓഡിറ്റ് ലോഗ് മായ്ക്കുക';

  @override
  String get auditClearSubtitle =>
      'എല്ലാ രേഖകളും മായ്ച്ച് ചെയിൻ വീണ്ടും തുടങ്ങുന്നു.';

  @override
  String get auditClearTitle => 'ഓഡിറ്റ് ലോഗ് മായ്ക്കണമോ?';

  @override
  String get auditClearConfirmation =>
      'ഇത് എല്ലാ ഓഡിറ്റ് രേഖകളും മായ്ക്കും. ക്രിപ്റ്റോഗ്രാഫിക് ചെയിൻ പുതിയൊരു തുടക്കത്തിൽ നിന്ന് വീണ്ടും ആരംഭിക്കും.';

  @override
  String get auditClearSuccess => 'ഓഡിറ്റ് ലോഗ് മായ്ച്ചു.';

  @override
  String get auditEmptyState => 'ഓഡിറ്റ് രേഖകളൊന്നും രേഖപ്പെടുത്തിയിട്ടില്ല.';

  @override
  String get auditBadgeVerified => 'പരിശോധിച്ച് ഉറപ്പാക്കി';

  @override
  String get auditBadgeCorrupted => 'ചെയിൻ തകരാറിലാണ്';

  @override
  String get auditBadgeEmpty => 'ശൂന്യമാണ്';

  @override
  String get auditBadgeVerifying => 'പരിശോധിക്കുന്നു…';

  @override
  String get auditBadgeError => 'പരിശോധന പരാജയപ്പെട്ടു';

  @override
  String auditChainVerifiedBanner(int count) {
    return 'മാറ്റമില്ലാത്ത ചെയിൻ ഉറപ്പാക്കി ($count രേഖകൾ)';
  }

  @override
  String auditChainCorruptedBanner(int index) {
    return '#$index-ാമത്തെ രേഖയിൽ ചെയിൻ തകരാറിലാണ്';
  }

  @override
  String get auditChainEmptyBanner => 'പരിശോധിക്കാൻ ഓഡിറ്റ് രേഖകളൊന്നുമില്ല.';

  @override
  String get backupSectionTitle => 'ബാക്കപ്പും പുനഃസ്ഥാപനവും';

  @override
  String get backupCardSubtitle => 'എൻക്രിപ്റ്റ് ചെയ്ത ബാക്കപ്പ് ഫയൽ (.txdata)';

  @override
  String get backupSectionDescription =>
      'നിങ്ങളുടെ ഫയലുകൾ, സമീപകാല ഫയലുകൾ, പ്രിയപ്പെട്ടവ, ബുക്ക്മാർക്കുകൾ, ക്രമീകരണങ്ങൾ എന്നിവ ഒറ്റ AES-256 .txdata ഫയലായി ബാക്കപ്പ് ചെയ്യുക അല്ലെങ്കിൽ പുനഃസ്ഥാപിക്കുക.';

  @override
  String get backupManageTitle => 'ബാക്കപ്പ് മാനേജർ';

  @override
  String get backupManageSubtitle =>
      'പാസ്‌വേഡ് സുരക്ഷിതമായ ബാക്കപ്പ് ഉണ്ടാക്കുക അല്ലെങ്കിൽ .txdata ഫയലിൽ നിന്ന് പുനഃസ്ഥാപിക്കുക.';

  @override
  String get backupZeroKnowledgeNote =>
      'പൂർണ്ണ സുരക്ഷ: PBKDF2-HMAC-SHA256 (200,000 ആവർത്തനങ്ങൾ), AES-256-GCM ഉപയോഗിച്ചാണ് ബാക്കപ്പ് എൻക്രിപ്റ്റ് ചെയ്യുന്നത്. നിങ്ങളുടെ പാസ്‌വേഡ് എവിടെയും സൂക്ഷിക്കുന്നില്ല. പാസ്‌വേഡ് മറന്നുപോയാൽ ബാക്കപ്പ് വീണ്ടെടുക്കാൻ കഴിയില്ല.';

  @override
  String get backupScreenTitle => 'ബാക്കപ്പും പുനഃസ്ഥാപനവും (.txdata)';

  @override
  String get backupHeroTitle => 'സുരക്ഷിത ബാക്കപ്പ് ആർക്കൈവുകൾ';

  @override
  String get backupHeroBody =>
      'നിങ്ങളുടെ ആപ്പ് വിവരങ്ങളും ക്രമീകരണങ്ങളും പാസ്‌വേഡ് സുരക്ഷിതമായ AES-256 ഫയലായി സൂക്ഷിക്കുക. പൂർണ്ണമായും ഓഫ്‌ലൈനാണ്.';

  @override
  String get backupExportCardTitle => 'ബാക്കപ്പ് നിർമ്മിക്കുക';

  @override
  String get backupExportCardBody =>
      'ആവശ്യമുള്ള വിവരങ്ങൾ തിരഞ്ഞെടുത്ത് പാസ്‌വേഡ് നൽകി .txdata ഫയലായി മാറ്റുക.';

  @override
  String get backupExportButton => 'ബാക്കപ്പ് നിർമ്മിക്കുക (.txdata)';

  @override
  String get backupRestoreCardTitle => 'ബാക്കപ്പിൽ നിന്ന് പുനഃസ്ഥാപിക്കുക';

  @override
  String get backupRestoreCardBody =>
      'ഒരു .txdata ഫയൽ തുറന്ന്, പാസ്‌വേഡ് നൽകി വിവരങ്ങൾ ആപ്പിലേക്ക് തിരികെ എടുക്കുക.';

  @override
  String get backupRestoreButton => 'ബാക്കപ്പ് ഫയൽ തിരഞ്ഞെടുക്കുക (.txdata)';

  @override
  String get backupSaveToDevice => 'ഫോണിൽ സേവ് ചെയ്യുക';

  @override
  String get backupShareArchive => 'ബാക്കപ്പ് ഫയൽ പങ്കിടുക';

  @override
  String backupExportSaved(String fileName) {
    return 'ബാക്കപ്പ് $fileName ആയി സേവ് ചെയ്തു';
  }

  @override
  String get backupExportError => 'ബാക്കപ്പ് നിർമ്മാണം പരാജയപ്പെട്ടു';

  @override
  String get backupRestoreError => 'ബാക്കപ്പ് പുനഃസ്ഥാപനം പരാജയപ്പെട്ടു';

  @override
  String get backupUnlockFailedTitle => 'ബാക്കപ്പ് തുറക്കാനായില്ല';

  @override
  String backupRestoreSuccessSummary(
    int recents,
    int favorites,
    int bookmarks,
    int settings,
  ) {
    return '$recents സമീപകാല ഫയലുകൾ, $favorites പ്രിയപ്പെട്ടവ, $bookmarks ബുക്ക്മാർക്കുകൾ, $settings ക്രമീകരണങ്ങൾ പുനഃസ്ഥാപിച്ചു.';
  }

  @override
  String get backupExportTitle => 'ബാക്കപ്പ് നിർമ്മിക്കുക';

  @override
  String get backupExportSelectItems => 'ഉൾപ്പെടുത്തേണ്ടവ തിരഞ്ഞെടുക്കുക:';

  @override
  String get backupIncludeRecents => 'സമീപകാല ഫയലുകളുടെ ചരിത്രം';

  @override
  String get backupIncludeFavorites => 'പ്രിയപ്പെട്ട ഫയലുകൾ';

  @override
  String get backupIncludeBookmarks => 'ബുക്ക്മാർക്കുകൾ';

  @override
  String get backupIncludeSettings => 'ആപ്പ് ക്രമീകരണങ്ങൾ';

  @override
  String backupIncludeFiles(int count) {
    return 'തുറന്ന രേഖകൾ ($count എണ്ണം)';
  }

  @override
  String get backupPasswordHeader => 'എൻക്രിപ്ഷൻ പാസ്‌വേഡ്:';

  @override
  String get backupPasswordLabel => 'പാസ്‌വേഡ്';

  @override
  String get backupConfirmPasswordLabel => 'പാസ്‌വേഡ് സ്ഥിരീകരിക്കുക';

  @override
  String get backupPasswordTooShort => 'പാസ്‌വേഡിന് കുറഞ്ഞത് 6 അക്ഷരങ്ങൾ വേണം.';

  @override
  String get backupPasswordsDoNotMatch => 'പാസ്‌വേഡുകൾ പൊരുത്തപ്പെടുന്നില്ല.';

  @override
  String get backupPasswordWarning =>
      'ഈ പാസ്‌വേഡ് ഓർത്തു വെയ്ക്കുക. മറന്നുപോയാൽ ബാക്കപ്പ് ഫയൽ തുറക്കാൻ കഴിയില്ല.';

  @override
  String get backupCreateAction => 'ബാക്കപ്പ് ഉണ്ടാക്കുക';

  @override
  String get backupEnterPasswordTitle => 'ബാക്കപ്പ് അൺലോക്ക് ചെയ്യുക';

  @override
  String get backupEnterPasswordPrompt => 'ഈ .txdata ഫയലിന്റെ പാസ്‌വേഡ് നൽകുക:';

  @override
  String get backupUnlockAction => 'തുറക്കുക';

  @override
  String get backupRestoreTitle => 'ബാക്കപ്പ് പുനഃസ്ഥാപിക്കുക';

  @override
  String backupCreatedOn(String date) {
    return 'ബാക്കപ്പ് നിർമ്മിച്ച തീയതി: $date';
  }

  @override
  String get backupSelectRestoreItems => 'പുനഃസ്ഥാപിക്കേണ്ടവ തിരഞ്ഞെടുക്കുക:';

  @override
  String backupRecentsCount(int count) {
    return 'സമീപകാല ഫയലുകൾ ($count എണ്ണം)';
  }

  @override
  String backupFavoritesCount(int count) {
    return 'പ്രിയപ്പെട്ടവ ($count എണ്ണം)';
  }

  @override
  String backupBookmarksCount(int count) {
    return 'ബുക്ക്മാർക്കുകൾ ($count എണ്ണം)';
  }

  @override
  String backupSettingsCount(int count) {
    return 'ആപ്പ് ക്രമീകരണങ്ങൾ ($count എണ്ണം)';
  }

  @override
  String backupFilesCount(int count) {
    return 'രേഖകൾ ($count എണ്ണം)';
  }

  @override
  String get backupMergeModeTitle => 'നിലവിലുള്ള വിവരങ്ങളിലേക്ക് ചേർക്കുക';

  @override
  String get backupMergeModeSubtitle =>
      'നിലവിലുള്ളവ നിലനിർത്തി പുതിയവ ചേർക്കുന്നു.';

  @override
  String get backupReplaceModeSubtitle =>
      'നിലവിലുള്ളവ മാറ്റി ബാക്കപ്പിലെ വിവരങ്ങൾ മാത്രം നൽകുന്നു.';

  @override
  String get backupRestoreAction => 'പുനഃസ്ഥാപിക്കുക';

  @override
  String get vaultTitle => 'ബയോമെട്രിക് വോൾട്ട്';

  @override
  String get vaultLockAction => 'ബയോമെട്രിക് വോൾട്ടിൽ പൂട്ടുക';

  @override
  String get vaultUnlockAction => 'ഡോക്യുമെന്റ് തുറക്കുക';

  @override
  String get p2pFileTransferTitle => 'രേഖകൾ കൈമാറുക';

  @override
  String get columnSelectionTitle => 'കോളം & മൾട്ടി-കർസർ എഡിറ്റ്';

  @override
  String get columnSelectionAction => 'കോളം / മൾട്ടി-കർസർ';

  @override
  String columnSelectionLines(int start, int end, int count) {
    return 'വരികൾ $start മുതൽ $end വരെ ($count വരികൾ)';
  }

  @override
  String get columnSelectionStartLine => 'തുടക്ക വരി';

  @override
  String get columnSelectionEndLine => 'അവസാന വരി';

  @override
  String get columnSelectionAllLines => 'മുഴുവൻ വരികളും';

  @override
  String get columnSelectionCurrentLines => 'തിരഞ്ഞെടുത്തവ';

  @override
  String get columnModePrefixSuffix => 'പ്രിഫിക്‌സ് / സഫിക്‌സ്';

  @override
  String get columnModeBlock => 'കോളം ബ്ലോക്ക്';

  @override
  String get columnModeInsertAtCol => 'കോളത്തിൽ ചേർക്കുക';

  @override
  String get columnModeNumbering => 'നമ്പറിംഗ്';

  @override
  String get columnPrefixLabel => 'പ്രിഫിക്‌സ് (വരിയുടെ തുടക്കത്തിൽ)';

  @override
  String get columnSuffixLabel => 'സഫിക്‌സ് (വരിയുടെ ഒടുവിൽ)';

  @override
  String get columnStartColLabel => 'തുടക്ക കോളം';

  @override
  String get columnEndColLabel => 'അവസാന കോളം';

  @override
  String get columnInsertColLabel => 'കോളം നമ്പർ';

  @override
  String get columnInsertTextLabel => 'ചേർക്കേണ്ട ടെക്സ്റ്റ്';

  @override
  String get columnPadShorterLines => 'ചെറിയ വരികളിൽ സ്‌പേസ് ചേർക്കുക';

  @override
  String get columnNumberStart => 'തുടക്ക നമ്പർ';

  @override
  String get columnNumberStep => 'സ്റ്റെപ്പ്';

  @override
  String get columnNumberFormat => 'ഫോർമാറ്റ് (%d)';

  @override
  String get columnNumberPadding => 'പൂജ്യങ്ങൾ ചേർക്കുക';

  @override
  String get columnLivePreview => 'തത്സമയ പ്രിവ്യൂ';

  @override
  String get columnApplyAction => 'മാറ്റങ്ങൾ വരുത്തുക';

  @override
  String get columnCopyBlockAction => 'ബ്ലോക്ക് കോപ്പി ചെയ്യുക';

  @override
  String get columnCutBlockAction => 'ബ്ലോക്ക് കട്ട് ചെയ്യുക';

  @override
  String get columnDeleteBlockAction => 'ബ്ലോക്ക് മായ്ക്കുക';

  @override
  String get columnBlockCopied =>
      'കോളം ബ്ലോക്ക് ക്ലിപ്പ്ബോർഡിലേക്ക് കോപ്പി ചെയ്തു';

  @override
  String columnEditsApplied(int count) {
    return '$count വരികളിൽ മാറ്റങ്ങൾ വരുത്തി';
  }

  @override
  String get columnTrimWhitespace => 'സ്‌പേസ് ഒഴിവാക്കുക';

  @override
  String get privacyShieldTitle => 'ഓഫ്‌ലൈൻ പ്രൈവസി ഷീൽഡ്';

  @override
  String get privacyShieldSubtitle => 'രഹസ്യ വിവരങ്ങളും PII-യും കണ്ടെത്തുന്നു';

  @override
  String get privacyShieldAction => 'പ്രൈവസി ഷീൽഡ് & സ്ക്രബ്ബിംഗ്';

  @override
  String get privacyModeRedact => 'മറയ്ക്കുക (Redact)';

  @override
  String get privacyModeHash => 'ഹാഷ് ചെയ്യുക (Hash)';

  @override
  String get privacyModeAnonymize => 'അജ്ഞാതമാക്കുക (Anonymize)';

  @override
  String get privacySelectAll => 'എല്ലാം തിരഞ്ഞെടുക്കുക';

  @override
  String get privacyTabDetections => 'കണ്ടെത്തിയവ';

  @override
  String get privacyTabPreview => 'പൂർണ്ണ പ്രിവ്യൂ';

  @override
  String get privacyCleanTitle => 'രഹസ്യ വിവരങ്ങളൊന്നും കണ്ടെത്തിയില്ല';

  @override
  String get privacyCleanDescription =>
      'ഈ ഫയലിൽ ഇമെയിൽ, ഫോൺ നമ്പർ, കാർഡ് വിവരങ്ങൾ, ഐപി വിലാസങ്ങൾ എന്നിവയൊന്നും ഇല്ല.';

  @override
  String get privacyApplyToBuffer => 'രേഖയിൽ മാറ്റുക';

  @override
  String get privacyShareScrubbed => 'മറച്ച കോപ്പി പങ്കിടുക';

  @override
  String get privacyExportScrubbed => 'മറച്ച കോപ്പി സേവ് ചെയ്യുക';

  @override
  String get privacyShareFailed => 'ഡോക്യുമെന്റ് പങ്കിടാൻ കഴിഞ്ഞില്ല.';

  @override
  String get liveDiffTitle => 'തത്സമയ ഡിഫ് & ഡെൽറ്റ സമന്വയം';

  @override
  String get liveDiffAction => 'തത്സമയ P2P ഡിഫ് & സമന്വയം';

  @override
  String get liveDiffAutoMerge => 'ഓട്ടോ-മെർജ്ജ്';

  @override
  String get liveDiffAcceptMine => 'എന്റേത് സ്വീകരിക്കുക';

  @override
  String get liveDiffAcceptPeer => 'മറുഭാഗത്തിന്റേത് സ്വീകരിക്കുക';

  @override
  String get liveDiffSideBySide => 'വശങ്ങളിലായി കാണുക';

  @override
  String get liveDiffUnified => 'ഒരുമിച്ചു കാണുക';

  @override
  String get liveDiffPreview => 'പ്രിവ്യൂ';

  @override
  String get liveDiffPushToPeer => 'മറുഭാഗത്തേക്ക് അയക്കുക';

  @override
  String get liveDiffSaveMerged => 'യോജിപ്പിച്ച ഫയൽ സേവ് ചെയ്യുക';
}
