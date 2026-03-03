class Business < ApplicationRecord
  has_many :preview_links, dependent: :destroy
end
