require 'active_record'
require 'active_record/base'
require File.expand_path('../../lib/sengiri', __FILE__)
require File.expand_path('../../lib/sengiri/model/base', __FILE__)

require "sqlite3"
require 'pry-byebug'

def setup_test_database(path)
  # Open a database
  db = SQLite3::Database.new path

  # Create a database
  rows = db.execute <<-SQL
    drop table if exists sengiri_models;
  SQL
  rows = db.execute <<-SQL
    create table sengiri_models ( id int PRIMARY KEY, name varchar(30));
  SQL
end

setup_test_database "spec/db/sengiri_shard_1.sqlite3"
setup_test_database "spec/db/sengiri_shard_2.sqlite3"
setup_test_database "spec/db/sengiri_shard_secondary_1.sqlite3"
setup_test_database "spec/db/sengiri_shard_secondary_2.sqlite3"
