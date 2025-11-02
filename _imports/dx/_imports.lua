local __ExportedFunctions = {
    -- amit meghivsz a resourceben = export neve
    dxDrawButton = "drawButton",
    isButtonHover = "isButtonHover",
    getButtonCustomData = "getButtonCustomData",

    dxDrawEdit = "drawEdit",
    isEditHover = "isEditHover",
    setEditText = "setEditText",
    getEditText = "getEditText",
    setEditFieldType = "setEditFieldType",

    dxDrawHScroll = "drawHScroll",

    dxDrawLogo = "dxDrawLogo",

    createMoveableWindow = "createMoveableWindow",

    dxDrawBorderedRectangleSVG = "dxDrawBorderedRectangleSVG",

    dxDrawScroll = "drawScroll",
    isScrollHover = "isScrollHover",
    getScrollValue = "getScrollValue",
    getScrollMin = "getScrollMin",
    getScrollMax = "getScrollMax",

    dxDrawTable = "drawTable",
    isTableHover = "isTableHover",
    getTableHoveredItem = "getTableHoveredItem",
    getTableSortedBy = "getTableSortedBy",
    setTableColumnType = "setTableColumnType",
    setTableColumnAlign = "setTableColumnAlign",
    setTableColumnWidth = "setTableColumnWidth",
    findTableElementInColumn = "findTableElementInColumn",
    reloadTableElements = "reloadTableElements",

    dxDrawVScroll = "drawVScroll",

    dxDrawWindow = "drawWindow",
    drawWindow = "drawWindow",
    dxDrawGradient = "drawGradient",
    drawGradient = "drawGradient",

    showAlert = "showAlert",
    dxShowAlert = "showAlert",
	
    checkCursor = "checkCursor",
    getCursorPos = "getCursorPos",
    isInBox = "isInBox",
    isCursorHover = "isInBox",
    tooltip = "tooltip",
    toRGBA = "toRGBA",
    stringToRGBA = "stringToRGBA",
    stringToColor = "stringToColor",
    colorDarker = "colorDarker",
    drawBorderedRectangle = "drawBorderedRectangle",
    dxDrawBorderedRectangle = "drawBorderedRectangle",
    injectTextTo = "injectTextTo",
    padnum = "padnum",
    alphanumsort = "alphanumsort",
    dxDrawRoundedRectangle = "dxDrawRoundedRectangle",
    dxDrawBorderedText = "dxDrawBorderedText",
    dxDrawBorderedTextWithAlpha = "dxDrawBorderedTextWithAlpha",
    reMap = "reMap",
    resp = "resp",
    respc = "respc",
};

local NeedInvoker = {
    ["dxDrawEdit"] = true,
    ["dxDrawHScroll"] = true,
    ["dxDrawVScroll"] = true,
    ["createMoveableWindow"] = true,
    ["dxDrawBorderedRectangleSVG"] = true,
    ["dxDrawTable"] = true,
    ["dxDrawWindow"] = true
}

for ExportFunc, LocalFunc in pairs(__ExportedFunctions) do 
    _G[ExportFunc] = function(...)
        if (NeedInvoker[ExportFunc]) then
            call(getResourceFromName("ex_dx"), "setInvoker", inspect(debug.getinfo(2)));
        end
        return call(getResourceFromName("ex_dx"), LocalFunc, ...);
    end
end 

addEventHandler("onClientResourceStart", getResourceRootElement(getResourceFromName("ex_dx")), function()
    for ExportFunc, LocalFunc in pairs(__ExportedFunctions) do 
        _G[ExportFunc] = function(...)
            if (NeedInvoker[ExportFunc]) then
                call(getResourceFromName("ex_dx"), "setInvoker", inspect(debug.getinfo(2)));
            end
            return call(getResourceFromName("ex_dx"), LocalFunc, ...);
        end
    end 
end);
