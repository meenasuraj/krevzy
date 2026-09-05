# GAPSHAP Phase 2 — Data Flow

LOGIN
User -> Authentication -> Session -> Authorized account data

NOTES
User -> Notes UI -> Notes service -> Cloud database
                              -> ownerId authorization

VAULT
User -> Upload -> Validation/security scan -> Private cloud storage
                                            -> safe: owner access
                                            -> suspicious: quarantine
                                            -> pending: not trusted

RECOVERY
Logout/uninstall does not erase server-side account data.
Reinstall -> login -> authorized cloud data becomes available again.

Backend authorization must enforce ownership; hiding buttons in the mobile UI is not security.
