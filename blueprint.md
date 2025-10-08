# Project Blueprint: Lava Ring

## 1. Overview

A Flutter application for tracking the daily wear time of a thermal ring. The core feature is a timer that runs in the background, logging wear sessions. The application supports user authentication via Google, stores data in Firebase Firestore, and provides local notifications. The goal is to wear the ring for 15 hours within a daily tracking window that resets at 8:00 PM (20:00) local time. The application is in French.

## 2. Style, Design, and Features

*   **Authentication:**
    *   Users sign in using their Google account via `firebase_auth` and `google_sign_in`.
    *   The user's login state is managed, and their `userId` is passed to the background service for data association.

*   **UI/UX:**
    *   Clean, modern interface using Material Design 3.
    *   The main screen features a large circular progress indicator showing progress towards the 15-hour goal.
    *   A digital timer displays the total time worn for the current day.
    *   Control buttons ("Démarrer," "Pause") manage the timer.

*   **Core Logic & State Management:**
    *   `provider` is used for state management, with `TimerProvider` handling the UI state.
    *   `flutter_background_service` runs a persistent foreground service to ensure the timer continues running even when the app is in the background.

*   **Daily Tracking Cycle (20:00 - 19:59):**
    *   **Automatic Daily Reset:** At 8:00 PM local time, the service automatically finalizes the current day's log, saves it to Firestore, and resets the timer and total wear time to zero for the new day.
    *   **Automatic Session Logging:** Each "Démarrer" and "Pause" action creates a distinct session `{start, end}` which is saved.
    *   **State Persistence:** The current session's start time, total daily seconds, and running state are persisted in `SharedPreferences` to survive app restarts or crashes.

*   **Firebase Integration:**
    *   **Firestore Data Structure:** Wear data is stored in a structured way to support historical views (like a future calendar view).
        *   **Path:** `users/{userId}/daily_logs/{YYYY-MM-DD}`
        *   **Schema:**
            ```json
            {
              "date": "2025-10-08",
              "total_seconds": 54000, // 15h
              "status": "vert", // vert, orange, rouge
              "sessions": [
                { "start": timestamp, "end": timestamp },
                ...
              ],
              "last_update": timestamp
            }
            ```
    *   **Automatic Status Calculation:** The `status` field is automatically calculated based on the `total_seconds` when the data is saved.
        *   `>= 15 hours`: **vert**
        *   `14 to < 15 hours`: **orange**
        *   `< 14 hours`: **rouge**

*   **Notifications:**
    *   A persistent foreground notification shows the timer's status ("Actif" or "En pause") and the remaining time to reach the goal.
    *   A notification is triggered once the daily 15-hour goal is achieved.
    *   A notification is sent when a daily log is finalized at 8:00 PM.

## 3. Current Plan: Implemented Features

1.  **Dependencies Added:** `intl` for date formatting.
2.  **Firestore Service Updated:** `FirestoreService` now includes models (`DailyLog`, `Session`) and methods to save data according to the new structured schema.
3.  **Background Service Rewritten:**
    *   The `onStart` function in `background_service.dart` contains the new core logic.
    *   Manages the daily cycle with an automatic reset at 20:00.
    *   Handles session creation on `pauseTimer`.
    *   Persists state locally using `SharedPreferences` to handle restarts.
    *   Saves final daily logs and incremental session data to Firestore.
    *   Checks for day changes on every action and periodically.
4.  **Providers & UI Adapted:**
    *   `TimerProvider` now acts as a simple bridge, invoking actions on the background service and listening for UI updates.
    *   `main.dart` passes the `userId` to the background service upon successful login, enabling data to be saved to the correct user document.

