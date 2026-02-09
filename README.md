# Task Management App

A clean, minimal task management application built with Flutter featuring voice input, categories, and smart filtering.

## Features

- **CRUD Operations** — Create, read, update, and delete tasks with titles, descriptions, priorities, and due dates
- **Categories** — Organize tasks into color-coded categories with custom icons
- **Voice Input** — Add tasks using natural language via speech-to-text (e.g. "Buy groceries tomorrow high priority for Personal")
- **Smart Filtering** — View tasks by Today, Upcoming, Overdue, or All
- **Sorting** — Sort by priority, due date, title, or creation date
- **Search** — Full-text search across task titles and descriptions
- **Statistics** — Dashboard summary showing total, completed today, overdue counts, and weekly completion rate
- **Swipe Actions** — Swipe right to complete, left to delete with undo support

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter 3.32 / Dart 3.8 |
| State Management | Riverpod 2.6 |
| Database | Drift 2.22 (SQLite) |
| Navigation | GoRouter 14.8 |
| Voice Input | speech_to_text 7.0 |
| Fonts | Google Fonts |

## Project Structure

```
lib/
├── main.dart                  # App entry point
├── app.dart                   # MaterialApp + GoRouter config
├── core/
│   ├── constants/             # App-wide string constants
│   ├── services/              # SpeechService, VoiceTaskParser
│   ├── theme/                 # Colors, shadows, theme data
│   └── utils/                 # Date, icon, and feedback utilities
├── data/
│   ├── database/              # Drift AppDatabase + migrations
│   ├── daos/                  # TaskDao, CategoryDao (data access)
│   └── tables/                # Drift table definitions
├── models/
│   └── enums/                 # Priority, TaskFilter, TaskSort
├── providers/                 # Riverpod providers + notifiers
├── screens/                   # Home, Task, Category screens
└── widgets/                   # Shared UI components
```

## Getting Started

### Prerequisites

- Flutter SDK 3.8+
- Dart SDK 3.8+

### Installation

```bash
flutter pub get
```

### Run

```bash
flutter run
```

### Run Tests

```bash
flutter test
```

## Architecture

The app follows a layered architecture:

1. **Data Layer** — Drift tables and DAOs handle all SQLite operations
2. **Provider Layer** — Riverpod providers expose reactive streams from DAOs and manage mutations via StateNotifiers
3. **UI Layer** — Screens and widgets consume providers and render the interface

Data flows unidirectionally: **Database → DAOs → Providers → UI**.

## Testing

The test suite covers:

- **Enum tests** — Priority, TaskFilter, TaskSort value correctness
- **Utility tests** — Date formatting, overdue/upcoming checks, icon resolution
- **DAO tests** — Full CRUD, filtered queries, search, and stats using in-memory databases
- **Voice parser tests** — 46 tests for natural language date, time, priority, and category extraction
