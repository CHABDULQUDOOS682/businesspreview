# frozen_string_literal: true

class Admin::ContractsController < ApplicationController
  layout "admin"
  before_action :require_admin_or_super_admin!
  before_action :set_business
  before_action :set_contract, only: %i[show send_for_signature void download sync_to_sitepilot]

  def new
    @contract = @business.contracts.build(
      client_name: @business.name,
      client_email: @business.email,
      agency_name: "DevDeBizz",
      currency: "usd"
    )

    kind = params[:kind].presence_in(Contract::KINDS.keys) ||
      (@business.subscription_active? ? "subscription" : "one_time_project")
    @subscription_package_key = params[:package_key].presence_in(Contracts::PackageCatalog::SUBSCRIPTION_PACKAGES.keys) ||
      Contracts::PackageCatalog.suggest_subscription_key(@business)
    @project_package_key = params[:package_key].presence_in(Contracts::PackageCatalog::PROJECT_PACKAGES.keys) ||
      Contracts::PackageCatalog.suggest_project_key(@business)

    package_key = kind == "subscription" ? @subscription_package_key : @project_package_key
    apply_package_to_contract!(@contract, kind, package_key)
  end

  def create
    @contract = @business.contracts.build(contract_params.except(:amount_dollars))
    @contract.created_by = current_user
    @contract.status = "draft"
    assign_amount_cents!(@contract)
    assign_package_key!(@contract)

    @subscription_package_key = @contract.package_key.presence_in(Contracts::PackageCatalog::SUBSCRIPTION_PACKAGES.keys) ||
      Contracts::PackageCatalog.suggest_subscription_key(@business)
    @project_package_key = @contract.package_key.presence_in(Contracts::PackageCatalog::PROJECT_PACKAGES.keys) ||
      Contracts::PackageCatalog.suggest_project_key(@business)

    if @contract.save
      Contracts::PdfGenerator.new(@contract).attach!
      redirect_to admin_business_contract_path(@business, @contract), notice: "Contract draft created."
    else
      flash.now[:alert] = @contract.errors.full_messages.to_sentence
      render :new, status: :unprocessable_entity
    end
  end

  def show
  end

  def send_for_signature
    if @contract.void? || @contract.signed?
      redirect_to admin_business_contract_path(@business, @contract), alert: "This contract cannot be sent."
      return
    end

    if @contract.client_email.blank?
      redirect_to admin_business_contract_path(@business, @contract), alert: "Client email is required."
      return
    end

    @contract.mark_sent!
    Contracts::PdfGenerator.new(@contract).attach!
    ContractMailer.with(contract: @contract).sign_request.deliver_later
    Crm::NotifyContractJob.perform_later(@contract.id, "contract_sent")

    redirect_to admin_business_contract_path(@business, @contract), notice: "Contract sent for signature."
  end

  def void
    if @contract.signed?
      redirect_to admin_business_contract_path(@business, @contract), alert: "Signed contracts cannot be voided here."
      return
    end

    @contract.mark_void!
    redirect_to admin_business_path(@business), notice: "Contract voided."
  end

  def download
    unless @contract.document.attached?
      Contracts::PdfGenerator.new(@contract).attach!
      @contract.reload
    end

    redirect_to rails_blob_url(@contract.document, disposition: "attachment")
  end

  def sync_to_sitepilot
    client = Crm::WebhookClient.new(@business)
    unless client.configured?
      redirect_to admin_business_contract_path(@business, @contract),
                  alert: "SitePilot is not connected yet. Save Site API Base URL, secret, and business number on the business, then try again."
      return
    end

    if @contract.void?
      redirect_to admin_business_contract_path(@business, @contract), alert: "Voided contracts are not synced."
      return
    end

    event = @contract.signed? ? "contract_signed" : "contract_sent"
    Crm::ContractEventNotifier.new(contract: @contract).call(event)
    redirect_to admin_business_contract_path(@business, @contract), notice: "Contract synced to SitePilot."
  rescue Crm::WebhookClient::Error => e
    redirect_to admin_business_contract_path(@business, @contract), alert: "Sync failed: #{e.message}"
  end

  def sync_all_to_sitepilot
    client = Crm::WebhookClient.new(@business)
    unless client.configured?
      redirect_to admin_business_path(@business),
                  alert: "SitePilot is not connected yet. Configure Site API fields on this business first."
      return
    end

    synced = 0
    @business.contracts.where.not(status: "void").find_each do |contract|
      event = contract.signed? ? "contract_signed" : "contract_sent"
      Crm::ContractEventNotifier.new(contract: contract).call(event)
      synced += 1
    end

    redirect_to admin_business_path(@business), notice: "Synced #{synced} #{'contract'.pluralize(synced)} to SitePilot."
  rescue Crm::WebhookClient::Error => e
    redirect_to admin_business_path(@business), alert: "Sync failed: #{e.message}"
  end

  private

  def set_business
    @business = Business.find(params[:business_id])
  end

  def set_contract
    @contract = @business.contracts.find(params[:id])
  end

  def contract_params
    params.require(:contract).permit(
      :kind,
      :title,
      :client_name,
      :client_email,
      :agency_name,
      :scope_of_work,
      :pricing_terms,
      :timeline_terms,
      :termination_terms,
      :currency,
      :amount_dollars,
      :package_key
    )
  end

  def assign_amount_cents!(contract)
    dollars = params.dig(:contract, :amount_dollars)
    return if dollars.blank?

    contract.amount_cents = (BigDecimal(dollars.to_s) * 100).round
  end

  def assign_package_key!(contract)
    key = params.dig(:contract, :package_key).to_s
    allowed =
      if contract.kind == "subscription"
        Contracts::PackageCatalog::SUBSCRIPTION_PACKAGES.keys
      else
        Contracts::PackageCatalog::PROJECT_PACKAGES.keys
      end
    contract.package_key = allowed.include?(key) ? key : nil
  end

  def apply_package_to_contract!(contract, kind, package_key)
    payload = Contracts::PackageCatalog.payload_for(kind, package_key, business: @business)
    contract.kind = payload[:kind]
    contract.package_key = payload[:package_key]
    contract.title = payload[:title]
    contract.scope_of_work = payload[:scope_of_work]
    contract.pricing_terms = payload[:pricing_terms]
    contract.timeline_terms = payload[:timeline_terms]
    contract.termination_terms = payload[:termination_terms]
    contract.amount_cents = payload[:amount_dollars].present? ? (payload[:amount_dollars].to_f * 100).round : nil
  end
end
