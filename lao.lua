local lao = {}
local VERSION = "1.0.1 Alpha"
local VERSION_DATE = "2026-06-27"

local config = {
    allowed_extensions = {},
    log_enabled = true  -- YENİ: Log açıqdır (default)
}

local dictionary = {
    ["create a file"] = "+f",
    ["delete this file"] = "-f",
    ["print this"] = "@",
    ["slowprint this"] = "s@",
    ["write this"] = "w>",
    ["into"] = "->",
    ["go to website"] = "g2w",
    ["wait for"] = "w4",
    ["compress this .lao file from .olao"] = "c20",
    ["open"] = "op",
    ["ask"] = "sk",
    ["if"] = "if",
    ["help"] = "hlp",
    ["end"] = ".",
    ["set"] = "=",
    ["get"] = "?",
    ["calc"] = "~",
    ["loop"] = "L",
    ["color"] = "clr",
    ["read file"] = "rf",
    ["read line"] = "rl",
    ["get time"] = "gt",
    ["get date"] = "gd",
    ["get datetime"] = "gdt",
    ["errorlogfile on"] = "elf+",     -- YENİ
    ["errorlogfile off"] = "elf-"     -- YENİ
}

local variables = {}

local colors = {
    reset = "\27[0m",
    red = "\27[31m",
    green = "\27[32m",
    yellow = "\27[33m",
    blue = "\27[34m",
    magenta = "\27[35m",
    cyan = "\27[36m",
    white = "\27[37m",
    bold = "\27[1m",
    underline = "\27[4m"
}

local function log_error(msg)
    if not config.log_enabled then return end  -- YENİ: Log bağlıdırsa, heç nə yazma!
    local log_file = io.open("lao_error.log", "a")
    if log_file then
        log_file:write(os.date("%Y-%m-%d %H:%M:%S") .. " - " .. msg .. "\n")
        log_file:close()
    end
end

local function sanitize_filepath(path)
    return path, nil
end

local function type_write(text)
    for i = 1, #text do
        local char = text:sub(i, i)
        io.write(char)
        io.flush()
        local start = os.clock()
        while os.clock() - start < 0.04 do end
    end
    print()
end

local function parse_line_by_other(line)
    local commands = {}
    local currentCommand = ""
    local inQuotes = false
    local i = 1
    while i <= #line do
        local char = line:sub(i, i)
        if char == '"' then
            inQuotes = not inQuotes
            currentCommand = currentCommand .. char
            i = i + 1
        elseif not inQuotes and line:sub(i, i + 4) == "other" then
            if currentCommand:match("%S") then
                table.insert(commands, currentCommand:match("^%s*(.-)%s*$"))
            end
            currentCommand = ""
            i = i + 5
        else
            currentCommand = currentCommand .. char
            i = i + 1
        end
    end
    if currentCommand ~= "" and currentCommand:match("%S") then
        table.insert(commands, currentCommand:match("^%s*(.-)%s*$"))
    end
    return commands
end

local function get_friendly_suggestion(input)
    local function levenshtein(s1, s2)
        local len1, len2 = #s1, #s2
        local matrix = {}
        for i = 0, len1 do matrix[i] = { [0] = i } end
        for j = 0, len2 do matrix[0][j] = j end
        for i = 1, len1 do
            for j = 1, len2 do
                local cost = (s1:sub(i, i) == s2:sub(j, j)) and 0 or 1
                matrix[i][j] = math.min(
                    matrix[i-1][j] + 1,
                    matrix[i][j-1] + 1,
                    matrix[i-1][j-1] + cost
                )
            end
        end
        return matrix[len1][len2]
    end
    
    local best_match = nil
    local best_distance = 3
    for cmd, _ in pairs(dictionary) do
        local dist = levenshtein(input:lower(), cmd:lower())
        if dist < best_distance then
            best_distance = dist
            best_match = cmd
        end
    end
    
    if best_match then
        return "Did you mean: " .. best_match .. " ?"
    end
    
    local random_messages = {
        "You haven't written anything meaningful here.",
        "I don't understand that. Try 'help' for available commands!",
        "Hmm, that doesn't look like a Lao command. Type 'help'!",
        "Oops! That command doesn't exist. Check 'help' for the list."
    }
    return random_messages[math.random(#random_messages)]
end

function lao.show_help()
    print("\n=======================================================")
    print("                LAO LANGUAGE COMMANDS MAP              ")
    print("                Version: v" .. VERSION)
    print("=======================================================")
    print(" Human Command                        | .olao Symbol   ")
    print("-------------------------------------------------------")
    for word, symbol in pairs(dictionary) do
        local padding = string.rep(" ", 35 - #word)
        print(" " .. word .. padding .. "| " .. symbol)
    end
    print("=======================================================")
    print("Error Log Status: " .. (config.log_enabled and "ON" or "OFF"))  -- YENİ
    print("=======================================================\n")
end

function lao.run_line(raw_line)
    local line = raw_line:gsub("^%s*(.-)%s*$", "%1"):gsub("\r", "")
    
    if line == "" then 
        print("Type something or 'help'!") 
        return true 
    end
    
    if line:match("^#") then 
        return true 
    end

    if line == "help" then
        lao.show_help()
        return true
    end

    if line == "version" then
        print("Lao Language Engine v" .. VERSION)
        print("Release Date: " .. VERSION_DATE)
        print("Runtime: Lua " .. _VERSION)
        return true
    end

    -- YENİ: Error Log AÇ
    if line == "errorlogfile on" then
        config.log_enabled = true
        print("[Lao]: Error log file is now ON")
        return true
    end

    -- YENİ: Error Log BAĞLA
    if line == "errorlogfile off" then
        config.log_enabled = false
        print("[Lao]: Error log file is now OFF")
        return true
    end

    local color_name, color_text = line:match('^color%s+(%w+)%s+"(.-)"$')
    if color_name and color_text then
        if colors[color_name:lower()] then
            print(colors[color_name:lower()] .. color_text .. colors.reset)
        else
            print("[Lao]: Invalid color! Available: red, green, yellow, blue, magenta, cyan, white, bold, underline")
        end
        return true
    end

    local read_path = line:match('^read%s+file%s+"(.-)"$')
    if read_path then
        local safe_path, err = sanitize_filepath(read_path)
        if not safe_path then
            print("[Security]: " .. err)
            return true
        end
        local f = io.open(safe_path, "r")
        if f then
            local content = f:read("*all")
            f:close()
            print(content)
        else
            print("[Lao]: File not found: " .. read_path)
        end
        return true
    end

    local line_num, read_path2 = line:match('^read%s+line%s+(%d+)%s+from%s+"(.-)"$')
    if line_num and read_path2 then
        local safe_path, err = sanitize_filepath(read_path2)
        if not safe_path then
            print("[Security]: " .. err)
            return true
        end
        local f = io.open(safe_path, "r")
        if f then
            local num = tonumber(line_num)
            local current_line = 0
            local found = false
            for raw_line in f:lines() do
                current_line = current_line + 1
                if current_line == num then
                    print(raw_line)
                    found = true
                    break
                end
            end
            if not found then
                print("[Lao]: Line " .. num .. " not found in file")
            end
            f:close()
        else
            print("[Lao]: File not found: " .. read_path2)
        end
        return true
    end

    if line == "get time" then
        print(os.date("%H:%M:%S"))
        return true
    end

    if line == "get date" then
        print(os.date("%Y-%m-%d"))
        return true
    end

    if line == "get datetime" then
        print(os.date("%Y-%m-%d %H:%M:%S"))
        return true
    end

    local var_name, var_value = line:match('^set%s+(%w+)%s+"(.-)"$')
    if var_name and var_value then
        variables[var_name] = var_value
        print("[Lao]: " .. var_name .. " = " .. var_value)
        return true
    end

    local get_var = line:match('^get%s+(%w+)$')
    if get_var then
        if variables[get_var] then
            print(variables[get_var])
        else
            print("[Lao]: Variable '" .. get_var .. "' not found!")
        end
        return true
    end

    local calc_expr = line:match('^calc%s+(.+)$')
    if calc_expr then
        if calc_expr:match("^[%d+%-%*%/%(%)%s]+$") then
            local func, err = load("return " .. calc_expr)
            if func then
                local result = func()
                if result then
                    print("[Lao]: " .. calc_expr .. " = " .. result)
                else
                    print("[Lao]: Calculation error!")
                end
            else
                print("[Lao]: " .. err)
            end
        else
            print("[Lao]: Invalid expression! Use numbers and operators (+, -, *, /)")
        end
        return true
    end

    local loop_count, loop_cmd = line:match('^loop%s+(%d+)%s+%[(.+)%]$')
    if loop_count and loop_cmd then
        local count = tonumber(loop_count)
        if count and count > 0 and count <= 100 then
            for i = 1, count do
                lao.run_line(loop_cmd)
            end
        else
            print("[Lao]: Loop count must be between 1 and 100")
        end
        return true
    end

    local open_file = line:match('^open%s+"(.-)"$')
    if open_file then
        local safe_path, err = sanitize_filepath(open_file)
        if not safe_path then
            print("[Security]: " .. err)
            return true
        end
        if not lao.execute_file(safe_path) then
            print("Could not execute file: " .. open_file)
        end
        return true
    end

    local ask_msg = line:match('^ask%s+"(.-)"$')
    if ask_msg then
        io.write(ask_msg .. " ")
        local user_input = io.read()
        if user_input then
            _G.last_answer = user_input:gsub("\r", "")
        else
            _G.last_answer = ""
        end
        return true
    end

    local condition, action = line:match('^if%s+(.-)%s+then%s+(.+)$')
    if condition and action then
        local check_var = condition:match('^answer%s*==%s*"(.-)"$')
        local check_var_not = condition:match('^answer%s*~=%s*"(.-)"$')
        
        if check_var then
            if _G.last_answer == check_var then
                lao.run_line(action)
            else
                print("Condition not met (answer ~= " .. check_var .. ")")
            end
        elseif check_var_not then
            if _G.last_answer ~= check_var_not then
                lao.run_line(action)
            else
                print("Condition not met (answer == " .. check_var_not .. ")")
            end
        end
        return true
    end

    local slow_print_val = line:match('^slowprint%s+this%s+"(.-)"$')
    if slow_print_val then
        type_write(slow_print_val)
        return true
    end

    local print_val = line:match('^print%s+this%s+"(.-)"$')
    if print_val then
        print(print_val)
        return true
    end

    local create_fname = line:match('^create%s+a%s+file%s+"(.-)"$')
    if create_fname then
        local safe_path, err = sanitize_filepath(create_fname)
        if not safe_path then
            print("[Security]: " .. err)
            return true
        end
        local f = io.open(safe_path, "w")
        if f then 
            f:close() 
            print("[Lao]: File created -> " .. create_fname) 
        else
            print("Could not create file: " .. create_fname)
        end
        return true
    end

    local delete_fname = line:match('^delete%s+this%s+file%s+"(.-)"$')
    if delete_fname then
        local safe_path, err = sanitize_filepath(delete_fname)
        if not safe_path then
            print("[Security]: " .. err)
            return true
        end
        if os.remove(safe_path) then
            print("[Lao]: File deleted -> " .. delete_fname)
        else
            print("Could not delete file: " .. delete_fname)
        end
        return true
    end

    local content, filename = line:match('^write%s+this%s+"(.-)"%s+into%s+"(.-)"$')
    if content and filename then
        local safe_path, err = sanitize_filepath(filename)
        if not safe_path then
            print("[Security]: " .. err)
            return true
        end
        local f = io.open(safe_path, "a")
        if f then
            f:write(content .. "\n")
            f:close()
            print("[Lao]: Text appended to " .. filename)
        else
            print("Could not write to file: " .. filename)
        end
        return true
    end

    local url = line:match('^go%s+to%s+website%s+"(.-)"$')
    if url then
        print("[Lao]: Opening browser -> " .. url)
        local os_name = package.config:sub(1,1)
        if os_name == "\\" then
            os.execute("start " .. url)
        else
            os.execute("xdg-open " .. url .. " 2>/dev/null || open " .. url)
        end
        return true
    end

    local seconds = line:match('^wait%s+for%s+(%d+)%s+seconds$')
    if seconds then
        local sec = tonumber(seconds)
        if sec and sec > 0 and sec <= 3600 then
            print("[Lao]: Waiting for " .. sec .. " seconds...")
            os.execute("timeout /t " .. sec .. " >nul 2>nul || sleep " .. sec .. " 2>/dev/null")
            print("[Lao]: Wait completed!")
        else
            print("Invalid seconds: " .. (seconds or "?"))
            print("Use: wait for 5 seconds (1-3600)")
        end
        return true
    end

    local l_path, o_path = line:match('^compress%s+this%s+%.lao%s+file%s+from%s+%.olao%s+"(.-)"%s+"(.-)"$')
    if l_path and o_path then
        lao.compress_to_olao(l_path, o_path)
        return true
    end

    if line == "end" then
        print("[Lao]: Execution ended.")
        return false
    end

    local suggestion = get_friendly_suggestion(line)
    print("[Lao]: " .. suggestion)
    log_error("Unknown command: " .. line)  -- YENİ: Log bağlıdırsa yazmayacaq
    return true
end

function lao.compress_to_olao(lao_path, olao_path)
    local safe_path, err = sanitize_filepath(lao_path)
    if not safe_path then
        print("[Lao Error]: " .. err)
        log_error("Compression failed: " .. err)
        return false
    end
    
    local infile = io.open(safe_path, "r")
    if not infile then 
        print("File not found: " .. lao_path)
        return false 
    end

    local outfile = io.open(olao_path, "w")
    for raw_line in infile:lines() do
        local working_line = raw_line
        for word, symbol in pairs(dictionary) do
            working_line = working_line:gsub(word, symbol)
        end
        outfile:write(working_line .. "\n")
    end
    infile:close()
    outfile:close()
    print("[Lao]: Compression successful -> " .. olao_path)
    return true
end

function lao.execute_file(filepath)
    local safe_path, err = sanitize_filepath(filepath)
    if not safe_path then
        print("[Security]: " .. err)
        return false
    end
    
    local file = io.open(safe_path, "r")
    if not file then 
        print("File not found: " .. filepath)
        return false
    end
    
    for raw_line in file:lines() do
        local commands = parse_line_by_other(raw_line)
        for _, single_cmd in ipairs(commands) do
            local status = lao.run_line(single_cmd)
            if status == false then 
                file:close()
                return true 
            end
        end
    end
    file:close()
    return true
end

function lao.start_interactive()
    print("====================================")
    print("  Lao Language Engine v" .. VERSION)
    print("  " .. VERSION_DATE)
    print("  Type 'help' for commands")
    print("  Type 'version' for info")
    print("  Type 'end' to exit")
    print("  Type 'errorlogfile on/off' to toggle error log")
    print("====================================")
    
    local running = true
    while running do
        io.write("Lao> ")
        local input = io.read()
        if not input then break end
        
        local commands = parse_line_by_other(input)
        if #commands == 0 then
            print("Type something!")
        else
            for _, single_cmd in ipairs(commands) do
                running = lao.run_line(single_cmd)
                if running == false then break end
            end
        end
    end
    print("Goodbye!")
end

lao.start_interactive()
