#!/bin/bash

###
# инициализируем сервер конфигурайций
###
docker compose exec -T configSrv mongosh --port 27017 --quiet <<EOF
rs.initiate(
  {
    _id : "config_server",
       configsvr: true,
    members: [
      { _id : 0, host : "configSrv:27017" }
    ]
  }
);
exit();
EOF

###
# инициализируем шарды базы
###
docker compose exec -T mongodb1 mongosh --port 27019 --quiet <<EOF
rs.initiate({_id: "shard1", members: [
{_id: 0, host: "mongodb1:27019"},
{_id: 1, host: "mongodb2:27020"},
{_id: 2, host: "mongodb3:27021"}
]});
exit();
EOF

docker compose exec -T mongodb4 mongosh --port 27022 --quiet <<EOF
rs.initiate({_id: "shard2", members: [
{_id: 0, host: "mongodb4:27022"},
{_id: 1, host: "mongodb5:27023"},
{_id: 2, host: "mongodb6:27024"}
]});
exit(); 
EOF

###
# инициализируем роутер, создаем коллекцию и заполняем ее данными
###
docker compose exec -T mongos_router mongosh --port 27018 --quiet <<EOF
sh.addShard( "shard2/mongodb4:27022");
sh.addShard( "shard2/mongodb5:27023");
sh.addShard( "shard2/mongodb6:27024");
sh.addShard( "shard1/mongodb1:27019");
sh.addShard( "shard1/mongodb2:27020");
sh.addShard( "shard1/mongodb3:27021");

sh.enableSharding("somedb");
sh.shardCollection("somedb.helloDoc", { "name" : "hashed" } )

use somedb

for(var i = 0; i < 1000; i++) db.helloDoc.insert({age:i, name:"ly"+i})
exit();
EOF