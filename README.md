# Kong plugin AMQP

This repository contains AMQP Kong plugin that's permits post message directly on AMQP exchange.

__IMPORTANT:__ _As this one use the template designed to work with the `kong-vagrant` [development environment](https://github.com/Mashape/kong-vagrant). Please check out that repo's `README` for usage instructions._

## Install

This section shows how to install this one in a built in kong docker image.

1) Create a Dockerfile with the content below.
    ```docker
    FROM docker:2.0
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
$ https://github.com/gsdenys/kong-plugin-amqp.git

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