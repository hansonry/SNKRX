Seeker = Object:extend()
Seeker:implement(GameObject)
Seeker:implement(Physics)
Seeker:implement(Unit)
function Seeker:init(args)
  self:init_game_object(args)
  self:init_unit()
  self:set_as_rectangle(14, 6, 'dynamic', 'enemy')
  self:set_restitution(0.5)

  self.color = red[0]
  self.classes = {'seeker'}
  self:calculate_stats(true)
  self:set_as_steerable(self.v, 2000, 4*math.pi, 4)
end


function Seeker:update(dt)
  self:update_game_object(dt)

  if main.current.mage_level == 2 then self.buff_def_a = -30
  elseif main.current.mage_level == 1 then self.buff_def_a = -15
  else self.buff_def_a = 0 end
  self:calculate_stats()

  if self.being_pushed then
    local v = math.length(self:get_velocity())
    if v < 25 then
      self.being_pushed = false
      self.steering_enabled = true
      self:set_damping(0)
      self:set_angular_damping(0)
    end
  else
    local player = main.current.player
    self:seek_point(player.x, player.y)
    self:wander(50, 100, 20)
    self:steering_separate(16, main.current.enemies)
    self:rotate_towards_velocity(0.5)
  end
  self.r = self:get_angle()
end


function Seeker:draw()
  graphics.push(self.x, self.y, self.r, self.hfx.hit.x, self.hfx.hit.x)
    graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, 3, 3, self.hfx.hit.f and fg[0] or self.color)
  graphics.pop()
end


function Seeker:on_collision_enter(other, contact)
  local x, y = contact:getPositions()

  if other:is(Wall) then
    self.hfx:use('hit', 0.15, 200, 10, 0.1)
    self:bounce(contact:getNormal())

  elseif table.any(main.current.enemies, function(v) return other:is(v) end) then
    if self.being_pushed and math.length(self:get_velocity()) > 60 then
      other:hit(math.floor(self.dmg/4))
      self:hit(math.floor(self.dmg/2))
      other:push(random:float(10, 15), other:angle_to_object(self))
      HitCircle{group = main.current.effects, x = x, y = y, rs = 6, color = fg[0], duration = 0.1}
      for i = 1, 2 do HitParticle{group = main.current.effects, x = x, y = y, color = self.color} end
      hit2:play{pitch = random:float(0.95, 1.05), volume = 0.35}
    end
  
  elseif other:is(Turret) then
    _G[random:table{'player_hit1', 'player_hit2'}]:play{pitch = random:float(0.95, 1.05), volume = 0.35}
    self:hit(0)
    self:push(random:float(2.5, 7), other:angle_to_object(self))
  end
end


function Seeker:hit(damage)
  if self.dead then return end
  self.hfx:use('hit', 0.25, 200, 10)
  self:show_hp()
  
  local actual_damage = self:calculate_damage(damage)
  self.hp = self.hp - actual_damage
  main.current.damage_dealt = main.current.damage_dealt + actual_damage
  if self.hp <= 0 then
    self.dead = true
    for i = 1, random:int(4, 6) do HitParticle{group = main.current.effects, x = self.x, y = self.y, color = self.color} end
    HitCircle{group = main.current.effects, x = self.x, y = self.y, rs = 12}:scale_down(0.3):change_color(0.5, self.color)
    main.current:enemy_killed()
    _G[random:table{'enemy_die1', 'enemy_die2'}]:play{pitch = random:float(0.9, 1.1), volume = 0.5}
  end
end


function Seeker:push(f, r)
  self.being_pushed = true
  self.steering_enabled = false
  self:apply_impulse(f*math.cos(r), f*math.sin(r))
  self:apply_angular_impulse(random:table{random:float(-12*math.pi, -4*math.pi), random:float(4*math.pi, 12*math.pi)})
  self:set_damping(1.5)
  self:set_angular_damping(1.5)
end




EnemyProjectile = Object:extend()
EnemyProjectile:implement(GameObject)
EnemyProjectile:implement(Physics)
function EnemyProjectile:init(args)
  self:init_game_object(args)
  self:set_as_rectangle(10, 4, 'dynamic', 'enemy_projectile')
end


function EnemyProjectile:update(dt)
  self:update_game_object(dt)

  self:set_angle(self.r)
  self:move_along_angle(self.v, self.r)
end


function EnemyProjectile:draw()
  graphics.push(self.x, self.y, self.r)
  graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, 2, 2, self.color)
  graphics.pop()
end


function EnemyProjectile:die(x, y, r, n)
  if self.dead then return end
  x = x or self.x
  y = y or self.y
  n = n or random:int(3, 4)
  for i = 1, n do HitParticle{group = main.current.effects, x = x, y = y, r = random:float(0, 2*math.pi), color = self.color} end
  HitCircle{group = main.current.effects, x = x, y = y}:scale_down()
  self.dead = true
end


function EnemyProjectile:on_collision_enter(other, contact)
  local x, y = contact:getPositions()
  local nx, ny = contact:getNormal()
  local r = 0
  if nx == 0 and ny == -1 then r = -math.pi/2
  elseif nx == 0 and ny == 1 then r = math.pi/2
  elseif nx == -1 and ny == 0 then r = math.pi
  else r = 0 end

  if other:is(Wall) then
    self:die(x, y, r, random:int(2, 3))
  end
end


function EnemyProjectile:on_trigger_enter(other, contact)
  if other:is(Player) then
    self:die(self.x, self.y, nil, random:int(2, 3))
    other:hit(self.dmg)
  end
end
