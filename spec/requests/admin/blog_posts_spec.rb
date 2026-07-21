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
