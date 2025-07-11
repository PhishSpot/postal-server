class CreateAPIKeys < ActiveRecord::Migration[7.0]
  def change
    create_table :api_keys do |t|
      t.integer :organization_id, null: false
      t.integer :user_id, null: false
      t.string :uuid
      t.string :name
      t.string :token_digest
      t.datetime :last_used_at

      t.timestamps
    end

    add_foreign_key :api_keys, :organizations
    add_foreign_key :api_keys, :users
  end
end
