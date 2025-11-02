serverResponsePending = false
serverResponseState = ""
serverResponseTimer = nil
limitActionTimer = 0

renderData = {
	activeDirectX = "",
	shopOpened = false,
	officePreview = nil,
	officeID = 0,
	officeHasOwner = 0,
	shopW = respc(490),
	shopH = respc(240),
	headerH = respc(50),
	backgroundGap = respc(2),
	itemGap = respc(16),
	popupButtonW = respc(350),
	popupButtonH = respc(20),
	popupContentH = respc(50),
	popupCorrectionH = respc(60),
	searchBarH = respc(25),
	searchBarGap = respc(1),
}

renderData.shopX = screenX/2 - renderData.shopW/2
renderData.shopY = screenY/2 - renderData.shopH/2

local shopData = {
	--[[
	shopName = "Bolt",
	shopOwner = 0,
	shopItems = {
		{
			itemName = "Diesel Evo",
			price = 10,
			availableStock = 200,
		},
	},
	]]
}

function renderItemShop()
	if not renderData.shopOpened then
		return
	end
	renderData.activeDirectX = ""

	-- # Background
	dxDrawRectangle(0, 0, screenX, screenY, tocolor(0,0,0,100))
	dxDrawRectangle(renderData.shopX, renderData.shopY, renderData.shopW, renderData.shopH, tocolor(15,15,15,200))
	dxDrawRectangle(renderData.shopX + renderData.backgroundGap, renderData.shopY + renderData.backgroundGap, renderData.shopW - renderData.backgroundGap*2, renderData.shopH - renderData.backgroundGap*2, tocolor(54,54,54,255))
	-- # Popup Window For Buying Bussiness
	dxDrawRectangle(renderData.shopX, renderData.shopY, renderData.shopW, renderData.shopH, tocolor(0,0,0,180))
	dxDrawCorrectText("BENZINKÚT MEGVÁSÁRLÁSA", renderData.shopX, renderData.shopY - renderData.popupCorrectionH, renderData.shopW, renderData.shopH, tocolor(255,255,255,255), 1, getFont("Roboto-Bold", resp(12)), "center", "center")
	dxDrawCorrectText("Ennek az benzinkútnak még nincs tulajdonosa.\nSzeretnéd megvásárolni?", renderData.shopX, renderData.shopY - renderData.popupCorrectionH + respc(40), renderData.shopW, renderData.shopH, tocolor(255,255,255,255), 1, getFont("Roboto", resp(10)), "center", "center")
	dxDrawCorrectText("Ár: "..OldCore:formatCurrency(shopData.shopPrice), renderData.shopX, renderData.shopY - renderData.popupCorrectionH + respc(75), renderData.shopW, renderData.shopH, tocolor(64,179,110,255), 1, getFont("Roboto", resp(10)), "center", "center")
	dxDrawSmoothButton("exitBuyBussiness", renderData.shopX + (renderData.shopW - renderData.popupButtonW/1.25)/2, renderData.shopY + renderData.shopH / 2 + renderData.itemGap*2.25 + renderData.popupContentH + renderData.popupButtonH - renderData.popupCorrectionH, renderData.popupButtonW/2.5 - respc(5), renderData.popupButtonH, {27, 60, 40, 255}, {43, 109, 69, 255})
	dxDrawSmoothButton("acceptBuyBussiness", renderData.shopX + (renderData.shopW - renderData.popupButtonW/1.25)/2 + renderData.popupButtonW/2.5, renderData.shopY + renderData.shopH / 2 + renderData.itemGap*2.25 + renderData.popupContentH + renderData.popupButtonH - renderData.popupCorrectionH, renderData.popupButtonW/2.5 - respc(5), renderData.popupButtonH, {51, 133, 84, 255}, {67, 182, 113, 255})
	dxDrawCorrectText("Kilépés", renderData.shopX + (renderData.shopW - renderData.popupButtonW/1.25)/2, renderData.shopY + renderData.shopH / 2 + renderData.itemGap*2.25 + renderData.popupContentH + renderData.popupButtonH - renderData.popupCorrectionH, renderData.popupButtonW/2.5 - respc(5), renderData.popupButtonH, tocolor(255, 255, 255, 255), 1, getFont("Roboto", resp(8)), "center", "center")
	dxDrawCorrectText("Megvásárlás", renderData.shopX + (renderData.shopW - renderData.popupButtonW/1.25)/2 + renderData.popupButtonW/2.5, renderData.shopY + renderData.shopH / 2 + renderData.itemGap*2.25 + renderData.popupContentH + renderData.popupButtonH - renderData.popupCorrectionH, renderData.popupButtonW/2.5 - respc(5), renderData.popupButtonH, tocolor(255, 255, 255, 255), 1, getFont("Roboto", resp(8)), "center", "center")
	-- # Wait for server response
	if serverResponsePending then
		dxDrawRectangle(renderData.shopX, renderData.shopY, renderData.shopW, renderData.shopH, tocolor(20,20,20,240))
		dxDrawCorrectText("Várakozás a szerver válaszára...", renderData.shopX, renderData.shopY + respc(40), renderData.shopW, renderData.shopH, tocolor(255,255,255,255), 1, getFont("Roboto-Bold", resp(12)), "center", "center")
		dxDrawImage(renderData.shopX + renderData.shopW/2 - respc(32), renderData.shopY + renderData.shopH/2 - respc(40), respc(64), respc(64), "files/loading_background.png", 0, 0, 0, tocolor(255,255,255,100))
		dxDrawImage(renderData.shopX + renderData.shopW/2 - respc(32), renderData.shopY + renderData.shopH/2 - respc(40), respc(64), respc(64), "files/loading_circle.png", -(getTickCount() % 1000) / 1000 * 360, 0, 0, tocolor(255,0,0,200))
	end
end

function handleClickShop(button, state, absoluteX, absoluteY, worldX, worldY, worldZ, clickedElement)
	if serverResponsePending then return end
	if renderData.shopOpened then
		if button == "left" and state == "up" then
			if renderData.activeDirectX == "exitBuyBussiness" then
				exitShop()
				return
			elseif renderData.activeDirectX == "acceptBuyBussiness" then
				if (getTickCount() - limitActionTimer) < 1000 then return end

				-- # Player Trying to buy the bussiness
				activeServerRequest(function()
					exitShop()
				end)
				triggerServerEvent("requestFuelBussinessPurchase", localPlayer, localPlayer, shopData.shopID, shopData.shopPrice)
			end
		end
	end
end

function exitShop()
	removeEventHandler("onClientRender", getRootElement(), renderItemShop)
	removeEventHandler("onClientClick", getRootElement(), handleClickShop)
	renderData.shopOpened = false

	if shopData.shopID and shopData.shopID > 0 then
		triggerServerEvent("exitFuelBussinessShop", localPlayer, localPlayer, shopData.shopID, shopData.elementShopIndex)
		shopData = {}
	end
end
addEvent("fuelSys:clientExitShop", true)
addEventHandler("fuelSys:clientExitShop", getRootElement(), exitShop)

addEvent("receiveFuelBussinessData", true)
addEventHandler("receiveFuelBussinessData", root, function(id, shopPrice)
	shopData.shopID = id
	shopData.shopPrice = shopPrice

	if not renderData.shopOpened then
		renderData.shopOpened = true
		addEventHandler("onClientRender", getRootElement(), renderItemShop)
		addEventHandler("onClientClick", getRootElement(), handleClickShop)
	end
end)


addEvent("changeFuelRequestState", true)
addEventHandler("changeFuelRequestState", root, function(state, callbackMessage)
	serverResponseState = state

	if (callbackMessage) then
		showInfoBox(callbackMessage)
	end
end)

-- Kliens: szerver-válaszok kezelése a shop UI részére
addEvent("createFuelOrderResult", true)
addEventHandler("createFuelOrderResult", root, function(success, payload)
	if success then
		serverResponseState = "Successful"
	else
		serverResponseState = "Failed"
	end
	if payload and type(payload) == "string" then
		showInfoBox("Szerver: "..tostring(payload), success and "success" or "error")
	end
end)

addEvent("orderFinishedClient", true)
addEventHandler("orderFinishedClient", root, function(resultOrOrderID)
	if resultOrOrderID == false then
		serverResponseState = "Failed"
		showInfoBox("A rendelés lezárása sikertelen.", "error")
	else
		serverResponseState = "Successful"
		showInfoBox("A rendelés lezárva: "..tostring(resultOrOrderID), "success")
	end
end)

addEvent("showFuelCapacityPurchaseResult", true)
addEventHandler("showFuelCapacityPurchaseResult", root, function(success, addAmount)
	if success then
		serverResponseState = "Successful"
		showInfoBox("Kapacitás bővítve: +"..tostring(addAmount), "success")
	else
		serverResponseState = "Failed"
		showInfoBox("Kapacitás bővítése sikertelen.", "error")
	end
end)

function activeServerRequest(callBackFunction)
	if (serverResponseTimer and serverResponseTimer.valid) then
		return
	end

	if (not serverResponsePending) then
		serverResponsePending = true
		limitActionTimer = getTickCount()
	end

	serverResponseTimer = setTimer(function()
		if (serverResponseState == "") then return end

		if (serverResponseState == "Successful" or serverResponseState == "Checked") then
			if (serverResponseTimer and serverResponseTimer.valid) then
				serverResponseTimer:destroy(serverResponseTimer)
				serverResponseTimer = nil
			end

			if callBackFunction and serverResponseState == "Successful" then
				callBackFunction()
			end

			serverResponsePending = false
			serverResponseState = ""
		end
	end, 50, 0)
end

-- # Admin Part # ..

function adminChooseFuelOfficePosition(bussinessID, hasOwner)
	showInfoBox("A kurzorod segítségével válaszd ki az iroda interior pozícióját!")
	renderData.officePreview = createMarker(0, 0, 0, "cylinder", 1, 255, 105, 38, 200)
	renderData.officeID = bussinessID
	renderData.officeHasOwner = hasOwner
	setElementInterior(renderData.officePreview, localPlayer.interior)
	setElementDimension(renderData.officePreview, localPlayer.dimension)
	addEventHandler("onClientRender", getRootElement(), renderOfficePreview)
	addEventHandler("onClientClick", getRootElement(), clickOfficePreview)
end
addEvent("adminChooseFuelOfficePosition", true)
addEventHandler("adminChooseFuelOfficePosition", root, adminChooseFuelOfficePosition)

function renderOfficePreview()
	if isElement(renderData.officePreview) then
		-- # Give information to the admin
		dxDrawTextWithBorder("Az iroda interior pozíciójának beállításához használd a kurzorod.\nMentés: #0072ffBal klikk #ffffff", 2, 0, screenY-respc(200), screenX, 0, tocolor(0, 0, 0, 25), tocolor(255, 255, 255), 1, 1, getFont("Roboto", resp(12)), "center", "top", false, false,false, true)
		if isCursorShowing() then
			-- # Calculate the hit position of the cursor
			local relX, relY = getCursorPosition(true)
			local cursorX, cursorY = relX * screenX, relY * screenY
			local camX, camY, camZ = getCameraMatrix()
			local cursorWorldPosX, cursorWorldPosY, cursorWorldPosZ = getWorldFromScreenPosition(cursorX, cursorY, 1000)
			local hit, hitX, hitY, hitZ, hitElement, normalX, normalY, normalZ = processLineOfSight(camX, camY, camZ, cursorWorldPosX, cursorWorldPosY, cursorWorldPosZ, true, true, false, true, true, true, false, true)
			-- # Set the preview table to the hit position
			if hitX and hitY and hitZ then
				setElementPosition(renderData.officePreview, hitX, hitY, hitZ)
			end
		end
	end
end

function clickOfficePreview(button, state)
	if button == "left" and state == "down" then
		if isElement(renderData.officePreview) then
			local newX, newY, newZ = getElementPosition(renderData.officePreview)
			local saveTable = {x = newX, y = newY, z = newZ, interior = renderData.officePreview.interior, dimension = renderData.officePreview.dimension}
			triggerServerEvent("setFuelBussinessOfficePosition", localPlayer, localPlayer, renderData.officeID, saveTable, renderData.officeHasOwner and renderData.officeHasOwner > 0)
			removeEventHandler("onClientRender", getRootElement(), renderOfficePreview)
			removeEventHandler("onClientClick", getRootElement(), clickOfficePreview)
			destroyElement(renderData.officePreview)
			renderData.officeID = 0
			showInfoBox("Sikeresen beállítottad az üzlet iroda pozícióját.")
			showInfoBox("Állítsd be a vállalat lerakodó pozícióját a \n/setrefillposition [bussinessID] paranccsal!!")
		end
	end
end

-- addCommandHandler("nearbyfuelnpcs", function()
-- 	if Admin:IsHeadAdmin(localPlayer) then
-- 		outputChatBox("#FFB300[HL] #ffffffNPC-k körülötted:", 255, 126, 0, true)

-- 		local posX, posY, posZ = getElementPosition(localPlayer)
-- 		local count = 0

-- 		for key, theNPC in ipairs(getElementsByType("ped", resourceRoot, true)) do
-- 			local x, y, z = getElementPosition(theNPC)
-- 			local distance = getDistanceBetweenPoints3D(posX, posY, posZ, x, y, z)
-- 			if distance <= 10 then
-- 				local id = tonumber(getElementData(theNPC, "fuel:id")) or 0
-- 				if id > 0 then
-- 					local npcName = tostring(getElementData(theNPC, "name")) or "Ismeretlen"
-- 					count = count + 1
-- 					outputChatBox("#FFB300[HL-Fuel]#ffffff ID: "..id.." - NÉV: "..npcName, 0, 255, 255, true)
-- 				end
-- 			end
-- 		end

-- 		if count == 0 then
-- 			outputChatBox("#FFB300[HL] #ffffffNincs találat.", 255, 255, 255, true)
-- 		end
-- 	end
-- end)

addCommandHandler({"nearbyfuelnpcs", "neargas", "neargasstations"}, function()
	if Admin:IsHeadAdmin(localPlayer) or Dashboard:GetPlayerFactionType(localPlayer) == 8 then
		outputChatBox("#FFB300[HL ~ Benzinkút] #ffffffNPC-k körülötted:", 255, 126, 0, true)

		local posX, posY, posZ = getElementPosition(localPlayer)
		local count = 0

		for key, theNPC in ipairs(getElementsByType("ped", resourceRoot, true)) do
			local x, y, z = getElementPosition(theNPC)
			local distance = getDistanceBetweenPoints3D(posX, posY, posZ, x, y, z)
			if distance <= 10 then
				local id = tonumber(getElementData(theNPC, "fuel:id")) or 0
				if id > 0 then
					local npcName = tostring(getElementData(theNPC, "name")) or "Ismeretlen"
					count = count + 1
					Core:OutputToPlayer("ID: "..id.." - NÉV: "..npcName, _, "red", "Benzinkút")
					Core:OutputToPlayer("BENZINKÚT AZONOSÍTÓ: "..(tonumber(getElementData(theNPC, "fuel:stationIndex")) or 0), _, "red", "Benzinkút")
				end
			end
		end

		if count == 0 then
			outputChatBox("#FFB300[HL ~ Benzinkút] #ffffffNincs találat.", 255, 255, 255, true)
		end
	end
end)
