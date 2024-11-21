#!/bin/bash

###
# Инициализируем бд
###

##Сервер конфигурации
docker compose exec -T configSrv1 mongosh --port 27017 --quiet <<EOF
rs.initiate(
  {
    _id : "config_server1",
       configsvr: true,
    members: [
      { _id : 0, host : "configSrv1:27017" }
    ]
  }
);
EOF

##Сегмент 1-1
docker compose exec -T shard11 mongosh --port 27017 --quiet <<EOF
rs.initiate(
    {
      _id : "shard11",
      members: [
        { _id : 0, host : "shard11:27017" }
      ]
    }
);
EOF
##Сегмент 1-2
docker compose exec -T shard12 mongosh --port 27017 --quiet <<EOF
rs.initiate(
    {
      _id : "shard12",
      members: [
        { _id : 1, host : "shard12:27017" }
      ]
    }
);
EOF

##Маршрутизатор
docker compose exec -T mongos_router1 mongosh --port 27017 --quiet <<EOF
sh.addShard( "shard11/shard11:27017");
sh.addShard( "shard12/shard12:27017");
sh.enableSharding("somedb");
sh.shardCollection("somedb.helloDoc", { "name" : "hashed" } );

use somedb;
for(var i = 0; i < 1000; i++) db.helloDoc.insertOne({age:i, name:"ly"+i});
EOF

