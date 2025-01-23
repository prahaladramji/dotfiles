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
require("windowPositions")
require("screenPositions")
require("layouts")

-- Modifier sets that I use
modKeys = {"shift", "alt" }

-- Bind hotkeys
hs.hotkey.bind(modKeys, "D", function() setWindow("leftHalf") end)
hs.hotkey.bind(modKeys, "G", function() setWindow("rightHalf") end)
hs.hotkey.bind(modKeys, "R", function() setWindow("topLeft") end)
hs.hotkey.bind(modKeys, "T", function() setWindow("topRight") end)
hs.hotkey.bind(modKeys, "C", function() setWindow("bottomLeft") end)
hs.hotkey.bind(modKeys, "V", function() setWindow("bottomRight") end)
hs.hotkey.bind(modKeys, "Y", function() setWindow("topLarge") end)
hs.hotkey.bind(modKeys, "B", function() setWindow("bottomSmall") end)
hs.hotkey.bind(modKeys, "F", setWindow)

hs.hotkey.bind(modKeys, "E", cycleVertical)
hs.hotkey.bind(modKeys, "X", cycleHorizontal)
hs.hotkey.bind(modKeys, "tab", function() cycleScreens() end)

hs.hotkey.bind(modKeys, "1", function() setLayout() end)

-- Successfully loaded config
hs.alert.show("Config loaded")

