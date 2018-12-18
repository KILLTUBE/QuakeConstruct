local function preDamage(self,inflictor,attacker,damage)
	return damage * 3
end
hook.add("PrePlayerDamaged","damagescale",preDamage)