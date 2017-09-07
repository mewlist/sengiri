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

ENV['SENGIRI_ENV'] = 'rails_env'

class SengiriModel < Sengiri::Model::Base
  sharding_group 'sengiri', confs: {
    'sengiri_shard_1_rails_env'=> {
      adapter: "sqlite3",
      database: "spec/db/sengiri_shard_1.sqlite3",
      pool: 5,
      timeout: 5000,
    },
    'sengiri_shard_second_rails_env'=> {
      adapter: "sqlite3",
      database: "spec/db/sengiri_shard_2.sqlite3",
      pool: 5,
      timeout: 5000,
    },
  }
end

class SengiriModelWithSuffix < Sengiri::Model::Base
  sharding_group 'sengiri', {
    confs: {
      'sengiri_shard_1_rails_env_suffix'=> {
        adapter: "sqlite3",
        database: "spec/db/sengiri_shard_secondary_1.sqlite3",
        pool: 5,
        timeout: 5000,
      },
      'sengiri_shard_second_rails_env_suffix'=> {
        adapter: "sqlite3",
        database: "spec/db/sengiri_shard_secondary_2.sqlite3",
        pool: 5,
        timeout: 5000,
      },
    },
    suffix: 'suffix' }
end
