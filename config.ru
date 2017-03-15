require 'rubygems'
require 'sinatra'
require 'sequel'
require 'json'
require 'bcrypt'
require 'sinatra/session'
require File.expand_path '../app.rb', __FILE__

run Sinatra::Application