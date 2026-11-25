class AddSignerUserToAgpContracts < ActiveRecord::Migration[7.1]
  def change
    add_reference :agp_contracts, :signer_user, foreign_key: { to_table: :users }, null: true
  end
end
