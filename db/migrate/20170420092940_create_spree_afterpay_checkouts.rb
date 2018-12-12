class CreateSpreeAfterpayCheckouts < ActiveRecord::Migration
  def change
    create_table :spree_afterpay_checkouts do |t|
      t.string :token
      t.string :payer_id
      t.string :transaction_id
      t.string :state, default: 'complete'
      t.string :refund_transaction_id
      t.datetime :refunded_at
      t.string :refund_type
    end
  end
end
