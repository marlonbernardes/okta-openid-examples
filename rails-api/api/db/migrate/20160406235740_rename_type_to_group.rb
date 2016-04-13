class RenameTypeToGroup < ActiveRecord::Migration
  def change
    rename_column :events, :type, :group
  end
end
