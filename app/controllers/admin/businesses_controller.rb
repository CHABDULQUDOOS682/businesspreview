require "csv"

class Admin::BusinessesController < ApplicationController
  layout "admin"

  def index
    @segment = Business.normalize_segment(params[:segment])
    @segment_counts = Business.segment_counts

    segment_scope = Business.for_segment(@segment)
    @businesses = apply_filters(segment_scope).order(created_at: :desc)

    @niches = segment_scope.where.not(niche: [ nil, "" ]).distinct.pluck(:niche).sort
    @cities = segment_scope.where.not(city: [ nil, "" ]).distinct.pluck(:city).sort
    @countries = segment_scope.where.not(country: [ nil, "" ]).distinct.pluck(:country).sort
  end

  def import
    unless params[:file].present?
      redirect_to admin_businesses_path, alert: "Please upload a CSV file."
      return
    end

    created = 0
    failed = []

    begin
      CSV.foreach(params[:file].path, headers: true) do |row|
        attrs = {
          name: row["Business Name"],
          city: row["City"],
          country: row["Country"],
          niche: row["Business Type"],
          phone: "+#{row['Phone Number']}",
          rating: row["Rating"]
        }.compact

        next if attrs[:name].blank?

        business = Business.new(attrs)
        if business.save
          created += 1
        else
          failed << { name: attrs[:name], errors: business.errors.full_messages }
        end
      end
    rescue => e
      redirect_to admin_businesses_path, alert: "Import failed: #{e.message}"
      return
    end

    if failed.empty?
      redirect_to admin_businesses_path, notice: "Imported #{created} businesses successfully."
    else
      redirect_to admin_businesses_path, alert: "Imported #{created}, #{failed.size} failed."
    end
  end

  def new
    @business = Business.new
  end

  def create
    @business = Business.new(business_params)
    if @business.save
      redirect_to admin_businesses_path, notice: "Business created!"
    else
      render :new
    end
  end

  def show
    @business = Business.find(params[:id])
    @templates = PreviewLink.available_templates
  end
  
  def edit
    @business = Business.find(params[:id])
  end
  
  def update
    @business = Business.find(params[:id])
    if @business.update(business_params)
      redirect_to admin_business_path(@business), notice: "Business updated!"
    else
      render :edit, alert: "Update failed."
    end
  end

  private

  def apply_filters(scope)
    scope = scope.where("LOWER(name) ILIKE LOWER(?)", "%#{params[:name]}%") if params[:name].present?
    scope = scope.where(niche: params[:niche]) if params[:niche].present?
    scope = scope.where(city: params[:city]) if params[:city].present?
    scope = scope.where(country: params[:country]) if params[:country].present?
    scope
  end

  def business_params
    params.require(:business)
          .permit(
            :name,
            :owner_name,
            :city,
            :country,
            :niche,
            :phone,
            :email,
            :website_url,
            :website_name,
            :rating,
            :message,
            :sold_price,
            :subscription_fee,
            :subscription,
            :task_source_enabled,
            :task_base_url,
            :task_secret,
            :task_endpoint_path
          )
  end
end
