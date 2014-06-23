local M = class("FNAnimationSkins")

function M:ctor()
    self.__skins = {}
end

function M:setSkin(skinname, val)
    self.__skins[skinname] = val
end

function M:getSkin(skinname)
    local skin = self.__skins[skinname]
    if type(skin) == "function" then
         print("nil123")
        return skin(skinname)
    end

    return self:getDefaultSkin(skinname)
end

function M:getDefaultSkin(skinname)
    return display.newSprite(skinname)
end

return M