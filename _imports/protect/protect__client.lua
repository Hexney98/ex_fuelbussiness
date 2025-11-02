-- protectGlobal.lua / Hungary Life ~ 2023 Xenius
RESOURCE_PREFIX = "ex_"

local model_cache = {};
local addedEvent = false;
function requestModel(name, path)
    local eventName = "client" == "client" and "onClientModelsLoaded" or "onServerModelsLoaded"

    if (not model_cache[name .. ":" .. path]) then
        model_cache[name .. ":" .. path] = {name = name, path = path};
    end

    if (not addedEvent) then
        addedEvent = true;
        
		addEvent(eventName, true)
        addEventHandler(eventName, root, function()
			for key, value in pairs(model_cache) do
				_G[value.name] = nexports.models_loader:getModel(value.path);
			end
        end);
    end

    if (nexports.core:isResourceRunning("ex_models_loader")) then
        _G[name] = nexports.models_loader:getModel(path);
    end
end

function _getModel(name)
    return _G[name];
end
-- requestModel("ami lesz a valtozo neve", "path ami benne van a json fileba (model_keys.json)")

-- Szerver verzió lekérdezés (number)
function getServerVersion()
    return tonumber(getElementData(root, "server:VersionNumber") or 0)
end

-- Timer idejének átkonvertálása kiírássá (string)
local function convertToTime(ms)
    local seconds = math.floor(ms / 1000)
    local minutes = math.floor(seconds / 60)
    seconds = seconds % 60
    
    return string.format("%02d:%02d", minutes, seconds)
end

-- Model lekérés az új skin rendszerrel
_getElementModel = getElementModel
function getElementModel(element)
    if getElementType(element) == "player" or getElementType(element) == "ped" then
        local model = tonumber(getElementData(element, "ped:model")) or -1
        if nexports.core:isSkinValid(model) then
            return model
        end

        return 1
    end

    return _getElementModel(element)
end

-- Model állítás az új skin rendszerrel
_setElementModel = setElementModel
function setElementModel(element, model)
    if getElementType(element) == "player" or getElementType(element) == "ped" then
        if nexports.core:isSkinValid(model) then
            return setElementData(element, "ped:model", model)
        end

        return false
    end

    return _setElementModel(element, model)
end

function formatCurrency(...)
    return nexports.core:formatCurrency(...)
end

function getShortString(...)
    return nexports.new_core:GetServerPrefix()
end

-- vehicle types
local typeMap = {
	car = function(vehicleType) return vehicleType == "Automobile" or model == 539 end,
	boat = function(vehicleType) return vehicleType == "Boat" end,
	bike = function(vehicleType) return vehicleType == "Bike" or vehicleType == "Quad" end,
	bicycle = function(vehicleType) return vehicleType == "BMX" end,
	heli = function(vehicleType) return vehicleType == "Helicopter" end,
	plane = function(vehicleType) return vehicleType == "Plane" end,
	trailer = function(vehicleType) return vehicleType == "Trailer" end
}

function isVehicleInType(vehicleOrModel, types)
	if type(vehicleOrModel) ~= "number" and getElementType(vehicleOrModel) ~= "vehicle" then return false end
	if type(vehicleOrModel) == "number" and (vehicleOrModel < 400 or vehicleOrModel > 611) then return false end

    local vehicleType = getVehicleType(vehicleOrModel)
    local model = (type(vehicleOrModel) == "number" and vehicleOrModel or getElementModel(vehicleOrModel))
	
	if type(types) == "table" then
		for _, vType in ipairs(types) do
			if typeMap[vType] and typeMap[vType](vehicleType) then
				return true
			end
		end
	else
		if typeMap[types] and typeMap[types](vehicleType) then
			return true
		end
    end

    return false
end
-- usage: isVehicleInType(vehicle, {"car", "bike", "plane"})

-- Triggerek, commandhandler

    -- régi scriptből megmaradt, backward compatilibity
    _triggerServerEvent = triggerServerEvent
    
    local spamTimers = {}
    _addCommandHandler = addCommandHandler
    function addCommandHandler(cmd, handlerFunction, caseSensitive, spamProtection, msg)
        local function wrappedHandler(...)
            if isTimer(spamTimers[cmd]) then
                if msg then
                    local timeLeft = convert_to_time(getTimerDetails(spamTimers[cmd]))
                    nexports.new_core:OutputToPlayer("Spam érzékelve. Várj még: " .. timeLeft)
                end
                return
            end

            if not nexports.core:getNetworkState() then
                nexports.new_core:OutputToPlayer("Nem érzékelhető netkapcsolat, parancs nem futott le: "..cmd)
                return
            end

            if spamProtection then
                spamTimers[cmd] = setTimer(function() end, spamProtection, 1)
            end

            return handlerFunction(...)
        end

        if type(cmd) == "table" then
            for _, value in ipairs(cmd) do
                _addCommandHandler(value, wrappedHandler, caseSensitive)
            end
        else
            _addCommandHandler(cmd, wrappedHandler, caseSensitive)
        end
    end
    
    if isOOPEnabled() then
        function Player:triggerServer(name, ...)
            return triggerServerEvent(name, self, ...)
        end
        
        function Element:triggerServer(name, ...)
            return triggerServerEvent(name, self, ...)
        end
    end

    local boundKeys = {}
    local _bindKey = bindKey
    local _unbindKey = unbindKey

    function bindKey(key, keyState, func, ...)
        local funcName = tostring(func)
        funcName = funcName:gsub("function: ", "") .. "_" .. key
        if not boundKeys[funcName] then
            boundKeys[funcName] = true
            return _bindKey(key, keyState, func, ...)
        end
    end

    function unbindKey(key, keyState, func)
        local funcName = tostring(func)
        funcName = funcName:gsub("function: ", "") .. "_" .. key
        if boundKeys[funcName] then
            boundKeys[funcName] = nil
            return _unbindKey(key, keyState, func)
        end
    end


function getResourceRealName(name)
    return "ex_" .. name
end

local rescallMT_N = {}
function rescallMT_N:__index(k)
    if type(k) ~= 'string' then k = tostring(k) end
        self[k] = function(resExportTable, ...)
        if type(self.res) == 'userdata' and getResourceRootElement(self.res) then
            return call(self.res, k, ...)
        else
            return nil
        end
    end
    return self[k]
end

local nexportsMT = {}
function nexportsMT:__index(k)
    if (not string.find(k, "ex_")) then
        k = getResourceRealName(k)
    end
    
    if type(k) == 'userdata' and getResourceRootElement(k) then
        return setmetatable({ res = k }, rescallMT_N)
    elseif type(k) ~= 'string' then
        k = tostring(k)
    end

    local res = getResourceFromName(k)
    if res and getResourceRootElement(res) then
        return setmetatable({ res = res }, rescallMT_N)
    else
        outputDebugString('nexports: Call to non-running server resource (' .. k .. ')', 1)
        return setmetatable({}, rescallMT_N)
    end
end
nexports = setmetatable({}, nexportsMT)


	-- font cache
	addEvent("onClientFontsCleanup", true)

	local addedFontEvent
	local fontsInThisResource = {}
	local function cleanupFonts()
		local count = 0
		local tick = getTickCount()
		for key, data in pairs(fontsInThisResource) do
			if tick - data.lastCall >= 1000 then
				if isElement(data.font) then
					destroyElement(data.font)
				end
				fontsInThisResource[key] = nil
			else
				count = count + 1
			end
		end

		if count == 0 then
			removeEventHandler("onClientFontsCleanup", root, cleanupFonts)
			addedFontEvent = false
		end
	end
	
	function getFont(font, size, bold)
		if font:find("fa-") then
			font = "fontawesome"
		elseif font:find("fab-") then
			font = "fontawesome_brands"
		elseif font:find("fas-") then
			font = "fontawesome_light"
		end
		
		local key = font .. "-" .. size .. "-" .. tostring(bold)
		if not fontsInThisResource[key] or not isElement(fontsInThisResource[key].font) then
			if font == "fontawesome" or font == "fontawesome_brands" or font == "fontawesome_regular" or font == "fontawesome_light" or font == "AwesomeFont" then
				if font == "AwesomeFont" or font == "fontawesome_regular" then font = "fontawesome" end
				
				fontsInThisResource[key] = {
					font = dxCreateFont(":".."ex_".."icons/fonts/"..font..".ttf", size, bold),
					lastCall = getTickCount()
				}
			else
				fontsInThisResource[key] = {
					font = dxCreateFont(":".."ex_".."fonts/files/"..font..".ttf", size, bold),
					lastCall = getTickCount()
				}
			end
		else
			fontsInThisResource[key].lastCall = getTickCount()
		end

		if not addedFontEvent then
			addedFontEvent = true
			addEventHandler("onClientFontsCleanup", root, cleanupFonts)
		end

		return fontsInThisResource[key].font
	end

	-- icons cache
	local addedIconsEvent
	local iconsInThisResource = {}
	local function cleanupIcons()
		local count = 0
		local tick = getTickCount()
		for key, data in pairs(iconsInThisResource) do
			if tick - data.lastCall >= 1000 then
				if isElement(data.icon) then
					destroyElement(data.icon)
				end
				iconsInThisResource[key] = nil
			else
				count = count + 1
			end
		end

		if count == 0 then
			removeEventHandler("onClientFontsCleanup", root, cleanupIcons)
			addedIconsEvent = false
		end
	end

	function getIcon(name)
		if not iconsInThisResource[name] then
			iconsInThisResource[name] = {
				icon = exports["ex_icons"]:getIcon(name),
				lastCall = getTickCount()
			}
		else
			iconsInThisResource[name].lastCall = getTickCount()
		end

		if not addedIconsEvent then
			addedIconsEvent = true
			addEventHandler("onClientFontsCleanup", root, cleanupIcons)
		end

		return iconsInThisResource[name].icon
	end

	-- ha megint elbasznák csak ezt kell visszarakni + szerverrestart
	--function createBuilding(model, x, y, z, rx, ry, rz, int)
	--	local obj = createObject(model, x, y, z, rx, ry, rz)
	--	if obj then
	--		setElementDimension(obj, -1)
	--		setElementInterior(obj, int or 0)
	--	end
	--	return obj
	--end


local _createVehicle = createVehicle
function createVehicle(model, x, y, z, rx, ry, rz, numberplate, bDirection, variant1, variant2, synced)
    variant1 = tonumber(variant1) or 255
    variant2 = tonumber(variant2) or 255

    if (variant1 < 0 or variant1 > 255) then error("Invalid variant1 value: must be between 0 and 255, got " .. tostring(variant1)) end
    if (variant2 < 0 or variant2 > 255) then error("Invalid variant2 value: must be between 0 and 255, got " .. tostring(variant2)) end
    
    local v1IsCustom = variant1 >= 6 and variant1 <= 254
    local v2IsCustom = variant2 >= 6 and variant2 <= 254

    local vehicle
    
        vehicle = _createVehicle(model, x, y, z, rx, ry, rz, numberplate, (v1IsCustom and 255 or variant1), (v2IsCustom and 255 or variant2))
    

    if vehicle and (v1IsCustom or v2IsCustom) then
        setVehicleVariant(vehicle, variant1, variant2)
    end
    
    return vehicle
end

local _getVehicleVariant = getVehicleVariant
function getVehicleVariant(vehicle)
    local custom = getElementData(vehicle, "veh:customVariant")
    if type(custom) == "table" then
        return tonumber(custom[1]) or 255, tonumber(custom[2]) or 255
    end
    
    return _getVehicleVariant(vehicle)
end

local _setVehicleVariant = setVehicleVariant
function setVehicleVariant(vehicle, variant1, variant2)
    local v1 = tonumber(variant1)
    local v2 = tonumber(variant2)

    if v1 and (v1 < 0 or v1 > 255) then error("Invalid variant1 value: must be between 0 and 255, got " .. tostring(v1)) end
    if v2 and (v2 < 0 or v2 > 255) then error("Invalid variant2 value: must be between 0 and 255, got " .. tostring(v2)) end

    v1 = v1 or 255
    v2 = v2 or 255
    
    local v1IsCustom = v1 >= 6 and v1 <= 254
    local v2IsCustom = v2 >= 6 and v2 <= 254

    if v1IsCustom or v2IsCustom then
        return setElementData(vehicle, "veh:customVariant", {v1, v2})
    else
        if localPlayer then
            setElementData(vehicle, "veh:customVariant", nil)
        else
            removeElementData(vehicle, "veh:customVariant")
        end
        return _setVehicleVariant(vehicle, v1, v2)
    end
end
