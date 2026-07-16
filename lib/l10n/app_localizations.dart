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

  /// Help topic title for splitting a JSON array.
  ///
  /// In en, this message translates to:
  /// **'Split array'**
  String get helpSplitArrayTitle;

  /// Help text explaining how Split array works.
  ///
  /// In en, this message translates to:
  /// **'Split array works when the top level of a JSON file is an array. Choose how many items each part should contain. The app then creates numbered files such as name.part1.json and asks where to save each one. The last part may contain fewer items. Your original file is not changed.'**
  String get helpSplitArrayBody;

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
