--[[
  @author bfut
  @version 1.2
  @description bfut_Copy item to clipboard
  @about
    HOW TO USE:
      1) Select media item.
      2) Run script "bfut_Copy item to clipboard".
      3) Select other media item(s).
      4) Run script "bfut_Paste item from clipboard to selected items (replace)".
    REQUIRES: Reaper v6.04 or later, SWS v2.10.0.1 or later
  @changelog
    + improved performance
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
local item = reaper.GetSelectedMediaItem(0, 0)
if item then
  local retval, item_chunk = reaper.GetItemStateChunk(item, "", false)
  if retval then
    if reaper.APIExists("CF_SetClipboard") then
      reaper.CF_SetClipboard(item_chunk)
    else
      reaper.ReaScriptError("Requires extension, SWS v2.10.0.1 or later.\n")
    end
  end
end