require 'sequel'
require 'telegram/bot'
require 'json'
require 'sinatra'

DB = Sequel.connect('sqlite://pr.db')


get '/' do
	requests = DB[:pull_request]

end

post '/gh-event' do
	logger.info "got request: #{params}"
end