local class = select(2, UnitClass('player'))
local frame = CreateFrame('Frame')
for _, v in pairs({'PLAYER_ENTERING_WORLD', 'UNIT_SPELLCAST_SUCCEEDED', 'UNIT_MAXPOWER', 'UNIT_POWER_FREQUENT'}) do
	frame:RegisterEvent(v, 'player')
end
if class == 'ROGUE' then frame:RegisterEvent('UNIT_AURA') end
frame:SetScript('OnEvent', function(self, event, ...)
	if event == 'PLAYER_ENTERING_WORLD' then
		function self.cure(key)
			local type = UnitPowerType('player')
			local cure = UnitPower('player', type)
			if key == 'druid' then
				type = 0
				cure = DruidBarKey.currentmana
			end
			return cure, type
		end
		function self.wait(key)
			if UnitPowerType('player') == 0 or key == 'druid' then self[key].wait = GetTime() + 5 end
		end
		function self.rest(key)
			local cure, type = self.cure(key)
			if type == 3 then self[key].wait = nil end
			if cure > self[key].cure then self[key].timer = GetTime() end
			self[key].cure = cure
		end
		function self.init(parent, key) --初始化
			if not parent then return end
			local now = GetTime()
			local type = UnitPowerType('player')
			local power = CreateFrame('StatusBar', nil, parent)
			--print(parent:GetWidth())
			power:SetWidth(PlayerFrameManaBar:GetWidth())
			power:SetHeight(parent:GetHeight())
			power:SetPoint('CENTER')
			power.spark = power:CreateTexture(nil, 'OVERLAY')
			power.spark:SetTexture('Interface\\CastingBar\\UI-CastingBar-Spark')
			power.spark:SetWidth(32)
			power.spark:SetHeight(32)
			power.spark:SetBlendMode('ADD')
			power.spark:SetAlpha(0)
			power.rate = now
			power.cure = UnitPower('player', type)
			power.timer = now
			if key == 'DRUID' then power.cure = DruidBarKey.currentmana end
			power.interval = 2
			power.key = key
			function power.hide(key)
				local cure, type = self.cure(key)
				return UnitIsDeadOrGhost('player') or key == 'default' and type == 1 or type == 0 and cure >= UnitPowerMax('player', 0) or type == 3 and cure >= UnitPowerMax('player') and not IsStealthed() and (not UnitCanAttack('player', 'target') or UnitIsDeadOrGhost('target')) --角色死亡/怒气/满蓝/满能量且不潜行且目标不可攻击
			end
			power:HookScript('OnUpdate', function(self)
				local now = GetTime()
				if now < self.rate then return end
				self.rate = now + 0.03 --刷新率
				if self.hide(self.key) then
					self.spark:SetAlpha(0)
					return
				end
				self.spark:SetAlpha(1)
				if self.wait and self.wait > now then --5秒等待回蓝
					self.spark:SetPoint('CENTER', self, 'LEFT', self:GetWidth() * (self.wait - now) / 5, 0)
				else
					self.spark:SetPoint('CENTER', self, 'LEFT', self:GetWidth() * (mod(now - self.timer, self.interval) / self.interval), 0)
				end
			end)
			self[key] = power
		end
		self.init(PlayerFrameManaBar, 'default')
		if class == 'DRUID' and DruidBarFrame and DruidBarKey then self.init(DruidBarFrame, 'druid') end
	elseif event == 'UNIT_SPELLCAST_SUCCEEDED' then
		self.wait('default')
		if self.druid then self.wait('druid') end
	elseif event =='UNIT_MAXPOWER' or event == 'UNIT_POWER_FREQUENT' then
		self.rest('default')
		if self.druid then self.rest('druid') end
	elseif event == 'UNIT_AURA' then
		self.interval = 2
		local i = 1
		while UnitBuff('player', i) do
			if select(10,UnitBuff('player', i)) == 13750 then --开了冲动
				self.interval = 1
				break
			end
			i = i + 1
		end
	end
end)