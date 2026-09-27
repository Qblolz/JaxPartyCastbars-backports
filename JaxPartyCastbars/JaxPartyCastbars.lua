JaxPartyCastBars = LibStub("AceAddon-3.0"):NewAddon("JaxPartyCastBars", "AceEvent-3.0", "AceHook-3.0", "AceConsole-3.0")

local defaults = {
	profile = {
		offsetY = 0,
		offsetX = 210,
		scale = 0.7,
		attachPointBar = "CENTER",
		attachPointFrame = "CENTER",
	}
}

function JaxPartyCastBars:OnInitialize()
	JaxPartyCastBars.db = LibStub("AceDB-3.0"):New("jpcbDB", defaults, true)
	self:SetupOptions()
end

local JPC = CreateFrame("Frame", "JPC", UIParent)
local GetNumPartyMembers = GetNumGroupMembers
local usingRaidFrames = tonumber(GetCVar("useCompactPartyFrames"))
local spellBars = {}
local InArena = function() return (select(2, IsInInstance()) == "arena") end

local function HookSortFunction()
	if CompactRaidFrameContainer_SetFlowSortFunction and not JPC.sortHooked then
		JPC.sortHooked = true
		hooksecurefunc("CompactRaidFrameContainer_SetFlowSortFunction", function()
			JPC:UpdateBars()
		end)
	end
end

function JPC:UpdateBars()
	local raidFramesOn = tonumber(GetCVar("useCompactPartyFrames"))
	for k, sp in ipairs(spellBars) do
		sp:SetScale(JaxPartyCastBars.db.profile.scale)
		if (GetNumPartyMembers() > k) then
			sp:ClearAllPoints()
			if (raidFramesOn == 1) or (UnitInRaid("player") and not InArena()) then
				local keepGroups = CompactRaidFrameManager_GetSetting and CompactRaidFrameManager_GetSetting("KeepGroupsTogether")
				for g = 1, GetNumPartyMembers(), 1 do
					local raidFrame = nil
					if keepGroups then
						if UnitInRaid("player") then
							raidFrame = _G["CompactRaidGroup1Member"..g]
						else
							raidFrame = _G["CompactPartyFrameMember"..g]
						end
					else
						raidFrame = _G["CompactRaidFrame"..g]
					end
					if raidFrame and raidFrame.unit and UnitIsUnit(raidFrame.unit, "party"..k) then
						sp:SetParent(raidFrame)
						sp:SetPoint(JaxPartyCastBars.db.profile.attachPointFrame, raidFrame, JaxPartyCastBars.db.profile.attachPointBar, JaxPartyCastBars.db.profile.offsetX, JaxPartyCastBars.db.profile.offsetY)
					end
				end
			else
				local partyFrame = _G["PartyMemberFrame"..k]
				if partyFrame and partyFrame.unit and UnitIsUnit(partyFrame.unit, "party"..k) then
					sp:SetParent(partyFrame)
					sp:SetPoint(JaxPartyCastBars.db.profile.attachPointFrame, partyFrame, JaxPartyCastBars.db.profile.attachPointBar, JaxPartyCastBars.db.profile.offsetX, JaxPartyCastBars.db.profile.offsetY)
				end
			end
		end
	end
end

function JPC:GROUP_ROSTER_UPDATE()
	JPC:UpdateBars()
end

function JPC:ADDON_LOADED(addonName)
	if addonName == "Blizzard_CompactRaidFrames" then
		HookSortFunction()
		JPC:UpdateBars()
	end
end

local updateElapsed = 0
local function JPC_OnUpdate(self, elapsed)
	updateElapsed = updateElapsed + (elapsed or 0)
	if updateElapsed < 1 then
		return
	end
	updateElapsed = 0

	if usingRaidFrames ~= tonumber(GetCVar("useCompactPartyFrames")) then
		usingRaidFrames = tonumber(GetCVar("useCompactPartyFrames"))
		self:UpdateBars()
	end
end

local function SetCastBarUnit(bar, unit)
	bar.unit = unit
	bar:RegisterUnitEvent("UNIT_SPELLCAST_START", unit)
	bar:RegisterUnitEvent("UNIT_SPELLCAST_STOP", unit)
	bar:RegisterUnitEvent("UNIT_SPELLCAST_FAILED", unit)
end

local function JPC_OnLoad(self)
	JPC.locked = true
	self:RegisterEvent("GROUP_ROSTER_UPDATE")
	self:RegisterEvent("ADDON_LOADED")
	self:SetScript("OnEvent", function(self, event, ...) if self[event] then self[event](self, ...) end end)

	for i = 1, 5 do
		local spellbar = CreateFrame("StatusBar", "raid"..i.."SpellBar", UIParent, "SmallCastingBarFrameTemplate")
		spellbar:SetScale(JaxPartyCastBars.db.profile.scale)
		SetCastBarUnit(spellbar, "party"..i)
		spellbar:Hide()
		spellBars[i] = spellbar
	end

	HookSortFunction()
	JPC:UpdateBars()
	self:SetScript("OnUpdate", JPC_OnUpdate)
end

function JPC_Unlock()
	local lock = not JPC.locked
	JPC.locked = not JPC.locked
	for i = 1, 5 do
		if lock then
			spellBars[i]:SetAlpha(0)
		else
			spellBars[i]:Show()
			spellBars[i]:SetAlpha(1)
			spellBars[i].icon:SetTexture(GetSpellTexture(116))
		end
	end
end

JPC:RegisterEvent("VARIABLES_LOADED")
JPC:SetScript("OnEvent", JPC_OnLoad)

SLASH_JaxPartyCastbars1 = "/jpcb"
SLASH_JaxPartyCastbars2 = "/jaxpartycastbars"
SlashCmdList.JaxPartyCastbars = function(msg)
end
