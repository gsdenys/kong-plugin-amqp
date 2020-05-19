#!/sh

CONST_LOCATE="/usr/local/share/lua/5.1/kong/constants.lua"

sed -i 's/http = "http"/amqp = "http",\n  http = "http"/g' $CONST_LOCATE