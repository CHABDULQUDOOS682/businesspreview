class BusinessImportRow < ApplicationRecord
  STATUSES = %w[created duplicate failed].freeze

  belongs_to :business_import
  belongs_to :business, optional: true

  validates :status, inclusion: { in: STATUSES }
end
