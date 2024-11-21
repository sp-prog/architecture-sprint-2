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
docker compose exec -T shard111 mongosh --port 27017 --quiet <<EOF
rs.initiate(
    {
      _id : "shard111",
      members: [
        {_id: 111, host: "shard111:27017"},
        {_id: 112, host: "shard112:27017"},
        {_id: 113, host: "shard113:27017"}
      ]
    }
);
EOF

##Сегмент 1-2
docker compose exec -T shard121 mongosh --port 27017 --quiet <<EOF
rs.initiate(
    {
      _id : "shard121",
      members: [
        { _id: 121, host : "shard121:27017" },
        { _id: 122, host : "shard122:27017" },
        { _id: 123, host : "shard123:27017" }
      ]
    }
);
EOF


##Маршрутизатор
docker compose exec -T mongos_router1 mongosh --port 27017 --quiet <<EOF
sh.addShard( "shard111/shard111:27017");
sh.addShard( "shard121/shard121:27017");
sh.enableSharding("somedb");
sh.shardCollection("somedb.helloDoc", { "name" : "hashed" } );

use somedb;
for(var i = 0; i < 1000; i++) db.helloDoc.insertOne({age:i, name:"ly"+i});
EOF

