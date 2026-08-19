local Player = Players.LocalPlayer
local Character = Player.Character
local DefaultWalkSpeed = Player.WalkSpeed

local CurrentCamera = Environment.CurrentCamera
local TrussJump = Input.GetButton("TrussJump")
local ClimbingTruss = nil

local LastCharacterRotationY = 0
local CharacterRotationYDifference = 0
local OutsideRange = 2

local function CreateTempStep(PlayerPosition, YDifference)
	local NewPart = Part.New()
	NewPart.Position = Vector3.New(PlayerPosition.X, PlayerPosition.Y - YDifference, PlayerPosition.Z)
	NewPart.Size = Vector3.New(3, 1, 3)
	NewPart.AddTag("Untouchable")
	NewPart.Parent = Environment
	wait(0.05)
	NewPart:Destroy()
end

local function ChangeCharacterAlpha(Alpha)
	local HeadColor = Character.HeadColor
	local LeftArmColor = Character.LeftArmColor
	local RightArmColor = Character.RightArmColor
	local TorsoColor = Character.TorsoColor
	local LeftLegColor = Character.LeftLegColor
	local RightLegColor = Character.RightLegColor
	Character.HeadColor = Color.New(HeadColor.R, HeadColor.G, HeadColor.B, Alpha)
	Character.LeftArmColor = Color.New(LeftArmColor.R, LeftArmColor.G, LeftArmColor.B, Alpha)
	Character.RightArmColor = Color.New(RightArmColor.R, RightArmColor.G, RightArmColor.B, Alpha)
	Character.TorsoColor = Color.New(TorsoColor.R, TorsoColor.G, TorsoColor.B, Alpha)
	Character.LeftLegColor = Color.New(LeftLegColor.R, LeftLegColor.G, LeftLegColor.B, Alpha)
	Character.RightLegColor = Color.New(RightLegColor.R, RightLegColor.G, RightLegColor.B, Alpha)
end

local SmoothIllusionStepUp = 0.3
local function AirStepUp(PartTouched)
	local PlayerPosition = Player.Position
	local PartTouchedPosition = PartTouched.Position
	local PartTouchedSize = PartTouched.Size
	if PlayerPosition.Y - 0.5 > PartTouchedPosition.Y and PlayerPosition.Y - 3.5 < PartTouchedPosition.Y and PartTouchedSize.Y < 2 and Player.IsOnGround == false and Player.IsClimbing == false then
		Player.Position = Vector3.New(math.clamp(PlayerPosition.X, PartTouchedPosition.X - PartTouchedSize.X / 2 - SmoothIllusionStepUp, PartTouchedPosition.X + PartTouchedSize.X / 2 + SmoothIllusionStepUp), PartTouchedPosition.Y + 3 + PartTouchedSize.Y / 2, math.clamp(PlayerPosition.Z, PartTouchedPosition.Z - PartTouchedSize.Z / 2 - SmoothIllusionStepUp, PartTouchedPosition.Z + PartTouchedSize.Z / 2 + SmoothIllusionStepUp))
	end
end

local SmoothIllusionHeadTuck = 0.2
local function HeadTuck(PartTouched)
	local PlayerPosition = Player.Position
	local PartTouchedPosition = PartTouched.Position
	local PartTouchedSize = PartTouched.Size
	if PlayerPosition.Y + 2.25 < PartTouchedPosition.Y - PartTouchedSize.Y / 2 + 0.5 and Player.IsOnGround == true and Player.IsClimbing == false then
		Player.Position = Vector3.New(math.clamp(PlayerPosition.X, PartTouchedPosition.X - PartTouchedSize.X / 2 - SmoothIllusionHeadTuck, PartTouchedPosition.X + PartTouchedSize.X / 2 + SmoothIllusionHeadTuck), PartTouchedPosition.Y - 4, math.clamp(PlayerPosition.Z, PartTouchedPosition.Z - PartTouchedSize.Z / 2 - SmoothIllusionHeadTuck, PartTouchedPosition.Z + PartTouchedSize.Z / 2 + SmoothIllusionHeadTuck))
	end
end

local function TrussCatch(PartTouched)
	local PlayerPosition = Player.Position
	local PartTouchedPosition = PartTouched.Position
	local PartTouchedSize = PartTouched.Size
	if PartTouched:IsA("Truss") then
		if PlayerPosition.Y > PartTouchedPosition.Y - PartTouchedSize.Y / 2 + 2.5 and PlayerPosition.Y < PartTouchedPosition.Y + PartTouchedSize.Y / 2 + 2.5 then
			CreateTempStep(PlayerPosition, 3.25)
		elseif PlayerPosition.Y < PartTouchedPosition.Y - PartTouchedSize.Y / 2 + 2.5 and Player.IsClimbing == false then
			Player.Position = Vector3.New(PlayerPosition.X, PlayerPosition.Y + 1.5, PlayerPosition.Z)
		end
	end
end

local function WallHop(PartTouched)
	local PlayerPosition = Player.Position
	local PartTouchedPosition = PartTouched.Position
	local PartTouchedSize = PartTouched.Size
	if PlayerPosition.Y - 3 > PartTouchedPosition.Y + PartTouchedSize.Y / 2 - 1.5 and Player.IsOnGround == false and Player.IsClimbing == false then
		for i = 1, 5, 1 do
			if CharacterRotationYDifference >= 60 and Player.IsOnGround == false and Player.IsClimbing == false then CreateTempStep(Player.Position, 2.75) break end
			wait(0.05)
		end
	end
end

local CornerLeniency = 2
local function CornerClip(PartTouched)
	if not PartTouched.HasTag("Untouchable") then
		local PlayerPosition = Player.Position
		local PartTouchedPosition = PartTouched.Position
		local PartTouchedSize = PartTouched.Size
		local Clippable = true
		local TouchEndedConnection = PartTouched.TouchEnded:Connect(function() Clippable = false end)
		local MinX, MaxX = PartTouchedPosition.X - PartTouchedSize.X / 2, PartTouchedPosition.X + PartTouchedSize.X / 2
		local MinZ, MaxZ = PartTouchedPosition.Z - PartTouchedSize.Z / 2, PartTouchedPosition.Z + PartTouchedSize.Z / 2
		while Clippable == true do
			PlayerPosition = Player.Position
			if PlayerPosition.X < MinX - OutsideRange or PlayerPosition.X > MaxX + OutsideRange or PlayerPosition.Z < MinZ - OutsideRange or PlayerPosition.Z > MaxZ + OutsideRange or PlayerPosition.Y - 2.5 > PartTouchedPosition.Y then
				Clippable = false
				break
			elseif CharacterRotationYDifference >= 170 and CharacterRotationYDifference <= 190 then
				local OutsideX = PlayerPosition.X <= MinX + CornerLeniency or PlayerPosition.X >= MaxX - CornerLeniency
				local OutsideZ = PlayerPosition.Z <= MinZ + CornerLeniency or PlayerPosition.Z >= MaxZ - CornerLeniency
				if OutsideX and OutsideZ then
					local NewX = (PlayerPosition.X <= MinX + CornerLeniency) and MaxX or MinX
					local NewZ = (PlayerPosition.Z <= MinZ + CornerLeniency) and MaxZ or MinZ
					Player.Position = Vector3.New(NewX, PlayerPosition.Y, NewZ)
				end
			end
			wait(0.05)
		end
		TouchEndedConnection:Disconnect()
	end
end

local function IcePhysics(PartTouched)
	local Walkable = true
	local PlayerPosition = Player.Position
	local PartTouchedPosition = PartTouched.Position
	local PartTouchedSize = PartTouched.Size
	local LastPlayerPosition = PlayerPosition
	local LastDelta = Vector3.Zero
	local PartTouchedFriction = math.clamp(PartTouched.Friction, 0.001, 0.6)
	local TouchEndedConnection = PartTouched.TouchEnded:Connect(function() Walkable = false Player.WalkSpeed = DefaultWalkSpeed end)
	local MinX, MaxX = PartTouchedPosition.X - PartTouchedSize.X / 2, PartTouchedPosition.X + PartTouchedSize.X / 2
	local MinZ, MaxZ = PartTouchedPosition.Z - PartTouchedSize.Z / 2, PartTouchedPosition.Z + PartTouchedSize.Z / 2
	while Walkable == true do
		if PlayerPosition.X < MinX - OutsideRange or PlayerPosition.X > MaxX + OutsideRange or PlayerPosition.Z < MinZ - OutsideRange or PlayerPosition.Z > MaxZ + OutsideRange or PlayerPosition.Y - 5 > PartTouchedPosition.Y then
			Walkable = false
			break
		end
		local Pass = false
		PlayerPosition = Player.Position
		local Delta = PlayerPosition - LastPlayerPosition
		Player.WalkSpeed = DefaultWalkSpeed * PartTouchedFriction * 1.667
		Player.Position = PlayerPosition + Delta * (0.08 / PartTouchedFriction)
		LastPlayerPosition = PlayerPosition
		if Delta == LastDelta then Pass = true end
		if Delta ~= LastDelta and Pass == false then LastDelta = Delta end
		Delta = Vector3.New(math.clamp(LastDelta.X, -DefaultWalkSpeed, DefaultWalkSpeed), 0, math.clamp(LastDelta.Z, -DefaultWalkSpeed, DefaultWalkSpeed))
		wait(0.05)
	end
	TouchEndedConnection:Disconnect()
end

local function SomethingTouched(PartTouched)
	AirStepUp(PartTouched)
	--HeadTuck(PartTouched)
	TrussCatch(PartTouched)
	WallHop(PartTouched)
	CornerClip(PartTouched)
	IcePhysics(PartTouched)
end

Player.Touched:Connect(function(PartTouched)
	if not PartTouched:HasTag("Untouchable") then
		SomethingTouched(PartTouched)
	end
end)

TrussJump.Pressed:Connect(function()
	if ClimbingTruss ~= nil then
		Player.Jump()
		local Explosion = Explosion.New()
		Explosion.Position = Vector3.New(ClimbingTruss.Position.X, Player.Position.Y - 1, ClimbingTruss.Position.Z)
		Explosion.Force = 4000
		Explosion.Radius = 100
		Explosion.Damage = 0
		Explosion.AffectAnchored = false
		Explosion.AffectWelds = false
		Explosion.UseEffects = false
		Explosion.Parent = Environment
	end
end)

while wait(0.05) do
	local PlayerRotationY = Player.Rotation.Y
	local Distance = (CurrentCamera.Position - Player.Position).Magnitude
	local Alpha = math.clamp(0.01 * Distance * 5, 0, 1)
	ClimbingTruss = Player.ClimbingTruss
	ChangeCharacterAlpha(Alpha)
	CharacterRotationYDifference = math.abs(PlayerRotationY - LastCharacterRotationY)
	LastCharacterRotationY = PlayerRotationY
end