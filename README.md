# Pyramid

A Premier League **Last Man Standing** iOS app. Players pick one team each gameweek — if their team wins or draws, they survive. If their team loses, they're eliminated. Last players standing share the prize pot.

## How It Works

- **Free leagues** — create a league, share the join code, play for bragging rights (5–50 players)
- **Paid leagues** — stake £5, get randomly matched, top 3 split the prize pot (5–30 players)
- Picks lock at first kick-off of the gameweek
- No repeating team picks within a round
- Draw = survived; miss the deadline = auto-eliminated

Full game rules: [`docs/game-rules/rules.md`](docs/game-rules/rules.md)

## Tech Stack

| Layer | Technology |
|-------|-----------|
| iOS | SwiftUI (MVVM), Swift 5.9, iOS 16+ |
| Backend | Supabase (Postgres, Auth, Edge Functions) |
| Payments | Stripe (via Edge Functions) |
| Football Data | API-Football |
| Project Gen | XcodeGen |
| CI | GitHub Actions |

## Project Structure

```
ios/
  Pyramid/Sources/
    App/              # App entry point, root navigation, app state
    Features/
      Auth/           # Sign in / sign up
      Leagues/        # Create, join, and manage leagues
      Picks/          # Weekly team selection
      Results/        # Match results and standings
      Profile/        # User profile and settings
      Wallet/         # Top-up, withdraw, transaction history
    Models/           # Data models
    Services/         # API and business logic services
    Shared/           # Design system, Supabase client, utilities
  project.yml         # XcodeGen spec

supabase/
  functions/          # Deno Edge Functions
    create-league/        join-league/         join-paid-league/
    submit-pick/          settle-picks/        poll-live-scores/
    sync-fixtures/        get-wallet/          top-up/
    request-withdrawal/   credit-winnings/     distribute-prizes/
    process-dispute-window/  refund-stake/     register-device-token/
  migrations/         # Postgres schema migrations
  seed/               # Dev seed data

docs/
  game-rules/         # Authoritative game rules
  adr/                # Architecture Decision Records
  prd/                # Product Requirements Documents
  plans/              # Implementation plans
```

## Getting Started

### Prerequisites

- Xcode 15+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)
- [Supabase CLI](https://supabase.com/docs/guides/cli) (`brew install supabase/tap/supabase`)
- Node.js 18+ (for Edge Function tooling)

### Setup

```bash
# Clone the repo
git clone https://github.com/your-org/Pyramid.git
cd Pyramid

# Generate the Xcode project
cd ios
xcodegen generate
open Pyramid.xcodeproj

# Start Supabase locally
cd ../supabase
supabase start
supabase db reset   # applies migrations + seed data
```

### Configuration

Create `ios/Config/Debug.xcconfig` with your Supabase dev credentials:

```
SUPABASE_URL = http://<local-or-dev-url>
SUPABASE_ANON_KEY = <your-anon-key>
```

These are read at runtime via `Info.plist` — no secrets in source code.

## Architecture

- **All mutations go through Edge Functions** — the iOS client never writes directly to the database
- **Idempotent settlement** — every settlement operation is safe to replay (unique constraint on idempotency keys)
- **Immutable audit trail** — every pick, result, and financial transaction is logged
- **Correctness over speed** — pick and settlement logic is designed to be bulletproof since real money is involved

### Key ADRs

| ADR | Decision |
|-----|----------|
| [ADR-001](docs/adr/ADR-001-database-backend-platform.md) | Supabase for backend |
| [ADR-002](docs/adr/ADR-002-ios-tech-stack.md) | SwiftUI + MVVM |
| [ADR-003](docs/adr/ADR-003-pl-data-provider.md) | API-Football for match data |
| [ADR-004](docs/adr/ADR-004-payment-provider.md) | Stripe for payments |

## Development

### Branch Strategy

| Branch | Purpose |
|--------|---------|
| `main` | Production — protected, requires approval |
| `develop` | Integration branch |
| `feature/*` | Feature work |
| `fix/*` | Bug fixes |
| `chore/*` | Non-feature changes |

### After Adding Swift Files

Always regenerate the Xcode project:

```bash
cd ios && xcodegen generate
```

XcodeGen auto-discovers all `.swift` files, so you don't need to manually update the project file.

### Running Edge Functions Locally

```bash
cd supabase
supabase functions serve --env-file .env.local
```

## License

All rights reserved.
