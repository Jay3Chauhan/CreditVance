---
description: Strict Flutter Clean Architecture, Provider, ValueNotifier and Zero-setState Guidelines for CardSage
globs: lib/**/*.dart
always_on: true
---

# CardSage Flutter Clean Architecture & Vibe-Coding Standards

## 1. Zero `setState()` Mandate
- Calling `setState()` is strictly prohibited in any file in this codebase.
- Presentation logic belongs in `ChangeNotifier` (via Provider) or `ValueNotifier<T>`.
- Use `ValueNotifier<T>` paired with `ValueListenableBuilder<T>` for local UI state (e.g., active tabs, modal states, input masks).
- Use `ChangeNotifier` with `Consumer<T>` or `Selector<T, S>` for async data flows, domain entities, and repository communication.
- All screen classes must be `StatelessWidget`.

## 2. Directory & Layer Organization
```
lib/
├── core/
│   ├── constants/
│   │   ├── api_endpoints.dart
│   │   ├── app_colors.dart
│   │   ├── app_dimensions.dart
│   │   ├── app_icons.dart
│   │   ├── app_strings.dart
│   │   └── app_typography.dart
│   ├── network/
│   │   ├── api_client.dart
│   │   ├── api_result.dart
│   │   ├── auth_interceptor.dart
│   │   └── network_info.dart
│   ├── storage/
│   │   ├── secure_vault_service.dart
│   │   └── local_cache_service.dart
│   ├── theme/
│   │   └── app_theme.dart
│   ├── utils/
│   │   ├── card_formatter.dart
│   │   ├── clipboard_helper.dart
│   │   ├── currency_formatter.dart
│   │   └── haptics_helper.dart
│   └── widgets/
│       ├── luxury_button.dart
│       ├── luxury_text_field.dart
│       ├── luxury_glass_card.dart
│       ├── luxury_badge.dart
│       ├── shimmer_card_skeleton.dart
│       ├── empty_state_view.dart
│       └── error_state_view.dart
└── features/
    ├── auth/
    ├── advisor/
    ├── wallet/
    ├── catalog/
    └── calculator/
```

## 3. UI/UX Rules
- **Color Consistency**: Never instantiate `Color(0x...)` inline in UI widgets. Always use `AppColors.*`.
- **Icon Consistency**: Never import different random icon packages across widgets. Always use `AppIcons.*`.
- **Text Styles**: Never declare raw `TextStyle(...)` directly in UI components. Use `AppTypography.*` or `Theme.of(context).textTheme.*`.
- **Performance**: Use `const` constructors on every immutable widget and constructor call.
- **Granular Rebuilds**: Narrow the scope of `Consumer` or `ValueListenableBuilder` to the absolute leaf widget that needs to change.

## 4. Security & Vault Standards
- Never send card PAN (16 digits), CVV, or full expiration to the backend.
- Full card numbers are stored exclusively in hardware Secure Enclave via `SecureVaultService`.
- Biometric authentication (`local_auth`) is mandatory before viewing or copying full card PAN/CVV.
- Clipboard copy actions must auto-wipe the clipboard after 30 seconds.
