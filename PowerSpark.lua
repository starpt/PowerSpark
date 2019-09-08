if select(2, UnitClass('player')) == 'WARRIOR' then return end


local PowerFrame = CreateFrame('Frame')
PowerFrame:RegisterEvent('PLAYER_ENTERING_WORLD')
PowerFrame:RegisterEvent('UNIT_POWER_UPDATE')
-- PowerFrame:RegisterEvent('UNIT_SPELLCAST_SUCCEEDED')
PowerFrame:SetScript('OnUpdate', function(self, sinceLastUpdate) PowerFrame:onUpdate(sinceLastUpdate); end)
PowerFrame:SetScript('OnEvent', function(self, event, arg1, ...) PowerFrame:onEvent(self, event, arg1, ...) end)


local mana = CreateFrame('Statusbar', 'UFP_PowerManaBar', PlayerFrameManaBar)
local spark = mana:CreateTexture(nil, 'OVERLAY')
spark:SetTexture('Interface\\CastingBar\\UI-CastingBar-Spark')
spark:SetWidth(32)
spark:SetHeight(32)
spark:SetBlendMode('ADD')
spark:SetAlpha(.4)


local interval = 0 --间隔
local lastPower = 0 --次能量/法力值
local lastTime = GetTime() --上次时间
local lastLeft = 0 --上次距离

function PowerFrame:onEvent(self, event, arg1)
	if event == 'PLAYER_ENTERING_WORLD' then
		mana:ClearAllPoints()
		mana:SetWidth(PlayerFrameManaBar:GetWidth() - 2)
		mana:SetHeight(PlayerFrameManaBar:GetHeight() - 2)
		mana:SetPoint("CENTER")
		lastPower = UnitPower('player')
		PowerFrame:PowerStart(self, event, arg1)
	end

	if event == 'UNIT_POWER_UPDATE' then
		PowerFrame:PowerStart(self, event, arg1)
	end
end

function PowerFrame:onUpdate()
	if UnitPower('player') < UnitPowerMax('player') and interval > 0 then
		mana:Show()
		if interval > 2 then
			local left = mana:GetWidth() - mana:GetWidth() * (mod(GetTime() - lastTime, interval) / interval)
			spark:SetAlpha(.8)
			if lastLeft >= left then
				spark:SetPoint('CENTER', mana, 'LEFT', left, 0)
				lastLeft = left
			else
				lastTime = GetTime()
				interval = .5
				lastLeft = 0
			end
		else
			local left = mana:GetWidth() * (mod(GetTime() - lastTime, interval) / interval)
			spark:SetPoint('CENTER', mana, 'LEFT', left, 0)
			spark:SetAlpha(.4)
			interval = 2
			lastLeft = left
		end
	else
		mana:Hide()
	end
end

function PowerFrame:PowerStart(self, event, arg1)
	if arg1 == 'player' then
		local powerType = select(1, UnitPowerType('player'))
		if powerType == 0 then
			if UnitPower('player', 0) < lastPower then
				lastTime = GetTime()
				lastLeft = mana:GetWidth()
				interval = 5
			elseif GetTime() - lastTime > interval then
				lastTime = GetTime()
				lastLeft = 0
				interval = 2
			end
		elseif powerType == 3 then
			if UnitPower('player') > lastPower then
				lastTime = GetTime()
				lastLeft = 0
				interval = 2
			end
		end
		lastPower = UnitPower('player')
	end
end
