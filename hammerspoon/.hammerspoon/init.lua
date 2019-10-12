----------------
-- Configuration
----------------

-- Make the alerts look nicer.
hs.alert.defaultStyle.strokeColor = {white = 1, alpha = 0}
hs.alert.defaultStyle.fillColor = {white = 0.05, alpha = 0.75}
hs.alert.defaultStyle.radius = 10

-- Disable the slow default window animations.
hs.window.animationDuration = 0

require("configWatcher")

-- Modifier sets that I use
modKeys = {"shift", "alt" }

---------------------
-- Window positioning
---------------------

function setWindow(position)
    local position = position or "maximize"

    local window = hs.window.focusedWindow()
    local frame = window:frame()
    local max = window:screen():frame()

    -- Default maximize
    frame.x = max.x
    frame.y = max.y
    frame.w = max.w
    frame.h = max.h

    local case = {
        leftHalf = function (frame, max)
            frame.w = max.w / 2
        end,

        rightHalf = function (frame, max)
            frame.x = max.x + (max.w / 2)
            frame.w = max.w / 2
        end,

        topLeft = function (frame, max)
            frame.w = max.w / 2
            frame.h = max.h / 2
        end,

        topRight = function (frame, max)
            frame.x = max.x + (max.w / 2)
            frame.w = max.w / 2
            frame.h = max.h / 2
        end,

        bottomLeft = function (frame, max)
            frame.y = max.y + (max.h / 2)
            frame.w = max.w / 2
            frame.h = max.h / 2
        end,

        bottomRight = function (frame, max)
            frame.x = max.x + (max.w / 2)
            frame.y = max.y + (max.h / 2)
            frame.w = max.w / 2
            frame.h = max.h / 2
        end,

        topLarge = function (frame, max)
            frame.h = max.h * 2 / 3
        end,

        bottomSmall = function (frame, max)
            frame.y = max.y + (max.h * 2 / 3)
            frame.h = max.h / 3
        end,
    }

    if case[position] then
        case[position](frame, max)
    end

    window:setFrame(frame)
end

function moveToScreen(screenPos)
    local window = hs.window.focusedWindow()
    local screen = hs.screen.find({x=screenPos, y=0})
    window:moveToScreen(screen)
    setWindow()
end

hs.hotkey.bind(modKeys, "D", function() setWindow("leftHalf") end)
hs.hotkey.bind(modKeys, "G", function() setWindow("rightHalf") end)
hs.hotkey.bind(modKeys, "R", function() setWindow("topLeft") end)
hs.hotkey.bind(modKeys, "T", function() setWindow("topRight") end)
hs.hotkey.bind(modKeys, "C", function() setWindow("bottomLeft") end)
hs.hotkey.bind(modKeys, "V", function() setWindow("bottomRight") end)
hs.hotkey.bind(modKeys, "Y", function() setWindow("topLarge") end)
hs.hotkey.bind(modKeys, "B", function() setWindow("bottomSmall") end)
hs.hotkey.bind(modKeys, "F", setWindow)

hs.hotkey.bind(modKeys, "1", function() moveToScreen(0) end)
hs.hotkey.bind(modKeys, "2", function() moveToScreen(1) end)
hs.hotkey.bind(modKeys, "3", function() moveToScreen(2) end)

hs.alert.show("Config loaded")
