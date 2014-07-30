BaseStorage = require "./base"
pkgcloud = require("pkgcloud")

class SwiftStorage extends BaseStorage
  constructor: (options) ->
    @options = options

    @client = pkgcloud.storage.createClient
      provider: "openstack"
      container: options.container
      username: options.username
      password: options.password
      authUrl: options.url + "/auth/v1.0/"

  exists: (filename, callback) =>
    @client.getFile @options.container, filename, (err, file) =>
      console.log err
      console.log file

      return callback err if err

      return callback err, true

  createReadStream: (filename, callback) =>
    options =
      container: @options.container
      remote: filename

    readStream = @client.download options

    return callback null, readStream

  createWriteStream: (filename, callback) =>
    options =
      container: @options.container
      remote: filename

    writeStream = @client.upload options

    return callback null, writeStream
