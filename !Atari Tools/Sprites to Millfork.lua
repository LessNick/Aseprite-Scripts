-- Understand, Correct, Improve           ___
-- ________/| _________________/\__/\____/  /_____
-- \  ____/ |/   __/  /  / __ /  \/  \  \  /   __/
-- |   __/  /\__   \    /  __ \      /     \  _/ \
-- |___\ \__\____  //__/\_____/\    /__/\  /_____/
-- +-------------\/breeze'13----\  /crew-\/------+
--                               \/
-- https://github.com/LessNick/Aseprite-Scripts
-- BSD-3-Clause license


local spr = app.sprite
if not spr then return app.alert "No active sprite" end

local sprPal = spr.palettes[1];
if #sprPal > 2 then 
	app.alert "Warning! Support only 2 colors palette!"
end

local pixelRatio = spr.pixelRatio
if pixelRatio.width ~= 2 and pixelRatio.width ~= 4 and pixelRatio.width ~= 8 then
	app.alert("Warning! Pixel Ratio (" .. (pixelRatio.width) .. ") not equals x2, x4 or x8!")
end

local title = ""
local exp = ""

local aniTimeMult = 100

function mysplit(inputstr, sep)
	if sep == nil then
		sep = "%s"
	end
	local t = {}
	for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
		table.insert(t, str)
	end
	return t
end

function getSprArrayText(sPrefix, fNum, sNum, aByte, w, h)
	local lit = "abcdefghijklmnopqrstuvwxyz"
	local sLit = string.sub(lit, fNum, fNum)
	local sName = sPrefix .. "Spr" .. sNum .. sLit
	local result = "// Sprite " .. sNum .. " " .. w .. "x" .. h .. "\r\n"
	result = result .. "array(byte) " .. sName .. " = ["
	for i = 1, #aByte, 1 do
		if i > 1 then result = result .. ", " end
		result = result .. "0x" .. string.format("%02x", aByte[i])
	end
	result = result .. "]"
	return result, sName
end

function makeText(sPrefix, enableAni, enableEmpty)
	local frames = app.sprite.frames
	local aniStr1 = ""	-- Sprite 1 animation list
	local aniStr2 = ""	-- Sprite 2 animation list
	local aniStr3 = ""	-- Sprite 3 animation list
	local aniStr4 = ""	-- Sprite 4 animation list
	local timeStr = ""	-- Sprite timeline list
	
	exp = exp .. "\r\n// Sprite size (width) of player: 0 = normal, 1 = double, 3 = quadruple"
	local pSize = 0
	if (pixelRatio.width == 4) then
		pSize = 1
	elseif (pixelRatio.width == 8) then
		pSize = 3
	end
	exp = exp .. "\r\nbyte " .. sPrefix .. "Size = " .. pSize .. "\r\n"
	
	for fNum = 1, #frames, 1 do
		local frame = app.sprite.frames[fNum]
		local frameD = math.ceil(frame.duration * aniTimeMult / 2)
		local image = Image(frame.sprite.width, frame.sprite.height)
		image:drawSprite(frame.sprite, fNum)
		local pr = frame.sprite.pixelRatio
		local sWidth = frame.sprite.width
		local sHeight = frame.sprite.height
		local aByte1 = {}	-- Atari sprite 1 (array bytes)
		local aByte2 = {}	-- Atari sprite 2 (array bytes)
		local aByte3 = {}	-- Atari sprite 3 (array bytes)
		local aByte4 = {}	-- Atari sprite 4 (array bytes)
		local workByte = 0
		local bitPos = 7
		for it in image:pixels() do
			local pixelValue = it()
			local pc = app.pixelColor
			local r = pc.rgbaR(pixelValue)
			local g = pc.rgbaG(pixelValue)
			local b = pc.rgbaB(pixelValue)
			if r > 0 or g > 0 or b > 0 then
				local bValue = (1 << bitPos)
				workByte = (workByte | bValue)
			end
			bitPos = bitPos - 1
			if bitPos == -1 then
				bitPos = 7
				if (it.x >= 0 and it.x <= 7) then
					aByte1[#aByte1 + 1] = workByte
				
				elseif (it.x >= 8 and it.x <= 15) then
					aByte2[#aByte2 + 1] = workByte
				
				elseif (it.x >= 16 and it.x <= 23) then
					aByte3[#aByte3 + 1] = workByte
				
				elseif (it.x >= 24 and it.x <= 27) then
					aByte4[#aByte4 + 1] = workByte
				end
				workByte = 0
			end
		end
		
		if (#aByte1 > 0) then
			r, n = getSprArrayText(sPrefix, fNum, 1, aByte1, sWidth, sHeight)
			exp = exp .. "\r\n" .. r
			if aniStr1 ~= "" then
				aniStr1 = aniStr1 .. ", "
				timeStr = timeStr .. ", "
			end
			aniStr1 = aniStr1 .. n
			timeStr = timeStr .. frameD
		end
		if (#aByte2 > 0) then
			r, n = getSprArrayText(sPrefix, fNum, 2, aByte2, sWidth, sHeight)
			exp = exp .. "\r\n" .. r
			if aniStr2 ~= "" then
				aniStr2 = aniStr2 .. ", "
			end
			aniStr2 = aniStr2 .. n
		end
		if (#aByte3 > 0) then
			r, n = getSprArrayText(sPrefix, fNum, 3, aByte3, sWidth, sHeight)
			exp = exp .. "\r\n" .. r
			if aniStr3 ~= "" then
				aniStr3 = aniStr3 .. ", "
			end
			aniStr3 = aniStr3 .. n
		end
		if (#aByte4 > 0) then
			r, n = getSprArrayText(sPrefix, fNum, 4, aByte4, sWidth, sHeight)
			exp = exp .. "\r\n" .. r
			if aniStr4 ~= "" then
				aniStr4 = aniStr4 .. ", "
			end
			aniStr4 = aniStr4 .. n
		end

		exp = exp .. "\r\n"
	end
	if enableAni == true then
		if aniStr1 ~= "" then
			exp = exp .. "\r\n// Sprite 1 Frame Animation \r\narray(pointer) " .. sPrefix .. "FramesAni1 = [\r\n\t" .. aniStr1 .. "\r\n]\r\n"
		end
		if aniStr2 ~= "" then
			exp = exp .. "\r\n// Sprite 2 Frame Animation \r\narray(pointer) " .. sPrefix .. "FramesAni2 = [\r\n\t" .. aniStr2 .. "\r\n]\r\n"
		end
		if aniStr3 ~= "" then
			exp = exp .. "\r\n// Sprite 3 Frame Animation \r\narray(pointer) " .. sPrefix .. "FramesAni3 = [\r\n\t" .. aniStr3 .. "\r\n]\r\n"
		end
		if aniStr4 ~= "" then
			exp = exp .. "\r\n// Sprite 4 Frame Animation \r\narray(pointer) " .. sPrefix .. "FramesAni4 = [\r\n\t" .. aniStr4 .. "\r\n]\r\n"
		end
		
		exp = exp .. "\r\n// Sprite Frame Duration \r\narray(byte) " .. sPrefix .. "FramesDuration = [\r\n\t" .. timeStr .. "\r\n]\r\n"
		
		exp = exp .. "\r\n"
	end

end

local tmp = mysplit(spr.filename, "\\|/")
title = mysplit(tmp[#tmp], '.')[1]

local lay = app.activeLayer
local dlg = Dialog("Export Sprites to Millfork")
dlg:entry{
	id="sPrefix",
	label="variable prefix",
	text=title,
	focus=true
}
:check{ id="writeAni",
	label="Animation Frames List",
	text="Add to file",
	selected=true
}
:entry{
	id="repeatCount",
	label="Repeat Frames (Count)",
	text="1",
	focus=false
}
:radio{
	id="newFile",
	label="Sprites Data",
	text="Write New File",
	selected=false,
	onclick=selectFrameRange
}:newrow()
:radio{
	id="appendFile",
	text="Append Exist File",
	selected=true,
	onclick=selectFrameRange
}
:file {
	id="filename",
	label="Export sprites to Milfork file:",
	save=true,
	focus=false,
	filename=app.fs.joinPath(app.fs.filePath(lay.sprite.filename), "spritesData.mfk")
}
:separator()
:button{ text="&Export", focus=true, id="ok" }
:button{ text="&Cancel" }
:show()

local data = dlg.data
if data.ok then
	sPrefix = data.sPrefix
	makeText(sPrefix, data.writeAni, data.writeEmpty)
	if exp ~= "" then
		local writeMode = "wb"
		if data.appendFile == true then
			writeMode = "a+b"
		end
		local out = io.open(app.fs.normalizePath(data.filename), writeMode)
		local header = "////////////////////////////////////////////\r\n"
		out:write(header .. "// Spites " .. title .. "\r\n" .. header)
 		out:write(exp)
 		out:close()
	end
end
