--[[
  @author bfut
  @version 1.2
  @description bfut_Paste item from clipboard to selected items (replace)
  @about
    HOW TO USE:
      1) Select media item.
      2) Run script "bfut_Copy item to clipboard".
      3) Select other media item(s).
      4) Run script "bfut_Paste item from clipboard to selected items (replace)".
    REQUIRES: Reaper v6.04 or later, SWS v2.11.0.0 or later
  @changelog
    + native pooled (ghost) MIDI item behavior
    + Fix: replace FXIDs in replaced items
    Requires SWS v2.11.0.0 or later
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
local COUNT_SEL_ITEMS = reaper.CountSelectedMediaItems(0)
if COUNT_SEL_ITEMS < 1 then
  return
end
if not reaper.APIExists("CF_GetClipboard") then
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
local POOL_MIDI = CONFIG["always_pool_midi"] or (reaper.GetToggleCommandState(41071) == 1)
local buf = reaper.CF_GetClipboard("")
if not buf or buf:find('<ITEM', 0, true) ~= 1 then
  return
end
reaper.Undo_BeginBlock2(0)
reaper.PreventUIRefresh(1)
for i = 0, COUNT_SEL_ITEMS - 1 do
  item = reaper.GetSelectedMediaItem(0, i)
  if not IS_ITEM_LOCKED[reaper.GetMediaItemInfo_Value(item, "C_LOCK")] then
    local retval, old_item_chunk = reaper.GetItemStateChunk(item, "", false)
    if retval then
      local new_item_chunk = buf
      for _, key in ipairs({"POSITION", "LENGTH", "MUTE", "SEL", "IID"}) do
        new_item_chunk = bfut_GetSetItemChunkValue(
          new_item_chunk,
          key,
          bfut_GetSetItemChunkValue(old_item_chunk, key, "", false),
          true
        )
      end
      new_item_chunk = bfut_GetSetItemChunkValue(
        new_item_chunk,
        "LOCK",
        RPPXML_LOCK[bfut_GetSetItemChunkValue(new_item_chunk, "LOCK", "", false) or "1"],
        true
      )
      new_item_chunk = bfut_GetSetItemChunkValue(new_item_chunk, "IGUID", reaper.genGuid(""), true)
      new_item_chunk = bfut_ResetAllChunkGuids(new_item_chunk, "GUID")
      new_item_chunk = bfut_ResetAllChunkGuids(new_item_chunk, "FXID")
      if not POOL_MIDI then
        new_item_chunk = bfut_ResetAllChunkGuids(new_item_chunk, "POOLEDEVTS")
      end
      if not reaper.SetItemStateChunk(item, new_item_chunk, true) then
        reaper.ShowConsoleMsg(string.format("%s SetItemStateChunk(selected item) has failed.\n", i))
      end
    end
  end
end
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()
reaper.Undo_EndBlock2(0, "bfut_Paste item from clipboard to selected items (replace)", -1)