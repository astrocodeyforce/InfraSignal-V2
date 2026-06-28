# InfraSignal — Users, Roles & Access Control

This document explains who can do what in InfraSignal: the kinds of users, the
permissions that exist, the standard roles, which admin sections each unlocks,
and the exact steps to grant access. It also spells out the hard boundaries that
keep one government body from ever seeing or touching another.

> TL;DR
> - There are exactly **two kinds of account**: the platform **Superuser**, and
>   **body staff** (anyone with a "body" assigned).
> - A body staff member can do nothing until they are given a **role** (or
>   individual permissions). Roles/permissions are always scoped to **their own
>   body only**.
> - **Superuser = whole platform.** Body staff = **their one body, period.**
> - Roles and permissions are **data**, not code — they must be set up
>   separately in each environment (dev / staging / production).

---

## 1. The mental model

Every account is defined by two flags:

| Flag | Meaning | Who sets it |
| --- | --- | --- |
| `is_superuser` | Platform owner. Sees and controls **everything**, across all bodies. | Only another superuser. |
| `from_body` | The single government body (city/county/state) this person works for. | A superuser, or a body admin (for their own body only). |

From these two flags everything else follows:

- **Superuser** (`is_superuser = true`): full platform access. Not limited by
  permissions or roles.
- **Body staff** (`from_body` set, `is_superuser = false`): can reach the admin,
  but only sees their **own body's** data, and only the sections their
  role/permissions unlock.
- **Citizen** (neither flag): a normal public reporter. No admin access (gets a
  403 if they try).

A staff member's power comes from **permissions**, which are granted in bundles
called **roles**.

---

## 2. The permission catalog

These are the individual permissions that can be assigned (grouped as they
appear in the admin). Each one, when held by body staff, applies **only to their
own body**.

### Problems
| Permission | What it allows |
| --- | --- |
| `report_inspect` | Inspect / mark up report details (the core triage permission). |
| `report_edit` | Full edit of a report (incl. category, location). |
| `report_mark_private` | View and mark reports private. |
| `moderate` | Moderate report details (hide offensive content, edit text). |
| `report_edit_category` / `report_edit_priority` | Change a report's category / priority. |
| `report_instruct` | Instruct contractors to fix problems. |
| `report_prefill` | Auto-populate report subject/detail. |
| `planned_reports` | Manage the shortlist of planned work. |
| `assign_report_to_user` | Assign reports to a staff member. |
| `contribute_as_body` | Post reports/updates as the council. |
| `default_to_body` | Default new reports/updates to being "as the council". |
| `contribute_as_another_user` | Create reports/updates on a user's behalf. |
| `view_body_contribute_details` | See user details on council-created reports. |

### Users
| Permission | What it allows |
| --- | --- |
| `user_edit` | Edit users / search their reports. **This is what unlocks the Users + Roles admin sections.** |
| `user_manage_permissions` | Edit other users' permissions and roles. |
| `user_assign_body` | Grant admin access (assign a user to the body). |

### Bodies
| Permission | What it allows |
| --- | --- |
| `category_edit` | Add/edit the body's service categories and contact/email routing (also unlocks Report Extra Fields). |
| `template_edit` | Add/edit response templates. |
| `responsepriority_edit` | Add/edit response priorities. |
| `emergency_message_edit` | Add/edit the body's site / emergency banner message. |

> Note: `user_edit`, `user_manage_permissions` and `user_assign_body` are
> powerful — together they let a person manage other staff. They are still
> strictly body-scoped (see §6), but only hand them to someone trusted.

---

## 3. The standard roles

Each body has its own copy of these five roles. A role is just a named bundle of
permissions. Assign a role to a staff member and they get everything in it.

| Role | Purpose | Permissions |
| --- | --- | --- |
| **Body Manager** | Runs the whole body independently — operations **and** setup, including managing their own staff. The "government admin". | report_inspect, report_mark_private, moderate, assign_report_to_user, planned_reports, contribute_as_body, default_to_body, view_body_contribute_details, **template_edit, responsepriority_edit, category_edit, emergency_message_edit**, **user_edit, user_assign_body, user_manage_permissions** |
| **Account Admin** | A narrower "HR" profile: manage staff accounts only, no operational tools. | user_edit, user_assign_body, user_manage_permissions |
| **Inspector** | Field/triage staff: look at and triage reports. | report_inspect, planned_reports, report_mark_private |
| **Customer Service** | Front-desk: log reports/updates on behalf of citizens. | contribute_as_another_user, contribute_as_body, view_body_contribute_details |
| **Auth** | Default broad operations role (everything operational, but **no** user management). | category_edit, emergency_message_edit, responsepriority_edit, template_edit, assign_report_to_user, contribute_as_body, default_to_body, moderate, planned_reports, report_edit_category, report_edit_priority, report_inspect, report_instruct, report_mark_private, report_prefill, view_body_contribute_details |

**Which role to give whom**
- One trusted person per government → **Body Manager** (they can then create and
  manage everyone else for their body themselves).
- Someone who only manages accounts, not reports → **Account Admin**.
- Day-to-day report handlers → **Inspector** (or **Auth** for fuller operations).
- Call-center / front desk → **Customer Service**.

---

## 4. Admin sections → who sees them

What appears in the left admin sidebar is driven by permissions. This is the map:

| Admin section | Requires | Body Manager? | Superuser? |
| --- | --- | --- | --- |
| Summary (dashboard) | any admin access | ✅ (own body) | ✅ (platform) |
| Reports | `report_edit` **or** `user_edit` | ✅ (own body) | ✅ (all) |
| Duplicate Reports | `report_inspect` | ✅ (own body) | ✅ (all) |
| Priority Zones | `report_inspect` | ✅ (own body overrides) | ✅ (global) |
| Templates | `template_edit` | ✅ | ✅ |
| Priorities | `responsepriority_edit` | ✅ (own body, no state picker) | ✅ (state/body picker) |
| Categories / Bodies | `category_edit` | ✅ (own body only) | ✅ (all 28k bodies) |
| Report Extra Fields | `category_edit` | ✅ | ✅ |
| Site message | `emergency_message_edit` | ✅ (own body) | ✅ (any body) |
| Users | `user_edit` | ✅ (own body staff) | ✅ (everyone) |
| Roles | `user_edit` | ✅ (own body roles) | ✅ (all) |
| **Stats** (whole-system) | **superuser only** | ❌ | ✅ |
| **Timeline** (whole-system) | **superuser only** | ❌ | ✅ |
| **Configuration, States, Manifest Theme, Flagged, User Import** | **superuser only** | ❌ | ✅ |

With the standard Body Manager role this comes to **10 admin sections**, all
confined to the manager's own body.

---

## 5. How to give access (step by step)

### Grant a role to an existing staff member
1. Log in as a **superuser** or a **Body Manager / Account Admin** of that body.
2. Go to **Admin → Users**.
3. Find the person (use search). Open their account.
4. Under **Roles**, tick the role(s) to grant (e.g. *Inspector*).
   - Roles take precedence over individual permission checkboxes.
5. Save. The change takes effect on their next page load.

### Create a brand-new staff account
1. **Admin → Users → Add user**.
2. Enter name + email, tick **email verified**.
3. For a Body Manager/Account Admin the **body is locked to their own** and set
   automatically. (A superuser may choose any body.)
4. Save, then open the new user and assign a **role** as above.

### Promote someone to "government admin" for their body
- Give them the **Body Manager** role. They can then create and manage the rest
  of their body's staff without any platform involvement.

### Bulk-assign on the Users list
- On **Admin → Users**, select people with the checkboxes and choose roles, or
  use **Remove staff**. For body admins this only affects **their own body's**
  users and **their own body's** roles.

> Tip: prefer **roles** over hand-picking individual permission checkboxes —
> roles are consistent, auditable, and easier to reason about.

---

## 6. Hard boundaries (what body staff can NEVER do)

These are enforced server-side and verified by automated tests — not just hidden
in the UI:

- **No cross-body visibility.** Reports, the Summary queue, charts, the Users
  list, dropdowns — all filtered to the staff member's own body. They never see
  another body's data.
- **No whole-system stats.** Stats and Timeline are superuser-only (404 for
  staff, even by direct URL).
- **Cannot create or become a superuser.** The `is_superuser` flag is ignored on
  any add/edit a non-superuser submits.
- **Cannot move users between bodies.** A staff-submitted body value is forced to
  their own body (or cleared).
- **Cannot manage another body's accounts.** They can't open, edit, role-assign,
  or remove-staff a user belonging to another body — or a superuser — even via a
  crafted request (returns 404 / silently no-ops).
- **Cannot edit another body's categories, site message, or priorities.**
  (403 / redirected to their own body.)
- **Cannot assign another body's roles** to their users.

Tested across two independent bodies (Buffalo Grove + Raleigh) with cross-body
attacks in both directions — 32/32 checks pass. See `CHANGELOG.md`
(Jun 11, 2026 entries) for the audit detail.

---

## 7. Superuser-only capabilities

Reserved for the platform owner; never delegated to a government body:

- Global **Configuration**, **States**, **Manifest Theme**
- Platform-wide **Bodies** list (all ~28k organizations)
- Whole-system **Stats** and **Timeline**
- **Flagged** content review and bulk **User Import**
- Creating other **superusers**
- Any action that crosses bodies

---

## 8. Test accounts (dev environment)

Two fully isolated government profiles are set up on **dev** for testing:

| Role | Buffalo Grove, IL (body 10588) | Raleigh, NC (body 24482) |
| --- | --- | --- |
| Body Manager | `staff-demo@buffalogrove.test` / `BGstaff-demo-2026!` | `staff-demo@raleigh.test` / `RALstaff-demo-2026!` |
| Account Admin | `acct-admin@buffalogrove.test` / `BGacct-admin-2026!` | `acct-admin@raleigh.test` / `RALacct-admin-2026!` |
| Superuser | `admin@infrasignal.dev` / `InfraSignalDev!2026` | (same — platform-wide) |

> These are **dev-only demo credentials**. Do not reuse these passwords in
> staging or production.

---

## 9. Applying this to staging / production

Roles and user accounts are **database data**, so they do **not** travel with a
`git` deploy. The *code* that enforces scoping deploys normally, but to make a
body self-sufficient in another environment you must, in that environment:

1. Ensure the five standard roles exist for the body (name + permissions).
2. Create the staff accounts and assign roles.
3. Use strong, environment-specific passwords (never the dev demo ones).

When you're ready to set up real governments on staging/production, do it there
explicitly rather than copying the dev demo data.

---

## 10. Where this lives in the code (for engineers)

| Concern | File |
| --- | --- |
| Who may reach `/admin`; which pages show; Stats/Timeline hidden for staff | `perllib/FixMyStreet/Cobrand/Infrasignal.pm` (`admin_allow_user`, `admin_pages`) |
| Staff Users list & user query scoping to own body | `perllib/FixMyStreet/Cobrand/Infrasignal.pm` (`users_staff_admin`, `users_restriction`) |
| User add/edit + bulk POST hardening (no superuser, own-body only, role validation) | `perllib/FixMyStreet/App/Controller/Admin/Users.pm` |
| Summary dashboard + Reports search body-scoping helper | `perllib/FixMyStreet/App/Controller/Admin.pm` (`_scope_to_staff_body`), `.../Admin/Reports.pm` |
| Duplicate Reports / Priority Zones body-scoping | `.../Admin/DuplicateReports.pm`, `.../Admin/PriorityZones.pm` |
| Permission catalog & default page→permission map | `perllib/FixMyStreet/Cobrand/Default.pm` (`available_permissions`, `admin_pages`) |

---
*Last updated: Jun 17, 2026. Keep this in sync with `CHANGELOG.md` when the
permission model changes.*
