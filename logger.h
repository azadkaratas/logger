/*
 * logger.h - Header file for the LOGGER library
 * Provides logging functionality with multiple levels, colored output, and configurable application name
 */

 #ifndef LOGGER_H
 #define LOGGER_H
 
 #include <stdio.h>
 
 /* Log levels */
 typedef enum {
     LOG_DEBUG,
     LOG_INFO,
     LOG_WARNING,
     LOG_ERROR
 } LogLevel;
 
 /* ANSI color codes */
 #define COLOR_RED    "\033[31m"
 #define COLOR_YELLOW "\033[33m"
 #define COLOR_GREEN  "\033[32m"
 #define COLOR_BLUE   "\033[34m"
 #define COLOR_RESET  "\033[0m"
 
 /* Initialize logger with application name and default log file */
 void logger_init(const char *app_name, const char *log_file);
 
 /* Set a custom log file for the logger */
 void logger_set_logfile(const char *log_file);
 
 /* Log a message with specified level, application name, function, and format */
 #define logger(level, fmt, ...) \
     logger_log(level, get_app_name(), __func__, fmt, ##__VA_ARGS__)
 
 /* Internal log function (not to be called directly) */
 void logger_log(LogLevel level, const char *app_name, const char *func,
                 const char *fmt, ...);
 
 /* Cleanup logger resources */
 void logger_cleanup(void);
 
 /* Get application name (internal use) */
 const char *get_app_name(void);
 
 #endif