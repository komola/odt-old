async = require "async"
_ = require "lodash"
fs = require "fs"
temp = require "temp"
{exec} = require "child_process"

module.exports = (job, done) =>
  tmpFilePath = null
  tmpThumbnailPath = null

  job.logger.debug "[##{job.id}] generate thumbnail", job.data

  data = job.data.payload

  async.series [
    # download the file to a tmp file
    (cb) =>
      job.originalStorage.createReadStream data.path, (err, readStream) =>
        return cb err if err

        writeStream = temp.createWriteStream("odt")

        tmpFilePath = writeStream.path

        readStream.pipe writeStream

        writeStream.on "close", cb

    # generate the thumbnail
    (cb) =>
      tmpThumbnailPath = temp.path(affix: "odt")

      execCommand = [
        "gm convert"
        "-size #{data.width}x#{data.height}"
        "-quality 100"
        "-resize #{data.width}x#{data.height}"
        "+profile '*'"
        "-scale #{data.width}x#{data.height}"
        "-interlace Line"
        "#{tmpFilePath} #{tmpThumbnailPath}"
      ].join " "

      job.logger.debug "[##{job.id}] executing", execCommand

      job.logger.profile "[##{job.id}] generate thumbnail"

      exec execCommand, (error, stdout, stderr) =>
        if error
          job.logger.error error.message

        job.logger.profile "[##{job.id}] generate thumbnail"
        return cb error

    # store the thumbnail file in the storage
    (cb) =>
      job.thumbnailStorage.createWriteStream data.hash, (err, writeStream) =>
        readStream = fs.createReadStream tmpThumbnailPath
        readStream.pipe writeStream

        writeStream.on "close", cb

    # cleanup
    (cb) =>
      async.eachSeries [tmpFilePath, tmpThumbnailPath], fs.unlink, cb

  ], (err) =>
    if err
      job.logger.error err
      job.log err

    return done err
