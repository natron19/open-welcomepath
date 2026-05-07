# Phase 3 — Routes and PathsController

**Goal:** All routes are defined and `PathsController` handles every action with correct authentication scoping, owner-only authorization (404 on mismatch), and stubs for the AI call that will be fully wired in Phase 6.

**Prerequisite:** Phases 1 and 2 complete. Both model specs pass.

**Spec reference:** `docs/open-welcomepath/welcomepath-demo-spec.md` sections 4 and 5.

---

## Tasks

### 3.1 — Routes

In `config/routes.rb`, add the paths resource **inside** the authenticated block (or alongside the other authenticated routes — wherever auth is enforced globally):

```ruby
resources :paths do
  member do
    post :clone
    get  :print
  end
end
```

Verify these named helpers resolve in `rails console`:
- `paths_path` → `/paths`
- `new_path_path` → `/paths/new`
- `path_path("some-id")` → `/paths/some-id`
- `edit_path_path("some-id")` → `/paths/some-id/edit`
- `clone_path_path("some-id")` → `/paths/some-id/clone`
- `print_path_path("some-id")` → `/paths/some-id/print`

### 3.2 — `app/controllers/paths_controller.rb`

```ruby
class PathsController < ApplicationController
  ParseError = Class.new(StandardError)

  before_action :set_path, only: [:show, :edit, :update, :destroy, :clone, :print]

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
    unless @path.valid?
      return render :new, status: :unprocessable_entity
    end
    # AI integration wired in Phase 6 — placeholder for now
    raise NotImplementedError, "AI integration not yet wired (Phase 6)"
  end

  def show
    @activities_by_root = @path.activities_by_root
    @activities_by_week = @path.activities_by_week
  end

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

  def path_params
    params.require(:onboarding_path).permit(
      :name, :community_type, :member_type, :member_background, :integration_goal
    )
  end
end
```

> **Note:** `update` limits permitted params to `name` and `integration_goal` only — the four AI-input fields are intentionally not editable after generation. `path_params` permits all five for use in `create`.

---

## RSpec

These specs live in `spec/requests/paths_spec.rb`. Write basic access-control stubs now; full coverage is added in Phase 9. At minimum, confirm these three things work before moving on:

```ruby
RSpec.describe "Paths", type: :request do
  let(:user)  { create(:user) }
  let(:other) { create(:user) }
  let(:path)  { create(:onboarding_path, :with_activities, user: user) }

  describe "unauthenticated access" do
    it "redirects GET /paths to sign in"       { get paths_path;          expect(response).to redirect_to(sign_in_path) }
    it "redirects GET /paths/new to sign in"   { get new_path_path;       expect(response).to redirect_to(sign_in_path) }
    it "redirects GET /paths/:id to sign in"   { get path_path(path);     expect(response).to redirect_to(sign_in_path) }
  end

  describe "owner-only enforcement" do
    before { sign_in_as(other) }

    it "returns 404 for another user's path show" do
      get path_path(path)
      expect(response).to have_http_status(:not_found)
    end

    it "returns 404 for another user's path edit" do
      get edit_path_path(path)
      expect(response).to have_http_status(:not_found)
    end

    it "returns 404 for another user's path destroy" do
      delete path_path(path)
      expect(response).to have_http_status(:not_found)
    end
  end
end
```

Run: `bundle exec rspec spec/requests/paths_spec.rb`

---

## Manual Checks

After `bin/dev`:

- [ ] `GET /paths` redirects to sign-in when not authenticated
- [ ] `GET /paths` returns 200 when signed in
- [ ] `GET /paths/new` returns 200 when signed in
- [ ] `GET /paths/00000000-0000-0000-0000-000000000000` (nonexistent UUID) returns 404, not 500
- [ ] `DELETE /paths/:id` for another user's path returns 404 (sign in as a second user and try)
- [ ] `POST /paths` with valid params returns 500 with "NotImplementedError" in development log (expected — AI not yet wired)
- [ ] `GET /paths/:id/print` for an owned path with `layout: "print"` in controller — returns 500 (print layout not yet created in Phase 7, expected)
- [ ] In `rails routes | grep path`, confirm `clone` and `print` member routes appear
