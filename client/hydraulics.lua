class "Hydraulics"

function Hydraulics:__init()
	self.lastVehicle = nil
	self.defaultLengths = {}
	self.targetLengths = {}

	Events:Subscribe("ModuleLoad", self, self.ModuleLoad)
end

function Hydraulics:ModuleLoad()
	if LocalPlayer:InVehicle() then
		self:LocalPlayerEnterVehicle({
			vehicle = LocalPlayer:GetVehicle()
		})
	end

	Events:Subscribe("InputPoll", self, self.InputPoll)
	Events:Subscribe("LocalPlayerEnterVehicle", self, self.LocalPlayerEnterVehicle)
	Events:Subscribe("LocalPlayerExitVehicle", self, self.LocalPlayerExitVehicle)
	Events:Subscribe("PreTick", self, self.PreTick)
	Events:Subscribe("ModuleUnload", self, self.ModuleUnload)
end

function Hydraulics:InputPoll(args)
	if not LocalPlayer:InVehicle() then return end

	local vehicle = LocalPlayer:GetVehicle()

	if vehicle:GetDriver() == LocalPlayer then
		local wheelCount = vehicle:GetWheelCount()

		if Input:GetValue(Action.Handbrake) ~= 0 then
			if vehicle:GetLinearVelocity():Length() < 2.5 then
				for wheelIndex = 1, math.floor(wheelCount/ (wheelCount == 6 and 3 or wheelCount == 8 and 4 or 2)) do
					if Input:GetValue(Action.MoveBackward) > 0 then
						self.targetLengths[wheelIndex] = self.defaultLengths[wheelIndex] * 2 * (Input:GetValue(Action.MoveBackward) / 65536)
					else
						self.targetLengths[wheelIndex] = self.defaultLengths[wheelIndex]
					end
				end

				for wheelIndex = math.floor(wheelCount / (wheelCount == 6 and 3 or wheelCount == 8 and 4 or 2)) + 1, wheelCount do
					if Input:GetValue(Action.MoveForward) > 0 then
						self.targetLengths[wheelIndex] = self.defaultLengths[wheelIndex] * 2 * (Input:GetValue(Action.MoveForward) / 65536)
					else
						self.targetLengths[wheelIndex] = self.defaultLengths[wheelIndex]
					end
				end

				if wheelCount > 3 then
					for wheelIndex = 1, wheelCount do
						if Input:GetValue(Action.MoveLeft) > 0 and wheelIndex % 2 == 0 then
							local targetLength = self.defaultLengths[wheelIndex] * 2 * (Input:GetValue(Action.MoveLeft) / 65536)

							if targetLength > self.targetLengths[wheelIndex] then
								self.targetLengths[wheelIndex] = targetLength
							end
						elseif Input:GetValue(Action.MoveRight) > 0 and wheelIndex % 2 ~= 0 then
							local targetLength = self.defaultLengths[wheelIndex] * 2 * (Input:GetValue(Action.MoveRight) / 65536)

							if targetLength > self.targetLengths[wheelIndex] then
								self.targetLengths[wheelIndex] = targetLength
							end
						end
					end
				end

				Input:SetValue(Action.Accelerate, 0)
				Input:SetValue(Action.Reverse, 0)
				Input:SetValue(Action.TurnLeft, 0)
				Input:SetValue(Action.TurnRight, 0)
			else
				for wheelIndex = 1, wheelCount do
					self.targetLengths[wheelIndex] = self.defaultLengths[wheelIndex]
				end
			end
		end
	end
end

function Hydraulics:LocalPlayerEnterVehicle(args)
	local vehicle = args.vehicle

	self.lastVehicle = vehicle
	self.defaultLengths = {}

	for wheelIndex = 1, vehicle:GetWheelCount() do
		self.defaultLengths[wheelIndex] = vehicle:GetSuspension():GetLength(wheelIndex)
	end

	self.targetLengths = Copy(self.defaultLengths)
end

function Hydraulics:LocalPlayerExitVehicle(args)
	local vehicle = args.vehicle

	for wheelIndex = 1, vehicle:GetWheelCount() do
		vehicle:GetSuspension():SetLength(wheelIndex, self.defaultLengths[wheelIndex])
	end

	self.defaultLengths = {}
	self.targetLengths = {}
end

function Hydraulics:PreTick(args)
	if LocalPlayer:InVehicle() then
		local vehicle = LocalPlayer:GetVehicle()

		if vehicle:GetDriver() == LocalPlayer and #self.targetLengths > 0 and self.lastVehicle == vehicle then
			local suspension = vehicle:GetSuspension()

			for wheelIndex = 1, vehicle:GetWheelCount() do
				local length = suspension:GetLength(wheelIndex)
				local targetLength = self.targetLengths[wheelIndex]

				suspension:SetLength(wheelIndex, length + ((targetLength - length) * args.delta * 100))
			end
		end
	end
end

function Hydraulics:ModuleUnload()
	if LocalPlayer:InVehicle() and #self.defaultLengths > 0 then
		local vehicle = LocalPlayer:GetVehicle()

		if vehicle:GetDriver() == LocalPlayer then
			self:LocalPlayerExitVehicle({
				vehicle = vehicle
			})
		end
	end
end

Hydraulics = Hydraulics()
