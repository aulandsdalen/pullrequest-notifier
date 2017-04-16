Sequel.migration do
	change do
		drop_column :pulls, :build_status
		add_column :pulls, :build_status, TrueClass
	end
end