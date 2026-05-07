FactoryBot.define do
  factory :path_activity do
    association :onboarding_path
    root_system       { "relationships" }
    name              { "Coffee chat with a current member" }
    description       { "Reach out to one current member who shares your background and schedule a 30-minute video call or coffee." }
    estimated_minutes { 30 }
    week_number       { 1 }
    position          { 0 }

    trait :orientation   do; root_system { "orientation" }; end
    trait :opportunities do; root_system { "opportunities" }; end
    trait :training      do; root_system { "training" }; end
    trait :stories       do; root_system { "stories" }; end
  end
end
