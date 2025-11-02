local worldTexts = {}

function createWorldText(index, text, position, color, font, plusZ, textIcon, maxDistance)
  maxDistance = maxDistance or 3
  plusZ = plusZ or 0

  worldTexts[index] = {
    text = text,
    position = position,
    color = color,
    font = font,
    plusZ = plusZ,
    textIcon = textIcon,
    maxDistance = maxDistance,
  }
end

function createWorldButton(index, position, color, hoverColor, hoverText, buttonIcon, plusZ, maxDistance)
  maxDistance = maxDistance or 3
  plusZ = plusZ or 0

  worldTexts[index] = {
    text = false,
    position = position,
    color = color,
    hoverColor = hoverColor,
    hoverText = hoverText,
    buttonIcon = buttonIcon,
    plusZ = plusZ,
    maxDistance = maxDistance,
  }
end

function createWorldImage(index, position, texture, maxDistance)
  maxDistance = maxDistance or 3
  plusZ = plusZ or 0

  worldTexts[index] = {
    text = false,
    position = position,
    texture = texture,
    plusZ = plusZ,
    maxDistance = maxDistance,
  }
end

function getWorldTextPosition(index)
  if worldTexts[index] then
    return worldTexts[index].position
  end
end

function setWorldTextPosition(index, position)
  if worldTexts[index] then
    worldTexts[index].position = position
  end
end

function removeWorldText(index)
  worldTexts[index] = nil
end

function renderWorldTexts()
  if managementData.showComputer then return end
  local cameraX, cameraY, cameraZ = getCameraMatrix()
  renderData.activeDirectX = ""

  for k, v in pairs(worldTexts) do
    local posX, posY, posZ = unpack(v.position)
    --if isLineOfSightClear(cameraX, cameraY, cameraZ, posX, posY, posZ+v.plusZ, true, false, false, false, false, true, false) then
      local headPosX, headPosY = getScreenFromWorldPosition(posX, posY, posZ+v.plusZ, 0, false)
      if headPosX and headPosY then
        local distance = getDistanceBetweenPoints3D(cameraX, cameraY, cameraZ, posX, posY, posZ)

        if distance <= v.maxDistance then
          local progress = distance / v.maxDistance

          if progress < 1 then
            local scale = interpolateBetween(1, 0, 0, 0.17, 0, 0, progress, "OutQuad") * responsiveMultiplier

            local text = v.text
            if text then
              local font = getFont(v.font[1], v.font[2])

              local fontScale = responsiveMultiplier * scale
              fontScale = fontScale * 2
              local textWidth = dxGetTextWidth(text, fontScale, font, true)
              local fontHeight = dxGetFontHeight(fontScale, font)

              if textWidth then
                local textPosX = headPosX - textWidth * 0.5
                dxDrawText(utf8.gsub(text, "#%x%x%x%x%x%x", ""), textPosX + 1, headPosY + 1, 100, 100, tocolor(0,0,0), fontScale, font, "left", "top", false, false, false, true, true)
                dxDrawText(text, textPosX, headPosY, 100, 100, tocolor(255,255,255), fontScale, font, "left", "top", false, false, false, true, true)
                if v.textIcon then
                  dxDrawImage(textPosX + textWidth/2 - 40 * fontScale, headPosY - 80 * fontScale - 5, 80 * fontScale, 80 * fontScale, "files/computer/"..v.textIcon..".png")
                end
              end
            else
              if v.buttonIcon then
                dxDrawRectangle(headPosX - respc(50) * scale, headPosY - respc(50) * scale, respc(100) * scale, respc(100) * scale, v.color)
                dxDrawImage(headPosX - respc(50) * scale, headPosY - respc(50) * scale, respc(100) * scale, respc(100) * scale, "files/computer/"..v.buttonIcon..".png")
                dxDrawHoverFrame(k, headPosX - respc(50) * scale, headPosY - respc(50) * scale, respc(100) * scale, respc(100) * scale, 1, v.hoverColor, v.hoverText)
              end
              if v.texture then
                dxDrawImage(headPosX - respc(140) * scale, headPosY - respc(140) * scale, respc(280) * scale, respc(280) * scale, "files/oxygen_meter.png")
                dxDrawImage(headPosX - respc(140) * scale, headPosY - respc(140) * scale, respc(280) * scale, respc(280) * scale, "files/oxygen_needle.png", loadOxygenRotation)
              end
            end
          end
        end
      end
    --end
  end
end
addEventHandler("onClientRender", getRootElement(), renderWorldTexts)
