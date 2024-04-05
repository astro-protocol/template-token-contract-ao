local runtime = require "src.runtime"

-- These libs should exist in ao

local mod = {}

-- Define json

local cjsonstatus, cjson = pcall(require, "cjson")

if cjsonstatus then
  mod.json = cjson
else
  local jsonstatus, json = pcall(require, "json")
  if not jsonstatus then
    runtime.throw("Library 'json' does not exist")
  else
    mod.json = json
  end
end

local rbintstatus, rbint = pcall(require, ".bint")

if rbintstatus then
  mod.bint = rbint(512)
else
  runtime.throw("Library '.bint' does not exist")
end

return mod