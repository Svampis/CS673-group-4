class AddTwoFactorAuthToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :two_factor_secret, :string
    add_column :users, :two_factor_enabled, :boolean, default: false
  end
end
