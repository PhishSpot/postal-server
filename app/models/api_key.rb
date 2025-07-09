# frozen_string_literal: true

# == Schema Information
#
# Table name: api_keys
#
#  id              :bigint           not null, primary key
#  last_used_at    :datetime
#  name            :string(255)
#  token_digest    :string(255)
#  uuid            :string(255)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  organization_id :integer          not null
#  user_id         :integer          not null
#
# Indexes
#
#  fk_rails_32c28d0dc2  (user_id)
#  fk_rails_7aab96f30e  (organization_id)
#
# Foreign Keys
#
#  fk_rails_...  (organization_id => organizations.id)
#  fk_rails_...  (user_id => users.id)
#

class APIKey < ApplicationRecord
  include HasUUID

  belongs_to :organization
  belongs_to :user

  validates :name, :token_digest, presence: true
  validates :token_digest, uniqueness: true

  before_validation :generate_token, on: :create

  attr_reader :raw_token

  def self.digest(token)
    Digest::SHA256.hexdigest(token)
  end

  def self.authenticate(token)
    digest = digest(token)
    find_by(token_digest: digest)
  end

  def to_param
    uuid
  end

  private

  def generate_token
    raw_token = SecureRandom.hex(32)
    self.token_digest = APIKey.digest(raw_token)
    @raw_token = raw_token
  end
end
