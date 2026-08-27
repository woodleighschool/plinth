# Plinth

[![Release](https://img.shields.io/github/v/release/woodleighschool/plinth?display_name=tag&sort=semver)](https://github.com/woodleighschool/plinth/releases/latest)
[![CI](https://github.com/woodleighschool/plinth/actions/workflows/ci.yaml/badge.svg?branch=main)](https://github.com/woodleighschool/plinth/actions/workflows/ci.yaml)
![macOS 26+](https://img.shields.io/badge/macOS-26%2B-000000?logo=apple&logoColor=white)
[![License](https://img.shields.io/github/license/woodleighschool/plinth)](https://github.com/woodleighschool/plinth/blob/main/LICENSE)

Plinth is a browser for macOS 26 or later that runs inside Automatic Assessment Configuration. Managed configuration chooses the site, browser limits, display schedule, and whether the app is active.

## 🚀 Usage

Download the `.pkg` from the [latest release](https://github.com/woodleighschool/plinth/releases/latest). It installs `Plinth.app` in `/Applications` and a LaunchAgent in `/Library/LaunchAgents`. The agent starts Plinth when a user signs in and restarts it after a failure. Installing an update restarts Plinth for the active user.

## ⚙️ Configuration

The `au.edu.vic.woodleigh.Plinth` defaults domain supports:

| Key                      | Type             | Behaviour                                                                     |
| ------------------------ | ---------------- | ----------------------------------------------------------------------------- |
| `Enabled`                | Boolean          | Enters assessment mode only when true.                                        |
| `StartURL`               | String           | Required absolute HTTPS URL.                                                  |
| `AllowedHosts`           | Array of strings | Optional exact host and subdomain allowlist; defaults to the `StartURL` host. |
| `IdleResetSeconds`       | Integer          | Recreates the browser after inactivity; zero disables reset.                  |
| `EphemeralSession`       | Boolean          | Uses a non-persistent WebKit data store; defaults to true.                    |
| `DisplayScheduleEnabled` | Boolean          | Lets the app manage display sleep; defaults to false.                         |
| `DisplayOnTime`          | String           | Required `HH:mm` local time when display scheduling is enabled.               |
| `DisplayOffTime`         | String           | Required `HH:mm` local time when display scheduling is enabled.               |
| `DisplayDays`            | Array of strings | Optional title-case weekday names for interval starts; defaults to weekdays.  |
| `EscapeCode`             | String           | Enables administrator exit with Control-Option-Command-E when non-empty.      |

Display intervals include the on time and exclude the off time. An overnight interval belongs to the day on which it starts. During scheduled hours, Plinth prevents idle system and display sleep. At the off time it releases both assertions and sleeps the display once; AAC and the browser remain active, and later display wakes follow normal macOS idle policy. Launching outside scheduled hours does not force the display to sleep.

## 🧑‍💻 Development

Open `Plinth.xcodeproj` in Xcode, or use the repository tasks:

```bash
mise run fmt-check
mise run lint
mise run test
mise run build
mise run workflow-lint
```

`mise run build` produces a local app build without installing it or loading the LaunchAgent.

A DEBUG build can pass `--unlocked` to exercise WebKit without entering assessment mode. That bypass is not compiled into Release builds.

## 📄 License

Licensed under the [Apache License 2.0](LICENSE).
