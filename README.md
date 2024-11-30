# Alethia 📚

<div align="center">

![Alethia Logo](./Assets//icon.png)

_A modern, SwiftUI-based Manga Reader with API-driven architecture_

[![GitHub license](https://img.shields.io/github/license/alethiaorg/alethia.svg)](https://github.com/alethiaorg/alethia/blob/main/LICENSE)
[![GitHub release](https://img.shields.io/github/release/alethiaorg/alethia.svg)](https://GitHub.com/alethiaorg/alethia/releases/)
[![GitHub stars](https://img.shields.io/github/stars/alethiaorg/alethia.svg)](https://GitHub.com/alethiaorg/alethia/stargazers/)

[Overview](#overview) • [Features](#features) • [Getting Started](#getting-started) • [Usage](#usage) • [Roadmap](#roadmap) • [Contributing](#contributing) • [License](#license)

</div>

## Overview

Alethia is a cutting-edge Manga Reader built with SwiftUI, leveraging the power of APIs to provide a seamless and extensible reading experience. Unlike traditional extension-based systems, Alethia's API-driven architecture ensures easy integration of new sources and features.

## ✨ Features

- 🌐 **API-based system** API tailored ensures extensibility regardless of the language choice (TypeScript, C#, Rust, etc.)!
- 📱 **99% SwiftUI** implementation using bleeding-edge iOS 18 features
- 🔎 **Search Capabilities** Like every other reader
- 🔄 **Cross-source support** (access manga from multiple sources)
- 📚 **Collection-based grouping** for efficient library management
- 🧠 **Smart chapter sorting** with special chapter handling across different sources
- ⌛ **Historical tracking** with details down to the second on all reading sessions
- 💾 **Downloads** Fast and in .CBZ format for support with other cbz-based readers

## 🚀 Getting Started

### Prerequisites

- iOS 18.0+
- Xcode 15.0+
- Swift 5.9+

## Roadmap

| Feature                                                        | Description                                                                                                                                                                       | Status           | Version |
| -------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------- | ------- |
| ~~Base app with cross-source support + chapter smart sorting~~ | ~~Base app design including cross-source support and chapter smart sort requirements~~                                                                                            | ~~✅ Completed~~ | ~~1.0~~ |
| ~~Settings~~                                                   | ~~Set up settings (@AppStorage and @Storage) for app-wise controls and config~~                                                                                                   | ~~✅ Completed~~ | ~~1.1~~ |
| ~~Collection-based grouping~~                                  | ~~Allow manga to be grouped to collections in a many-to-many relationship with CRUD support displayable as tabs in library~~                                                      | ~~✅ Completed~~ | ~~1.2~~ |
| ~~Search on Global and Source-exclusive scopes~~               | ~~Ability to search for manga based on title which require API adjustments (to be expanded later)~~                                                                               | ~~✅ Completed~~ | ~~1.3~~ |
| ~~Chapter progression tracking and History Tab~~               | ~~Uplift Chapter View with select buttons on UI mark as read/not read above/below/in range, Basic history tab displaying recently read chapters~~                                 | ~~✅ Completed~~ | ~~1.4~~ |
| ~~Downloads per chapter~~ and bulk downloading                 | Chapter downloads packaged to .cbz files for potential future sync with offline systems like Komga + extend for any and all manga images to be stored locally/use local url-paths | 🚧 In Progress   | 1.5     |
| Batch-update, widget + background/cron update support          | Batch-update (global, collection) level scopes, widgets that show recently updated and background cron jobs via Automations in the Shortcuts app                                  | 🗓️ Planned       | 1.6     |
| Advanced search on source-exclusive scopes                     | Extend search with advanced search capabilities with filter/sort methods + tag-based auto-collection grouping                                                                     | 🗓️ Planned       | 1.7     |
| Tracking + Drop notification alerts                            | Tracking via AniList (for now) + richful alerts to all related content (https://github.com/omaralbeik/Drops)                                                                      | 🗓️ Planned       | 1.8     |
| Backup/Export + Migration from other readers                   | Backup/Export to JSON - migration targets (Tachiyomi/Mihon, Paperback, Aidoku, Suwatte)                                                                                           | 🗓️ Planned       | 1.9     |
| Alethia.moe + public release                                   | Alethia.moe as the main website to serve for docs, public release via public TestFlight beta                                                                                      | 🗓️ Planned       | 2.0     |
