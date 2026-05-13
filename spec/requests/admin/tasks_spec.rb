require 'rails_helper'

RSpec.describe "Admin::Tasks", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:task) { build(:developer_task) }

  before do
    sign_in admin
  end

  describe "GET /admin/tasks" do
    let(:client_mock) { instance_double(DeveloperTasks::Client) }

    before do
      allow(DeveloperTasks::Client).to receive(:new).and_return(client_mock)
      allow(client_mock).to receive(:sources).and_return([])
      allow(client_mock).to receive(:fetch_tasks).and_return([ [ task ], [] ])
    end

    it "returns http success" do
      get admin_tasks_path
      expect(response).to have_http_status(:success)
      expect(assigns(:tasks)).to include(task)
    end

    it "filters tasks by query" do
      get admin_tasks_path, params: { q: task.title }
      expect(response).to have_http_status(:success)
    end

    it "filters tasks by source and status" do
      get admin_tasks_path, params: { source: task.source_key, status: task.status }
      expect(response).to have_http_status(:success)
    end
  end

  describe "PATCH /admin/tasks/:id" do
    let(:client_mock) { instance_double(DeveloperTasks::Client) }

    before do
      allow(DeveloperTasks::Client).to receive(:new).and_return(client_mock)
      allow(client_mock).to receive(:update_status).and_return([ true, task ])
    end

    it "updates task status and redirects" do
      patch admin_task_path(id: task.id), params: { source_key: task.source_key, status: "completed" }
      expect(response).to redirect_to(admin_tasks_path)
      expect(flash[:notice]).to include("updated to Completed")
    end

    context "when update fails" do
      before do
        allow(client_mock).to receive(:update_status).and_return([ false, "API Error" ])
      end

      it "redirects with alert" do
        patch admin_task_path(id: task.id), params: { source_key: task.source_key, status: "completed" }
        expect(response).to redirect_to(admin_tasks_path)
        expect(flash[:alert]).to eq("API Error")
      end
    end

    it "redirects with alert if status is blank" do
      patch admin_task_path(id: task.id), params: { source_key: task.source_key, status: "" }
      expect(response).to redirect_to(admin_tasks_path)
      expect(flash[:alert]).to include("Choose a status")
    end
  end
end
