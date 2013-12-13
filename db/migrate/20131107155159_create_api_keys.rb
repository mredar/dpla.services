class CreateApiKeys < ActiveRecord::Migration
  def change
    create_table :api_keys do |t|
      t.string :api_key
      t.string :email

      t.timestamps
    end
  end
end
