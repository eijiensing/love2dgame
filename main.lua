-- TODO: FIX CAMERA PLS
Vector = require("libraries.brinevector.brinevector")
Camera = require("libraries.hump.camera")

function love.load()
	love.window.setFullscreen(true)
	love.window.setMode(800, 600, { fullscreentype = "desktop" })
	local width, height, _ = love.window.getMode()
	World = {
		Entities = {
			Bullets = {},
		},
	}
	Player = {
		Position = Vector(width / 2, height / 2),
		Aiming = Vector(1, 0),
		Stats = {
			Size = 20,
			Speed = 300,
			ShootCooldown = 0.1,
			BulletSpeed = 400,
			BulletLifespan = 0.8,
		},
		CurrentCooldowns = {
			Shoot = 0,
		},
	}
	MousePosition = Vector(0, 0)
	love.mouse.setVisible(false)
	Cam = Camera(Player.Position.x, Player.Position.y)
end

function love.update(dt)
	local dx, dy = Player.Position.x - Cam.x, Player.Position.y - Cam.y
	Cam:move(dx / 2, dy / 2)
	MousePosition = Vector(love.mouse.getX(), love.mouse.getY())
	Player.Aiming = (MousePosition - Player.Position).normalized

	local direction = Vector(0, 0)
	if love.keyboard.isDown("w") then
		direction.y = direction.y - 1
	end
	if love.keyboard.isDown("a") then
		direction.x = direction.x - 1
	end
	if love.keyboard.isDown("s") then
		direction.y = direction.y + 1
	end
	if love.keyboard.isDown("d") then
		direction.x = direction.x + 1
	end
	direction = direction.normalized * dt * Player.Stats.Speed
	Player.Position = Player.Position + direction

	if love.mouse.isDown(1) and Player.CurrentCooldowns.Shoot <= 0 then
		Player.CurrentCooldowns.Shoot = Player.Stats.ShootCooldown
		World.Entities.Bullets[#World.Entities.Bullets + 1] = {
			Direction = Player.Aiming,
			Position = Player.Position + (Player.Aiming * 2),
			Lifespan = Player.Stats.BulletLifespan,
			-- 30% of player move dir will get added to bullet maybe goofy
			Velocity = (Player.Aiming * Player.Stats.BulletSpeed * dt)
				+ (0.3 * direction.normalized * dt * Player.Stats.Speed),
		}
	end

	for _, bullet in pairs(World.Entities.Bullets) do
		bullet.Position = bullet.Position + bullet.Velocity
		bullet.Lifespan = bullet.Lifespan - dt
		bullet.ToBeDeleted = bullet.Lifespan < 0
	end

	for i = #World.Entities.Bullets, 1, -1 do
		local bullet = World.Entities.Bullets[i]
		if bullet.ToBeDeleted then
			table.remove(World.Entities.Bullets, i)
		end
	end

	for key, cooldown in pairs(Player.CurrentCooldowns) do
		if cooldown > 0 then
			Player.CurrentCooldowns[key] = cooldown - dt
		end
	end
end

function love.draw()
	Cam:attach()
	local offset = 0
	for i, stat in pairs(Player.Stats) do
		offset = offset + 20
		love.graphics.print(tostring(i) .. " = " .. tostring(stat), 0, offset)
	end

	love.graphics.setColor(1, 0, 0)
	love.graphics.circle("fill", Player.Position.x, Player.Position.y, Player.Stats.Size)
	love.graphics.circle("fill", love.mouse.getX(), love.mouse.getY(), 10)

	local arrowHeadSize = 20
	local arrowEnd = Player.Position + Player.Aiming * 100
	local perp = Vector(-Player.Aiming.y, Player.Aiming.x)

	for _, bullet in pairs(World.Entities.Bullets) do
		love.graphics.circle("fill", bullet.Position.x, bullet.Position.y, 5)
	end

	love.graphics.polygon(
		"fill",
		arrowEnd.x,
		arrowEnd.y,
		arrowEnd.x - Player.Aiming.x * arrowHeadSize + perp.x * arrowHeadSize / 2,
		arrowEnd.y - Player.Aiming.y * arrowHeadSize + perp.y * arrowHeadSize / 2,
		arrowEnd.x - Player.Aiming.x * arrowHeadSize - perp.x * arrowHeadSize / 2,
		arrowEnd.y - Player.Aiming.y * arrowHeadSize - perp.y * arrowHeadSize / 2
	)
	Cam:detach()
end
