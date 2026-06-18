# CommitHike 🏔️ — Outdoor Rental & Inventory Manager

CommitHike is a modern, premium mobile management system designed for outdoor equipment rental and retail businesses. Built using Flutter and Material 3 design principles, this app provides business owners with a visual, efficient, and responsive tool to manage stock, audit physical inventory, and register customer rentals.

This project features a fully optimized **Light & Dark Mode** user interface with seamless state changes, sleek container physics, and highly polished user experiences (UX) designed to mimic premium modern SaaS dashboards.

---

## ✨ Features & Enhancements

### 🖥️ 1. Dynamic Performance Dashboard
*   **Greeting Banner:** A personalized welcome panel that adjusts greeting text based on the time of day (Morning/Afternoon/Evening) with descriptive task subtexts.
*   **SaaS-Style Statistics:** High-contrast widgets displaying Total Items, Active Rentals, and Total Earnings with colored icon chips and elevation-free borders.
*   **Contextual Quick Actions:** Quick-entry buttons for adding items, creating rentals, or performing stock audits, complete with detailed helper descriptions.

### 📦 2. Smart Inventory & Cataloging
*   **Inline Choice Chips:** Replaces cumbersome modal filter popups with instant, horizontal scrolling chips for Product Type (*Rent / Sell*) and Categories.
*   **Enhanced Cards:** Beautiful product lists displaying image previews, distinct category badges, bold localized price formatting, and status trackers.
*   **Integrated Category Management:** Directly add, edit, or remove custom equipment categories from a dedicated settings screen.
*   **Actions Popup:** Interactive three-dot popup menus on each card for quick editing or deletion, improving discoverability over hidden gestures.

### 📊 3. Interactive Stock Opname (Physical Audit)
*   **Verification Defaulting:** Checking an item immediately defaults its physical audit count to matches the system database, minimizing manual entry.
*   **Tap-to-Counter Controls:** Replaces standard text inputs with mobile-friendly increment `[+]` and decrement `[-]` buttons.
*   **Live Discrepancy Badges:** Real-time color status indicators showing if stock matches (**"Sesuai"**) or has variations (**"Selisih -x"** / **"Selisih +x"**) so auditors can spot discrepancies instantly.

### 💳 4. Checkout Flow & Digital Receipt Invoices
*   **Rental Duration Chip:** A simplified date range selection showing localized start-end schedules and active day tallies in custom colored tags.
*   **Searchable Multi-Selection:** Quick name search across the catalog with interactive selection states and quantity limit validations.
*   **Invoice Receipt Sheet:** Rental details open in a gorgeous, scrollable modal sheet styled as a **digital retail invoice receipt**, outlining structured client metadata, category-badged item lists, date margins, and bold total pricing.
*   **Interactive History:** Tap any history transaction to pull up the digital receipt sheet to verify items and total costs of finished transactions.

---

## 🛠️ Tech Stack & Libraries
*   **Framework:** [Flutter](https://flutter.dev) (v3.12.1+ / Material 3)
*   **Language:** [Dart](https://dart.dev)
*   **Local Storage:** SQLite via `sqflite` (relational structure for `items`, `rentals`, `rental_items`, and `categories`)
*   **Utilities:** `intl` (local currency formatters, date pickers) and `image_picker` (item camera/gallery attachments)

---

## 🎨 Theme & Styling System
The app features a cohesive design language specified globally in `main.dart`:
*   **Light Theme:** A crisp slate background (`#F8FAFC`) with emerald-teal (`#0F766E`) primary details and indigo accents (`#4F46E5`).
*   **Dark Theme:** A sleek slate-navy backdrop (`#0F172A`) with neon emerald (`#2DD4BF`) primary elements and light indigo icons (`#818CF8`).
*   **Inputs & Fields:** Thick outlined inputs, rounded fields (`16dp`), and color transitions that match the selected theme configuration.

---

## 🚀 Getting Started

### Prerequisites
Before running CommitHike, ensure you have the following installed on your machine:
*   [Flutter SDK](https://docs.flutter.dev/get-started/install) (Stable channel)
*   [Android Studio](https://developer.android.com/studio) or [VS Code](https://code.visualstudio.com) with Dart/Flutter plugins.
*   An Android/iOS emulator or connected physical device.

### Installation

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/YOUR_USERNAME/rental_outdoor_app.git
    cd rental_outdoor_app
    ```

2.  **Install project dependencies:**
    ```bash
    flutter pub get
    ```

3.  **Run the application:**
    ```bash
    flutter run
    ```
