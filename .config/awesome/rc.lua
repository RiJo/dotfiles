-- Standard awesome library
local gears = require("gears")
local awful = require("awful")
awful.rules = require("awful.rules")
require("awful.autofocus")
-- Widget and layout library
local wibox = require("wibox")
-- Theme handling library
local beautiful = require("beautiful")
-- Notification library
local naughty = require("naughty")
local menubar = require("menubar")

local vicious = require("vicious")

function file_exists(name)
   local f=io.open(name,"r")
   if f~=nil then io.close(f) return true else return false end
end

-- {{{ Error handling
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
    naughty.notify({ preset = naughty.config.presets.critical,
                     title = "Oops, there were errors during startup!",
                     text = awesome.startup_errors })
end

-- Handle runtime errors after startup
do
    local in_error = false
    awesome.connect_signal("debug::error", function (err)
        -- Make sure we don't go into an endless error loop
        if in_error then return end
        in_error = true

        naughty.notify({ preset = naughty.config.presets.critical,
                         title = "Oops, an error happened!",
                         text = err })
        in_error = false
    end)
end
-- }}}

-- Environment variables (in lua)
home_dir="/home/rijo/"
std_gtk_theme = home_dir .. ".std_gtk_theme "
terminal = os.getenv("TERMINAL") or "xterm"
editor = os.getenv("EDITOR") or "vim"
geditor = os.getenv("GEDITOR") or "scite"
webbrowser = std_gtk_theme .. (os.getenv("WEBBROWSER") or "firefox")
--~ webbrowser = "firefox-bin"
--~ filebrowser = std_gtk_theme .. "rox"
--~ office = std_gtk_theme .. "libreoffice"
editor_cmd = terminal .. " -e " .. editor

-- {{{ Variable definitions
-- Themes define colours, icons, and wallpapers
--beautiful.init("/usr/share/awesome/themes/default/theme.lua")
--beautiful.init(home_dir .. ".config/awesome/themes/arch_black/theme.lua")
beautiful.init(awful.util.getdir("config") .. "/themes/arch_black/theme.lua")
--beautiful.init("/home/rijo/.config/awesome/themes/tlab/theme.lua")

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
modkey = "Mod4"

-- Table of layouts to cover with awful.layout.inc, order matters.
local layouts =
{
    awful.layout.suit.floating,
    awful.layout.suit.tile,
    awful.layout.suit.tile.left,
    awful.layout.suit.tile.bottom,
    awful.layout.suit.tile.top,
    --awful.layout.suit.fair,
    --awful.layout.suit.fair.horizontal,
    --awful.layout.suit.spiral,
    --awful.layout.suit.spiral.dwindle,
    awful.layout.suit.max,
    awful.layout.suit.max.fullscreen,
    awful.layout.suit.magnifier
}
-- }}}

-- {{{ Wallpaper
if beautiful.wallpaper then
    for s = 1, screen.count() do
        gears.wallpaper.maximized(beautiful.wallpaper, s, true)
    end
end
-- }}}

-- {{{ Tags
-- Define a tag table which hold all screen tags.
tags = {}
for s = 1, screen.count() do
    -- Each screen has its own tag table.
    tags[s] = awful.tag({
        "alpha",
        "beta",
        "gamma",
        "delta",
--~         "epsilon",
--~         "zeta",
--~         "eta",
--~         "theta",
--~         "jota"
    }, s, layouts[1])
end
-- }}}

-- {{{ Menu
-- Create a laucher widget and a main menu
--myawesomemenu = {
--   { "manual", terminal .. " -e man awesome" },
--   { "edit config", editor_cmd .. " " .. awesome.conffile },
--   { "restart", awesome.restart },
--   { "quit", awesome.quit }
--}

--mymainmenu = awful.menu({ items = { { "awesome", myawesomemenu, beautiful.awesome_icon },
--                                    { "open terminal", terminal }
--                                  }
--                        })

--mylauncher = awful.widget.launcher({ image = beautiful.awesome_icon,
--                                     menu = mymainmenu })

-- Menubar configuration
menubar.utils.terminal = terminal -- Set the terminal for applications that require it
-- }}}

-- {{{ Wibox
-- Create a textclock widget
mytextclock = awful.widget.textclock()
--mytextclock = awful.widget.textclock({ align = "right" })

-- Execute command and return its output. You probably won't only execute commands with one
-- line of output
function execute_command(command)
   local fh = io.popen(command)
   local str = ""
   for i in fh:lines() do
      str = str .. i
   end
   io.close(fh)
   return str
end

function split(pString, pPattern)
   local Table = {}  -- NOTE: use {n = 0} in Lua-5.0
   local fpat = "(.-)" .. pPattern
   local last_end = 1
   local s, e, cap = pString:find(fpat, 1)
   while s do
      if s ~= 1 or cap ~= "" then
      table.insert(Table,cap)
      end
      last_end = e+1
      s, e, cap = pString:find(fpat, last_end)
   end
   if last_end <= #pString then
      cap = pString:sub(last_end)
      table.insert(Table, cap)
   end
   return Table
end

function os.capture(cmd, raw)
    local f = assert(io.popen(cmd, 'r'))
    local s = assert(f:read('*a'))
    f:close()
    if raw then return s end
        s = string.gsub(s, '^%s+', '')
        s = string.gsub(s, '%s+$', '')
        s = string.gsub(s, '[\n\r]+', ' ')
    return s
end

-- Space
space = wibox.widget.textbox()
space:set_text("  ")

-- Separator
separator_text = " | "
separator = wibox.widget.textbox()
separator:set_text(separator_text)

-- CPU graph
cpuwidget = awful.widget.graph()
cpuwidget:set_width(50)
cpuwidget:set_background_color(theme.color_label_background)
--cpuwidget:set_color("#FF5656")
cpuwidget:set_color({ type = "linear", from = { 0, 0 }, to = { 0, 20 }, stops = { { 0, theme.color_bar_red }, { 0.5, theme.color_bar_yellow }, { 1, theme.color_bar_green } }})
--~ cpuwidget:set_stack(true)
--~ cpuwidget:set_stack_colors({ "#FF5656", "#88A175", "#AECF96" })
--~ cpuwidget:set_gradient_colors({ "#FF5656", "#88A175", "#AECF96" })
--~ cpuwidget:set_gradient_angle(0)
vicious.register(cpuwidget, vicious.widgets.cpu, "$1")

-- Memory widget
--~ memwidget = wibox.widget.textbox()
--~ vicious.register(memwidget, vicious.widgets.mem, "$1% ($2MB/$3MB)", 20)

-- Volume widget
--volumewidget = wibox.widget.textbox()
--vicious.register(volumewidget, vicious.widgets.volume, "vol: $1%", 10, "Master")

-- NICs widget
nicwidget = wibox.widget.textbox()
function nic_status()
    spacer = " "
    --local nics_info = "n/a"
    local nics_info = execute_command("ip link show | grep '^[0-9]:' | grep -v '^[0-9]: lo:' | awk '{ print $2 $9 }' | tr ':' ' ' | tr '\n' '|'")
    local foo = ""
    for nic_info in (nics_info):gmatch"(.-)|" do
        local interface_info = split(nic_info, " ")
        local interface_name = interface_info[1]
        local interface_state = interface_info[2]
        if interface_state == "UP" then
            nic_info = '<span foreground="'..theme.color_label_green..'">'..interface_name..'</span>'
        else
            nic_info = '<span foreground="'..theme.color_label_red..'">'..interface_name..'</span>'
        end

        foo = foo..nic_info..separator_text
    end
    nicwidget:set_markup(foo)
    --nicwidget:set_text(foo)
end
nic_status()
wifi_timer = timer({timeout=13})
wifi_timer:connect_signal("timeout", nic_status)
wifi_timer:start()

-- Thermal widget
thermalwidget = wibox.widget.textbox()
--vicious.register(thermalwidget, vicious.widgets.thermal, "$1°C", 10, { "thermal_zone0", "sys"} )
vicious.register(thermalwidget, vicious.widgets.thermal, function (widget, args)
    local color = ""
    if args[1] >= 75 then
        color = theme.color_label_red
    elseif args[1] >= 55 then
        color = theme.color_label_yellow
    else
        color = theme.color_label_default
    end
    local text = args[1]..'°C'
    if color == "" then
        return text
    end
    return '<span color="'..color..'">'..text..'</span>'
end, 18, { "thermal_zone0", "sys"} )

-- Battery widget
batterywidget = wibox.widget.textbox()
--vicious.register(batterywidget, vicious.widgets.bat, 'bat: $1$2', 10, 'BAT0')
vicious.register(batterywidget, vicious.widgets.bat, function (widget, args)
    local color = ""
    --if string.byte(args[1]) == 55 or string.byte(args[1]) == 226 then
    if utf8.codepoint(args[1]) == 8722 then
        color = theme.color_label_red -- Uncharging
    elseif args[2] >= 75 then
        color = theme.color_label_green -- Charged/charging and level >=75%
    else
        color = theme.color_label_default -- Charged/charging and level <75%
    end
    local text = args[1]..args[2]..'%'
    --local text = args[1]..args[2]..'</span>'..' ('..args[3]..')'
    if color == "" then
        return text
    end
    return '<span color="'..color..'">'..text..'</span>'
end, 23, 'BAT0')

-- Packages widget
pkgwidget = wibox.widget.textbox()
vicious.register(pkgwidget, vicious.widgets.pkg, 'pkg: $1', 120, 'Arch')

-- Create a wibox for each screen and add it
mywibox = {}
--bottombox = {}
mypromptbox = {}
mylayoutbox = {}
mytaglist = {}
mytaglist.buttons = awful.util.table.join(
                    awful.button({ }, 1, awful.tag.viewonly),
                    awful.button({ modkey }, 1, awful.client.movetotag),
                    awful.button({ }, 3, awful.tag.viewtoggle),
                    awful.button({ modkey }, 3, awful.client.toggletag),
                    awful.button({ }, 4, function(t) awful.tag.viewnext(awful.tag.getscreen(t)) end),
                    awful.button({ }, 5, function(t) awful.tag.viewprev(awful.tag.getscreen(t)) end)
                    )
mytasklist = {}
mytasklist.buttons = awful.util.table.join(
                     awful.button({ }, 1, function (c)
                                              if c == client.focus then
                                                  c.minimized = true
                                              else
                                                  -- Without this, the following
                                                  -- :isvisible() makes no sense
                                                  c.minimized = false
                                                  if not c:isvisible() then
                                                      awful.tag.viewonly(c:tags()[1])
                                                  end
                                                  -- This will also un-minimize
                                                  -- the client, if needed
                                                  client.focus = c
                                                  c:raise()
                                              end
                                          end),
                     awful.button({ }, 3, function ()
                                              if instance then
                                                  instance:hide()
                                                  instance = nil
                                              else
                                                  instance = awful.menu.clients({
                                                      theme = { width = 250 }
                                                  })
                                              end
                                          end),
                     awful.button({ }, 4, function ()
                                              awful.client.focus.byidx(1)
                                              if client.focus then client.focus:raise() end
                                          end),
                     awful.button({ }, 5, function ()
                                              awful.client.focus.byidx(-1)
                                              if client.focus then client.focus:raise() end
                                          end))

for s = 1, screen.count() do
    -- Create a promptbox for each screen
    mypromptbox[s] = awful.widget.prompt()
    -- Create an imagebox widget which will contains an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    mylayoutbox[s] = awful.widget.layoutbox(s)
    mylayoutbox[s]:buttons(awful.util.table.join(
                           awful.button({ }, 1, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 3, function () awful.layout.inc(layouts, -1) end),
                           awful.button({ }, 4, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 5, function () awful.layout.inc(layouts, -1) end)))
    -- Create a taglist widget
    mytaglist[s] = awful.widget.taglist(s, awful.widget.taglist.filter.all, mytaglist.buttons)

    -- Create a tasklist widget
    mytasklist[s] = awful.widget.tasklist(s, awful.widget.tasklist.filter.currenttags, mytasklist.buttons)

    -- Create the wibox
    mywibox[s] = awful.wibox({ position = "top", screen = s })

    -- Widgets that are aligned to the left
    local left_layout = wibox.layout.fixed.horizontal()
--~     left_layout:add(mylauncher)
    left_layout:add(mytaglist[s])
    left_layout:add(cpuwidget)
    left_layout:add(space)
    left_layout:add(thermalwidget)
--~     left_layout:add(separator)
--~     left_layout:add(mypromptbox[s])
    left_layout:add(space)


    -- Widgets that are aligned to the right
    local right_layout = wibox.layout.fixed.horizontal()
    right_layout:add(space)
--~     right_layout:add(separator)
--~     right_layout:add(memwidget)
--    right_layout:add(volumewidget)
    right_layout:add(nicwidget)
    --right_layout:add(wifi_signal_widget)
    --right_layout:add(separator)
    right_layout:add(batterywidget)
    right_layout:add(separator)
    right_layout:add(pkgwidget)
    right_layout:add(separator)
    right_layout:add(mytextclock)
    if s == 1 then right_layout:add(wibox.widget.systray()) end
    right_layout:add(mylayoutbox[s])

    -- Now bring it all together (with the tasklist in the middle)
    local layout = wibox.layout.align.horizontal()
    layout:set_left(left_layout)
    layout:set_middle(mytasklist[s])
    layout:set_right(right_layout)

    mywibox[s]:set_widget(layout)

    --
    --  Bottom box
    --
    --bottombox[s] = awful.wibox({ position = "bottom", screen = s })
    --local bottom_layout = wibox.layout.fixed.horizontal()
    --bottom_layout:add(space)
    --bottom_layout:add(mypromptbox[s])
    --bottombox[s]:set_widget(bottom_layout)
end
-- }}}

-- {{{ Mouse bindings
root.buttons(awful.util.table.join(
--    awful.button({ }, 3, function () mymainmenu:toggle() end),
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev)
))
-- }}}

-- {{{ Key bindings
globalkeys = awful.util.table.join(
    awful.key({ modkey,           }, "Left",   awful.tag.viewprev       ),
    awful.key({ modkey,           }, "Right",  awful.tag.viewnext       ),
    awful.key({ modkey,           }, "Escape", awful.tag.history.restore),

    awful.key({ modkey,           }, "j",
        function ()
            awful.client.focus.byidx( 1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey,           }, "k",
        function ()
            awful.client.focus.byidx(-1)
            if client.focus then client.focus:raise() end
        end),
--    awful.key({ modkey,           }, "w", function () mymainmenu:show() end),

    -- Layout manipulation
    awful.key({ modkey, "Shift"   }, "j", function () awful.client.swap.byidx(  1)    end),
    awful.key({ modkey, "Shift"   }, "k", function () awful.client.swap.byidx( -1)    end),
    awful.key({ modkey, "Control" }, "j", function () awful.screen.focus_relative( 1) end),
    awful.key({ modkey, "Control" }, "k", function () awful.screen.focus_relative(-1) end),
    awful.key({ modkey,           }, "u", awful.client.urgent.jumpto),
    awful.key({ modkey,           }, "Tab",
        function ()
            awful.client.focus.history.previous()
            if client.focus then
                client.focus:raise()
            end
        end),

    -- Standard program
    awful.key({ modkey,           }, "Return", function () awful.util.spawn(terminal, false)   end),
    awful.key({ modkey,           }, "w",      function () awful.util.spawn(webbrowser, false) end),
    awful.key({ modkey,           }, "s",      function () awful.util.spawn(geditor, false)    end),
--~     awful.key({ modkey,           }, "e",      function () awful.util.spawn(filebrowser, false)end),
--~     awful.key({ modkey,           }, "o",      function () awful.util.spawn(office, false)     end),
    awful.key({ modkey, "Control" }, "r", awesome.restart),
    awful.key({ modkey, "Shift"   }, "q", awesome.quit),

    awful.key({ modkey,           }, "l",     function () awful.tag.incmwfact( 0.05)    end),
    awful.key({ modkey,           }, "h",     function () awful.tag.incmwfact(-0.05)    end),
    awful.key({ modkey, "Shift"   }, "h",     function () awful.tag.incnmaster( 1)      end),
    awful.key({ modkey, "Shift"   }, "l",     function () awful.tag.incnmaster(-1)      end),
    awful.key({ modkey, "Control" }, "h",     function () awful.tag.incncol( 1)         end),
    awful.key({ modkey, "Control" }, "l",     function () awful.tag.incncol(-1)         end),
    awful.key({ modkey,           }, "space", function () awful.layout.inc(layouts,  1) end),
    awful.key({ modkey, "Shift"   }, "space", function () awful.layout.inc(layouts, -1) end),

    awful.key({ modkey, "Control" }, "n", awful.client.restore),

    -- Prompt
    awful.key({ modkey },            "r",     function () mypromptbox[mouse.screen]:run() end),

    awful.key({ modkey }, "x",
              function ()
                  awful.prompt.run({ prompt = "Run Lua code: " },
                  mypromptbox[mouse.screen].widget,
                  awful.util.eval, nil,
                  awful.util.getdir("cache") .. "/history_eval")
              end),

    -- Multimedia keys
    awful.key({ }, "XF86AudioRaiseVolume", function () awful.util.spawn("amixer set Master 2%+", false) end),
    awful.key({ }, "XF86AudioLowerVolume", function () awful.util.spawn("amixer set Master 2%-", false) end),
    awful.key({ }, "XF86AudioMute", function () awful.util.spawn("amixer set Master toggle", false) end),

    -- Other
     awful.key({ }, "Print", function () awful.util.spawn("scrot -e 'mv $f ~/screenshots/ 2>/dev/null'") end)

    -- Menubar
    --awful.key({ modkey }, "p", function() menubar.show() end)
)

clientkeys = awful.util.table.join(
    awful.key({ modkey,           }, "f",      function (c) c.fullscreen = not c.fullscreen  end),
    awful.key({ modkey, "Shift"   }, "c",      function (c) c:kill()                         end),
    awful.key({ modkey, "Control" }, "space",  awful.client.floating.toggle                     ),
    awful.key({ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end),
    awful.key({ modkey,           }, "o",      awful.client.movetoscreen                        ),
    awful.key({ modkey,           }, "t",      function (c) c.ontop = not c.ontop            end),
    awful.key({ modkey,           }, "n",
        function (c)
            -- The client currently has the input focus, so it cannot be
            -- minimized, since minimized clients can't have the focus.
            c.minimized = true
        end),
    awful.key({ modkey,           }, "m",
        function (c)
            c.maximized_horizontal = not c.maximized_horizontal
            c.maximized_vertical   = not c.maximized_vertical
        end)
)

-- Compute the maximum number of digit we need, limited to 9
--keynumber = 0
--for s = 1, screen.count() do
--   keynumber = math.min(9, math.max(#tags[s], keynumber))
--end

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it works on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, 9 do
    globalkeys = awful.util.table.join(globalkeys,
        -- View tag only.
        awful.key({ modkey }, "#" .. i + 9,
                  function ()
                        local screen = mouse.screen
                        local tag = awful.tag.gettags(screen)[i]
                        if tag then
                           awful.tag.viewonly(tag)
                        end
                  end),
        -- Toggle tag.
        awful.key({ modkey, "Control" }, "#" .. i + 9,
                  function ()
                      local screen = mouse.screen
                      local tag = awful.tag.gettags(screen)[i]
                      if tag then
                         awful.tag.viewtoggle(tag)
                      end
                  end),
        -- Move client to tag.
        awful.key({ modkey, "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = awful.tag.gettags(client.focus.screen)[i]
                          if tag then
                              awful.client.movetotag(tag)
                          end
                     end
                  end),
        -- Toggle tag.
        awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = awful.tag.gettags(client.focus.screen)[i]
                          if tag then
                              awful.client.toggletag(tag)
                          end
                      end
                  end))
end

clientbuttons = awful.util.table.join(
    awful.button({ }, 1, function (c) client.focus = c; c:raise() end),
    awful.button({ modkey }, 1, awful.mouse.client.move),
    awful.button({ modkey }, 3, awful.mouse.client.resize))

-- Set keys
root.keys(globalkeys)
-- }}}

-- {{{ Rules
-- Rules to apply to new clients (through the "manage" signal).
awful.rules.rules = {
    -- All clients will match this rule.
    { rule = { },
      properties = { border_width = beautiful.border_width,
                     border_color = beautiful.border_normal,
                     focus = awful.client.focus.filter,
                     raise = true,
                     keys = clientkeys,
                     buttons = clientbuttons,
                     size_hints_honor = false -- Remove window gaps
    } },
    { rule = { class = "MPlayer" },
      properties = { floating = true } },
    { rule = { class = "pinentry" },
      properties = { floating = true } },
    { rule = { class = "gimp" },
      properties = { floating = true } },
    -- Set Firefox to always map on tags number 2 of screen 1.
    -- { rule = { class = "Firefox" },
    --   properties = { tag = tags[1][2] } },
}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.connect_signal("manage", function (c, startup)
    -- Enable sloppy focus
    c:connect_signal("mouse::enter", function(c)
        if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
            and awful.client.focus.filter(c) then
            client.focus = c
        end
    end)

    if not startup then
        -- Set the windows at the slave,
        -- i.e. put it at the end of others instead of setting it master.
        -- awful.client.setslave(c)

        -- Put windows in a smart way, only if they does not set an initial position.
        if not c.size_hints.user_position and not c.size_hints.program_position then
            awful.placement.no_overlap(c)
            awful.placement.no_offscreen(c)
        end
    end

    local titlebars_enabled = false
    if titlebars_enabled and (c.type == "normal" or c.type == "dialog") then
        -- buttons for the titlebar
        local buttons = awful.util.table.join(
                awful.button({ }, 1, function()
                    client.focus = c
                    c:raise()
                    awful.mouse.client.move(c)
                end),
                awful.button({ }, 3, function()
                    client.focus = c
                    c:raise()
                    awful.mouse.client.resize(c)
                end)
                )

        -- Widgets that are aligned to the left
        local left_layout = wibox.layout.fixed.horizontal()
        left_layout:add(awful.titlebar.widget.iconwidget(c))
        left_layout:buttons(buttons)

        -- Widgets that are aligned to the right
        local right_layout = wibox.layout.fixed.horizontal()
        right_layout:add(awful.titlebar.widget.floatingbutton(c))
        right_layout:add(awful.titlebar.widget.maximizedbutton(c))
        right_layout:add(awful.titlebar.widget.stickybutton(c))
        right_layout:add(awful.titlebar.widget.ontopbutton(c))
        right_layout:add(awful.titlebar.widget.closebutton(c))

        -- The title goes in the middle
        local middle_layout = wibox.layout.flex.horizontal()
        local title = awful.titlebar.widget.titlewidget(c)
        title:set_align("center")
        middle_layout:add(title)
        middle_layout:buttons(buttons)
--        title:buttons(awful.util.table.join(
--                awful.button({ }, 1, function()
--                    client.focus = c
--                    c:raise()
--                    awful.mouse.client.move(c)
--                end),
--                awful.button({ }, 3, function()
--                    client.focus = c
--                    c:raise()
--                    awful.mouse.client.resize(c)
--                end)
--                ))

        -- Now bring it all together
        local layout = wibox.layout.align.horizontal()
        layout:set_left(left_layout)
        layout:set_right(right_layout)
        layout:set_middle(middle_layout)

        awful.titlebar(c):set_widget(layout)
    end
end)

client.connect_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)
-- }}}
