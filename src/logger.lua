local Logger = require "arweave.logs.logger"

local mod = Logger.init({
  level = "info",
  logger = {
    log = print
  }
})

return mod