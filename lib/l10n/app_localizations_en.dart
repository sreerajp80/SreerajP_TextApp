// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'TextData';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionSave => 'Save';

  @override
  String get actionOk => 'OK';

  @override
  String get actionCopy => 'Copy';

  @override
  String get actionRemove => 'Remove';

  @override
  String get actionClearAll => 'Clear all';

  @override
  String get actionContinue => 'Continue';

  @override
  String get actionOpenFile => 'Open a file';

  @override
  String get actionNewDocument => 'New document';

  @override
  String get newDocumentChooseFormat => 'Choose a document type';

  @override
  String get newDocumentTxt => 'Text (TXT)';

  @override
  String get newDocumentMarkdown => 'Markdown (MD)';

  @override
  String get newDocumentCsv => 'Table (CSV)';

  @override
  String get newDocumentJson => 'Data (JSON)';

  @override
  String get newDocumentXml => 'Data (XML)';

  @override
  String get actionUndo => 'Undo';

  @override
  String get actionRedo => 'Redo';

  @override
  String get actionFind => 'Find';

  @override
  String get actionFindReplace => 'Find & replace';

  @override
  String get actionShare => 'Share';

  @override
  String get actionShareZip => 'Share as zip';

  @override
  String get actionPrint => 'Print';

  @override
  String get actionExport => 'Export…';

  @override
  String get actionFileInfo => 'File info';

  @override
  String get actionGo => 'Go';

  @override
  String get actionSaveAsCopy => 'Save as a copy';

  @override
  String get actionSaveAs => 'Save as…';

  @override
  String get actionRestore => 'Restore';

  @override
  String get actionDiscard => 'Discard';

  @override
  String get actionRetry => 'Retry';

  @override
  String get draftBannerText =>
      'Unsaved changes from a previous session were found.';

  @override
  String get failCantOpenTitle => 'Can\'t open this file';

  @override
  String get failCannotOpen => 'This file could not be opened.';

  @override
  String get readAloud => 'Read aloud';

  @override
  String get readAloudStop => 'Stop reading';

  @override
  String get readAloudUnavailable => 'Read aloud is not available right now.';

  @override
  String get actionSplit => 'Split';

  @override
  String get actionNext => 'Next';

  @override
  String splitStopped(int done, int total) {
    return 'Stopped after saving $done of $total parts.';
  }

  @override
  String splitSaved(int count) {
    return 'Saved $count parts.';
  }

  @override
  String mergedReview(String name) {
    return 'Merged $name. Review and save.';
  }

  @override
  String get labelEncoding => 'Encoding';

  @override
  String get labelLineEnding => 'Line ending';

  @override
  String get labelDelimiter => 'Delimiter';

  @override
  String get commonYes => 'Yes';

  @override
  String get commonNo => 'No';

  @override
  String get infoSize => 'Size';

  @override
  String get infoModified => 'Modified';

  @override
  String get infoTitle => 'File info';

  @override
  String get saveOptionsTitle => 'Save options';

  @override
  String get saveDone => 'Saved.';

  @override
  String saveCopyDone(String name) {
    return 'Saved a copy: $name.';
  }

  @override
  String get saveNewFile => 'new file';

  @override
  String get saveCouldNot => 'Could not save.';

  @override
  String get saveReadOnly => 'This file is read-only.';

  @override
  String get saveFailed => 'Could not save the file.';

  @override
  String get exportSheetTitle => 'Export';

  @override
  String get exportAsTitle => 'Export as';

  @override
  String get exportAllRows => 'All rows';

  @override
  String get exportFilteredRows => 'Filtered';

  @override
  String get exportSelectedRows => 'Selected';

  @override
  String exportCreated(String name) {
    return 'Created $name';
  }

  @override
  String get exportSaveCopy => 'Save a copy';

  @override
  String get outShareFileFailed => 'Could not share the file.';

  @override
  String get outShareZipFailed => 'Could not share the zip.';

  @override
  String get outPrintFailed => 'Could not print the file.';

  @override
  String get outExportFailed => 'Could not create the export.';

  @override
  String get outShareExportFailed => 'Could not share the export.';

  @override
  String outSaved(String name) {
    return 'Saved $name.';
  }

  @override
  String get homeTitle => 'Recent files';

  @override
  String get homeEmptyTitle => 'No recent files';

  @override
  String get homeClearAllTitle => 'Clear recent files?';

  @override
  String get homeClearAllBody =>
      'This removes the list only. Your files are not deleted.';

  @override
  String get homeUnavailable =>
      'Unavailable — file moved, deleted, or access revoked';

  @override
  String get homeClearConfirm => 'Clear';

  @override
  String get homeRemoveTooltip => 'Remove';

  @override
  String get homeClearAllTooltip => 'Clear all';

  @override
  String get homeEmptyBody =>
      'Open a text or data file to get started. It will show up here next time.';

  @override
  String get homeLoadError => 'Could not load recent files';

  @override
  String get navHome => 'Home';

  @override
  String get navEditor => 'Editor';

  @override
  String get navSettings => 'Settings';

  @override
  String get tabClose => 'Close';

  @override
  String get tabCloseOthers => 'Close others';

  @override
  String get tabCloseAll => 'Close all';

  @override
  String get tabNoDocuments => 'No open documents';

  @override
  String get tabOpenFromHome => 'Open a file from Home to start.';

  @override
  String get tabCouldNotSave => 'Could not save; tab kept open.';

  @override
  String get unsavedTitle => 'Save changes?';

  @override
  String unsavedBody(String fileName) {
    return '\"$fileName\" has unsaved changes. What would you like to do?';
  }

  @override
  String get unsavedKeepEditing => 'Keep editing';

  @override
  String get degradedPrevPage => 'Previous page';

  @override
  String get degradedNextPage => 'Next page';

  @override
  String get degradedPageLabel => 'Page';

  @override
  String degradedOfCount(int count) {
    return 'of $count';
  }

  @override
  String get degradedLargeBanner =>
      'This file is large. It is open in read-only mode; editing is turned off.';

  @override
  String get degradedTryAgain => 'Try again';

  @override
  String get placeholderComingSoon =>
      'The viewer for this file type is coming in a later phase.';

  @override
  String get placeholderOpenedFile => 'Opened file';

  @override
  String get overwriteTitle => 'Overwrite the file?';

  @override
  String get overwriteBody =>
      'This replaces the original file with your changes. You can turn off this check in Settings › Editor.';

  @override
  String get overwriteConfirm => 'Overwrite';

  @override
  String shellTabsSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count saved tabs could not be reopened (file moved, deleted, or access revoked).',
      one:
          '1 saved tab could not be reopened (file moved, deleted, or access revoked).',
    );
    return '$_temp0';
  }

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingGetStarted => 'Get started';

  @override
  String get onboarding1Title => 'Read and edit your files';

  @override
  String get onboarding1Body =>
      'Open TXT, Markdown, CSV, JSON, and XML files — view them, edit them, and save changes back safely.';

  @override
  String get onboarding2Title => 'Private and offline';

  @override
  String get onboarding2Body =>
      'Everything works offline. Files open only through the system picker, so the app never browses your storage on its own.';

  @override
  String get onboarding3Title => 'Share across devices';

  @override
  String get onboarding3Body =>
      'Move your app data between two devices on the same Wi-Fi — no server and no internet needed.';

  @override
  String get securitySectionTitle => 'Security';

  @override
  String get securityCardSubtitle => 'Protect app access and private data.';

  @override
  String get securityAppLockTitle => 'App lock';

  @override
  String get securityAppLockSubtitle =>
      'Require a PIN (or biometric) to open the app.';

  @override
  String get securityChangePin => 'Change PIN';

  @override
  String get securityShowNewRecovery => 'Show a new recovery code';

  @override
  String get securityShowNewRecoverySubtitle =>
      'Replaces the old one. Use if you lost your recovery code.';

  @override
  String get securityBiometricTitle => 'Biometric unlock';

  @override
  String get securityBiometricSubtitle =>
      'Use fingerprint or face to unlock, when the device supports it.';

  @override
  String get securityScreenshotTitle =>
      'Block screenshots on the pairing screen';

  @override
  String get securityScreenshotSubtitle =>
      'Hides the app from screenshots and screen recording. The pairing code / QR screen is always protected.';

  @override
  String get securitySetPinTitle => 'Set an app-lock PIN';

  @override
  String get securitySetPinSubtitle =>
      'You will need this PIN to open the app.';

  @override
  String get securityTurnOffTitle => 'Turn off app lock?';

  @override
  String get securityTurnOffBody =>
      'This removes your PIN and recovery code. The app will open without unlocking.';

  @override
  String get securityTurnOff => 'Turn off';

  @override
  String get securityPinChanged => 'PIN changed';

  @override
  String get lockEnterPin => 'Enter your PIN';

  @override
  String get lockPinLabel => 'PIN';

  @override
  String get lockUnlock => 'Unlock';

  @override
  String get lockUseBiometric => 'Use biometric';

  @override
  String get lockForgotPin => 'Forgot PIN?';

  @override
  String get lockWrongPin => 'Wrong PIN. Try again.';

  @override
  String get lockEnterRecoveryTitle => 'Enter recovery code';

  @override
  String get lockRecoveryHint => 'ABCD-EFGH-JKMN';

  @override
  String get lockRecoveryWrong => 'That recovery code is not correct.';

  @override
  String get lockSetNewPinTitle => 'Set a new PIN';

  @override
  String get lockSetNewPinSubtitle =>
      'Your recovery code was accepted. Choose a new PIN.';

  @override
  String get lockBiometricReason => 'Unlock TextData';

  @override
  String get setPinTitle => 'Set a PIN';

  @override
  String get setPinSubtitle => 'Choose a PIN of at least 4 digits.';

  @override
  String get setPinConfirmLabel => 'Confirm PIN';

  @override
  String get setPinSave => 'Save PIN';

  @override
  String setPinTooShort(int min) {
    return 'Use at least $min digits.';
  }

  @override
  String get setPinMismatch => 'The two PINs do not match.';

  @override
  String get recoveryTitle => 'Save your recovery code';

  @override
  String get recoveryBody =>
      'If you forget your PIN, this recovery code is the only way back in. Write it down and keep it somewhere safe. It is shown only once.';

  @override
  String get recoveryCopied => 'Recovery code copied';

  @override
  String get recoverySaved => 'I have saved it';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get appearSectionTitle => 'Appearance';

  @override
  String get appearCardSubtitle => 'Theme, text size, font, and line spacing.';

  @override
  String get appearTheme => 'Theme';

  @override
  String get appearFontSize => 'Font size';

  @override
  String get appearFontFamily => 'Font family';

  @override
  String get appearMalayalamFontFamily => 'Malayalam font';

  @override
  String get appearLineSpacing => 'Line spacing';

  @override
  String get appearWordWrapTitle => 'Word wrap';

  @override
  String get appearWordWrapSubtitle =>
      'Wrap long lines by default in text files.';

  @override
  String get appearLanguage => 'Language';

  @override
  String get languageSystem => 'System';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageMalayalam => 'Malayalam';

  @override
  String get editorSectionTitle => 'Editor';

  @override
  String get editorCardSubtitle =>
      'Saving, line endings, and editing defaults.';

  @override
  String get editorDefaultEncoding => 'Default encoding on save';

  @override
  String get editorPreserveEncoding =>
      'Preserve keeps the file’s own encoding.';

  @override
  String get editorDefaultLineEnding => 'Default line ending on save';

  @override
  String get editorPreserveLineEnding =>
      'Preserve keeps the file’s own line ending.';

  @override
  String get editorConfirmOverwrite => 'Confirm before overwriting';

  @override
  String get editorConfirmOverwriteSub =>
      'Ask before replacing the original file when you save.';

  @override
  String get editorOpenReadOnly => 'Open files read-only by default';

  @override
  String get editorOpenReadOnlySub => 'New tabs start locked; unlock to edit.';

  @override
  String get editorAutoSaveLabel => 'Auto-save draft every';

  @override
  String get editorAutoSaveOff => 'Off';

  @override
  String editorAutoSaveValue(int seconds) {
    return '$seconds s';
  }

  @override
  String get filesTabsSectionTitle => 'Files & Tabs';

  @override
  String get filesTabsCardSubtitle => 'Tab limits and restore behavior.';

  @override
  String get filesAuto => 'Auto';

  @override
  String filesAutoCap(int cap) {
    String _temp0 = intl.Intl.pluralLogic(
      cap,
      locale: localeName,
      other: 'Auto — $cap tabs',
      one: 'Auto — 1 tab',
    );
    return '$_temp0';
  }

  @override
  String get filesAutoLimit => 'Automatic tab limit';

  @override
  String filesChosenFromMemory(String label) {
    return 'Chosen from device memory ($label).';
  }

  @override
  String get filesUsingFixed => 'Using a fixed limit.';

  @override
  String get filesMaxOpenTabs => 'Maximum open tabs';

  @override
  String get filesWhenLimitReached => 'When the limit is reached';

  @override
  String get filesRestoreOnRelaunch => 'Restore tabs on relaunch';

  @override
  String get filesRestoreSub =>
      'Reopen the files you had open when the app starts again.';

  @override
  String get speechSectionTitle => 'Speech (read aloud)';

  @override
  String get speechCardSubtitle => 'Languages and text-to-speech voices.';

  @override
  String get speechEnglish => 'English';

  @override
  String get speechEnglishSub => 'Read content aloud in English.';

  @override
  String get speechMalayalam => 'Malayalam';

  @override
  String get speechMalayalamSub =>
      'Needs the Malayalam voice installed on this device.';

  @override
  String get speechChecking => 'Checking the Malayalam voice…';

  @override
  String get speechMlReady => 'The Malayalam voice is ready.';

  @override
  String get speechMlNeedsInstall =>
      'The Malayalam voice is not installed yet. Install the voice data, then check again.';

  @override
  String get speechInstallVoice => 'Install voice data';

  @override
  String get speechOpenTtsSettings => 'Open TTS settings';

  @override
  String get speechCheckAgain => 'Check again';

  @override
  String get speechNoEngine =>
      'No text-to-speech engine is available on this device.';

  @override
  String get speechCouldNotOpen => 'Could not open the voice-install screen.';

  @override
  String get syncSectionTitle => 'Sync';

  @override
  String get syncCardSubtitle => 'Choose what to share between devices.';

  @override
  String get syncDefaultCategories =>
      'Categories to share by default. You can still change the selection each time you send.';

  @override
  String get syncLocalNote =>
      'Sync stays on your local network. Only your display settings and the categories above are shared — never passwords, keys, or the pairing code.';

  @override
  String get syncOpenSync => 'Open sync';

  @override
  String get helpSectionTitle => 'Help';

  @override
  String get helpCardSubtitle => 'Learn how app features work.';

  @override
  String get helpSplitArrayTitle => 'Split array';

  @override
  String get helpSplitArrayBody =>
      'Split array works when the top level of a JSON file is an array. Choose how many items each part should contain. The app then creates numbered files such as name.part1.json and asks where to save each one. The last part may contain fewer items. Your original file is not changed.';

  @override
  String get aboutSectionTitle => 'About';

  @override
  String get aboutCardSubtitle => 'App version, author, and license details.';

  @override
  String get aboutLoading => 'Loading app details…';

  @override
  String get aboutUnavailable => 'App details are unavailable.';

  @override
  String get aboutVersion => 'Version';

  @override
  String aboutVersionValue(String version, String build) {
    return '$version (build $build)';
  }

  @override
  String get aboutAuthor => 'Author';

  @override
  String get aboutContact => 'Contact';

  @override
  String get aboutLicenses => 'Licenses';

  @override
  String get aboutLinkPrivacy => 'Privacy policy';

  @override
  String get aboutLinkSupport => 'Support';

  @override
  String get aboutLinkSource => 'Source code';

  @override
  String get linkCouldNotOpen => 'Could not open the link.';

  @override
  String get syncStatusWaiting => 'Waiting for a device…';

  @override
  String get syncStatusConnected => 'Device connected';

  @override
  String get syncStatusWrongCode => 'Wrong code';

  @override
  String get syncStatusError => 'Something went wrong';

  @override
  String get syncStatusStopped => 'Stopped';

  @override
  String get syncTitle => 'Sync with another device';

  @override
  String get syncIntro =>
      'Move your favorites, bookmarks, recent files, and display settings between two devices on the same Wi-Fi. No internet is used, and nothing is ever overwritten on the other device.';

  @override
  String get syncSend => 'Send';

  @override
  String get syncSendSubtitle => 'Share this device\'s data';

  @override
  String get syncReceive => 'Receive';

  @override
  String get syncReceiveSubtitle => 'Get data from another device';

  @override
  String get syncComplete => 'Sync complete';

  @override
  String syncAddedKept(int added, int kept) {
    return '$added added · $kept kept';
  }

  @override
  String syncAppliedKept(int applied, int kept) {
    return '$applied applied · $kept kept';
  }

  @override
  String get syncCatFavorites => 'Favorites';

  @override
  String get syncCatBookmarks => 'Bookmarks';

  @override
  String get syncCatRecents => 'Recent files';

  @override
  String get syncDisplaySettings => 'Display settings';

  @override
  String get syncHostTitle => 'Send to a device';

  @override
  String get syncClientTitle => 'Receive from a device';

  @override
  String syncCouldNotStart(String error) {
    return 'Could not start: $error';
  }

  @override
  String get syncTabConnection => 'Connection';

  @override
  String get syncTabWhatToShare => 'What to share';

  @override
  String get syncDataSent => 'Data sent. You can send again or stop.';

  @override
  String get syncNoWifi =>
      'No Wi-Fi address found. Connect both devices to the same Wi-Fi, then type the code, address, and port on the other device.';

  @override
  String get syncPairingCode => 'Pairing code';

  @override
  String get syncAddress => 'Address';

  @override
  String get syncPort => 'Port';

  @override
  String get syncStop => 'Stop';

  @override
  String get syncConnecting => 'Connecting…';

  @override
  String get syncConnectedWaiting =>
      'Connected — waiting for the sender to choose what to send…';

  @override
  String get syncApplying => 'Applying the received data…';

  @override
  String get syncFailedGeneric => 'The sync failed.';

  @override
  String get syncFailed => 'Sync failed';

  @override
  String get syncScanQr => 'Scan QR code';

  @override
  String get syncOrTypeDetails => 'Or type the details';

  @override
  String get syncAddressHint => 'e.g. 192.168.1.5';

  @override
  String get syncConnect => 'Connect';

  @override
  String get syncScanTitle => 'Scan the QR code';

  @override
  String get syncScanSemantics =>
      'Camera viewfinder. Point it at the pairing QR code on the other device. You can also go back and type the code instead.';

  @override
  String get syncFreshDevice => 'Fresh device';

  @override
  String get syncFreshDeviceBody =>
      'Send everything (favorites, bookmarks, recent files and display settings) to a device that has no data yet.';

  @override
  String get syncFullSync => 'Full sync';

  @override
  String get syncChooseWhatToShare => 'Choose what to share';

  @override
  String get syncWontOverride =>
      'This won\'t override anything already on the other device; on a conflict the other device keeps its data.';

  @override
  String get syncSendSelected => 'Send selected';

  @override
  String get findFind => 'Find';

  @override
  String get findReplace => 'Replace';

  @override
  String get findReplaceAll => 'Replace all';

  @override
  String get findReplaceWith => 'Replace with';

  @override
  String get findMatchCase => 'Match case';

  @override
  String get findUseRegex => 'Use regular expression';

  @override
  String get findToggleReplace => 'Toggle replace';

  @override
  String get findClose => 'Close find';

  @override
  String get findNextMatch => 'Next match';

  @override
  String get findPreviousMatch => 'Previous match';

  @override
  String get findNoResults => 'No results';

  @override
  String get txtFind => 'Find';

  @override
  String get txtReplace => 'Replace';

  @override
  String get txtReplaceAll => 'Replace all';

  @override
  String get txtReplaceWith => 'Replace with';

  @override
  String get txtMatchCase => 'Match case';

  @override
  String get txtUseRegex => 'Use regular expression';

  @override
  String get txtToggleReplace => 'Toggle replace';

  @override
  String get txtCloseFind => 'Close find';

  @override
  String get txtNextMatch => 'Next match';

  @override
  String get txtPreviousMatch => 'Previous match';

  @override
  String get txtNoResults => 'No results';

  @override
  String get txtCancel => 'Cancel';

  @override
  String get txtLinksTitle => 'Links';

  @override
  String get txtNoLinksFound => 'No links found';

  @override
  String get txtNoLinksBody => 'This file has no web links.';

  @override
  String get txtCopyLink => 'Copy link';

  @override
  String get txtOpenInBrowser => 'Open in browser';

  @override
  String get txtLinkWarningTitle => 'Open this link?';

  @override
  String get txtLinkWarningBody =>
      'This opens an external link in your browser. Only open links you trust.';

  @override
  String get txtInfoTitle => 'File information';

  @override
  String get txtInfoSize => 'Size';

  @override
  String get txtInfoModified => 'Modified';

  @override
  String get txtInfoWords => 'Words';

  @override
  String get txtInfoCharacters => 'Characters';

  @override
  String get txtInfoCharactersNoLineBreaks => 'Characters (no line breaks)';

  @override
  String get txtInfoLines => 'Lines';

  @override
  String get txtEncoding => 'Encoding';

  @override
  String get txtEncodingSheetTitle => 'Text encoding';

  @override
  String get txtLineEnding => 'Line ending';

  @override
  String get txtBinaryWarning =>
      'This file doesn\'t look like text. It is shown as-is and may appear garbled.';

  @override
  String get txtLinkCopied => 'Link copied to clipboard.';

  @override
  String get txtSplitFile => 'Split file';

  @override
  String get txtSplitByLines => 'By line count';

  @override
  String get txtSplitBySize => 'By size (KB)';

  @override
  String get txtLinesPerPart => 'Lines per part';

  @override
  String get txtKbPerPart => 'Kilobytes per part';

  @override
  String get txtSplitOnePart => 'The file is small enough to fit in one part.';

  @override
  String get txtViewMode => 'View mode';

  @override
  String get txtEditMode => 'Edit mode';

  @override
  String get txtWordWrapOn => 'Word wrap: on';

  @override
  String get txtWordWrapOff => 'Word wrap: off';

  @override
  String get txtJumpToLine => 'Jump to line';

  @override
  String get txtLineNumber => 'Line number';

  @override
  String get txtAppendFile => 'Append a file';

  @override
  String get mdShowRendered => 'Rendered';

  @override
  String get mdShowSource => 'Source';

  @override
  String get mdEdit => 'Edit';

  @override
  String get mdPreview => 'Preview';

  @override
  String get mdLivePreviewOn => 'Live preview on';

  @override
  String get mdLivePreviewOff => 'Live preview off';

  @override
  String get mdSave => 'Save';

  @override
  String get mdUndo => 'Undo';

  @override
  String get mdRedo => 'Redo';

  @override
  String get mdFind => 'Find';

  @override
  String get mdContents => 'Contents';

  @override
  String get mdDraftFound => 'Unsaved draft found';

  @override
  String get mdRestore => 'Restore';

  @override
  String get mdDiscard => 'Discard';

  @override
  String get mdCantOpenTitle => 'Cannot open this file';

  @override
  String get mdCannotOpenFile => 'This file could not be opened.';

  @override
  String get mdRetry => 'Retry';

  @override
  String get mdSplitByHeading => 'Split by heading';

  @override
  String get mdAppendFile => 'Append a file';

  @override
  String get mdBold => 'Bold';

  @override
  String get mdItalic => 'Italic';

  @override
  String get mdStrikethrough => 'Strikethrough';

  @override
  String get mdBulletList => 'Bullet list';

  @override
  String get mdNumberedList => 'Numbered list';

  @override
  String get mdTaskList => 'Task list';

  @override
  String get mdQuote => 'Quote';

  @override
  String get mdInlineCode => 'Inline code';

  @override
  String get mdCodeBlock => 'Code block';

  @override
  String get mdLink => 'Link';

  @override
  String get mdTable => 'Table';

  @override
  String get mdHeading => 'Heading';

  @override
  String get mdHeading1 => 'Heading 1';

  @override
  String get mdHeading2 => 'Heading 2';

  @override
  String get mdHeading3 => 'Heading 3';

  @override
  String get mdLinkWarningBody =>
      'This link goes online and opens outside the app. Only open links you trust.';

  @override
  String get mdNoHeadings => 'This document has no headings.';

  @override
  String get mdInfoWords => 'Words';

  @override
  String get mdInfoHeadings => 'Headings';

  @override
  String get mdInfoLinks => 'Links';

  @override
  String get mdInfoLines => 'Lines';

  @override
  String get mdInfoTitleField => 'Title';

  @override
  String get mdInfoAuthorField => 'Author';

  @override
  String get mdInfoTags => 'Tags';

  @override
  String get mdNoTopHeadings => 'No top-level headings to split on.';

  @override
  String get jsonReadAloud => 'Read aloud';

  @override
  String get jsonStopReading => 'Stop reading';

  @override
  String get jsonReadAloudUnavailable => 'Read aloud is not available';

  @override
  String get jsonViewMinified => 'Minified';

  @override
  String get jsonPathQuery => 'JSONPath query';

  @override
  String get jsonCompareFile => 'Compare with a file';

  @override
  String get jsonSplitArray => 'Split array';

  @override
  String get jsonNotValidTree =>
      'This document is not valid JSON. Open the editor to fix it.';

  @override
  String get jsonCopyValue => 'Copy value';

  @override
  String get jsonCopyJson => 'Copy JSON';

  @override
  String get jsonEditValue => 'Edit value';

  @override
  String get jsonEditKey => 'Edit key';

  @override
  String get jsonValueCopied => 'Value copied.';

  @override
  String get jsonJsonCopied => 'JSON copied.';

  @override
  String get jsonValueHint => 'A JSON value, e.g. \"text\", 42, true';

  @override
  String get jsonInvalidValue => 'That is not a valid JSON value.';

  @override
  String get jsonNewKey => 'New key';

  @override
  String get jsonMemberKeyHint => 'The member key';

  @override
  String get jsonNewValue => 'New value';

  @override
  String get jsonPathTitle => 'JSONPath';

  @override
  String get jsonPathHint => 'e.g. \$.data.users[*].name';

  @override
  String get jsonNotValidDoc => 'The document is not valid JSON.';

  @override
  String get jsonWellFormed => 'Well-formed JSON.';

  @override
  String jsonNotValidWithLine(int line, String error) {
    return 'Not valid JSON (line $line): $error';
  }

  @override
  String jsonNotValidNoLine(String error) {
    return 'Not valid JSON: $error';
  }

  @override
  String get jsonValidateAgainstSchema => 'Validate against a schema…';

  @override
  String get jsonFixErrorsFirst => 'Fix the JSON errors first.';

  @override
  String get jsonValidAgainstSchema => 'Valid against the schema.';

  @override
  String get jsonSchemaReadError => 'That schema file could not be read.';

  @override
  String jsonSchemaErrors(int count) {
    return '$count schema error(s):';
  }

  @override
  String get jsonFixBeforeCompare => 'Fix the JSON errors before comparing.';

  @override
  String get jsonOtherNotValid => 'The other file is not valid JSON.';

  @override
  String jsonDiffWith(String name) {
    return 'Diff with $name';
  }

  @override
  String get jsonIdentical => 'The two documents are identical.';

  @override
  String jsonDiffSummary(int added, int removed, int changed) {
    return '$added added · $removed removed · $changed changed';
  }

  @override
  String get jsonDiffAdded => 'Added';

  @override
  String get jsonDiffRemoved => 'Removed';

  @override
  String get jsonDiffChanged => 'Changed';

  @override
  String jsonDiffSection(String title, int count) {
    return '$title ($count)';
  }

  @override
  String get jsonNothingToSplit => 'Nothing to split — too few items.';

  @override
  String get jsonItemsPerPart => 'Items per part';

  @override
  String get jsonInfoValid => 'Valid JSON';

  @override
  String get jsonInfoTopType => 'Top-level type';

  @override
  String get jsonInfoTopItems => 'Top-level items';

  @override
  String get jsonInfoKeys => 'Keys';

  @override
  String get jsonInfoArrays => 'Arrays';

  @override
  String get jsonInfoLargestArray => 'Largest array';

  @override
  String get jsonInfoTypes => 'Types';

  @override
  String get jsonNotValidYet => 'Not valid JSON yet';

  @override
  String jsonProblemNearLine(int line) {
    return 'There is a problem near line $line. Open the editor to fix it.';
  }

  @override
  String get jsonOpenEditorToFix => 'Open the editor to fix the JSON.';

  @override
  String jsonNdjsonBanner(int count) {
    return 'Newline-delimited JSON — $count records.';
  }

  @override
  String get jsonLenientBanner =>
      'Read leniently (comments / trailing commas). Saving writes strict JSON.';

  @override
  String get jsonMakeStrict => 'Make strict';

  @override
  String get jsonTreeFilterHint => 'Filter by key or value';

  @override
  String get jsonReformatStrict => 'Reformat as strict JSON before saving';

  @override
  String mdByAuthor(String author) {
    return 'By $author';
  }

  @override
  String get xmlTreeFilterHint => 'Filter by tag, attribute, or text';

  @override
  String get xmlViewPretty => 'Pretty';

  @override
  String get xmlViewTree => 'Tree';

  @override
  String get xmlViewRaw => 'Raw';

  @override
  String get xmlStopEditing => 'Stop editing';

  @override
  String get xmlEditSource => 'Edit source';

  @override
  String get xmlExpandAll => 'Expand all';

  @override
  String get xmlCollapseAll => 'Collapse all';

  @override
  String get xmlFormat => 'Format';

  @override
  String get xmlMinify => 'Minify';

  @override
  String get xmlValidate => 'Validate';

  @override
  String get xmlXPathQuery => 'XPath query';

  @override
  String get xmlInsightsInfo => 'Insights & info';

  @override
  String get xmlSplitByElement => 'Split by element';

  @override
  String get xmlMergeFile => 'Merge a file';

  @override
  String get xmlCopyAll => 'Copy all';

  @override
  String get xmlCopyMinified => 'Copy minified';

  @override
  String get xmlInfoWellFormed => 'Well-formed XML';

  @override
  String get xmlInfoRoot => 'Root element';

  @override
  String get xmlInfoElements => 'Elements';

  @override
  String get xmlInfoMaxDepth => 'Max depth';

  @override
  String get xmlInfoAttributes => 'Attributes';

  @override
  String get xmlInfoCommonTags => 'Common tags';

  @override
  String get xmlInfoNamespaces => 'Namespaces';

  @override
  String get xmlFixErrorsBeforeSplit => 'Fix the XML errors before splitting.';

  @override
  String get xmlNothingToSplit => 'Nothing to split — too few elements.';

  @override
  String get xmlRepeatedChildElement => 'Repeated child element';

  @override
  String get xmlElementsPerPart => 'Elements per part';

  @override
  String get xmlNewWrapperName => 'New wrapper element name';

  @override
  String get xmlPickFile => 'Pick file';

  @override
  String get xmlIndentation => 'Indentation (when reformatting)';

  @override
  String get xmlReformat => 'Reformat (pretty-print) before saving';

  @override
  String get xmlNotWellFormedTree =>
      'This document is not well-formed XML. Open the editor to fix it.';

  @override
  String get xmlNoMatches => 'No matches.';

  @override
  String get xmlNodeActions => 'Node actions';

  @override
  String get xmlCopyPath => 'Copy path';

  @override
  String get xmlCopyText => 'Copy text';

  @override
  String get xmlCopyXml => 'Copy XML';

  @override
  String get xmlEditText => 'Edit text';

  @override
  String get xmlSetAttribute => 'Set attribute';

  @override
  String get xmlRemoveAttribute => 'Remove attribute';

  @override
  String get xmlRename => 'Rename';

  @override
  String get xmlAddChild => 'Add child';

  @override
  String get xmlMoveUp => 'Move up';

  @override
  String get xmlMoveDown => 'Move down';

  @override
  String get xmlDelete => 'Delete';

  @override
  String get xmlPathCopied => 'Path copied.';

  @override
  String get xmlTextCopied => 'Text copied.';

  @override
  String get xmlXmlCopied => 'XML copied.';

  @override
  String get xmlEditTextTitle => 'Edit text';

  @override
  String get xmlAttributeName => 'Attribute name';

  @override
  String get xmlAttributeValue => 'Attribute value';

  @override
  String get xmlNoAttributes => 'This element has no attributes.';

  @override
  String get xmlRenameElementTitle => 'Rename element';

  @override
  String get xmlNewChildElement => 'New child element';

  @override
  String get xmlTextOptional => 'Text (optional)';

  @override
  String get xmlRemoveWhichAttribute => 'Remove which attribute?';

  @override
  String get xmlXPathTitle => 'XPath';

  @override
  String get xmlXPathHint => 'e.g. //book/title';

  @override
  String get xmlRun => 'Run';

  @override
  String get xmlNotWellFormedDoc => 'The document is not well-formed XML.';

  @override
  String xmlMatchCount(int count) {
    return '$count match(es)';
  }

  @override
  String get xmlWellFormedYes => 'Well-formed XML.';

  @override
  String xmlNotWellFormedWithLine(int line, String error) {
    return 'Not well-formed (line $line): $error';
  }

  @override
  String xmlNotWellFormedNoLine(String error) {
    return 'Not well-formed: $error';
  }

  @override
  String get xmlXsdComing =>
      'XSD schema validation is coming in a later update.';

  @override
  String get xmlNotWellFormedYet => 'Not well-formed XML yet';

  @override
  String xmlProblemNearLine(int line) {
    return 'There is a problem near line $line. Open the editor to fix it.';
  }

  @override
  String get xmlOpenEditorToFix => 'Open the editor to fix the XML.';

  @override
  String get openTooManyTabs =>
      'Too many tabs open. Close one first, then reopen.';

  @override
  String get csvShowRawText => 'Show raw text';

  @override
  String get csvShowTable => 'Show table';

  @override
  String get csvFilterRows => 'Filter rows';

  @override
  String get csvFilterRowsHint => 'Filter rows…';

  @override
  String get csvJumpToRow => 'Jump to row';

  @override
  String get csvColumnsView => 'Columns & view';

  @override
  String get csvInsights => 'Insights';

  @override
  String csvRowNumberLabel(int max) {
    return 'Row number (1–$max)';
  }

  @override
  String get csvRemoveDuplicates => 'Remove duplicate rows';

  @override
  String get csvSplitByRows => 'Split by rows';

  @override
  String get csvAppendFile => 'Append a file';

  @override
  String get csvMatchDuplicatesBy => 'Match duplicates by';

  @override
  String get csvWholeRow => 'Whole row';

  @override
  String csvColumnN(int n) {
    return 'Column $n';
  }

  @override
  String get csvNoDuplicates => 'No duplicate rows found.';

  @override
  String csvRemovedDuplicates(int count) {
    return 'Removed $count duplicate row(s).';
  }

  @override
  String get csvInfoTitle => 'File info';

  @override
  String get csvInfoRows => 'Rows';

  @override
  String get csvInfoColumns => 'Columns';

  @override
  String get csvInfoDelimiter => 'Delimiter';

  @override
  String get csvInfoHeaderRow => 'Header row';

  @override
  String get csvInfoEncoding => 'Encoding';

  @override
  String get csvInfoLineEnding => 'Line ending';

  @override
  String get csvInfoSize => 'Size';

  @override
  String get csvInfoModified => 'Modified';

  @override
  String get csvYes => 'Yes';

  @override
  String get csvNo => 'No';

  @override
  String get csvFreezeHeader => 'Freeze header row';

  @override
  String get csvFreezeFirstColumn => 'Freeze first column';

  @override
  String get csvFirstRowHeader => 'First row is a header';

  @override
  String get csvShowColumns => 'Show columns';

  @override
  String get csvNoColumns => 'No columns to analyze.';

  @override
  String get csvDataInsights => 'Data insights';

  @override
  String get csvColumnLabel => 'Column';

  @override
  String get csvStatType => 'Type';

  @override
  String get csvStatValues => 'Values';

  @override
  String get csvStatEmpty => 'Empty';

  @override
  String get csvStatUnique => 'Unique';

  @override
  String get csvStatMin => 'Min';

  @override
  String get csvStatMax => 'Max';

  @override
  String get csvStatSum => 'Sum';

  @override
  String get csvStatAverage => 'Average';

  @override
  String get csvSplitOnePart => 'The file is small enough to fit in one part.';

  @override
  String csvSplitStopped(int done, int total) {
    return 'Stopped after saving $done of $total parts.';
  }

  @override
  String csvSplitSaved(int count) {
    return 'Saved $count parts.';
  }

  @override
  String csvMerged(String name) {
    return 'Merged $name. Review and save.';
  }

  @override
  String get csvRowsPerPart => 'Rows per part';

  @override
  String get csvSplitAction => 'Split';

  @override
  String get csvAddRow => 'Add row';

  @override
  String csvEditCell(String name) {
    return 'Edit \"$name\"';
  }

  @override
  String get csvCellFallback => 'Cell';

  @override
  String get csvRenameColumn => 'Rename column';

  @override
  String get csvInsertColumnLeft => 'Insert column left';

  @override
  String get csvInsertColumnRight => 'Insert column right';

  @override
  String get csvHideColumn => 'Hide column';

  @override
  String get csvDeleteColumn => 'Delete column';

  @override
  String get csvInsertRowAbove => 'Insert row above';

  @override
  String get csvInsertRowBelow => 'Insert row below';

  @override
  String get csvMoveUp => 'Move up';

  @override
  String get csvMoveDown => 'Move down';

  @override
  String get csvDeleteRow => 'Delete row';
}
