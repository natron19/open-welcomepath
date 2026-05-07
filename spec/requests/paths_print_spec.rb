require "rails_helper"

RSpec.describe "Paths print", type: :request do
  let(:user)  { create(:user) }
  let(:other) { create(:user) }
  let(:path)  { create(:onboarding_path, :with_activities, user: user) }

  describe "GET /paths/:id/print" do
    context "when unauthenticated" do
      it "redirects to sign in" do
        get print_path_path(path)
        expect(response).to redirect_to(sign_in_path)
      end
    end

    context "when signed in as the owner" do
      before { sign_in_as(user) }

      it "returns 200" do
        get print_path_path(path)
        expect(response).to have_http_status(:ok)
      end

      it "renders without a navbar" do
        get print_path_path(path)
        expect(response.body).not_to include("<nav")
      end

      it "renders without a footer" do
        get print_path_path(path)
        expect(response.body).not_to include("<footer")
      end
    end

    context "when signed in as a different user" do
      before { sign_in_as(other) }

      it "returns 404" do
        get print_path_path(path)
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
