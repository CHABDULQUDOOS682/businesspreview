class Admin::CommissionRatesController < ApplicationController
  layout "admin"
  before_action :require_user_management_access!

  def index
    @commission_rates = CommissionRate.order(:kind, :month_number)
  end

  def update
    rates_params = params.require(:commission_rates)

    ActiveRecord::Base.transaction do
      rates_params.each do |id, rate_params|
        rate = CommissionRate.find(id)
        rate.update!(percentage: rate_params[:percentage])
      end
    end

    redirect_to admin_commission_rates_path, notice: "Global commission rates updated successfully."
  rescue => e
    redirect_to admin_commission_rates_path, alert: "Error updating commission rates: #{e.message}"
  end
end
