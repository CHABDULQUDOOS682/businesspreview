require "csv"

class Admin::BusinessImportsController < ApplicationController
  layout "admin"
  before_action :require_super_admin!

  def index
    @pagy, @business_imports = pagy(BusinessImport.order(created_at: :desc))
  end

  def show
    @business_import = BusinessImport.find(params[:id])
    @pagy, @rows = pagy(@business_import.business_import_rows.order(:row_number))
  end

  def download
    business_import = BusinessImport.find(params[:id])
    csv_data = CSV.generate(headers: true) do |csv|
      csv << [ "Row", "Business Name", "Phone", "Status", "Reason" ]
      business_import.business_import_rows.order(:row_number).each do |row|
        csv << [ row.row_number, row.business_name, row.phone, row.status, row.reason ]
      end
    end

    send_data csv_data, filename: "business_import_#{business_import.id}_report.csv"
  end
end
