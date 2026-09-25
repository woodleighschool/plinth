# Changelog

## [0.1.11](https://github.com/woodleighschool/plinth/compare/0.1.10...0.1.11) (2026-09-25)


### Features

* **npm:** update dependency oxfmt (0.68.0 → 0.70.0) ([#18](https://github.com/woodleighschool/plinth/issues/18)) ([de07d71](https://github.com/woodleighschool/plinth/commit/de07d71df59c809906dcb4dd3107810eec9d69f3))


### Miscellaneous Chores

* **mise:** update tool oxfmt (0.68.0 → 0.70.0) ([#19](https://github.com/woodleighschool/plinth/issues/19)) ([9d7caa0](https://github.com/woodleighschool/plinth/commit/9d7caa09a79c4f6cdf97f8f09c4f737642fd8358))

## [0.1.10](https://github.com/woodleighschool/plinth/compare/0.1.9...0.1.10) (2026-09-23)


### Features

* allow managed network participants during assessment ([0cf8c62](https://github.com/woodleighschool/plinth/commit/0cf8c6261217a8e478f456022175205bd70a4d3f))


### Bug Fixes

* actionlint xcode 27 runner allow ([96d0260](https://github.com/woodleighschool/plinth/commit/96d02601c2707f9917d391dd52d37571102edc6e))
* limit browser context menu ([ad0b037](https://github.com/woodleighschool/plinth/commit/ad0b037ca5863e178dfd6018c8f173119e4629c3))
* present kiosk before starting assessment ([6163edb](https://github.com/woodleighschool/plinth/commit/6163edbca8dc6fe2417ba4576e504b4b19692fa2))


### Continuous Integration

* avoid redundant release metadata checks ([431631d](https://github.com/woodleighschool/plinth/commit/431631d29ccd7cf866c1a2dc4f9f67ee9d4e7292))


### Miscellaneous Chores

* fresh mise lock ([163c385](https://github.com/woodleighschool/plinth/commit/163c385b1142bd79ebe22b13ed5bd1ad3477eebd))
* remove redundant workflow lint task ([707d819](https://github.com/woodleighschool/plinth/commit/707d8197df7d2bb41a3ee36df4cd2f93f0f3fdab))

## [0.1.9](https://github.com/woodleighschool/plinth/compare/0.1.8...0.1.9) (2026-09-23)


### Continuous Integration

* **github-action:** update action jdx/mise-action (v4.2.5 → v4.3.0) ([#11](https://github.com/woodleighschool/plinth/issues/11)) ([2de1db9](https://github.com/woodleighschool/plinth/commit/2de1db9991598acaf638650fae07cd76bb26365b))


### Miscellaneous Chores

* **github-action:** Update action home-operations/.github/actions/workflow-lint (v1.0.3 → v1.0.4) ([#16](https://github.com/woodleighschool/plinth/issues/16)) ([d03561e](https://github.com/woodleighschool/plinth/commit/d03561e9edac568629ea705131a0a44b9b607a1f))
* **github-action:** update action ubuntu (24.04 → 26.04) ([#15](https://github.com/woodleighschool/plinth/issues/15)) ([3d6042c](https://github.com/woodleighschool/plinth/commit/3d6042c9e39686faffb5034b0f4208e922d8de2c))
* **mise:** update mise tools ([#14](https://github.com/woodleighschool/plinth/issues/14)) ([cd240c2](https://github.com/woodleighschool/plinth/commit/cd240c2f17fd45622cf087418486edc1595f2043))
* **mise:** update tool lefthook (2.1.11 → 2.1.12) ([#13](https://github.com/woodleighschool/plinth/issues/13)) ([76aaf3c](https://github.com/woodleighschool/plinth/commit/76aaf3c5528922fb80d938b8f439ef18b0cd0daa))

## [0.1.8](https://github.com/woodleighschool/plinth/compare/0.1.7...0.1.8) (2026-08-27)


### Bug Fixes

* decouple kiosk from display schedule ([5582dcd](https://github.com/woodleighschool/plinth/commit/5582dcd25ab2eda7091f105df9ed2a24744f7590))


### Documentation

* clarify usage and releases ([abd870a](https://github.com/woodleighschool/plinth/commit/abd870a1d088c5440d6f394f1bd570063a14e3d3))

## [0.1.7](https://github.com/woodleighschool/plinth/compare/0.1.6...0.1.7) (2026-08-27)


### Bug Fixes

* **kiosk:** make blocked navigation dismissible ([ed7f132](https://github.com/woodleighschool/plinth/commit/ed7f132243740adfd19aa66bf12e1fc030934df3))


### Code Refactoring

* observe managed configuration changes ([cd84571](https://github.com/woodleighschool/plinth/commit/cd84571fefab399b3d74eb27333b805e925aa38c))

## [0.1.6](https://github.com/woodleighschool/plinth/compare/0.1.5...0.1.6) (2026-08-26)


### Miscellaneous Chores

* really fullscreen, minus menubar ([b5c4cde](https://github.com/woodleighschool/plinth/commit/b5c4cde5a45ae10496a22f8a1876003b0e31dfa7))

## [0.1.5](https://github.com/woodleighschool/plinth/compare/0.1.4...0.1.5) (2026-08-26)


### Bug Fixes

* correct focus ([72e7f42](https://github.com/woodleighschool/plinth/commit/72e7f420a93a1a5b2d9b4c338455c629dd2b9e2c))
* **kiosk:** handle blocked navigation and resize ([44a12cc](https://github.com/woodleighschool/plinth/commit/44a12cc8ab1108b7450f2be399dc3c5ec9cda443))
* **kiosk:** use native administrator exit alert ([93b204c](https://github.com/woodleighschool/plinth/commit/93b204c1c0cdf7043c4f4e5e939bf4420a55cf1d))

## [0.1.4](https://github.com/woodleighschool/plinth/compare/0.1.3...0.1.4) (2026-08-26)


### Features

* add administrator escape hatch ([9ee5166](https://github.com/woodleighschool/plinth/commit/9ee5166afad61c55fa925a0f1967f5a94d52bb57))
* add managed display scheduling ([9aa38f9](https://github.com/woodleighschool/plinth/commit/9aa38f97e5f42f3997169e0278b9a8db99d768d5))

## [0.1.3](https://github.com/woodleighschool/plinth/compare/0.1.2...0.1.3) (2026-08-26)


### Bug Fixes

* **ci:** lint package root plists ([89dc2ed](https://github.com/woodleighschool/plinth/commit/89dc2ed4814c89a576f7d83f381d2530cdd8bb25))


### Continuous Integration

* **release:** use shared package action ([0696498](https://github.com/woodleighschool/plinth/commit/0696498f63e9273b092cba9da00f50dd81fb36f1))


### Miscellaneous Chores

* **mise:** update tool oxfmt (0.64.0 → 0.65.0) ([#2](https://github.com/woodleighschool/plinth/issues/2)) ([4435e5d](https://github.com/woodleighschool/plinth/commit/4435e5de83746d631491b936e4170db47218a8d4))

## [0.1.2](https://github.com/woodleighschool/plinth/compare/0.1.1...0.1.2) (2026-08-26)


### Miscellaneous Chores

* useless verification ([980ea18](https://github.com/woodleighschool/plinth/commit/980ea1877697b77eb03992843df07d088ea68396))

## [0.1.1](https://github.com/woodleighschool/plinth/compare/0.1.0...0.1.1) (2026-08-25)


### Bug Fixes

* **xcode:** xcode 26.3 min compatability ([92106fe](https://github.com/woodleighschool/plinth/commit/92106fe485d1485bab4aba7a2a2a133d62d2a93e))


### Miscellaneous Chores

* initial commit ([b48ec0e](https://github.com/woodleighschool/plinth/commit/b48ec0edc6dc8e2e797a082b69c9aa0ac8fdbc4e))
* real icon ([8588ae8](https://github.com/woodleighschool/plinth/commit/8588ae8537a22cbba9481fca01621ee343938836))
* xcode bootstrap ([46c2916](https://github.com/woodleighschool/plinth/commit/46c291657427d08a96094cf92675d6f81824a9ba))

## Changelog
