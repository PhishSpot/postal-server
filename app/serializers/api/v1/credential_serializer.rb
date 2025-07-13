# frozen_string_literal: true

class API::V1::CredentialSerializer < ActiveModel::Serializer
  attributes :id, :name, :type, :key, :hold, :last_used_at, :created_at, :updated_at

  def id
    object.uuid
  end

  def last_used_at
    object.last_used_at&.iso8601
  end

  def created_at
    object.created_at&.iso8601
  end

  def updated_at
    object.updated_at&.iso8601
  end
end
