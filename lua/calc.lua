-- just some lua to reverse engineer and test the calendar layout


--[[
--Calendar layouts:

63 columns
   left = 8
   right = 5
   delta = 7
       +------+------+------+------+------+------+------+
       | +8   |  9   |+10   |+11   |+12   |+13   |+14   | KW45!

105 Columns:
   left  = 12
   right = 9
   delta = 12
           +-----------+-----------+-----------+-----------+-----------+-----------+-----------+
           |+22        |+23        |+24        |+25        |*26        | 27        | 28        | KW47   !


100 columns:
    left  = 13
    right = 10
    delta = 11
            +----------+----------+----------+----------+----------+----------+----------+
            |+22       |+23       |+24       |+25       |*26       | 27       | 28       | KW47    !

190 columns:
    left  = 16
    right = 13
    delta = 23
               +----------------------+----------------------+----------------------+----------------------+----------------------+----------------------+----------------------+
               |+22                   |+23                   |+24                   |+25                   |*26                   | 27                   | 28                   | KW47       !
--]]

local inspect = function(t)
	for k, v in pairs(t) do
		print(k .. ":" .. " " .. v)
	end
end

local layout_consts = function(winwidth, left, delta)
	-- right + 3 + 7 * delta + right = winwidth
	-- 2 * right = winwidth - 7*delta - 3
	-- right = (winwidth - 7*delta - 3) / 2
	-- left = right + 3
	local d = math.floor((winwidth - 5) / 8)
	local right = math.floor((winwidth - 7 * d - 3) / 2)
	local l = right + 3
	local ret = {}
	ret.left = l
	ret.delta = d
	ret.right = right
	return ret
end

local weekday = function(winwidth, x)
	local c = layout_consts(winwidth)
	local ret = {}
	ret.windwidth = winwidth
	ret.cursor_x = x
	ret.dayindex = math.floor((x - c.left) / c.delta)
	print(inspect(ret))
	return ret
end

-- layout_consts(63, 8, 7)
-- layout_consts(105, 12, 12)
-- layout_consts(100, 13, 11)
-- layout_consts(190, 16, 23)

local foo = function()
	print(weekday(63, 8).dayindex == 0, "\n")
	print(weekday(63, 9).dayindex == 0, "\n")
	print(weekday(63, 10).dayindex == 0, "\n")
	print(weekday(63, 11).dayindex == 0, "\n")
	print(weekday(63, 12).dayindex == 0, "\n")
	print(weekday(63, 13).dayindex == 0, "\n")
	print(weekday(63, 14).dayindex == 0, "\n")
	print(weekday(63, 15).dayindex == 1, "\n")
	print(weekday(63, 16).dayindex == 1, "\n")
	print(weekday(63, 49).dayindex == 5, "\n")
	print(weekday(63, 50).dayindex == 6, "\n")
	print(weekday(63, 51).dayindex == 6, "\n")
end
