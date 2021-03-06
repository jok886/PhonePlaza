-- Oxqkbnew
--获取使用kernel类函数
local ClientKernel = require("common.ClientKernel")--外部公共库kernel
local GameKernel   = import("..Kernel.GameKernel")--内部公共库kernel
local oxui     = import("..Kernel.oxui")--辅助ui
local GameUser     = import("..View.Player")--玩家管理
local CardControl  = import("..View.CardControl")--用户牌管理
--local HeapCard     = import("..View.HeapCard")--牌堆管理
local PokerCard = import("..Kernel.PokerCard")
local GameLogic = import("..Kernel.GameLogic")--主逻辑

local settingUI = import("..View.SettingView")--主逻辑
local talkUI = import("..View.TalkWidget")--主逻辑

--声明游戏场景类
local Oxqkbnew  = class("Oxqkbnew", function() return display.newScene("Oxqkbnew")end)

local MAX_TIME = 10
local CMD_C_CallBanker = {}
local CMD_C_AddScore = {}
local CMD_C_CHANGE_CARD = {}
local CMD_C_OxCard = {}
--本类的构造函数
function Oxqkbnew:ctor(args)
    display.addSpriteFrames("oxqkbnew/UIGameIng.plist","oxqkbnew/UIGameIng.png")
    display.addSpriteFrames("oxqkbnew/talkWidgetPlist.plist","oxqkbnew/talkWidgetPlist.png")
    display.addSpriteFrames("oxqkbnew/settingWidgetPlist.plist","oxqkbnew/settingWidgetPlist.png")
    self.App=AppBaseInstanse.OxqkbnewApp
    self:setNodeEventEnabled(true)
    self.gameState = OxqkbnewDefine.SUB_S_GAME_START
    self.wBankerUser = nil
    self.handCardControl = {}
    self.timerCount = 0
    self.t_Start = nil
    self.t_Bander = nil
    self.t_AddSource = nil
    self.t_Change = nil
    self.t_Open = nil
    self.totalScoure = 0
    
    --创建gamekernel
    if args.gameClient then
        self.gameClient = args.gameClient
        self.ClientKernel = ClientKernel.new(self.gameClient,self.App.EventCenter)
        --声明conmand对象
        self.m_GameKernel=GameKernel.new(self.ClientKernel)

    end
    --设置游戏属性
    local gameAttribute =
        {
            wKindID=OxqkbnewDefine.KIND_ID,
            wPlayerCount=OxqkbnewDefine.GAME_PLAYER,
            dwClientVersion=OxqkbnewDefine.VERSION_CLIENT,
            pszGameName=OxqkbnewDefine.GAME_NAME,
        }
    self.m_GameKernel:getClientKernel():SetGameAttribute(gameAttribute)

    print("注册事件管理")
    self:RegistEventManager() --注册事件管理
    print("注册事件管理结束")
    self:InitUnits()          --加载资源
    self:FreeAllData()        --初始化数据
    self:ButtonMsg()          --控件消息


end

--初始化数据
function Oxqkbnew:FreeAllData()
    --首发牌用户
    self.HandCardCount={0,0}
    for i=1, OxqkbnewDefine.GAME_PLAYER do
        self.handCardControl[i]:FreeControl()
    end

    local xspac = 200
    local yspac = 200
    local xx = display.cx + 200
    local xj = display.cx - 200
    self.handCardPos=
        {
            cc.p(display.cx-80,display.height -180),--1号位置 对家
            cc.p(xx-40,display.height -220),--2号位置 对家
            cc.p(xx +40,275),--3号位置 对家
            cc.p(display.cx-300,120),--4号位置 对家
            cc.p(xj-190,275),--5号位置 对家
            cc.p(xj-100,display.height -220),--6号位置 对家
        }
    self.isopen = false
    self.wBankerUser = nil
    self.bUserOxCard = {}
    self.lTurnMaxScore = 0
    self.lUserMaxScore = {}
    self.pokerCards = {}
    self.pokerCount = 0
    self.wWinUser = 0 --记录上次赢得玩家
    self.lTotalScore=nil
    self.lTableScore=nil
    self.cbPlayStatus = {} --所有玩家状态
    self.wViewChairID = {} --对应视图位置
    self.bUserOxCard = {}
    self.bShowSocre = {}
    self.bWaitAdd = true
    self.bAutoOpenCard = true
    self.wWaitCallIndex = 0
    self.wDispatchCardIndex = 0
    self.bRiffleCard = false
    self.wDispatchCardIndex = 0
    self.countindex = 0
    self.isChange = true
    self.ismoveDisPach = true
    --记录叫庄的人状态
    self.isBankers = {}
    
    self.BankerView:hide()
    self.addSourceView:hide() 
    self.openView:hide()
    self.m_GameUser:FreeAllBanders()
    self.m_GameUser:FreeAllAddSouce()
end
--加载资源
function Oxqkbnew:InitUnits()

    --读取json 文件
    local node = oxui.getUIByName("oxqkbnew/oxqkbLayer.json")
    self.node  = node 
    --node:setContentSize(display.width,display.height)
    node:addTo(self)
    self.btnStart=oxui.getNodeByName(node,"btnStart")
    --退出按钮
    self.btnLeave=oxui.getNodeByName(node,"btnLeave")
    --提示按钮
    --self.btnTip=oxui.getNodeByName(node,"btnTip")
    --托管按钮
    self.btnTrust=oxui.getNodeByName(node,"btnTrust")
    self.btnTrust:hide()
    --设置按钮
    self.btnSetting=oxui.getNodeByName(node,"btnSetting")
    --任务按钮
    self.btnChangeDesk=oxui.getNodeByName(node,"btnChangeDesk")
    self.btnChangeDesk:show()
    --任务按钮
    self.clock=oxui.getNodeByName(node,"clock")
    --时间
    self.lbltime=oxui.getNodeByName(node,"time")
    --名称
    self.lab=oxui.getNodeByName(node,"lab")
    --名称
    self.BankerView=oxui.getNodeByName(node,"BankerView")
    self.btnBanker=oxui.getNodeByName(self.BankerView,"btnBanker")
    self.btnBankerCancel=oxui.getNodeByName(self.BankerView,"btnBankerCancel")
    --加分
    self.addSourceView=oxui.getNodeByName(node,"addSourceView")
    --分数1
    self.btnAdd1=oxui.getNodeByName(self.addSourceView,"btnAdd1")

    self.lblnum1 = oxui.getNodeByName(self.btnAdd1,"num")
    --分数1
    self.btnAdd2=oxui.getNodeByName(self.addSourceView,"btnAdd2")
    self.lblnum2 = oxui.getNodeByName(self.btnAdd2,"num")
    --分数1
    self.btnAdd3=oxui.getNodeByName(self.addSourceView,"btnAdd3")
    self.lblnum3 = oxui.getNodeByName(self.btnAdd3,"num")
    --分数1
    self.btnAdd4=oxui.getNodeByName(self.addSourceView,"btnAdd4")
    self.lblnum4 = oxui.getNodeByName(self.btnAdd4,"num")

    --开牌视图
    self.openView=oxui.getNodeByName(node,"openView")
    self.btnOpen=oxui.getNodeByName(self.openView,"btnOpen")
    self.btnTip=oxui.getNodeByName(self.openView,"btnTip") 

    self.btnChat = oxui.getNodeByName(node,"btnChat")
    
    self.Totalay=oxui.getNodeByName(node,"Totalay")
    self.TotaScoure=oxui.getNodeByName(self.Totalay,"TotaScoure")
    --声明Player对象
    self.m_GameUser=GameUser.new(node,self.m_GameKernel)
    --加载牌的资源
    ccs.ArmatureDataManager:getInstance():addArmatureFileInfo("Common/AnimationCard.ExportJson")

    -- --牌堆位置
    self.HeapPos=cc.p(display.cx,display.cy)
    --用户手牌的位置

    --初始化牌堆
    self:InitHeapCard()
    --初始化手牌
    self:InitHandCardControl()
    
    require("plazacenter.widgets.GameHornMsgWidget").new(self)
end
--初始化牌堆
function Oxqkbnew:InitHeapCard()
    --发牌张数
    self.DispatchCount={0,0}

    for i=1,OxqkbnewDefine.GAME_PLAYER do
        table.insert(self.handCardControl,CardControl.new())
    end

    local xspac = 200
    local yspac = 200
    local xx = display.cx + 200
    local xj = display.cx - 200

    self.handCardPos=
        {
            cc.p(display.cx-80,display.height -180),--1号位置 对家
            cc.p(xx-40,display.height -220),--2号位置 对家
            cc.p(xx +40,275),--3号位置 对家
            cc.p(display.cx-300,120),--4号位置 对家
            cc.p(xj-190,275),--5号位置 对家
            cc.p(xj-100,display.height -220),--6号位置 对家
        }
    --用户手牌的间距
    self.handCardDistance=
        {
            22,--0号位置 对家
            22,--0号位置 对家
            22,--0号位置 对家
            100,--1号位置 对家
            22,--0号位置 对家
            22,--0号位置 对家

        }
    --用户手牌的大小
    self.handCardScal=
        {
            0.6,--1号位置 对家
            0.6,--2号位置 对家
            0.6,--3号位置 对家
            0.8,--4号位置 对家
            0.6,--5号位置 对家
            0.6,--6号位置 对家
        }
end
--初始化手牌
function Oxqkbnew:InitHandCardControl()
    for i=1, OxqkbnewDefine.GAME_PLAYER do
        self.handCardControl[i]:SetStartPos(self.handCardPos[i])
        self.handCardControl[i]:SetDistance(self.handCardDistance[i])
        --self.handCardControl[i]:SetScal(self.handCardScal[i])
        self.handCardControl[i]:addTo(self.node)
        --self.handCardControl[i]:zorder(100)
        if i == OxqkbnewDefine.MYSELF_VIEW_ID then
            self.handCardControl[i]:SetShow(true)
            self.handCardControl[i]:SetCardTouchEnabled(true)
        else
            self.handCardControl[i]:SetShow(false)
            self.handCardControl[i]:SetCardTouchEnabled(false)
        end
    end
end

--开始发牌
function Oxqkbnew:StartDisPachCard()
    --发牌张数
    self:stopAllTimer()
    self.dispatchCardCount=0
    self.HandCardCount={0,0}
    if self.ismoveDisPach then
        self.ismoveDisPach = false
        self:moveDisPachCard()
    end
    
end

function Oxqkbnew:DisPatchOneCardEnd(evt)
    oxui.playSound("SEND_CARD",false,OxqkbnewDefine.wav)
    self.pokerCount = self.pokerCount - 1
    if self.pokerCount == 0 then
        self:OnSendCardFinish()
    end
end

--控件消息
function Oxqkbnew:ButtonMsg()
    -------------------------------------------------
    --开始按钮事件
    -------------------------------------------------
    self.btnStart:onButtonClicked(function ()
        self.m_GameKernel:StartGame()
        if self:IsNotLookonMode() then
            self:stopAllTimer()
        end
        self.btnStart:hide()
    end)
    --开始按钮按下
    self.btnStart:onButtonPressed(function ()
        self:playScaleAnimation(true,self.btnStart)
    end)

    --开始按钮抬起
    self.btnStart:onButtonRelease(function ()
        self:playScaleAnimation(false,self.btnStart)
    end)
    -------------------------------------------------
    --离开按钮事件
    -------------------------------------------------
    self.btnLeave:onButtonClicked(function ()
        --self:stopTimer()
        self:Exit()
    end)
    --离开按钮按下
    self.btnLeave:onButtonPressed(function ()
        self:playScaleAnimation(true,self.btnLeave)
    end)

    --离开按钮抬起
    self.btnLeave:onButtonRelease(function ()
        self:playScaleAnimation(false,self.btnLeave)
    end)


    self.btnChat:onButtonClicked(function ()
        dump("提示")
        if not  self.isChat then
            self.isChat = true
            self.chatView = talkUI.new(self.ClientKernel)
            self.chatView:setPosition(cc.p(display.width - 408,56))
            self:addChild(self.chatView)
        else
            self.isChat= false
            self.chatView:removeFromParent()
            self.chatView= nil
        end

    end)
    --提示按钮按下
    self.btnChat:onButtonPressed(function ()
        self:playScaleAnimation(true,self.btnChat)

    end)

    --离开按钮抬起
    self.btnChat:onButtonRelease(function ()
        self:playScaleAnimation(false,self.btnChat)
    end)
    -------------------------------------------------
    --托管按钮事件
    -------------------------------------------------

    self.btnTrust:onButtonClicked(function ()
        dump("提示")

    end)
    --托管按钮按下
    self.btnTrust:onButtonPressed(function ()
        self:playScaleAnimation(true,self.btnTrust)
    end)

    --托管按钮抬起
    self.btnTrust:onButtonRelease(function ()
        self:playScaleAnimation(false,self.btnTrust)
    end)
    --------------------------------------------------
    --托管按钮事件
    -------------------------------------------------
    self.btnTrust:onButtonClicked(function ()
        dump("托管按钮事件")

    end)
    --托管按钮按下
    self.btnTrust:onButtonPressed(function ()
        self:playScaleAnimation(true,self.btnTrust)
    end)

    --托管按钮抬起
    self.btnTrust:onButtonRelease(function ()
        self:playScaleAnimation(false,self.btnTrust)
    end)
    
    -------------------------------------------------
    --换桌按钮事件
    -------------------------------------------------

    self.btnChangeDesk:onButtonClicked(function ()
        self:FreeAllData()
        self.ClientKernel:quickChangeTable()
    end)
    --托管按钮按下
    self.btnChangeDesk:onButtonPressed(function ()
        self:playScaleAnimation(true,self.btnChangeDesk)
    end)

    --托管按钮抬起
    self.btnChangeDesk:onButtonRelease(function ()
        self:playScaleAnimation(false,self.btnChangeDesk)
    end)

    --------------------------------------------------
    --设置按钮事件
    -------------------------------------------------
    self.btnSetting:onButtonClicked(function ()
        dump("设置按钮事件")
        local settingView = settingUI.new()
        settingView:setPosition(cc.p(display.cx,display.cy))
        self:addChild(settingView)
    end)
    --设置按钮按下
    self.btnSetting:onButtonPressed(function ()
        self:playScaleAnimation(true,self.btnSetting)
    end)

    --设置按钮抬起
    self.btnSetting:onButtonRelease(function ()
        self:playScaleAnimation(false,self.btnSetting)
    end)
  
    --------------------------------------------------
    --
    self.btnBanker:onButtonClicked(function ()
        print("叫庄确定")
        self:stopAllTimer()
        CMD_C_CallBanker.bBanker =  1 
        self:send(OxqkbnewDefine.SUB_C_CALL_BANKER,CMD_C_CallBanker ,"CMD_C_CallBanker")
        self.BankerView:hide()
        self.clock:hide()
    end)

    self.btnBankerCancel:onButtonClicked(function ()
        print("叫庄取消")
        CMD_C_CallBanker.bBanker = 0
        self:send(OxqkbnewDefine.SUB_C_CALL_BANKER,CMD_C_CallBanker ,"CMD_C_CallBanker")
        self.BankerView:hide()
    end)

    self.btnAdd1:onButtonClicked(function ()
        self:sendAddSource(1)
        self.addSourceView:hide()
    end)

    self.btnAdd2:onButtonClicked(function ()
        self:sendAddSource(2)
        self.addSourceView:hide()
    end)

    self.btnAdd3:onButtonClicked(function ()
        self:sendAddSource(3)
        self.addSourceView:hide()
    end)

    self.btnAdd4:onButtonClicked(function ()
        self:sendAddSource(4)
        self.addSourceView:hide()
    end)
 
 
    self.btnOpen:onButtonClicked(function ()
        --if self.open == false then
        self:sendOpenMsg()
        self.openView:hide()
        --end
    end)

    self.btnTip:onButtonClicked(function ()
        local cardData = self.cbHandCardData[self:GetMeChairID()+1]
        local bCardValue = GameLogic:GetCardType2(cardData,OxqkbnewDefine.MAXCOUNT,cardData)
        if bCardValue > 0 then
            self.handCardControl[OxqkbnewDefine.MYSELF_VIEW_ID]:SetShootOXOpoker()
        else
            self.openView:hide()
            self:SetAnimCard(OxqkbnewDefine.MYSELF_VIEW_ID,0)
            local bOX = 0
            CMD_C_OxCard = {bOX = bOX}
            self:send(OxqkbnewDefine.SUB_C_OPEN_CARD,CMD_C_OxCard ,"CMD_C_OxCard")
        end
    end) 

    self.btnOpen:onButtonPressed(function ()
        self:playScaleAnimation(true,self.btnOpen)
    end)

    --设置按钮抬起
    self.btnOpen:onButtonRelease(function ()
        self:playScaleAnimation(false,self.btnOpen)
    end)

    self.btnTip:onButtonPressed(function ()
        self:playScaleAnimation(true,self.btnTip)
    end)

    --设置按钮抬起
    self.btnTip:onButtonRelease(function ()
        self:playScaleAnimation(false,self.btnTip)
    end)
end

function Oxqkbnew:sendChangeMsgNo()
    CMD_C_CHANGE_CARD = {bChange = 0,wPlayer =self:GetMeChairID(),cbChangeCard = 0}
    self:send(OxqkbnewDefine.SUB_C_CHANGE_CARD,CMD_C_CHANGE_CARD ,"CMD_C_ChangeCard")
    --self.changeView:hide()
end

function Oxqkbnew:sendOpenMsg()
    local cardData = self.cbHandCardData[self:GetMeChairID()+1]
    local bOX = 0
    if GameLogic:GetOxCard(cardData,OxqkbnewDefine.MAXCOUNT) then
        bOX = 1
    else
        self.openView:hide()
    end

    CMD_C_OxCard = {bOX = bOX}
    self:send(OxqkbnewDefine.SUB_C_OPEN_CARD,CMD_C_OxCard ,"CMD_C_OxCard")
end

function Oxqkbnew:sendAddSource(index)
    print("addSouceindex" .. index)
    dump(self.lUserMaxScore)
    CMD_C_AddScore.lScore = self.lUserMaxScore[index]
    self:send(OxqkbnewDefine.SUB_C_ADD_SCORE,CMD_C_AddScore ,"CMD_C_AddScore")
end



---------------[[以下是接收游戏服务端消息处理]]--------------
--场景
function Oxqkbnew:OnGameScenceMsg(evt)
    print("场景====++++++++++++++++++++++++++++++++++")
    dump(evt.para)
    local unResolvedData = evt.para.unResolvedData
    local param = evt.para
    local gameStatus = self.ClientKernel.cbGameStatus

    if gameStatus == OxqkbnewDefine.GS_TK_FREE then
        print("空闲状态")
        local statusInfo = self.ClientKernel:ParseStruct(unResolvedData.dataPtr,unResolvedData.size,"CMD_S_StatusFree")

        if self:getMyStatus() == US_SIT and self:getMyStatus() ~= US_PLAYING then
            local lCellScore = statusInfo.lCellScore
            if not self.t_Start then
                self.gameState = OxqkbnewDefine.GS_TK_FREE
                self.timerCount = 10
                self.t_Start = oxui.schedule(function()self:updateState() end,OxqkbnewDefine.TIME_INTERVAL,OxqkbnewDefine.TIME_USER_START_GAME)
            end

            self.btnStart:show() 
        end
        --叫庄状态
    elseif gameStatus == OxqkbnewDefine.GS_TK_CALL then

        local statusInfo = self.ClientKernel:ParseStruct(unResolvedData.dataPtr,unResolvedData.size,"CMD_S_StatusCall")
        self.btnStart:hide() 
        local mycbPlayStatus = statusInfo.cbPlayStatus
        local m_wBankerUser=statusInfo.wBankerUser
        self.wBankerUser = m_wBankerUser
        print("  游戏开始中-------000-----叫庄状态 ")
        dump(statusInfo) 
        --更新状态
        for i=0,OxqkbnewDefine.GAME_PLAYER - 1 do
            self.wViewChairID[i] = self.m_GameKernel:SwitchViewChairID(i)
            self:setUserPlayingStatus(i,mycbPlayStatus[i+1])
        end
        --设置筹码

        if(self:IsNotLookonMode() and m_wBankerUser==self:GetMeChairID()) then
            self.BankerView:show()
        end

        if m_wBankerUser == self:GetMeChairID() then
            if not self.t_Bander then
                self:stopAllTimer()
                self.gameState = OxqkbnewDefine.SUB_S_CALL_BANKER
                self.timerCount = OxqkbnewDefine.TIME_USER_CALL_BANKER
                self.t_Bander = oxui.schedule(function()
                    self:updateState()
                end ,
                OxqkbnewDefine.TIME_INTERVAL,
                OxqkbnewDefine.TIME_USER_CALL_BANKER)
            end
        else
            if not self.t_Bander then
                self:stopAllTimer()
                self.gameState = OxqkbnewDefine.SUB_S_CALL_OTH
                self.timerCount = OxqkbnewDefine.TIME_USER_CALL_BANKER
                self.t_Bander = oxui.schedule(function()
                    self:updateState()
                end ,
                OxqkbnewDefine.TIME_INTERVAL,
                OxqkbnewDefine.TIME_USER_CALL_BANKER)
            end
        end
        --加注状态
    elseif gameStatus == OxqkbnewDefine.GS_TK_SCORE then
        local statusInfo = self.ClientKernel:ParseStruct(unResolvedData.dataPtr,unResolvedData.size,"CMD_S_StatusScore")
        dump(statusInfo)
        print("下注-------000-----状态")
        local lTurnMaxScore = statusInfo.lTurnMaxScore
        local m_wBankerUser = statusInfo.wBankerUser
        local m_lTableScore = statusInfo.lTableScore
        local mycbPlayStatus = statusInfo.cbPlayStatus
        self.btnStart:hide() 
        --更新状态
        for i=0,OxqkbnewDefine.GAME_PLAYER -1 do
            self.wViewChairID[i] = self.m_GameKernel:SwitchViewChairID(i)
            self:setUserPlayingStatus(i,mycbPlayStatus[i + 1])

            if m_lTableScore[i+1]>0 then
                self:setUserTableScore(self.wViewChairID[i],m_lTableScore[i+1])
            end
        end
        --设置庄家
        self.m_GameUser:setBander(self.wViewChairID[m_wBankerUser])
        self.gameState = OxqkbnewDefine.SUB_S_ADD_SCORE
        if not self.t_Change then
            self:stopAllTimer()
            self.timerCount = OxqkbnewDefine.TIME_USER_ADD_SCORE
            self.t_Change = oxui.schedule(function()
                self:updateState()
            end ,
            OxqkbnewDefine.TIME_INTERVAL,
            OxqkbnewDefine.TIME_USER_ADD_SCORE)
        end
        self.wBankerUser = m_wBankerUser
        dump(self.cbPlayStatus)

        --加注状态
    elseif gameStatus == OxqkbnewDefine.GS_TK_PLAYING then
        local statusInfo = self.ClientKernel:ParseStruct(unResolvedData.dataPtr,unResolvedData.size,"CMD_S_StatusPlay")
        print("游戏-------000-----进行")
        dump(statusInfo)
        self.btnStart:hide() 
        self.lTurnMaxScore=statusInfo.lTurnMaxScore
        local wBankerUser=statusInfo.wBankerUser
        self.wBankerUser = wBankerUser
        local mycbPlayStatus = statusInfo.cbPlayStatus
        local m_lTableScore = statusInfo.lTableScore
        --更新状态
        for i=0,OxqkbnewDefine.GAME_PLAYER - 1 do
            self.wViewChairID[i] = self.m_GameKernel:SwitchViewChairID(i)
            self:setUserPlayingStatus(i,mycbPlayStatus[i+1])

            if m_lTableScore[i+1]>0 then
                self:setUserTableScore(self.wViewChairID[i],m_lTableScore[i+1])
            end
        end
        self.m_GameUser:setBander(self.wViewChairID[wBankerUser])
       -- self:OnSubGameStart(evt)
        self.gameState = OxqkbnewDefine.TIME_USER_OPEN_ING
        if not self.t_Open then
            self:stopAllTimer()
            self.timerCount = OxqkbnewDefine.TIME_USER_OPEN_ING
            self.t_Open = oxui.schedule(function()
                self:updateState()
            end ,
            OxqkbnewDefine.TIME_INTERVAL,
            OxqkbnewDefine.TIME_USER_OPEN_ING)
        end
    end

end

--退出
function Oxqkbnew:Exit()
    if self:getMyStatus() == US_PLAYING then
        local dataMsgBox =
            {
                nodeParent=self,
                msgboxType=MSGBOX_TYPE_OKCANCEL,
                msgInfo="您当前正在游戏中，退出将会受到惩罚，是否确定退出？",
                callBack=function(ret)
                    if ret == MSGBOX_RETURN_OK then
                        oxui.removeAll()
                        self.m_GameUser:LeaveType()
                    end
                end
            }
        local msgbox=require("plazacenter.widgets.CommonMsgBoxWidget").new(dataMsgBox)
        --msgbox:zoder(self,10000)

    else
        oxui.removeAll()
        self.m_GameUser:LeaveType()
    end
end

function Oxqkbnew:OnSubPlayerOpen(evt)
    print("所有玩家都开完牌")
    self:stopAllTimer()
    local pPlayerOpen = evt.para 
    if self.ismoveDisPach then
        self.ismoveDisPach = false
        self:moveDisPachCard()
    end
    self.gameState = OxqkbnewDefine.TIME_USER_OPEN_ING
    if not self.t_Open then
        self:stopAllTimer()
        self.timerCount = OxqkbnewDefine.TIME_USER_OPEN_ING
        self.t_Open = oxui.schedule(function()
            self:updateState()
        end ,
        OxqkbnewDefine.TIME_INTERVAL,
        OxqkbnewDefine.TIME_USER_OPEN_ING)
    end

    local index = 1
    local t = 1 
    local banker =  self.wBankerUser or 0
    
    for i=OxqkbnewDefine.GAME_PLAYER + banker - 1,banker ,-1 do  
        local w = i%OxqkbnewDefine.GAME_PLAYER 
        if self.cbPlayStatus[w]==OxqkbnewDefine.USEX_PLAYING and w ~= self:GetMeChairID() then
            local wViewChairID =  self.wViewChairID[ w] 
            if self.cbHandCardData and self.cbHandCardData[w+1] then
                self.handCardControl[wViewChairID]:SetCardData(self.cbHandCardData[w+1],OxqkbnewDefine.MAXCOUNT)
                local time = cc.DelayTime:create(t)
                t = t+0.7
                index = index + 1
                local fuc = cc.CallFunc:create(function()
                    self.handCardControl[wViewChairID]:SetShow(true)
                    if self.cbHandCardData[w+1] then
                        local num = GameLogic:GetCardType2(self.cbHandCardData[w+1],OxqkbnewDefine.MAXCOUNT)
                        if num > 0 then
                            self:onOxEnable(false,w+1)
                        end
                        print("11111111111111111111111111111111111111111111111122222222")
                        self:SetAnimCard(wViewChairID,num)
                    end 
                end )
                self:runAction(cc.Sequence:create(time,fuc))
            end
        else
            self.openView:hide()
        end
    end
    local d = cc.DelayTime:create(t)
    local c = cc.CallFunc:create(function()
        self:stopAllTimer()
        
        if not self:IsNotLookonMode() then
            return
        end
        dump("发送开牌结束命令")
        self:send(OxqkbnewDefine.SUB_C_OPEN_END)
    end )
    self:runAction(cc.Sequence:create(d,c))
end
--游戏结束
function Oxqkbnew:OnSubGameOver(evt)
    local pGameEnd = evt.para
    dump("游戏结束")
    self.wWinUser = pGameEnd.wWinUser or 0
    self.cbHandCardData = {}

    self:stopAllTimer()
    
    function callFuck()
    	local v = self:getChildByName("AnimationWin")
        if v then
            v:removeFromParent()
        end
        local v = self:getChildByName("AnimationLose")
        if v then
            v:removeFromParent()
        end
        
        self.gameState = OxqkbnewDefine.GS_TK_FREE
        if not self.t_Start then
            self.timerCount = OxqkbnewDefine.TIME_USER_START_GAME
            self.t_Start = oxui.schedule(function(t) self:updateState(OxqkbnewDefine.TIME_USER_START_GAME - t) end ,OxqkbnewDefine.TIME_INTERVAL,OxqkbnewDefine.TIME_USER_START_GAME)
        end
        
        self.btnStart:show()
    end
    
    --播放音乐和显示动画 胜负
    if self:IsNotLookonMode() then
        --dump( pGameEnd.lGameScore)
        if pGameEnd.lGameScore[self:GetMeChairID()+1] > 0 then
            oxui.playSound("GAME_WIN",false,OxqkbnewDefine.m4a)
            local armature = oxui.playAnimation(self,1000,"AnimationGameEnd",0,false)
            armature:setName("AnimationWin")
            armature:setPosition(display.cx,display.cy)
            local ani = armature:getAnimation() 
            ani:setMovementEventCallFunc(
             function() callFuck() end )
        else
            oxui.playSound("GAME_LOST",false,OxqkbnewDefine.m4a)
            local armature = oxui.playAnimation(self,1000,"AnimationGameEnd",1,false)
            armature:setName("AnimationLose")
            armature:setPosition(display.cx,display.cy)
            local ani = armature:getAnimation()
            ani:setMovementEventCallFunc( 
                 function() 
                  callFuck() 
                  end 
            )
        end
    else
        self.gameState = OxqkbnewDefine.GS_TK_FREE
        if not self.t_Start then
            self.timerCount = OxqkbnewDefine.TIME_USER_START_GAME
            self.t_Start = oxui.schedule(function(t) self:updateState(OxqkbnewDefine.TIME_USER_START_GAME - t) end ,OxqkbnewDefine.TIME_INTERVAL,OxqkbnewDefine.TIME_USER_START_GAME)
        end
        self.btnStart:show()
    end
    
   
    --设置积分
    for  i=1,OxqkbnewDefine.GAME_PLAYER do
        local souce = pGameEnd.lGameScore[i]
        if self.cbPlayStatus[i-1]==OxqkbnewDefine.USEX_PLAYING then
            if souce >= 0 then
                self.m_GameUser:ShowScore(self.wViewChairID[i-1],souce,true)
            else
                self.m_GameUser:ShowScore(self.wViewChairID[i-1],souce,false)
            end
        end
    end
    self.totalScoure = self.totalScoure + pGameEnd.lGameScore[self:GetMeChairID()+1]
    self.TotaScoure:setString(oxui.BMString(self.totalScoure))
  
    self:FreeAllData()
   
end

function Oxqkbnew:stopAllTimer()
    self.clock:hide()
    --print("self.gamestage".. self.gameState)
    if self.t_Start then
        oxui.stop(self.t_Start)
        self.t_Start = nil
    end

    if self.t_Bander then
        oxui.stop(self.t_Bander)
        self.t_Bander = nil
    end

    if self.t_AddSource then
        oxui.stop(self.t_AddSource)
        self.t_AddSource = nil
    end

    if self.t_Change then
        oxui.stop(self.t_Change)
        self.t_Change = nil
    end

    if self.t_Open then
        oxui.stop(self.t_Open)
        self.t_Open = nil
    end
end


--游戏开始
function Oxqkbnew:OnSubGameStart(evt)
    print("游戏开始")
    local user = evt.para
    dump(user)
    self.lTurnMaxScore=user.lTurnMaxScore
    self.wBankerUser=user.wBankerUser 

    if self:IsNotLookonMode() and  self.lTurnMaxScore > 0 and user.wBankerUser ~= self:GetMeChairID() and self.cbPlayStatus[self.wBankerUser] == OxqkbnewDefine.USEX_PLAYING then
        self.bWaitAdd=true

        self.addSourceView:show()
        self:updateAddSourceView(true)
        self.BankerView:hide()
        print("进入加注")
    else
        print("开始游戏不满足")
    end
    oxui.playSound("GAME_START",false,OxqkbnewDefine.m4a)
    if self.clock:isVisible() then
        self:stopAllTimer()
    end

    if not self.t_AddSource then
        self.gameState = OxqkbnewDefine.SUB_S_ADD_SCORE
        print("加分")
        self.timerCount = OxqkbnewDefine.TIME_USER_ADD_SCORE
        self.t_AddSource = oxui.schedule(function () self:updateState()end ,OxqkbnewDefine.TIME_INTERVAL,OxqkbnewDefine.TIME_USER_ADD_SCORE)
    end
    
--    if table.getn(self.isBankers) > 1 then
--    	self.isBankers
--    end
    
    if user.wBankerUser then
        local ViewID=self.m_GameKernel:SwitchViewChairID(user.wBankerUser)
        self.m_GameUser:setBander(ViewID)
    end
end

--加注结果
function Oxqkbnew:OnSubAddScore(evt)
    print("加注结果11111")
    local p = evt.para -- lAddScoreCount --加注数目
    local ViewID=self.m_GameKernel:SwitchViewChairID(p.wAddScoreUser)
    print("ViewID 。。 " .. ViewID)
    if ViewID == OxqkbnewDefine.MYSELF_VIEW_ID and self:IsNotLookonMode() then
        self.addSourceView:hide()
        print("加注时器")
    end

    local wAddScoreUser=p.wAddScoreUser
    local wViewChairID=self.wViewChairID[wAddScoreUser]
    self:setUserTableScore(ViewID,p.lAddScoreCount)
    if self.cbPlayStatus[p.wAddScoreUser]==OxqkbnewDefine.USEX_PLAYING then
        self:OnUserAddScore(wViewChairID,p.lAddScoreCount,false)
    end
    print("加注数目"  .. p.lAddScoreCount )
    oxui.playSound("ADD_SCORE" ,false, OxqkbnewDefine.wav)
end

function Oxqkbnew:OnUserAddScore(id)
--移动筹码
--m_GoldMove.SetAddScore(wChairID,lTableScore,m_JetonStartPos[wChairID]);
end
--加注显示
function Oxqkbnew:updateAddScore(scrs)

end
--用户强退
function Oxqkbnew:OnSubPlayerExit(evt)
    print("用户强退1111")
    --dump(evt.para);
end
--发牌消息
function Oxqkbnew:OnSubSendCard(evt)
    print("发牌消息111")
    local pSendCard = evt.para
    local wMeChiarID=self:GetMeChairID()
    local wViewChairID=self.wViewChairID[wMeChiarID] 
    local mycbPlayStatus = pSendCard.cbPlayStatus   
    --更新状态
    for i=0,OxqkbnewDefine.GAME_PLAYER - 1 do
        self.wViewChairID[i] = self.m_GameKernel:SwitchViewChairID(i)
        self:setUserPlayingStatus(i,mycbPlayStatus[i+1])
    end
    
    self.MeCard = pSendCard.cbCardData
    self:dealCardRes(self.MeCard)
end



--用户叫庄
function Oxqkbnew:OnSubCallBanker(evt)
    local p = evt.para 
    --dump(p)
    --print("p.wCallBanker = ".. p.wCallBanker)
    
    local isbander = p.bFirstTimes
    
    if p.bFirstTimes > 1 then
    	self.isBankers[p.wCallBanker] = p.bFirstTimes
    end
    
end
--发送基数
function Oxqkbnew:OnSubGameBase(evt)
    print("发送基数111")
    --dump(evt.para);
end 
--摊牌
function Oxqkbnew:OnSubOpenCard(evt)
    print("所有人换牌完成 摊牌")
    local pPlayerOpen = evt.para
    dump(pPlayerOpen.cbCardData)
    local data = pPlayerOpen.cbCardData
    if pPlayerOpen.cbCardData then
        self:fntCardData(data)
    end
    
    local wChairID= self:GetMeChairID()

    if self:IsNotLookonMode() then 
        self.handCardControl[OxqkbnewDefine.MYSELF_VIEW_ID]:SetShow(true,5)
    end
    local wViewChairID = self.wViewChairID[wChairID]
    if not self.t_Open then
        self:stopAllTimer()
        self.gameState = OxqkbnewDefine.SUB_S_CHANGE_OPEN
        self.timerCount = OxqkbnewDefine.TIME_USER_OPEN_CARD
        self.t_Open = oxui.schedule(function()
            self:updateState()
        end ,
        OxqkbnewDefine.TIME_INTERVAL,
        OxqkbnewDefine.TIME_USER_OPEN_CARD)
    end

    if self.cbHandCardData[wChairID+1] and self.cbHandCardData[wChairID+1][1] >0 then
        local bCardType = GameLogic:GetCardType2(self.cbHandCardData[wChairID+1],OxqkbnewDefine.MAXCOUNT)
        if bCardType >= OxqkbnewDefine.OX_THREE_SAME then

            CMD_C_OxCard = {bOX = 1}
            self:send(OxqkbnewDefine.SUB_C_OPEN_CARD,CMD_C_OxCard ,"CMD_C_OxCard")
 
            self.handCardControl[wViewChairID]:SetPositively(false); 

            --保存牛信息
            self.bUserOxCard[wChairID]=true
        end
    end
 
    if(self.cbPlayStatus[wChairID]==OxqkbnewDefine.USEX_PLAYING) then
        self.openView:show()
        self.handCardControl[OxqkbnewDefine.MYSELF_VIEW_ID]:SetCardData(self.cbHandCardData[wChairID+1])
        self.handCardControl[OxqkbnewDefine.MYSELF_VIEW_ID]:SetShow(true,5)
    end

end

function Oxqkbnew:OnSubEndOpen(evt)
    print("开牌")
    local p = evt.para
    --dump(evt)
    local wChairID = self:GetMeChairID()
    local myViewID = self.wViewChairID[wChairID]
    local wID=p.wPlayerID
    if not self:IsNotLookonMode() then
        return
    end
    if self:IsCurrentUser(wID) then
        self.handCardControl[myViewID]:SetCardTouchEnabled(false)
        oxui.playSound("OPEN_CARD",false,OxqkbnewDefine.wav)
    end

    if not self.isopen and wID == self:GetMeChairID() then

        local cardData = self.cbHandCardData[self:GetMeChairID()+1]
        print("self:GetMeChairID()+1 = " .. self:GetMeChairID()+1)
        dump(cardData)
        local bCardValue = GameLogic:GetCardType2(cardData,OxqkbnewDefine.MAXCOUNT,cardData)
        if bCardValue > 0 then
            self:SetAnimCard(OxqkbnewDefine.MYSELF_VIEW_ID,bCardValue)
            self:onOxEnable(true,wID+1)
        else
            self:SetAnimCard(OxqkbnewDefine.MYSELF_VIEW_ID,0) 
        end
        self.isopen = true
    end
end

function Oxqkbnew:SetAnimCard(wViewChairID,number)
    print("wViewChairID= %d, number= %d",wViewChairID,number)

    --local armature
    if not self.handCardControl[wViewChairID]:getChildByName("AnimationOxType") then
        local armature = oxui.playAnimation(self.handCardControl[wViewChairID],200,"AnimationOxType",number,false)
        armature:setName("AnimationOxType")
        armature:setScale(0.6)
        if  number and number > 0 then
            armature:setColor(cc.c3b(223,214,1,255))
        end

        local posx
        if wViewChairID == OxqkbnewDefine.MYSELF_VIEW_ID then
            posx = self.handCardPos[wViewChairID].x - 180
        else
            posx = self.handCardPos[wViewChairID].x -60
        end

        local posy = self.handCardPos[wViewChairID].y - 20
        armature:setPosition(posx,posy)
    end


    if number then
        oxui.playSound("ox" .. number,false,OxqkbnewDefine.m4a)
    end

    if number == 0 and wViewChairID == OxqkbnewDefine.MYSELF_VIEW_ID then
        self.handCardControl[OxqkbnewDefine.MYSELF_VIEW_ID]:setUnSelected()
    end


end
--场景进入
function Oxqkbnew:onEnter()
    SoundManager:playMusicBackground(oxui.ogg .. "ox_backbround.m4a", true)
    
    local game = (0 ~= bit._and(self.ClientKernel.serverAttribute.dwServerRule, SR_FORFEND_GAME_CHAT))
    local room = (0 ~= bit._and(self.ClientKernel.serverAttribute.dwServerRule, SR_FORFEND_ROOM_CHAT))
    if game or room then
        self.btnChat:hide()
    else
        self.btnChat:show()
    end
end
--场景销毁
function Oxqkbnew:onExit()
    print("退出了") 
    SoundManager:stopMusicBackground()   
    self.ClientKernel:removeListenersByTable(self.GameeventHandles) 
end
function Oxqkbnew:onCleanup()
    print("场景销毁") 
    oxui.removeArmatureFileInfo("AnimationBeginGame")
    oxui.removeArmatureFileInfo("AnimationGameEnd")
    oxui.removeArmatureFileInfo("AnimationOxType")
    ccs.ArmatureDataManager:destroyInstance()
    display.removeSpriteFramesWithFile("oxqkbnew/UIGameIng.plist","oxqkbnew/UIGameIng.png")
    display.removeSpriteFramesWithFile("oxqkbnew/talkWidgetPlist.plist","oxqkbnew/talkWidgetPlist.png")
    display.removeSpriteFramesWithFile("oxqkbnew/settingWidgetPlist.plist","oxqkbnew/settingWidgetPlist.png")
    display.removeSpriteFrameByImageName("oxqkbnew/u_game_table.jpg") 
    display.removeSpriteFrameByImageName("oxqkbnew/bg_kqqz_logo.png") 
    self.m_GameUser:OnFreeInterface()
    self.m_GameKernel:OnFreeInterface()
    self.ClientKernel:cleanup()
end
--事件管理
function Oxqkbnew:RegistEventManager()

    --游戏类操作消息
    local eventListeners = eventListeners or {}
    eventListeners[OxqkbnewDefine.GAME_SCENCE] = handler(self, self.OnGameScenceMsg)-- 场景的消息
    eventListeners[OxqkbnewDefine.GAME_START] = handler(self, self.OnSubGameStart)  -- 游戏开始
    eventListeners[OxqkbnewDefine.GAME_ADD_SCORE] = handler(self, self.OnSubAddScore)-- 加注结果
    eventListeners[OxqkbnewDefine.GAME_PLAYER_EXIT] = handler(self, self.OnSubPlayerExit)-- 玩家退出
    eventListeners[OxqkbnewDefine.GAME_SEND_CARD] = handler(self, self.OnSubSendCard) -- 发牌消息
    eventListeners[OxqkbnewDefine.GAME_CALL_BANKER] = handler(self, self.OnSubCallBanker)--用户叫庄
    eventListeners[OxqkbnewDefine.GAME_BASE] = handler(self, self.OnSubGameBase)--发送基数
    --eventListeners[OxqkbnewDefine.GAME_CHANGE_CARD] = handler(self, self.OnSubChangeCard)--换牌
    eventListeners[OxqkbnewDefine.GAME_USER_OPEN_CAED] = handler(self, self.OnSubOpenCard)--开牌
    eventListeners[OxqkbnewDefine.GAME_OPEN_CARD] = handler(self, self.OnSubEndOpen)
    eventListeners[OxqkbnewDefine.GAME_PLAYER_OPEN] = handler(self, self.OnSubPlayerOpen)

    --eventListeners["GF_USER_CHAT"] = handler(self, self.ChatCallBack)
    eventListeners[OxqkbnewDefine.GAME_OVER] = handler(self, self.OnSubGameOver) --结束
    self.GameeventHandles = self.ClientKernel:addEventListenersByTable( eventListeners )
end 

--定义按钮缩放动画函数
function Oxqkbnew:playScaleAnimation(less, pSender)
    local  scale = less and 0.9 or 1
    pSender:runAction(cc.ScaleTo:create(0.2,scale))
end

function Oxqkbnew:updateState()
    self.timerCount = self.timerCount - 1
    --self.lbltime:setString(self.timerCount)
    self.clock:show()
    if  self.timerCount <= 0 then
        if self.gameState == OxqkbnewDefine.GS_TK_FREE and self:getMyStatus() ~= US_READY then
            self.m_GameUser:LeaveType()
        end 

        if self.gameState == OxqkbnewDefine.SUB_S_CHANGE_OPEN then
            self:sendOpenMsg()
        end
        self:stopAllTimer()
        return
    end

    if self.gameState == OxqkbnewDefine.GS_TK_FREE then
        self.lab:setString("等待玩家准备:" ..  self.timerCount)
    elseif self.gameState == OxqkbnewDefine.SUB_S_CALL_BANKER then
        self.lab:setString("叫庄:" ..  self.timerCount)
    elseif self.gameState == OxqkbnewDefine.SUB_S_ADD_SCORE then
        self.lab:setString("等待他人加注:" ..  self.timerCount) 
    elseif self.gameState == OxqkbnewDefine.SUB_S_CHANGE_OPEN then
        self.lab:setString("等待他人开牌:" ..  self.timerCount)
    elseif self.gameState == OxqkbnewDefine.SUB_S_CALL_OTH then
        self.lab:setString("等待他人叫庄:" ..  self.timerCount) 
    elseif self.gameState == OxqkbnewDefine.TIME_USER_OPEN_ING then
        self.lab:setString("开牌:" ..  self.timerCount)

    end
end

function Oxqkbnew:resetGameView()
    --更新玩家试图
    self.m_GameUser:resetGameView()
    self.wBankerUser = nil
    self.lTurnMaxScore = 0 -- 下注分数
    self.timer = nil
end

function Oxqkbnew:setUserPlayingStatus(wChairID,statu)
    print("wChairID" .. wChairID)
    if wChairID <= OxqkbnewDefine.GAME_PLAYER then
        self.cbPlayStatus[wChairID]=statu
    else
        print("设置状态出错了 。。 " .. wChairID)
    end
    
    --dump(self.cbPlayStatus)
end

function Oxqkbnew:ShowScore(wChairID,isshow)
    self.bShowSocre[wChairID]=isshow
    self:refreshGameView()
end

function Oxqkbnew:updateAddSourceView(ishow)
    self.lUserMaxScore = {}
    local souce = self.lTurnMaxScore
    for i=1,4 do
        self.lUserMaxScore[i]= math.floor(souce)
        souce = souce / 2
    end
    for i=1, 4 do
        self["lblnum" .. i]:setString(self.lUserMaxScore[i])
        self["btnAdd" .. i]:show()
        if not ishow then
            self["btnAdd" .. i]:hide()
        end
    end
end

function Oxqkbnew:setUserTableScore(wViewChairID,lAddScoreCount)
    self.m_GameUser:SetaddScouce(wViewChairID,lAddScoreCount)
end

function Oxqkbnew:resetGameView()
    self.pokerCards  = {}
end

function Oxqkbnew:fntCardData(para)
    local data = para
    --dump(data)
    self.cbHandCardData = {}
    local ix = 1
    local  iy = 1
    for key, var in ipairs(data) do
        if not self.cbHandCardData[ix] then
            self.cbHandCardData[ix] = {}
        end

        self.cbHandCardData[ix][iy] = var

        if key % OxqkbnewDefine.MAXCOUNT == 0 then
            ix = ix + 1
            iy = 1
        else
            iy = iy + 1
        end
    end
    --dump(self.cbHandCardData)
end
function Oxqkbnew:dealCardRes(data)
    local index = 1
    self:fntCardData(data)
    self:StartDisPachCard()
end

function Oxqkbnew:dispatchUserCard(wChairID,cbCardData)
    local wViewChairID=self.wViewChairID[wChairID]
    local poker
    if wChairID == self:GetMeChairID() then
        poker = self.handCardControl[wViewChairID]:AddOneCard(cbCardData,true)
        self.handCardControl[wViewChairID]:SetCardTouchEnabled(true)
    else
        poker = self.handCardControl[wViewChairID]:AddOneCard(cbCardData,false)
    end
    self.pokerCount = self.pokerCount + 1
    return poker
end

function Oxqkbnew:moveDisPachCard()
    
    print("移动卡牌")
    dump(self.cbPlayStatus)
    local winUser = self.wWinUser or 0
    local index = 0
    for j=winUser ,winUser + OxqkbnewDefine.GAME_PLAYER -1 do
        local w= j%OxqkbnewDefine.GAME_PLAYER
        local wViewChairID = self.wViewChairID[w]
        if self.cbPlayStatus[w] == OxqkbnewDefine.USEX_PLAYING then
            for i=1,OxqkbnewDefine.MAXCOUNT do
                local poker
                if wViewChairID == OxqkbnewDefine.MYSELF_VIEW_ID then
                    print("ww.. " .. w)
                    if self.cbHandCardData[w+1][i] ~= 0 then
                        poker = self:dispatchUserCard(w,self.cbHandCardData[w+1][i])
                    else
                        poker = self:dispatchUserCard(w,1)
                    end
                else
                    poker = self:dispatchUserCard(w,1)
                end
                local DelyTime=0.05*index

                --oxui.schedule(function ()
                local posStart = self.HeapPos
                local posEnd = self.handCardPos[wViewChairID]
                posEnd.x= posEnd.x + self.handCardDistance[wViewChairID]
                --决定牌大小
                local Scale=self.handCardScal[wViewChairID]

                local args=
                    {
                        startPos=posStart , --起始位置
                        endPos =posEnd,     --结束位置
                        delay=DelyTime,
                        scal=Scale,
                        moveEndHandler= handler(self,self.DisPatchOneCardEnd),--结束回调处理
                    } 
                poker:doCardAnimation(args) 

                index = index + 1
            end
        end
    end
end


--发牌完成
function Oxqkbnew:OnSendCardFinish()
    local wMeChairID=self:GetMeChairID()
    if self:IsNotLookonMode()then
        --self.changeView:show()
        self.handCardControl[OxqkbnewDefine.MYSELF_VIEW_ID]:SetShow(true,3)
        self.BankerView:show()
        if not self.t_Bander then
            self:stopAllTimer()
            self.gameState = OxqkbnewDefine.SUB_S_CALL_BANKER
            self.timerCount = OxqkbnewDefine.TIME_USER_CALL_BANKER
            self.t_Bander = oxui.schedule(function()
                self:updateState()
            end ,
            OxqkbnewDefine.TIME_INTERVAL,
            OxqkbnewDefine.TIME_USER_CALL_BANKER)
        end
    end
    
end

function Oxqkbnew:IsNotLookonMode()
    local state
    if self:getMyStatus() == US_PLAYING then
        --dump(self:getMyStatus())
        state = true
    else
        state = false
    end
    return state
end

function Oxqkbnew:getMyStatus()
    return self.m_GameUser.myHero.cbUserStatus
end

function Oxqkbnew:GetMeChairID()
    return self.m_GameUser.myHero.wChairID
end

function Oxqkbnew:IsCurrentUser(wCurrentUser)
    if self:IsNotLookonMode() and  wCurrentUser == self:GetMeChairID() then
        return true
    end
    return false
end

function Oxqkbnew:send(type,data,name)
    self.ClientKernel:requestCommand(MDM_GF_GAME,type,data ,name)
end


function Oxqkbnew:onOxEnable(isShoot,wchairid)
    local cbCardData = self.cbHandCardData[wchairid]
    --    else
    --        cbCardData = self.cbHandCardData[self:GetMeChairID()+1]
    --    end
    local shoot= isShoot
    local myControl = self.handCardControl[self.wViewChairID[wchairid-1]]
    --    dump(self.cbHandCardData)
    --    print("wchairid =="..wchairid)
    --    dump(cbCardData)
    local newData = GameLogic:sortCardRes(cbCardData,OxqkbnewDefine.MAXCOUNT)
    myControl:SetCardData(newData)
    myControl:SetShow(true)
    
    if shoot then
      
        myControl:SetShootOX()
    end
end

-- type
-- 0 开始下注
-- 1 是白色云
-- 2 是红色云
-- 3是小手
function Oxqkbnew:addAnimChangeView(type,isLoop)
--    local loop = isLoop
--    if not loop or isLoop == false then
--        loop = false
--    else
--        loop = true
--    end
--
--    local t = type
--    if not t  then
--        t= 3
--    end
--
--    local armature = oxui.playAnimation(self.changeTouchView,200,"AnimationGameIng",t,loop)
--    armature:setName("AnimationGameIng")
--    armature:setPosition(110,90)
--
--    if t == OxqkbnewDefine.animHead then
--        local r = cc.RotateBy:create(10,3600)
--        self.light:runAction(r)
--    end
end


return Oxqkbnew