var program = require("commander");

program
  .version("0.0.1")
  .option('-i, --instances [instance number]', 'Number of handler instances. Default: Number of CPU cores', parseInt)
  .option('-p, --port [port]', 'Handler port. Default: 5000', parseInt)
  .option('-w, --queue-port [interface port]', 'Queue interface port. Set to false to disable interface. Default: 4900')
  .parse(process.argv)
  ;

require("coffee-script/register");
require("./app/server")({
  instances: program.instances
});
