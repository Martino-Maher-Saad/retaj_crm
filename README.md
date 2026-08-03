# Retaj CRM - Project Context & Documentation

This document serves as a comprehensive, token-optimized context file for AI models. It encapsulates the architecture, features, business logic, and state management of **Retaj CRM**, a robust Real Estate CRM application built with Flutter and Supabase.

## 1. Project Overview & Tech Stack
- **Application**: Retaj CRM (Real Estate Customer Relationship Management).
- **Framework**: Flutter (Dart ^3.8.1).
- **Backend & Database**: Supabase (PostgreSQL) for Auth, Database, Storage, and Realtime subscriptions.
- **State Management**: BLoC / Cubit (`flutter_bloc`, `bloc`).
- **Dependency Injection**: `get_it`.
- **AI Integration**: Google Generative AI (`google_generative_ai`) for embeddings and semantic "Smart Matching".
- **UI/UX Components**: `skeletonizer` (loading states), `shimmer`, `responsive_grid_list`, `fl_chart` (analytics), `cached_network_image`.
- **Utilities**: Excel/PDF generation, WhatsApp sharing, Pattern formatters.

## 2. System Architecture
The project follows a modular, feature-first Clean Architecture pattern.
- **`lib/core/`**: Constants (colors, styles), Theme, Utilities (NumberFormatter, RoleHelper, Debouncers), DI setup, and shared widgets.
- **`lib/data/`**: 
  - **Models**: Defines data entities (`LeadModel`, `PropertyModel`, `ProfileModel`, `CrmEvent`).
  - **Repositories**: Abstracts data fetching (`LeadRepository`, `PropertyRepository`).
  - **Services**: Low-level integrations (`Supabase` operations, `AuthService`, `RealtimeService`, `AiService`, `GeminiEmbeddingService`).
- **`lib/features/`**: UI and Business Logic separated by feature domain (`leads`, `properties`, `tasks`, `profile`, `duplicates`, `layout`).

## 3. Core Entities & Data Models

### A. Lead (Client) Management (`LeadModel`)
- **Structure**: Contains `clientName`, multiple `phones` (via `LeadPhoneModel`), `budgetFrom`/`budgetTo`, location needs (`cityId`, `governorateId`), and requested types (`propertyTypeId`, `listingTypeId`).
- **Nested Relationships**: Includes `LeadNoteModel` (timestamped notes by users) and `LeadLogEntryModel` (audit trail of status changes/actions).
- **Metadata**: Tracks assignment (`assignedTo`, `transferredFrom`), states (`isActive`, `isArchived`, `isPinned`), and `leadStatus`.

### B. Property Management (`PropertyModel`)
- **Structure**: Stores `titleAr`, `descAr`, `price`, `ownerName`, `ownerPhone`, `internalNotes`, `managerNotes`, location data.
- **Media & Advertising**: Handles a list of `PropertyImageModel` and `advertisingPlatforms` (`PropertyPlatformEntry`).
- **AI Fields**: Includes `embedding` and `embeddingV2` (vector representations of the property for AI semantic search).
- **Metadata**: Tracks `approvalStatusId` (Manager approvals), `isPinned`, `status`.

### C. Users & RBAC (`ProfileModel` & `role_helper.dart`)
- Defines roles (e.g., `sales`, `admin`, `manager`). Permissions dynamically control UI visibility (e.g., hiding owner phone numbers from standard sales reps unless they own the property).

## 4. Key Functionalities & Use Cases

### 1. Smart Match (AI-Powered Recommendation)
- **Use Case**: A sales agent views a Lead and wants to find suitable properties.
- **Mechanism**: The `SmartMatchScreen` invokes `PropertiesCubit.smartSearch()`. It passes the lead's text description (`descLeadNeed`), budget ranges, and explicit filters (city, property type). 
- **AI Flow**: The query is likely embedded via `GeminiEmbeddingService` and matched against `property.embeddingV2` in Supabase (using pgvector), merged with hard SQL filters (budget, location) to return highly accurate property recommendations.

### 2. Lead Lifecycle & Pipeline
- **Use Case**: Tracking a client from initial contact to closing.
- **Mechanism**: Leads have visual pipeline indicators. Actions like adding comments, updating statuses, or transferring to another agent automatically generate `LeadLogEntryModel` entries, maintaining a strict audit trail.
- **Features**: Bulk adding leads (`BulkAddLeadsCubit`), advanced filtering, archiving/restoring.

### 3. Property Management & Internal Shares
- **Use Case**: Managing the agency's inventory and sharing properties among agents.
- **Mechanism**: Properties undergo an approval workflow (via `manager_approvals_screen.dart`). Properties have a detailed view with a full-screen image gallery (InteractiveViewer).
- **Features**: "Property Shares" allows agents to securely share property specs with clients via WhatsApp or internally without exposing direct owner contacts.

### 4. Tasks & Manager Approvals
- **Use Case**: Assigning follow-ups or requesting managerial overrides.
- **Mechanism**: Segregated into Lead Tasks and Property Tasks. Managers have a dedicated "Approvals" dashboard to approve/reject property publications or sensitive lead transfers.

### 5. Realtime Synchronization (`RealtimeService`)
- **Use Case**: Ensuring all connected agents see the latest updates instantly.
- **Mechanism**: Subscribes to Supabase `PostgresChangeEvent.all` on `leads` and `properties` tables. Broadcasts `CrmEvent` (insert/update/delete) through a Dart Stream. Cubits listen to this stream to dynamically inject/update/remove items from their local state lists without refreshing the page.

### 6. Duplicate Detection
- **Use Case**: Preventing data pollution.
- **Mechanism**: Dedicated screens (`duplicates_views.dart`) scan the database for matching phone numbers or closely matching names/properties, prompting the user to merge or dismiss duplicates.

## 5. UI/UX & State Management Patterns
- **Cubits**: Every major feature relies on a Cubit (e.g., `LeadsCubit`, `PropertiesCubit`) emitting standard states (`Loading`, `Success`, `Error`).
- **Caching & Optimizations**: Uses `property_cache_manager.dart` and `flutter_cache_manager` for heavy image loads. Uses debouncers (`responsive_debouncer_wrapper.dart`) for search inputs to prevent API spam.
- **Static Data**: `StaticDataManager` loads lookup tables (governorates, property types, statuses) once at startup to ensure synchronous, low-latency UI dropdowns and filters.

---
**Note to AI Models**: When editing this codebase, strictly adhere to the established BLoC/Cubit state management pattern, maintain responsive UI constraints (`flutter_screenutil`), and ensure all Supabase data mutations correctly reflect in the UI either via optimistic updates or by relying on `RealtimeService` events.
