--
-- (C) 2013 Kriss@XIXs.com
--
local coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,load,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require=coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,load,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require


-- handle a collection of windocks that all live in the same place

--module
local M={ modname=(...) } ; package.loaded[M.modname]=M

function M.bake(oven,wwindock)

local framebuffers=oven.rebake("wetgenes.gamecake.framebuffers")
local widgets_menuitem=oven.rebake("wetgenes.gamecake.widgets.menuitem")

wwindock=wwindock or {}

function wwindock.update(widget)
	return widget.meta.update(widget)
end

function wwindock.draw(widget)
	return widget.meta.draw(widget)
end

function wwindock.layout(widget)

	if widget.windock=="stack" then
	
		local px=0
		local py=0
		
		for i,window in ipairs(widget) do
			if widget.stack_axis=="x" then

				window.py=0
				window.hy=widget.hy
				window.px=px
				if window.panel_mode=="scale" then -- maintain aspect
					window.hx=window.win_fbo.hx*(window.hy/window.win_fbo.hy)
				end
				px=px+window.hx
				
			else -- y axis

				window.px=0
				window.hx=widget.hx
				window.py=py
				if window.panel_mode=="scale" then -- maintain aspect
					window.hy=window.win_fbo.hy*(window.hx/window.win_fbo.hx)
				end
				py=py+window.hy

			end
		end

	elseif widget.windock=="drag" then
	
		local px=0
		local py=0
		local hx=0
		local hy=0
		for i,v in ipairs(widget) do
			if v.px<px then px=v.px end
			if v.py<py then px=v.py end
			if v.px+v.hx>hx then hx=v.px+v.hx end
			if v.py+v.hy>hy then hy=v.py+v.hy end
		end

--print("dock",px,py,hx,hy)

		local ss=widget.hx/hx
		if widget.hy/hy < ss then ss=widget.hy/hy end
		if ss>1 then ss=1 end
		widget.hx=widget.hx/ss
		widget.hy=widget.hy/ss
		widget.sx=ss
		widget.sy=ss

	end
		
	return widget.meta.layout(widget)
end

function wwindock.setup(widget,def)

	widget.class="windock"
	widget.windock=def.windock or "drag" -- type of dock
-- "drag" is a collection of dragable windows
-- "stack" is a stack of side by side windows

	widget.stack_axis=def.stack_axis -- "x" or "y"
	-- the axis along which the the windows stack
	
	widget.smode=def.smode or "topleft"

	widget.update=wwindock.update
	widget.draw=wwindock.draw
	widget.layout=wwindock.layout

	return widget
end

return wwindock
end
