TOOL.Tab = "Aperture"
TOOL.Category = "Puzzle elements"
TOOL.Name = "#tool.aperture_fizzler.name"

TOOL.ClientConVar["model"] = "models/aperture/fizzler_emitter.mdl"
TOOL.ClientConVar["keyenable"] = "45"
TOOL.ClientConVar["startenabled"] = "0"
TOOL.ClientConVar["toggle"] = "0"

local PAINT_MAX_LAUNCH_SPEED = 1000
local ToolBackground = Material("vgui/tool_screen_background")

if CLIENT then
	language.Add("tool.aperture_fizzler.name", "Fizzler")
	language.Add(
		"tool.aperture_fizzler.desc",
		"A Material Emancipation Grill, often referred to by test subjects as a fizzler for some reason, is used to prevent the passage of unauthorized equipment or objects that pass through it."
	)
	language.Add("tool.aperture_fizzler.0", "Left click to place")
	language.Add("tool.aperture_fizzler.enable", "Enable")
	language.Add("tool.aperture_fizzler.startenabled", "Enabled")
	language.Add("tool.aperture_fizzler.startenabled.help", "Material Emancipation Grill will be enabled when placed")
	language.Add("tool.aperture_fizzler.toggle", "Toggle")
end

if SERVER then
	function MakePortalFizzler(ply, pos, ang, model, key_enable, startenabled, toggle, data)
		local ent = ents.Create("ent_portal_fizzler")
		if not IsValid(ent) then
			return
		end

		duplicator.DoGeneric(ent, data)
		ent:SetModel(model)
		ent:SetPos(pos)
		ent:SetAngles(ang)
		ent:SetMoveType(MOVETYPE_NONE)
		ent.Owner = ply
		ent:SetStartEnabled(tobool(startenabled))
		ent:SetToggle(tobool(toggle))
		ent:Spawn()

		-- initializing numpad inputs
		ent.NumDown = numpad.OnDown(ply, key_enable, "PortalField_Enable", ent, true)
		ent.NumUp = numpad.OnUp(ply, key_enable, "PortalField_Enable", ent, false)

		-- saving data
		local ttable = {
			model = model,
			key_enable = key_enable,
			ply = ply,
			startenabled = startenabled,
			toggle = toggle
		}

		table.Merge(ent:GetTable(), ttable)

		if IsValid(ply) then
			ply:AddCleanup("#tool.aperture_fizzler.name", ent)
		end

		return ent
	end

	duplicator.RegisterEntityClass(
		"ent_fizzler",
		MakePortalFizzler,
		"pos",
		"ang",
		"model",
		"key_enable",
		"startenabled",
		"toggle",
		"data"
	)
end

function TOOL:LeftClick(trace)
	-- Ignore if place target is Alive
	--if ( trace.Entity and ( trace.Entity:IsPlayer() or trace.Entity:IsNPC() or APERTURESCIENCE:GASLStuff( trace.Entity ) ) ) then return false end

	if CLIENT then
		return true
	end

	-- if not APERTURESCIENCE.ALLOWING.paint and not self:GetOwner():IsSuperAdmin() then self:GetOwner():PrintMessageHUD_PRINTTALK, "This tool is disabled" return end

	local ply = self:GetOwner()
	local model = self:GetClientInfo("model")
	local key_enable = self:GetClientNumber("keyenable")
	local startenabled = self:GetClientNumber("startenabled")
	local toggle = self:GetClientNumber("toggle")

	local pos = trace.HitPos
	local plyPos = ply:GetPos()
	local angle =
		math.abs(trace.HitNormal.z) == 1 and
		math.Round((Vector(plyPos.x, plyPos.y) - Vector(pos.x, pos.y)):Angle().yaw / 90) * 90 or
		0
	if self.FizzlerRotate then
		angle = angle + self.FizzlerRotate
	end
	local _,
		ang = LocalToWorld(Vector(), Angle(angle, -90, 0), Vector(), trace.HitNormal:Angle())

	local ent = MakePortalFizzler(ply, pos, ang, model, key_enable, startenabled, toggle)

	undo.Create("Material Emancipation Grill")
	undo.AddEntity(ent)
	undo.SetPlayer(ply)
	undo.Finish()

	return true, ent
end

function TOOL:UpdateGhostFizzler(ent, ply)
	if not IsValid(ent) then
		return
	end

	local trace = ply:GetEyeTrace()
	if not trace.Hit or trace.Entity and (trace.Entity:IsPlayer() or trace.Entity:IsNPC() or trace.Entity.IsAperture) then
		ent:SetNoDraw(true)
		return
	end

	local pos = trace.HitPos
	local plyPos = ply:GetPos()
	local angle =
		math.abs(trace.HitNormal.z) == 1 and
		math.Round((Vector(plyPos.x, plyPos.y) - Vector(pos.x, pos.y)):Angle().yaw / 90) * 90 or
		0
	if self.FizzlerRotate then
		angle = angle + self.FizzlerRotate
	end
	local _,
		ang = LocalToWorld(Vector(), Angle(angle, -90, 0), Vector(), trace.HitNormal:Angle())

	ent:SetPos(pos)
	ent:SetAngles(ang)
	ent:SetNoDraw(false)
end

function TOOL:RightClick(trace)
	if not self.FizzlerRotate then
		self.FizzlerRotate = 0
	end
	-- Somehow rightCLick on client work double or even tripple at the time
	if CLIENT and self.LastClientRightClick ~= CurTime() or SERVER then
		self.LastClientRightClick = CurTime()
		self.FizzlerRotate = self.FizzlerRotate == 0 and 90 or 0
	end
end

function TOOL:Think()
	local mdl = self:GetClientInfo("model")
	if not util.IsValidModel(mdl) then
		self:ReleaseGhostEntity()
		return
	end

	if not IsValid(self.GhostEntity) or self.GhostEntity:GetModel() ~= mdl then
		self:MakeGhostEntity(mdl, Vector(), Angle())
	end

	if IsValid(self.GhostEntity) then
		local paintType = self:GetClientNumber("paint_type")
		self.GhostEntity:SetSkin(paintType)
	end

	self:UpdateGhostFizzler(self.GhostEntity, self:GetOwner())
end

-- function TOOL:DrawToolScreen(width, height)
-- surface.SetDrawColor(Color(255, 255, 255, 255))
-- surface.SetMaterial(ToolBackground)
-- surface.DrawTexturedRect(0, 0, width, height)

-- local text = "#tool.aperture_fizzler.name"
-- local x,y = surface.GetTextSize(text)
-- draw.SimpleText("#tool.aperture_fizzler.name", "CloseCaption_Bold", x + 20, y + 20, Color(50, 50, 50), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
-- end

local ConVarsDefault = TOOL:BuildConVarList()

function TOOL.BuildCPanel(CPanel)
	CPanel:AddControl("Header", {Description = "#tool.aperture_fizzler.desc"})
	CPanel:AddControl(
		"PropSelect",
		{ConVar = "aperture_fizzler_model", Models = list.Get("PortalFizzlerModels"), Height = 1}
	)
	CPanel:AddControl(
		"CheckBox",
		{Label = "#tool.aperture_fizzler.startenabled", Command = "aperture_fizzler_startenabled", Help = true}
	)
	CPanel:AddControl("Numpad", {Label = "#tool.aperture_fizzler.enable", Command = "aperture_fizzler_keyenable"})
	CPanel:AddControl("CheckBox", {Label = "#tool.aperture_fizzler.toggle", Command = "aperture_fizzler_toggle"})
end

list.Set("PortalFizzlerModels", "models/aperture/fizzler_emitter.mdl", {})
