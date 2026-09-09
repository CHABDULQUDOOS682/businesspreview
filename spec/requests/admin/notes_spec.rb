require 'rails_helper'

RSpec.describe "Admin::Notes", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:business) { create(:business) }
  let!(:note) { create(:note, business: business) }

  before do
    sign_in admin
  end

  describe "GET /admin/notes" do
    it "returns http success" do
      get admin_notes_path
      expect(response).to have_http_status(:success)
    end

    it "allows searching and filtering" do
      get admin_notes_path, params: { q: "important", role: "admin" }
      expect(response).to have_http_status(:success)
    end

    it "filters notes by user" do
      author = create(:user, :admin)
      authored_note = create(:note, business: business, user: author, body: "Author note")

      get admin_notes_path, params: { user_id: author.id }

      expect(response).to have_http_status(:success)
      expect(assigns(:notes)).to include(authored_note)
      expect(assigns(:notes).map(&:user_id).uniq).to eq([ author.id ])
    end
  end

  describe "POST /admin/notes" do
    it "creates a new note, assigns the current user and redirects" do
      expect {
        post admin_notes_path, params: { note: { body: "New note", business_id: business.id } }
      }.to change(Note, :count).by(1)
      expect(Note.last.user).to eq(admin)
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

  describe "employee access" do
    let(:employee) { create(:user, :employee) }
    let!(:my_business) { create(:business, assigned_to: employee) }
    let!(:their_business) { create(:business, assigned_to: create(:user, :employee)) }
    let!(:my_note) { create(:note, business: my_business, user: employee) }
    let!(:their_note) { create(:note, business: their_business) }

    before do
      sign_out admin
      sign_in employee
    end

    it "only lists notes for businesses assigned to the employee" do
      get admin_notes_path

      expect(assigns(:notes)).to include(my_note)
      expect(assigns(:notes)).not_to include(their_note, note)
    end

    it "does not expose the full user directory in filters" do
      expect { get admin_notes_path }.not_to raise_error
      expect(assigns(:users).map(&:id)).to eq([ employee.id ])
    end

    it "blocks editing another employee's note" do
      get edit_admin_note_path(their_note)

      expect(response).to redirect_to(admin_notes_path)
      expect(flash[:alert]).to include("do not have access")
    end

    it "blocks updating another employee's note" do
      patch admin_note_path(their_note), params: { note: { body: "hijacked" } }

      expect(their_note.reload.body).not_to eq("hijacked")
      expect(response).to redirect_to(admin_notes_path)
    end

    it "blocks deleting another employee's note" do
      expect {
        delete admin_note_path(their_note)
      }.not_to change(Note, :count)

      expect(response).to redirect_to(admin_notes_path)
    end

    it "blocks creating a note on a business they are not assigned" do
      expect {
        post admin_notes_path, params: { note: { body: "spy", business_id: their_business.id } }
      }.not_to change(Note, :count)

      expect(flash[:alert]).to include("do not have access")
    end

    it "blocks moving their own note onto another business" do
      patch admin_note_path(my_note), params: { note: { business_id: their_business.id } }

      expect(my_note.reload.business_id).to eq(my_business.id)
      expect(response).to redirect_to(admin_notes_path)
    end

    it "still allows managing their own note on an assigned business" do
      patch admin_note_path(my_note), params: { note: { body: "Progress update" } }

      expect(my_note.reload.body).to eq("Progress update")
    end

    it "still allows creating a note on an assigned business" do
      expect {
        post admin_notes_path, params: { note: { body: "Called owner", business_id: my_business.id } }
      }.to change(Note, :count).by(1)
    end
  end
end
