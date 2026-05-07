FactoryBot.define do
  factory :onboarding_path do
    association :user
    name              { "Newcomer path for nonprofit" }
    community_type    { "nonprofit" }
    member_type       { "newcomer" }
    member_background { "Twenty-something professional, recently relocated, background in marketing, no prior nonprofit involvement, looking to build community in a new city." }
    integration_goal  { "Feel like a contributing member within 30 days with at least one strong peer connection." }
    gemini_raw        { nil }

    trait :with_activities do
      after(:create) do |path|
        PathActivity::ROOT_SYSTEMS.each_with_index do |root, root_idx|
          2.times do |i|
            create(:path_activity,
              onboarding_path: path,
              root_system:     root,
              week_number:     (root_idx % 4) + 1,
              position:        i
            )
          end
        end
      end
    end
  end
end
