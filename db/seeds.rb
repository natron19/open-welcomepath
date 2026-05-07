# Admin user — credentials for local demo use only
User.find_or_create_by!(email: "demo@example.com") do |u|
  u.name                  = "Demo User"
  u.password              = "password123"
  u.password_confirmation = "password123"
  u.admin                 = true
end

puts "Demo user: demo@example.com / password123"

# Health ping template — used by /up/llm
AiTemplate.find_or_create_by!(name: "health_ping") do |t|
  t.description          = "Minimal prompt used by the /up/llm health check endpoint."
  t.system_prompt        = "You are a health check endpoint. Respond with exactly: ok"
  t.user_prompt_template = "ping"
  t.model                = "gemini-2.5-flash"
  t.max_output_tokens    = 10
  t.temperature          = 0.0
  t.notes                = "Do not modify. Used by HealthController#llm."
end

puts "Seeded: health_ping AI template"

# Placeholder demo template — each demo app replaces this
AiTemplate.find_or_create_by!(name: "demo_placeholder_v1") do |t|
  t.description          = "Starter template. Replace with your demo's actual prompt."
  t.system_prompt        = "You are a helpful assistant."
  t.user_prompt_template = "Please help me with: {{request}}"
  t.model                = "gemini-2.5-flash"
  t.max_output_tokens    = 2000
  t.temperature          = 0.7
  t.notes                = "Starter template. Replace this in your demo app's seeds.rb."
end

puts "Seeded: demo_placeholder_v1 AI template"

# WelcomePath Demo — path generation template
AiTemplate.find_or_create_by!(name: "welcomepath_path_v1") do |t|
  t.description      = "Generates a 30-day R.O.O.T.S. onboarding path for a new community member."
  t.model            = "gemini-2.5-flash"
  t.max_output_tokens = 3000
  t.temperature      = 0.5

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

puts "Seeded: welcomepath_path_v1 AI template"

# Sample onboarding path for demo user
ActiveRecord::Base.transaction do
  demo_user = User.find_by(email: "demo@example.com")
  next unless demo_user

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
