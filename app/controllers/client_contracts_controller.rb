# frozen_string_literal: true

class ClientContractsController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :set_unread_message_count
  layout "public"

  before_action :set_contract

  def show
  end

  def sign
    if @contract.signed?
      redirect_to client_contract_path(@contract.access_token), notice: "This agreement is already signed."
      return
    end

    unless @contract.signable? && !@contract.void?
      redirect_to client_contract_path(@contract.access_token), alert: "This agreement is no longer available to sign."
      return
    end

    unless ActiveModel::Type::Boolean.new.cast(params[:agree])
      flash.now[:alert] = "Please confirm you agree to the terms before signing."
      render :show, status: :unprocessable_entity
      return
    end

    signature_data = params[:signature_data].to_s
    if signature_data.blank?
      flash.now[:alert] = "Please draw your signature before submitting."
      render :show, status: :unprocessable_entity
      return
    end

    @contract.sign_by_client!(
      name: params[:signer_name].presence || @contract.client_name,
      ip: request.remote_ip,
      user_agent: request.user_agent,
      signature_data: signature_data
    )
    Contracts::PdfGenerator.new(@contract).attach!
    ContractMailer.with(contract: @contract).signed_confirmation.deliver_later
    Crm::NotifyContractJob.perform_later(@contract.id, "contract_signed")

    redirect_to client_contract_path(@contract.access_token), notice: "Thank you — your agreement is signed."
  rescue ArgumentError => e
    flash.now[:alert] = e.message
    render :show, status: :unprocessable_entity
  end

  private

  def set_contract
    @contract = Contract.find_by!(access_token: params[:token])
  end
end
