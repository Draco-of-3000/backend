class AddWinsLossesToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :wins, :integer, null: false, default: 0
    add_column :users, :losses, :integer, null: false, default: 0
  end
end
