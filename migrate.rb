require 'sequel'

Sequel.extension :migration, :core_extensions

DB = Sequel.connect(ENV['DATABASE_URL'])

Sequel::Migrator.apply(DB, 'migrations')