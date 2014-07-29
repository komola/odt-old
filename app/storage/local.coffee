BaseStorage = require "./base"
fs = require "fs"

class LocalStorage extends BaseStorage
  constructor: (options) ->
    unless options.sourcePath
      throw new Error "No source path given!"

    @options = options

  exists: (filename, callback) =>
    fs.exists "#{@options.sourcePath}/#{filename}", (exists) =>
      return callback null, exists

  createReadStream: (filename, callback) =>
    stream = fs.createReadStream "#{@options.sourcePath}/#{filename}"
    return callback null, stream

  createWriteStream: (filename, callback) =>
    stream = fs.createWriteStream "#{@options.sourcePath}/#{filename}"
    return callback null, stream

module.exports = LocalStorage
