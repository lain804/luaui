local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local Element = require("../element")
local dispatchCallback = Element.dispatchCallback
local Style = require("../style")
local Theme = Style.Theme
local INPUT_ROW_HEIGHT = Style.INPUT_ROW_HEIGHT
local createRow = Style.createRow
local createLabel = Style.createLabel
local createInputSurface = Style.createInputSurface
local Input = require("../input")
local bindButtonFeedback = Input.bindButtonFeedback
local bindActivation = Input.bindActivation
local isVisible = Input.isVisible
local isPointerPress = Input.isPointerPress
local focusDirection = Input.focusDirection
local stepFocus = Input.stepFocus
local Util = require("../util")
local finiteNumber = Util.finiteNumber
local disconnectAll = Util.disconnectAll

-- Options is an array of strings, finite numbers, or booleans.
return function(self, args)
    args = args or {}
    local text = args.Text or "Dropdown"
    local function normalizeOptions(values)
        assert(type(values) == "table", "Dropdown options must be a table")
        local result, seen = {}, {}
        for _, option in ipairs(values) do
            local kind = type(option)
            assert(kind == "string" or kind == "boolean" or kind == "number" and finiteNumber(option, nil),
                "Dropdown options must be strings, finite numbers, or booleans")
            if not seen[option] then
                seen[option] = true
                table.insert(result, option)
            end
        end
        return result, seen
    end
    local options, optionSet = normalizeOptions(if args.Options == nil then {} else args.Options)
    local multiSelect = args.Multi or false
    local callback = args.Callback
    local flag = args.Flag or args.Save
    local selected = {}
    local selectionOrder = {}

    local function replaceSelection(values)
        if type(values) ~= "table" then values = { values } end
        table.clear(selected)
        table.clear(selectionOrder)
        for _, option in ipairs(values) do
            if optionSet[option] and not selected[option] then
                selected[option] = true
                table.insert(selectionOrder, option)
                if not multiSelect then break end
            end
        end
    end

    replaceSelection(self:_GetSaved(flag, args.Default == nil and {} or args.Default))

    local frame = createRow(self, "Frame", "Dropdown", args.Height, INPUT_ROW_HEIGHT)
    frame.ZIndex = 5

    local label = createLabel(frame, text, args.TextSize)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.Size = UDim2.new(0.42, -18, 1, 0)
    label.ZIndex = 6

    local button = createInputSurface(frame, "TextButton")
    button.Text = ""
    button.AutoButtonColor = false
    button.ZIndex = 6
    local resetFeedback, setActiveFeedback = bindButtonFeedback(button, Theme.Background)

    local selectedLabel = createLabel(button, "", args.TextSize)
    selectedLabel.Position = UDim2.new(0, 6, 0, 0)
    selectedLabel.Size = UDim2.new(1, -26, 1, 0)
    selectedLabel.ZIndex = 7

    local arrow = Instance.new("TextLabel")
    arrow.Parent = button
    arrow.BackgroundTransparency = 1
    arrow.AnchorPoint = Vector2.new(1, 0.5)
    arrow.Position = UDim2.new(1, -6, 0.5, 0)
    arrow.Size = UDim2.new(0, 15, 1, 0)
    arrow.Font = Enum.Font.Code
    arrow.Text = "v"
    arrow.TextColor3 = Theme.TextDim
    arrow.TextSize = 10
    arrow.ZIndex = 7

    local touch = UserInputService.TouchEnabled
    local optionHeight = touch and 44 or 28
    local headerHeight = touch and 52 or 34
    local footerHeight = multiSelect and (touch and 52 or 32) or 0
    local dropdownHeight

    local overlay = Instance.new("Frame")
    overlay.Name = "DropdownOverlay"
    overlay.Parent = self.library.MainFrame
    overlay.BackgroundTransparency = 1
    overlay.BorderSizePixel = 0
    overlay.Position = UDim2.new(0, 0, 0, 0)
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.Visible = false
    overlay.ZIndex = 40

    local outsideButton = Instance.new("TextButton")
    outsideButton.Name = "OutsideClose"
    outsideButton.Parent = overlay
    outsideButton.BackgroundTransparency = 1
    outsideButton.BorderSizePixel = 0
    outsideButton.Position = UDim2.new(0, 0, 0, 0)
    outsideButton.Size = UDim2.new(1, 0, 1, 0)
    outsideButton.Text = ""
    outsideButton.AutoButtonColor = false
    outsideButton.Selectable = false
    outsideButton.ZIndex = 40

    local dropdown = Instance.new("Frame")
    dropdown.Name = "DropdownList"
    dropdown.Parent = overlay
    dropdown.BackgroundColor3 = Theme.Element
    dropdown.BorderColor3 = Theme.BorderHover
    dropdown.BorderSizePixel = 1
    dropdown.AnchorPoint = Vector2.new(0, 0)
    dropdown.Position = UDim2.new(0, 0, 0, 0)
    dropdown.Size = UDim2.fromOffset(0, 0)
    dropdown.Visible = false
    dropdown.Active = true
    dropdown.ClipsDescendants = true
    dropdown.SelectionGroup = true
    dropdown.SelectionBehaviorUp = Enum.SelectionBehavior.Stop
    dropdown.SelectionBehaviorDown = Enum.SelectionBehavior.Stop
    dropdown.SelectionBehaviorLeft = Enum.SelectionBehavior.Stop
    dropdown.SelectionBehaviorRight = Enum.SelectionBehavior.Stop
    dropdown.ZIndex = 50

    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Parent = dropdown
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.BorderSizePixel = 0
    scrollFrame.Position = UDim2.new(0, 0, 0, headerHeight)
    scrollFrame.Size = UDim2.new(1, 0, 1, -headerHeight - footerHeight)
    scrollFrame.ScrollingDirection = Enum.ScrollingDirection.Y
    scrollFrame.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar
    scrollFrame.ScrollBarThickness = 4
    scrollFrame.ScrollBarImageColor3 = Theme.BorderHover
    scrollFrame.ClipsDescendants = true
    scrollFrame.ZIndex = 51

    local layout = Instance.new("UIListLayout")
    layout.Parent = scrollFrame
    layout.SortOrder = Enum.SortOrder.LayoutOrder

    local search = Instance.new("TextBox")
    search.Name = "Search"
    search.Parent = dropdown
    search.Size = UDim2.new(1, -12, 0, headerHeight - 8)
    search.Position = UDim2.fromOffset(6, 4)
    search.BackgroundColor3 = Theme.Track
    search.BorderColor3 = Theme.Border
    search.BorderSizePixel = 1
    search.Font = Enum.Font.Code
    search.Text = ""
    search.TextSize = 12
    search.TextColor3 = Theme.Text
    search.PlaceholderText = "Search options..."
    search.PlaceholderColor3 = Theme.TextDim
    search.ClearTextOnFocus = false
    search.TextXAlignment = Enum.TextXAlignment.Left
    search.ZIndex = 52
    local searchPadding = Instance.new("UIPadding")
    searchPadding.PaddingLeft = UDim.new(0, 8)
    searchPadding.PaddingRight = UDim.new(0, 8)
    searchPadding.Parent = search
    self.library:_DecorateObject(search)

    local bulkButtons = {}
    local resetBulkFeedback = {}
    if multiSelect then
        for index, caption in ipairs({"All", "Clear"}) do
            local bulk = Instance.new("TextButton")
            bulk.Parent = dropdown
            bulk.Text = caption
            bulk.Font = Enum.Font.Code
            bulk.TextSize = 12
            bulk.TextColor3 = Theme.Text
            bulk.BackgroundColor3 = Theme.Tab
            bulk.BorderColor3 = Theme.Border
            bulk.AutoButtonColor = false
            bulk.Position = UDim2.new((index - 1) * 0.5, index == 1 and 6 or 2, 1, 3 - footerHeight)
            bulk.Size = UDim2.new(0.5, -8, 0, footerHeight - 8)
            bulk.ZIndex = 52
            self.library:_DecorateObject(bulk)
            resetBulkFeedback[index] = bindButtonFeedback(bulk, Theme.Tab)
            bulkButtons[index] = bulk
        end
    end

    local emptyMessage = createLabel(dropdown, "No results", 12)
    emptyMessage.Position = UDim2.new(0, 8, 0, headerHeight)
    emptyMessage.Size = UDim2.new(1, -16, 0, optionHeight)
    emptyMessage.TextColor3 = Theme.TextDim
    emptyMessage.Visible = false
    emptyMessage.ZIndex = 52
    local visibleIndices = {}
    local optionButtons = {}
    local activeIndex = nil
    local hoveredIndex = nil

    local function getSelectedTable()
        return table.clone(selectionOrder)
    end

    local function getValue()
        if multiSelect then return getSelectedTable() end
        return selectionOrder[1]
    end

    local function getSelectedText()
        local list = selectionOrder
        if #list == 0 then
            return #options == 0 and "No options" or "None"
        elseif #list == 1 then
            return tostring(list[1])
        else
            return tostring(list[1]) .. " (+" .. (#list - 1) .. ")"
        end
    end

    local function paintOptionBackground(index)
        local item = optionButtons[index]
        if item then
            item.Button.BackgroundColor3 = index == (hoveredIndex or activeIndex) and Theme.ElementPressed
                or selected[item.Option] and Theme.ElementHover or Theme.Background
        end
    end

    local function setOptionHighlight(active, hovered)
        local previous = hoveredIndex or activeIndex
        activeIndex, hoveredIndex = active, hovered
        local current = hoveredIndex or activeIndex
        if previous ~= current then
            paintOptionBackground(previous)
            paintOptionBackground(current)
        end
    end

    local function repaintOptions()
        for index, item in ipairs(optionButtons) do
            local isSelected = selected[item.Option] == true

            item.Marker.Visible = isSelected
            item.Button.TextColor3 = isSelected and Theme.Accent or Theme.Text
            paintOptionBackground(index)
        end
    end

    local function focusOption(index, keepSelection)
        setOptionHighlight(table.find(visibleIndices, index) and index or visibleIndices[1], nil)
        if not keepSelection and not search:IsFocused() then
            GuiService.SelectedObject = activeIndex and optionButtons[activeIndex].Button or search
        end
        if not activeIndex then return end
        local top = (table.find(visibleIndices, activeIndex) - 1) * optionHeight
        local height = math.max(0, dropdown.Size.Y.Offset - headerHeight - footerHeight)
        local canvasY = scrollFrame.CanvasPosition.Y
        if top < canvasY then
            scrollFrame.CanvasPosition = Vector2.new(0, top)
        elseif top + optionHeight > canvasY + height then
            scrollFrame.CanvasPosition = Vector2.new(0, math.max(0, top + optionHeight - height))
        end
    end

    local function renderSelection()
        selectedLabel.Text = getSelectedText()
        selectedLabel.TextColor3 = #selectionOrder > 0 and Theme.Text or Theme.TextDim
        repaintOptions()
    end

    local function updateDisplay(noCallback)
        renderSelection()
        local selection = getSelectedTable()
        -- An empty array preserves an explicitly cleared single selection in JSON.
        local persisted = multiSelect and selection or selection[1]
        self:_SaveFlag(flag, persisted == nil and {} or persisted)
        if callback and not noCallback then
            dispatchCallback(self, frame, callback, getValue())
        end
    end

    local function setSelected(value, noCallback)
        replaceSelection(value)
        updateDisplay(noCallback)
    end

    local isOpen = false
    local placeConnections = {}

    local closeDropdown
    local function placeDropdown()
        local main = self.library.MainFrame
        if not main then return end

        local buttonPos = button.AbsolutePosition
        local buttonSize = button.AbsoluteSize
        local mainPos = main.AbsolutePosition
        local mainSize = main.AbsoluteSize
        local gap = 2
        local contentPos, contentSize = self.content.AbsolutePosition, self.content.AbsoluteSize
        if buttonPos.Y + buttonSize.Y <= contentPos.Y
            or buttonPos.Y >= contentPos.Y + contentSize.Y then
            closeDropdown()
            return
        end

        -- The overlay is a child of MainFrame, which clips descendants. Work in
        -- MainFrame-local coordinates so the decision matches the actual clipping
        -- bounds rather than the top of the screen.
        local x = buttonPos.X - mainPos.X
        local buttonY = buttonPos.Y - mainPos.Y
        local spaceAbove = math.max(0, buttonY - gap)
        local spaceBelow = math.max(0, mainSize.Y - (buttonY + buttonSize.Y) - gap)

        local openAbove
        if dropdownHeight <= spaceBelow then
            openAbove = false
        elseif dropdownHeight <= spaceAbove then
            openAbove = true
        else
            openAbove = spaceAbove > spaceBelow
        end

        -- If neither direction can hold the full list, use the roomier side and
        -- let the existing ScrollingFrame expose the remaining options.
        local availableHeight = openAbove and spaceAbove or spaceBelow
        local visibleHeight = math.min(dropdownHeight, availableHeight)
        local y = openAbove
            and (buttonY - gap - visibleHeight)
            or (buttonY + buttonSize.Y + gap)

        -- Keep the list inside the frame horizontally too, for narrow/resized UIs.
        local visibleWidth = math.min(buttonSize.X, mainSize.X)
        x = math.clamp(x, 0, math.max(0, mainSize.X - visibleWidth))

        dropdown.Size = UDim2.new(0, visibleWidth, 0, visibleHeight)
        dropdown.Position = UDim2.new(0, x, 0, y)
    end

    closeDropdown = function()
        if not isOpen then return end
        isOpen = false
        setOptionHighlight(nil, nil)
        if search:IsFocused() then search:ReleaseFocus() end
        if GuiService.SelectedObject and GuiService.SelectedObject:IsDescendantOf(overlay) then
            GuiService.SelectedObject = isVisible(self.library, button) and button or nil
        end
        dropdown.Visible = false
        overlay.Visible = false
        arrow.Text = "v"
        arrow.TextColor3 = Theme.TextDim
        setActiveFeedback(false)
        for _, reset in ipairs(resetBulkFeedback) do reset() end
        disconnectAll(placeConnections)
        if self.library._closeDropdown == closeDropdown then
            self.library._closeDropdown = nil
        end
    end

    local function chooseOption(option)
        if multiSelect then
            local wasSelected = not not selected[option]
            if wasSelected then
                selected[option] = nil
                for idx, value in ipairs(selectionOrder) do
                    if value == option then
                        table.remove(selectionOrder, idx)
                        break
                    end
                end
            else
                selected[option] = true
                table.insert(selectionOrder, option)
            end
        else
            table.clear(selected)
            table.clear(selectionOrder)
            selected[option] = true
            table.insert(selectionOrder, option)
            closeDropdown()
        end
        updateDisplay()
    end

    local function createOptionButton(option, index)
        local optionButton = Instance.new("TextButton")
        optionButton.Name = "Option" .. index
        optionButton.Parent = scrollFrame
        optionButton.BackgroundColor3 = selected[option] and Theme.ElementHover or Theme.Background
        optionButton.BorderSizePixel = 0
        optionButton.Size = UDim2.new(1, 0, 0, optionHeight)
        optionButton.LayoutOrder = index
        optionButton.TextTruncate = Enum.TextTruncate.AtEnd
        optionButton.Font = Enum.Font.Code
        optionButton.Text = " " .. tostring(option)
        optionButton.TextColor3 = selected[option] and Theme.Accent or Theme.Text
        optionButton.TextSize = args.TextSize or 13
        optionButton.TextXAlignment = Enum.TextXAlignment.Left
        optionButton.AutoButtonColor = false
        optionButton.ZIndex = 52
        local marker = Instance.new("Frame")
        marker.Name = "SelectedMark"
        marker.Parent = optionButton
        marker.BackgroundColor3 = Theme.Accent
        marker.BorderSizePixel = 0
        marker.Position = UDim2.new(0, 0, 0, 6)
        marker.Size = UDim2.new(0, 2, 1, -12)
        marker.Visible = selected[option] == true
        table.insert(optionButtons, {
            Option = option,
            Button = optionButton,
            Marker = marker
        })

        self.library:_DecorateObject(optionButton)
        optionButton.SelectionGained:Connect(function()
            if activeIndex ~= index then focusOption(index) end
        end)
        optionButton.MouseEnter:Connect(function()
            setOptionHighlight(activeIndex, index)
        end)
        optionButton.MouseLeave:Connect(function()
            if hoveredIndex == index then setOptionHighlight(activeIndex, nil) end
        end)
        bindActivation(self.library, optionButton, function() chooseOption(option) end)
    end

    local function filterOptions()
        table.clear(visibleIndices)
        local query = string.lower(search.Text)
        for index, item in ipairs(optionButtons) do
            item.Button.Visible = string.find(string.lower(tostring(item.Option)), query, 1, true) ~= nil
            if item.Button.Visible then table.insert(visibleIndices, index) end
        end
        emptyMessage.Visible = #visibleIndices == 0
        emptyMessage.Text = #options == 0 and "No options available" or "No results"
        local totalHeight = #visibleIndices * optionHeight
        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, totalHeight)
        scrollFrame.CanvasPosition = Vector2.new(0, 0)
        focusOption(activeIndex, true)
    end
    search:GetPropertyChangedSignal("Text"):Connect(function()
        if isOpen then filterOptions() end
    end)
    search.FocusLost:Connect(function(enterPressed)
        if isOpen and enterPressed and activeIndex and optionButtons[activeIndex] then
            chooseOption(optionButtons[activeIndex].Option)
            if isOpen then focusOption(activeIndex) end
        end
    end)
    local function bulkSelect(clear)
        if clear then
            if #selectionOrder > 0 then setSelected({}) end
        else
            for _, option in ipairs(options) do
                if not selected[option] then setSelected(options); break end
            end
        end
    end
    if multiSelect then
        bindActivation(self.library, bulkButtons[1], function() bulkSelect(false) end)
        bindActivation(self.library, bulkButtons[2], function() bulkSelect(true) end)
    end

    local function rebuildOptionButtons()
        local selectedObject = GuiService.SelectedObject
        local hadOptionFocus = selectedObject and selectedObject:IsDescendantOf(scrollFrame)
        for _, item in ipairs(optionButtons) do
            item.Button:Destroy()
        end
        table.clear(optionButtons)
        activeIndex, hoveredIndex = nil, nil

        for index, option in ipairs(options) do
            createOptionButton(option, index)
        end

        -- Keep the search field stationary while the option list is filtered.
        dropdownHeight = math.min(math.max(#options, 1) * optionHeight, 150) + headerHeight + footerHeight
        if isOpen then placeDropdown() end
        filterOptions()
        if isOpen and hadOptionFocus then focusOption(activeIndex) end
    end

    local function setOptions(newOptions, noCallback)
        local previousSelection = getSelectedTable()
        options, optionSet = normalizeOptions(newOptions)

        replaceSelection(previousSelection)

        rebuildOptionButtons()

        -- Filtering preserves order, so only a shorter selection can have changed.
        local selectionChanged = #previousSelection ~= #selectionOrder

        if selectionChanged then updateDisplay(noCallback) else renderSelection() end
    end

    rebuildOptionButtons()

    outsideButton.Activated:Connect(closeDropdown)

    local function openDropdown()
        if isOpen then return end
        if self.library._cancelKeybind then self.library._cancelKeybind() end
        if self.library._closeDropdown then self.library._closeDropdown() end
        self.library._closeDropdown = closeDropdown
        isOpen = true
        search.Text = ""
        filterOptions()
        table.insert(placeConnections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if not isOpen or not isVisible(self.library, dropdown) then return end
            local key = input.KeyCode
            if isPointerPress(input) then
                -- The overlay handles clicks inside the window.
                local x, y = input.Position.X, input.Position.Y
                local main = self.library.MainFrame
                local position, size = main.AbsolutePosition, main.AbsoluteSize
                if x < position.X or x >= position.X + size.X or y < position.Y or y >= position.Y + size.Y then
                    closeDropdown()
                end
                return
            end
            local focused = UserInputService:GetFocusedTextBox()
            local selectedObject = GuiService.SelectedObject
            if focused ~= search and (focused or not selectedObject
                or not selectedObject:IsDescendantOf(dropdown) or not isVisible(self.library, selectedObject)) then return end
            self.library._capturedInput = input
            if key == Enum.KeyCode.Escape and focused == search then
                search:ReleaseFocus()
                focusOption(activeIndex)
                return
            end
            if key == Enum.KeyCode.Escape or key == Enum.KeyCode.ButtonB then closeDropdown(); return end
            if key == Enum.KeyCode.Tab then
                local targets = {search}
                if activeIndex then table.insert(targets, optionButtons[activeIndex].Button) end
                for _, bulk in ipairs(bulkButtons) do table.insert(targets, bulk) end
                stepFocus(targets, focusDirection(), focused)
                return
            end
            if gameProcessed and focused ~= search then return end
            if multiSelect and not focused and key == Enum.KeyCode.A
                and (UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)) then
                bulkSelect(UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift))
            elseif key == Enum.KeyCode.Down or key == Enum.KeyCode.DPadDown then
                local index = table.find(visibleIndices, activeIndex) or 0
                focusOption(visibleIndices[math.min(#visibleIndices, index + 1)])
            elseif key == Enum.KeyCode.Up or key == Enum.KeyCode.DPadUp then
                local index = table.find(visibleIndices, activeIndex) or (#visibleIndices + 1)
                focusOption(visibleIndices[math.max(1, index - 1)])
            elseif key == Enum.KeyCode.Home then
                focusOption(visibleIndices[1])
            elseif key == Enum.KeyCode.End then
                focusOption(visibleIndices[#visibleIndices])
            elseif (key == Enum.KeyCode.Return or key == Enum.KeyCode.KeypadEnter or key == Enum.KeyCode.Space) and not focused then
                if selectedObject == search then
                    search:CaptureFocus()
                elseif table.find(bulkButtons, selectedObject) then
                    bulkSelect(selectedObject == bulkButtons[2])
                elseif activeIndex then
                    chooseOption(optionButtons[activeIndex].Option)
                end
            end
        end))
        placeDropdown()
        if not isOpen then return end
        overlay.Visible = true
        dropdown.Visible = true
        focusOption(table.find(options, selectionOrder[1]) or visibleIndices[1])
        arrow.Text = "^"
        arrow.TextColor3 = Theme.Accent
        setActiveFeedback(true)
        -- keep the list pinned to the button as it moves (scrolling the content,
        -- dragging the window, resizing) instead of leaving it where it opened.
        table.insert(placeConnections, button:GetPropertyChangedSignal("AbsolutePosition"):Connect(placeDropdown))
        table.insert(placeConnections, button:GetPropertyChangedSignal("AbsoluteSize"):Connect(placeDropdown))
        table.insert(placeConnections, self.library.MainFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(placeDropdown))
    end

    bindActivation(self.library, button, function()
        if isOpen then
            closeDropdown()
        else
            openDropdown()
        end
    end)

    renderSelection()

    local element = Element.new(self, frame, {
        Type = "Dropdown",
        Flag = flag,
        GetValue = getValue,
        SetValue = setSelected,
        GetOptions = function()
            return table.clone(options)
        end,
        SetOptions = setOptions,
        Cleanup = function()
            overlay:Destroy()
        end,
        OnHide = function()
            closeDropdown()
            resetFeedback()
        end
    })
    self:_BindFlag(flag, element)

    if flag and self.library.loadedFlags[flag] ~= nil and args.CallOnLoad ~= false and callback then
        dispatchCallback(self, frame, callback, getValue())
    end

    return element
end
