class AddUtcOffsetToDevice < ActiveRecord::Migration[5.2]
  def change
    add_column :devices, :utc_offset, :integer
  end
end
