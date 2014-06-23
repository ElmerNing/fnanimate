local M = class("FNAnimationLayer", function()
        local node = CCAnchorNode:create()
        local peer = {}              
        tolua.setpeer(node , peer )
        return node
    end)

function M:ctor(layerName, layerData, options)
    self.layerName = layerName
    self.layerData = layerData
    self.frameCount = layerData.frameCount
    self.options = options
    self.crtSkin = nil
end

function M:play(idx)

    local playwrap = function()
        --开始播放的帧
        if idx == nil then
            idx = 0
        end

        -- 删除当前所有子节点
        self:removeAllChildrenWithCleanup(true)

        --播放队列
        local keyframes = self.layerData
        local lastKeyframe = nil
        for i, keyframe in ipairs(keyframes) do
            --下一帧 or 哨兵
            local nf = keyframes[i+1] or setmetatable({idx=self.frameCount}, {__index=keyframe})
            if nf.idx >= idx then  
                --当前帧索引
                local crtIdx = lastKeyframe and keyframe.idx or idx     
                --上一帧 or 哨兵
                local lf = lastKeyframe or {skin=nil, idx=-1}
                --执行当前帧的动作 并等待完成
                self:doAction(lf, keyframe, nf, crtIdx)
                --记录上一帧数据
                lastKeyframe = keyframe
            end
        end

        --动画结束回调
        if self.options.finishEventHandler ~= nil then
            self.options.finishEventHandler(self.layerName)
        end
    end

    coroutine.wrap(playwrap)();
end

--[[
function M:pause()
    self:pauseSchedulerAndActions()
end

function M:resume()
    self:resumeSchedulerAndActions()
end
]]

function M:doAction(lastKeyframe, keyframe, nextKeyframe, crtIdx)

    function tween(attr)
        if (not keyframe.tw) or nextKeyframe==nil or nextKeyframe[attr]==nil or crtIdx == keyframe.idx then
            return keyframe[attr]
        end
        return keyframe[attr]+(nextKeyframe[attr]-keyframe[attr])*(crtIdx - keyframe.idx)/(nextKeyframe.idx-keyframe.idx)
    end 

    -- 判断图片是否更换
    local skin = self.crtSkin
    if lastKeyframe.skin ~= keyframe.skin then
        
        --清除上一帧
        if self.crtSkin then
            self.crtSkin:removeFromParentAndCleanup(true)
        end
        
        --加入新skin
        skin = self.options.skins:getSkin(keyframe.skin)
        if skin ~= nil then
            self:setPosition(ccp(tween("x"), tween("y")))
            self:setScaleX(tween("sx"))
            self:setScaleY(tween("sy"))

            local aaa = keyframe.sy+(nextKeyframe.sy-keyframe.sy)*(crtIdx - keyframe.idx)/(nextKeyframe.idx-keyframe.idx)
            print(keyframe.sy)
            print(crtIdx)
            print(nextKeyframe.idx,keyframe.idx)

            self:setRotation(tween("r"))   
            skin:setOpacity(tween("alpha")*2.55)
        else
            --创建一个空的CCNode
            skin = CCNode:create()
        end

        --设置当前皮肤
        self:addChild(skin)
        self.crtSkin = skin 
    end

    --设置属性

    --锚点, 有别与cocos2dx的setAnchorPoint
    self:setAnchorPointInPoints(ccp(keyframe.tx, keyframe.ty))

    --混合模式
    local blendMod = ccBlendFunc:new_local()
    if keyframe.blend == "add" then   
        blendMod.src = GL_ONE
        blendMod.dst = GL_ONE
    else
        blendMod.src = GL_ONE
        blendMod.dst = GL_ONE_MINUS_SRC_ALPHA
    end


    --设置动作

    --没有下一帧了 返回nil
    if  nextKeyframe==nil then
        return
    end

    --持续时间
    local duration = (nextKeyframe.idx - crtIdx) * self.options.interval
    --动作
    local actions = CCArray:create()

    --下一帧不为空白, 并且当前帧需要补间
    if nextKeyframe.skin ~= nil and keyframe.tw then

        --位置
        local nx = nextKeyframe.x
        local ny = nextKeyframe.y
        if keyframe.x ~= nx or keyframe.y ~= ny then
            local action = CCMoveTo:create(duration, ccp(nx, ny))
            actions:addObject(action)
        end

        --旋转
        local nr = nextKeyframe.r
        if keyframe.r ~= nr then
            local action = CCRotateTo:create(duration, nr)
            actions:addObject(action)
        end

        --缩放
        local nsx = nextKeyframe.sx
        local nsy = nextKeyframe.sy
        if keyframe.sx ~= nsx or keyframe.sy ~= nsy then
            local action = CCScaleTo:create(duration, nsx, nsy)
            actions:addObject(action)
        end

        --透明度
        local nalpha = nextKeyframe.alpha
        if keyframe.alpha ~= nalpha then
            skin:runAction(CCFadeTo:create(duration, nalpha*2.55))
        end
    end

    --延迟函数
    local action = CCDelayTime:create(duration)
    actions:addObject(action)
    local spawnAction = CCSpawn:create(actions)
    
    --帧事件
    if keyframe.name ~= "" then
        if self.options.keyframeEventHandler ~= nil then
            self.options.keyframeEventHandler(layerName, keyframe.name)
        end
    end

    --执行action 并等待结束
    do   
        local co = coroutine.running()
        local callback = CCCallFuncN:create(function (  )
              coroutine.resume(co)
        end)
        self:runAction(CCSequence:createWithTwoActions(
             spawnAction, callback))
        coroutine.yield()     
    end
end

return M

