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
