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

    -h, --help                                 output usage information
    -V, --version                              output the version number
    -i, --instances [instance number]          Number of handler instances. Default: Number of CPU cores
    -p, --port [port]                          Handler port. Default: 5000
    -w, --queue-port [interface port]          Queue interface port. Set to false to disable interface. Default: 4900
    --original-storage-type <type>             Select original storage type.
    --original-storage-source-path <source>    Set original storage source path
    --original-storage-container <container>   Set original storage container name
    --original-storage-username <username>     Set original storage username
    --original-storage-password <password>     Set original storage password
    --original-storage-url <url>               Set original storage url
    --thumbnail-storage-type [type]            Select thumbnail storage type.
    --thumbnail-storage-source-path [source]   Set thumbnail storage source path
    --thumbnail-storage-container <container>  Set thumbnail storage container name
    --thumbnail-storage-username <username>    Set thumbnail storage username
    --thumbnail-storage-password <password>    Set thumbnail storage password
    --thumbnail-storage-url <url>              Set thumbnail storage url
```

### Starting the worker

```
$ ./bin/odt-worker --help

  Usage: odt-worker [options]

  Options:

    -h, --help                                 output usage information
    -V, --version                              output the version number
    -i, --instances [instance number]          Number of worker instances. Default: Number of CPU cores
    --original-storage-type <type>             Select original storage type.
    --original-storage-source-path <source>    Set original storage source path
    --original-storage-container <container>   Set original storage container name
    --original-storage-username <username>     Set original storage username
    --original-storage-password <password>     Set original storage password
    --original-storage-url <url>               Set original storage url
    --thumbnail-storage-type [type]            Select thumbnail storage type. If not passed, will use the same as original storage.
    --thumbnail-storage-source-path [source]   Set thumbnail storage source path
    --thumbnail-storage-container <container>  Set thumbnail storage container name
    --thumbnail-storage-username <username>    Set thumbnail storage username
    --thumbnail-storage-password <password>    Set thumbnail storage password
    --thumbnail-storage-url <url>              Set thumbnail storage url
```

## Handler endpoints

When started, you can access images on the handler by requesting this url:

`http://localhost:5000/v1/400/300/image.jpg`

### Adding filters

You can define filters that should be added on top of the image. These filters
can be things like

* watermarks

The url for this type of requests is:

`http://localhost:5000/v1/400/300/filters:watermark(logo.png, 0, center)/image.jpg`

## Available filters

### Watermark
Valid parameters are:

* `watermark(*filename*, *x*, *y*, *opacity*)`
* `watermark(*filename*, *opacity*, tile)` tile the watermark over the image
* `watermark(*filename*, *opacity*, cover)` scale the watermark to cover the whole image
