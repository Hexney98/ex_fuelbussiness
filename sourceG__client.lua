-- NOTE: Variables For Bussiness Shops :

AddExportReference({
	Fonts = "fonts", Database = "mysql", OldCore = "core", Deliver = "job_deliver", Admin = "admin", Dashboard = "dashboard",
	Inventory = "inventory", Gui = "gui", Farmer = "job_farmer", Logs = "logs", Core = "new_core", Anticheat = "anticheat",
	Interior = "interior", Utility = "utility", StoreRob = "storerob", Skin = "skin", SkinShop = "skinshop", Chat = "chat",
	Fuel = "fuel", JobTruckdriver = "job_truckdriver", Account = "account"
})

officeComputerPosition = {position = {1104.3232421875, -768.99487304688, 976.2771484375}, interior = 1}
maxFuelPrice = ({
	["v3"] = 600,
	["sa"] = 20000,
	["ng"] = 25
})["v3"]

taxFactions = ({
	["v3"] = {
		2, 27
	},
	["sa"] = {
		10
	},
	["ng"] = {
		2
	}
})["v3"]

defaultDatas = ({
	["v3"] = {
		maxStorageItems = 2, -- NOTE: How many types of items can the shop sell
		storageCapacity = {
			["benzin"] = 3000,
			["diesel"] = 3000,
			["benzin_plus"] = 3000,
			["diesel_plus"] = 3000,
			["kerosene"] = 3000,
		},
		plusStorageCapacityPrice = 2000, -- NOTE: Unit: dollar / amount
		plusItemTypesPrice = 3000, -- NOTE: Unit: PP / amount
		refreshMarketSupplyTime = 3600 * 8, -- NOTE: Unit: seconds , Default: 8 hours
		maximumOrderOneTime = 1, -- NOTE: How many types of items you can order at one time
		maximumOrderAmount = 55000, -- NOTE: How many items you can order
		orderDeliverDeleteTime = 86400 * 2, -- NOTE: The time the player has to deliver the order, after that time the order will be canceled
		depositTax = 0.05, -- NOTE: 5%
		withDrawTax = 0.01, -- NOTE: 1%
		changeBussinessNamePrice = 300000,
		bussinessNameMaxCharacters = 45, -- NOTE: How long the bussiness name can be
		globalDeliveryOffers = {minimum = 90, maximum = 110},
		respawnOffersTime = 43200000, -- NOTE: Unit: Milliseconds -> Default: 8 hours
		availableTimeForDelivery = 1000 * 60 * 15, -- NOTE: Unit: Milliseconds -> Default: 15 Minutes NOTE 2: It only applies for global delivery orders
		offerDeliveryWage = 7000, -- NOTE: This will be multiplied by the delivery products amount / 100
		refreshMarketCost = 5000,
	},
	["sa"] = {
		maxStorageItems = 2, -- NOTE: How many types of items can the shop sell
		storageCapacity = {
			["benzin"] = 6000,
			["diesel"] = 6000,
			["benzin_plus"] = 6000,
			["diesel_plus"] = 6000,
			["kerosene"] = 6000,
		},
		plusStorageCapacityPrice = 20000, -- NOTE: Unit: dollar / amount
		plusItemTypesPrice = 3000, -- NOTE: Unit: PP / amount
		refreshMarketSupplyTime = 3600 * 8, -- NOTE: Unit: seconds , Default: 8 hours
		maximumOrderOneTime = 1, -- NOTE: How many types of items you can order at one time
		maximumOrderAmount = 50000, -- NOTE: How many items you can order
		orderDeliverDeleteTime = 86400, -- NOTE: The time the player has to deliver the order, after that time the order will be canceled
		depositTax = 0.05, -- NOTE: 5%
		withDrawTax = 0.01, -- NOTE: 1%
		changeBussinessNamePrice = 300000,
		bussinessNameMaxCharacters = 45, -- NOTE: How long the bussiness name can be
		globalDeliveryOffers = {minimum = 90, maximum = 110},
		respawnOffersTime = 28800000, -- NOTE: Unit: Milliseconds -> Default: 8 hours
		availableTimeForDelivery = 1000 * 60 * 15, -- NOTE: Unit: Milliseconds -> Default: 15 Minutes NOTE 2: It only applies for global delivery orders
		offerDeliveryWage = 75000, -- NOTE: This will be multiplied by the delivery products amount / 100
		refreshMarketCost = 2000,
	},
	["ng"] = {
		maxStorageItems = 2, -- NOTE: How many types of items can the shop sell
		storageCapacity = {
			["benzin"] = 6000,
			["diesel"] = 6000,
			["benzin_plus"] = 6000,
			["diesel_plus"] = 6000,
			["kerosene"] = 6000,
		},
		plusStorageCapacityPrice = 100, -- NOTE: Unit: dollar / amount
		plusItemTypesPrice = 8000, -- NOTE: Unit: PP / amount
		refreshMarketSupplyTime = 3600 * 8, -- NOTE: Unit: seconds , Default: 8 hours
		maximumOrderOneTime = 1, -- NOTE: How many types of items you can order at one time
		maximumOrderAmount = 7500, -- NOTE: How many items you can order
		orderDeliverDeleteTime = 86400, -- NOTE: The time the player has to deliver the order, after that time the order will be canceled
		depositTax = 0.05, -- NOTE: 5%
		withDrawTax = 0.01, -- NOTE: 1%
		changeBussinessNamePrice = 10000,
		bussinessNameMaxCharacters = 45, -- NOTE: How long the bussiness name can be
		globalDeliveryOffers = {minimum = 5, maximum = 15},
		respawnOffersTime = 28800000, -- NOTE: Unit: Milliseconds -> Default: 8 hours
		availableTimeForDelivery = 1000 * 60 * 15, -- NOTE: Unit: Milliseconds -> Default: 15 Minutes NOTE 2: It only applies for global delivery orders
		offerDeliveryWage = 1000, -- NOTE: This will be multiplied by the delivery products amount / 100
		refreshMarketCost = 2000,
	},
})["v3"]

specialFuels = {
	["kerosene"] = "Kerozin"
}

itemNameToRealName = {
	["benzin"] = "Benzin EVO",
	["diesel"] = "Diesel EVO",
	["benzin_plus"] = "Benzin EVO Plus",
	["diesel_plus"] = "Diesel EVO Plus",
	["kerosene"] = "Kerozin",
}

allAvailableMarketItems = ({
	["v3"] = {
		{itemName = "Benzin EVO", itemID = "benzin", price = 2},
		{itemName = "Diesel EVO", itemID = "diesel", price = 3},
		{itemName = "Benzin EVO Plus", itemID = "benzin_plus", price = 4},
		{itemName = "Diesel EVO Plus", itemID = "diesel_plus", price = 5},
		{itemName = "Kerozin", itemID = "kerosene", price = 10},
	},
	["sa"] = {
		{itemName = "Benzin EVO", itemID = "benzin", price = 100},
		{itemName = "Diesel EVO", itemID = "diesel", price = 120},
		{itemName = "Benzin EVO Plus", itemID = "benzin_plus", price = 140},
		{itemName = "Diesel EVO Plus", itemID = "diesel_plus", price = 190},
		{itemName = "Kerozin", itemID = "kerosene", price = 500},
	},
	["ng"] = {
		{itemName = "Benzin EVO", itemID = "benzin", price = 5},
		{itemName = "Diesel EVO", itemID = "diesel", price = 5},
		{itemName = "Benzin EVO Plus", itemID = "benzin_plus", price = 10},
		{itemName = "Diesel EVO Plus", itemID = "diesel_plus", price = 10},
		{itemName = "Kerozin", itemID = "kerosene", price = 20},
	},
})["v3"]

deliveryPositions = ({
	["v3"] = {
		{position = {-149.72244262695, -222.0721282959, 0.421875}, rotation = 0},
		{position = {-77.329536437988, -75.056793212891, 2.1171875}, rotation = -45},
		{position = {-1841.5286865234, -99.308815002441, 14.109375}, rotation = -165},
	},
	["sa"] = {
		{position = {-149.72244262695, -222.0721282959, 0.421875}, rotation = 0},
		{position = {-77.329536437988, -75.056793212891, 2.1171875}, rotation = -45},
	},
	["ng"] = {
		{position = {-149.72244262695, -222.0721282959, 0.421875}, rotation = 0},
		{position = {-77.329536437988, -75.056793212891, 2.1171875}, rotation = -45},
	},
})["v3"]

-- # Timestamp function from Wiki :

function isLeapYear(year)
    if year then year = math.floor(year)
    else year = getRealTime().year + 1900 end
    return ((year % 4 == 0 and year % 100 ~= 0) or year % 400 == 0)
end

function getTimestamp(year, month, day, hour, minute, second)
    -- initiate variables
    local monthseconds = { 2678400, 2419200, 2678400, 2592000, 2678400, 2592000, 2678400, 2678400, 2592000, 2678400, 2592000, 2678400 }
    local timestamp = 0
    local datetime = getRealTime()
    year, month, day = year or datetime.year + 1900, month or datetime.month + 1, day or datetime.monthday
    hour, minute, second = hour or datetime.hour, minute or datetime.minute, second or datetime.second

    -- calculate timestamp
    for i=1970, year-1 do timestamp = timestamp + (isLeapYear(i) and 31622400 or 31536000) end
    for i=1, month-1 do timestamp = timestamp + ((isLeapYear(year) and i == 2) and 2505600 or monthseconds[i]) end
    timestamp = timestamp + 86400 * (day - 1) + 3600 * hour + 60 * minute + second

    timestamp = timestamp - 3600 --GMT+1 compensation
    if datetime.isdst then timestamp = timestamp - 3600 end

    return timestamp
end

function isGasStationLocked(id)
	local data = getElementData(root, "lockedGasStations") or {}
	if data then
		if data[id] then
			return true, data[id]
		end
	end
	return false
end
