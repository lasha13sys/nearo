# Nearo Project Documentation

## 1. Project Summary
Nearo is a proximity-based social networking application designed to facilitate real-time connections between people sharing the same physical location. Unlike traditional social media platforms that focus on global connections, Nearo emphasizes the "here and now," helping users discover and interact with others in venues such as lounges, clubs, and bars. The app leverages Wi-Fi BSSID hashing for privacy-preserving proximity detection, ensuring that interactions are grounded in shared real-world experiences.

## 2. Project Goal
The primary goal of Nearo is to bridge the gap between digital interaction and real-world social presence.
- **Main Goal:** To create a safe, seamless, and engaging platform for spontaneous social discovery at venues.
- **Sub-goals:**
  - Implement a privacy-first proximity detection system.
  - Provide real-time communication tools for matched users.
  - Establish a robust safety framework for adult-oriented social spaces.
- **Expected Outcome:** A fully functional Flutter application supported by a scalable Firebase backend, ready for deployment in social environments.

## 3. Problem Description
In modern social settings, people often find it challenging to initiate conversations with strangers, despite being in the same room. Physical proximity does not always lead to social connection due to social anxiety, lack of context, or missing "ice-breakers." Existing social apps often focus on distant matches or swipe-heavy mechanics that don't translate well to immediate, local surroundings. Nearo solves this by providing a digital layer to physical venues, making it easier to see who is around and express interest respectfully.

## 4. Target Audience
Nearo is intended for:
- **Social Explorers:** Adults (18+) who enjoy visiting nightlife venues and are open to meeting new people.
- **Venue Owners:** Businesses looking to increase engagement and provide a unique digital experience to their patrons.
- **Community Builders:** People interested in local, event-based social networking.

## 5. Core Features
- **Proximity Discovery:** Detects other users in the same venue using Wi-Fi BSSID hashing (without needing constant GPS tracking).
- **Signal System:** Users can send "Signals" to others nearby. A signal is a low-pressure way to show interest.
- **Match System:** When interest is mutual (either through reciprocal signals or an accepted signal), a Match is created.
- **Real-time Chat:** Once matched, users can communicate through a secure, real-time messaging system.
- **Venue Insights:** Displays venue statistics such as "Social Energy," capacity levels, and average age to help users decide where to go.
- **Safety & Moderation:** Includes an 18+ age gate, a reporting system for inappropriate behavior, and server-side validation of interactions.

## 6. Technical Description
- **Frontend:** Built with Flutter for cross-platform compatibility (Android, iOS, Web).
- **State Management:** Riverpod for robust, testable, and scalable state handling.
- **Backend:** Firebase suite:
  - **Firebase Auth:** Secure email/password authentication.
  - **Cloud Firestore:** NoSQL database for real-time data synchronization.
  - **Cloud Functions:** Server-side logic for match creation, signal expiration, and notifications.
  - **Firebase Cloud Messaging (FCM):** Push notifications for matches and messages.
  - **Firebase Storage:** (Optional) for profile media.
- **Proximity Logic:** Uses `network_info_plus` to retrieve BSSID, which is then hashed with a salt for privacy before being compared in Firestore.

## 7. Project Architecture
The project follows a modular Layered Architecture:
- **App Layer (`lib/app`):** Entry point and global configuration.
- **Presentation Layer (`lib/presentation`):** UI components and screens (Auth, Home, Nearby, Matches, Chat, Profile).
- **Domain Layer (`lib/domain`):** Pure business logic, including entities (User, Venue, Signal, Match, Message).
- **Data Layer (`lib/data`):** Implementation of repositories (Auth, User, Signal, Venue, Chat) interacting with Firebase.
- **Core Layer (`lib/core`):** Shared utilities, services (Proximity, Notification), themes, and constants.

## 8. User Journey
1. **Onboarding:** User signs up, verifies they are 18+, and accepts safety guidelines.
2. **Venue Entry:** Upon entering a venue, the user "checks in" (manually or automatically via Wi-Fi refresh).
3. **Discovery:** User browses the "Nearby" screen to see other active users in the same venue.
4. **Interaction:** User sends a Signal to someone they find interesting.
5. **Connection:** If the other user accepts or sends a signal back, a Match is formed.
6. **Communication:** The Match opens a chat channel where users can coordinate a real-world meeting.
7. **Profile Management:** User can toggle visibility or update their "Mood Status" at any time.

## 9. Data Structure / Required Files
### Firestore Collections
- `users`: Profile data, visibility status, FCM tokens, and venue hashes.
- `venues`: Venue details, Wi-Fi BSSID lists, and live statistics.
- `signals`: Record of sent interactions and their statuses (pending, accepted, expired).
- `matches`: Active connections between users.
- `conversations`: Chat metadata.
- `messages`: Individual chat entries (sub-collection of conversations).
- `reports`: User-submitted safety reports.

### Key Files
- `lib/main.dart`: App bootstrap.
- `lib/firebase_options.dart`: Firebase configuration (platform-specific).
- `firebase/firestore.rules`: Security rules for data access.
- `firebase/functions/index.js`: Backend logic for match automation.

## 10. Security and Risks
- **Privacy:** BSSIDs are never stored in plain text; only salted SHA-256 hashes are used.
- **Data Security:** Firestore rules ensure users can only read their own signals/matches and cannot modify critical fields like `isBanned`.
- **Physical Safety:** Users are encouraged to meet in public areas of the venue. A "Report" feature is prominently available.
- **Technical Risks:** Dependency on Wi-Fi availability for proximity. Fallback to location-based services may be required in some environments.

## 11. Usage or Setup Instructions
1.  **Environment:** Install Flutter SDK and Dart.
2.  **Dependencies:** Run `flutter pub get` in the `nearo_fixed_clean` directory.
3.  **Firebase Configuration:**
    - Create a Firebase project.
    - Run `flutterfire configure` to generate `lib/firebase_options.dart`.
    - Deploy Firestore rules: `firebase deploy --only firestore:rules`.
    - Deploy Cloud Functions: `cd firebase/functions && npm install && cd .. && firebase deploy --only functions`.
4.  **Run the App:**
    - For Web: `flutter run -d chrome`
    - For Mobile: `flutter run -d android` or `flutter run -d ios`

## 12. Future Development Plan
- **Advanced Proximity:** Integrate Bluetooth Low Energy (BLE) for even more precise indoor positioning.
- **Enhanced Venue Features:** Real-time venue heatmaps and event integrations.
- **Monetization:** Premium "Super Signals" or venue-sponsored promotions.
- **AI Integration:** Smart ice-breakers based on shared interests or venue atmosphere.
- **Expanded Safety:** Integration with third-party identity verification services.

## 13. Final Conclusion
Nearo is a technically sound and strategically focused application that addresses a real-world social need. By combining Flutter's cross-platform efficiency with Firebase's real-time capabilities and a privacy-conscious proximity model, it provides a solid foundation for a next-generation social networking platform. The project is well-documented, follows industry-standard architectural patterns, and is ready for further development or immediate deployment.
