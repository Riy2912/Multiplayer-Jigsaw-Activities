# 🧩 Jigsaw Party - Multiplayer Puzzle Game

A real-time multiplayer jigsaw puzzle game built with **Flutter** and **Firebase**. Users can create private rooms, share access codes with friends, and solve puzzles together on separate devices instantly.

## 📱 Features

* **Real-Time Multiplayer:** Move a piece on one phone, and it moves on all other phones in the room instantly.
* **Lobby System:**
    * **Create Room:** Generates a unique 4-letter room code (e.g., `ABCD`).
    * **Join Room:** Friends can enter the code to join the same board.
* **Drag & Drop Gameplay:** Smooth touch controls to pick up and place puzzle pieces.
* **Cross-Device Sync:** Powered by Firebase Realtime Database for millisecond-latency updates.
* **Custom App Icon:** Professional launcher icon generated for Android.

## 🛠️ Tech Stack

* **Frontend:** Flutter (Dart)
* **Backend:** Firebase Realtime Database
* **Architecture:** Android (Universal APK support)

## 🚀 Getting Started

Follow these instructions to run the project on your local machine.

### Prerequisites
* [Flutter SDK](https://flutter.dev/docs/get-started/install) installed.
* Android Studio (with Android SDK 34/UpsideDownCake).
* A Firebase Project.

### Installation

1.  **Clone the repository:**
    ```bash
    git clone [https://github.com/YourUsername/JigsawParty.git](https://github.com/YourUsername/JigsawParty.git)
    cd JigsawParty
    ```

2.  **Install Dependencies:**
    ```bash
    flutter pub get
    ```

3.  **Firebase Setup (Crucial):**
    * Create a project in the [Firebase Console](https://console.firebase.google.com/).
    * Add an Android App (package name: `com.example.jigsaw_multiplayer`).
    * Download the `google-services.json` file.
    * Place it in: `android/app/google-services.json`.
    * **Enable Realtime Database** in Firebase and set rules to `read: true, write: true` (for testing).

4.  **Run the App:**
    ```bash
    flutter run
    ```

## 📦 Building the APK

To generate a shareable APK file for Android phones:

1.  Clean the project:
    ```bash
    flutter clean
    flutter pub get
    ```
2.  Build the release version:
    ```bash
    flutter build apk --release --no-shrink
    ```
3.  Locate the file at:
    `build/app/outputs/flutter-apk/app-release.apk`

## 🎮 How to Play

1.  Open the app on two different devices.
2.  **Player 1:** Taps "CREATE NEW ROOM". A room code (e.g., `XJTP`) will appear at the top.
3.  **Player 2:** Enters `XJTP` in the text box and taps "JOIN ROOM".
4.  Both players can now drag pieces, and the board will stay in sync!
