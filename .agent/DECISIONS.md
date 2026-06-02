# Decisions Log

## D001: Initial Architecture and Tooling (S0)
- **Decision:** Use Flutter stable (3.41), Riverpod 2 (with codegen), Freezed, GoRouter, and Firebase for the entire stack.
- **Rationale:** Ensures type safety, maintainable state management, offline-first capabilities, and robust routing.
- **Alternatives considered:** None (locked decision by user).

## D002: L10n Strategy (S0)
- **Decision:** Use standard Flutter `flutter_localizations` with ARB files and a custom extension `context.l10n`.
- **Rationale:** Standard, scalable, statically typed, and recommended approach for localization in Flutter.

## D003: Version Conflicts Resolution (S0)
- **Decision:** Downgraded Riverpod dependencies to v2.x and relaxed json_annotation versions to avoid `custom_lint` and `riverpod_lint` clashes.
- **Rationale:** The generated boilerplate uses Riverpod 2, and Riverpod 3 is still in dev and causing linting package incompatibility.
