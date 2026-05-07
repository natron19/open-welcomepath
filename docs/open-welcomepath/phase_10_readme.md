# Phase 10 — README Update

**Goal:** The README reflects WelcomePath Demo, not the generic boilerplate. A first-time visitor understands what the app does, how to run it, and how to extend it.

**Prerequisite:** All prior phases complete. The app works end-to-end.

**Spec reference:** `docs/open-welcomepath/welcomepath-demo-spec.md` section 11.

---

## Tasks

### 10.1 — Replace the README header

```markdown
# WelcomePath Demo

Welcome new members with a 30-day path that builds belonging, not just compliance.

A single-feature demo of the R.O.O.T.S. onboarding framework: Relationships,
Orientation, Opportunities, Training, Stories. Enter a few details about a
new community member and get back a complete 30-day path with activities
mapped to all five root systems.

<!-- Add screenshot of the path show page (five-root map + weekly panels) here.
     Recommended: 1400×900, dark mode, with at least two weekly panels visible. -->
```

### 10.2 — Add "Why I Built This" section

```markdown
## Why I Built This

I'm building a multi-tenant SaaS suite for community-driven organizations.
WelcomePath is the onboarding tool in that suite. The full product does cohort
tracking, guide assignments, integration assessments, and per-organization path
libraries. This demo isolates the single most valuable action: generating a path.
If the path is good, the rest is worth building.

Most onboarding tools are checklists. Belonging is not a checklist. The R.O.O.T.S.
framework is my answer to that.

This demo is open source under the MIT license. Clone it, tune the prompt in the
admin panel, and see how the output changes.
```

### 10.3 — Add "AI Prompt Editing" section

```markdown
## Editing the AI Prompt

The prompt that generates paths is fully editable in the admin UI:

1. Sign in as `demo@example.com` / `password123`
2. Navigate to `/admin/ai_templates`
3. Click `welcomepath_path_v1`
4. Edit the system prompt or user prompt template
5. Use the test panel on the right to run Gemini with sample variables before saving
6. Save — the next path generated uses the updated prompt

This is the fastest way to tune the output without touching any code.
```

### 10.4 — Add "What This Demo Does Not Do" section

```markdown
## What This Demo Does Not Do

This demo is intentionally scoped. The following features exist in the full
production product and are deliberately absent here:

- **Member enrollment tracking.** The production app tracks individual members
  through their assigned path with completion timestamps and milestone attainment.
  The demo stops at path generation.
- **Guide assignment.** In production, each path can be assigned to a guide
  who receives notifications and tracks the member's progress.
- **Peer cohort logic.** The production app groups members into cohorts and
  surfaces cross-cohort connections. Not in scope for the demo.
- **Integration assessment.** A structured mid-path check that measures belonging
  indicators. Production only.
- **Multi-tenancy.** No organizations, memberships, or invitations. Single user only.
- **Connection and story curation.** Separate AI features for peer introductions
  and story selection. Not seeded in this demo.
- **Multi-language support.** English only. Production supports the locale of the
  host community.
- **File uploads, OAuth, Stripe.** None of the above.
```

### 10.5 — Keep and update boilerplate sections

The following sections come from the boilerplate README template. Update any boilerplate-generic phrasing to WelcomePath-specific context:

- **Quick Start** — no app-specific steps beyond `bin/setup`; keep as-is
- **Stack** — update to reflect WelcomePath's two domain models; keep rest as-is
- **Environment Variables** — add `APP_NAME`, `APP_TAGLINE`, `APP_DESCRIPTION` rows to the table
- **AI Safety Posture** — add the app-specific note from spec section 8: temperature lowered to 0.5, max tokens raised to 3000, disclaimer on the show page
- **Cost** — note that paths typically use 800–1200 tokens at $0.15/1M input + $0.60/1M output for gemini-2.5-flash (rough estimate; actual varies by input length)
- **License** — MIT, no changes

### 10.6 — Seeded credentials block

Add a visible callout near the Quick Start section:

```markdown
### Default Login

After `rails db:seed`:

| Field    | Value                  |
|----------|------------------------|
| Email    | demo@example.com       |
| Password | password123            |
| Role     | Admin                  |
```

---

## RSpec

No specs for documentation. Run the full suite as a final sanity check after README changes:

```
bundle exec rspec
```

---

## Manual Checks

- [ ] Read the README from top to bottom as a first-time visitor — no boilerplate placeholder text remains
- [ ] All section headers are present: Why I Built This, AI Prompt Editing, Quick Start, Stack, What This Demo Does Not Do, Environment Variables, AI Safety Posture, Cost, License
- [ ] The screenshot placeholder comment is present and describes what to add
- [ ] No internal infrastructure details, real email addresses, or hardcoded values appear
- [ ] The seeded credentials table is accurate
- [ ] Render the README on GitHub (or via `grip`/similar tool) to verify markdown formatting is correct
