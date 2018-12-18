WEAPON.Firerate = 350
WEAPON.baseModel = "models/weapons2/rocketl/rocketl.md3"
WEAPON.pickupSound = "sound/misc/w_pkup.wav"
WEAPON.canDrop = true
WEAPON.register = false --base_weapon is not a spawnable class
WEAPON.ammoClass = "ammo_bullets"
WEAPON.printName = "Base Weapon"
WEAPON.slot = 1

WEAPON.ITEM.Quantity = 25
WEAPON.ITEM.respawnTime = 5000


function WEAPON:ItemOverride(ITEM)

end

function WEAPON:GetAmmo(player)
	if(CLIENT and player == nil) then player = LocalPlayer():EntIndex() end
	if(type(player) == "number") then
		return __GetAmmo(player,self._id)
	elseif(type(player) == "userdata") then
		return __GetAmmo(player:EntIndex(),self._id)
	else
		return 0
	end
end

function WEAPON:RegisterItem(spawnable)
	ITEM = self.ITEM
	ITEM.WEAP = self --table.Copy(self)
	
	if(SERVER) then
		function ITEM:Initialized()
			self.lifetime = 0
			
			self.Entity:SetMins(Vector(-15,-15,-15))
			self.Entity:SetMaxs(Vector(15,15,15))
			self.Entity:SetClip(1)
			self.Entity:SetContents(CONTENTS_TRIGGER)
			self.Entity:SetBounce(.7)
			self.Entity:SetTrType(TR_STATIONARY) --TR_GRAVITY
			self.Entity:SetSvFlags(SVF_BROADCAST)
			
			self:SetVisible(true)
			
			self.net.draw = 1
			self.dropped = false

			self.respawning = false
		end

		function ITEM:SetVisible(b)
			if(b) then self.net.draw = 1 else self.net.draw = 0 end
		end

		function ITEM:Respawn()
			self:SetVisible(true)
			self.respawning = false
		end

		function ITEM:Think()
			if(self.respawning) then
				self:Respawn()
			end
		end

		function ITEM:ShouldPickup(other,trace)
			return other:IsPlayer() and other:GetHealth() > 0
		end

		function ITEM:Affect(other)
			__GiveCustomWeapon(other,self.WEAP._classname,self.Quantity,self.dropped)
		end

		function ITEM:Touch(other,trace)
			if(self.respawning) then

			else
				if(other != nil and self:ShouldPickup(other,trace)) then
					self:Affect(other)
					
					if(self.respawnTime == 0) then
						self.Entity:Remove()
					else
						self:SetVisible(false)
						self.Entity:SetNextThink(LevelTime() + self.respawnTime)
						self.respawning = true
					end
				end
			end
		end
	else
		function ITEM:Initialized()
			self.ref = RefEntity()
			self.ref:SetModel(LoadModel(self.WEAP.baseModel))
			self.ghostShader = LoadShader("powerups/invisibility")
			self.white = CreateShader("f",[[{
				{
					map $whiteimage
					blendFunc add
					alphaGen entity
					rgbGen entity
				}
			}]])
			self.light = 0
		end
		
		function ITEM:ItemFX(ref)
			local time = LevelTime()
			if(self.net.draw == 0) then
				ref:SetShader(self.ghostShader)
				self.light = 0
			else
				ref:SetShader(0)
				if(self.light == 0) then 
					self.light = time 
				end
			end
			
			ref:Render()
			
			if(time - self.light < 500) then
				local l = (time-self.light) / 500
				l = 1 - CLAMP(l,0,1)
				ref:SetShader(self.white)
				ref:SetColor(l,l,l,1)
				ref:Render()
			end		
		end
	
		function ITEM:Draw()
			--if not (self.net.draw == 1) then return end
			local time = LevelTime()
			self.ref:SetLightingOrigin(self.Entity:GetPos())
			self.ref:SetPos(self.Entity:GetPos() + Vector(0,0,math.sin(time/150)*5))
			self.ref:SetAngles(Vector(0,time/4,0))
			self.ref:Scale(Vector(1.5,1.5,1.5))
			
			self:ItemFX(self.ref)
			
			return self.ref
		end
	end
	
	self:ItemOverride(self.ITEM)
	
	if(spawnable) then
		RegisterEntityClass(ITEM.WEAP._classname,self.ITEM)
	end
end