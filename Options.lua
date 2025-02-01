local addonName = ...
local option = CreateFrame('Frame', addonName .. 'Option')
local category = Settings.RegisterCanvasLayoutCategory(option, addonName)
Settings.RegisterAddOnCategory(category)

-- 命令行
SlashCmdList[addonName] = function()
	Settings.OpenToCategory(category.ID)
end
_G['SLASH_' .. addonName .. '1'] = '/ps'

local L = {
	comfing = 'Need to reload UI, Reload?',
	info = 'Email: ' .. GetAddOnMetadata(addonName, 'X-eMail'),
	enabled = 'Enabled ' .. addonName,
	maxManaHide = 'Hide when mana is full',
	maxEnergyHide = 'Hide when energy is full',
	DruidBarFrame = 'Show DruidBarFrame addon Druid mana bar',
	SUF = 'Show Shadowed Unit Frames addon Power bar and Druid mana bar',
	ElvUI = 'Show ElvUI addon Power bar',
	Statusbars2 = 'Show Statusbars2 addon Energy bar',
}
if GetLocale() == 'zhCN' then
	L.comfing = '需要重新加载UI才能生效, 是否加载?'
	L.info = 'QQ讨论群: 377298123'
	L.enabled = '启用 ' .. addonName
	L.maxManaHide = '非战斗状态满法力后不显示'
	L.maxEnergyHide = '非战斗状态满能量后, 非隐身/潜行或者无可攻击目标时不显示'
	L.DruidBarFrame = '支持 DruidBarFrame 插件额外德鲁伊法力条'
	L.SUF = '支持 Shadowed Unit Frames 插件能力条和德鲁伊法力条'
	L.Statusbars2 = '支持 Statusbars2 插件能量条'
	L.ElvUI = '支持 ElvUI 插件能力条'
end

-- 确认
function option.comfing()
	local comfing = _G[addonName .. 'Comfing']
	if not comfing then
		comfing = CreateFrame('Frame', addonName .. 'Comfing')
		comfing:Hide()
		comfing:SetPoint('CENTER')
		comfing:SetSize(320, 80)
		comfing:SetScale(.72)
		comfing:SetFrameStrata('TOOLTIP')
		comfing:SetFrameLevel(99)
		comfing:SetScript('OnKeyDown', function(self, key)
			if key == 'ESCAPE' then
				self:Hide()
			end
		end)

		comfing.border = CreateFrame('Frame', nil, comfing, 'DialogBorderOpaqueTemplate')
		comfing.border:SetAllPoints(comfing)
		comfing.text = comfing:CreateFontString(nil, 'ARTWORK', 'GameFontHighlight')
		comfing.text:SetSize(290, 0)
		comfing.text:SetPoint('TOP', 0, -20)
		comfing.text:SetText(L.comfing)

		comfing.accept = CreateFrame('Button', nil, comfing, 'UIPanelButtonTemplate')
		comfing.accept:SetSize(128, 21)
		comfing.accept:SetPoint('BOTTOMLEFT', 26, 16)
		comfing.accept:SetText(OKAY) -- 确认
		comfing.accept:SetScript('OnClick', function()
			ReloadUI()
		end)

		comfing.cancel = CreateFrame('Button', nil, comfing, 'UIPanelButtonTemplate')
		comfing.cancel:SetSize(128, 21)
		comfing.cancel:SetPoint('LEFT', comfing.accept, 'RIGHT', 12, 0)
		comfing.cancel:SetText(CANCEL) -- 取消
		comfing.cancel:SetScript('OnClick', function()
			comfing:Hide()
		end)
	end

	comfing:Show()
end

-- 勾选
function option:check(name, comfing, relative, offsetX, offsetY)
	self[name] = CreateFrame('CheckButton', self:GetName() .. name:gsub('^%l', string.upper), self, 'ChatConfigCheckButtonTemplate')
	self[name]:SetPoint('TOPLEFT', relative and self[relative] or self, offsetX or 0, offsetY or -32)
	_G[self[name]:GetName() .. 'Text']:SetText(L[name])

	self[name]:SetScript('OnClick', function(self)
		PowerSparkDB[name] = self:GetChecked() or nil
		if name == 'enabled' then option:init() end
		if comfing then option.comfing() end
	end)

	hooksecurefunc(self[name], 'SetEnabled', function(self, value)
		if value then
			_G[self:GetName() .. 'Text']:SetTextColor(1, 1, 1)
		else
			_G[self:GetName() .. 'Text']:SetTextColor(.5, .5, .5)
		end
	end)
end

function option:init()
	local playerClass = select(2, UnitClass('player'))
	self.enabled:SetChecked(PowerSparkDB.enabled and playerClass ~= 'WARRIOR')
	self.enabled:SetEnabled(playerClass ~= 'WARRIOR')

	self.maxManaHide:SetChecked(PowerSparkDB.maxManaHide and playerClass ~= 'WARRIOR' and playerClass ~= 'ROGUE')
	self.maxManaHide:SetEnabled(PowerSparkDB.enabled and playerClass ~= 'WARRIOR' and playerClass ~= 'ROGUE')

	self.maxEnergyHide:SetChecked(PowerSparkDB.maxEnergyHide and (playerClass == 'DRUID' or playerClass == 'ROGUE'))
	self.maxEnergyHide:SetEnabled(PowerSparkDB.enabled and (playerClass == 'DRUID' or playerClass == 'ROGUE'))

	self.DruidBarFrame:SetChecked(PowerSparkDB.DruidBarFrame and playerClass == 'DRUID' and DruidBarFrame)
	self.DruidBarFrame:SetEnabled(PowerSparkDB.enabled and playerClass == 'DRUID' and DruidBarFrame)

	self.ElvUI:SetChecked(PowerSparkDB.ElvUI and ElvUF_Player)
	self.ElvUI:SetEnabled(PowerSparkDB.enabled and ElvUF_Player)

	self.Statusbars2:SetChecked(PowerSparkDB.Statusbars2 and StatusBars2_playerPowerBar)
	self.Statusbars2:SetEnabled(PowerSparkDB.enabled and StatusBars2_playerPowerBar)

	self.SUF:SetChecked(PowerSparkDB.SUF and SUFUnitplayer)
	self.SUF:SetEnabled(PowerSparkDB.enabled and SUFUnitplayer)
end
option:SetScript('OnShow', option.init)

option.title = option:CreateFontString(nil, 'ARTWORK', 'GameFontNormalLarge')
option.title:SetPoint('TOPLEFT', 16, -16)
option.title:SetText(addonName .. ' v' .. GetAddOnMetadata(addonName, 'Version'))
option.info = option:CreateFontString(option:GetName() .. 'Info', 'ARTWORK', 'SystemFont_Small')
option.info:SetPoint('TOPLEFT', 17, -36)
option.info:SetTextColor(.7, .7, .7)
option.info:SetText(L.info)

option:check('enabled', true, 'info', -2, -24)
option:check('maxManaHide', nil, 'enabled')
option:check('maxEnergyHide', nil, 'maxManaHide')
option:check('DruidBarFrame', true, 'maxEnergyHide')
option:check('SUF', true, 'DruidBarFrame')
option:check('ElvUI', true, 'SUF')
option:check('Statusbars2', true, 'ElvUI')

option.accept = CreateFrame('Button', nil, option, 'UIPanelButtonTemplate')
option.accept:SetSize(160, 32)
option.accept:SetPoint('BOTTOMLEFT', 16, 16)
option.accept:SetText(RELOADUI)
option.accept:SetScript('OnClick', ReloadUI)
