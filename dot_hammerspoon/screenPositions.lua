---------------------
-- Screen positioning
---------------------

function cycleScreens()
    local window = hs.window.focusedWindow()
    local currentScreen = window:screen()

    window:moveToScreen(currentScreen:next(), ensureInScreenBounds)
end

