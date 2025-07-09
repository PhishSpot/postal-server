# frozen_string_literal: true

class APIKeysController < ApplicationController
  include WithinOrganization

  before_action :set_api_key, only: [:destroy]

  def index
    @api_keys = organization.api_keys.order(created_at: :desc)
    @api_key = organization.api_keys.build
  end

  def new
    @api_key = organization.api_keys.build
  end

  def create
    @api_key = organization.api_keys.build(api_key_params)
    @api_key.user = current_user

    if @api_key.save
      flash[:notice] = "API Key created successfully."
      flash[:raw_token] = @api_key.raw_token # shown once only!
      redirect_to_with_json organization_api_keys_path(organization)
    else
      render_form_errors "new", @api_key
    end
  end

  def destroy
    @api_key.destroy
    redirect_to_with_json organization_api_keys_path(organization), notice: "API Key deleted."
  end

  private

  def set_api_key
    @api_key = organization.api_keys.find_by!(uuid: params[:id])
  end

  def api_key_params
    params.require(:api_key).permit(:name)
  end
end