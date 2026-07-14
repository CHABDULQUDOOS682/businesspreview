require "rails_helper"

RSpec.describe "Admin::ColdCallingScripts", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:super_admin) { create(:user, :super_admin) }
  let(:employee) { create(:user, role: "employee") }
  let!(:active_script) { create(:cold_calling_script, title: "Active opener", category: "Opening", created_by: admin) }
  let!(:archived_script) { create(:cold_calling_script, title: "Old closer", category: "Closing", active: false, created_by: admin) }

  describe "employee access" do
    before { sign_in employee }

    it "lists only active scripts" do
      get admin_cold_calling_scripts_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Active opener")
      expect(response.body).not_to include("Old closer")
      expect(response.body).not_to include("New Script")
    end

    it "shows an active script" do
      get admin_cold_calling_script_path(active_script)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(active_script.body.to_plain_text)
      expect(response.body).not_to include(edit_admin_cold_calling_script_path(active_script))
    end

    it "blocks show for archived scripts" do
      get admin_cold_calling_script_path(archived_script)

      expect(response).to redirect_to(admin_cold_calling_scripts_path)
      expect(flash[:alert]).to include("not found")
    end

    it "blocks new" do
      get new_admin_cold_calling_script_path

      expect(response).to redirect_to(admin_cold_calling_scripts_path)
      expect(flash[:alert]).to include("do not have access")
    end

    it "blocks create" do
      expect {
        post admin_cold_calling_scripts_path, params: {
          cold_calling_script: { title: "Nope", body: "Nope", category: "Opening" }
        }
      }.not_to change(ColdCallingScript, :count)

      expect(response).to redirect_to(admin_cold_calling_scripts_path)
    end

    it "blocks edit and update" do
      get edit_admin_cold_calling_script_path(active_script)
      expect(response).to redirect_to(admin_cold_calling_scripts_path)

      patch admin_cold_calling_script_path(active_script), params: {
        cold_calling_script: { title: "Hacked" }
      }
      expect(response).to redirect_to(admin_cold_calling_scripts_path)
      expect(active_script.reload.title).to eq("Active opener")
    end

    it "blocks destroy" do
      expect {
        delete admin_cold_calling_script_path(active_script)
      }.not_to change(ColdCallingScript, :count)

      expect(response).to redirect_to(admin_cold_calling_scripts_path)
    end
  end

  describe "admin access" do
    before { sign_in admin }

    it "lists active and archived scripts with write controls" do
      get admin_cold_calling_scripts_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Active opener")
      expect(response.body).to include("Old closer")
      expect(response.body).to include("New Script")
    end

    it "renders the new script form" do
      get new_admin_cold_calling_script_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("New Script")
    end

    it "creates a script" do
      expect {
        post admin_cold_calling_scripts_path, params: {
          cold_calling_script: {
            title: "Price objection",
            body: "I hear you on price...",
            category: "Objection",
            active: true
          }
        }
      }.to change(ColdCallingScript, :count).by(1)

      script = ColdCallingScript.order(:created_at).last
      expect(script.created_by).to eq(admin)
      expect(response).to redirect_to(admin_cold_calling_scripts_path)
    end

    it "re-renders new when create validation fails" do
      expect {
        post admin_cold_calling_scripts_path, params: {
          cold_calling_script: { title: "", body: "", category: "Opening" }
        }
      }.not_to change(ColdCallingScript, :count)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("New Script")
    end

    it "updates and archives a script" do
      patch admin_cold_calling_script_path(active_script), params: {
        cold_calling_script: { title: "Updated opener", active: false }
      }

      expect(response).to redirect_to(admin_cold_calling_script_path(active_script))
      expect(active_script.reload.title).to eq("Updated opener")
      expect(active_script).not_to be_active
    end

    it "re-renders edit when update validation fails" do
      patch admin_cold_calling_script_path(active_script), params: {
        cold_calling_script: { title: "", body: "" }
      }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("Edit Script")
    end

    it "filters by category and search" do
      get admin_cold_calling_scripts_path, params: { category: "Opening", q: "opener" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Active opener")
      expect(response.body).not_to include("Old closer")
    end

    it "destroys a script" do
      expect {
        delete admin_cold_calling_script_path(active_script)
      }.to change(ColdCallingScript, :count).by(-1)

      expect(response).to redirect_to(admin_cold_calling_scripts_path)
    end
  end

  describe "super_admin access" do
    before { sign_in super_admin }

    it "can create scripts" do
      expect {
        post admin_cold_calling_scripts_path, params: {
          cold_calling_script: { title: "Discovery close", body: "Next steps...", category: "Closing" }
        }
      }.to change(ColdCallingScript, :count).by(1)

      expect(ColdCallingScript.order(:created_at).last.created_by).to eq(super_admin)
    end
  end
end
