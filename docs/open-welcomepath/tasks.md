# WelcomePath Demo — Build Tasks

Built on Open Demo Starter v2.0. Each phase has a dedicated spec file with full implementation details, RSpec tests, and manual checks.

**Spec:** `docs/open-welcomepath/welcomepath-demo-spec.md`

---

## Golden Rules (applies to all phases)

- `turbo_stream.update()` — never `replace()` → see `docs/turbo-stimulus-patterns.md`
- All JavaScript via Stimulus — no `<script>` tags, no `addEventListener`, no `onclick` (single exception: `window.print()` in Phase 7)
- All AI calls via `GeminiService.generate(...)` — never call Gemini directly
- All app name / tagline / description via `ENV.fetch(...)` — never hardcode
- Model for this demo: `gemini-2.5-flash` (not `gemini-2.0-flash` — deprecated for new API keys)
- Never start the Rails server automatically — tell the user to run `bin/dev`
- Never run RSpec automatically — tell the user to run `bundle exec rspec`

---

## Progress

| Phase | Description | Spec | Status |
|-------|-------------|------|--------|
| 1 | Foundation: Branding, CSS, Navbar, Overrides | [phase_1_foundation.md](phase_1_foundation.md) | ✅ |
| 2 | Data Models: Migrations, Models, Factories | [phase_2_data_models.md](phase_2_data_models.md) | ✅ |
| 3 | Routes and PathsController | [phase_3_routes_controller.md](phase_3_routes_controller.md) | ✅ |
| 4 | Core Views: Index, New, Show, Edit | [phase_4_views.md](phase_4_views.md) | ✅ |
| 5 | Stimulus Controllers | [phase_5_stimulus.md](phase_5_stimulus.md) | ✅ |
| 6 | AI Integration: Template, Create, Parsing | [phase_6_ai_integration.md](phase_6_ai_integration.md) | ✅ |
| 7 | Print Layout and Print View | [phase_7_print_layout.md](phase_7_print_layout.md) | ✅ |
| 8 | Seed Data: Sample Path for Demo User | [phase_8_seed_data.md](phase_8_seed_data.md) | ✅ |
| 9 | RSpec Test Suite | [phase_9_rspec.md](phase_9_rspec.md) | ✅ |
| 10 | README Update | [phase_10_readme.md](phase_10_readme.md) | ✅ |
| 11 | Security Review and Publish Prep | [phase_11_security_and_publish.md](phase_11_security_and_publish.md) | ✅ |

---

## Phase Detail

### Phase 1 — Foundation
**Spec:** [phase_1_foundation.md](phase_1_foundation.md)

- [ ] `.env.example` updated with `APP_NAME`, `APP_TAGLINE`, `APP_DESCRIPTION`
- [ ] CSS variables: `--accent`, `--accent-hover`, `--accent-secondary`, five `--root-*` variables
- [ ] Path CSS block stubbed in `application.css` (badge classes, `.root-map-svg`, print stub)
- [ ] Navbar: `Paths` and `New Path` links added (guarded by `current_user`)
- [ ] `home/index.html.erb` replaced with marketing-lite landing page
- [ ] `dashboard/show.html.erb` replaced with path-oriented dashboard (recent paths as placeholder)
- [ ] Boilerplate RSpec suite still passes

---

### Phase 2 — Data Models
**Spec:** [phase_2_data_models.md](phase_2_data_models.md)

- [ ] Migration: `onboarding_paths` (UUID PK, all columns, timestamps null: false, index on user_id)
- [ ] Migration: `path_activities` (UUID PK, all columns, composite indexes)
- [ ] `rails db:migrate` succeeds
- [ ] `OnboardingPath` model: associations, validations, `COMMUNITY_TYPES`, `MEMBER_TYPES`, `activities_by_root`, `activities_by_week`
- [ ] `PathActivity` model: associations, validations, `ROOT_SYSTEMS` constant
- [ ] `User` model: `has_many :onboarding_paths, dependent: :destroy`
- [ ] Factory: `onboarding_paths` with `:with_activities` trait
- [ ] Factory: `path_activities` with one trait per root system
- [ ] `spec/models/onboarding_path_spec.rb` — all examples pass
- [ ] `spec/models/path_activity_spec.rb` — all examples pass

---

### Phase 3 — Routes and PathsController
**Spec:** [phase_3_routes_controller.md](phase_3_routes_controller.md)

- [ ] Routes: `resources :paths` with `clone` and `print` member routes
- [ ] `PathsController`: all actions, `set_path` scoped to `current_user`, `ParseError` constant, `path_params`
- [ ] `clone` action: transactional dup with " (copy)" suffix
- [ ] `print` action: `render :print, layout: "print"`
- [ ] `create` action: `NotImplementedError` placeholder (wired in Phase 6)
- [ ] Access-control request specs pass (unauthenticated redirects, 404 on non-owner)

---

### Phase 4 — Core Views
**Spec:** [phase_4_views.md](phase_4_views.md)

- [ ] `paths/index.html.erb`: card grid, empty state, delete link with confirm
- [ ] `dashboard/show.html.erb`: recent paths wired, `DashboardHelper#roots_tip`, rotating tip card
- [ ] `paths/new.html.erb`: four fields, Stimulus data attributes wired, character counter `<small>` elements
- [ ] `paths/_root_map.html.erb`: inline SVG partial with five root paths, color variables, ARIA
- [ ] `paths/show.html.erb`: header controls, input summary, root map, AI disclaimer, weekly panels, raw response collapse
- [ ] `paths/edit.html.erb`: name and integration_goal only, explanatory note
- [ ] `home/index.html.erb`: SVG placeholder replaced with `_root_map` partial
- [ ] Full RSpec suite still passes

---

### Phase 5 — Stimulus Controllers
**Spec:** [phase_5_stimulus.md](phase_5_stimulus.md)

- [ ] `form_submit_controller.js`: disables button, shows "Generating…" + spinner on submit
- [ ] `character_count_controller.js`: live counter, turns red at limit, initializes on connect
- [ ] Both controllers registered in `controllers/index.js`
- [ ] Full RSpec suite still passes

---

### Phase 6 — AI Integration
**Spec:** [phase_6_ai_integration.md](phase_6_ai_integration.md)

- [ ] `welcomepath_path_v1` AI template seeded in `db/seeds.rb`
- [ ] `rails db:seed` succeeds; template visible at `/admin/ai_templates`
- [ ] Admin panel test confirms correct JSON output shape before wiring the controller
- [ ] `PathsController#create` rewrites with full `GeminiService.generate` call
- [ ] `parse_and_save_activities!` private method: JSON.parse, 5-root check, activity creation in transaction
- [ ] Parse error message shown in `paths/new.html.erb`
- [ ] Rate limiting: 5 per minute on `create`
- [ ] Smoke test spec passes (stubbed Gemini → creates path + 10 activities)

---

### Phase 7 — Print Layout
**Spec:** [phase_7_print_layout.md](phase_7_print_layout.md)

- [ ] `layouts/print.html.erb`: no navbar, no footer, Bootstrap CDN, `@media print` styles
- [ ] `paths/print.html.erb`: input summary, root summary list, AI disclaimer, Print button, weekly panels
- [ ] `PathsController`: `set_path_activities` before_action added for `:show` and `:print`
- [ ] `@media print` in `application.css`: `.week-panel { page-break-after: always; }`
- [ ] `spec/requests/paths_print_spec.rb` — all examples pass

---

### Phase 8 — Seed Data
**Spec:** [phase_8_seed_data.md](phase_8_seed_data.md)

- [ ] Sample `OnboardingPath` seeded for `demo@example.com` (nonprofit / newcomer)
- [ ] 11 child `PathActivity` records across all 5 roots and all 4 weeks
- [ ] Hand-crafted `gemini_raw` JSON stored on the path
- [ ] Seed guarded: `if demo_user.onboarding_paths.empty?` — idempotent
- [ ] `rails db:seed` produces no errors; demo path visible at `/paths`
- [ ] Full RSpec suite still passes

---

### Phase 9 — RSpec
**Spec:** [phase_9_rspec.md](phase_9_rspec.md)

- [ ] `spec/models/onboarding_path_spec.rb` — all examples pass
- [ ] `spec/models/path_activity_spec.rb` — all examples pass
- [ ] `spec/requests/paths_spec.rb` — full coverage: unauthenticated redirects, owner-only 404s, create success/failures (GeminiError, BudgetExceeded, Timeout, GatekeeperError, malformed JSON, missing root), clone, destroy
- [ ] `spec/requests/paths_print_spec.rb` — unauthenticated redirect, owner 200 without nav, non-owner 404
- [ ] `bundle exec rspec` — 0 failures, 0 pending
- [ ] Zero real Gemini API calls made during the test run

---

### Phase 10 — README
**Spec:** [phase_10_readme.md](phase_10_readme.md)

- [ ] README header replaced with WelcomePath Demo header
- [ ] "Why I Built This" section added
- [ ] "AI Prompt Editing" section added
- [ ] "What This Demo Does Not Do" section added
- [ ] Screenshot placeholder comment added
- [ ] Seeded credentials table visible near Quick Start
- [ ] Boilerplate sections updated (Stack, Env Vars, AI Safety, Cost, License)
- [ ] No boilerplate placeholder text remains

---

### Phase 11 — Security Review and Publish Prep
**Spec:** [phase_11_security_and_publish.md](phase_11_security_and_publish.md)

- [ ] Pre-publish security check (`docs/prompts/pre-publish-security-check.md`) run and all findings resolved
- [ ] No hardcoded secrets in any committed file
- [ ] `.gitignore` covers `.env`, `*.key`, `config/master.key`, `log/`, `tmp/`
- [ ] `.env.example` — all values are placeholders
- [ ] Git history clean — no commit message suggests a secret was committed
- [ ] Code hygiene: no `binding.pry`, `console.log`, `NotImplementedError` stubs, hardcoded names
- [ ] `bundle exec rspec` — 0 failures, 0 pending
- [ ] Full end-to-end smoke test passes (see phase spec for checklist)
- [ ] **Repo is ready to make public**
