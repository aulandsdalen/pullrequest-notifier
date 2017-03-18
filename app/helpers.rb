def send_welcome_email(email, login, name)
	Pony.mail({
		:to => email,
		:via => :smtp,
		:via_options => {
		    :address              => 'smtp.gmail.com',
		    :port                 => '587',
		    :enable_starttls_auto => true,
		    :user_name            => 'janechecksmirea',
		    :password             => 'P!ssw0rd',
		    :authentication       => :plain, # :plain, :login, :cram_md5, no auth by default
		    :domain               => "jc.mirea.ru" # the HELO domain provided by the client to the server
			},
		:html_body => (haml :emailtemplate, :locals => {:login => login, :name => name}),
		:subject => "Пользователь #{login} зарегистрирован"
		})
end