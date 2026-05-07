# Phase 1 — Foundation: Branding, CSS, Navbar, Overrides

**Goal:** The app looks and feels like WelcomePath Demo from the first page load — correct accent color, navbar links, and overridden home/dashboard views in place. No domain models yet.

**Prerequisite:** Open Demo Starter boilerplate is fully built (all auth, admin panel, AI service, and RSpec suite are in place). Run `bundle exec rspec` before starting this phase and confirm the boilerplate suite passes.

**Spec reference:** `docs/open-welcomepath/welcomepath-demo-spec.md` sections 1, 2, and 12.

---

## Tasks

### 1.1 — Update `.env.example`

Set app branding variables (do not change `GEMINI_API_KEY` or AI operational settings):

```
APP_NAME=WelcomePath Demo
APP_TAGLINE=Welcome new members with a 30-day path that builds belonging, not just compliance.
APP_DESCRIPTION=WelcomePath Demo generates a complete 30-day R.O.O.T.S. onboarding path for any new community member. Fill in four fields and get a structured path across Relationships, Orientation, Opportunities, Training, and Stories — mapped to all four weeks of the first month.
```

### 1.2 — CSS Variables

In `app/assets/stylesheets/application.css`, update `:root` with:

```css
:root {
  --accent: #3b82f6;
  --accent-hover: #2563eb;
  --accent-secondary: #d97706;

  /* One color per R.O.O.T.S. root system */
  --root-relationships: #6366f1;
  --root-orientation:   #06b6d4;
  --root-opportunities: #10b981;
  --root-training:      #f59e0b;
  --root-stories:       #f43f5e;
}
```

### 1.3 — Path-specific CSS block

Add a `/* Paths */` section in `application.css` for rules added in later phases. Stub it now so future phases have a home:

```css
/* Paths */
.root-map-svg { width: 100%; height: auto; }

.badge-root-relationships { background-color: var(--root-relationships); }
.badge-root-orientation   { background-color: var(--root-orientation); }
.badge-root-opportunities { background-color: var(--root-opportunities); }
.badge-root-training      { background-color: var(--root-training); }
.badge-root-stories       { background-color: var(--root-stories); }

/* Print overrides — expanded in Phase 7 */
@media print {
  .d-print-none { display: none !important; }
}
```

### 1.4 — Navbar

In `app/views/layouts/application.html.erb`, add two nav links **before** the user dropdown — only render them when `current_user` is present:

```erb
<% if current_user %>
  <%= link_to "Paths", paths_path, class: "nav-link" %>
  <%= link_to "New Path", new_path_path, class: "nav-link" %>
<% end %>
```

The links will 404 until Phase 3 adds routes — that is expected.

Admin link remains in the user dropdown, guarded by `current_user.admin?`.

### 1.5 — Replace `home/index.html.erb`

```erb
<div class="container py-5">
  <div class="row justify-content-center">
    <div class="col-lg-8 text-center">
      <h1 class="display-5 fw-bold mb-3"><%= ENV.fetch("APP_NAME", "WelcomePath Demo") %></h1>
      <p class="lead mb-4"><%= ENV.fetch("APP_TAGLINE", "") %></p>

      <div class="card mb-4">
        <div class="card-body text-start">
          <h5 class="card-title">The R.O.O.T.S. Framework</h5>
          <p class="card-text">
            Belonging does not come from completing a checklist. It comes from establishing roots.
            The R.O.O.T.S. framework ensures five root systems are deliberately addressed in a new
            member's first 30 days: <strong>Relationships</strong>, <strong>Orientation</strong>,
            <strong>Opportunities</strong>, <strong>Training</strong>, and <strong>Stories</strong>.
          </p>
        </div>
      </div>

      <%# Root map SVG placeholder — replaced with _root_map partial in Phase 4 %>
      <div id="home-root-map-placeholder" class="mb-4 p-4 border rounded text-muted">
        [Five-root illustration — added in Phase 4]
      </div>

      <% if current_user %>
        <%= link_to "Create your first path", new_path_path, class: "btn btn-lg", style: "background-color: var(--accent); color: white;" %>
      <% else %>
        <%= link_to "Get started — sign up free", sign_up_path, class: "btn btn-lg", style: "background-color: var(--accent); color: white;" %>
        <%= link_to "Sign in", sign_in_path, class: "btn btn-lg btn-outline-secondary ms-2" %>
      <% end %>

      <p class="text-muted small mt-4">
        MIT licensed · runs locally · no data leaves your machine except for the Gemini call
      </p>
    </div>
  </div>
</div>
```

### 1.6 — Replace `dashboard/show.html.erb`

```erb
<div class="container py-4">
  <div class="row">
    <div class="col">
      <h1 class="mb-4">Welcome back, <%= current_user.first_name %>.</h1>
    </div>
  </div>

  <div class="row g-4">
    <%# Primary CTA %>
    <div class="col-md-6">
      <div class="card h-100">
        <div class="card-body d-flex flex-column justify-content-center align-items-center py-5">
          <h5 class="card-title mb-3">Ready to build a path?</h5>
          <%= link_to "Create a New Path", new_path_path, class: "btn btn-lg", style: "background-color: var(--accent); color: white;" %>
        </div>
      </div>
    </div>

    <%# Recent paths — placeholder until Phase 4 wires the real list %>
    <div class="col-md-6">
      <div class="card h-100">
        <div class="card-header">Recent Paths</div>
        <div class="card-body">
          <p class="text-muted">No paths yet — create your first one above.</p>
        </div>
      </div>
    </div>

    <%# Framework tip card %>
    <div class="col-12">
      <div class="card border-0 bg-body-secondary">
        <div class="card-body">
          <h6 class="card-subtitle text-muted mb-1">Framework Tip</h6>
          <p class="card-text mb-0">
            <strong>Relationships root:</strong> Every new member needs at least one peer connection
            in the first two weeks. Schedule an introduction before the path is handed off.
          </p>
        </div>
      </div>
    </div>
  </div>
</div>
```

The recent paths list and rotating tip helper are wired in Phase 4.

---

## RSpec

No new specs in this phase. After completing these tasks, run the boilerplate suite to verify no regressions:

```
bundle exec rspec
```

All existing specs must continue to pass before proceeding to Phase 2.

---

## Manual Checks

After `bin/dev`:

- [ ] Navigate to `/` — hero band shows the tagline from `.env`, R.O.O.T.S. paragraph is visible, CTA button renders in accent blue
- [ ] Navigate to `/` while signed out — CTA links to `/sign_up`
- [ ] Sign in as `demo@example.com` / `password123`
- [ ] Navigate to `/dashboard` — greeting shows first name, "Create a New Path" card is visible
- [ ] Verify `Paths` and `New Path` links appear in the navbar (they return 404 until Phase 3 — that is expected)
- [ ] Verify the admin dropdown link appears only when signed in as an admin user
- [ ] Inspect page source — confirm `--accent: #3b82f6` in stylesheet and `--root-relationships` are all defined
- [ ] Verify Bootstrap dark mode remains intact (dark background, light text)
