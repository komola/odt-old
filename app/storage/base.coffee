crypto = require "crypto"

class BaseStorage
  calculateHash: (filename, options) =>
    signature = [filename]

    for key, val of options
      signature.push "#{key}:#{val}"

    signature = signature.join "_"

    return crypto.createHash("md5").update(signature).digest "hex"

module.exports = BaseStorage
