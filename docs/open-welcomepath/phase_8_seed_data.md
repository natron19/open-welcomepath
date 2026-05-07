# Phase 8 — Seed Data: Sample Path for Demo User

**Goal:** After `rails db:seed`, the demo user has one complete sample path with realistic activities across all five roots and all four weeks, so the show page renders meaningfully on first run without requiring a Gemini API call.

**Prerequisite:** Phase 7 complete. Phase 6 seed already created the `welcomepath_path_v1` AI template.

**Spec reference:** `docs/open-welcomepath/welcomepath-demo-spec.md` section 10.

---

## Tasks

### 8.1 — Sample path and activities in `db/seeds.rb`

Add below the AI template seed (the demo user is already created by the boilerplate seed):

```ruby
ActiveRecord::Base.transaction do
  demo_user = User.find_by(email: "demo@example.com")
  next unless demo_user  # guard: skip if demo user was not seeded

  if demo_user.onboarding_paths.empty?
    sample_path = demo_user.onboarding_paths.create!(
      name:              "Newcomer path for nonprofit",
      community_type:    "nonprofit",
      member_type:       "newcomer",
      member_background: "Twenty-something, recently relocated, professional background in marketing, no prior nonprofit involvement, looking to build community connections in a new city.",
      integration_goal:  "Feel like a contributing member of the community within 30 days, with at least one strong peer connection and a clear way to help.",
      gemini_raw:        <<~JSON.strip
        {
          "relationships": [
            {"name": "Coffee chat with a current member", "description": "Reach out to one current member who shares your background and schedule a 30-minute video call or coffee to learn about their experience.", "estimated_minutes": 30, "week_number": 1},
            {"name": "Attend a community social event", "description": "Show up to the next informal gathering. Introduce yourself to at least three people and follow up with one connection you made.", "estimated_minutes": 90, "week_number": 2},
            {"name": "Request a mentor pairing", "description": "Ask the onboarding coordinator to pair you with a more experienced member in a similar role for a monthly check-in through your first quarter.", "estimated_minutes": 20, "week_number": 3}
          ],
          "orientation": [
            {"name": "Read the community history document", "description": "Review the organization's founding story, current priorities, and community norms. Note three things you find surprising or that you want to ask about.", "estimated_minutes": 45, "week_number": 1},
            {"name": "Shadow a current member for a day", "description": "Observe how an experienced member navigates a typical work session — what tools they use, how they communicate, and what decisions they make.", "estimated_minutes": 120, "week_number": 2}
          ],
          "opportunities": [
            {"name": "Take on a small first task", "description": "Volunteer for one clearly scoped task that can be completed in a week. Completing it builds ownership and signals you are ready for more.", "estimated_minutes": 60, "week_number": 2},
            {"name": "Attend a working group meeting", "description": "Sit in on one active working group as an observer. Introduce yourself at the start and ask one question at the end.", "estimated_minutes": 60, "week_number": 3},
            {"name": "Propose a small improvement", "description": "Identify one thing that confused you during onboarding and suggest a simple way to make it clearer for the next new member.", "estimated_minutes": 30, "week_number": 4}
          ],
          "training": [
            {"name": "Learn the essential vocabulary", "description": "Review the glossary of terms the community uses regularly. Create a personal reference card with the 10 terms most relevant to your role.", "estimated_minutes": 30, "week_number": 1},
            {"name": "Tool orientation session", "description": "Schedule a one-hour walkthrough of the tools you will use day-to-day with someone who can answer questions in real time.", "estimated_minutes": 60, "week_number": 1},
            {"name": "Observe a decision-making process", "description": "Sit in on a meeting where a real decision is being made. Pay attention to how dissent is handled and how consensus is reached.", "estimated_minutes": 60, "week_number": 3}
          ],
          "stories": [
            {"name": "Read the founding story", "description": "Learn how and why the community was started. Understanding the origin helps you speak authentically about why you joined.", "estimated_minutes": 20, "week_number": 1},
            {"name": "Share your own story", "description": "At an appropriate moment in week 3 — a team meeting, a one-on-one, or a community channel — briefly share what brought you here and what you hope to contribute.", "estimated_minutes": 10, "week_number": 3},
            {"name": "Collect a recent win story", "description": "Ask one current member to tell you about a recent success the community is proud of. This gives you something concrete to share when you tell others about the organization.", "estimated_minutes": 20, "week_number": 4}
          ]
        }
      JSON
    )

    # Build the activities from the seeded gemini_raw
    activities_data = JSON.parse(sample_path.gemini_raw)
    PathActivity::ROOT_SYSTEMS.each do |root|
      Array(activities_data[root]).each_with_index do |a, idx|
        sample_path.path_activities.create!(
          root_system:       root,
          name:              a["name"],
          description:       a["description"],
          estimated_minutes: a["estimated_minutes"].to_i,
          week_number:       a["week_number"].to_i,
          position:          idx
        )
      end
    end

    puts "  Created sample OnboardingPath for demo@example.com (#{sample_path.path_activities.count} activities)"
  end
end
```

### 8.2 — Run seeds

```bash
rails db:seed
```

If the database already has data from development, reset first:

```bash
rails db:reset  # drops, recreates, migrates, seeds
```

---

## RSpec

No new spec files in this phase. Run the full suite to confirm seeds do not introduce any model validation errors:

```
bundle exec rspec
```

---

## Manual Checks

After `rails db:seed` and `bin/dev`:

- [ ] Sign in as `demo@example.com` / `password123`
- [ ] Navigate to `/paths` — one path card is visible: "Newcomer path for nonprofit"
- [ ] Navigate to the path show page — all five root sections appear in the SVG map with activity counts
- [ ] All four weekly panels have at least one activity
- [ ] "Show raw response" toggle reveals the hand-crafted JSON (the multi-root structure is visible)
- [ ] Navigate to `/paths/:id/print` — renders cleanly with all activities, no navbar, no footer
- [ ] Clone the seeded path — clone appears at `/paths` with " (copy)" in the name and all 11 activities are duplicated
- [ ] Delete the original path — cascade removes all activities, redirect to `/paths`, clone remains
- [ ] Run `rails db:seed` a second time — no duplicate path is created (the `if demo_user.onboarding_paths.empty?` guard prevents it)
