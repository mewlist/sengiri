# Sengiri

Flexible sharding access for Ruby on Rails with ActiveRecord

## Sharding model generator

    rails g sengiri:model mygroup user name:string

## database.yml

    mysql: &mysql
      adapter: mysql2
      encoding: utf8
      reconnect: false
      pool: 1
      username: root
      password:
      host: localhost
    
    mygroup_shards_first: # define shard as 'first'
      <<: *mysql
      database: mygroup_1
      host: hosta
    mygroup_shards_second: # define shard as 'second'
      <<: *mysql
      database: mygroup_2
      host: hostb
    mygroup_shards_third: # define shard as 'third'
      <<: *mysql
      database: mygroup_3
      host: hostc
    .
    .
    .

## Sharding migration

    rake sengiri:mygroup:db:create
    rake sengiri:mygroup:db:migrate

    
## Sharding access

    User.shard('second') do |shard|
      shard.all.limit(10) # query on db 'mygroup_1'
    end


    User.shards do |shard|
      shard.all.limit(10) # query on all db 'mygroup_1', 'mygroup_2', 'mygroup_3'
    end

## Transaction

    User.shard('second').transaction do
      # in mygroup_2 transaction
    end


    User.transaction do
      # in mygroup_1, mygroup_2 and mygroup_3 transaction
    end


    # This is same as below


    User.shard('first').transaction do
      User.shard('second').transaction do
        User.shard('third').transaction do
        end
      end
    end


This project rocks and uses MIT-LICENSE.
