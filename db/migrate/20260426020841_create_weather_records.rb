class CreateWeatherRecords < ActiveRecord::Migration[8.1]
  def change
    create_table :weather_records do |t|
      t.references :diary, null: false, foreign_key: true
      t.string :city_name, null: false
      t.string :weather_main, null: false
      t.string :description
      t.float :temp
      t.integer :humidity
      t.float :rainfall_mm

      t.timestamps
    end
  end
end
