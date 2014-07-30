BaseStorage = require "./base"
SwiftClient = require "../lib/swift"

class SwiftStorage extends BaseStorage
  constructor: (options) ->
    @options = options

    console.log options

    @client = new SwiftClient
      user: options.username
      pass: options.password
      host: options.url
      container: options.container

    @client.init()

  exists: (filename, callback) =>
    @client.exists filename, callback

  createReadStream: (filename, callback) =>
    @client.read filename, callback

  createWriteStream: (filename, callback) =>
    @client.write filename, callback

module.exports = SwiftStorage
