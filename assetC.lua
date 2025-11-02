-- // Assets for the Script collected and written by Steve Scott // --

screenX, screenY = guiGetScreenSize()

reMap = function(value, low1, high1, low2, high2)
	return low2 + (value - low1) * (high2 - low2) / (high1 - low1)
end

responsiveMultiplier = reMap(screenX, 1024, 1920, 0.85, 1)

resp = function(value)
	return value * responsiveMultiplier
end

respc = function(value)
	return math.ceil(value * responsiveMultiplier)
end

local animationData = {}
animationData.savedValue = {}
animationData.startInterpolation = {}
animationData.lastValue = {}

function calculateColorAnimation(key, color, duration, type)
	duration = duration or 500
	type = type or "Linear"
	size = size or 20

	color[4] = color[4] or 255

	if not animationData.savedValue[key] then
		animationData.savedValue[key] = color
		animationData.lastValue[key] = color
	end

	if animationData.lastValue[key][1] ~= color[1] or animationData.lastValue[key][2] ~= color[2] or animationData.lastValue[key][3] ~= color[3] or animationData.lastValue[key][4] ~= color[4] then
		animationData.lastValue[key] = color
		animationData.startInterpolation[key] = getTickCount()
	end

	local progress = 0
	if animationData.startInterpolation[key] then
		progress = (getTickCount() - animationData.startInterpolation[key]) / duration
		local newColor1, newColor2, newColor3 = interpolateBetween(animationData.savedValue[key][1], animationData.savedValue[key][2] or 0, animationData.savedValue[key][3] or 0, color[1], color[2] or 0, color[3] or 0, progress, type)

		alpha = interpolateBetween(animationData.savedValue[key][4], 0, 0, color[4], 0, 0, progress, type)

		animationData.savedValue[key] = {newColor1, newColor2, newColor3, alpha}

		if progress >= 1 then
			animationData.startInterpolation[key] = false
		end
	end

	return animationData.savedValue[key], progress
end

function dxDrawCorrectText(text, left, top, right, bottom, color, scale, font, alignX, alignY, clip, wordBreak, postGUI, colorHex)
  dxDrawText(text, left, top, left+right, top+bottom, color, scale, font, alignX, alignY, clip, wordBreak, postGUI, colorHex)
end

function dxDrawSmoothButtonImage(key,x,y,w,h,image,color,hoverColor,rotation,alphaMultiplier)
	local animatedColor = nil
	alphaMultiplier = alphaMultiplier or 1
	rotation = rotation or 0
	if isCursorInBox(x,y,w,h) then
		renderData.activeDirectX = key
		animatedColor = calculateColorAnimation(key, hoverColor, 500)
	else
		animatedColor = calculateColorAnimation(key, color, 500)
	end
	dxDrawImage(x,y,w,h,image,rotation,0,0,tocolor(animatedColor[1], animatedColor[2], animatedColor[3], animatedColor[4] * alphaMultiplier))
end

function dxDrawSmoothButton(key,x,y,w,h,color,hoverColor,alphaMultiplier)
	alphaMultiplier = alphaMultiplier or 1
	if isCursorInBox(x,y,w,h) then
		renderData.activeDirectX = key
		animatedColor = calculateColorAnimation(key, hoverColor, 500)
	else
		animatedColor = calculateColorAnimation(key, color, 500)
	end

	local calcAlpha = color[4] - animatedColor[4]
	dxDrawRectangle(x,y,w,h,tocolor(animatedColor[1], animatedColor[2], animatedColor[3], (color[4] - calcAlpha) * alphaMultiplier))
end

function dxDrawSmoothFrameButton(key,x,y,w,h,color,hoverColor,textDefColor, textActiveColor, text)
	if isCursorInBox(x,y,w,h) then
		renderData.activeDirectX = key
		animatedColor = calculateColorAnimation(key, hoverColor, 500)
		textColor = calculateColorAnimation(key.."text", textActiveColor, 500)
	else
		animatedColor = calculateColorAnimation(key, color, 500)
		textColor = calculateColorAnimation(key.."text", textDefColor, 500)
	end

	local calcAlpha = color[4] - animatedColor[4]
	dxDrawRectangle(x,y,w,h,tocolor(animatedColor[1], animatedColor[2], animatedColor[3], color[4] - calcAlpha))
	dxDrawCorrectText(text, x,y,w,h, tocolor(textColor[1],textColor[2],textColor[3],textColor[4]), 1, getFont("Roboto", resp(9)), "center", "center")
end

function dxDrawSmoothFrame(key,x,y,w,h,border,color,hoverColor)
	if isCursorInBox(x,y,w,h) then
		renderData.activeDirectX = key
		animatedColor = calculateColorAnimation(key, hoverColor, 500)
	else
		animatedColor = calculateColorAnimation(key, color, 500)
	end

	local calcAlpha = color[4] - animatedColor[4]
	dxDrawFrame(x,y,w,h,border, tocolor(animatedColor[1], animatedColor[2], animatedColor[3], color[4] - calcAlpha))
end

function dxDrawImageOnElement(TheElement,Image,distance,posZ,width,height,R,G,B,alpha)
	local x, y, z = getElementPosition(TheElement)
	local x2, y2, z2 = getElementPosition(localPlayer)
	local distance = distance or 20
	local height = height or 1
	local width = width or 1

	local distanceBetweenPoints = getDistanceBetweenPoints3D(x, y, z, x2, y2, z2)
	if(distanceBetweenPoints < distance) then
		dxDrawMaterialLine3D(x, y, z + posZ + height, x, y, z + posZ, Image, width, tocolor(R or 255, G or 255, B or 255, alpha or 255))
	end
end

function dxDrawScrollBar(x, y, widht, height, allElements, showing, place, backgroundColor, scrollColor)
	if allElements > showing then
		dxDrawRectangle(x, y, widht, height, backgroundColor or tocolor(0,0,0,200))
		dxDrawRectangle(x, y+((place)*(height/(allElements))), widht, height/math.max((allElements/showing),1), scrollColor or tocolor(102, 153, 204, 255))
	end
end

function dxDrawTextWithBorder(text, offset, x, y, w, h, borderColor, color, scale, font, alignX, alignY, clip, wordBreak, postGUI, colorCoded, subPixelPositioning, fRotation, fRotationCenterX, fRotationCenterY)
	for offsetX = -offset, offset do
		for offsetY = -offset, offset do
			dxDrawText(text:gsub("#%x%x%x%x%x%x", ""), x + offsetX, y + offsetY, w + offsetX, h + offsetY, borderColor, scale, font, alignX, alignY, clip, wordBreak, postGUI, colorCoded, subPixelPositioning, fRotation, fRotationCenterX, fRotationCenterY)
		end
	end

	dxDrawText(text, x, y, w, h, color, scale, font, alignX, alignY, clip, wordBreak, postGUI, colorCoded, subPixelPositioning, fRotation, fRotationCenterX, fRotationCenterY)
end

function dxDrawHoverFrame(index, x, y, sz, m, thickness, activeColor, hoverText)
	dxDrawToolTip(x,y,sz,m, hoverText)
	if isCursorInBox(x, y, sz, m) then
		renderData.activeDirectX = index
		dxDrawRectangle ( x, y-thickness, sz, thickness, activeColor ) -- Felso
		dxDrawRectangle ( x-thickness, y-thickness, thickness, m+(thickness*2), activeColor ) -- Bal
		dxDrawRectangle ( x+sz, y-thickness, thickness, m+(thickness*2), activeColor ) -- Jobb
		dxDrawRectangle ( x, y+m, sz, thickness, activeColor ) -- Also
	end
end

function dxDrawFrame(x, y, sz, m, thickness, activeColor)
	dxDrawRectangle ( x, y-thickness, sz, thickness, activeColor ) -- Felso
	dxDrawRectangle ( x-thickness, y-thickness, thickness, m+(thickness*2), activeColor ) -- Bal
	dxDrawRectangle ( x+sz, y-thickness, thickness, m+(thickness*2), activeColor ) -- Jobb
	dxDrawRectangle ( x, y+m, sz, thickness, activeColor ) -- Also
end

function dxDrawToolTip(x,y,sz,m, hoverText, fontSize)
	fontSize = fontSize or resp(12)
	if isCursorInBox(x, y, sz, m) then
		local cursorX, cursorY = getCursorPosition(true)
		local relX, relY = cursorX * screenX, cursorY * screenY
		local font = getFont("Roboto", fontSize)
		local textWidth = dxGetTextWidth(hoverText, 1, font)
		dxDrawRectangle(relX+respc(5), relY+respc(5), textWidth+respc(10), respc(30), tocolor(0,0,0,200), true)
		dxDrawText(hoverText, relX+respc(5), relY+respc(5), relX+textWidth+respc(15), relY+respc(35), tocolor(255,255,255), 1, font, "center", "center", true, true, true, true, true)
	end
end

function isCursorInBox(xS,yS,wS,hS)
	if(isCursorShowing()) then
		XY = {guiGetScreenSize()}
		local cursorX, cursorY = getCursorPosition(true)
		cursorX, cursorY = cursorX*XY[1], cursorY*XY[2]
		if(isInBox(xS,yS,wS,hS, cursorX, cursorY)) then
			return true
		else
			return false
		end
	end
end

function isInBox(dX, dY, dSZ, dM, eX, eY)
	if(eX >= dX and eX <= dX+dSZ and eY >= dY and eY <= dY+dM) then
		return true
	else
		return false
	end
end

function isObjectWithinDistance(object1, object2, meters)
  local x,y,z = getElementPosition(object1)
  local x2,y2,z2 = getElementPosition(object2)
  if getDistanceBetweenPoints3D(x,y,z,x2,y2,z2) <= meters then
    return true
  else
    return false
  end
end

function secondsToTimeDesc( seconds )
	if seconds then
		local results = {}
		local sec = ( seconds %60 )
		local min = math.floor ( ( seconds % 3600 ) /60 )
		local hou = math.floor ( ( seconds % 86400 ) /3600 )
		local day = math.floor ( seconds /86400 )

		if day > 0 then table.insert( results, day .. " nap") end
		if hou > 0 then table.insert( results, hou .. " óra") end
		if min > 0 then table.insert( results, min .. " perc") end
		if sec > 0 then table.insert( results, sec .. " másodperc") end

		return string.reverse ( table.concat ( results, " " ):reverse())
	end
	return ""
end

function getFormatDate(timestamp)
	local time = getRealTime(timestamp)
	time.year = time.year + 1900
	time.month = time.month + 1

	return time.year.."/"..time.month.."/"..time.monthday
end

function table.copy(tab, recursive)
    local ret = {}
    for key, value in pairs(tab) do
        if (type(value) == "table") and recursive then ret[key] = table.copy(value)
        else ret[key] = value end
    end
    return ret
end

stripeMarks = {}

stripeMinWidth = 1
stripeMinHeight = 1
stripeMaxWidth = 16
stripeMaxHeight = 16

function simulateStripeMove(startX, startY, endX, endY)
	if not startX or not startY or not endX or not endY then return end

	for k, v in pairs(stripeMarks) do
		if v.width == (endX - startX) or v.height == (endY - startY) then
			return
		end

		if ((endX and endY and hitZ)) and isElement(v.renderTarget) then
			destroyElement(v.renderTarget)
		end

		if endX - startX <= 0 then
			local temporaryX = startX
			startX = endX
			endX = temporaryX
			temporaryX = nil
		end

		if endY - startY <= 0 then
			local temporaryY = startY
			startY = endY
			endY = temporaryY
			temporaryY = nil
		end

		local finalWidth = endX - startX
		local finalHeight = endY - startY

		if finalWidth >= stripeMaxWidth then
			finalWidth = stripeMaxWidth
		end

		if finalHeight >= stripeMaxHeight then
			finalHeight = stripeMaxHeight
		end

		setStripeSize(startX or clickedPosition[1], startY or clickedPosition[2], finalWidth, finalHeight)
	end
end

function setStripeSize(x, y, width, height)
  local newStripe = stripeMarks[1]

  local halfWidth = width * 0.5
  local halfHeight = height * 0.5


  newStripe.x0 = x
  newStripe.y0 = y

  newStripe.x0mid = x + halfWidth
  newStripe.y0mid = y + halfHeight

  newStripe.x1 = x + halfWidth
  newStripe.y1 = y

  newStripe.x2 = x + halfWidth
  newStripe.y2 = y + height

  newStripe.x3 = x + halfWidth
  newStripe.y3 = y + halfHeight

  newStripe.width = width
  newStripe.height = height

	if newStripe.width >= stripeMinWidth and newStripe.height >= stripeMinHeight then
		newStripe.renderTarget = dxCreateRenderTarget(newStripe.width * 48, newStripe.height * 48, true)

    dxSetRenderTarget(newStripe.renderTarget)

    for x = 0, newStripe.width * 2 do
      for y = 0, newStripe.height * 2 do
        dxDrawImage(x * 24, y * 24, 24, 24, "files/stripe.png", 0, 0, 0)
      end
    end

    dxDrawRectangle(0, 0, 8, newStripe.height * 48)
    dxDrawRectangle(newStripe.width * 48 - 8, 0, 8, newStripe.height * 48)
    dxDrawRectangle(0, 0, newStripe.width * 48, 8)
    dxDrawRectangle(0, newStripe.height * 48 - 8, newStripe.width * 48, 8)

    dxSetRenderTarget()
	end
end

function makeNewStripe(x, y, z, width, height, resetRenderTarget, color, interior, dimension, type)
  local newStripe = {}

  newStripe.z0 = z-0.999
  newStripe.z0mid = z-0.999
  newStripe.z1 = z-0.999
  newStripe.z2 = z-0.999
  newStripe.z3 = z + 10

  newStripe.width = width
  newStripe.height = height

  newStripe.color = color

  if newStripe.width >= stripeMinWidth and newStripe.height >= stripeMinHeight then
    newStripe.renderTarget = dxCreateRenderTarget(newStripe.width * 48, newStripe.height * 48, true)

    dxSetRenderTarget(newStripe.renderTarget)

    for x = 0, newStripe.width * 2 do
      for y = 0, newStripe.height * 2 do
        dxDrawImage(x * 24, y * 24, 24, 24, "files/stripe.png", 0, 0, 0)
      end
    end

    dxDrawRectangle(0, 0, 8, newStripe.height * 48)
    dxDrawRectangle(newStripe.width * 48 - 8, 0, 8, newStripe.height * 48)
    dxDrawRectangle(0, 0, newStripe.width * 48, 8)
    dxDrawRectangle(0, newStripe.height * 48 - 8, newStripe.width * 48, 8)

    dxSetRenderTarget()
	end
  -- # Add the created table to the actual stripe array
  table.insert(stripeMarks, newStripe)
end

function DrawBoxOnGround(Position, Offset, Rotation, Color, HeightCorrect)
  local y = HeightCorrect and HeightCorrect or 0
  Utility:drawEmptyRectangle3D(Position[1], Position[2], Position[3] + y, 0, 0, Rotation, Offset[1] * 2, Offset[2] * 2, Color, 4)
end
