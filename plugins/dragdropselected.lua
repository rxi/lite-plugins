--[[
  dragdropselected.lua
  provides basic drag and drop of selected text (in same document)
  - LMB+drag selected text to move it elsewhere
  - or LMB on selection and then LMB at destination (if sticky is enabled)
  - hold ctrl on release to copy selection
  - press escape to abort
  version: 20230616_094245 by SwissalpS
  original: 20200627_133351 by SwissalpS

  TODO: add dragging image
  TODO: use OS drag and drop events
  TODO: change mouse cursor when duplicating (requires change in cpp/SDL2)
--]]
local core = require "core"
local style = require "core.style"
local common = require "core.common"
local config = require "core.config"
local DocView = require "core.docview"
local keymap = require "core.keymap"
local command = require "core.command"

local dnd = {}

if not config.dragdropselected then
  config.dragdropselected = {
    enabled = true,
    useSticky = false
  }
end


-- helper function to determine if mouse is in selection
-- iLine is line number where mouse is
-- iCol is column where mouse is
-- iLine1 is line number where selection starts
-- iCol1 is column where selection starts
-- iLine2 is line number where selection ends
-- iCol2 is column where selection ends
function dnd.isInSelection(iLine, iCol, iLine1, iCol1, iLine2, iCol2)
  if iLine < iLine1 then return false end
  if iLine > iLine2 then return false end
  if (iLine == iLine1) and (iCol < iCol1) then return false end
  if (iLine == iLine2) and (iCol > iCol2) then return false end
  return true
end -- dnd.isInSelection


function DocView:dnd_collectSelection()
  self.dnd_lSelection = nil
  local iLine1, iCol1, iLine2, iCol2, bSwap = self.doc:get_selection(true)
  -- skip empty selection (jic Doc didn't skip them)
  if iLine1 ~= iLine2 or iCol1 ~= iCol2 then
    self.dnd_lSelection = { iLine1, iCol1, iLine2, iCol2, bSwap }
  end
  return self.dnd_lSelection
end -- DocView:dnd_collectSelection


function dnd.getSelectedText(doc)
  local iLine1, iCol1, iLine2, iCol2, bSwap = doc:get_selection(true)
  -- skip empty markers
  if iLine1 ~= iLine2 or iCol1 ~= iCol2 then
    return doc:get_text(iLine1, iCol1, iLine2, iCol2)
  end

  return ''
end -- dnd.getSelectedText


-- checks whether given coordinates are in the selection
-- iLine, iCol are position of mouse
-- bDuplicating triggers 'exclusive' check making checked area smaller
function DocView:dnd_isInSelection(iX, iY, bDuplicating)
  self.dnd_lSelection = self.dnd_lSelection or self:dnd_collectSelection()
  if not self.dnd_lSelection then return nil end

  local iLine, iCol = self:resolve_screen_position(iX, iY)
  if config.dragdropselected.useSticky and not self.dnd_bDragging then
    -- allow user to clear selection in sticky mode by clicking in empty area
    -- to the right of selection
    local iX2 = self:get_line_screen_position(iLine, #self.doc.lines[iLine])
    -- this does not exactly corespond with the graphical selected area
    -- it means selection can't be grabbed by the "\n" at the end
    if iX2 < iX then return nil end
  end

  local iLine1, iCol1, iLine2, iCol2, bSwap
  iLine1, iCol1, iLine2, iCol2, bSwap = table.unpack(self.dnd_lSelection)
  if bDuplicating then
    -- adjust boundries for duplication actions
    -- this allows users to duplicate selection adjacent to selection
    iCol1 = iCol1 + 1
    if #self.doc.lines[iLine1] < iCol1 then
      iCol1 = 1
      iLine1 = iLine1 + 1
    end
    iCol2 = iCol2 - 1
    if 0 == iCol2 then
      iLine2 = iLine2 - 1
      iCol2 = #self.doc.lines[iLine2]
    end
  end -- if duplicating

  if dnd.isInSelection(iLine, iCol, iLine1, iCol1, iLine2, iCol2) then
    return self.dnd_lSelection
  end
  return nil
end -- DocView:dnd_isInSelection


-- restore selection that existed when DnD was initiated
function DocView:dnd_setSelection()
  if not self.dnd_lSelection then
    return
  end
  self.doc:set_selection(table.unpack(self.dnd_lSelection))
end -- DocView:dnd_setSelections


-- unset stashes and flag, reset cursor
-- helper for on_mouse_released and
-- when escape is pressed during drag (or not, not worth checking)
function dnd.reset(oDocView)
  if not oDocView then
    oDocView = core.active_view
    if not oDocView:is(DocView) then return end
  end

  if nil ~= oDocView.dnd_bBlink then
    config.disable_blink = oDocView.dnd_bBlink
  end
  oDocView.dnd_lSelection = nil
  oDocView.dnd_bDragging = nil
  oDocView.dnd_bBlink = nil
  oDocView.cursor = 'ibeam'
  oDocView.dnd_sText = nil
end -- dnd.reset


local on_mouse_moved = DocView.on_mouse_moved
function DocView:on_mouse_moved(x, y, ...)
  if not config.dragdropselected.enabled or not self.dnd_sText then
    -- there is nothing to do -> hand off to original on_mouse_moved()
    return on_mouse_moved(self, x, y, ...)
  end

  -- not sure we need to do this or if we better not
  DocView.super.on_mouse_moved(self, x, y, ...)

  if self.dnd_bDragging then
    -- remove last caret showing insert location
    --self.doc:remove_selection(self.doc.last_selection)
  else
    self.dnd_bDragging = true
    -- show that we are dragging something
    self.cursor = 'hand'
    -- make sure selection is marked
    self:dnd_setSelection()
  end
  -- calculate line and column for current mouse position
  local iLine, iCol = self:resolve_screen_position(x, y)
  -- TODO: show insert location
  --self.doc:add_selection(iLine, iCol)
  -- update scroll position, if needed
  self:scroll_to_line(iLine, true)
  return true
end -- DocView:on_mouse_moved


local on_mouse_pressed = DocView.on_mouse_pressed
function DocView:on_mouse_pressed(button, x, y, clicks)
  local caught = DocView.super.on_mouse_pressed(self, button, x, y, clicks)
  if caught then
      return caught
  end

  -- sticky mode support
  if self.dnd_bDragging then
    return true
  end

  -- no need to proceed if: not enabled, not left button, no selection
  -- or if this is a multi-click event
  if not config.dragdropselected.enabled
    or 'left' ~= button
    or 1 < clicks
    or not self:dnd_isInSelection(x, y)
  then
    dnd.reset(self)
    -- let 'old' on_mouse_pressed() do whatever it needs to do
    return on_mouse_pressed(self, button, x, y, clicks)
  end

  -- stash selection for inserting later
  self.dnd_sText = dnd.getSelectedText(self.doc)
  -- disable blinking caret and stash user setting
  self.dnd_bBlink = config.disable_blink
  config.disable_blink = true
  return true
end -- DocView:on_mouse_pressed


local on_mouse_released = DocView.on_mouse_released
function DocView:on_mouse_released(button, x, y)
  -- for some reason, lite triggers two on_mouse_released events
  -- one seems to be the suggestion box, we debounce that here
  if self.state and self.suggestions then
    return on_mouse_released(self, button, x, y)
  end
  -- nothing to do if: not enabled or never clicked into selection
  if not config.dragdropselected.enabled or not self.dnd_sText then
    return on_mouse_released(self, button, x, y)
  end

  local iLine, iCol = self:resolve_screen_position(x, y)
  if not self.dnd_sText then--bDragging then
    if not config.dragdropselected.useSticky then
      -- not using sticky -> clear selection
      self.doc:set_selection(iLine, iCol)
      dnd.reset(self)
    end
    return on_mouse_released(self, button, x, y)
  end

  local bDuplicating = keymap.modkeys['ctrl']
  if self:dnd_isInSelection(x, y, bDuplicating) then
    -- drag aborted by releasing mouse inside selection
    --self.doc:remove_selection(self.doc.last_selection)
    --self.doc:set_selection(iLine, iCol)
  else
    -- do some calculations for selecting inserted text
    local iAdditionalLines, sLast = -1, ''
    for s in (self.dnd_sText .. "\n"):gmatch("(.-)\n") do
      iAdditionalLines = iAdditionalLines + 1
      sLast = s
    end
    local iLastLength = #sLast
    -- have doc handle selection updates
    self.doc:insert(iLine, iCol, self.dnd_sText)
    -- add a marker so we know where to start selecting pasted text
    --self.doc:add_selection(iLine, iCol)
    if not bDuplicating then
      self.doc:delete_to(0)
    end
    -- get new location of inserted text
    --iLine, iCol = self.doc:get_selection_idx(self.doc.last_selection, true)
    local iLine2, iCol2 = iLine + iAdditionalLines
    if iLine == iLine2 then
      iCol2 = iCol + iLastLength
    else
      iCol2 = iLastLength + 1
    end
    -- finally select inserted text
    self.doc:set_selection(iLine, iCol, iLine2, iCol2)
  end
  -- unset stashes and flag
  dnd.reset(self)
  return on_mouse_released(self, button, x, y)
end -- DocView:on_mouse_released

--[[
local draw_caret = DocView.draw_caret
function DocView:draw_caret(x, y)
  if self.dnd_sText and config.dragdropselected.enabled then
    -- don't show carets inside selections
    if self:dnd_isInSelection(x, y, true) then
      return
    end
  end
  return draw_caret(self, x, y)
end -- DocView:draw_caret()
--]]

-- disable text_input during drag operations
local on_text_input = DocView.on_text_input
function DocView:on_text_input(text)
  if self.dnd_bDragging then
    return true
  end
  return on_text_input(self, text)
end -- DocView:on_text_input


function dnd.abort(oDocView)
  if not config.dragdropselected.enabled then return end

  oDocView = oDocView or core.active_view
  if oDocView.dnd_bDragging then
    oDocView:dnd_setSelection()
  end
  dnd.reset(oDocView)
end -- dnd.abort


function dnd.predicate()
  if not config.dragdropselected.enabled
    or not core.active_view:is(DocView)
    or not core.active_view.dnd_bDragging
  then return false end

  return true, core.active_view
end -- dnd.predicate


function dnd.toggleEnabled()
  config.dragdropselected.enabled = not config.dragdropselected.enabled
  core.status_view:show_message('i', style.text, 'Drag n\' Drop is '
      .. (config.dragdropselected.enabled and 'en' or 'dis') .. 'abled')
end


function dnd.toggleSticky()
  config.dragdropselected.useSticky = not config.dragdropselected.useSticky
  core.status_view:show_message('i', style.text, 'Sticky mode is '
      .. (config.dragdropselected.useSticky and 'en' or 'dis') .. 'abled')
end

command.add('core.docview', {
  ['dragdropselected:toggleEnabled'] = dnd.toggleEnabled,
  ['dragdropselected:toggleSticky'] =  dnd.toggleSticky
})
command.add(dnd.predicate, { ['dragdropselected:abort'] = dnd.abort })
keymap.add({ ['escape'] = 'dragdropselected:abort' })


return dnd

