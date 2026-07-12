# Create a new supported document
**Status:** completed

## Issue

The Home screen only lets the user open an existing file. A user cannot create a
new TXT, Markdown, CSV, JSON, or XML document from inside the app.

The app already has a scoped-storage `createDocument` operation and a shared
open-file flow. This change should reuse both. It must not add broad storage
permission, an in-app file browser, or a separate tab-opening path.

## Files to change

- `lib/shell/home/home_screen.dart`
  - Replace the single-purpose Open file floating button with a clear entry point
    for both opening a file and creating a new document.
  - Show a Material 3 format picker for TXT, Markdown, CSV, JSON, and XML.
- `lib/shell/create_document_action.dart` (new)
  - Define the five choices, their file extensions, MIME types, suggested names,
    and small valid starter contents.
  - Call the existing SAF create-document picker.
  - Handle cancellation and storage errors with friendly messages.
  - Open the created file through the shared fingerprint, recents, tab-cap, and
    editor-navigation flow.
- `lib/shell/open_file_action.dart`
  - Expose/refactor the existing shared “open this `SafFile`” operation so both
    picked files and newly created files use one path.
- `lib/l10n/app_en.arb`
  - Add English strings for the New document action, format picker, format names,
    and creation failure feedback.
- `lib/l10n/app_localizations.dart`
- `lib/l10n/app_localizations_en.dart`
  - Regenerate localization code from the ARB file.
- `test/support/test_support.dart`
  - Extend the fake SAF service so tests can capture and return created documents.
- `test/shell/home_screen_widget_test.dart`
  - Test that the new action and format picker appear on empty and populated Home
    screens.
- `test/shell/create_document_action_test.dart` (new)
  - Test each format's suggested extension, MIME type, and starter bytes.
  - Test successful creation opens the correct editor tab and updates navigation.
  - Test cancellation and storage failure without crashes or unwanted tabs.
- `docs/implementation-progress.md`
  - Record the added create-document capability and any manual Android check still
    required.
- `change_log/<timestamp>_create-new-document.md` (new, after implementation)
  - Record the completed work, checks, and the plan implemented.
- `plans/20260712_131042_create-new-document.md`
  - Keep this plan's status current through implementation.

Generated localization files will only be changed through Flutter's localization
generator. No dependency, Android manifest, or native Android source change is
planned because the required SAF platform operation already exists.

## Plan for the fix

1. Refactor the existing file-open coordinator just enough to accept a `SafFile`
   returned by either Pick or Create. Preserve its current fingerprint, recent-file,
   tab-cap, friendly-error, and editor-navigation behavior.
2. Add a create-document coordinator with a fixed definition for each supported
   format:
   - TXT: empty UTF-8 content, `.txt`, `text/plain`.
   - Markdown: empty UTF-8 content, `.md`, `text/markdown`.
   - CSV: empty UTF-8 content, `.csv`, `text/csv`.
   - JSON: a valid empty object plus newline, `.json`, `application/json`.
   - XML: a UTF-8 declaration and one valid root element plus newline, `.xml`,
     `application/xml`.
3. Add a Home action that offers Open file and New document. The New document
   choice opens an accessible Material 3 picker listing all five supported formats.
4. Send the chosen suggested name, MIME type, and bytes to the existing Android
   Storage Access Framework create picker. If the user cancels, leave the app state
   unchanged. If creation fails, show a friendly message and do not open a tab.
5. After successful creation, send the returned SAF file into the shared open flow.
   This records it in Recents, respects the tab limit/read-only settings, and opens
   the matching format editor.
6. Add and regenerate all user-facing localized text. Do not hardcode UI strings.
7. Add widget and coordinator tests for the UI, all format definitions, success,
   cancellation, errors, and navigation. Keep file contents out of logs and error
   messages.
8. Run `dart format` on changed Dart files, generate localizations, run focused
   tests, run the full test suite, and run `flutter analyze`.
9. Update `docs/implementation-progress.md`, write the required change log, and
   mark this plan `completed`. Note that the Android system create picker still
   needs a manual on-device check if it cannot be verified in this environment.

## Acceptance checks

- Home clearly offers both Open file and New document.
- New document lists exactly TXT, Markdown, CSV, JSON, and XML.
- The Android system picker controls the new file's name and location.
- A successful creation opens the correct app editor and appears in Recents.
- JSON and XML starter files are well formed; all starter files are UTF-8.
- Cancelling or encountering a SAF error does not create a tab or crash.
- No broad storage permission, in-app file browser, new online behavior, or new
  package is introduced.
- Focused tests, full tests, localization generation, formatting, and static
  analysis pass, or any remaining failure is clearly recorded.
