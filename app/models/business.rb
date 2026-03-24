class Business < ApplicationRecord
  has_many :preview_links, dependent: :destroy
  has_many :messages, dependent: :destroy
  alias_attribute :website, :website_url

  SEGMENTS = {
    "nurture" => "Neutral",
    "purchased" => "Purchased Website",
    "subscriptions" => "Subscriptions"
  }.freeze

  scope :with_active_subscription, -> {
    where("subscription = ? OR subscription_fee IS NOT NULL", true)
  }
  scope :with_purchased_website, -> {
    where.not(sold_price: nil)
  }
  scope :nurture_pipeline, -> {
    where(sold_price: nil, subscription_fee: nil, subscription: [ false, nil ])
  }
  scope :purchased_pipeline, -> {
    with_purchased_website.where(subscription_fee: nil, subscription: [ false, nil ])
  }
  scope :subscriptions_pipeline, -> {
    with_active_subscription
  }

  def self.normalize_segment(segment)
    segment = segment.to_s
    SEGMENTS.key?(segment) ? segment : "nurture"
  end

  def self.for_segment(segment)
    case normalize_segment(segment)
    when "purchased"
      purchased_pipeline
    when "subscriptions"
      subscriptions_pipeline
    else
      nurture_pipeline
    end
  end

  def self.segment_counts
    SEGMENTS.keys.index_with { |segment| for_segment(segment).count }
  end

  def business_segment
    return "subscriptions" if subscription_active?
    return "purchased" if sold_price.present?

    "nurture"
  end

  def business_segment_label
    SEGMENTS.fetch(business_segment)
  end

  def subscription_active?
    subscription? || subscription_fee.present?
  end
end
