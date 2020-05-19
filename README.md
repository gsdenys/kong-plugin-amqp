# Kong plugin AMQP

This repository contains AMQP Kong plugin that's permits post message directly on AMQP exchange.

__IMPORTANT:__ _As this one use the template designed to work with the `kong-vagrant` [development environment](https://github.com/Mashape/kong-vagrant). Please check out that repo's `README` for usage instructions._

## Install

This section shows how to install this one in a built in kong docker image.

1) Create a new folder and download the package 1.0.0 using command below.

    ```sh
    # Create a new Folder
    $ mkdir kong-plugin-amqp
    $ cd kong-plugin-amqp

    #download the lua rock package
    $wget https://github.com/gsdenys/kong-plugin-amqp/releases/download/1.0.0/kong-plugin-amqp-1.0.0-6.src.rock
    ```

2) Create a Dockerfile with the content below.
    ```docker
    FROM kong:2.0

    USER root
    RUN apk add git

    # This lib is required by lua uuid package
    RUN apk add libuuid

    COPY *.src.rock .
    RUN luarocks install kong-plugin-amqp-1.0.0-6.src.rock

    # This is required because this plugin needs to write a kong core file
    # Issue #8 https://github.com/gsdenys/kong-plugin-amqp/issues/8
    # the better is kong provide a protocol extension point
    RUN /usr/local/openresty/luajit/bin/luajit /usr/local/share/lua/5.1/kong/plugin/amqp/prepare.lua

    USER kong
    ```

3) Execute the command to generate the dist.

    ```sh
    $ docker build --tag kong-plugin-amqp .
    ```

4) Now, run the containers.

    ```sh
    # Start Kong Postgres Database
    $ docker run -d --name kong-database \
        --network=kong-net \
        -p 5432:543 \
        -e "POSTGRES_USER=kong" \ 
        -e "POSTGRES_DB=kong" \
        -e "POSTGRES_PASSWORD=kong" \           
        postgres:9.6 

    # Execute Kong Migrations
    $ docker run --rm \ 
        --network=kong-net \
        -e "KONG_DATABASE=postgres" \  
        -e "KONG_PG_HOST=kong-database" \                 
        -e "KONG_PG_PASSWORD=kong" \
        -e "KONG_CASSANDRA_CONTACT_POINTS=kong-database" \
        kong:latest kong migrations bootstrap  

    # Execute Kong
    $ docker run --name kong \
        --network=kong-net \
        -e "KONG_DATABASE=postgres" \
        -e "KONG_PG_HOST=kong-database" \
        -e "KONG_PG_PASSWORD=kong" \
        -e "KONG_CASSANDRA_CONTACT_POINTS=kong-database" \
        -e "KONG_PROXY_ACCESS_LOG=/dev/stdout" \
        -e "KONG_ADMIN_ACCESS_LOG=/dev/stdout" \
        -e "KONG_PROXY_ERROR_LOG=/dev/stderr" \
        -e "KONG_ADMIN_ERROR_LOG=/dev/stderr" \
        -e "KONG_PLUGINS=bundled,amqp" \
        -e "KONG_ADMIN_LISTEN=0.0.0.0:8001, 0.0.0.0:8444 ssl" \
        -p 8000:8000 \
        -p 8443:8443 \
        -p 127.0.0.1:8001:8001 \
        -p 127.0.0.1:8444:8444 \
        kong-plugin-amqp:latest
    ```

## Usage

1) Check if the plugin are installed execution the following command.

    ```sh
    $ curl -X GET http://localhost:8001
    ```

    and search by:

    ```json
    "plugins": {
        // ...
        "available_on_server": {
            // ...
            "amqp": true,
            // ...
        }
    }
    ```

2) create a service using the protocol `amqp`.

    ```sh
    $ curl -i -X POST \
        --url http://localhost:8001/services/ \
        --data 'name=example-service' \
        --data 'url=amqp://rabbitamqp' \
        --data 'port=5672'
    ```
    the result is:

    ```json
    {
        "host":"rabbitamqp",
        "created_at":1589889979,
        "connect_timeout":60000,
        "id":"e5820acd-5d40-4547-aa15-5fb45d8bab75",
        "protocol":"amqp",
        "name":"example-service",
        "read_timeout":60000,
        "port":5672,
        "path":null,
        "updated_at":1589889979,
        "retries":5,
        "write_timeout":60000,
        "tags":null,
        "client_certificate":null
    }
    ```

3) Add the plugin to the service

    ```sh
    $ curl -i -X POST \
        --url http://localhost:8001/services/example-service/plugins/ \
        --data 'name=amqp' \
        --data 'config.routingkey=test'
    ```

    the result is:

    ```json
    {
        "created_at":1589890576,
        "config":{
            "routingkey":"test",
            "user":"guest",
            "password":"guest",
            "exchange":""
        },
        "id":"6b562949-a592-4f3d-bc3d-4b37bbba0c68",
        "service":{
            "id":"e5820acd-5d40-4547-aa15-5fb45d8bab75"
        },
        "enabled":true,
        "protocols":["amqp","grpc","grpcs","http","https"],
        "name":"amqp",
        "consumer":null,
        "route":null,
        "tags":null
    }
    ```

4) Create a route

    ```sh
    $ curl -i -X POST \
        --url http://localhost:8001/services/example-service/routes \
        --data 'paths[]=/amqp-example'
    ```

    the result is:

    ```json
    {
        "id":"ba7eb735-969b-4adf-966b-4e0d8213a752",
        "path_handling":"v0",
        "paths":["\/amqp-example"],
        "destinations":null,
        "headers":null,
        "protocols":["http","https"],
        "methods":null,
        "snis":null,
        "service":{
            "id":"e5820acd-5d40-4547-aa15-5fb45d8bab75"
        },
        "name":null,
        "strip_path":true,
        "preserve_host":false,
        "regex_priority":0,
        "updated_at":1589890208,
        "sources":null,
        "hosts":null,
        "https_redirect_status_code":426,
        "tags":null,
        "created_at":1589890208
    }
    ```

5) Bind though the created route

    ```sh
    $ curl -X POST http://localhost:8000/amqp-example \
        --data '{"hello":"world"}' \
        -H "Content-Type:application/json"
    ```

    the result is:

    ```json
    {
        "uuid":"9da7f847-b069-49f2-8b43-e49c520d66fd",
        "time":"2020-05-19 12:34:49"
    }
    ```

6) Check if the Rabbit has the message.

![RabbitMQ Message Add](../media/rabbit-1.png?raw=true)

![RabbitMQ Message Stored](../media/rabbit-2.png?raw=true)

## Develop 

Once you've followed the steps in the documentation above mentioned, you'll note that this plugin will not works or simply do not appear on the /kong-plugin folder.

Its occur because the vagrant file just make reference to the kong-plugin-template. So you needs to change this refece to make its works. Against that, you can clone this one to the kong-plugin folder instead kong-plugin-amqp.

The commands bellow shows you how to prepare you environment to develope this plugin (you already need to have Vagrant).

```sh
# clone the kong vagrant repository
$ git clone https://github.com/Kong/kong-vagrant
$ cd kong-vagrant

# clone the Kong repo (inside the vagrant one)
$ git clone https://github.com/Kong/kong

# clone the this repo (inside the vagrant one)
$ git clone https://github.com/gsdenys/kong-plugin-amqp.git kong-plugin

# build a box with a folder synced to your local Kong and plugin sources
$ vagrant up

# ssh into the Vagrant machine, and setup the dev environment
$ vagrant ssh
$ cd /kong
$ make dev

# export the kong plugin configuration (tell Kong to load it)
$ export KONG_PLUGINS=bundled,kong-plugin-amqp

# We need to ensure that migrations are up to date
$ cd /kong
$ bin/kong migrations bootstrap

# Start up kong
$ bin/kong start
``` 