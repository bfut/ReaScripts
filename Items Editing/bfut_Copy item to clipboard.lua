--[[
  @author bfut
  @version 1.0
  DESCRIPTION: bfut_Copy item to clipboard
  HOW TO USE:
    1) Select media item.
    2) Run script "bfut_Copy item to clipboard".
    3) Select other media item(s).
    4) Run script "bfut_Paste item from clipboard to selected items (replace)".
  REQUIRES: Reaper v5.95 or later, SWS v2.9.7 or later
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
local reaper = reaper
if reaper.CountSelectedMediaItems(0) < 1 then
  return
end
local function_name ="CF_SetClipboard"
if not reaper.APIExists(function_name) then
  reaper.ReaScriptError("Requires extension, SWS v2.9.7 or later.\n")
  return
end
local _,item_chunk = reaper.GetItemStateChunk(reaper.GetSelectedMediaItem(0,0),"",false)
if not _ or item_chunk == nil then
  return
end
reaper.CF_SetClipboard(item_chunk)