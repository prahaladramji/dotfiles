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

function cycleVertical()
    local window = hs.window.focusedWindow()
    local frame = window:frame()
    local max = window:screen():frame()

    local placement = {
        left = function (frame, max)
            frame.x = max.x
        end,

        vMid = function (frame, max)
            frame.x = max.x + (max.w / 3)
        end,

        right = function (frame, max)
            frame.x = max.x + (max.w * 2 / 3)
        end,
    }

    if ((frame.w ~= (max.w / 3)) or (frame.x >= max.x + (max.w * 2 / 3))) then
        placement["left"](frame, max)
    elseif ((frame.w == (max.w / 3)) and (frame.x ~= max.x + (max.w / 3))) then
        placement["vMid"](frame, max)
    else
        placement["right"](frame, max)
    end

    -- Set full screen hieght and a thrid screen size
    frame.y = max.y
    frame.w = max.w / 3
    frame.h = max.h
    window:setFrame(frame)
end

function cycleHorizontal()
    local window = hs.window.focusedWindow()
    local frame = window:frame()
    local max = window:screen():frame()

    local placement = {
        top = function (frame, max)
            frame.y = max.y
        end,

        hMid = function (frame, max)
            frame.y = max.y + (max.h / 3)
        end,

        bottom = function (frame, max)
            frame.y = max.y + (max.h * 2 / 3)
        end,
    }

    if ((frame.h ~= math.floor(max.h / 3)) or (frame.y >= max.y + math.floor(max.h * 2 / 3))) then
        placement["top"](frame, max)
    elseif ((frame.h == math.floor(max.h / 3)) and (frame.y ~= max.y + math.floor(max.h / 3))) then
        placement["hMid"](frame, max)
    else
        placement["bottom"](frame, max)
    end

    -- Set full screen width and a thrid screen size
    frame.x = max.x
    frame.w = max.w
    frame.h = max.h / 3
    window:setFrame(frame)
end

