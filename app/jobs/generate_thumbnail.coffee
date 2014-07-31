async = require "async"
_ = require "lodash"
fs = require "fs"
temp = require "temp"
{exec} = require "child_process"

module.exports = (job, done) =>
  tmpFiles = {}

  job.logger.profile "[##{job.id}] generate thumbnail"
  job.logger.debug "[##{job.id}] generate thumbnail", job.data

  data = job.data.payload

  async.series [
    # download the file to a tmp file
    (cb) =>
      writeStreams = {}
      files = [data.path]

      if data.filters
        for filter in data.filters when filter.type is "watermark"
          files.push filter.file

      job.logger.profile "[##{job.id}] download #{files.length} images"

      download = (filename, done) =>

        job.originalStorage.createReadStream filename, (err, readStream) =>
          return done err if err

          writeStream = temp.createWriteStream("odt")

          tmpFiles[filename] = writeStream.path

          readStream.pipe writeStream

          writeStream.on "close", (err) =>
            job.logger.profile "[##{job.id}] read file #{filename}"
            return done err

      async.each files, download, (err) =>
        job.logger.profile "[##{job.id}] download #{files.length} images"
        return cb err

    # generate the thumbnail
    (cb) =>
      tmpFiles.thumbnail = temp.path(affix: "odt")

      job.logger.profile "[##{job.id}] execute gm"

      commands = []

      execCommand = [
        "gm convert"
        "-auto-orient"
        "-size #{data.width}x#{data.height}"
        "-quality 100"
        "-resize #{data.width}x#{data.height}"
        "+profile '*'"
        "-scale #{data.width}x#{data.height}"
        "-interlace Line"
        "#{tmpFiles[data.path]} #{tmpFiles.thumbnail}"
      ]

      commands.push execCommand.join " "

      # add watermark info
      if data.filters
        for filter in data.filters when filter.type is "watermark"
          commands.push [
            "gm composite"
            "-interlace Line"
            "-quality 100%"
            "-resize #{data.width}x#{data.height}"
            "-gravity center"
            "#{tmpFiles[filter.file]}"
            "#{tmpFiles.thumbnail} #{tmpFiles.thumbnail}"
          ].join " "

      job.logger.debug "[##{job.id}] executing", commands

      async.eachSeries commands, exec, (error) =>
      # exec execCommand, (error, stdout, stderr) =>
        if error
          job.logger.error error.message

        job.logger.profile "[##{job.id}] execute gm"
        return cb error

    # store the thumbnail file in the storage
    (cb) =>
      job.logger.profile "[##{job.id}] store thumbnail"
      job.thumbnailStorage.createWriteStream data.hash, (err, writeStream) =>
        readStream = fs.createReadStream tmpFiles.thumbnail
        readStream.pipe writeStream

        writeStream.on "close", (err) =>
          job.logger.profile "[##{job.id}] store thumbnail"
          return cb err

    # cleanup
    (cb) =>
      files = _.values tmpFiles
      async.eachSeries files, fs.unlink, cb

  ], (err) =>
    if err
      job.logger.error err.message, err

    job.logger.profile "[##{job.id}] generate thumbnail"

    return done err
