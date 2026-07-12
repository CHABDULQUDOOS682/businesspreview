# frozen_string_literal: true

class ContentUpdateWebhooksController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :set_unread_message_count
  skip_before_action :verify_authenticity_token

  def create
    result = ContentUpdateWebhookService.call(
      payload: webhook_payload,
      secret: request.headers["X-Site-Api-Secret"].to_s
    )

    if result.success?
      render json: {
        ok: true,
        agency_task_id: result.task.id,
        status: result.task.status
      }, status: :ok
    else
      render json: { ok: false, error: result.error }, status: result.http_status
    end
  end

  private

  def webhook_payload
    params.permit(
      :event,
      :business_number,
      content_update: [
        :id,
        :description,
        :status,
        :requester_name,
        :requester_email,
        :created_at,
        :admin_url
      ]
    ).to_h
  end
end
