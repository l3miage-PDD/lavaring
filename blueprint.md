# Project Blueprint: Lava Ring

## 1. Overview
A Flutter application for tracking the daily wear time of a thermal ring. Users will log in to their accounts to start, pause, and resume a timer. The goal is 15 hours of wear time per flexible 24-hour cycle. Data will be stored in Firebase Firestore, and users will be notified upon reaching their goal. The application will be in French.

## 2. Style, Design, and Features
*   **Authentication:**
    *   A login screen will allow users to sign in using their Google account.
    *   The app will manage the user's login state, automatically redirecting to the home screen if already logged in.
*   **UI/UX:**
    *   Clean, modern interface using Material Design 3.
    *   The main screen will feature a large circular progress indicator for the 15-hour goal.
    *   A digital timer will display the total time worn.
    *   Control buttons ("Start," "Pause," "Resume") will be clearly visible.
*   **Core Logic & State Management:**
    *   `provider` will manage the application's state, including authentication status and the timer's state.
*   **Firebase Integration:**
    *   **Authentication:** Firebase Authentication will handle user login and account management via Google Sign-In.
    *   **Firestore:** Firestore will store wear logs, with each user having their own collection of data.
*   **Notifications:**
    *   `flutter_local_notifications` will send a notification when the 15-hour goal is reached.

## 3. Current Plan: Step-by-Step Implementation
1.  **Update `blueprint.md`:** Reflect the change from email/password to Google Sign-In and the name change to "Lava Ring", as well as the localization to French.
2.  **Add Dependencies:** Add `google_sign_in`.
3.  **Configure Firebase & Google Sign-In:** Guide the user on necessary setup steps.
4.  **Implement Authentication Flow:** Update `AuthService` and the `LoginScreen` to use Google Sign-In.
5.  **Implement Core App:** Build the main timer screen and related services.
