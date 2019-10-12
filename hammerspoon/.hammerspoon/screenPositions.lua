---------------------
-- Screen positioning
---------------------

function moveToScreen(screenPos)
    local window = hs.window.focusedWindow()
    local screen = hs.screen.find({x=screenPos, y=0})
    window:moveToScreen(screen)
    setWindow()
end
