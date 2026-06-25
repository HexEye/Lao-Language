local lao = {}

local dictionary = {
    ["create a file"] = "+f",
    ["delete this file"] = "-f",
    ["print this"] = "?@",
    ["slowprint this"] = "s?@",
    ["write this"] = "w>",
    ["into"] = "->",
    ["go to website"] = "g2w",
    ["run terminal command"] = "rtc",
    ["wait for"] = "w4",
    ["compress this .lao file from .olao"] = "c2o",
    ["open"] = "op",
    ["ask"] = "sk",
    ["if"] = "if",
    ["help"] = "hlp",
    ["end"] = "."
}

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
            table.insert(commands, currentCommand:match("^%s*(.-)%s*$"))
            currentCommand = ""
            i = i + 5
        else
            currentCommand = currentCommand .. char
            i = i + 1
        end
    end
    if currentCommand ~= "" then
        table.insert(commands, currentCommand:match("^%s*(.-)%s*$"))
    end
    return commands
end

function lao.compress_to_olao(lao_path, olao_path)
    local infile = io.open(lao_path, "r")
    if not infile then 
        print("[Lao Error]: Source file not found for compression -> " .. lao_path)
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

function lao.show_help()
    print("\n=======================================================")
    print("                LAO LANGUAGE COMMANDS MAP              ")
    print("=======================================================")
    print(" Human Command                        | .olao Symbol   ")
    print("-------------------------------------------------------")
    for word, symbol in pairs(dictionary) do
        local padding = string.rep(" ", 35 - #word)
        print(" " .. word .. padding .. "| " .. symbol)
    end
    print("=======================================================\n")
end

function lao.run_line(raw_line)
    local line = raw_line:gsub("^%s*(.-)%s*$", "%1"):gsub("\r", "")
    if line == "" or line:match("^#") then return true end

    if line == "help" then
        lao.show_help()
        return true
    end

    local open_file = line:match('^open%s+"(.-)"$')
    if open_file then
        lao.execute_file(open_file)
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
        if check_var then
            if _G.last_answer == check_var then
                lao.run_line(action)
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
        local f = io.open(create_fname, "w")
        if f then f:close() print("[Lao]: File created -> " .. create_fname) end
        return true
    end

    local delete_fname = line:match('^delete%s+this%s+file%s+"(.-)"$')
    if delete_fname then
        if os.remove(delete_fname) then
            print("[Lao]: File deleted -> " .. delete_fname)
        else
            print("[Lao Error]: Could not delete file -> " .. delete_fname)
        end
        return true
    end

    local content, filename = line:match('^write%s+this%s+"(.-)"%s+into%s+"(.-)"$')
    if content and filename then
        local f = io.open(filename, "a")
        if f then
            f:write(content .. "\n")
            f:close()
            print("[Lao]: Text successfully appended to " .. filename)
        else
            print("[Lao Error]: Could not write to file -> " .. filename)
        end
        return true
    end

    local url = line:match('^go%s+to%s+website%s+"(.-)"$')
    if url then
        print("[Lao]: Opening browser -> " .. url)
        os.execute("start " .. url)
        return true
    end

    local cmd = line:match('^run%s+terminal%s+command%s+"(.-)"$')
    if cmd then
        print("[Lao]: Executing system command -> " .. cmd)
        os.execute(cmd)
        return true
    end

    local seconds = line:match('^wait%s+for%s+(%d+)%s+seconds$')
    if seconds then
        print("[Lao]: Waiting for " .. seconds .. " seconds...")
        os.execute("timeout /t " .. seconds .. " >nul")
        return true
    end

    local l_path, o_path = line:match('^compress%s+this%s+%.lao%s+file%s+from%s+%.olao%s+"(.-)"%s+"(.-)"$')
    if l_path and o_path then
        lao.compress_to_olao(l_path, o_path)
        return true
    end

    if line == "end" then
        print("[Lao]: Execution ended successfully.")
        return false
    end

    print("[Lao Error]: Unknown command -> " .. line)
    return true
end

function lao.execute_file(filepath)
    local file = io.open(filepath, "r")
    if not file then 
        print("[Lao Error]: Script file '" .. filepath .. "' not found!") 
        return 
    end
    for raw_line in file:lines() do
        local commands = parse_line_by_other(raw_line)
        for _, single_cmd in ipairs(commands) do
            local status = lao.run_line(single_cmd)
            if status == false then break end
        end
    end
    file:close()
end

function lao.start_interactive()
    print("====================================")
    print("  Lao Language Engine (Interactive) ")
    print("  Type your commands below. Type 'end' to exit. ")
    print("====================================")
    
    local running = true
    while running do
        io.write("Lao> ")
        local input = io.read()
        if not input then break end
        
        local commands = parse_line_by_other(input)
        for _, single_cmd in ipairs(commands) do
            running = lao.run_line(single_cmd)
            if running == false then break end
        end
    end
end

lao.start_interactive()