var program = require("commander");

program
  .version("0.0.1")
  .option('-i, --instances [instance number]', 'Number of handler instances. Default: Number of CPU cores', parseInt)
  .option('-p, --port [port]', 'Handler port. Default: 5000', parseInt)
  .option('-w, --queue-port [interface port]', 'Queue interface port. Set to false to disable interface. Default: 4900')
  .option('--original-storage-type <type>', 'Select original storage type.')
  .option('--original-storage-source-path <source>', 'Set original storage source path')
  .option('--thumbnail-storage-type [type]', 'Select thumbnail storage type.')
  .option('--thumbnail-storage-source-path [source]', 'Set thumbnail storage source path')
  .parse(process.argv)
  ;

var options = {
  instances: program.instances,
  handlerPort: program.port,
  queuePort: program.queuePort,
  storage: {}
};

if (program.thumbnailStorageType === 'local') {
  options.storage.thumbnail = {
    type: 'local',
    sourcePath: program.thumbnailStorageSourcePath
  };
}

if (program.originalStorageType === 'local') {
  options.storage.original = {
    type: 'local',
    sourcePath: program.originalStorageSourcePath
  };
}

require("coffee-script/register");
require("./app/server")(options);
