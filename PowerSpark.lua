if select(2, UnitClass('player')) == 'WARRIOR' then return end

local PowerSparkFrame = CreateFrame('Frame')
PowerSparkFrame:RegisterEvent('PLAYER_ENTERING_WORLD')
PowerSparkFrame:RegisterEvent('UNIT_POWER_UPDATE')
PowerSparkFrame:SetScript('OnEvent', function(self, event, arg1) PowerSparkFrame:event(self, event, arg1) end)
PowerSparkFrame:SetScript('OnUpdate', function() PowerSparkFrame:update() end)

local PowerSparkDB = {
	default = {
		name = 'PowerSparkFrameManaBar',
		parent = PlayerFrameManaBar
	},
	druid = {
		name = 'PowerSparkFrameDruidManaBar',
		parent = DruidBarFrame,
		enable = select(2, UnitClass('player')) == 'DRUID' and DruidBarFrame and DruidBarKey --小德蓝条启用条件
	}
}

function PowerSparkFrame:event(self, event, arg1)
	if event == 'PLAYER_ENTERING_WORLD' then
		local last
		if select(1, UnitPowerType('player')) == 3 then
			last = UnitPower('player')
		else
			last = UnitPower('player', 0)
		end
		PowerSparkFrame:init(PowerSparkDB.default, last) --默认界面初始化
		if PowerSparkDB.druid.enable then PowerSparkFrame:init(PowerSparkDB.druid, DruidBarKey.currentmana) end --小德界面初始化
	end
	if event == 'UNIT_POWER_UPDATE' and arg1 == 'player' then
		local powerType = select(1, UnitPowerType('player'))
		if powerType == 3 then
			PowerSparkFrame:energy(PowerSparkDB.default)
		elseif powerType == 0 then
			PowerSparkFrame:mana(PowerSparkDB.default, UnitPower('player', 0))
		end
		if PowerSparkDB.druid.enable then
			PowerSparkFrame:mana(PowerSparkDB.druid, DruidBarKey.currentmana)
		end
	end
end

function PowerSparkFrame:update()
	PowerSparkFrame:flash(PowerSparkDB.default)
	if PowerSparkDB.druid.enable then PowerSparkFrame:flash(PowerSparkDB.druid) end
end

function PowerSparkFrame:init(power, last)
	power.bar = CreateFrame('Statusbar', power.name, power.parent)
	power.bar:SetWidth(PlayerFrameManaBar:GetWidth() - 2)
	power.bar:SetHeight(power.parent:GetHeight() - 2)
	power.bar:SetPoint('CENTER')
	power.spark = power.bar:CreateTexture(nil, 'OVERLAY')
	power.spark:SetTexture('Interface\\CastingBar\\UI-CastingBar-Spark')
	power.spark:SetWidth(32)
	power.spark:SetHeight(32)
	power.spark:SetBlendMode('ADD')
	power.spark:SetAlpha(0)
	power.timer = power.timer or GetTime() --定时器
	power.interval = power.interval or 2
	power.last = last
end

function PowerSparkFrame:energy(power) --回能量
	if UnitPower('player') > power.last and UnitPower('player') <= power.last + 20 then --不触发其它加能量方法
		power.timer = GetTime()
		power.interval = 2
	end
	power.last = UnitPower('player')
end

function PowerSparkFrame:mana(power, mp) --回蓝
	if mp < power.last then
		power.timer = GetTime()
		power.interval = 5
	elseif GetTime() >= power.timer + power.interval then
		power.timer = GetTime()
		power.interval = 2
	end
	power.last = mp
end

function PowerSparkFrame:flash(power) --闪动
	local powerType = select(1, UnitPowerType('player'))
	if powerType == 1 and not power.enable then  --熊的怒气槽
		power.bar:Hide()
	elseif powerType == 0 and UnitPower('player', 0) >= UnitPowerMax('player', 0) or power.enable and DruidBarKey.currentmana >= UnitPowerMax('player', 0) then --蓝条满
		power.bar:Hide()
	elseif powerType == 3 and UnitPower('player') >= UnitPowerMax('player') then
		if UnitCanAttack('player', 'target') and not UnitIsDeadOrGhost('target') then --可攻击目标
			power.bar:Show()
		else
			power.bar:Hide()
		end
	else
		power.bar:Show()
	end
	if not power.bar:IsVisible() then return end

	if power.interval > 2 then --5秒等待回蓝
		if power.timer + power.interval > GetTime() then
			power.spark:SetAlpha(.75)
			power.spark:SetPoint('CENTER', power.bar, 'LEFT', power.bar:GetWidth() - power.bar:GetWidth() * (mod(GetTime() - power.timer, power.interval) / power.interval), 0)
		else --5秒后等待恢复
			power.spark:SetAlpha(0)
		end
	else
		power.spark:SetAlpha(.5)
		if power.timer + power.interval > GetTime() then
			power.spark:SetPoint('CENTER', power.bar, 'LEFT', power.bar:GetWidth() * (mod(GetTime() - power.timer, power.interval) / power.interval), 0)
		else --满能量
			power.spark:SetPoint('CENTER', power.bar, 'LEFT', power.bar:GetWidth() * (mod(math.fmod(GetTime() - power.timer, 2), 2) / 2), 0)
		end
	end
end
