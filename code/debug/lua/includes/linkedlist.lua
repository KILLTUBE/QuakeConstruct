local LinkedListT = {}

local function newLink(v)
	local link = {}
		
	link.__o = v
		
	return link
end

function LinkedListT:Init()
	if(self.inited ~= true) then 
		self.inited = true 
	else
		return
	end
	self.count = 0
	self.start = nil
	self.current = nil
end

local function GetLinkAtIndex(self,index)
	if(self.start == nil) then return end
	if(index == nil) then return end
	if(index <= 0) then error("index Out Of Bounds " .. index .. " <= 0") return end
	local l = self.start
	local i = 1
	while(l.next ~= nil and i < index) do
		l = l.next
		i = i + 1
	end
	if(i < index) then error("index Out Of Bounds " .. index .. " > " .. i) return end
	return l
end

function LinkedListT:GetLink(index)
	return GetLinkAtIndex(self,index)
end

function LinkedListT:Get(index)
	local l = GetLinkAtIndex(self,index)
	if(l == nil) then return end
	return l.__o
end

function LinkedListT:Add(v)
	if(v == nil) then return end
	local link = newLink(v)
	if(self.start == nil) then
		self.start = link
		self.last = link
		self.count = 1
	else
		if(self.last == nil) then return end
		self.last.next = link
		link.prev = self.last
		self.last = link
		self.count = self.count + 1
	end
end

function LinkedListT:Replace(index,v)
	local l = GetLinkAtIndex(self,index)
	if(v == nil) then
		self:Remove(index)
		return
	end
	l.__o = v
end

function LinkedListT:Sort(comparator)
	if(self.start == nil) then return end
	local temp, temp1, temp2
	local d
	local head = self.start
	
	temp=head
	temp1=head
	
	while(temp.next ~= nil) do
		temp=temp.next
		while(temp1.next ~= nil) do
			temp2=temp1
			temp1=temp1.next
			local b,e = pcall(comparator,temp2.__o,temp1.__o)
			if(b == nil) then error("LinkedListT Comparator Error: " .. e .. "\n") end
			
			if(e) then
				d = temp2.__o
				temp2.__o = temp1.__o
				temp1.__o = d
			end
		end
		
		temp2=head
		temp1=head
	end
end

function LinkedListT:Clear()
	self.count = 0
	self.start = nil
end

local function LRemove(self,l)
	if(l == nil) then return end
	if(l.prev == nil) then
		if(l.next ~= nil) then
			self.start = l.next
			self.start.prev = nil
		else
			self.start = nil
			self.last = nil
			self.count = 1
		end
	elseif(l.next == nil) then
		l.prev.next = nil
		self.last = l.prev
	else
		l.prev.next = l.next
		l.next.prev = l.prev
	end
	l = nil
	self.count = self.count - 1
	self.removeCall = true
end

function LinkedListT:Remove(index)
	if(index == nil and self.current ~= nil) then
		LRemove(self,self.current)
		self.current = nil
		return;
	end
	local l = GetLinkAtIndex(self,index)
	LRemove(self,l)
end

function LinkedListT:Len()
	return self.count
end

function LinkedListT:IterReverse(func)
	if(type(func) ~= "function") then return end
	if(self.last == nil) then return end
	local i = 1
	local l = self.last
	while(l.prev ~= nil) do
		if(self.removeCall == true) then
			i = i - 1
			self.removeCall = false
		end
		
		self.current = l
		if(i > self:Len() or i <= 0) then return end
		local b,e = pcall(func,l.__o,i)
		self.current = nil
		if(b ~= true) then error(e) end
		if(e ~= nil) then return e end
		l = l.prev
		i = i + 1
	end
	
	self.current = l
	if(i > self:Len() or i <= 0) then return end
	local b,e = pcall(func,l.__o,i)
	self.current = nil
	if(b ~= true) then error(e) end
	if(e ~= nil) then return e end
end

function LinkedListT:Iter(func)
	if(type(func) ~= "function") then return end
	if(self.start == nil) then return end
	local i = 1
	local l = self.start
	while(l.next ~= nil) do
		if(self.removeCall == true) then
			i = i - 1
			self.removeCall = false
		end
		
		self.current = l
		if(i > self:Len() or i <= 0) then return end
		local b,e = pcall(func,l.__o,i)
		self.current = nil
		if(b ~= true) then error(e) end
		if(e ~= nil) then return e end
		l = l.next
		i = i + 1
	end
	
	self.current = l
	if(i > self:Len() or i <= 0) then return end
	local b,e = pcall(func,l.__o,i)
	self.current = nil
	if(b ~= true) then error(e) end
	if(e ~= nil) then return e end
end

function LinkedList()
	local o = {}

	setmetatable(o,LinkedListT)
	LinkedListT.__index = LinkedListT
	
	o:Init()
	
	return o;
end