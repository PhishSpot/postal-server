# frozen_string_literal: true

class API::V1::BaseController < ActionController::Base
  protect_from_forgery with: :null_session

  before_action :authenticate_api_key!
  before_action :set_organization_and_server

  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
  rescue_from ActiveRecord::RecordInvalid, with: :render_validation_errors

  private

  def authenticate_api_key!
    token = request.headers['Authorization']&.gsub(/^Bearer\s+/, '')
    
    unless token
      render json: { error: 'Authorization header required' }, status: :unauthorized
      return
    end

    @current_api_key = APIKey.authenticate(token)
    
    unless @current_api_key
      render json: { error: 'Invalid API key' }, status: :unauthorized
      return
    end

    @current_api_key.update_column(:last_used_at, Time.current)
  end

  def set_organization_and_server
    @organization = Organization.find_by_permalink!(params[:org_permalink])
    
    unless @current_api_key.organization_id == @organization.id
      render json: { error: 'Access denied' }, status: :forbidden
      return
    end

    if params[:server_id]
      @server = @organization.servers.present.find_by_permalink!(params[:server_id])
    end
  end

  def render_not_found(exception)
    render json: { error: 'Record not found' }, status: :not_found
  end

  def render_validation_errors(exception)
    render json: { 
      error: 'Validation failed',
      errors: exception.record.errors.full_messages
    }, status: :unprocessable_entity
  end

  def render_success(data = {}, status = :ok, message = nil)
    response = { success: true, data: data }
    response[:message] = message if message
    render json: response, status: status
  end

  def render_error(message, status = :bad_request, errors = nil)
    response = { error: message }
    response[:errors] = errors if errors
    render json: response, status: status
  end

  def serialize_collection(collection, serializer_class, options = {})
    ActiveModel::Serializer::CollectionSerializer.new(
      collection,
      serializer: serializer_class,
      **options
    )
  end

  def serialize_resource(resource, serializer_class, options = {})
    serializer_class.new(resource, options)
  end
end
