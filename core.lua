local _, class = UnitClass("player");
if (class == "MAGE" or class == "WARLOCK" or class == "PRIEST") then
	return;
end

local GetTime = GetTime;
local FormatTime = AzCastBar.FormatTime;

-- Extra Options
local extraOptions = {
	{
		[0] = "Colors",
		{ type = "Color", var = "colNormal", default = { 0.4, 0.6, 0.8 }, label = "Normal Swing Color" },
		{ type = "Color", var = "colParry", default = { 1, 0.75, 0.5 }, label = "Parry Color" },
	},
};

-- Variables
local plugin = AzCastBar.CreateMainBar("Frame","Swing",extraOptions);
local plugin2 = AzCastBar.CreateMainBar("Frame","SwingOffHand",extraOptions);
local pName = UnitName("player");

-- Localized Names
local slam = GetSpellInfo(1464);
local autoShot = GetSpellInfo(75);
local wandShot = GetSpellInfo(5019);
local meleeSwing = GetLocale() == "enUS" and "Melee Swing" or GetSpellInfo(6603);
local spellSwingReset = {
	[GetSpellInfo(78)] = true,		-- Heroic Strike
	[GetSpellInfo(845)] = true,		-- Cleave
	[GetSpellInfo(2973)] = true,	-- Raptor Strike
	[GetSpellInfo(6807)] = true,	-- Maul
	[GetSpellInfo(56815)] = true,	-- Rune Strike
};

--------------------------------------------------------------------------------------------------------
--                                           Frame Scripts                                            --
--------------------------------------------------------------------------------------------------------

local function OnUpdate(self,elapsed)
	-- midswing attackspeed changes affect the rest of the swing..
	-- local speed = UnitAttackSpeed("player")
	-- if(speed ~= self.aspeed)then
		-- self.duration = (self.duration / self.aspeed)*speed;
		-- self.aspeed = speed;
		-- StartSwing(duration, meleeSwing);
	-- end
	-- No update on slam suspend
	if (self.slamStart) then
		return;
	-- Progression
	elseif (not self.fadeTime) then
		self.timeLeft = max(0,self.startTime + self.duration - GetTime());
		self.status:SetValue(self.duration - self.timeLeft);
		self:SetTimeText(self.timeLeft);
		if (self.timeLeft == 0) then
			self.fadeTime = self.cfg.fadeTime;
		end
	-- FadeOut
	elseif (self.fadeElapsed < self.fadeTime) then
		self.fadeElapsed = (self.fadeElapsed + elapsed);
		self:SetAlpha(self.cfg.alpha - self.fadeElapsed / self.fadeTime * self.cfg.alpha);
	else
		self:Hide();
	end
end

local function OnUpdate2(self,elapsed)
	-- -- midswing attackspeed changes affect the rest of the swing..
	-- local _,speed = UnitAttackSpeed("player")
	-- if(speed ~= self.aspeed)then
		-- self.duration = (self.duration / self.aspeed)*speed;
		-- self.aspeed = speed;
		-- StartSwingOffHand(duration, meleeSwing);
	-- end
	-- No update on slam suspend
	if (self.slamStart) then
		return;
	-- Progression
	elseif (not self.fadeTime) then
		self.timeLeft = max(0,self.startTime + self.duration - GetTime());
		self.status:SetValue(self.duration - self.timeLeft);
		self:SetTimeText(self.timeLeft);
		if (self.timeLeft == 0) then
			self.fadeTime = self.cfg.fadeTime;
		end
	-- FadeOut
	elseif (self.fadeElapsed < self.fadeTime) then
		self.fadeElapsed = (self.fadeElapsed + elapsed);
		self:SetAlpha(self.cfg.alpha - self.fadeElapsed / self.fadeTime * self.cfg.alpha);
	else
		self:Hide();
	end
end

--------------------------------------------------------------------------------------------------------
--                                           Event Handling                                           --
--------------------------------------------------------------------------------------------------------

local function StartSwing(time,text)
	plugin.duration = time;
	plugin.aspeed = time;
	plugin.name:SetText(text);
	plugin.startTime = GetTime();
	plugin.status:SetMinMaxValues(0,time);
	plugin.status:SetStatusBarColor(unpack(plugin.cfg.colNormal));
	plugin.totalTimeText = (plugin.cfg.showTotalTime and " / "..FormatTime(time,1) or nil);
	plugin.fadeTime = nil;
	plugin.fadeElapsed = 0;
	plugin:SetAlpha(plugin.cfg.alpha);
	plugin:Show();
end

local function StartSwingOffHand(time,text)
	plugin2.duration = time;
	plugin2.aspeed = time;
	plugin2.name:SetText(text);
	plugin2.startTime = GetTime();
	plugin2.status:SetMinMaxValues(0,time);
	plugin2.status:SetStatusBarColor(unpack(plugin2.cfg.colNormal));
	plugin2.totalTimeText = (plugin2.cfg.showTotalTime and " / "..FormatTime(time,1) or nil);
	plugin2.fadeTime = nil;
	plugin2.fadeElapsed = 0;
	plugin2:SetAlpha(plugin2.cfg.alpha);
	plugin2:Show();
end

-- Combat Log Parser
function plugin:COMBAT_LOG_EVENT_UNFILTERED(event,time,type,sourceGUID,sourceName,sourceFlags,destGUID,destName,destFlags,...)
	local speed = UnitAttackSpeed("player");
	-- Something our Player does
	if (sourceName == pName) then
		local prefix, suffix = type:match("(.-)_(.+)");
		if (prefix == "SWING") then -- and (not self.timeLeft or self.timeLeft <= 0.1)
			if(not self.timeLeft) then
				StartSwing(speed,"Mainhand");
			elseif(plugin2.timeLeft)then
				if(self.timeLeft <= plugin2.timeLeft)then
					StartSwing(speed,"Mainhand");
				end
			end
		end
	-- Something Happens to our Player
	elseif (destName == pName) then
		local prefix, suffix = type:match("(.-)_(.+)");
		local missType = ...;
		-- Az: the info on wowwiki seemed obsolete, so this might not be 100% correct, I had to ignore the 20% rule as that didn't seem to be correct from tests
		if (prefix == "SWING") and (suffix == "MISSED") and (self.duration) and (missType == "PARRY") then
			local newDuration = (self.duration * 0.6);
--			local newTimeLeft = (self.startTime + newDuration - GetTime());
			self.duration = newDuration;
			self.status:SetMinMaxValues(0,self.duration);
			self.status:SetStatusBarColor(unpack(self.cfg.colParry));
			self.totalTimeText = (self.cfg.showTotalTime and " / "..FormatTime(self.duration,1) or nil);
		end
	end
end

function plugin2:COMBAT_LOG_EVENT_UNFILTERED(event,time,type,sourceGUID,sourceName,sourceFlags,destGUID,destName,destFlags,...)
	local _,speed = UnitAttackSpeed("player");
	if(speed)then
		-- Something our Player does
		if (sourceName == pName) then
			local prefix, suffix = type:match("(.-)_(.+)");
			if (prefix == "SWING") then
				if(self.timeLeft and plugin.timeLeft) then
					if(self.timeLeft < plugin.timeLeft) then
						StartSwingOffHand(speed,"Offhand");
					end
				elseif((not self.timeLeft) and plugin.timeLeft) then
					StartSwingOffHand(speed,"Offhand");
				end
			end
		-- Something Happens to our Player
		-- presume only mainhand is parryhasted until i realize otherwise
		-- elseif (destName == pName) then
			-- local prefix, suffix = type:match("(.-)_(.+)");
			-- local missType = ...;
			-- -- Az: the info on wowwiki seemed obsolete, so this might not be 100% correct, I had to ignore the 20% rule as that didn't seem to be correct from tests
			-- if (prefix == "SWING") and (suffix == "MISSED") and (self.duration) and (missType == "PARRY") then
				-- local newDuration = (self.duration * 0.6);
	-- --			local newTimeLeft = (self.startTime + newDuration - GetTime());
				-- self.duration = newDuration;
				-- self.status:SetMinMaxValues(0,self.duration);
				-- self.status:SetStatusBarColor(unpack(self.cfg.colParry));
				-- self.totalTimeText = (self.cfg.showTotalTime and " / "..FormatTime(self.duration,1) or nil);
			-- end
		end
	end
end

-- Spell Cast Succeeded
function plugin:UNIT_SPELLCAST_SUCCEEDED(event,unit,spell,id)
	if (unit == "player") then
		if (spell == autoShot) or (spell == wandShot) then
			StartSwing(UnitRangedDamage("player"),spell);
		elseif (spell == slam) and (self.slamStart) then
			self.startTime = (self.startTime + GetTime() - self.slamStart);
			self.slamStart = nil;
		-- Az: cata has no spells that are on next melee afaik?
		elseif (spellSwingReset[spell]) then
			StartSwing(UnitAttackSpeed("player"),meleeSwing);
		end
	end
end

function plugin2:UNIT_SPELLCAST_SUCCEEDED(event,unit,spell,id)
	if (unit == "player") then
		if (spell == slam) and (self.slamStart) then
			self.startTime = (self.startTime + GetTime() - self.slamStart);
			self.slamStart = nil;
		-- all yellow swings are mainhand even if dualwielding
		end
	end
end

-- Warrior Only
if (class == "WARRIOR") then
	-- Spell Cast Start
	function plugin:UNIT_SPELLCAST_START(event,unit,spell,id)
		if (unit == "player") and (spell == slam) then
			self.slamStart = GetTime();
		end
	end
	
	function plugin2:UNIT_SPELLCAST_START(event,unit,spell,id)
		if (unit == "player") and (spell == slam) then
			self.slamStart = GetTime();
		end
	end
	-- Spell Cast Interrupted
	function plugin:UNIT_SPELLCAST_INTERRUPTED(event,unit,spell,id)
		if (unit == "player") and (spell == slam) and (self.slamStart) then
			self.slamStart = nil;
		end
	end
	
	function plugin2:UNIT_SPELLCAST_INTERRUPTED(event,unit,spell,id)
		if (unit == "player") and (spell == slam) and (self.slamStart) then
			self.slamStart = nil;
		end
	end
end

-- OnConfigChanged
function plugin:OnConfigChanged(cfg)
	if (cfg.enabled) then
		self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
		self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED");
		if (class == "WARRIOR") then
			self:RegisterEvent("UNIT_SPELLCAST_START");
			self:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED");
		end
	else
		self:UnregisterAllEvents();
	end
end

function plugin2:OnConfigChanged(cfg)
	if (cfg.enabled) then
		self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
		self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED");
		if (class == "WARRIOR") then
			self:RegisterEvent("UNIT_SPELLCAST_START");
			self:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED");
		end
	else
		self:UnregisterAllEvents();
	end
end

--------------------------------------------------------------------------------------------------------
--                                          Initialise Plugin                                         --
--------------------------------------------------------------------------------------------------------

plugin.icon:SetTexture("Interface\\Icons\\Spell_Shadow_SoulLeech_2");
plugin2.icon:SetTexture("Interface\\Icons\\Spell_Shadow_SoulLeech_2");
--plugin.icon:Hide();
plugin:SetScript("OnUpdate",OnUpdate);
plugin2:SetScript("OnUpdate",OnUpdate2);