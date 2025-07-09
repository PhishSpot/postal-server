# frozen_string_literal: true

class API::V1::DomainsController < API::V1::BaseController
  before_action :set_domain, only: [:show, :update, :destroy, :verify, :dns_records, :check_dns]

  def index
    domains = @server ? @server.domains.order(:name) : @organization.domains.order(:name)
    render json: {
      success: true,
      data: serialize_collection(domains, API::V1::DomainSerializer)
    }
  end

  def show
    render json: {
      success: true,
      data: serialize_resource(@domain, API::V1::DomainSerializer)
    }
  end

  def create
    scope = @server ? @server.domains : @organization.domains
    domain = scope.build(domain_params)

    if @current_api_key.user.admin?
      domain.verification_method = "DNS"
      domain.verified_at = Time.current
    end

    if domain.save
      render json: {
        success: true,
        data: serialize_resource(domain, API::V1::DomainSerializer)
      }, status: :created
    else
      render_error('Failed to create domain', :unprocessable_entity, domain.errors.full_messages)
    end
  end

  def update
    if @domain.update(domain_params)
      render json: {
        success: true,
        data: serialize_resource(@domain, API::V1::DomainSerializer)
      }
    else
      render_error('Failed to update domain', :unprocessable_entity, @domain.errors.full_messages)
    end
  end

  def destroy
    @domain.destroy
    render_success({}, :ok, 'Domain deleted successfully')
  end

  def verify
    if @domain.verified?
      render json: {
        success: true,
        message: 'Domain is already verified',
        data: serialize_resource(@domain, API::V1::DomainSerializer)
      }
      return
    end

    case @domain.verification_method
    when "DNS"
      if @domain.verify_with_dns
        render json: {
          success: true,
          message: 'Domain verified successfully via DNS',
          data: serialize_resource(@domain.reload, API::V1::DomainSerializer)
        }
      else
        render_error('DNS verification failed', :unprocessable_entity, ['Could not verify domain via DNS. Please check your TXT record.'])
      end
    when "Email"
      handle_email_verification
    else
      render_error('Invalid verification method', :unprocessable_entity, ['Domain has an invalid verification method.'])
    end
  end

  def dns_records
    unless @domain.verified?
      render_error('Domain not verified', :unprocessable_entity, ['Domain must be verified before retrieving DNS records.'])
      return
    end

    render json: {
      success: true,
      data: API::V1::DNSRecordsSerializer.new(@domain).as_json
    }
  end

  def check_dns
    unless @domain.verified?
      render_error('Domain not verified', :unprocessable_entity, ['Domain must be verified before checking DNS records.'])
      return
    end

    if @domain.check_dns(:manual)
      render json: {
        success: true,
        message: 'DNS records are configured correctly',
        data: serialize_resource(@domain.reload, API::V1::DomainSerializer)
      }
    else
      render json: {
        success: false,
        message: 'DNS records have issues',
        data: serialize_resource(@domain.reload, API::V1::DomainSerializer),
        dns_errors: {
          spf: @domain.spf_error,
          dkim: @domain.dkim_error,
          mx: @domain.mx_error,
          return_path: @domain.return_path_error
        }
      }
    end
  end

  private

  def set_domain
    domain_name = params[:domain_name]
    
    if @server
      @domain = @server.domains.find_by!(name: domain_name)
    else
      @domain = @organization.domains.find_by!(name: domain_name)
    end
  end

  def domain_params
    params.require(:domain).permit(:name)
  end

  def handle_email_verification
    verification_code = params[:verification_code]
    email_address = params[:email_address]

    if verification_code.present?
      if @domain.verification_token == verification_code.to_s.strip
        @domain.mark_as_verified
        render json: {
          success: true,
          message: 'Domain verified successfully via email',
          data: serialize_resource(@domain.reload, API::V1::DomainSerializer)
        }
      else
        render_error('Invalid verification code', :unprocessable_entity, ['The verification code provided is incorrect.'])
      end
    elsif email_address.present?
      unless @domain.verification_email_addresses.include?(email_address)
        render_error('Invalid email address', :unprocessable_entity, ['The email address is not valid for this domain.'])
        return
      end

      AppMailer.verify_domain(@domain, email_address, @current_api_key.user).deliver
      render json: {
        success: true,
        message: 'Verification email sent',
        data: { email_address: email_address }
      }
    else
      render_error('Missing parameters', :bad_request, ['Either verification_code or email_address is required for email verification.'])
    end
  end
end
