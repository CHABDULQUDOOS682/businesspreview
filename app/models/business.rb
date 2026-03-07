class Business < ApplicationRecord
  has_many :preview_links, dependent: :destroy
  alias_attribute :website, :website_url
end
