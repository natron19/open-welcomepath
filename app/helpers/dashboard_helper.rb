module DashboardHelper
  ROOTS_TIPS = [
    { root: "Relationships", tip: "Every new member needs at least one peer connection in the first two weeks. Schedule an introduction before the path is handed off." },
    { root: "Orientation",   tip: "New members absorb community history best through stories, not documents. Pair the written orientation with a conversation." },
    { root: "Opportunities", tip: "A small first contribution in week one builds ownership faster than any amount of observation." },
    { root: "Training",      tip: "Focus training on the vocabulary and tools the member needs to participate — not everything they will eventually need to know." },
    { root: "Stories",       tip: "Invite new members to share their own story early. It signals the community is interested in them, not just in onboarding them." }
  ].freeze

  def roots_tip
    ROOTS_TIPS.sample
  end
end
