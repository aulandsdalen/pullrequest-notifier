require 'rubygems'
require 'sinatra'
require 'sequel'
require 'json'
require 'bcrypt'
require 'sinatra/session'
require 'pony'
require 'tempfile'
require './app/helpers.rb'
require File.expand_path '../app/app.rb', __FILE__

run Sinatra::Application