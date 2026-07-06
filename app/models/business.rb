class Business < ApplicationRecord
  has_many :preview_links, dependent: :destroy
  has_many :messages, dependent: :destroy
  has_many :notes, dependent: :destroy
  has_many :payment_invoices, dependent: :destroy
  has_many :reviews, dependent: :destroy
  belongs_to :sold_by, class_name: "User", optional: true
  has_many :commissions, dependent: :destroy
  has_many :business_commission_rates, dependent: :destroy
  alias_attribute :website, :website_url

  before_validation :normalize_phone
  before_create :generate_review_token

  validates :name, presence: true
  validates :phone, presence: true
  validates :phone, uniqueness: { case_sensitive: false }, if: -> { phone.present? }

  SEGMENTS = {
    "nurture" => "Neutral",
    "purchased" => "Purchased Website",
    "subscriptions" => "Subscriptions"
  }.freeze

  scope :with_active_subscription, -> {
    where("subscription = ? OR subscription_fee IS NOT NULL", true)
  }
  scope :task_sources, -> {
    where(task_source_enabled: true)
      .where.not(task_base_url: [ nil, "" ])
      .where.not(task_secret: [ nil, "" ])
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

  def subscription_first_invoice?(excluding: nil)
    scope = payment_invoices.where(kind: "subscription").where.not(status: %w[draft failed])
    scope = scope.where.not(id: excluding.id) if excluding&.id
    scope.none?
  end

  def task_source_name
    website_name.presence || name
  end

  def review_url
    Rails.application.routes.url_helpers.new_review_submission_url(
      token: review_token,
      host: ENV.fetch("APP_HOST", "localhost"),
      protocol: ENV.fetch("APP_PROTOCOL", "https")
    )
  end

  private

  def normalize_phone
    return if phone.blank?

    digits = phone.to_s.gsub(/[^\d+]/, "")
    digits = "+#{digits.delete('+')}" if digits.present?
    self.phone = digits
  end

  def generate_review_token
    self.review_token ||= SecureRandom.urlsafe_base64(16)
  end
end
