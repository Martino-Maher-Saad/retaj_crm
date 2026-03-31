# UI/UX Reference — Retaj CRM (Web → Mobile Guide)

> **Purpose:** This document is the single source of truth for the visual design, screen layouts, component behavior, and interaction patterns of the Retaj CRM Flutter Web application. It is intended to guide an AI or developer in building a pixel-perfect, architecturally consistent **Mobile** version of the same app.

---

## Table of Contents

1. [Visual Language](#1-visual-language)
   - 1.1 Color Palette
   - 1.2 Typography
   - 1.3 Spacing & Sizing System
   - 1.4 Elevation & Shadows
2. [App Entry Point & Auth Flow](#2-app-entry-point--auth-flow)
3. [Global Shell — Layout Screen](#3-global-shell--layout-screen)
4. [Screen Breakdown](#4-screen-breakdown)
   - 4.1 Login Screen
   - 4.2 Dashboard Screen
   - 4.3 Properties List Screen
   - 4.4 Property Details Screen
   - 4.5 Property Form Screen (Add/Edit)
   - 4.6 Leads Management Screen
   - 4.7 Lead Details Screen
   - 4.8 Lead Form Screen (Add/Edit)
   - 4.9 Designs List Screen
   - 4.10 Accounts Management Screen (Admin Only)
5. [Reusable Core Widgets](#5-reusable-core-widgets)
6. [Web-to-Mobile Adaptation Strategy](#6-web-to-mobile-adaptation-strategy)

---

## 1. Visual Language

### 1.1 Color Palette

The app uses a dual-brand color system: **Deep Blue (primary)** for structural and interactive elements, and **Red (accent)** for destructive or attention-critical actions. All colors are defined in `lib/core/constants/app_colors.dart`.

#### Brand — Blue Scale (Primary)
| Token | Hex | Usage |
|---|---|---|
| `brandPrimary` | `#2E3192` | Primary buttons, active nav items, section titles, focus borders |
| `brandPrimaryDark` | `#1D1F5E` | Login card title, AppBar icons, heading text |
| `brandPrimaryLight` | `#5A5EB9` | Hover states, secondary highlights |
| `brandPrimarySurface` | `#EAEBFF` | Subtle selected element backgrounds |

#### Brand — Red Scale (Accent / Destructive)
| Token | Hex | Usage |
|---|---|---|
| `brandAccent` | `#E31E24` | Delete buttons, error messages, badges for "excluded/rejected" leads |
| `brandAccentDark` | `#B3171B` | Pressed state for destructive actions |
| `brandAccentLight` | `#ED5D62` | Soft error highlights |
| `brandAccentSurface` | `#FFEBEC` | Error message background containers |

#### Backgrounds
| Token | Hex | Usage |
|---|---|---|
| `bgMain` / `scaffoldBackground` | `#F8F9FA` | Main scaffold / page background (off-white) |
| `bgSurface` / `cardBackground` | `#FFFFFF` | Cards, modals, form fields, AppBar |
| `bgSideBar` / `sidebarBackground` | `#1A1F2E` | Deep navy — sidebar background |

#### Text & Neutrals
| Token | Hex | Usage |
|---|---|---|
| `textPrimary` | `#1A1A1A` | Headings, card titles, primary body text |
| `textSecondary` | `#666666` | Table sub-labels, placeholder text, secondary info |
| `textDisabled` | `#9E9E9E` | Disabled state text, inactive toggle thumbs |
| `borderSubtle` | `#E0E0E0` | Card borders, dividers, form field borders (resting) |
| `borderStrong` | `#BDBDBD` | Focused field border alternative |

#### Status Colors
| Token | Hex | Usage |
|---|---|---|
| `success` | `#2D6A4F` | "Contracted" lead badge, active property badge, role badge in sidebar |
| `warning` | `#D97706` | "Negotiation" lead badge |
| `info` | `#2563EB` | "Contacted" lead badge, location icons on cards |
| `error` | `#D32F2F` | Form validation errors |

#### Lead Status → Color Mapping
This is critical for rendering the pipeline badges consistently:
```
جديد (New)          → info     (#2563EB)
تم التواصل (Contacted) → warning  (#D97706)
تفاوض (Negotiation)   → brandPrimary (#2E3192)
تم التعاقد (Contracted)→ success  (#2D6A4F)
مستبعد (Excluded)    → brandAccent (#E31E24)
```

---

### 1.2 Typography

**Font Family:** `Cairo` (Google Fonts) — used for all text. This font supports both Arabic and English beautifully with a line height of `1.4`.

All text styles are defined in `lib/core/constants/app_text_styles.dart`. The app uses `flutter_screenutil` for responsive font scaling (`.sp` suffix). The ScreenUtil design reference size is **1920×1080** (Full HD desktop).

#### Semantic Text Style Reference
| Style Name | Font Size | Weight | Color | Usage |
|---|---|---|---|---|
| `displayLarge` | 34sp | w800 | `brandPrimary` | Large stat numbers on dashboard |
| `statsNumber` | 24sp | bold | `textPrimary` | Dashboard metric values |
| `h1` | 26sp | bold | `textPrimary` | Page-level main headings |
| `h2` | 20sp | w700 | `brandPrimaryDark` | AppBar titles, section headings |
| `h3` | 18sp | w600 | `textPrimary` | Card titles, sub-section titles |
| `tableHeader` | 13sp | w800 | `textSecondary` | Column headers (all-caps feel) |
| `tableCellMain` | 14sp | w600 | `textPrimary` | Primary cell content |
| `tableCellSub` | 12sp | normal | `textSecondary` | Secondary cell content, dates |
| `cardTitle` | 16sp | bold | `textPrimary` | Lead/Property card main name |
| `cardPrice` | 18sp | w800 | `success` | Property price display |
| `cardLocation` | 13sp | w500 | `info` | Location text on cards |
| `inputLabel` | 14sp | w700 | `brandPrimary` | Form field labels |
| `inputText` | 15sp | normal | `textPrimary` | Form field input text |
| `helperText` | 12sp | normal | `brandAccent` | Validation/helper text under fields |
| `buttonLarge` | 16sp | bold | white | Primary action button text |
| `chipLabel` | 12sp | w600 | white | Status badge / chip text |
| `blue32Bold` | 32 | bold | `brandPrimaryDark` | Top header page title (web) |
| `blue28Bold` | 28 | bold | `brandPrimaryDark` | Login card title |
| `white18SemiBold` | 18 | w600 | white | Sidebar nav item label |

---

### 1.3 Spacing & Sizing System

All spacing values are responsive via `flutter_screenutil` (`.w` for widths, `.h` for heights, `.r` for border radii).

Defined in `lib/core/constants/app_constants.dart`:

#### Padding / Margin Scale
| Token | Value | Usage |
|---|---|---|
| `p4` | 4.w | Tight internal spacing (icon gaps) |
| `p8` | 8.w | Small gaps, badge padding |
| `p16` | 16.w | Standard section padding, card internal padding |
| `p24` | 24.w | Page-level horizontal padding |
| `p32` | 32.w | Large section separations |

#### Border Radius Scale
| Token | Value | Usage |
|---|---|---|
| `r4` | 4.r | Small pills, tiny badges |
| `r8` | 8.r | Buttons, text fields, action icon containers |
| `r12` | 12.r | Cards (LeadCard, PropertyCard), larger containers |
| `r20` | 20.r | Modals, bottom sheets |

#### Icon Sizes
| Token | Value | Usage |
|---|---|---|
| `iconSm` | 16.sp | Inline icons within text or tight spaces |
| `iconMd` | 24.sp | Standard action icons (edit, delete, nav) |
| `iconLg` | 32.sp | Feature/section icons |

#### Layout Constants
- **Sidebar width:** `280.w`
- **Top header height:** `90.h`
- **Min desktop width:** `1100px` (below this, horizontal scroll appears)
- **Pagination page size:** `5` items per page

---

### 1.4 Elevation & Shadows

The design is largely **flat** (Material 3 principles) with minimal shadows:
- **Cards:** `elevation: 0` with a `BorderSide(color: borderSubtle)` border. Shadow: `BoxShadow(color: black.withOpacity(0.04), blurRadius: 12, offset: Offset(0, 4))`.
- **Login Card:** `BoxShadow(color: black12, blurRadius: 10, spreadRadius: 2)`.
- **AppBar:** `elevation: 0` with bottom border: `BorderSide(color: greyLight.withOpacity(0.5))`.
- **Buttons (`CustomButton`):** Soft shadow: `BoxShadow(color: greyDark.withOpacity(0.2), blurRadius: 7, spreadRadius: 0.3, offset: Offset(-0.5, 3.3))`.

---

## 2. App Entry Point & Auth Flow

**File:** `lib/main.dart`

### Application Bootstrap
1. App initializes with `ScreenUtilInit` at design size **1920×1080**.
2. `AuthCubit` is provided at root and immediately calls `checkAuthStatus()`.
3. `MaterialApp` uses `AppTheme.lightTheme`.

### Auth State Routing (RootAuthWrapper)
```
AuthLoading  → Full-screen CircularProgressIndicator (white scaffold)
AuthSuccess  → LayoutScreen(user: state.user)  [Main app shell]
AuthFailure / initial → LoginWebScreen()
```
The user never manually navigates; routing is fully driven by BLoC state.

---

## 3. Global Shell — Layout Screen

**File:** `lib/features/layout/screens/layout_screen.dart`

This is the **master layout** that wraps all main app pages after authentication. It uses a classic **Sidebar + Header + Content** pattern.

### Visual Structure (Web)
```
┌──────────────────────────────────────────────────────────┐
│ SIDEBAR (280px)  │  TOP HEADER (90px)                    │
│                  ├────────────────────────────────────────│
│  [Logo]          │                                        │
│  [UserAvatar]    │    PAGE CONTENT (PageView)             │
│  ─────────────   │    (Dashboard / Properties / Leads /   │
│  [Nav Items]     │     Designs / Accounts)                │
│  ─────────────   │                                        │
│  [LogoutButton]  │                                        │
└──────────────────┴────────────────────────────────────────┘
```

### Sidebar (`_buildCustomSidebar`)
- **Background:** `sidebarBackground` (`#1A1F2E` — deep navy)
- **Width:** `280.w`
- **Structure (top to bottom):**
  1. `SideBarLogo` widget — company logo at the top
  2. `UserAvatar` widget — circular avatar + name + role badge
  3. Subtle `Divider` (`greyLight.withOpacity(0.3)`)
  4. `ListView` of Nav Items (see below)
  5. `LogoutButton` widget — pinned at the bottom

#### Sidebar Navigation Items
Each item is a custom `AnimatedContainer` (200ms duration) with:
- **Icon** (white, 24sp) + **Label** (white text, 18sp)
- **Resting state:** Transparent background
- **Selected state:** `white.withOpacity(0.15)` background, **bold** font weight
- **Items:**
  | Index | Icon | Label | Visible To |
  |---|---|---|---|
  | 0 | `analytics_outlined` | Dashboard | All |
  | 1 | `home_work_outlined` | Properties | All |
  | 2 | `person_search_outlined` | Leads | All |
  | 3 | `format_paint_outlined` | Designs | All |
  | 4 | `admin_panel_settings_outlined` | Accounts | Admin only |
- **On tap:** `LayoutCubit.changeNavigation(index)` → `PageController.animateToPage()` (300ms, `easeInOut`)

### Top Header (`TopHeader`)
- **Height:** `90.h`
- **Background:** White with bottom border (`greyLight.withOpacity(0.5)`)
- **Left side:** Dynamic page title (updates via `LayoutCubit` state) — style: `blue32Bold` (28sp)
- **Right side (actions row):**
  - Search icon button (`search_rounded`)
  - Notifications icon button (`notifications_none_rounded`)
  - Settings icon button (`settings_outlined`)
  - Vertical divider
  - User's first name text (14sp, `blue18Medium`)
- All action icons use `sidebarBackground.withOpacity(0.7)` color and have tap ripple bounds.

### Content Area
- `PageView` with `NeverScrollableScrollPhysics` (navigation is only via sidebar)
- Pages are kept alive via `AutomaticKeepAliveClientMixin` and `PageStorageKey`

### Role-Based Pages
```dart
// All users see:
[DashboardScreen, PropertiesListScreen, LeadsManagementScreen, DesignsListScreen]
// Admin additionally sees:
[AccountsManagementScreen]
```

---

## 4. Screen Breakdown

---

### 4.1 Login Screen

**File:** `lib/features/auth/screens/login_web_screen.dart`

#### Layout
- Full-screen `Scaffold` with `bgMain` (`#F8F9FA`) background.
- Content is centered both horizontally and vertically.
- A single white card (`width: 450`, `borderRadius: 12`, `boxShadow: black12`) floats in the center.

#### Card Contents (Column, top to bottom)
1. **Title:** "تسجيل الدخول" — style `blue28Bold`, centered.
2. **SizedBox(height: 32)**
3. **Email Field:** `CustomTextFormField`
   - Label: Email
   - Prefix icon: `Icons.email` (blue dark, 20sp)
   - Border color: `primaryBlueDark`
   - Validation: minimum 6 characters
4. **SizedBox(height: 20)**
5. **Password Field:** `CustomTextFormField`
   - Label: Password
   - `obscureText: true`
   - Prefix icon: `Icons.lock_outline` (blue dark)
   - Suffix icon: `Icons.remove_red_eye` (for toggle visibility)
   - Border color: `primaryBlueDark`
6. **SizedBox(height: 30)**
7. **Login Button:** `CustomButton`
   - Full width, height 50
   - Background: `primaryBlueDark`
   - Text: "تسجيل الدخول", white, 22sp, bold
   - While `AuthLoading`: replaced by `CircularProgressIndicator`
   
#### Interactions
- **Tap Login:** Validates form → calls `authCubit.login(email, password)`.
- **AuthFailure:** `SnackBar` with red background and error message appears.
- **AuthSuccess:** Navigation handled by root `BlocBuilder`, user is taken directly to `LayoutScreen`.

---

### 4.2 Dashboard Screen

**File:** `lib/features/dashboard/screens/dashboard_screen.dart`

> ⚠️ **Status: Placeholder / Under Development.** The screen currently only renders a `CustomSearchBar` and a centered `Text('Dashboard Screen')`. The full implementation with stats widgets is pending.

#### Current Layout
- `Scaffold` with a `Column`:
  1. `CustomSearchBar` (horizontal padding 3, vertical 8)
  2. `Center(child: Text('Dashboard Screen'))`

#### Planned Purpose
Based on text styles defined (e.g., `displayLarge`, `statsNumber`), the dashboard is intended to show KPI stat cards with aggregate numbers like total leads, contracted clients, active properties, etc.

---

### 4.3 Properties List Screen

**File:** `lib/features/properties/screens/properties_list_screen.dart`

#### Layout
- Background: `#F8FAFC`
- No AppBar — header is embedded in the top of the content column.
- Structure:
  ```
  ┌────────────────────────────────────┐
  │ PropertyListHeader (count + Add btn)│
  ├────────────────────────────────────┤
  │ PropertySearchBar                  │
  ├────────────────────────────────────┤
  │ ListView of PropertyCard widgets   │
  │ (Infinite Scroll + Pull-to-Refresh)│
  └────────────────────────────────────┘
  ```

#### Key Widgets
- **`PropertyListHeader`:** Displays total property count and an "+ Add" button.
- **`PropertySearchBar`:** A specialized search bar that calls `_cubit.search(value)` on each change.
- **`PropertyShimmerList`:** Shown during the initial `PropertiesLoading` state — skeleton loader animation.
- **`PropertyCard`:** Each card in the list (see Section 5 for details).
- **`PropertyDeleteDialog`:** A confirmation `AlertDialog` shown before deletion.

#### Interactions
- **Add button tap:** Opens `PropertyFormScreen` (Add mode) via `Navigator.push`.
- **PropertyCard tap:** Opens `PropertyDetailsScreen` via `Navigator.push`.
- **PropertyCard edit button:** Opens `PropertyFormScreen` (Edit mode).
- **PropertyCard delete button:** Shows `PropertyDeleteDialog`, on confirm calls `_cubit.deleteFullProperty(id)`.
- **Scroll to bottom:** Triggers infinite scroll — loads next page of properties.
- **Pull-to-refresh:** Calls `_cubit.fetchMyProperties(isRefresh: true)`.
- **Error:** Shown as a red `SnackBar`.

---

### 4.4 Property Details Screen

**File:** `lib/features/properties/screens/property_details_screen.dart`

#### Layout
- AppBar: white background, title = property's Arabic title (`blue16Bold`), back arrow (`Icons.arrow_back_ios`, black).
- Body: `SingleChildScrollView` with a vertical `Column`.

#### Sections (top to bottom)
1. **`PropertyImageHeader`** — A horizontal image gallery/carousel at the top showing property images. Tappable for full-screen view.
2. **`PropertyMainInfoCard`** — White card showing listing type, property type, price (in EGP), and key headline info.
3. **`PropertySectionCard` — "المواصفات الفنية" (Technical Specs)**
   - Contains `PropertySpecsGrid`: a grid of specs (bedrooms, bathrooms, area, floor, etc.).
4. **`PropertySectionCard` — "الموقع" (Location)**
   - `PropertyCopyableField` rows for: Governorate, City, Region, Detailed Address.
5. **`PropertySectionCard` — "الوصف" (Description)**
   - `PropertyCopyableField` for Arabic description (multi-line).
6. **`PropertySectionCard` — "بيانات الإدارة والمالك" (Owner & Admin)**
   - Owner Name, Owner Phone, internal staff notes.
   - A `Divider` separates owner info from internal notes.

#### `PropertyCopyableField` Behavior
Each field shows a label + value and has a copy icon. Tapping copies the value to the clipboard — useful for sharing property details.

---

### 4.5 Property Form Screen (Add / Edit)

**File:** `lib/features/properties/screens/property_form_screen.dart`

This is the most complex screen in the app. It is a **multi-section scrollable form** organized into **7 `PropertyFormCard` steps**.

#### Layout
- AppBar title: "إضافة إعلان" or "تعديل إعلان" depending on mode.
- Body: `Form` wrapped in `SingleChildScrollView` with `padding: 16.w`.

#### The 7 Form Sections (PropertyFormCard)
Each `PropertyFormCard` is a collapsible/expandable card with a step number, icon, and title.

| # | Title (AR) | Icon | Key Fields |
|---|---|---|---|
| 1 | الصور | `photo_camera_outlined` | Image picker grid (existing + new), max 10 images |
| 2 | المعلومات الأساسية | `assignment_outlined` | Property Code, Arabic Title, Description, Listing Type dropdown (بيع/إيجار), Property Type dropdown (شقة/فيلا/...) |
| 3 | الموقع | `location_on_outlined` | Governorate dropdown → City dropdown (cascading), Region text field, Detailed address, Map link |
| 4 | المواصفات الفنية | `straighten_rounded` | Built Area, Land Area, Garden Area, Bedrooms, Bathrooms, Kitchens, Balconies, Floor (conditional), Total Floors, Building Age, Furnished dropdown |
| 5 | حالة العقار | `check_circle_outline` | Is Compound toggle (`FormToggleTile`), Completion Status dropdown, Delivery Date picker |
| 6 | بيانات السعر | `payments_outlined` | Price field, Negotiable toggle, Rental Frequency (if listing=إيجار), Has Installment toggle, Down Payment, Monthly installment, Months, Insurance |
| 7 | الإدارة والمالك | `admin_panel_settings_outlined` | Status toggle (Active/Inactive), Owner Name, Owner Phone, Internal Notes |

#### Submit Button
- Full width, height 54.h.
- Background: `primaryBlue`, white text.
- Add mode: Icon `add_task`, label "إضافة العقار"
- Edit mode: Icon `save_outlined`, label "حفظ التعديلات"
- While loading: `AnimatedSwitcher` shows a `CircularProgressIndicator` in place of the button.
- On success: green `SnackBar` + `Navigator.pop()`.

#### Special Behaviors
- **Floor field:** Only shown for certain property types (apartments, duplexes, offices, etc.) — hidden for villas and land.
- **Installment fields:** Only shown when "Has Installment" toggle is ON.
- **Rental Frequency:** Only shown when listing type is "إيجار".
- **City dropdown:** Cascades from Governorate — resets when governorate changes.
- **Image management:** Supports adding new images (from device picker), removing existing (from server), and removing newly added images before saving.

---

### 4.6 Leads Management Screen

**File:** `lib/features/leads/screens/leads_management_screen.dart`

#### Layout
- AppBar: "إدارة العملاء" — style `h2`, centered, white background, no elevation.
- Background: `bgMain` (`#F8F9FA`).
- Body: `Column`:
  ```
  ┌──────────────────────────────────────┐
  │ LeadTopActionsBar                    │
  │ [+ Add Button] [Filter Chips Row]    │
  ├──────────────────────────────────────┤
  │ ListView of LeadCard widgets         │
  │ (Infinite Scroll + Pull-to-Refresh)  │
  └──────────────────────────────────────┘
  ```

#### `LeadTopActionsBar`
- An "Add New Lead" button on the right.
- A horizontally scrollable row of filter chips:
  `الكل` | `جديد` | `تم التواصل` | `تفاوض` | `تم التعاقد` | `مستبعد`
- Active filter chip has colored background; inactive has neutral style.

#### Interactions
- **Add button:** Opens `LeadFormScreen` (Add mode).
- **Filter chip tap:** Calls `_cubit.filterLeads(filter)` — filters the local list without a new network call.
- **LeadCard tap:** Opens `LeadDetailsScreen`.
- **LeadCard edit button:** Opens `LeadFormScreen` (Edit mode).
- **LeadCard delete button:** Shows `LeadDeleteDialog`, on confirm calls `_cubit.deleteLead(id)`.
- **Scroll to bottom:** Triggers `loadMoreLeads()`.
- **Pull-to-refresh:** Calls `getAllLeads(isRefresh: true)`.
- **Empty state:** Shows `LeadEmptyState` widget (likely an illustration + message).

#### Role-Based Data
- **Admin:** Sees all leads from all agents.
- **Agent:** Sees only their own assigned leads.

---

### 4.7 Lead Details Screen

**File:** `lib/features/leads/screens/lead_details_screen.dart`

#### Layout
- AppBar: "تفاصيل العميل" — style `h2`, centered. Back icon: `arrow_back_ios_new` in `brandPrimary` color.
- Background: `bgMain`.
- Body: `SingleChildScrollView` with `padding: 16.w`.

#### Sections (top to bottom)
1. **`LeadHeaderCard`** — A prominent card at top showing:
   - Client avatar/initials
   - Client name (large)
   - Current pipeline status badge (color-coded per status)
   - Communication channel icon+label
2. **"المعلومات الأساسية" (Basic Info)**
   - `LeadCopyableField` for: Full Name
   - Multiple `LeadCopyableField` rows for phones (labeled "تيلفون 1", "تيلفون 2", etc.)
3. **"تفاصيل الطلب" (Request Details)**
   - City, Communication Channel, Property Code of Interest, Source
4. **"وصف الاحتياج" (Need Description)** — Only shown if `descLeadNeed` is not empty.
5. **"ملاحظات الموظف" (Staff Notes)** — Only shown if `comment` is not empty.
6. **Footer:** Creation date at bottom center — format `yyyy/MM/dd - hh:mm a`, 60% opacity, 11sp.

#### `LeadCopyableField` Behavior
Similar to PropertyCopyableField — label + value with a copy icon. Designed for easy sharing of contact information.

#### `LeadPipelineIndicator`
A visual horizontal pipeline showing all statuses, with the current one highlighted — gives at-a-glance stage awareness.

---

### 4.8 Lead Form Screen (Add / Edit)

**File:** `lib/features/leads/screens/lead_form_screen.dart`

#### Layout
- AppBar: "إضافة عميل جديد" or "تعديل بيانات عميل" — style `h2`, centered.
- Body: `Form` in `SingleChildScrollView` with `padding: 16.w`.
- Organized into **3 logical section widgets:**

#### Section 1 — `ClientBasicSection` (Client Identity)
- **Client Name** text field (required)
- **Phone Numbers** — Dynamic list of text fields:
  - Minimum 1 phone field, can add more via an "Add Phone" button.
  - Each added phone has a remove icon next to it.
  - On add: `setState(() => _phoneControllers.add(...))`.
  - On remove: `setState(() => _phoneControllers.removeAt(idx))`.

#### Section 2 — `ClientRequirementsSection` (Request Details)
- **Property Code** of interest (text field)
- **Source** of the lead (text field)
- **Need Description** (multi-line text area)
- **Communication Channel** — SegmentedButton or DropdownButton with options:
  `مكالمة هاتفية` | `واتساب` | `مسنجر` | `زيارة مقر`

#### Section 3 — `ClientAdminSection` (Admin / Assignment)
- **City** — `DropdownButton` populated from `cities.json` asset (loaded async).
- **Lead Status** — `DropdownButton` with values:
  `جديد` | `تم التواصل` | `تفاوض` | `تم التعاقد` | `مستبعد`
- **Comment / Staff Notes** (multi-line text area)

#### Submit Button
- Full width, height 54.h, background `brandPrimary`.
- Add mode: "حفظ العميل الجديد"
- Edit mode: "تحديث بيانات العميل"
- While loading: Inline `CircularProgressIndicator(strokeWidth: 2)` in button.

---

### 4.9 Designs List Screen

**File:** `lib/features/designs/screens/designs_list_screen.dart`

> ⚠️ **Status: Stub / Early Stage.** The screen file exists but has a very minimal implementation (only 272 bytes). It is a placeholder for a future designs management feature.

Related screens exist: `add_design_screen.dart`, `edit_design_screen.dart`, `design_details_screen.dart`.
Related widgets: `design_form.dart`, `design_images_section.dart`.

**Intended Purpose:** Manage interior design projects with images (similar to properties but focused on design work portfolio).

---

### 4.10 Accounts Management Screen (Admin Only)

**File:** `lib/features/auth/screens/accounts_management_screen.dart`

> ⚠️ **Status: Stub.** The screen is only 293 bytes — essentially an empty placeholder. It is only injected into the page list for users with `role == 'admin'`.

**Intended Purpose:** Allow admins to create, view, and manage CRM user accounts (agents).

---

## 5. Reusable Core Widgets

All located in `lib/core/widgets/`. These must be ported to or reused in the mobile app.

---

### 5.1 `CustomButton`
**File:** `lib/core/widgets/custom_button.dart`

A fully configurable button container using `InkWell` (not `ElevatedButton`).

**Parameters:**
| Param | Type | Default | Description |
|---|---|---|---|
| `title` | String | required | Button label text |
| `isCenter` | bool | required | Center or left-align content |
| `onTap` | VoidCallback? | null | Tap handler |
| `buttonWidth` | double? | `double.infinity` | Width |
| `buttonHeight` | double? | `50` | Height |
| `buttonColor` | Color? | white | Background color |
| `buttonBorderRad` | double? | `15` | Corner radius |
| `buttonBorderColor` | Color? | `primaryBlueDark` | Border color |
| `borderWidth` | double? | `2` | Border stroke width |
| `icon` | Widget? | null | Leading icon widget |
| `titleSize` | double? | — | Font size |
| `titleColor` | Color? | — | Font color |
| `titleWeight` | FontWeight? | — | Font weight |

**Visual:** White container with blue border and a soft drop shadow by default. Pass `buttonColor: primaryBlueDark` and `titleColor: white` for solid primary style (as used in Login screen).

---

### 5.2 `CustomTextFormField`
**File:** `lib/core/widgets/custom_text_form_field.dart`

A fully configurable `TextFormField` with support for prefix/suffix icons and custom border colors.

**Parameters:**
| Param | Type | Default | Description |
|---|---|---|---|
| `labelText` | String | required | The floating label |
| `controller` | TextEditingController | required | — |
| `obscureText` | bool | required | Password masking |
| `validator` | Function | required | Validation function |
| `enabledBorderColor` | Color | required | Border color when idle |
| `focusedBorderColor` | Color | required | Border color on focus |
| `filledColor` | Color? | white | Background fill |
| `maxLines` | int? | 1 | For multi-line text areas |
| `prefixIcon` | IconData? | null | Left icon |
| `prefixIconColor` | Color? | — | — |
| `prefixIconSize` | double? | — | — |
| `suffixIcon` | IconData? | null | Right icon |
| `suffixIconColor` | Color? | — | — |
| `onTabSuffix` | VoidCallback? | null | Suffix icon tap (e.g., toggle visibility) |
| `borderRad` | double? | `14` | Border corner radius |

**Theme:** The global `AppTheme` sets `InputDecorationTheme` with `OutlineInputBorder`, `r8` radius, `bgSurface` fill. The `CustomTextFormField` overrides these as needed per usage.

---

### 5.3 `CustomSearchBar`
**File:** `lib/core/widgets/custom_search_bar.dart`

A search row widget combining a text input and a filter button.

**Structure:**
```
[🔍 TextField (flex: 10)] [Filters button (flex: 1)]
```
- TextField: Rounded (radius 20), white fill, hint "Search...", prefix search icon.
- Filter button: Outlined style, black foreground, `Icons.filter_list`, label "Filters".
- Currently a static shell — no callback props (to be connected to state management).

---

### 5.4 `FormToggleTile`
**File:** `lib/core/widgets/form_toggle_tile.dart`

A premium replacement for the default `SwitchListTile`. Used throughout property and lead forms.

**Visual States:**
- **OFF:** White background, `borderSubtle` border (1px), muted icon color.
- **ON:** `activeColor.withOpacity(0.06)` background, colored border (1.5px), colored icon and bold text.

**Parameters:**
| Param | Type | Description |
|---|---|---|
| `title` | String | Main label |
| `subtitle` | String? | Optional sub-label (shown below title) |
| `icon` | IconData? | Optional leading icon |
| `value` | bool | Current toggle state |
| `onChanged` | ValueChanged\<bool\> | State change callback |
| `activeColor` | Color? | Default: `brandPrimary` |

**Animation:** `AnimatedContainer` with 200ms duration for smooth color transitions.

---

### 5.5 `UserAvatar` (Sidebar)
**File:** `lib/features/layout/widgets/user_avatar.dart`

Displays the logged-in user's profile in the sidebar.

**Structure:**
- `CircleAvatar` (radius 28.r, `primaryBlue` background):
  - If no image: Shows uppercase first letter of first name.
  - If image URL exists: `CachedNetworkImage` with `PropertyCacheManager`.
- User full name (white, 16sp, overflow ellipsis).
- Role badge: Small pill container (`success.withOpacity(0.2)` background, green border, uppercase role text).

---

### 5.6 `LeadCard`
**File:** `lib/features/leads/widgets/lead_card.dart`

The primary list item for the Leads Management screen.

**Structure (Row, RTL-aware):**
```
[Edit/Delete buttons column] [Client info (Expanded)] [Status badge + Date column]
```
- **Card:** `elevation: 0`, `borderSubtle` border, `r12` radius, white background.
- **Edit button:** Blue tinted container (`info.withOpacity(0.1)`), `edit_rounded` icon in `info` color.
- **Delete button:** Red tinted container (`brandAccent.withOpacity(0.1)`), `delete_outline_rounded` in `brandAccent`.
- **Client info:** Name (`cardTitle`, ellipsis), Property code with home icon, City with location icon (`info` color).
- **Status badge:** Colored pill with status text using the Lead Status color mapping.
- **Date:** `tableCellSub` style, 10sp, format `yyyy/MM/dd`.

---

### 5.7 `PropertyCard`
**File:** `lib/features/properties/widgets/property_card.dart`

The primary list item for the Properties List screen.

**Structure (Row):**
```
[Image Stack (300w × 200h)] [Property Data (Expanded)] [Edit/Delete buttons column]
```
- **Container:** White, `r12`, subtle border, soft shadow (`0.04` opacity).
- **Image:** `CachedNetworkImage` with rounded corners, fallback to broken-image icon. Stack overlay shows a **status badge** (green "نشط" / red "مغلق").
- **Data column:**
  - Row: Listing Type - Property Type (`primaryBlue`, 11sp) | Short ID (`tableCellSub`, 9sp)
  - Price with EGP suffix (17sp, w800, `primaryBlueDark`)
  - Location: red location icon + "City - Region"
  - Features row: bed icon + count, bath icon + count, area icon + m²
- **Action buttons:** Same style as LeadCard — blue for edit, red for delete.

---

## 6. Web-to-Mobile Adaptation Strategy

This section guides the transformation of Web-specific patterns into native mobile UX patterns.

---

### 6.1 Global Navigation: Sidebar → Drawer + Bottom Navigation Bar

**Web Pattern:** Fixed left sidebar (280px) always visible.

**Mobile Pattern:** Use a **combination approach**:
- **`Drawer`** (slide-in from left) for the full sidebar with logo, user avatar, and all nav items.
- **`BottomNavigationBar`** with icons only (no labels, or short labels) for quick switching between the 4 primary sections:
  - Dashboard (analytics icon)
  - Properties (home_work icon)
  - Leads (person_search icon)
  - Designs (format_paint icon)
- The Accounts page (admin-only) remains accessible via the Drawer.
- The hamburger menu icon in the `AppBar` opens the Drawer.

---

### 6.2 Top Header → Standard AppBar

**Web Pattern:** A custom `TopHeader` widget (90px tall) with page title + action icons on the right.

**Mobile Pattern:** Use Flutter's built-in `AppBar`:
- `title`: Dynamic page title (from `LayoutCubit` state)
- `leading`: Hamburger icon → opens `Drawer`
- `actions`: Retain the search, notifications, settings icons (they become more compact)
- The username text can be removed from the AppBar (it already appears in the Drawer's UserAvatar).

---

### 6.3 Properties & Leads Lists

**Web Pattern:** `ListView` of rich horizontal cards with large image + inline action buttons, designed for wide screens.

**Mobile Pattern (Option A — Cards):**
- Reuse `LeadCard` and `PropertyCard` as-is but constrain widths to screen width.
- The `PropertyCard` image should be reduced (e.g., `100.w × 100.h` thumbnail) or moved above the text in a vertical layout.
- Action buttons (edit/delete) can move to a swipe-to-reveal gesture (`Dismissible` widget) or a trailing `PopupMenuButton`.

**Mobile Pattern (Option B — ListTile):**
- For `LeadCard`: Convert to a `ListTile` with the status chip as `trailing`, name as `title`, city+phone as `subtitle`.
- For `PropertyCard`: Use a vertical card layout (image on top, details below) — similar to real estate apps.

---

### 6.4 Property Form (7-Section)

**Web Pattern:** All 7 `PropertyFormCard` sections scroll vertically on one page.

**Mobile Pattern:** Keep the same single-scroll approach — it works well on mobile too. The `PropertyFormCard` collapsible cards are ideal for mobile because users can collapse sections they've already filled.

**Adaptation tips:**
- All `TextFormField` widths are `double.infinity` — perfect for mobile.
- The image grid inside `ImageSection` should use a 3-column `GridView` (instead of horizontal scroll).
- The date picker can use `showDatePicker` dialog — same as web.

---

### 6.5 Details Screens (Lead & Property)

**Web Pattern:** Single scrollable column with section cards.

**Mobile Pattern:** **No change needed** — these screens are already built in a mobile-friendly scroll pattern. They will work on mobile with minimal layout changes:
- `PropertyImageHeader` can become a full-width `PageView` image carousel with dot indicators.
- `PropertySectionCard` and section titles render naturally at mobile widths.

---

### 6.6 Login Screen

**Web Pattern:** Centered card with fixed `width: 450`.

**Mobile Pattern:**
- Remove the fixed width — use `width: double.infinity` with horizontal padding `24.w`.
- Remove the `BoxShadow` (or keep subtle).
- The form fields and button already use `double.infinity` width — ideal for mobile.

---

### 6.7 Responsive Sizing

**Web ScreenUtil Reference:** `1920×1080`

When creating the mobile app, reinitialize ScreenUtil with a mobile design reference:
```dart
ScreenUtilInit(
  designSize: const Size(390, 844), // iPhone 14 reference
  minTextAdapt: true,
  splitScreenMode: true,
  ...
)
```
All the `.sp`, `.w`, `.h`, `.r` responsive values will automatically re-scale to the new reference.

---

### 6.8 Component Conversion Summary

| Web Component | Mobile Equivalent | Notes |
|---|---|---|
| Fixed Sidebar (280px) | `Drawer` + `BottomNavigationBar` | Admin nav items in Drawer only |
| `TopHeader` widget | `AppBar` | Keep action icons |
| `PageView` (no physics) | `PageView` or `IndexedStack` | Same pattern |
| Horizontal `PropertyCard` | Vertical card or ListTile | Reduce image size |
| 7-section `PropertyFormCard` | Same (collapsible cards scroll) | Works as-is |
| `CustomSearchBar` with Filter button | `SearchBar` + `FilterChip` row | Same logic |
| `LeadTopActionsBar` filter chips | `SingleChildScrollView` + `FilterChip` | Same component |
| `UserAvatar` in Sidebar | `DrawerHeader` with same widget | Direct reuse |
| `LogoutButton` in Sidebar | `ListTile` at bottom of Drawer | Direct reuse |
| `ResponsiveDebouncerWrapper` | Not needed | Mobile doesn't have window resize |
| `minDesktopWidth: 1100` constraint | Remove entirely | Mobile is always < 600px |

---

## Appendix: Data Models Referenced

### `ProfileModel` (User)
Key fields: `id`, `firstName`, `lastName`, `email`, `role` (`'admin'` or `'agent'`), `imageUrl`.

### `LeadModel`
Key fields: `id`, `clientName`, `clientPhone` (List\<String\>), `city`, `leadStatus`, `propertyCode`, `source`, `communicationChannel`, `descLeadNeed`, `comment`, `createdBy`, `assignedTo`, `createdAt`.

### `PropertyModel`
Key fields: `id`, `propertyCode`, `status` (bool: active/closed), `titleAr`, `descAr`, `listingTypeAr` (بيع/إيجار), `propertyTypeAr`, `governorateAr`, `cityAr`, `regionAr`, `locationInDetails`, `price`, `negotiable`, `hasInstallment`, `downPayment`, `monthlyInstallation`, `builtArea`, `bedrooms`, `bathrooms`, `ownerName`, `ownerPhone`, `images` (List\<PropertyImageModel\>), `createdBy`.

### `PropertyImageModel`
Key fields: `url` (full URL), `thumbnail` (optimized URL for list display).

---

*Generated by AI analysis of `lib/` source code — Retaj CRM Flutter Web Project.*
*Date: 2026-03-11*
