class Admin::ColdCallingScriptsController < ApplicationController
  layout "admin"

  before_action :require_script_manager!, only: %i[new create edit update destroy]
  before_action :set_script, only: %i[show edit update destroy]

  def index
    scope = ColdCallingScript.alphabetical
    scope = scope.active unless can_manage_scripts?
    scope = scope.by_category(params[:category])

    if params[:q].present?
      q = "%#{params[:q]}%"
      scope = scope.where("title ILIKE :q OR body ILIKE :q", q: q)
    end

    category_scope = can_manage_scripts? ? ColdCallingScript.all : ColdCallingScript.active
    @categories = category_scope.where.not(category: [ nil, "" ]).distinct.order(:category).pluck(:category)
    @pagy, @scripts = pagy(scope, limit: 20)
  end

  def show
  end

  def new
    @script = ColdCallingScript.new
  end

  def create
    @script = ColdCallingScript.new(script_params)
    @script.created_by = current_user

    if @script.save
      redirect_to admin_cold_calling_scripts_path, notice: "Script added."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @script.update(script_params)
      redirect_to admin_cold_calling_script_path(@script), notice: "Script updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @script.destroy
    redirect_to admin_cold_calling_scripts_path, notice: "Script deleted."
  end

  private

  def set_script
    scope = can_manage_scripts? ? ColdCallingScript.all : ColdCallingScript.active
    @script = scope.find_by(id: params[:id])
    return if @script.present?

    redirect_to admin_cold_calling_scripts_path, alert: "Script not found." and return
  end

  def can_manage_scripts?
    super_admin? || admin_role?
  end
  helper_method :can_manage_scripts?

  def require_script_manager!
    return if can_manage_scripts?

    redirect_to admin_cold_calling_scripts_path, alert: "You do not have access to manage scripts."
  end

  def script_params
    params.require(:cold_calling_script).permit(:title, :body, :category, :active)
  end
end
