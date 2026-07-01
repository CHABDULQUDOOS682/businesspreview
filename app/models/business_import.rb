class BusinessImport < ApplicationRecord
  belongs_to :imported_by, class_name: "User", optional: true
  has_many :business_import_rows, dependent: :destroy

  def created_count = business_import_rows.where(status: "created").count
  def duplicate_count = business_import_rows.where(status: "duplicate").count
  def failed_count = business_import_rows.where(status: "failed").count
  def total_rows = business_import_rows.count
end
