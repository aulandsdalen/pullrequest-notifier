Sequel.migration do
	change do
		add_column :pulls, :build_status, TrueClass, :default => false
		add_column :pulls, :build_log, String, :text => true
	end
end