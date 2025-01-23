---------------------
-- Fixed layouts
---------------------
require("windowPositions")

-- Constants
local primary_monitor = hs.screen.primaryScreen()
local right_monitor = hs.screen{x=1,y=0}
local left_monitor = hs.screen{x=-1,y=0}

hs.application.enableSpotlightForNameSearches(true)

function setLayout()
    local layouts = {
        {
            name = {"Sublime Text", "ForkLift"},
            func = function(index, win)
                win:moveToScreen(primary_monitor)
                setWindow("bottomLeft")
            end
        }
    }

    for i, layout in ipairs(layouts) do
        if(type(layout.name) == "table") then
            for i, appName in ipairs(layout.name) do
                local app = hs.application.find(appName)
                hs.alert.show(app:title())
                if (app) then
                    local wins = app:allWindows()
                    local counter = 1
                    for j, win in ipairs(wins) do
                        if (win:isVisible() and layout.func) then
                            layout.func(counter, win)
                            counter = counter + 1
                        end
                    end
                end
            end
        end
    end
end

