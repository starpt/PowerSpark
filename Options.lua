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
	comfing = 'Need to Reload UI!',
	info = 'Email: ' .. GetAddOnMetadata(addonName, 'X-eMail'),
	enabled = 'Enabled ' .. addonName,
	maxManaHide = 'Hide when mana is full',
	maxEnergyHide = 'Hide when energy is full',
	DruidBarFrame = 'Show DruidBarFrame addon Druid mana bar',
	SUF = 'Show Shadowed Unit Frames addon Power bar and Druid mana bar',
	ElvUI = 'Show ElvUI addon Power bar',
	Statusbars2 = 'Show Statusbars2 addon Energy bar',
	ReloadUI = 'Reload UI',
}
if GetLocale() == 'zhCN' then
	L.comfing = '需要重新加载UI才能生效!'
	L.info = 'QQ讨论群: 377298123'
	L.enabled = '启用 ' .. addonName
	L.maxManaHide = '非战斗状态满法力后不显示'
	L.maxEnergyHide = '非战斗状态满能量后, 非隐身/潜行或者无可攻击目标时不显示'
	L.DruidBarFrame = '支持 DruidBarFrame 插件额外德鲁伊法力条'
	L.SUF = '支持 Shadowed Unit Frames 插件能力条和德鲁伊法力条'
	L.Statusbars2 = '支持 Statusbars2 插件能量条'
	L.ElvUI = '支持 ElvUI 插件能力条'
	L.ReloadUI = '重新加载UI'
end
if GetLocale() == 'ruRU' then
	L.comfing = 'Требуется перезагрузка интерфейса для применения изменений!'
	L.info = 'Электронная почта: ' .. GetAddOnMetadata(addonName, 'X-eMail')
	L.enabled = 'Включено ' .. addonName
	L.maxManaHide = 'Скрывать вне боя при полной мане'
	L.maxEnergyHide = 'Скрывать вне боя при полной энергии, если не в скрытности/подкрадывании или нет цели для атаки'
	L.DruidBarFrame = 'Поддержка дополнительной полосы маны друида из аддона DruidBarFrame'
	L.SUF = 'Поддержка полосы энергии и полосы маны друида из аддона Shadowed Unit Frames'
	L.Statusbars2 = 'Поддержка полосы энергии из аддона Statusbars2'
	L.ElvUI = 'Поддержка полосы энергии из аддона ElvUI'
	L.ReloadUI = 'Перезагрузить интерфейс'
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

option:RegisterEvent('VARIABLES_LOADED')
option:SetScript('OnEvent', function(self, event)
	if event == 'VARIABLES_LOADED' then self:init() end
end)

-- 勾选
function option:check(name, relative, offsetX, offsetY)
	self[name] = CreateFrame('CheckButton', self:GetName() .. name:gsub('^%l', string.upper), self, 'ChatConfigCheckButtonTemplate')
	self[name]:SetPoint('TOPLEFT', relative and self[relative] or self, offsetX or 0, offsetY or -32)
	_G[self[name]:GetName() .. 'Text']:SetText(L[name])

	self[name]:SetScript('OnClick', function(self)
		PowerSparkDB[name] = self:GetChecked() or nil
		if name == 'enabled' then option:init() end
		if name ~= 'maxManaHide' and name ~= 'maxEnergyHide' then
			print('|cffffff00'.. addonName .. ': ' .. L.comfing .. '|r')
		end
	end)

	hooksecurefunc(self[name], 'SetEnabled', function(self, value)
		if value then
			_G[self:GetName() .. 'Text']:SetTextColor(1, 1, 1)
		else
			_G[self:GetName() .. 'Text']:SetTextColor(.5, .5, .5)
		end
	end)
end

option.title = option:CreateFontString(nil, 'ARTWORK', 'GameFontNormalLarge')
option.title:SetPoint('TOPLEFT', 16, -16)
option.title:SetText(addonName .. ' v' .. GetAddOnMetadata(addonName, 'Version'))
option.info = option:CreateFontString(option:GetName() .. 'Info', 'ARTWORK', 'SystemFont_Small')
option.info:SetPoint('TOPLEFT', 17, -36)
option.info:SetTextColor(.7, .7, .7)
option.info:SetText(L.info)

option:check('enabled', 'info', -2, -24)
option:check('maxManaHide', 'enabled')
option:check('maxEnergyHide', 'maxManaHide')
option:check('DruidBarFrame', 'maxEnergyHide')
option:check('SUF', 'DruidBarFrame')
option:check('ElvUI', 'SUF')
option:check('Statusbars2', 'ElvUI')

option.accept = CreateFrame('Button', nil, option, 'UIPanelButtonTemplate')
option.accept:SetSize(160, 32)
option.accept:SetPoint('BOTTOMLEFT', 16, 16)
option.accept:SetText(L.ReloadUI)
option.accept:SetScript('OnClick', ReloadUI)
