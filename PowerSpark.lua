if select(2, UnitClass('player')) == 'WARRIOR' then return end

local PowerFrame = CreateFrame('Frame')
PowerFrame:RegisterEvent('PLAYER_ENTERING_WORLD')
PowerFrame:RegisterEvent('UNIT_POWER_UPDATE')
-- PowerFrame:RegisterEvent('UNIT_SPELLCAST_SUCCEEDED')
PowerFrame:SetScript('OnUpdate', function() PowerFrame:onUpdate() end)
PowerFrame:SetScript('OnEvent', function(self, event, arg1, ...) PowerFrame:onEvent(self, event, arg1, ...) end)

local interval = 0 --间隔
local lastPower = 0 --次能量/法力值
local lastTime = GetTime() --上次时间

local mana = CreateFrame('Statusbar', 'UFP_PowerManaBar', PlayerFrameManaBar)
local spark = mana:CreateTexture(nil, 'OVERLAY')
spark:SetTexture('Interface\\CastingBar\\UI-CastingBar-Spark')
spark:SetWidth(32)
spark:SetHeight(32)
spark:SetBlendMode('ADD')
local druidMana
local druidSpark

function PowerFrame:onEvent(self, event, arg1)
	if event == 'PLAYER_ENTERING_WORLD' then
		lastPower = UnitPower('player', 0)
		PowerFrame:PowerStart(self, event, arg1)
		mana:SetWidth(PlayerFrameManaBar:GetWidth() - 2)
		mana:SetHeight(PlayerFrameManaBar:GetHeight() - 2)
		mana:SetPoint('CENTER')
		if PowerFrame:Druid() then
			druidMana = CreateFrame('Statusbar', 'UFP_PowerManaBar', DruidBarFrame)
			druidMana:SetWidth(PlayerFrameManaBar:GetWidth() - 2)
			druidMana:SetHeight(PlayerFrameManaBar:GetHeight() - 2)
			druidMana:SetPoint('CENTER')
			druidSpark = druidMana:CreateTexture(nil, 'OVERLAY')
			druidSpark:SetTexture('Interface\\CastingBar\\UI-CastingBar-Spark')
			druidSpark:SetWidth(32)
			druidSpark:SetHeight(32)
			druidSpark:SetBlendMode('ADD')
		end
	end
	if event == 'UNIT_POWER_UPDATE' then
		PowerFrame:PowerStart(self, event, arg1)
	end
end

function PowerFrame:onUpdate()
	if select(1, UnitPowerType('player')) == 1 and PowerFrame:Druid() then
		mana:Hide()
		PowerFrame:PowerSpark(druidMana, druidSpark)
	else
		if druidMana then
			druidMana:Hide()
		end
		PowerFrame:PowerSpark(mana, spark)
	end
end

function PowerFrame:PowerStart(self, event, arg1)
	if arg1 == 'player' then
		local powerType = select(1, UnitPowerType('player'))
		if powerType == 0 or powerType == 1 and PowerFrame:Druid() then
			if UnitPower('player', 0) < lastPower then
				PowerFrame:PowerWait()
			elseif GetTime() >= lastTime + interval then
				PowerFrame:PowerReply()
			end
			lastPower = UnitPower('player', 0)
		elseif powerType == 3 then
			if UnitPower('player') > lastPower then
				PowerFrame:PowerReply()
			end
			lastPower = UnitPower('player')
		else
			interval = 0
		end
	end
end

function PowerFrame:PowerReply() --2秒回复
	lastTime = GetTime()
	interval = 2
end

function PowerFrame:PowerWait() --5秒回蓝
	lastTime = GetTime()
	interval = 5
end

function PowerFrame:PowerSpark(mana, spark) --闪动
	local stop
	if select(1, UnitPowerType('player')) == 3 then --能量满
		if UnitPower('player') >= UnitPowerMax('player') then
			stop = false
		end
	elseif PowerFrame:Druid(1) >= UnitPowerMax('player', 0) then
		stop = true
	elseif UnitPower('player', 0) >= UnitPowerMax('player', 0) then --法力满
		stop = true
	end

	if stop or interval <= 0 then
		mana:Hide()
	else
		if select(1, UnitPowerType('player')) == 3 then
			if UnitPower('player') <= UnitPowerMax('player') and interval > 0 then
				mana:Show()

				if lastTime + interval > GetTime() then
					local left = mana:GetWidth() * (mod(GetTime() - lastTime, interval) / interval)

					spark:SetAlpha(.4)
					spark:SetPoint('CENTER', mana, 'LEFT', left, 0)
				else
					lastTime = GetTime()
				end
			end
		else
			if UnitPower('player') < UnitPowerMax('player') and interval > 0 then
				mana:Show()

				if lastTime + interval > GetTime() then
					local left = mana:GetWidth() - mana:GetWidth() * (mod(GetTime() - lastTime, interval) / interval)

					spark:SetAlpha(.7)
					spark:SetPoint('CENTER', mana, 'LEFT', left, 0)
				else
					spark:SetAlpha(0)
				end
			end
		end
	end
end

function PowerFrame:Druid(sort) --有小德蓝条
	local druid = select(2, UnitClass('player')) == 'DRUID' and DruidBarFrame and DruidBarKey
	if sort then
		if druid then
			return DruidBarKey.currentmana or 0
		else
			return 0
		end
	else
		return druid
	end
end
