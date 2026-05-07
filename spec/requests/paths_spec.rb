require "rails_helper"

RSpec.describe "Paths", type: :request do
  let(:user)  { create(:user) }
  let(:other) { create(:user) }
  let(:path)  { create(:onboarding_path, :with_activities, user: user) }

  let(:valid_gemini_json) do
    roots = %w[relationships orientation opportunities training stories]
    roots.index_with do |_|
      [
        { "name" => "Activity A", "description" => "Do the thing thoroughly.", "estimated_minutes" => 30, "week_number" => 1 },
        { "name" => "Activity B", "description" => "Follow up afterward.",    "estimated_minutes" => 20, "week_number" => 2 }
      ]
    end.to_json
  end

  let(:valid_path_params) do
    {
      onboarding_path: {
        community_type:    "nonprofit",
        member_type:       "newcomer",
        member_background: "Twenty-something professional recently relocated, looking to get involved.",
        integration_goal:  "Feel like a contributing member within 30 days."
      }
    }
  end

  # ─── GET /paths ───────────────────────────────────────────────────────────

  describe "GET /paths" do
    context "when unauthenticated" do
      it "redirects to sign in" do
        get paths_path
        expect(response).to redirect_to(sign_in_path)
      end
    end

    context "when signed in" do
      before { sign_in_as(user) }

      it "returns 200" do
        get paths_path
        expect(response).to have_http_status(:ok)
      end

      it "shows only the current user's paths" do
        own_path   = create(:onboarding_path, user: user,  name: "My Path")
        other_path = create(:onboarding_path, user: other, name: "Their Path")
        get paths_path
        expect(response.body).to include("My Path")
        expect(response.body).not_to include("Their Path")
      end
    end
  end

  # ─── GET /paths/new ──────────────────────────────────────────────────────

  describe "GET /paths/new" do
    context "when unauthenticated" do
      it "redirects to sign in" do
        get new_path_path
        expect(response).to redirect_to(sign_in_path)
      end
    end

    context "when signed in" do
      it "returns 200" do
        sign_in_as(user)
        get new_path_path
        expect(response).to have_http_status(:ok)
      end
    end
  end

  # ─── POST /paths ─────────────────────────────────────────────────────────

  describe "POST /paths" do
    context "when unauthenticated" do
      it "redirects to sign in" do
        post paths_path, params: valid_path_params
        expect(response).to redirect_to(sign_in_path)
      end
    end

    context "when signed in" do
      before { sign_in_as(user) }

      context "with valid params and a successful Gemini response" do
        before { allow(GeminiService).to receive(:generate).and_return(valid_gemini_json) }

        it "creates an OnboardingPath" do
          expect { post paths_path, params: valid_path_params }
            .to change(OnboardingPath, :count).by(1)
        end

        it "creates PathActivity records for all 5 root sections" do
          expect { post paths_path, params: valid_path_params }
            .to change(PathActivity, :count).by(10)
        end

        it "redirects to the show page" do
          post paths_path, params: valid_path_params
          expect(response).to redirect_to(path_path(OnboardingPath.order(created_at: :desc).first))
        end
      end

      context "with invalid params (member_background too short)" do
        let(:short_params) do
          valid_path_params.deep_merge(onboarding_path: { member_background: "Too short." })
        end

        it "does not call GeminiService" do
          expect(GeminiService).not_to receive(:generate)
          post paths_path, params: short_params
        end

        it "re-renders the form with 422" do
          post paths_path, params: short_params
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it "does not create an OnboardingPath" do
          expect { post paths_path, params: short_params }
            .not_to change(OnboardingPath, :count)
        end
      end

      context "when Gemini raises GeminiError" do
        before { allow(GeminiService).to receive(:generate).and_raise(GeminiService::GeminiError) }

        it "renders an error message" do
          post paths_path, params: valid_path_params
          expect(response.body).to include("unexpected error")
        end

        it "does not create an OnboardingPath" do
          expect { post paths_path, params: valid_path_params }
            .not_to change(OnboardingPath, :count)
        end
      end

      context "when Gemini raises BudgetExceededError" do
        before { allow(GeminiService).to receive(:generate).and_raise(GeminiService::BudgetExceededError) }

        it "renders the budget exceeded error" do
          post paths_path, params: valid_path_params
          expect(response.body).to include("request limit")
        end
      end

      context "when Gemini raises TimeoutError" do
        before { allow(GeminiService).to receive(:generate).and_raise(GeminiService::TimeoutError) }

        it "renders the timeout error" do
          post paths_path, params: valid_path_params
          expect(response.body).to include("too long")
        end
      end

      context "when Gemini returns malformed JSON" do
        before { allow(GeminiService).to receive(:generate).and_return("not json {{{") }

        it "re-renders the form with 422" do
          post paths_path, params: valid_path_params
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it "does not persist an OnboardingPath" do
          expect { post paths_path, params: valid_path_params }
            .not_to change(OnboardingPath, :count)
        end
      end

      context "when Gemini returns JSON missing a root section" do
        let(:incomplete_json) { { "relationships" => [] }.to_json }
        before { allow(GeminiService).to receive(:generate).and_return(incomplete_json) }

        it "re-renders the form with 422" do
          post paths_path, params: valid_path_params
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end
  end

  # ─── GET /paths/:id ──────────────────────────────────────────────────────

  describe "GET /paths/:id" do
    context "when unauthenticated" do
      it "redirects to sign in" do
        get path_path(path)
        expect(response).to redirect_to(sign_in_path)
      end
    end

    context "when signed in as the owner" do
      it "returns 200" do
        sign_in_as(user)
        get path_path(path)
        expect(response).to have_http_status(:ok)
      end
    end

    context "when signed in as a different user" do
      it "returns 404" do
        sign_in_as(other)
        get path_path(path)
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  # ─── GET /paths/:id/edit ─────────────────────────────────────────────────

  describe "GET /paths/:id/edit" do
    context "when signed in as the owner" do
      it "returns 200" do
        sign_in_as(user)
        get edit_path_path(path)
        expect(response).to have_http_status(:ok)
      end
    end

    context "when signed in as a different user" do
      it "returns 404" do
        sign_in_as(other)
        get edit_path_path(path)
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  # ─── PATCH /paths/:id ────────────────────────────────────────────────────

  describe "PATCH /paths/:id" do
    before { sign_in_as(user) }

    it "updates name and redirects to show" do
      patch path_path(path), params: { onboarding_path: { name: "Updated Name" } }
      expect(response).to redirect_to(path_path(path))
      expect(path.reload.name).to eq("Updated Name")
    end

    it "does not allow updating community_type" do
      original = path.community_type
      patch path_path(path), params: { onboarding_path: { community_type: "workplace" } }
      expect(path.reload.community_type).to eq(original)
    end
  end

  # ─── DELETE /paths/:id ───────────────────────────────────────────────────

  describe "DELETE /paths/:id" do
    context "when unauthenticated" do
      it "redirects to sign in" do
        delete path_path(path)
        expect(response).to redirect_to(sign_in_path)
      end
    end

    context "when signed in as the owner" do
      before { sign_in_as(user) }

      it "destroys the path and its activities" do
        path  # force creation
        expect { delete path_path(path) }
          .to change(OnboardingPath, :count).by(-1)
          .and change(PathActivity, :count).by(-10)
      end

      it "redirects to the paths index" do
        delete path_path(path)
        expect(response).to redirect_to(paths_path)
      end
    end

    context "when signed in as a different user" do
      it "returns 404" do
        sign_in_as(other)
        delete path_path(path)
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  # ─── POST /paths/:id/clone ───────────────────────────────────────────────

  describe "POST /paths/:id/clone" do
    context "when unauthenticated" do
      it "redirects to sign in" do
        post clone_path_path(path)
        expect(response).to redirect_to(sign_in_path)
      end
    end

    context "when signed in as the owner" do
      before { sign_in_as(user) }

      it "creates a new path with ' (copy)' in the name" do
        path  # force creation
        expect { post clone_path_path(path) }
          .to change(OnboardingPath, :count).by(1)
        expect(OnboardingPath.order(created_at: :desc).first.name).to include("(copy)")
      end

      it "duplicates all activities" do
        path  # force creation
        expect { post clone_path_path(path) }
          .to change(PathActivity, :count).by(path.path_activities.count)
      end

      it "redirects to the clone show page" do
        post clone_path_path(path)
        clone = OnboardingPath.order(created_at: :desc).first
        expect(response).to redirect_to(path_path(clone))
      end
    end

    context "when signed in as a different user" do
      it "returns 404" do
        sign_in_as(other)
        post clone_path_path(path)
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
