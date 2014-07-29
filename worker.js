var program = require("commander");

program
  .version("0.0.1")
  .option('-i, --instances [instance number]', 'Number of worker instances. Default: Number of CPU cores', parseInt)
  .option('--original-storage-type <type>', 'Select original storage type.')
  .option('--original-storage-source-path <source>', 'Set original storage source path')
  .option('--thumbnail-storage-type [type]', 'Select thumbnail storage type. If not passed, will use the same as original storage.')
  .option('--thumbnail-storage-source-path [source]', 'Set thumbnail storage source path')
  .parse(process.argv)
  ;

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


if (program.thumbnailStorageType === 'local') {
  options.storage.thumbnail = {
    type: 'local',
    sourcePath: program.thumbnailStorageSourcePath
  };
}

options.isWorker = true;

require("coffee-script/register");
require("./app/server")(options);
