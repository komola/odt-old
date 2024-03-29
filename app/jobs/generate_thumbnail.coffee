async = require "async"
_ = require "lodash"
fs = require "fs"
temp = require "temp"
{exec} = require "child_process"

module.exports = (job, done) =>
  tmpFiles = {}

  job.logger.debug "[##{job.id}] generate thumbnail", job.data
  job.metrics.increment "thumbnail.generate.attempted"

  job.logger.profile "[##{job.id}] generate thumbnail"
  start = +new Date()

  data = job.data.payload

  async.series [
    # download the file to a tmp file
    (cb) =>
      writeStreams = {}
      files = [data.path]

      if data.filters
        for filter in data.filters when filter.type is "watermark"
          files.push filter.file

      downloadStart = +new Date()
      job.logger.profile "[##{job.id}] download #{files.length} images"

      download = (filename, done) =>

        job.originalStorage.createReadStream filename, (err, readStream) =>
          if err
            job.metrics.increment "thumbnail.generate.failure.file_download_failed"
            return done err

          writeStream = temp.createWriteStream("odt")

          tmpFiles[filename] = writeStream.path

          readStream.pipe writeStream

          returned = false

          readStream.on "error", (err) =>
            job.logger.error err
            return if returned
            returned = true
            return done err

          writeStream.on "close", (err) =>
            job.logger.profile "[##{job.id}] read file #{filename}"
            return if returned
            returned = true
            return done err

      async.each files, download, (err) =>
        job.logger.profile "[##{job.id}] download #{files.length} images"
        job.metrics.timing "thumbnail.generate.file_download", +new Date() - downloadStart
        return cb err

    # generate the thumbnail
    (cb) =>
      tmpFiles.thumbnail = temp.path(affix: "odt")

      job.logger.profile "[##{job.id}] execute gm"

      gmStart = +new Date()

      commands = []

      execCommand = [
        "gm convert"
        # "-auto-orient"# comment out for now.
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
          command = [
            "gm composite"
            "-interlace Line"
            "-quality 100%"
          ]

          if filter.behavior is "tile"
            command.push [
              "-resize 100%"
              "-dissolve #{filter.opacity}"
              "-gravity center"
              "-tile"
            ].join " "

          else if filter.behavior is "center"
            command.push [
              "-compose Over"
              "-dissolve #{filter.opacity}"
              "-gravity center"
            ].join " "

          else if filter.behavior is "cover"
            command.push [
              "-compose Over"
              "-dissolve #{filter.opacity}"
              "-resize #{data.width}x#{data.height}"
              "-gravity center"
            ].join " "

          else if filter.behavior in ["north_east", "south_east", "south_west", "north_west"]
            position = switch filter.behavior
              when "north_east" then "NorthEast"
              when "south_east" then "SouthEast"
              when "south_west" then "SouthWest"
              when "north_west" then "NorthWest"

            command.push [
              "-compose Over"
              "-gravity #{position}"
              "-dissolve #{filter.opacity}"
              "-resize #{Math.floor(data.width/4)}x#{Math.floor(data.height/4)}"
            ].join " "

          else if filter.behavior in ["top", "bottom"]
            position = switch filter.behavior
              when "top" then "NorthWest"
              when "bottom" then "SouthWest"

            command.push [
              "-compose Over"
              "-gravity #{position}"
              "-dissolve #{filter.opacity}"
              "-resize #{Math.floor(data.width)}"
            ].join " "

          else
            command.push [
              "-compose Over"
              "-gravity SouthEast"
              "-geometry +#{filter.x}+#{filter.y}"
              "-dissolve #{filter.opacity}"
              "-resize #{Math.floor(data.width/4)}x#{Math.floor(data.height/4)}"
            ].join " "

          command.push [
            "#{tmpFiles[filter.file]}"
            "#{tmpFiles.thumbnail} #{tmpFiles.thumbnail}"
          ].join " "

          commands.push command.join " "

      job.logger.debug "[##{job.id}] executing", commands

      async.eachSeries commands, exec, (error) =>
      # exec execCommand, (error, stdout, stderr) =>
        if error
          job.metrics.increment "thumbnail.generate.failure.gm_failed"
          job.logger.error error.message

        job.logger.profile "[##{job.id}] execute gm"
        job.metrics.timing "thumbnail.generate.execute_gm", +new Date() - gmStart
        return cb error

    # store the thumbnail file in the storage
    (cb) =>
      storageStart = +new Date()
      job.logger.profile "[##{job.id}] store thumbnail"
      job.thumbnailStorage.createWriteStream data.hash, (err, writeStream) =>
        readStream = fs.createReadStream tmpFiles.thumbnail
        readStream.pipe writeStream

        writeStream.on "close", (err) =>
          if err
            job.metrics.increment "thumbnail.generate.failure.storing_failed"
            job.logger.error err.message, err

          job.logger.profile "[##{job.id}] store thumbnail"
          job.metrics.timing "thumbnail.generate.store_thumbnail", +new Date() - storageStart

          return cb err

  ], (err) =>
    if err
      job.logger.error err.message, err

    unless err
      job.metrics.increment "thumbnail.generate.succeeded"

    if err?.timeout
      job.metrics.increment "thumbnail.generate.failure.timeout"

    job.logger.profile "[##{job.id}] generate thumbnail"
    job.metrics.timing "thumbnail.generate.total", +new Date() - start

    files = _.values tmpFiles
    async.eachSeries files, fs.unlink, (err2) =>
      return done err or err2
