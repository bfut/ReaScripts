--[[
  @author bfut
  @version 1.1
  DESCRIPTION: bfut_Copy item to clipboard
  HOW TO USE:
    1) Select media item.
    2) Run script "bfut_Copy item to clipboard".
    3) Select other media item(s).
    4) Run script "bfut_Paste item from clipboard to selected items (replace)".
  REQUIRES: Reaper v5.980 or later, SWS v2.10.0.1 or later
  LICENSE: Public Domain
]]
local reaper = reaper
if reaper.CountSelectedMediaItems(0) < 1 then
  return
end
local function_name ="CF_SetClipboard"
if not reaper.APIExists(function_name) then
  reaper.ReaScriptError("Requires extension, SWS v2.10.0.1 or later.\n")
  return
end
local _,item_chunk = reaper.GetItemStateChunk(reaper.GetSelectedMediaItem(0,0),"",false)
if not _ or item_chunk == nil then
  return
end
reaper.CF_SetClipboard(item_chunk)
