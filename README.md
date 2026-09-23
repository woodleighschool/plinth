# Plinth

[![Release](https://img.shields.io/github/v/release/woodleighschool/plinth?display_name=tag&sort=semver)](https://github.com/woodleighschool/plinth/releases/latest)
[![CI](https://github.com/woodleighschool/plinth/actions/workflows/ci.yaml/badge.svg?branch=main)](https://github.com/woodleighschool/plinth/actions/workflows/ci.yaml)
![macOS 27+](https://img.shields.io/badge/macOS-27%2B-000000?logo=apple&logoColor=white)
[![License](https://img.shields.io/github/license/woodleighschool/plinth)](https://github.com/woodleighschool/plinth/blob/main/LICENSE)

Plinth is a browser for Apple silicon Macs running macOS 27 or later, inside Automatic Assessment Configuration. Managed configuration chooses the site, browser limits, background network access, display schedule, and whether the app is active.

## 🚀 Usage

Download the `.pkg` from the [latest release](https://github.com/woodleighschool/plinth/releases/latest). It installs `Plinth.app` in `/Applications` and a LaunchAgent in `/Library/LaunchAgents`. The agent starts Plinth when a user signs in and restarts it after a failure. Installing an update restarts Plinth for the active user.

## ⚙️ Configuration

The `au.edu.vic.woodleigh.Plinth` defaults domain supports:

| Key                      | Type                  | Behaviour                                                                     |
| ------------------------ | --------------------- | ----------------------------------------------------------------------------- |
| `Enabled`                | Boolean               | Enters assessment mode only when true.                                        |
| `StartURL`               | String                | Required absolute HTTPS URL.                                                  |
| `AllowedHosts`           | Array of strings      | Optional exact host and subdomain allowlist; defaults to the `StartURL` host. |
| `IdleResetSeconds`       | Integer               | Recreates the browser after inactivity; zero disables reset.                  |
| `EphemeralSession`       | Boolean               | Uses a non-persistent WebKit data store; defaults to true.                    |
| `NetworkParticipants`    | Array of dictionaries | Additional AAC participants allowed to use the network; defaults to empty.    |
| `DisplayScheduleEnabled` | Boolean               | Lets the app manage display sleep; defaults to false.                         |
| `DisplayOnTime`          | String                | Required `HH:mm` local time when display scheduling is enabled.               |
| `DisplayOffTime`         | String                | Required `HH:mm` local time when display scheduling is enabled.               |
| `DisplayDays`            | Array of strings      | Optional title-case weekday names for interval starts; defaults to weekdays.  |
| `EscapeCode`             | String                | Enables administrator exit with Control-Option-Command-E when non-empty.      |

Display intervals include the on time and exclude the off time. An overnight interval belongs to the day on which it starts. During scheduled hours, Plinth prevents idle system and display sleep. At the off time it releases both assertions and sleeps the display once; AAC and the browser remain active, and later display wakes follow normal macOS idle policy. Launching outside scheduled hours does not force the display to sleep.

### Background networking

AAC restricts background networking even while the display is asleep. `NetworkParticipants` grants network access to specific applications and executables; `AllowedHosts` only controls navigation in our browser. We do not add vendor or Apple service exceptions in code.

Each entry supports:

| Key                | Type    | Behaviour                                                                                 |
| ------------------ | ------- | ----------------------------------------------------------------------------------------- |
| `ExecutablePath`   | String  | Exact absolute path to a non-bundled executable. No wildcards, arguments or script paths. |
| `BundleIdentifier` | String  | Exact identifier of a bundled application. Use this or `ExecutablePath`, not both.        |
| `TeamIdentifier`   | String  | Optional ten-character signing team identifier. Omit for Apple platform binaries.         |
| `Required`         | Boolean | Prevents AAC startup if the participant is unavailable; defaults to false.                |

Signatures are always validated. AAC may omit an unavailable optional participant; `Required` checks availability, not successful communication. A bundle entry makes that application available in AAC, including its UI. Prefer headless participants for a kiosk, and identify their helpers separately where needed. Listing a participant neither installs nor starts it.

Changes apply to the running assessment without resetting the browser. Updates are serialized, and a rejected update displays an error while retaining the previous session. Correct the profile or use administrator exit. Malformed configuration is rejected before starting AAC.

[Config/Plinth.mobileconfig](Config/Plinth.mobileconfig) is our starting profile for the library catalogue, with APNs/MDM candidates, the Intune agent and daemon, and signed native Munki 7 updater and precache binaries. Replace the example escape code and check executable paths and signing teams against the installed packages. Vendor entries are optional; set `Required` where a missing agent should prevent kiosk startup. These identities are not proof that the complete management path works under AAC: verify a new profile arriving, agent check-ins and a Munki download, including after reconnecting the network.

Managed Software Center's GUI is not needed for Munki's background checks. To make it available during AAC, add `BundleIdentifier = com.googlecode.munki.ManagedSoftwareCenter` with its signing team. This deliberately permits another application in the session.

For an SSH trial, add separate `ExecutablePath` entries for `/usr/libexec/sshd-keygen-wrapper`, `/usr/sbin/sshd`, `/usr/libexec/sshd-session` and `/usr/libexec/sshd-auth`. Leave `TeamIdentifier` unset for these Apple binaries. Remote Login must already be enabled and authorized separately; the profile does not enable it. Test a fresh connection during AAC. This does not grant arbitrary commands, shells or download tools network access.

Apple documents [executable participants](https://developer.apple.com/documentation/automaticassessmentconfiguration/aeassessmentbinaryexecutable) and [AAC networking restrictions](https://developer.apple.com/documentation/automaticassessmentconfiguration/preparing-an-educational-assessment-app-for-distribution). Network extensions and content filters still need their own compatibility checks; allowing their parent app does not establish that they work.

## 🧑‍💻 Development

Open `Plinth.xcodeproj` in Xcode, or use the repository tasks:

```bash
mise run fmt-check
mise run lint
mise run test
mise run build
```

`mise run build` produces a local app build without installing it or loading the LaunchAgent.

A DEBUG build can pass `--unlocked` to exercise WebKit without entering assessment mode. That bypass is not compiled into Release builds.

## 📄 License

Licensed under the [Apache License 2.0](LICENSE).
