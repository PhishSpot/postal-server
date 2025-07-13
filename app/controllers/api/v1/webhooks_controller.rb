# frozen_string_literal: true

class API::V1::WebhooksController < API::V1::BaseController
  before_action :set_webhook, only: [:show, :update, :destroy, :history]

  def index
    webhooks = @server.webhooks.order(:url)
    render json: {
      success: true,
      data: serialize_collection(webhooks, API::V1::WebhookSerializer)
    }
  end

  def show
    render json: {
      success: true,
      data: serialize_resource(@webhook, API::V1::WebhookSerializer)
    }
  end

  def create
    webhook = @server.webhooks.build(webhook_params)
    
    if webhook.save
      render json: {
        success: true,
        data: serialize_resource(webhook, API::V1::WebhookSerializer)
      }, status: :created
    else
      render_error('Failed to create webhook', :unprocessable_entity, webhook.errors.full_messages)
    end
  end

  def update
    if @webhook.update(webhook_params)
      render json: {
        success: true,
        data: serialize_resource(@webhook, API::V1::WebhookSerializer)
      }
    else
      render_error('Failed to update webhook', :unprocessable_entity, @webhook.errors.full_messages)
    end
  end

  def destroy
    @webhook.destroy
    render_success({}, :ok, 'Webhook deleted successfully')
  end

  def history
    begin
      current_page = params[:page] ? params[:page].to_i : 1
      requests = @server.message_db.webhooks.list(current_page)
      
      render json: {
        success: true,
        data: {
          current_page: current_page,
          requests: serialize_collection(requests, API::V1::WebhookRequestSerializer)
        }
      }
    rescue => e
      render_error('Failed to retrieve webhook history', :internal_server_error, [e.message])
    end
  end

  private

  def set_webhook
    @webhook = @server.webhooks.find_by!(uuid: params[:id])
  end

  def webhook_params
    params.require(:webhook).permit(:name, :url, :all_events, :enabled, :sign, events: [])
  end
end
