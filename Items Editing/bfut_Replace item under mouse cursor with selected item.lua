--[[
  @author bfut
  @version 1.2
  @description bfut_Replace item under mouse cursor with selected item
  @about
    HOW TO USE:
      1) Select media item.
      2) Hover mouse over another item.
      3) Run the script.
    REQUIRES: Reaper v6.04 or later, SWS v2.11.0.0 or later
  @changelog
    + native pooled (ghost) MIDI item behavior
    + Fix: replace FXIDs in replaced item
  @website https://github.com/bfut
  LICENSE:
    Copyright (C) 2018 and later Benjamin Futasz

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.
]]
--[[ CONFIG defaults:
  always_pool_midi =
    false  -- factory default
    true  -- ignore Options: Toggle pooled (ghost) MIDI source data when copying media items
]]
local CONFIG = {
  always_pool_midi = false
}
local function bfut_GetSetItemChunkValue(item_chunk, key, param, set)
  if set then
    if item_chunk:match('('..key..')') then
      return item_chunk:gsub('%s'..key..'%s+.-[\r]-[%\n]', "\n"..key.." "..param.."\n", 1), true
    else
      return item_chunk:gsub('<ITEM[\r]-[%\n]', "<ITEM\n"..key.." "..param.."\n", 1), true
    end
  else
    if item_chunk:match('('..key..')') then
      return item_chunk:match('%s'..key..'%s+(.-)[\r]-[%\n]'), true
    else
      return nil, false
    end
  end
end
local function bfut_ResetAllChunkGuids(item_chunk, key)
  while item_chunk:match('%s('..key..')') do
    item_chunk = item_chunk:gsub('%s('..key..')%s+.-[\r]-[%\n]', "\ntemp%1 "..reaper.genGuid("").."\n", 1)
  end
  return item_chunk:gsub('temp'..key, key), true
end
if not reaper.APIExists("BR_GetMouseCursorContext_Item") then
  reaper.ReaScriptError("Requires extension, SWS v2.11.0.0 or later.\n")
  return
end
local RPPXML_LOCK = {
  ["1"] = 0,
  ["2"] = 2,
  ["3"] = 2
}
local IS_ITEM_LOCKED = {
    [1.0] = true,
    [3.0] = true
}
local SRC_ITEM = reaper.GetSelectedMediaItem(0, 0)
if not SRC_ITEM then
  return
end
reaper.BR_GetMouseCursorContext()
local TARGET_ITEM = reaper.BR_GetMouseCursorContext_Item()
if not TARGET_ITEM or TARGET_ITEM == SRC_ITEM then
  return
end
if IS_ITEM_LOCKED[reaper.GetMediaItemInfo_Value(TARGET_ITEM, "C_LOCK")] then
  return
end
local retval, old_item_chunk = reaper.GetItemStateChunk(TARGET_ITEM, "", false)
if not retval then
  return
end
local retval, src_item_chunk = reaper.GetItemStateChunk(SRC_ITEM, "", false)
if not retval then
  return
end
for _, key in ipairs({"POSITION", "LENGTH", "MUTE", "SEL", "IID"}) do
  src_item_chunk = bfut_GetSetItemChunkValue(
    src_item_chunk,
    key,
    bfut_GetSetItemChunkValue(old_item_chunk, key, "", false),
    true
  )
end
src_item_chunk = bfut_GetSetItemChunkValue(
  src_item_chunk,
  "LOCK",
  RPPXML_LOCK[bfut_GetSetItemChunkValue(src_item_chunk, "LOCK", "", false) or "1"],
  true
)
src_item_chunk = bfut_GetSetItemChunkValue(src_item_chunk, "IGUID", reaper.genGuid(""), true)
src_item_chunk = bfut_ResetAllChunkGuids(src_item_chunk, "GUID")
src_item_chunk = bfut_ResetAllChunkGuids(src_item_chunk, "FXID")
if not CONFIG["always_pool_midi"] and (reaper.GetToggleCommandState(41071) ~= 1) then
  src_item_chunk = bfut_ResetAllChunkGuids(src_item_chunk, "POOLEDEVTS")
end
reaper.Undo_BeginBlock2(0)
reaper.PreventUIRefresh(1)
if not reaper.SetItemStateChunk(TARGET_ITEM, src_item_chunk, true) then
  reaper.ShowConsoleMsg("SetItemStateChunk(selected item) has failed.\n")
end
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()
reaper.Undo_EndBlock2(0, "bfut_Replace item under mouse cursor with selected item", -1)