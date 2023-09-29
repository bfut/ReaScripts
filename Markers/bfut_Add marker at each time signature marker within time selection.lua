--[[
  @author bfut
  @version 1.0
  @description bfut_Add marker at each time signature marker within time selection
  @about
    * bfut_Add marker at each time signature marker
    * bfut_Add marker at each time signature marker within time selection

    HOW TO USE:
      1) Set time selection. (optional)
      2) Run the script.
  @changelog
    REQUIRES: Reaper v6.82 or later
    + initial version
  @website https://github.com/bfut
  LICENSE:
    Copyright (C) 2023 and later Benjamin Futasz

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
local TIMESIG_NUM = reaper.CountTempoTimeSigMarkers(0)
if TIMESIG_NUM > 0 then
  local function bfut_GetBehavior()
    local ORIGINAL_TIMESEL_START, ORIGINAL_TIMESEL_END = reaper.GetSet_LoopTimeRange2(0, false, false, -1, -1, false)
    if ORIGINAL_TIMESEL_END - ORIGINAL_TIMESEL_START < 10^-6 then
      return "all"
    end
    local EDIT_CUR_POS = reaper.GetCursorPositionEx(0)
    reaper.SetEditCurPos2(0, ORIGINAL_TIMESEL_END, false, false)
    reaper.Main_OnCommandEx(41820, 0)
    local prev_pos = reaper.GetCursorPositionEx(0)
    reaper.Main_OnCommandEx(41821, 0)
    local next_pos = reaper.GetCursorPositionEx(0)
    reaper.SetEditCurPos2(0, EDIT_CUR_POS, false, false)
    if prev_pos >= ORIGINAL_TIMESEL_START or (next_pos <= ORIGINAL_TIMESEL_END and next_pos >= ORIGINAL_TIMESEL_START) then
      return "sel", ORIGINAL_TIMESEL_START, ORIGINAL_TIMESEL_END
    end
    return "quit"
  end
  local option, original_timesel_start, original_timesel_end = bfut_GetBehavior()
  if option == "quit" then
    return
  end
  reaper.Undo_BeginBlock2(0)
  reaper.PreventUIRefresh(1)
  if option == "sel" then
    for i = TIMESIG_NUM - 1, 0, -1 do
      local _, timepos = reaper.GetTempoTimeSigMarker(0, i)
      if timepos >= original_timesel_start and timepos <= original_timesel_end then
        reaper.AddProjectMarker(0, false, timepos, -1, "", -1)
      end
    end
  else
    for i = TIMESIG_NUM - 1, 0, -1 do
      local _, timepos = reaper.GetTempoTimeSigMarker(0, i)
      reaper.AddProjectMarker(0, false, timepos, -1, "", -1)
    end
  end
  reaper.PreventUIRefresh(-1)
  reaper.UpdateArrange()
  reaper.Undo_EndBlock2(0, "bfut_Add marker at each time signature marker within time selection", -1)
end