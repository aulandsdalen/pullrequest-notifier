Sequel.migration do
	change do
		add_column :pulls, :tid, Integer
	end
end