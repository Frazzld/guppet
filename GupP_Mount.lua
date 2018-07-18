local function GupP_Mount_CanFlyThisContinent()

	-- To avoid errors
	if InCombatLockdown() then return false end

	local continent = MapUtil.GetMapParentInfo(C_Map.GetBestMapForUnit("player"), Enum.UIMapType.Continent).mapID

	if continent == 875 or continent == 876 then -- BfA
		-- if not IsSpellKnown() then -- TODO:insert BfA Pathfinder
			return false
		-- end
	elseif continent == 619 then -- Broken Isles
		if not IsSpellKnown(233368) then	-- Broken Isles Pathfinder
			return false
		end
	elseif continent == 572 then -- Draenor
		if not IsSpellKnown(191645) then	-- Draenor Pathfinder
			return false
		end
	elseif continent == 12 -- Kalimdor
		or continent == 13 -- Eastern Kingdom
		or continent == 101 -- Outland
		or continent == 424 -- Pandaria
		or continent == 113 -- Northrend
		or continent == 948 then -- Maelstrom (Deepholm)

		if not select(13,GetAchievementInfo(890)) then	-- Expert Riding
			return false
		end
	else
		return true
	end
end

function GupPet_CanFly()

	if  not(IsFlyableArea()) then
		return false
	else

		if  GupP_Mount_CanFlyThisContinent() == false  then
			return false
		end

		-- Check for active World PVP
		for i=1, GetNumWorldPVPAreas() do
			local _, localizedName, isActive = GetWorldPVPAreaInfo(i)
			if localizedName == GetZoneText() and isActive then
				return false
			end
		end

		return true
	end
end

function GupPet_Exit()

	if IsMounted() then

		Dismount()
		return true

	elseif UnitInVehicle("player")  then

		VehicleExit()
		return true
	else
		return false
	end
end

function GupPet_AutoMultiGround()

	if GupPet_PreMounten( "Multi" ) then return end -- If you can mount return

end

function GupPet_AutoMounten()

	if GupPet_Exit() then return end	-- If you exit something return

	if GupPet_CanFly() then
		if GupPet_AutoFly() then return end -- If you can fly return
	end

	if GupPet_AutoGround() then return end -- If you can mount return

end

function GupPet_AutoGround()
	if GupPet_Exit() then return end ;	-- If you exit something return
	if IsSwimming() then  if GupPet_PreMounten( "Aquatic" ) then return end end -- If you can swim then swim ;p

	if GupPet_PreMounten( "Ground" ) then	return true end

	return false
end

function GupPet_AutoFly()
	if GupPet_Exit() then return end ;	-- If you exit something return

	if GupPet_PreMounten( "Fly" ) then	return true end

	return false
end

function GupPet_AutoDismount( dismount ) --what it do?
	if dismount then
		GupPetFrame:RegisterEvent("UI_ERROR_MESSAGE")
		GUPPET_OPTIONS["AutoDismount"] = true
	else
		GupPetFrame:UnregisterEvent("UI_ERROR_MESSAGE")
		GUPPET_OPTIONS["AutoDismount"] = false
	end
end

local function GupPet_Mounten( MountType , Location   )
	if C_MountJournal.GetNumMounts() == 0  then
		return
	end

	--Delay pet summoning so if you got a small amount off lag you wont get kicked off your mount again
	if GUPPET_AUTOCOMPANION.ResummonFrame.TotalElapsed then
		GUPPET_AUTOCOMPANION.ResummonFrame.TotalElapsed = -3
	end

	-- Summon Chauffeur for lowlvl chars without riding skill
	local apprenticeRiding = select(13,GetAchievementInfo(891))
	local hasChauffeur = select(4,GetAchievementInfo(9909)) -- Collect 35 Heirlooms
	if not apprenticeRiding and hasChauffeur then
		local playerfaction = UnitFactionGroup("player")

		for i, mountID in ipairs(C_MountJournal.GetMountIDs()) do
			local _, spellID = C_MountJournal.GetMountInfoByID(mountID)
			if spellID then
				if spellID == 179244 and  playerfaction == "Horde" then
					C_MountJournal.SummonByID(mountID)
					return
				end
				if spellID == 179245 and playerfaction == "Alliance" then
					C_MountJournal.SummonByID(mountID)
					return
				end
			end
		end
	end
	--|

	local MountSlots = {}
	local Total = 0

	for i = 1 , GUPPET_SAVEDDATA[ MountType ]["Total"] do

		if GUPPET_SAVEDDATA[ MountType ][i]["Weight"][ Location ] > 0 then

			for q = 1 , GUPPET_SAVEDDATA[ MountType ][i]["Weight"][ Location ] do

				Total = Total + 1
				MountSlots[Total] = GUPPET_SAVEDDATA[ MountType ][i]["Id"]
			end
		end
	end

	if Total > 0 then

		local randomMount =  math.random(Total)

		for i, mountID in ipairs(C_MountJournal.GetMountIDs()) do
            local _, spellID = C_MountJournal.GetMountInfoByID(mountID)
			if spellID then
				if MountSlots[randomMount] == spellID then
					C_MountJournal.SummonByID(mountID)
					return
				end
			end
		end
	end
end

function GupPet_PreMounten( MountType )

	local Location = GetRealZoneText()

	-- First check if you got something enabled for this Location
	if GUPPET_SAVEDLOCATIONS[ Location ] then

		if GUPPET_SAVEDDATA[MountType]["TotalWeight"][ Location ] > 0 then
			GupPet_Mounten( MountType , Location )
			return true
		end
	end

	local _, instanceType = IsInInstance()

	if ( IsResting() ) then
		Location = GUPPET_C["M_CITIES"]
	elseif ( instanceType == "pvp" ) then
		Location = GUPPET_C["M_BATTLEGROUNDS"]
	elseif ( instanceType == "arena" ) then
		Location = GUPPET_C["M_ARENAS"]
	elseif ( instanceType == "party" or instanceType == "raid" ) then
		Location = GUPPET_C["M_INSTANCES"]
	else
		Location = GUPPET_C["M_GLOBALWORLD"]
	end

	if GUPPET_SAVEDDATA[MountType]["TotalWeight"][ Location ] > 0 then
		GupPet_Mounten( MountType , Location )
		return true
	end

	if GUPPET_SAVEDDATA[MountType]["TotalWeight"][ GUPPET_C["M_GLOBALWORLD"] ] > 0 then
		GupPet_Mounten( MountType , GUPPET_C["M_GLOBALWORLD"] )
		return true
	end

	return false
end
