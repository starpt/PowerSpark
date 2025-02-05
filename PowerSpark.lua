local playerClass = select(2, UnitClass('player'))
if playerClass == 'WARRIOR' then return end -- 战士不需要

PowerSparkDB = PowerSparkDB or {
	enabled = true,
	DruidBarFrame = true,
	SUF = true,
	ElvUI = true,
	Statusbars2 = true,
	maxManaHide = true,
	maxEnergyHide = true,
}
local frame = CreateFrame('Frame')

-- 初始化
function frame:init(bar, powerType)
	if not bar then return end
	if not bar.spark then
		bar.spark = bar:CreateTexture(nil, 'OVERLAY')
		bar.spark:SetTexture('Interface\\CastingBar\\UI-CastingBar-Spark')
		bar.spark:SetBlendMode('ADD')
		bar.spark:SetSize(28, 28)
		bar.spark:SetAlpha(.8)
		if powerType then bar.powerType = powerType end
	end

	bar:HookScript('OnUpdate', function(self)
		local now = GetTime()
		if self.rate and now < self.rate then return end
		self.rate = now + .02 --刷新率
		local powerType = self.powerType or UnitPowerType('player')

		if UnitIsDeadOrGhost('player') or
			powerType ~= 0 and powerType ~= 3 or
			not InCombatLockdown() and UnitPower('player', powerType) >= UnitPowerMax('player', powerType) and (
				powerType == 0 and PowerSparkDB.maxManaHide or
				powerType == 3 and not IsStealthed() and not UnitCanAttack('player', 'target') and PowerSparkDB.maxEnergyHide
			) then
			self.spark:Hide()
			return
		end

		local interval = frame.interval or 2 -- 恢复间隔
		if powerType == 0 and type(frame.waitTime) == 'number' and frame.waitTime > now then
			self.spark:Show()
			self.spark:SetPoint('CENTER', self, 'LEFT', self:GetWidth() * (frame.waitTime - now) / 5, 0)
		elseif type(frame.sparkTime) == 'number' and now > frame.sparkTime then
			self.spark:Show()
			self.spark:SetPoint('CENTER', self, 'LEFT', self:GetWidth() * (mod(now - frame.sparkTime, interval) / interval), 0)
		end
	end)
end

for _, event in pairs({
	'PLAYER_ENTERING_WORLD',
	'COMBAT_LOG_EVENT_UNFILTERED',
	'UNIT_POWER_UPDATE',
}) do
	frame:RegisterEvent(event)
end
frame:SetScript('OnEvent', function(self, event, unit, powerType)
	local now = GetTime()
	if event == 'PLAYER_ENTERING_WORLD' then
		if PowerSparkDB.enabled then
			if UnitPowerType('player') == 0 or playerClass == 'DRUID' then -- 法力
				self.lastMana = UnitPower('player', 0)
			end
			if UnitPowerType('player') == 3 then -- 能量
				self.lastEnergy = UnitPower('player', 3)
			end
			self.sparkTime = now

			self:init(PlayerFrameManaBar)
			self:init(PlayerFrameDruidBar) -- 兼容 BiechuUnitFrames 德鲁伊法力条
			if playerClass == 'DRUID' and PowerSparkDB.DruidBarFrame then self:init(DruidBarFrame, 0) end -- 兼容 DruidBarFrame
			if ElvUF_Player and PowerSparkDB.ElvUI then self:init(ElvUF_Player.Power) end -- 兼容 ElvUI
			if PowerSparkDB.Statusbars2 then self:init(StatusBars2_playerPowerBar) end -- 兼容 Statusbars2

			-- 兼容 SUF
			if SUFUnitplayer and PowerSparkDB.SUF then
				self:init(SUFUnitplayer.powerBar)
				if playerClass == 'DRUID' then self:init(SUFUnitplayer.druidBar, 0) end
			end
		end
	elseif event == 'COMBAT_LOG_EVENT_UNFILTERED' then
		local guid = UnitGUID('player')
		local _, subevent, _, sourceGUID, _, _, _, destGUID, _, _, _, spellId = CombatLogGetCurrentEventInfo()
		if destGUID == guid then -- 施法目标自己
			if spellId == 13750 then -- 冲动, 加速能量恢复速度
				if subevent == 'SPELL_AURA_APPLIED' then -- 冲动 开始
					self.interval = 1
				elseif subevent == 'SPELL_AURA_REMOVED' then -- 冲动 结束
					self.interval = nil
				end
			elseif spellId == 29166 then -- 忽视 激活期间 5秒回蓝等待
				if subevent == 'SPELL_AURA_APPLIED' then -- 激活 开始
					self.ignore = true
				elseif subevent == 'SPELL_AURA_REMOVED' then -- 激活 结束
					self.ignore = nil
				end
			elseif subevent == 'SPELL_ENERGIZE' then -- 法力药水恢复 生命分流 跳过
				self.skip = true
			end
		end
	elseif event == 'UNIT_POWER_UPDATE' then
		if unit == 'player' then
			if UnitPowerType('player') == 0 or playerClass == 'DRUID' then -- 法力
				local mana = UnitPower('player', 0)
				if not self.ignore and type(self.lastMana) == 'number' and mana < self.lastMana and mana < UnitPowerMax('player', 0) then
					self.waitTime = now + 5
				elseif type(self.lastMana) == 'number' and mana > self.lastMana then -- 法力增加
					if self.skip then -- 跳过非2秒回蓝, 比如 法力药水 生命分流
						self.skip = nil
					else
						self.sparkTime = now
						self.waitTime = nil
					end
				end
				self.lastMana = mana
			end

			if UnitPowerType('player') == 3 then -- 能量
				local energy = UnitPower('player', 3)
				if type(self.lastEnergy) == 'number' and energy > self.lastEnergy then -- 能量增加
					if self.skip then -- 跳过 如菊花茶
						self.skip = nil
					else
						self.sparkTime = now
					end
				end
				self.lastEnergy = UnitPower('player', 3)
			end
		end
	end
end)
