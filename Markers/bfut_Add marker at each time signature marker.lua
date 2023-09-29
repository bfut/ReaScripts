--[[
  @author bfut
  @version 1.0
  @description bfut_Add marker at each time signature marker
  @about
    * bfut_Add marker at each time signature marker
    * bfut_Add marker at each time signature marker within time selection

    HOW TO USE:
      1) Run the script.
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
  reaper.Undo_BeginBlock2(0)
  reaper.PreventUIRefresh(1)
  for i = TIMESIG_NUM - 1, 0, -1 do
    local _, timepos = reaper.GetTempoTimeSigMarker(0, i)  
    reaper.AddProjectMarker(0, false, timepos, -1, "", -1)
  end
  reaper.PreventUIRefresh(-1)
  reaper.UpdateArrange()
  reaper.Undo_EndBlock2(0, "bfut_Add marker at each time signature marker", -1)
end
