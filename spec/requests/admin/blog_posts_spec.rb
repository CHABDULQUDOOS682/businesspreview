require "rails_helper"

RSpec.describe "Admin::BlogPosts", type: :request do
  let(:admin) { create(:user, :admin) }
  let!(:blog_post) { create(:blog_post) }

  before { sign_in admin }

  describe "GET /admin/blog_posts" do
    it "returns http success" do
      get admin_blog_posts_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /admin/blog_posts/new" do
    it "returns http success" do
      get new_admin_blog_post_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /admin/blog_posts" do
    it "creates a blog post" do
      expect {
        post admin_blog_posts_path, params: {
          blog_post: {
            title: "New post",
            category: "SEO",
            excerpt: "A short excerpt",
            read_time_label: "4 min read",
            published_on: Date.current,
            active: true
          }
        }
      }.to change(BlogPost, :count).by(1)

      expect(response).to redirect_to(admin_blog_posts_path)
    end

    it "renders new on validation failure" do
      post admin_blog_posts_path, params: { blog_post: { title: "", excerpt: "" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "GET /admin/blog_posts/:id/edit" do
    it "returns http success" do
      get edit_admin_blog_post_path(blog_post)
      expect(response).to have_http_status(:success)
    end
  end

  describe "PATCH /admin/blog_posts/:id" do
    it "updates the blog post" do
      patch admin_blog_post_path(blog_post), params: { blog_post: { title: "Updated title" } }
      expect(blog_post.reload.title).to eq("Updated title")
      expect(response).to redirect_to(admin_blog_posts_path)
    end

    it "renders edit on validation failure" do
      patch admin_blog_post_path(blog_post), params: { blog_post: { title: "" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "DELETE /admin/blog_posts/:id" do
    it "destroys the blog post" do
      expect {
        delete admin_blog_post_path(blog_post)
      }.to change(BlogPost, :count).by(-1)
      expect(response).to redirect_to(admin_blog_posts_path)
    end
  end

  describe "PATCH /admin/blog_posts/:id/toggle_active" do
    it "toggles visibility" do
      expect {
        patch toggle_active_admin_blog_post_path(blog_post)
      }.to change { blog_post.reload.active }.from(true).to(false)
      expect(response).to redirect_to(admin_blog_posts_path)
    end
  end

  describe "employee access" do
    let(:employee) { create(:user, role: "employee") }

    before { sign_in employee }

    it "redirects employees away" do
      get admin_blog_posts_path
      expect(response).to redirect_to(admin_root_path)
    end
  end
end
