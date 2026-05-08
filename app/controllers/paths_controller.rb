class PathsController < ApplicationController
  ParseError = Class.new(StandardError)

  rate_limit to: 5, within: 1.minute, only: [:create],
             with: -> { redirect_to new_path_path, alert: "Please wait before generating again." }

  before_action :set_path, only: [:show, :edit, :update, :destroy, :clone, :print]
  before_action :set_path_activities, only: [:show, :print]

  def index
    @paths = current_user.onboarding_paths.order(created_at: :desc)
  end

  def new
    @path = OnboardingPath.new
    if (last = current_user.onboarding_paths.order(created_at: :desc).first)
      @path.community_type = last.community_type
      @path.member_type    = last.member_type
    end
  end

  def create
    @path = current_user.onboarding_paths.build(path_params)
    return render :new, status: :unprocessable_entity unless @path.valid?

    raw = GeminiService.generate(
      template:  "welcomepath_path_v1",
      variables: {
        community_type:    @path.community_type,
        member_type:       @path.member_type,
        member_background: @path.member_background,
        integration_goal:  @path.integration_goal
      }
    )

    ActiveRecord::Base.transaction do
      @path.gemini_raw = raw
      @path.save!
      parse_and_save_activities!(raw, @path)
    end

    redirect_to path_path(@path), notice: "Path generated!"

  rescue PathsController::ParseError => e
    @parse_error_message = e.message
    render :new, status: :unprocessable_entity
  rescue GeminiService::BudgetExceededError
    render partial: "shared/ai_error", locals: { error_type: :budget_exceeded }
  rescue GeminiService::GatekeeperError
    render partial: "shared/ai_error", locals: { error_type: :gatekeeper_blocked }
  rescue GeminiService::TimeoutError
    render partial: "shared/ai_error", locals: { error_type: :timeout }
  rescue GeminiService::GeminiError
    render partial: "shared/ai_error", locals: { error_type: :error }
  end

  def show; end

  def edit; end

  def update
    if @path.update(path_params.slice(:name, :integration_goal))
      redirect_to path_path(@path), notice: "Path updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @path.destroy
    redirect_to paths_path, notice: "Path deleted."
  end

  def clone
    cloned_path = nil
    ActiveRecord::Base.transaction do
      cloned_path = @path.dup
      cloned_path.name = "#{@path.name} (copy)"
      cloned_path.save!
      @path.path_activities.each do |activity|
        cloned = activity.dup
        cloned.onboarding_path = cloned_path
        cloned.save!
      end
    end
    redirect_to path_path(cloned_path), notice: "Path cloned."
  end

  def print
    render :print, layout: "print"
  end

  private

  def set_path
    @path = current_user.onboarding_paths.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render file: Rails.public_path.join("404.html"), status: :not_found, layout: false
  end

  def set_path_activities
    @activities_by_root = @path.activities_by_root
    @activities_by_week = @path.activities_by_week
  end

  def parse_and_save_activities!(raw, path)
    cleaned = raw.gsub(/\A```(?:json)?\s*/, "").gsub(/\s*```\z/, "").strip
    data = JSON.parse(cleaned)
  rescue JSON::ParserError
    raise ParseError, "Gemini returned invalid JSON. Please try again."
  else
    PathActivity::ROOT_SYSTEMS.each do |root|
      unless data.key?(root)
        raise ParseError, "Gemini response missing '#{root}' root section."
      end

      Array(data[root]).each_with_index do |activity, idx|
        minutes = activity["estimated_minutes"].to_i
        next unless minutes.between?(1, 240)

        path.path_activities.create!(
          root_system:       root,
          name:              activity["name"].to_s.truncate(120),
          description:       activity["description"].to_s,
          estimated_minutes: minutes,
          week_number:       activity["week_number"].to_i.clamp(1, 4),
          position:          idx
        )
      end
    end
  end

  def path_params
    params.require(:onboarding_path).permit(
      :name, :community_type, :member_type, :member_background, :integration_goal
    )
  end
end
