return {
  no_consumer = false, -- this plugin is available on APIs as well as on Consumers,
  fields = {
    routing_key = { required = true, type = "string" },
    exchange = { default = "", type = "string" },
    user = { default = "guest", type = "string" },
    password = { default = "guest", type = "string" }
  },
  self_check = function(schema, plugin_t, dao, is_updating)
    -- perform any custom verification
    return true
  end
}
