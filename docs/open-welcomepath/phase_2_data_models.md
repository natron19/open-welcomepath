# Phase 2 — Data Models: Migrations, Models, Factories

**Goal:** `OnboardingPath` and `PathActivity` are fully defined with correct schema, validations, associations, indexes, and helper methods. No controller or view work yet.

**Prerequisite:** Phase 1 complete. Boilerplate RSpec suite passes.

**Spec reference:** `docs/open-welcomepath/welcomepath-demo-spec.md` section 3.

---

## Tasks

### 2.1 — Migration: `onboarding_paths`

```bash
rails generate migration CreateOnboardingPaths \
  user_id:uuid:index \
  name:string \
  community_type:string \
  member_type:string \
  member_background:text \
  integration_goal:text \
  gemini_raw:text
```

Edit the generated migration:
- Add `id: :uuid` to `create_table`
- Add `null: false` to both timestamps
- Confirm `pgcrypto` extension is already enabled (check `schema.rb` — it was added in the boilerplate Phase 1 migration)

### 2.2 — Migration: `path_activities`

```bash
rails generate migration CreatePathActivities \
  onboarding_path_id:uuid \
  root_system:string \
  name:string \
  description:text \
  estimated_minutes:integer \
  week_number:integer \
  position:integer
```

Edit the generated migration:
- Add `id: :uuid` to `create_table`
- Add `null: false` to timestamps
- Add `add_index :path_activities, [:onboarding_path_id, :root_system, :position]`
- Add `add_index :path_activities, [:onboarding_path_id, :week_number]`

### 2.3 — Run migrations

```bash
rails db:migrate
```

Verify `schema.rb` shows both tables with UUID PKs and all expected indexes.

### 2.4 — `app/models/onboarding_path.rb`

```ruby
class OnboardingPath < ApplicationRecord
  COMMUNITY_TYPES = [
    "faith community",
    "nonprofit",
    "workplace",
    "coworking space",
    "professional network"
  ].freeze

  MEMBER_TYPES = [
    "newcomer",
    "new hire",
    "new family",
    "new cohort student"
  ].freeze

  belongs_to :user
  has_many :path_activities, dependent: :destroy

  validates :community_type,    presence: true, inclusion: { in: COMMUNITY_TYPES }
  validates :member_type,       presence: true, inclusion: { in: MEMBER_TYPES }
  validates :member_background, presence: true, length: { minimum: 20, maximum: 1500 }
  validates :integration_goal,  presence: true, length: { minimum: 10, maximum: 300 }

  def activities_by_root
    path_activities.order(:position).group_by(&:root_system)
  end

  def activities_by_week
    path_activities.order(:position).group_by(&:week_number)
  end
end
```

### 2.5 — `app/models/path_activity.rb`

```ruby
class PathActivity < ApplicationRecord
  ROOT_SYSTEMS = %w[relationships orientation opportunities training stories].freeze

  belongs_to :onboarding_path

  validates :root_system,       presence: true, inclusion: { in: ROOT_SYSTEMS }
  validates :name,              presence: true
  validates :description,       presence: true
  validates :estimated_minutes, presence: true,
            numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 240 }
  validates :week_number,       presence: true, inclusion: { in: [1, 2, 3, 4] }
end
```

### 2.6 — Update `User` model

Add to `app/models/user.rb`:

```ruby
has_many :onboarding_paths, dependent: :destroy
```

### 2.7 — Factory: `spec/factories/onboarding_paths.rb`

```ruby
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
              root_system: root,
              week_number: (root_idx % 4) + 1,
              position: i
            )
          end
        end
      end
    end
  end
end
```

### 2.8 — Factory: `spec/factories/path_activities.rb`

```ruby
FactoryBot.define do
  factory :path_activity do
    association :onboarding_path
    root_system       { "relationships" }
    name              { "Coffee chat with a current member" }
    description       { "Reach out to one current member who shares your background and schedule a 30-minute video call or coffee." }
    estimated_minutes { 30 }
    week_number       { 1 }
    position          { 0 }

    trait :orientation   { root_system { "orientation" } }
    trait :opportunities { root_system { "opportunities" } }
    trait :training      { root_system { "training" } }
    trait :stories       { root_system { "stories" } }
  end
end
```

---

## RSpec

Write `spec/models/onboarding_path_spec.rb`:

```ruby
RSpec.describe OnboardingPath, type: :model do
  subject { build(:onboarding_path) }

  describe "validations" do
    it { should validate_presence_of(:community_type) }
    it { should validate_presence_of(:member_type) }
    it { should validate_presence_of(:member_background) }
    it { should validate_presence_of(:integration_goal) }

    it "accepts valid community_type values" do
      OnboardingPath::COMMUNITY_TYPES.each do |type|
        expect(build(:onboarding_path, community_type: type)).to be_valid
      end
    end

    it "rejects an unknown community_type" do
      expect(build(:onboarding_path, community_type: "moon base")).not_to be_valid
    end

    it "accepts valid member_type values" do
      OnboardingPath::MEMBER_TYPES.each do |type|
        expect(build(:onboarding_path, member_type: type)).to be_valid
      end
    end

    it "rejects an unknown member_type" do
      expect(build(:onboarding_path, member_type: "robot")).not_to be_valid
    end

    it "rejects member_background shorter than 20 characters" do
      expect(build(:onboarding_path, member_background: "Too short.")).not_to be_valid
    end

    it "accepts member_background at exactly 20 characters" do
      expect(build(:onboarding_path, member_background: "a" * 20)).to be_valid
    end

    it "rejects member_background longer than 1500 characters" do
      expect(build(:onboarding_path, member_background: "a" * 1501)).not_to be_valid
    end

    it "rejects integration_goal shorter than 10 characters" do
      expect(build(:onboarding_path, integration_goal: "Short.")).not_to be_valid
    end

    it "rejects integration_goal longer than 300 characters" do
      expect(build(:onboarding_path, integration_goal: "a" * 301)).not_to be_valid
    end
  end

  describe "associations" do
    it { should belong_to(:user) }
    it { should have_many(:path_activities).dependent(:destroy) }

    it "cascades activity deletion when path is destroyed" do
      path = create(:onboarding_path, :with_activities)
      expect { path.destroy }.to change(PathActivity, :count).by(-10)
    end
  end

  describe "#activities_by_root" do
    it "returns a hash keyed by root system" do
      path = create(:onboarding_path, :with_activities)
      result = path.activities_by_root
      expect(result.keys).to match_array(PathActivity::ROOT_SYSTEMS)
    end

    it "each root key contains only activities for that root" do
      path = create(:onboarding_path, :with_activities)
      path.activities_by_root.each do |root, activities|
        expect(activities.map(&:root_system).uniq).to eq([root])
      end
    end
  end

  describe "#activities_by_week" do
    it "returns activities grouped by week_number" do
      path = create(:onboarding_path, :with_activities)
      result = path.activities_by_week
      result.each do |week, activities|
        expect(activities.map(&:week_number).uniq).to eq([week])
      end
    end
  end
end
```

Write `spec/models/path_activity_spec.rb`:

```ruby
RSpec.describe PathActivity, type: :model do
  subject { build(:path_activity) }

  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:description) }
    it { should validate_presence_of(:estimated_minutes) }
    it { should validate_presence_of(:week_number) }

    it "accepts all valid root_system values" do
      PathActivity::ROOT_SYSTEMS.each do |root|
        expect(build(:path_activity, root_system: root)).to be_valid
      end
    end

    it "rejects an unknown root_system" do
      expect(build(:path_activity, root_system: "magic")).not_to be_valid
    end

    it "accepts week_number in 1..4" do
      (1..4).each do |n|
        expect(build(:path_activity, week_number: n)).to be_valid
      end
    end

    it "rejects week_number 0 and 5" do
      expect(build(:path_activity, week_number: 0)).not_to be_valid
      expect(build(:path_activity, week_number: 5)).not_to be_valid
    end

    it "rejects estimated_minutes of 0" do
      expect(build(:path_activity, estimated_minutes: 0)).not_to be_valid
    end

    it "rejects estimated_minutes greater than 240" do
      expect(build(:path_activity, estimated_minutes: 241)).not_to be_valid
    end

    it "accepts estimated_minutes at the boundary values 1 and 240" do
      expect(build(:path_activity, estimated_minutes: 1)).to be_valid
      expect(build(:path_activity, estimated_minutes: 240)).to be_valid
    end
  end

  describe "associations" do
    it { should belong_to(:onboarding_path) }
  end
end
```

---

## Manual Checks

In `rails console`:

- [ ] `OnboardingPath.new.valid?` → `false`
- [ ] `OnboardingPath.new(community_type: "nonprofit", member_type: "newcomer", member_background: "Short.", integration_goal: "Short.").valid?` → `false` (background too short, goal too short)
- [ ] Create a valid path and add 5 activities; call `.activities_by_root` and verify the hash has all 5 root keys
- [ ] Call `.activities_by_week` and verify the hash keys are integers 1..4
- [ ] Destroy the path and verify `PathActivity.count` dropped by 5
- [ ] Verify `User.first.onboarding_paths` returns an ActiveRecord relation (not error)
- [ ] Run `bundle exec rspec spec/models/` — both new model specs pass alongside the boilerplate model specs
