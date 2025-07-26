# Logger Library

## Overview

The Logger library is a lightweight logging solution designed for embedded Linux systems. It provides flexible logging capabilities with multiple log levels (DEBUG, INFO, WARNING, ERROR), colored console output, and support for custom log files. The library is written in C and includes optional Node.js addon support for integration with Node.js applications.

## Features

- **Multiple Log Levels**: Supports DEBUG, INFO, WARNING, and ERROR levels with color-coded console output.
- **Customizable Log File**: Allows specifying a custom log file path, with fallback to stdout if the file cannot be opened.
- **Application Name Support**: Logs include an application name for context.
- **Timestamped Logs**: Includes precise timestamps (microsecond precision for DEBUG level).
- **Node.js Addon**: Optional Node.js integration for use in JavaScript applications.
- **Buildroot Integration**: Easily integrated into embedded systems using Buildroot.

## Installation

The Logger library is designed to be built and installed using Buildroot. Follow these steps to include it in your Buildroot project:

1. **Add to Buildroot Configuration**:
   - Copy the provided `logger` package files (e.g., `logger.mk`, `logger.c`, `logger.h`, `Config.in`, etc.) to your Buildroot `package/logger/` directory or source in your application Config.in file like: `source "$BR2_EXTERNAL_APPLICATION_PATH/../../tools/logger/Config.in`.
   - Enable the logger package in your Buildroot configuration by running:
     ```bash
     make menuconfig
     ```
     Navigate to `Target packages -> Libraries -> logger` and enable `BR2_PACKAGE_LOGGER`. Optionally, enable `BR2_PACKAGE_LOGGER_NODEJS` for Node.js support.

2. **Build the Project**:
   - Run the following command to build the logger library and integrate it into your target filesystem:
     ```bash
     make
     ```

3. **Verify Installation**:
   - The library (`liblogger.so`) will be installed in `/usr/lib/` and `/usr/lib64/` on the target system.
   - The header file (`logger.h`) will be installed in `/usr/include/logger/`.
   - If Node.js support is enabled, the Node.js addon (`logger.node`) will be installed in `/usr/lib/node_modules/logger/`.

## Integration into an Application

### Using the Logger Library in a C Application

To use the Logger library in a C application, include the `logger.h` header and link against `liblogger.so`. Below is an example of how to integrate and use the library:

```c
#include <logger/logger.h>

int main() {
    // Initialize the logger with an application name and log file
    logger_init("MyApp", "/var/log/myapp.log");
    // or use the default log file with: logger_init("MyApp", NULL);

    // Log messages at different levels
    logger(LOG_INFO, "Application started");
    logger(LOG_DEBUG, "Debugging value: %d", 42);
    logger(LOG_WARNING, "Warning: something might be wrong");
    logger(LOG_ERROR, "Error occurred: %s", "file not found");

    // Cleanup logger resources
    logger_cleanup();

    return 0;
}
```

**Compilation**:
Compile your application with the following command, assuming the library and headers are installed in the standard paths:
```bash
gcc -o myapp myapp.c -I/usr/include -L/usr/lib -llogger
```

**Key Functions**:
- `logger_init(const char *app_name, const char *log_file)`: Initializes the logger with an application name and log file.
- `logger_set_logfile(const char *log_file)`: Changes the log file path.
- `logger(level, format, ...)`: Macro to log messages with the specified level and format.
- `logger_cleanup()`: Frees resources used by the logger.

### Using the Logger Library in a Node.js Application

If the Node.js addon support is enabled (`BR2_PACKAGE_LOGGER_NODEJS`), you can use the logger in a Node.js application. Below is an example:

```javascript
const logger = require('/usr/lib/node_modules/logger/logger.node');

// Initialize the logger
logger.init('MyNodeApp', '/var/log/mynodeapp.log');

// Log messages
logger.log(logger.LogLevel.INFO, 'Application started');
logger.log(logger.LogLevel.DEBUG, 'Debugging value: %d', 42);
logger.log(logger.LogLevel.WARNING, 'Warning: something might be wrong');
logger.log(logger.LogLevel.ERROR, 'Error occurred: %s', 'file not found');

// Cleanup
logger.cleanup();
```

**Notes**:
- The Node.js addon is located at `/usr/lib/node_modules/logger/logger.node` on the target system.
- The `LogLevel` enum is exposed as `logger.LogLevel` with values `DEBUG`, `INFO`, `WARNING`, and `ERROR`.
- Ensure Node.js is installed and configured on your target system.

## Log Output Format

Logs are formatted as follows:
- For DEBUG level: `[timestamp.us] DEBUG <app_name>function_name: message`
- For other levels: `[timestamp] LEVEL <app_name> message`

Example output:
```
[2025-07-26 17:21:30.123456] DEBUG <MyApp>main: Debugging value: 42
[2025-07-26 17:21:30] INFO <MyApp> Application started
[2025-07-26 17:21:30] WARNING <MyApp> Warning: something might be wrong
[2025-07-26 17:21:30] ERROR <MyApp> Error occurred: file not found
```

## License

This project is licensed under the MIT License. See the LICENSE file for details.