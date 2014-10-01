# Sengiri

Flexible sharding access for Ruby on Rails with ActiveRecord

## Sharding model generator

```
    rails g sengiri:model mygroup user name:string
```

## database.yml

```ruby
    mysql: &mysql
      adapter: mysql2
      encoding: utf8
      reconnect: false
      pool: 1
      username: root
      password:
      host: localhost
    
    mygroup_shard_first: # define shard as 'first'
      <<: *mysql
      database: mygroup_1
      host: hosta
    mygroup_shard_second: # define shard as 'second'
      <<: *mysql
      database: mygroup_2
      host: hostb
    mygroup_shard_third: # define shard as 'third'
      <<: *mysql
      database: mygroup_3
      host: hostc
    .
    .
    .
```

## Sharding migration

ActiveRecord task is available on every shard.

```ruby
    rake sengiri:mygroup:db:create
    rake sengiri:mygroup:db:migrate
    rake sengiri:mygroup:db:rollback
    ...
```
    
## Sharding access

On a shard, ActiveRecord class is given.

```ruby
    User.shard('second') do |shard|
      shard.all.limit(10)   # query on db 'mygroup_2'
      shard.find(1)         # query on db 'mygroup_2'
    end
```

Every shard.

```ruby
    User.shards do |shard|
      shard.all.limit(10) # query on all shards 'mygroup_1', 'mygroup_2', 'mygroup_3'
    end
```

All records from all shards.

```ruby
    all_records = User.all.broadcast
```

## Transaction

In a shard transaction.

```ruby
    User.shard('second').transaction do
      # in mygroup_2 transaction
    end
```

In all shards transaction.

```ruby
    User.transaction do
      # in mygroup_1, mygroup_2 and mygroup_3 transaction
    end
```

This is same as below

```ruby
    User.shard('first').transaction do
      User.shard('second').transaction do
        User.shard('third').transaction do
        end
      end
    end
```

This project rocks and uses MIT-LICENSE.
