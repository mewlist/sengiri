# Sengiri

Flexible sharding access with ActiveRecord

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
    
    mygroup_1:
      <<: *mysql
      database: mygroup_1
      host: hosta
    mygroup_2:
      <<: *mysql
      database: mygroup_2
      host: hostb
    mygroup_3:
      <<: *mysql
      database: mygroup_3
      host: hostc
    .
    .
    .

## Sharding migration

    rake sengiri:mygroup:db:create
    rake sengiri:mygroup:db:migrate


This project rocks and uses MIT-LICENSE.
