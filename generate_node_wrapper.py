import re
import os
import sys

# Get source directory from command-line argument
if len(sys.argv) != 2:
    print("Error: Source directory must be provided as an argument")
    sys.exit(1)
source_dir = sys.argv[1]

# Path to logger.h
header_path = os.path.join(source_dir, 'logger.h')

# Read logger.h
with open(header_path, 'r') as f:
    header_content = f.read()

# Extract function declarations
functions = []
function_regex = r'void\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*\(([^)]*)\)\s*;'
for match in re.finditer(function_regex, header_content):
    func_name = match.group(1)
    params = match.group(2).strip()
    if params == 'void' or not params:
        param_list = []
    else:
        param_list = [p.strip() for p in params.split(',')]
    functions.append((func_name, param_list))

# Generate logger_node.c
output = '''#include <node_api.h>
#include <string.h>
#include <stdarg.h>
#include <stdlib.h>
#include "logger.h"

/* Helper: Convert Node.js string to C string */
static char* get_string(napi_env env, napi_value value) {
    if (!value) return NULL;
    size_t len;
    napi_get_value_string_utf8(env, value, NULL, 0, &len);
    char* str = (char*)malloc(len + 1);
    if (str) {
        napi_get_value_string_utf8(env, value, str, len + 1, &len);
    }
    return str;
}

/* Helper: Convert Node.js int32 to C int */
static int get_int32(napi_env env, napi_value value) {
    int32_t result;
    napi_get_value_int32(env, value, &result);
    return result;
}
'''

# Generate wrapper functions
for func_name, params in functions:
    if func_name == 'logger_log':  # Special case for variadic function
        output += f'''
/* Wrapper for {func_name} */
napi_value Wrapper_{func_name}(napi_env env, napi_callback_info info) {{
    size_t argc = 16; // Allow up to 12 variadic args + 4 fixed
    napi_value argv[16];
    napi_get_cb_info(env, info, &argc, argv, NULL, NULL);

    if (argc < 4) {{
        napi_throw_error(env, NULL, "Insufficient arguments for {func_name}");
        return NULL;
    }}

    LogLevel level = (LogLevel)get_int32(env, argv[0]);
    const char* app_name = get_string(env, argv[1]);
    const char* func = get_string(env, argv[2]);
    const char* fmt = get_string(env, argv[3]);

    // Handle variadic arguments
    if (argc == 4) {{
        {func_name}(level, app_name ? app_name : "unknown", func ? func : "unknown", "%s", fmt ? fmt : "");
    }} else if (argc == 5) {{
        int32_t arg4;
        napi_get_value_int32(env, argv[4], &arg4);
        {func_name}(level, app_name ? app_name : "unknown", func ? func : "unknown", fmt ? fmt : "", arg4);
    }} else {{
        napi_throw_error(env, NULL, "Too many arguments for {func_name}");
        return NULL;
    }}

    if (app_name) free((void*)app_name);
    if (func) free((void*)func);
    if (fmt) free((void*)fmt);

    return NULL;
}}
'''
    elif func_name == 'get_app_name':  # Special case for return value
        output += f'''
/* Wrapper for {func_name} */
napi_value Wrapper_{func_name}(napi_env env, napi_callback_info info) {{
    const char* result = {func_name}();
    napi_value ret;
    napi_create_string_utf8(env, result ? result : "unknown", NAPI_AUTO_LENGTH, &ret);
    return ret;
}}
'''
    else:  # Standard functions
        param_names = []
        for i, p in enumerate(params):
            name = p.split()[-1].strip('*')
            if not name or name == 'void':
                name = f"param{i}"
            param_names.append(name)
        
        argc_check = '' if not params else f'''
    if (argc < {len(params)}) {{
        napi_throw_error(env, NULL, "Insufficient arguments for {func_name}");
        return NULL;
    }}
'''
        
        output += f'''
/* Wrapper for {func_name} */
napi_value Wrapper_{func_name}(napi_env env, napi_callback_info info) {{
    size_t argc = {len(params)};
    napi_value argv[{len(params)}];
    napi_get_cb_info(env, info, &argc, argv, NULL, NULL);
{argc_check}
    {"\n    ".join(f"const char* {name} = get_string(env, argv[{i}]);" for i, name in enumerate(param_names))}

    {func_name}({", ".join(name for name in param_names)});

    {"\n    ".join(f"if ({name}) free((void*){name});" for name in param_names)}

    return NULL;
}}
'''

# Generate module initialization
output += '''
/* Initialize the addon */
napi_value Init(napi_env env, napi_value exports) {
    napi_value fn;

    /* Export LogLevel enum */
    napi_value log_level;
    napi_create_object(env, &log_level);
    napi_set_named_property(env, exports, "LogLevel", log_level);
    napi_create_int32(env, LOG_DEBUG, &fn);
    napi_set_named_property(env, log_level, "DEBUG", fn);
    napi_create_int32(env, LOG_INFO, &fn);
    napi_set_named_property(env, log_level, "INFO", fn);
    napi_create_int32(env, LOG_WARNING, &fn);
    napi_set_named_property(env, log_level, "WARNING", fn);
    napi_create_int32(env, LOG_ERROR, &fn);
    napi_set_named_property(env, log_level, "ERROR", fn);

    /* Export functions */
'''

for func_name, _ in functions:
    js_name = func_name.replace('logger_', '')
    output += f'    napi_create_function(env, NULL, 0, Wrapper_{func_name}, NULL, &fn);\n'
    output += f'    napi_set_named_property(env, exports, "{js_name}", fn);\n'

output += '''
    return exports;
}

NAPI_MODULE(NODE_GYP_MODULE_NAME, Init)
'''

# Write to logger_node.c in the source directory
output_path = os.path.join(source_dir, 'logger_node.c')
with open(output_path, 'w') as f:
    f.write(output)