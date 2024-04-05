local aolibs = require "src.aolibs"

local json = aolibs.json

local mod = {}

mod.json = function(json_object)
  print(json.encode(json_object))
end

return mod