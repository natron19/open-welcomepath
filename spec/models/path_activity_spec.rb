require "rails_helper"

RSpec.describe PathActivity, type: :model do
  describe "validations" do
    it "is valid with valid attributes" do
      expect(build(:path_activity)).to be_valid
    end

    it "requires name" do
      expect(build(:path_activity, name: nil)).not_to be_valid
    end

    it "requires description" do
      expect(build(:path_activity, description: nil)).not_to be_valid
    end

    it "requires estimated_minutes" do
      expect(build(:path_activity, estimated_minutes: nil)).not_to be_valid
    end

    it "requires week_number" do
      expect(build(:path_activity, week_number: nil)).not_to be_valid
    end

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

    it "rejects week_number 0" do
      expect(build(:path_activity, week_number: 0)).not_to be_valid
    end

    it "rejects week_number 5" do
      expect(build(:path_activity, week_number: 5)).not_to be_valid
    end

    it "rejects estimated_minutes of 0" do
      expect(build(:path_activity, estimated_minutes: 0)).not_to be_valid
    end

    it "rejects estimated_minutes greater than 240" do
      expect(build(:path_activity, estimated_minutes: 241)).not_to be_valid
    end

    it "accepts estimated_minutes of 1" do
      expect(build(:path_activity, estimated_minutes: 1)).to be_valid
    end

    it "accepts estimated_minutes of 240" do
      expect(build(:path_activity, estimated_minutes: 240)).to be_valid
    end
  end

  describe "associations" do
    it "belongs to an onboarding_path" do
      activity = build(:path_activity)
      expect(activity.onboarding_path).to be_a(OnboardingPath)
    end
  end
end
