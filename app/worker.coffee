_ = require "lodash"
cluster = require "cluster"
kue = require "kue"

ODT = require "./odt"

class Worker extends ODT
  start: (callback) =>
    super()
    @setupWorker()

  setupWorker: =>
    if cluster.isMaster and process.env.NODE_ENV isnt "test"
      for port in [1..@options.instances]
        cluster.fork()

      cluster.on "exit", (worker) =>
        @logger.error "Worker #{worker.id} died"
        cluster.fork()

    else
      @queue.process "thumbnail:generate", (job, done) =>
        job.options = @options
        job.logger = @logger
        job.originalStorage = @originalStorage
        job.thumbnailStorage = @thumbnailStorage
        job.queue = @queue
        job.metrics = @metrics

        require("./jobs/generate_thumbnail")(job, done)

    process.once "SIGTERM", (sig) =>
      @queue.shutdown (err) =>
        @logger.log "Worker shutting down"
        process.exit 0

module.exports = Worker
