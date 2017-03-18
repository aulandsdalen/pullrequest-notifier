Sequel.migration do
	change do
		add_column :names, :email, String
	end
end