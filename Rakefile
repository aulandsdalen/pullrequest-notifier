require 'sequel'

=begin
CREATE TABLE pulls(id integer primary key autoincrement, owner_id int, is_open boolean, is_merged boolean, link varchar(255), created_at datetime);
CREATE TABLE "names"(uid integer primary key autoincrement, group_id int, username varchar(255), realname varchar(255));
CREATE TABLE "groups"(gid integer primary key autoincrement, group_name varchar(255));
CREATE TABLE mgmt(id integer primary key autoincrement, login varchar(255), hash varchar(255));
=end

task :initdb do
	dbname = ENV["dbname"]
	username = ENV["username"]
	password = ENV["password"]
	puts "initializing database #{dbname}"
	DB = Sequel.connect("postgres://#{username}@localhost:5432/#{dbname}")
	puts "creating pulls table"
	DB.create_table :pulls do 
		primary_key :id
		Integer :owner_id
		Boolean :is_open
		Boolean :is_merged
		String :link
		DateTime :created_at
	end
	puts "creating names table"
	DB.create_table :names do
		primary_key :uid
		Integer :group_id
		String :username
		String :realname
	end
	puts "creating groups table"
	DB.create_table :groups do
		primary_key :gid
		String :group_name
	end
	puts "initializing management"
	DB.create_table :mgmt do
		primary_key :id
		String :login
		String :hash
	end
	DB[:mgmt].insert(:login => "aulandsdalen", :hash => "$2a$10$kUQA1ndJv2A5RjlLgIdzAejvmRYFlX1gpro4I0gVecBeQPF3ziL5W")
end