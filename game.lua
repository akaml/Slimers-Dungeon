local sti = require("lib.sti")
local bump = require("lib.bump")
local view = require("lib.fennelview")
local moonshine = require("lib.moonshine")
local gamera = require("lib.gamera")
local anim8 = require("lib.anim8")
local map = nil
local world = nil
local canvas = nil
local camera = nil
local scale = 1
local enemy_list = {}
local player = {aim = 0, animation = nil, grid = nil, height = 16, live = true, speed = 40, type = "player", width = 7, x = 8, y = 8}
local bullet = {aim = 0, direction = "right", exists = nil, height = 4, speed = 180, type = "bullet", width = 8, x = 0, y = 0}
local enemy = {["down-animation"] = nil, ["left-animation"] = nil, ["right-animation"] = nil, ["up-animation"] = nil, aim = 0, flipped = nil, grid = nil, health = 5, height = 8, id = 0, speed = 1, type = "enemy", width = 8, x = 0, y = 0}
local enemy_spawner = {{roomi = 2, roomj = 1, x = 260, y = 60}, {roomi = 1, roomj = 2, x = 80, y = 180}, {roomi = 1, roomj = 3, x = 62, y = 321}, {roomi = 2, roomj = 3, x = 186, y = 321}, {roomi = 1, roomj = 4, x = 53, y = 423}, {roomi = 2, roomj = 5, x = 276, y = 492}, {roomi = 4, roomj = 4, x = 502, y = 419}}
local can_shoot = true
p = player
local last_camera_x = nil
local last_camera_y = nil
local camera_offset = nil
local camera_dy = 0
local camera_dx = 0
local chain = nil
local music = nil
local shoot_sound = nil
local boom_sound = nil
local hit_sound = nil
local roomi = 1
local roomj = 1
local room_w = 160
local room_h = 120
local player_win = nil
local id = 0
local function get_id()
  id = (id + 1)
  return id
end
love.load = function()
  camera = gamera.new(0, 0, 2000, 2000)
  camera:setWorld(0, 0, 2000, 2000)
  camera:setWindow(0, 0, 1024, 768)
  camera:setScale(5)
  camera:setPosition(0, 0)
  camera.l = 0
  camera.t = 0
  last_camera_x = camera.x
  last_camera_y = camera.y
  chain = moonshine.chain(800, 600, moonshine.effects.crt)
  chain.crt.scaleFactor = 1
  chain.crt.distortionFactor = {1.02, 1.02}
  chain.crt.feather = 0.14999999999999999
  chain.chain(moonshine.effects.chromasep)
  chain.chromasep.radius = 3
  map = sti("level.lua", {"bump"})
  world = bump.newWorld()
  world:add(player, player.x, player.y, player.width, player.height)
  map:bump_init(world)
  do
    local layer = map:addCustomLayer("player")
    layer.sprites = {player}
  end
  player.image = love.graphics.newImage("assets/player.png")
  player.image:setFilter("nearest", "nearest")
  bullet.image = love.graphics.newImage("assets/bullet.png")
  bullet.image:setFilter("nearest", "nearest")
  enemy.image = love.graphics.newImage("assets/slime.png")
  enemy.image:setFilter("nearest", "nearest")
  enemy.grid = anim8.newGrid(8, 8, enemy.image:getWidth(), enemy.image:getHeight())
  enemy.animation = anim8.newAnimation(enemy.grid:getFrames("1-5", 1), 0.10000000000000001)
  player.grid = anim8.newGrid(7, 16, player.image:getWidth(), player.image:getHeight())
  player["right-animation"] = anim8.newAnimation(player.grid:getFrames("1-3", 1), 0.10000000000000001)
  player["left-animation"] = player["right-animation"]:clone():flipH()
  player["up-animation"] = anim8.newAnimation(player.grid:getFrames("1-3", 2), 0.10000000000000001)
  player["down-animation"] = anim8.newAnimation(player.grid:getFrames("1-3", 3), 0.10000000000000001)
  music = love.audio.newSource("assets/music.wav", "static")
  music:setLooping(true)
  music:play()
  shoot_sound = love.audio.newSource("assets/shoot.wav", "static")
  boom_sound = love.audio.newSource("assets/boom.wav", "static")
  hit_sound = love.audio.newSource("assets/hit.wav", "static")
  return nil
end
local dirs = {down = {0, 1}, left = {-1, 0}, right = {1, 0}, up = {0, -1}}
local states = {"cameraL", "cameraR", "cameraU", "cameraD", "cameraInTrans", "cameraStopTrans", "cameraIDLE"}
local game_state = "cameraIDLE"
local spawned = 0
local spawn_target = 0
local spawned_roomi = 1
local spawned_roomj = 1
local function remove_enemies()
  if (#enemy_list > 0) then
    do
      local len = #enemy_list
      for i = 1, len do
        local en = enemy_list[i]
        local function _0_()
          if world:hasItem(en) then
            return world:remove(en)
          end
        end
        _0_()
      end
    end
    print("removing", "enemy")
    enemy_list = {}
    return nil
  end
end
local function spawn(en)
  do
    local layer = map:addCustomLayer("enemy")
    layer.sprites = {en}
  end
  local function _0_()
    if not world:hasItem(en) then
      return world:add(en, en.x, en.y, en.width, en.height)
    else
      local _0_ = {world:move(en, x, y)}
      en.x = _0_[1]
      en.y = _0_[2]
      return nil
    end
  end
  _0_()
  return table.insert(enemy_list, en)
end
local function spawn_enemies()
  if ((roomi ~= spawned_roomi) or (roomj ~= spawned_roomj)) then
    remove_enemies()
    local _0_ = {roomi, roomj}
    spawned_roomi = _0_[1]
    spawned_roomj = _0_[2]
    do
      local len = #enemy_spawner
      for i = 1, len do
        local en = enemy_spawner[i]
        local function _1_()
          if ((roomi == en.roomi) and (roomj == en.roomj)) then
            local slime = enemy
            local _1_ = {en.x, en.y, get_id(), 6}
            slime.x = _1_[1]
            slime.y = _1_[2]
            slime.id = _1_[3]
            slime.health = _1_[4]
            return spawn(slime)
          end
        end
        _1_()
      end
      return nil
    end
  end
end
local function draw_enemies()
  if (#enemy_list > 0) then
    local len = #enemy_list
    for i = 1, len do
      local e = enemy_list[i]
      local function _0_()
        if (e.health > 0) then
          return e.animation:draw(e.image, e.x, e.y)
        end
      end
      _0_()
    end
    return nil
  end
end
local ecols = nil
local elen = nil
local function update_enemies(dt)
  if (#enemy_list > 0) then
    local len = #enemy_list
    for i = 1, len do
      local e = enemy_list[i]
      local function _0_()
        if ((e.health <= 0) and world:hasItem(e)) then
          return world:remove(e)
        end
      end
      _0_()
      do
        local deltaX = (player.x - e.x)
        local deltaY = (player.y - e.y)
        local _1_ = {deltaX, deltaY}
        local dx = _1_[1]
        local dy = _1_[2]
        local x = (e.x + ((dx * e.speed) * dt))
        local y = (e.y + ((dy * e.speed) * dt))
        local function _2_()
          if world:hasItem(e) then
            e.animation:update(dt)
            local _2_ = {world:move(e, x, y)}
            e.x = _2_[1]
            e.y = _2_[2]
            ecols = _2_[3]
            elen = _2_[4]
            for i = 1, elen do
              local col = ecols[i]
              local function _3_()
                if (col.other ~= nil) then
                  if ((col.other.type ~= nil) and (col.other.type == "player") and player.live) then
                    hit_sound:play()
                    player.live = nil
                    return nil
                  end
                end
              end
              _3_()
            end
            return nil
          end
        end
        _2_()
      end
    end
    return nil
  end
end
local function shoot()
  bullet.shotting = true
  shoot_sound:play()
  local function _0_()
    if (bullet.direction == "right") then
      local _0_ = {(player.x + player.width), (player.y + (player.height / 2)), true, player.direction}
      bullet.x = _0_[1]
      bullet.y = _0_[2]
      bullet.shotting = _0_[3]
      bullet.direction = _0_[4]
      return nil
    elseif (bullet.direction == "left") then
      local _0_ = {(player.x - bullet.width), (player.y + (player.height / 2)), true, player.direction}
      bullet.x = _0_[1]
      bullet.y = _0_[2]
      bullet.shotting = _0_[3]
      bullet.direction = _0_[4]
      return nil
    elseif (bullet.direction == "down") then
      local _0_ = {player.x, (player.y + player.height), true, player.direction}
      bullet.x = _0_[1]
      bullet.y = _0_[2]
      bullet.shotting = _0_[3]
      bullet.direction = _0_[4]
      return nil
    elseif (bullet.direction == "up") then
      local _0_ = {player.x, (player.y - bullet.height), true, player.direction}
      bullet.x = _0_[1]
      bullet.y = _0_[2]
      bullet.shotting = _0_[3]
      bullet.direction = _0_[4]
      return nil
    end
  end
  _0_()
  if not world:hasItem(bullet) then
    return world:add(bullet, bullet.x, bullet.y, bullet.width, bullet.height)
  else
    local _1_
    do
      local layer = map:addCustomLayer("bullet")
      layer.sprites = {bullet}
      _1_ = nil
    end
    if _1_ then
      local _2_ = {world:move(bullet, x, y)}
      bullet.x = _2_[1]
      bullet.y = _2_[2]
      return nil
    else
      can_shoot = nil
      return nil
    end
  end
end
local function damage_enemy(en)
  if ((en.type == "enemy") and (en.health ~= nil)) then
    local len = #enemy_list
    for i = 1, len do
      local e = enemy_list[i]
      local function _0_()
        if (e.id == en.id) then
          e.health = (e.health - 1)
          return nil
        end
      end
      _0_()
    end
    return nil
  end
end
local function update_bullet(dt)
  local cols = nil
  local len = 0
  if world:hasItem(bullet) then
    for key, delta in pairs(dirs) do
      local function _0_()
        if (bullet.direction == key) then
          local _0_ = delta
          local dx = _0_[1]
          local dy = _0_[2]
          local x = (bullet.x + ((dx * bullet.speed) * dt))
          local y = (bullet.y + ((dy * bullet.speed) * dt))
          local _1_ = {world:move(bullet, x, y)}
          bullet.x = _1_[1]
          bullet.y = _1_[2]
          cols = _1_[3]
          len = _1_[4]
          for i = 0, len do
            local collision = cols[i]
            local function _2_()
              if ((collision ~= nil) and (collision.other ~= nil)) then
                return damage_enemy(collision.other)
              end
            end
            _2_()
            local function _3_()
              if ((len > 0) and world:hasItem(bullet)) then
                world:remove(bullet)
                can_shoot = true
                bullet.shotting = nil
                local _3_ = {player.x, player.y}
                bullet.x = _3_[1]
                bullet.y = _3_[2]
                return boom_sound:play()
              end
            end
            _3_()
          end
          return nil
        end
      end
      _0_()
    end
    return nil
  end
end
local key_pressed = nil
local function update_level(dt)
  key_pressed = nil
  local cons = nil
  local len = nil
  local function _0_()
    if (love.keyboard.isDown("space") and not bullet.shotting and player.live) then
      return shoot()
    end
  end
  _0_()
  for key, delta in pairs(dirs) do
    local function _1_()
      if love.keyboard.isDown(key) then
        key_pressed = true
        player.direction = key
        do
          local _1_ = delta
          local dx = _1_[1]
          local dy = _1_[2]
          local x = (player.x + ((dx * player.speed) * dt))
          local y = (player.y + ((dy * player.speed) * dt))
          local _2_ = {world:move(player, x, y)}
          player.x = _2_[1]
          player.y = _2_[2]
          return nil
        end
      end
    end
    _1_()
  end
  local function _1_()
    if key_pressed then
      player["down-animation"]:update(dt)
      player["up-animation"]:update(dt)
      player["left-animation"]:update(dt)
      return player["right-animation"]:update(dt)
    end
  end
  _1_()
  update_bullet(dt)
  update_enemies(dt)
  return map:update(dt)
end
local deltax = 160
local deltay = 120
local camera_speed = 10
local function move_camera_right(dt)
  camera:setPosition((camera.x + room_w), camera.y)
  roomi = (roomi + 1)
  game_state = "cameraIDLE"
  return nil
end
local function move_camera_left(dt)
  camera:setPosition((camera.x - room_w), camera.y)
  roomi = (roomi - 1)
  game_state = "cameraIDLE"
  return nil
end
local function move_camera_up(dt)
  camera:setPosition(camera.x, (camera.y - room_h))
  roomj = (roomj - 1)
  game_state = "cameraIDLE"
  return nil
end
local function move_camera_down(dt)
  roomj = (roomj + 1)
  camera:setPosition(camera.x, (camera.y + room_h))
  game_state = "cameraIDLE"
  return nil
end
local function update_dy()
  if (camera.y ~= last_camera_y) then
    camera_dy = ((roomj - 1) * ( - (camera.y - last_camera_y)))
    local function _0_()
      if (camera_dy > 0) then
        camera_dy = ( - camera_dy)
        return nil
      end
    end
    _0_()
    last_camera_y = camera.y
    local function _1_()
      if (roomj == 1) then
        camera_dy = 0
        return nil
      end
    end
    _1_()
    return spawn_enemies()
  end
end
local function update_dx()
  if (camera.x ~= last_camera_x) then
    camera_dx = ((roomi - 1) * ( - (camera.x - last_camera_x)))
    local function _0_()
      if (camera_dx > 0) then
        camera_dx = ( - camera_dx)
        return nil
      end
    end
    _0_()
    last_camera_x = camera.x
    local function _1_()
      if (roomi == 1) then
        camera_dx = 0
        return nil
      end
    end
    _1_()
    return spawn_enemies()
  end
end
love.update = function(dt)
  update_dy()
  update_dx()
  local function _0_()
    if (game_state == "cameraIDLE") then
      return update_level(dt)
    end
  end
  _0_()
  local function _1_()
    if ((player.x > (roomi * room_w)) and (game_state == "cameraIDLE")) then
      game_state = "cameraR"
      return move_camera_right(dt)
    end
  end
  _1_()
  local function _2_()
    if ((roomi > 1) and (player.x < ((roomi * room_w) - room_w)) and (game_state == "cameraIDLE")) then
      game_state = "cameraL"
      return move_camera_left(dt)
    end
  end
  _2_()
  local function _3_()
    if ((player.y < (roomj * room_h)) and (roomj > 1) and (game_state == "cameraIDLE")) then
      game_state = "cameraUP"
      return move_camera_up(dt)
    end
  end
  _3_()
  if ((player.y > (roomj * room_h)) and (game_state == "cameraIDLE")) then
    game_state = "cameraDown"
    return move_camera_down(dt)
  end
end
love.draw = function()
  local rotation = 0
  local function _0_()
    local function _1_(l, t, w, h)
      love.graphics.clear()
      local function _2_()
        if player.live then
          love.graphics.scale(scale, scale)
          love.graphics.setColor(1, 1, 1)
          love.graphics.print(("ROOM: " .. roomi .. "-" .. roomj), (camera.x - 90), (camera.y - 70), 0, 0.5)
          map:draw(camera_dx, camera_dy, camera.scale, camera.scale)
          local function _2_()
            if (player.direction == "left") then
              return player["left-animation"]:draw(player.image, player.x, player.y)
            elseif (player.direction == "right") then
              return player["right-animation"]:draw(player.image, player.x, player.y)
            elseif (player.direction == "down") then
              return player["down-animation"]:draw(player.image, player.x, player.y)
            elseif (player.direction == "up") then
              return player["up-animation"]:draw(player.image, player.x, player.y)
            end
          end
          _2_()
          local function _3_()
            if (bullet.direction == "up") then
              rotation = (math.pi / -2)
              return nil
            elseif (bullet.direction == "down") then
              rotation = (math.pi / -2)
              return nil
            end
          end
          _3_()
          draw_enemies()
          if bullet.shotting then
            return love.graphics.draw(bullet.image, bullet.x, bullet.y, rotation)
          end
        end
      end
      _2_()
      local function _3_()
        if ((player.live == nil) and not player_win) then
          return love.graphics.print("Game over", (camera.x - 40), (camera.y - 40), 0, 0.5)
        end
      end
      _3_()
      local function _4_()
        if ((roomi == 4) and (roomj == 2)) then
          player_win = true
          player.live = nil
          return love.graphics.print("You WIN!", (camera.x - 40), (camera.y - 40), 0, 0.5)
        end
      end
      _4_()
      return love.graphics.setColor(1, 1, 1)
    end
    return camera:draw(_1_)
  end
  return chain.draw(_0_)
end
love.keypressed = function(key)
  if (key == "escape") then
    return love.event.quit()
  end
end
return love.keypressed
