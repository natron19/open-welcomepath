require "rails_helper"

RSpec.describe OnboardingPath, type: :model do
  describe "validations" do
    it "is valid with valid attributes" do
      expect(build(:onboarding_path)).to be_valid
    end

    it "requires community_type" do
      expect(build(:onboarding_path, community_type: nil)).not_to be_valid
    end

    it "requires member_type" do
      expect(build(:onboarding_path, member_type: nil)).not_to be_valid
    end

    it "requires member_background" do
      expect(build(:onboarding_path, member_background: nil)).not_to be_valid
    end

    it "requires integration_goal" do
      expect(build(:onboarding_path, integration_goal: nil)).not_to be_valid
    end

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

    it "accepts member_background at exactly 1500 characters" do
      expect(build(:onboarding_path, member_background: "a" * 1500)).to be_valid
    end

    it "rejects integration_goal shorter than 10 characters" do
      expect(build(:onboarding_path, integration_goal: "Short.")).not_to be_valid
    end

    it "accepts integration_goal at exactly 10 characters" do
      expect(build(:onboarding_path, integration_goal: "a" * 10)).to be_valid
    end

    it "rejects integration_goal longer than 300 characters" do
      expect(build(:onboarding_path, integration_goal: "a" * 301)).not_to be_valid
    end

    it "accepts integration_goal at exactly 300 characters" do
      expect(build(:onboarding_path, integration_goal: "a" * 300)).to be_valid
    end
  end

  describe "associations" do
    it "belongs to a user" do
      path = build(:onboarding_path)
      expect(path.user).to be_a(User)
    end

    it "has many path_activities" do
      path = create(:onboarding_path, :with_activities)
      expect(path.path_activities.count).to eq(10)
    end

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
