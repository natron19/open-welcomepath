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
