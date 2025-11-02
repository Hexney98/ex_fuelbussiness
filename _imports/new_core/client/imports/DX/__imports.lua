-- @require: Class, DX/Rectangle, DX/Fonts
local ServerRGB = exports["ex_new_core"]:GetColor("server", "rgb");

local _dxDrawText = dxDrawText
local function dxDrawText(Text, x, y, w, h, Color, FontSize, FontData, ...)
    -- if (type(FontData) == "table" and isElement(FontData.Font)) then 
    --     return _dxDrawText(Text, x, y, x + (w or 0), y + (h or 0), Color, FontSize, FontData.Font, ...);
    -- elseif (isElement(FontData)) then 
    --     return _dxDrawText(Text, x, y, x + (w or 0), y + (h or 0), Color, FontSize, FontData, ...);
    -- else 
    --     return _dxDrawText(Text, x, y, x + (w or 0), y + (h or 0), Color, FontSize, "arial", ...);
    -- end 
    
    return _dxDrawText(Text, x, y, x + (w or 0), y + (h or 0), Color, FontSize, FontData or "arial", ...);
end

local __Buttons = {};
local __ButtonTransitionIncrease = 6.5;
local __DefaultButtonStyles = {
    default = {
        BackgroundColor = { 20, 20, 20, 255 },
        BackgroundHoverColor = { ServerRGB[1], ServerRGB[2], ServerRGB[3], 255 },
        TextColor = { 255, 255, 255, 255 }, 
        TextHoverColor = { 14, 14, 14, 255 },
        Radius = 0.5, 
        UseRelativeRadius = true,
        Border = nil, 
    },
};

local __DefaultButtonSettings = {
    disabled = false,
    Style = 'default',
    Font = { "OpenSans", 11 },
    __Value = 0, 
    __LastVisible = 0,
    __LastPosition = nil, 
    __LastSize = nil,
    __Hovering = false,
    __Events = {},
};

Button = Class {
    __Constructor = function(self, ID, Settings)
        local Settings = Settings or { };

        local mergedSettings = Settings;
        for key, data in pairs(__DefaultButtonSettings) do
            if (not mergedSettings[key]) then 
                mergedSettings[key] = data;
            end 
        end

        self = table.merge(self, mergedSettings);
        self.id = ID;
        self.Style = (type(self.Style) ~= 'table')
                    and (__DefaultButtonStyles[self.Style] or __DefaultButtonStyles.default) 
                    or table.merge(self.Style, __DefaultButtonStyles.default);

        __Buttons[self.id] = self;
    end, 

    Destroy = function(self)
        __Buttons[self.id] = nil;
        self["__Deconstruct"]();
    end, 

    Render = function(self, Text, X, Y, Width, Height, TransformToText)
        local Style = self.Style;
        local r, g, b = interpolateBetween(
            Style.BackgroundColor[1], Style.BackgroundColor[2], Style.BackgroundColor[3], 
            Style.BackgroundHoverColor[1], Style.BackgroundHoverColor[2], Style.BackgroundHoverColor[3], 
            self.__Value / 100, "InQuad"
        );
        local alpha = interpolateBetween(Style.BackgroundColor[4], 0, 0, Style.BackgroundHoverColor[4], 0, 0, self.__Value / 100, "InQuad");
        local tR, tG, tB = interpolateBetween(
            Style.TextColor[1], Style.TextColor[2], Style.TextColor[3], 
            Style.TextHoverColor[1], Style.TextHoverColor[2], Style.TextHoverColor[3], 
            self.__Value / 100, "InQuad"
        );

        local tAlpha = interpolateBetween(Style.TextColor[4], 0, 0, Style.TextHoverColor[4], 0, 0, self.__Value / 100, "InQuad");
        if (Style.Radius) then 
            if (not dxDrawRoundedRectangleCore) then 
                outputDebugString("Requirezd mar a kurva \"Rectangle\" componentet is...", 1);
                return;
            end 

            dxDrawRoundedRectangleCore(
                X, Y, Width, Height, 
                tocolor(r, g, b, alpha), 
                Style.Radius, nil, nil, nil, 
                Style.UseRelativeRadius
            );
        else 
            dxDrawRectangle(
                X, Y, Width, Height, 
                tocolor(r, g, b, alpha)
            );
        end 

        local UsedFont = "arial";
        if (isElement(self.Font)) then
            UsedFont = self.Font;
        elseif (type(self.Font) == "table") then
            UsedFont = getFont(unpack(self.Font));
        end 

        dxDrawText(
            Text, 
            X, Y, Width, Height, 
            tocolor(tR, tG, tB, tAlpha), 
            1, UsedFont, 
            'center', 'center'
        );

        self.__LastPosition = Vector2(X, Y);
        self.__LastSize = Vector2(Width, Height);

        local insideArea = isCursorInArea(self.__LastPosition, self.__LastSize);
        if (insideArea and self.__Value < 100) then 
            self.__Value = (self.__Value + __ButtonTransitionIncrease > 100) and 100 or (self.__Value + __ButtonTransitionIncrease);
        elseif (not insideArea and self.__Value > 0) then 
            self.__Value = (self.__Value - __ButtonTransitionIncrease < 0) and 0 or (self.__Value - __ButtonTransitionIncrease);
        end 

        if (self.__Hovering ~= insideArea) then 
            self.__EmitEvent('Hover', insideArea);
            self.__Hovering = insideArea;
        end 

        self.__LastVisible = getTickCount();
    end, 

    On = function(self, EventName, Handler)
        if (not self.__Events[EventName]) then 
            self.__Events[EventName] = {};
        end 

        table.insert(self.__Events[EventName], Handler);
    end, 

    __EmitEvent = function(self, EventName, ...)
        if (EventName and self.__Events[EventName]) then
            for _, Handler in ipairs(self.__Events[EventName]) do 
                Handler(self, ...);
            end 
        end 
    end, 
}

addEventHandler('onClientClick', root, function(button, state)
    if (isCursorShowing()) then 
        local tick = getTickCount();
        for id, v in pairs(__Buttons) do 
            if (
                isCursorInArea(v.__LastPosition, v.__LastSize) and 
                v.__LastVisible and 
                v.__LastVisible + 500 > tick and 
                v.__Events.Submit
            ) then 
                for _, Handler in ipairs(v.__Events.Submit) do 
                    Handler(v, button, state);
                end 
            end 
        end 
    end 
end);

__Editboxes = {};
__EditboxOrder = {};
__SelectedEditbox = nil; 
__visibilityDiff = 200; -- ms
__SubstrFromLength = 128;

local __DefaultEditboxStyles = {
    Default = {
        Background = tocolor(20, 20, 20),
        Background_active = nil, 
        Padding = 16,
        Align = 'left',
        Radius = 1, 
        UseRelativeRadius = true, 
        Border = 0.035, 
        BorderColor = tocolor(26, 26, 26),
        BorderColor_active = tocolor(unpack(exports["ex_new_core"]:GetColor("server", "rgb"))),
    },
    Transparent = {
        Background = tocolor(0, 0, 0, 0),
        Padding = 5,
        Radius = 1, 
        UseRelativeRadius = true, 
        Border = 0.035, 
        BorderColor = tocolor(0, 0, 0, 0),
    },
};

local __DefaultEditboxSettings = {
    Masked = false,
    Disabled = false,
    Value = '',
    Style = 'Default',
    Font = { "Roboto", 10 },

    NumbersAllowed = true, 
    SpecialsAllowed = false,
    MaxLength = 512,
    
    __Position = nil, 
    __Size = nil, 
    __LastVisible = 0,
    __Events = {},
};

local __RetardedUTF8Chars = {
    ['ö'] = true, ['Ö'] = true,
    ['ű'] = true, ['Ű'] = true,
    ['ü'] = true, ['Ü'] = true,
    ['ó'] = true, ['Ó'] = true,
    ['ő'] = true, ['Ő'] = true,
    ['ú'] = true, ['Ú'] = true,
    ['é'] = true, ['É'] = true,
    ['á'] = true, ['Á'] = true,
    ['í'] = true, ['Í'] = true,
};

local __IncludedCharacters = {
    ['ö'] = true, ['Ö'] = true,
    ['ű'] = true, ['Ű'] = true,
    ['ü'] = true, ['Ü'] = true,
    ['ó'] = true, ['Ó'] = true,
    ['ő'] = true, ['Ő'] = true,
    ['ú'] = true, ['Ú'] = true,
    ['é'] = true, ['É'] = true,
    ['á'] = true, ['Á'] = true,
    ['í'] = true, ['Í'] = true,

    ['!'] = true,
    ['@'] = true,
    ['#'] = true,
    ['$'] = true,
    ['%'] = true,
    ['^'] = true,
    ['&'] = true,
    ['*'] = true,
    ['('] = true,
    [')'] = true,
    ['-'] = true,
    ['_'] = true,
    ['='] = true,
    ['+'] = true,
    [','] = true,
    ['.'] = true,
    ['/'] = true,
    ['?'] = true,
    [':'] = true,
    ["'"] = true, 
    ['"'] = true, 
    ["["] = true, 
    ["]"] = true, 
    ["{"] = true, 
    ["}"] = true, 

    [' '] = true,
};

Editbox = Class {
    __Constructor = function(self, ID, Settings)
        local Settings = Settings or { };

        local MergedSettings = table.merge(Settings, __DefaultEditboxSettings);

        self = table.merge(self, MergedSettings);
        self.ID = ID;
        self.Style = (type(self.Style) ~= 'table')
                    and (__DefaultEditboxStyles[self.Style] or __DefaultEditboxStyles.Default) 
                    or table.merge(self.Style, __DefaultEditboxStyles.Default);

        __Editboxes[self.ID] = self;
    end, 

    Destroy = function(self)
        if (
            __SelectedEditbox and
            __SelectedEditbox == self.ID
        ) then 
            __SelectedEditbox = nil;
            guiSetInputMode("allow_binds");
        end 

        if (__Editboxes[self.ID]) then
            __Editboxes[self.ID] = nil;
        end 

        for i, v in ipairs(__EditboxOrder) do 
            if (v == self.ID) then 
                table.remove(__EditboxOrder, i);
            end 
        end 

        self["__Deconstruct"]();
    end, 

    GetValue = function(self)
        return self.Value;
    end,
    Render = function(self, X, Y, Width, Height)
        local Style = self.Style;
        
        local Padding = Style.Padding;

        local UsedFont = isElement(self.Font) and self.Font or getFont(unpack(self.Font));

        if (Style.Radius ~= nil and not Style.noRenderBorder) then 
            if (not dxDrawRoundedRectangleCore) then 
                outputDebugString("Requirezd mar a kurva \"Rectangle\" componentet is...", 1);
                return;
            end 

            dxDrawRoundedRectangleCore(
                X, Y, Width, Height, 
                Style.Background, Style.Radius, 
                nil, nil, nil, Style.UseRelativeRadius
            );

            if (Style.Border ~= nil) then 
                Padding = Padding + Style.Border * 80;

                local Color = (
                    __SelectedEditbox and 
                    __SelectedEditbox == self.ID and 
                    Style.BorderColor_active ~= nil
                ) and Style.BorderColor_active or Style.BorderColor;

                dxDrawRoundedRectangleCore(
                    X, Y, Width, Height, 
                    Color, Style.Radius,  
                    false, Style.Border, 
                    nil, Style.UseRelativeRadius
                );
            end 
        else
            if (not Style.noRenderBorder) then
                dxDrawRectangle(X, Y, Width, Height, Style.Background);
            end 
        end 

        local Text = utf8.sub(self.Value, 1, self.MaxLength);
        local IsPlaceholder = false;

        if (
            Text == '' and
            (
                not __SelectedEditbox or 
                __SelectedEditbox ~= self.ID
            )
        ) then 
            Text = self.Placeholder or '';
            IsPlaceholder = true;
        else 
            if (self.Masked) then 
                Text = string.rep("*", string.len(self.Value));
            end 
            
            local TextSuffix = (
                __SelectedEditbox and 
                __SelectedEditbox == self.ID and
                getTickCount() % 1000 <= 500
            ) and "|" or " ";
            Text = Text .. TextSuffix;
        end 

        local TextWidth = dxGetTextWidth(Text, 1, UsedFont);
        local TextLength = string.len(Text);

        if (not Style.wordBreak) then
            Text = (TextLength > __SubstrFromLength)
                        and string.sub(Text, TextLength - __SubstrFromLength, TextLength)
                        or Text;
        end

        -- dxDrawText(#Text, X, Y - 30)

        local align = Style.Align;
        if (not Style.wordBreak) then 
            align = (TextWidth >= (Width - Padding * 2)) and 'right' or Style.Align;
        end

        local heightPadding = Style.heightPadding or 0;
        if (not Style.noUI) then
            _dxDrawText(
                Text, 
                X + Padding / 2, Y + heightPadding, 
                X + Padding / 2 + (Width - Padding), Y + Height + heightPadding, 
                tocolor(255, 255, 255, IsPlaceholder and 150 or 200),
                1, UsedFont, 
                align, Style.alignCucc and Style.alignCucc or 'center', 
                not Style.wordBreak, Style.wordBreak 
            );
        end

        self.__LastVisible = getTickCount();
        self.__Position = Vector2(X, Y);
        self.__Size = Vector2(Width, Height);
    end, 

    On = function(self, EventName, Handler)
        if (not EventName or not Handler) then 
            return false;
        end 

        if (not self.__Events[EventName]) then 
            self.__Events[EventName] = {};
        end 

        table.insert(self.__Events[EventName], Handler);
    end, 

    __EmitEvent = function(self, EventName, ...)
        if (not EventName or not self.__Events[EventName]) then 
            return false;
        end 

        for _, Handler in ipairs(self.__Events[EventName]) do 
            Handler(self, ...);
        end 
    end, 
}

-- addEventHandler('onClientClick', root, function(button, state)
--     if (not isCursorShowing() or button ~= 'left' or state ~= 'down') then return; end
--     local tick = getTickCount();
--     for id, v in pairs(__Editboxes) do 
--         if (
--             v.__LastVisible and 
--             (v.__LastVisible + __visibilityDiff) > tick and 
--             (v.__Position ~= nil and v.__Size ~= nil) and 
--             isCursorInArea(v.__Position, v.__Size) and 
--             (guiGetInputMode() or 'allow_binds') == 'allow_binds'
--         ) then
--             __SelectedEditbox = id;
--             guiSetInputMode("no_binds");
--             v.__EmitEvent('focus');
--             return;
--         end 
--     end 
--     guiSetInputMode("allow_binds");
--     __SelectedEditbox = nil;
-- end);

addEventHandler('onClientKey', root, function(Key, IsPress)
    if (IsPress and __SelectedEditbox) then 
        if (Key == 'backspace') then 
            if (not __Editboxes[__SelectedEditbox]) then 
                __SelectedEditbox = nil;
                return;
            end 
            
            local box = __Editboxes[__SelectedEditbox];
            if (box.Disabled) then 
                return;
            end 
            
            if (isTimer(box.backpaceTimer)) then 
                return;
            end 

			box.Value = utf8.sub(box.Value, 1, -2);
            box.__EmitEvent('OnChange', box.Value);

            -- Kicsi callbackhell, hogy a szerverhez melto legyen!
            setTimer(function()
                if (getKeyState('backspace') and not isTimer(box.backpaceTimer)) then 
                    box.backpaceTimer = setTimer(function()
                        if (
                            getKeyState('backspace') and 
                            box and 
                            isTimer(box.backpaceTimer) and 
                            box.Value ~= '' and 
                            not box.Disabled
                        ) then 
                            box.Value = utf8.sub(box.Value, 1, -2);
                            box.__EmitEvent('OnChange');
                        else 
                            killTimer(box.backpaceTimer);
                        end 
                    end, 30, 0);
                end 
            end, 500, 1);
        elseif (Key == 'tab') then 
            local index = table.findIndex(__EditboxOrder, function(x) return (__SelectedEditbox == x); end);
            if (not index) then 
                return;
            end 

            local nextIndex = ((index + 1) > #__EditboxOrder) and 1 or index + 1;
            local nextEditbox = table.find_Keytbl(__Editboxes, function(x) return (x.ID == __EditboxOrder[nextIndex]); end);

            if (nextEditbox) then 
                __SelectedEditbox = nextEditbox.ID;
                nextEditbox.__EmitEvent('Focus');

                if (nextEditbox.onChange) then
                    nextEditbox.onChange("open");
                end
            end 
        elseif (Key:find("enter")) then 
            if (not __Editboxes[__SelectedEditbox]) then 
                __SelectedEditbox = nil;
                return;
            end 
            
            local Input = __Editboxes[__SelectedEditbox];
            if (Input.Disabled) then 
                return;
            end 

            if (isTimer(Input.backpaceTimer)) then 
                return;
            end 

            if (Input.disableEnter) then return end

            Input.__EmitEvent("Submit", Input.Value);
            Input.Value = "";
        end 
    end 
end)

addEventHandler('onClientCharacter', root, function(character)
    if (
        not __SelectedEditbox or 
        not isCursorShowing() or 
        isMTAWindowActive() or
        isConsoleActive()
    ) then 
        return; 
    end 
    
    if (not __Editboxes[__SelectedEditbox]) then
        __SelectedEditbox = nil;
    end
    
    local box = __Editboxes[__SelectedEditbox];
    
    if (
        box.Disabled or 
        (not box.NumbersAllowed and tonumber(character)) or 
        #box.Value >= box.MaxLength
    ) then 
        return;
    end 
    
    -- aaaaaa miez
    local byte = string.byte(character);
    if (
        not box.SpecialsAllowed and 
        (
            not (
                (byte >= 65 and byte <= 90) or 
                (byte >= 97 and byte <= 122) or 
                (byte >= 48 and byte <= 57)
            ) and not __IncludedCharacters[character]
        )
    ) then 
        return;
    end 
    
    if (isTimer(box.backpaceTimer)) then 
        return;
    end 

	box.Value = box.Value .. character;
    box.__EmitEvent('OnChange', box.Value);
end);

addEventHandler('onClientPaste', root, function(Text)
    if (
        not __SelectedEditbox or 
        not __Editboxes[__SelectedEditbox]
    ) then 
        return;
    end
        
    local Editbox = __Editboxes[__SelectedEditbox];
    if (__SelectedEditbox and __Editboxes[__SelectedEditbox]) then 
        Text = utf8.gsub(Text, ".", function(Letter)
            local byte = string.byte(Letter);
            if (
                not Editbox.NumbersAllowed and 
                tonumber(character)
            ) then 
                return "";
            end 

            local byte = string.byte(Letter);
            if (
                not Editbox.SpecialsAllowed and 
                (
                    not (
                        (byte >= 65 and byte <= 90) or 
                        (byte >= 97 and byte <= 122) or 
                        (byte >= 48 and byte <= 57)
                    ) and not __IncludedCharacters[Letter]
                )
            ) then 
                return "";
            end 

            return Letter;
        end);

        local NewText = utf8.sub(Editbox.Value .. utf8.gsub(Text, "\n", " "), 1, Editbox.MaxLength);
		Editbox.Value = NewText;
        Editbox.__EmitEvent('OnChange', Editbox.Value, NewText);
    end 
end);

local __FontCleanupState = false;
local __FontCleanupAfter = 30000;
local __FontPool = {};
function GetFont(Name, Size, IsBold, Quality)
    local FontKey = Name .. ";" .. Size .. ";" .. tostring(IsBold) .. ";" .. tostring(Quality);
    local Size = Size or 12;

    Size = math.floor(Size * GetResp(Size));

    if (__FontPool[FontKey]) then 
        if (not isElement(__FontPool[FontKey].Font)) then 
            return "arial";
        end 

        __FontPool[FontKey].AtTick = getTickCount();
        return __FontPool[FontKey].Font;
    end 

    local Font = exports["ex_new_core"]:RequireFont(Name, Size, IsBold, Quality);
    if (not isElement(Font)) then return "arial"; end 

    __FontPool[FontKey] = {
        Font = Font, 
        AtTick = getTickCount(), 
    };

    return Font;
end 

function SetFontsCleanupState(NewState)
    __FontCleanupState = type(NewState) == "boolean" and NewState == true;
end 

local __IconPool = {};
function GetIcon(IconName)
    assert(type(IconName) == "string", "GetIcon got an invalid IconName at argument #1!");

    if (__IconPool[IconName]) then
        return __IconPool[IconName];
    end 

    local Icon = exports["ex_new_core"]:GetIcon(IconName);
    if (not Icon) then 
        return "";
    end 

    __IconPool[IconName] = Icon;
    return Icon;
end 

setTimer(function()
    if (not __FontCleanupState) then 
        return;
    end 

    local Tick = getTickCount();
    for Key, Font in pairs(__FontPool) do 
        if (Font.AtTick + __FontCleanupAfter < Tick) then 
            exports["ex_new_core"]:OnFontCleanedInResource(Key);
            __FontPool[Key] = nil;
        end 
    end 
end, 1, 2000);

__Lists = {};

local ServerRGB = exports["ex_new_core"]:GetColor("server", "rgb");

local __DefaultListStyles = {
    default = {
        Background = tocolor(20, 20, 20),
        Align = 'left',
        Font = GetFont("roboto", 9),
        Radius = nil, 
        UseRelativeRadius = false, 

        Padding = 4, 
        MarginBottom = 4, 

        ItemHeight = 24, 
        ItemColor = { 34, 34, 34 }, 
        ItemColorSelected = ServerRGB
    },
};

local __DefaultListSettings = {
    __Events = {}, 

    Top = 0, 
    Selected = {}, -- number[]
    MultiSelection = false,
    Items = {}, 
    EmptyText = "Ez a lista üres", 
};

List = Class {
    __Constructor = function(self, ID, Settings)
        local Settings = Settings or { };

        local MergedSettings = table.merge(Settings, __DefaultListSettings);

        self = table.merge(self, MergedSettings);
        self.id = ID;
        self.Style = (type(self.style) ~= 'table')
                    and (__DefaultListStyles[self.style] or __DefaultListStyles.default) 
                    or table.merge(self.style, __DefaultListStyles.default);

        self.Scrollbar = Scrollbar("List.Scrollbar." .. ID, { __ChangeByScroll = 12 });

        __Lists[self.id] = self;
    end, 

    Render = function(self, X, Y, Width, Height)
        local Style = self.Style;

        self.Top = self.Scrollbar.__Index;

        if (Style.Radius ~= nil) then 
            if (not dxDrawRoundedRectangleCore) then 
                outputDebugString("Requirezd mar a kurva \"Rectangle\" componentet is...", 1);
                return;
            end 

            dxDrawRoundedRectangleCore(
                X, Y, Width, Height, 
                Style.Background, Style.Radius, 
                nil, nil, nil, Style.UseRelativeRadius
            );
        else 
            dxDrawRectangle(X, Y, Width, Height, Style.Background);
        end 

        if (#self.Items > 0) then 
            local TotalHeightOfList = (#self.Items * (Style.ItemHeight + Style.MarginBottom)) + Style.Padding * 2;
            local IsScrollbarVisible = Height < TotalHeightOfList;
            local ListWidth = Width - Style.Padding * 2 - (IsScrollbarVisible and 8 or 0); -- -10 mert a scrollbar
    
            local ContainerTop = Y + Style.Padding;
            local ContainerBottom = Y + Height - Style.Padding;
    
            local ItemY = Y + Style.Padding - self.Top; -- Y, a kovetkezo item teteje
            for Index = 1, #self.Items do 
                if (
                    ItemY <= ContainerBottom and 
                    ItemY + Style.ItemHeight >= ContainerTop
                ) then -- Ha viewportba van 
                    local TextAlpha = 255;
                    local BoxY = ItemY;
                    local BoxHeight = Style.ItemHeight;
                    if (ItemY < ContainerTop) then -- Ha a tetejebol kilog egy resze
                        BoxHeight = BoxHeight - (ContainerTop - ItemY);
                        BoxY = ItemY + (Style.ItemHeight - BoxHeight);
                        TextAlpha = (BoxHeight / Style.ItemHeight) * 255;
                    elseif (ItemY + Style.ItemHeight > ContainerBottom) then 
                        BoxHeight = ContainerBottom - ItemY;
                        TextAlpha = (BoxHeight / Style.ItemHeight) * 255;
                    end 
    
                    local Color = (self.Selected and self.Selected[Index]) and Style.ItemColorSelected or Style.ItemColor;
    
                    dxDrawRectangle(
                        X + Style.Padding, BoxY, 
                        ListWidth, BoxHeight, 
                        tocolor(Color[1], Color[2], Color[3], TextAlpha)
                    );
    
                    dxDrawText(
                        self.Items[Index], 
                        X + Style.Padding, BoxY, ListWidth, BoxHeight, 
                        tocolor(255, 255, 255, TextAlpha), 
                        1, "arial", "center", "center"
                    );
                end 
    
                ItemY = ItemY + Style.ItemHeight + Style.MarginBottom;
            end 
    
            self.Scrollbar.Render(
                X + Width - 10, Y + 5, 8, Height - 10, 
                Height, TotalHeightOfList
            );
        else 
            dxDrawText(self.EmptyText, X, Y, Width, Height, tocolor(255, 255, 255, 180), 1, Style.Font, "center", "center");
        end 

        self.__LastVisible = getTickCount();
        self.__LastPosition = { X, Y };
        self.__LastSize = { Width, Height };
    end,

    AddItem = function(self, Text, Index)
        local Index = type(Index) and Index or (#self.Items + 1);
        table.insert(self.Items, Index, tostring(Text));
    end, 

    RemoveItem = function(self, Index)
        assert(type(Index) == "number", "RemoveItem at arg #1 expected number, got '" .. type(Index) .. "'");
        table.remove(self.Items, Index);
    end, 

    GetSelected = function(self)
        if (self.MultiSelection) then 
            local Selected = {};

            for Index, _ in pairs(self.Selected) do 
                Selected[Index] = self.Items[Index];
            end 

            return Selected;
        else 
            for Index, _ in pairs(self.Selected) do 
                return Index, self.Items[Index];
            end 
        end  
    end, 

    SetSelected = function(self, Index)
        assert(type(Index) == "number", "SetSelected expected number @ arg 1, got '" .. type(Index) .. "'");

        if (not self.Items[Index]) then return false; end
        
        self.Selected[Index] = true;
        return true;
    end, 

    GetItems = function(self) return self.Items; end, 

    On = function(self, EventName, Handler)
        if (not EventName or not Handler) then 
            return false;
        end 

        if (not self.__Events[EventName]) then 
            self.__Events[EventName] = {};
        end 

        table.insert(self.__Events[EventName], Handler);
    end, 

    __EmitEvent = function(self, EventName, ...)
        if (not EventName or not self.__Events[EventName]) then 
            return false;
        end 

        for _, Handler in ipairs(self.__Events[EventName]) do 
            Handler(self, ...);
        end 
    end, 
}

addEventHandler("onClientClick", root, function(Button, State)
    if (Button ~= "left" or State ~= "down") then return; end 
    
    for _, List in pairs(__Lists) do 
        local X, Y = unpack(List.__LastPosition);
        local Width, Height = unpack(List.__LastSize);

        local Style = List.Style;
        local TotalHeightOfList = #List.Items * Style.ItemHeight;
        local ContainerTop = Y + Style.Padding;
        local ContainerBottom = Y + Height - Style.Padding * 2;
        local ListWidth = Width - Style.Padding * 2 - 10;

        if (isCursorInArea(X, Y, ListWidth, Height)) then 
            local NewSelected = List.Selected;
            if (not getKeyState("lshift") or not List.MultiSelection) then 
                NewSelected = {};
            end 

            local CursorX, CursorY = getCursorPosition(true);

            local ItemY = Y + Style.Padding - List.Top; 
            for Index = 1, #List.Items do 
                if (
                    ItemY <= Y + Height - Style.Padding * 2 and 
                    ItemY + Style.ItemHeight >= ContainerTop
                ) then 
                    local BoxY = ItemY;
                    local BoxHeight = Style.ItemHeight;
                    if (ItemY < ContainerTop) then 
                        BoxHeight = BoxHeight - (ContainerTop - ItemY);
                        BoxY = ItemY + (Style.ItemHeight - BoxHeight);
                    elseif (ItemY + Style.ItemHeight > ContainerBottom) then 
                        BoxHeight = ContainerBottom - ItemY;
                    end 

                    if (isCursorInArea(X + Style.Padding, BoxY, ListWidth, BoxHeight)) then 
                        NewSelected[Index] = (not List.Selected[Index]) and true or nil;
                        List.__EmitEvent("Select", Index, NewSelected[Index] ~= nil);
                    end 
                end 

                ItemY = ItemY + Style.ItemHeight + Style.MarginBottom;
            end 

            List.Selected = NewSelected;
        end 
    end 
end);

local __ProgressBars = {};

local __ProgressBarStyles = {
    default = {
        progressColor = tocolor(255, 50, 50, 150),
        bgColor = tocolor(0, 0, 0, 150),
        thickness = 0.06, 
        radius = 0.45,
        aliasing = 0.02, 
    },
};

local __DefaultProgressBarSettings = {
    value = 0, 
    min_value = 0, 
    max_value = 100, 

    __transition_interval = 2000,
    __previous_value = 0, 
    __previous_value_change = getTickCount(),

    style = 'default',
    type = "rounded",
};

-- Kitepve DGS-bol mert nem ertek shaderekhez es nem is akarokxd
local shaders_raw = {
    rounded = [[
        #define PI2 6.283185307179586476925286766559
        float borderSoft = 0.02;
        float radius = 0.2;
        float thickness = 0.02;
        float2 progress = float2(0,0.1);
        float4 indicatorColor = float4(1, 1, 1, 1);
        float4 backgroundColor = float4(0.5, 0.5, 0.5, 0.5);
        float4 blend(float4 c1, float4 c2){
            float alp = c1.a+c2.a-c1.a*c2.a;
            float3 color = (c1.rgb*c1.a*(1.0-c2.a)+c2.rgb*c2.a)/alp;
            return float4(color,alp);
        }
        float4 myShader(float2 tex:TEXCOORD0,float4 color:COLOR0):COLOR0{
            float2 dxy = float2(length(ddx(tex)),length(ddy(tex)));
            float nBS = borderSoft*sqrt(dxy.x*dxy.y)*100;
            float4 bgColor = backgroundColor;
            float4 inColor = 0;
            float2 texFixed = tex-0.5;
            float delta = clamp(1-(abs(length(texFixed)-radius)-thickness+nBS)/nBS,0,1);
            bgColor.a *= delta;
            float2 progFixed = progress * PI2;
            float angle = atan2(tex.y-0.5,0.5-tex.x)+0.5*PI2;
            bool tmp1 = angle>progFixed.x;
            bool tmp2 = angle<progFixed.y;
            float dis_ = distance(float2(cos(progFixed.x),-sin(progFixed.x))*radius,texFixed);
            float4 Color1,Color2;
            if(dis_<=thickness){
                float tmpDelta = clamp(1-(dis_-thickness+nBS)/nBS,0,1);
                Color1 = indicatorColor;
                inColor = indicatorColor;
                Color1.a *= tmpDelta;
            }
            dis_ = distance(float2(cos(progFixed.y),-sin(progFixed.y))*radius,texFixed);
            if(dis_<=thickness){
                float tmpDelta = clamp(1-(dis_-thickness+nBS)/nBS,0,1);
                Color2 = indicatorColor;
                inColor = indicatorColor;
                Color2.a *= tmpDelta;
            }
            inColor.a = max(Color1.a,Color2.a);
            if(progress.x>=progress.y){
                if(tmp1+tmp2){
                    inColor = indicatorColor;
                    inColor.a *= delta;
                }
            }else{
                if(tmp1*tmp2){
                    inColor = indicatorColor;
                    inColor.a *= delta;
                }
            }
            return blend(bgColor,inColor);
        }
        technique DrawCircle{
            pass P0	{
                PixelShader = compile ps_2_a myShader();
            }
        }
    ]], 
};

function Progressbar(id, settings)
    local settings = (settings or {});
    local self = table.merge(settings, __DefaultProgressBarSettings);

    self.id = id;
    self.style = (type(self.style) ~= 'table')
                        and (__ProgressBarStyles[self.style] or __ProgressBarStyles.default) 
                        or table.merge(self.style, __ProgressBarStyles.default);

    self.__updateShader = function()
        if (shaders_raw[self.type]) then 
            if (not self.__shader) then 
                self.__shader = {};
                self.__shader.progress = dxCreateShader(shaders_raw[self.type]);
            end 

            -- Progress
            local progress = clamp(rangePercentage(self.min_value, self.max_value, (self.__last_shown_value or 0)) / 100, 0.0, 1.0);

            dxSetShaderValue(self.__shader.progress, "progress", 0, progress);
            dxSetShaderValue(self.__shader.progress, "indicatorColor", fromcolor(self.style.progressColor, true, true));
            dxSetShaderValue(self.__shader.progress, "backgroundColor", fromcolor(self.style.bgColor, true, true));
            dxSetShaderValue(self.__shader.progress, "thickness", self.style.thickness);
            dxSetShaderValue(self.__shader.progress, "radius", self.style.radius);
            dxSetShaderValue(self.__shader.progress, "antiAliased", self.style.aliasing);
        end 
    end 

    self.__renderers = {};

    self.__renderers['rounded'] = function(x, y, width, height, rotation)
        local rotation = (rotation or 0);

        dxDrawImage(x, y, width, height, self.__shader.progress, rotation);
    end

    self.render = function(...)
        if (self.type and self.__renderers[self.type]) then 
            self.__last_shown_value = interpolateBetween(
                self.__previous_value, 0, 0, 
                self.value, 0, 0, 
                (getTickCount() - self.__previous_value_change) / self.__transition_interval, 
                "InOutQuad"
            );

            if (self.__last_shown_value ~= self.value) then 
                self.__updateShader();
            end 

            self.__renderers[self.type](...);
        end 
    end

    self.setValue = function(val)
        self.__previous_value = self.value;
        self.value = val;
        self.__previous_value_change = getTickCount();
    end

    self.Destroy = function()

    end

    self.__updateShader();

    __ProgressBars[id] = self;
    return self;
end 

function clamp(num, min, max)
    if (num < min) then return min; end 
    if (num > max) then return max; end 
    
    return num;
end 

function rangePercentage(min, max, value)
    return ((value - min) * 100) / (max - min);
end 

function fromcolor(int,useMath,relative)
	local a,r,g,b
	if useMath then
		b = int%256
		local int = (int-b)/256
		g = int%256
		local int = (int-g)/256
		r = int%256
		local int = (int-r)/256
		a = int%256
	else
		a,r,g,b = getColorFromString(format("#%.8x",int))
	end
	if relative then
		a,r,g,b = a/255,r/255,g/255,b/255
	end
	return r,g,b,a
end

function __RequestRoundRectangleShader(withoutFilled)
    local woF = not withoutFilled and ""
    return ([[
        texture sourceTexture;
        float4 color = float4(1,1,1,1);
        bool textureLoad = false;
        bool textureRotated = false;
        float4 isRelative = 1;
        float4 radius = 0.2;
        float borderSoft = 0.01;
        bool colorOverwritten = true;
        ]] .. (woF or [[
        float2 borderThickness = float2(0.2,0.2);
        float radiusMultipler = 0.95;
        ]]) .. [[
        SamplerState tSampler{
            Texture = sourceTexture;
            MinFilter = Linear;
            MagFilter = Linear;
            MipFilter = Linear;
        };
        float4 rndRect(float2 tex: TEXCOORD0, float4 _color : COLOR0):COLOR0{
            float4 result = textureLoad?tex2D(tSampler,textureRotated?tex.yx:tex)*color:color;
            float alp = 1;
            float2 tex_bk = tex;
            float2 dx = ddx(tex);
            float2 dy = ddy(tex);
            float2 dd = float2(length(float2(dx.x,dy.x)),length(float2(dx.y,dy.y)));
            float a = dd.x/dd.y;
            float2 center = 0.5*float2(1/(a<=1?a:1),a<=1?1:a);
            float4 nRadius;
            float aA = borderSoft*100;
            if(a<=1){
                tex.x /= a;
                aA *= dd.y;
                nRadius = float4(isRelative.x==1?radius.x/2:radius.x*dd.y,isRelative.y==1?radius.y/2:radius.y*dd.y,isRelative.z==1?radius.z/2:radius.z*dd.y,isRelative.w==1?radius.w/2:radius.w*dd.y);
            }else{
                tex.y *= a;
                aA *= dd.x;
                nRadius = float4(isRelative.x==1?radius.x/2:radius.x*dd.x,isRelative.y==1?radius.y/2:radius.y*dd.x,isRelative.z==1?radius.z/2:radius.z*dd.x,isRelative.w==1?radius.w/2:radius.w*dd.x);
            }
            float2 fixedPos = tex-center;
            float2 corner[] = {center-nRadius.x,center-nRadius.y,center-nRadius.z,center-nRadius.w};
            //LTCorner
            if(-fixedPos.x >= corner[0].x && -fixedPos.y >= corner[0].y){
                float dis = distance(-fixedPos,corner[0]);
                alp = 1-(dis-nRadius.x+aA)/aA;
            }
            //RTCorner
            if(fixedPos.x >= corner[1].x && -fixedPos.y >= corner[1].y){
                float dis = distance(float2(fixedPos.x,-fixedPos.y),corner[1]);
                alp = 1-(dis-nRadius.y+aA)/aA;
            }
            //RBCorner
            if(fixedPos.x >= corner[2].x && fixedPos.y >= corner[2].y){
                float dis = distance(float2(fixedPos.x,fixedPos.y),corner[2]);
                alp = 1-(dis-nRadius.z+aA)/aA;
            }
            //LBCorner
            if(-fixedPos.x >= corner[3].x && fixedPos.y >= corner[3].y){
                float dis = distance(float2(-fixedPos.x,fixedPos.y),corner[3]);
                alp = 1-(dis-nRadius.w+aA)/aA;
            }
            if (fixedPos.y <= 0 && -fixedPos.x <= corner[0].x && fixedPos.x <= corner[1].x && (nRadius[0] || nRadius[1])){
                alp = (fixedPos.y+center.y)/aA;
            }else if (fixedPos.y >= 0 && -fixedPos.x <= corner[3].x && fixedPos.x <= corner[2].x && (nRadius[2] || nRadius[3])){
                alp = (-fixedPos.y+center.y)/aA;
            }else if (fixedPos.x <= 0 && -fixedPos.y <= corner[0].y && fixedPos.y <= corner[3].y && (nRadius[0] || nRadius[3])){
                alp = (fixedPos.x+center.x)/aA;
            }else if (fixedPos.x >= 0 && -fixedPos.y <= corner[1].y && fixedPos.y <= corner[2].y && (nRadius[1] || nRadius[2])){
                alp = (-fixedPos.x+center.x)/aA;
            }
            alp = clamp(alp,0,1);
            ]] .. (woF or [[
            float2 newborderThickness = borderThickness*dd*100;
            tex_bk = tex_bk+tex_bk*newborderThickness;
            dx = ddx(tex_bk);
            dy = ddy(tex_bk);
            dd = float2(length(float2(dx.x,dy.x)),length(float2(dx.y,dy.y)));
            a = dd.x/dd.y;
            center = 0.5*float2(1/(a<=1?a:1),a<=1?1:a);
            aA = borderSoft*100;
            if(a<=1){
                tex_bk.x /= a;
                aA *= dd.y;
                nRadius = float4(isRelative.x==1?radius.x/2:radius.x*dd.y,isRelative.y==1?radius.y/2:radius.y*dd.y,isRelative.z==1?radius.z/2:radius.z*dd.y,isRelative.w==1?radius.w/2:radius.w*dd.y);
            }
            else{
                tex_bk.y *= a;
                aA *= dd.x;
                nRadius = float4(isRelative.x==1?radius.x/2:radius.x*dd.x,isRelative.y==1?radius.y/2:radius.y*dd.x,isRelative.z==1?radius.z/2:radius.z*dd.x,isRelative.w==1?radius.w/2:radius.w*dd.x);
            }
            fixedPos = (tex_bk-center*(newborderThickness+1));
            float4 nRadiusHalf = nRadius*radiusMultipler;
            corner[0] = center-nRadiusHalf.x;
            corner[1] = center-nRadiusHalf.y;
            corner[2] = center-nRadiusHalf.z;
            corner[3] = center-nRadiusHalf.w;
            //LTCorner
            float nAlp = 0;
            if(-fixedPos.x >= corner[0].x && -fixedPos.y >= corner[0].y){
                float dis = distance(-fixedPos,corner[0]);
                nAlp = (dis-nRadiusHalf.x+aA)/aA;
            }
            //RTCorner
            if(fixedPos.x >= corner[1].x && -fixedPos.y >= corner[1].y){
                float dis = distance(float2(fixedPos.x,-fixedPos.y),corner[1]);
                nAlp = (dis-nRadiusHalf.y+aA)/aA;
            }
            //RBCorner
            if(fixedPos.x >= corner[2].x && fixedPos.y >= corner[2].y){
                float dis = distance(float2(fixedPos.x,fixedPos.y),corner[2]);
                nAlp = (dis-nRadiusHalf.z+aA)/aA;
            }
            //LBCorner
            if(-fixedPos.x >= corner[3].x && fixedPos.y >= corner[3].y){
                float dis = distance(float2(-fixedPos.x,fixedPos.y),corner[3]);
                nAlp = (dis-nRadiusHalf.w+aA)/aA;
            }
            if (fixedPos.y <= 0 && -fixedPos.x <= corner[0].x && fixedPos.x <= corner[1].x && (nRadiusHalf[0] || nRadiusHalf[1])){
                nAlp = 1-(fixedPos.y+center.y)/aA;
            }else if (fixedPos.y >= 0 && -fixedPos.x <= corner[3].x && fixedPos.x <= corner[2].x && (nRadiusHalf[2] || nRadiusHalf[3])){
                nAlp = 1-(-fixedPos.y+center.y)/aA;
            }else if (fixedPos.x <= 0 && -fixedPos.y <= corner[0].y && fixedPos.y <= corner[3].y && (nRadiusHalf[0] || nRadiusHalf[3])){
                nAlp = 1-(fixedPos.x+center.x)/aA;
            }else if (fixedPos.x >= 0 && -fixedPos.y <= corner[1].y && fixedPos.y <= corner[2].y && (nRadiusHalf[1] || nRadiusHalf[2])){
                nAlp = 1-(-fixedPos.x+center.x)/aA;
            }
            alp *= clamp(nAlp,0,1);
            ]]) .. [[
            result.rgb = colorOverwritten?result.rgb:_color.rgb;
            result.a *= _color.a*alp;
            return result;
        }
        technique rndRectTech{
            pass P0{
                PixelShader = compile ps_2_a rndRect();
            }
        }
    ]])
end

local __RectangleCache = {};
local __TruncateRectanglesInterval = 100;

function dxDrawRoundedRectangle(x, y, width, height, color, radius, fill, borderThickness, isPostGUI, useRelativeRadius, customName)
    assert(type(x) == "number", "dxDrawRoundedRectangle argument #1 must be a number, got '" .. type(x) .. "'.");
    assert(type(y) == "number", "dxDrawRoundedRectangle argument #2 must be a number, got '" .. type(y) .. "'.");
    assert(type(width) == "number", "dxDrawRoundedRectangle argument #3 must be a number, got '" .. type(width) .. "'.");
    assert(type(height) == "number", "dxDrawRoundedRectangle argument #4 must be a number, got '" .. type(height) .. "'.");

    if (not color) then color = tocolor(255, 255, 255); end 
    if (not radius) then radius = 24 + 25; end 
    if (fill == nil) then fill = true; end 
    if (not borderThickness) then borderThickness = { 0.2, 0.2 }; end 
    if (useRelativeRadius == nil) then useRelativeRadius = false; end 
    if (type(radius) == 'number') then if (useRelativeRadius) then radius = math.max(math.min(radius, 1), 0); end radius = { radius, radius, radius, radius }; end 
    if (type(radius) == 'table' and useRelativeRadius) then table.map(radius, function(x) return math.max(math.min(x, 1), 0); end) end
    if (type(borderThickness) == 'number') then borderThickness = { borderThickness, borderThickness }; end 
    
    local shaderId = 'rounded;' .. table.concat(radius, ';') .. tostring(fill) .. table.concat(borderThickness, ';') .. tonumber(color) .. (customName or "");
    -- if (customName) then shaderId = customName; end
    local shader = __RectangleCache[shaderId];
    if (not shader) then 
        __RectangleCache[shaderId] = {
            element = dxCreateShader(__RequestRoundRectangleShader(not fill)), 
            __lastVisible = getTickCount(),
        };

        shader = __RectangleCache[shaderId];

        local b = bitExtract(color, 0, 8);
        local g = bitExtract(color, 8, 8);
        local r = bitExtract(color, 16, 8);
        local a = bitExtract(color, 24, 8);

        -- local calculatedRadius = radius;
        -- local midpointOfSize = math.floor(width + height) / 2;
        local midpointOfSize = height * 8;
        local calculatedRadius = {
            useRelativeRadius and radius[1] or ((radius[1] or 0) / midpointOfSize), 
            useRelativeRadius and radius[2] or ((radius[2] or 0) / midpointOfSize), 
            useRelativeRadius and radius[3] or ((radius[3] or 0) / midpointOfSize), 
            useRelativeRadius and radius[4] or ((radius[4] or 0) / midpointOfSize), 
        };

        dxSetShaderValue(shader.element, 'radius', calculatedRadius);
        dxSetShaderValue(shader.element, 'color', { r / 255, g / 255, b / 255, a / 255 });
        dxSetShaderValue(shader.element, 'borderThickness', borderThickness);
    end 
    dxDrawImage(x, y, width, height, shader.element, 0, 0, 0, nil, isPostGUI);
    shader.__lastVisible = getTickCount();
end
dxDrawRoundedRectangleCore = dxDrawRoundedRectangle;

function dxDrawGradientRectangle(x, y, width, height, fromColor, toColor, orientation)
    assert(type(x) == "number", "dxDrawRoundedRectangle argument #1 must be a number, got '" .. type(x) .. "'.");
    assert(type(y) == "number", "dxDrawRoundedRectangle argument #2 must be a number, got '" .. type(y) .. "'.");
    assert(type(width) == "number", "dxDrawRoundedRectangle argument #3 must be a number, got '" .. type(width) .. "'.");
    assert(type(height) == "number", "dxDrawRoundedRectangle argument #4 must be a number, got '" .. type(height) .. "'.");

    local fromColor = fromColor or tocolor(0, 0, 0);
    local toColor = toColor or tocolor(255, 255, 255);
    local orientation = orientation or "horizontal";

    local rectId = fromColor .. ';' .. toColor .. ';' .. orientation;
    if (not __RectangleCache[rectId]) then 
        __RectangleCache[rectId] = {
            element = dxCreateRenderTarget(width, height, true),
            __lastVisible = getTickCount(),
        };
        local fB = bitExtract(fromColor, 0, 8);
        local fG = bitExtract(fromColor, 8, 8);
        local fR = bitExtract(fromColor, 16, 8);
        local fA = bitExtract(fromColor, 24, 8);
        local tB = bitExtract(toColor, 0, 8);
        local tG = bitExtract(toColor, 8, 8);
        local tR = bitExtract(toColor, 16, 8);
        local tA = bitExtract(toColor, 24, 8);
        local index = 0;
        dxSetRenderTarget(__RectangleCache[rectId].element, true);
            if (orientation == 'horizontal') then 
                while (index < width) do 
                    local r, g, b = interpolateBetween(fR, fG, fB, tR, tG, tB, index / width, 'Linear');
                    local alpha = interpolateBetween(fA, 0, 0, tA, 0, 0, index / width, 'Linear');
                    dxDrawRectangle(
                        index,
                        0, 1, height, 
                        tocolor(r, g, b, alpha)
                    );
                    index = index + 1;
                end 
            elseif (orientation == 'vertical') then 
            end 
        dxSetRenderTarget(nil);
    end 
    --dxDrawRectangle(x, y, width, height, tocolor(255, 0, 0, 25));
    dxDrawImage(x, y, width, height, __RectangleCache[rectId].element);
    __RectangleCache[rectId].__lastVisible = getTickCount();
end 

setTimer(function()
    local tick = getTickCount();
    for k,v in pairs(__RectangleCache) do 
        if (
            v.__lastVisible and 
            v.__lastVisible + __TruncateRectanglesInterval < tick
        ) then 
            if (isElement(v.element)) then 
                destroyElement(v.element);
            end 
            __RectangleCache[k] = nil;
        end 
    end 
end, __TruncateRectanglesInterval, 0);

local __Scrollbars = {};
local __LastDraggedScrollbar = nil;
local __DefaultScrollbarStyles = {
    Default = {
        BackgroundColor = tocolor(20, 20, 20),
        BarColor = tocolor(128, 128, 128),
        BarColorHover = tocolor(180, 180, 180),
        
        Radius = 1, 
        Padding = 2,
    },
};
local __DefaultScrollbarSettings = {
    Style = 'Default',
    ScrollArea = nil, -- [x, y, width, height]
    __Index = 1,
    __ChangeByScroll = nil,
    __LastVisible = 0,
    __LastPosition = nil, 
    __LastSize = nil,
    __LastGapHeight = 0,
    __LastTotal = 0, 
    __LastShown = 0, 
};

Scrollbar = Class {
    __Constructor = function(self, ID, Settings)
        local Settings = Settings or { };

        local mergedSettings = table.merge(Settings, __DefaultScrollbarSettings);

        self = table.merge(self, mergedSettings);
        self.ID = ID;
        self.Style = (type(self.Style) ~= 'table')
                    and (__DefaultScrollbarStyles[self.Style] or __DefaultScrollbarStyles.Default) 
                    or table.merge(self.Style, __DefaultScrollbarStyles.Default);

        __Scrollbars[self.ID] = self;
    end, 

    Render = function(self, X, Y, Width, Height, Shown, Total)
        local Style = (type(self.Style) ~= 'table')
                        and (__DefaultScrollbarStyles[self.Style] or __DefaultScrollbarStyles.Default) 
                        or self.Style;
        local VisibleFactor = math.min(Shown / Total, 1.0);
        VisibleFactor = math.max(VisibleFactor, 0.05);

        local BarHeight = Height * VisibleFactor;
        local Position = math.min(self.__Index / Total, 1.0 - VisibleFactor) * Height;

        self.__LastPosition = Vector2(X + Style.Padding, Y + Position + Style.Padding);
        self.__LastSize = Vector2(Width - Style.Padding * 2, BarHeight - Style.Padding * 2);

        local isBarHovered = (
            IsCursorInArea(
                self.__LastPosition, self.__LastSize
            ) or (__LastDraggedScrollbar and self.ID == __LastDraggedScrollbar)
        );

        -- if (Style.Radius) then 
        --     if (not dxDrawRoundedRectangleCore) then 
        --         outputDebugString("Requirezd mar a kurva \"Rectangle\" componentet is...", 1);
        --         return;
        --     end 
        --     if (Shown < Total) then 
        --         dxDrawRoundedRectangleCore(
        --             X, Y, Width, Height, 
        --             tocolor(14, 14, 14, 255), 1.0
        --         );

        --         dxDrawRoundedRectangleCore(
        --             self.__LastPosition.x, self.__LastPosition.y, 
        --             self.__LastSize.x, self.__LastSize.y, 
        --             isBarHovered and Style.BarColorHover or Style.BarColor, 1.0
        --         );
        --     end 
        -- else 
            if (Shown < Total) then
                dxDrawRectangle(X, Y, Width, Height, tocolor(14, 14, 14, 255));
                dxDrawRectangle(
                    self.__LastPosition.x, self.__LastPosition.y, 
                    self.__LastSize.x, self.__LastSize.y, 
                    tocolor(205, 105, 38, 255)
                );
            end 
        -- end 

        self.__LastGapHeight = Height / Total;

        if (__LastDraggedScrollbar and __LastDraggedScrollbar == self.ID) then 
            local CursorX, CursorY = getCursorPosition();
            local indexDiff = math.floor(
                (
                    ((CursorY + self.Click.Offset) - Y) - (self.Click.Height - Y)
                ) / self.__LastGapHeight
            );

            local NewIndex = self.Click.index + indexDiff;

            -- dxDrawText(NewIndex .. ' - ' .. self.__LastGapHeight .. ' - ' .. Y .. ' - ' .. CursorY .. ' - ' .. self.Click.Height .. ' - ' .. self.Click.Offset, CursorX + 20, CursorY, 
            --             _, _, _, 1, 'arial', _, _, _, _, true);

            if (NewIndex < 0) then NewIndex = 0; end
            if (NewIndex > (Total - Shown)) then NewIndex = (Total - Shown); end 

            self.__Index = NewIndex;

            if (self.callBack) then
                self.callBack();
            end
        end 

        if (Total ~= self.__LastTotal) then self.__LastTotal = Total; end 
        if (Shown ~= self.__LastShown) then self.__LastShown = Shown; end 
    end, 

    Destroy = function(self)
        if (__LastDraggedScrollbar and __LastDraggedScrollbar == self.ID) then 
            __LastDraggedScrollbar = nil;
        end 

        if (__Scrollbars[self.ID]) then 
            __Scrollbars[self.ID] = nil;
        end 
        
        self.__Deconstruct();
    end, 
}

addEventHandler('onClientClick', root, function(Button, State)
    if (isCursorShowing() and Button == 'left' and State == 'down') then 
        for ID,v in pairs(__Scrollbars) do 
            if (
                IsCursorInArea(v.__LastPosition, v.__LastSize) and 
                v.__LastShown < v.__LastTotal
            ) then 
                local CursorX, CursorY = getCursorPosition();
                __LastDraggedScrollbar = ID;

                v.Click = {
                    Height = v.__LastPosition.y, 
                    Offset = v.__LastPosition.y - CursorY,
                    index = v.__Index
                };
            end 
        end 
    elseif (Button == 'left' and State == 'up' and __LastDraggedScrollbar) then 
        local Box = __Scrollbars[__LastDraggedScrollbar];
    
        if (Box) then 
            Box.Click = { Height = Vector2(0, 0), index = 0 };
        end 

        __LastDraggedScrollbar = nil;
    end 
end)

function __OnScroll(key)
    for ID,v in pairs(__Scrollbars) do 
        if (
            v.__LastShown < v.__LastTotal and 
            (not v.ScrollArea or IsCursorInArea(unpack(v.ScrollArea)))
        ) then 
            local NewIndex = v.__Index;
    
            if (key == 'mouse_wheel_up' and v.__Index > 0) then 
                NewIndex = v.__Index - ((not v.__ChangeByScroll) and v.__LastShown or v.__ChangeByScroll);
            elseif (key == 'mouse_wheel_down' and v.__Index < v.__LastTotal - v.__LastShown) then 
                NewIndex = v.__Index + ((not v.__ChangeByScroll) and v.__LastShown or v.__ChangeByScroll);
            end 
    
            if (NewIndex < 0) then 
                NewIndex = 0;
            elseif (NewIndex > v.__LastTotal - v.__LastShown) then 
                NewIndex = v.__LastTotal - v.__LastShown;
            end 
    
            v.__Index = NewIndex;

            if (v.callBack) then
                v.callBack();
            end
        end 
    end 
end 
bindKey('mouse_wheel_up', 'down', __OnScroll);
bindKey('mouse_wheel_down', 'down', __OnScroll);

local __Switches = {};
local __SwitchAnimInterval = 400;
local __SwitchVisibilityDiff = 250;
local __DefaultSwitchStyles = {
    default = {
        bgColor = { 20, 20, 20 },
        thumbColor_false = { 48, 48, 48 },
        thumbColor_true = { 49, 158, 50 },
        padding = 6,
        radius = 1.0, 
        radiusUseRelative = true,
    },
};

local __DefaultSwitchSettings = {
    Value = true, 
    style = 'default', 
    __position = Vector2(0.0, 0.0),
    __size = Vector2(0.0, 0.0),
    __lastVisible = 0.0,
    __last_change = getTickCount(),
};

function Switch(id, settings)
    local settings = (settings or {});
    local self = table.merge(settings, __DefaultSwitchSettings);
    
    self.id = id;
    self.__events = {};
    self.style = (type(self.style) ~= 'table')
                    and (__DefaultSwitchStyles[self.style] or __DefaultSwitchStyles.default) 
                    or table.merge(self.style, __DefaultSwitchStyles.default);

    self.Render = function(x, y, width, height, alpha)
        local tick = getTickCount();
        local style = (type(self.style) ~= 'table')
                        and (__DefaultSwitchStyles[self.style] or __DefaultSwitchStyles.default) 
                        or self.style;
        
        local bgColor = style.bgColor;

        bgColor[4] = alpha;
        if (style.radius ~= nil) then 
            if (not dxDrawRoundedRectangleCore) then 
                outputDebugString("Requirezd mar a kurva \"Rectangle\" componentet is...", 1);
                return;
            end 
            dxDrawRoundedRectangleCore(
                x, y, width, height, 
                tocolor(unpack(bgColor)), 
                style.radius, nil, nil, nil, 
                style.useRelativeRadius
            );
        else 
            dxDrawRectangle(
                x, y, 
                width, height, 
                tocolor(unpack(bgColor))
            );
        end 
        local thumbSize = (width > height) and (height - style.padding) or (width - style.padding);
        local btnX, btnY = interpolateBetween(
            (self.Value and (x + style.padding / 2) or (x + width - thumbSize - style.padding / 2)), 0, 0,
            (self.Value and (x + width - thumbSize - style.padding / 2) or (x + style.padding / 2)), 0, 0,
            (tick - self.__last_change) / __SwitchAnimInterval, "InOutQuad"
        ), (y + height / 2) - (thumbSize / 2);
        local thumbColor = {interpolateBetween(
            style['thumbColor_' .. tostring(not self.Value)][1], style['thumbColor_' .. tostring(not self.Value)][2], style['thumbColor_' .. tostring(not self.Value)][3], 
            style['thumbColor_' .. tostring(self.Value)][1], style['thumbColor_' .. tostring(self.Value)][2], style['thumbColor_' .. tostring(self.Value)][3],
            (tick - self.__last_change) / __SwitchAnimInterval, "InOutQuad"
        )};
        thumbColor[4] = alpha;
        if (style.radius ~= nil) then 
            if (not dxDrawRoundedRectangleCore) then 
                outputDebugString("Requirezd mar a kurva \"Rectangle\" componentet is...", 1);
                return;
            end 
            dxDrawRoundedRectangleCore(
                btnX, btnY, thumbSize, thumbSize, 
                tocolor(unpack(thumbColor)), 
                style.radius, nil, nil, nil, 
                style.useRelativeRadius
            );
        else 
            dxDrawRectangle(
                btnX, btnY, 
                thumbSize, thumbSize, 
                tocolor(unpack(thumbColor))
            );
        end 
        self.__position = Vector2(x, y);
        self.__size = Vector2(width, height);
        self.__lastVisible = tick;
    end
    self.__EmitEvent = function(event, ...)
        if (event and self.__events[event]) then 
            for _, handler in ipairs(self.__events[event]) do 
                handler(self, ...);
            end 
        end 
    end 
    self.On = function(event, handler)
        if (not event or not handler) then return; end 
        if (not self.__events[event]) then 
            self.__events[event] = {};
        end 
        table.insert(self.__events[event], handler);
    end 
    __Switches[id] = self;
    return self;
end 

addEventHandler('onClientClick', root, function(button, state)
    if (button ~= 'left' and state ~= 'down') then 
        return;
    end 
    
    local tick = getTickCount();
    local cursorX, cursorY = getCursorPosition(true);

    for id, v in pairs(__Switches) do 
        if (
            isCursorInArea(v.__position.x, v.__position.y, v.__size.x, v.__size.y) and 
            v.__last_change + __SwitchAnimInterval < tick and -- nem kattintgatja kurvagyorsan
            tick < v.__lastVisible + __SwitchVisibilityDiff -- latszodik egyaltalan
        ) then 
            v.__last_change = tick;
            v.Value = not v.Value;
            v.__EmitEvent('OnChange');
        end 
    end 
end);

-- Nem nyulkapiszka mert eltorom a kezed
__Textareas = {};
__TextareaOrder = {};
__SelectedTextarea = nil; 
__visibilityDiff = 200; -- ms
__substrFromLength = 128;

-- Itt nyulkapiszkazhatszmar
local __DefaultTextareaStyles = {
    default = {
        Background = tocolor(20, 20, 20),
        BackgroundActive = nil, 

        Padding = 8,
        Align = 'left',

        Radius = 0.2, 
        UseRelativeRadius = true, 
        Border = 0.035, 
        BorderColor = tocolor(26, 26, 26),
        BorderColorActive = tocolor(unpack(exports["ex_new_core"]:GetColor("server", "rgb"))),
    },

    transparent = {
        Background = tocolor(0, 0, 0, 0),

        Padding = 5,

        Radius = 0.3, 
        UseRelativeRadius = true,
        Border = 0.035, 
        BorderColor = tocolor(0, 0, 0, 0),
    },
};

local __DefaultTextareaSettings = {
    Masked = false,
    Disabled = false,
    Value = '',
    Style = 'default',
    Font = { "OpenSans", 9 },

    NumbersAllowed = true, 
    SpecialsAllowed = false,
    MaxLength = 512,

    __Events = {},
    __Position = nil, 
    __Size = nil, 
    __LastVisible = 0,
};

local __IncludedCharacters = {
    ['ö'] = true, ['Ö'] = true,
    ['ű'] = true, ['Ű'] = true,
    ['ü'] = true, ['Ü'] = true,
    ['ó'] = true, ['Ó'] = true,
    ['ő'] = true, ['Ő'] = true,
    ['ú'] = true, ['Ú'] = true,
    ['é'] = true, ['É'] = true,
    ['á'] = true, ['Á'] = true,
    ['í'] = true, ['Í'] = true,

    ['!'] = true,
    ['@'] = true,
    ['#'] = true,
    ['$'] = true,
    ['%'] = true,
    ['^'] = true,
    ['&'] = true,
    ['*'] = true,
    ['('] = true,
    [')'] = true,
    ['-'] = true,
    ['_'] = true,
    ['='] = true,
    ['+'] = true,
    [','] = true,
    ['.'] = true,
    ['/'] = true,
    ['?'] = true,
    [':'] = true,

    [' '] = true,
};

Textarea = Class {
    __Constructor = function(self, ID, Settings)
        local Settings = Settings or { };

        local MergedSettings = table.merge(Settings, __DefaultTextareaSettings);

        self = table.merge(self, MergedSettings);
        self.ID = ID;
        self.Style = (type(self.Style) ~= 'table')
                    and (__DefaultTextareaStyles[self.Style] or __DefaultTextareaStyles.Default) 
                    or table.merge(self.Style, __DefaultTextareaStyles.Default);

        __Textareas[self.ID] = self;
        table.insert(__TextareaOrder, ID);
    end, 

    Render = function(self, X, Y, Width, Height)
        local Style = self.Style;
        local Padding = Style.Padding;

        if (Style.Radius ~= nil) then 
            if (not dxDrawRoundedRectangleCore) then 
                outputDebugString("Requirezd mar a kurva \"Rectangle\" componentet is...", 1);
                return;
            end 

            dxDrawRoundedRectangleCore(
                X, Y, Width, Height, 
                Style.Background, Style.Radius, 
                true, false, false, Style.UseRelativeRadius
            );

            if (Style.Border ~= nil) then 
                Padding = Padding + Style.Border * 80;

                local Color = (
                    __SelectedTextarea and 
                    __SelectedTextarea == self.ID and 
                    Style.BorderColorActive ~= nil
                ) and Style.BorderColorActive or Style.BorderColor;

                dxDrawRoundedRectangleCore(
                    X, Y, Width, Height, 
                    Color, Style.Radius, 
                    false, Style.Border, 
                    false, Style.UseRelativeRadius
                );
            end 
        else 
            dxDrawRectangle(X, Y, Width, Height, Style.Background);
        end 

        local Text = utf8.sub(self.Value, 1, self.MaxLength);
        local isPlaceholder = false;

        if (
            Text == '' and
            (
                not __SelectedTextarea or 
                __SelectedTextarea ~= self.ID
            )
        ) then 
            Text = self.Placeholder or '';
            isPlaceholder = true;
        else 
            if (self.Masked) then 
                Text = string.rep("*", string.len(self.Value));
            end 
            
            local TextSuffix = (
                __SelectedTextarea and 
                __SelectedTextarea == self.ID and
                getTickCount() % 1000 <= 500
            ) and "|" or " ";

            Text = Text .. TextSuffix;
        end 

        local UsedFont = isElement(self.Font) and self.Font or getFont(unpack(self.Font));

        local TextWidth = dxGetTextWidth(Text, 1, UsedFont);
        local TextHeight = dxGetFontHeight(1, UsedFont);
        local TextLines = dxGetTextHeight(Text, UsedFont, 1, (Width - Padding));
        
        -- dxDrawText(#Text, X, Y - 30);

        dxDrawText(
            Text, 
            X + Padding / 2, Y + Padding / 2, 
            Width - Padding, Height - Padding, 
            tocolor(255, 255, 255, isPlaceholder and 150 or 200), 
            1, UsedFont, 
            'left', (math.floor(Height / TextHeight) >= TextLines) and 'top' or 'bottom',
            true, true
        );

        self.__LastVisible = getTickCount();
        self.__Position = Vector2(X, Y);
        self.__Size = Vector2(Width, Height);
    end, 

    Destroy = function(self)
        if (
            __SelectedTextarea and
            __SelectedTextarea == self.id
        ) then 
            __SelectedTextarea = nil;
            guiSetInputMode("allow_binds");
        end 

        if (__Textareas[self.id]) then
            __Textareas[self.id] = nil;
        end 

        for i, v in ipairs(__TextareaOrder) do 
            if (v == self.ID) then 
                table.remove(__TextareaOrder, i);
            end 
        end 

        self = nil;
    end, 

    __EmitEvent = function(self, EventName, ...)
        if (not EventName or not self.__Events[EventName]) then 
            return false;
        end 

        for _, Handler in ipairs(self.__Events[EventName]) do 
            Handler(self, ...);
        end 
    end, 

    On = function(self, EventName, Handler)
        if (not EventName or not Handler) then 
            return false;
        end 

        if (not self.__Events[EventName]) then 
            self.__Events[EventName] = {};
        end 

        table.insert(self.__Events[EventName], Handler);
    end, 
}

addEventHandler('onClientKey', root, function(Key, IsPress)
    if (IsPress and __SelectedTextarea) then 
        if (Key == 'backspace') then 
            if (not __Textareas[__SelectedTextarea]) then 
                __SelectedTextarea = nil;
                return;
            end 

            local Box = __Textareas[__SelectedTextarea];

            if (Box.Disabled) then 
                return;
            end 

            if (isTimer(Box.BackspaceTimer)) then 
                return;
            end 

            Box.Value = utf8.sub(Box.Value, 1, -2);
            Box.__EmitEvent('OnChange');

            -- Kicsi callbackhell, hogy a szerverhez melto legyen!
            setTimer(function()
                if (getKeyState('backspace') and not isTimer(Box.BackspaceTimer)) then 
                    Box.BackspaceTimer = setTimer(function()
                        if (
                            getKeyState('backspace') and 
                            Box and 
                            isTimer(Box.BackspaceTimer) and 
                            Box.Value ~= '' and 
                            not Box.Disabled
                        ) then 
                            Box.Value = utf8.sub(Box.Value, 1, -2);
                            Box.__EmitEvent('OnChange');
                        else 
                            killTimer(Box.BackspaceTimer);
                        end 
                    end, 30, 0);
                end 
            end, 500, 1);
        elseif (Key == 'tab') then 
            local Index = table.findIndex(__TextareaOrder, function(x) return (__SelectedTextarea == x); end);

            if (not Index) then 
                return;
            end 

            local NextIndex = ((Index + 1) > #__TextareaOrder) and 1 or Index + 1;
            local NextTextarea = table.find_Keytbl(__Textareas, function(x) return (x.id == __TextareaOrder[NextIndex]); end);
            if (NextTextarea) then 
                __SelectedTextarea = NextTextarea.ID;
            end 
        end 
    end 
end)

addEventHandler('onClientCharacter', root, function(character)
    if (
        not __SelectedTextarea or 
        not isCursorShowing() or 
        isMTAWindowActive() or
        isConsoleActive()
    ) then 
        return; 
    end 

    if (not __Textareas[__SelectedTextarea]) then
        __SelectedTextarea = nil;
    end

    local Box = __Textareas[__SelectedTextarea];

    if (
        Box.Disabled or 
        (not Box.NumbersAllowed and tonumber(character)) or 
        #Box.Value >= Box.MaxLength
    ) then 
        return;
    end 

    -- aaaaaa miez
    local byte = string.byte(character);
    if (
        not Box.SpecialsAllowed and 
        (
            not (
                (byte >= 65 and byte <= 90) or 
                (byte >= 97 and byte <= 122) or 
                (byte >= 48 and byte <= 57)
            ) and not __IncludedCharacters[character]
        )
    ) then 
        return;
    end 

    if (isTimer(Box.BackspaceTimer)) then 
        return;
    end 

    Box.Value = Box.Value .. character;
    Box.__EmitEvent('OnChange');
end);

addEventHandler('onClientPaste', root, function(Text)
    if (
        not __SelectedTextarea or 
        not __Textareas[__SelectedTextarea]
    ) then 
        return;
    end
        
    local Textarea = __Textareas[__SelectedTextarea];
    if (__SelectedTextarea and __Textareas[__SelectedTextarea]) then 
        Text = Text:gsub(".", function(Letter)
            if (
                not Textarea.NumbersAllowed and 
                tonumber(Letter)
            ) then 
                return "";
            end 

            local Byte = string.byte(Letter);
            if (
                not Textarea.SpecialsAllowed and 
                (
                    not (
                        (Byte >= 65 and Byte <= 90) or 
                        (Byte >= 97 and Byte <= 122) or 
                        (Byte >= 48 and Byte <= 57)
                    ) and not __IncludedCharacters[Letter]
                )
            ) then 
                return "";
            end 

            return Letter;
        end);

        local NewText = utf8.sub(Textarea.Value .. utf8.gsub(Text, "\n", " "), 1, Textarea.MaxLength);
		Textarea.Value = NewText;
        Textarea.__EmitEvent('OnChange', Textarea.Value, NewText);
    end 
end);

addEventHandler("onClientResourceStop", resourceRoot, function()
    if (not __SelectedEditbox) then return end
    if (not __Editboxes[__SelectedEditbox]) then return end

    nexports.new_core:SetEditboxUsage(false);
end);

addEventHandler('onClientClick', root, function(button, state)
    if (not isCursorShowing() or button ~= 'left' or state ~= 'down') then return; end
    local tick = getTickCount();
    local haveAnyVisibleEditbox = false;
    
    if (__Editboxes) then 
        for id, v in pairs(__Editboxes) do 
            if (
                v.__LastVisible and 
                (v.__LastVisible + __VisibilityDiff) > tick and 
                (v.__Position ~= nil and v.__Size ~= nil) and 
                not isChatBoxInputActive() and not isConsoleActive() and not v.noFocus
            ) then
                if (isCursorInArea(v.__Position, v.__Size) and not v.disabled) then 
                    nexports.new_core:SetEditboxUsage(true);
                    __SelectedEditbox = id;
                    guiSetInputMode("no_binds");
                    v.__EmitEvent('focus');
                    
                    if (v.onChange) then
                        v.onChange("open");
                    end

                    return;
                end 
                haveAnyVisibleEditbox = true;
            end 
        end 
    end 

    if (__Textareas) then 
        for id, v in pairs(__Textareas) do 
            if (
                v.__LastVisible and 
                (v.__LastVisible + __VisibilityDiff) > tick and 
                (v.__Position ~= nil and v.__Size ~= nil) and 
                not isChatBoxInputActive() and not isConsoleActive()
            ) then
                if (isCursorInArea(v.__Position, v.__Size)) then 
                    nexports.new_core:SetEditboxUsage(true);
                    __SelectedTextarea = id;
                    guiSetInputMode("no_binds");
                    v.__EmitEvent('focus');

                    return;
                end 

                haveAnyVisibleEditbox = true;
            end 
        end 
    end 

    if (haveAnyVisibleEditbox) then 
        nexports.new_core:SetEditboxUsage(false);
        guiSetInputMode("allow_binds");

        if (__Editboxes[__SelectedEditbox] and __Editboxes[__SelectedEditbox].onChange) then
            __Editboxes[__SelectedEditbox].onChange("close");
        end

        __SelectedEditbox = nil;
        __SelectedTextarea = nil;
    end 
end, true, "low-10");
