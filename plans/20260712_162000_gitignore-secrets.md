# Plan: Make .gitignore protect signing secrets

**Status:** completed

## The issue

The root `.gitignore` does not ignore the app signing secrets. These files exist in the tree:

- `textapp-keystore.jks` (root) — the signing keystore (private key).
- `android/key.properties` — keystore passwords and key alias.
- `android/local.properties` — local machine SDK path (should never be committed).

If the repo is initialised and `git add .` is run, all three would be committed. The
keystore and its passwords are secrets and must never enter version control.

Note: the `.git` folder in the project is currently empty (not a valid repo), so nothing
has been committed yet. This fix is preventive.

## Files to change

- `.gitignore` (root) — add rules for signing secrets.

## The plan for the fix

Add a new "Signing / secrets" section to `.gitignore` with:

```
# Signing / secrets — never commit these
*.jks
*.keystore
**/key.properties
**/android/local.properties
*.p12
*.pem
```

Keep `android/key.properties.example` committable (the `*.properties` pattern is not used,
so the example file stays tracked).

## Verify

- Confirm the patterns match the three real files but not `key.properties.example`.
