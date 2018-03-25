-- Utility

local try = function(try_fun, catch_fun)
    local s, r = pcall(try_fun)
    if not s then
        catch_fun(r)
    else
        return r
    end
end

local tryfun = function(name, fun) 
    return try(fun, function(ex)
        ShowConsoleLog(true)
        AddConsoleLog("Exception in " .. name .. ": " .. print_format(ex), true)
    end)
end

local openPath = function(path)
    if Platform.pc then
        os.execute('explorer "' .. path .. '"')
        return
    end
    if Platform.osx then
        os.execute('open "' .. path .. '"')
        return
    end
    os.execute([[xterm -e "cd ']] .. path .. [[' && bash"]])
end

-- Minimized Window

DefineClass.LuaConsoleMinimized = {
    __parents = {
        "FrameWindow"
    },
    ZOrder = 10000
}

function LuaConsoleMinimized:Init() 
    tryfun("LuaConsoleMinimized:Init()", function()
        local ui_scale = GetUIScale()
        local s = ui_scale/100.0

        self:SetWindowScale(ui_scale)

        self:SetPos(point(10*s, 10*s))
        self:SetTranslate(false)
        self:SetMinSize(point(40*s, self.caption_height+20*s))
        self:SetSize(point(40*s, self.caption_height+20*s))
        self:SetMovable(true)
        self:SetZOrder(10000)
        
        local tmp
        tmp = StaticText:new(self)
        tmp:SetId("lcTitle")
        tmp:SetPos(point(10*s, 10*s+self.caption_height))
        tmp:SetSize(point(40*s, self.caption_height+20*s))   
        tmp:SetHSizing("AnchorToLeft")
        tmp:SetVSizing("AnchorToTop")
        tmp:SetBackgroundColor(RGBA(0,0,0,65))
        tmp:SetFontStyle("UIDefault")
        tmp:SetText("<image UI/Icons/res_experimental_research.tga><color 255 230 100>Lua")
        
        tmp.OnLButtonDown = function(this)
            luaConsoleMinimized:delete()
            luaConsoleMinimized = nil
            luaConsoleWindow:SetVisible(true, true)
        end

        self:InitChildrenSizing()
    end)
end

function LuaConsoleMinimized:OnBoxChanged()
    Window.OnBoxChanged(self)
    if luaConsoleWindow then
        luaConsoleWindow.minX = self:GetX()
        luaConsoleWindow.minY = self:GetY()
        luaConsoleWindow:SaveSettings()
    end
end


-- Console Window

DefineClass.LuaConsoleWindow = {
    __parents = {
        "FrameWindow"
    },
    ZOrder = 10000
}

function LuaConsoleWindow:Init()
    tryfun("LuaConsoleWindow:Init()", function()
        local ui_scale = GetUIScale()
        local s = ui_scale/100.0

        self:SetWindowScale(ui_scale)

        self:SetPos(point(100*s, 100*s))
        self:SetTranslate(false)
        self:SetMinSize(point(400*s, 300*s))
        self:SetSize(point(400*s, 300*s))
        self:SetMovable(true)
        self:SetZOrder(10000)
        
        local tmp
        tmp = StaticText:new(self)
        tmp:SetId("lcTitle")
        tmp:SetPos(point(102*s, 100*s+self.caption_height))
        tmp:SetSize(point(396*s, 25*s))   
        tmp:SetHSizing("Resize")
        tmp:SetVSizing("AnchorToTop")
        tmp:SetBackgroundColor(RGBA(0,0,0,65))
        tmp:SetFontStyle("UIDefault")
        tmp:SetText("<image UI/Icons/res_experimental_research.tga><color 255 230 100>Lua Console")
        
        tmp.OnLButtonDown = function(this)
            luaConsoleWindow.lcMenu:CreateDropdownBox()
        end

        tmp = ComboBox:new(self)
        tmp:SetId("lcMenu")
        tmp:SetPos(point(104*s, 100*s))
        tmp:SetSize(point(200*s, 25*s)) 
        tmp:SetHSizing("AnchorToLeft")
        tmp:SetVSizing("AnchorToTop")
        tmp:SetFontStyle("UIDefault")
        tmp:SetText("Menu")
        tmp:SetVisible(false)
        tmp:SetItemsLimit(100)

        tmp.OnComboClose = function(this, idx)
            if luaConsoleWindow.lcMenu.list.rollover then
                luaConsoleWindow:MenuAction(this.items[idx].text)
            end
        end

        for k, v in pairs({
            "Minimize",
            "Help",
            "-",
            "Clear",
            "Save Console Log",
            "-",
            "Watch Last Input",
            "-",
            "Open Scratch Pad",
            "Reload Scratch Pad",
            "Reload Mods",
        }) do
            local itm = StaticText:new(tmp)
            itm:SetText(v)
            itm:SetBackgroundColor(RGB(0,0,0))
            if v:sub(1,1) == "-" then
                itm:SetText("<color 180 180 180>" .. v:sub(2))
            end
            tmp:AddItem(itm)
        end

        tmp = StaticText:new(self)
        tmp:SetId("lcText")
        tmp:SetPos(point(102*s, 125*s+self.caption_height))
        tmp:SetSize(point(396*s, 378*s-125*s-self.caption_height-2))
        tmp:SetHSizing("Resize")
        tmp:SetVSizing("Resize")
        tmp:SetBackgroundColor(RGBA(0,0,0,50))
        tmp:SetFontStyle("console")
        tmp:SetScrollBar(true)
        tmp:SetText("")

        tmp.OnHyperLink = function(this, link, arg, box, pos, button)
            luaConsoleWindow:OnHyperLink(link, arg, box, pos, button)
        end

        tmp = StaticText:new(self)
        tmp:SetId("lcWatches")
        tmp:SetPos(point(300*s, 130*s+self.caption_height))
        tmp:SetSize(point(176*s, 40*s))
        tmp:SetHSizing("AnchorToRight")
        tmp:SetVSizing("AnchorToTop")
        tmp:SetBackgroundColor(RGBA(0,0,0,50))
        tmp:SetVisible(false)
        
        tmp.OnHyperLink = function(this, link, arg, box, pos, button)
            luaConsoleWindow:OnHyperLink(link, arg, box, pos, button)
        end

        tmp = SingleLineEdit:new(self)
        tmp:SetId("lcInput")
        tmp:SetPos(point(102*s, 378*s))
        tmp:SetSize(point(396*s, 20*s))
        tmp:SetHSizing("Resize")
        tmp:SetVSizing("AnchorToBottom")
        tmp:SetFontStyle("Editor12Bold")
        tmp:SetBackgroundColor(RGBA(100,100,100,50))

        function tmp.OnKbdKeyDown(this, char, vkey)
            if vkey == const.vkEnter then
                self:Input(tmp.text)
                tmp:SetText("")
                self.historyPos = 0
                return "break"
            end
            if vkey == const.vkDown then
                self:History(-1)
                return "break"
            end
            if vkey == const.vkUp then
                self:History(1)
                return "break"
            end
            return SingleLineEdit.OnKbdKeyDown(this, char, vkey)
        end

        self:InitChildrenSizing()
        self.historyPos = 0
        self.loaded = false
        self.minX = 10
        self.minY = 10
        self.watches = {}
        self.watchThread = nil
        self.watchHistory = {}
        self.lastInput = ""
        self.externalEditor = nil
    end)
end

function LuaConsoleWindow:StopThreads()
    self:StopWatchThread()
end

function LuaConsoleWindow:StopWatchThread()
    if IsValidThread(self.watchThread) then
        DeleteThread(self.watchThread)
    end
end

function LuaConsoleWindow:UpdateWatches()
    if #self.watches < 1 then
        self.lcWatches:SetText("")
        self.lcWatches:SetVisible(false)
        self:StopWatchThread()
        return
    end

    local txt = ""
    for k, v in pairs(self.watches) do
        res = "<color 255 100 100>error"
        local fun, err = load("return " .. v, nil, nil, _G)
        if err then
            res = "<color 255 100 100>" .. err
        else
            local s, r = pcall(fun)
            if s then
                res = Literal(tostring(r))
            else
                res = "<color 255 100 100>" .. r
            end
        end
        txt = txt .. "<color 255 255 255>"
        txt = txt .. "<h watch " .. tostring(k) .. " 255 100 100>" .. Literal(v) .. "</h>\n"
        txt = txt .. "<color 255 200 50>" .. res .. "\n"
        txt = txt .. "\n"
    end

    self.lcWatches:SetText(txt)
    self.lcWatches:SetHeight(self.lcWatches.text_height)
    self.lcWatches:SetVisible(true)
end

function LuaConsoleWindow:CreateWatchThread()
    if not IsValidThread(self.watchThread) then
        self.watchThread = CreateRealTimeThread(function()
            while true do
                luaConsoleWindow:UpdateWatches()
                Sleep(1000)
            end
        end)
    end
end

function LuaConsoleWindow:AddWatch(expr)
    if not expr then
        return
    end
    if expr == "" then
        return
    end
    for k, v in pairs(self.watches) do
        if v == expr then
            return
        end
    end
    table.insert(self.watches, expr)
    self:StopWatchThread()
    self:CreateWatchThread()
end

function LuaConsoleWindow:RemoveWatch(idx)
    table.remove(self.watches, idx)
    self:StopWatchThread()
    self:CreateWatchThread()
end

function LuaConsoleWindow:OnBoxChanged()
    Window.OnBoxChanged(self)
    if self.loaded then
        self:SaveSettings()
    end
end

function LuaConsoleWindow:LoadSettings()
    local s = LocalStorage.luaConsoleSettings
    if s then
        try(function()
            local s = LocalStorage.luaConsoleSettings
            luaConsoleWindow:SetPos(point(s[1], s[2]))
            luaConsoleWindow:SetSize(point(s[3], s[4]))
            luaConsoleWindow.minX = s[5]
            luaConsoleWindow.minY = s[6]
        end, function(ex)
        end)
    end
    self.loaded = true
end

function LuaConsoleWindow:SaveSettings()
    LocalStorage.luaConsoleSettings = {
        self:GetX(),
        self:GetY(),
        self:GetWidth(),
        self:GetHeight(),
        self.minX,
        self.minY,
    }
    SaveLocalStorage()
end

function LuaConsoleWindow:Minimize()
    if not luaConsoleMinimized then
        local mpos = point(self.minX, self.minY)
        luaConsoleMinimized = LuaConsoleMinimized:new()
        luaConsoleMinimized:SetPos(mpos)
    end
    self:SetVisible(false, true)
end

function LuaConsoleWindow:MenuAction(val)
    if val == "Minimize" then
        luaConsoleWindow:Minimize()
        return
    end
    if val == "Help" then
        self:Print("")
        self:Print("<image UI/Icons/res_experimental_research.tga><color 255 230 100>Lua Console by special_snowcat<color 220 220 180>")
        self:Print("")
        self:Print("Type lua expressions or statements in the input field below.")
        self:Print("")
        self:Print("Click an expression you've entered previously to watch it, or use the menu to watch your last input.")
        self:Print("Watched expressions are updated once per second.")
        self:Print("")
        self:Print("Useful engine variables (click to watch):")
        table.insert(self.watchHistory, "SelectedObj")
        self:Print("  <h expr " .. #self.watchHistory .. " 100 255 100>SelectedObj</h> - current selected object in the game world")
        self:Print("")
        self:Print("Useful engine functions:")
        self:Print("  ShowMe(obj) - point out a game object")
        self:Print("  OpenExamine(obj) - examine a lua value")
        self:Print("")
        return
    end
    if val == "Clear" then
        self.lcText.scroll:SetValue(0)
        self.lcText:SetText("")
        self.watchHistory = {}
        return
    end
    if val == "Save Console Log" then
        tryfun("Save Console Log", function()
            local file = io.open("AppData/LuaConsole.log", "w")
            file:write(self.lcText.text)
            file:close()
            self:Print("Log written to <h path AppData 255 0 255>" .. ConvertToOSPath("AppData/LuaConsole.log") .. "</h>.")
        end)
        return
    end
    if val == "Watch Last Input" then
        self:AddWatch(self.lastInput)
        return
    end
    if val == "Open Scratch Pad" then
        self:OpenScratchPad()
        return
    end
    if val == "Reload Scratch Pad" then
        self:Print("Reloading scratch pad...")
        self:ExecuteScratchPad()
        return
    end
    if val == "Reload Mods" then
        self:Print("Reloading mods...")
        ReloadLua()
        return
    end
end

function LuaConsoleWindow:ExecuteScratchPad()
    local path = ConvertToOSPath("AppData/LuaConsoleScratchPad.lua")
    local f = io.open(path, "r")
    if not f then
        return
    end
    local text = f:read("*a")
    f:close()

    local fun, err = load(text, nil, nil, _G)
    if err then
        self:Print("<color 255 100 100>Scratch Pad: " .. err)
        return
    end

    try(function()
        fun()
    end, function(ex)
        luaConsoleWindow:Print("<color 255 100 100>Scratch Pad: " .. Literal(ex))
    end)    
end

function LuaConsoleWindow:OpenScratchPad()
    local path = ConvertToOSPath("AppData/LuaConsoleScratchPad.lua")
    local cmd = "gedit"
    if Platform.pc then
        cmd = "start notepad"
    end
    if Platform.osx then
        cmd = "open -a TextEdit"
    end
    if self.externalEditor then
        cmd = self.externalEditor
    end

    local f = io.open(path, "r")
    if f then
        f:close()
    else
        f = io.open(path, "w")
        local preset = [[--
-- Lua Console Scratch Pad
--
-- This is a space for lua code you want to run whenever Lua Console is loaded.
-- Use it to define your own helper functions or set up your environment.
--

-- Examples (uncomment to enable):

-- Override what editor Lua Console will try to open files like this scratch pad with:
-- luaConsoleWindow.externalEditor = 'start "C:\\Program Files (x86)\\Vim\\vim80\\gvim.exe"'

-- Print some text to the console:
-- lcPrint("Hello there! You're beautiful!")

-- Watch an expression:
-- lcWatch("SelectedObj and SelectedObj.name")

-- Define a helper function for frequent console tasks:
-- function json(x)
--     return LuaToJSON(x)
-- end
        ]]
        if Platform.pc then
            preset = preset:gsub("\n", "\r\n")
        end
        f:write(preset)
        f:close()
    end

    if Platform.pc then
        self:Print("Executing: " .. cmd .. ' "<h path AppData 255 0 255>' .. path .. '</h>"')
    else
        self:Print("Running external commands is not supported on this platform.")
        self:Print("Please edit this file: <h path AppData 255 0 255>" .. path .. "</h>")
    end
    os.execute(cmd .. ' "' .. path .. '"')
end

function LuaConsoleWindow:OnHyperLink(link, arg, box, pos, button)
    if link == "path" then
        openPath(ConvertToOSPath(arg .. "/"))
        return
    end
    if link == "watch" then
        self:RemoveWatch(tonumber(arg))
        return
    end
    if link == "expr" then
        self:AddWatch(self.watchHistory[tonumber(arg)])
        return
    end
end

function LuaConsoleWindow:Print(text)
    if not text then
        text = ""
    end
    local smax = self.lcText.scroll:GetMax()
    local sval = self.lcText.scroll:GetValue()
    self.lcText:SetText(self.lcText.text .. "\n" .. text)
    if sval == smax then
        self.lcText.scroll:SetValue(self.lcText.scroll:GetMax())
    end
end

function LuaConsoleWindow:History(offset)
    if not dlgConsole then
        return
    end
    self.historyPos = self.historyPos + offset
    if self.historyPos < 1 then
        self.historyPos = 0
        self.lcInput:SetText("")
        return
    end
    if self.historyPos > #dlgConsole.historyQueue then
        self.historyPos = #dlgConsole.historyQueue
    end
    self.lcInput:SetText(dlgConsole.historyQueue[self.historyPos])
end

function LuaConsoleWindow:Input(text)
    if dlgConsole then
        dlgConsole:AddHistory(text)
    end
    
    self.lastInput = text

    local fun, err = load("return " .. text, nil, nil, _G)
    if err then
        self:Print("<color 200 200 200>$ " .. Literal(text))
        local err2
        fun, err2 = load(text, nil, nil, _G)
        if err2 then
            self:Print("<color 255 100 100>" .. Literal(err))
            return
        end
    else 
        table.insert(self.watchHistory, text)
        self:Print("<color 200 200 200>$ <h expr " .. #self.watchHistory .. " 100 255 100>" .. Literal(text) .. "</h>")
    end

    try(function()
        local res = fun()
        if res then
            luaConsoleWindow:Print("<color 255 255 255>" .. Literal(print_format(res)))
        end
    end, function(ex)
        luaConsoleWindow:Print("<color 255 100 100>" .. Literal(ex))
    end)
end

function lcPrint(text)
    if not text then
        return
    end
    if luaConsoleWindow then
        luaConsoleWindow:Print("<color 255 255 255>" .. text)
    else
        ShowConsoleLog(true)
        AddConsoleLog(text, true)
    end
end

function lcWatch(expr)
    if luaConsoleWindow then
        luaConsoleWindow:AddWatch(expr)
    end
end

function OnMsg.Autorun()
    tryfun("Autorun", function()
        ShowConsole(true)
        ShowConsole(false)

        local save_text = ""
        if luaConsoleWindow and luaConsoleWindow.lcText then
            save_text = luaConsoleWindow.lcText.text
            save_watches = luaConsoleWindow.watches
            save_watchHistory = luaConsoleWindow.watchHistory
            luaConsoleWindow:StopThreads()
            luaConsoleWindow:delete()
        end
        luaConsoleWindow = LuaConsoleWindow:new()
        luaConsoleWindow:LoadSettings()

        if luaConsoleReloaded and luaConsoleWindow and luaConsoleWindow.lcText then
            luaConsoleWindow.lcText.text = save_text
            luaConsoleWindow.watches = save_watches
            luaConsoleWindow.watchHistory = save_watchHistory
            luaConsoleWindow:CreateWatchThread()
            lcPrint("<color 100 255 100>Console reloaded.")
        end
        luaConsoleReloaded = true
        luaConsoleWindow:ExecuteScratchPad()
    end)
end

