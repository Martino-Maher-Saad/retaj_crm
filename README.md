# Retaj CRM | Enterprise Real Estate Management System

Retaj CRM is a high-performance, enterprise-grade management system tailored for real estate agencies. Built with **Flutter** and **Supabase**, it provides a robust infrastructure for managing leads, property inventories, and architectural designs with a focus on operational efficiency and a premium user experience.

---

## 🚀 Overview

In the fast-paced real estate market, managing client relationships and massive property data requires more than just a simple spreadsheet. **Retaj CRM** solves this by providing a centralized dashboard that bridges the gap between sales teams, property managers, and raw data.

### Key Problem Solved
- **Lead Fragmentation**: Centralizes leads from various sources (social media, walk-ins, referrals).
- **Inventory Complexity**: Handles multi-layered property data including location hierarchies, pricing models, and extensive media storage.
- **Role-Based Workflow**: Ensures that sensitive data is only accessible to authorized personnel (Admin, Manager, Sales).

---

## ✨ Key Features

- **🛡️ Secure Role-Based Authentication**: Integrated with Supabase Auth for fine-grained access control.
- **📊 Real-time Smart Dashboards**: 
  - **Employee View**: Tracks personal pipeline, conversion rates, and recent leads.
  - **Manager View**: Tracks team performance, top governorates, platform conversions, and period-over-period growth via Supabase RPCs.
- **📑 Comprehensive Lead Management**: 
  - Tracks status, source, communication channels, notes, and multiple phone numbers.
  - Advanced filtering and assignment logic.
- **🏠 Advanced Property Engine**:
  - Complex data models supporting multiple image uploads and multi-platform advertising tracking.
  - Full-text search using PostgreSQL `search_vector`.
  - Dynamic filtering by city and property type.
- **⚙️ Dynamic System Management**: Admins can manage dropdown options (cities, property types, sources, etc.) and user accounts directly from the UI.
- **📱 Responsive Desktop UI**: Optimized for high-resolution displays (1920x1080) with a premium Arabic-first design.

---

## 🛠️ Tech Stack

- **Frontend**: 
  - **Framework**: [Flutter](https://flutter.dev/) (Material 3)
  - **State Management**: [BLoC / Cubit](https://pub.dev/packages/flutter_bloc) for predictable state transitions.
  - **Dependency Injection**: [GetIt](https://pub.dev/packages/get_it) for centralized dependency management.
  - **Responsiveness**: `flutter_screenutil` for pixel-perfect scaling.
  - **Typography**: [Google Fonts (Cairo)](https://fonts.google.com/specimen/Cairo) for professional Arabic rendering.
- **Backend / Infrastructure**:
  - **Database**: [Supabase / PostgreSQL](https://supabase.com/).
  - **Authentication**: Supabase Auth (JWT).
  - **Storage**: Supabase Storage Buckets for property/design media.
- **Optimizations**:
  - `cached_network_image` for aggressive media caching.
  - `shimmer` for polished loading states.
  - `image_picker` + `flutter_image_compress` for client-side image optimization before upload.

---

## 🏗️ Architecture & System Design

The project follows a **Custom Layered Architecture** (simplified Clean Architecture) designed for scalability and maintainability.

### The "Surgical Update" Pattern
To ensure a high-performance UI, the application implements a **Surgical Update** pattern. Instead of re-fetching entire lists after a mutation (Create/Update/Delete), the Cubit state is mutated in-memory:
1. **Optimistic UI/Mutation**: The Cubit performs the action via Repository.
2. **Local State Update**: On success, only the specific item in the list is modified/added/removed.
3. **Rollback**: If the server fails, the Cubit emits the previous state and triggers a user notification.

### Layers:
1. **Presentation**: Atomic widgets and feature-specific screens.
2. **State (Cubit)**: Business logic and UI state orchestration.
3. **Domain (Repository)**: Data mapping, Arabic error handling, and business rules.
4. **Data (Service + Model)**: Raw Supabase queries and type-safe Dart models.

---

## 📂 Folder Structure

```text
lib/
├── core/               # Shared constants, theme, utils, and generic widgets
│   ├── constants/      # AppColors, AppStrings (Arabic), AppTextStyles
│   ├── theme/          # Centralized Material 3 ThemeData
│   └── utils/          # Role helpers, validators, and formatters
├── data/               # Persistent data layer
│   ├── models/         # Type-safe objects (LeadModel, PropertyModel, etc.)
│   ├── services/       # Raw Supabase API interaction
│   └── repositories/   # Error handling and data transformation
├── features/           # Self-contained business modules
│   ├── admin_users/    # User creation and role management
│   ├── auth/           # Login and session management
│   ├── dashboard/      # Employee and Manager analytics screens
│   ├── leads/          # Leads board and forms
│   ├── profile/        # Current user profile management
│   ├── properties/     # Advanced property inventory entries
│   └── designs/        # Architectural design management
└── main.dart           # App bootstrap and provider initialization
```

---

## 🗄️ Database Design

Based on **PostgreSQL**, the database uses relational integrity and performance optimizations:
- **`profiles`**: Stores user metadata and roles (Admin/Manager/Sales).
- **`properties`**: The core table with `search_vector` for fast full-text searching across Arabic text.
- **`property_images`**: A one-to-many relationship table for high-res property media.
- **`leads`**: Tracks customer interactions with relationship links to specific properties.
- **Pagination**: Implements `range(from, to)` queries (15 items per page) to minimize payload size and memory footprint.

---

## 🛠️ Installation & Setup

1. **Clone the project**
   ```bash
   git clone https://github.com/Martino-Maher-Saad/retaj_crm.git
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Supabase Setup**
   - Create a new project in your [Supabase Dashboard](https://app.supabase.com/).
   - Run the SQL migrations (found in `/database` if available, or recreate tables based on `/data/models`).
   - Enable Storage buckets for `property_images` and `designs`.

4. **Run the app**
   ```bash
   flutter run
   ```

---

## 🔮 Future Improvements

- **Push Notifications**: Real-time alerts for lead assignments using Supabase Edge Functions.
- **Advanced Analytics**: Integration of charts/graphs for sales performance metrics.
- **Offline Mode**: Local caching using `is_sarar` or `sqflite` for field agents with poor connectivity.
- **Multi-language Support**: Expanding from Arabic-first to a full RTL/LTR localization.

---

## 📱 Ecosystem Note
This repository contains the **CRM Management App** (Desktop/Web focus for staff). 
The project ecosystem also includes:
- **Retaj Staff Mobile**: A mobile-optimized version for employees on the field.
- **Retaj Client**: A dedicated mobile application for clients to browse properties and submit leads.

---

## 👨‍💻 Author

**Martino Maher Saad**  
*Senior Flutter Software Engineer*  
[LinkedIn](https://www.linkedin.com/in/martino-maher-saad/) | [Portfolio](https://github.com/Martino-Maher-Saad)

