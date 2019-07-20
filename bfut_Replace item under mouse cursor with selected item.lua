--[[
  @author bfut
  @version 1.1
  DESCRIPTION: bfut_Replace item under mouse cursor with selected item
  HOW TO USE:
    1) Select media item.
    2) Hover mouse over another item.
    3) Run the script.
  REQUIRES: Reaper v5.980 or later, SWS v2.10.0.1 or later
  LICENSE:
    Copyright (c) 2018 and later Benjamin Futasz <bendfu@gmail.com><https://github.com/bfut>
    
    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:
    
    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.
    
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
]]
--[[ config defaults:
  pool_midi = true
  
  allowed values: Boolean
]]
local config = {
  pool_midi = true 
}
local reaper = reaper
local type = type
local ipairs = ipairs
local function bfut_GetSetItemChunkValue2(s,key,param,set)
  if type(s) ~= "string" then reaper.ReaScriptError("bfut_GetSetItemChunkValue2: string expected (arg 1)") return s,false end
  if type(key) ~= "string" then reaper.ReaScriptError("bfut_GetSetItemChunkValue2: string expected (arg 2)") return s,false end
  if type(param) ~= "string" and type(param) ~= "number" then reaper.ReaScriptError("bfut_GetSetItemChunkValue2: string expected (arg 3)") return s,false end
  if type(set) ~= "boolean" then reaper.ReaScriptError("bfut_GetSetItemChunkValue2: boolean expected (arg 4)") return s,false end
  if set then
    if s:match('('..key..')') ~= nil then
      return s:gsub('%s'..key..'%s+.-[\r]-[%\n]',"\n"..key.." "..param.."\n",1),true
    else
      return s:gsub('<ITEM[\r]-[%\n]',"<ITEM\n"..key.." "..param.."\n",1),true
    end
  else
    if s:match('('..key..')') ~= nil then
      return s:match('%s'..key..'%s+(.-)[\r]-[%\n]'),true
    else
      return nil,false
    end
  end
end
local function bfut_ResetAllChunkGuids(s,key)
  if type(s) ~= "string" then reaper.ReaScriptError("bfut_ResetAllChunkGuids: string expected (arg 1)") return s,false end
  if type(key) ~= "string" or type(key) == "number" then reaper.ReaScriptError("bfut_ResetAllChunkGuids: string expected (arg 2)") return s,false end
  while s:match('%s('..key..')') ~= nil do
    s = s:gsub('%s('..key..')%s+.-[\r]-[%\n]',"\ntemp%1 "..reaper.genGuid("").."\n",1)
  end
  return s:gsub('temp'..key,key),true
end
local RPPXML_LOCK = {
  ["1"] = 0,
  ["2"] = 2,
  ["3"] = 2,
}
if reaper.CountSelectedMediaItems(0) < 1 then
  return
end
if type(config["pool_midi"]) ~= "boolean" then
  reaper.ReaScriptError("config[pool_midi] must be Boolean.\n")
  return
end
for _,function_name in ipairs({"BR_GetMouseCursorContext","BR_GetMouseCursorContext_Item"}) do
  if not reaper.APIExists(function_name) then
    reaper.ReaScriptError("Requires extension, SWS v2.10.0.1 or later.\n")
    return
  end
end
reaper.BR_GetMouseCursorContext()
local item = reaper.BR_GetMouseCursorContext_Item()
if item == nil or item == reaper.GetSelectedMediaItem(0,0) then
  return
end
local locked = reaper.GetMediaItemInfo_Value(item,"C_LOCK")
if locked ~= 0.0 and locked ~= 2.0 then
  return
end
local _,item_chunk = reaper.GetItemStateChunk(item,"",false)
if not _ or item_chunk == nil then
  reaper.ShowConsoleMsg("err: GetItemStateChunk(item) has failed.\n")
  return
end
local _,src_item_chunk = reaper.GetItemStateChunk(reaper.GetSelectedMediaItem(0,0), "", false)
if not _ or src_item_chunk == nil then
  reaper.ShowConsoleMsg("err: GetItemStateChunk(source item) has failed.\n")
  return
end
for _,key in ipairs({"POSITION","LENGTH","MUTE","SEL","IID"}) do
  src_item_chunk = bfut_GetSetItemChunkValue2(
    src_item_chunk,
    key,
    bfut_GetSetItemChunkValue2(item_chunk,key,"",false),
    true
  )
end
src_item_chunk = bfut_GetSetItemChunkValue2(
  src_item_chunk,"LOCK",
  RPPXML_LOCK[bfut_GetSetItemChunkValue2(src_item_chunk,"LOCK","",false) or "1"],
  true
)
src_item_chunk = bfut_GetSetItemChunkValue2(src_item_chunk,"IGUID",reaper.genGuid(""),true)
src_item_chunk = bfut_ResetAllChunkGuids(src_item_chunk,"GUID")
if not config["pool_midi"] then
  src_item_chunk = bfut_ResetAllChunkGuids(src_item_chunk,"POOLEDEVTS")
end
reaper.Undo_BeginBlock2(0)
reaper.PreventUIRefresh(1)
if not reaper.SetItemStateChunk(item,src_item_chunk,true) then
  reaper.SetItemStateChunk(item,item_chunk,false)
  reaper.ShowConsoleMsg("err: SetItemStateChunk() has failed.\n")
end
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()
reaper.Undo_EndBlock2(0,"bfut_Replace item under mouse cursor with selected item",-1)
