--[[
  @author bfut
  @version 1.0
  DESCRIPTION: bfut_Copy items to project markers, remove overlaps
  REQUIRES: Reaper v5.70 or later
  LICENSE:
    Copyright (c) 2017 and later Benjamin Futasz <bendfu@gmail.com><https://github.com/bfut>
    
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
local reaper = reaper
reaper.Undo_BeginBlock2(0)
local gl_num_items = reaper.CountSelectedMediaItems(0)
if gl_num_items < 1 then
  return
end
local _, gl_num_markers = reaper.CountProjectMarkers(0)
if gl_num_markers < 1 then
  return
end
reaper.PreventUIRefresh(1)
local gl_timesel_start
local gl_timesel_len
local gl_envelope_points
reaper.Main_OnCommandEx(40630,0)
gl_timesel_start = reaper.GetCursorPosition(0)
reaper.Main_OnCommandEx(40631,0)
gl_timesel_len = reaper.GetCursorPosition(0)-gl_timesel_start
gl_envelope_points = reaper.GetToggleCommandState(40070)
if gl_envelope_points == 1 then
  reaper.Main_OnCommandEx(40070,0)
end
reaper.GoToMarker(0,1,true)
reaper.Main_OnCommandEx(40698,0)
reaper.Main_OnCommandEx(40058,0)
reaper.Main_OnCommandEx(40626,0)
local gl_num_grouped_items = 0
local gl_grouping={}
for j=0,gl_num_items-1 do
  local groupid = reaper.GetMediaItemInfo_Value(reaper.GetSelectedMediaItem(0,j),"I_GROUPID")
  if groupid > 0.0 then
    gl_grouping[j] = groupid
    gl_num_grouped_items = gl_num_grouped_items+1
  else
    reaper.SetMediaItemInfo_Value(reaper.GetSelectedMediaItem(0,j),"I_GROUPID",-1)
  end
end
local function PasteItemsWithGroups(gl_num_grouped_items)
  for i=2,gl_num_markers do
    reaper.GoToMarker(0,i,true)
    reaper.Main_OnCommandEx(40625,0)
    reaper.Main_OnCommandEx(40312,0)
    reaper.Main_OnCommandEx(40058,0)
    reaper.Main_OnCommandEx(40626,0)
    for j=0,gl_num_items-1 do
      if gl_grouping[j] == nil then
        reaper.SetMediaItemInfo_Value(reaper.GetSelectedMediaItem(0,j),"I_GROUPID",-1)
      else
        reaper.SetMediaItemInfo_Value(reaper.GetSelectedMediaItem(0,j),"I_GROUPID",gl_grouping[j])
      end
    end
  end
  gl_grouping = nil
  reaper.Main_OnCommandEx(40034,0)
  for j=0,reaper.CountSelectedMediaItems(0)-1 do
    if reaper.GetMediaItemInfo_Value(reaper.GetSelectedMediaItem(0,j),"I_GROUPID") == -1 then
      reaper.SetMediaItemInfo_Value(reaper.GetSelectedMediaItem(0,j),"I_GROUPID",0.0)
    end
  end
end
local function PasteItemsNoGroups()
  reaper.Main_OnCommandEx(40033,0)
  reaper.Main_OnCommandEx(40032,0)
  local gl_pasted_items_start
  local gl_first_item
  reaper.Main_OnCommandEx(41173,0)
  gl_pasted_items_start = reaper.GetCursorPosition(0)
  local k=0
  while reaper.GetMediaItemInfo_Value(reaper.GetSelectedMediaItem(0,k), "D_POSITION")-gl_pasted_items_start > 0 do
    k=k+1
  end
  gl_first_item = reaper.GetSelectedMediaItem(0,k)
  for i=2,gl_num_markers do
    reaper.GoToMarker(0,i,true)
    reaper.Main_OnCommandEx(40625,0)
    reaper.Main_OnCommandEx(40312,0)
    reaper.Main_OnCommandEx(40058,0)
    reaper.Main_OnCommandEx(40626,0)
    reaper.SetMediaItemSelected(gl_first_item, true)
    reaper.Main_OnCommandEx(40034,0)
    reaper.Main_OnCommandEx(40032,0)
  end
  reaper.Main_OnCommandEx(40033,0)
end
if gl_num_grouped_items > 0 then
  PasteItemsWithGroups(gl_num_grouped_items)
else
  gl_grouping = nil
  PasteItemsNoGroups()
end
reaper.Main_OnCommandEx(40635,0)
reaper.MoveEditCursor(gl_timesel_start-reaper.GetCursorPosition(0), false)
reaper.MoveEditCursor(gl_timesel_len, true)
reaper.Main_OnCommandEx(41174,0)
if gl_envelope_points == 1 then
  reaper.Main_OnCommandEx(40070,0)
end
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()
reaper.Undo_EndBlock2(0,"bfut_Copy items to project markers, remove overlaps",-1)