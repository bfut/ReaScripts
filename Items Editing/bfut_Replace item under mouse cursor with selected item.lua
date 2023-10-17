--[[
  @author bfut
  @version 1.3
  @description bfut_Replace item under mouse cursor with selected item
  @about
    HOW TO USE:
      1) Select media item.
      2) Hover mouse over another item.
      3) Run the script.
  @changelog
    REQUIRES: Reaper v7.00 or later
    + add support for item lanes / free item position: preserve position of item under mouse
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
local SCREEN_X, SCREEN_Y = reaper.GetMousePosition()
local TARGET_ITEM = reaper.GetItemFromPoint(SCREEN_X, SCREEN_Y, true)
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
local TARGET_ITEMF_FREEMODE_Y = reaper.GetMediaItemInfo_Value(TARGET_ITEM, "F_FREEMODE_Y")
local TARGET_ITEMF_FREEMODE_H = reaper.GetMediaItemInfo_Value(TARGET_ITEM, "F_FREEMODE_H")
local TARGET_ITEMI_FIXEDLANE = reaper.GetMediaItemInfo_Value(TARGET_ITEM, "I_FIXEDLANE")
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
if reaper.SetItemStateChunk(TARGET_ITEM, src_item_chunk, true) then
  local freemode = reaper.GetMediaTrackInfo_Value(reaper.GetMediaItem_Track(TARGET_ITEM), "I_FREEMODE")
  if freemode == 1 then
    reaper.SetMediaItemInfo_Value(TARGET_ITEM, "F_FREEMODE_Y", TARGET_ITEMF_FREEMODE_Y)
    reaper.SetMediaItemInfo_Value(TARGET_ITEM, "F_FREEMODE_H", TARGET_ITEMF_FREEMODE_H)
  elseif freemode == 2 then
    reaper.SetMediaItemInfo_Value(TARGET_ITEM, "I_FIXEDLANE", TARGET_ITEMI_FIXEDLANE)
  end
else
  reaper.ShowConsoleMsg("SetItemStateChunk(selected item) has failed.\n")
end
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()
reaper.Undo_EndBlock2(0, "bfut_Replace item under mouse cursor with selected item", -1)