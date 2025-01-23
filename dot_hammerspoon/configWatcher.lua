---------------------
-- Watch for changes in config files
---------------------

function reloadConfig(files)
    local doReload = false
    for _,file in pairs(files) do
    	if file:sub(-4) == ".lua" then
        	doReload = true
    	end
    end
    if doReload then
        hs.reload()
    end
end

configFilesWatcher = hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", reloadConfig):start()
initFileWatcher = hs.pathwatcher.new(os.getenv("HOME") .. "/dotfiles/hammerspoon/.hammerspoon/", reloadConfig):start()

