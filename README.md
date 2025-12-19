# 🧩 Jigsaw Party - Multiplayer Puzzle Game

A real-time multiplayer jigsaw puzzle game built with **Flutter** and **Firebase**. Users can create private rooms, share access codes with friends, and solve puzzles together on separate devices instantly.

## 📱 Features

* **Real-Time Multiplayer:** Move a piece on one phone, and it moves on all other phones in the room instantly.
* **Scrollable Piece Drawer:** Keeps the board clean! Unplaced pieces sit in a wooden tray at the bottom until you drag them onto the board.
* **Lobby System:**
    * **Create Room:** Generates a unique 4-letter room code (e.g., `ABCD`).
    * **Join Room:** Friends can enter the code to join the same board.
* **Smart Drag & Drop:** Pieces are tracked globally. If a player drops a piece, it updates for everyone.
* **Cross-Device Sync:** Powered by Firebase Realtime Database for millisecond-latency updates.

## 🛠️ Tech Stack

* **Frontend:** Flutter (Dart)
* **Backend:** Firebase Realtime Database
* **Architecture:** Android (Universal APK support)

## 🚀 Getting Started

Follow these instructions to run the project on your local machine.

### Prerequisites
* [Flutter SDK](https://flutter.dev/docs/get-started/install) installed.
* Android Studio (with Android SDK 34).
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

3.  **Firebase Setup:**
    * Create a project in [Firebase Console](https://console.firebase.google.com/).
    * Download `google-services.json` and place it in `android/app/`.
    * **Enable Realtime Database** and set rules to `true`.

4.  **Run the App:**
    ```bash
    flutter run
    ```

## 🎮 How to Play

1.  **Host:** Tap "CREATE NEW ROOM". A code (e.g., `XJTP`) will appear.
2.  **Guest:** Enter `XJTP` and tap "JOIN ROOM".
3.  **Play:** Drag pieces from the bottom **Drawer** onto the main board.
4.  **Collaborate:** Watch as your friend moves pieces in real-time!

## 🔮 Future Improvements
* Add "Snapping" logic so pieces lock into the correct position.
* Add different puzzle images.
* Add a "Win" screen when all pieces are placed.
