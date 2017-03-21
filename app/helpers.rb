# extend String class & add email? method

class String
	def email?
		!((self =~ URI::MailTo::EMAIL_REGEXP).nil?)
	end
end


# mail helpers

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
		:html_body => (haml :welcomeemailtemplate, :locals => {:login => login, :name => name}),
		:subject => "Пользователь #{login} зарегистрирован"
		})
end

def send_status_email(email, url, accepted)
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
		:html_body => (haml :requestemailtemplate, :locals => {:success => accepted, :url => url}),
		})
end
