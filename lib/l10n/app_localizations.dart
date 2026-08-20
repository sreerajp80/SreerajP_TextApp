import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ml.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ml'),
  ];

  /// The application name.
  ///
  /// In en, this message translates to:
  /// **'TextData'**
  String get appTitle;

  /// Generic cancel button.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// Generic save button.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get actionSave;

  /// Generic confirm button.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get actionOk;

  /// Generic copy button/tooltip.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get actionCopy;

  /// Generic remove button/tooltip.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get actionRemove;

  /// Clear the whole list.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get actionClearAll;

  /// Generic continue button.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get actionContinue;

  /// Open a file via the system picker.
  ///
  /// In en, this message translates to:
  /// **'Open a file'**
  String get actionOpenFile;

  /// Create a supported document via the system picker.
  ///
  /// In en, this message translates to:
  /// **'New document'**
  String get actionNewDocument;

  /// Title of the new-document format picker.
  ///
  /// In en, this message translates to:
  /// **'Choose a document type'**
  String get newDocumentChooseFormat;

  /// New-document format: plain text.
  ///
  /// In en, this message translates to:
  /// **'Text (TXT)'**
  String get newDocumentTxt;

  /// New-document format: Markdown.
  ///
  /// In en, this message translates to:
  /// **'Markdown (MD)'**
  String get newDocumentMarkdown;

  /// New-document format: CSV.
  ///
  /// In en, this message translates to:
  /// **'Table (CSV)'**
  String get newDocumentCsv;

  /// New-document format: JSON.
  ///
  /// In en, this message translates to:
  /// **'Data (JSON)'**
  String get newDocumentJson;

  /// New-document format: XML.
  ///
  /// In en, this message translates to:
  /// **'Data (XML)'**
  String get newDocumentXml;

  /// Undo action tooltip.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get actionUndo;

  /// Redo action tooltip.
  ///
  /// In en, this message translates to:
  /// **'Redo'**
  String get actionRedo;

  /// Find action tooltip.
  ///
  /// In en, this message translates to:
  /// **'Find'**
  String get actionFind;

  /// Find and replace menu item.
  ///
  /// In en, this message translates to:
  /// **'Find & replace'**
  String get actionFindReplace;

  /// Share menu item.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get actionShare;

  /// Share-as-zip menu item.
  ///
  /// In en, this message translates to:
  /// **'Share as zip'**
  String get actionShareZip;

  /// Print menu item.
  ///
  /// In en, this message translates to:
  /// **'Print'**
  String get actionPrint;

  /// Export menu item.
  ///
  /// In en, this message translates to:
  /// **'Export…'**
  String get actionExport;

  /// File-info menu item.
  ///
  /// In en, this message translates to:
  /// **'File info'**
  String get actionFileInfo;

  /// Generic go/confirm button.
  ///
  /// In en, this message translates to:
  /// **'Go'**
  String get actionGo;

  /// Save-as-a-copy button (shared).
  ///
  /// In en, this message translates to:
  /// **'Save as a copy'**
  String get actionSaveAsCopy;

  /// Menu item opening the save options (encoding, line ending, save a copy).
  ///
  /// In en, this message translates to:
  /// **'Save as…'**
  String get actionSaveAs;

  /// Restore a recovered draft (shared).
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get actionRestore;

  /// Discard a recovered draft (shared).
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get actionDiscard;

  /// Retry opening a file (shared).
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get actionRetry;

  /// Draft-recovery banner text (shared).
  ///
  /// In en, this message translates to:
  /// **'Unsaved changes from a previous session were found.'**
  String get draftBannerText;

  /// Failure-state title (shared).
  ///
  /// In en, this message translates to:
  /// **'Can\'t open this file'**
  String get failCantOpenTitle;

  /// Default failure-state body (shared).
  ///
  /// In en, this message translates to:
  /// **'This file could not be opened.'**
  String get failCannotOpen;

  /// Read-aloud button tooltip (shared).
  ///
  /// In en, this message translates to:
  /// **'Read aloud'**
  String get readAloud;

  /// Stop-reading tooltip (shared).
  ///
  /// In en, this message translates to:
  /// **'Stop reading'**
  String get readAloudStop;

  /// Snackbar when read-aloud can't run (shared).
  ///
  /// In en, this message translates to:
  /// **'Read aloud is not available right now.'**
  String get readAloudUnavailable;

  /// Split confirm button (shared).
  ///
  /// In en, this message translates to:
  /// **'Split'**
  String get actionSplit;

  /// Next button (shared).
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get actionNext;

  /// Split cancelled partway (shared).
  ///
  /// In en, this message translates to:
  /// **'Stopped after saving {done} of {total} parts.'**
  String splitStopped(int done, int total);

  /// All split parts saved (shared).
  ///
  /// In en, this message translates to:
  /// **'Saved {count} parts.'**
  String splitSaved(int count);

  /// File merged (shared).
  ///
  /// In en, this message translates to:
  /// **'Merged {name}. Review and save.'**
  String mergedReview(String name);

  /// Encoding field label (shared).
  ///
  /// In en, this message translates to:
  /// **'Encoding'**
  String get labelEncoding;

  /// Line-ending field label (shared).
  ///
  /// In en, this message translates to:
  /// **'Line ending'**
  String get labelLineEnding;

  /// Delimiter field label (shared).
  ///
  /// In en, this message translates to:
  /// **'Delimiter'**
  String get labelDelimiter;

  /// Generic yes (shared).
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get commonYes;

  /// Generic no (shared).
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get commonNo;

  /// File-info: size (shared).
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get infoSize;

  /// File-info: modified date (shared).
  ///
  /// In en, this message translates to:
  /// **'Modified'**
  String get infoModified;

  /// File-info sheet title (shared).
  ///
  /// In en, this message translates to:
  /// **'File info'**
  String get infoTitle;

  /// Save-options sheet title (shared).
  ///
  /// In en, this message translates to:
  /// **'Save options'**
  String get saveOptionsTitle;

  /// Snackbar after a successful overwrite save.
  ///
  /// In en, this message translates to:
  /// **'Saved.'**
  String get saveDone;

  /// Snackbar after save-as-copy.
  ///
  /// In en, this message translates to:
  /// **'Saved a copy: {name}.'**
  String saveCopyDone(String name);

  /// Fallback name for a saved copy with no name.
  ///
  /// In en, this message translates to:
  /// **'new file'**
  String get saveNewFile;

  /// Snackbar when a save is blocked by the gate.
  ///
  /// In en, this message translates to:
  /// **'Could not save.'**
  String get saveCouldNot;

  /// Snackbar when the file is read-only.
  ///
  /// In en, this message translates to:
  /// **'This file is read-only.'**
  String get saveReadOnly;

  /// Snackbar when a save fails.
  ///
  /// In en, this message translates to:
  /// **'Could not save the file.'**
  String get saveFailed;

  /// Export sheet title (shared).
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get exportSheetTitle;

  /// Export-target picker title (shared).
  ///
  /// In en, this message translates to:
  /// **'Export as'**
  String get exportAsTitle;

  /// Export scope: all rows.
  ///
  /// In en, this message translates to:
  /// **'All rows'**
  String get exportAllRows;

  /// Export scope: filtered rows.
  ///
  /// In en, this message translates to:
  /// **'Filtered'**
  String get exportFilteredRows;

  /// Export scope: selected rows.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get exportSelectedRows;

  /// Title after an export is created.
  ///
  /// In en, this message translates to:
  /// **'Created {name}'**
  String exportCreated(String name);

  /// Save the exported result as a copy.
  ///
  /// In en, this message translates to:
  /// **'Save a copy'**
  String get exportSaveCopy;

  /// Snackbar: share failed (shared).
  ///
  /// In en, this message translates to:
  /// **'Could not share the file.'**
  String get outShareFileFailed;

  /// Snackbar: share-as-zip failed (shared).
  ///
  /// In en, this message translates to:
  /// **'Could not share the zip.'**
  String get outShareZipFailed;

  /// Snackbar: print failed (shared).
  ///
  /// In en, this message translates to:
  /// **'Could not print the file.'**
  String get outPrintFailed;

  /// Snackbar: export failed (shared).
  ///
  /// In en, this message translates to:
  /// **'Could not create the export.'**
  String get outExportFailed;

  /// Snackbar: share-export failed (shared).
  ///
  /// In en, this message translates to:
  /// **'Could not share the export.'**
  String get outShareExportFailed;

  /// Snackbar after saving an exported file (shared).
  ///
  /// In en, this message translates to:
  /// **'Saved {name}.'**
  String outSaved(String name);

  /// Title of the Home / Recent files screen.
  ///
  /// In en, this message translates to:
  /// **'Recent files'**
  String get homeTitle;

  /// Empty-state title on Home.
  ///
  /// In en, this message translates to:
  /// **'No recent files'**
  String get homeEmptyTitle;

  /// Confirm dialog title for clearing recents.
  ///
  /// In en, this message translates to:
  /// **'Clear recent files?'**
  String get homeClearAllTitle;

  /// Confirm dialog body for clearing recents.
  ///
  /// In en, this message translates to:
  /// **'This removes the list only. Your files are not deleted.'**
  String get homeClearAllBody;

  /// Subtitle for a recent file whose URI is no longer accessible.
  ///
  /// In en, this message translates to:
  /// **'Unavailable — file moved, deleted, or access revoked'**
  String get homeUnavailable;

  /// Confirm button in the clear-recents dialog.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get homeClearConfirm;

  /// Tooltip on the per-item remove action.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get homeRemoveTooltip;

  /// Tooltip on the clear-all action.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get homeClearAllTooltip;

  /// Empty-state body on Home.
  ///
  /// In en, this message translates to:
  /// **'Open a text or data file to get started. It will show up here next time.'**
  String get homeEmptyBody;

  /// Error-state title on Home.
  ///
  /// In en, this message translates to:
  /// **'Could not load recent files'**
  String get homeLoadError;

  /// Navigation label for Home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// Navigation label for the Editor workspace.
  ///
  /// In en, this message translates to:
  /// **'Editor'**
  String get navEditor;

  /// Navigation label for Settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// Tab: close tooltip.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get tabClose;

  /// Tab menu: close other tabs.
  ///
  /// In en, this message translates to:
  /// **'Close others'**
  String get tabCloseOthers;

  /// Tab menu: close all tabs.
  ///
  /// In en, this message translates to:
  /// **'Close all'**
  String get tabCloseAll;

  /// Workspace empty-state title.
  ///
  /// In en, this message translates to:
  /// **'No open documents'**
  String get tabNoDocuments;

  /// Workspace empty-state body.
  ///
  /// In en, this message translates to:
  /// **'Open a file from Home to start.'**
  String get tabOpenFromHome;

  /// Snackbar when closing a tab fails to save.
  ///
  /// In en, this message translates to:
  /// **'Could not save; tab kept open.'**
  String get tabCouldNotSave;

  /// Banner shown when another app changed the open file.
  ///
  /// In en, this message translates to:
  /// **'This file changed on disk.'**
  String get fileChangedBanner;

  /// Banner action: load the file from disk again.
  ///
  /// In en, this message translates to:
  /// **'Reload'**
  String get fileChangedReload;

  /// Banner action: keep the current content and hide the warning.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get fileChangedDismiss;

  /// Snackbar when reloading the changed file fails.
  ///
  /// In en, this message translates to:
  /// **'Could not reload the file.'**
  String get fileChangedReloadFailed;

  /// Confirm dialog title before reloading a tab with unsaved edits.
  ///
  /// In en, this message translates to:
  /// **'Reload and lose your edits?'**
  String get fileChangedConfirmTitle;

  /// Confirm dialog body before reloading a tab with unsaved edits.
  ///
  /// In en, this message translates to:
  /// **'\"{fileName}\" has unsaved edits. Reloading loads the file from disk and throws those edits away.'**
  String fileChangedConfirmBody(String fileName);

  /// Confirm dialog action: reload, discarding unsaved edits.
  ///
  /// In en, this message translates to:
  /// **'Reload and discard'**
  String get fileChangedConfirmReload;

  /// Confirm dialog action: keep the edits, do not reload.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get fileChangedConfirmCancel;

  /// Unsaved-changes dialog title.
  ///
  /// In en, this message translates to:
  /// **'Save changes?'**
  String get unsavedTitle;

  /// Unsaved-changes dialog body.
  ///
  /// In en, this message translates to:
  /// **'\"{fileName}\" has unsaved changes. What would you like to do?'**
  String unsavedBody(String fileName);

  /// Unsaved-changes dialog: keep editing.
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get unsavedKeepEditing;

  /// Degraded view: previous page tooltip.
  ///
  /// In en, this message translates to:
  /// **'Previous page'**
  String get degradedPrevPage;

  /// Degraded view: next page tooltip.
  ///
  /// In en, this message translates to:
  /// **'Next page'**
  String get degradedNextPage;

  /// Degraded view: 'Page' label.
  ///
  /// In en, this message translates to:
  /// **'Page'**
  String get degradedPageLabel;

  /// Degraded view: 'of N' page count.
  ///
  /// In en, this message translates to:
  /// **'of {count}'**
  String degradedOfCount(int count);

  /// Degraded view: large-file banner.
  ///
  /// In en, this message translates to:
  /// **'This file is large. It is open in read-only mode; editing is turned off.'**
  String get degradedLargeBanner;

  /// Degraded view: retry button.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get degradedTryAgain;

  /// Placeholder view: coming-soon note.
  ///
  /// In en, this message translates to:
  /// **'The viewer for this file type is coming in a later phase.'**
  String get placeholderComingSoon;

  /// Placeholder view: fallback details.
  ///
  /// In en, this message translates to:
  /// **'Opened file'**
  String get placeholderOpenedFile;

  /// Overwrite-confirm dialog title.
  ///
  /// In en, this message translates to:
  /// **'Overwrite the file?'**
  String get overwriteTitle;

  /// Overwrite-confirm dialog body.
  ///
  /// In en, this message translates to:
  /// **'This replaces the original file with your changes. You can turn off this check in Settings › Editor.'**
  String get overwriteBody;

  /// Overwrite-confirm button.
  ///
  /// In en, this message translates to:
  /// **'Overwrite'**
  String get overwriteConfirm;

  /// Snackbar when some saved tabs could not be restored.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 saved tab could not be reopened (file moved, deleted, or access revoked).} other{{count} saved tabs could not be reopened (file moved, deleted, or access revoked).}}'**
  String shellTabsSkipped(int count);

  /// Skip button on onboarding.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkip;

  /// Next button on onboarding.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingNext;

  /// Final button on onboarding.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get onboardingGetStarted;

  /// Onboarding page 1 title.
  ///
  /// In en, this message translates to:
  /// **'Read and edit your files'**
  String get onboarding1Title;

  /// Onboarding page 1 body.
  ///
  /// In en, this message translates to:
  /// **'Open TXT, Markdown, CSV, JSON, and XML files — view them, edit them, and save changes back safely.'**
  String get onboarding1Body;

  /// Onboarding page 2 title.
  ///
  /// In en, this message translates to:
  /// **'Private and offline'**
  String get onboarding2Title;

  /// Onboarding page 2 body.
  ///
  /// In en, this message translates to:
  /// **'Everything works offline. Files open only through the system picker, so the app never browses your storage on its own.'**
  String get onboarding2Body;

  /// Onboarding page 3 title.
  ///
  /// In en, this message translates to:
  /// **'Share across devices'**
  String get onboarding3Title;

  /// Onboarding page 3 body.
  ///
  /// In en, this message translates to:
  /// **'Move your app data between two devices on the same Wi-Fi — no server and no internet needed.'**
  String get onboarding3Body;

  /// Security settings section header.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get securitySectionTitle;

  /// Security settings card description.
  ///
  /// In en, this message translates to:
  /// **'Protect app access and private data.'**
  String get securityCardSubtitle;

  /// App-lock toggle title.
  ///
  /// In en, this message translates to:
  /// **'App lock'**
  String get securityAppLockTitle;

  /// App-lock toggle subtitle.
  ///
  /// In en, this message translates to:
  /// **'Require a PIN (or biometric) to open the app.'**
  String get securityAppLockSubtitle;

  /// Change-PIN action.
  ///
  /// In en, this message translates to:
  /// **'Change PIN'**
  String get securityChangePin;

  /// Regenerate recovery code action.
  ///
  /// In en, this message translates to:
  /// **'Show a new recovery code'**
  String get securityShowNewRecovery;

  /// Subtitle for regenerate recovery.
  ///
  /// In en, this message translates to:
  /// **'Replaces the old one. Use if you lost your recovery code.'**
  String get securityShowNewRecoverySubtitle;

  /// Biometric toggle title.
  ///
  /// In en, this message translates to:
  /// **'Biometric unlock'**
  String get securityBiometricTitle;

  /// Biometric toggle subtitle.
  ///
  /// In en, this message translates to:
  /// **'Use fingerprint or face to unlock, when the device supports it.'**
  String get securityBiometricSubtitle;

  /// Screenshot-protection toggle title.
  ///
  /// In en, this message translates to:
  /// **'Block screenshots on the pairing screen'**
  String get securityScreenshotTitle;

  /// Screenshot-protection toggle subtitle.
  ///
  /// In en, this message translates to:
  /// **'Hides the app from screenshots and screen recording. The pairing code / QR screen is always protected.'**
  String get securityScreenshotSubtitle;

  /// Title when setting a PIN to enable app-lock.
  ///
  /// In en, this message translates to:
  /// **'Set an app-lock PIN'**
  String get securitySetPinTitle;

  /// Subtitle when setting a PIN to enable app-lock.
  ///
  /// In en, this message translates to:
  /// **'You will need this PIN to open the app.'**
  String get securitySetPinSubtitle;

  /// Confirm dialog title when disabling app-lock.
  ///
  /// In en, this message translates to:
  /// **'Turn off app lock?'**
  String get securityTurnOffTitle;

  /// Confirm dialog body when disabling app-lock.
  ///
  /// In en, this message translates to:
  /// **'This removes your PIN and recovery code. The app will open without unlocking.'**
  String get securityTurnOffBody;

  /// Confirm button to disable app-lock.
  ///
  /// In en, this message translates to:
  /// **'Turn off'**
  String get securityTurnOff;

  /// Snackbar after changing the PIN.
  ///
  /// In en, this message translates to:
  /// **'PIN changed'**
  String get securityPinChanged;

  /// Lock screen prompt.
  ///
  /// In en, this message translates to:
  /// **'Enter your PIN'**
  String get lockEnterPin;

  /// PIN text field label.
  ///
  /// In en, this message translates to:
  /// **'PIN'**
  String get lockPinLabel;

  /// Unlock button.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get lockUnlock;

  /// Biometric unlock button.
  ///
  /// In en, this message translates to:
  /// **'Use biometric'**
  String get lockUseBiometric;

  /// Forgot-PIN link.
  ///
  /// In en, this message translates to:
  /// **'Forgot PIN?'**
  String get lockForgotPin;

  /// Error after a wrong PIN.
  ///
  /// In en, this message translates to:
  /// **'Wrong PIN. Try again.'**
  String get lockWrongPin;

  /// Recovery-code entry dialog title.
  ///
  /// In en, this message translates to:
  /// **'Enter recovery code'**
  String get lockEnterRecoveryTitle;

  /// Recovery-code entry hint.
  ///
  /// In en, this message translates to:
  /// **'ABCD-EFGH-JKMN'**
  String get lockRecoveryHint;

  /// Error after a wrong recovery code.
  ///
  /// In en, this message translates to:
  /// **'That recovery code is not correct.'**
  String get lockRecoveryWrong;

  /// Title when choosing a new PIN after recovery.
  ///
  /// In en, this message translates to:
  /// **'Set a new PIN'**
  String get lockSetNewPinTitle;

  /// Subtitle when choosing a new PIN after recovery.
  ///
  /// In en, this message translates to:
  /// **'Your recovery code was accepted. Choose a new PIN.'**
  String get lockSetNewPinSubtitle;

  /// System biometric prompt reason.
  ///
  /// In en, this message translates to:
  /// **'Unlock TextData'**
  String get lockBiometricReason;

  /// Default set-PIN screen title.
  ///
  /// In en, this message translates to:
  /// **'Set a PIN'**
  String get setPinTitle;

  /// Default set-PIN screen subtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a PIN of at least 4 digits.'**
  String get setPinSubtitle;

  /// Confirm-PIN field label.
  ///
  /// In en, this message translates to:
  /// **'Confirm PIN'**
  String get setPinConfirmLabel;

  /// Save-PIN button.
  ///
  /// In en, this message translates to:
  /// **'Save PIN'**
  String get setPinSave;

  /// Error when the PIN is too short.
  ///
  /// In en, this message translates to:
  /// **'Use at least {min} digits.'**
  String setPinTooShort(int min);

  /// Error when the two PINs differ.
  ///
  /// In en, this message translates to:
  /// **'The two PINs do not match.'**
  String get setPinMismatch;

  /// Recovery-code screen title.
  ///
  /// In en, this message translates to:
  /// **'Save your recovery code'**
  String get recoveryTitle;

  /// Recovery-code screen explanation.
  ///
  /// In en, this message translates to:
  /// **'If you forget your PIN, this recovery code is the only way back in. Write it down and keep it somewhere safe. It is shown only once.'**
  String get recoveryBody;

  /// Snackbar after copying the recovery code.
  ///
  /// In en, this message translates to:
  /// **'Recovery code copied'**
  String get recoveryCopied;

  /// Button to dismiss the recovery-code screen.
  ///
  /// In en, this message translates to:
  /// **'I have saved it'**
  String get recoverySaved;

  /// Settings screen title.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Appearance settings section header.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearSectionTitle;

  /// Appearance settings card description.
  ///
  /// In en, this message translates to:
  /// **'Theme, text size, font, and line spacing.'**
  String get appearCardSubtitle;

  /// Theme label.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get appearTheme;

  /// Font-size slider label.
  ///
  /// In en, this message translates to:
  /// **'Font size'**
  String get appearFontSize;

  /// Font-family label.
  ///
  /// In en, this message translates to:
  /// **'Font family'**
  String get appearFontFamily;

  /// Malayalam font-family label.
  ///
  /// In en, this message translates to:
  /// **'Malayalam font'**
  String get appearMalayalamFontFamily;

  /// Line-spacing slider label.
  ///
  /// In en, this message translates to:
  /// **'Line spacing'**
  String get appearLineSpacing;

  /// Default word-wrap toggle title.
  ///
  /// In en, this message translates to:
  /// **'Word wrap'**
  String get appearWordWrapTitle;

  /// Default word-wrap toggle subtitle.
  ///
  /// In en, this message translates to:
  /// **'Wrap long lines by default in text files.'**
  String get appearWordWrapSubtitle;

  /// App language setting label.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get appearLanguage;

  /// Language choice: follow the device language.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get languageSystem;

  /// Language choice: English.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// Language choice: Malayalam.
  ///
  /// In en, this message translates to:
  /// **'Malayalam'**
  String get languageMalayalam;

  /// Editor settings section header.
  ///
  /// In en, this message translates to:
  /// **'Editor'**
  String get editorSectionTitle;

  /// Editor settings card description.
  ///
  /// In en, this message translates to:
  /// **'Saving, line endings, and editing defaults.'**
  String get editorCardSubtitle;

  /// Editor: default encoding setting.
  ///
  /// In en, this message translates to:
  /// **'Default encoding on save'**
  String get editorDefaultEncoding;

  /// Editor: preserve-encoding subtitle.
  ///
  /// In en, this message translates to:
  /// **'Preserve keeps the file’s own encoding.'**
  String get editorPreserveEncoding;

  /// Editor: default line-ending setting.
  ///
  /// In en, this message translates to:
  /// **'Default line ending on save'**
  String get editorDefaultLineEnding;

  /// Editor: preserve-line-ending subtitle.
  ///
  /// In en, this message translates to:
  /// **'Preserve keeps the file’s own line ending.'**
  String get editorPreserveLineEnding;

  /// Editor: confirm-overwrite toggle.
  ///
  /// In en, this message translates to:
  /// **'Confirm before overwriting'**
  String get editorConfirmOverwrite;

  /// Editor: confirm-overwrite subtitle.
  ///
  /// In en, this message translates to:
  /// **'Ask before replacing the original file when you save.'**
  String get editorConfirmOverwriteSub;

  /// Editor: open-read-only toggle.
  ///
  /// In en, this message translates to:
  /// **'Open files read-only by default'**
  String get editorOpenReadOnly;

  /// Editor: open-read-only subtitle.
  ///
  /// In en, this message translates to:
  /// **'New tabs start locked; unlock to edit.'**
  String get editorOpenReadOnlySub;

  /// Editor: auto-save interval slider label.
  ///
  /// In en, this message translates to:
  /// **'Auto-save draft every'**
  String get editorAutoSaveLabel;

  /// Editor: auto-save disabled.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get editorAutoSaveOff;

  /// Editor: auto-save interval in seconds.
  ///
  /// In en, this message translates to:
  /// **'{seconds} s'**
  String editorAutoSaveValue(int seconds);

  /// Editor: leave-edit-mode-after-saving toggle.
  ///
  /// In en, this message translates to:
  /// **'Leave edit mode after saving'**
  String get editorExitEditAfterSave;

  /// Editor: leave-edit-mode-after-saving subtitle.
  ///
  /// In en, this message translates to:
  /// **'Go back to view mode when a save succeeds.'**
  String get editorExitEditAfterSaveSub;

  /// Files & Tabs settings section header.
  ///
  /// In en, this message translates to:
  /// **'Files & Tabs'**
  String get filesTabsSectionTitle;

  /// Files and Tabs settings card description.
  ///
  /// In en, this message translates to:
  /// **'Tab limits and restore behavior.'**
  String get filesTabsCardSubtitle;

  /// Files: auto cap (unknown value).
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get filesAuto;

  /// Files: auto cap with the resolved number.
  ///
  /// In en, this message translates to:
  /// **'{cap, plural, =1{Auto — 1 tab} other{Auto — {cap} tabs}}'**
  String filesAutoCap(int cap);

  /// Files: automatic-limit toggle.
  ///
  /// In en, this message translates to:
  /// **'Automatic tab limit'**
  String get filesAutoLimit;

  /// Files: auto-limit subtitle.
  ///
  /// In en, this message translates to:
  /// **'Chosen from device memory ({label}).'**
  String filesChosenFromMemory(String label);

  /// Files: fixed-limit subtitle.
  ///
  /// In en, this message translates to:
  /// **'Using a fixed limit.'**
  String get filesUsingFixed;

  /// Files: max-open-tabs setting.
  ///
  /// In en, this message translates to:
  /// **'Maximum open tabs'**
  String get filesMaxOpenTabs;

  /// Files: over-limit behavior setting.
  ///
  /// In en, this message translates to:
  /// **'When the limit is reached'**
  String get filesWhenLimitReached;

  /// Files: restore-on-relaunch toggle.
  ///
  /// In en, this message translates to:
  /// **'Restore tabs on relaunch'**
  String get filesRestoreOnRelaunch;

  /// Files: restore-on-relaunch subtitle.
  ///
  /// In en, this message translates to:
  /// **'Reopen the files you had open when the app starts again.'**
  String get filesRestoreSub;

  /// Speech settings section header.
  ///
  /// In en, this message translates to:
  /// **'Speech (read aloud)'**
  String get speechSectionTitle;

  /// Speech settings card description.
  ///
  /// In en, this message translates to:
  /// **'Languages and text-to-speech voices.'**
  String get speechCardSubtitle;

  /// Speech: English toggle.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get speechEnglish;

  /// Speech: English toggle subtitle.
  ///
  /// In en, this message translates to:
  /// **'Read content aloud in English.'**
  String get speechEnglishSub;

  /// Speech: Malayalam toggle.
  ///
  /// In en, this message translates to:
  /// **'Malayalam'**
  String get speechMalayalam;

  /// Speech: Malayalam toggle subtitle.
  ///
  /// In en, this message translates to:
  /// **'Needs the Malayalam voice installed on this device.'**
  String get speechMalayalamSub;

  /// Speech: checking status.
  ///
  /// In en, this message translates to:
  /// **'Checking the Malayalam voice…'**
  String get speechChecking;

  /// Speech: Malayalam ready.
  ///
  /// In en, this message translates to:
  /// **'The Malayalam voice is ready.'**
  String get speechMlReady;

  /// Speech: Malayalam needs install.
  ///
  /// In en, this message translates to:
  /// **'The Malayalam voice is not installed yet. Install the voice data, then check again.'**
  String get speechMlNeedsInstall;

  /// Speech: install voice button.
  ///
  /// In en, this message translates to:
  /// **'Install voice data'**
  String get speechInstallVoice;

  /// Speech: open TTS settings button.
  ///
  /// In en, this message translates to:
  /// **'Open TTS settings'**
  String get speechOpenTtsSettings;

  /// Speech: re-check button.
  ///
  /// In en, this message translates to:
  /// **'Check again'**
  String get speechCheckAgain;

  /// Speech: no TTS engine.
  ///
  /// In en, this message translates to:
  /// **'No text-to-speech engine is available on this device.'**
  String get speechNoEngine;

  /// Speech: could not open install screen.
  ///
  /// In en, this message translates to:
  /// **'Could not open the voice-install screen.'**
  String get speechCouldNotOpen;

  /// Sync settings section header.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get syncSectionTitle;

  /// Sync settings card description.
  ///
  /// In en, this message translates to:
  /// **'Choose what to share between devices.'**
  String get syncCardSubtitle;

  /// Sync settings: default categories note.
  ///
  /// In en, this message translates to:
  /// **'Categories to share by default. You can still change the selection each time you send.'**
  String get syncDefaultCategories;

  /// Sync settings: local-network note.
  ///
  /// In en, this message translates to:
  /// **'Sync stays on your local network. Only your display settings and the categories above are shared — never passwords, keys, or the pairing code.'**
  String get syncLocalNote;

  /// Sync settings: open-sync button.
  ///
  /// In en, this message translates to:
  /// **'Open sync'**
  String get syncOpenSync;

  /// Help section header.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get helpSectionTitle;

  /// Help settings card description.
  ///
  /// In en, this message translates to:
  /// **'Learn how app features work.'**
  String get helpCardSubtitle;

  /// Hint in Help search bar.
  ///
  /// In en, this message translates to:
  /// **'Search help topics…'**
  String get helpSearchFilterHint;

  /// Empty state when search matches no help topics.
  ///
  /// In en, this message translates to:
  /// **'No matching help topics found.'**
  String get helpNoTopicsFound;

  /// Help topic title for LAN sync and live diff.
  ///
  /// In en, this message translates to:
  /// **'LAN Sync & Live Diff'**
  String get helpP2pSyncTitle;

  /// Short subtitle for LAN sync and live diff.
  ///
  /// In en, this message translates to:
  /// **'Sync data and compare document versions live over Wi-Fi.'**
  String get helpP2pSyncSubtitle;

  /// Help text explaining LAN sync and live diff.
  ///
  /// In en, this message translates to:
  /// **'Sync favorites, bookmarks, recents, and display settings across devices on your local Wi-Fi without internet or external servers.\n\n• Live Diff & Delta Sync: Open any document, tap menu and select Live Diff to connect with a nearby device. View color-coded line-by-line differences and merge specific incoming changes directly.\n• Security: All sync communication is encrypted end-to-end using AES-256-GCM with a temporary pairing code. Nothing is ever sent over the internet.'**
  String get helpP2pSyncBody;

  /// Help topic title for air-gap QR transfer.
  ///
  /// In en, this message translates to:
  /// **'Optical QR Transfer (AirQR)'**
  String get helpQrSharingTitle;

  /// Short subtitle for the QR-sharing help card.
  ///
  /// In en, this message translates to:
  /// **'Transfer text and files visually without Wi-Fi, Bluetooth, or cables.'**
  String get helpQrSharingSubtitle;

  /// Help text explaining how QR sharing works.
  ///
  /// In en, this message translates to:
  /// **'Send documents or selections between devices using animated high-density QR codes and camera scanning without any network connection.\n\n• How to Send: Open a document, tap the menu and choose \"Send by QR\" or \"Send selection by QR\". Adjust speed and density if needed.\n• How to Receive: Open the AirQR screen on the receiver and point the camera at the sender\'s screen.\n• Encryption: Enable encryption to protect transfers with an AES-256 session passphrase.'**
  String get helpQrSharingBody;

  /// Help topic title for Privacy Shield.
  ///
  /// In en, this message translates to:
  /// **'Privacy Shield & PII Scrubber'**
  String get helpPrivacyShieldTitle;

  /// Short subtitle for Privacy Shield.
  ///
  /// In en, this message translates to:
  /// **'Detect and redact sensitive personal information completely offline.'**
  String get helpPrivacyShieldSubtitle;

  /// Help text explaining Privacy Shield.
  ///
  /// In en, this message translates to:
  /// **'Protect personal and confidential information before sharing or saving.\n\n• Automatic Detection: Privacy Shield scans text offline for email addresses, phone numbers, credit card numbers, IPv4/IPv6 addresses, national IDs (SSN/Aadhaar), and secret API keys/tokens.\n• Redact & Mask: Preview detected items, select specific categories to mask, and replace them with standard redaction tokens (e.g. [EMAIL], [PHONE]) or asterisks.\n• Zero Network Leakage: All scanning and scrubbing is performed purely on your device.'**
  String get helpPrivacyShieldBody;

  /// Help topic title for Document Vault and Backups.
  ///
  /// In en, this message translates to:
  /// **'Document Vault & Encrypted Backups'**
  String get helpVaultBackupTitle;

  /// Short subtitle for Document Vault and Backups.
  ///
  /// In en, this message translates to:
  /// **'Store sensitive files in an encrypted vault and export .txdata archives.'**
  String get helpVaultBackupSubtitle;

  /// Help text explaining Document Vault and Backups.
  ///
  /// In en, this message translates to:
  /// **'Keep sensitive files secure with hardware-backed encryption.\n\n• Document Vault: Store private files in an isolated AES-256-GCM encrypted vault protected by your app PIN or biometric authentication.\n• Encrypted Backups (.txdata): Export multiple documents and settings into password-protected encrypted .txdata archive files.\n• Restore: Import .txdata backups at any time with the archive password.'**
  String get helpVaultBackupBody;

  /// Help topic title for SQL Query Engine.
  ///
  /// In en, this message translates to:
  /// **'SQL Query Engine'**
  String get helpSqlQueryTitle;

  /// Short subtitle for SQL Query Engine.
  ///
  /// In en, this message translates to:
  /// **'Query CSV, JSON, and XML files directly with local SQL statements.'**
  String get helpSqlQuerySubtitle;

  /// Help text explaining SQL Query Engine.
  ///
  /// In en, this message translates to:
  /// **'Analyze and transform tabular and structured data using standard SQL syntax directly on your device.\n\n• Supported Formats: Run queries on CSV, JSON, and XML documents.\n• Capabilities: Full SQL syntax including SELECT, WHERE, GROUP BY, HAVING, ORDER BY, and table JOINs across opened tabs.\n• Export Results: Save query output directly as new CSV or JSON files.'**
  String get helpSqlQueryBody;

  /// Help topic title for multi-cursor and column selection.
  ///
  /// In en, this message translates to:
  /// **'Multi-Cursor & Column Editing'**
  String get helpMultiCursorTitle;

  /// Short subtitle for multi-cursor and column selection.
  ///
  /// In en, this message translates to:
  /// **'Simultaneously edit multiple lines and select vertical text columns.'**
  String get helpMultiCursorSubtitle;

  /// Help text explaining multi-cursor and column selection.
  ///
  /// In en, this message translates to:
  /// **'Boost editing speed on repetitive formatting and text transformation tasks.\n\n• Multi-Cursor: Tap and hold to place multiple independent cursors in the text editor. All cursors type, delete, and paste at the same time.\n• Column Selection: Select vertical columns of text across multiple lines to easily add prefixes, suffixes, or edit tabular text alignments.'**
  String get helpMultiCursorBody;

  /// Help topic title for search features.
  ///
  /// In en, this message translates to:
  /// **'Search & Workspace Index'**
  String get helpSearchTitle;

  /// Short subtitle for the search help card.
  ///
  /// In en, this message translates to:
  /// **'Find text inside documents or search across all files with SQLite FTS5.'**
  String get helpSearchSubtitle;

  /// Help text explaining search features.
  ///
  /// In en, this message translates to:
  /// **'Find text rapidly across your documents:\n\n• In-Document Search: Use Find & Replace with case sensitivity, whole-word matching, and regular expressions.\n• Global Workspace Search: Tap the search icon on the Home screen to query the high-speed SQLite FTS5 full-text index covering all recent and favorite documents.\n• 100% Private: All indexing and search operations occur locally on your device.'**
  String get helpSearchBody;

  /// Help topic title for Tamper-Evident Audit Log.
  ///
  /// In en, this message translates to:
  /// **'Tamper-Evident Audit Log'**
  String get helpAuditLogTitle;

  /// Short subtitle for Tamper-Evident Audit Log.
  ///
  /// In en, this message translates to:
  /// **'Verify file integrity with cryptographic SHA-256 hash chains.'**
  String get helpAuditLogSubtitle;

  /// Help text explaining Tamper-Evident Audit Log.
  ///
  /// In en, this message translates to:
  /// **'Maintain transparent and tamper-evident records of document operations.\n\n• Hash Chaining: Every file open, edit, save, export, and vault operation is logged with SHA-256 digests chained cryptographically to the previous entry.\n• Integrity Verification: Run verification from Settings → Audit Log to mathematically prove no log entries or file histories have been altered.'**
  String get helpAuditLogBody;

  /// Help topic title for Format Tools.
  ///
  /// In en, this message translates to:
  /// **'Format-Specific Tools'**
  String get helpFormatToolsTitle;

  /// Short subtitle for Format Tools.
  ///
  /// In en, this message translates to:
  /// **'Specialized visual tools and editors for JSON, Markdown, CSV, XML, and TXT.'**
  String get helpFormatToolsSubtitle;

  /// Help text explaining Format Tools.
  ///
  /// In en, this message translates to:
  /// **'TextData provides custom editors and visual tools tailored to each file type:\n\n• JSON: Interactive visual tree viewer, JSONPath query runner, schema validator, array splitter, and formatter.\n• Markdown: Live split-screen preview, visual table builder, YAML front-matter editor, and heading splitter.\n• CSV: Interactive spreadsheet grid, column sorting, formulas (SUM, AVG, MIN, MAX, COUNT), and delimiter converter.\n• XML: Hierarchical tree view, XPath query runner, XSD schema validator, and auto-beautifier.\n• TXT: Line splitting, word wrap toggling, line jump, and web link extractor.'**
  String get helpFormatToolsBody;

  /// Help topic title for speech features.
  ///
  /// In en, this message translates to:
  /// **'Speech & Read Aloud'**
  String get helpSpeechTitle;

  /// Short subtitle for speech features.
  ///
  /// In en, this message translates to:
  /// **'Listen to documents read aloud in English and Malayalam.'**
  String get helpSpeechSubtitle;

  /// Help text explaining speech features.
  ///
  /// In en, this message translates to:
  /// **'Listen to documents hands-free using your device\'s built-in text-to-speech engine.\n\n• Supported Languages: English and Malayalam.\n• Voice Controls: Play, pause, stop, and configure speech rate and language from Settings → Speech.'**
  String get helpSpeechBody;

  /// Help topic title for splitting a JSON array.
  ///
  /// In en, this message translates to:
  /// **'Split array'**
  String get helpSplitArrayTitle;

  /// Short subtitle for the split-array help card.
  ///
  /// In en, this message translates to:
  /// **'Break a JSON array into smaller numbered files.'**
  String get helpSplitArraySubtitle;

  /// Help text explaining how Split array works.
  ///
  /// In en, this message translates to:
  /// **'Split array works when the top level of a JSON file is an array. Choose how many items each part should contain. The app then creates numbered files such as name.part1.json and asks where to save each one. The last part may contain fewer items. Your original file is not changed.'**
  String get helpSplitArrayBody;

  /// Help topic title for backup and export.
  ///
  /// In en, this message translates to:
  /// **'Backup & export'**
  String get helpBackupTitle;

  /// Short subtitle for the backup help card.
  ///
  /// In en, this message translates to:
  /// **'Keep copies of your files safe in other formats or locations.'**
  String get helpBackupSubtitle;

  /// Help text explaining backup and export features.
  ///
  /// In en, this message translates to:
  /// **'Keep copies of your files safe using Export and Save a copy. Open any document and tap the menu to find \"Export\" — this converts your file to another format such as PDF or plain text. Use \"Save a copy\" to save the document to a new location without changing the original. For extra safety, export important files regularly and store copies in a safe place such as a cloud folder, an SD card, or another device using LAN sync or QR sharing.'**
  String get helpBackupBody;

  /// About settings section header.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutSectionTitle;

  /// About settings card description.
  ///
  /// In en, this message translates to:
  /// **'App version, author, and license details.'**
  String get aboutCardSubtitle;

  /// About: loading.
  ///
  /// In en, this message translates to:
  /// **'Loading app details…'**
  String get aboutLoading;

  /// About: unavailable.
  ///
  /// In en, this message translates to:
  /// **'App details are unavailable.'**
  String get aboutUnavailable;

  /// About: version label.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get aboutVersion;

  /// About: version and build.
  ///
  /// In en, this message translates to:
  /// **'{version} (build {build})'**
  String aboutVersionValue(String version, String build);

  /// About: author label.
  ///
  /// In en, this message translates to:
  /// **'Author'**
  String get aboutAuthor;

  /// About: contact label.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get aboutContact;

  /// About: licenses label.
  ///
  /// In en, this message translates to:
  /// **'Licenses'**
  String get aboutLicenses;

  /// About: privacy link label.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get aboutLinkPrivacy;

  /// About: support link label.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get aboutLinkSupport;

  /// About: source link label.
  ///
  /// In en, this message translates to:
  /// **'Source code'**
  String get aboutLinkSource;

  /// Snackbar when a link cannot open (shared).
  ///
  /// In en, this message translates to:
  /// **'Could not open the link.'**
  String get linkCouldNotOpen;

  /// Host status: listening for a client.
  ///
  /// In en, this message translates to:
  /// **'Waiting for a device…'**
  String get syncStatusWaiting;

  /// Host status: a client is connected.
  ///
  /// In en, this message translates to:
  /// **'Device connected'**
  String get syncStatusConnected;

  /// Host status: a client used the wrong code.
  ///
  /// In en, this message translates to:
  /// **'Wrong code'**
  String get syncStatusWrongCode;

  /// Host status: an error occurred.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get syncStatusError;

  /// Host status: sync stopped.
  ///
  /// In en, this message translates to:
  /// **'Stopped'**
  String get syncStatusStopped;

  /// Sync landing screen title.
  ///
  /// In en, this message translates to:
  /// **'Sync with another device'**
  String get syncTitle;

  /// Sync landing intro paragraph.
  ///
  /// In en, this message translates to:
  /// **'Move your favorites, bookmarks, recent files, and display settings between two devices on the same Wi-Fi. No internet is used, and nothing is ever overwritten on the other device.'**
  String get syncIntro;

  /// Sync: send (host) option.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get syncSend;

  /// Sync: send option subtitle.
  ///
  /// In en, this message translates to:
  /// **'Share this device\'s data'**
  String get syncSendSubtitle;

  /// Sync: receive (client) option.
  ///
  /// In en, this message translates to:
  /// **'Receive'**
  String get syncReceive;

  /// Sync: receive option subtitle.
  ///
  /// In en, this message translates to:
  /// **'Get data from another device'**
  String get syncReceiveSubtitle;

  /// Sync summary: completed title.
  ///
  /// In en, this message translates to:
  /// **'Sync complete'**
  String get syncComplete;

  /// Sync summary: records added/kept.
  ///
  /// In en, this message translates to:
  /// **'{added} added · {kept} kept'**
  String syncAddedKept(int added, int kept);

  /// Sync summary: settings applied/kept.
  ///
  /// In en, this message translates to:
  /// **'{applied} applied · {kept} kept'**
  String syncAppliedKept(int applied, int kept);

  /// Sync category: favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get syncCatFavorites;

  /// Sync category: bookmarks.
  ///
  /// In en, this message translates to:
  /// **'Bookmarks'**
  String get syncCatBookmarks;

  /// Sync category: recent files.
  ///
  /// In en, this message translates to:
  /// **'Recent files'**
  String get syncCatRecents;

  /// Sync category: display settings.
  ///
  /// In en, this message translates to:
  /// **'Display settings'**
  String get syncDisplaySettings;

  /// Sync host screen title.
  ///
  /// In en, this message translates to:
  /// **'Send to a device'**
  String get syncHostTitle;

  /// Sync client screen title.
  ///
  /// In en, this message translates to:
  /// **'Receive from a device'**
  String get syncClientTitle;

  /// Sync: failed to start.
  ///
  /// In en, this message translates to:
  /// **'Could not start: {error}'**
  String syncCouldNotStart(String error);

  /// Sync host: connection tab.
  ///
  /// In en, this message translates to:
  /// **'Connection'**
  String get syncTabConnection;

  /// Sync host: what-to-share tab.
  ///
  /// In en, this message translates to:
  /// **'What to share'**
  String get syncTabWhatToShare;

  /// Sync host: payload sent notice.
  ///
  /// In en, this message translates to:
  /// **'Data sent. You can send again or stop.'**
  String get syncDataSent;

  /// Sync host: no Wi-Fi address.
  ///
  /// In en, this message translates to:
  /// **'No Wi-Fi address found. Connect both devices to the same Wi-Fi, then type the code, address, and port on the other device.'**
  String get syncNoWifi;

  /// Sync: pairing code label.
  ///
  /// In en, this message translates to:
  /// **'Pairing code'**
  String get syncPairingCode;

  /// Sync: address label.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get syncAddress;

  /// Sync: port label.
  ///
  /// In en, this message translates to:
  /// **'Port'**
  String get syncPort;

  /// Sync host: stop button.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get syncStop;

  /// Sync client: connecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get syncConnecting;

  /// Sync client: connected, waiting.
  ///
  /// In en, this message translates to:
  /// **'Connected — waiting for the sender to choose what to send…'**
  String get syncConnectedWaiting;

  /// Sync client: applying data.
  ///
  /// In en, this message translates to:
  /// **'Applying the received data…'**
  String get syncApplying;

  /// Sync client: generic failure message.
  ///
  /// In en, this message translates to:
  /// **'The sync failed.'**
  String get syncFailedGeneric;

  /// Sync client: failure title.
  ///
  /// In en, this message translates to:
  /// **'Sync failed'**
  String get syncFailed;

  /// Sync client: scan-QR button.
  ///
  /// In en, this message translates to:
  /// **'Scan QR code'**
  String get syncScanQr;

  /// Sync client: manual entry header.
  ///
  /// In en, this message translates to:
  /// **'Or type the details'**
  String get syncOrTypeDetails;

  /// Sync client: address field hint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 192.168.1.5'**
  String get syncAddressHint;

  /// Sync client: connect button.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get syncConnect;

  /// Sync client: scanner screen title.
  ///
  /// In en, this message translates to:
  /// **'Scan the QR code'**
  String get syncScanTitle;

  /// Sync client: scanner semantics label.
  ///
  /// In en, this message translates to:
  /// **'Camera viewfinder. Point it at the pairing QR code on the other device. You can also go back and type the code instead.'**
  String get syncScanSemantics;

  /// Sync share: fresh-device card title.
  ///
  /// In en, this message translates to:
  /// **'Fresh device'**
  String get syncFreshDevice;

  /// Sync share: fresh-device card body.
  ///
  /// In en, this message translates to:
  /// **'Send everything (favorites, bookmarks, recent files and display settings) to a device that has no data yet.'**
  String get syncFreshDeviceBody;

  /// Sync share: full-sync button.
  ///
  /// In en, this message translates to:
  /// **'Full sync'**
  String get syncFullSync;

  /// Sync share: selective card title.
  ///
  /// In en, this message translates to:
  /// **'Choose what to share'**
  String get syncChooseWhatToShare;

  /// Sync share: won't-override note.
  ///
  /// In en, this message translates to:
  /// **'This won\'t override anything already on the other device; on a conflict the other device keeps its data.'**
  String get syncWontOverride;

  /// Sync share: send-selected button.
  ///
  /// In en, this message translates to:
  /// **'Send selected'**
  String get syncSendSelected;

  /// Find field hint (shared across editors).
  ///
  /// In en, this message translates to:
  /// **'Find'**
  String get findFind;

  /// Replace one action.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get findReplace;

  /// Replace all action.
  ///
  /// In en, this message translates to:
  /// **'Replace all'**
  String get findReplaceAll;

  /// Replace-with field hint.
  ///
  /// In en, this message translates to:
  /// **'Replace with'**
  String get findReplaceWith;

  /// Case-sensitive toggle tooltip.
  ///
  /// In en, this message translates to:
  /// **'Match case'**
  String get findMatchCase;

  /// Regex toggle tooltip.
  ///
  /// In en, this message translates to:
  /// **'Use regular expression'**
  String get findUseRegex;

  /// Toggle replace-mode tooltip.
  ///
  /// In en, this message translates to:
  /// **'Toggle replace'**
  String get findToggleReplace;

  /// Close find tooltip.
  ///
  /// In en, this message translates to:
  /// **'Close find'**
  String get findClose;

  /// Next-match tooltip.
  ///
  /// In en, this message translates to:
  /// **'Next match'**
  String get findNextMatch;

  /// Previous-match tooltip.
  ///
  /// In en, this message translates to:
  /// **'Previous match'**
  String get findPreviousMatch;

  /// Shown when there are no matches.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get findNoResults;

  /// TXT find hint.
  ///
  /// In en, this message translates to:
  /// **'Find'**
  String get txtFind;

  /// TXT replace action.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get txtReplace;

  /// TXT replace-all action.
  ///
  /// In en, this message translates to:
  /// **'Replace all'**
  String get txtReplaceAll;

  /// TXT replace-with hint.
  ///
  /// In en, this message translates to:
  /// **'Replace with'**
  String get txtReplaceWith;

  /// TXT case-sensitive toggle.
  ///
  /// In en, this message translates to:
  /// **'Match case'**
  String get txtMatchCase;

  /// TXT regex toggle.
  ///
  /// In en, this message translates to:
  /// **'Use regular expression'**
  String get txtUseRegex;

  /// TXT toggle replace mode.
  ///
  /// In en, this message translates to:
  /// **'Toggle replace'**
  String get txtToggleReplace;

  /// TXT close find.
  ///
  /// In en, this message translates to:
  /// **'Close find'**
  String get txtCloseFind;

  /// TXT next match.
  ///
  /// In en, this message translates to:
  /// **'Next match'**
  String get txtNextMatch;

  /// TXT previous match.
  ///
  /// In en, this message translates to:
  /// **'Previous match'**
  String get txtPreviousMatch;

  /// TXT no matches.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get txtNoResults;

  /// TXT cancel button.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get txtCancel;

  /// TXT links sheet title.
  ///
  /// In en, this message translates to:
  /// **'Links'**
  String get txtLinksTitle;

  /// TXT links sheet title when empty.
  ///
  /// In en, this message translates to:
  /// **'No links found'**
  String get txtNoLinksFound;

  /// TXT links sheet empty body.
  ///
  /// In en, this message translates to:
  /// **'This file has no web links.'**
  String get txtNoLinksBody;

  /// TXT copy-link button.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get txtCopyLink;

  /// TXT open-link button.
  ///
  /// In en, this message translates to:
  /// **'Open in browser'**
  String get txtOpenInBrowser;

  /// TXT link warning dialog title.
  ///
  /// In en, this message translates to:
  /// **'Open this link?'**
  String get txtLinkWarningTitle;

  /// TXT link warning dialog body.
  ///
  /// In en, this message translates to:
  /// **'This opens an external link in your browser. Only open links you trust.'**
  String get txtLinkWarningBody;

  /// TXT file-info sheet title.
  ///
  /// In en, this message translates to:
  /// **'File information'**
  String get txtInfoTitle;

  /// TXT info: size.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get txtInfoSize;

  /// TXT info: modified date.
  ///
  /// In en, this message translates to:
  /// **'Modified'**
  String get txtInfoModified;

  /// TXT info: word count.
  ///
  /// In en, this message translates to:
  /// **'Words'**
  String get txtInfoWords;

  /// TXT info: character count.
  ///
  /// In en, this message translates to:
  /// **'Characters'**
  String get txtInfoCharacters;

  /// TXT info: characters excluding line breaks.
  ///
  /// In en, this message translates to:
  /// **'Characters (no line breaks)'**
  String get txtInfoCharactersNoLineBreaks;

  /// TXT info: line count.
  ///
  /// In en, this message translates to:
  /// **'Lines'**
  String get txtInfoLines;

  /// TXT encoding label.
  ///
  /// In en, this message translates to:
  /// **'Encoding'**
  String get txtEncoding;

  /// TXT encoding sheet title.
  ///
  /// In en, this message translates to:
  /// **'Text encoding'**
  String get txtEncodingSheetTitle;

  /// TXT line-ending label.
  ///
  /// In en, this message translates to:
  /// **'Line ending'**
  String get txtLineEnding;

  /// TXT: binary-content warning banner.
  ///
  /// In en, this message translates to:
  /// **'This file doesn\'t look like text. It is shown as-is and may appear garbled.'**
  String get txtBinaryWarning;

  /// TXT: link copied snackbar.
  ///
  /// In en, this message translates to:
  /// **'Link copied to clipboard.'**
  String get txtLinkCopied;

  /// TXT split: dialog title.
  ///
  /// In en, this message translates to:
  /// **'Split file'**
  String get txtSplitFile;

  /// TXT split: split by lines option.
  ///
  /// In en, this message translates to:
  /// **'By line count'**
  String get txtSplitByLines;

  /// TXT split: split by size option.
  ///
  /// In en, this message translates to:
  /// **'By size (KB)'**
  String get txtSplitBySize;

  /// TXT split: lines-per-part field label.
  ///
  /// In en, this message translates to:
  /// **'Lines per part'**
  String get txtLinesPerPart;

  /// TXT split: KB-per-part field label.
  ///
  /// In en, this message translates to:
  /// **'Kilobytes per part'**
  String get txtKbPerPart;

  /// TXT split: only one part needed.
  ///
  /// In en, this message translates to:
  /// **'The file is small enough to fit in one part.'**
  String get txtSplitOnePart;

  /// TXT toolbar: switch to view mode.
  ///
  /// In en, this message translates to:
  /// **'View mode'**
  String get txtViewMode;

  /// TXT toolbar: switch to edit mode.
  ///
  /// In en, this message translates to:
  /// **'Edit mode'**
  String get txtEditMode;

  /// Editor toolbar: stop editing and go back to viewing.
  ///
  /// In en, this message translates to:
  /// **'Exit edit mode'**
  String get editorExitEditMode;

  /// Editor banner: the crash-recovery draft could not be written.
  ///
  /// In en, this message translates to:
  /// **'Auto-save is not working. Save the file to keep your changes.'**
  String get editorAutoSaveFailing;

  /// TXT toolbar: word wrap on.
  ///
  /// In en, this message translates to:
  /// **'Word wrap: on'**
  String get txtWordWrapOn;

  /// TXT toolbar: word wrap off.
  ///
  /// In en, this message translates to:
  /// **'Word wrap: off'**
  String get txtWordWrapOff;

  /// TXT toolbar: jump-to-line menu item and dialog title.
  ///
  /// In en, this message translates to:
  /// **'Jump to line'**
  String get txtJumpToLine;

  /// TXT jump-to-line: line number field label.
  ///
  /// In en, this message translates to:
  /// **'Line number'**
  String get txtLineNumber;

  /// TXT toolbar: append/merge a file.
  ///
  /// In en, this message translates to:
  /// **'Append a file'**
  String get txtAppendFile;

  /// Markdown: show rendered view.
  ///
  /// In en, this message translates to:
  /// **'Rendered'**
  String get mdShowRendered;

  /// Markdown: show raw source view.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get mdShowSource;

  /// Markdown: edit mode.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get mdEdit;

  /// Markdown: preview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get mdPreview;

  /// Markdown: live preview enabled tooltip.
  ///
  /// In en, this message translates to:
  /// **'Live preview on'**
  String get mdLivePreviewOn;

  /// Title of the visual Markdown table builder (roadmap 4.4.2).
  ///
  /// In en, this message translates to:
  /// **'Table builder'**
  String get mdTableBuilder;

  /// Short help text in the table builder.
  ///
  /// In en, this message translates to:
  /// **'Fill in the cells; the pipe characters are lined up for you.'**
  String get mdTableBuilderHelp;

  /// Label of a header cell field.
  ///
  /// In en, this message translates to:
  /// **'Header'**
  String get mdTableHeaderCell;

  /// Adds a body row to the table being built.
  ///
  /// In en, this message translates to:
  /// **'Add row'**
  String get mdTableAddRow;

  /// Adds a column to the table being built.
  ///
  /// In en, this message translates to:
  /// **'Add column'**
  String get mdTableAddColumn;

  /// Removes one body row.
  ///
  /// In en, this message translates to:
  /// **'Remove this row'**
  String get mdTableRemoveRow;

  /// Removes one column.
  ///
  /// In en, this message translates to:
  /// **'Remove this column'**
  String get mdTableRemoveColumn;

  /// Heading above the generated table source.
  ///
  /// In en, this message translates to:
  /// **'Markdown'**
  String get mdTablePreview;

  /// Writes the built table into the document.
  ///
  /// In en, this message translates to:
  /// **'Insert table'**
  String get mdTableInsert;

  /// Column alignment: none set.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get mdTableAlignDefault;

  /// Column alignment: left.
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get mdTableAlignLeft;

  /// Column alignment: centre.
  ///
  /// In en, this message translates to:
  /// **'Center'**
  String get mdTableAlignCenter;

  /// Column alignment: right.
  ///
  /// In en, this message translates to:
  /// **'Right'**
  String get mdTableAlignRight;

  /// Title of the YAML front-matter form editor (roadmap 4.4.3).
  ///
  /// In en, this message translates to:
  /// **'Front matter'**
  String get mdFrontMatterTitle;

  /// Explains that unknown YAML is preserved.
  ///
  /// In en, this message translates to:
  /// **'Edit the fields below. Anything this form does not show is left exactly as it is.'**
  String get mdFrontMatterHelp;

  /// Shown when the file has no front-matter block.
  ///
  /// In en, this message translates to:
  /// **'This file has no front matter yet. Fill in a field to add one.'**
  String get mdFrontMatterNone;

  /// Adds a new front-matter field.
  ///
  /// In en, this message translates to:
  /// **'Add field'**
  String get mdFrontMatterAddField;

  /// Label of the new-field name input.
  ///
  /// In en, this message translates to:
  /// **'Field name'**
  String get mdFrontMatterFieldName;

  /// Confirms adding a new field.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get mdFrontMatterAdd;

  /// Hint of the tag chip input.
  ///
  /// In en, this message translates to:
  /// **'Type a tag and press enter'**
  String get mdFrontMatterAddTag;

  /// Opens the date picker for the date field.
  ///
  /// In en, this message translates to:
  /// **'Pick a date'**
  String get mdFrontMatterPickDate;

  /// Writes the form back into the document.
  ///
  /// In en, this message translates to:
  /// **'Apply changes'**
  String get mdFrontMatterApply;

  /// Markdown: live preview disabled tooltip.
  ///
  /// In en, this message translates to:
  /// **'Live preview off'**
  String get mdLivePreviewOff;

  /// Markdown: save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get mdSave;

  /// Markdown: undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get mdUndo;

  /// Markdown: redo.
  ///
  /// In en, this message translates to:
  /// **'Redo'**
  String get mdRedo;

  /// Markdown: find.
  ///
  /// In en, this message translates to:
  /// **'Find'**
  String get mdFind;

  /// Markdown: table of contents.
  ///
  /// In en, this message translates to:
  /// **'Contents'**
  String get mdContents;

  /// Markdown: a recovered draft exists.
  ///
  /// In en, this message translates to:
  /// **'Unsaved draft found'**
  String get mdDraftFound;

  /// Markdown: restore the draft.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get mdRestore;

  /// Markdown: discard the draft.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get mdDiscard;

  /// Markdown: failure-state title.
  ///
  /// In en, this message translates to:
  /// **'Cannot open this file'**
  String get mdCantOpenTitle;

  /// Markdown: failure-state body.
  ///
  /// In en, this message translates to:
  /// **'This file could not be opened.'**
  String get mdCannotOpenFile;

  /// Markdown: retry opening.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get mdRetry;

  /// Markdown: split-by-heading menu item.
  ///
  /// In en, this message translates to:
  /// **'Split by heading'**
  String get mdSplitByHeading;

  /// Markdown: append/merge a file menu item.
  ///
  /// In en, this message translates to:
  /// **'Append a file'**
  String get mdAppendFile;

  /// Markdown format: bold.
  ///
  /// In en, this message translates to:
  /// **'Bold'**
  String get mdBold;

  /// Markdown format: italic.
  ///
  /// In en, this message translates to:
  /// **'Italic'**
  String get mdItalic;

  /// Markdown format: strikethrough.
  ///
  /// In en, this message translates to:
  /// **'Strikethrough'**
  String get mdStrikethrough;

  /// Markdown format: bullet list.
  ///
  /// In en, this message translates to:
  /// **'Bullet list'**
  String get mdBulletList;

  /// Markdown format: numbered list.
  ///
  /// In en, this message translates to:
  /// **'Numbered list'**
  String get mdNumberedList;

  /// Markdown format: task list.
  ///
  /// In en, this message translates to:
  /// **'Task list'**
  String get mdTaskList;

  /// Markdown format: blockquote.
  ///
  /// In en, this message translates to:
  /// **'Quote'**
  String get mdQuote;

  /// Markdown format: inline code.
  ///
  /// In en, this message translates to:
  /// **'Inline code'**
  String get mdInlineCode;

  /// Markdown format: code block.
  ///
  /// In en, this message translates to:
  /// **'Code block'**
  String get mdCodeBlock;

  /// Markdown format: link.
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get mdLink;

  /// Markdown format: table.
  ///
  /// In en, this message translates to:
  /// **'Table'**
  String get mdTable;

  /// Markdown format: heading menu.
  ///
  /// In en, this message translates to:
  /// **'Heading'**
  String get mdHeading;

  /// Markdown format: heading level 1.
  ///
  /// In en, this message translates to:
  /// **'Heading 1'**
  String get mdHeading1;

  /// Markdown format: heading level 2.
  ///
  /// In en, this message translates to:
  /// **'Heading 2'**
  String get mdHeading2;

  /// Markdown format: heading level 3.
  ///
  /// In en, this message translates to:
  /// **'Heading 3'**
  String get mdHeading3;

  /// Markdown link warning dialog body.
  ///
  /// In en, this message translates to:
  /// **'This link goes online and opens outside the app. Only open links you trust.'**
  String get mdLinkWarningBody;

  /// Markdown TOC: no headings snackbar.
  ///
  /// In en, this message translates to:
  /// **'This document has no headings.'**
  String get mdNoHeadings;

  /// Markdown info: word count.
  ///
  /// In en, this message translates to:
  /// **'Words'**
  String get mdInfoWords;

  /// Markdown info: heading count.
  ///
  /// In en, this message translates to:
  /// **'Headings'**
  String get mdInfoHeadings;

  /// Markdown info: link count.
  ///
  /// In en, this message translates to:
  /// **'Links'**
  String get mdInfoLinks;

  /// Markdown info: line count.
  ///
  /// In en, this message translates to:
  /// **'Lines'**
  String get mdInfoLines;

  /// Markdown info: front-matter title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get mdInfoTitleField;

  /// Markdown info: front-matter author.
  ///
  /// In en, this message translates to:
  /// **'Author'**
  String get mdInfoAuthorField;

  /// Markdown info: front-matter tags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get mdInfoTags;

  /// Markdown split: no top-level headings.
  ///
  /// In en, this message translates to:
  /// **'No top-level headings to split on.'**
  String get mdNoTopHeadings;

  /// JSON: start read-aloud.
  ///
  /// In en, this message translates to:
  /// **'Read aloud'**
  String get jsonReadAloud;

  /// JSON: stop read-aloud.
  ///
  /// In en, this message translates to:
  /// **'Stop reading'**
  String get jsonStopReading;

  /// JSON: read-aloud unavailable tooltip.
  ///
  /// In en, this message translates to:
  /// **'Read aloud is not available'**
  String get jsonReadAloudUnavailable;

  /// JSON view: minified.
  ///
  /// In en, this message translates to:
  /// **'Minified'**
  String get jsonViewMinified;

  /// JSON: JSONPath query menu item.
  ///
  /// In en, this message translates to:
  /// **'JSONPath query'**
  String get jsonPathQuery;

  /// JSON: diff/compare menu item.
  ///
  /// In en, this message translates to:
  /// **'Compare with a file'**
  String get jsonCompareFile;

  /// JSON: split-array menu item.
  ///
  /// In en, this message translates to:
  /// **'Split array'**
  String get jsonSplitArray;

  /// JSON tree: invalid document.
  ///
  /// In en, this message translates to:
  /// **'This document is not valid JSON. Open the editor to fix it.'**
  String get jsonNotValidTree;

  /// JSON tree: copy value.
  ///
  /// In en, this message translates to:
  /// **'Copy value'**
  String get jsonCopyValue;

  /// JSON tree: copy subtree.
  ///
  /// In en, this message translates to:
  /// **'Copy JSON'**
  String get jsonCopyJson;

  /// JSON tree: edit value.
  ///
  /// In en, this message translates to:
  /// **'Edit value'**
  String get jsonEditValue;

  /// JSON tree: edit key.
  ///
  /// In en, this message translates to:
  /// **'Edit key'**
  String get jsonEditKey;

  /// JSON tree: value copied snackbar.
  ///
  /// In en, this message translates to:
  /// **'Value copied.'**
  String get jsonValueCopied;

  /// JSON tree: JSON copied snackbar.
  ///
  /// In en, this message translates to:
  /// **'JSON copied.'**
  String get jsonJsonCopied;

  /// JSON tree: value field hint.
  ///
  /// In en, this message translates to:
  /// **'A JSON value, e.g. \"text\", 42, true'**
  String get jsonValueHint;

  /// JSON tree: invalid value snackbar.
  ///
  /// In en, this message translates to:
  /// **'That is not a valid JSON value.'**
  String get jsonInvalidValue;

  /// JSON tree: new key prompt title.
  ///
  /// In en, this message translates to:
  /// **'New key'**
  String get jsonNewKey;

  /// JSON tree: member key hint.
  ///
  /// In en, this message translates to:
  /// **'The member key'**
  String get jsonMemberKeyHint;

  /// JSON tree: new value prompt title.
  ///
  /// In en, this message translates to:
  /// **'New value'**
  String get jsonNewValue;

  /// JSONPath sheet title.
  ///
  /// In en, this message translates to:
  /// **'JSONPath'**
  String get jsonPathTitle;

  /// JSONPath query hint.
  ///
  /// In en, this message translates to:
  /// **'e.g. \$.data.users[*].name'**
  String get jsonPathHint;

  /// JSONPath: document not valid.
  ///
  /// In en, this message translates to:
  /// **'The document is not valid JSON.'**
  String get jsonNotValidDoc;

  /// JSON validate: well-formed.
  ///
  /// In en, this message translates to:
  /// **'Well-formed JSON.'**
  String get jsonWellFormed;

  /// JSON validate: not valid with a line.
  ///
  /// In en, this message translates to:
  /// **'Not valid JSON (line {line}): {error}'**
  String jsonNotValidWithLine(int line, String error);

  /// JSON validate: not valid without a line.
  ///
  /// In en, this message translates to:
  /// **'Not valid JSON: {error}'**
  String jsonNotValidNoLine(String error);

  /// JSON validate: schema button.
  ///
  /// In en, this message translates to:
  /// **'Validate against a schema…'**
  String get jsonValidateAgainstSchema;

  /// JSON validate: fix errors first.
  ///
  /// In en, this message translates to:
  /// **'Fix the JSON errors first.'**
  String get jsonFixErrorsFirst;

  /// JSON validate: schema passed.
  ///
  /// In en, this message translates to:
  /// **'Valid against the schema.'**
  String get jsonValidAgainstSchema;

  /// JSON validate: schema read error.
  ///
  /// In en, this message translates to:
  /// **'That schema file could not be read.'**
  String get jsonSchemaReadError;

  /// JSON validate: schema error count.
  ///
  /// In en, this message translates to:
  /// **'{count} schema error(s):'**
  String jsonSchemaErrors(int count);

  /// JSON diff: fix errors first.
  ///
  /// In en, this message translates to:
  /// **'Fix the JSON errors before comparing.'**
  String get jsonFixBeforeCompare;

  /// JSON diff: other file invalid.
  ///
  /// In en, this message translates to:
  /// **'The other file is not valid JSON.'**
  String get jsonOtherNotValid;

  /// JSON diff: sheet title.
  ///
  /// In en, this message translates to:
  /// **'Diff with {name}'**
  String jsonDiffWith(String name);

  /// JSON diff: identical.
  ///
  /// In en, this message translates to:
  /// **'The two documents are identical.'**
  String get jsonIdentical;

  /// JSON diff: summary counts.
  ///
  /// In en, this message translates to:
  /// **'{added} added · {removed} removed · {changed} changed'**
  String jsonDiffSummary(int added, int removed, int changed);

  /// JSON diff: added section.
  ///
  /// In en, this message translates to:
  /// **'Added'**
  String get jsonDiffAdded;

  /// JSON diff: removed section.
  ///
  /// In en, this message translates to:
  /// **'Removed'**
  String get jsonDiffRemoved;

  /// JSON diff: changed section.
  ///
  /// In en, this message translates to:
  /// **'Changed'**
  String get jsonDiffChanged;

  /// JSON diff: section header with count.
  ///
  /// In en, this message translates to:
  /// **'{title} ({count})'**
  String jsonDiffSection(String title, int count);

  /// JSON split: too few items.
  ///
  /// In en, this message translates to:
  /// **'Nothing to split — too few items.'**
  String get jsonNothingToSplit;

  /// JSON split: items-per-part label.
  ///
  /// In en, this message translates to:
  /// **'Items per part'**
  String get jsonItemsPerPart;

  /// JSON info: validity.
  ///
  /// In en, this message translates to:
  /// **'Valid JSON'**
  String get jsonInfoValid;

  /// JSON info: top-level type.
  ///
  /// In en, this message translates to:
  /// **'Top-level type'**
  String get jsonInfoTopType;

  /// JSON info: top-level item count.
  ///
  /// In en, this message translates to:
  /// **'Top-level items'**
  String get jsonInfoTopItems;

  /// JSON info: key count.
  ///
  /// In en, this message translates to:
  /// **'Keys'**
  String get jsonInfoKeys;

  /// JSON info: array count.
  ///
  /// In en, this message translates to:
  /// **'Arrays'**
  String get jsonInfoArrays;

  /// JSON info: largest array size.
  ///
  /// In en, this message translates to:
  /// **'Largest array'**
  String get jsonInfoLargestArray;

  /// JSON info: type breakdown.
  ///
  /// In en, this message translates to:
  /// **'Types'**
  String get jsonInfoTypes;

  /// JSON pretty view: invalid title.
  ///
  /// In en, this message translates to:
  /// **'Not valid JSON yet'**
  String get jsonNotValidYet;

  /// JSON pretty view: invalid with a line.
  ///
  /// In en, this message translates to:
  /// **'There is a problem near line {line}. Open the editor to fix it.'**
  String jsonProblemNearLine(int line);

  /// JSON pretty view: invalid without a line.
  ///
  /// In en, this message translates to:
  /// **'Open the editor to fix the JSON.'**
  String get jsonOpenEditorToFix;

  /// JSON: NDJSON banner.
  ///
  /// In en, this message translates to:
  /// **'Newline-delimited JSON — {count} records.'**
  String jsonNdjsonBanner(int count);

  /// JSON: lenient-read banner.
  ///
  /// In en, this message translates to:
  /// **'Read leniently (comments / trailing commas). Saving writes strict JSON.'**
  String get jsonLenientBanner;

  /// JSON: make-strict button.
  ///
  /// In en, this message translates to:
  /// **'Make strict'**
  String get jsonMakeStrict;

  /// JSON: tree search hint.
  ///
  /// In en, this message translates to:
  /// **'Filter by key or value'**
  String get jsonTreeFilterHint;

  /// JSON save: reformat checkbox.
  ///
  /// In en, this message translates to:
  /// **'Reformat as strict JSON before saving'**
  String get jsonReformatStrict;

  /// Markdown front-matter author line.
  ///
  /// In en, this message translates to:
  /// **'By {author}'**
  String mdByAuthor(String author);

  /// XML tree search field hint.
  ///
  /// In en, this message translates to:
  /// **'Filter by tag, attribute, or text'**
  String get xmlTreeFilterHint;

  /// XML view: pretty.
  ///
  /// In en, this message translates to:
  /// **'Pretty'**
  String get xmlViewPretty;

  /// XML view: tree.
  ///
  /// In en, this message translates to:
  /// **'Tree'**
  String get xmlViewTree;

  /// XML view: raw.
  ///
  /// In en, this message translates to:
  /// **'Raw'**
  String get xmlViewRaw;

  /// XML: stop editing source.
  ///
  /// In en, this message translates to:
  /// **'Stop editing'**
  String get xmlStopEditing;

  /// XML: edit source.
  ///
  /// In en, this message translates to:
  /// **'Edit source'**
  String get xmlEditSource;

  /// XML: expand all tree nodes.
  ///
  /// In en, this message translates to:
  /// **'Expand all'**
  String get xmlExpandAll;

  /// XML: collapse all tree nodes.
  ///
  /// In en, this message translates to:
  /// **'Collapse all'**
  String get xmlCollapseAll;

  /// XML: format/pretty-print.
  ///
  /// In en, this message translates to:
  /// **'Format'**
  String get xmlFormat;

  /// XML: minify.
  ///
  /// In en, this message translates to:
  /// **'Minify'**
  String get xmlMinify;

  /// XML: validate well-formedness.
  ///
  /// In en, this message translates to:
  /// **'Validate'**
  String get xmlValidate;

  /// XML: XPath query menu item.
  ///
  /// In en, this message translates to:
  /// **'XPath query'**
  String get xmlXPathQuery;

  /// XML: insights and info menu item.
  ///
  /// In en, this message translates to:
  /// **'Insights & info'**
  String get xmlInsightsInfo;

  /// XML: split-by-element menu item.
  ///
  /// In en, this message translates to:
  /// **'Split by element'**
  String get xmlSplitByElement;

  /// XML: merge-a-file menu item.
  ///
  /// In en, this message translates to:
  /// **'Merge a file'**
  String get xmlMergeFile;

  /// XML: copy the whole document.
  ///
  /// In en, this message translates to:
  /// **'Copy all'**
  String get xmlCopyAll;

  /// XML: copy the minified document.
  ///
  /// In en, this message translates to:
  /// **'Copy minified'**
  String get xmlCopyMinified;

  /// XML info: well-formedness.
  ///
  /// In en, this message translates to:
  /// **'Well-formed XML'**
  String get xmlInfoWellFormed;

  /// XML info: root element.
  ///
  /// In en, this message translates to:
  /// **'Root element'**
  String get xmlInfoRoot;

  /// XML info: element count.
  ///
  /// In en, this message translates to:
  /// **'Elements'**
  String get xmlInfoElements;

  /// XML info: max depth.
  ///
  /// In en, this message translates to:
  /// **'Max depth'**
  String get xmlInfoMaxDepth;

  /// XML info: attribute count.
  ///
  /// In en, this message translates to:
  /// **'Attributes'**
  String get xmlInfoAttributes;

  /// XML info: most common tags.
  ///
  /// In en, this message translates to:
  /// **'Common tags'**
  String get xmlInfoCommonTags;

  /// XML info: namespaces.
  ///
  /// In en, this message translates to:
  /// **'Namespaces'**
  String get xmlInfoNamespaces;

  /// XML split: document has errors.
  ///
  /// In en, this message translates to:
  /// **'Fix the XML errors before splitting.'**
  String get xmlFixErrorsBeforeSplit;

  /// XML split: not enough elements.
  ///
  /// In en, this message translates to:
  /// **'Nothing to split — too few elements.'**
  String get xmlNothingToSplit;

  /// XML split: tag field label.
  ///
  /// In en, this message translates to:
  /// **'Repeated child element'**
  String get xmlRepeatedChildElement;

  /// XML split: elements-per-part label and title.
  ///
  /// In en, this message translates to:
  /// **'Elements per part'**
  String get xmlElementsPerPart;

  /// XML merge: wrapper element name label.
  ///
  /// In en, this message translates to:
  /// **'New wrapper element name'**
  String get xmlNewWrapperName;

  /// XML merge: pick-file button.
  ///
  /// In en, this message translates to:
  /// **'Pick file'**
  String get xmlPickFile;

  /// XML save: indentation label.
  ///
  /// In en, this message translates to:
  /// **'Indentation (when reformatting)'**
  String get xmlIndentation;

  /// XML save: reformat checkbox.
  ///
  /// In en, this message translates to:
  /// **'Reformat (pretty-print) before saving'**
  String get xmlReformat;

  /// XML tree: document is not well-formed.
  ///
  /// In en, this message translates to:
  /// **'This document is not well-formed XML. Open the editor to fix it.'**
  String get xmlNotWellFormedTree;

  /// XML tree: filter matched nothing.
  ///
  /// In en, this message translates to:
  /// **'No matches.'**
  String get xmlNoMatches;

  /// XML tree: row menu tooltip.
  ///
  /// In en, this message translates to:
  /// **'Node actions'**
  String get xmlNodeActions;

  /// XML tree: copy the node path.
  ///
  /// In en, this message translates to:
  /// **'Copy path'**
  String get xmlCopyPath;

  /// XML tree: copy the node text.
  ///
  /// In en, this message translates to:
  /// **'Copy text'**
  String get xmlCopyText;

  /// XML tree: copy the node subtree.
  ///
  /// In en, this message translates to:
  /// **'Copy XML'**
  String get xmlCopyXml;

  /// XML tree: edit element text.
  ///
  /// In en, this message translates to:
  /// **'Edit text'**
  String get xmlEditText;

  /// XML tree: set an attribute.
  ///
  /// In en, this message translates to:
  /// **'Set attribute'**
  String get xmlSetAttribute;

  /// XML tree: remove an attribute.
  ///
  /// In en, this message translates to:
  /// **'Remove attribute'**
  String get xmlRemoveAttribute;

  /// XML tree: rename element menu item.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get xmlRename;

  /// XML tree: add a child element.
  ///
  /// In en, this message translates to:
  /// **'Add child'**
  String get xmlAddChild;

  /// XML tree: move element up.
  ///
  /// In en, this message translates to:
  /// **'Move up'**
  String get xmlMoveUp;

  /// XML tree: move element down.
  ///
  /// In en, this message translates to:
  /// **'Move down'**
  String get xmlMoveDown;

  /// XML tree: delete a node.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get xmlDelete;

  /// XML tree: path copied snackbar.
  ///
  /// In en, this message translates to:
  /// **'Path copied.'**
  String get xmlPathCopied;

  /// XML tree: text copied snackbar.
  ///
  /// In en, this message translates to:
  /// **'Text copied.'**
  String get xmlTextCopied;

  /// XML tree: XML copied snackbar.
  ///
  /// In en, this message translates to:
  /// **'XML copied.'**
  String get xmlXmlCopied;

  /// XML tree: edit-text dialog title.
  ///
  /// In en, this message translates to:
  /// **'Edit text'**
  String get xmlEditTextTitle;

  /// XML tree: attribute name prompt.
  ///
  /// In en, this message translates to:
  /// **'Attribute name'**
  String get xmlAttributeName;

  /// XML tree: attribute value prompt.
  ///
  /// In en, this message translates to:
  /// **'Attribute value'**
  String get xmlAttributeValue;

  /// XML tree: element has no attributes.
  ///
  /// In en, this message translates to:
  /// **'This element has no attributes.'**
  String get xmlNoAttributes;

  /// XML tree: rename-element dialog title.
  ///
  /// In en, this message translates to:
  /// **'Rename element'**
  String get xmlRenameElementTitle;

  /// XML tree: new child element prompt.
  ///
  /// In en, this message translates to:
  /// **'New child element'**
  String get xmlNewChildElement;

  /// XML tree: optional text prompt.
  ///
  /// In en, this message translates to:
  /// **'Text (optional)'**
  String get xmlTextOptional;

  /// XML tree: pick attribute to remove.
  ///
  /// In en, this message translates to:
  /// **'Remove which attribute?'**
  String get xmlRemoveWhichAttribute;

  /// XML XPath sheet title.
  ///
  /// In en, this message translates to:
  /// **'XPath'**
  String get xmlXPathTitle;

  /// XML XPath query hint.
  ///
  /// In en, this message translates to:
  /// **'e.g. //book/title'**
  String get xmlXPathHint;

  /// XML XPath: run button.
  ///
  /// In en, this message translates to:
  /// **'Run'**
  String get xmlRun;

  /// XML XPath: document not well-formed.
  ///
  /// In en, this message translates to:
  /// **'The document is not well-formed XML.'**
  String get xmlNotWellFormedDoc;

  /// XML XPath: number of matches.
  ///
  /// In en, this message translates to:
  /// **'{count} match(es)'**
  String xmlMatchCount(int count);

  /// XML validate: well-formed message.
  ///
  /// In en, this message translates to:
  /// **'Well-formed XML.'**
  String get xmlWellFormedYes;

  /// XML validate: not well-formed with a line number.
  ///
  /// In en, this message translates to:
  /// **'Not well-formed (line {line}): {error}'**
  String xmlNotWellFormedWithLine(int line, String error);

  /// XML validate: not well-formed without a line number.
  ///
  /// In en, this message translates to:
  /// **'Not well-formed: {error}'**
  String xmlNotWellFormedNoLine(String error);

  /// XML validate: XSD note.
  ///
  /// In en, this message translates to:
  /// **'XSD schema validation is coming in a later update.'**
  String get xmlXsdComing;

  /// Shows a uniform JSON array as a grid (roadmap 4.3.1).
  ///
  /// In en, this message translates to:
  /// **'View as table'**
  String get jsonViewAsTable;

  /// Shown when no array in the file fits the grid.
  ///
  /// In en, this message translates to:
  /// **'This document has no array of records to show as a table.'**
  String get jsonTableNothingToShow;

  /// Says which array the grid is showing and how big it is.
  ///
  /// In en, this message translates to:
  /// **'{path} · {rows} rows · {columns} columns'**
  String jsonTableSummary(String path, int rows, int columns);

  /// Goes back from a picked array to the document's default one.
  ///
  /// In en, this message translates to:
  /// **'Whole document'**
  String get jsonTableWholeDocument;

  /// A grid cell's value was copied.
  ///
  /// In en, this message translates to:
  /// **'Value copied'**
  String get jsonTableCopied;

  /// Title of the visual JSONPath builder (roadmap 4.3.2).
  ///
  /// In en, this message translates to:
  /// **'Query builder'**
  String get jsonQueryBuilderTitle;

  /// Heading above the next-step chips.
  ///
  /// In en, this message translates to:
  /// **'Go into'**
  String get jsonQueryGoInto;

  /// Heading above the recursive-search chips.
  ///
  /// In en, this message translates to:
  /// **'At any depth'**
  String get jsonQueryAtAnyDepth;

  /// Heading above the list of matched paths.
  ///
  /// In en, this message translates to:
  /// **'Matches'**
  String get jsonQueryMatchesHeading;

  /// Shown when the built query selects nothing.
  ///
  /// In en, this message translates to:
  /// **'Nothing matches yet. Step back and try another path.'**
  String get jsonQueryNoMatches;

  /// Shown when the selection has no children.
  ///
  /// In en, this message translates to:
  /// **'There is nothing deeper to go into from here.'**
  String get jsonQueryNothingDeeper;

  /// Removes the last step of the built query.
  ///
  /// In en, this message translates to:
  /// **'Step back'**
  String get jsonQueryStepBack;

  /// Clears every step of the built query.
  ///
  /// In en, this message translates to:
  /// **'Start over'**
  String get jsonQueryStartOver;

  /// Hands the built query to the query sheet to run.
  ///
  /// In en, this message translates to:
  /// **'Use this query'**
  String get jsonQueryUse;

  /// Heading above the 1-tap repairs (roadmap 4.3.3).
  ///
  /// In en, this message translates to:
  /// **'Quick fixes'**
  String get jsonQuickFixes;

  /// Applies every quick fix at once.
  ///
  /// In en, this message translates to:
  /// **'Fix everything'**
  String get jsonFixEverything;

  /// JSON quick fix.
  ///
  /// In en, this message translates to:
  /// **'Put quotes around keys'**
  String get jsonFixQuoteKeys;

  /// JSON quick fix.
  ///
  /// In en, this message translates to:
  /// **'Use double quotes'**
  String get jsonFixDoubleQuotes;

  /// JSON quick fix.
  ///
  /// In en, this message translates to:
  /// **'Remove extra commas'**
  String get jsonFixTrailingCommas;

  /// JSON quick fix.
  ///
  /// In en, this message translates to:
  /// **'Remove comments'**
  String get jsonFixRemoveComments;

  /// JSON quick fix for True/False/None.
  ///
  /// In en, this message translates to:
  /// **'Use true, false and null'**
  String get jsonFixPythonLiterals;

  /// Title of the visual XPath builder (roadmap 4.3.2).
  ///
  /// In en, this message translates to:
  /// **'XPath builder'**
  String get xmlQueryBuilderTitle;

  /// XML quick fix.
  ///
  /// In en, this message translates to:
  /// **'Close the open tags'**
  String get xmlFixCloseTags;

  /// XML quick fix.
  ///
  /// In en, this message translates to:
  /// **'Escape the & signs'**
  String get xmlFixEscapeAmpersands;

  /// XML quick fix.
  ///
  /// In en, this message translates to:
  /// **'Wrap in a single root'**
  String get xmlFixWrapRoot;

  /// XML quick fix.
  ///
  /// In en, this message translates to:
  /// **'Remove the text before the first tag'**
  String get xmlFixTrimJunk;

  /// XML pretty view: invalid title.
  ///
  /// In en, this message translates to:
  /// **'Not well-formed XML yet'**
  String get xmlNotWellFormedYet;

  /// XML pretty view: invalid with a line.
  ///
  /// In en, this message translates to:
  /// **'There is a problem near line {line}. Open the editor to fix it.'**
  String xmlProblemNearLine(int line);

  /// XML pretty view: invalid without a line.
  ///
  /// In en, this message translates to:
  /// **'Open the editor to fix the XML.'**
  String get xmlOpenEditorToFix;

  /// Snackbar when the tab cap is reached.
  ///
  /// In en, this message translates to:
  /// **'Too many tabs open. Close one first, then reopen.'**
  String get openTooManyTabs;

  /// CSV: switch to raw text view.
  ///
  /// In en, this message translates to:
  /// **'Show raw text'**
  String get csvShowRawText;

  /// CSV: switch to table view.
  ///
  /// In en, this message translates to:
  /// **'Show table'**
  String get csvShowTable;

  /// CSV: filter-rows tooltip.
  ///
  /// In en, this message translates to:
  /// **'Filter rows'**
  String get csvFilterRows;

  /// CSV: filter-rows field hint.
  ///
  /// In en, this message translates to:
  /// **'Filter rows…'**
  String get csvFilterRowsHint;

  /// CSV: jump-to-row tooltip and dialog title.
  ///
  /// In en, this message translates to:
  /// **'Jump to row'**
  String get csvJumpToRow;

  /// CSV: columns and view options tooltip.
  ///
  /// In en, this message translates to:
  /// **'Columns & view'**
  String get csvColumnsView;

  /// CSV: insights tooltip.
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get csvInsights;

  /// CSV: jump-to-row field label.
  ///
  /// In en, this message translates to:
  /// **'Row number (1–{max})'**
  String csvRowNumberLabel(int max);

  /// CSV: remove duplicate rows menu item.
  ///
  /// In en, this message translates to:
  /// **'Remove duplicate rows'**
  String get csvRemoveDuplicates;

  /// CSV: split-by-rows menu item.
  ///
  /// In en, this message translates to:
  /// **'Split by rows'**
  String get csvSplitByRows;

  /// CSV: append/merge a file menu item.
  ///
  /// In en, this message translates to:
  /// **'Append a file'**
  String get csvAppendFile;

  /// CSV: dedup key chooser title.
  ///
  /// In en, this message translates to:
  /// **'Match duplicates by'**
  String get csvMatchDuplicatesBy;

  /// CSV: dedup by the whole row.
  ///
  /// In en, this message translates to:
  /// **'Whole row'**
  String get csvWholeRow;

  /// CSV: a column with no header name.
  ///
  /// In en, this message translates to:
  /// **'Column {n}'**
  String csvColumnN(int n);

  /// CSV: snackbar when there are no duplicates.
  ///
  /// In en, this message translates to:
  /// **'No duplicate rows found.'**
  String get csvNoDuplicates;

  /// CSV: snackbar after removing duplicates.
  ///
  /// In en, this message translates to:
  /// **'Removed {count} duplicate row(s).'**
  String csvRemovedDuplicates(int count);

  /// CSV: file-info sheet title.
  ///
  /// In en, this message translates to:
  /// **'File info'**
  String get csvInfoTitle;

  /// CSV info: row count.
  ///
  /// In en, this message translates to:
  /// **'Rows'**
  String get csvInfoRows;

  /// CSV info: column count.
  ///
  /// In en, this message translates to:
  /// **'Columns'**
  String get csvInfoColumns;

  /// CSV info: delimiter.
  ///
  /// In en, this message translates to:
  /// **'Delimiter'**
  String get csvInfoDelimiter;

  /// CSV info: header-row present.
  ///
  /// In en, this message translates to:
  /// **'Header row'**
  String get csvInfoHeaderRow;

  /// CSV info: encoding.
  ///
  /// In en, this message translates to:
  /// **'Encoding'**
  String get csvInfoEncoding;

  /// CSV info: line ending.
  ///
  /// In en, this message translates to:
  /// **'Line ending'**
  String get csvInfoLineEnding;

  /// CSV info: size.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get csvInfoSize;

  /// CSV info: modified date.
  ///
  /// In en, this message translates to:
  /// **'Modified'**
  String get csvInfoModified;

  /// CSV info: yes value.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get csvYes;

  /// CSV info: no value.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get csvNo;

  /// CSV columns: freeze the header row.
  ///
  /// In en, this message translates to:
  /// **'Freeze header row'**
  String get csvFreezeHeader;

  /// CSV columns: freeze the first column.
  ///
  /// In en, this message translates to:
  /// **'Freeze first column'**
  String get csvFreezeFirstColumn;

  /// CSV columns: treat the first row as a header.
  ///
  /// In en, this message translates to:
  /// **'First row is a header'**
  String get csvFirstRowHeader;

  /// CSV columns: show/hide columns header.
  ///
  /// In en, this message translates to:
  /// **'Show columns'**
  String get csvShowColumns;

  /// CSV insights: no columns.
  ///
  /// In en, this message translates to:
  /// **'No columns to analyze.'**
  String get csvNoColumns;

  /// CSV insights sheet title.
  ///
  /// In en, this message translates to:
  /// **'Data insights'**
  String get csvDataInsights;

  /// CSV insights: column picker label.
  ///
  /// In en, this message translates to:
  /// **'Column'**
  String get csvColumnLabel;

  /// CSV insights stat: type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get csvStatType;

  /// CSV insights stat: value count.
  ///
  /// In en, this message translates to:
  /// **'Values'**
  String get csvStatValues;

  /// CSV insights stat: empty count.
  ///
  /// In en, this message translates to:
  /// **'Empty'**
  String get csvStatEmpty;

  /// CSV insights stat: unique count.
  ///
  /// In en, this message translates to:
  /// **'Unique'**
  String get csvStatUnique;

  /// CSV insights stat: minimum.
  ///
  /// In en, this message translates to:
  /// **'Min'**
  String get csvStatMin;

  /// CSV insights stat: maximum.
  ///
  /// In en, this message translates to:
  /// **'Max'**
  String get csvStatMax;

  /// CSV insights stat: sum.
  ///
  /// In en, this message translates to:
  /// **'Sum'**
  String get csvStatSum;

  /// CSV insights stat: average.
  ///
  /// In en, this message translates to:
  /// **'Average'**
  String get csvStatAverage;

  /// Title of the multi-column sort sheet (roadmap 4.2.1).
  ///
  /// In en, this message translates to:
  /// **'Sort levels'**
  String get csvSortLevels;

  /// Shown when the sort hierarchy is empty.
  ///
  /// In en, this message translates to:
  /// **'No sort yet. Add a level to sort by more than one column.'**
  String get csvSortNoLevels;

  /// Adds another level to the sort hierarchy.
  ///
  /// In en, this message translates to:
  /// **'Add level'**
  String get csvSortAddLevel;

  /// Applies the built sort hierarchy to the grid.
  ///
  /// In en, this message translates to:
  /// **'Apply sort'**
  String get csvSortApply;

  /// Removes every sort level.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get csvSortClear;

  /// Label of the first sort level.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get csvSortFirstBy;

  /// Label of a later sort level.
  ///
  /// In en, this message translates to:
  /// **'Then by'**
  String get csvSortThenBy;

  /// Ascending sort direction.
  ///
  /// In en, this message translates to:
  /// **'A → Z'**
  String get csvSortAscending;

  /// Descending sort direction.
  ///
  /// In en, this message translates to:
  /// **'Z → A'**
  String get csvSortDescending;

  /// Reorders a sort level.
  ///
  /// In en, this message translates to:
  /// **'Move this level up'**
  String get csvSortMoveUp;

  /// Reorders a sort level.
  ///
  /// In en, this message translates to:
  /// **'Move this level down'**
  String get csvSortMoveDown;

  /// Column menu: turn a column into a calculated one (roadmap 4.2.2).
  ///
  /// In en, this message translates to:
  /// **'Set formula…'**
  String get csvSetFormula;

  /// Column menu: change an existing column formula.
  ///
  /// In en, this message translates to:
  /// **'Edit formula…'**
  String get csvEditFormula;

  /// Title of the column formula sheet.
  ///
  /// In en, this message translates to:
  /// **'Formula for \"{name}\"'**
  String csvFormulaTitle(String name);

  /// Short help text explaining what a formula can contain.
  ///
  /// In en, this message translates to:
  /// **'Use column letters for this row (A, B), a row number for a fixed cell (B2), or a range inside SUM, AVG, MIN, MAX, COUNT or PRODUCT.'**
  String get csvFormulaHelp;

  /// Label of the formula input field.
  ///
  /// In en, this message translates to:
  /// **'Formula'**
  String get csvFormulaLabel;

  /// Heading above the tappable column-letter chips.
  ///
  /// In en, this message translates to:
  /// **'Columns you can use'**
  String get csvFormulaColumnLetters;

  /// Heading above the computed preview values.
  ///
  /// In en, this message translates to:
  /// **'First rows'**
  String get csvFormulaPreview;

  /// Applies the formula to the column.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get csvFormulaApply;

  /// Turns a calculated column back into a normal one.
  ///
  /// In en, this message translates to:
  /// **'Remove formula'**
  String get csvFormulaRemove;

  /// Title of the conditional formatting sheet (roadmap 4.2.3).
  ///
  /// In en, this message translates to:
  /// **'Highlight rules'**
  String get csvHighlightRules;

  /// Shown when there are no conditional formatting rules.
  ///
  /// In en, this message translates to:
  /// **'No rules yet. Add one to colour cells automatically.'**
  String get csvNoHighlightRules;

  /// Opens the form for a new highlight rule.
  ///
  /// In en, this message translates to:
  /// **'Add rule'**
  String get csvAddHighlightRule;

  /// Rule applies to all columns rather than one.
  ///
  /// In en, this message translates to:
  /// **'Every column'**
  String get csvRuleEveryColumn;

  /// Label of the rule's condition picker.
  ///
  /// In en, this message translates to:
  /// **'When the value'**
  String get csvRuleWhen;

  /// Label of the rule's comparison value field.
  ///
  /// In en, this message translates to:
  /// **'Compare with'**
  String get csvRuleValue;

  /// Label of the rule's colour picker.
  ///
  /// In en, this message translates to:
  /// **'Highlight in'**
  String get csvRuleHighlight;

  /// Highlight rule condition.
  ///
  /// In en, this message translates to:
  /// **'is less than'**
  String get csvConditionLessThan;

  /// Highlight rule condition.
  ///
  /// In en, this message translates to:
  /// **'is greater than'**
  String get csvConditionGreaterThan;

  /// Highlight rule condition.
  ///
  /// In en, this message translates to:
  /// **'is equal to'**
  String get csvConditionEqualTo;

  /// Highlight rule condition.
  ///
  /// In en, this message translates to:
  /// **'is not equal to'**
  String get csvConditionNotEqualTo;

  /// Highlight rule condition.
  ///
  /// In en, this message translates to:
  /// **'contains'**
  String get csvConditionContains;

  /// Highlight rule condition.
  ///
  /// In en, this message translates to:
  /// **'is empty'**
  String get csvConditionIsEmpty;

  /// Highlight rule condition for duplicate values.
  ///
  /// In en, this message translates to:
  /// **'repeats in its column'**
  String get csvConditionIsDuplicate;

  /// Highlight colour name.
  ///
  /// In en, this message translates to:
  /// **'Red'**
  String get csvHighlightRed;

  /// Highlight colour name.
  ///
  /// In en, this message translates to:
  /// **'Yellow'**
  String get csvHighlightYellow;

  /// Highlight colour name.
  ///
  /// In en, this message translates to:
  /// **'Green'**
  String get csvHighlightGreen;

  /// Highlight colour name.
  ///
  /// In en, this message translates to:
  /// **'Blue'**
  String get csvHighlightBlue;

  /// Title of the full-screen chart page (roadmap 4.2.4).
  ///
  /// In en, this message translates to:
  /// **'Chart'**
  String get csvChartTitle;

  /// Opens the full-screen interactive chart from the insights sheet.
  ///
  /// In en, this message translates to:
  /// **'Open full chart'**
  String get csvOpenFullChart;

  /// Chart type: bar chart.
  ///
  /// In en, this message translates to:
  /// **'Bar'**
  String get csvChartBar;

  /// Chart type: line graph.
  ///
  /// In en, this message translates to:
  /// **'Line'**
  String get csvChartLine;

  /// Chart type: pie chart.
  ///
  /// In en, this message translates to:
  /// **'Pie'**
  String get csvChartPie;

  /// Picks the numeric column to plot.
  ///
  /// In en, this message translates to:
  /// **'Values from'**
  String get csvChartValueColumn;

  /// Picks the column that names each point.
  ///
  /// In en, this message translates to:
  /// **'Labels from'**
  String get csvChartLabelColumn;

  /// Use row numbers instead of a label column.
  ///
  /// In en, this message translates to:
  /// **'Row numbers'**
  String get csvChartRowNumbers;

  /// Chart follows the grid's current filter.
  ///
  /// In en, this message translates to:
  /// **'Only the rows on screen'**
  String get csvChartVisibleRowsOnly;

  /// Shown when nothing can be plotted.
  ///
  /// In en, this message translates to:
  /// **'This file has no number columns to chart.'**
  String get csvChartNoNumericColumns;

  /// Shown when the chosen column produced no points.
  ///
  /// In en, this message translates to:
  /// **'Nothing to chart for this column.'**
  String get csvChartNothingToDraw;

  /// Pie chart slice grouping the smaller values.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get csvChartOther;

  /// Told to the user when the chart capped how much it drew.
  ///
  /// In en, this message translates to:
  /// **'Showing the first {count} values.'**
  String csvChartShowingFirst(int count);

  /// A pie chart cannot draw negative slices.
  ///
  /// In en, this message translates to:
  /// **'{count} negative values were left out of the pie.'**
  String csvChartSkippedNegative(int count);

  /// CSV split: only one part needed.
  ///
  /// In en, this message translates to:
  /// **'The file is small enough to fit in one part.'**
  String get csvSplitOnePart;

  /// CSV split: cancelled partway.
  ///
  /// In en, this message translates to:
  /// **'Stopped after saving {done} of {total} parts.'**
  String csvSplitStopped(int done, int total);

  /// CSV split: all parts saved.
  ///
  /// In en, this message translates to:
  /// **'Saved {count} parts.'**
  String csvSplitSaved(int count);

  /// CSV merge: file appended.
  ///
  /// In en, this message translates to:
  /// **'Merged {name}. Review and save.'**
  String csvMerged(String name);

  /// CSV split: rows-per-part field label.
  ///
  /// In en, this message translates to:
  /// **'Rows per part'**
  String get csvRowsPerPart;

  /// CSV split: confirm button.
  ///
  /// In en, this message translates to:
  /// **'Split'**
  String get csvSplitAction;

  /// CSV grid: add a row tooltip.
  ///
  /// In en, this message translates to:
  /// **'Add row'**
  String get csvAddRow;

  /// CSV grid: edit-cell dialog title.
  ///
  /// In en, this message translates to:
  /// **'Edit \"{name}\"'**
  String csvEditCell(String name);

  /// CSV grid: fallback name for a cell with no header.
  ///
  /// In en, this message translates to:
  /// **'Cell'**
  String get csvCellFallback;

  /// CSV grid: rename column.
  ///
  /// In en, this message translates to:
  /// **'Rename column'**
  String get csvRenameColumn;

  /// CSV grid: insert a column to the left.
  ///
  /// In en, this message translates to:
  /// **'Insert column left'**
  String get csvInsertColumnLeft;

  /// CSV grid: insert a column to the right.
  ///
  /// In en, this message translates to:
  /// **'Insert column right'**
  String get csvInsertColumnRight;

  /// CSV grid: hide a column.
  ///
  /// In en, this message translates to:
  /// **'Hide column'**
  String get csvHideColumn;

  /// CSV grid: delete a column.
  ///
  /// In en, this message translates to:
  /// **'Delete column'**
  String get csvDeleteColumn;

  /// CSV grid: insert a row above.
  ///
  /// In en, this message translates to:
  /// **'Insert row above'**
  String get csvInsertRowAbove;

  /// CSV grid: insert a row below.
  ///
  /// In en, this message translates to:
  /// **'Insert row below'**
  String get csvInsertRowBelow;

  /// CSV grid: move a row up.
  ///
  /// In en, this message translates to:
  /// **'Move up'**
  String get csvMoveUp;

  /// CSV grid: move a row down.
  ///
  /// In en, this message translates to:
  /// **'Move down'**
  String get csvMoveDown;

  /// CSV grid: delete a row.
  ///
  /// In en, this message translates to:
  /// **'Delete row'**
  String get csvDeleteRow;

  /// Title of the AirQR landing screen.
  ///
  /// In en, this message translates to:
  /// **'Air-gap transfer (QR)'**
  String get airqrTitle;

  /// Explains what optical air-gap transfer is.
  ///
  /// In en, this message translates to:
  /// **'Move a document or a piece of text to another device using only the screen and the camera. Nothing is sent over Wi-Fi, Bluetooth, or the internet.'**
  String get airqrIntro;

  /// Start receiving an animated QR stream.
  ///
  /// In en, this message translates to:
  /// **'Receive'**
  String get airqrReceive;

  /// Subtitle for the receive option.
  ///
  /// In en, this message translates to:
  /// **'Point the camera at the other device\'s screen'**
  String get airqrReceiveSubtitle;

  /// Heading for the send instructions card.
  ///
  /// In en, this message translates to:
  /// **'How to send'**
  String get airqrHowToSend;

  /// Explains that sending starts from a document, not this screen.
  ///
  /// In en, this message translates to:
  /// **'Open the document you want to send, then choose \"Send by QR\" from its menu. To send only part of a document, select the text first.'**
  String get airqrHowToSendBody;

  /// Heading for the speed expectations card.
  ///
  /// In en, this message translates to:
  /// **'This is slow on purpose'**
  String get airqrSpeedNoteTitle;

  /// Sets an honest expectation about optical transfer speed.
  ///
  /// In en, this message translates to:
  /// **'A camera link carries about 15 KB each second. Short notes take a few seconds; a large file can take minutes. For anything big, use LAN sync instead.'**
  String get airqrSpeedNoteBody;

  /// Title of the AirQR send screen.
  ///
  /// In en, this message translates to:
  /// **'Sending by QR'**
  String get airqrSendTitle;

  /// Menu action to send the open document by QR.
  ///
  /// In en, this message translates to:
  /// **'Send by QR'**
  String get airqrSendByQr;

  /// Menu action to send the selected text by QR.
  ///
  /// In en, this message translates to:
  /// **'Send selection by QR'**
  String get airqrSendSelectionByQr;

  /// Instruction shown under the animated QR.
  ///
  /// In en, this message translates to:
  /// **'Hold both devices steady until the other device says it has every frame. The code below repeats until then.'**
  String get airqrHoldSteady;

  /// Label for the short session code.
  ///
  /// In en, this message translates to:
  /// **'Session code'**
  String get airqrCodeLabel;

  /// Explains why the code travels separately from the QR stream.
  ///
  /// In en, this message translates to:
  /// **'Read this code to the other person. It is not inside the QR code, so anyone who records the screen still cannot read your data without it.'**
  String get airqrCodeHint;

  /// Warning shown when a transfer is sent unsealed.
  ///
  /// In en, this message translates to:
  /// **'This transfer is not protected. Anyone who can see this screen can read the data.'**
  String get airqrUnsealedWarning;

  /// How many frames make up the transfer.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 frame} other{{count} frames}}'**
  String airqrFrameCount(int count);

  /// How many complete loops of the frame set have finished.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{First pass} =1{1 pass done} other{{count} passes done}}'**
  String airqrPassCount(int count);

  /// Estimated duration of a single pass.
  ///
  /// In en, this message translates to:
  /// **'One full pass takes about {seconds} seconds.'**
  String airqrOnePassTakes(int seconds);

  /// Label for the animation speed slider.
  ///
  /// In en, this message translates to:
  /// **'Speed: {fps} frames per second'**
  String airqrSpeedLabel(int fps);

  /// Help text for the speed slider.
  ///
  /// In en, this message translates to:
  /// **'Lower this if the other device is missing frames.'**
  String get airqrSpeedHelp;

  /// Label for the QR density slider.
  ///
  /// In en, this message translates to:
  /// **'Detail: {bytes} bytes per frame'**
  String airqrDensityLabel(int bytes);

  /// Help text for the density slider.
  ///
  /// In en, this message translates to:
  /// **'Lower this for an easier-to-scan code on an older camera. It needs more frames.'**
  String get airqrDensityHelp;

  /// Title of the AirQR receive screen.
  ///
  /// In en, this message translates to:
  /// **'Receiving by QR'**
  String get airqrReceiveTitle;

  /// Screen reader label for the scanner.
  ///
  /// In en, this message translates to:
  /// **'Camera viewfinder for receiving an animated QR code'**
  String get airqrScanSemantics;

  /// Shown before the first frame is recognised.
  ///
  /// In en, this message translates to:
  /// **'Looking for a transfer…'**
  String get airqrLookingForStream;

  /// Live frame collection progress.
  ///
  /// In en, this message translates to:
  /// **'{received} of {total} frames'**
  String airqrFramesProgress(int received, int total);

  /// Live capture rate.
  ///
  /// In en, this message translates to:
  /// **'{rate} frames/second'**
  String airqrFps(String rate);

  /// Estimated time remaining.
  ///
  /// In en, this message translates to:
  /// **'About {seconds}s left'**
  String airqrRemaining(int seconds);

  /// How many frames have still not arrived.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Waiting for 1 more frame} other{Waiting for {count} more frames}}'**
  String airqrStillMissing(int count);

  /// Shown while the payload is being reassembled.
  ///
  /// In en, this message translates to:
  /// **'Checking and rebuilding the data…'**
  String get airqrAssembling;

  /// Shown when collection is complete.
  ///
  /// In en, this message translates to:
  /// **'All frames received'**
  String get airqrAllFramesReceived;

  /// Prompt for the session code.
  ///
  /// In en, this message translates to:
  /// **'Enter the session code shown on the sending device.'**
  String get airqrEnterCodePrompt;

  /// Button that submits the session code.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get airqrUnlock;

  /// Discard everything collected and scan again.
  ///
  /// In en, this message translates to:
  /// **'Start over'**
  String get airqrStartOver;

  /// Shown when a payload has been received and verified.
  ///
  /// In en, this message translates to:
  /// **'Transfer complete'**
  String get airqrReceivedTitle;

  /// Size of the received text.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 character} other{{count} characters}}'**
  String airqrCharacterCount(int count);

  /// Heading above the received content preview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get airqrPreview;

  /// Copy the received text to the clipboard.
  ///
  /// In en, this message translates to:
  /// **'Copy text'**
  String get airqrCopyText;

  /// Confirmation that the text was copied.
  ///
  /// In en, this message translates to:
  /// **'Copied to the clipboard'**
  String get airqrCopied;

  /// Save the received text through the system file picker.
  ///
  /// In en, this message translates to:
  /// **'Save as a file'**
  String get airqrUseThis;

  /// Fallback failure message.
  ///
  /// In en, this message translates to:
  /// **'The transfer could not be completed.'**
  String get airqrFailedGeneric;

  /// Confirmation that a received document was saved.
  ///
  /// In en, this message translates to:
  /// **'Saved as {name}'**
  String airqrSavedAs(String name);

  /// Confirmation that a received snippet was pasted in.
  ///
  /// In en, this message translates to:
  /// **'Text inserted into the open document'**
  String get airqrInsertedIntoDocument;

  /// Title of the hard-cap refusal dialog.
  ///
  /// In en, this message translates to:
  /// **'Too large for QR transfer'**
  String get airqrTooLargeTitle;

  /// Explains why an oversized transfer is refused.
  ///
  /// In en, this message translates to:
  /// **'This is {size}, and QR transfer stops at {limit}. At camera speed it would take far too long. Use LAN sync instead.'**
  String airqrTooLargeBody(String size, String limit);

  /// Title of the soft-cap warning dialog.
  ///
  /// In en, this message translates to:
  /// **'This will take a while'**
  String get airqrSlowTitle;

  /// Warns about a slow transfer and offers an alternative.
  ///
  /// In en, this message translates to:
  /// **'This is {size}, which takes {duration} by QR code. You will need to hold both devices steady for that long. LAN sync would be much faster.'**
  String airqrSlowBody(String size, String duration);

  /// Proceed with a slow transfer.
  ///
  /// In en, this message translates to:
  /// **'Send anyway'**
  String get airqrSendAnyway;

  /// A duration in minutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes, plural, =1{about 1 minute} other{about {minutes} minutes}}'**
  String airqrAboutMinutes(int minutes);

  /// A duration in seconds.
  ///
  /// In en, this message translates to:
  /// **'{seconds, plural, =1{about 1 second} other{about {seconds} seconds}}'**
  String airqrAboutSeconds(int seconds);

  /// Shown when a send is attempted with no content.
  ///
  /// In en, this message translates to:
  /// **'There is nothing to send.'**
  String get airqrNothingToSend;

  /// Title of the workspace-wide search screen.
  ///
  /// In en, this message translates to:
  /// **'Search all files'**
  String get searchWorkspaceTitle;

  /// Tooltip on the workspace search action.
  ///
  /// In en, this message translates to:
  /// **'Search all files'**
  String get searchWorkspaceTooltip;

  /// Hint text in the workspace search field.
  ///
  /// In en, this message translates to:
  /// **'Search recent and favorite files'**
  String get searchWorkspaceHint;

  /// Title of the start state before anything is typed.
  ///
  /// In en, this message translates to:
  /// **'Search inside your files'**
  String get searchWorkspaceStartTitle;

  /// Body of the start state on the search screen.
  ///
  /// In en, this message translates to:
  /// **'Type a word to find it in the files you opened or marked as favorites. Everything is searched on this device only.'**
  String get searchWorkspaceStartBody;

  /// Shown when a search returns nothing.
  ///
  /// In en, this message translates to:
  /// **'No matches found'**
  String get searchWorkspaceNoResults;

  /// Help text under the no-results message.
  ///
  /// In en, this message translates to:
  /// **'Try a shorter word, or open the file once so it gets indexed.'**
  String get searchWorkspaceNoResultsBody;

  /// Shown when the index setting is turned off.
  ///
  /// In en, this message translates to:
  /// **'Workspace search is off'**
  String get searchWorkspaceOffTitle;

  /// Help text when the index is off.
  ///
  /// In en, this message translates to:
  /// **'Turn it on in Settings › Files & Tabs to search across your files.'**
  String get searchWorkspaceOffBody;

  /// Tooltip on the clear-query button.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get searchWorkspaceClear;

  /// Filter chip that clears the format filters.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get searchWorkspaceAll;

  /// Note on a result whose file was indexed only in part.
  ///
  /// In en, this message translates to:
  /// **'Long file — only the first part is searched'**
  String get searchWorkspacePartial;

  /// Shown on a result whose file can no longer be opened.
  ///
  /// In en, this message translates to:
  /// **'File not available — remove from search'**
  String get searchWorkspaceUnavailable;

  /// How many files matched.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 file} other{{count} files}}'**
  String searchWorkspaceResults(int count);

  /// Settings switch that turns the search index on or off.
  ///
  /// In en, this message translates to:
  /// **'Workspace search index'**
  String get filesIndexTitle;

  /// Subtitle when the index is on.
  ///
  /// In en, this message translates to:
  /// **'Files you open are indexed on this device so you can search inside all of them.'**
  String get filesIndexOn;

  /// Subtitle when the index is off.
  ///
  /// In en, this message translates to:
  /// **'New files are not indexed. Search only finds what was stored before.'**
  String get filesIndexOff;

  /// How many files are in the search index.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No files indexed} =1{1 file indexed} other{{count} files indexed}}'**
  String filesIndexCount(int count);

  /// Settings action that empties the index.
  ///
  /// In en, this message translates to:
  /// **'Clear search index'**
  String get filesIndexClear;

  /// Confirmation body for clearing the index.
  ///
  /// In en, this message translates to:
  /// **'This deletes the stored text of every indexed file. Files themselves are not touched.'**
  String get filesIndexClearBody;

  /// Snackbar after the index is cleared.
  ///
  /// In en, this message translates to:
  /// **'Search index cleared'**
  String get filesIndexCleared;

  /// Settings action that re-reads favorites and recents.
  ///
  /// In en, this message translates to:
  /// **'Rebuild search index'**
  String get filesIndexRebuild;

  /// Snackbar while the rebuild runs.
  ///
  /// In en, this message translates to:
  /// **'Rebuilding the search index…'**
  String get filesIndexRebuilding;

  /// Snackbar after a rebuild finishes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Nothing new to index} =1{1 file indexed} other{{count} files indexed}}'**
  String filesIndexRebuilt(int count);

  /// Tooltip on the countdown badge of an ephemeral tab.
  ///
  /// In en, this message translates to:
  /// **'This tab self-destructs in {time}'**
  String ephemeralBadgeTimerTooltip(String time);

  /// Tooltip on an ephemeral tab with no timer.
  ///
  /// In en, this message translates to:
  /// **'This tab self-destructs after the next export or share'**
  String get ephemeralBadgeOutputTooltip;

  /// Title of the ephemeral options sheet.
  ///
  /// In en, this message translates to:
  /// **'Make this tab self-destruct'**
  String get ephemeralSheetTitle;

  /// Explains what a burn removes.
  ///
  /// In en, this message translates to:
  /// **'When it burns, the app forgets this document: the auto-save draft, the recent entry, favourites, bookmarks, its reading position, and its text in the workspace search index.'**
  String get ephemeralSheetWhatIsWiped;

  /// States that the user's own file survives a burn.
  ///
  /// In en, this message translates to:
  /// **'Your file itself is not deleted. The app only clears what it stores about it.'**
  String get ephemeralSheetFileKept;

  /// Warns that a burn skips the unsaved-changes prompt.
  ///
  /// In en, this message translates to:
  /// **'Unsaved edits in this tab are thrown away when it burns, with no further prompt.'**
  String get ephemeralSheetUnsavedWarning;

  /// Heading above the timer choices.
  ///
  /// In en, this message translates to:
  /// **'Self-destruct after'**
  String get ephemeralSheetTimerLabel;

  /// Label of the custom minutes field.
  ///
  /// In en, this message translates to:
  /// **'Minutes'**
  String get ephemeralSheetCustomMinutes;

  /// Switch that burns the tab after one output action.
  ///
  /// In en, this message translates to:
  /// **'Burn after export or share'**
  String get ephemeralSheetBurnAfterOutput;

  /// Explains the burn-after-export switch.
  ///
  /// In en, this message translates to:
  /// **'The first successful export, share, or print destroys the tab. A cancelled or failed one does not.'**
  String get ephemeralSheetBurnAfterOutputHint;

  /// Shown when the chosen options would do nothing.
  ///
  /// In en, this message translates to:
  /// **'Choose a timer, turn on burn after export, or both.'**
  String get ephemeralSheetNothingChosen;

  /// Confirm button of the ephemeral sheet.
  ///
  /// In en, this message translates to:
  /// **'Make ephemeral'**
  String get ephemeralSheetConfirm;

  /// Ephemeral timer choice.
  ///
  /// In en, this message translates to:
  /// **'15 minutes'**
  String get ephemeralDuration15Minutes;

  /// Ephemeral timer choice.
  ///
  /// In en, this message translates to:
  /// **'1 hour'**
  String get ephemeralDuration1Hour;

  /// Ephemeral timer choice.
  ///
  /// In en, this message translates to:
  /// **'4 hours'**
  String get ephemeralDuration4Hours;

  /// Ephemeral timer choice.
  ///
  /// In en, this message translates to:
  /// **'24 hours'**
  String get ephemeralDuration24Hours;

  /// Ephemeral timer choice with a typed number of minutes.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get ephemeralDurationCustom;

  /// Ephemeral choice with no countdown.
  ///
  /// In en, this message translates to:
  /// **'No timer'**
  String get ephemeralDurationNone;

  /// Tab menu item that opens the ephemeral sheet.
  ///
  /// In en, this message translates to:
  /// **'Make self-destructing…'**
  String get tabMakeEphemeral;

  /// Tab menu item for a tab that is already ephemeral.
  ///
  /// In en, this message translates to:
  /// **'Change self-destruct…'**
  String get tabChangeEphemeral;

  /// Tab menu item that removes the ephemeral mark.
  ///
  /// In en, this message translates to:
  /// **'Keep this tab'**
  String get tabCancelEphemeral;

  /// Tab menu item that burns the tab immediately.
  ///
  /// In en, this message translates to:
  /// **'Burn now'**
  String get tabBurnNow;

  /// Snackbar after a tab is marked ephemeral.
  ///
  /// In en, this message translates to:
  /// **'{name} will self-destruct'**
  String ephemeralMarked(String name);

  /// Snackbar after the ephemeral mark is removed.
  ///
  /// In en, this message translates to:
  /// **'{name} is a normal tab again'**
  String ephemeralCancelled(String name);

  /// Snackbar after a tab self-destructs.
  ///
  /// In en, this message translates to:
  /// **'{name} was burned'**
  String ephemeralBurned(String name);

  /// Snackbar when part of the wipe failed.
  ///
  /// In en, this message translates to:
  /// **'{name} was closed, but some stored traces could not be removed'**
  String ephemeralBurnedPartly(String name);

  /// Title of the burn-now confirmation.
  ///
  /// In en, this message translates to:
  /// **'Burn this tab?'**
  String get ephemeralBurnNowTitle;

  /// Body of the burn-now confirmation.
  ///
  /// In en, this message translates to:
  /// **'The tab closes and the app forgets this document. Unsaved edits are lost. Your file itself is not deleted.'**
  String get ephemeralBurnNowBody;

  /// Confirm button that destroys an ephemeral tab.
  ///
  /// In en, this message translates to:
  /// **'Burn'**
  String get actionBurn;

  /// Long-press action that opens a file straight into an ephemeral tab.
  ///
  /// In en, this message translates to:
  /// **'Open as self-destructing…'**
  String get ephemeralOpenAsEphemeral;

  /// Settings group heading.
  ///
  /// In en, this message translates to:
  /// **'Self-destructing documents'**
  String get ephemeralSettingsTitle;

  /// Settings row for the pre-selected timer.
  ///
  /// In en, this message translates to:
  /// **'Default timer'**
  String get ephemeralSettingsDefaultDuration;

  /// Settings switch preselecting burn-after-export.
  ///
  /// In en, this message translates to:
  /// **'Default to burn after export'**
  String get ephemeralSettingsBurnAfterOutput;

  /// Explains the default burn-after-export setting.
  ///
  /// In en, this message translates to:
  /// **'Pre-selects the switch in the self-destruct sheet. It does not change any tab on its own.'**
  String get ephemeralSettingsBurnAfterOutputHint;

  /// Settings action that burns every ephemeral tab.
  ///
  /// In en, this message translates to:
  /// **'Burn all self-destructing tabs now'**
  String get ephemeralSettingsBurnAll;

  /// How many ephemeral tabs are open right now.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No self-destructing tabs are open} =1{1 self-destructing tab is open} other{{count} self-destructing tabs are open}}'**
  String ephemeralSettingsOpenCount(int count);

  /// Snackbar after burning every ephemeral tab.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Nothing to burn} =1{1 tab burned} other{{count} tabs burned}}'**
  String ephemeralSettingsBurnAllDone(int count);

  /// Honest note about what zero-fill wiping does and does not promise.
  ///
  /// In en, this message translates to:
  /// **'A burn overwrites the app\'s stored copy with zeros before deleting it. On flash storage that is a strong extra step, not a guarantee — Android\'s own app encryption is the real protection.'**
  String get ephemeralSettingsWipeNote;

  /// Overflow menu item that opens the SQL query screen.
  ///
  /// In en, this message translates to:
  /// **'Run SQL query…'**
  String get sqlMenuAction;

  /// Title of the SQL query screen.
  ///
  /// In en, this message translates to:
  /// **'SQL query'**
  String get sqlQueryTitle;

  /// Placeholder shown in the empty SQL box.
  ///
  /// In en, this message translates to:
  /// **'SELECT * FROM data LIMIT 100'**
  String get sqlQueryHint;

  /// Button that runs the typed query.
  ///
  /// In en, this message translates to:
  /// **'Run'**
  String get sqlRunAction;

  /// Shown while a query is running.
  ///
  /// In en, this message translates to:
  /// **'Running…'**
  String get sqlRunning;

  /// Shown while the document is being copied into the query engine.
  ///
  /// In en, this message translates to:
  /// **'Loading the data…'**
  String get sqlLoadingData;

  /// Heading of the schema panel.
  ///
  /// In en, this message translates to:
  /// **'Tables'**
  String get sqlTablesHeading;

  /// Size of one loaded table.
  ///
  /// In en, this message translates to:
  /// **'{rows} rows · {columns} columns'**
  String sqlTableSummary(int rows, int columns);

  /// Note under a column whose name had to be changed to be usable in SQL.
  ///
  /// In en, this message translates to:
  /// **'was “{original}”'**
  String sqlColumnRenamed(String original);

  /// Stands in for a column header that was empty in the file.
  ///
  /// In en, this message translates to:
  /// **'(blank)'**
  String get sqlColumnBlankName;

  /// Warning when a large document was cut down to the row cap.
  ///
  /// In en, this message translates to:
  /// **'Only the first {count} rows of this file were loaded.'**
  String sqlRowsCapped(int count);

  /// Action that loads another open document as a second table for a JOIN.
  ///
  /// In en, this message translates to:
  /// **'Add a table'**
  String get sqlAddTable;

  /// Title of the extra-table picker.
  ///
  /// In en, this message translates to:
  /// **'Add another open document'**
  String get sqlAddTableTitle;

  /// Shown when there is nothing to join with.
  ///
  /// In en, this message translates to:
  /// **'No other CSV or JSON tab is open.'**
  String get sqlAddTableEmpty;

  /// Shown when a picked document holds no tabular data.
  ///
  /// In en, this message translates to:
  /// **'{name} has nothing that can be loaded as a table.'**
  String sqlAddTableFailed(String name);

  /// Confirms an extra table was loaded and says what to call it.
  ///
  /// In en, this message translates to:
  /// **'{name} is now the table {table}.'**
  String sqlTableAdded(String name, String table);

  /// Removes an added table from the query engine.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get sqlRemoveTable;

  /// Heading of the ready-made query list.
  ///
  /// In en, this message translates to:
  /// **'Starter queries'**
  String get sqlPresetsHeading;

  /// Starter query: select everything with a limit.
  ///
  /// In en, this message translates to:
  /// **'Show the first rows'**
  String get sqlPresetSelectAll;

  /// Starter query: COUNT(*).
  ///
  /// In en, this message translates to:
  /// **'Count the rows'**
  String get sqlPresetCountRows;

  /// Starter query: GROUP BY with a count and a sum.
  ///
  /// In en, this message translates to:
  /// **'Group and total'**
  String get sqlPresetGroupCount;

  /// Starter query: ORDER BY a numeric column.
  ///
  /// In en, this message translates to:
  /// **'Highest values first'**
  String get sqlPresetOrderBy;

  /// Starter query: JOIN two loaded tables.
  ///
  /// In en, this message translates to:
  /// **'Join the two tables'**
  String get sqlPresetJoin;

  /// How big the result is and how long it took.
  ///
  /// In en, this message translates to:
  /// **'{rows} rows in {ms} ms'**
  String sqlResultSummary(int rows, int ms);

  /// Warning that the result was cut down to the display cap.
  ///
  /// In en, this message translates to:
  /// **'Showing the first {count} rows of the result.'**
  String sqlResultTruncated(int count);

  /// Shown when a valid query returns nothing.
  ///
  /// In en, this message translates to:
  /// **'The query ran, but no rows matched.'**
  String get sqlResultEmpty;

  /// Shown before the first query is run.
  ///
  /// In en, this message translates to:
  /// **'Type a query and tap Run, or pick a starter query.'**
  String get sqlResultPlaceholder;

  /// Copies the result grid to the clipboard as CSV.
  ///
  /// In en, this message translates to:
  /// **'Copy result as CSV'**
  String get sqlCopyResult;

  /// Confirms the clipboard copy.
  ///
  /// In en, this message translates to:
  /// **'Result copied as CSV'**
  String get sqlCopiedResult;

  /// Saves the result through the system file picker.
  ///
  /// In en, this message translates to:
  /// **'Save result as CSV…'**
  String get sqlSaveResult;

  /// Confirms the result file was written.
  ///
  /// In en, this message translates to:
  /// **'Saved {name}'**
  String sqlSavedResult(String name);

  /// Shown when a save or copy is asked for before a query has run.
  ///
  /// In en, this message translates to:
  /// **'There is no result to save yet.'**
  String get sqlNoResultYet;

  /// Re-copies the documents into the query engine.
  ///
  /// In en, this message translates to:
  /// **'Reload data'**
  String get sqlReloadData;

  /// Confirms the reload.
  ///
  /// In en, this message translates to:
  /// **'Data reloaded from the open documents.'**
  String get sqlReloadedData;

  /// Explains that the query engine holds a snapshot, not the live buffer.
  ///
  /// In en, this message translates to:
  /// **'Queries run over a copy taken when this screen opened. Reload after editing the document.'**
  String get sqlSnapshotNote;

  /// Shown when the open document holds no rows and columns.
  ///
  /// In en, this message translates to:
  /// **'This document has nothing that can be queried as a table.'**
  String get sqlNoData;

  /// Shown when copying the document into SQLite failed.
  ///
  /// In en, this message translates to:
  /// **'The data could not be loaded for querying.'**
  String get sqlLoadFailed;

  /// The SQL box was empty.
  ///
  /// In en, this message translates to:
  /// **'Type a query first.'**
  String get sqlErrorEmpty;

  /// The statement was not a read-only query.
  ///
  /// In en, this message translates to:
  /// **'Only a query that starts with SELECT or WITH can run here.'**
  String get sqlErrorNotSelect;

  /// More than one statement was typed.
  ///
  /// In en, this message translates to:
  /// **'Type one statement only.'**
  String get sqlErrorMultiple;

  /// A blocked SQL word was used.
  ///
  /// In en, this message translates to:
  /// **'“{keyword}” is not allowed — this screen only reads data.'**
  String sqlErrorForbidden(String keyword);

  /// Reassures the user that querying is safe.
  ///
  /// In en, this message translates to:
  /// **'This is a read-only copy of your data. A query can never change or delete your file.'**
  String get sqlReadOnlyNote;

  /// Title of the Audit Log settings card and section.
  ///
  /// In en, this message translates to:
  /// **'Audit Log'**
  String get auditSectionTitle;

  /// Subtitle on the Audit Log card on the settings menu.
  ///
  /// In en, this message translates to:
  /// **'Cryptographic SHA-256 chain log of workspace activity'**
  String get auditCardSubtitle;

  /// Title of the enable audit log switch.
  ///
  /// In en, this message translates to:
  /// **'Record workspace audit log'**
  String get auditEnableTitle;

  /// Subtitle of the enable audit log switch.
  ///
  /// In en, this message translates to:
  /// **'Chains SHA-256 hashes of document edits, exports, sync, and security events.'**
  String get auditEnableSubtitle;

  /// Label before the audit chain status badge.
  ///
  /// In en, this message translates to:
  /// **'Chain status'**
  String get auditChainStatusLabel;

  /// Menu tile opening the full audit log screen.
  ///
  /// In en, this message translates to:
  /// **'View audit log'**
  String get auditViewLogTitle;

  /// Number of entries in the audit log.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No recorded entries} =1{1 recorded entry} other{{count} recorded entries}}'**
  String auditEntryCount(int count);

  /// Title of the audit log screen.
  ///
  /// In en, this message translates to:
  /// **'Workspace Audit Log'**
  String get auditLogTitle;

  /// App bar action to re-verify the hash chain.
  ///
  /// In en, this message translates to:
  /// **'Verify chain'**
  String get auditVerifyAction;

  /// App bar action to export signed audit certificate.
  ///
  /// In en, this message translates to:
  /// **'Export certificate'**
  String get auditExportAction;

  /// Subject line when sharing the audit certificate.
  ///
  /// In en, this message translates to:
  /// **'TextData Audit Certificate'**
  String get auditExportSubject;

  /// Snackbar shown when certificate export fails.
  ///
  /// In en, this message translates to:
  /// **'Could not export the audit certificate.'**
  String get auditExportFailed;

  /// Button to clear the audit log.
  ///
  /// In en, this message translates to:
  /// **'Clear audit log'**
  String get auditClearAction;

  /// Subtitle on the clear audit log tile.
  ///
  /// In en, this message translates to:
  /// **'Deletes all audit records and resets the cryptographic chain.'**
  String get auditClearSubtitle;

  /// Title of the clear audit log confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'Clear audit log?'**
  String get auditClearTitle;

  /// Body of the clear audit log confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'This will delete all activity records. The cryptographic hash chain will restart with a new genesis entry.'**
  String get auditClearConfirmation;

  /// Snackbar confirming audit log clearance.
  ///
  /// In en, this message translates to:
  /// **'Audit log cleared.'**
  String get auditClearSuccess;

  /// Shown on the audit log screen when empty.
  ///
  /// In en, this message translates to:
  /// **'No audit entries recorded yet.'**
  String get auditEmptyState;

  /// Text in the verified status badge.
  ///
  /// In en, this message translates to:
  /// **'Chain Verified'**
  String get auditBadgeVerified;

  /// Text in the corrupted status badge.
  ///
  /// In en, this message translates to:
  /// **'Chain Corrupted'**
  String get auditBadgeCorrupted;

  /// Text in the empty status badge.
  ///
  /// In en, this message translates to:
  /// **'Log Empty'**
  String get auditBadgeEmpty;

  /// Text in the verifying status badge.
  ///
  /// In en, this message translates to:
  /// **'Verifying…'**
  String get auditBadgeVerifying;

  /// Text in the error status badge.
  ///
  /// In en, this message translates to:
  /// **'Check Failed'**
  String get auditBadgeError;

  /// Banner text when the audit chain is fully verified.
  ///
  /// In en, this message translates to:
  /// **'Tamper-Proof Chain Verified ({count} entries)'**
  String auditChainVerifiedBanner(int count);

  /// Banner text when tampering is detected at a specific entry.
  ///
  /// In en, this message translates to:
  /// **'Audit Chain Corrupted at Entry #{index}'**
  String auditChainCorruptedBanner(int index);

  /// Banner text when the audit log has no entries.
  ///
  /// In en, this message translates to:
  /// **'No audit log entries to verify.'**
  String get auditChainEmptyBanner;

  /// Title of the backup settings section.
  ///
  /// In en, this message translates to:
  /// **'Backup & Restore'**
  String get backupSectionTitle;

  /// Subtitle on the backup settings card.
  ///
  /// In en, this message translates to:
  /// **'Encrypted archive export and restore (.txdata)'**
  String get backupCardSubtitle;

  /// Overview text in the backup settings section.
  ///
  /// In en, this message translates to:
  /// **'Export or restore your files, recents, favorites, bookmarks, and settings in a single AES-256 encrypted .txdata bundle.'**
  String get backupSectionDescription;

  /// Title of the backup manager menu item.
  ///
  /// In en, this message translates to:
  /// **'Backup Archive Manager'**
  String get backupManageTitle;

  /// Subtitle of the backup manager menu item.
  ///
  /// In en, this message translates to:
  /// **'Create password-sealed backups or restore from existing .txdata archives.'**
  String get backupManageSubtitle;

  /// Explanatory note about zero-knowledge encryption.
  ///
  /// In en, this message translates to:
  /// **'Zero-Knowledge Protection: Archives are sealed with AES-256-GCM using keys derived via PBKDF2-HMAC-SHA256 (200,000 iterations). Your password is never stored or transmitted. If forgotten, encrypted backups cannot be recovered.'**
  String get backupZeroKnowledgeNote;

  /// App bar title of the backup screen.
  ///
  /// In en, this message translates to:
  /// **'Backup & Restore (.txdata)'**
  String get backupScreenTitle;

  /// Header title on the backup screen overview card.
  ///
  /// In en, this message translates to:
  /// **'Encrypted Backup Archives'**
  String get backupHeroTitle;

  /// Body text on the backup screen overview card.
  ///
  /// In en, this message translates to:
  /// **'Bundle your workspace data and settings into a tamper-evident, password-sealed AES-256 archive. Fully offline with zero cloud access.'**
  String get backupHeroBody;

  /// Title on the export backup card.
  ///
  /// In en, this message translates to:
  /// **'Create Encrypted Backup'**
  String get backupExportCardTitle;

  /// Description on the export backup card.
  ///
  /// In en, this message translates to:
  /// **'Select workspace items and seal them under a chosen password into a .txdata file.'**
  String get backupExportCardBody;

  /// Button to start the export backup flow.
  ///
  /// In en, this message translates to:
  /// **'Export Backup (.txdata)'**
  String get backupExportButton;

  /// Title on the restore backup card.
  ///
  /// In en, this message translates to:
  /// **'Restore From Backup'**
  String get backupRestoreCardTitle;

  /// Description on the restore backup card.
  ///
  /// In en, this message translates to:
  /// **'Open an existing .txdata file, verify your password, and selectively restore items.'**
  String get backupRestoreCardBody;

  /// Button to start the restore backup flow.
  ///
  /// In en, this message translates to:
  /// **'Select Backup File (.txdata)'**
  String get backupRestoreButton;

  /// Action to save backup archive file.
  ///
  /// In en, this message translates to:
  /// **'Save to device (SAF)'**
  String get backupSaveToDevice;

  /// Action to share backup archive file.
  ///
  /// In en, this message translates to:
  /// **'Share archive file'**
  String get backupShareArchive;

  /// Snackbar shown when backup file is successfully saved.
  ///
  /// In en, this message translates to:
  /// **'Backup archive saved as {fileName}'**
  String backupExportSaved(String fileName);

  /// Error prefix when backup creation fails.
  ///
  /// In en, this message translates to:
  /// **'Failed to create backup'**
  String get backupExportError;

  /// Error prefix when restore fails.
  ///
  /// In en, this message translates to:
  /// **'Failed to restore backup'**
  String get backupRestoreError;

  /// Title when password verification fails.
  ///
  /// In en, this message translates to:
  /// **'Cannot Unlock Backup'**
  String get backupUnlockFailedTitle;

  /// Snackbar shown upon successful restore.
  ///
  /// In en, this message translates to:
  /// **'Restored {recents} recents, {favorites} favorites, {bookmarks} bookmarks, {settings} settings.'**
  String backupRestoreSuccessSummary(
    int recents,
    int favorites,
    int bookmarks,
    int settings,
  );

  /// Title of the export options dialog.
  ///
  /// In en, this message translates to:
  /// **'Create Encrypted Backup'**
  String get backupExportTitle;

  /// Header for backup items checklist.
  ///
  /// In en, this message translates to:
  /// **'Select components to include:'**
  String get backupExportSelectItems;

  /// Checkbox to include recents.
  ///
  /// In en, this message translates to:
  /// **'Recent files history'**
  String get backupIncludeRecents;

  /// Checkbox to include favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorite files list'**
  String get backupIncludeFavorites;

  /// Checkbox to include bookmarks.
  ///
  /// In en, this message translates to:
  /// **'Document bookmarks'**
  String get backupIncludeBookmarks;

  /// Checkbox to include settings.
  ///
  /// In en, this message translates to:
  /// **'App settings & preferences'**
  String get backupIncludeSettings;

  /// Checkbox to include attached files.
  ///
  /// In en, this message translates to:
  /// **'Open documents ({count} files)'**
  String backupIncludeFiles(int count);

  /// Header for password input.
  ///
  /// In en, this message translates to:
  /// **'Encryption Password:'**
  String get backupPasswordHeader;

  /// Label for password text field.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get backupPasswordLabel;

  /// Label for confirm password field.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get backupConfirmPasswordLabel;

  /// Validation message for short passwords.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters.'**
  String get backupPasswordTooShort;

  /// Validation message when passwords differ.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get backupPasswordsDoNotMatch;

  /// Warning notice in the password dialog.
  ///
  /// In en, this message translates to:
  /// **'Keep this password safe. If forgotten, this backup archive cannot be decrypted.'**
  String get backupPasswordWarning;

  /// Button to confirm backup creation.
  ///
  /// In en, this message translates to:
  /// **'Create Backup'**
  String get backupCreateAction;

  /// Title of the password prompt dialog.
  ///
  /// In en, this message translates to:
  /// **'Unlock Backup Archive'**
  String get backupEnterPasswordTitle;

  /// Prompt text in password dialog.
  ///
  /// In en, this message translates to:
  /// **'Enter the password used to encrypt this .txdata archive:'**
  String get backupEnterPasswordPrompt;

  /// Button to decrypt backup.
  ///
  /// In en, this message translates to:
  /// **'Unlock & Inspect'**
  String get backupUnlockAction;

  /// Title of the restore confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'Restore Backup Archive'**
  String get backupRestoreTitle;

  /// Creation timestamp in restore dialog.
  ///
  /// In en, this message translates to:
  /// **'Archive created on {date}'**
  String backupCreatedOn(String date);

  /// Header for restore items checklist.
  ///
  /// In en, this message translates to:
  /// **'Select items to restore:'**
  String get backupSelectRestoreItems;

  /// Recent files item count in restore dialog.
  ///
  /// In en, this message translates to:
  /// **'Recent files ({count} items)'**
  String backupRecentsCount(int count);

  /// Favorite files item count in restore dialog.
  ///
  /// In en, this message translates to:
  /// **'Favorite files ({count} items)'**
  String backupFavoritesCount(int count);

  /// Bookmarks item count in restore dialog.
  ///
  /// In en, this message translates to:
  /// **'Document bookmarks ({count} items)'**
  String backupBookmarksCount(int count);

  /// Settings count in restore dialog.
  ///
  /// In en, this message translates to:
  /// **'App settings ({count} preferences)'**
  String backupSettingsCount(int count);

  /// Files count in restore dialog.
  ///
  /// In en, this message translates to:
  /// **'Attached document files ({count} files)'**
  String backupFilesCount(int count);

  /// Title of merge mode switch.
  ///
  /// In en, this message translates to:
  /// **'Merge with existing data'**
  String get backupMergeModeTitle;

  /// Subtitle when merge mode is on.
  ///
  /// In en, this message translates to:
  /// **'Preserves existing records and adds missing ones.'**
  String get backupMergeModeSubtitle;

  /// Subtitle when merge mode is off.
  ///
  /// In en, this message translates to:
  /// **'Replaces existing records with items from this backup.'**
  String get backupReplaceModeSubtitle;

  /// Button to confirm restore.
  ///
  /// In en, this message translates to:
  /// **'Restore Data'**
  String get backupRestoreAction;

  /// Title of biometric vault feature.
  ///
  /// In en, this message translates to:
  /// **'Biometric Vault'**
  String get vaultTitle;

  /// Menu action to lock file in biometric vault.
  ///
  /// In en, this message translates to:
  /// **'Lock in Biometric Vault'**
  String get vaultLockAction;

  /// Button to unlock encrypted vault document.
  ///
  /// In en, this message translates to:
  /// **'Unlock Document'**
  String get vaultUnlockAction;

  /// Title of P2P direct document file transfer tab.
  ///
  /// In en, this message translates to:
  /// **'Document Transfer'**
  String get p2pFileTransferTitle;

  /// Title of the column block and multi-cursor editing sheet.
  ///
  /// In en, this message translates to:
  /// **'Column & Multi-Cursor Edit'**
  String get columnSelectionTitle;

  /// Action item in editor selection toolbar to open column editing.
  ///
  /// In en, this message translates to:
  /// **'Column / Multi-Cursor'**
  String get columnSelectionAction;

  /// Selected line range description in column editing.
  ///
  /// In en, this message translates to:
  /// **'Lines {start} to {end} ({count} lines)'**
  String columnSelectionLines(int start, int end, int count);

  /// Start line input label.
  ///
  /// In en, this message translates to:
  /// **'Start line'**
  String get columnSelectionStartLine;

  /// End line input label.
  ///
  /// In en, this message translates to:
  /// **'End line'**
  String get columnSelectionEndLine;

  /// Preset button to select all lines in document.
  ///
  /// In en, this message translates to:
  /// **'All lines'**
  String get columnSelectionAllLines;

  /// Preset button to select only the current selection lines.
  ///
  /// In en, this message translates to:
  /// **'Selection'**
  String get columnSelectionCurrentLines;

  /// Mode tab for prefixing and suffixing lines.
  ///
  /// In en, this message translates to:
  /// **'Prefix / Suffix'**
  String get columnModePrefixSuffix;

  /// Mode tab for vertical column block slicing.
  ///
  /// In en, this message translates to:
  /// **'Column Block'**
  String get columnModeBlock;

  /// Mode tab for multi-cursor insertion at a specific column.
  ///
  /// In en, this message translates to:
  /// **'Insert at Column'**
  String get columnModeInsertAtCol;

  /// Mode tab for auto-incrementing line numbering.
  ///
  /// In en, this message translates to:
  /// **'Numbering'**
  String get columnModeNumbering;

  /// Input label for prefix text.
  ///
  /// In en, this message translates to:
  /// **'Prefix (start of line)'**
  String get columnPrefixLabel;

  /// Input label for suffix text.
  ///
  /// In en, this message translates to:
  /// **'Suffix (end of line)'**
  String get columnSuffixLabel;

  /// Start column index label.
  ///
  /// In en, this message translates to:
  /// **'Start column'**
  String get columnStartColLabel;

  /// End column index label.
  ///
  /// In en, this message translates to:
  /// **'End column'**
  String get columnEndColLabel;

  /// Column position to insert text.
  ///
  /// In en, this message translates to:
  /// **'Column index'**
  String get columnInsertColLabel;

  /// Input label for text to insert across lines.
  ///
  /// In en, this message translates to:
  /// **'Text to insert'**
  String get columnInsertTextLabel;

  /// Checkbox to pad short lines up to the target column.
  ///
  /// In en, this message translates to:
  /// **'Pad shorter lines with spaces'**
  String get columnPadShorterLines;

  /// Initial number in sequence.
  ///
  /// In en, this message translates to:
  /// **'Start number'**
  String get columnNumberStart;

  /// Increment step per line.
  ///
  /// In en, this message translates to:
  /// **'Step'**
  String get columnNumberStep;

  /// Format string with %d placeholder.
  ///
  /// In en, this message translates to:
  /// **'Format template (%d)'**
  String get columnNumberFormat;

  /// Minimum digits for zero-padded numbers.
  ///
  /// In en, this message translates to:
  /// **'Zero padding digits'**
  String get columnNumberPadding;

  /// Header for the live diff preview panel.
  ///
  /// In en, this message translates to:
  /// **'Live Preview'**
  String get columnLivePreview;

  /// Button to commit bulk column edits.
  ///
  /// In en, this message translates to:
  /// **'Apply Edits'**
  String get columnApplyAction;

  /// Button to copy the rectangular column block to clipboard.
  ///
  /// In en, this message translates to:
  /// **'Copy Block'**
  String get columnCopyBlockAction;

  /// Button to cut the rectangular column block.
  ///
  /// In en, this message translates to:
  /// **'Cut Block'**
  String get columnCutBlockAction;

  /// Button to delete the rectangular column block.
  ///
  /// In en, this message translates to:
  /// **'Delete Block'**
  String get columnDeleteBlockAction;

  /// Snackbar message when column block is copied.
  ///
  /// In en, this message translates to:
  /// **'Column block copied to clipboard'**
  String get columnBlockCopied;

  /// Snackbar message after applying column edits.
  ///
  /// In en, this message translates to:
  /// **'Applied bulk edits across {count} lines'**
  String columnEditsApplied(int count);

  /// Chip to trim leading and trailing spaces.
  ///
  /// In en, this message translates to:
  /// **'Trim whitespace'**
  String get columnTrimWhitespace;

  /// Title of the Privacy Shield sheet.
  ///
  /// In en, this message translates to:
  /// **'Offline Privacy Shield'**
  String get privacyShieldTitle;

  /// Subtitle describing offline scanning.
  ///
  /// In en, this message translates to:
  /// **'On-device PII & secret credentials scanner'**
  String get privacyShieldSubtitle;

  /// Toolbar overflow menu item.
  ///
  /// In en, this message translates to:
  /// **'Privacy Shield & Scrubbing'**
  String get privacyShieldAction;

  /// Masking mode: redact.
  ///
  /// In en, this message translates to:
  /// **'Redact'**
  String get privacyModeRedact;

  /// Masking mode: salted SHA-256 hash.
  ///
  /// In en, this message translates to:
  /// **'Salted Hash'**
  String get privacyModeHash;

  /// Masking mode: pseudo-anonymize.
  ///
  /// In en, this message translates to:
  /// **'Anonymize'**
  String get privacyModeAnonymize;

  /// Filter chip to select all detected items.
  ///
  /// In en, this message translates to:
  /// **'All Items'**
  String get privacySelectAll;

  /// Tab label for list of detections.
  ///
  /// In en, this message translates to:
  /// **'Detected Items'**
  String get privacyTabDetections;

  /// Tab label for scrubbed text preview.
  ///
  /// In en, this message translates to:
  /// **'Full Preview'**
  String get privacyTabPreview;

  /// Title when document has no PII matches.
  ///
  /// In en, this message translates to:
  /// **'No Sensitive Data Detected'**
  String get privacyCleanTitle;

  /// Description when no sensitive items are found.
  ///
  /// In en, this message translates to:
  /// **'No emails, phone numbers, cards, IP addresses, or secret keys found in this file.'**
  String get privacyCleanDescription;

  /// Button to apply redactions to the active editor.
  ///
  /// In en, this message translates to:
  /// **'Apply to Document'**
  String get privacyApplyToBuffer;

  /// Button to share scrubbed copy without altering original.
  ///
  /// In en, this message translates to:
  /// **'Share Scrubbed'**
  String get privacyShareScrubbed;

  /// Button to export scrubbed copy to a new file.
  ///
  /// In en, this message translates to:
  /// **'Export Scrubbed'**
  String get privacyExportScrubbed;

  /// Error snackbar when sharing scrubbed copy fails.
  ///
  /// In en, this message translates to:
  /// **'Could not share the scrubbed document.'**
  String get privacyShareFailed;

  /// Title of the Live Diff screen.
  ///
  /// In en, this message translates to:
  /// **'Live Diff & Delta Sync'**
  String get liveDiffTitle;

  /// Toolbar overflow menu item.
  ///
  /// In en, this message translates to:
  /// **'Live P2P Diff & Sync'**
  String get liveDiffAction;

  /// Button to auto-merge non-conflicting changes.
  ///
  /// In en, this message translates to:
  /// **'Auto-Merge'**
  String get liveDiffAutoMerge;

  /// Option to accept all local changes.
  ///
  /// In en, this message translates to:
  /// **'Accept All Mine'**
  String get liveDiffAcceptMine;

  /// Option to accept all remote peer changes.
  ///
  /// In en, this message translates to:
  /// **'Accept All Peer'**
  String get liveDiffAcceptPeer;

  /// Segment button for side-by-side view.
  ///
  /// In en, this message translates to:
  /// **'Side-by-Side'**
  String get liveDiffSideBySide;

  /// Segment button for unified diff view.
  ///
  /// In en, this message translates to:
  /// **'Unified Diff'**
  String get liveDiffUnified;

  /// Segment button for merge result preview.
  ///
  /// In en, this message translates to:
  /// **'Merge Preview'**
  String get liveDiffPreview;

  /// Tooltip for pushing live delta to peer.
  ///
  /// In en, this message translates to:
  /// **'Push My Edits to Peer'**
  String get liveDiffPushToPeer;

  /// Button to save merged result.
  ///
  /// In en, this message translates to:
  /// **'Save Merged Document'**
  String get liveDiffSaveMerged;

  /// Body text of the vault lock dialog.
  ///
  /// In en, this message translates to:
  /// **'Encrypt \"{fileName}\" using AES-256-GCM hardware key encryption.'**
  String vaultLockBody(String fileName);

  /// Explanation shown under the vault lock dialog body.
  ///
  /// In en, this message translates to:
  /// **'The resulting .txvault file can only be decrypted and read by this app using your fingerprint or device biometrics.'**
  String get vaultLockNote;

  /// Confirm button in the vault lock dialog.
  ///
  /// In en, this message translates to:
  /// **'Encrypt & Save'**
  String get vaultEncryptAndSave;

  /// Snack bar shown after the vault file is written.
  ///
  /// In en, this message translates to:
  /// **'Encrypted vault saved as \"{fileName}\"'**
  String vaultSavedAs(String fileName);

  /// Error snack bar when the vault file cannot be written.
  ///
  /// In en, this message translates to:
  /// **'Could not save encrypted vault file.'**
  String get vaultSaveFailed;

  /// Reason shown in the system biometric prompt.
  ///
  /// In en, this message translates to:
  /// **'Lock {fileName} in Biometric Vault'**
  String vaultBiometricReason(String fileName);

  /// Footer line on the About screen.
  ///
  /// In en, this message translates to:
  /// **'Made with ❤ from India'**
  String get aboutMadeInIndia;

  /// Option to begin a live diff session with a peer device.
  ///
  /// In en, this message translates to:
  /// **'Start P2P Live Sync with Peer'**
  String get diffStartLiveSync;

  /// Option to compare the open document with a file picked from storage.
  ///
  /// In en, this message translates to:
  /// **'Compare with Local File (SAF)'**
  String get diffCompareLocalFile;

  /// Empty state in the CSV diff view.
  ///
  /// In en, this message translates to:
  /// **'No CSV data to compare.'**
  String get diffNoCsvData;

  /// Empty state in the text diff view.
  ///
  /// In en, this message translates to:
  /// **'No differences found. Documents are identical.'**
  String get diffNoDifferences;

  /// Button to accept the local side of one diff block.
  ///
  /// In en, this message translates to:
  /// **'← Mine'**
  String get diffAcceptMineSide;

  /// Button to accept the peer side of one diff block.
  ///
  /// In en, this message translates to:
  /// **'Peer →'**
  String get diffAcceptPeerSide;

  /// Button to keep both sides of one diff block.
  ///
  /// In en, this message translates to:
  /// **'Both'**
  String get diffAcceptBoth;

  /// Snack bar after the merged result is applied to the open tab.
  ///
  /// In en, this message translates to:
  /// **'Applied merged changes to open document.'**
  String get liveDiffApplied;

  /// Snack bar after the merged file is written.
  ///
  /// In en, this message translates to:
  /// **'Saved merged file as \"{fileName}\"'**
  String liveDiffSavedAs(String fileName);

  /// Error snack bar when the merged file cannot be written.
  ///
  /// In en, this message translates to:
  /// **'Could not save merged file.'**
  String get liveDiffSaveFailed;

  /// Menu item to merge all non-conflicting blocks at once.
  ///
  /// In en, this message translates to:
  /// **'Auto-Merge Clean Changes'**
  String get liveDiffAutoMergeClean;

  /// Error snack bar when a picked file cannot be read.
  ///
  /// In en, this message translates to:
  /// **'Could not read selected file.'**
  String get p2pReadFileFailed;

  /// Error snack bar when the open tab content cannot be read.
  ///
  /// In en, this message translates to:
  /// **'Could not read open tab content.'**
  String get p2pReadTabFailed;

  /// Button to choose a file through the system file picker.
  ///
  /// In en, this message translates to:
  /// **'Pick from Device Storage (SAF)'**
  String get p2pPickFromStorage;

  /// Snack bar after a received file is written.
  ///
  /// In en, this message translates to:
  /// **'File saved as \"{fileName}\"'**
  String syncClientSavedAs(String fileName);

  /// Error snack bar when a received file cannot be written.
  ///
  /// In en, this message translates to:
  /// **'Could not save received file.'**
  String get syncClientSaveFailed;

  /// Button to pick a local file to compare against.
  ///
  /// In en, this message translates to:
  /// **'Pick Local File (SAF)'**
  String get syncClientPickLocalFile;

  /// Chip showing which local file is being compared.
  ///
  /// In en, this message translates to:
  /// **'Comparing with: {fileName}'**
  String syncClientComparingWith(String fileName);

  /// Text field label in the column selection sheet.
  ///
  /// In en, this message translates to:
  /// **'Replace column block with (optional)'**
  String get columnReplaceLabel;

  /// Text field hint in the column selection sheet.
  ///
  /// In en, this message translates to:
  /// **'Leave empty to keep or delete'**
  String get columnReplaceHint;

  /// Title of the diff options bottom sheet.
  ///
  /// In en, this message translates to:
  /// **'Live Document Diff & Delta Sync'**
  String get diffSheetTitle;

  /// Subtitle of the diff options bottom sheet.
  ///
  /// In en, this message translates to:
  /// **'Compare \"{fileName}\" side-by-side and selectively merge edits.'**
  String diffSheetSubtitle(String fileName);

  /// Subtitle of the start-live-sync option.
  ///
  /// In en, this message translates to:
  /// **'Connect with another device over local Wi-Fi to diff & pair-edit.'**
  String get diffStartLiveSyncSubtitle;

  /// Subtitle of the compare-with-local-file option.
  ///
  /// In en, this message translates to:
  /// **'Pick a second document from device storage.'**
  String get diffCompareLocalFileSubtitle;

  /// Error when the picked comparison file cannot be read.
  ///
  /// In en, this message translates to:
  /// **'Could not read chosen file for diff.'**
  String get diffReadChosenFileFailed;

  /// Heading above the list of open tabs in the diff sheet.
  ///
  /// In en, this message translates to:
  /// **'Or Compare with Open Tab:'**
  String get diffCompareOpenTab;

  /// Error when an open tab cannot be read for comparison.
  ///
  /// In en, this message translates to:
  /// **'Could not read tab for comparison.'**
  String get diffReadTabFailed;

  /// Button label while a received file is being saved.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get syncClientSaving;

  /// Button to save a received file through the system file picker.
  ///
  /// In en, this message translates to:
  /// **'Save to Device (SAF)'**
  String get syncClientSaveToDevice;

  /// Heading above the open-tab list on the receive screen.
  ///
  /// In en, this message translates to:
  /// **'Or match with an open tab:'**
  String get syncClientMatchOpenTab;

  /// Title for the features catalog screen.
  ///
  /// In en, this message translates to:
  /// **'Features'**
  String get featuresSectionTitle;

  /// Subtitle for the features card on the settings menu.
  ///
  /// In en, this message translates to:
  /// **'Explore all capabilities of SreerajP Text App'**
  String get featuresCardSubtitle;

  /// Header title on the features catalog screen.
  ///
  /// In en, this message translates to:
  /// **'SreerajP Text App Features'**
  String get featuresHeaderTitle;

  /// Header subtitle on the features catalog screen.
  ///
  /// In en, this message translates to:
  /// **'Explore every document format, powerful editor tool, offline sync, and privacy safeguard built for you.'**
  String get featuresHeaderSubtitle;

  /// Explanation of the sepia theme mode in appearance settings.
  ///
  /// In en, this message translates to:
  /// **'Sepia mode provides a warm, paper-like low-contrast look designed for comfortable long reading.'**
  String get appearThemeSepiaInfo;

  /// Explanation of the system theme mode in appearance settings.
  ///
  /// In en, this message translates to:
  /// **'System mode automatically matches your device\'s system-wide dark mode setting.'**
  String get appearThemeSystemInfo;

  /// Sample text rendered for English font preview.
  ///
  /// In en, this message translates to:
  /// **'The quick brown fox • 0123'**
  String get appearEnglishFontSample;

  /// Sample text rendered for Malayalam font preview.
  ///
  /// In en, this message translates to:
  /// **'മലയാളം സുന്ദരമാണ്'**
  String get appearMalayalamFontSample;

  /// Header title on the help hub.
  ///
  /// In en, this message translates to:
  /// **'Help Center & User Guides'**
  String get helpSectionHeader;

  /// Header subtitle on the help hub.
  ///
  /// In en, this message translates to:
  /// **'Browse in-depth guides and tips for all features of SreerajP Text App.'**
  String get helpSectionSubtitle;

  /// Help category for editor and document management.
  ///
  /// In en, this message translates to:
  /// **'Editing & Documents'**
  String get helpCategoryEditing;

  /// Help category for SQL, JSONPath, and XML tools.
  ///
  /// In en, this message translates to:
  /// **'Data Querying & Analysis'**
  String get helpCategoryData;

  /// Help category for vault, lock, and audit features.
  ///
  /// In en, this message translates to:
  /// **'Privacy & Security'**
  String get helpCategoryPrivacy;

  /// Help category for LAN sync and AirQR.
  ///
  /// In en, this message translates to:
  /// **'Sync & AirQR Transfer'**
  String get helpCategorySync;

  /// Help category for TTS, speech, and themes.
  ///
  /// In en, this message translates to:
  /// **'Voice & Accessibility'**
  String get helpCategoryVoice;

  /// Help category for FAQs and troubleshooting.
  ///
  /// In en, this message translates to:
  /// **'Frequently Asked Questions'**
  String get helpCategoryFaq;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ml'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ml':
      return AppLocalizationsMl();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
