# WelcomePath Demo - Spec Document

**Document Version:** 1.0
**Built On:** Open Demo Starter v2.0
**License:** MIT
**Accent Color:** `#3b82f6` (Trustworthy Blue) with `#d97706` (Warm Amber) secondary
**UX Pattern:** Form-then-result with a five-root visual map and a timed activity list

---

## 1. App Overview

WelcomePath Demo is a single-feature open source Rails 8 app that generates a complete 30-day onboarding path for a new member of a community. The user fills in four fields (community type, member type, member background, integration goal), submits, and Gemini returns a structured R.O.O.T.S. path: activities grouped under five root systems (Relationships, Orientation, Opportunities, Training, Stories), each tagged to a specific week (1 through 4), with a name, description, and estimated time.

**The problem this solves.** Most onboarding tools track checklist completion. Belonging does not come from completing forms; it comes from establishing roots. The R.O.O.T.S. framework ensures all five root systems are deliberately addressed in the first 30 days. This demo proves the path engine that sits at the heart of the larger product.

**Indie hacker angle.** This is one tool in a larger multi-tenant SaaS suite the author is building. The production version of WelcomePath is multi-tenant with team collaboration, member enrollment tracking across cohorts, guide assignments, integration assessments, and per-organization path libraries. This demo strips that down to the single most valuable action: generating a path. The full app is the engine; this demo is the spark.

**Scope of the demo.** Open source under MIT license. Scoped to a single signed-in user. Runs locally only. No multi-tenancy, no Stripe, no production deployment, no cohort management. One signed-in user can create, view, save, clone, and print paths.

---

## 2. Customizations Applied to the Boilerplate

The boilerplate ships clean. WelcomePath Demo applies a small, contained set of overrides:

- `.env.example` sets `APP_NAME=WelcomePath Demo`, `APP_TAGLINE=Welcome new members with a 30-day path that builds belonging, not just compliance.`, and `APP_DESCRIPTION` to a one-paragraph summary of the demo.
- `app/assets/stylesheets/_accent.scss` sets `--accent: #3b82f6` and `--accent-hover: #2563eb`. A second variable `--accent-secondary: #d97706` is added for the milestone and story-share amber accent.
- Five additional CSS custom properties for root-system color tagging are added (one hue per root) so each root reads consistently across the path show page.
- Navbar adds two links: `Paths` (path index) and `New Path` (path form). Admin link continues to render in the user dropdown only when `current_user.admin?`.
- `home/index.html.erb` is replaced with a marketing-lite landing pitch that explains R.O.O.T.S. in one paragraph and shows a sample five-root illustration.
- `dashboard/show.html.erb` is replaced with a path-oriented dashboard: a primary call to action (Create a New Path), a list of the most recent five paths, and a tip card explaining the framework.
- UX pattern: form-then-result. The form lives at `/paths/new`; the result page is the path show page with the five-root visual map and weekly activity panels.
- One AI template is seeded into `db/seeds.rb`: `welcomepath_path_v1`. Full content in Section 7.
- Two domain models are added: `OnboardingPath` and `PathActivity`. Full schema in Section 3.

The boilerplate's authentication, layout shell, admin panel, AI service, gatekeeper, budget checker, request log, and RSpec setup are inherited unchanged.

---

## 3. Data Model

Two new domain models. Both belong to a user; all queries scope to `current_user`.

### OnboardingPath

| Field | Type | Notes |
|---|---|---|
| `id` | uuid | Primary key |
| `user_id` | uuid | Foreign key. `belongs_to :user` |
| `name` | string | Generated as `"#{member_type} path for #{community_type}"`; user-editable after generation |
| `community_type` | string | **(template variable)** One of: faith community, nonprofit, workplace, coworking space, professional network |
| `member_type` | string | **(template variable)** One of: newcomer, new hire, new family, new cohort student |
| `member_background` | text | **(template variable)** Free-form summary, max 1500 chars |
| `integration_goal` | text | **(template variable)** One sentence, max 300 chars |
| `gemini_raw` | text | **(Gemini output, used for Show raw response toggle)** Full JSON response stored verbatim |
| `created_at` | datetime | |
| `updated_at` | datetime | |

**Validations:**
- `community_type`, `member_type`, `member_background`, `integration_goal` all `presence: true`
- `community_type` and `member_type` validated against an enum-like inclusion list
- `member_background` length 20 to 1500
- `integration_goal` length 10 to 300

**Associations:**
- `belongs_to :user`
- `has_many :path_activities, dependent: :destroy`

**Helper methods:**
- `activities_by_root` returns a hash keyed on root system name with an array of activities, used by the show view
- `activities_by_week` returns a hash keyed on week number (1 through 4) with an array of activities, used by the show view's weekly panels

### PathActivity

| Field | Type | Notes |
|---|---|---|
| `id` | uuid | Primary key |
| `onboarding_path_id` | uuid | Foreign key |
| `root_system` | string | One of: relationships, orientation, opportunities, training, stories |
| `name` | string | Short activity title, max 120 chars |
| `description` | text | One-to-three sentence description of the activity |
| `estimated_minutes` | integer | Time the new member will spend on this activity |
| `week_number` | integer | 1, 2, 3, or 4 |
| `position` | integer | Display order within its root system, used to keep activities sorted |
| `created_at` | datetime | |
| `updated_at` | datetime | |

**Validations:**
- `root_system` inclusion in the five allowed values
- `name`, `description`, `estimated_minutes`, `week_number` all `presence: true`
- `week_number` inclusion 1 through 4
- `estimated_minutes` numericality, greater than 0, less than or equal to 240

**Associations:**
- `belongs_to :onboarding_path`
- `has_one :user, through: :onboarding_path`

**Indexes:**
- Composite index on `[onboarding_path_id, root_system, position]` for fast tab rendering
- Index on `[onboarding_path_id, week_number]` for fast week-panel rendering

The `User`, `AiTemplate`, and `LlmRequest` models are inherited from the boilerplate and are not redescribed here.

---

## 4. Routes

All routes return HTML. The path generation endpoint returns a Turbo Stream that swaps in the result.

| Verb | Path | Controller#Action | Purpose |
|---|---|---|---|
| GET | `/` | `home#index` | Override: marketing-lite landing pitch with R.O.O.T.S. explanation |
| GET | `/dashboard` | `dashboard#show` | Override: recent paths list, primary call to action, framework tip |
| GET | `/paths` | `paths#index` | List of all paths for the signed-in user, newest first |
| GET | `/paths/new` | `paths#new` | The four-field generation form |
| POST | `/paths` | `paths#create` | Triggers `GeminiService.generate(template: "welcomepath_path_v1", ...)`, persists OnboardingPath and child PathActivities, redirects to show |
| GET | `/paths/:id` | `paths#show` | Five-root visual map, weekly activity panels, Show raw response toggle, Print button |
| GET | `/paths/:id/edit` | `paths#edit` | Edit the path name and integration goal (does not regenerate AI) |
| PATCH | `/paths/:id` | `paths#update` | Save edits |
| DELETE | `/paths/:id` | `paths#destroy` | Destroy path and its activities |
| POST | `/paths/:id/clone` | `paths#clone` | Duplicate the path and its activities under the same user; redirect to show on the clone |
| GET | `/paths/:id/print` | `paths#print` | Renders a printer-friendly view (clean layout, no nav, no footer) |

Auth routes (`/sign_up`, `/sign_in`, `/passwords`) and admin routes (`/admin/*`) come from the boilerplate.

---

## 5. Controllers and Actions

### `PathsController`

Inherits from `ApplicationController`, which already requires authentication and exposes `current_user`. All actions scope queries with `current_user.onboarding_paths`. Strong parameters: `path_params` permits `name`, `community_type`, `member_type`, `member_background`, `integration_goal`.

- `index`: Renders the most recent paths for `current_user`, ordered by `created_at desc`. Shows an empty state with a call to action when the list is empty.
- `new`: Renders the four-field generation form. Pre-fills `community_type` and `member_type` with sensible defaults if a path was previously created.
- `create`: This is the action that triggers the AI call. Builds an `OnboardingPath` for `current_user` from `path_params`, validates it, then calls `GeminiService.generate(template: "welcomepath_path_v1", variables: { community_type:, member_type:, member_background:, integration_goal: })`. On success, parses the JSON response, persists `gemini_raw`, builds the child `PathActivity` records inside a transaction, and redirects to the show page. On any `GeminiService::GeminiError`, re-renders the form with the boilerplate's friendly inline error partial and a retry button.
- `show`: Loads the path with its activities, groups them with the helper methods on the model, and renders the five-root visual map and the weekly panels.
- `edit`: Renders a small form for the path's name and integration goal only. Does not allow editing the four AI inputs after generation; users who want a different path clone or create a new one.
- `update`: Saves edits and redirects to show.
- `destroy`: Destroys the path and its activities; cascade is handled by `dependent: :destroy`. Redirects to the index with a flash.
- `clone`: Inside a transaction, duplicates the path (appending " (copy)" to the name) and copies all of its activities. Redirects to the new path's show.
- `print`: Renders the path under a `print` layout (no navbar, no footer, larger print-friendly typography, page-break CSS rules between week panels).

### `HomeController`, `DashboardController`

Both override the boilerplate templates only at the view level. The controllers themselves stay as the boilerplate provides them.

`ApplicationController`, `Admin::*Controller`, `SessionsController`, `RegistrationsController`, `PasswordsController`, and `HealthController` are inherited from the boilerplate.

---

## 6. Views

All new view files live under `app/views/paths/` plus the two override views. Bootstrap 5 dark mode classes are used throughout. Custom CSS is restricted to `_accent.scss` and a small `_paths.scss` partial for the five-root visual map.

### `home/index.html.erb` (override)

- Hero band with the app tagline and a sample R.O.O.T.S. SVG illustration (the same five-root motif used on the path show page, rendered small)
- One paragraph that explains the framework
- Primary call to action button: "Create your first path" linking to `/paths/new` (or `/sign_up` if signed out)
- Footer hint: "MIT licensed, runs locally, no data leaves your machine except for the Gemini call"

### `dashboard/show.html.erb` (override)

- Greeting line: "Welcome back, [first name]"
- Primary card: large "Create a New Path" button linking to `/paths/new`
- Recent paths card: up to five most recent paths as compact rows (path name, member type, community type, created date)
- Framework tip card: rotates between five tips, one per root system, randomly selected on page load. Tips are static and live in a helper

### `paths/index.html.erb`

- Bootstrap card grid (3-up on desktop, 1-up on mobile)
- Each card: path name, badges for community type and member type, count of activities, "View" link
- Empty state with the same call to action as the dashboard

### `paths/new.html.erb`

- Single-column form, max width 720px, centered
- Four fields: `community_type` (Bootstrap select), `member_type` (Bootstrap select), `member_background` (textarea, character counter), `integration_goal` (textarea, character counter)
- A small explanatory note above the textarea fields about what makes a useful answer
- Submit button: "Generate path"
- The submit button is wired to a Stimulus controller (`form-submit`) that disables the button on submit and replaces the label with "Generating..." and a spinner; users see a clear pending state during the Gemini call
- Below the button, a small note: "This will use 1 of your 50 daily AI calls"

### `paths/show.html.erb`

This is the primary visual deliverable of the demo.

- Header: path name, edit link, clone button, print button, delete button (with `data-turbo-confirm`)
- Four-field summary card: shows the inputs that produced the path (community type, member type, member background, integration goal)
- **Five-root visual map.** A custom SVG component (`_root_map.html.erb`) at the top of the page. Five branching root lines emanate from a central point, each labeled with the root name and the count of activities under that root. Each root line is colored with its root-specific CSS variable. The component is purely decorative; clicking a root scrolls to its weekly section
- **Weekly activity panels.** Four panels labeled Week 1, Week 2, Week 3, Week 4. Each panel renders the activities scheduled for that week as cards. Each activity card shows: name, root system badge (color-tagged), description, estimated time
- "Show raw response" toggle (Bootstrap collapse) at the bottom that reveals the path's `gemini_raw` field content in a `<pre>` block (this is the inherited UX expectation for every demo with Gemini output)

### `paths/edit.html.erb`

- Two fields: name and integration goal
- Save and Cancel buttons
- Note explaining that re-generating activities is not supported in the demo; clone the path or create a new one

### `paths/print.html.erb` (rendered under `layouts/print.html.erb`)

- No navbar, no footer
- Path name, four-field summary, five-root summary list, weekly activity panels
- CSS includes `@media print` rules: page break between week panels, larger body type, removed background colors

### `_root_map.html.erb` (partial)

- Inline SVG, viewBox `0 0 800 300`
- Five paths drawn as gentle curves from a central trunk to five leaf labels
- Each path uses its root-specific color from the SCSS variables
- Activity counts rendered as a number badge on each leaf
- ARIA labels for screen readers describe each root and its activity count

The application layout, auth pages, and admin views come from the boilerplate.

---

## 7. AI Templates and Gemini Integration

One template is seeded for this demo. Templates live in the `ai_templates` table and are looked up by name. The boilerplate's `GeminiService.generate(template:, variables:)` call resolves the lookup, runs the gatekeeper, runs the budget checker, makes the timed Gemini call, logs an `LlmRequest`, and returns the response or raises an error.

### Template: `welcomepath_path_v1`

**Description.** Generates a 30-day R.O.O.T.S. onboarding path for a new community member. Output is a strict JSON object with five named root sections, each containing 2 to 4 activities, each tagged to a week.

**System prompt.**

```
You are an expert in community integration and onboarding design. You design 30-day onboarding paths grounded in the R.O.O.T.S. framework: Relationships, Orientation, Opportunities, Training, Stories. Each path you generate must address all five root systems with concrete, week-tagged activities.

You will be given the type of community, the type of new member, a summary of the member's background, and a one-sentence integration goal. Generate a path that fits this specific context.

You must return a JSON object with this exact shape:

{
  "relationships": [ { "name": "...", "description": "...", "estimated_minutes": 30, "week_number": 1 }, ... ],
  "orientation": [ ... ],
  "opportunities": [ ... ],
  "training": [ ... ],
  "stories": [ ... ]
}

Constraints:
- Each root must contain at least 2 activities and at most 4 activities.
- Activities must be distributed across all four weeks of the 30-day window. Do not pack everything into week 1.
- Activity names must be concrete and action-oriented (e.g., "Coffee chat with a current member who shares your background", not "Make some friends").
- Descriptions must be one to three sentences and explain how to do the activity.
- Estimated minutes must be realistic for the activity (typical range: 15 to 90 minutes).
- Output JSON only. No prose, no markdown fences, no explanation.

The five root systems are:
- Relationships: introductions, mentor pairing, peer connections, structured one-on-ones
- Orientation: community history, current priorities, norms and expectations, observation exercises
- Opportunities: small first contributions, medium contribution options, longer-term contribution paths
- Training: essential skills, vocabulary, tools the member needs to be effective
- Stories: community origin, recent achievements, prompts for the new member to share their own story

You structurally cannot produce a path that skips a root system. All five keys must be present and populated.
```

**User prompt template.**

```
Community type: {{community_type}}
New member type: {{member_type}}
Member background: {{member_background}}
Integration goal: {{integration_goal}}

Generate the R.O.O.T.S. path now. Return JSON only.
```

**Variables consumed.**

- `community_type` from `OnboardingPath.community_type`
- `member_type` from `OnboardingPath.member_type`
- `member_background` from `OnboardingPath.member_background`
- `integration_goal` from `OnboardingPath.integration_goal`

**Model.** `gemini-2.0-flash` (boilerplate default; appropriate for structured-JSON generation at low cost).

**Max output tokens.** `3000`. The default 2000 is tight for five sections each containing up to 4 activities with full descriptions; 3000 leaves headroom without inviting verbose output.

**Temperature.** `0.5`. Lower than the boilerplate default of 0.7. The output is structured and the JSON shape is non-negotiable; lower temperature improves schema adherence. Activity names and descriptions remain creative enough at 0.5.

**Author's notes.**

```
The system prompt's structural constraint ("you cannot produce a path that skips a root") is the lever that makes this template reliable. Without it, Gemini occasionally returns three or four roots and skips one, especially when the member background is short. With it, all five always appear.

Watch for: descriptions creeping over three sentences (the prompt says one to three; tighten if drift appears). Estimated minutes occasionally come back as 0 or as strings; the parser coerces and rejects. Activity names occasionally start with "Have a..." or "Do a..." which feels weak; consider tightening the prompt with example names if this becomes a pattern.

Known failure mode: when the integration goal is generic (e.g., "feel welcome"), the activities skew generic. The fix is in the input, not the prompt; the form's helper text guides users toward specific goals.
```

**Where it is called.** `PathsController#create` invokes `GeminiService.generate(template: "welcomepath_path_v1", variables: { ... })`.

**Expected output format.** JSON object. Schema:

```
{
  "relationships": [{"name": String, "description": String, "estimated_minutes": Integer, "week_number": 1..4}],
  "orientation":   [...same shape, 2 to 4 items],
  "opportunities": [...same shape, 2 to 4 items],
  "training":      [...same shape, 2 to 4 items],
  "stories":       [...same shape, 2 to 4 items]
}
```

**How the response is parsed and rendered.**

- `PathsController#create` parses the response with `JSON.parse`, then iterates over the five keys
- For each root, it iterates over the activity array and builds a `PathActivity` with `root_system: key`, plus the activity's `name`, `description`, `estimated_minutes`, `week_number`, and a `position` derived from array index
- All activities are persisted in a single transaction with the parent `OnboardingPath`
- The full raw response string is also persisted on `OnboardingPath#gemini_raw` for the Show raw response toggle
- Parser failures (malformed JSON, missing key, wrong shape) raise a `PathsController::ParseError`, which renders the same friendly inline error as a Gemini error and surfaces a retry button
- The `LlmRequest` log entry is written by `GeminiService` regardless of parse outcome; the operator can see in the admin panel exactly what Gemini returned

The boilerplate's gatekeeper, budget checker, request log, timeout behavior, and fail-soft error UI apply automatically and are not redescribed here.

---

## 8. AI Safety Considerations (Specific to This App)

This is a low-stakes demo. The output is an onboarding plan; a user acting on it experiences friction at worst, not harm. That said, three specific considerations apply:

**Content sensitivity.** Onboarding sometimes touches personal context (background, prior community experiences). Users may paste sensitive details into the `member_background` textarea. The boilerplate gatekeeper enforces a 5000-character cap, but no PII scrubbing happens. The README explicitly warns users that this is a local demo and not to paste real, identifiable information about real people; for a production version, PII scrubbing would be added.

**Domain accuracy requirements.** The R.O.O.T.S. framework is the author's own. There is no external authority that defines it. Gemini occasionally produces activities that look plausible but do not actually serve the named root system (e.g., a "training" activity that is really an orientation exercise). The Show raw response toggle is the user's check; the path show page also color-codes activity cards by root so visual inspection is easy. Operators reviewing the admin LlmRequest log can spot drift over time.

**App-specific disclaimers.** Beyond the boilerplate's footer note, the path show page renders a small note above the weekly panels: "This path is a starting point, not a finished plan. Review each activity for fit with your community before sharing it with a new member." This appears on every show page and on the print layout.

**Tightened settings.** Temperature is lowered from the boilerplate default of 0.7 to 0.5 for schema adherence. `max_output_tokens` is raised from 2000 to 3000 to fit the structured five-section output. The boilerplate's daily call cap of 50 is left at the default; this demo is not a high-volume use case.

**What this demo deliberately does not do.**

- No member enrollment tracking. The production app tracks individual new members through their assigned path with completion timestamps, milestone attainment, and integration assessments. The demo stops at path generation. Adding enrollment would obscure the single point this demo makes.
- No connection or story curation. The production app has separate AI features for recommending peer introductions and selecting community stories. The demo does not include these features; the corresponding production templates do not appear in the seeds.
- No guide assignment, no peer cohort logic, no integration assessment. These are production-only.
- No multi-language support. English only. The production app supports the locale of the host community.
- No fine-tuning, no embeddings, no RAG. Single-shot prompt; the framework is encoded in the system prompt.

The pattern of "small set of explicit guardrails plus an explicit list of omissions with rationale" mirrors the boilerplate's own safety section and is itself the strongest signal to a reader.

---

## 9. RSpec Outline

New spec files added on top of the boilerplate's spec suite. Each test stubs Gemini via the boilerplate's test double; no real API calls run.

### `spec/models/onboarding_path_spec.rb`

- Validates presence of `community_type`, `member_type`, `member_background`, `integration_goal`
- Validates `community_type` and `member_type` are in the allowed inclusion list
- Validates `member_background` length 20 to 1500
- Validates `integration_goal` length 10 to 300
- `belongs_to :user` and `has_many :path_activities` associations
- `dependent: :destroy` cascades activity deletion when the path is destroyed
- `activities_by_root` and `activities_by_week` return correctly grouped hashes

### `spec/models/path_activity_spec.rb`

- Validates `root_system` is one of the five allowed values
- Validates `week_number` is in 1..4
- Validates `estimated_minutes` is a positive integer no greater than 240
- `belongs_to :onboarding_path` association

### `spec/requests/paths_spec.rb`

- `GET /paths` lists only paths owned by the signed-in user
- A signed-in user cannot access another user's path via `GET /paths/:id` (returns 404)
- `GET /paths/new` renders the form
- `POST /paths` with valid params creates an OnboardingPath, persists 5 root sections worth of PathActivities (verified via the stubbed Gemini response), and redirects to show
- `POST /paths` with invalid params re-renders the form and does not call Gemini
- `POST /paths` writes an `LlmRequest` record on every AI call (success or failure)
- `POST /paths` when Gemini raises `GeminiService::GeminiError` re-renders the form with the inline error partial and writes an `LlmRequest` with `status: error`
- `POST /paths` when Gemini returns malformed JSON renders the parse-error path and the OnboardingPath is not created
- `POST /paths/:id/clone` duplicates the path and its activities, names the clone with " (copy)", and redirects to the clone
- `DELETE /paths/:id` destroys the path and its activities

### `spec/requests/paths_print_spec.rb`

- `GET /paths/:id/print` renders under the `print` layout (asserts no navbar, no footer)
- A signed-in user cannot print another user's path

The boilerplate's `user_spec.rb`, `ai_template_spec.rb`, `llm_request_spec.rb`, `gemini_service_spec.rb`, `ai_gatekeeper_spec.rb`, `ai_budget_checker_spec.rb`, and the auth request specs are inherited.

---

## 10. Seed Data

`db/seeds.rb` extends the boilerplate's seed file (which already creates the admin demo user) with the AiTemplate seed and a sample path.

### AiTemplate seeds

One record, created with `find_or_create_by!(name: "welcomepath_path_v1")`:

- `name: "welcomepath_path_v1"`
- `description: "Generates a 30-day R.O.O.T.S. onboarding path for a new community member."`
- `system_prompt:` full text from Section 7
- `user_prompt_template:` full text from Section 7
- `model: "gemini-2.0-flash"`
- `max_output_tokens: 3000`
- `temperature: 0.5`
- `notes:` author's notes from Section 7

### Domain seeds

One sample `OnboardingPath` is created for the seeded demo user (`demo@example.com`) so the show page renders meaningfully on first run. The seed bypasses the AI call by inserting a hardcoded path with realistic-looking activities across all five roots:

- `community_type: "nonprofit"`
- `member_type: "newcomer"`
- `member_background: "Twenty-something, recently relocated, professional background in marketing, no prior nonprofit involvement, looking to build community connections in a new city."`
- `integration_goal: "Feel like a contributing member of the community within 30 days, with at least one strong peer connection and a clear way to help."`
- 15 child `PathActivity` records spread across the five roots and four weeks, with realistic names and descriptions

The seed also stores a hand-crafted `gemini_raw` value on this path so the Show raw response toggle has something to display on first run.

---

## 11. README Additions

The boilerplate's README template provides standard sections for Stack, Setup, License, AI Safety Posture, and About the Author. WelcomePath Demo overrides and extends as follows:

### App Header

```
# WelcomePath Demo

Welcome new members with a 30-day path that builds belonging, not just compliance.

A single-feature demo of the R.O.O.T.S. onboarding framework: Relationships,
Orientation, Opportunities, Training, Stories. Enter a few details about a
new community member and get back a complete 30-day path with activities
mapped to all five root systems.
```

### Screenshot

A placeholder note: `<!-- Add screenshot of the path show page (five-root map + weekly panels) here -->` with a recommended dimension and dark-mode screenshot.

### Why I Built This

Short, indie hacker voice:

- I am building a multi-tenant SaaS suite for community-driven organizations. WelcomePath is the onboarding tool. The full app does cohort tracking, guide assignments, integration assessments, and per-organization libraries. This demo isolates the single most valuable thing the full app does: generate a path. If the path is good, the rest of the app is worth building.
- Most onboarding tools are checklists. Belonging is not a checklist. The R.O.O.T.S. framework is my answer to that.
- The full version lives at [welcomepath.app](https://welcomepath.app) (placeholder URL). The demo is open source under the MIT license; clone it, modify the prompt, see how the output changes.

### AI Prompt Editing

```
The AI prompt for this demo is editable in the admin UI at /admin/ai_templates.
Sign in as the seeded admin user (demo@example.com / password123), navigate to
AI Templates, click `welcomepath_path_v1`, and tune the system prompt or user
prompt template directly. The right-hand panel lets you test changes against
Gemini without leaving the page. Save persists changes; the next path you
generate uses the updated prompt.
```

### Setup

No app-specific steps beyond `bin/setup`. The boilerplate template covers `GEMINI_API_KEY`, `bin/setup`, and `bin/dev`. The reader follows those.

The standard boilerplate sections (Stack, Setup, License, AI Safety Posture, About the Author, Cost) remain unchanged.

---

## 12. Bootstrap Dark Mode and Accent Color Notes

### Component Choices

- **Card-based layout.** Path index uses Bootstrap card grid (3-up on desktop). Path show uses cards for each weekly panel and within those, smaller cards for each activity.
- **Form layout.** `form-control`, `form-label`, `form-select`, `form-text` for character counter hints. The new-path form is a single column at max width 720px.
- **Badges.** Each activity card has a `badge` for its root system, color-tagged with the root-specific CSS variable. Each card also shows estimated minutes as a smaller text-muted line.
- **Navbar.** Standard Bootstrap dark navbar from the boilerplate. Two new links added: Paths and New Path.
- **Print layout.** A second Bootstrap layout `layouts/print.html.erb` is added with `@media print` overrides; it strips the navbar and footer entirely.

### Accent Color Application

- Primary buttons use `var(--accent)` for background and `var(--accent-hover)` on hover. The Generate button on the new-path form is the visual anchor.
- Active nav links use `var(--accent)` for the underline indicator.
- All hyperlinks in body content use `var(--accent)` with a slightly darker hover.
- The five-root SVG illustration on the home page and inside `_root_map.html.erb` uses the five root-specific CSS variables. The trunk of the root map uses `var(--accent)`.
- The Warm Amber secondary (`--accent-secondary: #d97706`) is reserved for milestone-style accents: the path-saved confirmation flash, the Print button, and the Show raw response toggle's active state. This is the only place a second color appears, and it is deliberately rare.

### Custom CSS

The custom SCSS footprint is intentionally small:

- `_accent.scss`: overrides `--accent`, `--accent-hover`, adds `--accent-secondary` and the five `--root-*` variables
- `_paths.scss`: contains the five-root SVG sizing rules, the activity-card root-tag color binding, and the print layout `@media print` overrides

No JavaScript bundlers, no React, no custom build steps beyond what Rails 8 ships with. Stimulus controllers are used for: the new-path form's submit-pending state (`form-submit_controller.js`), the character counters on the textareas (`character-count_controller.js`), and the Show raw response toggle (Bootstrap's collapse component handles this; no Stimulus needed).

---

*v1.0 - WelcomePath Demo spec. Built on Open Demo Starter v2.0. Open source under MIT license.*
