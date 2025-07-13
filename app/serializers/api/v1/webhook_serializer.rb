# frozen_string_literal: true

class API::V1::WebhookSerializer < ActiveModel::Serializer
  attributes :id, :name, :url, :all_events, :enabled, :sign, :events, 
             :last_used_at, :created_at, :updated_at

  def id
    object.uuid
  end

  def events
    object.webhook_events.pluck(:event)
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
