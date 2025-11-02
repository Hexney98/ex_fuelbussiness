-- server.lua
-- Full-featured server-side for ex_fuel_bussiness (MTA)
-- MySQL-backed, integrated with sCore exports for economy

-- ======= CONFIG =======
local SHOPS_TABLE = "fuel_business_shops"   -- táblanév az adatbázisban
local AUTO_CREATE_TABLE = true              -- ha true: létrehozza a táblát ha nem létezik
local DATA_SAVE_INTERVAL = 60 * 1000        -- automatikus mentés (ms) - opcionális
-- ======================

-- utilities: JSON encode/decode (MTA builtins)
local function encodeJSON(t)
    return toJSON(t)
end
local function decodeJSON(s)
    return fromJSON(s)
end

-- get a DB connection (tries global getConnection(), then exports.mysql:getConnection())
local function getDB()
    if type(getConnection) == "function" then
        return getConnection()
    end
    if exports and exports.mysql and type(exports.mysql.getConnection) == "function" then
        return exports.mysql:getConnection()
    end
    return nil
end

-- run a query with the local "connection" (uses dbExec/dbQuery directly)
local function safeDBExec(query, ...)
    local conn = getDB()
    if not conn then
        outputDebugString("[ex_fuel_bussiness] DB connection not available (dbExec).", 1)
        return false
    end
    return dbExec(conn, query, ...)
end

local function safeDBQuery(callback, query, ...)
    local conn = getDB()
    if not conn then
        outputDebugString("[ex_fuel_bussiness] DB connection not available (dbQuery).", 1)
        if callback then callback(false) end
        return nil
    end
    return dbQuery(callback, conn, query, ...)
end

-- in-memory cache of shops
local Shops = {}

-- Create DB table if missing (simple table: shopID INT PK, data TEXT JSON)
local function ensureTable()
    if not AUTO_CREATE_TABLE then return end
    local conn = getDB()
    if not conn then
        outputDebugString("[ex_fuel_bussiness] ensureTable: no DB connection.", 1)
        return
    end
    local q = [[
        CREATE TABLE IF NOT EXISTS `]]..SHOPS_TABLE..[[` (
            `shopID` INT NOT NULL PRIMARY KEY,
            `data` LONGTEXT NOT NULL
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]]
    dbExec(conn, q)
end

-- Load all shops from DB into Shops table
local function loadAllShops()
    Shops = {}
    local conn = getDB()
    if not conn then
        outputDebugString("[ex_fuel_bussiness] loadAllShops: no DB connection.", 1)
        return
    end
    local q = "SELECT shopID, data FROM `" .. SHOPS_TABLE .. "`;"
    local handle = dbQuery(conn, q)
    if not handle then return end
    local result = dbPoll(handle, 5)
    if not result then return end
    for _, row in ipairs(result) do
        local shopID = tostring(row.shopID)
        local ok, decoded = pcall(decodeJSON, row.data)
        if ok and decoded then
            Shops[shopID] = decoded
        else
            outputDebugString("[ex_fuel_bussiness] loadAllShops: JSON parse failed for shop " .. shopID, 2)
        end
    end
    outputDebugString("[ex_fuel_bussiness] Loaded " .. tostring(#(result or {})) .. " shops from DB.")
end

-- Save a single shop back to DB
local function saveShopToDB(shopID)
    shopID = tostring(shopID)
    local shop = Shops[shopID]
    if not shop then
        outputDebugString("[ex_fuel_bussiness] saveShopToDB: no shop " .. shopID, 2)
        return false
    end
    local data = encodeJSON(shop)
    local conn = getDB()
    if not conn then
        outputDebugString("[ex_fuel_bussiness] saveShopToDB: no DB connection.", 1)
        return false
    end
    -- Use INSERT ... ON DUPLICATE KEY UPDATE
    local q = "INSERT INTO `"..SHOPS_TABLE.."` (`shopID`,`data`) VALUES (?,?) ON DUPLICATE KEY UPDATE `data` = VALUES(`data`);"
    local success = dbExec(conn, q, tonumber(shopID), data)
    if not success then
        outputDebugString("[ex_fuel_bussiness] Failed to save shop " .. shopID, 1)
    end
    return success
end

-- Save all shops
local function saveAllShops()
    for k,_ in pairs(Shops) do
        saveShopToDB(k)
    end
    outputDebugString("[ex_fuel_bussiness] All shops saved.")
end

-- Create a default shop template (so a shop always has required fields)
local function defaultShopTemplate(shopID)
    return {
        shopID = tonumber(shopID),
        bussinessName = "Benzinkút #" .. tostring(shopID),
        bussinessOwner = 0, -- char.ID of owner
        storageCapacity = 500,
        maxStorageItems = 8,
        productData = {
            { itemID = "diesel", itemName = "Diesel", price = 10, availableStock = 400 },
            { itemID = "benzin", itemName = "Benzin", price = 10, availableStock = 400 },
            { itemID = "benzin_plus", itemName = "Benzin plus", price = 10, availableStock = 20 },
        },
        offersData = {},
        generatedMarketSupply = { lastGeneratedTime = 0, refreshTime = 3600, marketTable = {} },
        orderList = {},
        permissionData = {},
        officePosition = nil,
        storagePositionData = {},
        shopPrice = 100000
    }
end

-- Get or create shop in memory
local function getShop(shopID, createIfMissing)
    if not shopID then return nil end
    local sid = tostring(shopID)
    if Shops[sid] then return Shops[sid] end
    if createIfMissing then
        Shops[sid] = defaultShopTemplate(sid)
        -- persist immediately
        saveShopToDB(sid)
        return Shops[sid]
    end
    return nil
end

-- Helper: get player's char ID
local function getPlayerCharID(player)
    if not isElement(player) then return nil end
    return tonumber(getElementData(player, "char.ID")) or nil
end

-- Helper: economy operations using sCore exports (fall back safe checks)
local function getPlayerCash(player)
    if exports and exports.sCore and type(exports.sCore.getMoney) == "function" then
        return exports.sCore:getMoney(player)
    end
    -- fallback: try element data
    return (getElementData(player, "money") or 0)
end

local function setPlayerCash(player, amount)
    if exports and exports.sCore and type(exports.sCore.setMoney) == "function" then
        exports.sCore:setMoney(player, amount)
        return true
    end
    if isElement(player) then
        setElementData(player, "money", amount)
        triggerClientEvent(player, "refreshMoney", player, amount)
        return true
    end
    return false
end

local function takePlayerCash(player, amount)
    amount = tonumber(amount) or 0
    local cash = getPlayerCash(player) or 0
    if cash < amount then return false end
    return setPlayerCash(player, cash - amount)
end

local function givePlayerCash(player, amount)
    amount = tonumber(amount) or 0
    local cash = getPlayerCash(player) or 0
    return setPlayerCash(player, cash + amount)
end

local function getPlayerBank(player)
    if exports and exports.sCore and type(exports.sCore.getBankMoney) == "function" then
        return exports.sCore:getBankMoney(player)
    end
    return (getElementData(player, "bankMoney") or 0)
end

local function takePlayerBank(player, amount)
    if exports and exports.sCore and type(exports.sCore.takeBankMoney) == "function" then
        return exports.sCore:takeBankMoney(player, amount)
    end
    -- fallback
    local b = getPlayerBank(player) or 0
    if b < amount then return false end
    if exports and exports.sCore and type(exports.sCore.setBankMoney) == "function" then
        exports.sCore:setBankMoney(player, b - amount)
        return true
    end
    setElementData(player, "bankMoney", b - amount)
    triggerClientEvent(player, "refreshBankMoney", player, b - amount)
    return true
end

local function givePlayerBank(player, amount)
    if exports and exports.sCore and type(exports.sCore.giveBankMoney) == "function" then
        return exports.sCore:giveBankMoney(player, amount)
    end
    local b = getPlayerBank(player) or 0
    if exports and exports.sCore and type(exports.sCore.setBankMoney) == "function" then
        exports.sCore:setBankMoney(player, b + amount)
        return true
    end
    setElementData(player, "bankMoney", b + amount)
    triggerClientEvent(player, "refreshBankMoney", player, b + amount)
    return true
end

-- Permission helpers: owner check (uses bussinessOwner == charID)
local function isOwner(player, shop)
    local cid = getPlayerCharID(player)
    if not cid then return false end
    return shop and (shop.bussinessOwner == cid)
end

local function isAdmin(player)
    -- try common admin exports first (safer when servers use custom admin resources)
    if exports and exports.Admin and type(exports.Admin.IsHeadAdmin) == "function" then
        return exports.Admin:IsHeadAdmin(player)
    end
    if exports and exports.admin and type(exports.admin.IsPlayerAdmin) == "function" then
        return exports.admin:IsPlayerAdmin(player)
    end
    -- fallback to ACL group check
    local acc = getPlayerAccount(player)
    if not acc then return false end
    return isObjectInACLGroup("user." .. getAccountName(acc), aclGetGroup("Admin"))
end

-- ========== VALIDATORS ==========
local function isArray(t)
    if type(t) ~= "table" then return false end
    local i = 0
    for k,_ in pairs(t) do
        i = i + 1
        if t[i] == nil then return false end
    end
    return true
end

local function validateProductData(tbl)
    if type(tbl) ~= "table" then return false end
    for _, prod in ipairs(tbl) do
        if type(prod.itemID) ~= "string" then return false end
        if type(prod.itemName) ~= "string" and type(prod.itemName) ~= "nil" then return false end
        if type(prod.price) ~= "number" or prod.price < 0 then return false end
        if type(prod.availableStock) ~= "number" or prod.availableStock < 0 then return false end
    end
    return true
end

local function validatePermissionData(tbl)
    return type(tbl) == "table"
end

local function validateStoragePositionData(tbl)
    return type(tbl) == "table"
end

local function validateOffersData(tbl)
    return type(tbl) == "table"
end

local function validateShopName(name)
    return type(name) == "string" and #name > 0 and #name <= 45
end

local function validateOrderData(orderData)
    if type(orderData) ~= "table" then return false end
    if type(orderData.totalPrice) ~= "number" or orderData.totalPrice < 0 then return false end
    if type(orderData.items) ~= "table" then return false end
    for _, it in ipairs(orderData.items) do
        if type(it.itemID) ~= "string" then return false end
        if type(it.amount) ~= "number" or it.amount <= 0 then return false end
        if type(it.price) ~= "number" or it.price < 0 then return false end
    end
    return true
end

-- ========== EVENTS ========== 

-- Request shop data (computer open)
addEvent("requestFuelBussinessComputerData", true)
addEventHandler("requestFuelBussinessComputerData", resourceRoot, function(requestingPlayer, shopID)
    local src = client or source
    if not isElement(src) then return end
    -- do NOT auto-create shops on client request; only return existing data
    local shop = getShop(shopID, false)
    if not shop then
        triggerClientEvent(src, "receiveFuelComputerData", resourceRoot, nil)
        return
    end
    -- send deep copy to client to avoid tampering
    local copy = decodeJSON(encodeJSON(shop))
    triggerClientEvent(src, "receiveFuelComputerData", resourceRoot, copy)
end)

-- Purchase a shop
addEvent("requestFuelBussinessPurchase", true)
addEventHandler("requestFuelBussinessPurchase", resourceRoot, function(requestingPlayer, shopID, price, useBank)
    local src = client or source
    if not isElement(src) then return end
    local shop = getShop(shopID, true)
    local cid = getPlayerCharID(src)
    if not cid then
        triggerClientEvent(src, "fuelSys:clientExitShop", resourceRoot, false, "Nincs karakter azonosító.")
        return
    end
    if shop.bussinessOwner and shop.bussinessOwner ~= 0 then
        triggerClientEvent(src, "fuelSys:clientExitShop", resourceRoot, false, "Ez a benzinkút már meg van véve.")
        return
    end
    price = tonumber(price) or tonumber(shop.shopPrice) or 0
    local charged = false
    if useBank then
        if takePlayerBank(src, price) then charged = true end
    else
        if takePlayerCash(src, price) then charged = true end
    end
    if not charged then
        triggerClientEvent(src, "fuelSys:clientExitShop", resourceRoot, false, "Nincs elég pénz.")
        return
    end
    -- set owner and persist; if DB save fails, rollback and refund
    shop.bussinessOwner = cid
    local ok = saveShopToDB(shopID)
    if not ok then
        -- rollback
        shop.bussinessOwner = 0
        if useBank then
            givePlayerBank(src, price)
        else
            givePlayerCash(src, price)
        end
        triggerClientEvent(src, "fuelSys:clientExitShop", resourceRoot, false, "Szerverhiba: nem sikerült menteni a tranzakciót. Visszatérítettük a pénzt.")
        outputDebugString("[ex_fuel_bussiness] Failed to persist shop purchase for shop "..tostring(shopID), 1)
        return
    end
    triggerClientEvent(src, "fuelSys:clientExitShop", resourceRoot, true, "Sikeres vásárlás.")
    outputDebugString("[ex_fuel_bussiness] Player charID "..tostring(cid) .." bought shop "..tostring(shopID))
end)

-- Update shop data (productData, permissionData, offersData, shopName, storagePositionData)
addEvent("updateFuelBussinessData", true)
addEventHandler("updateFuelBussinessData", resourceRoot, function(requestingPlayer, shopID, payload, dataType)
    local src = client or source
    if not isElement(src) then return end
    local shop = getShop(shopID, false)
    if not shop then
        outputDebugString("[ex_fuel_bussiness] updateFuelBussinessData called for unknown shop "..tostring(shopID), 2)
        return
    end
    local cid = getPlayerCharID(src)
    if not cid then return end
    local allowed = (shop.bussinessOwner == cid) or isAdmin(src)
    if not allowed then
        outputDebugString("[ex_fuel_bussiness] Unauthorized update attempt by "..tostring(getPlayerName(src)), 2)
        return
    end

    local allowedTypes = {
        productData = true,
        permissionData = true,
        storagePositionData = true,
        offersData = true,
        shopName = true,
        storageCapacity = true,
        maxStorageItems = true,
    }

    if not allowedTypes[dataType] then
        outputDebugString("[ex_fuel_bussiness] updateFuelBussinessData: forbidden dataType "..tostring(dataType), 2)
        return
    end

    -- validate based on type
    if dataType == "productData" then
        if not validateProductData(payload) then
            outputDebugString("[ex_fuel_bussiness] Invalid productData payload from "..tostring(getPlayerName(src)), 2)
            return
        end
        shop.productData = payload or {}
    elseif dataType == "permissionData" then
        if not validatePermissionData(payload) then return end
        shop.permissionData = payload or {}
    elseif dataType == "storagePositionData" then
        if not validateStoragePositionData(payload) then return end
        shop.storagePositionData = payload or {}
    elseif dataType == "offersData" then
        if not validateOffersData(payload) then return end
        shop.offersData = payload or {}
    elseif dataType == "shopName" then
        if not validateShopName(payload) then return end
        shop.bussinessName = tostring(payload or shop.bussinessName)
    elseif dataType == "storageCapacity" then
        local v = tonumber(payload)
        if not v or v < 0 then return end
        shop.storageCapacity = v
    elseif dataType == "maxStorageItems" then
        local v = tonumber(payload)
        if not v or v < 0 then return end
        shop.maxStorageItems = v
    end

    local ok = saveShopToDB(shopID)
    if not ok then
        outputDebugString("[ex_fuel_bussiness] Failed to save shop after update "..tostring(shopID), 1)
        -- optionally notify client
        triggerClientEvent(src, "receiveFuelComputerData", resourceRoot, nil)
        return
    end

    -- send updated data back to the requester
    triggerClientEvent(src, "receiveFuelComputerData", resourceRoot, decodeJSON(encodeJSON(shop)))
    outputDebugString("[ex_fuel_bussiness] shop "..tostring(shopID) .." updated by "..tostring(cid))
end)

-- Refresh offers from client
addEvent("refreshFuelOffersServer", true)
addEventHandler("refreshFuelOffersServer", resourceRoot, function(requestingPlayer, shopID, newOffers)
    local src = client or source
    if not isElement(src) then return end
    local shop = getShop(shopID, false)
    if not shop then return end
    local cid = getPlayerCharID(src)
    if not cid then return end
    local allowed = (shop.bussinessOwner == cid) or isAdmin(src)
    if not allowed then return end
    if not validateOffersData(newOffers) then return end
    shop.offersData = newOffers or {}
    saveShopToDB(shopID)
    triggerClientEvent(src, "refreshFuelOffersClient", resourceRoot, shop.offersData)
end)

-- Check and purchase extra capacity
addEvent("checkFuelCapacityPurchaseServer", true)
addEventHandler("checkFuelCapacityPurchaseServer", resourceRoot, function(requestingPlayer, shopID, priceType, productIndex, useBank)
    local src = client or source
    if not isElement(src) then return end
    local shop = getShop(shopID, false)
    if not shop then return end
    local cid = getPlayerCharID(src)
    if not cid then return end
    local allowed = (shop.bussinessOwner == cid) or isAdmin(src)
    if not allowed then
        triggerClientEvent(src, "showFuelCapacityPurchaseResult", resourceRoot, false, 0)
        return
    end
    -- example: determine price by priceType or productIndex (client may send it)
    local addAmount = 100
    local price = tonumber(priceType) or 50000 -- fallback price
    local charged = false
    if useBank then
        charged = takePlayerBank(src, price)
    else
        charged = takePlayerCash(src, price)
    end
    if not charged then
        triggerClientEvent(src, "showFuelCapacityPurchaseResult", resourceRoot, false, 0)
        return
    end
    shop.storageCapacity = (shop.storageCapacity or 0) + addAmount
    local ok = saveShopToDB(shopID)
    if not ok then
        -- rollback
        shop.storageCapacity = (shop.storageCapacity or 0) - addAmount
        if useBank then givePlayerBank(src, price) else givePlayerCash(src, price) end
        triggerClientEvent(src, "showFuelCapacityPurchaseResult", resourceRoot, false, 0)
        return
    end
    triggerClientEvent(src, "receiveFuelComputerData", resourceRoot, decodeJSON(encodeJSON(shop)))
    triggerClientEvent(src, "showFuelCapacityPurchaseResult", resourceRoot, true, addAmount)
end)

-- Add stock by admin/owner (e.g., when receiving order)
addEvent("addFuelOrderProductToStorage", true)
addEventHandler("addFuelOrderProductToStorage", resourceRoot, function(requestingPlayer, shopID, itemID, amount)
    local src = client or source
    if not isElement(src) then return end
    local shop = getShop(shopID, false)
    if not shop then return end
    local cid = getPlayerCharID(src)
    if not cid then return end
    local allowed = (shop.bussinessOwner == cid) or isAdmin(src)
    if not allowed then return end

    amount = tonumber(amount) or 0
    if amount <= 0 then return end
    -- find product
    local found = false
    for _, prod in ipairs(shop.productData) do
        if prod.itemID == itemID then
            prod.availableStock = (prod.availableStock or 0) + amount
            found = true
            break
        end
    end
    if not found then
        table.insert(shop.productData, { itemID = itemID, itemName = itemID, price = 0, availableStock = amount })
    end
    local ok = saveShopToDB(shopID)
    if not ok then
        outputDebugString("[ex_fuel_bussiness] Failed to save shop after adding stock "..tostring(shopID), 1)
        return
    end
    triggerClientEvent(src, "receiveFuelComputerData", resourceRoot, decodeJSON(encodeJSON(shop)))
end)

-- Finish an order (client notifies server that order finished)
addEvent("checkFinishFuelOrderServer", true)
addEventHandler("checkFinishFuelOrderServer", resourceRoot, function(requestingPlayer, shopID, orderID, priceTag, copyTable, generatedMarketSupply)
    local src = client or source
    if not isElement(src) then return end
    local shop = getShop(shopID, false)
    if not shop then return end
    local cid = getPlayerCharID(src)
    if not cid then return end
    local allowed = (shop.bussinessOwner == cid) or isAdmin(src)
    if not allowed then
        triggerClientEvent(src, "orderFinishedClient", resourceRoot, false)
        return
    end

    -- find and remove order
    local orderIndex = nil
    for i, o in ipairs(shop.orderList or {}) do
        if tostring(o.orderID) == tostring(orderID) then orderIndex = i; break end
    end
    if not orderIndex then
        triggerClientEvent(src, "orderFinishedClient", resourceRoot, false)
        return
    end
    local order = table.remove(shop.orderList, orderIndex)
    -- add items to stock
    for _, it in ipairs(order.items or {}) do
        local added = false
        for _, prod in ipairs(shop.productData) do
            if prod.itemID == it.itemID then
                prod.availableStock = (prod.availableStock or 0) + (tonumber(it.amount) or 0)
                added = true
                break
            end
        end
        if not added then
            table.insert(shop.productData, { itemID = it.itemID, itemName = it.itemName or it.itemID, price = it.price or 0, availableStock = tonumber(it.amount) or 0 })
        end
    end

    local ok = saveShopToDB(shopID)
    if not ok then
        -- rollback: reinsert order and revert product changes is complex; notify and reinsert order
        table.insert(shop.orderList, orderIndex, order)
        triggerClientEvent(src, "orderFinishedClient", resourceRoot, false)
        outputDebugString("[ex_fuel_bussiness] Failed to persist finished order for shop "..tostring(shopID), 1)
        return
    end
    triggerClientEvent(src, "receiveFuelComputerData", resourceRoot, decodeJSON(encodeJSON(shop)))
    triggerClientEvent(src, "orderFinishedClient", resourceRoot, orderID)
end)

-- Create an order from player (customer buys product to add to shop order list, or owner orders from supplier)
addEvent("createFuelOrderServer", true)
addEventHandler("createFuelOrderServer", resourceRoot, function(requestingPlayer, shopID, orderData, useBank)
    local src = client or source
    if not isElement(src) then return end
    local shop = getShop(shopID, false)
    if not shop then return end
    -- validate order structure
    if not validateOrderData(orderData) then
        triggerClientEvent(src, "createFuelOrderResult", resourceRoot, false, "Érvénytelen rendelés adatok.")
        return
    end
    local total = tonumber(orderData.totalPrice) or 0
    local charged = false
    if total > 0 then
        if useBank then
            charged = takePlayerBank(src, total)
        else
            charged = takePlayerCash(src, total)
        end
        if not charged then
            triggerClientEvent(src, "createFuelOrderResult", resourceRoot, false, "Nincs elég pénz.")
            return
        end
    end
    -- generate unique orderID
    local orderID
    repeat
        orderID = tostring(os.time()) .. tostring(math.random(100,999))
        local exists = false
        for _, o in ipairs(shop.orderList or {}) do
            if tostring(o.orderID) == orderID then exists = true; break end
        end
    until not exists

    local order = {
        orderID = orderID,
        items = orderData.items or {},
        totalPrice = total,
        createdAt = os.time(),
        createdBy = getPlayerCharID(src)
    }
    table.insert(shop.orderList, order)
    local ok = saveShopToDB(shopID)
    if not ok then
        -- refund if needed and remove order
        table.remove(shop.orderList)
        if charged then
            if useBank then givePlayerBank(src, total) else givePlayerCash(src, total) end
        end
        triggerClientEvent(src, "createFuelOrderResult", resourceRoot, false, "Szerverhiba: nem sikerült rögzíteni a rendelést. Visszatérítettük a pénzt.")
        return
    end
    triggerClientEvent(src, "createFuelOrderResult", resourceRoot, true, orderID)
    outputDebugString("[ex_fuel_bussiness] New order "..orderID.." for shop "..tostring(shopID))
end)

-- Set office position
addEvent("setFuelBussinessOfficePosition", true)
addEventHandler("setFuelBussinessOfficePosition", resourceRoot, function(requestingPlayer, shopID, position)
    local src = client or source
    if not isElement(src) then return end
    local shop = getShop(shopID, false)
    if not shop then return end
    local cid = getPlayerCharID(src)
    if not cid then return end
    if shop.bussinessOwner ~= cid and not isAdmin(src) then
        return
    end
    shop.officePosition = position
    saveShopToDB(shopID)
    triggerClientEvent(src, "receiveFuelOfficeDataOnEnter", resourceRoot, position)
end)

-- Optional: admin command to create default shop if missing
addCommandHandler("createfuelshop", function(player, cmd, shopID)
    if not isAdmin(player) then
        outputChatBox("Nincs jogod ehhez a parancshoz.", player, 255,0,0)
        return
    end
    if not shopID then
        outputChatBox("Használat: /createfuelshop <shopID>", player, 255,200,0)
        return
    end
    shopID = tostring(shopID)
    if Shops[shopID] then
        outputChatBox("Már létezik shop "..shopID, player, 255,200,0)
        return
    end
    Shops[shopID] = defaultShopTemplate(shopID)
    saveShopToDB(shopID)
    outputChatBox("Létrehozva shop "..shopID, player, 0,255,0)
end)

-- Save all shops on resource stop
addEventHandler("onResourceStop", resourceRoot, function()
    saveAllShops()
end)

-- initialize on resource start
addEventHandler("onResourceStart", resourceRoot, function()
    ensureTable()
    loadAllShops()
    -- optional: timer to autosave
    setTimer(function() saveAllShops() end, DATA_SAVE_INTERVAL, 0)
    outputDebugString("[ex_fuel_bussiness] Resource started and shops loaded.")
end)