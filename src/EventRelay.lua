

--- @class EventRelay 
--- @server
--- Event Relay class init.
local EventRelay = {}
EventRelay.__index = EventRelay

export type EventRelay = {
	remote:RemoteEvent,
	config:config,
	callback:() -> () | nil,
	signal:RBXScriptSignal?
}
export type config = {
	timeout:number?,
	player:Player,
	ID:string? | number?
}

function EventRelayAssert(blah,msg)
	if not blah then
		error(msg, 3)  -- '2' ensures the error points to the line that called customAssert
	end
end

-- Creates new EventRelay object
-- Returns the EventRelay object for use.

---
--- @within EventRelay
--- Creates a new EventRelay for later use.
---
--- @param remote RemoteEvent -- The RemoteEvent you'd like to listen to
--- @param config config -- The config for EventRelay to follow
--- @return EventRelay -- Returns the EventRelay

function EventRelay.new(remote:RemoteEvent, config:config):EventRelay
	EventRelayAssert(typeof(config) == "table","Expected a table/dictionary instead got "..typeof(config))
	
	setmetatable(config, {__index = {timeout = 10,ID = math.huge}})
	local self = setmetatable({}, EventRelay)
	
	self.remote = remote
	self.config = config
	self.callback = nil
	self.signal = nil
	
	return self
end

-- Starts waiting for the remote event to be fired according to config.
-- When it finds one that abides to the config, it will fire callback and stop listening.


---
--- @within EventRelay
---	
--- Starts listening until it finds one that abides to the config.
--- It then fires the callback and stops listening.
---
--- @param callback (any) -> any? -- Function to fire
--- @return number -- Returns success code. 1 -> Success | 0 -> Timeout

function EventRelay:Listen(callback:(any) -> any?):number
	if callback or self.callback then
		self:StopListening()
		self.signal = self.remote.OnServerEvent:Connect(function(plr,...)
			if plr == self.config.player then
				self.callback(plr,...)
			end
			self:StopListening()
			return 1
		end)
		task.wait(self.config.timeout)
		return 0
	end
end


-- Safe wrapper to manually stop listening / disconnect from listening signal.
---
--- @within EventRelay
--- Safe wrapper to manually stop listening to the signal.
---
--- @return nil 

function EventRelay:StopListening()
	if self.signal and typeof(self.signal) == "RBXScriptConnection" then
		self.signal:Disconnect()
	end
end

-- To cleanup and destroy EventRelay Object.
---
--- @within EventRelay
--- Function to cleanup and destroy the EventRelay.
---
--- @return nil 
---
function EventRelay:Destroy()
	self.remote = nil
	self.config = nil
	self.callback = nil
	self:StopListening()
	self = nil
end

return EventRelay
