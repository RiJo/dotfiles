#!/usr/bin/lua

-- Executes the current file in an external terminal
function ExternalGo()
    local term = "xterm -e"
    local path = props['FileDir']
    local bin = props['FileName']

    os.execute(term .. " 'cd " ..path .. ";./" .. bin .. ";echo;echo \" --- Press any key to continue ---\";read -n 1'");
end

-- Executes gdb in an external terminal
function ExternalDebug()
    local term = "xterm -e"
    local path = props['FileDir']
    local bin = props['FileName']

    os.execute(term .. " 'cd " ..path .. ";gdb ./" .. bin .. ";echo;echo done'");
end

-- Perform a revision control commit in the current directory
function RevisionControlCommit()
    local term = "xterm -e"
    local path = props['FileDir']
    local askPush = "read -n 1 -p \"Do you want to push (y/n)? \" push"
    local gitCommit = "git commit -a"
    local gitPush = "git push"
    local evalPush = "if [ \"$push\" == \"y\" ]; then echo \"Pushing to server...\"; " .. gitPush .. "; fi"

    os.execute(term .. " 'cd " ..path .. ";" .. gitCommit .. " && " .. askPush .. ";echo;" .. evalPush .. ";echo;echo \" --- Press any key to continue ---\";read -n 1'");
end

-- Perform a revision control update in the current directory
function RevisionControlUpdate()
    local vcs = {}
    vcs["svn"] = {"ls .svn", SvnUpdate}
    vcs["git"] = {"git status", GitUpdate}

    output:AppendText("Performing version control update\n")
    for key, mapping in pairs(vcs) do
        output:AppendText("Looking for " .. key .. "...")
        if os.execute(mapping[1]) == 0 then
            output:AppendText("found\n\n")
            mapping[2]()
            break
        else
            output:AppendText("not found\n")
        end
    end
end

-- Perform a git pull in the current directory
function GitUpdate()
    local term = "xterm -e"
    local path = props['FileDir']
    local bin = props['FileName']
    local gitPull = "git pull"

    os.execute(term .. " 'cd " ..path .. ";" .. gitPull .. ";echo;echo \" --- Press any key to continue ---\";read -n 1'");
end

-- Perform a svn update in the current directory
function SvnUpdate()
    local term = "xterm -e"
    local path = props['FileDir']
    local bin = props['FileName']
    local svnUpdate = "svn update"

    os.execute(term .. " 'cd " ..path .. ";" .. svnUpdate .. ";echo;echo \" --- Press any key to continue ---\";read -n 1'");
end

-- Inserts current date
function InsertDate()
    editor:AddText(os.date("%Y-%m-%d"))
end

-- Formats the code according to RiJo
function FormatCode()
    local data = string_to_table(editor:GetSelText())

    local searched = 0
    local affected = 0
    local corrected_tabs = 0
    local corrected_before = 0
    local corrected_after = 0
    for key, value in pairs(data) do
        data[key],tabs,before,after = fix_indentation(value)
        searched = searched + 1
        if tabs > 0 or before > 0 or after > 0 then
            affected = affected + 1
        end
        corrected_tabs = corrected_tabs + tabs
        corrected_before = corrected_before + before
        corrected_after = corrected_after + after
    end
    editor:ReplaceSel(table.concat(data,"\n"))
    header = "Indentation fix done!\n"
    line = string.rep("-", 50) .. "\n"

    -- Print to output
    output:AppendText(header)
    output:AppendText(line)
    output:AppendText(
        "Rows searched:\t\t\t\t" .. searched .. "\n" ..
        "Rows affected:\t\t\t\t" .. affected .. "\n" ..
        "Tabs removed before:\t\t\t" .. corrected_tabs .. "\n" ..
        "Spaces added before:\t\t\t" .. corrected_before .. "\n" ..
        "Characters removed after:\t\t" .. corrected_after
    )

    -- Style
    output:StartStyling(0, 31)
    output:SetStyling(string.len(header), STYLE_DEFAULT)
    output:SetStyling(string.len(line), STYLE_LINENUMBER)
    output:SetStyling(512, STYLE_BRACELIGHT)
    
end

-- Fix the formatting of a line
function fix_indentation(str)
    indentation = "    "
    corrected_tabs = 0
    corrected_before = 0
    corrected_after = 0

    -- Trim string
    str,corrections = r_trim(str)
    corrected_after = corrected_after + corrections
    -- Remove tabs
    str,corrections = string.gsub(str,"\t",indentation)
    corrected_tabs = corrected_tabs + corrections
    -- Fix indentation
    str,corrections = indent(str,indentation)
    corrected_before = corrected_before + corrections

    return str,corrected_tabs,corrected_before,corrected_after
end

--~ function trim(str)
--~   return str:gsub("^%s*(.-)%s*$", "%1")
--~ end

function r_trim(str)
    characters = string.len(str:gsub("^.-(%s*)$", "%1"))
    str = str:gsub("^(.-)%s*$", "%1")
    return str,characters
end

function l_trim(str)
    return str:gsub("^%s*(.-)$", "%1")
end

-- Fix the indentation of the given string
function indent(str, symbol)
    spaces = string.len(str:gsub("^(%s*).-$", "%1"))
    indents = math.ceil(spaces / string.len(symbol))
    diff = (indents*string.len(symbol)) - spaces
    return string.rep(symbol, indents) .. l_trim(str),diff
end

-- Splits a text by lines to a table
function string_to_table(str)
    local t = {}
    local function helper(line) table.insert(t, line) return "" end
    helper((str:gsub("(.-)\r?\n", helper)))
    return t
end

-- Returns a table of the files in the given path
function GetFiles(path, extension)
    files = {}
    for filename in io.popen("ls " .. path):lines() do
        if string.find(filename,"%." .. extension .. "$") then
            table.insert(files, filename)
        end
    end
    return files
end

-- Creates a box comment header of the selected text
-- Bugs:
--  * doesn't work with .lua (--)
--  * should not format lines longer than 80 chars
function BoxCommentHeader()
    local width = 80
    local margin = 3
    local fill = (props['comment.block' .. props['FileExt']])

    if string.len(fill) == 0 then
        fill = "#" -- default
    else
        fill = string.sub(fill,0,string.len(fill)-1)
--~         fill = string.gsub(fill,"-", "%-")
    end

    local position = editor.SelectionStart
    local text = editor:GetSelText()
    if string.len(text) > 0 then
        if string.sub(text,0,width) == string.rep(fill,width/string.len(fill)) and string.len(text) == 3 * width + 2 then
            text = string.gsub(text, ".+" .. string.rep(" ",margin) .. "(.+)" .. string.rep(" ",margin) .. ".+", "%1")
        elseif not string.find(text, fill) then
            middle_rest_length = width - string.len(text) - 2*margin - string.len(fill)
            rest = string.rep(fill,math.ceil(middle_rest_length/string.len(fill)))
            rest = string.sub(rest,0,middle_rest_length)
            text =
                string.rep(fill,width/string.len(fill)) ..
                "\n" ..
                fill .. string.rep(" ",margin) .. text .. string.rep(" ",margin) .. rest ..
                "\n" ..
                string.rep(fill,width/string.len(fill))
        end
        editor:ReplaceSel(text)
        -- Select the new text
        editor.Anchor = position
        editor.SelectionEnd   = position + string.len(text)
    end
end

-- Toggles binary values
function ToggleBinaryValue()
    local StartPos = editor.CurrentPos
    editor:WordRight()
    editor:WordLeftExtend()
    local Word = editor:GetSelText()

    if Word == "FALSE" then editor:ReplaceSel("TRUE") end
    if Word == "TRUE" then editor:ReplaceSel("FALSE") end
    if Word == "false" then editor:ReplaceSel("true") end
    if Word == "true" then editor:ReplaceSel("false") end
    if Word == "False" then editor:ReplaceSel("True") end
    if Word == "True" then editor:ReplaceSel("False") end
    if Word == "YES" then editor:ReplaceSel("NO") end
    if Word == "NO" then editor:ReplaceSel("YES") end
    if Word == "yes" then editor:ReplaceSel("no") end
    if Word == "no" then editor:ReplaceSel("yes") end
    if Word == "0" then editor:ReplaceSel("1") end
    if Word == "1" then editor:ReplaceSel("0") end

    editor:GotoPos(StartPos)
end

function SciteListAllOccurances()
    if props.CurrentSelection ~= "" then
        for m in editor:match( "^.*" .. props.CurrentSelection .. ".*$", SCFIND_REGEXP, 0) do
            print(props.FileNameExt .. ":" .. (editor:LineFromPosition(m.pos)+1) .. ":" .. m.text);
        end
    else
        alert("The InternalGrep script only searchs for selected text");
    end
end