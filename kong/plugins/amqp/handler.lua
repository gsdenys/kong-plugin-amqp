
-- Grab pluginname from module name
local plugin_name = ({...})[1]:match("^kong%.plugins%.([^%.]+)")

-- load the base plugin object and create a subclass
local plugin = require("kong.plugins.base_plugin"):extend()
local amqp = require "amqp"
local cjson = require("cjson")


---[[ handles more initialization, but AFTER the worker process has been forked/created.
-- It runs in the 'init_worker_by_lua_block'
function plugin:init_worker()
  plugin.super.init_worker(self)
end --]]


---[[ runs in the 'access_by_lua_block'
function plugin:access(conf)
  plugin.super.access(self)

  local ctx = amqp_get_context(conf)
  amqp_connect(ctx)
  amqp_publish(ctx, kong.request.get_raw_body())

  response = get_response("qwer-qwerqwr-qwer-qwerqwer")
  ngx.say(response)

  ngx.ctx.status = ngx.HTTP_CREATED
  ngx.exit(ngx.ctx.status)
end --]]


---[[ runs in the 'header_filter_by_lua_block'
function plugin:header_filter(plugin_conf)
  plugin.super.header_filter(self)

  ngx.header["Content-Type"] = "application/json"
  --ngx.status = ngx.ctx.status
end --]]



function amqp_get_context(conf)
  local ctx = amqp.new({
      role = "publisher", 
      routing_key = conf.routing_key, 
      exchange = conf.exchange, 
      ssl = kong.router.get_service().protocol == "https", 
      user = conf.user, 
      password = conf.password,
      properties = {correlation_id = "message_id"}
    })

  ngx.log(ngx.DEBUG, "AMQP context created successfully")

  return ctx
end

function amqp_connect(ctx)
  ctx:connect(
    kong.router.get_service().host,
    kong.router.get_service().port
  )
  ctx:setup()

  ngx.log(
    ngx.DEBUG, 
    "AMQP connected successfully at: ",
    kong.router.get_service().protocol, "://",
    kong.router.get_service().host, ":",
    kong.router.get_service().port
  )

  return ctx
end

function amqp_publish(ctx, message)
  local ok, err = ctx:publish(message)
  
  if err then
    ngx.log(ngx.ERR, "Internal server errror: ", err)
    ngx.say(cjson.encode({error = "Internal Server Error"}))

    ngx.ctx.status = ngx.HTTP_INTERNAL_SERVER_ERROR
    ngx.exit(ngx.ctx.status)
  end

  ngx.log(ngx.DEBUG, "Raw Body Published successfully")
end

function get_response(id)
  resp = cjson.encode({
    uuid = id, 
    time = ngx.localtime()
  })

  ngx.log(ngx.DEBUG, "AMQP Response body generated with ID: ", id)
  
  return resp
end

-- set the plugin priority, which determines plugin execution order
plugin.PRIORITY = 1000

-- return our plugin object
return plugin
