# plinth

Plinth runs web-based assessments and kiosk sessions on managed Macs. It stays in maintenance mode until managed configuration enables it, then loads configured sites in `WKWebView`. Automatic Assessment Configuration blocks other apps and system features until the session ends.

## ⚙️ Configuration

The `au.edu.vic.woodleigh.Plinth` defaults domain supports:

| Key                | Type             | Behaviour                                                                     |
| ------------------ | ---------------- | ----------------------------------------------------------------------------- |
| `Enabled`          | Boolean          | Enters assessment mode only when true.                                        |
| `StartURL`         | String           | Required absolute HTTPS URL.                                                  |
| `AllowedHosts`     | Array of strings | Optional exact host and subdomain allowlist; defaults to the `StartURL` host. |
| `IdleResetSeconds` | Integer          | Recreates the browser after inactivity; zero disables reset.                  |
| `EphemeralSession` | Boolean          | Uses a non-persistent WebKit data store; defaults to true.                    |

## 🧑‍💻 Development

Open `Plinth.xcodeproj` in Xcode, or use the repository tasks:

```bash
mise run fmt-check
mise run lint
mise run test
mise run build
mise run workflow-lint
```

A DEBUG build can pass `--unlocked` to exercise WebKit without entering assessment mode. That bypass is not compiled into Release builds.

## 📄 License

Licensed under the [Apache License 2.0](LICENSE).
