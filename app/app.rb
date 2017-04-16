set :views, settings.root + '/views'
set :public_folder, 'assets'
set :session_fail, '/login'

MAJOR_VERSION = 0
MINOR_VERSION = 2
APP_VERSION = "#{MAJOR_VERSION}.#{MINOR_VERSION} build " + ENV['HEROKU_RELEASE_VERSION']

DB = Sequel.connect(ENV['DATABASE_URL'])

get '/' do
	if session?
		redirect '/requests'
	else
		haml :index
	end
end

get '/info' do
	session!
	haml :info, :locals => {:info => getinfo, :version => APP_VERSION}
end

get '/login' do
	if session?
		redirect '/'
	else
		haml :login
	end
end

get '/build-generator' do
	haml :buildgen, :locals => {:version => "#{MAJOR_VERSION}.#{MINOR_VERSION}", :build => ENV['HEROKU_RELEASE_VERSION'], :format_version => 1}
end

get '/requests' do
	session!
	request_table = DB[:pulls].join(:names, :uid => :owner_id).order(Sequel.desc(:created_at))
	requests = request_table.all
	haml :pulls, :locals => {:reqs => requests, :login =>session[:login], :version => APP_VERSION}
end

get '/requests/:id' do
	session!
end

get '/students' do
	session!
	students_table = DB[:names].left_outer_join(:groups, :gid => :group_id).order(Sequel.asc(:uid))
	students = students_table.all
	haml :users, :locals =>  {:students => students, :version => APP_VERSION}
end

get '/students/:sid' do
	session!
	users_table = DB[:names].left_outer_join(:groups, :gid => :group_id)
	pulls_table = DB[:pulls].where(:owner_id => params[:sid])
	pulls = pulls_table.all
	user = users_table.where(:uid => params[:sid])
	user = user.first
	redirect '/students' unless user
	haml :user, :locals => {:data => user, :reqs => pulls, :version => APP_VERSION}
end

get '/students/:sid/delete' do
	session! 
	DB[:names].where(:uid => params[:sid]).delete
	redirect '/students'
end

get '/students/:sid/edit' do
	session!
	users_table = DB[:names].left_outer_join(:groups, :gid => :group_id)
	user = users_table.where(:uid => params[:sid]).first
	groups = DB[:groups].all
	haml :user_edit, :locals => {:user => user, :groups => groups, :version => APP_VERSION}
end

get '/tasks' do
	session!
	tasks_table = DB[:tasks].left_outer_join(:mgmt, :id => :assigned_by)
	tasks = tasks_table.all
	haml :tasks, :locals => {:tasks => tasks, :version => APP_VERSION}
end

get '/tasks/:tid' do 
	# show all requests related to this particular tid
end

get '/logout' do
	session_end!
	redirect '/'
end

get '/signup' do
	haml :signup, :locals => {:version => APP_VERSION}
end

get '/signup-success' do
	haml :signup_success
end

post '/signup' do
	logger.info params
	payload = JSON.parse(request.body.read)
	realname = payload['realname']
	username = payload['username']
	email = payload['email']
	group_id = payload['group']
	unless(DB[:names].where(:username => username).all.empty?)
		return {:status => false, :reason => "user #{username} already exists"}.to_json
	end
	unless(DB[:names].where(:email => email).all.empty?)
		return {:status => false, :reason => "user with email #{email} already exists"}.to_json
	end
	unless (email.email?)
		return {:status => false, :reason => "#{email} is not an email address"}.to_json
	end
	DB[:names].insert(:group_id => group_id,
					  :realname => realname,
					  :username => username,
					  :email => email)
	send_welcome_email(email, username, realname)
	{:status => true}.to_json
end


post '/gh-event' do
	# for tasks: 
	# full repo url is sent as payload['repository']['html_url']
	# github sends probe request when initializing new webhook
	# these requests have payload['zen'] field, while pull-request doesn't
	payload = JSON.parse(request.body.read)
	if payload['zen']
		# new repo initialized by github 
		# when a new repo initialized, task's creator defaults to id=1
		logger.info "new repo initialized, zen was #{payload['zen']}"
		DB[:tasks].insert(:assigned_by => 1,
						  :url => payload['repository']['html_url'],
						  :created_at => payload['repository']['created_at']) # will use repo creation date here
		{:status => true}.to_json
	else
		action = payload['action']
		url = payload['pull_request']['html_url']
		repo_url = payload['repository']['html_url'] # upstream
		created_at = payload['pull_request']['created_at']
		is_merged = payload['pull_request']['merged']
		creator = payload['pull_request']['user']['login']
		user = DB[:names][:username => creator]
		if user
			user_id = user[:uid]
		else
			DB[:names].insert(:username => creator, :realname => 'UNKNOWN')
			logger.info "new username #{creator}"
			user_id = DB[:names][:username => creator][:uid]
		end
		if action == 'opened'
			logger.info "new pull_request opened"
			task = DB[:tasks].where(:url => repo_url).first
			if task.nil?
				task_id = 0
			else
				task_id = task[:task_id]
			end
			DB[:pulls].insert(:owner_id => user_id, 
							  :is_open => true, 
							  :is_merged => is_merged, 
							  :link => url, 
							  :created_at => created_at,
							  :tid => task_id)
			{:status => true}.to_json
		elsif (action == 'closed' && is_merged)
			logger.info "pull request merged"
			DB[:pulls].where(:link => url).update(:is_open => false, :is_merged => true)
			send_status_email(user[:email], url, true)
			{:status => true}.to_json
		elsif (action == 'closed' && !is_merged)
			logger.info "pull request closed without merging"
			DB[:pulls].where(:link => url).update(:is_open => false)
			send_status_email(user[:email], url, false)
			{:status => true}.to_json
		end
	end
end


post '/login' do
	logger.info params
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
	DB[:groups].order(Sequel.asc(:group_name)).all.to_json
end

get '/students.json' do
	DB[:names].all.to_json
end

get '/session-status.json' do
	if session?
		{:status => true,
		 :message => "logged in"}.to_json
	else
		{:status => false,
		 :message => "not logged in"}.to_json
	end
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
				DB[:names].insert(:realname => payload['realname'], 
								  :username => payload['username'], 
								  :group_id => payload['group_id'])
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
		students = DB[:names].where(:uid => payload["uid"]).all
		unless students.empty?
			DB[:names].where(:uid => payload["uid"]).update(:realname => payload['realname'],
																	  :username => payload['username'],
																	  :group_id => payload['group'], 
																	  :email => payload['email'])
			{:status => true}.to_json
		else
			{:status => false, :reason => 'user not found'}.to_json
		end

	else
		{:status => false, :reason => 'not logged in'}.to_json
	end
end