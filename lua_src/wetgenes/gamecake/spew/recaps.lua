--
-- (C) 2013 Kriss@XIXs.com
--
local coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,Gload,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require=coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,load,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require

--module
local M={ modname=(...) } ; package.loaded[M.modname]=M

M.bake=function(oven,recaps)

	recaps=recaps or {} 
	
	local cake=oven.cake
	local canvas=cake.canvas
	
	local keys=oven.rebake("wetgenes.gamecake.spew.keys")

	function recaps.setup(opts)
		if type(opts)=="number" then opts={max_up=opts} end
		if not opts then opts={} end
		recaps.opts=opts

		opts.max_up=opts.max_up or 1
		recaps.up={}
		for i=1,opts.max_up do
			recaps.up[i]=recaps.create() -- 1up 2up etc
		end
		return recaps -- so setup is chainable with a bake
	end

	function recaps.step()
		for i,v in ipairs(recaps.up or {}) do
			v.step()
		end
	end
	
-- pick one of the up[idx] tables
	function recaps.ups(idx)
		if idx==0 then -- merge all buttons and axis of all controllers
			local up={}
			
			up.button=function(name)
				local b=false
				for i=1,#recaps.up do
					b=b or recaps.up[i].button(name)
				end
				return b
			end

			up.axis=function(name)
				local n=0
				local t=0
				for i=1,#recaps.up do
					local v=recaps.up[i].axis(name)
					if v then
						n=n+v
						t=t+1
					end
				end
				if t>0 then return math.floor(n/t) end
			end		

			return up
		end
		return recaps.up and ( recaps.up[idx or 1] or recaps.up[1] )
	end

-- create a new recap table, then we can load or save this data to or from our server
	function recaps.create(idx)
		local recap={}
		recap.idx=idx
		

		function recap.reset(flow)
			recap.flow=flow or "none" -- do not play or record by default
			recap.state={}
			recap.now={}
			recap.state_axis={}
			recap.now_axis={}
			recap.autoclear={}
			recap.stream={} -- a stream of change "table"s or "number" frame skips
			recap.frame=0
			recap.read=0
			recap.wait=0
			recap.touch="" -- you can replace this with a requested touch control scheme

-- "left_right" is a two button touch screen split
			
		end
		
		function recap.set(nam,dat) -- set the volatile data,this gets copied into state before it should be used
			recap.now[nam]=dat
		end
		function recap.get(nam) -- get the volatile data
			return recap.now[nam]
		end
		function recap.pulse(nam,dat) -- set the volatile data but *only* for one frame
			recap.now[nam]=dat
			recap.autoclear[nam]=true
		end
		


		function recap.button(name) -- return state "valid" frame data not current "volatile" frame data
			if name then
				return recap.state[name]
			end
			return recap.state -- return all buttons if no name given			
		end

		function recap.axis(name) -- return state "valid" frame data not current "volatile" frame data
			if name then
				return recap.state_axis[name]
			end
			return recap.state_axis -- return all axis if no name given
		end
		
-- use this to set a joysticks/mouse axis position
		function recap.set_axis(m)
			for _,n in ipairs{"lx","ly","lz","rx","ry","rz","dx","dy","mx","my","tx","ty"} do
				if m[n] then recap.now_axis[n]=m[n] end
			end
		end

-- use this to set button flags, that may trigger a set/clr extra pulse state
		function recap.set_button(nam,v)
--print(nam,v)
			if type(nam)=="table" then
				for _,n in ipairs(nam) do recap.set_button(n,v) end -- multi
			else
				local l=recap.now[nam]
				if type(l)=="nil" then l=recap.state[nam] end -- now probably only contains recent changes
				if v then -- set
					if not l then -- change?
						recap.set(nam,true)
						recap.pulse(nam.."_set",true)
					end
				else -- clr
					if l then -- change?
						recap.set(nam,false)
						recap.pulse(nam.."_clr",true)
					end
				end
			end
		end


		function recap.step(flow)
			flow=flow or recap.flow

--print("step "..tostring(flow))	

			if flow=="record" then
				local change
				for n,v in pairs(recap.now) do
					if recap.state[n]~=v then -- changes
						change=change or {}
						change[n]=v
						recap.state[n]=v
						recap.now[n]=nil -- from now on we get the value from the state table
					end
				end
				if change then
					table.insert(recap.stream,change) -- change something
				else
					if type(recap.stream[#recap.stream])=="number" then
						recap.stream[#recap.stream] = recap.stream[#recap.stream] + 1 -- keep on changing nothing
					else
						table.insert(recap.stream,1) -- change nothing
					end
				end
				
			elseif flow=="play" then -- grab from the stream
			
				if recap.wait>0 then
				
					recap.wait=recap.wait-1
					
				else
				
					recap.read=recap.read+1
					
					local t=recap.stream[recap.read]
					local tt=type(t)
					
					if tt=="number" then
					
						recap.wait=t-1

					elseif tt=="table"then
					
						for n,v in pairs(t) do
							recap.state[n]=v
							recap.now[n]=v
						end
					
					end
				end
			
			else -- default of do not record, do not play just be
			
				for n,v in pairs(recap.now) do
					recap.state[n]=v
					recap.now[n]=nil
				end
				
				for n,v in pairs(recap.now_axis) do
					recap.state_axis[n]=v
					recap.now_axis[n]=nil
				end

			end
			
			if flow~="play" then
				for n,b in pairs(recap.autoclear) do -- auto clear volatile button pulse states
					recap.now[n]=false
					recap.autoclear[n]=nil
				end
			end
			
			recap.frame=recap.frame+1 -- advance frame counter
		end
		
		recap.reset()

		return recap
	end


	return recaps
end
