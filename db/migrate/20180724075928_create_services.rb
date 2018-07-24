class CreateServices < ActiveRecord::Migration[5.2]
  def change
    create_table :services do |t|
      t.string :name
      t.integer :price
      t.string :country
      t.integer :cost

      t.timestamps
    end
  end
end
