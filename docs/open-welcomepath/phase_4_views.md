# Phase 4 — Core Views: Index, New, Show, Edit

**Goal:** Every view is complete and styled with Bootstrap 5 dark mode. The show page renders the five-root visual map and weekly activity panels. Edit is locked to name and integration goal only. Dashboard recent-paths list is wired.

**Prerequisite:** Phase 3 complete. Routes and controller are in place.

**Spec reference:** `docs/open-welcomepath/welcomepath-demo-spec.md` sections 6 and 12.

---

## Tasks

### 4.1 — `app/views/paths/index.html.erb`

```erb
<div class="container py-4">
  <div class="d-flex justify-content-between align-items-center mb-4">
    <h1>My Paths</h1>
    <%= link_to "New Path", new_path_path, class: "btn", style: "background-color: var(--accent); color: white;" %>
  </div>

  <% if @paths.empty? %>
    <div class="text-center py-5">
      <p class="text-muted mb-3">No paths yet.</p>
      <%= link_to "Create your first path", new_path_path, class: "btn btn-outline-secondary" %>
    </div>
  <% else %>
    <div class="row g-4">
      <% @paths.each do |path| %>
        <div class="col-md-4">
          <div class="card h-100">
            <div class="card-body">
              <h5 class="card-title"><%= path.name %></h5>
              <p class="card-text">
                <span class="badge bg-secondary"><%= path.community_type %></span>
                <span class="badge bg-secondary ms-1"><%= path.member_type %></span>
              </p>
              <p class="text-muted small"><%= path.path_activities.count %> activities</p>
            </div>
            <div class="card-footer d-flex justify-content-between align-items-center">
              <%= link_to "View", path_path(path), class: "btn btn-sm btn-outline-primary" %>
              <%= link_to "Delete", path_path(path),
                    data: { turbo_method: :delete, turbo_confirm: "Delete this path and all its activities?" },
                    class: "btn btn-sm btn-outline-danger" %>
            </div>
          </div>
        </div>
      <% end %>
    </div>
  <% end %>
</div>
```

### 4.2 — Wire dashboard recent paths list

In `app/views/dashboard/show.html.erb`, replace the placeholder "Recent Paths" card body with:

```erb
<div class="card h-100">
  <div class="card-header">Recent Paths</div>
  <% recent = current_user.onboarding_paths.order(created_at: :desc).limit(5) %>
  <% if recent.empty? %>
    <div class="card-body">
      <p class="text-muted mb-0">No paths yet.</p>
    </div>
  <% else %>
    <ul class="list-group list-group-flush">
      <% recent.each do |path| %>
        <li class="list-group-item d-flex justify-content-between align-items-center">
          <span>
            <%= link_to path.name, path_path(path) %>
            <small class="text-muted ms-2"><%= path.member_type %> · <%= path.community_type %></small>
          </span>
          <small class="text-muted"><%= path.created_at.strftime("%b %-d") %></small>
        </li>
      <% end %>
    </ul>
  <% end %>
</div>
```

Add `DashboardHelper#roots_tip` in `app/helpers/dashboard_helper.rb`:

```ruby
module DashboardHelper
  ROOTS_TIPS = [
    { root: "Relationships", tip: "Every new member needs at least one peer connection in the first two weeks. Schedule an introduction before the path is handed off." },
    { root: "Orientation",   tip: "New members absorb community history best through stories, not documents. Pair the written orientation with a conversation." },
    { root: "Opportunities", tip: "A small first contribution in week one builds ownership faster than any amount of observation." },
    { root: "Training",      tip: "Focus training on the vocabulary and tools the member needs to participate — not everything they will eventually need to know." },
    { root: "Stories",       tip: "Invite new members to share their own story early. It signals the community is interested in them, not just in onboarding them." }
  ].freeze

  def roots_tip
    ROOTS_TIPS.sample
  end
end
```

Replace the hardcoded tip card in `dashboard/show.html.erb` with:

```erb
<% tip = roots_tip %>
<div class="col-12">
  <div class="card border-0 bg-body-secondary">
    <div class="card-body">
      <h6 class="card-subtitle text-muted mb-1">Framework Tip · <%= tip[:root] %></h6>
      <p class="card-text mb-0"><%= tip[:tip] %></p>
    </div>
  </div>
</div>
```

### 4.3 — `app/views/paths/new.html.erb`

```erb
<div class="container py-4">
  <div class="row justify-content-center">
    <div class="col" style="max-width: 720px;">
      <h1 class="mb-4">Generate a New Path</h1>

      <% if @path.errors.any? %>
        <div class="alert alert-danger">
          <ul class="mb-0">
            <% @path.errors.full_messages.each do |msg| %>
              <li><%= msg %></li>
            <% end %>
          </ul>
        </div>
      <% end %>

      <%= form_with model: @path, url: paths_path,
            data: { controller: "form-submit", action: "submit->form-submit#submit" } do |f| %>

        <div class="mb-3">
          <%= f.label :community_type, class: "form-label" %>
          <%= f.select :community_type, OnboardingPath::COMMUNITY_TYPES,
                { include_blank: "Select community type" },
                { class: "form-select" } %>
        </div>

        <div class="mb-3">
          <%= f.label :member_type, class: "form-label" %>
          <%= f.select :member_type, OnboardingPath::MEMBER_TYPES,
                { include_blank: "Select member type" },
                { class: "form-select" } %>
        </div>

        <div class="mb-3"
             data-controller="character-count"
             data-character-count-max-value="1500">
          <%= f.label :member_background, class: "form-label" %>
          <small class="text-muted ms-2">Who is this person? What do they bring?</small>
          <%= f.text_area :member_background, rows: 4, class: "form-control",
                data: { character_count_target: "input", action: "input->character-count#update" } %>
          <small class="form-text text-muted" data-character-count-target="counter"></small>
        </div>

        <div class="mb-4"
             data-controller="character-count"
             data-character-count-max-value="300">
          <%= f.label :integration_goal, class: "form-label" %>
          <small class="text-muted ms-2">One sentence: what does success look like after 30 days?</small>
          <%= f.text_area :integration_goal, rows: 2, class: "form-control",
                data: { character_count_target: "input", action: "input->character-count#update" } %>
          <small class="form-text text-muted" data-character-count-target="counter"></small>
        </div>

        <%= f.submit "Generate path",
              class: "btn btn-lg",
              style: "background-color: var(--accent); color: white;",
              data: { form_submit_target: "button" } %>

        <small class="text-muted ms-3">This will use 1 of your daily AI calls.</small>
      <% end %>
    </div>
  </div>
</div>
```

> The `form-submit` and `character-count` Stimulus controllers are built in Phase 5. Adding the `data-` attributes now is correct — the page will render without errors even before the controllers exist.

### 4.4 — `app/views/paths/_root_map.html.erb`

This partial renders the decorative five-root SVG. It accepts a `activities_by_root` local hash.

```erb
<%# locals: (activities_by_root:) %>
<svg viewBox="0 0 800 300" class="root-map-svg" role="img" aria-label="R.O.O.T.S. root map">
  <title>
    R.O.O.T.S. root map:
    <% PathActivity::ROOT_SYSTEMS.each do |root| %>
      <%= root.capitalize %> (<%= activities_by_root[root]&.size || 0 %> activities),
    <% end %>
  </title>

  <%# Central trunk %>
  <line x1="400" y1="280" x2="400" y2="160" stroke="var(--accent)" stroke-width="4"/>

  <%# Five root paths with leaf labels %>
  <%
    roots = [
      { name: "relationships", x: 80,  y: 60,  cx1: 300, cy1: 160, cx2: 120, cy2: 100 },
      { name: "orientation",   x: 210, y: 30,  cx1: 350, cy1: 140, cx2: 240, cy2: 60  },
      { name: "opportunities", x: 400, y: 20,  cx1: 400, cy1: 120, cx2: 400, cy2: 50  },
      { name: "training",      x: 590, y: 30,  cx1: 450, cy1: 140, cx2: 560, cy2: 60  },
      { name: "stories",       x: 720, y: 60,  cx1: 500, cy1: 160, cx2: 680, cy2: 100 }
    ]
  %>

  <% roots.each do |r| %>
    <path d="M 400 160 C <%= r[:cx1] %> <%= r[:cy1] %>, <%= r[:cx2] %> <%= r[:cy2] %>, <%= r[:x] %> <%= r[:y] %>"
          fill="none"
          stroke="var(--root-<%= r[:name] %>)"
          stroke-width="3"/>
    <circle cx="<%= r[:x] %>" cy="<%= r[:y] %>" r="6" fill="var(--root-<%= r[:name] %>)"/>
    <text x="<%= r[:x] %>" y="<%= r[:y] - 12 %>"
          text-anchor="middle"
          fill="var(--root-<%= r[:name] %>)"
          font-size="11"
          font-weight="600">
      <%= r[:name].capitalize %>
    </text>
    <text x="<%= r[:x] %>" y="<%= r[:y] + 22 %>"
          text-anchor="middle"
          fill="var(--bs-body-color)"
          font-size="10">
      <%= activities_by_root[r[:name]]&.size || 0 %> activities
    </text>
  <% end %>
</svg>
```

### 4.5 — `app/views/paths/show.html.erb`

```erb
<div class="container py-4">
  <%# Header row %>
  <div class="d-flex justify-content-between align-items-start mb-4 flex-wrap gap-2">
    <h1><%= @path.name %></h1>
    <div class="d-flex gap-2 flex-wrap">
      <%= link_to "Edit", edit_path_path(@path), class: "btn btn-sm btn-outline-secondary" %>
      <%= button_to "Clone", clone_path_path(@path), method: :post, class: "btn btn-sm btn-outline-secondary" %>
      <%= link_to "Print", print_path_path(@path), class: "btn btn-sm btn-outline-secondary" %>
      <%= link_to "Delete", path_path(@path),
            data: { turbo_method: :delete, turbo_confirm: "Delete this path and all its activities?" },
            class: "btn btn-sm btn-outline-danger" %>
    </div>
  </div>

  <%# Input summary card %>
  <div class="card mb-4">
    <div class="card-body">
      <div class="row g-3">
        <div class="col-md-3">
          <div class="text-muted small">Community type</div>
          <div><%= @path.community_type %></div>
        </div>
        <div class="col-md-3">
          <div class="text-muted small">Member type</div>
          <div><%= @path.member_type %></div>
        </div>
        <div class="col-md-6">
          <div class="text-muted small">Integration goal</div>
          <div><%= @path.integration_goal %></div>
        </div>
        <div class="col-12">
          <div class="text-muted small">Member background</div>
          <div><%= @path.member_background %></div>
        </div>
      </div>
    </div>
  </div>

  <%# Root map SVG %>
  <div class="mb-4">
    <%= render "root_map", activities_by_root: @activities_by_root %>
  </div>

  <%# AI disclaimer %>
  <div class="alert alert-secondary mb-4" role="note">
    This path is a starting point, not a finished plan. Review each activity for fit with your
    community before sharing it with a new member.
  </div>

  <%# Weekly panels %>
  <% (1..4).each do |week| %>
    <div class="card mb-3 week-panel">
      <div class="card-header fw-semibold">Week <%= week %></div>
      <div class="card-body">
        <% activities = @activities_by_week[week] || [] %>
        <% if activities.empty? %>
          <p class="text-muted mb-0">No activities for this week.</p>
        <% else %>
          <div class="row g-3">
            <% activities.each do |activity| %>
              <div class="col-md-6">
                <div class="card h-100 bg-body-secondary border-0">
                  <div class="card-body">
                    <h6 class="card-title mb-1">
                      <%= activity.name %>
                      <span class="badge ms-1 badge-root-<%= activity.root_system %>">
                        <%= activity.root_system %>
                      </span>
                    </h6>
                    <p class="card-text small mb-1"><%= activity.description %></p>
                    <p class="card-text text-muted small mb-0">~<%= activity.estimated_minutes %> min</p>
                  </div>
                </div>
              </div>
            <% end %>
          </div>
        <% end %>
      </div>
    </div>
  <% end %>

  <%# Raw response toggle — only show if gemini_raw is present %>
  <% if @path.gemini_raw.present? %>
    <div class="mt-4">
      <button class="btn btn-sm btn-outline-secondary"
              type="button"
              data-bs-toggle="collapse"
              data-bs-target="#raw-response">
        Show raw Gemini response
      </button>
      <div id="raw-response" class="collapse mt-2">
        <pre class="bg-body-secondary p-3 rounded small"><%= @path.gemini_raw %></pre>
      </div>
    </div>
  <% end %>
</div>
```

### 4.6 — `app/views/paths/edit.html.erb`

```erb
<div class="container py-4">
  <div class="row justify-content-center">
    <div class="col" style="max-width: 600px;">
      <h1 class="mb-4">Edit Path</h1>

      <div class="alert alert-secondary mb-4">
        To regenerate activities with different inputs, clone this path or create a new one.
      </div>

      <% if @path.errors.any? %>
        <div class="alert alert-danger">
          <ul class="mb-0">
            <% @path.errors.full_messages.each do |msg| %>
              <li><%= msg %></li>
            <% end %>
          </ul>
        </div>
      <% end %>

      <%= form_with model: @path, url: path_path(@path), method: :patch do |f| %>
        <div class="mb-3">
          <%= f.label :name, class: "form-label" %>
          <%= f.text_field :name, class: "form-control" %>
        </div>

        <div class="mb-4">
          <%= f.label :integration_goal, class: "form-label" %>
          <%= f.text_area :integration_goal, rows: 3, class: "form-control" %>
        </div>

        <div class="d-flex gap-2">
          <%= f.submit "Save changes", class: "btn btn-primary" %>
          <%= link_to "Cancel", path_path(@path), class: "btn btn-outline-secondary" %>
        </div>
      <% end %>
    </div>
  </div>
</div>
```

### 4.7 — Update `home/index.html.erb`

Replace the `[Five-root illustration — added in Phase 4]` placeholder div with a live render of the root map partial, passing an empty hash so the home page shows all roots with 0 activities (decorative only):

```erb
<div class="mb-4">
  <%= render "paths/root_map", activities_by_root: {} %>
</div>
```

---

## RSpec

No new spec files in this phase. After completing views, run:

```
bundle exec rspec
```

Verify all existing specs still pass (no view regressions).

---

## Manual Checks

After `bin/dev` (seed data from Phase 8 will not be available yet — test with manually created records):

- [ ] `/paths` shows empty state with CTA button for a new user
- [ ] `/paths` shows path cards after cloning the seeded path or manually creating a path record in `rails console`
- [ ] `/paths/new` renders with all four fields — selects for community and member type, textareas for background and goal
- [ ] `/paths/new` shows character counter placeholder `<small>` elements below both textareas (counters will be blank until Phase 5 adds the JS)
- [ ] Show page renders with four weekly panels, root map SVG, and the input summary card
- [ ] Activity cards on show page display the root badge with the correct CSS class (`badge-root-relationships` etc.)
- [ ] "Show raw response" toggle only appears if `gemini_raw` is non-null
- [ ] Bootstrap collapse for raw response works (click toggles visibility)
- [ ] Edit page shows only `name` and `integration_goal` fields
- [ ] Edit form submits and redirects to show page with updated values
- [ ] Clone button creates a copy; new path appears at `/paths` with " (copy)" appended to the name
- [ ] Delete button with confirmation destroys the path and redirects to `/paths`
- [ ] Dashboard recent paths list shows up to 5 paths with formatted dates
- [ ] Dashboard tip card shows a R.O.O.T.S. tip (root name in subtitle)
- [ ] Home page decorative root map renders (all 5 root labels visible, all showing 0 activities)
