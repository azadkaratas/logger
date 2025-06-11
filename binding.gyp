{
  "targets": [
    {
      "target_name": "logger",
      "sources": [ "logger_node.c" ],
      "include_dirs": [
        "<(module_root_dir)",
        "<(module_root_dir)/../../host/usr/lib/node_modules/node-addon-api"
      ],
      "libraries": [
        "-L<(module_root_dir)/../../staging/usr/lib64",
        "-llogger"
      ],
      "cflags": [ "-fPIC" ],
      "defines": [ "NAPI_DISABLE_CPP_EXCEPTIONS" ]
    }
  ]
}