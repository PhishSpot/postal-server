# frozen_string_literal: true

class API::V1::CredentialsController < API::V1::BaseController
  before_action :set_credential, only: [:show, :update, :destroy]

  def index
    credentials = @server.credentials.order(:name)
    render json: {
      success: true,
      data: serialize_collection(credentials, API::V1::CredentialSerializer)
    }
  end

  def show
    render json: {
      success: true,
      data: serialize_resource(@credential, API::V1::CredentialSerializer)
    }
  end

  def create
    credential = @server.credentials.build(credential_params)
    
    if credential.save
      render json: {
        success: true,
        data: serialize_resource(credential, API::V1::CredentialSerializer)
      }, status: :created
    else
      render_error('Failed to create credential', :unprocessable_entity, credential.errors.full_messages)
    end
  end

  def update
    if @credential.update(credential_params)
      render json: {
        success: true,
        data: serialize_resource(@credential, API::V1::CredentialSerializer)
      }
    else
      render_error('Failed to update credential', :unprocessable_entity, @credential.errors.full_messages)
    end
  end

  def destroy
    @credential.destroy
    render_success({}, :ok, 'Credential deleted successfully')
  end

  private

  def set_credential
    @credential = @server.credentials.find_by!(uuid: params[:id])
  end

  def credential_params
    params.require(:credential).permit(:type, :name, :key, :hold)
  end
end