odt ![Build Status](https://travis-ci.org/komola/odt.svg)
===

On Demand Thumbnail generator

Usage
-----

### Starting the handler

```
$ ./bin/odt --help

  Usage: odt [options]

  Options:

    -h, --help                                output usage information
    -V, --version                             output the version number
    -i, --instances [instance number]         Number of handler instances. Default: Number of CPU cores
    -p, --port [port]                         Handler port. Default: 5000
    -w, --queue-port [interface port]         Queue interface port. Set to false to disable interface. Default: 4900
    --original-storage-type <type>            Select original storage type.
    --original-storage-source-path <source>   Set original storage source path
    --thumbnail-storage-type [type]           Select thumbnail storage type.
    --thumbnail-storage-source-path [source]  Set thumbnail storage source path
```

### Starting the worker

```
$ ./bin/odt-worker --help

  Usage: odt-worker [options]

  Options:

    -h, --help                                output usage information
    -V, --version                             output the version number
    -i, --instances [instance number]         Number of worker instances. Default: Number of CPU cores
    --original-storage-type <type>            Select original storage type.
    --original-storage-source-path <source>   Set original storage source path
    --thumbnail-storage-type [type]           Select thumbnail storage type. If not passed, will use the same as original storage.
    --thumbnail-storage-source-path [source]  Set thumbnail storage source path
```
