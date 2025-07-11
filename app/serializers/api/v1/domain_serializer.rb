# frozen_string_literal: true

class API::V1::DomainSerializer < ActiveModel::Serializer
  attributes :id, :name, :verification_method, :verification_token, :verified_at,
             :outgoing, :incoming, :use_for_any, :dns_status, :dkim_identifier,
             :created_at, :updated_at

  def id
    object.uuid
  end

  def verified_at
    object.verified_at&.iso8601
  end

  def dns_status
    {
      last_checked: object.dns_checked_at&.iso8601,
      spf_status: object.spf_status,
      spf_error: object.spf_error,
      dkim_status: object.dkim_status,
      dkim_error: object.dkim_error,
      mx_status: object.mx_status,
      mx_error: object.mx_error,
      return_path_status: object.return_path_status,
      return_path_error: object.return_path_error
    }
  end

  def dkim_identifier
    object.dkim_identifier_string
  end

  def created_at
    object.created_at&.iso8601
  end

  def updated_at
    object.updated_at&.iso8601
  end
end