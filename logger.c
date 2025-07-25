/*
 * logger.c - Implementation of the LOGGER library
 * Handles logging with different levels, colored output, and application name
 */

 #include <stdarg.h>
 #include <stdio.h>
 #include <stdlib.h>
 #include <string.h>
 #include <time.h>
 #include <sys/time.h>
 #include "logger.h"
 
 /* Default log file path */
 #define DEFAULT_LOG_FILE "/var/log/app.log"
 
 static FILE *log_fp = NULL;
 static char *current_log_file = NULL;
 static char *app_name = NULL;
 
 /* Convert log level to string with color */
 static const char *level_to_string(LogLevel level) {
     switch (level) {
         case LOG_DEBUG:   return COLOR_BLUE "DEBUG" COLOR_RESET;
         case LOG_INFO:    return COLOR_GREEN "INFO" COLOR_RESET;
         case LOG_WARNING: return COLOR_YELLOW "WARNING" COLOR_RESET;
         case LOG_ERROR:   return COLOR_RED "ERROR" COLOR_RESET;
         default:          return "UNKNOWN";
     }
 }
 
 /* Get application name */
 const char *get_app_name(void) {
     return app_name ? app_name : "unknown";
 }
 
 /* Initialize logger with application name and default log file */
 void logger_init(const char *app_name_str, const char *log_file) { 
     /* Free existing app_name if it exists */
     if (app_name) {
         free(app_name);
         app_name = NULL;
     }
 
     /* Set application name */
     app_name = app_name_str ? strdup(app_name_str) : strdup("unknown");
     if (!app_name) {
         fprintf(stderr, "logger_init: Failed to allocate app_name\n");
         app_name = "unknown"; /* Fallback to static string */
     }
 
     /* Set log file */
     logger_set_logfile(log_file ? log_file : DEFAULT_LOG_FILE);
 }
 
 /* Set a custom log file for the logger */
 void logger_set_logfile(const char *log_file) { 
     /* Close existing log file if open */
     if (log_fp && log_fp != stdout) {
         fclose(log_fp);
         log_fp = NULL;
     }
 
     /* Open new log file */
     log_fp = fopen(log_file, "a");
     if (!log_fp) {
         log_fp = stdout; /* Fallback to stdout */
         fprintf(stderr, "Failed to open log file %s, using stdout\n", log_file);
     }
 
     /* Update current_log_file */
     if (current_log_file) {
         free(current_log_file);
         current_log_file = NULL;
     }
     current_log_file = strdup(log_file);
     if (!current_log_file) {
         fprintf(stderr, "logger_set_logfile: Failed to allocate current_log_file\n");
         current_log_file = "unknown"; /* Fallback */
     }
 }
 
 /* Log a message with specified level, application name, function, and format */
 void logger_log(LogLevel level, const char *app_name, const char *func,
                 const char *fmt, ...) {
     if (!log_fp) {
         log_fp = stdout; /* Fallback to stdout */
         fprintf(stderr, "logger_log: log_fp was NULL, using stdout\n");
     }
 
     /* Get current time */
     char time_str[32];
     if (level == LOG_DEBUG) {
         /* Microsecond precision for DEBUG */
         struct timeval tv;
         gettimeofday(&tv, NULL);
         struct tm *tm = localtime(&tv.tv_sec);
         strftime(time_str, sizeof(time_str), "%Y-%m-%d %H:%M:%S", tm);
         snprintf(time_str + strlen(time_str), sizeof(time_str) - strlen(time_str), 
                  ".%06ld", tv.tv_usec);
     } else {
         /* Standard precision for other levels */
         time_t now = time(NULL);
         struct tm *tm = localtime(&now);
         strftime(time_str, sizeof(time_str), "%Y-%m-%d %H:%M:%S", tm);
     }
 
     /* Write log header with aligned fields */
     if (level == LOG_DEBUG) {
         fprintf(log_fp, "[%s]\t%s\t<%s>%s:\t", time_str, level_to_string(level), 
                 app_name, func);
     } else {
         fprintf(log_fp, "[%s]\t%s\t<%s>\t", time_str, level_to_string(level), app_name);
     }
 
     /* Write log message */
     va_list args;
     va_start(args, fmt);
     vfprintf(log_fp, fmt, args);
     va_end(args);
 
     fprintf(log_fp, "\n");
     fflush(log_fp);
 }
 
 /* Cleanup logger resources */
 void logger_cleanup(void) { 
     if (log_fp && log_fp != stdout) {
         fclose(log_fp);
         log_fp = NULL;
     }
     if (current_log_file) {
         free(current_log_file);
         current_log_file = NULL;
     }
     if (app_name && app_name != "unknown") {
         free(app_name);
         app_name = NULL;
     }
 }