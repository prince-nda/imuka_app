# Imuka — relocation made simple

Imuka is a Flutter mobile app for people relocating within Rwanda. In one
place you can find **verified homes**, compare them side by side, request a
viewing, list what you are moving, get an **upfront itemised price**, book a
verified mover, **track the truck live**, tick every item on arrival and only
then pay.

Backend: **Firebase Authentication** (email + password, and Google) and
**Cloud Firestore**, project `imuka-app`.

## Running the app

Requirements: Flutter 3.47+ (Dart 3.13+, see `pubspec.yaml`), an Android
emulator, iOS simulator or phone, and the Firebase CLI (`npm i -g
firebase-tools`) plus FlutterFire CLI (`dart pub global activate
flutterfire_cli`). The app targets **Android and iOS only**.

```bash
flutter pub get
flutter run
```

Offline UI work without Firebase: `flutter run --dart-define=USE_MOCKS=true`
(demo login `aline@imuka.rw` / `kigali2026`).

### One-time Firebase setup (per teammate)

1. `firebase login` with an account that has access to `imuka-app`.
2. **Android:** register your debug signing key, which Google sign-in
   needs:
   ```bash
   keytool -list -v -keystore ~/.android/debug.keystore \
     -alias androiddebugkey -storepass android | grep -E "SHA1|SHA256"
   firebase apps:android:sha:create 1:982611988114:android:7b26b857ef9bfc230d204b <SHA>
   ```
3. After changing providers in the console, re-run
   `flutterfire configure --project=imuka-app --platforms=android,ios`.

### Database setup (already done for `imuka-app`)

```bash
firebase deploy --only firestore      # security rules + indexes
dart run tool/export_seed.dart        # catalogue → tool/seed/seed_data.json
node tool/seed_firestore.mjs          # upload listings, landlords, movers
```

Listings, landlords and movers are read-only in the rules, so they are
published with the seed tool (using your Firebase CLI login), not from the
app.

### Signing in

| Method | How |
|---|---|
| Email + password | Create an account → open the verification email → tap **I've verified my email** |
| Google | Log in → **Continue with Google** |

The phone number asked at sign-up is a contact number for movers and
owners; it is not verified.

Forgot password sends a reset email. The session survives app restarts.

### Quality checks

```bash
dart format lib test tool
flutter analyze        # 0 issues
flutter test           # 55 unit, bloc and widget tests
flutter test --coverage
```

## Architecture

Clean Architecture per feature, with **flutter_bloc (Cubit)** for state. No
`setState` is used for state management. The few `StatefulWidget`s only own
`TextEditingController`s, form keys, an `AnimationController` or the router.

```
lib/
├── main.dart                 # wires repositories (mock → Firebase later)
├── app.dart                  # RepositoryProviders, app-wide Cubits, theme
├── core/
│   ├── domain/               # GeoPoint (haversine), Rwandan towns & road distances
│   ├── router/               # go_router: auth guard, 4-tab StatefulShellRoute
│   ├── theme/                # light/dark ThemeData + AppPalette tokens from Figma
│   ├── utils/                # formatters (RWF, dates), validators
│   └── widgets/              # reusable UI kit (buttons, badges, pickers, map…)
└── features/
    ├── auth/                 # welcome, login (email/Google), sign-up, verify email, reset password
    ├── properties/           # home, filters, results, details, how we verify
    ├── shortlist/            # compare homes
    ├── viewing/              # contact owner, viewing requested
    ├── move/                 # my move, items, costs, movers, tracking,
    │                         # check items, payment, complete, tasks
    └── settings/             # SharedPreferences preferences, logout
        each feature:  domain/   entities, repository interfaces, services
                       data/     repository implementations (mock today)
                       presentation/ cubit/, pages/, widgets/
```

Business rules live in the domain layer and are unit-tested:

* `MoveCostCalculator`: items + `vehicle.baseFee + perKm × distance` +
  loaders. It reproduces the Figma total of RWF 220,000 for Huye → Kigali.
* `MoverRanking.bestValue`: highest `rating × 100,000 − quote`.
* `PropertyFilter.matches/apply`: all search filters, sorted by distance.
* `CompareInsights.bestMatch`: closest *verified* home to work or school.

### Data layer

Each feature's `domain/repositories` defines an interface, and `data/`
provides two implementations: **Firestore** (used by the app) and an
in-memory **mock** (used by tests and `USE_MOCKS`). Field names live in
`data/models`, which both the app and `tool/export_seed.dart` use, so the
database, the seed data and the ERD stay identical. See
[docs/ERD.md](docs/ERD.md).

| Collection | Contents | CRUD in the app |
|---|---|---|
| `users/{uid}` | profile | create (sign-up), read, update (name) |
| `users/{uid}/shortlist/{propertyId}` | saved homes | create, read, delete |
| `properties`, `landlords`, `movers` | catalogue | read |
| `viewings/{id}` | viewing requests | create, read (My viewings), update (cancel) |
| `moves/{uid}` | plan, booking, payment, rating | create, read, update |
| `moves/{uid}/items/{id}` | items to move | create, read, update (quantity), delete, clear all |
| `moves/{uid}/tasks/{id}` | checklist | create, read, update (tick, rename), delete |

### Security rules (`firestore.rules`)

* Nothing is readable while signed out.
* Users can only read and write their own documents. Paths are keyed by
  uid, and viewings carry `userId`, which must equal the caller's uid
  (queries included).
* Email accounts must verify their email (`email_verified` token claim)
  before they can use move, shortlist or viewing data. Google sign-ins
  count as verified.
* Catalogue collections reject every write from the app.
* Every write is validated:
  * only whitelisted fields are allowed, with type and range checks
    (quantity 1–99, rating 0–5, 9-digit phone, enums);
  * item prices and user roles can't be changed after creation;
  * a viewing's `landlordId` must match the listing;
  * a booked `moverId` must exist.

### State management

| Cubit | Scope | Purpose |
|---|---|---|
| `AuthCubit` | app | session; router redirects on change |
| `SettingsCubit` | app | theme, verified-only default, payment method, reminders (persisted) |
| `PropertySearchCubit` | app | filters shared by Home, Search and Results |
| `ShortlistCubit` | app | saved homes (bookmark icon + Shortlist tab badge) |
| `MovePlanCubit` | app | route, date, vehicle, items CRUD, live estimate |
| `MoveBookingCubit` | app | movers, booking, payment, rating |
| `MoveTasksCubit` | app | checklist CRUD |
| `Login/Signup/VerifyEmail/ResetPasswordCubit` | page | auth flows |
| `MyViewingsCubit` | page | list and cancel viewings |
| `PropertyDetailsCubit`, `ContactOwnerCubit` | page | listing, viewing request |
| `TrackingCubit`, `DeliveryCheckCubit` | page | live truck stream, item check |

### User preferences (SharedPreferences)

Theme mode, *verified listings only* default, preferred payment method and
move reminders are saved on change and restored on launch (Settings, opened
from the avatar on Home). The login session is also persisted.

## Responsiveness and accessibility

* Every screen scrolls and is width-capped, so landscape and tablets don't
  overflow. Welcome and Live tracking switch to side-by-side layouts in
  landscape.
* Touch targets are ≥ 44–48 pt and secondary text meets 4.5:1 contrast.
  Semantics labels are set on custom controls.

## Known limitations and future work

* **Payments are recorded, not processed.** The receipt is written by the
  app. A real MTN MoMo / Airtel / card integration would confirm payments
  server-side (Cloud Functions), with rules that block client writes to
  payment fields.
* **Live tracking is simulated** until movers have a driver app that shares
  GPS.
* **Phone numbers are not verified.** SMS verification was removed
  because Firebase only sends real SMS on the paid Blaze plan; it could
  return with that plan.
* **Landlord tools are not built yet.** The landlord role exists, but
  listing a home is future work.
* **No automated rule tests yet.** Next step: `@firebase/rules-unit-testing`
  against the emulator.

## Assets

Photos and the truck illustration are placeholders cropped from the 1× Figma
screenshots, in `assets/images/`. **Export them at 3× from Figma** and
replace the files (same names) for sharp images. Font: Plus Jakarta Sans
(OFL), bundled in `assets/fonts/`.
