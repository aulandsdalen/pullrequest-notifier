require 'sequel'
require 'telegram/bot'
require 'json'
require 'sinatra'

DB = Sequel.connect('sqlite://pr.db')