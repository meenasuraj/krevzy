# GAPSHAP Phase 2 — File Locations

Project root: GAPSHAP/

Create/copy these exact paths:

lib/core/config/app_config.dart
lib/core/navigation/app_routes.dart
lib/core/services/auth_service.dart
lib/core/services/notes_service.dart
lib/core/services/vault_service.dart
lib/features/auth/models/app_user.dart
lib/features/auth/presentation/welcome_page.dart
lib/features/notes/models/note.dart
lib/features/vault/models/media_item.dart

The service files are contracts for now; no database credentials are included.

Laptop later:
1. Open the GAPSHAP Flutter project.
2. Create the folders above.
3. Copy each file to its matching path.
4. Run `flutter analyze`.
5. Run the app and test navigation.
6. Connect the selected secure cloud backend afterward.

Never place passwords, payment secrets, service-account files, or private API keys in source code.
