local AddOnName, AddOn = ...
local tooltipInfo = {}
local customframes;
local wowheadLink = "wowhead.com/"
local wowheadLinkFinal = ""
local hash = ""
local frame = CreateFrame("Frame")
local gotoLink = ""
local QuestMapFrame_IsQuestWorldQuest = QuestMapFrame_IsQuestWorldQuest or QuestUtils_IsQuestWorldQuest
local isClassicWow = select(4,GetBuildInfo()) < 20000

local loctable = {
  ["enUS"] = "en-us",
  ["esMX"] = "es-mx",
  ["ptBR"] = "pt-br",
  ["koKR"] = "ko-kr",
  ["zhCN"] = "zh-cn",
  ["zhTW"] = "zh-tw",
  ["enGB"] = "en-gb",
  ["frFR"] = "fr-fr",
  ["deDE"] = "de-de",
  ["itIT"] = "it-it",
  ["esES"] = "es-es",
  ["ruRU"] = "ru-ru",
}

local function AddOnPrint(msg)
	(SELECTED_CHAT_FRAME or DEFAULT_CHAT_FRAME):AddMessage("|cffffff78WHLG: |r"..msg)
end

local locale = string.sub(GetLocale(), 1, 2)
if locale == "zh" then locale = "cn" end
if locale ~= "en" then
	wowheadLinkFinal = locale.."."..wowheadLink	
  hash = "#english-comments"
else
	wowheadLinkFinal = wowheadLink
end

if (isClassicWow) then
	if locale == "en" then locale = "classic" else locale = locale..".classic" end
	wowheadLinkFinal = locale.."."..wowheadLink
end

local validfounds = {
  npc = "",
	mount = "Mount",
  spell = GetSpellInfo,
  achievement = function(id)
    return select(2, GetAchievementInfo(id))
  end,
  quest = function(id)
    if not id then return "" end
    if QuestMapFrame_IsQuestWorldQuest(id) then
      return select(4, GetTaskInfo(id))
    else
      for i = 1, C_QuestLog.GetNumQuestLogEntries() do
				local info = C_QuestLog.GetInfo(i)
				if not info then return end
				if not info.isHeader then
					--local name, _, _, _, _, _, _, qid = C_QuestLog.GetQuestLogTitle(i)
					if id == info.questID then
						return info.title
					end
				end
      end
      return "Quest";
    end
  end,
  item = GetItemInfo,
	currency = "Currency"
}

local function clearTooltipInfo(tooltip)
	if tooltip then
		if tooltipInfo[tooltip] then
			wipe(tooltipInfo[tooltip])
		end
	end
end

--[[
local function setTooltipHyperkink(tooltip, hyperlink)
  local ttable = tooltipInfo[tooltip];
	ttable.hl = hyperlink;
end
]]

local function setTooltipAura(tooltip, unit, index, filter)
  local ttable = tooltipInfo[tooltip];
  local name = UnitAura(unit, index, filter);
  local id = select(10, UnitAura(unit, index, filter));
 -- print("\nName: "..name.."\nID: "..id)
  ttable.aura = id
  ttable.name = name
end

local function doSetRecipeReagentItem(tooltip, recipeId, reagentIndex)
	if not tooltip then return end
	if recipeId and reagentIndex then		
		--print("\nRecipeID: "..recipeId.."\nReagentIndex: "..reagentIndex.."\nLink: ")
		local ttable = tooltipInfo[tooltip];
		ttable.recipeId = recipeId
		ttable.reagentIndex = reagentIndex
	end
end

local function hookTooltip(tooltip)
	if ((not tooltip) or (tooltip:IsForbidden())) then return end
  tooltipInfo[tooltip] = {}
	WowheadLinkGrabberDB.tooltipInfo = {}
  --hooksecurefunc(tooltip, "SetHyperlink", setTooltipHyperkink)
	if tooltip.SetRecipeReagentItem or tooltip["SetRecipeReagentItem"] then
		hooksecurefunc(tooltip, "SetRecipeReagentItem", doSetRecipeReagentItem)
	end
	
	if tooltip.SetUnitAura or tooltip["SetUnitAura"] then
		hooksecurefunc(tooltip, "SetUnitAura", setTooltipAura)
	end
	
	if tooltip.OnTooltipSetSpell or tooltip["OnTooltipSetSpell"] then
		hooksecurefunc(tooltip, "OnTooltipSetSpell", setTooltipAura)
	end
	
  tooltip:HookScript("OnTooltipCleared", clearTooltipInfo)
end

local tooltipList = {
	GameTooltip,
	ItemRefTooltip
}

local function onEvent(frame, event, addon, ...)
  if event == "PLAYER_ENTERING_WORLD" then
		if not WowheadLinkGrabberDB then
			WowheadLinkGrabberDB = {
				debug = false,
			}
		end
		
		for _, tt in ipairs(tooltipList) do
			if tt then
				hookTooltip(tt)
			end
		end
	end
end

local function onUpdate()
  StaticPopup_Show("WOWHEAD_LINK_GRABBER")
  frame:Hide();
end

local function foundplayer(unit)
  if ( (not unit) or (isClassicWow) ) then return end

  local name, realm = UnitFullName(unit)
  realm = realm or GetRealmName()
  if name and realm then
    wwwrealm = realm:gsub("'", "")

    local reg = GetCurrentRegion()
    local isEU = reg == 3
    local loc = GetLocale()
    if reg == 3 and loc == "enUS" then loc = "enGB" end
    local sitelocale = loctable[loc] or (isEU and "en-gb" or "en-us")

    local link = "https://worldofwarcraft.com/"..sitelocale.."/character/{realm-}/{name}";
    link = link:gsub("{realm%-}", ""..wwwrealm:gsub(" ","-"));
    link = link:gsub("{name}", name);

    gotoLink = link
    StaticPopupDialogs["WOWHEAD_LINK_GRABBER"].text = "|cffffff00".. "Armory URL" ..":\n|r" .. name .. " - " .. realm .. "\n\n|cff00ff00CTRL+C to copy!|r";
    frame:Show();
    return true;
  end
end

local function found(ftype, id, name)
  local foundAccept = validfounds[ftype];
  if foundAccept then
    name = name or foundAccept;
    if type(name) == 'function' then
      name = name(id);
    end
    name = name or ftype;
    --print("Found "..type.." "..id)
    -- Show frame to recieve OnUpdate next frame
    -- So pressed hotkey doesnt erase text field
    gotoLink = "http://" .. wowheadLinkFinal .. ftype .. "=" .. id .. hash;
    local upper_name = firstToUpper(ftype)
    if QuestMapFrame_IsQuestWorldQuest(id) then
      upper_name = firstToUpper("World Quest");
    end
    StaticPopupDialogs["WOWHEAD_LINK_GRABBER"].text = "|cffffff00"..upper_name .. ":\n|r" .. name .. "\n\n|cff00ff00CTRL+C to copy!|r";
    frame:Show();
    return true;
  end
end

local function getUnitInfo(unit, name)
  if UnitIsPlayer(unit) then
    return foundplayer(unit)
  else
    local GUID = UnitGUID(unit)
    local type, _, _, _, _, id = strsplit("-", GUID);
    if type == "Creature" then return found("npc", id, name) end
  end
end

local function getFocusInfo()
  local focus = GetMouseFocus()
  local current = focus;
  local focusname;
  while current and (not focusname) do

    -- World Quest support in BfA
    if WorldMapFrame and WorldMapFrame:IsVisible() and current and current.questID and QuestMapFrame_IsQuestWorldQuest(current.questID) then
      return found("quest", current.questID, select(4, GetTaskInfo(current.questID)))
    end		

		-- BattletPet #2
		if PetJournal and PetJournal:IsVisible() and current and current.speciesID then
			local name, _, _, id = C_PetJournal.GetPetInfoBySpeciesID(current.speciesID)
			if id then
				local dString = "Battle Pet"
				gotoLink = "https://" .. wowheadLinkFinal .. "npc=" .. id;
				StaticPopupDialogs["WOWHEAD_LINK_GRABBER"].text = "|cffffff00"..dString.. ":\n|r" .. name .. "\n\n|cff00ff00CTRL+C to copy!|r";
				frame:Show();
				return true
			end
		end

    focusname = current:GetName()
    current = current:GetParent()
  end

  if not focusname then return end
  local focuslen = string.len(focusname);
	if WowheadLinkGrabberDB.debug then
		--if not IsAddOnLoaded("Blizzard_DebugTools") then UIParentLoadAddOn("Blizzard_DebugTools");
		print("\nFocusName: "..focusname.."");
	end
  for name, func in pairs(customframes) do
    local customlen = string.len(name)
    if customlen <= focuslen and name == string.sub(focusname, 1, customlen) then
      if func(focus, focusname) then return true end
    end
  end
end

local function parseLink(link)
  local linkstart = string.find(link, "|H")
  local _, lastfound, type, id = string.find(link, "(%a+):(%d+):", linkstart and linkstart + 2)
  local _, _, name = string.find(link, "%[([^%[%]]*)%]", lastfound)
  return found(type, id, name)
end

local function parseTooltip(tooltip)
	if tooltip:IsForbidden() then return end
	
  local ttdata = tooltipInfo[tooltip];
	if ttdata and ttdata.recipeId and ttdata.reagentIndex then
		local recipeId = tonumber(ttdata.recipeId)
		local reagentIndex = tonumber(ttdata.reagentIndex)
		local link = C_TradeSkillUI.GetRecipeReagentItemLink(recipeId, reagentIndex)
		--print("\nRecipeID: "..recipeId.."\nReagentIndex: "..reagentIndex.."\nLink: "..tostring(link))
		return parseLink(link)
	end
	
	--[[
  if ttdata and ttdata.hl then
		--print("\nHyperlink: "..ttdata.hl)
		return parseLink(ttdata.hl)
	end
	]]
	
  if ttdata and ttdata.aura then
		--print("\nAuraID: "..ttdata.aura.."\nAuraName: "..ttdata.name)
		return found("spell", ttdata.aura, ttdata.name)
	end
	
	if ttdata and ttdata.spellid then
		--print("\nSpellID: "..ttdata.spellid.."\SpellName: "..ttdata.name)
		return found("spell", ttdata.spellid, ttdata.name)
	end

  local name, link = tooltip:GetItem()
  if name then return parseLink(link) end
  local name, id = tooltip:GetSpell();
  if name then return found("spell", id, name) end
  local name, unit = tooltip:GetUnit()
  if unit then return getUnitInfo(unit, name) end
end

local function linkGrabberRunInternal()
  return parseTooltip(ItemRefTooltip)
    or parseTooltip(GameTooltip)
    or getFocusInfo()
end

linkGrabberRun = function()
  linkGrabberRunInternal()
end

-- Formatting
function firstToUpper(str)
  return (str:gsub("^%l", string.upper))
end

-- Custom frames mouseover
local function AchievmentWidget(widget)
  if not widget then return end
  return found("achievement", widget.id);
end

local function AchievmentWidgetParent(widget)
  if not widget then return end
  return AchievmentWidget(widget:GetParent())
end

local function QuestWidget(widget)
  if not widget then return end
  local qid = widget.questID or widget.questId or widget.questid or nil
  if qid and qid > 0 then return found("quest", qid, select(4, GetTaskInfo(qid))) end
end

local function QuestWidgetClassic(widget)
	if widget.isHeader then return end
  local i = widget:GetID();
	local index = FauxScrollFrame_GetOffset(QuestLogListScrollFrame) + i
  if index then
    local name = GetQuestLogTitle(index);
    local id = select(8,GetQuestLogTitle(index));
    found("quest", id, name);
  end
end

local function TrackWidget(widget)
  if not widget then return end
  local parent = widget:GetParent()
	if not parent then return end
  local module = parent.module;
	if not module then return end
	if (not parent.id) then return end
  if (module == QUEST_TRACKER_MODULE) or (module == CAMPAIGN_QUEST_TRACKER_MODULE) or (module == SCENARIO_TRACKER_MODULE) or (module == CAMPAIGN_QUEST_TRACKER_MODULE) then
    return found("quest", parent.id)
  elseif module == ACHIEVEMENT_TRACKER_MODULE then
    return found("achievement", parent.id)
  end
end

local function TrackWorldQuestWidget(widget)
	if not widget then return end
  local module = widget.module;
	if WowheadLinkGrabberDB.debug then
		print("\widget: "..tostring(widget:GetName()).."");
	end
  if module == WORLD_QUEST_TRACKER_MODULE then
    if widget.id then
      return found("quest", widget.id, select(4, GetTaskInfo(widget.id)))
    end
  elseif widget.questID then -- World Quest Tracker support
    if QuestMapFrame_IsQuestWorldQuest(widget.questID) then
      return found("quest", widget.questID, select(4, GetTaskInfo(widget.questID)))
  end
  end
end

local function BFAMissionFrameFollowers(widget)
	if not widget then return end
	if (not BFAMissionFrame) or (not BFAMissionFrame:IsVisible()) then return end
	local parent = widget:GetParent()
	if not parent then return end
	local follower = parent.Follower
	if not follower then return end
	local info = follower.info;	
	if not info then return end
	--UIParentLoadAddOn("Blizzard_DebugTools");
	--DevTools_Dump(follower)
	local name = info.name;
	local fID = info.followerID;
	local campID = info.garrFollowerID or info.followerID;
	local troop = info.isTroop;
	local faction = UnitFactionGroup("player");
	if (not faction) or (not campID) then return end
	
	local cID;
	if faction == "Horde" then
		cID = ""..campID..".2";
	elseif faction == "Alliance" then
		cID = ""..campID..".1";
	end
	if not cID then return end
	
	local dString;
	if troop then
		dString = "Troop"
	else
		dString = "Champion"
	end
	
	gotoLink = "https://" .. wowheadLinkFinal .. "bfa-champion=" .. cID;
	StaticPopupDialogs["WOWHEAD_LINK_GRABBER"].text = "|cffffff00"..dString.. ":\n|r" .. name .. "\n\n|cff00ff00CTRL+C to copy!|r";
	frame:Show();
end

local function BattlePetWidget(widget)
	if not widget then return end
	local speciesID = widget.speciesID
	if not speciesID then return end
	local name, _, _, id = C_PetJournal.GetPetInfoBySpeciesID(speciesID)
	if not id then return end
	if id then
		local dString = "Battle Pet"
		gotoLink = "https://" .. wowheadLinkFinal .. "npc=" .. id;
		StaticPopupDialogs["WOWHEAD_LINK_GRABBER"].text = "|cffffff00"..dString.. ":\n|r" .. name .. "\n\n|cff00ff00CTRL+C to copy!|r";
		frame:Show();
	end
end

local function RematchCard(widget)
	if not widget then return end
	local petID = widget.petID
	if not petID then
		if not RematchPetCard then return end
		petID = RematchPetCard.petID
	end
	if not petID then return end
	local speciesID = 0
	if type(petID)=="string" then		
		if petID:match("^BattlePet%-%x%-%x%x%x%x%x%x%x%x%x%x%x%x$") then
			speciesID = C_PetJournal.GetPetInfoByPetID(petID)
		end
	elseif type(petID)=="number" then
		speciesID = petID
	end
	if not speciesID or (speciesID == 0) then return end
	local name, _, _, id = C_PetJournal.GetPetInfoBySpeciesID(speciesID)
	if not id then return end
	if id then
		local dString = "Battle Pet"
		gotoLink = "https://" .. wowheadLinkFinal .. "npc=" .. id;
		StaticPopupDialogs["WOWHEAD_LINK_GRABBER"].text = "|cffffff00"..dString.. ":\n|r" .. name .. "\n\n|cff00ff00CTRL+C to copy!|r";
		frame:Show();
	end
end

local function MountsWidget(widget)
	if not widget then return end
	local index = widget.index
	if not index then return end
	local name, id = C_MountJournal.GetDisplayedMountInfo(index)
	if id then
		local dString = "Mount"
		gotoLink = "https://" .. wowheadLinkFinal .. "spell=" .. id;
		StaticPopupDialogs["WOWHEAD_LINK_GRABBER"].text = "|cffffff00"..dString.. ":\n|r" .. name .. "\n\n|cff00ff00CTRL+C to copy!|r";
		frame:Show();
	end
end

local function CurrencyWidget(widget)
	if not widget then return end
	local parent = widget:GetParent()	
	if widget.isHeader or parent.isHeader then return end
	local index = widget.index or parent.index
	if not index then return end
	local link = C_CurrencyInfo.GetCurrencyListLink(index)
	if link then
		return parseLink(link)
	end
end

local function SpellButtonWidget(widget)
	if not widget then return end
	if SpellBookFrame:IsVisible() then
		if SpellBookFrame.bookType == BOOKTYPE_SPELL or SpellBookFrame.bookType == BOOKTYPE_PET then
			local id = SpellBook_GetSpellBookSlot(widget)
			local name, _, spellid = GetSpellBookItemName(id , SpellBookFrame.bookType)
			if name and spellid then
				--print("\nname: "..name.."\nid: "..spellid.."\n")
				return found("spell", spellid, name)
			end
		end
	end
end

customframes = {
  ["AchievementFrameCriteria"] = AchievmentWidgetParent,
  ["AchievementFrameSummaryAchievement"] = AchievmentWidget,
  ["AchievementFrameAchievementsContainerButton"] = AchievmentWidget,
  ["QuestScrollFrame"] = QuestWidget,
  ["ObjectiveTrackerBlocksFrameHeader"] = TrackWidget,
  ["ObjectiveTrackerBlocksFrame"] = TrackWorldQuestWidget, -- World Quest support
  ["BFAMissionFrameFollowersListScrollFrameButton"] = BFAMissionFrameFollowers, -- BfA Missions NPC Support
	["MountJournalListScrollFrameButton"] = MountsWidget, -- Mounts #1
	["PetJournalListScrollFrameButton"] = BattlePetWidget, -- BattlePet #1
	["TokenFrameContainerButton"] = CurrencyWidget, -- BattlePet #1
	["SpellButton"] = SpellButtonWidget, -- Spell Book Button
	--["WardrobeCollectionFrame "] = WardrobeCollectionFrame
	
  -- 3rd party AddOns
  ["WorldQuestTracker_Tracker"] = TrackWorldQuestWidget, -- World Quest Tracker support
  ["ClassicQuestLogScrollFrameButton"] = QuestWidget, -- Classic Quest Log support
  ["WQT_QuestScrollFrameButton"] = QuestWidget, -- World Quest Tab support
	
	-- Battle Pet - Rematch AddOn
  ["RematchPetPanel"] = RematchCard,
  ["RematchPetCard"] = RematchCard,
  ["RematchQueuePanel"] = RematchCard,
  ["RematchLoadoutPanel"] = RematchCard,
  ["RematchMiniPanel"] = RematchCard,
	
	-- Classic Quest Title
  ["QuestLogTitle"] = QuestWidgetClassic,
}

frame:Hide()
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", onEvent)
frame:SetScript("OnUpdate", onUpdate)

BINDING_HEADER_LINK_GRABBER_HEAD = "Wowhead Link Grabber"
BINDING_DESCRIPTION_LINK_GRABBER_DESC = "Hotkey for displaying wowhead link"
BINDING_NAME_LINK_GRABBER_NAME = "Generate Link"

StaticPopupDialogs["WOWHEAD_LINK_GRABBER"] = {
  OnShow = function (self, data)
    self.editBox:SetText(gotoLink)
    self.editBox:HighlightText()
  end,
  EditBoxOnEscapePressed = function(self)
    self:GetParent():Hide();
  end,
  EditBoxOnTextChanged = function(self)
    self:SetText(gotoLink)
    self:HighlightText()
  end,
  button1 = OKAY,
  editBoxWidth = 350,
  hasEditBox = true,
  preferredIndex = 3
}

_G['SLASH_' .. AddOnName .."debug" .. 1] = '/wlg'
_G['SLASH_' .. AddOnName .."debug" .. 2] = '/wowheadlinkgrabber'
SlashCmdList[AddOnName.."debug"] = function(msg)
	local cmd = ""
	if msg and type(msg) == "string" then cmd = msg end
	if cmd ~= "" then
		if cmd == "debug" then
			if WowheadLinkGrabberDB then
				if WowheadLinkGrabberDB.debug then
					WowheadLinkGrabberDB.debug = false					
					AddOnPrint("Debug disabled.")
				else
					WowheadLinkGrabberDB.debug = true
					AddOnPrint("Debug enabled.")
				end
			end
		end
	else
		ChatFrame1:AddMessage("|cffffff78WowHead Link Grabber |r/wlg |cffffff78Usage:|r")
		ChatFrame1:AddMessage("|cffffff78/wlg debug|r - Toggle Debug")
	end
end