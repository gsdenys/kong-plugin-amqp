-- local path="/usr/local/share/lua/5.1/kong/constants.lua"

-- sed -i 's/http = "http"/amqp = "http",\n  http = "http"/g' $CONST_LOCATE

local constants = require("kong.constants")

local function has_amqp_module()
    print(constants.PROTOCOLS)
    for _, v in pairs(constants.PROTOCOLS) do
        print(v)
        if v == "amqp" then
            return true
        end
    end
    return false
end

local function readAll(file)
    local module_file = assert(io.open(file, "rb"))
    
    if module_file ~= nil then
        local content = module_file:read("*all")
        module_file:close()
        return content
    else
        print("[ERROR] Constant file not found!")
    end

    return nil
end

local function include_amqp()
    local module_path = package.searchpath('kong.constants', package.path)
    local content = readAll(module_path)
    local module_file = io.open(module_path, "w")

    if module_file ~= nil then
        content = string.gsub(content, '(http = "http")', 'amqp = "http",\n  %1')
        module_file:write(content)
        module_file:close()
    else
        print("[ERROR] Constant file not found!")
    end
end


if not has_amqp_module() then
    print("[INFO] Installing AMQP module - A Kong New Protocol")
    include_amqp()
else
    print("[INFO] The AMQP module is already installed!")
end
