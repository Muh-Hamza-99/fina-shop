class CreateStores < ActiveRecord::Migration[8.1]
  def change
    create_table :stores do |t|
      t.string :name_ar, null: false
      t.string :name_en
      t.text :description_ar
      t.text :description_en
      t.string :subdomain, null: false, index: { unique: true }
      t.string :custom_domain, index: { unique: true }

      # Contact
      t.string :email
      t.string :phone
      t.string :whatsapp_phone
      t.string :website

      # Saudi national address (required for ZATCA e-invoicing)
      t.string :country_code, default: "SA", null: false
      t.string :region
      t.string :city
      t.string :district
      t.string :street
      t.string :building_number
      t.string :postal_code

      # KSA business identity
      t.string :unified_number_700
      t.string :cr_number
      t.string :vat_number
      t.boolean :zatca_enabled, default: false, null: false

      t.boolean :show_prices_default, default: true, null: false
      t.boolean :show_stock_default, default: false, null: false
      t.boolean :pos_sync_enabled, default: false, null: false
      t.string :fina_merchant_id
      t.string :subscription_status, default: "trialing", null: false
      t.datetime :trial_ends_at
      t.jsonb :theme_config, default: {}, null: false

      t.timestamps
    end
  end
end
