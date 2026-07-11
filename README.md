# Campus Connect Admin Portal

Live Web App: [ccadmin.99practice.com](https://ccadmin.99practice.com)


Use These Credentials to get Access to the portal : 
  Email : campus.admin789@gmail.com
  Password : securepassword123

Welcome to the admin repository for **Campus Connect**, a comprehensive centralized management dashboard built to oversee campus notices and events. This project is submitted as part of the DevSoc society selection task and is designed to provide administrators with a seamless, cross-platform interface for content moderation and creation.

---

## 🚀 Key Features

* **Secure Authentication:** Protected route management using Supabase Authentication, ensuring only authorized personnel can access the dashboard.
* **Complete CRUD Operations:** Full control over campus data. Admins can create, read, update, and delete (CRUD) both events and notices in real-time.
* **Dynamic Link Management:** Easily attach multiple important external links (e.g., registration forms, syllabus PDFs, Google Maps locations) directly to events and notices.
* **Cross-Platform Image Uploads:** Unified image picker that works flawlessly across web and mobile, handling binary data extraction and uploading directly to Supabase Storage buckets.
* **Adaptive Responsive Layout:** A custom `DesktopMobileWrapper` seamlessly adapts the UI. On desktop displays, it renders a side navigation rail with a 75%-scaled mobile preview, while gracefully falling back to a standard bottom navigation bar on mobile devices.
* **Smart State Refreshes:** Integration of Riverpod's `AsyncNotifier` ensures that the UI instantly reflects changes (like deletions or edits) without requiring manual page reloads.

---

## 🛠️ Technology Stack

* **Frontend Framework:** Flutter (Dart)
* **State Management:** Riverpod (`flutter_riverpod`) for declarative and reactive state caching.
* **Backend & APIs:** Express.js REST API (hosted on Render) for business logic and data routing.
* **Database & Auth:** Supabase (PostgreSQL) handling robust session management, JWT verification, and blob storage for thumbnails.
* **Networking:** `http` package for authenticated API requests passing Supabase Bearer tokens.

---

## 📁 Project Structure

The application is structured for high modularity and scalable maintenance:

* **`/models`**: Contains the typed data structures (`Event` and `Notice`), complete with JSON serialization logic to handle complex dynamic link mappings.
* **`/providers`**: Houses the `AsyncNotifierProvider` classes (`adminNoticesProvider`, `adminEventsProvider`) for decoupling API fetching logic from the UI.
* **`/services`**: The core `AdminService` class that standardizes all external communication, including authentication, image uploading, and Express API HTTP requests.
* **`/screens`**: The visual layer, segmented into dashboard layouts (`AdminDashboard`), list views (`AdminNoticesList`, `AdminEventsList`), detail views, and dedicated creation/editing forms.

---

## ⚙️ Core Mechanisms Explained

* **Unified API Integration:** The app connects to a custom Node.js backend (`[https://campus-connect-api-z6og.onrender.com](https://campus-connect-api-z6og.onrender.com)`), passing the active Supabase JWT in the authorization header to validate admin privileges on the server side before executing any destructive operations.
* **Graceful Loading States:** The UI elegantly transitions between data states using Riverpod's `.when()` method, providing clear loading indicators and error handling if network requests fail.
* **Safe Resource Launching:** The built-in URL launcher automatically sanitizes web links (appending `https://` if necessary) before pushing users to external browsers, ensuring broken links don't crash the internal application flow.
