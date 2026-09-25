# Antigravity Project Instructions: CardSage
See [AGENTS.md](./AGENTS.md) for complete architecture and guidelines.

## Quick Summary for Antigravity:
1. **Flutter Clean Architecture**: Domain, Data, Presentation layers separated.
2. **Zero `setState`**: Strictly use `Provider` (`ChangeNotifier`) and `ValueNotifier<T>` + `ValueListenableBuilder<T>`.
3. **UI Quality**: Premium MNC Fintech aesthetic (Obsidian Dark `#090B10`, Imperial Gold `#DFB76C`, Cyber Emerald `#10B981`, Sapphire `#3B82F6`).
4. **Const Correctness**: Apply `const` wherever feasible.
5. **Centralized Tokens**: `AppColors`, `AppTypography`, `AppIcons`, `AppDimensions`.
6. **Zero-Knowledge Security**: PAN / CVV only in `flutter_secure_storage` with biometric unlock.
