# Production Deployment Runbook

> Step-by-step guide for setting up and running production deployments.
> All three pipelines are manual-trigger only with confirmation gates.

---

## 1. One-Time Setup: GitHub Environment

Before any production workflow can run, create the `production` GitHub Environment:

1. Go to **GitHub repo → Settings → Environments**
2. Click **New environment** → name it `production`
3. Enable **Required reviewers** → add yourself (Jake Cox)
4. Optionally set **Wait timer** (e.g. 5 minutes) for extra safety
5. Save

This means every production deploy will require your explicit approval in the GitHub Actions UI.

---

## 2. One-Time Setup: GitHub Secrets

Go to **GitHub repo → Settings → Secrets and variables → Actions**.

### Edge Functions (prod)

These secrets are needed for `deploy-functions-prod.yml`:

| Secret Name | Where to Get It | Notes |
|------------|-----------------|-------|
| `SUPABASE_ACCESS_TOKEN` | **Already exists** | Shared between dev and prod |
| `SUPABASE_PROJECT_REF_PROD` | Set to `cracvbokmvryhhclzxxw` | The prod Supabase project ref |

**Steps:**
1. Add `SUPABASE_PROJECT_REF_PROD` = `cracvbokmvryhhclzxxw`
2. That's it — `SUPABASE_ACCESS_TOKEN` is already configured

### Database Migrations (prod)

These secrets are needed for `deploy-migrations-prod.yml`:

| Secret Name | Where to Get It | Notes |
|------------|-----------------|-------|
| `SUPABASE_DB_PASSWORD_PROD` | Supabase Dashboard → Project Settings → Database → Database password | The password you set when creating the prod project |

**Steps:**
1. Go to https://supabase.com/dashboard/project/cracvbokmvryhhclzxxw/settings/database
2. Copy the database password (or reset it if you don't have it)
3. Add as `SUPABASE_DB_PASSWORD_PROD` in GitHub Secrets

### iOS TestFlight

These secrets are needed for `deploy-testflight.yml`:

| Secret Name | Where to Get It | Notes |
|------------|-----------------|-------|
| `APPLE_TEAM_ID` | Apple Developer Portal → Membership → Team ID | 10-character alphanumeric |
| `APP_STORE_CONNECT_API_KEY_ID` | App Store Connect → Users → Keys → Generate | Short string like `ABC123DEF4` |
| `APP_STORE_CONNECT_ISSUER_ID` | Same page as above → Issuer ID at top | UUID format |
| `APP_STORE_CONNECT_API_KEY_P8` | Download the .p8 file → base64 encode | See encoding steps below |
| `APPLE_CERTIFICATE_P12` | Export from Keychain Access → base64 encode | Distribution certificate |
| `APPLE_CERTIFICATE_PASSWORD` | Password you set when exporting the .p12 | Plain text |
| `APPLE_PROVISIONING_PROFILE` | Apple Developer Portal → Profiles → base64 encode | App Store distribution profile |
| `SUPABASE_URL_PROD` | Set to `https://cracvbokmvryhhclzxxw.supabase.co` | Prod Supabase URL |
| `SUPABASE_ANON_KEY_PROD` | Supabase Dashboard → Project Settings → API → anon key | The prod anon key |

#### Step-by-step: App Store Connect API Key

1. Go to https://appstoreconnect.apple.com/access/integrations/api
2. Click **Generate API Key**
3. Name: `Pyramid CI` | Access: `App Manager`
4. Download the `.p8` file (you can only download it once!)
5. Note the **Key ID** and **Issuer ID** shown on the page
6. Base64-encode the .p8 file:
   ```bash
   base64 -i AuthKey_XXXXXXXXXX.p8 | tr -d '\n'
   ```
7. Add to GitHub Secrets:
   - `APP_STORE_CONNECT_API_KEY_ID` = the Key ID
   - `APP_STORE_CONNECT_ISSUER_ID` = the Issuer ID
   - `APP_STORE_CONNECT_API_KEY_P8` = the base64 output

#### Step-by-step: Distribution Certificate

1. Open **Keychain Access** on your Mac
2. Go to Apple Developer Portal → Certificates → Create a **Apple Distribution** certificate (if you don't have one)
3. Download and install it into Keychain Access
4. In Keychain Access, find the certificate → right-click → **Export** as .p12
5. Set a password when prompted
6. Base64-encode:
   ```bash
   base64 -i Certificates.p12 | tr -d '\n'
   ```
7. Add to GitHub Secrets:
   - `APPLE_CERTIFICATE_P12` = the base64 output
   - `APPLE_CERTIFICATE_PASSWORD` = the password you set

#### Step-by-step: Provisioning Profile

1. Go to https://developer.apple.com/account/resources/profiles/list
2. Create a new profile:
   - Type: **App Store Distribution**
   - App ID: `com.pyramid.app`
   - Certificate: select the distribution cert from above
   - Name: `Pyramid Distribution`
3. Download the `.mobileprovision` file
4. Base64-encode:
   ```bash
   base64 -i Pyramid_Distribution.mobileprovision | tr -d '\n'
   ```
5. Add as `APPLE_PROVISIONING_PROFILE` in GitHub Secrets

#### Note: exportOptions.plist

The `ios/exportOptions.plist` file contains a `TEAM_ID_PLACEHOLDER` value. This is **intentional** — the CI workflow patches it at build time using the `APPLE_TEAM_ID` secret via PlistBuddy. You do not need to commit your real Team ID into the file.

If your provisioning profile name differs from `Pyramid Distribution`, update the profile name in `exportOptions.plist` and commit the change.

---

## 3. Running Deployments

### Deploy Edge Functions to Production

1. Go to **Actions → Deploy Edge Functions (Production)**
2. Click **Run workflow**
3. Type `deploy-prod` in the confirmation field
4. Optionally check **Dry run** to preview first
5. Click **Run workflow**
6. Approve the environment protection rule when prompted
7. Monitor the logs

**Rollback:** Re-run the workflow from a previous commit. Find the last good tag:
```bash
git tag --list 'prod-functions-*' --sort=-creatordate | head -5
```
Then checkout that tag and re-trigger the workflow.

### Deploy Database Migrations to Production

1. Go to **Actions → Deploy Migrations (Production)**
2. Click **Run workflow**
3. Type `migrate-prod` in the confirmation field
4. **First run with Dry run = true** to preview pending migrations
5. Review the diff output in the logs
6. Re-run with **Dry run = false** to apply
7. Approve the environment protection rule when prompted

**Rollback:** Database migrations are not automatically reversible. If a migration breaks something, you'll need to write a corrective migration or restore from backup.

### Deploy to TestFlight

1. Go to **Actions → Deploy to TestFlight**
2. Click **Run workflow**
3. Enter the **version number** (e.g. `1.0.0`)
4. Type `deploy-testflight` in the confirmation field
5. Click **Run workflow**
6. Approve the environment protection rule when prompted
7. Wait ~15 minutes for TestFlight processing after upload

**Version strategy:**
- `MARKETING_VERSION` = the user-facing version you enter (1.0.0, 1.1.0, etc.)
- `BUILD_NUMBER` = auto-set to the GitHub Actions run number (always increasing)

---

## 4. Production Deploy Order (First Time)

When deploying to production for the first time, follow this order:

1. **Database migrations first** — schema must exist before functions can query it
2. **Edge Functions second** — functions depend on the schema
3. **iOS TestFlight last** — app depends on functions being live

---

## 5. Secret Summary

| Secret | Used By | Status |
|--------|---------|--------|
| `SUPABASE_ACCESS_TOKEN` | Functions, Migrations | Already configured |
| `SUPABASE_PROJECT_REF_PROD` | Functions, Migrations | Needs adding: `cracvbokmvryhhclzxxw` |
| `SUPABASE_DB_PASSWORD_PROD` | Migrations | Needs adding |
| `APPLE_TEAM_ID` | TestFlight | Needs adding |
| `APP_STORE_CONNECT_API_KEY_ID` | TestFlight | Needs adding |
| `APP_STORE_CONNECT_ISSUER_ID` | TestFlight | Needs adding |
| `APP_STORE_CONNECT_API_KEY_P8` | TestFlight | Needs adding |
| `APPLE_CERTIFICATE_P12` | TestFlight | Needs adding |
| `APPLE_CERTIFICATE_PASSWORD` | TestFlight | Needs adding |
| `APPLE_PROVISIONING_PROFILE` | TestFlight | Needs adding |
| `SUPABASE_URL_PROD` | TestFlight | Needs adding: `https://cracvbokmvryhhclzxxw.supabase.co` |
| `SUPABASE_ANON_KEY_PROD` | TestFlight | Needs adding |
