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
  String get fileChangedBanner => 'This file changed on disk.';

  @override
  String get fileChangedReload => 'Reload';

  @override
  String get fileChangedDismiss => 'Dismiss';

  @override
  String get fileChangedReloadFailed => 'Could not reload the file.';

  @override
  String get fileChangedConfirmTitle => 'Reload and lose your edits?';

  @override
  String fileChangedConfirmBody(String fileName) {
    return '\"$fileName\" has unsaved edits. Reloading loads the file from disk and throws those edits away.';
  }

  @override
  String get fileChangedConfirmReload => 'Reload and discard';

  @override
  String get fileChangedConfirmCancel => 'Cancel';

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
  String get editorExitEditAfterSave => 'Leave edit mode after saving';

  @override
  String get editorExitEditAfterSaveSub =>
      'Go back to view mode when a save succeeds.';

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
  String get helpSearchFilterHint => 'Search help topics…';

  @override
  String get helpNoTopicsFound => 'No matching help topics found.';

  @override
  String get helpP2pSyncTitle => 'LAN Sync & Live Diff';

  @override
  String get helpP2pSyncSubtitle =>
      'Sync data and compare document versions live over Wi-Fi.';

  @override
  String get helpP2pSyncBody =>
      'Sync favorites, bookmarks, recents, and display settings across devices on your local Wi-Fi without internet or external servers.\n\n• Live Diff & Delta Sync: Open any document, tap menu and select Live Diff to connect with a nearby device. View color-coded line-by-line differences and merge specific incoming changes directly.\n• Security: All sync communication is encrypted end-to-end using AES-256-GCM with a temporary pairing code. Nothing is ever sent over the internet.';

  @override
  String get helpQrSharingTitle => 'Optical QR Transfer (AirQR)';

  @override
  String get helpQrSharingSubtitle =>
      'Transfer text and files visually without Wi-Fi, Bluetooth, or cables.';

  @override
  String get helpQrSharingBody =>
      'Send documents or selections between devices using animated high-density QR codes and camera scanning without any network connection.\n\n• How to Send: Open a document, tap the menu and choose \"Send by QR\" or \"Send selection by QR\". Adjust speed and density if needed.\n• How to Receive: Open the AirQR screen on the receiver and point the camera at the sender\'s screen.\n• Encryption: Enable encryption to protect transfers with an AES-256 session passphrase.';

  @override
  String get helpPrivacyShieldTitle => 'Privacy Shield & PII Scrubber';

  @override
  String get helpPrivacyShieldSubtitle =>
      'Detect and redact sensitive personal information completely offline.';

  @override
  String get helpPrivacyShieldBody =>
      'Protect personal and confidential information before sharing or saving.\n\n• Automatic Detection: Privacy Shield scans text offline for email addresses, phone numbers, credit card numbers, IPv4/IPv6 addresses, national IDs (SSN/Aadhaar), and secret API keys/tokens.\n• Redact & Mask: Preview detected items, select specific categories to mask, and replace them with standard redaction tokens (e.g. [EMAIL], [PHONE]) or asterisks.\n• Zero Network Leakage: All scanning and scrubbing is performed purely on your device.';

  @override
  String get helpVaultBackupTitle => 'Document Vault & Encrypted Backups';

  @override
  String get helpVaultBackupSubtitle =>
      'Store sensitive files in an encrypted vault and export .txdata archives.';

  @override
  String get helpVaultBackupBody =>
      'Keep sensitive files secure with hardware-backed encryption.\n\n• Document Vault: Store private files in an isolated AES-256-GCM encrypted vault protected by your app PIN or biometric authentication.\n• Encrypted Backups (.txdata): Export multiple documents and settings into password-protected encrypted .txdata archive files.\n• Restore: Import .txdata backups at any time with the archive password.';

  @override
  String get helpSqlQueryTitle => 'SQL Query Engine';

  @override
  String get helpSqlQuerySubtitle =>
      'Query CSV, JSON, and XML files directly with local SQL statements.';

  @override
  String get helpSqlQueryBody =>
      'Analyze and transform tabular and structured data using standard SQL syntax directly on your device.\n\n• Supported Formats: Run queries on CSV, JSON, and XML documents.\n• Capabilities: Full SQL syntax including SELECT, WHERE, GROUP BY, HAVING, ORDER BY, and table JOINs across opened tabs.\n• Export Results: Save query output directly as new CSV or JSON files.';

  @override
  String get helpMultiCursorTitle => 'Multi-Cursor & Column Editing';

  @override
  String get helpMultiCursorSubtitle =>
      'Simultaneously edit multiple lines and select vertical text columns.';

  @override
  String get helpMultiCursorBody =>
      'Boost editing speed on repetitive formatting and text transformation tasks.\n\n• Multi-Cursor: Tap and hold to place multiple independent cursors in the text editor. All cursors type, delete, and paste at the same time.\n• Column Selection: Select vertical columns of text across multiple lines to easily add prefixes, suffixes, or edit tabular text alignments.';

  @override
  String get helpSearchTitle => 'Search & Workspace Index';

  @override
  String get helpSearchSubtitle =>
      'Find text inside documents or search across all files with SQLite FTS5.';

  @override
  String get helpSearchBody =>
      'Find text rapidly across your documents:\n\n• In-Document Search: Use Find & Replace with case sensitivity, whole-word matching, and regular expressions.\n• Global Workspace Search: Tap the search icon on the Home screen to query the high-speed SQLite FTS5 full-text index covering all recent and favorite documents.\n• 100% Private: All indexing and search operations occur locally on your device.';

  @override
  String get helpAuditLogTitle => 'Tamper-Evident Audit Log';

  @override
  String get helpAuditLogSubtitle =>
      'Verify file integrity with cryptographic SHA-256 hash chains.';

  @override
  String get helpAuditLogBody =>
      'Maintain transparent and tamper-evident records of document operations.\n\n• Hash Chaining: Every file open, edit, save, export, and vault operation is logged with SHA-256 digests chained cryptographically to the previous entry.\n• Integrity Verification: Run verification from Settings → Audit Log to mathematically prove no log entries or file histories have been altered.';

  @override
  String get helpFormatToolsTitle => 'Format-Specific Tools';

  @override
  String get helpFormatToolsSubtitle =>
      'Specialized visual tools and editors for JSON, Markdown, CSV, XML, and TXT.';

  @override
  String get helpFormatToolsBody =>
      'TextData provides custom editors and visual tools tailored to each file type:\n\n• JSON: Interactive visual tree viewer, JSONPath query runner, schema validator, array splitter, and formatter.\n• Markdown: Live split-screen preview, visual table builder, YAML front-matter editor, and heading splitter.\n• CSV: Interactive spreadsheet grid, column sorting, formulas (SUM, AVG, MIN, MAX, COUNT), and delimiter converter.\n• XML: Hierarchical tree view, XPath query runner, XSD schema validator, and auto-beautifier.\n• TXT: Line splitting, word wrap toggling, line jump, and web link extractor.';

  @override
  String get helpSpeechTitle => 'Speech & Read Aloud';

  @override
  String get helpSpeechSubtitle =>
      'Listen to documents read aloud in English and Malayalam.';

  @override
  String get helpSpeechBody =>
      'Listen to documents hands-free using your device\'s built-in text-to-speech engine.\n\n• Supported Languages: English and Malayalam.\n• Voice Controls: Play, pause, stop, and configure speech rate and language from Settings → Speech.';

  @override
  String get helpSplitArrayTitle => 'Split array';

  @override
  String get helpSplitArraySubtitle =>
      'Break a JSON array into smaller numbered files.';

  @override
  String get helpSplitArrayBody =>
      'Split array works when the top level of a JSON file is an array. Choose how many items each part should contain. The app then creates numbered files such as name.part1.json and asks where to save each one. The last part may contain fewer items. Your original file is not changed.';

  @override
  String get helpBackupTitle => 'Backup & export';

  @override
  String get helpBackupSubtitle =>
      'Keep copies of your files safe in other formats or locations.';

  @override
  String get helpBackupBody =>
      'Keep copies of your files safe using Export and Save a copy. Open any document and tap the menu to find \"Export\" — this converts your file to another format such as PDF or plain text. Use \"Save a copy\" to save the document to a new location without changing the original. For extra safety, export important files regularly and store copies in a safe place such as a cloud folder, an SD card, or another device using LAN sync or QR sharing.';

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
  String get editorExitEditMode => 'Exit edit mode';

  @override
  String get editorAutoSaveFailing =>
      'Auto-save is not working. Save the file to keep your changes.';

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
  String get mdTableBuilder => 'Table builder';

  @override
  String get mdTableBuilderHelp =>
      'Fill in the cells; the pipe characters are lined up for you.';

  @override
  String get mdTableHeaderCell => 'Header';

  @override
  String get mdTableAddRow => 'Add row';

  @override
  String get mdTableAddColumn => 'Add column';

  @override
  String get mdTableRemoveRow => 'Remove this row';

  @override
  String get mdTableRemoveColumn => 'Remove this column';

  @override
  String get mdTablePreview => 'Markdown';

  @override
  String get mdTableInsert => 'Insert table';

  @override
  String get mdTableAlignDefault => 'Default';

  @override
  String get mdTableAlignLeft => 'Left';

  @override
  String get mdTableAlignCenter => 'Center';

  @override
  String get mdTableAlignRight => 'Right';

  @override
  String get mdFrontMatterTitle => 'Front matter';

  @override
  String get mdFrontMatterHelp =>
      'Edit the fields below. Anything this form does not show is left exactly as it is.';

  @override
  String get mdFrontMatterNone =>
      'This file has no front matter yet. Fill in a field to add one.';

  @override
  String get mdFrontMatterAddField => 'Add field';

  @override
  String get mdFrontMatterFieldName => 'Field name';

  @override
  String get mdFrontMatterAdd => 'Add';

  @override
  String get mdFrontMatterAddTag => 'Type a tag and press enter';

  @override
  String get mdFrontMatterPickDate => 'Pick a date';

  @override
  String get mdFrontMatterApply => 'Apply changes';

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
  String get jsonViewAsTable => 'View as table';

  @override
  String get jsonTableNothingToShow =>
      'This document has no array of records to show as a table.';

  @override
  String jsonTableSummary(String path, int rows, int columns) {
    return '$path · $rows rows · $columns columns';
  }

  @override
  String get jsonTableWholeDocument => 'Whole document';

  @override
  String get jsonTableCopied => 'Value copied';

  @override
  String get jsonQueryBuilderTitle => 'Query builder';

  @override
  String get jsonQueryGoInto => 'Go into';

  @override
  String get jsonQueryAtAnyDepth => 'At any depth';

  @override
  String get jsonQueryMatchesHeading => 'Matches';

  @override
  String get jsonQueryNoMatches =>
      'Nothing matches yet. Step back and try another path.';

  @override
  String get jsonQueryNothingDeeper =>
      'There is nothing deeper to go into from here.';

  @override
  String get jsonQueryStepBack => 'Step back';

  @override
  String get jsonQueryStartOver => 'Start over';

  @override
  String get jsonQueryUse => 'Use this query';

  @override
  String get jsonQuickFixes => 'Quick fixes';

  @override
  String get jsonFixEverything => 'Fix everything';

  @override
  String get jsonFixQuoteKeys => 'Put quotes around keys';

  @override
  String get jsonFixDoubleQuotes => 'Use double quotes';

  @override
  String get jsonFixTrailingCommas => 'Remove extra commas';

  @override
  String get jsonFixRemoveComments => 'Remove comments';

  @override
  String get jsonFixPythonLiterals => 'Use true, false and null';

  @override
  String get xmlQueryBuilderTitle => 'XPath builder';

  @override
  String get xmlFixCloseTags => 'Close the open tags';

  @override
  String get xmlFixEscapeAmpersands => 'Escape the & signs';

  @override
  String get xmlFixWrapRoot => 'Wrap in a single root';

  @override
  String get xmlFixTrimJunk => 'Remove the text before the first tag';

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
  String get csvSortLevels => 'Sort levels';

  @override
  String get csvSortNoLevels =>
      'No sort yet. Add a level to sort by more than one column.';

  @override
  String get csvSortAddLevel => 'Add level';

  @override
  String get csvSortApply => 'Apply sort';

  @override
  String get csvSortClear => 'Clear';

  @override
  String get csvSortFirstBy => 'Sort by';

  @override
  String get csvSortThenBy => 'Then by';

  @override
  String get csvSortAscending => 'A → Z';

  @override
  String get csvSortDescending => 'Z → A';

  @override
  String get csvSortMoveUp => 'Move this level up';

  @override
  String get csvSortMoveDown => 'Move this level down';

  @override
  String get csvSetFormula => 'Set formula…';

  @override
  String get csvEditFormula => 'Edit formula…';

  @override
  String csvFormulaTitle(String name) {
    return 'Formula for \"$name\"';
  }

  @override
  String get csvFormulaHelp =>
      'Use column letters for this row (A, B), a row number for a fixed cell (B2), or a range inside SUM, AVG, MIN, MAX, COUNT or PRODUCT.';

  @override
  String get csvFormulaLabel => 'Formula';

  @override
  String get csvFormulaColumnLetters => 'Columns you can use';

  @override
  String get csvFormulaPreview => 'First rows';

  @override
  String get csvFormulaApply => 'Apply';

  @override
  String get csvFormulaRemove => 'Remove formula';

  @override
  String get csvHighlightRules => 'Highlight rules';

  @override
  String get csvNoHighlightRules =>
      'No rules yet. Add one to colour cells automatically.';

  @override
  String get csvAddHighlightRule => 'Add rule';

  @override
  String get csvRuleEveryColumn => 'Every column';

  @override
  String get csvRuleWhen => 'When the value';

  @override
  String get csvRuleValue => 'Compare with';

  @override
  String get csvRuleHighlight => 'Highlight in';

  @override
  String get csvConditionLessThan => 'is less than';

  @override
  String get csvConditionGreaterThan => 'is greater than';

  @override
  String get csvConditionEqualTo => 'is equal to';

  @override
  String get csvConditionNotEqualTo => 'is not equal to';

  @override
  String get csvConditionContains => 'contains';

  @override
  String get csvConditionIsEmpty => 'is empty';

  @override
  String get csvConditionIsDuplicate => 'repeats in its column';

  @override
  String get csvHighlightRed => 'Red';

  @override
  String get csvHighlightYellow => 'Yellow';

  @override
  String get csvHighlightGreen => 'Green';

  @override
  String get csvHighlightBlue => 'Blue';

  @override
  String get csvChartTitle => 'Chart';

  @override
  String get csvOpenFullChart => 'Open full chart';

  @override
  String get csvChartBar => 'Bar';

  @override
  String get csvChartLine => 'Line';

  @override
  String get csvChartPie => 'Pie';

  @override
  String get csvChartValueColumn => 'Values from';

  @override
  String get csvChartLabelColumn => 'Labels from';

  @override
  String get csvChartRowNumbers => 'Row numbers';

  @override
  String get csvChartVisibleRowsOnly => 'Only the rows on screen';

  @override
  String get csvChartNoNumericColumns =>
      'This file has no number columns to chart.';

  @override
  String get csvChartNothingToDraw => 'Nothing to chart for this column.';

  @override
  String get csvChartOther => 'Other';

  @override
  String csvChartShowingFirst(int count) {
    return 'Showing the first $count values.';
  }

  @override
  String csvChartSkippedNegative(int count) {
    return '$count negative values were left out of the pie.';
  }

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

  @override
  String get airqrTitle => 'Air-gap transfer (QR)';

  @override
  String get airqrIntro =>
      'Move a document or a piece of text to another device using only the screen and the camera. Nothing is sent over Wi-Fi, Bluetooth, or the internet.';

  @override
  String get airqrReceive => 'Receive';

  @override
  String get airqrReceiveSubtitle =>
      'Point the camera at the other device\'s screen';

  @override
  String get airqrHowToSend => 'How to send';

  @override
  String get airqrHowToSendBody =>
      'Open the document you want to send, then choose \"Send by QR\" from its menu. To send only part of a document, select the text first.';

  @override
  String get airqrSpeedNoteTitle => 'This is slow on purpose';

  @override
  String get airqrSpeedNoteBody =>
      'A camera link carries about 15 KB each second. Short notes take a few seconds; a large file can take minutes. For anything big, use LAN sync instead.';

  @override
  String get airqrSendTitle => 'Sending by QR';

  @override
  String get airqrSendByQr => 'Send by QR';

  @override
  String get airqrSendSelectionByQr => 'Send selection by QR';

  @override
  String get airqrHoldSteady =>
      'Hold both devices steady until the other device says it has every frame. The code below repeats until then.';

  @override
  String get airqrCodeLabel => 'Session code';

  @override
  String get airqrCodeHint =>
      'Read this code to the other person. It is not inside the QR code, so anyone who records the screen still cannot read your data without it.';

  @override
  String get airqrUnsealedWarning =>
      'This transfer is not protected. Anyone who can see this screen can read the data.';

  @override
  String airqrFrameCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count frames',
      one: '1 frame',
    );
    return '$_temp0';
  }

  @override
  String airqrPassCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count passes done',
      one: '1 pass done',
      zero: 'First pass',
    );
    return '$_temp0';
  }

  @override
  String airqrOnePassTakes(int seconds) {
    return 'One full pass takes about $seconds seconds.';
  }

  @override
  String airqrSpeedLabel(int fps) {
    return 'Speed: $fps frames per second';
  }

  @override
  String get airqrSpeedHelp =>
      'Lower this if the other device is missing frames.';

  @override
  String airqrDensityLabel(int bytes) {
    return 'Detail: $bytes bytes per frame';
  }

  @override
  String get airqrDensityHelp =>
      'Lower this for an easier-to-scan code on an older camera. It needs more frames.';

  @override
  String get airqrReceiveTitle => 'Receiving by QR';

  @override
  String get airqrScanSemantics =>
      'Camera viewfinder for receiving an animated QR code';

  @override
  String get airqrLookingForStream => 'Looking for a transfer…';

  @override
  String airqrFramesProgress(int received, int total) {
    return '$received of $total frames';
  }

  @override
  String airqrFps(String rate) {
    return '$rate frames/second';
  }

  @override
  String airqrRemaining(int seconds) {
    return 'About ${seconds}s left';
  }

  @override
  String airqrStillMissing(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Waiting for $count more frames',
      one: 'Waiting for 1 more frame',
    );
    return '$_temp0';
  }

  @override
  String get airqrAssembling => 'Checking and rebuilding the data…';

  @override
  String get airqrAllFramesReceived => 'All frames received';

  @override
  String get airqrEnterCodePrompt =>
      'Enter the session code shown on the sending device.';

  @override
  String get airqrUnlock => 'Unlock';

  @override
  String get airqrStartOver => 'Start over';

  @override
  String get airqrReceivedTitle => 'Transfer complete';

  @override
  String airqrCharacterCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count characters',
      one: '1 character',
    );
    return '$_temp0';
  }

  @override
  String get airqrPreview => 'Preview';

  @override
  String get airqrCopyText => 'Copy text';

  @override
  String get airqrCopied => 'Copied to the clipboard';

  @override
  String get airqrUseThis => 'Save as a file';

  @override
  String get airqrFailedGeneric => 'The transfer could not be completed.';

  @override
  String airqrSavedAs(String name) {
    return 'Saved as $name';
  }

  @override
  String get airqrInsertedIntoDocument =>
      'Text inserted into the open document';

  @override
  String get airqrTooLargeTitle => 'Too large for QR transfer';

  @override
  String airqrTooLargeBody(String size, String limit) {
    return 'This is $size, and QR transfer stops at $limit. At camera speed it would take far too long. Use LAN sync instead.';
  }

  @override
  String get airqrSlowTitle => 'This will take a while';

  @override
  String airqrSlowBody(String size, String duration) {
    return 'This is $size, which takes $duration by QR code. You will need to hold both devices steady for that long. LAN sync would be much faster.';
  }

  @override
  String get airqrSendAnyway => 'Send anyway';

  @override
  String airqrAboutMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'about $minutes minutes',
      one: 'about 1 minute',
    );
    return '$_temp0';
  }

  @override
  String airqrAboutSeconds(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: 'about $seconds seconds',
      one: 'about 1 second',
    );
    return '$_temp0';
  }

  @override
  String get airqrNothingToSend => 'There is nothing to send.';

  @override
  String get searchWorkspaceTitle => 'Search all files';

  @override
  String get searchWorkspaceTooltip => 'Search all files';

  @override
  String get searchWorkspaceHint => 'Search recent and favorite files';

  @override
  String get searchWorkspaceStartTitle => 'Search inside your files';

  @override
  String get searchWorkspaceStartBody =>
      'Type a word to find it in the files you opened or marked as favorites. Everything is searched on this device only.';

  @override
  String get searchWorkspaceNoResults => 'No matches found';

  @override
  String get searchWorkspaceNoResultsBody =>
      'Try a shorter word, or open the file once so it gets indexed.';

  @override
  String get searchWorkspaceOffTitle => 'Workspace search is off';

  @override
  String get searchWorkspaceOffBody =>
      'Turn it on in Settings › Files & Tabs to search across your files.';

  @override
  String get searchWorkspaceClear => 'Clear search';

  @override
  String get searchWorkspaceAll => 'All';

  @override
  String get searchWorkspacePartial =>
      'Long file — only the first part is searched';

  @override
  String get searchWorkspaceUnavailable =>
      'File not available — remove from search';

  @override
  String searchWorkspaceResults(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files',
      one: '1 file',
    );
    return '$_temp0';
  }

  @override
  String get filesIndexTitle => 'Workspace search index';

  @override
  String get filesIndexOn =>
      'Files you open are indexed on this device so you can search inside all of them.';

  @override
  String get filesIndexOff =>
      'New files are not indexed. Search only finds what was stored before.';

  @override
  String filesIndexCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files indexed',
      one: '1 file indexed',
      zero: 'No files indexed',
    );
    return '$_temp0';
  }

  @override
  String get filesIndexClear => 'Clear search index';

  @override
  String get filesIndexClearBody =>
      'This deletes the stored text of every indexed file. Files themselves are not touched.';

  @override
  String get filesIndexCleared => 'Search index cleared';

  @override
  String get filesIndexRebuild => 'Rebuild search index';

  @override
  String get filesIndexRebuilding => 'Rebuilding the search index…';

  @override
  String filesIndexRebuilt(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files indexed',
      one: '1 file indexed',
      zero: 'Nothing new to index',
    );
    return '$_temp0';
  }

  @override
  String ephemeralBadgeTimerTooltip(String time) {
    return 'This tab self-destructs in $time';
  }

  @override
  String get ephemeralBadgeOutputTooltip =>
      'This tab self-destructs after the next export or share';

  @override
  String get ephemeralSheetTitle => 'Make this tab self-destruct';

  @override
  String get ephemeralSheetWhatIsWiped =>
      'When it burns, the app forgets this document: the auto-save draft, the recent entry, favourites, bookmarks, its reading position, and its text in the workspace search index.';

  @override
  String get ephemeralSheetFileKept =>
      'Your file itself is not deleted. The app only clears what it stores about it.';

  @override
  String get ephemeralSheetUnsavedWarning =>
      'Unsaved edits in this tab are thrown away when it burns, with no further prompt.';

  @override
  String get ephemeralSheetTimerLabel => 'Self-destruct after';

  @override
  String get ephemeralSheetCustomMinutes => 'Minutes';

  @override
  String get ephemeralSheetBurnAfterOutput => 'Burn after export or share';

  @override
  String get ephemeralSheetBurnAfterOutputHint =>
      'The first successful export, share, or print destroys the tab. A cancelled or failed one does not.';

  @override
  String get ephemeralSheetNothingChosen =>
      'Choose a timer, turn on burn after export, or both.';

  @override
  String get ephemeralSheetConfirm => 'Make ephemeral';

  @override
  String get ephemeralDuration15Minutes => '15 minutes';

  @override
  String get ephemeralDuration1Hour => '1 hour';

  @override
  String get ephemeralDuration4Hours => '4 hours';

  @override
  String get ephemeralDuration24Hours => '24 hours';

  @override
  String get ephemeralDurationCustom => 'Custom';

  @override
  String get ephemeralDurationNone => 'No timer';

  @override
  String get tabMakeEphemeral => 'Make self-destructing…';

  @override
  String get tabChangeEphemeral => 'Change self-destruct…';

  @override
  String get tabCancelEphemeral => 'Keep this tab';

  @override
  String get tabBurnNow => 'Burn now';

  @override
  String ephemeralMarked(String name) {
    return '$name will self-destruct';
  }

  @override
  String ephemeralCancelled(String name) {
    return '$name is a normal tab again';
  }

  @override
  String ephemeralBurned(String name) {
    return '$name was burned';
  }

  @override
  String ephemeralBurnedPartly(String name) {
    return '$name was closed, but some stored traces could not be removed';
  }

  @override
  String get ephemeralBurnNowTitle => 'Burn this tab?';

  @override
  String get ephemeralBurnNowBody =>
      'The tab closes and the app forgets this document. Unsaved edits are lost. Your file itself is not deleted.';

  @override
  String get actionBurn => 'Burn';

  @override
  String get ephemeralOpenAsEphemeral => 'Open as self-destructing…';

  @override
  String get ephemeralSettingsTitle => 'Self-destructing documents';

  @override
  String get ephemeralSettingsDefaultDuration => 'Default timer';

  @override
  String get ephemeralSettingsBurnAfterOutput => 'Default to burn after export';

  @override
  String get ephemeralSettingsBurnAfterOutputHint =>
      'Pre-selects the switch in the self-destruct sheet. It does not change any tab on its own.';

  @override
  String get ephemeralSettingsBurnAll => 'Burn all self-destructing tabs now';

  @override
  String ephemeralSettingsOpenCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count self-destructing tabs are open',
      one: '1 self-destructing tab is open',
      zero: 'No self-destructing tabs are open',
    );
    return '$_temp0';
  }

  @override
  String ephemeralSettingsBurnAllDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tabs burned',
      one: '1 tab burned',
      zero: 'Nothing to burn',
    );
    return '$_temp0';
  }

  @override
  String get ephemeralSettingsWipeNote =>
      'A burn overwrites the app\'s stored copy with zeros before deleting it. On flash storage that is a strong extra step, not a guarantee — Android\'s own app encryption is the real protection.';

  @override
  String get sqlMenuAction => 'Run SQL query…';

  @override
  String get sqlQueryTitle => 'SQL query';

  @override
  String get sqlQueryHint => 'SELECT * FROM data LIMIT 100';

  @override
  String get sqlRunAction => 'Run';

  @override
  String get sqlRunning => 'Running…';

  @override
  String get sqlLoadingData => 'Loading the data…';

  @override
  String get sqlTablesHeading => 'Tables';

  @override
  String sqlTableSummary(int rows, int columns) {
    return '$rows rows · $columns columns';
  }

  @override
  String sqlColumnRenamed(String original) {
    return 'was “$original”';
  }

  @override
  String get sqlColumnBlankName => '(blank)';

  @override
  String sqlRowsCapped(int count) {
    return 'Only the first $count rows of this file were loaded.';
  }

  @override
  String get sqlAddTable => 'Add a table';

  @override
  String get sqlAddTableTitle => 'Add another open document';

  @override
  String get sqlAddTableEmpty => 'No other CSV or JSON tab is open.';

  @override
  String sqlAddTableFailed(String name) {
    return '$name has nothing that can be loaded as a table.';
  }

  @override
  String sqlTableAdded(String name, String table) {
    return '$name is now the table $table.';
  }

  @override
  String get sqlRemoveTable => 'Remove';

  @override
  String get sqlPresetsHeading => 'Starter queries';

  @override
  String get sqlPresetSelectAll => 'Show the first rows';

  @override
  String get sqlPresetCountRows => 'Count the rows';

  @override
  String get sqlPresetGroupCount => 'Group and total';

  @override
  String get sqlPresetOrderBy => 'Highest values first';

  @override
  String get sqlPresetJoin => 'Join the two tables';

  @override
  String sqlResultSummary(int rows, int ms) {
    return '$rows rows in $ms ms';
  }

  @override
  String sqlResultTruncated(int count) {
    return 'Showing the first $count rows of the result.';
  }

  @override
  String get sqlResultEmpty => 'The query ran, but no rows matched.';

  @override
  String get sqlResultPlaceholder =>
      'Type a query and tap Run, or pick a starter query.';

  @override
  String get sqlCopyResult => 'Copy result as CSV';

  @override
  String get sqlCopiedResult => 'Result copied as CSV';

  @override
  String get sqlSaveResult => 'Save result as CSV…';

  @override
  String sqlSavedResult(String name) {
    return 'Saved $name';
  }

  @override
  String get sqlNoResultYet => 'There is no result to save yet.';

  @override
  String get sqlReloadData => 'Reload data';

  @override
  String get sqlReloadedData => 'Data reloaded from the open documents.';

  @override
  String get sqlSnapshotNote =>
      'Queries run over a copy taken when this screen opened. Reload after editing the document.';

  @override
  String get sqlNoData =>
      'This document has nothing that can be queried as a table.';

  @override
  String get sqlLoadFailed => 'The data could not be loaded for querying.';

  @override
  String get sqlErrorEmpty => 'Type a query first.';

  @override
  String get sqlErrorNotSelect =>
      'Only a query that starts with SELECT or WITH can run here.';

  @override
  String get sqlErrorMultiple => 'Type one statement only.';

  @override
  String sqlErrorForbidden(String keyword) {
    return '“$keyword” is not allowed — this screen only reads data.';
  }

  @override
  String get sqlReadOnlyNote =>
      'This is a read-only copy of your data. A query can never change or delete your file.';

  @override
  String get auditSectionTitle => 'Audit Log';

  @override
  String get auditCardSubtitle =>
      'Cryptographic SHA-256 chain log of workspace activity';

  @override
  String get auditEnableTitle => 'Record workspace audit log';

  @override
  String get auditEnableSubtitle =>
      'Chains SHA-256 hashes of document edits, exports, sync, and security events.';

  @override
  String get auditChainStatusLabel => 'Chain status';

  @override
  String get auditViewLogTitle => 'View audit log';

  @override
  String auditEntryCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count recorded entries',
      one: '1 recorded entry',
      zero: 'No recorded entries',
    );
    return '$_temp0';
  }

  @override
  String get auditLogTitle => 'Workspace Audit Log';

  @override
  String get auditVerifyAction => 'Verify chain';

  @override
  String get auditExportAction => 'Export certificate';

  @override
  String get auditExportSubject => 'TextData Audit Certificate';

  @override
  String get auditExportFailed => 'Could not export the audit certificate.';

  @override
  String get auditClearAction => 'Clear audit log';

  @override
  String get auditClearSubtitle =>
      'Deletes all audit records and resets the cryptographic chain.';

  @override
  String get auditClearTitle => 'Clear audit log?';

  @override
  String get auditClearConfirmation =>
      'This will delete all activity records. The cryptographic hash chain will restart with a new genesis entry.';

  @override
  String get auditClearSuccess => 'Audit log cleared.';

  @override
  String get auditEmptyState => 'No audit entries recorded yet.';

  @override
  String get auditBadgeVerified => 'Chain Verified';

  @override
  String get auditBadgeCorrupted => 'Chain Corrupted';

  @override
  String get auditBadgeEmpty => 'Log Empty';

  @override
  String get auditBadgeVerifying => 'Verifying…';

  @override
  String get auditBadgeError => 'Check Failed';

  @override
  String auditChainVerifiedBanner(int count) {
    return 'Tamper-Proof Chain Verified ($count entries)';
  }

  @override
  String auditChainCorruptedBanner(int index) {
    return 'Audit Chain Corrupted at Entry #$index';
  }

  @override
  String get auditChainEmptyBanner => 'No audit log entries to verify.';

  @override
  String get backupSectionTitle => 'Backup & Restore';

  @override
  String get backupCardSubtitle =>
      'Encrypted archive export and restore (.txdata)';

  @override
  String get backupSectionDescription =>
      'Export or restore your files, recents, favorites, bookmarks, and settings in a single AES-256 encrypted .txdata bundle.';

  @override
  String get backupManageTitle => 'Backup Archive Manager';

  @override
  String get backupManageSubtitle =>
      'Create password-sealed backups or restore from existing .txdata archives.';

  @override
  String get backupZeroKnowledgeNote =>
      'Zero-Knowledge Protection: Archives are sealed with AES-256-GCM using keys derived via PBKDF2-HMAC-SHA256 (200,000 iterations). Your password is never stored or transmitted. If forgotten, encrypted backups cannot be recovered.';

  @override
  String get backupScreenTitle => 'Backup & Restore (.txdata)';

  @override
  String get backupHeroTitle => 'Encrypted Backup Archives';

  @override
  String get backupHeroBody =>
      'Bundle your workspace data and settings into a tamper-evident, password-sealed AES-256 archive. Fully offline with zero cloud access.';

  @override
  String get backupExportCardTitle => 'Create Encrypted Backup';

  @override
  String get backupExportCardBody =>
      'Select workspace items and seal them under a chosen password into a .txdata file.';

  @override
  String get backupExportButton => 'Export Backup (.txdata)';

  @override
  String get backupRestoreCardTitle => 'Restore From Backup';

  @override
  String get backupRestoreCardBody =>
      'Open an existing .txdata file, verify your password, and selectively restore items.';

  @override
  String get backupRestoreButton => 'Select Backup File (.txdata)';

  @override
  String get backupSaveToDevice => 'Save to device (SAF)';

  @override
  String get backupShareArchive => 'Share archive file';

  @override
  String backupExportSaved(String fileName) {
    return 'Backup archive saved as $fileName';
  }

  @override
  String get backupExportError => 'Failed to create backup';

  @override
  String get backupRestoreError => 'Failed to restore backup';

  @override
  String get backupUnlockFailedTitle => 'Cannot Unlock Backup';

  @override
  String backupRestoreSuccessSummary(
    int recents,
    int favorites,
    int bookmarks,
    int settings,
  ) {
    return 'Restored $recents recents, $favorites favorites, $bookmarks bookmarks, $settings settings.';
  }

  @override
  String get backupExportTitle => 'Create Encrypted Backup';

  @override
  String get backupExportSelectItems => 'Select components to include:';

  @override
  String get backupIncludeRecents => 'Recent files history';

  @override
  String get backupIncludeFavorites => 'Favorite files list';

  @override
  String get backupIncludeBookmarks => 'Document bookmarks';

  @override
  String get backupIncludeSettings => 'App settings & preferences';

  @override
  String backupIncludeFiles(int count) {
    return 'Open documents ($count files)';
  }

  @override
  String get backupPasswordHeader => 'Encryption Password:';

  @override
  String get backupPasswordLabel => 'Password';

  @override
  String get backupConfirmPasswordLabel => 'Confirm Password';

  @override
  String get backupPasswordTooShort =>
      'Password must be at least 6 characters.';

  @override
  String get backupPasswordsDoNotMatch => 'Passwords do not match.';

  @override
  String get backupPasswordWarning =>
      'Keep this password safe. If forgotten, this backup archive cannot be decrypted.';

  @override
  String get backupCreateAction => 'Create Backup';

  @override
  String get backupEnterPasswordTitle => 'Unlock Backup Archive';

  @override
  String get backupEnterPasswordPrompt =>
      'Enter the password used to encrypt this .txdata archive:';

  @override
  String get backupUnlockAction => 'Unlock & Inspect';

  @override
  String get backupRestoreTitle => 'Restore Backup Archive';

  @override
  String backupCreatedOn(String date) {
    return 'Archive created on $date';
  }

  @override
  String get backupSelectRestoreItems => 'Select items to restore:';

  @override
  String backupRecentsCount(int count) {
    return 'Recent files ($count items)';
  }

  @override
  String backupFavoritesCount(int count) {
    return 'Favorite files ($count items)';
  }

  @override
  String backupBookmarksCount(int count) {
    return 'Document bookmarks ($count items)';
  }

  @override
  String backupSettingsCount(int count) {
    return 'App settings ($count preferences)';
  }

  @override
  String backupFilesCount(int count) {
    return 'Attached document files ($count files)';
  }

  @override
  String get backupMergeModeTitle => 'Merge with existing data';

  @override
  String get backupMergeModeSubtitle =>
      'Preserves existing records and adds missing ones.';

  @override
  String get backupReplaceModeSubtitle =>
      'Replaces existing records with items from this backup.';

  @override
  String get backupRestoreAction => 'Restore Data';

  @override
  String get vaultTitle => 'Biometric Vault';

  @override
  String get vaultLockAction => 'Lock in Biometric Vault';

  @override
  String get vaultUnlockAction => 'Unlock Document';

  @override
  String get p2pFileTransferTitle => 'Document Transfer';

  @override
  String get columnSelectionTitle => 'Column & Multi-Cursor Edit';

  @override
  String get columnSelectionAction => 'Column / Multi-Cursor';

  @override
  String columnSelectionLines(int start, int end, int count) {
    return 'Lines $start to $end ($count lines)';
  }

  @override
  String get columnSelectionStartLine => 'Start line';

  @override
  String get columnSelectionEndLine => 'End line';

  @override
  String get columnSelectionAllLines => 'All lines';

  @override
  String get columnSelectionCurrentLines => 'Selection';

  @override
  String get columnModePrefixSuffix => 'Prefix / Suffix';

  @override
  String get columnModeBlock => 'Column Block';

  @override
  String get columnModeInsertAtCol => 'Insert at Column';

  @override
  String get columnModeNumbering => 'Numbering';

  @override
  String get columnPrefixLabel => 'Prefix (start of line)';

  @override
  String get columnSuffixLabel => 'Suffix (end of line)';

  @override
  String get columnStartColLabel => 'Start column';

  @override
  String get columnEndColLabel => 'End column';

  @override
  String get columnInsertColLabel => 'Column index';

  @override
  String get columnInsertTextLabel => 'Text to insert';

  @override
  String get columnPadShorterLines => 'Pad shorter lines with spaces';

  @override
  String get columnNumberStart => 'Start number';

  @override
  String get columnNumberStep => 'Step';

  @override
  String get columnNumberFormat => 'Format template (%d)';

  @override
  String get columnNumberPadding => 'Zero padding digits';

  @override
  String get columnLivePreview => 'Live Preview';

  @override
  String get columnApplyAction => 'Apply Edits';

  @override
  String get columnCopyBlockAction => 'Copy Block';

  @override
  String get columnCutBlockAction => 'Cut Block';

  @override
  String get columnDeleteBlockAction => 'Delete Block';

  @override
  String get columnBlockCopied => 'Column block copied to clipboard';

  @override
  String columnEditsApplied(int count) {
    return 'Applied bulk edits across $count lines';
  }

  @override
  String get columnTrimWhitespace => 'Trim whitespace';

  @override
  String get privacyShieldTitle => 'Offline Privacy Shield';

  @override
  String get privacyShieldSubtitle =>
      'On-device PII & secret credentials scanner';

  @override
  String get privacyShieldAction => 'Privacy Shield & Scrubbing';

  @override
  String get privacyModeRedact => 'Redact';

  @override
  String get privacyModeHash => 'Salted Hash';

  @override
  String get privacyModeAnonymize => 'Anonymize';

  @override
  String get privacySelectAll => 'All Items';

  @override
  String get privacyTabDetections => 'Detected Items';

  @override
  String get privacyTabPreview => 'Full Preview';

  @override
  String get privacyCleanTitle => 'No Sensitive Data Detected';

  @override
  String get privacyCleanDescription =>
      'No emails, phone numbers, cards, IP addresses, or secret keys found in this file.';

  @override
  String get privacyApplyToBuffer => 'Apply to Document';

  @override
  String get privacyShareScrubbed => 'Share Scrubbed';

  @override
  String get privacyExportScrubbed => 'Export Scrubbed';

  @override
  String get privacyShareFailed => 'Could not share the scrubbed document.';

  @override
  String get liveDiffTitle => 'Live Diff & Delta Sync';

  @override
  String get liveDiffAction => 'Live P2P Diff & Sync';

  @override
  String get liveDiffAutoMerge => 'Auto-Merge';

  @override
  String get liveDiffAcceptMine => 'Accept All Mine';

  @override
  String get liveDiffAcceptPeer => 'Accept All Peer';

  @override
  String get liveDiffSideBySide => 'Side-by-Side';

  @override
  String get liveDiffUnified => 'Unified Diff';

  @override
  String get liveDiffPreview => 'Merge Preview';

  @override
  String get liveDiffPushToPeer => 'Push My Edits to Peer';

  @override
  String get liveDiffSaveMerged => 'Save Merged Document';

  @override
  String vaultLockBody(String fileName) {
    return 'Encrypt \"$fileName\" using AES-256-GCM hardware key encryption.';
  }

  @override
  String get vaultLockNote =>
      'The resulting .txvault file can only be decrypted and read by this app using your fingerprint or device biometrics.';

  @override
  String get vaultEncryptAndSave => 'Encrypt & Save';

  @override
  String vaultSavedAs(String fileName) {
    return 'Encrypted vault saved as \"$fileName\"';
  }

  @override
  String get vaultSaveFailed => 'Could not save encrypted vault file.';

  @override
  String vaultBiometricReason(String fileName) {
    return 'Lock $fileName in Biometric Vault';
  }

  @override
  String get aboutMadeInIndia => 'Made with ❤ from India';

  @override
  String get diffStartLiveSync => 'Start P2P Live Sync with Peer';

  @override
  String get diffCompareLocalFile => 'Compare with Local File (SAF)';

  @override
  String get diffNoCsvData => 'No CSV data to compare.';

  @override
  String get diffNoDifferences =>
      'No differences found. Documents are identical.';

  @override
  String get diffAcceptMineSide => '← Mine';

  @override
  String get diffAcceptPeerSide => 'Peer →';

  @override
  String get diffAcceptBoth => 'Both';

  @override
  String get liveDiffApplied => 'Applied merged changes to open document.';

  @override
  String liveDiffSavedAs(String fileName) {
    return 'Saved merged file as \"$fileName\"';
  }

  @override
  String get liveDiffSaveFailed => 'Could not save merged file.';

  @override
  String get liveDiffAutoMergeClean => 'Auto-Merge Clean Changes';

  @override
  String get p2pReadFileFailed => 'Could not read selected file.';

  @override
  String get p2pReadTabFailed => 'Could not read open tab content.';

  @override
  String get p2pPickFromStorage => 'Pick from Device Storage (SAF)';

  @override
  String syncClientSavedAs(String fileName) {
    return 'File saved as \"$fileName\"';
  }

  @override
  String get syncClientSaveFailed => 'Could not save received file.';

  @override
  String get syncClientPickLocalFile => 'Pick Local File (SAF)';

  @override
  String syncClientComparingWith(String fileName) {
    return 'Comparing with: $fileName';
  }

  @override
  String get columnReplaceLabel => 'Replace column block with (optional)';

  @override
  String get columnReplaceHint => 'Leave empty to keep or delete';

  @override
  String get diffSheetTitle => 'Live Document Diff & Delta Sync';

  @override
  String diffSheetSubtitle(String fileName) {
    return 'Compare \"$fileName\" side-by-side and selectively merge edits.';
  }

  @override
  String get diffStartLiveSyncSubtitle =>
      'Connect with another device over local Wi-Fi to diff & pair-edit.';

  @override
  String get diffCompareLocalFileSubtitle =>
      'Pick a second document from device storage.';

  @override
  String get diffReadChosenFileFailed => 'Could not read chosen file for diff.';

  @override
  String get diffCompareOpenTab => 'Or Compare with Open Tab:';

  @override
  String get diffReadTabFailed => 'Could not read tab for comparison.';

  @override
  String get syncClientSaving => 'Saving...';

  @override
  String get syncClientSaveToDevice => 'Save to Device (SAF)';

  @override
  String get syncClientMatchOpenTab => 'Or match with an open tab:';

  @override
  String get featuresSectionTitle => 'Features';

  @override
  String get featuresCardSubtitle =>
      'Explore all capabilities of SreerajP Text App';

  @override
  String get featuresHeaderTitle => 'SreerajP Text App Features';

  @override
  String get featuresHeaderSubtitle =>
      'Explore every document format, powerful editor tool, offline sync, and privacy safeguard built for you.';

  @override
  String get appearThemeSepiaInfo =>
      'Sepia mode provides a warm, paper-like low-contrast look designed for comfortable long reading.';

  @override
  String get appearThemeSystemInfo =>
      'System mode automatically matches your device\'s system-wide dark mode setting.';

  @override
  String get appearEnglishFontSample => 'The quick brown fox • 0123';

  @override
  String get appearMalayalamFontSample => 'മലയാളം സുന്ദരമാണ്';

  @override
  String get helpSectionHeader => 'Help Center & User Guides';

  @override
  String get helpSectionSubtitle =>
      'Browse in-depth guides and tips for all features of SreerajP Text App.';

  @override
  String get helpCategoryEditing => 'Editing & Documents';

  @override
  String get helpCategoryData => 'Data Querying & Analysis';

  @override
  String get helpCategoryPrivacy => 'Privacy & Security';

  @override
  String get helpCategorySync => 'Sync & AirQR Transfer';

  @override
  String get helpCategoryVoice => 'Voice & Accessibility';

  @override
  String get helpCategoryFaq => 'Frequently Asked Questions';
}
