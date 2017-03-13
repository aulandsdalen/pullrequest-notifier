require 'sequel'
require 'json'
require 'sinatra'
require 'bcrypt'
require 'sinatra/session'

set :views, settings.root + '/views'
set :public_folder, 'assets'
set :session_fail, '/login'
set :bind, '0.0.0.0'

DB = Sequel.connect('sqlite://pr.db')

get '/' do
	haml :index, :locals  => {:login => session[:login]}
end

get '/login' do
	if session?
		redirect '/'
	else
		haml :login
	end
end


get '/requests' do
	session!
	request_table = DB[:pulls].join(:names, :uid => :owner_id)
	requests = request_table.all
	haml :pulls, :locals => {:reqs => requests}
end

get '/students' do
	session!
	students_table = DB[:names].left_outer_join(:groups, :gid => :group_id)
	students = students_table.all
	haml :users, :locals =>  {:students => students}
end

get '/students/:sid' do
	session!
	users_table = DB[:names].left_outer_join(:groups, :gid => :group_id)
	pulls_table = DB[:pulls].where(:owner_id => params[:sid])
	pulls = pulls_table.all
	user = users_table.where(:uid => params[:sid])
	user = user.first
	haml :user, :locals => {:data => user, :reqs => pulls}
end

post '/login' do
	login = DB[:mgmt].where(:login => params[:login]).first
	redirect '/login' unless login
	hashed_pwd = BCrypt::Password.new(login[:hash])
	if hashed_pwd == params[:password]
		session_start!
		session[:login] = params[:login]
		redirect '/'
	else
		redirect '/login'
	end
end

get '/logout' do
	session_end!
	redirect '/'
end

post '/gh-event' do
	payload = JSON.parse(request.body.read)
	action = payload['action']
	url = payload['pull_request']['html_url']
	created_at = payload['pull_request']['created_at']
	is_merged = payload['pull_request']['merged']
	creator = payload['pull_request']['user']['login']
	user = DB[:names][:username => creator]
	if user
		user_id = user[:uid]
	else
		DB[:names].insert(:username => creator, :realname => 'UNKNOWN')
		logger.info 'new username #{creator}'
		user_id = DB[:names][:username => creator][:uid]
	end
	if action == 'opened'
		logger.info "new pull_request opened"
		DB[:pulls].insert(:owner_id => user_id, 
						  :is_open => true, 
						  :is_merged => is_merged, 
						  :link => url, 
						  :created_at => created_at)
		{:status => true}.to_json
	elsif (action == 'closed' && is_merged)
		logger.info "pull request merged"
		DB[:pulls].where(:link => url).update(:is_open => false, :is_merged => true)
		{:status => true}.to_json
	end
end


### API SECTION ###

get '/requests.json' do
	request_table = DB[:pulls].join(:names, :uid => :owner_id)
	requests = request_table.all
	requests.to_json
end

get '/requests/:id.json' do
	id = params[:id]
	request_table = DB[:pulls].join(:names, :uid => :owner_id)
	request = request_table.where(:id => id)
	request.first.to_json
end

get '/groups.json' do
	DB[:groups].all.to_json
end

get '/students.json' do
	DB[:names].all.to_json
end

post '/create-group' do
	if session?
		payload = JSON.parse(request.body.read)
		groups = DB[:groups].where(:group_name => payload["group_name"])
		if groups.empty?
			DB[:groups].insert(:group_name => payload["group_name"])
			{:status => true}.to_json
		else
			{:status => 'fail', :reason => 'group already exists}'}.to_json
		end
	else
		{:status => 'fail', :reason => 'not logged in'}.to_json
	end
end

post '/create-student' do
	if session?
		payload = JSON.parse(request.body.read)
		students = DB[:names].where(:username => payload["username"]).all
		groups = DB[:groups].where(:gid => payload["group_id"]).all
		if students.empty?
			if groups.empty?
				{:status => 'fail', :reason => 'group does not exist'}.to_json
			else
				DB[:names].insert(:realname => payload['realname'], :username => payload['username'], :group_id => payload['group_id'])
				{:status => true}.to_json
			end
		else
			{:status => 'fail', :reason => 'student with this username already exists'}.to_json
		end
	else
		{:status => 'fail', :reason => 'not logged in'}.to_json
	end
end

post '/update-student' do
	if session?
		payload = JSON.parse(request.body.read) 
		students = DB[:names].where(:username => payload["username"]).all
		unless students.empty?
			DB[:names].where(:username => payload["username"]).update(:realname => payload["realname"], :group_id => payload["group_id"])
			{:status => true}.to_json
		else
			{:status => 'fail', :reason => 'username not found'}.to_json
		end
	else
		{:status => 'fail', :reason => 'not logged in'}.to_json
	end
end