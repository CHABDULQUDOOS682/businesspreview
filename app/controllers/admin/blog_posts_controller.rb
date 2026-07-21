module Admin
  class BlogPostsController < ApplicationController
    layout "admin"
    before_action :require_admin_or_super_admin!
    before_action :set_blog_post, only: [ :edit, :update, :destroy, :toggle_active ]

    def index
      @blog_posts = BlogPost.ordered
    end

    def new
      @blog_post = BlogPost.new(active: true, published_on: Date.current, read_time_label: "5 min read")
    end

    def edit
    end

    def create
      @blog_post = BlogPost.new(blog_post_params)

      if @blog_post.save
        redirect_to admin_blog_posts_path, notice: "Blog post was successfully created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def update
      if @blog_post.update(blog_post_params)
        redirect_to admin_blog_posts_path, notice: "Blog post was successfully updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @blog_post.destroy
      redirect_to admin_blog_posts_path, notice: "Blog post was successfully destroyed."
    end

    def toggle_active
      @blog_post.update(active: !@blog_post.active)
      redirect_to admin_blog_posts_path, notice: "Blog post is now #{@blog_post.active? ? 'visible' : 'hidden'}."
    end

    private

    def set_blog_post
      @blog_post = BlogPost.find(params[:id])
    end

    def blog_post_params
      params.require(:blog_post).permit(
        :title, :slug, :category, :excerpt, :read_time_label, :published_on,
        :active, :meta_title, :meta_description, :body
      )
    end
  end
end
