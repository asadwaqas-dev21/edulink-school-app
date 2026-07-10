# Edulink — LMS for Schools & Colleges

A cross-platform (Android, iOS, Web, Windows, macOS, Linux) Learning Management
System built with **Flutter + GetX + Supabase**. It supports four roles —
**Principal, Teacher, Student, Parent** — and covers both educational and
financial workflows.

## Product Requirements Document (PRD)

> **Document status:** Living document · **Product:** Edulink LMS · **Platforms:** Android, iOS, Web, Windows, macOS, Linux · **Currency:** PKR (Rs)

### 1. Overview

Edulink is a multi-tenant Learning Management System that digitizes the full lifecycle
of a school or college — academics, daily operations, finance, and communication — in a
single cross-platform app. Each **institute** is an isolated tenant with four roles
(Principal, Teacher, Student, Parent), and every user sees a role-specific dashboard.

### 2. Problem Statement

Educational institutes juggle disconnected tools: paper registers for attendance,
spreadsheets for fees and salaries, WhatsApp for announcements, and nothing that ties
academics to finances. Parents lack real-time visibility into their child's progress and
dues. Edulink replaces these silos with one unified, real-time system.

### 3. Goals & Objectives

- Provide a single source of truth for academics, attendance, finance, and communication.
- Give each role a focused, professional experience (dashboard-first on web/desktop).
- Make institute finances transparent end-to-end: **income (fees) and expenses (payroll, rent, utilities)** in one place.
- Ship a cross-platform product from a single Flutter codebase.

### 4. Success Metrics (KPIs)

- **Adoption:** % of an institute's teachers/students/parents active weekly.
- **Attendance digitization:** % of class-days with attendance marked in-app.
- **Fee collection:** collection rate (collected ÷ billed) and reduction in outstanding balance.
- **Financial visibility:** % of institute expenses logged vs. actual.
- **Engagement:** announcements read and messages exchanged per week.

### 5. Personas & Roles

| Role | Primary goals | Key capabilities |
| --- | --- | --- |
| **Principal / Admin** | Run the institute end-to-end | Create institute; manage people, classes, subjects, enrollments; issue fee slips; **manage all institute finances (income + expenses)**; broadcast announcements; view reports |
| **Teacher** | Deliver and assess learning | Manage assigned classes/subjects; upload lessons & materials; create assignments & quizzes; grade; mark attendance; manage timetable; announce; message |
| **Student** | Learn and stay on track | View courses/materials; submit assignments; take quizzes; view timetable & attendance; view/pay fees; message |
| **Parent** | Monitor their child | View linked children's attendance & progress; view/pay fees; read announcements; message teachers |

### 6. Scope

**In scope (implemented):** multi-role auth, institute setup, academics (classes/subjects/enrollments/parent-links), courses & content, assignments & quizzes, attendance & timetable, fees & multi-item printable fee slips, admin finance/expense management, announcements & 1:1 messaging, reports, web/desktop dashboard shell, global search, notifications.

**Out of scope (for now):** live online payment gateway, video conferencing, native push notifications, report-card/transcript PDFs, multi-institute users, offline mode.

### 7. Functional Requirements by Module

#### 7.1 Authentication & Roles
- Email/password sign-up and sign-in via Supabase Auth.
- A `profiles` row is auto-created on sign-up (trigger) with the chosen role.
- Role determines dashboard, navigation, and permitted actions.

#### 7.2 Institute & People
- Principal creates an institute and becomes its admin.
- Principal adds existing users (by account email) as Teacher/Student/Parent and assigns them to the institute.
- Parent↔child links connect guardians to students.

#### 7.3 Academics
- Classes/sections, subjects (with assigned teacher), and student enrollments.
- Teachers see only their assigned classes/subjects.

#### 7.4 Courses & Content
- Lessons with descriptions and optional video links.
- File materials uploaded to Supabase Storage; students view/download.

#### 7.5 Assessments
- Assignments with due dates, file submissions, grading and feedback.
- Quizzes with authored MCQs; students take them with automatic scoring.

#### 7.6 Attendance & Timetable
- Teachers mark daily attendance (present/absent/late/excused) per class.
- Weekly timetable per class; visible to students and parents.

#### 7.7 Fees & Fee Slips
- Principal issues invoices to students. **One fee slip can contain multiple expense line items** (description, quantity, unit price); the total is derived automatically.
- Students/parents view invoices and outstanding balances; payments are recorded with history and status (pending/partial/paid).
- **Printable fee slips**: any invoice can be rendered to a professional PDF and printed or saved (works on web, desktop, and mobile).
- All amounts are shown in **PKR (Rs)**.

#### 7.8 Finance Management (Admin only)
- A **Principal-only** module to manage the institute's money holistically.
- **Income view:** fees collected (jama) and fees pending/outstanding (receivable).
- **Expense tracking:** add/edit/delete manual expenses across categories — **teacher salary, staff salary, building rent, utilities, supplies, maintenance, transport, other** — each with amount, payee, date, note, and a Paid/Pending status.
- **Net position:** net balance in hand = fees collected − expenses paid, plus totals for spent and pending payouts.
- Enforced at the database level via RLS so only the owning institute's principal can access expenses.

#### 7.9 Communication
- Institute-wide announcements (by Principal/Teacher) with audience targeting.
- 1:1 direct messaging between users of the same institute.

#### 7.10 Reports & Dashboards
- Institute overview (students/teachers/parents/classes counts).
- Finance summary with collection rate; role-specific dashboard stats.

#### 7.11 Web / Desktop Experience
- Professional dashboard shell: branded collapsible sidebar, per-role navigation, and a user/profile section with theme toggle.
- A top bar with **global search** (find people and classes) and a **notifications** bell (recent announcements with an unseen badge).
- Content is centered/constrained and grids are responsive for large screens.

### 8. Non-Functional Requirements

- **Security:** Supabase Auth + Row Level Security; admin-only tables (expenses) restricted by role and institute.
- **Cross-platform:** single Flutter codebase for mobile, web, and desktop.
- **Responsive UI:** adaptive layouts (bottom nav on mobile, sidebar + top bar on web/desktop).
- **Performance:** list queries are institute-scoped, indexed on foreign keys, and paginated/limited where relevant (e.g., search).
- **Maintainability:** clean layering (domain / data / presentation) with GetX DI and repositories.
- **Localization-ready:** currency centralized in one formatter (PKR); date/number formatting via `intl`.

### 9. Technical Architecture

- **Frontend:** Flutter (Dart). State, DI, and routing via **GetX**. Theming with Material 3.
- **Backend (BaaS):** **Supabase** — PostgreSQL, Row Level Security, Auth, and Storage.
- **PDF/Printing:** `pdf` + `printing` packages generate and print/share fee slips on all platforms.
- **Data model:** normalized schema for institutes, profiles, classes, subjects, enrollments, parent-links, lessons, materials, assignments, submissions, quizzes/questions, attendance, timetable, invoices, **invoice_items**, payments, **expenses**, announcements, and messages. See `supabase/schema.sql`.

### 10. Assumptions & Dependencies

- Each user belongs to a single institute; the principal owns institute setup.
- A configured Supabase project (URL + anon key) is required to run.
- Email confirmation may be disabled in development for faster onboarding.

### 11. Future Roadmap

- Online payment gateway integration (e.g. Stripe) replacing manual `recordPayment`.
- Report cards / transcripts and printable attendance reports.
- Native push notifications and in-app notification center.
- Salary/payroll runs and recurring expense scheduling.
- Tighter, granular RLS policies per role/institute for production.

## Features

- **Auth & roles** — email/password sign up & sign in, role-based dashboards.
- **Academics** — institutes, classes/sections, subjects, enrollments,
  teacher assignment, parent-child linking.
- **Courses & content** — lessons, materials & video links, file uploads to
  Supabase Storage.
- **Assessments** — assignments (with file submissions & grading), quizzes
  (author questions, students take & auto-score).
- **Attendance & timetable** — daily attendance marking, weekly class schedule.
- **Fees & fee slips** — invoices with **multiple expense line items**, payments,
  outstanding balances, and **printable PDF fee slips** (web/desktop/mobile). All
  amounts in **PKR (Rs)**.
- **Finance management (admin only)** — track institute **income and expenses**
  (teacher/staff salaries, building rent, utilities, and manual entries), with
  add/edit/delete, Paid/Pending status, and a net-balance overview.
- **Communication** — announcements & 1:1 messaging.
- **Reports** — institute overview and finance collection dashboards.
- **Web/desktop dashboard** — professional sidebar shell, top-bar **global search**
  (people & classes) and **notifications**, responsive layouts, light/dark themes.

## Project structure

```
lib/
  app/            App widget, routes, bindings, session controller
  core/           Config (Supabase/env), theme, enums, utils, services (PDF/print)
  domain/         Entities (plain models)
  data/           Supabase repositories
  presentation/   Feature modules (view + controller) and global widgets
supabase/
  schema.sql      Database tables, trigger, RLS policies, storage buckets
```

## Setup

### 1. Generate platform folders

This repo ships the Dart source and config. Generate the native platform
scaffolding (this will NOT overwrite existing `lib/` or `pubspec.yaml`):

```bash
cd edulink
flutter create --platforms=android,ios,web,windows,macos,linux .
flutter pub get
```

### 2. Create a Supabase project

1. Go to https://supabase.com and create a new project.
2. Open **SQL Editor**, paste the contents of `supabase/schema.sql`, and run it.
3. In **Authentication -> Providers -> Email**, (optionally) disable
   "Confirm email" during development so sign-up logs you in immediately.

### 3. Configure your keys

Get your **Project URL** and **anon public key** from
**Project Settings -> API**, then either:

- Edit `lib/core/config/env.dart` and replace the placeholder values, **or**
- Pass them at runtime:

```bash
flutter run --dart-define=SUPABASE_URL=https://YOUR_REF.supabase.co \
            --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

### 4. Run

```bash
flutter run              # mobile / desktop
flutter run -d chrome    # web
```

## Getting started in the app

1. Register the **Principal** account first, open **Settings** (or the
   dashboard prompt) and **create your institute**.
2. Have teachers/students/parents register their own accounts, then the
   principal adds them from **People -> Add Member** (by their account email).
3. Create classes, add subjects (assign teachers), and enroll students.
4. Link parents to their children from **People** (Parents tab).

## Notes

- **RLS**: Most policies in `schema.sql` are permissive for authenticated users
  so the MVP works out of the box. The **`expenses`** table is an exception — it is
  restricted to the owning institute's principal. Harden the remaining policies
  per-role/per-institute before production.
- **Payments**: "Pay Now" records payments directly. Integrating a real gateway
  (e.g. Stripe) is a planned follow-up — swap the `recordPayment` call in
  `InvoiceDetailsScreen` for a gateway checkout, then record on success.
- **Currency**: All monetary values are formatted as **PKR (Rs)** via
  `Formatters.money` — change the default there to switch currency app-wide.
- **Fee slips**: Printing/exporting to PDF uses the `pdf` + `printing` packages
  (`lib/core/services/fee_slip_service.dart`).
#   e d u l i n k - s c h o o l - a p p 
 
 