# Change log: Make .gitignore protect signing secrets

Implements plan `plans/20260712_162000_gitignore-secrets.md`.

## What changed

Added a "Signing / secrets" section to the root `.gitignore`:

```
# Signing / secrets — never commit these
*.jks
*.keystore
**/key.properties
**/android/local.properties
*.p12
*.pem
```

## Why

The signing keystore (`textapp-keystore.jks`), keystore passwords
(`android/key.properties`), and local SDK path (`android/local.properties`) were not
ignored. Without these rules a `git add .` would commit the private signing key and its
passwords.

## Verification

Tested the patterns in a throwaway git repo against dummy files:

- `textapp-keystore.jks` → ignored
- `android/key.properties` → ignored
- `android/local.properties` → ignored
- `*.keystore`, `*.p12`, `*.pem` → ignored
- `android/key.properties.example` → still tracked (template kept in version control)

## Notes

- The project's `.git` folder is currently empty (not a valid repository), so no secret
  has been committed. This change is preventive. If the repo is later initialised, the
  keystore and passwords will be excluded automatically.
