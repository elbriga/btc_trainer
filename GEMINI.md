# Project Overview

This is a Flutter application that allows users to simulate Bitcoin trading. The app fetches real-time Bitcoin prices and allows users to buy and sell Bitcoin using a simulated wallet.

I'm using gemini-cli to implement features, do not ask for running flutter analyze or any git related commands. I'm with the project open on vscode seeing all changes you make

## Main Technologies

- **Frontend:** Flutter
- **State Management:** Provider
- **HTTP Client:** http
- **Charting:** fl_chart
- **Background Service:** flutter_background_service
- **Database:** sqflite

## Architecture

The application follows a simple MVVM (Model-View-ViewModel) architecture:

- **Models:** `PriceData`, `TransactionData`
- **Views:** `HomeScreen`, `BuySellDialog`
- **ViewModels:** `WalletViewModel`

The app uses a background service to fetch the Bitcoin price every minute and stores it in a local SQLite database. The `WalletViewModel` listens for updates from the background service and updates the UI accordingly.

## Building and Running

To build and run the project, use the following commands:

```bash
flutter pub get
flutter run
```

## Development Conventions

- The project uses the recommended lints from the `flutter_lints` package.
- The code is well-structured and follows the standard Flutter project layout.
- State management is handled by the `provider` package.
- The app uses a local SQLite database to persist data.
