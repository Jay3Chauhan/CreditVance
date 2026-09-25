# CardSage Project Agent Guidelines & Vibe-Coding Rules
*Target IDEs: Antigravity & Cursor*

## 1. Architectural Philosophy: Flutter Clean Architecture
Every feature must follow feature-first Clean Architecture:
```
lib/
├── core/
│   ├── constants/       # AppColors, AppTypography, AppDimensions, AppAssets, ApiEndpoints
│   ├── network/         # ApiClient, AuthInterceptor, NetworkInfo, ApiResult, NetworkExceptions
│   ├── storage/         # SecureVaultService (Biometrics + Hardware Enclave), CacheService
│   ├── theme/           # AppTheme (Dark & Light luxury themes)
│   ├── utils/           # Formatters, ClipboardHelper, HapticsHelper
│   └── widgets/         # Centralized reusable widgets (Buttons, Shimmers, ErrorStates, AppIcons)
└── features/
    ├── <feature_name>/
    │   ├── data/
    │   │   ├── datasources/  # Remote & Local datasources
    │   │   ├── models/       # DTOs / JSON parsing
    │   │   └── repositories/ # Concrete repository implementations
    │   ├── domain/
    │   │   ├── entities/     # Immutable business objects
    │   │   └── repositories/ # Abstract repository contracts
    │   └── presentation/
    │       ├── providers/    # ChangeNotifiers / ViewModels (State Machines)
    │       ├── screens/      # Stateless Screens
    │       └── widgets/      # Atomic UI components for this feature
```

## 2. STRICT State Management Rules (ZERO `setState`)
- **NEVER use `setState()` in any widget**.
- Use **`ChangeNotifier` + `Provider`** for complex feature states and asynchronous operations.
- Use **`ValueNotifier<T>` + `ValueListenableBuilder<T>`** for micro-states (e.g. tabs, animations, input toggles, search queries).
- Screens must extend **`StatelessWidget`**.
- Keep widget rebuild scopes minimal: wrap only the affected subtree in `Consumer<T>`, `Selector<T, S>`, or `ValueListenableBuilder<T>`.
- Never rebuild an entire screen when only a single button, label, or chip changed.

## 3. Strict UI/UX Standards & Centralization
- **No Raw Hardcoded Colors**: Always reference `AppColors.*`.
- **No Raw TextStyles**: Always reference `AppTypography.*` or `Theme.of(context).textTheme.*`.
- **No Raw Dimensions/Paddings**: Always reference `AppDimensions.*`.
- **Centralized Icons**: Never use arbitrary icon packages or direct native icons across files. All iconography must be accessed via `AppIcons.*` in `core/constants/app_icons.dart`.
- **Const Optimization**: Enforce `const` on all possible constructors to prevent unnecessary rebuilds.
- **Micro-Animations & Tactile Feedback**:
  - Interactive elements must use haptic feedback (`HapticsHelper`).
  - Subtle transitions and staggered entrances using `flutter_animate`.
  - Luxury fintech aesthetic: layered obsidian surfaces (`#090B10`, `#11151F`, `#181E2C`), subtle gold (`#DFB76C`), emerald (`#10B981`), sapphire (`#3B82F6`).

## 4. Error Handling & State Machine Protocol
Every ViewModel/Provider must implement a standard `ViewState`:
- `ViewState.initial`
- `ViewState.loading`
- `ViewState.loaded`
- `ViewState.empty`
- `ViewState.error`
- `ViewState.refreshing`

Every asynchronous data call must:
1. Handle network loss gracefully.
2. Return a typed `Result<T>` or `ApiResult<T>`.
3. Provide descriptive user-facing error messages via `ErrorStateView`.
4. Provide an offline/cache fallback if the backend is unreachable.

## 5. Security & Zero-Knowledge Vault Rules
- Card PAN (16-digit card number), CVV, and full expiry MUST NEVER be sent to any backend API.
- All sensitive card data is encrypted on device using `flutter_secure_storage` backed by Android KeyStore / iOS Keychain.
- Decryption or copying to clipboard REQUIRES biometric verification via `local_auth`.
- Clipboard auto-clears after 30 seconds for security.
