express = require "express"
router = express.Router()
async = require "async"
_ = require "lodash"
parser = require "../../lib/parametersParser"

handleRequest = (req, res, next) =>
  path = req.params.path
  additionalParameters = _.omit req.params, "path"

  # parse the URL parameters for filters etc. and add them to the parameters
  if req.params.parameters
    parameters = parser.parse(req.params.parameters)
    _.extend req.params, parameters

  hash = null

  req.logger.debug "requesting image", req.params
  req.metrics.increment "thumbnail.request.attempted"

  req.logger.profile "delivering thumbnail"
  start = +new Date()

  async.waterfall [
    (cb) =>
      req.originalStorage.exists path, (err, exists) =>
        if err.timeout
          req.metrics.increment "thumbnail.request.failure.timeout"

        req.logger.error err.message, err if err

        return cb() if exists

        req.metrics.increment "thumbnail.request.failure.not_found"
        req.logger.profile "delivering thumbnail"

        req.logger.info "could not find image in original storage"

        res.status(404).end()

        return cb "not_existing"

    (cb) =>
      hash = req.thumbnailStorage.calculateHash path, additionalParameters

      req.logger.debug "calculated hash", hash: hash

      return cb null, hash

    (hash, cb) =>
      req.thumbnailStorage.exists hash, (err, exists) =>
        if err.timeout
          req.metrics.increment "thumbnail.request.failure.timeout"

        return cb err if err

        req.logger.debug "check if thumbnail exists", exists: exists

        # create the thumbnail in case the hash does not exist
        return cb() unless exists

        req.metrics.increment "thumbnail.request.cached"
        req.logger.debug "thumbnail exists. Stream to client"

        # create a read stream and serve the file
        req.thumbnailStorage.createReadStream hash, (err, stream) =>
          return cb err if err

          req.metrics.timing "thumbnail.delivery_time", +new Date() - start
          req.logger.profile "delivering thumbnail"

          res.set "Content-Type", "image/jpeg"

          stream.pipe res
          stream.on "error", cb

          stream.on "close", =>
            req.logger.info "successfully served image to client"
            return cb "served"

    (cb) =>
      data =
        payload: req.params
        title: "Generate Thumbnail #{path} (#{req.params.width}x#{req.params.height})"

      data.payload.hash = hash

      req.metrics.increment "thumbnail.request.new"
      job = req.queue.create "thumbnail:generate", data

      job.attempts(3)

      job.save()

      job.on "failed", cb
      job.on "complete", (result) =>
        req.logger.debug "job fired complete event", result
        return cb()

    # try to serve the just created thumbnail
    (cb) =>
      req.thumbnailStorage.exists hash, (err, exists) =>
        if err.timeout
          req.metrics.increment "thumbnail.request.failure.timeout"

        return cb err if err

        req.logger.debug "thumbnailStorage contains file", exists: exists

        # thumbnail still does not exist!
        return cb "creation_failed" unless exists

        # create a read stream and serve the file
        req.thumbnailStorage.createReadStream hash, (err, stream) =>
          return cb err if err

          res.set "Content-Type", "image/jpeg"

          req.logger.profile "delivering thumbnail"
          stream.pipe res
          stream.on "error", cb

          stream.on "close", =>
            return cb "served"

  ], (err) =>
    if err in ["not_existing", "served"]
      err = null

    if err
      res.status(502).end()
      req.logger.error err

router.get "/:width/:height/:parameters/:path", handleRequest
router.get "/:width/:height/:path", handleRequest

module.exports = router
