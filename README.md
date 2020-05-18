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

    USER kong
    ```

3) Execute the command below to generate the dist.

    ```sh
    $ docker build --tag kong-plugin-amqp .
    ```
4) Now, run the container using the commands below.

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