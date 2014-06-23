--[[
    FNAnimation 一个可以播放动画的 CCNode
]]

local FNAnimationLayer = import(".FNAnimationLayer")
local FNAnimationSkins = import(".FNAnimationSkins")

local M = class("FNAnimation", function() 
     local node = CCNode:create() 
     local peer = {}              
     tolua.setpeer(node , peer )
     return node
end)

--[[---------------------------------------------------------
    - desc: 创建一个动画
    - params: 
        - animationData: 动画数据
        - options:  一个table 可设置各个选项
            -skins: 皮肤库, 根据皮肤的名字索引皮肤, 皮肤可以是构建函数或者CCSpriteFrame或者CCTexuture2D,
                    如果为索引皮肤为nil, 则默认构造函数创建
            -interval: 间隔, 默认1/60
            -keyframeEventHandler: 帧事件回调, 函数原型 function(layerName, kayframename)
            -finishEventEvent: 动画结束回调,  函数原型 function(layerName)
--]]---------------------------------------------------------
function M:ctor(animationData, options)

    if options == nil then
       options = {} 
    end

    --默认皮肤
    options.skins = options.skins or FNAnimationSkins.new()
    --间隔
    options.interval = options.interval or 1/60
    --layer(参照flash内的概念), 每个layer是执行动画的一个元件
    self.layers = {}
    --总帧数
    self.frameCount = 0

    --初始话layers
    local zorder = 10000
    for layerName, layerData in pairs(animationData) do
        --最大frameCount
        if layerData.frameCount > self.frameCount then
            self.frameCount = layerData.frameCount
        end
        --加入layer
        self.layers[layerName] = FNAnimationLayer.new(layerName, layerData, options)
        self:addChild(self.layers[layerName], zorder)
        zorder = zorder-1
    end

end

function M:play(index)
    for name, layer in pairs(self.layers) do
        layer:play(index)
    end
end

function M:stop()
    for name, layer in pairs(self.layers) do
        layer:stopAllActions()
        layer.crtSkin:stopAllActions()
    end
end

return M

