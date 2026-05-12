require 'rails_helper'

RSpec.describe "Admin::Notes", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:business) { create(:business) }
  let!(:note) { create(:note, business: business) }

  before do
    sign_in admin
  end

  describe "POST /admin/notes" do
    it "creates a new note and redirects" do
      expect {
        post admin_notes_path, params: { note: { body: "New note", business_id: business.id } }
      }.to change(Note, :count).by(1)
      expect(response).to redirect_to(admin_business_path(business))
    end

    it "redirects back if creation fails" do
      post admin_notes_path, params: { note: { body: "", business_id: business.id } }
      expect(response).to redirect_to(admin_business_path(business))
      expect(flash[:alert]).to be_present
    end
  end

  describe "GET /admin/notes/:id/edit" do
    it "returns http success" do
      get edit_admin_note_path(note)
      expect(response).to have_http_status(:success)
    end
  end

  describe "PATCH /admin/notes/:id" do
    it "updates the note and redirects" do
      patch admin_note_path(note), params: { note: { body: "Updated note" } }
      expect(note.reload.body).to eq("Updated note")
      expect(response).to redirect_to(admin_business_path(business))
    end

    it "renders edit if update fails" do
      patch admin_note_path(note), params: { note: { body: "" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "DELETE /admin/notes/:id" do
    it "destroys the note and redirects" do
      expect {
        delete admin_note_path(note)
      }.to change(Note, :count).by(-1)
      expect(response).to redirect_to(admin_business_path(business))
    end
  end
end
