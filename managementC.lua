managementData = {
	showComputer = false,
	shopID = 54,
	activePage = 0,
	availableApps = {"inventory list", "oil market", "rendelések", "alkalmazottak", "kiszállítás"},
	scrollStorageNumber = 0,
	scrollMarketNumber = 0,
	scrollOrdersNumber = 0,
	scrollOfferNumber = 0,
	maxShowableStorageItems = 4,
	maxMarketItemShowing = 4,
	maxShowAbleOrderItems = 16,
	maxShowAbleOfferItems = 14,
	validOffers = 0,
	-- # Render Values :
	computerW = respc(864),
	computerH = respc(484),
	closeComputerSize = respc(24),
	appsBorderGap = respc(10),
	gapBetweenApps = respc(25),
	appSize = respc(65),
	inventoryBorder = respc(15),
	closeAppSize = respc(14),
	headerGap = respc(45),
	headerItemsGap = respc(40),
	itemListHeaderY = respc(115),
	itemListHeaderH = respc(15),
	inventoryItemSize = respc(32),
	inventoryItemGap = respc(10),
	inventoryButtonW = respc(115),
	inventoryButtonH = respc(20),
	notificationTextY = respc(55),
	notificationCenterY = respc(30),
	notificationW = respc(450),
	notificationSumY = respc(45),
	checkOrderH = respc(20),
	checkOrderW = respc(170),
	searchBarY = respc(50),
	marketItemFrameW = respc(197),
	marketItemFrameH = respc(85),
	marketItemGap = respc(15),
	marketOrderButtonH = respc(20),
	itemSize = respc(35),
	orderHeaderGap = respc(45),
	orderElementH = respc(25),
	offerHeaderGap = respc(95),
	offerButtonW = respc(150),
	offerMoreButtonW = respc(80),
	settingsLeftW = respc(186),
	settingsLeftButtonGap = respc(15),
	settingsLeftButtonH = respc(27),
	settingsBankButtonH = respc(23),
	tickFrameSize = respc(13),
	fireButtonW = respc(100),
	fireButtonH = respc(20),
	statusW = respc(130),
	statusH = respc(30),
}

managementData.computerX = (screenX - managementData.computerW) / 2
managementData.computerY = (screenY - managementData.computerH) / 2

local sellBussinessData = {
	buyerElement = nil,
	bussinessCost = 0,
	sellPending = false,
}

local editData = {
	actualEditingPrice = 0,
	actualEditing = "",
	editingText = "",
	searchInputText = "Termék keresése...",
}

local notificationData = {
	state = false,
	title = "",
	description = "",
	productName = "",
	productIndex = 0,
	productCount = 0,
	priceTag = 1,
	priceType = "dollar", -- or premium
	acceptButtonText = "Vásárlás",
	acceptButtonDirectX = "",
	declineButtonText = "Elvetés",
	declineButtonDirectX = "",
	notificationAlpha = 0,
	notificationTick = 0,
	closeTimer = nil,
	editAbleCount = false,
}

computerData = {
	-- NOTE: structure
	bussinessName = "Kutas",
	storageCapacity = 500,
	maxStorageItems = 8,
	productData = {
		{
			itemID = "diesel",
			itemName = "Diesel",
			price = 10,
			availableStock = 400,
		},
		{
			itemID = "benzin",
			itemName = "Benzin",
			price = 10,
			availableStock = 300,
		},
		{
			itemID = "diesel_plus",
			itemName = "Diesel Plus",
			price = 10,
			availableStock = 200,
		},
		{
			itemID = "benzin_plus",
			itemName = "Benzin plus",
			price = 10,
			availableStock = 20,
		},
	},
}

local lastChangeCursorState = 0
local cursorState = false

function hasTruckerLicense()
    local hasLicense = Admin:isScripter(localPlayer)

    if (not hasLicense) then
		for Key, Data in pairs(Inventory:HasItem(_, 111, nil, true) or {}) do
			if (Data and Data.Item) then
				local Item = Data.Item
				if (Item and Item.ItemDatas and Item.ItemDatas.ItemValue) then
					local ItemValue = Inventory:GetItemTableValue(Item.ItemDatas.ItemValue)
					
					if (ItemValue[3] == "C+E" and not ItemValue.Copied) then
						hasLicense = true

						break
					end
				end
			end
		end
	end

    return hasLicense;
end

-- NOTE a mennyiséget szerveroldalon csak a véglegesítés után módosítjuk és akkor vesszük le a számláról a pénzt is
local shoppingCartData = {
	--{realIndex = 3, itemID = 73, price = 42, amount = 12, itemName = "Kancsó"},
}

-- NOTE: For test porpuses
--triggerServerEvent("updateFuelBussinessData", localPlayer, localPlayer, 54, computerData.productData, "productData")
-- triggerServerEvent("requestFuelBussinessComputerData", localPlayer, localPlayer, managementData.shopID)
--triggerServerEvent("addFuelOrderProductToStorage", localPlayer, localPlayer, 63, 4)

addEvent("receiveFuelComputerData", true)
addEventHandler("receiveFuelComputerData", root, function(data)
	computerData = data

	if (#shoppingCartData > 0) then
		Gui:showInfoBox("A rendszer frissítette a benzinkút adatait, így a kosárban lévő termékek törlésre kerültek!", "info", nil, nil, true);
	end
	shoppingCartData = {};
	if (managementData.showComputer) then return end

	managementData.showComputer = true
	managementData.activePage = 0

	addEventHandler("onClientClick", getRootElement(), notificationClick)
	addEventHandler("onClientClick", getRootElement(), computerClickHandler)
	addEventHandler("onClientRender", getRootElement(), renderComputer)
end)

addEvent("refreshFuelOffersClient", true)
addEventHandler("refreshFuelOffersClient", root, function(data)
	computerData.offersData = data
end)

addEvent("refreshFuelMarketClient", true)
addEventHandler("refreshFuelMarketClient", root, function(data)
	computerData.generatedMarketSupply = data
end)

function closeComputer()
	triggerServerEvent("closeFuelComputerServer", localPlayer, localPlayer, managementData.shopID)
	managementData.showComputer = false
	managementData.scrollStorageNumber = 0
	managementData.scrollMarketNumber = 0
	managementData.scrollOrdersNumber = 0
	shoppingCartData = {}
	computerData = {}
	removeEventHandler("onClientClick", getRootElement(), notificationClick)
	removeEventHandler("onClientClick", getRootElement(), computerClickHandler)
	removeEventHandler("onClientRender", getRootElement(), renderComputer)
	limitActionTimer = getTickCount()
end

function setBackfuelOrderStatusClient(bussinessID, orderID, status)
	triggerServerEvent("setBackFuelOrderStatus", localPlayer, localPlayer, bussinessID, orderID, status)
end

-- # Computer Management # --

function renderComputer()
	if not managementData.showComputer then return end
	renderData.activeDirectX = ""
	local time = getTickCount() - lastChangeCursorState
	if time >= 500 then
		cursorState = not cursorState
		lastChangeCursorState = getTickCount()
	end

	-- # Desktop
	dxDrawFrame(managementData.computerX, managementData.computerY, managementData.computerW, managementData.computerH, respc(6), tocolor(10,10,10,255))
	if managementData.activePage == 0 then
		local actualTime = getCorrectTimeFormat()
		dxDrawImage(managementData.computerX, managementData.computerY, managementData.computerW, managementData.computerH, "files/computer/win_background.png")
		dxDrawCorrectText(actualTime, managementData.computerX + managementData.computerW - respc(85), managementData.computerY + managementData.computerH - respc(34), respc(85), respc(34), tocolor(10,10,10,255), 1, getFont("Roboto-Light", resp(9)), "center", "center")
		dxDrawSmoothButtonImage("closeComputer", managementData.computerX + managementData.computerW - managementData.closeComputerSize - managementData.appsBorderGap, managementData.computerY + managementData.appsBorderGap, managementData.closeComputerSize, managementData.closeComputerSize,"files/computer/close_computer.png", {200,200,200,150}, {198, 59, 59, 255})
		-- # Draw App Icons
		for index = 1, #managementData.availableApps do
			if isCursorInBox(managementData.computerX + managementData.appsBorderGap, managementData.computerY + managementData.appsBorderGap + (managementData.gapBetweenApps + managementData.appSize) * (index - 1), managementData.appSize, managementData.appSize) then
				renderData.activeDirectX = "app_"..index
				dxDrawRectangle(managementData.computerX + managementData.appsBorderGap, managementData.computerY + managementData.appsBorderGap + (managementData.gapBetweenApps + managementData.appSize) * (index - 1), managementData.appSize, managementData.appSize, tocolor(59, 183, 245, 255))
				dxDrawFrame(managementData.computerX + managementData.appsBorderGap, managementData.computerY + managementData.appsBorderGap + (managementData.gapBetweenApps + managementData.appSize) * (index - 1), managementData.appSize, managementData.appSize, 1, tocolor(147, 213, 238, 255))
			end
			dxDrawImage(managementData.computerX + managementData.appsBorderGap, managementData.computerY + managementData.appsBorderGap + (managementData.gapBetweenApps + managementData.appSize) * (index - 1), managementData.appSize, managementData.appSize, "files/computer/apps/"..index..".png")
		end
	elseif managementData.activePage == 1 then
		-- # Draw 1st App : Inventory List
		dxDrawRectangle(managementData.computerX, managementData.computerY, managementData.computerW, managementData.computerH, tocolor(242, 224, 192, 255))
		dxDrawCorrectText(utf8.upper(managementData.availableApps[managementData.activePage]), managementData.computerX + managementData.inventoryBorder, managementData.computerY + managementData.inventoryBorder, 0, 0, tocolor(10,10,10,255), 1, getFont("Roboto", resp(12)), "left", "top")
		dxDrawRectangle(managementData.computerX + managementData.inventoryBorder, managementData.computerY + respc(40), managementData.computerW - managementData.inventoryBorder*2, respc(2), tocolor(10, 10, 10, 255))
		dxDrawSmoothButtonImage("closeAppPage", managementData.computerX + managementData.computerW - managementData.inventoryBorder - managementData.closeAppSize, managementData.computerY + respc(20), managementData.closeAppSize, managementData.closeAppSize,"files/computer/close.png", {10,10,10,255}, {198, 59, 59, 255})
		-- # Header section
		dxDrawCorrectText("TELJES BEVÉTEL", managementData.computerX + managementData.inventoryBorder, managementData.computerY + managementData.inventoryBorder + managementData.headerGap, 0, 0, tocolor(10,10,10,255), 1, getFont("Roboto-Light", resp(10)), "left", "top")
		dxDrawCorrectText(OldCore:formatCurrency(computerData.bussinessIncome), managementData.computerX + managementData.inventoryBorder, managementData.computerY + managementData.inventoryBorder + managementData.headerGap + respc(20), 0, 0, tocolor(10,10,10,255), 1, getFont("Roboto", resp(10)), "left", "top")

		local plusWidth = dxGetTextWidth("TELJES BEVÉTEL", 1, getFont("Roboto-Light", resp(10)))
		dxDrawCorrectText("ÜZEMANYAG TÍPUSOK", managementData.computerX + managementData.inventoryBorder + plusWidth + managementData.headerItemsGap, managementData.computerY + managementData.inventoryBorder + managementData.headerGap, 0, 0, tocolor(10,10,10,255), 1, getFont("Roboto-Light", resp(10)), "left", "top")
		dxDrawCorrectText(computerData.maxStorageItems.."/"..#computerData.productData, managementData.computerX + managementData.inventoryBorder + plusWidth + managementData.headerItemsGap, managementData.computerY + managementData.inventoryBorder + managementData.headerGap + respc(20), 0, 0, tocolor(10,10,10,255), 1, getFont("Roboto", resp(10)), "left", "top")

		local plusWidth = dxGetTextWidth("TELJES BEVÉTEL", 1, getFont("Roboto-Light", resp(10))) + dxGetTextWidth("ÜZEMANYAG TÍPUSOK", 1, getFont("Roboto", resp(10)))
		dxDrawCorrectText("TELJES TELÍTETTSÉG", managementData.computerX + managementData.inventoryBorder + plusWidth + managementData.headerItemsGap*2, managementData.computerY + managementData.inventoryBorder + managementData.headerGap, 0, 0, tocolor(10,10,10,255), 1, getFont("Roboto-Light", resp(10)), "left", "top")
		dxDrawCorrectText(getStorageCapacitySum().."/"..getStorageItemCount().." Liter", managementData.computerX + managementData.inventoryBorder + plusWidth + managementData.headerItemsGap*2, managementData.computerY + managementData.inventoryBorder + managementData.headerGap + respc(20), 0, 0, tocolor(10,10,10,255), 1, getFont("Roboto", resp(10)), "left", "top")

		-- # Plus Storage Things
		dxDrawCorrectText("ÜZEMANYAGTARTÁLY KAPACITÁSÁNAK NÖVELÉSE", managementData.computerX + managementData.inventoryBorder, managementData.computerY + managementData.inventoryBorder + managementData.headerGap, managementData.computerW - managementData.inventoryBorder*2 - respc(25), 0, tocolor(10,10,10,255), 1, getFont("Roboto", resp(9)), "right", "top")
		dxDrawSmoothButtonImage("plusStorageCapacity", managementData.computerX + managementData.computerW - managementData.inventoryBorder*2, managementData.computerY + managementData.inventoryBorder + managementData.headerGap - respc(2), respc(18), respc(18), "files/computer/plus.png", {10,10,10,255}, {67, 182, 113, 255})
		dxDrawCorrectText("PLUSZ ÜZEMANYAG TÍPUS", managementData.computerX + managementData.inventoryBorder, managementData.computerY + managementData.inventoryBorder + managementData.headerGap + respc(20), managementData.computerW - managementData.inventoryBorder*2 - respc(25), 0, tocolor(10,10,10,255), 1, getFont("Roboto", resp(9)), "right", "top")
		dxDrawSmoothButtonImage("plusItemTypes", managementData.computerX + managementData.computerW - managementData.inventoryBorder*2, managementData.computerY + managementData.inventoryBorder + managementData.headerGap + respc(18), respc(18), respc(18), "files/computer/plus.png", {10,10,10,255}, {67, 182, 113, 255})
		dxDrawRectangle(managementData.computerX + managementData.inventoryBorder, managementData.computerY + managementData.itemListHeaderY, managementData.computerW - managementData.inventoryBorder*2, respc(2), tocolor(70, 70, 70, 255))

		local counter = 0
		for key, value in pairs(computerData.productData) do
			if (key > managementData.scrollStorageNumber and counter < managementData.maxShowableStorageItems) then
				counter = counter + 1
				dxDrawImage(managementData.computerX + managementData.inventoryBorder, managementData.computerY + managementData.itemListHeaderY + managementData.itemListHeaderH + (counter - 1) * respc(86), managementData.computerW - managementData.inventoryBorder*2, respc(81), "files/computer/"..value.itemID..".png")

				local loadingWidth = managementData.statusW * value.availableStock / computerData.storageCapacity[value.itemID]
				if (loadingWidth > managementData.statusW) then
					loadingWidth = managementData.statusW;
				end

				dxDrawFrame(managementData.computerX + managementData.computerW - managementData.statusW*2 - managementData.inventoryBorder - respc(30), managementData.computerY + managementData.itemListHeaderY + managementData.itemListHeaderH + (counter - 1) * respc(86) + respc(35), managementData.statusW, managementData.statusH, respc(2), tocolor(10,10,10,255))
				dxDrawRectangle(managementData.computerX + managementData.computerW - managementData.statusW*2 - managementData.inventoryBorder - respc(30), managementData.computerY + managementData.itemListHeaderY + managementData.itemListHeaderH + (counter - 1) * respc(86) + respc(35), managementData.statusW, managementData.statusH, tocolor(90,90,90,255))
				dxDrawRectangle(managementData.computerX + managementData.computerW - managementData.statusW*2 - managementData.inventoryBorder - respc(30), managementData.computerY + managementData.itemListHeaderY + managementData.itemListHeaderH + (counter - 1) * respc(86) + respc(35), loadingWidth, managementData.statusH, tocolor(162,254,179,255))
				dxDrawCorrectText("Tartálykészlet", managementData.computerX + managementData.computerW - managementData.statusW*2 - managementData.inventoryBorder - respc(30), managementData.computerY + managementData.itemListHeaderY + managementData.itemListHeaderH + (counter - 1) * respc(86) + respc(15), managementData.statusW, managementData.statusH, tocolor(200,200,200,255), 1, getFont("Roboto-Bold", resp(9)), "center", "top")
				dxDrawCorrectText(math.floor(value.availableStock).."/"..computerData.storageCapacity[value.itemID].." L", managementData.computerX + managementData.computerW - managementData.statusW*2 - managementData.inventoryBorder - respc(30), managementData.computerY + managementData.itemListHeaderY + managementData.itemListHeaderH + (counter - 1) * respc(86) + respc(37), managementData.statusW, managementData.statusH, tocolor(40,40,40,255), 1, getFont("Roboto", resp(10)), "center", "center")
				-- # Change Price Button
				if editData.actualEditingPrice > 0 and editData.actualEditingPrice == key then
					if cursorState then
						local textWidth = dxGetTextWidth("Eladási ár: "..OldCore:formatCurrency(editData.editingText), 1, getFont("Roboto", resp(9)))
						dxDrawLine(managementData.computerX + managementData.computerW - managementData.statusW*1 - managementData.inventoryBorder - respc(15)+textWidth/2 + respc(58), managementData.computerY + managementData.itemListHeaderY + managementData.itemListHeaderH + (counter - 1) * respc(86) + respc(15), managementData.computerX + managementData.computerW - managementData.statusW*1 - managementData.inventoryBorder - respc(15) + textWidth/2 + respc(58), managementData.computerY + managementData.itemListHeaderY + managementData.itemListHeaderH + (counter - 1) * respc(86) + respc(29), tocolor(255, 255, 255, 255), 1)
					end

					dxDrawSmoothButton("change_price_"..key, managementData.computerX + managementData.computerW - managementData.statusW - managementData.inventoryBorder - respc(15), managementData.computerY + managementData.itemListHeaderY + managementData.itemListHeaderH + (counter - 1) * respc(86) + respc(35), managementData.statusW, managementData.statusH, {110, 183, 123, 255}, {65, 182, 86, 255})
					dxDrawCorrectText("Mentés", managementData.computerX + managementData.computerW - managementData.statusW - managementData.inventoryBorder - respc(15), managementData.computerY + managementData.itemListHeaderY + managementData.itemListHeaderH + (counter - 1) * respc(86) + respc(37), managementData.statusW, managementData.statusH, tocolor(10,10,10,255), 1, getFont("Roboto", resp(10)), "center", "center")
					-- # Draw the editing price tag
					dxDrawCorrectText("Eladási ár: "..OldCore:formatCurrency(editData.editingText).." / L"..'', managementData.computerX + managementData.computerW - managementData.statusW*1 - managementData.inventoryBorder - respc(15), managementData.computerY + managementData.itemListHeaderY + managementData.itemListHeaderH + (counter - 1) * respc(86) + respc(15), managementData.statusW, managementData.statusH, tocolor(200,200,200,255), 1, getFont("Roboto-Bold", resp(9)), "center", "top")
				else
					dxDrawSmoothButton("change_price_"..key, managementData.computerX + managementData.computerW - managementData.statusW - managementData.inventoryBorder - respc(15), managementData.computerY + managementData.itemListHeaderY + managementData.itemListHeaderH + (counter - 1) * respc(86) + respc(35), managementData.statusW, managementData.statusH, {240, 232, 216, 255}, {240, 218, 175, 255})
					dxDrawCorrectText("Módosítás", managementData.computerX + managementData.computerW - managementData.statusW - managementData.inventoryBorder - respc(15), managementData.computerY + managementData.itemListHeaderY + managementData.itemListHeaderH + (counter - 1) * respc(86) + respc(37), managementData.statusW, managementData.statusH, tocolor(10,10,10,255), 1, getFont("Roboto", resp(10)), "center", "center")
					-- # Draw the price tag
					dxDrawCorrectText("Eladási ár: "..OldCore:formatCurrency(value.price).." / L"..'', managementData.computerX + managementData.computerW - managementData.statusW*1 - managementData.inventoryBorder - respc(15), managementData.computerY + managementData.itemListHeaderY + managementData.itemListHeaderH + (counter - 1) * respc(86) + respc(15), managementData.statusW, managementData.statusH, tocolor(200,200,200,255), 1, getFont("Roboto-Bold", resp(9)), "center", "top")
				end
				--[[
				-- # Quick Sell Button
				dxDrawSmoothButton("quick_sell_"..key, managementData.computerX + managementData.computerW - managementData.inventoryButtonW - managementData.inventoryBorder - 1, managementData.computerY + managementData.itemListHeaderY + managementData.itemListHeaderH + managementData.inventoryItemGap + (counter - 1) * (managementData.inventoryItemSize + managementData.inventoryItemGap) + respc(6), managementData.inventoryButtonW, managementData.inventoryButtonH, {255, 151, 151, 255}, {255, 112, 112, 255})
				dxDrawFrame(managementData.computerX + managementData.computerW - managementData.inventoryButtonW - managementData.inventoryBorder - 1, managementData.computerY + managementData.itemListHeaderY + managementData.itemListHeaderH + managementData.inventoryItemGap + (counter - 1) * (managementData.inventoryItemSize + managementData.inventoryItemGap) + respc(6), managementData.inventoryButtonW, managementData.inventoryButtonH, 1, tocolor(10,10,10,255))
				dxDrawCorrectText("Eladás", managementData.computerX + managementData.computerW - managementData.inventoryButtonW - managementData.inventoryBorder - 1, managementData.computerY + managementData.itemListHeaderY + managementData.itemListHeaderH + managementData.inventoryItemGap + (counter - 1) * (managementData.inventoryItemSize + managementData.inventoryItemGap) + respc(6), managementData.inventoryButtonW, managementData.inventoryButtonH, tocolor(10,10,10,255), 1, getFont("Roboto", resp(8)), "center", "center")
				]]
			end
		end
		-- # Scroll bar
		dxDrawScrollBar(managementData.computerX + managementData.computerW - managementData.inventoryBorder + respc(5), managementData.computerY + managementData.itemListHeaderY, respc(4), (managementData.maxShowableStorageItems) * (managementData.inventoryItemSize + managementData.inventoryItemGap) + managementData.itemListHeaderH - respc(5), #computerData.productData, managementData.maxShowableStorageItems, managementData.scrollStorageNumber, tocolor(0, 0, 0, 255))

		-- # No Items In Storage
		if #computerData.productData == 0 then
			dxDrawCorrectText("JELENLEG MINDEN ÜZEMANYAGTARTÁLY ÜRES.", managementData.computerX + managementData.inventoryBorder, managementData.computerY + managementData.itemListHeaderY + managementData.itemListHeaderH + managementData.inventoryItemGap, managementData.computerW - managementData.inventoryItemGap*2, managementData.computerH - managementData.itemListHeaderY - managementData.itemListHeaderH*3 - managementData.inventoryItemGap, tocolor(50,50,50,100), 1, getFont("Roboto", resp(14)), "center", "center")
		end
	elseif managementData.activePage == 2 then
		-- # Oil Market
		local timeLeft = (computerData.generatedMarketSupply.lastGeneratedTime + defaultDatas.refreshMarketSupplyTime - getTimestamp())

		dxDrawRectangle(managementData.computerX, managementData.computerY, managementData.computerW, managementData.computerH, tocolor(232, 232, 232, 255))
		dxDrawCorrectText(utf8.upper(managementData.availableApps[managementData.activePage]), managementData.computerX + managementData.inventoryBorder, managementData.computerY + managementData.inventoryBorder, 0, 0, tocolor(10,10,10,255), 1, getFont("Roboto", resp(12)), "left", "top")
--		dxDrawCorrectText("Következő kínálatfrissítés: "..secondsToTimeDesc(timeLeft), managementData.computerX + managementData.inventoryBorder + respc(110), managementData.computerY + managementData.inventoryBorder + respc(5), 0, 0, tocolor(60,60,60,255), 1, getFont("Roboto", resp(9)), "left", "top")

		dxDrawRectangle(managementData.computerX + managementData.inventoryBorder, managementData.computerY + respc(40), managementData.computerW - managementData.inventoryBorder*2, respc(2), tocolor(10, 10, 10, 255))
		dxDrawSmoothButton("closeAppPage", managementData.computerX + managementData.computerW - managementData.inventoryBorder - managementData.checkOrderH, managementData.computerY + respc(17), managementData.checkOrderH, managementData.checkOrderH, {198, 85, 85, 255}, {198, 59, 59, 255})
		dxDrawImage(managementData.computerX + managementData.computerW - managementData.inventoryBorder - managementData.closeAppSize - respc(3), managementData.computerY + respc(20), managementData.closeAppSize, managementData.closeAppSize,"files/computer/close.png", 0, 0, 0, tocolor(10,10,10,255))

		dxDrawSmoothButton("checkOrderList", managementData.computerX + managementData.computerW - managementData.inventoryBorder - managementData.closeAppSize - managementData.checkOrderW - respc(10), managementData.computerY + respc(17), managementData.checkOrderW, managementData.checkOrderH, {110, 183, 123, 255}, {67, 182, 113, 255})
		dxDrawImage(managementData.computerX + managementData.computerW - managementData.inventoryBorder - managementData.closeAppSize - managementData.checkOrderW - respc(10), managementData.computerY + respc(17), managementData.checkOrderH, managementData.checkOrderH, "files/shopping_cart.png")
		dxDrawCorrectText("Rendelés véglegesítése", managementData.computerX + managementData.computerW - managementData.inventoryBorder - managementData.closeAppSize - managementData.checkOrderW - respc(5) + managementData.checkOrderH, managementData.computerY + respc(17), managementData.checkOrderW, managementData.checkOrderH, tocolor(240,240,240,255), 1, getFont("Roboto-Bold", resp(9)), "left", "center")

		-- # Header section
		dxDrawRectangle(managementData.computerX + managementData.inventoryBorder, managementData.computerY + managementData.itemListHeaderY, managementData.computerW - managementData.inventoryBorder*2, respc(2), tocolor(70, 70, 70, 255))
		dxDrawCorrectText("KÖVETKEZŐ KÍNÁLATFRISSÍTÉS", managementData.computerX + managementData.inventoryBorder, managementData.computerY + managementData.inventoryBorder + managementData.headerGap, 0, 0, tocolor(10,10,10,200), 1, getFont("Roboto", resp(10)), "left", "top")
		dxDrawCorrectText(secondsToTimeDesc(timeLeft), managementData.computerX + managementData.inventoryBorder, managementData.computerY + managementData.inventoryBorder + managementData.headerGap + respc(20), 0, 0, tocolor(10,10,10,200), 1, getFont("Roboto", resp(9)), "left", "top")

		local plusWidth = dxGetTextWidth("KÖVETKEZŐ KÍNÁLATFRISSÍTÉS", 1, getFont("Roboto", resp(10)))
		dxDrawCorrectText("ELÉRHETŐ ÜZEMANYAGOK SZÁMA", managementData.computerX + managementData.inventoryBorder + plusWidth + managementData.headerItemsGap, managementData.computerY + managementData.inventoryBorder + managementData.headerGap, 0, 0, tocolor(10,10,10,200), 1, getFont("Roboto", resp(10)), "left", "top")
		dxDrawCorrectText(#computerData.generatedMarketSupply.marketTable.." darab", managementData.computerX + managementData.inventoryBorder + plusWidth + managementData.headerItemsGap, managementData.computerY + managementData.inventoryBorder + managementData.headerGap + respc(20), 0, 0, tocolor(10,10,10,200), 1, getFont("Roboto", resp(9)), "left", "top")


		dxDrawCorrectText("KÍNÁLAT FRISSÍTÉSE",managementData.computerX + managementData.computerW - managementData.statusW - managementData.inventoryBorder - respc(15), managementData.computerY + managementData.inventoryBorder + managementData.headerGap, managementData.statusW, 0, tocolor(10,10,10,200), 1, getFont("Roboto", resp(9)), "center", "top")
		dxDrawFrame(managementData.computerX + managementData.computerW - managementData.statusW - managementData.inventoryBorder - respc(15), managementData.computerY + managementData.inventoryBorder + managementData.headerGap + respc(20), managementData.statusW, managementData.statusH/1.5, respc(1), tocolor(10,10,10,255))
		dxDrawSmoothButton("refreshMarketSupply", managementData.computerX + managementData.computerW - managementData.statusW - managementData.inventoryBorder - respc(15), managementData.computerY + managementData.inventoryBorder + managementData.headerGap + respc(20), managementData.statusW, managementData.statusH/1.5, {255, 194, 98, 150}, {255, 194, 98, 255})
		dxDrawCorrectText("Frissítés", managementData.computerX + managementData.computerW - managementData.statusW - managementData.inventoryBorder - respc(15), managementData.computerY + managementData.inventoryBorder + managementData.headerGap + respc(20), managementData.statusW, managementData.statusH/1.5, tocolor(40,40,40,200), 1, getFont("Roboto", resp(9)), "center", "center")

		-- # Available Items

		for key, value in pairs(computerData.generatedMarketSupply.marketTable) do
			dxDrawImage(managementData.computerX + managementData.inventoryBorder, managementData.computerY + managementData.itemListHeaderY + managementData.itemListHeaderH + (key - 1) * respc(86), managementData.computerW - managementData.inventoryBorder*2, respc(81), "files/computer/"..value.itemID..".png")
			-- # Available stock
			dxDrawCorrectText("Elérhető mennyiség", managementData.computerX + managementData.computerW - managementData.statusW*2 - managementData.inventoryBorder - respc(30), managementData.computerY + managementData.itemListHeaderY + managementData.itemListHeaderH + (key - 1) * respc(86) + respc(15), managementData.statusW, managementData.statusH, tocolor(245,245,245,255), 1, getFont("Roboto-Bold", resp(9)), "center", "top")
			dxDrawFrame(managementData.computerX + managementData.computerW - managementData.statusW*2 - managementData.inventoryBorder - respc(30), managementData.computerY + managementData.itemListHeaderY + managementData.itemListHeaderH + (key - 1) * respc(86) + respc(35), managementData.statusW, managementData.statusH, respc(2), tocolor(10,10,10,255))

			if value.availableStock == 0 then
				dxDrawRectangle(managementData.computerX + managementData.computerW - managementData.statusW*2 - managementData.inventoryBorder - respc(30), managementData.computerY + managementData.itemListHeaderY + managementData.itemListHeaderH + (key - 1) * respc(86) + respc(35), managementData.statusW, managementData.statusH, tocolor(198, 85, 85, 255))
				dxDrawCorrectText("Készlethiány", managementData.computerX + managementData.computerW - managementData.statusW*2 - managementData.inventoryBorder - respc(30), managementData.computerY + managementData.itemListHeaderY + managementData.itemListHeaderH + (key - 1) * respc(86) + respc(37), managementData.statusW, managementData.statusH, tocolor(245,245,245,255), 1, getFont("Roboto", resp(10)), "center", "center")
			else
				dxDrawCorrectText(value.availableStock.." Liter", managementData.computerX + managementData.computerW - managementData.statusW*2 - managementData.inventoryBorder - respc(30), managementData.computerY + managementData.itemListHeaderY + managementData.itemListHeaderH + (key - 1) * respc(86) + respc(37), managementData.statusW, managementData.statusH, tocolor(245,245,245,255), 1, getFont("Roboto", resp(10)), "center", "center")
			end
			-- # Shopping cart button
			dxDrawSmoothButton("add_cart_"..key, managementData.computerX + managementData.computerW - managementData.statusW - managementData.inventoryBorder - respc(15), managementData.computerY + managementData.itemListHeaderY + managementData.itemListHeaderH + (key - 1) * respc(86) + respc(35), managementData.statusW, managementData.statusH, {110, 183, 123, 150}, {110, 183, 123, 255})
			dxDrawCorrectText("Kosárba tesz", managementData.computerX + managementData.computerW - managementData.statusW - managementData.inventoryBorder - respc(15), managementData.computerY + managementData.itemListHeaderY + managementData.itemListHeaderH + (key - 1) * respc(86) + respc(37), managementData.statusW, managementData.statusH, tocolor(255,255,255,255), 1, getFont("Roboto", resp(10)), "center", "center")
			-- # Draw the price tag
			dxDrawCorrectText("Ár: "..OldCore:formatCurrency(value.price).." / L"..'', managementData.computerX + managementData.computerW - managementData.statusW*1 - managementData.inventoryBorder - respc(15), managementData.computerY + managementData.itemListHeaderY + managementData.itemListHeaderH + (key - 1) * respc(86) + respc(15), managementData.statusW, managementData.statusH, tocolor(245,245,245,255), 1, getFont("Roboto-Bold", resp(9)), "center", "top")
		end
		elseif managementData.activePage == 3 then
		-- # Top Section
		dxDrawRectangle(managementData.computerX, managementData.computerY, managementData.computerW, managementData.computerH, tocolor(232, 232, 232, 255))
		dxDrawCorrectText(utf8.upper(managementData.availableApps[managementData.activePage]), managementData.computerX + managementData.inventoryBorder, managementData.computerY + managementData.inventoryBorder, 0, 0, tocolor(10,10,10,255), 1, getFont("Roboto", resp(12)), "left", "top")
		dxDrawSmoothButtonImage("closeAppPage", managementData.computerX + managementData.computerW - managementData.inventoryBorder - managementData.closeAppSize, managementData.computerY + respc(20), managementData.closeAppSize, managementData.closeAppSize,"files/computer/close.png", {10,10,10,255}, {198, 59, 59, 255})
		-- # Header
		dxDrawRectangle(managementData.computerX + managementData.inventoryBorder, managementData.computerY + managementData.orderHeaderGap, managementData.computerW - managementData.inventoryBorder*2, managementData.orderElementH, tocolor(200, 200, 200, 255))
		dxDrawCorrectText("Rendelésszám", managementData.computerX + managementData.inventoryBorder + respc(5), managementData.computerY + managementData.orderHeaderGap, managementData.computerW - managementData.inventoryBorder*2, managementData.orderElementH, tocolor(10,10,10,255), 1, getFont("Roboto", resp(9)), "left", "center")
		dxDrawCorrectText("Rendelés dátuma", managementData.computerX + managementData.inventoryBorder + respc(140), managementData.computerY + managementData.orderHeaderGap, managementData.computerW - managementData.inventoryBorder*2, managementData.orderElementH, tocolor(10,10,10,255), 1, getFont("Roboto", resp(9)), "left", "center")
		dxDrawCorrectText("Átvehető", managementData.computerX + managementData.inventoryBorder + respc(300), managementData.computerY + managementData.orderHeaderGap, managementData.computerW - managementData.inventoryBorder*2, managementData.orderElementH, tocolor(10,10,10,255), 1, getFont("Roboto", resp(9)), "left", "center")
		dxDrawCorrectText("Státusz", managementData.computerX + managementData.inventoryBorder + respc(445), managementData.computerY + managementData.orderHeaderGap, managementData.computerW - managementData.inventoryBorder*2, managementData.orderElementH, tocolor(10,10,10,255), 1, getFont("Roboto", resp(9)), "left", "center")
		dxDrawCorrectText("Fizetve", managementData.computerX + managementData.inventoryBorder + respc(590), managementData.computerY + managementData.orderHeaderGap, managementData.computerW - managementData.inventoryBorder*2, managementData.orderElementH, tocolor(10,10,10,255), 1, getFont("Roboto", resp(9)), "left", "center")

		local counter = 0
		for key, value in pairs(computerData.orderList) do
			if (key > managementData.scrollOrdersNumber and counter < managementData.maxShowAbleOrderItems) then
				counter = counter + 1
				if key % 2 == 0 then
					dxDrawRectangle(managementData.computerX + managementData.inventoryBorder, managementData.computerY + managementData.orderHeaderGap + managementData.orderElementH + (counter - 1) * managementData.orderElementH, managementData.computerW - managementData.inventoryBorder*2, managementData.orderElementH, tocolor(210, 210, 210, 255))
				else
					dxDrawRectangle(managementData.computerX + managementData.inventoryBorder, managementData.computerY + managementData.orderHeaderGap + managementData.orderElementH + (counter - 1) * managementData.orderElementH, managementData.computerW - managementData.inventoryBorder*2, managementData.orderElementH, tocolor(220, 220, 220, 255))
				end
				local name = "#000"..key;
				if (value.orderData and value.orderData[1] and value.orderData[1].itemID) then
					name = "#000"..key .. " (" .. (itemNameToRealName[value.orderData[1].itemID] or orderData[1].itemID) .. ")";
				end
				dxDrawCorrectText(name, managementData.computerX + managementData.inventoryBorder + respc(5), managementData.computerY + managementData.orderHeaderGap + managementData.orderElementH + (counter - 1) * managementData.orderElementH, managementData.computerW - managementData.inventoryBorder*2, managementData.orderElementH, tocolor(80,132,216,255), 1, getFont("Roboto", resp(9)), "left", "center")
				dxDrawCorrectText(getFormatDate(value.orderMadeTime), managementData.computerX + managementData.inventoryBorder + respc(140), managementData.computerY + managementData.orderHeaderGap + managementData.orderElementH + (counter - 1) * managementData.orderElementH, managementData.computerW - managementData.inventoryBorder*2, managementData.orderElementH, tocolor(50,50,50,255), 1, getFont("Roboto", resp(9)), "left", "center")
				dxDrawCorrectText(getFormatDate((value.orderMadeTime + defaultDatas.orderDeliverDeleteTime)).."-ig", managementData.computerX + managementData.inventoryBorder + respc(300), managementData.computerY + managementData.orderHeaderGap + managementData.orderElementH + (counter - 1) * managementData.orderElementH, managementData.computerW - managementData.inventoryBorder*2, managementData.orderElementH, tocolor(50,50,50,255), 1, getFont("Roboto", resp(9)), "left", "center")
				-- # Draw Status Data
				local statusData = {statusText = "", statusColor = {255,255,255,255}}
				local startAvailable = false;
				if value.orderStatus == "delivery_needed" then
					statusData = {statusText = "Szállításra kész", statusColor = {0, 193, 0,255}}
					startAvailable = true;
				elseif value.orderStatus == "delivery_process" then
					statusData = {statusText = "Szállítás alatt", statusColor = {222,172,0,255}}
				elseif value.orderStatus == "delivery_canceled" then
					statusData = {statusText = "Szállítás sikertelen", statusColor = {255,52,60,255}}
				elseif value.orderStatus == "delivery_success" then
					statusData = {statusText = "Szállítás sikeres", statusColor = {203, 136, 49,255}}
				end
				dxDrawCorrectText(statusData.statusText, managementData.computerX + managementData.inventoryBorder + respc(445), managementData.computerY + managementData.orderHeaderGap + managementData.orderElementH + (counter - 1) * managementData.orderElementH, managementData.computerW - managementData.inventoryBorder*2, managementData.orderElementH, tocolor(statusData.statusColor[1],statusData.statusColor[2],statusData.statusColor[3],statusData.statusColor[4]), 1, getFont("Roboto", resp(9)), "left", "center")
				-- # Draw the cost
				dxDrawCorrectText(""..OldCore:formatCurrency(value.orderCost), managementData.computerX + managementData.inventoryBorder + respc(590), managementData.computerY + managementData.orderHeaderGap + managementData.orderElementH + (counter - 1) * managementData.orderElementH, managementData.computerW - managementData.inventoryBorder*2, managementData.orderElementH, tocolor(50,50,50,255), 1, getFont("Roboto", resp(9)), "left", "center")
				-- # Draw action buttons
				if (startAvailable) then
					dxDrawSmoothButton("deliver_order_"..key, managementData.computerX + managementData.inventoryBorder + respc(690), managementData.computerY + managementData.orderHeaderGap + managementData.orderElementH + respc(2) + (counter - 1) * managementData.orderElementH, managementData.inventoryButtonW, managementData.inventoryButtonH, {110, 183, 123, 255}, {65, 182, 86, 255})
					dxDrawCorrectText("Szállítás kezdése", managementData.computerX + managementData.inventoryBorder + respc(690), managementData.computerY + managementData.orderHeaderGap + managementData.orderElementH + respc(2) + (counter - 1) * managementData.orderElementH, managementData.inventoryButtonW, managementData.inventoryButtonH, tocolor(230,230,230,255), 1, getFont("Roboto", resp(9)), "center", "center")
				end

				dxDrawSmoothButton("cancel_order_"..key, managementData.computerX - managementData.inventoryBorder + managementData.computerW - managementData.inventoryButtonH, managementData.computerY + managementData.orderHeaderGap + managementData.orderElementH + respc(2) + (counter - 1) * managementData.orderElementH, managementData.inventoryButtonH, managementData.inventoryButtonH, {198, 85, 85, 255}, {198, 59, 59, 255})
				dxDrawImage(managementData.computerX - managementData.inventoryBorder + managementData.computerW - managementData.inventoryButtonH, managementData.computerY + managementData.orderHeaderGap + managementData.orderElementH + respc(2) + (counter - 1) * managementData.orderElementH, respc(20), respc(20), "files/computer/delete.png", 0, 0, 0, tocolor(30, 30, 30, 255))
			end
		end

		-- # Scroll bar
		dxDrawScrollBar(managementData.computerX + managementData.computerW - managementData.inventoryBorder + respc(5), managementData.computerY + managementData.orderHeaderGap + managementData.orderElementH, respc(4), managementData.orderElementH * 16, #computerData.orderList, managementData.maxShowAbleOrderItems, managementData.scrollOrdersNumber, tocolor(0, 0, 0, 255))

		-- # No orders
		if #computerData.orderList == 0 then
			dxDrawCorrectText("NINCS ELÉRHETŐ RENDELÉSI ELŐZMÉNY", managementData.computerX + managementData.inventoryBorder, managementData.computerY + managementData.orderHeaderGap + managementData.orderElementH, managementData.computerW - managementData.inventoryBorder*2, managementData.computerH - managementData.orderHeaderGap - managementData.orderElementH*2, tocolor(50,50,50,100), 1, getFont("Roboto", resp(22)), "center", "center")
		end
	elseif managementData.activePage == 4 then
		-- # Top Section
		dxDrawRectangle(managementData.computerX, managementData.computerY, managementData.computerW, managementData.computerH, tocolor(232, 232, 232, 255))
		dxDrawCorrectText(utf8.upper(managementData.availableApps[managementData.activePage]), managementData.computerX + managementData.inventoryBorder + managementData.settingsLeftW, managementData.computerY + managementData.inventoryBorder, 0, 0, tocolor(10,10,10,255), 1, getFont("Roboto", resp(12)), "left", "top")
		dxDrawSmoothButton("closeAppPage", managementData.computerX + managementData.computerW - managementData.inventoryBorder - managementData.checkOrderH, managementData.computerY + respc(17), managementData.checkOrderH, managementData.checkOrderH, {198, 85, 85, 255}, {198, 59, 59, 255})
		dxDrawImage(managementData.computerX + managementData.computerW - managementData.inventoryBorder - managementData.closeAppSize - respc(3), managementData.computerY + respc(20), managementData.closeAppSize, managementData.closeAppSize,"files/computer/close.png", 0, 0, 0, tocolor(10,10,10,255))

		dxDrawSmoothButton("plusBussinessMember", managementData.computerX + managementData.computerW - managementData.inventoryBorder - managementData.closeAppSize - managementData.checkOrderW - respc(10), managementData.computerY + respc(17), managementData.checkOrderW, managementData.checkOrderH, {110, 183, 123, 255}, {67, 182, 113, 255})
		dxDrawImage(managementData.computerX + managementData.computerW - managementData.inventoryBorder - managementData.closeAppSize - managementData.checkOrderW - respc(5), managementData.computerY + respc(19), respc(16), respc(16), "files/computer/plus.png")
		dxDrawCorrectText("Alkalmazott hozzáadása", managementData.computerX + managementData.computerW - managementData.inventoryBorder - managementData.closeAppSize - managementData.checkOrderW + managementData.checkOrderH, managementData.computerY + respc(17), managementData.checkOrderW, managementData.checkOrderH, tocolor(240,240,240,255), 1, getFont("Roboto-Bold", resp(8)), "left", "center")
		-- # Left Section
		dxDrawImage(managementData.computerX, managementData.computerY, managementData.settingsLeftW, managementData.computerH, "files/computer/settings_left_background.png")
		dxDrawCorrectText("VÁLLALKOZÁS NEVE", managementData.computerX, managementData.computerY + respc(125), managementData.settingsLeftW, managementData.computerH, tocolor(220,220,220,255), 1, getFont("Roboto", resp(9)), "center", "top")
		dxDrawCorrectText(computerData.bussinessName, managementData.computerX, managementData.computerY + respc(145), managementData.settingsLeftW, managementData.computerH, tocolor(220,220,220,255), 1, getFont("Roboto-Bold", resp(9)), "center", "top", false, true)
		
		dxDrawCorrectText("TULAJDONOS", managementData.computerX, managementData.computerY + respc(190), managementData.settingsLeftW, managementData.computerH, tocolor(220,220,220,255), 1, getFont("Roboto", resp(9)), "center", "top")
		dxDrawCorrectText(computerData.bussinessOwnerName:gsub("_", " "), managementData.computerX, managementData.computerY + respc(210), managementData.settingsLeftW, managementData.computerH, tocolor(220,220,220,255), 1, getFont("Roboto-Bold", resp(9)), "center", "top", false, true)
		
		dxDrawCorrectText("CÉG BEJEGYEZVE", managementData.computerX, managementData.computerY + respc(255), managementData.settingsLeftW, managementData.computerH, tocolor(220,220,220,255), 1, getFont("Roboto", resp(9)), "center", "top")
		local createTime = getRealTime(computerData.createdDate)
		dxDrawCorrectText((createTime.year + 1900).."/"..(createTime.month + 1).."/"..createTime.monthday, managementData.computerX, managementData.computerY + respc(275), managementData.settingsLeftW, managementData.computerH, tocolor(220,220,220,255), 1, getFont("Roboto-Bold", resp(9)), "center", "top", false, true)
		
		dxDrawCorrectText("UTOLSÓ BEJELENTÉS", managementData.computerX, managementData.computerY + respc(320), managementData.settingsLeftW, managementData.computerH, tocolor(220,220,220,255), 1, getFont("Roboto", resp(9)), "center", "top")
		local createTime = getRealTime(computerData.lastReport)
		dxDrawCorrectText((createTime.year + 1900).."/"..(createTime.month + 1).."/"..createTime.monthday, managementData.computerX, managementData.computerY + respc(340), managementData.settingsLeftW, managementData.computerH, tocolor(220,220,220,255), 1, getFont("Roboto-Bold", resp(9)), "center", "top", false, true)

		dxDrawFrame(managementData.computerX + managementData.settingsLeftButtonGap, managementData.computerY + managementData.computerH - managementData.settingsLeftButtonGap - managementData.settingsLeftButtonH, managementData.settingsLeftW - managementData.settingsLeftButtonGap*2, managementData.settingsLeftButtonH, 1, tocolor(230,230,230,255))
		dxDrawSmoothFrameButton("changeBussinessName", managementData.computerX + managementData.settingsLeftButtonGap, managementData.computerY + managementData.computerH - managementData.settingsLeftButtonGap - managementData.settingsLeftButtonH, managementData.settingsLeftW - managementData.settingsLeftButtonGap*2, managementData.settingsLeftButtonH, {0,0,0,0}, {230,230,230,255}, {230, 230, 230, 255}, {30,30,30,255}, "NÉVVÁLTOZTATÁS")
		dxDrawFrame(managementData.computerX + managementData.settingsLeftButtonGap, managementData.computerY + managementData.computerH - managementData.settingsLeftButtonGap*2 - managementData.settingsLeftButtonH*1.75, managementData.settingsLeftW - managementData.settingsLeftButtonGap*2, managementData.settingsLeftButtonH, 1, tocolor(230,230,230,255))
		dxDrawSmoothFrameButton("sellBussiness", managementData.computerX + managementData.settingsLeftButtonGap, managementData.computerY + managementData.computerH - managementData.settingsLeftButtonGap*2 - managementData.settingsLeftButtonH*1.75, managementData.settingsLeftW - managementData.settingsLeftButtonGap*2, managementData.settingsLeftButtonH, {0,0,0,0}, {230,230,230,255}, {230, 230, 230, 255}, {30,30,30,255}, "CÉG ELADÁSA")

		-- # Header
		dxDrawRectangle(managementData.computerX + managementData.inventoryBorder + managementData.settingsLeftW, managementData.computerY + managementData.orderHeaderGap, managementData.computerW - managementData.inventoryBorder*2 - managementData.settingsLeftW, managementData.orderElementH, tocolor(200, 200, 200, 255))
		dxDrawCorrectText("Teljes neve", managementData.computerX + managementData.inventoryBorder + managementData.settingsLeftW + respc(5), managementData.computerY + managementData.orderHeaderGap, managementData.computerW - managementData.inventoryBorder*2 - managementData.settingsLeftW, managementData.orderElementH, tocolor(30,30,30,255), 1, getFont("Roboto", resp(9)), "left", "center", false, true)
		dxDrawCorrectText("Leltár", managementData.computerX + managementData.inventoryBorder + managementData.settingsLeftW + respc(185), managementData.computerY + managementData.orderHeaderGap, managementData.computerW - managementData.inventoryBorder*2 - managementData.settingsLeftW, managementData.orderElementH, tocolor(30,30,30,255), 1, getFont("Roboto", resp(9)), "left", "center", false, true)
		dxDrawCorrectText("Oil Market", managementData.computerX + managementData.inventoryBorder + managementData.settingsLeftW + respc(255), managementData.computerY + managementData.orderHeaderGap, managementData.computerW - managementData.inventoryBorder*2 - managementData.settingsLeftW, managementData.orderElementH, tocolor(30,30,30,255), 1, getFont("Roboto", resp(9)), "left", "center", false, true)
		dxDrawCorrectText("Fuvarozás", managementData.computerX + managementData.inventoryBorder + managementData.settingsLeftW + respc(345), managementData.computerY + managementData.orderHeaderGap, managementData.computerW - managementData.inventoryBorder*2 - managementData.settingsLeftW, managementData.orderElementH, tocolor(30,30,30,255), 1, getFont("Roboto", resp(9)), "left", "center", false, true)
		dxDrawCorrectText("Pénzügyek", managementData.computerX + managementData.inventoryBorder + managementData.settingsLeftW + respc(435), managementData.computerY + managementData.orderHeaderGap, managementData.computerW - managementData.inventoryBorder*2 - managementData.settingsLeftW, managementData.orderElementH, tocolor(30,30,30,255), 1, getFont("Roboto", resp(9)), "left", "center", false, true)

		-- # Workers section
		for backGroundIndex = 1, 10 do
			if backGroundIndex % 2 == 0 then
				dxDrawRectangle(managementData.computerX + managementData.inventoryBorder + managementData.settingsLeftW, managementData.computerY + managementData.orderHeaderGap + managementData.orderElementH + (backGroundIndex - 1) * managementData.orderElementH, managementData.computerW - managementData.inventoryBorder*2 - managementData.settingsLeftW, managementData.orderElementH, tocolor(210, 210, 210, 255))
			else
				dxDrawRectangle(managementData.computerX + managementData.inventoryBorder + managementData.settingsLeftW, managementData.computerY + managementData.orderHeaderGap + managementData.orderElementH + (backGroundIndex - 1) * managementData.orderElementH, managementData.computerW - managementData.inventoryBorder*2 - managementData.settingsLeftW, managementData.orderElementH, tocolor(220, 220, 220, 255))
			end
		end
		for key, value in pairs(computerData.permissionData) do
			dxDrawCorrectText(value.playerName, managementData.computerX + managementData.inventoryBorder + managementData.settingsLeftW + respc(5), managementData.computerY + managementData.orderHeaderGap + managementData.orderElementH + (key - 1) * managementData.orderElementH, managementData.computerW - managementData.inventoryBorder*2 - managementData.settingsLeftW, managementData.orderElementH, tocolor(30,30,30,255), 1, getFont("Roboto", resp(9)), "left", "center", false, true)
			-- # Inventory Permission
			dxDrawSmoothFrame("toggle_permission_handleInventory_"..key, managementData.computerX + managementData.inventoryBorder + managementData.settingsLeftW + respc(195), managementData.computerY + managementData.orderHeaderGap + respc(5) + managementData.orderElementH + (key - 1) * managementData.orderElementH, managementData.tickFrameSize, managementData.tickFrameSize, 1, {10,10,10,255}, {117,212,118,255})
			if value.handleInventory then
				dxDrawImage(managementData.computerX + managementData.inventoryBorder + managementData.settingsLeftW + respc(194), managementData.computerY + managementData.orderHeaderGap + respc(4) + managementData.orderElementH + (key - 1) * managementData.orderElementH, respc(15), respc(15), "files/computer/tick.png", 0, 0, 0, tocolor(117,212,118,255))
			end
			-- # Market Permission
			dxDrawSmoothFrame("toggle_permission_accessMarket_"..key, managementData.computerX + managementData.inventoryBorder + managementData.settingsLeftW + respc(277), managementData.computerY + managementData.orderHeaderGap + respc(5) + managementData.orderElementH + (key - 1) * managementData.orderElementH, managementData.tickFrameSize, managementData.tickFrameSize, 1, {10,10,10,255}, {117,212,118,255})
			if value.accessMarket then
				dxDrawImage(managementData.computerX + managementData.inventoryBorder + managementData.settingsLeftW + respc(276), managementData.computerY + managementData.orderHeaderGap + respc(4) + managementData.orderElementH + (key - 1) * managementData.orderElementH, respc(15), respc(15), "files/computer/tick.png", 0, 0, 0, tocolor(117,212,118,255))
			end
			-- # Delivery Permission
			dxDrawSmoothFrame("toggle_permission_deliverOrders_"..key, managementData.computerX + managementData.inventoryBorder + managementData.settingsLeftW + respc(367), managementData.computerY + managementData.orderHeaderGap + respc(5) + managementData.orderElementH + (key - 1) * managementData.orderElementH, managementData.tickFrameSize, managementData.tickFrameSize, 1, {10,10,10,255}, {117,212,118,255})
			if value.deliverOrders then
				dxDrawImage(managementData.computerX + managementData.inventoryBorder + managementData.settingsLeftW + respc(366), managementData.computerY + managementData.orderHeaderGap + respc(4) + managementData.orderElementH + (key - 1) * managementData.orderElementH, respc(15), respc(15), "files/computer/tick.png", 0, 0, 0, tocolor(117,212,118,255))
			end
			-- # Bank Permission
			dxDrawSmoothFrame("toggle_permission_managePayments_"..key, managementData.computerX + managementData.inventoryBorder + managementData.settingsLeftW + respc(460), managementData.computerY + managementData.orderHeaderGap + respc(5) + managementData.orderElementH + (key - 1) * managementData.orderElementH, managementData.tickFrameSize, managementData.tickFrameSize, 1, {10,10,10,255}, {117,212,118,255})
			if value.managePayments then
				dxDrawImage(managementData.computerX + managementData.inventoryBorder + managementData.settingsLeftW + respc(459), managementData.computerY + managementData.orderHeaderGap + respc(4) + managementData.orderElementH + (key - 1) * managementData.orderElementH, respc(15), respc(15), "files/computer/tick.png", 0, 0, 0, tocolor(117,212,118,255))
			end
			-- # Delete Member
			dxDrawSmoothButton("fire_member_"..key, managementData.computerX - managementData.inventoryBorder + managementData.computerW - managementData.fireButtonW - respc(5), managementData.computerY + managementData.orderHeaderGap + managementData.orderElementH + respc(2) + (key - 1) * managementData.orderElementH, managementData.fireButtonW, managementData.fireButtonH, {255,151,151,255}, {248,93,93,255})
			dxDrawFrame(managementData.computerX - managementData.inventoryBorder + managementData.computerW - managementData.fireButtonW - respc(5), managementData.computerY + managementData.orderHeaderGap + managementData.orderElementH + respc(2) + (key - 1) * managementData.orderElementH, managementData.fireButtonW, managementData.fireButtonH, 1, tocolor(178,105,105,255))
			dxDrawCorrectText("KIRÚGÁS", managementData.computerX - managementData.inventoryBorder + managementData.computerW - managementData.fireButtonW - respc(5), managementData.computerY + managementData.orderHeaderGap + managementData.orderElementH + respc(2) + (key - 1) * managementData.orderElementH, managementData.fireButtonW, managementData.fireButtonH, tocolor(50,50,50,255), 1, getFont("Roboto", resp(8)), "center", "center", false, true)
		end
		-- # Banking Section
		dxDrawCorrectText("PÉNZÜGYEK", managementData.computerX + managementData.inventoryBorder + managementData.settingsLeftW, managementData.computerY + managementData.inventoryBorder + respc(330), 0, 0, tocolor(10,10,10,255), 1, getFont("Roboto", resp(12)), "left", "top")
		-- Balance
		dxDrawFrame(managementData.computerX + managementData.inventoryBorder + managementData.settingsLeftW, managementData.computerY + managementData.computerH - managementData.settingsBankButtonH*3 - managementData.inventoryBorder - managementData.inventoryBorder * 1.4, managementData.computerW - managementData.inventoryBorder*2 - managementData.settingsLeftW, managementData.settingsBankButtonH, 1, tocolor(150,150,153,255))
		dxDrawRectangle(managementData.computerX + managementData.inventoryBorder + managementData.settingsLeftW, managementData.computerY + managementData.computerH - managementData.settingsBankButtonH*3 - managementData.inventoryBorder - managementData.inventoryBorder * 1.4, managementData.computerW - managementData.inventoryBorder*2 - managementData.settingsLeftW, managementData.settingsBankButtonH, tocolor(215,215,219,255))
		dxDrawCorrectText("EGYENLEG:", managementData.computerX + managementData.inventoryBorder + managementData.settingsLeftW + respc(5), managementData.computerY + managementData.computerH - managementData.settingsBankButtonH*3 - managementData.inventoryBorder - managementData.inventoryBorder * 1.4, managementData.computerW - managementData.inventoryBorder*2 - managementData.settingsLeftW, managementData.settingsBankButtonH, tocolor(30,30,30,255), 1, getFont("Roboto", resp(9)), "left", "center", false, true)
		dxDrawCorrectText(""..OldCore:formatCurrency(computerData.bussinessBalance), managementData.computerX + managementData.inventoryBorder + managementData.settingsLeftW - respc(5), managementData.computerY + managementData.computerH - managementData.settingsBankButtonH*3 - managementData.inventoryBorder - managementData.inventoryBorder * 1.4, managementData.computerW - managementData.inventoryBorder*2 - managementData.settingsLeftW, managementData.settingsBankButtonH, tocolor(30,30,30,255), 1, getFont("Roboto", resp(9)), "right", "center", false, true)
		-- Deposit money
		dxDrawFrame(managementData.computerX + managementData.inventoryBorder + managementData.settingsLeftW, managementData.computerY + managementData.computerH - managementData.settingsBankButtonH*2 - managementData.inventoryBorder - managementData.inventoryBorder * 0.7, managementData.computerW - managementData.inventoryBorder*2 - managementData.settingsLeftW, managementData.settingsBankButtonH, 1, tocolor(133,158,135,255))
		dxDrawSmoothButton("depositBussinessMoney", managementData.computerX + managementData.inventoryBorder + managementData.settingsLeftW, managementData.computerY + managementData.computerH - managementData.settingsBankButtonH*2 - managementData.inventoryBorder - managementData.inventoryBorder * 0.7, managementData.computerW - managementData.inventoryBorder*2 - managementData.settingsLeftW, managementData.settingsBankButtonH, {190,226,194,255}, {140,226,150,255})
		dxDrawCorrectText("BEFIZETÉS INDÍTÁSA", managementData.computerX + managementData.inventoryBorder + managementData.settingsLeftW + respc(5), managementData.computerY + managementData.computerH - managementData.settingsBankButtonH*2 - managementData.inventoryBorder - managementData.inventoryBorder * 0.7, managementData.computerW - managementData.inventoryBorder*2 - managementData.settingsLeftW, managementData.settingsBankButtonH, tocolor(30,30,30,255), 1, getFont("Roboto", resp(9)), "left", "center", false, true)
		-- Withdrawal money
		dxDrawFrame(managementData.computerX + managementData.inventoryBorder + managementData.settingsLeftW, managementData.computerY + managementData.computerH - managementData.settingsBankButtonH - managementData.inventoryBorder, managementData.computerW - managementData.inventoryBorder*2 - managementData.settingsLeftW, managementData.settingsBankButtonH, 1, tocolor(178,105,105,255))
		dxDrawSmoothButton("withdrawalBussinessMoney", managementData.computerX + managementData.inventoryBorder + managementData.settingsLeftW, managementData.computerY + managementData.computerH - managementData.settingsBankButtonH - managementData.inventoryBorder, managementData.computerW - managementData.inventoryBorder*2 - managementData.settingsLeftW, managementData.settingsBankButtonH, {255,151,151,255}, {248,93,93,255})
		dxDrawCorrectText("KIFIZETÉS INDÍTÁSA", managementData.computerX + managementData.inventoryBorder + managementData.settingsLeftW + respc(5), managementData.computerY + managementData.computerH - managementData.settingsBankButtonH - managementData.inventoryBorder, managementData.computerW - managementData.inventoryBorder*2 - managementData.settingsLeftW, managementData.settingsBankButtonH, tocolor(30,30,30,255), 1, getFont("Roboto", resp(9)), "left", "center", false, true)
	elseif managementData.activePage == 5 then
		-- # Top Section
		dxDrawRectangle(managementData.computerX, managementData.computerY, managementData.computerW, managementData.computerH, tocolor(232, 232, 232, 255))
		dxDrawCorrectText(utf8.upper(managementData.availableApps[managementData.activePage]), managementData.computerX + managementData.inventoryBorder, managementData.computerY + managementData.inventoryBorder, 0, 0, tocolor(10,10,10,255), 1, getFont("Roboto", resp(12)), "left", "top")
		dxDrawSmoothButtonImage("closeAppPage", managementData.computerX + managementData.computerW - managementData.inventoryBorder - managementData.closeAppSize, managementData.computerY + respc(20), managementData.closeAppSize, managementData.closeAppSize,"files/computer/close.png", {10,10,10,255}, {198, 59, 59, 255})
		local timeLeft = (computerData.offersGeneratedTime + (defaultDatas.respawnOffersTime / 1000) - getTimestamp())
		dxDrawCorrectText("A jelen ajánlatok nem egyedileg erre a vállalkozásra szabottak, azokat bármely vállalat elfogadhatja.", managementData.computerX + managementData.inventoryBorder, managementData.computerY + managementData.inventoryBorder + respc(30), 0, 0, tocolor(60,60,60,255), 1, getFont("Roboto", resp(9)), "left", "top")
		dxDrawCorrectText("Érvényes ajánlatok: "..#computerData.offersData.." / "..managementData.validOffers.." db | Következő ajánlatfrissítés: "..secondsToTimeDesc(timeLeft), managementData.computerX + managementData.inventoryBorder, managementData.computerY + managementData.inventoryBorder + respc(50), 0, 0, tocolor(80,132,216,255), 1, getFont("Roboto", resp(9)), "left", "top")
		-- # Header
		dxDrawSmoothButtonImage("refreshOfferStatus", managementData.computerX + managementData.computerW - managementData.inventoryBorder - respc(120), managementData.computerY + managementData.offerHeaderGap - managementData.closeAppSize - respc(6), managementData.closeAppSize+1, managementData.closeAppSize+1,"files/computer/refresh.png", {80,132,216,180}, {80,132,216,255})
		dxDrawCorrectText("Státusz frissítése", managementData.computerX + managementData.inventoryBorder, managementData.computerY + managementData.offerHeaderGap - managementData.closeAppSize - respc(5), managementData.computerW - managementData.inventoryBorder*2, managementData.closeAppSize, tocolor(80,132,216,180), 1, getFont("Roboto", resp(9)), "right", "center")

		dxDrawRectangle(managementData.computerX + managementData.inventoryBorder, managementData.computerY + managementData.offerHeaderGap, managementData.computerW - managementData.inventoryBorder*2, managementData.orderElementH, tocolor(200, 200, 200, 255))
		dxDrawCorrectText("Megrendelő", managementData.computerX + managementData.inventoryBorder + respc(5), managementData.computerY + managementData.offerHeaderGap, managementData.computerW - managementData.inventoryBorder*2, managementData.orderElementH, tocolor(10,10,10,255), 1, getFont("Roboto", resp(9)), "left", "center")
		dxDrawCorrectText("Státusz", managementData.computerX + managementData.inventoryBorder + respc(185), managementData.computerY + managementData.offerHeaderGap, managementData.computerW - managementData.inventoryBorder*2, managementData.orderElementH, tocolor(10,10,10,255), 1, getFont("Roboto", resp(9)), "left", "center")
		dxDrawCorrectText("Szállítandó összesen", managementData.computerX + managementData.inventoryBorder + respc(340), managementData.computerY + managementData.offerHeaderGap, managementData.computerW - managementData.inventoryBorder*2, managementData.orderElementH, tocolor(10,10,10,255), 1, getFont("Roboto", resp(9)), "left", "center")
		dxDrawCorrectText("Ajánlat a szállításért", managementData.computerX + managementData.inventoryBorder + respc(520), managementData.computerY + managementData.offerHeaderGap, managementData.computerW - managementData.inventoryBorder*2, managementData.orderElementH, tocolor(10,10,10,255), 1, getFont("Roboto", resp(9)), "left", "center")

		managementData.validOffers = 0
		local counter = 0
		for key, value in pairs(computerData.offersData) do
			-- # Sum up the available offers
			if value.offerStatus then
				managementData.validOffers = managementData.validOffers + 1
			end
			-- # Draw the offers
			if (key > managementData.scrollOfferNumber and counter < managementData.maxShowAbleOfferItems) then
				counter = counter + 1
				if key % 2 == 0 then
					dxDrawRectangle(managementData.computerX + managementData.inventoryBorder, managementData.computerY + managementData.offerHeaderGap + managementData.orderElementH + (counter - 1) * managementData.orderElementH, managementData.computerW - managementData.inventoryBorder*2, managementData.orderElementH, tocolor(210, 210, 210, 255))
				else
					dxDrawRectangle(managementData.computerX + managementData.inventoryBorder, managementData.computerY + managementData.offerHeaderGap + managementData.orderElementH + (counter - 1) * managementData.orderElementH, managementData.computerW - managementData.inventoryBorder*2, managementData.orderElementH, tocolor(220, 220, 220, 255))
				end
				dxDrawCorrectText(value.bussinessName, managementData.computerX + managementData.inventoryBorder + respc(5), managementData.computerY + managementData.offerHeaderGap + managementData.orderElementH + (counter - 1) * managementData.orderElementH, managementData.computerW - managementData.inventoryBorder*2, managementData.orderElementH, tocolor(80,132,216,255), 1, getFont("Roboto", resp(9)), "left", "center")
				-- # Draw Status Data
				local statusData = {statusText = "", statusColor = {255,255,255,255}}
				if value.offerStatus == "offer_open" then
					statusData = {statusText = "Érvényes", statusColor = {71,179,90,255}}
				elseif value.offerStatus == "offer_process" then
					statusData = {statusText = "Szállítás alatt", statusColor = {222,172,0,255}}
				elseif value.offerStatus == "offer_closed" then
					statusData = {statusText = "Kiszállítva", statusColor = {255,52,60,255}}
				end
				dxDrawCorrectText(statusData.statusText, managementData.computerX + managementData.inventoryBorder + respc(185), managementData.computerY + managementData.offerHeaderGap + managementData.orderElementH + (counter - 1) * managementData.orderElementH, managementData.computerW - managementData.inventoryBorder*2, managementData.orderElementH, tocolor(statusData.statusColor[1],statusData.statusColor[2],statusData.statusColor[3],statusData.statusColor[4]), 1, getFont("Roboto", resp(9)), "left", "center")
				-- # Draw amount
			--	local calculatedBoxNumber = 10 * value.totalDeliveryAmount / defaultDatas.maximumOrderAmount
				dxDrawCorrectText(value.totalDeliveryAmount.." Liter (" .. value.offerItems[1].itemName .. ")", managementData.computerX + managementData.inventoryBorder + respc(340), managementData.computerY + managementData.offerHeaderGap + managementData.orderElementH + (counter - 1) * managementData.orderElementH, managementData.computerW - managementData.inventoryBorder*2, managementData.orderElementH, tocolor(50,50,50,255), 1, getFont("Roboto", resp(9)), "left", "center")
				-- # Draw money
				dxDrawCorrectText(""..OldCore:formatCurrency(value.offerMoney), managementData.computerX + managementData.inventoryBorder + respc(520), managementData.computerY + managementData.offerHeaderGap + managementData.orderElementH + (counter - 1) * managementData.orderElementH, respc(110), managementData.orderElementH, tocolor(50,50,50,255), 1, getFont("Roboto", resp(9)), "center", "center")
				-- # Draw action buttons
			--	dxDrawSmoothButton("accept_offer_"..key, managementData.computerX - managementData.inventoryBorder + managementData.computerW - managementData.offerButtonW - respc(5), managementData.computerY + managementData.offerHeaderGap + managementData.orderElementH + respc(2) + (counter - 1) * managementData.orderElementH, managementData.offerButtonW, managementData.inventoryButtonH, {110, 183, 123, 255}, {65, 182, 86, 255})
			--	dxDrawCorrectText("Kiszállítás elvállalása", managementData.computerX - managementData.inventoryBorder + managementData.computerW - managementData.offerButtonW - respc(5), managementData.computerY + managementData.offerHeaderGap + managementData.orderElementH + respc(2) + (counter - 1) * managementData.orderElementH, managementData.offerButtonW, managementData.inventoryButtonH, tocolor(230,230,230,255), 1, getFont("Roboto", resp(9)), "center", "center")
				dxDrawSmoothButton("show_more_offer_"..key, managementData.computerX - managementData.inventoryBorder + managementData.computerW - managementData.offerButtonW - respc(5), managementData.computerY + managementData.offerHeaderGap + managementData.orderElementH + respc(2) + (counter - 1) * managementData.orderElementH, managementData.offerButtonW, managementData.inventoryButtonH, {255, 138, 0, 180}, {255, 138, 0, 255})
				dxDrawCorrectText("Részletek megtekintése", managementData.computerX - managementData.inventoryBorder + managementData.computerW - managementData.offerButtonW - respc(5), managementData.computerY + managementData.offerHeaderGap + managementData.orderElementH + respc(2) + (counter - 1) * managementData.orderElementH, managementData.offerButtonW, managementData.inventoryButtonH, tocolor(230,230,230,255), 1, getFont("Roboto", resp(9)), "center", "center")
			end
		end
		-- # Scroll bar
		dxDrawScrollBar(managementData.computerX + managementData.computerW - managementData.inventoryBorder + respc(5), managementData.computerY + managementData.orderHeaderGap + managementData.orderElementH*2, respc(4), managementData.orderElementH * 15, #computerData.offersData, managementData.maxShowAbleOfferItems, managementData.scrollOfferNumber, tocolor(0, 0, 0, 255))
	end

	-- # Notification Panel
	if notificationData.state then
		local progress = (getTickCount() - notificationData.notificationTick) / 350
		local alphaMultiplier = interpolateBetween(math.abs(notificationData.notificationAlpha-1), 0, 0, notificationData.notificationAlpha, 0, 0, progress, "Linear")
		local listHeight = 0

		dxDrawRectangle(managementData.computerX, managementData.computerY, managementData.computerW, managementData.computerH, tocolor(20,20,20,250 * alphaMultiplier))
		dxDrawCorrectText(notificationData.title, managementData.computerX, managementData.computerY - managementData.notificationTextY - respc(25), managementData.computerW, managementData.computerH, tocolor(255,255,255,255 * alphaMultiplier), 1, getFont("Roboto", resp(14)), "center", "center")
		dxDrawCorrectText(notificationData.description, managementData.computerX, managementData.computerY - managementData.notificationTextY, managementData.computerW, managementData.computerH, tocolor(255,255,255,150 * alphaMultiplier), 1, getFont("Roboto-Light", resp(8)), "center", "center", false, false, false, true)
		dxDrawRectangle(managementData.computerX + (managementData.computerW - managementData.notificationW)/2, managementData.computerY + managementData.computerH/2 - managementData.notificationCenterY, managementData.notificationW, respc(1), tocolor(255,255,255,255 * alphaMultiplier))
		if not notificationData.fuelTypeSelect then
			if not notificationData.shoppingCartTable then
				dxDrawCorrectText(notificationData.productName, managementData.computerX + (managementData.computerW - managementData.notificationW)/2, managementData.computerY + managementData.computerH/2 - managementData.notificationCenterY, managementData.notificationW, respc(30), tocolor(255,255,255,255 * alphaMultiplier), 1, getFont("Roboto-Light", resp(9)), "left", "center")
				if notificationData.priceType == "dollar" then
					-- # Price / count
						dxDrawCorrectText(""..OldCore:formatCurrency(notificationData.priceTag).." / "..(notificationData.anotherUnit or "db"), managementData.computerX + (managementData.computerW - managementData.notificationW)/2, managementData.computerY + managementData.computerH/2 - managementData.notificationCenterY, managementData.notificationW, respc(30), tocolor(255,255,255,255 * alphaMultiplier), 1, getFont("Roboto-Light", resp(9)), "center", "center")
					-- # Price Sum
					dxDrawCorrectText(""..OldCore:formatCurrency(notificationData.priceTag * notificationData.productCount), managementData.computerX + (managementData.computerW - managementData.notificationW)/2 - respc(5), managementData.computerY + managementData.computerH/2 - managementData.notificationCenterY + managementData.notificationSumY, managementData.notificationW, renderData.popupButtonH, tocolor(255,255,255,255 * alphaMultiplier), 1, getFont("Roboto-Light", resp(9)), "right", "center", false, false, true)
				else
					-- # Price / count
					dxDrawCorrectText(notificationData.priceTag.." HLP / db", managementData.computerX + (managementData.computerW - managementData.notificationW)/2, managementData.computerY + managementData.computerH/2 - managementData.notificationCenterY, managementData.notificationW, respc(30), tocolor(255,255,255,255 * alphaMultiplier), 1, getFont("Roboto-Light", resp(9)), "center", "center")
					-- # Price Sum
					dxDrawCorrectText((notificationData.priceTag * notificationData.productCount).." HLP", managementData.computerX + (managementData.computerW - managementData.notificationW)/2 - respc(5), managementData.computerY + managementData.computerH/2 - managementData.notificationCenterY + managementData.notificationSumY, managementData.notificationW, renderData.popupButtonH, tocolor(255,255,255,255 * alphaMultiplier), 1, getFont("Roboto-Light", resp(9)), "right", "center", false, false, true)
				end

				if notificationData.editAbleCount then
					notificationData.productCount = editData.editingText
				end

				dxDrawCorrectText(notificationData.productCount.." "..(notificationData.anotherUnit or "db"), managementData.computerX + (managementData.computerW - managementData.notificationW)/2, managementData.computerY + managementData.computerH/2 - managementData.notificationCenterY, managementData.notificationW, respc(30), tocolor(255,255,255,255 * alphaMultiplier), 1, getFont("Roboto-Light", resp(9)), "right", "center")
			else
				if not notificationData.settingsType then
					for key, value in pairs(notificationData.shoppingCartTable) do
						dxDrawCorrectText(value.itemName, managementData.computerX + (managementData.computerW - managementData.notificationW)/2, managementData.computerY + managementData.computerH/2 - managementData.notificationCenterY + (key-1) * respc(30), managementData.notificationW, respc(30), tocolor(255,255,255,255 * alphaMultiplier), 1, getFont("Roboto-Light", resp(9)), "left", "center")
						listHeight = (key - 1) * respc(30)
						-- # Price / count
						if value.price then
							dxDrawCorrectText(""..OldCore:formatCurrency(value.price).." / "..(notificationData.anotherUnit or "db"), managementData.computerX + (managementData.computerW - managementData.notificationW)/2, managementData.computerY + managementData.computerH/2 - managementData.notificationCenterY + (key-1) * respc(30), managementData.notificationW, respc(30), tocolor(255,255,255,255 * alphaMultiplier), 1, getFont("Roboto-Light", resp(9)), "center", "center")
						end
						if value.amount then
							dxDrawCorrectText(value.amount.." "..(notificationData.anotherUnit or "db"), managementData.computerX + (managementData.computerW - managementData.notificationW)/2 - respc(25), managementData.computerY + managementData.computerH/2 - managementData.notificationCenterY + (key-1) * respc(30), managementData.notificationW, respc(30), tocolor(255,255,255,255 * alphaMultiplier), 1, getFont("Roboto-Light", resp(9)), "right", "center")
							if not notificationData.showStorageTick then
								dxDrawSmoothButtonImage("remove_cart_"..key, managementData.computerX + (managementData.computerW - managementData.notificationW)/2 + managementData.notificationW - respc(20), managementData.computerY + managementData.computerH/2 - managementData.notificationCenterY + respc(4) + (key-1) * respc(30), respc(20), respc(20), "files/computer/delete.png", {235,235,235,255}, {198, 59, 59, 255}, 0, alphaMultiplier)
							else
								if hasStorageItemAmount(value.itemID, value.amount) then
									dxDrawImage(managementData.computerX + (managementData.computerW - managementData.notificationW)/2 + managementData.notificationW - respc(20), managementData.computerY + managementData.computerH/2 - managementData.notificationCenterY + respc(7) + (key-1) * respc(30), respc(14), respc(14), "files/computer/tick.png", 0, 0, 0, tocolor(67, 182, 113, 255 * alphaMultiplier))
								else
									dxDrawImage(managementData.computerX + (managementData.computerW - managementData.notificationW)/2 + managementData.notificationW - respc(20), managementData.computerY + managementData.computerH/2 - managementData.notificationCenterY + respc(7) + (key-1) * respc(30), respc(14), respc(14), "files/computer/close.png", 0, 0, 0, tocolor(198, 59, 59, 255 * alphaMultiplier))
								end
							end
						end
					end
					-- # Price Sum
					dxDrawCorrectText(""..OldCore:formatCurrency(notificationData.priceTag), managementData.computerX + (managementData.computerW - managementData.notificationW)/2 - respc(5), managementData.computerY + managementData.computerH/2 - managementData.notificationCenterY + managementData.notificationSumY + listHeight, managementData.notificationW, renderData.popupButtonH, tocolor(255,255,255,255 * alphaMultiplier), 1, getFont("Roboto-Light", resp(9)), "right", "center", false, false, true)
				else
					listHeight = (-respc(30))
					if notificationData.editAbleCharacters then
						notificationData.editingText = editData.editingText
						if cursorState then
							local textWidth = dxGetTextWidth(""..OldCore:formatCurrency(editData.editingText), 1, getFont("Roboto", resp(9)))
							dxDrawLine(managementData.computerX + (managementData.computerW - managementData.notificationW)/2 + dxGetTextWidth(notificationData.sumText, 1, getFont("Roboto-Light", resp(9))) + respc(7) + textWidth, managementData.computerY + managementData.computerH/2 - managementData.notificationCenterY + managementData.notificationSumY + listHeight + respc(3), managementData.computerX + (managementData.computerW - managementData.notificationW)/2 + dxGetTextWidth(notificationData.sumText, 1, getFont("Roboto-Light", resp(9))) + respc(7) + textWidth, managementData.computerY + managementData.computerH/2 - managementData.notificationCenterY + managementData.notificationSumY + listHeight + respc(15), tocolor(255, 255, 255, 255), 1, true)
						end
					end
					dxDrawCorrectText(notificationData.editingText, managementData.computerX + (managementData.computerW - managementData.notificationW)/2 + dxGetTextWidth(notificationData.sumText, 1, getFont("Roboto-Light", resp(9))) + respc(10), managementData.computerY + managementData.computerH/2 - managementData.notificationCenterY + managementData.notificationSumY + listHeight, managementData.notificationW, renderData.popupButtonH, tocolor(77,144,255, 255 * alphaMultiplier), 1, getFont("Roboto-Light", resp(9)), "left", "center", false, false, true)
				end
			end
			-- # Sum up part
			dxDrawRectangle(managementData.computerX + (managementData.computerW - managementData.notificationW)/2, managementData.computerY + managementData.computerH/2 - managementData.notificationCenterY + managementData.notificationSumY + listHeight, managementData.notificationW, renderData.popupButtonH, tocolor(87,87,87,255 * alphaMultiplier))
			dxDrawCorrectText(notificationData.sumText or "Összesen", managementData.computerX + (managementData.computerW - managementData.notificationW)/2 + respc(5), managementData.computerY + managementData.computerH/2 - managementData.notificationCenterY + managementData.notificationSumY + listHeight, managementData.notificationW, renderData.popupButtonH, tocolor(255,255,255,255 * alphaMultiplier), 1, getFont("Roboto-Light", resp(9)), "left", "center")
			-- # Bottom Line
			dxDrawRectangle(managementData.computerX + (managementData.computerW - managementData.notificationW)/2, managementData.computerY + managementData.computerH/2 - managementData.notificationCenterY + respc(30) + listHeight, managementData.notificationW, respc(1), tocolor(255,255,255,255 * alphaMultiplier))
				-- # Accept Button
			dxDrawSmoothButton(notificationData.acceptButtonDirectX, managementData.computerX + (managementData.computerW - managementData.notificationW)/2 + managementData.notificationW/2 + respc(5), managementData.computerY + managementData.computerH/2 - managementData.notificationCenterY + managementData.notificationSumY + renderData.popupButtonH + respc(10) + listHeight, managementData.notificationW/2 - respc(5), renderData.popupButtonH, {51, 133, 84, 255}, {67, 182, 113, 255}, alphaMultiplier)
			dxDrawCorrectText(notificationData.acceptButtonText, managementData.computerX + (managementData.computerW - managementData.notificationW)/2 + managementData.notificationW/2 + respc(5), managementData.computerY + managementData.computerH/2 - managementData.notificationCenterY + managementData.notificationSumY + renderData.popupButtonH + respc(10) + listHeight, managementData.notificationW/2 - respc(5), renderData.popupButtonH, tocolor(255,255,255,255 * alphaMultiplier), 1, getFont("Roboto-Bold", resp(9)), "center", "center")
			-- # Decline Button
			dxDrawSmoothButton(notificationData.declineButtonDirectX, managementData.computerX + (managementData.computerW - managementData.notificationW)/2, managementData.computerY + managementData.computerH/2 - managementData.notificationCenterY + managementData.notificationSumY + renderData.popupButtonH + respc(10) + listHeight, managementData.notificationW/2 - respc(5), renderData.popupButtonH, {27, 60, 40, 255}, {43, 109, 69, 255}, alphaMultiplier)
			dxDrawCorrectText(notificationData.declineButtonText, managementData.computerX + (managementData.computerW - managementData.notificationW)/2, managementData.computerY + managementData.computerH/2 - managementData.notificationCenterY + managementData.notificationSumY + renderData.popupButtonH + respc(10) + listHeight, managementData.notificationW/2 - respc(5), renderData.popupButtonH, tocolor(255,255,255,255 * alphaMultiplier), 1, getFont("Roboto-Bold", resp(9)), "center", "center")
		else
			dxDrawSmoothButton("benzin", managementData.computerX + (managementData.computerW - managementData.notificationW)/2, managementData.computerY + managementData.computerH/2 - managementData.notificationCenterY + respc(10), managementData.notificationW, renderData.popupButtonH, {51, 133, 84, 255}, {67, 182, 113, 255}, alphaMultiplier)
			dxDrawCorrectText("Benzin EVO", managementData.computerX + (managementData.computerW - managementData.notificationW)/2, managementData.computerY + managementData.computerH/2 - managementData.notificationCenterY + respc(10), managementData.notificationW, renderData.popupButtonH, tocolor(255,255,255,255 * alphaMultiplier), 1, getFont("Roboto-Bold", resp(9)), "center", "center")
			dxDrawSmoothButton("diesel", managementData.computerX + (managementData.computerW - managementData.notificationW)/2, managementData.computerY + managementData.computerH/2 - managementData.notificationCenterY + respc(15) + renderData.popupButtonH, managementData.notificationW, renderData.popupButtonH, {51, 133, 84, 255}, {67, 182, 113, 255}, alphaMultiplier)
			dxDrawCorrectText("Diesel EVO", managementData.computerX + (managementData.computerW - managementData.notificationW)/2, managementData.computerY + managementData.computerH/2 - managementData.notificationCenterY + respc(15) + renderData.popupButtonH, managementData.notificationW, renderData.popupButtonH, tocolor(255,255,255,255 * alphaMultiplier), 1, getFont("Roboto-Bold", resp(9)), "center", "center")
			dxDrawSmoothButton("benzin_plus", managementData.computerX + (managementData.computerW - managementData.notificationW)/2, managementData.computerY + managementData.computerH/2 - managementData.notificationCenterY + respc(20) + renderData.popupButtonH*2, managementData.notificationW, renderData.popupButtonH, {51, 133, 84, 255}, {67, 182, 113, 255}, alphaMultiplier)
			dxDrawCorrectText("Benzin EVO Plus", managementData.computerX + (managementData.computerW - managementData.notificationW)/2, managementData.computerY + managementData.computerH/2 - managementData.notificationCenterY + respc(20) + renderData.popupButtonH*2, managementData.notificationW, renderData.popupButtonH, tocolor(255,255,255,255 * alphaMultiplier), 1, getFont("Roboto-Bold", resp(9)), "center", "center")
			dxDrawSmoothButton("diesel_plus", managementData.computerX + (managementData.computerW - managementData.notificationW)/2, managementData.computerY + managementData.computerH/2 - managementData.notificationCenterY + respc(25) + renderData.popupButtonH*3, managementData.notificationW, renderData.popupButtonH, {51, 133, 84, 255}, {67, 182, 113, 255}, alphaMultiplier)
			dxDrawCorrectText("Diesel EVO Plus", managementData.computerX + (managementData.computerW - managementData.notificationW)/2, managementData.computerY + managementData.computerH/2 - managementData.notificationCenterY + respc(25) + renderData.popupButtonH*3, managementData.notificationW, renderData.popupButtonH, tocolor(255,255,255,255 * alphaMultiplier), 1, getFont("Roboto-Bold", resp(9)), "center", "center")
			dxDrawSmoothButton("kerosene", managementData.computerX + (managementData.computerW - managementData.notificationW)/2, managementData.computerY + managementData.computerH/2 - managementData.notificationCenterY + respc(30) + renderData.popupButtonH*4, managementData.notificationW, renderData.popupButtonH, {51, 133, 84, 255}, {67, 182, 113, 255}, alphaMultiplier)
			dxDrawCorrectText("Kerozin", managementData.computerX + (managementData.computerW - managementData.notificationW)/2, managementData.computerY + managementData.computerH/2 - managementData.notificationCenterY + respc(30) + renderData.popupButtonH*4, managementData.notificationW, renderData.popupButtonH, tocolor(255,255,255,255 * alphaMultiplier), 1, getFont("Roboto-Bold", resp(9)), "center", "center")
			
			-- # Decline Button
			dxDrawSmoothButton(notificationData.declineButtonDirectX, managementData.computerX + (managementData.computerW - managementData.notificationW)/2, managementData.computerY + managementData.computerH/2 - managementData.notificationCenterY + respc(35) + renderData.popupButtonH*5, managementData.notificationW, renderData.popupButtonH, {27, 60, 40, 255}, {43, 109, 69, 255}, alphaMultiplier)
			dxDrawCorrectText(notificationData.declineButtonText, managementData.computerX + (managementData.computerW - managementData.notificationW)/2, managementData.computerY + managementData.computerH/2 - managementData.notificationCenterY + respc(35) + renderData.popupButtonH*5, managementData.notificationW, renderData.popupButtonH, tocolor(255,255,255,255 * alphaMultiplier), 1, getFont("Roboto-Bold", resp(9)), "center", "center")
		end
	end

	-- # Show Loading Screen In Case of Internet Problem
	if serverResponsePending then
		dxDrawRectangle(managementData.computerX, managementData.computerY, managementData.computerW, managementData.computerH, tocolor(20,20,20,240))
		dxDrawCorrectText("Várakozás a szerver válaszára...", managementData.computerX, managementData.computerY + respc(40), managementData.computerW, managementData.computerH, tocolor(255,255,255,255), 1, getFont("Roboto-Bold", resp(12)), "center", "center")
		dxDrawImage(managementData.computerX + managementData.computerW/2 - respc(32), managementData.computerY + managementData.computerH/2 - respc(40), respc(64), respc(64), "files/loading_background.png", 0, 0, 0, tocolor(255,255,255,100))
		dxDrawImage(managementData.computerX + managementData.computerW/2 - respc(32), managementData.computerY + managementData.computerH/2 - respc(40), respc(64), respc(64), "files/loading_circle.png", -(getTickCount() % 1000) / 1000 * 360, 0, 0, tocolor(255,0,0,200))
	end
end
--addEventHandler("onClientRender", getRootElement(), renderComputer)

function computerClickHandler(button, state)
	if not managementData.showComputer or serverResponsePending or notificationData.state then return end

	if button == "left" and state == "down" then

		if renderData.activeDirectX == "closeAppPage" and managementData.activePage > 0 then
			managementData.activePage = 0
			managementData.scrollStorageNumber = 0
			editData.actualEditing = ""
		end

		if managementData.activePage == 0 then
			if renderData.activeDirectX == "closeComputer" then
				closeComputer()
			end
		elseif managementData.activePage == 1 then
			-- # Click on change price
			if string.find(renderData.activeDirectX, "change_price_") and editData.actualEditingPrice == 0 then
				renderData.activeDirectX = renderData.activeDirectX:gsub("change_price_", "")
				editData.editingText = computerData.productData[tonumber(renderData.activeDirectX)].price
				editData.actualEditingPrice = tonumber(renderData.activeDirectX)
				editData.actualEditing = "item_price"
				showInfoBox("Add meg a billentyűzeted segítségével az új eladási árat.")
			end
			-- # Save edited price
			if string.find(renderData.activeDirectX, "change_price_") and editData.actualEditingPrice > 0 then
				renderData.activeDirectX = renderData.activeDirectX:gsub("change_price_", "")
				if tonumber(renderData.activeDirectX) == editData.actualEditingPrice then
					if (getTickCount() - limitActionTimer) < 1000 then return end
					
					local price = tonumber(editData.editingText) or 0
					if price >= maxFuelPrice then
						showInfoBox("Maximum "..OldCore:formatCurrency(maxFuelPrice).." lehet az üzemanyag ára!")
						editData.actualEditingPrice = 0
						editData.actualEditing = ""
						editData.editingText = ""
						return
					end
					activeServerRequest(function()
						computerData.productData[editData.actualEditingPrice].price = editData.editingText
						editData.actualEditingPrice = 0
						editData.actualEditing = ""
						editData.editingText = ""
						showInfoBox("Termék ára sikeresen módosítva.")
					end)
					triggerServerEvent("updateFuelBussinessProductData", localPlayer, localPlayer, managementData.shopID, price, editData.actualEditingPrice, "price")
				else
					showInfoBox("Előbb mentsd el a másik termék árát!")
				end
			end
			-- # Click on Quick Sell
			if string.find(renderData.activeDirectX, "quick_sell_") then
				if editData.actualEditingPrice == 0 then
						renderData.activeDirectX = renderData.activeDirectX:gsub("quick_sell_", "")
						-- # Activate notification panel
						notificationData = {
							state = true,
							title = "TERMÉK GYORS ELADÁSA",
							description = "Biztosan el akarod adni a készletet kiürítési áron?",
							productName = Inventory:GetItemName(computerData.productData[tonumber(renderData.activeDirectX)].itemID, computerData.productData[tonumber(renderData.activeDirectX)].itemValue or 1),
							productIndex = tonumber(renderData.activeDirectX),
							productCount = computerData.productData[tonumber(renderData.activeDirectX)].availableStock,
							priceTag = 1, -- TODO MAKE DYNAMIC PRICES
							priceType = "dollar", -- or premium
							acceptButtonText = "Eladás",
							acceptButtonDirectX = "acceptQuickSell",
							declineButtonText = "Mégsem",
							declineButtonDirectX = "declineNotification",
							notificationAlpha = 1,
							notificationTick = getTickCount(),
							editAbleCount = false,
						}
				else
					showInfoBox("Előbb mentsd el az árváltoztatást!")
				end
			end
			-- # Click on buy plus storage capacity
			if renderData.activeDirectX == "plusStorageCapacity" then
				-- # Set Default Edit Data
				editData.editingText = 1
				editData.actualEditing = "plus_capacity_count"
				-- # Activate notification panel
				notificationData = {
					state = true,
					title = "ÜZEMANYAGTARTÁLY KAPACITÁS NÖVELÉS",
					description = "Válaszd ki melyik üzemanyagtípus tartályának kapacitását szeretnéd növelni.",
					productName = "Plusz Kapacitás",
					productIndex = 0,
					productCount = 1,
					priceTag = defaultDatas.plusStorageCapacityPrice * OldCore:getJobPaymentMultiplier("fuel_bussiness_upgrades"),
					priceType = "dollar",
					acceptButtonText = "Bővítés",
					acceptButtonDirectX = "acceptPlusCapacity",
					declineButtonText = "Vissza",
					declineButtonDirectX = "declineNotification",
					notificationAlpha = 1,
					notificationTick = getTickCount(),
					fuelTypeSelect = true,
				}
			elseif renderData.activeDirectX == "plusItemTypes" then
				-- # Set Default Edit Data
				editData.editingText = 1
				editData.actualEditing = "plus_item_types_count"
				-- # Activate notification panel
				notificationData = {
					state = true,
					title = "MAXIMUM VÁLASZTÉK NÖVELÉSE",
					description = "Billentyűzet segítségével add meg a kívánt darabszámot.",
					productName = "Plusz Választék",
					productIndex = 0,
					productCount = 1,
					priceTag = defaultDatas.plusItemTypesPrice * OldCore:getJobPaymentMultiplier("fuel_bussiness_upgrades"),
					priceType = "premium",
					acceptButtonText = "Bővítés",
					acceptButtonDirectX = "acceptPlusItemTypes",
					declineButtonText = "Mégsem",
					declineButtonDirectX = "declineNotification",
					notificationAlpha = 1,
					notificationTick = getTickCount(),
					editAbleCount = true,
				}
			end
		elseif managementData.activePage == 2 then
			-- # Add product to cart
			if string.find(renderData.activeDirectX, "add_cart_") then
				renderData.activeDirectX = renderData.activeDirectX:gsub("add_cart_", "")
				local itemIndex = tonumber(renderData.activeDirectX)
				-- # Set Default Edit Data
				editData.editingText = 1
				editData.actualEditing = "add_cart_item_count"
				-- # Activate notification panel
				notificationData = {
					state = true,
					title = "MENNYISÉG MEGADÁSA",
					description = "Billentyűzet segítségével add meg a kívánt mennyiséget.",
					productName = computerData.generatedMarketSupply.marketTable[itemIndex].itemName,
					productIndex = itemIndex,
					productCount = 1,
					priceTag = computerData.generatedMarketSupply.marketTable[itemIndex].price,
					priceType = "dollar",
					acceptButtonText = "Hozzáadás a kosárhoz",
					acceptButtonDirectX = "addProductToCart",
					declineButtonText = "Elvetés",
					declineButtonDirectX = "declineNotification",
					notificationAlpha = 1,
					notificationTick = getTickCount(),
					editAbleCount = true,
					anotherUnit = "Liter",
				}
			end
			-- # Show shopping Cart
			if renderData.activeDirectX == "checkOrderList" then
				if #shoppingCartData > 0 then
					editData.actualEditing = ""
					-- # Activate notification panel
					notificationData = {
						state = true,
						title = "ÜZEMANYAG RENDELÉS TARTALMA",
						description = "A rendelés leadásra kattintva véglegesítheted rendelésedet.",
						acceptButtonText = "Rendelés leadása",
						acceptButtonDirectX = "finishMarketOrder",
						declineButtonText = "Vásárlás folytatása",
						declineButtonDirectX = "declineNotification",
						notificationAlpha = 1,
						notificationTick = getTickCount(),
						priceTag = getShoppingCartCostSum(),
						editAbleCount = false,
						shoppingCartTable = shoppingCartData,
						anotherUnit = "Liter"
					}
				else
					showInfoBox("Még egyetlen üzemanyagot sem adtál a kosaradhoz.")
				end
			elseif renderData.activeDirectX == "refreshMarketSupply" then
				editData.actualEditing = ""
				-- # Activate notification panel
				notificationData = {
					state = true,
					title = "OIL MARKET KÍNÁLAT FRISSÍTÉSE",
					description = "A frissítéssel teljesen új ajánlatot kap a vállalat.",
					acceptButtonText = "Frissítés",
					acceptButtonDirectX = "acceptRefreshMarket",
					declineButtonText = "Mégsem",
					declineButtonDirectX = "declineNotification",
					notificationAlpha = 1,
					notificationTick = getTickCount(),
					priceTag = defaultDatas.refreshMarketCost,
					priceType = "premium",
					productName = "Ajánlatok frissítése",
					productCount = 1,
					editAbleCount = false,
					shoppingCartTable = false,
					anotherUnit = "x"
				}
			end
			if renderData.activeDirectX == "marketSearchBar" then
				if editData.searchInputText == "Termék keresése..." then
					editData.editingText = ""
				else
					editData.editingText = editData.searchInputText
				end
				editData.actualEditing = "marketSearchBar"
			else
				if editData.actualEditing == "marketSearchBar" then
					editData.actualEditing = ""
					if editData.searchInputText == "Termék keresése..." or editData.searchInputText == "" then
						editData.searchInputText = "Termék keresése..."
					end
				end
			end
		elseif managementData.activePage == 3 then
			-- # Delete Order
			if string.find(renderData.activeDirectX, "cancel_order_") then
				if not isPlayerBussinessOwner() and not Admin:IsHeadAdmin(localPlayer) then
					showInfoBox("Csak a vállalat tulajdonosa törölheti a rendeléseket vagy rendelési előzményeket.", "error")
					return
				end
				renderData.activeDirectX = renderData.activeDirectX:gsub("cancel_order_", "")
				if computerData.orderList[tonumber(renderData.activeDirectX)].orderStatus == "delivery_needed" then
					editData.actualEditing = ""
					-- # Activate notification panel
					notificationData = {
						state = true,
						title = "SZÁLLÍTÁSRA KÉSZ RENDELÉS TÖRLÉSE",
						description = "Amennyiben törlöd a rendelést, az már nem lesz átvehető és az árát sem kapja vissza a cég.",
						acceptButtonText = "Rendelés törlése",
						acceptButtonDirectX = "deleteOrder",
						declineButtonText = "Mégsem",
						declineButtonDirectX = "declineNotification",
						notificationAlpha = 1,
						notificationTick = getTickCount(),
						priceTag = computerData.orderList[tonumber(renderData.activeDirectX)].orderCost,
						productIndex = tonumber(renderData.activeDirectX),
						editAbleCount = false,
						shoppingCartTable = {{itemName = "Rendelésszám: #000"..tonumber(renderData.activeDirectX).." || Rendelés dátuma: "..getFormatDate(computerData.orderList[tonumber(renderData.activeDirectX)].orderMadeTime)}},
					}
				elseif computerData.orderList[tonumber(renderData.activeDirectX)].orderStatus == "delivery_canceled" or computerData.orderList[tonumber(renderData.activeDirectX)].orderStatus == "delivery_success" then
					editData.actualEditing = ""
					-- # Activate notification panel
					notificationData = {
						state = true,
						title = "RENDELÉS TÖRLÉSE AZ ELŐZMÉNYEKBŐL",
						description = "A törléssel az előzményekben már nem fog szerepelni ez a rendelés.",
						acceptButtonText = "Törlése",
						acceptButtonDirectX = "deleteOrder",
						declineButtonText = "Mégsem",
						declineButtonDirectX = "declineNotification",
						notificationAlpha = 1,
						notificationTick = getTickCount(),
						priceTag = computerData.orderList[tonumber(renderData.activeDirectX)].orderCost,
						productIndex = tonumber(renderData.activeDirectX),
						editAbleCount = false,
						shoppingCartTable = {{itemName = "Rendelésszám: #000"..tonumber(renderData.activeDirectX).." || Rendelés dátuma: "..getFormatDate(computerData.orderList[tonumber(renderData.activeDirectX)].orderMadeTime)}},
					}
				elseif computerData.orderList[tonumber(renderData.activeDirectX)].orderStatus == "delivery_process" then
					showInfoBox("Ezt a rendelést nem törölheted, mert jelenleg szállítás alatt áll.")
				end
			elseif string.find(renderData.activeDirectX, "deliver_order_") then
				if not hasPlayerPermission("deliverOrders") then
					showInfoBox("Nincs jogosultságod a rendelések fuvarozásához.", "error")
					return
				end
				renderData.activeDirectX = renderData.activeDirectX:gsub("deliver_order_", "")
				if computerData.orderList[tonumber(renderData.activeDirectX)].orderStatus == "delivery_needed" then
					editData.actualEditing = ""
					-- # Activate notification panel
					notificationData = {
						state = true,
						title = "SZÁLLÍTÁS MEGKEZDÉSE",
						description = "A megkezdés után megkapod a pontos átvételi és lerakodási helyszínt.",
						acceptButtonText = "Megkezdés",
						acceptButtonDirectX = "takeDelivery",
						declineButtonText = "Mégsem",
						declineButtonDirectX = "declineNotification",
						notificationAlpha = 1,
						notificationTick = getTickCount(),
						priceTag = computerData.orderList[tonumber(renderData.activeDirectX)].orderCost,
						productIndex = tonumber(renderData.activeDirectX),
						editAbleCount = false,
						shoppingCartTable = {{itemName = "Rendelésszám: #000"..tonumber(renderData.activeDirectX).." || Rendelés dátuma: "..getFormatDate(computerData.orderList[tonumber(renderData.activeDirectX)].orderMadeTime)}},
					}
				elseif computerData.orderList[tonumber(renderData.activeDirectX)].orderStatus == "delivery_process" then
					showInfoBox("Ez a rendelés, már szállítás alatt áll.", "error")
				elseif computerData.orderList[tonumber(renderData.activeDirectX)].orderStatus == "delivery_success" then
					showInfoBox("Ez a rendelés, már sikeresen kiszállításra került.", "info")
				elseif computerData.orderList[tonumber(renderData.activeDirectX)].orderStatus == "delivery_canceled" then
					showInfoBox("Ez a rendelés meghiúsult, ezért már nem lehet szállítani.", "error")
				end
			end
		elseif managementData.activePage == 4 then
			if renderData.activeDirectX == "plusBussinessMember" then
				if not isPlayerBussinessOwner() and not Admin:IsHeadAdmin(localPlayer) then
					showInfoBox("Csak a vállalat tulajdonosa vehet fel alkalmazottat.", "error")
					return
				end
				editData.actualEditing = "inviteMember"
				editData.editingText = ""
				-- # Activate notification panel
				notificationData = {
					state = true,
					title = "ÚJ ALKALMAZOTT HOZZÁADÁSA",
					description = "Írd be az új alkalmazott nevét vagy ID-ját.",
					acceptButtonText = "Hozzáadás",
					acceptButtonDirectX = "acceptAddMember",
					declineButtonText = "Mégsem",
					declineButtonDirectX = "declineNotification",
					notificationAlpha = 1,
					notificationTick = getTickCount(),
					editAbleCount = false,
					shoppingCartTable = true,
					settingsType = true,
					sumText = "Név / ID:",
					editingText = "",
					editAbleCharacters = true,
				}
			elseif string.find(renderData.activeDirectX, "toggle_permission_handleInventory_") then
				if (getTickCount() - limitActionTimer) < 1000 then return end

				if not isPlayerBussinessOwner() and not Admin:IsHeadAdmin(localPlayer) then
					showInfoBox("Csak a vállalat tulajdonosa szabhatja meg az alkalmazottak jogkörét.", "error")
					return
				end
				renderData.activeDirectX = renderData.activeDirectX:gsub("toggle_permission_handleInventory_", "")
				computerData.permissionData[tonumber(renderData.activeDirectX)].handleInventory = not computerData.permissionData[tonumber(renderData.activeDirectX)].handleInventory
				limitActionTimer = getTickCount()

				triggerServerEvent("updateFuelBussinessData", localPlayer, localPlayer, managementData.shopID, computerData.permissionData, "permissionData")
			elseif string.find(renderData.activeDirectX, "toggle_permission_accessMarket_") then
				if (getTickCount() - limitActionTimer) < 1000 then return end

				if not isPlayerBussinessOwner() and not Admin:IsHeadAdmin(localPlayer) then
					showInfoBox("Csak a vállalat tulajdonosa szabhatja meg az alkalmazottak jogkörét.", "error")
					return
				end
				renderData.activeDirectX = renderData.activeDirectX:gsub("toggle_permission_accessMarket_", "")
				computerData.permissionData[tonumber(renderData.activeDirectX)].accessMarket = not computerData.permissionData[tonumber(renderData.activeDirectX)].accessMarket
				limitActionTimer = getTickCount()

				triggerServerEvent("updateFuelBussinessData", localPlayer, localPlayer, managementData.shopID, computerData.permissionData, "permissionData")
			elseif string.find(renderData.activeDirectX, "toggle_permission_deliverOrders_") then
				if (getTickCount() - limitActionTimer) < 1000 then return end

				if not isPlayerBussinessOwner() and not Admin:IsHeadAdmin(localPlayer) then
					showInfoBox("Csak a vállalat tulajdonosa szabhatja meg az alkalmazottak jogkörét.", "error")
					return
				end
				renderData.activeDirectX = renderData.activeDirectX:gsub("toggle_permission_deliverOrders_", "")
				computerData.permissionData[tonumber(renderData.activeDirectX)].deliverOrders = not computerData.permissionData[tonumber(renderData.activeDirectX)].deliverOrders
				limitActionTimer = getTickCount()

				triggerServerEvent("updateFuelBussinessData", localPlayer, localPlayer, managementData.shopID, computerData.permissionData, "permissionData")
			elseif string.find(renderData.activeDirectX, "toggle_permission_managePayments_") then
				if (getTickCount() - limitActionTimer) < 1000 then return end

				if not isPlayerBussinessOwner() and not Admin:IsHeadAdmin(localPlayer) then
					showInfoBox("Csak a vállalat tulajdonosa szabhatja meg az alkalmazottak jogkörét.", "error")
					return
				end
				renderData.activeDirectX = renderData.activeDirectX:gsub("toggle_permission_managePayments_", "")
				computerData.permissionData[tonumber(renderData.activeDirectX)].managePayments = not computerData.permissionData[tonumber(renderData.activeDirectX)].managePayments
				limitActionTimer = getTickCount()

				triggerServerEvent("updateFuelBussinessData", localPlayer, localPlayer, managementData.shopID, computerData.permissionData, "permissionData")
			elseif string.find(renderData.activeDirectX, "fire_member_") then
				if not isPlayerBussinessOwner() and not Admin:IsHeadAdmin(localPlayer) then
					showInfoBox("Csak a vállalat tulajdonosa rúghat ki alkalmazottat.", "error")
					return
				end
				renderData.activeDirectX = renderData.activeDirectX:gsub("fire_member_", "")
				editData.actualEditing = ""
				-- # Activate notification panel
				notificationData = {
					state = true,
					title = "ALKALMAZOTT KIRÚGÁSA",
					description = "Biztosan ki szeretnéd rúgni az alábbi alkalmazottat?",
					acceptButtonText = "Kirúgás",
					acceptButtonDirectX = "acceptFireMember",
					declineButtonText = "Mégsem",
					declineButtonDirectX = "declineNotification",
					notificationAlpha = 1,
					notificationTick = getTickCount(),
					productIndex = tonumber(renderData.activeDirectX),
					editAbleCount = false,
					shoppingCartTable = true,
					settingsType = true,
					sumText = "Alkalmazott neve:",
					editingText = computerData.permissionData[tonumber(renderData.activeDirectX)].playerName,
				}
			elseif renderData.activeDirectX == "depositBussinessMoney" then
				editData.actualEditing = "depositMoney"
				editData.editingText = ""
				-- # Activate notification panel
				notificationData = {
					state = true,
					title = "BEFIZETÉS A VÁLLALAT SZÁMLÁJÁRA",
					description = "Írd be az összeget, amennyi be akarsz rakni a számlára.",
					acceptButtonText = "Befizetés",
					acceptButtonDirectX = "acceptDepositAmount",
					declineButtonText = "Mégsem",
					declineButtonDirectX = "declineNotification",
					notificationAlpha = 1,
					notificationTick = getTickCount(),
					editAbleCount = false,
					shoppingCartTable = true,
					settingsType = true,
					sumText = "Összeg:",
					editingText = "",
					editAbleCharacters = true,
				}
			elseif renderData.activeDirectX == "withdrawalBussinessMoney" then
				editData.actualEditing = "withDrawMoney"
				editData.editingText = ""
				-- # Activate notification panel
				notificationData = {
					state = true,
					title = "KIFIZETÉS A VÁLLALAT SZÁMLÁJÁRÓL",
					description = "Írd be az összeget, amennyit ki akarsz venni a vállalat számlájáról.",
					acceptButtonText = "Kifizetés",
					acceptButtonDirectX = "acceptWithDrawAmount",
					declineButtonText = "Mégsem",
					declineButtonDirectX = "declineNotification",
					notificationAlpha = 1,
					notificationTick = getTickCount(),
					editAbleCount = false,
					shoppingCartTable = true,
					settingsType = true,
					sumText = "Összeg:",
					editingText = "",
					editAbleCharacters = true,
				}
			elseif renderData.activeDirectX == "changeBussinessName" then
				if not isPlayerBussinessOwner() and not Admin:IsHeadAdmin(localPlayer) then
					showInfoBox("Csak a vállalat tulajdonosa változtathatja meg a vállalat nevét.", "error")
					return
				end
				editData.actualEditing = "changeBussinessName"
				editData.editingText = ""
				-- # Activate notification panel
				notificationData = {
					state = true,
					title = "VÁLLALAT NEVÉNEK MEGVÁLTOZTATÁSA",
					description = "A névváltoztatás ára: #bee2c2"..OldCore:formatCurrency(defaultDatas.changeBussinessNamePrice),
					acceptButtonText = "Megváltoztat",
					acceptButtonDirectX = "acceptNameChange",
					declineButtonText = "Mégsem",
					declineButtonDirectX = "declineNotification",
					notificationAlpha = 1,
					notificationTick = getTickCount(),
					editAbleCount = false,
					shoppingCartTable = true,
					settingsType = true,
					sumText = "Új név:",
					editingText = "",
					editAbleCharacters = true,
				}
			elseif renderData.activeDirectX == "sellBussiness" then
				if not isPlayerBussinessOwner() and not Admin:IsHeadAdmin(localPlayer) then
					showInfoBox("Csak a vállalat tulajdonosa adhatja el a vállalatot.", "error")
					return
				end
				if not sellBussinessData.sellPending then
					editData.actualEditing = "sellBussinessPlayerName"
					editData.editingText = ""
					-- # Activate notification panel
					notificationData = {
						state = true,
						title = "VÁLLALAT ELADÁSA",
						description = "Elsőkörben add meg a játékos nevét / ID-t, akinek el akarod adni a vállalatot.",
						acceptButtonText = "Tovább",
						acceptButtonDirectX = "acceptSellPlayerName",
						declineButtonText = "Mégsem",
						declineButtonDirectX = "declineNotification",
						notificationAlpha = 1,
						notificationTick = getTickCount(),
						editAbleCount = false,
						shoppingCartTable = true,
						settingsType = true,
						sumText = "Név / ID:",
						editingText = "",
						editAbleCharacters = true,
					}
				else
					showInfoBox("Már folyamatban van egy ajánlattétel.", "error")
				end
			end
		elseif managementData.activePage == 5 then
			if string.find(renderData.activeDirectX, "show_more_offer_") then
				renderData.activeDirectX = renderData.activeDirectX:gsub("show_more_offer_", "")
				if computerData.offersData[tonumber(renderData.activeDirectX)].offerStatus == "offer_open" then
					editData.editingText = ""
					-- # Activate notification panel
					notificationData = {
						state = true,
						title = "KISZÁLLÍTÁSI AJÁNLAT",
						description = "Az ajánlatban kért áru kiszállítása a saját raktárkészletedből történik.",
						acceptButtonText = "Elfogadás",
						acceptButtonDirectX = "acceptSelectedOffer",
						declineButtonText = "Vissza",
						declineButtonDirectX = "declineNotification",
						notificationAlpha = 1,
						notificationTick = getTickCount(),
						productIndex = tonumber(renderData.activeDirectX),
						editAbleCount = false,
						sumText = "Fizetség összesen: ",
						shoppingCartTable = computerData.offersData[tonumber(renderData.activeDirectX)].offerItems,
						priceTag = computerData.offersData[tonumber(renderData.activeDirectX)].offerMoney,
						showStorageTick = true,
						anotherUnit = "Liter"
					}
				elseif computerData.offersData[tonumber(renderData.activeDirectX)].offerStatus == "offer_process" then
					showInfoBox("Ezt az ajánlatot már valaki szállítja jelenleg.")
				elseif computerData.offersData[tonumber(renderData.activeDirectX)].offerStatus == "offer_closed" then
					showInfoBox("Ezt az ajánlatot már valaki kiszállította.")
				end
			elseif renderData.activeDirectX == "refreshOfferStatus" then
				if (getTickCount() - limitActionTimer) < 1000 then return end

				activeServerRequest()
				triggerServerEvent("refreshFuelOffersServer", localPlayer, localPlayer, managementData.shopID, tonumber(editData.editingText), editData.actualEditingPrice, "price")
			end
		end
	end
end
--addEventHandler("onClientClick", getRootElement(), computerClickHandler)

function notificationClick(button, state)
	if not notificationData.state or serverResponsePending or (notificationData.closeTimer and isTimer(notificationData.closeTimer)) then return end

	if button == "left" and state == "up" then
		if renderData.activeDirectX == "declineNotification" then
			exitNotification()
		elseif renderData.activeDirectX == "acceptQuickSell" then
			if (getTickCount() - limitActionTimer) < 1000 then return end

			table.remove(computerData.productData, notificationData.productIndex)
			activeServerRequest(function()
				managementData.scrollStorageNumber = 0
				computerData.bussinessBalance = computerData.bussinessBalance + (notificationData.priceTag * notificationData.productCount)
				computerData.bussinessIncome = computerData.bussinessIncome + (notificationData.priceTag * notificationData.productCount)
				exitNotification()
				showInfoBox("A terméket sikeresen eladtad a kiürítési áron.")
			end)

			triggerServerEvent("updateFuelBussinessData", localPlayer, localPlayer, managementData.shopID, computerData.productData, "productData", "quickSellProduct", (notificationData.priceTag * notificationData.productCount))
		elseif renderData.activeDirectX == "acceptPlusCapacity" then
			if tonumber(notificationData.productCount) > 0 then
				if (getTickCount() - limitActionTimer) < 1000 then return end

				activeServerRequest(function()
					computerData.storageCapacity[notificationData.productIndex] = computerData.storageCapacity[notificationData.productIndex] + notificationData.productCount
					exitNotification()
				end)
				triggerServerEvent("checkFuelCapacityPurchaseServer", localPlayer, localPlayer, managementData.shopID, (notificationData.priceTag * notificationData.productCount), "storageCapacity", notificationData.productCount, "A raktár kapacitása sikeresen növelve.", notificationData.priceType, notificationData.productIndex)
			else
				showInfoBox("Adj meg nagyobb értéket mint 0!")
				return
			end
		elseif renderData.activeDirectX == "acceptPlusItemTypes" then
			if tonumber(notificationData.productCount) > 0 then
				if (computerData.maxStorageItems + notificationData.productCount) <= 4 then
					if (getTickCount() - limitActionTimer) < 1000 then return end

					exitNotification()
					activeServerRequest(function()
						computerData.maxStorageItems = computerData.maxStorageItems + notificationData.productCount
					end)
					triggerServerEvent("checkFuelCapacityPurchaseServer", localPlayer, localPlayer, managementData.shopID, (notificationData.priceTag * notificationData.productCount), "maxStorageItems", notificationData.productCount, "A maximum választék sikeresen növelve.", notificationData.priceType)
				else
					showInfoBox("A maximum választék legfeljebb 4 lehet!")
					return
				end
			else
				showInfoBox("Adj meg nagyobb értéket mint 0!")
				return
			end
			-- # Accept product to cart
		elseif renderData.activeDirectX == "addProductToCart" then
			if computerData.generatedMarketSupply.marketTable[notificationData.productIndex].availableStock <= 0 then
				showInfoBox("Ebből a termékből jelenleg készlethiány van.")
				exitNotification()
			else
				if tonumber(editData.editingText) == 0 then
					showInfoBox("Nullánál nagyobb darabszámot adj meg!", "error")
				else
					local amountSum = getShoppingCartAmountSum()
					if (amountSum + notificationData.productCount) <= defaultDatas.maximumOrderAmount then
						local selectedTable = computerData.generatedMarketSupply.marketTable[notificationData.productIndex]
						local alreadyInShoppingCartIndex = shoppingCartAlreadyHasItem(selectedTable.itemID)

						if alreadyInShoppingCartIndex then
							-- NOTE: If this type of product is already in the shopping cart we just add it to the amount
							shoppingCartData[alreadyInShoppingCartIndex].amount = shoppingCartData[alreadyInShoppingCartIndex].amount + notificationData.productCount
						else
							if #shoppingCartData < defaultDatas.maximumOrderOneTime then
								table.insert(shoppingCartData, {realIndex = notificationData.productIndex, itemID = selectedTable.itemID, price = selectedTable.price, amount = tonumber(notificationData.productCount), itemName = selectedTable.itemName})
							else
								exitNotification()
								showInfoBox("Egyszerre csak "..defaultDatas.maximumOrderOneTime.." fajta üzemanyagot rendelhetsz.", "error")
								return
							end
						end

						computerData.generatedMarketSupply.marketTable[notificationData.productIndex].availableStock = computerData.generatedMarketSupply.marketTable[notificationData.productIndex].availableStock - notificationData.productCount
						showInfoBox("A kiválasztott üzemanyag sikeresen hozzáadva a kosárhoz.", "success")
					else
						showInfoBox("Összesen "..defaultDatas.maximumOrderAmount.." liter üzemanyagot rendelhetsz egyszerre.\nKosár tartalma eddig összesen: "..amountSum.." liter", "error")
					end
					exitNotification()
				end
			end
		elseif renderData.activeDirectX == "finishMarketOrder" then
			if (getTickCount() - limitActionTimer) < 1000 then return end

			-- # Avoid bugs and deny order if delivery is in progress
			if isDeliveryInProgress() then
				showInfoBox("Ameddig van folyamatban lévő szállítás addig nem adhatsz le újabb rendelést!", "error")
				return
			end

			activeServerRequest(function()
				computerData.bussinessBalance = computerData.bussinessBalance - notificationData.priceTag
				table.insert(computerData.orderList,  {
					orderMadeTime = getTimestamp(),
					orderStatus = "delivery_needed",
					orderCost = notificationData.priceTag,
					orderData = shoppingCartData,
				})
				shoppingCartData = {}
				exitNotification()
			end)

			local copyTable = table.copy(computerData.orderList, true)
			table.insert(copyTable,  {
				orderMadeTime = getTimestamp(),
				orderStatus = "delivery_needed",
				orderCost = notificationData.priceTag,
				orderData = shoppingCartData,
			})
			triggerServerEvent("checkFinishFuelOrderServer", localPlayer, localPlayer, managementData.shopID, notificationData.priceTag, copyTable, computerData.generatedMarketSupply)
		elseif string.find(renderData.activeDirectX, "remove_cart_") then
			if (getTickCount() - limitActionTimer) < 1000 then return end

			renderData.activeDirectX = renderData.activeDirectX:gsub("remove_cart_", "")
			computerData.generatedMarketSupply.marketTable[shoppingCartData[tonumber(renderData.activeDirectX)].realIndex].availableStock = computerData.generatedMarketSupply.marketTable[shoppingCartData[tonumber(renderData.activeDirectX)].realIndex].availableStock + shoppingCartData[tonumber(renderData.activeDirectX)].amount
			table.remove(shoppingCartData, tonumber(renderData.activeDirectX))
			if #shoppingCartData == 0 then
				exitNotification()
			end
			showInfoBox("A kiválasztott üzemanyag sikeresen eltávolítva a kosaradból.", "success")
		elseif renderData.activeDirectX == "deleteOrder" then
			if (getTickCount() - limitActionTimer) < 1000 then return end

			table.remove(computerData.orderList, notificationData.productIndex)
			activeServerRequest(function()
				exitNotification()
			end)
			triggerServerEvent("updateFuelBussinessData", localPlayer, localPlayer, managementData.shopID,  computerData.orderList, "orderList", false, 0, "Rendelés sikeresen törölve.")
		elseif renderData.activeDirectX == "takeDelivery" then
			if not getElementData(localPlayer, "fuelOrderDelivering") then
				if (getTickCount() - limitActionTimer) < 1000 then return end

				if (not hasTruckerLicense()) then
					Gui:showInfoBox("Nincs érvényes C+E jogosítványod!", "error", nil, nil, true);

					exitNotification();

					return;
				end

				activeServerRequest(function()
					computerData.orderList[notificationData.productIndex].orderStatus = "delivery_process"
					JobTruckdriver:SelectCargoType(1, nil, {bussinessID = managementData.shopID, orderID = notificationData.productIndex}, computerData.storagePositionData)
				end)
				triggerServerEvent("setPlayerFuelOrderDeliveryStatus", localPlayer, localPlayer, managementData.shopID, notificationData.productIndex)
			else
				showInfoBox("Egyszerre csak 1 kiszállítást vállalhatsz el!", "error")
			end
			exitNotification()
		elseif renderData.activeDirectX == "acceptAddMember" then
			local targetPlayer, targetPlayerName = OldCore:findPlayerByPartialNick(localPlayer, notificationData.editingText, nil, 2)
			if targetPlayer then
				if #computerData.permissionData < 10 then
					if not isPlayerAlreadyEmployee(getElementData(targetPlayer, "dbid")) then
						if targetPlayer ~= localPlayer then
							if (getTickCount() - limitActionTimer) < 1000 then return end

							activeServerRequest(function()
								table.insert(computerData.permissionData, {playerID = getElementData(targetPlayer, "dbid"), playerName = getElementData(targetPlayer, "char:Name"):gsub("_", " "), handleInventory = false, accessMarket = false, deliverOrders = false, managePayments = false})
								showInfoBox("Játékos sikeresen hozzáadva a vállalkozáshoz.", "success")
							end)
							triggerServerEvent("addNewMemberToFuelBussiness", localPlayer, localPlayer, managementData.shopID, getElementData(targetPlayer, "dbid"), getElementData(targetPlayer, "char:Name"):gsub("_", " "))
						else
							showInfoBox("Saját magadat nem addhatod hozzá.", "error")
						end
					else
						showInfoBox("Ez a játékos már a vállalat alkalmazotta.", "error")
					end
				else
					showInfoBox("Maximum 10 alkalmazotta lehet a vállalatnak.", "error")
				end
			else
				showInfoBox("Nem található játékos ilyen névvel / ID-val!", "error")
			end
			exitNotification()
		elseif renderData.activeDirectX == "acceptFireMember" then
			if (getTickCount() - limitActionTimer) < 1000 then return end

			activeServerRequest(function()
				showInfoBox("Alkalmazott sikeresen kirúgva.", "success")
				table.remove(computerData.permissionData, notificationData.productIndex)
				exitNotification()
			end)

			local copyTable = table.copy(computerData.permissionData, true)
			table.remove(copyTable, notificationData.productIndex)

			triggerServerEvent("updateFuelBussinessData", localPlayer, localPlayer, managementData.shopID, copyTable, "permissionData")
		elseif renderData.activeDirectX == "acceptDepositAmount" then
			local depositAmount = tonumber(notificationData.editingText)
			if OldCore:hasMoney(localPlayer, depositAmount) then
				if (getTickCount() - limitActionTimer) < 1000 then return end

				activeServerRequest(function()
					local plusAmount = depositAmount - math.floor(depositAmount * defaultDatas.depositTax)
					computerData.bussinessBalance = computerData.bussinessBalance + plusAmount
					showInfoBox("Sikeres befizetve: "..OldCore:formatCurrency(plusAmount).."\nAdó: "..OldCore:formatCurrency(math.floor(depositAmount * defaultDatas.depositTax)))
					exitNotification()
				end)
				triggerServerEvent("manageFuelPaymentChangesServer", localPlayer, localPlayer, managementData.shopID, depositAmount, "deposit")
			else
				showInfoBox("Nincs elég pénz nálad!", "error")
				exitNotification()
			end
		elseif renderData.activeDirectX == "acceptWithDrawAmount" then
			local withDrawAmount = tonumber(notificationData.editingText)
			if computerData.bussinessBalance >= withDrawAmount then
				if (getTickCount() - limitActionTimer) < 1000 then return end

				activeServerRequest(function()
					local plusAmount = withDrawAmount - math.floor(withDrawAmount * defaultDatas.withDrawTax)
					computerData.bussinessBalance = computerData.bussinessBalance - withDrawAmount
					showInfoBox("Sikeres kifizetve: "..OldCore:formatCurrency(plusAmount).."\nAdó: "..OldCore:formatCurrency(math.floor(withDrawAmount * defaultDatas.withDrawTax)))

					exitNotification()
				end)
				triggerServerEvent("manageFuelPaymentChangesServer", localPlayer, localPlayer, managementData.shopID, withDrawAmount, "withdraw")
			else
				showInfoBox("Nincs ennyi pénz a vállalat számláján!", "error")
				exitNotification()
			end
		elseif renderData.activeDirectX == "acceptNameChange" then
			if notificationData.editingText ~= "" then
				if computerData.bussinessBalance >= defaultDatas.changeBussinessNamePrice then
					if (getTickCount() - limitActionTimer) < 1000 then return end

					activeServerRequest(function()
						computerData.bussinessName = notificationData.editingText
						computerData.bussinessBalance = computerData.bussinessBalance - defaultDatas.changeBussinessNamePrice
						showInfoBox("A vállalat neve sikeresen megváltoztatva", "success")
						exitNotification()
					end)

					triggerServerEvent("changeFuelBussinessNameServer", localPlayer, localPlayer, managementData.shopID, notificationData.editingText)
				else
					showInfoBox("Nincs ennyi pénz a vállalat számláján!", "error")
					exitNotification()
				end
			else
				showInfoBox("Adj meg egy érvényes nevet!", "error")
			end
		elseif renderData.activeDirectX == "acceptSellPlayerName" then
			local targetPlayer, targetPlayerName = OldCore:findPlayerByPartialNick(localPlayer, notificationData.editingText, nil, 2)
			if targetPlayer then
				if targetPlayer ~= localPlayer then
					local playerX, playerY, playerZ = getElementPosition(localPlayer)
					local targetX, targetY, targetZ = getElementPosition(targetPlayer)
					if getDistanceBetweenPoints3D(playerX, playerY, playerZ, targetX, targetY, targetZ) <= 5 then
						sellBussinessData.buyerElement = targetPlayer
						-- # Reactivate input
						editData.actualEditing = "sellBussinessCost"
						editData.editingText = ""
						-- # Activate notification panel
						notificationData = {
							state = true,
							title = "VÁLLALAT ELADÁSA",
							description = "Add meg az árat, amennyiért eladásra kínálod a vállalatot.",
							acceptButtonText = "Ajánlattétel",
							acceptButtonDirectX = "acceptSellBussiness",
							declineButtonText = "Mégsem",
							declineButtonDirectX = "declineNotification",
							notificationAlpha = 1,
							notificationTick = 0,
							editAbleCount = false,
							shoppingCartTable = true,
							settingsType = true,
							sumText = "Összeg:",
							editingText = "",
							editAbleCharacters = true,
						}
						showInfoBox("Játékos kiválasztva: "..targetPlayerName:gsub("_", " ").."\nMost add meg az eladási árat.", "success")
					else
						showInfoBox("A játékos nem tartózkodik a közeledben!", "error")
						exitNotification()
					end
				else
					showInfoBox("Saját magadnak nem adhatod el a vállalkozást.", "error")
				end
			else
				showInfoBox("Nem található játékos ilyen névvel / ID-val!", "error")
				exitNotification()
			end
		elseif renderData.activeDirectX == "acceptSellBussiness" then
			if (getTickCount() - limitActionTimer) < 1000 then return end

			sellBussinessData.bussinessCost = notificationData.editingText
			activeServerRequest(function()
				sellBussinessData.sellPending = true
			end)
			exitNotification()
			triggerServerEvent("makeFuelBussinessSellingDeal", localPlayer, localPlayer, sellBussinessData.buyerElement, sellBussinessData.bussinessCost, computerData.bussinessName, managementData.shopID)
		elseif renderData.activeDirectX == "acceptSelectedOffer" then
			if checkStorageForOffer(computerData.offersData[notificationData.productIndex].offerItems) then
				if (getElementData(localPlayer, "fuelOfferDelivering")) then
					showInfoBox("Egyszerre csak 1 kiszállítást vállalhatsz el!", "error")

					exitNotification();

					return;
				end

				if (getTickCount() - limitActionTimer) < 1000 then return end

				if (not hasTruckerLicense()) then
					Gui:showInfoBox("Nincs érvényes C+E jogosítványod!", "error", nil, nil, true);

					exitNotification();

					return;
				end

				activeServerRequest(function()
					computerData.offersData[notificationData.productIndex].offerStatus = "offer_process"
					-- # Start the truckdriver job
					local randomDeliveryIndex = math.random(1, #deliveryPositions)
					JobTruckdriver:StartDelivery({isOut = true, BusinessId = managementData.shopID, DeliveryId = notificationData.productIndex, offerMoney = computerData.offersData[notificationData.productIndex].offerMoney, deliveryPumpID = randomDeliveryIndex}, computerData.storagePositionData, deliveryPositions[randomDeliveryIndex])
					-- # Remove the items from storage
					-- removeStorageOfferItems(computerData.offersData[notificationData.productIndex].offerItems)
					exitNotification()
				end)

				triggerServerEvent("updateFuelOfferStatus", localPlayer, localPlayer, managementData.shopID, notificationData.productIndex, "offer_process")
			else
				showInfoBox("Az ajánlatban megjelölt áruból vagy azok mennyiségéből nincs elég raktáron.")
			end
		elseif renderData.activeDirectX == "benzin" or renderData.activeDirectX == "diesel" or renderData.activeDirectX == "benzin_plus" or renderData.activeDirectX == "diesel_plus" or renderData.activeDirectX == "kerosene" then
			local fuelIndex = renderData.activeDirectX
			local fuelText = fuelIndex
			if specialFuels[fuelIndex] then
				fuelText = specialFuels[fuelIndex] .. " tartály"
			else
				fuelText = fuelIndex:sub( 1, 1 ):upper( )..fuelIndex:sub( 2 ).." tartály"
				fuelText = fuelText:gsub("_", " ")
			end

			notificationData = {
				state = true,
				title = "ÜZEMANYAGTARTÁLY KAPACITÁS NÖVELÉS",
				description = "Billentyűzet segítségével add meg a kívánt darabszámot.",
				productName = fuelText,
				productIndex = fuelIndex,
				productCount = 1,
				priceTag = defaultDatas.plusStorageCapacityPrice * OldCore:getJobPaymentMultiplier("fuel_bussiness_upgrades"),
				priceType = "dollar",
				acceptButtonText = "Bővítés",
				acceptButtonDirectX = "acceptPlusCapacity",
				declineButtonText = "Mégsem",
				declineButtonDirectX = "declineNotification",
				notificationAlpha = 1,
				notificationTick = getTickCount(),
				editAbleCount = true,
			}
		elseif renderData.activeDirectX == "acceptRefreshMarket" then
			if (getTickCount() - limitActionTimer) < 1000 then return end

			activeServerRequest()
			exitNotification()
			triggerServerEvent("refreshOilMarketServer", localPlayer, localPlayer, managementData.shopID)
		end
	end
end
--addEventHandler("onClientClick", getRootElement(), notificationClick)

function exitNotification()
	notificationData.notificationTick = getTickCount()
	notificationData.notificationAlpha = 0
	notificationData.closeTimer = setTimer(function() notificationData.state = false end, 550, 1)
end

function doubleClickApps(button, state)
	if (not state) then return end

	if not managementData.showComputer or managementData.activePage > 0 or serverResponsePending then return end
	if button == "left" then
		if string.find(renderData.activeDirectX, "app_") then
			renderData.activeDirectX = renderData.activeDirectX:gsub("app_", "")
			if tonumber(renderData.activeDirectX) == 1 then
				if not hasPlayerPermission("handleInventory") then
					showInfoBox("Nincs jogosultságod megnyitni ezt az oldalt.", "error")
					return
				end
			elseif tonumber(renderData.activeDirectX) == 2 then
				if not hasPlayerPermission("accessMarket") then
					showInfoBox("Nincs jogosultságod megnyitni ezt az oldalt.", "error")
					return
				end
			elseif tonumber(renderData.activeDirectX) == 4 then
				if not hasPlayerPermission("managePayments") then
					showInfoBox("Nincs jogosultságod megnyitni ezt az oldalt.", "error")
					return
				end
			end
			managementData.activePage = tonumber(renderData.activeDirectX)
		end
	end
end
-- addEventHandler("onClientDoubleClick", getRootElement(), doubleClickApps)
addEventHandler("onClientClick", getRootElement(), doubleClickApps)

local allowedOnlyNumber = false
local numberAllowed = 10
local maximumLetter = 40

addEventHandler('onClientCharacter', getRootElement(), function(character)
	if not managementData.showComputer or serverResponsePending or editData.actualEditing == "" then return end

	if editData.actualEditingPrice > 0 then
		allowedOnlyNumber = true
		numberAllowed = 10000000
	end

	if editData.actualEditing == "marketSearchBar" then
		allowedOnlyNumber = false
		numberAllowed = 0
		maximumLetter = 40
	elseif editData.actualEditing == "inviteMember" or editData.actualEditing == "sellBussinessPlayerName" then
		allowedOnlyNumber = false
		numberAllowed = 0
		maximumLetter = 50
	elseif editData.actualEditing == "depositMoney" or editData.actualEditing == "withDrawMoney" or editData.actualEditing == "sellBussinessCost" then
		allowedOnlyNumber = true
		numberAllowed = 100000000
	elseif editData.actualEditing == "changeBussinessName" then
		allowedOnlyNumber = false
		numberAllowed = 0
		maximumLetter = defaultDatas.bussinessNameMaxCharacters
	elseif editData.actualEditing == "plus_capacity_count" or editData.actualEditing == "plus_item_types_count" then
		allowedOnlyNumber = true
		numberAllowed = 100000
	elseif editData.actualEditing == "add_cart_item_count" then
		allowedOnlyNumber = true
		numberAllowed = computerData.generatedMarketSupply.marketTable[notificationData.productIndex].availableStock
	end

	if allowedOnlyNumber then
		if editData.editingText == "0" then
			newText = character
		else
			newText = editData.editingText .. character
		end
		if tonumber(newText) then
			if tonumber(newText) >= 1 and tonumber(newText) <= numberAllowed and not string.find(newText, "e") and not string.find(newText, " ") then
				editData.editingText = newText
			end
		end
	else
		if (utf8.len(editData.editingText) <= maximumLetter) then
			managementData.scrollMarketNumber = 0

			if editData.editingText == "Termék keresése..." then
				editData.editingText = character
			else
				editData.editingText = editData.editingText .. character
			end
		end
	end
end)

addEventHandler('onClientKey', getRootElement(), function(button, state)
  if not managementData.showComputer or serverResponsePending then return end

	if editData.actualEditing ~= "" then
		if button ~= "mouse_wheel_up" and button ~= "mouse_wheel_down" then
			cancelEvent()
		end
	end

  if button == "backspace" and state then
		if editData.actualEditing == "marketSearchBar" then
			if editData.editingText == "Termék keresése..." then
				editData.editingText = ""
			end
		end
    if utf8.len(editData.editingText) > 1 then
      editData.editingText = utf8.sub(editData.editingText, 1, utf8.len(editData.editingText)-1)
		elseif utf8.len(editData.editingText) == 1 then
			if editData.actualEditing == "item_price" or editData.actualEditing == "plus_capacity_count" or editData.actualEditing == "plus_item_types_count" or editData.actualEditing == "add_cart_item_count" then
				editData.editingText = "0"
			else
				editData.editingText = ""
				return
			end
	  end
	end
end)

-- # Selling Contract # --
local buyingData = {
	sellerName = "Steve Scott",
	bussinessName = "Steve és Társa Bt.",
	sellingCost = 100000,
	shopID = 0,
	notificationAlpha = 1,
	notificationTick = 0,
}

function showFuelBussinessSellingContract(sellerElement, sellerName, sellingCost, bussinessName, shopID)
	addEventHandler("onClientClick", getRootElement(), clickSellingContract)
	addEventHandler("onClientRender", getRootElement(), renderBussinessContract)
	buyingData.sellerElement = sellerElement
	buyingData.sellerName = sellerName
	buyingData.sellingCost = sellingCost
	buyingData.bussinessName = bussinessName
	buyingData.shopID = shopID
	buyingData.notificationAlpha = 1
	buyingData.notificationTick = getTickCount()
end
addEvent("showFuelBussinessSellingContract", true)
addEventHandler("showFuelBussinessSellingContract", getRootElement(), showFuelBussinessSellingContract)

function playerDenyFuelBussinessDealClient()
	showInfoBox("Az adásvételi szerződést elutasította a kiválasztott játékos.", "error")
	sellBussinessData = {
		buyerElement = nil,
		bussinessCost = 0,
		sellPending = false,
	}
end
addEvent("playerDenyFuelBussinessDealClient", true)
addEventHandler("playerDenyFuelBussinessDealClient", getRootElement(), playerDenyFuelBussinessDealClient)

function playerAcceptFuelBussinessDealClient()
	showInfoBox("Sikeresen eladtad a vállalkozást.", "success")
	sellBussinessData = {
		buyerElement = nil,
		bussinessCost = 0,
		sellPending = false,
	}
	if managementData.showComputer then
		closeComputer()
	end
end
addEvent("playerAcceptFuelBussinessDealClient", true)
addEventHandler("playerAcceptFuelBussinessDealClient", getRootElement(), playerAcceptFuelBussinessDealClient)

function renderBussinessContract()
	local progress = (getTickCount() - buyingData.notificationTick) / 350
	local alphaMultiplier = interpolateBetween(math.abs(buyingData.notificationAlpha-1), 0, 0, buyingData.notificationAlpha, 0, 0, progress, "Linear")
	local listHeight = -respc(30)

	dxDrawRectangle(0, 0, screenX, screenY, tocolor(20,20,20,250 * alphaMultiplier))
	dxDrawCorrectText("VÁLLALAT ADÁSVÉTELI SZERZŐDÉS", managementData.computerX, managementData.computerY - managementData.notificationTextY - respc(25), managementData.computerW, managementData.computerH, tocolor(255,255,255,255 * alphaMultiplier), 1, getFont("Roboto", resp(14)), "center", "center")
	dxDrawCorrectText(buyingData.sellerName.." eladásra kínálta "..buyingData.bussinessName.." nevű vállalkozását.", managementData.computerX, managementData.computerY - managementData.notificationTextY, managementData.computerW, managementData.computerH, tocolor(255,255,255,150 * alphaMultiplier), 1, getFont("Roboto-Light", resp(10)), "center", "center", false, false, false, true)
	dxDrawRectangle(managementData.computerX + (managementData.computerW - managementData.notificationW)/2, managementData.computerY + managementData.computerH/2 - managementData.notificationCenterY, managementData.notificationW, respc(1), tocolor(255,255,255,255 * alphaMultiplier))
	dxDrawCorrectText("Eladási ár: ", managementData.computerX + (managementData.computerW - managementData.notificationW)/2, managementData.computerY + managementData.computerH/2 - managementData.notificationCenterY, managementData.notificationW, respc(30), tocolor(255,255,255,255 * alphaMultiplier), 1, getFont("Roboto-Light", resp(9)), "left", "center")
	dxDrawCorrectText(""..OldCore:formatCurrency(buyingData.sellingCost), managementData.computerX + (managementData.computerW - managementData.notificationW)/2, managementData.computerY + managementData.computerH/2 - managementData.notificationCenterY, managementData.notificationW, respc(30), tocolor(255,255,255,255 * alphaMultiplier), 1, getFont("Roboto-Light", resp(9)), "right", "center", false, false, true)
	dxDrawRectangle(managementData.computerX + (managementData.computerW - managementData.notificationW)/2, managementData.computerY + managementData.computerH/2 - managementData.notificationCenterY + respc(30), managementData.notificationW, respc(1), tocolor(255,255,255,255 * alphaMultiplier))
	-- # Accept Button
	dxDrawSmoothButton("acceptSellingContract", managementData.computerX + (managementData.computerW - managementData.notificationW)/2 + managementData.notificationW/2 + respc(5), managementData.computerY + managementData.computerH/2 - managementData.notificationCenterY + managementData.notificationSumY + renderData.popupButtonH + respc(10) + listHeight, managementData.notificationW/2 - respc(5), renderData.popupButtonH, {51, 133, 84, 255}, {67, 182, 113, 255}, alphaMultiplier)
	dxDrawCorrectText("Elfogadás", managementData.computerX + (managementData.computerW - managementData.notificationW)/2 + managementData.notificationW/2 + respc(5), managementData.computerY + managementData.computerH/2 - managementData.notificationCenterY + managementData.notificationSumY + renderData.popupButtonH + respc(10) + listHeight, managementData.notificationW/2 - respc(5), renderData.popupButtonH, tocolor(255,255,255,255 * alphaMultiplier), 1, getFont("Roboto-Bold", resp(9)), "center", "center")
	-- # Decline Button
	dxDrawSmoothButton("denySellingContract", managementData.computerX + (managementData.computerW - managementData.notificationW)/2, managementData.computerY + managementData.computerH/2 - managementData.notificationCenterY + managementData.notificationSumY + renderData.popupButtonH + respc(10) + listHeight, managementData.notificationW/2 - respc(5), renderData.popupButtonH, {27, 60, 40, 255}, {43, 109, 69, 255}, alphaMultiplier)
	dxDrawCorrectText("Elutasítás", managementData.computerX + (managementData.computerW - managementData.notificationW)/2, managementData.computerY + managementData.computerH/2 - managementData.notificationCenterY + managementData.notificationSumY + renderData.popupButtonH + respc(10) + listHeight, managementData.notificationW/2 - respc(5), renderData.popupButtonH, tocolor(255,255,255,255 * alphaMultiplier), 1, getFont("Roboto-Bold", resp(9)), "center", "center")
end

function clickSellingContract(button, state)
	if button == "left" and state == "down" then
		if renderData.activeDirectX == "denySellingContract" then
			if isElement(buyingData.sellerElement) then
				triggerServerEvent("playerDenyFuelBussinessDeal", localPlayer, buyingData.sellerElement)
			end
			showInfoBox("Sikeresen elutasítottad az adásvételi szerződést.")
			exitContract()
		elseif renderData.activeDirectX == "acceptSellingContract" then
			-- NOTE: trigger event for sellerElement: closeComputer, giveMoney | Change bussinessOwner | for buyer: Take money
			if OldCore:hasMoney(localPlayer, tonumber(buyingData.sellingCost)) then
				triggerServerEvent("playerAcceptFuelBussinessDeal", localPlayer, localPlayer, buyingData.sellerElement, tonumber(buyingData.sellingCost), buyingData.shopID)
				exitContract()
			else
				showInfoBox("Nincs elég pénzed a vásárláshoz.", "error")
				triggerServerEvent("playerDenyFuelBussinessDeal", localPlayer, buyingData.sellerElement)
				exitContract()
			end
		end
	end
end

function exitContract()
	removeEventHandler("onClientClick", getRootElement(), clickSellingContract)
	buyingData.notificationAlpha = 0
	buyingData.notificationTick = getTickCount()
	setTimer(function()
		buyingData = {}
		removeEventHandler("onClientRender", getRootElement(), renderBussinessContract)
	end, 550, 1)
end

-- # Side Functions # --

function getCorrectTimeFormat()
	local actualTime = getRealTime()
	local hours = actualTime.hour
	local minutes = actualTime.minute
	local monthday = actualTime.monthday
	local month = actualTime.month
	local year = actualTime.year
	-- Make sure to add a 0 to the front of single digits.
	if (hours < 10) then hours = "0"..hours end
	if (minutes < 10) then minutes = "0"..minutes end

	return hours..":"..minutes.."\n"..(year + 1900).."/"..(month + 1).."/"..monthday
end

function getStorageItemCount()
	local itemCount = 0
	for key, value in pairs(computerData.productData) do
		itemCount = itemCount + value.availableStock
	end
	return math.floor(itemCount)
end

function hasStorageItemAmount(itemID, amount)
	for key, value in pairs(computerData.productData) do
		if value.itemID == itemID and tonumber(value.availableStock) >= amount then
			return true
		end
	end
	return false
end

function checkStorageForOffer(offerTable)
	for key, value in pairs(offerTable) do
		if not hasStorageItemAmount(value.itemID, value.amount) then
			return false
		end
	end
	return true
end

function removeStorageOfferItems(offerTable)
	-- # Remove the products from storage
	for offerKey, offerValue in pairs(offerTable) do
		for storageKey, storageValue in pairs (computerData.productData) do
			if storageValue.itemID == offerValue.itemID then
				if tonumber(storageValue.availableStock) == offerValue.amount then
					table.remove(computerData.productData, storageKey)
				elseif tonumber(storageValue.availableStock) > offerValue.amount then
					storageValue.availableStock = storageValue.availableStock - offerValue.amount
				end
			end
		end
	end
end

function shoppingCartAlreadyHasItem(itemID)
	for key, value in pairs(shoppingCartData) do
		if value.itemID == itemID then
			return key
		end
	end
	return false
end

function getShoppingCartAmountSum()
	local sum = 0
	for key, value in pairs(shoppingCartData) do
		sum = sum + value.amount
	end
	return sum
end

function getOrderAmountSum(orderData)
	local sum = 0
	for key, value in pairs(orderData) do
		sum = sum + value.amount
	end
	return sum
end

function getShoppingCartCostSum()
	local totalCost = 0
	for key, value in pairs(shoppingCartData) do
		totalCost = totalCost + (value.amount * value.price)
	end
	return totalCost
end

function getStorageCapacitySum()
	local summa = 0
	for key, value in pairs(computerData.storageCapacity) do
		summa = summa + value
	end
	return math.floor(summa)
end

function isDeliveryInProgress()
	for key, value in pairs(computerData.orderList) do
		if value.orderStatus == "delivery_process" then
			return true
		end
	end
	return false
end

function hasPlayerPermission(permissionIndex)
	-- # Give the owner full permission
	if getElementData(localPlayer, "dbid") == computerData.bussinessOwner or Admin:IsHeadAdmin(localPlayer) then
		return true
	end
	-- # If the player is not owner
	for key, value in pairs(computerData.permissionData) do
		-- # Check if he is on the list
		if getElementData(localPlayer, "dbid") == tonumber(value.playerID) then
			return value[permissionIndex]
		end
	end
	return false
end

function isPlayerBussinessOwner()
	if getElementData(localPlayer, "dbid") == computerData.bussinessOwner then
		return true
	end
	return false
end

function isPlayerAlreadyEmployee(playerID)
	for key, value in pairs(computerData.permissionData) do
		if value.playerID == playerID then
			return true
		end
	end
	return false
end

bindKey("mouse_wheel_down", "down", function()
	if managementData.showComputer then
		if managementData.activePage == 1 then
			if managementData.scrollStorageNumber < #computerData.productData - managementData.maxShowableStorageItems then
				managementData.scrollStorageNumber = managementData.scrollStorageNumber + 1
			end
		elseif managementData.activePage == 3 then
			if managementData.scrollOrdersNumber < #computerData.orderList - managementData.maxShowAbleOrderItems then
				managementData.scrollOrdersNumber = managementData.scrollOrdersNumber + 1
			end
		elseif managementData.activePage == 5 then
			if managementData.scrollOfferNumber < #computerData.offersData - managementData.maxShowAbleOfferItems then
				managementData.scrollOfferNumber = managementData.scrollOfferNumber + 1
			end
		end
	end
end)

bindKey("mouse_wheel_up", "down", function()
	if managementData.showComputer then
	 	if managementData.activePage == 1 then
			if managementData.scrollStorageNumber > 0 then
				managementData.scrollStorageNumber = managementData.scrollStorageNumber - 1
			end
		elseif managementData.activePage == 2 then
			if managementData.scrollMarketNumber > 0 then
				managementData.scrollMarketNumber = managementData.scrollMarketNumber - 1
			end
		elseif managementData.activePage == 3 then
			if managementData.scrollOrdersNumber > 0 then
				managementData.scrollOrdersNumber = managementData.scrollOrdersNumber - 1
			end
		elseif managementData.activePage == 5 then
			if managementData.scrollOfferNumber > 0 then
				managementData.scrollOfferNumber = managementData.scrollOfferNumber - 1
			end
		end
	end
end)

-- # Create Computer Button In Office # --
function CheckInterior(_, newInterior)
	if newInterior == officeComputerPosition.interior and getDistanceBetweenPoints3D(Vector3(getElementPosition(localPlayer)), Vector3(unpack(officeComputerPosition.position))) <= 50 then
		triggerServerEvent("requestFuelOfficeInteriors", localPlayer, localPlayer)
	elseif newInterior == 0 then
		if managementData.officeID ~= 0 then
			removeWorldText("computerButton")
		end
	end
end

local checkTimer
addEventHandler("onClientElementInteriorChange", localPlayer, function()
	if isTimer(checkTimer) then killTimer(checkTimer) end
	checkTimer = setTimer(function()
		CheckInterior(_, getElementInterior(localPlayer))
	end, 1000, 1)
end)

addEventHandler("onClientElementDimensionChange", localPlayer, function()
	if isTimer(checkTimer) then killTimer(checkTimer) end
	checkTimer = setTimer(function()
		CheckInterior(_, getElementInterior(localPlayer))
	end, 1000, 1)
end)

addEventHandler("onClientResourceStart", getResourceRootElement(getThisResource()), function()
	CheckInterior(_, getElementInterior(localPlayer))
end)

addEventHandler("onClientElementDataChange", localPlayer, function(data)
	if data == "spawned" then
		CheckInterior(_, getElementInterior(localPlayer))
	end
end)

addEventHandler("onClientResourceStop", getResourceRootElement(getThisResource()), function()
	-- # Reset the job
	if getElementData(localPlayer, "fuelOfferDelivering") or getElementData(localPlayer, "fuelOrderDelivering") then
		JobTruckdriver:resetOilJob()
	end
end)

addEvent("receiveFuelOfficeDataOnEnter", true)
addEventHandler("receiveFuelOfficeDataOnEnter", root, function(shopID)
	if shopID > 0 then
		managementData.shopID = shopID -- NOTE: Ez az NPC shop ID-je, azaz a szerver data index key-e
		-- NOTE: ide át kell hozni az egész datat
		createWorldButton("computerButton", officeComputerPosition.position, tocolor(0,0,0,200), tocolor(248,102,37,255), "Számítógép kezelése", "computer", 0, 10)
	else
		if managementData.shopID > 0 then
			managementData.shopID = 0
		end
		removeWorldText("computerButton")
	end
end)

function clickOpenComputer(button, state)
	if button == "left" and state == "down" then
		if renderData.activeDirectX == "computerButton" then
			if not managementData.showComputer then
				if (getTickCount() - limitActionTimer) < 1000 then return end

				local playerX, playerY, playerZ = getElementPosition(localPlayer)
				if getDistanceBetweenPoints3D(Vector3(getElementPosition(localPlayer)), Vector3(unpack(getWorldTextPosition("computerButton")))) <= 1.5 then
					triggerServerEvent("requestFuelBussinessComputerData", localPlayer, localPlayer, managementData.shopID)
				else
					showInfoBox("Túl messze vagy a számítógéptől!", "error")
				end
			end
		end
	end
end
addEventHandler("onClientClick", getRootElement(), clickOpenComputer)


-- # Admin Part # ..
local clickedPosition = {position = {}, rotation = 0}
local saveEditShopID = 0
local onlyGetPosition = false
local pumpObject = nil

function adminChooseRefillPosition(shopID, getPosition)
	showCursor(true)
	saveEditShopID = shopID
	onlyGetPosition = getPosition
	local objId = ({
		["v3"] = 13864,
		["sa"] = 8069,
		["ng"] = 17857,
	})["v3"]
	pumpObject = createObject(objId, 0, 0, 0)
	setElementCollisionsEnabled(pumpObject, false)
	addEventHandler("onClientRender", getRootElement(), renderStripePreview)
	addEventHandler("onClientClick", getRootElement(), clickStoragePreview)
	bindKey("mouse_wheel_down", "down", rotatePreviewRight)
	bindKey("mouse_wheel_up", "down", rotatePreviewLeft)
end
addEvent("adminChooseRefillPosition", true)
addEventHandler("adminChooseRefillPosition", root, adminChooseRefillPosition)

function renderStripePreview()
	-- # Give information to the admin
	dxDrawTextWithBorder("A benzinkút lerakodóhelyének beállításához használd a kurzorod.\nA kijelölt pozíciót a #0072ffgörgő #ffffff segítségével tudod forgatni.\nA bal egérgomb lenyomásával rögzítheted a pozíciót.", 2, 0, screenY-respc(200), screenX, 0, tocolor(0, 0, 0, 25), tocolor(255, 255, 255), 1, 1, getFont("Roboto", resp(12)), "center", "top", false, false,false, true)
	-- # Create the stripe preview
	if isCursorShowing() then
		-- # Calculate the hit position of the cursor
		local relX, relY = getCursorPosition(true)
		local cursorX, cursorY = relX * screenX, relY * screenY
		local camX, camY, camZ = getCameraMatrix()
		local cursorWorldPosX, cursorWorldPosY, cursorWorldPosZ = getWorldFromScreenPosition(cursorX, cursorY, 1000)
		local hit, hitX, hitY, hitZ, hitElement, normalX, normalY, normalZ = processLineOfSight(camX, camY, camZ, cursorWorldPosX, cursorWorldPosY, cursorWorldPosZ, true, true, false, true, true, true, false, true)
		-- # Set the preview table to the hit position
		if hitX and hitY and hitZ then
			local rotVector = Vector3(0, 0, clickedPosition.rotation)
			local posM = Matrix(Vector3(hitX, hitY, hitZ), rotVector):transformPosition(Vector3(-6/2, -2/2, 0))
			local posMatrix = Matrix(posM, rotVector)
			local pos = posMatrix:transformPosition(Vector3(12, 0, 0))

			setElementPosition(pumpObject, pos.x, pos.y, pos.z)

			DrawBoxOnGround({hitX, hitY, hitZ}, {6, 2}, clickedPosition.rotation, tocolor(0, 200, 0), 0)
			clickedPosition.position[1], clickedPosition.position[2], clickedPosition.position[3] = hitX, hitY, hitZ
		end
	end
end

function clickStoragePreview(button, state)
	if button == "left" and state == "up" then
		if not onlyGetPosition then
			triggerServerEvent("updateFuelBussinessData", localPlayer, localPlayer, saveEditShopID, clickedPosition, "storagePositionData")
			showInfoBox("A benzinkút töltésipozíciója sikeresen elmentve.", "success")
			saveEditShopID = 0
		else
			Core:OutputToPlayer("A kijelölt pozíció: {position = {"..clickedPosition.position[1]..", "..clickedPosition.position[2]..", "..clickedPosition.position[3].."}, rotation = "..clickedPosition.rotation.."}", _, "green")
		end
		showCursor(false)
		removeEventHandler("onClientRender", getRootElement(), renderStripePreview)
		removeEventHandler("onClientClick", getRootElement(), clickStoragePreview)
		unbindKey("mouse_wheel_down", "down", rotatePreviewRight)
		unbindKey("mouse_wheel_up", "down", rotatePreviewLeft)
		destroyElement(pumpObject)
		pumpObject = nil
	end
end

function getStripePosition()
	if Admin:IsHeadAdmin(localPlayer) then
		adminChooseRefillPosition(0, true)
	end
end
addCommandHandler("getrefillposition", getStripePosition)

function rotatePreviewRight()
	clickedPosition.rotation = clickedPosition.rotation - 15
end

function rotatePreviewLeft()
	clickedPosition.rotation = clickedPosition.rotation + 15
end

-- infobox
function showInfoBox(msg, type)
	Gui:showInfoBox(msg, type, nil, nil, true)
end
