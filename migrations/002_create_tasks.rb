Sequel.migration do
	change do
		create_table(:tasks) do
			primary_key :task_id
			Integer :assigned_by
			String :url
			DateTime :created_at
		end
	end
end