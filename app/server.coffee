_ = require "lodash"
winston = require "winston"
numCPUs = require("os").cpus().length
Handler = require "./handler"

module.exports = (options = {}) =>
  # init logging
  logger = new winston.Logger
    transports: [
      new winston.transports.Console
        handleExceptions: true
        prettyPrint: false
        colorize: true
        timestamp: true
        level: "error"
    ]

  logger.setLevels winston.config.syslog.levels

  # initialize options
  options = _.defaults options,
    instances: numCPUs
    handlerPort: 5000
    queuePort: 4900

  if options.instances < 1
    options.instances = 1

  # Warn the user if he wants to spin up more instances than CPU cores available
  if options.instances > numCPUs
    logger.notice "You want to start #{options.instances} instances, but only have #{numCPUs} CPU cores available. Consider decreasing the number of instances you want to run."

  handler = new Handler
    options: options
    logger: logger

  handler.start()
