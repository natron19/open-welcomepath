# Phase 7 — Print Layout and Print View

**Goal:** The `/paths/:id/print` action renders a clean layout with no navbar or footer, with CSS `@media print` rules for page breaks between week panels. Users can print or save a path as PDF.

**Prerequisite:** Phase 6 complete. Full path generation flow works end-to-end.

**Spec reference:** `docs/open-welcomepath/welcomepath-demo-spec.md` section 6 (`paths/print.html.erb`).

---

## Tasks

### 7.1 — `app/views/layouts/print.html.erb`

```erb
<!DOCTYPE html>
<html data-bs-theme="dark">
  <head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title><%= ENV.fetch("APP_NAME", "WelcomePath Demo") %></title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css">
    <%= stylesheet_link_tag "application", "data-turbo-track": "reload" %>
    <style>
      @media print {
        @page { margin: 1in; }
        body  { font-size: 12pt; color: #000; background: #fff; }
        .week-panel { page-break-after: always; }
        .week-panel:last-child { page-break-after: avoid; }
        a { color: inherit; text-decoration: none; }
      }
    </style>
  </head>
  <body>
    <%= yield %>
  </body>
</html>
```

### 7.2 — `app/views/paths/print.html.erb`

```erb
<div class="container py-4">
  <h1 class="mb-3"><%= @path.name %></h1>

  <%# Input summary %>
  <div class="card mb-4">
    <div class="card-body">
      <div class="row g-2">
        <div class="col-6">
          <div class="text-muted small">Community type</div>
          <div><%= @path.community_type %></div>
        </div>
        <div class="col-6">
          <div class="text-muted small">Member type</div>
          <div><%= @path.member_type %></div>
        </div>
        <div class="col-12 mt-2">
          <div class="text-muted small">Integration goal</div>
          <div><%= @path.integration_goal %></div>
        </div>
        <div class="col-12 mt-2">
          <div class="text-muted small">Member background</div>
          <div><%= @path.member_background %></div>
        </div>
      </div>
    </div>
  </div>

  <%# Root summary list %>
  <div class="card mb-4">
    <div class="card-header">R.O.O.T.S. Summary</div>
    <ul class="list-group list-group-flush">
      <% PathActivity::ROOT_SYSTEMS.each do |root| %>
        <li class="list-group-item d-flex justify-content-between">
          <span class="fw-semibold text-capitalize"><%= root %></span>
          <span class="text-muted"><%= @activities_by_root[root]&.size || 0 %> activities</span>
        </li>
      <% end %>
    </ul>
  </div>

  <%# AI disclaimer %>
  <p class="text-muted small mb-4">
    This path is a starting point, not a finished plan.
    Review each activity for fit with your community before sharing it with a new member.
  </p>

  <%# Print button — d-print-none so it does not appear in the printed output %>
  <button onclick="window.print()" class="btn btn-outline-secondary mb-4 d-print-none">
    Print / Save PDF
  </button>
  <%# NOTE: onclick="window.print()" is a deliberate, narrow exception to the no-inline-JS rule.
      This is a single browser-native call on a print-specific layout that Turbo never re-renders. %>

  <%# Weekly panels %>
  <% (1..4).each do |week| %>
    <div class="card mb-3 week-panel">
      <div class="card-header fw-semibold">Week <%= week %></div>
      <div class="card-body">
        <% activities = @activities_by_week[week] || [] %>
        <% if activities.empty? %>
          <p class="text-muted mb-0">No activities for this week.</p>
        <% else %>
          <% activities.each do |activity| %>
            <div class="mb-3 pb-3 border-bottom">
              <div class="d-flex justify-content-between align-items-start">
                <strong><%= activity.name %></strong>
                <span class="badge ms-2 badge-root-<%= activity.root_system %>"><%= activity.root_system %></span>
              </div>
              <p class="mb-1 mt-1 small"><%= activity.description %></p>
              <small class="text-muted">~<%= activity.estimated_minutes %> min</small>
            </div>
          <% end %>
        <% end %>
      </div>
    </div>
  <% end %>
</div>
```

### 7.3 — Verify controller renders print layout

In `PathsController#print`, confirm:

```ruby
def print
  render :print, layout: "print"
end
```

The `@activities_by_root` and `@activities_by_week` instance variables are already set by `set_path` — wait, they are not. Add them explicitly because `show` sets them but `print` does not call `show`:

Update `set_path` or add a second `before_action` for print:

```ruby
before_action :set_path_activities, only: [:show, :print]

def set_path_activities
  @activities_by_root = @path.activities_by_root
  @activities_by_week = @path.activities_by_week
end
```

Remove the duplicate assignments from `show` if they now come from `set_path_activities`.

### 7.4 — Complete `@media print` in `application.css`

The Phase 1 stub defined `.d-print-none`. Add the week panel page break rule:

```css
@media print {
  .d-print-none  { display: none !important; }
  .week-panel    { page-break-after: always; }
  .week-panel:last-child { page-break-after: avoid; }
  nav, footer    { display: none !important; }
  body           { background: #fff !important; color: #000 !important; }
}
```

---

## RSpec

Write `spec/requests/paths_print_spec.rb`:

```ruby
RSpec.describe "Paths print", type: :request do
  let(:user)  { create(:user) }
  let(:other) { create(:user) }
  let(:path)  { create(:onboarding_path, :with_activities, user: user) }

  describe "GET /paths/:id/print" do
    context "when unauthenticated" do
      it "redirects to sign in" do
        get print_path_path(path)
        expect(response).to redirect_to(sign_in_path)
      end
    end

    context "when signed in as the owner" do
      before { sign_in_as(user) }

      it "returns 200" do
        get print_path_path(path)
        expect(response).to have_http_status(:ok)
      end

      it "renders without a navbar" do
        get print_path_path(path)
        expect(response.body).not_to include("<nav")
      end

      it "renders without a footer" do
        get print_path_path(path)
        expect(response.body).not_to include("<footer")
      end
    end

    context "when signed in as a different user" do
      before { sign_in_as(other) }

      it "returns 404" do
        get print_path_path(path)
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
```

Run: `bundle exec rspec spec/requests/paths_print_spec.rb`

---

## Manual Checks

After `bin/dev`:

- [ ] Navigate to `/paths/:id/print` for an owned path — no navbar, no footer visible
- [ ] Verify the "Print / Save PDF" button is visible on screen
- [ ] Click "Print / Save PDF" — browser print dialog opens
- [ ] In browser print preview, verify week panels have page breaks between them
- [ ] Use `Cmd+P` / `Ctrl+P` directly — same result as the button
- [ ] Navigate to another user's path `/paths/:id/print` — returns 404
- [ ] Unauthenticated access to `/paths/:id/print` redirects to sign in
