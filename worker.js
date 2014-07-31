var program = require("commander");
var version = require("./package.json").version;
var _ = require("lodash");
var path = require("path");

program
  .version(version)
  .option('-i, --instances [instance number]', 'Number of worker instances. Default: Number of CPU cores', parseInt)
  .option('-c, --config <config file>', 'Specify a config file to load')

  .option('--original-storage-type <type>', 'Select original storage type.')
  .option('--original-storage-source-path <source>', 'Set original storage source path')
  .option('--original-storage-container <container>', 'Set original storage container name')
  .option('--original-storage-username <username>', 'Set original storage username')
  .option('--original-storage-password <password>', 'Set original storage password')
  .option('--original-storage-url <url>', 'Set original storage url')

  .option('--thumbnail-storage-type [type]', 'Select thumbnail storage type. If not passed, will use the same as original storage.')
  .option('--thumbnail-storage-source-path [source]', 'Set thumbnail storage source path')

  .option('--thumbnail-storage-container <container>', 'Set thumbnail storage container name')
  .option('--thumbnail-storage-username <username>', 'Set thumbnail storage username')
  .option('--thumbnail-storage-password <password>', 'Set thumbnail storage password')
  .option('--thumbnail-storage-url <url>', 'Set thumbnail storage url')
  .parse(process.argv)
  ;

if (program.config) {
  program.config = path.resolve(program.config);
  config = require(program.config);

  _.extend(program, config);
}

var options = {
  instances: program.instances,
  handlerPort: program.port,
  queuePort: program.queuePort,
  storage: {}
};

if (program.originalStorageType === 'local') {
  options.storage.original = {
    type: 'local',
    sourcePath: program.originalStorageSourcePath
  };

  options.storage.thumbnail = {
    type: 'local',
    sourcePath: program.originalStorageSourcePath
  };
}

if (program.originalStorageType === 'swift') {
  options.storage.original = {
    type: 'swift',
    container: program.originalStorageContainer,
    username: program.originalStorageUsername,
    password: program.originalStoragePassword,
    url: program.originalStorageUrl
  };

  options.storage.thumbnail = {
    type: 'swift',
    container: program.originalStorageContainer,
    username: program.originalStorageUsername,
    password: program.originalStoragePassword,
    url: program.originalStorageUrl
  };
}



if (program.thumbnailStorageType === 'local') {
  options.storage.thumbnail = {
    type: 'local',
    sourcePath: program.thumbnailStorageSourcePath
  };
}

if (program.thumbnailStorageType === 'swift') {
  options.storage.thumbnail = {
    type: 'swift',
    container: program.thumbnailStorageContainer,
    username: program.thumbnailStorageUsername,
    password: program.thumbnailStoragePassword,
    url: program.thumbnailStorageUrl
  };
}

options.isWorker = true;

require("coffee-script/register");
require("./app/server")(options);
