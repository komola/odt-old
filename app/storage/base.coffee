crypto = require "crypto"

notImplemented = =>
  throw new Error "Not implemented yet!"

class BaseStorage
  calculateHash: (filename, options) =>
    signature = [filename]

    for key, val of options
      signature.push "#{key}:#{val}"

    signature = signature.join "_"

    return crypto.createHash("md5").update(signature).digest "hex"

  exists: (filename, callback) => notImplemented()
  createReadStream: (filename, callback) => notImplemented()
  createWriteStream: (filename, callback) => notImplemented()

module.exports = BaseStorage
