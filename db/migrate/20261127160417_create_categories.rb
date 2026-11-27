class CreateCategories < ActiveRecord::Migration[8.1]
  def change
    create_table :categories do |t|
      t.references :store, null: false, foreign_key: true
      t.references :parent, foreign_key: { to_table: :categories }
      t.string :name_ar, null: false
      t.string :name_en
      t.text :description_ar
      t.text :description_en
      t.integer :position, default: 0, null: false
      t.boolean :active, default: true, null: false

      t.timestamps
    end
    add_index :categories, [ :store_id, :parent_id, :position ]
  end
end
