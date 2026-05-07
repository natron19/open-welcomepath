# Phase 6 — AI Integration: Template Seed, Create Action, JSON Parsing

**Goal:** The full Gemini integration is wired. Submitting the new path form calls Gemini, parses the JSON response, persists `OnboardingPath` and all `PathActivity` records in one transaction, and shows meaningful errors on every failure path.

**Prerequisite:** Phases 1–5 complete. A valid `GEMINI_API_KEY` is set in `.env`.

**Required reading before this phase:**
- `docs/ai-templates.md` — `GeminiService.generate` call signature, error classes
- `docs/ai-guardrails.md` — what `AiGatekeeper` and `AiBudgetChecker` enforce automatically

**Spec reference:** `docs/open-welcomepath/welcomepath-demo-spec.md` sections 7 and 8.

---

## Tasks

### 6.1 — Seed the AI template

In `db/seeds.rb`, add after the existing boilerplate seeds:

```ruby
AiTemplate.find_or_create_by!(name: "welcomepath_path_v1") do |t|
  t.description = "Generates a 30-day R.O.O.T.S. onboarding path for a new community member."
  t.model = "gemini-2.5-flash"
  t.max_output_tokens = 3000
  t.temperature = 0.5

  t.system_prompt = <<~PROMPT.strip
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
  PROMPT

  t.user_prompt_template = <<~PROMPT.strip
    Community type: {{community_type}}
    New member type: {{member_type}}
    Member background: {{member_background}}
    Integration goal: {{integration_goal}}

    Generate the R.O.O.T.S. path now. Return JSON only.
  PROMPT

  t.notes = <<~NOTES.strip
    The system prompt's structural constraint ("you cannot produce a path that skips a root") is the lever that makes this template reliable. Without it, Gemini occasionally returns three or four roots and skips one.

    Watch for: descriptions creeping over three sentences. Estimated minutes occasionally come back as 0 or as strings — the parser coerces and rejects. Activity names occasionally start with "Have a..." which feels weak; tighten the prompt with example names if this becomes a pattern.

    Known failure mode: when the integration goal is generic (e.g., "feel welcome"), the activities skew generic. The fix is in the input, not the prompt.
  NOTES
end
```

### 6.2 — Run seed

```bash
rails db:seed
```

Verify the template appears at `/admin/ai_templates`. Use the admin test panel to run a live test with sample variables before writing the controller code.

### 6.3 — Rewrite `PathsController#create`

Replace the `NotImplementedError` placeholder from Phase 3:

```ruby
def create
  @path = current_user.onboarding_paths.build(path_params)
  return render :new, status: :unprocessable_entity unless @path.valid?

  raw = GeminiService.generate(
    template:  "welcomepath_path_v1",
    variables: {
      community_type:    @path.community_type,
      member_type:       @path.member_type,
      member_background: @path.member_background,
      integration_goal:  @path.integration_goal
    }
  )

  ActiveRecord::Base.transaction do
    @path.gemini_raw = raw
    @path.save!
    parse_and_save_activities!(raw, @path)
  end

  redirect_to path_path(@path), notice: "Path generated!"

rescue PathsController::ParseError => e
  @parse_error_message = e.message
  render :new, status: :unprocessable_entity
rescue GeminiService::BudgetExceededError
  render partial: "shared/ai_error", locals: { error_type: :budget_exceeded }
rescue GeminiService::GatekeeperError
  render partial: "shared/ai_error", locals: { error_type: :gatekeeper_blocked }
rescue GeminiService::TimeoutError
  render partial: "shared/ai_error", locals: { error_type: :timeout }
rescue GeminiService::GeminiError
  render partial: "shared/ai_error", locals: { error_type: :error }
end
```

### 6.4 — `parse_and_save_activities!` private method

Add to `PathsController` private section:

```ruby
def parse_and_save_activities!(raw, path)
  data = JSON.parse(raw)
rescue JSON::ParserError
  raise ParseError, "Gemini returned invalid JSON. Please try again."
else
  PathActivity::ROOT_SYSTEMS.each do |root|
    unless data.key?(root)
      raise ParseError, "Gemini response missing '#{root}' root section."
    end

    Array(data[root]).each_with_index do |activity, idx|
      minutes = activity["estimated_minutes"].to_i
      unless minutes.between?(1, 240)
        next  # skip activities with invalid minutes rather than failing the whole path
      end

      path.path_activities.create!(
        root_system:       root,
        name:              activity["name"].to_s.truncate(120),
        description:       activity["description"].to_s,
        estimated_minutes: minutes,
        week_number:       activity["week_number"].to_i.clamp(1, 4),
        position:          idx
      )
    end
  end
end
```

### 6.5 — Show parse error in `paths/new.html.erb`

Add above the form (after the `@path.errors` block):

```erb
<% if @parse_error_message.present? %>
  <div class="alert alert-warning">
    <strong>Could not process the AI response.</strong> <%= @parse_error_message %>
    Try submitting the form again — this is usually a one-time parsing issue.
  </div>
<% end %>
```

### 6.6 — Rate limiting on `create`

Add to `PathsController` (before any `before_action`):

```ruby
rate_limit to: 5, within: 1.minute, only: [:create],
           with: -> { redirect_to new_path_path, alert: "Please wait before generating again." }
```

---

## RSpec

These specs are written in full in Phase 9, but after wiring the AI integration, verify these manually and with targeted specs before moving on:

```ruby
# Quick smoke test — add to spec/requests/paths_spec.rb
describe "POST /paths with valid params and stubbed Gemini" do
  let(:valid_json) do
    roots = %w[relationships orientation opportunities training stories]
    roots.index_with do |_|
      [{ "name" => "Activity", "description" => "Do the thing.", "estimated_minutes" => 30, "week_number" => 1 }]
    end.to_json
  end

  before do
    sign_in_as(user)
    allow(GeminiService).to receive(:generate).and_return(valid_json)
  end

  it "creates the path and redirects to show" do
    post paths_path, params: { onboarding_path: {
      community_type:    "nonprofit",
      member_type:       "newcomer",
      member_background: "A twenty-something professional new to the city looking to connect.",
      integration_goal:  "Feel like a contributing member within 30 days."
    }}
    expect(response).to redirect_to(path_path(OnboardingPath.last))
    expect(OnboardingPath.count).to eq(1)
    expect(PathActivity.count).to eq(5)
  end
end
```

Run: `bundle exec rspec spec/requests/paths_spec.rb`

---

## Manual Checks

Requires a valid `GEMINI_API_KEY` in `.env`.

- [ ] Test the template in the admin panel first: `/admin/ai_templates` → click `welcomepath_path_v1` → fill in test variables → Run Test → verify JSON output with all 5 root keys
- [ ] Submit `/paths/new` with valid inputs — verify redirect to show page with all 5 root sections populated and weekly panels with activities
- [ ] Check `/admin/llm_requests` — a `success` entry should appear with token counts
- [ ] Verify "Show raw response" toggle on the show page reveals the actual JSON from Gemini
- [ ] Temporarily set `AI_CALLS_PER_USER_PER_DAY=0` in `.env`, restart `bin/dev`, submit the form — verify the budget error partial renders (not a 500)
- [ ] Restore the daily limit and submit with `member_background` under 20 characters — form re-renders with validation errors, Gemini is NOT called (verify no new `LlmRequest` row was created)
- [ ] Submit the form rapidly 6 times in under a minute — 6th submit should redirect with the rate-limit alert
