# Android Application Design Document: SOSNow

### 1. Introduction

This document outlines the design for an Android version of the SOSNow application. The app will allow users to send emergency alerts via MQTT, display their location on a map, manage personal information, and select their preferred language. It will interact with the existing Python MQTT server.

### 2. Architecture

The application will follow the **MVVM (Model-View-ViewModel)** architectural pattern, leveraging Android Jetpack components for robust, testable, and maintainable code.

*   **Model:** Represents the data and business logic (e.g., `User`, `Alert`, `LocationData`). This layer will also handle data persistence and network operations.
*   **View:** The UI layer (Activities, Fragments, Composables) responsible for displaying data and capturing user input. It observes changes in the ViewModel.
*   **ViewModel:** Acts as an intermediary between the View and the Model. It exposes data streams to the View, handles UI logic, and delegates business logic to the Model. It survives configuration changes.

### 3. Technology Stack

*   **Language:** Kotlin
*   **UI Toolkit:** Jetpack Compose (recommended for modern Android development) or XML Layouts (if targeting older Android versions or specific UI requirements). This design assumes Jetpack Compose.
*   **MQTT Client:** Eclipse Paho MQTT Client for Android (or a similar robust MQTT library).
*   **Location Services:** Google Play Services Location API (`FusedLocationProviderClient`).
*   **Dependency Injection:** Hilt (recommended for managing dependencies).
*   **Data Persistence:** Jetpack DataStore (for user preferences like name, number, language) or Room (if more complex local data storage is needed).
*   **Networking (for server's IP geolocation):** Retrofit with Moshi/Gson converter (if the Android app needs to perform similar IP lookups as the Python server, though this is typically a server-side concern).
*   **Asynchronous Operations:** Kotlin Coroutines and Flow.

### 4. Core Components & Functionality

#### 4.1. MQTT Management

*   **`MqttManager` (Model/Repository Layer):**
    *   **Purpose:** Handles all MQTT client lifecycle events (connect, disconnect), message publishing, and connection status.
    *   **Dependencies:** Eclipse Paho MQTT Client.
    *   **Methods:**
        *   `connect()`: Establishes connection to `broker.hivemq.com:1883`.
        *   `disconnect()`: Closes the MQTT connection.
        *   `publish(topic: String, message: String)`: Publishes a message to the specified topic (`sos/alert`).
    *   **State:** Exposes connection status (`isConnected: Flow<Boolean>`) as a Kotlin Flow to be observed by the ViewModel.
    *   **Implementation Details:**
        *   Implement `MqttCallback` to handle connection success/failure, message delivery, and disconnection.
        *   Use a persistent client ID (e.g., `UUID().toString()`) for each app instance.
        *   Implement reconnection logic (e.g., exponential backoff) on disconnection.

#### 4.2. Location Management

*   **`LocationRepository` (Model/Repository Layer):**
    *   **Purpose:** Manages location permissions and retrieves the device's current location.
    *   **Dependencies:** `FusedLocationProviderClient`.
    *   **Methods:**
        *   `requestPermissions(activity: Activity)`: Requests `ACCESS_FINE_LOCATION` and `ACCESS_COARSE_LOCATION`.
        *   `getCurrentLocation(): Flow<LocationData?>`: Provides a stream of location updates.
    *   **State:** Exposes location data (`currentLocation: Flow<LocationData?>`) and permission status (`permissionGranted: Flow<Boolean>`).
    *   **Implementation Details:**
        *   Handle runtime permissions using Android's permission APIs (e.g., `ActivityResultLauncher`).
        *   Use `LocationRequest` to specify update interval and accuracy.
        *   Ensure location updates are stopped when no longer needed to conserve battery.

#### 4.3. User Preferences & Settings

*   **`SettingsRepository` (Model/Repository Layer):**
    *   **Purpose:** Stores and retrieves user-specific data (name, phone number) and app settings (language).
    *   **Dependencies:** Jetpack DataStore (Preference DataStore).
    *   **Methods:**
        *   `saveUserName(name: String)`
        *   `getUserName(): Flow<String>`
        *   `saveUserNumber(number: String)`
        *   `getUserNumber(): Flow<String>`
        *   `saveSelectedLanguage(langCode: String)`
        *   `getSelectedLanguage(): Flow<String>`
    *   **Implementation Details:**
        *   Define keys for each preference.
        *   Use `Flow` to expose preferences, allowing UI to react to changes.

#### 4.4. UI (Jetpack Compose)

*   **`MainViewModel` (ViewModel Layer):**
    *   **Purpose:** Provides data to `MainActivity` (or `MainScreen` Composable) and handles UI-related logic for sending alerts and displaying status.
    *   **Dependencies:** `MqttManager`, `LocationRepository`, `SettingsRepository`.
    *   **State:**
        *   `mqttStatus: StateFlow<String>` (e.g., "Online", "Offline")
        *   `locationStatus: StateFlow<String>` (e.g., "Acquiring Location...", "Location OK")
        *   `isReadyToSend: StateFlow<Boolean>` (combines MQTT and location status)
        *   `confirmationMessage: StateFlow<String?>`
    *   **Methods:**
        *   `sendAlert(type: String)`: Gathers user data and location, constructs JSON payload, and calls `MqttManager.publish()`.
        *   `connectMqtt()`: Calls `MqttManager.connect()`.
    *   **Implementation Details:**
        *   Combine `MqttManager.isConnected` and `LocationRepository.currentLocation` flows to derive `isReadyToSend`.
        *   Use `viewModelScope` for coroutines.

*   **`SettingsViewModel` (ViewModel Layer):**
    *   **Purpose:** Manages data for `SettingsScreen`.
    *   **Dependencies:** `SettingsRepository`.
    *   **State:**
        *   `userName: MutableStateFlow<String>`
        *   `userNumber: MutableStateFlow<String>`
        *   `selectedLanguage: MutableStateFlow<String>`
    *   **Methods:**
        *   `updateUserName(name: String)`
        *   `updateUserNumber(number: String)`
        *   `updateSelectedLanguage(langCode: String)`
    *   **Implementation Details:**
        *   Bind `MutableStateFlow` to Compose `TextField` and `DropdownMenu` for two-way data binding.

*   **`MainActivity` (View Layer):**
    *   **Purpose:** Hosts the main UI Composables.
    *   **Implementation Details:**
        *   Set up `setContent` with `MainScreen` Composable.
        *   Inject `MainViewModel` using Hilt.

*   **`MainScreen` (Composable):**
    *   **Purpose:** Displays the main SOS interface (buttons, status, map).
    *   **Dependencies:** `MainViewModel`.
    *   **UI Elements:**
        *   Status text (observes `MainViewModel.mqttStatus`, `locationStatus`).
        *   SOS buttons (enabled/disabled based on `MainViewModel.isReadyToSend`).
        *   Map view (using a library like Google Maps SDK for Android, displaying user's current location).
        *   Settings button (navigates to `SettingsScreen`).
        *   Confirmation message (observes `MainViewModel.confirmationMessage`).
    *   **Interaction:**
        *   Tap on status text to trigger `MainViewModel.connectMqtt()`.
        *   Button clicks call `MainViewModel.sendAlert()`.

*   **`SettingsScreen` (Composable):**
    *   **Purpose:** Displays user information and language selection.
    *   **Dependencies:** `SettingsViewModel`.
    *   **UI Elements:**
        *   `TextField` for user name (binds to `SettingsViewModel.userName`).
        *   `TextField` for phone number (binds to `SettingsViewModel.userNumber`).
        *   `DropdownMenu` for language selection (binds to `SettingsViewModel.selectedLanguage`).
        *   App version and build number (retrieved from `BuildConfig` or `PackageManager`).
    *   **Interaction:**
        *   Changes in `TextField`s and `DropdownMenu` trigger updates in `SettingsViewModel`.

#### 4.5. Localization

*   **Android Resources:**
    *   Create `strings.xml` files in `res/values` (default English) and `res/values-<locale_code>` (e.g., `res/values-tl` for Tagalog, `res/values-ceb` for Bisaya, `res/values-zh` for Chinese, `res/values-ko` for Korean).
    *   Use `getString(R.string.my_string_key)` or `stringResource(R.string.my_string_key)` in Compose.
*   **Language Switching:**
    *   When `SettingsViewModel.updateSelectedLanguage()` is called, save the new language code to DataStore.
    *   To apply the language change immediately, the app needs to recreate the activity or update the configuration. A common approach is to use `AppCompatDelegate.setApplicationLocales()` (for API 24+) or restart the activity. The `SettingsScreen` will update the `SettingsRepository`, and the `MainScreen` will observe the `selectedLanguage` from the `SettingsRepository` and update its `Locale` accordingly.

### 6. Error Handling & Edge Cases

*   **MQTT Connection Errors:** Display user-friendly messages, implement retry logic.
*   **Location Permissions:** Guide the user to grant permissions if denied.
*   **No Location Available:** Inform the user if location cannot be acquired.
*   **Network Connectivity:** Handle cases where there's no internet connection for MQTT.
*   **Empty User Info:** Ensure the app handles cases where `userName` or `userNumber` are empty strings gracefully.
*   **JSON Encoding/Decoding:** Implement robust error handling for JSON serialization.

### 7. Development Workflow

1.  **Project Setup:** Create a new Android project in Android Studio with Kotlin and Jetpack Compose.
2.  **Add Dependencies:** Include necessary libraries (Paho MQTT, Google Play Services Location, DataStore, Hilt, etc.) in `build.gradle`.
3.  **Implement Core Services:** Develop `MqttManager`, `LocationRepository`, `SettingsRepository`.
4.  **Design ViewModels:** Create `MainViewModel` and `SettingsViewModel`.
5.  **Build UI:** Develop `MainScreen` and `SettingsScreen` Composables.
6.  **Integrate:** Connect ViewModels to Composables and inject dependencies.
7.  **Testing:** Write unit tests for ViewModels and integration tests for repositories.
8.  **Localization:** Add `strings.xml` files for all supported languages.
9.  **Testing on Device:** Thoroughly test on physical Android devices for various scenarios (network changes, location changes, backgrounding, language switching).
