Keys = {}

Keys.cycleRight = false
Keys.cycleLeft = false
Keys.cycleHoldTime = 0.25
Keys.maxCycleInterval = 100
Keys.cycleInterval = Keys.maxCycleInterval
Keys.minCycleInterval = 50
Keys.intervalDecreaseRate = 5
Keys.cycleIntervalInSeconds = Keys.cycleInterval / 1000
Keys.timer = 0

function getHighlightedIndex()
  for index, card in pairs(G.consumeables.cards) do
    if card == G.consumeables.highlighted[1] then
      return index
    end
  end
  return 1
end

function Keys.resetCycleInterval()
  Keys.cycleInterval = Keys.maxCycleInterval
end

function Keys.moveLeft()
  local index = getHighlightedIndex()
  local card = G.consumeables.cards[index]
  G.consumeables:remove_from_highlighted(card)
  if index == 1 then
    index = #G.consumeables.cards + 1
  end
  G.consumeables:add_to_highlighted(G.consumeables.cards[index - 1], true)
end

function Keys.moveRight()
  local index = getHighlightedIndex()
  local card = G.consumeables.cards[index]
  G.consumeables:remove_from_highlighted(card)
  if index == #G.consumeables.cards then
    index = 0
  end
  G.consumeables:add_to_highlighted(G.consumeables.cards[index + 1], true)
end

local kpuref = Controller.key_press_update
function Controller:key_press_update(key, dt)
  kpuref(self, key, dt)
  if key == 'left' and not G.SETTINGS.paused then
    if #G.consumeables.cards > 0 then
      Keys.moveLeft()
    end
  end
  if key == 'right' and not G.SETTINGS.paused then
    if #G.consumeables.cards > 0 then
      Keys.moveRight()
    end
  end
  if key == 'return' and not G.SETTINGS.paused then
    if (G.consumeables or {}).highlighted then
      if #G.consumeables.highlighted > 0 then
        local card = G.consumeables.highlighted[1]
        if card:can_use_consumeable() then
          G.consumeables:remove_from_highlighted(card)
          card:use_consumeable()
          card:start_dissolve()
        end
      end
    end
  end
end

local khuref = Controller.key_hold_update
function Controller:key_hold_update(key, dt)
  khuref(self, key, dt)
  if self.held_key_times[key] then
    if key == 'left' and not G.SETTINGS.paused then
      if self.held_key_times[key] > Keys.cycleHoldTime then
        Keys.cycleLeft = true
      else
        self.held_key_times[key] = self.held_key_times[key] + dt
      end
    end
    if key == 'right' and not G.SETTINGS.paused then
      if self.held_key_times[key] > Keys.cycleHoldTime then
        Keys.cycleRight = true
      else
        self.held_key_times[key] = self.held_key_times[key] + dt
      end
    end
  end
end

local kruref = Controller.key_release_update
function Controller:key_release_update(key, dt)
  kruref(self, key, dt)
  if key == 'left' then
    Keys.cycleLeft = false
    Keys.resetCycleInterval()
  end
  if key == 'right' then
    Keys.cycleRight = false
    Keys.resetCycleInterval()
  end
end

local updateRef = Game.update
function Game:update(dt)
  updateRef(self, dt)
  if Keys.cycleLeft and not Keys.cycleRight then
    Keys.timer = Keys.timer + dt
    if Keys.timer >= Keys.cycleIntervalInSeconds then
      Keys.moveLeft()
      Keys.cycleInterval = math.max(
        Keys.cycleInterval - Keys.intervalDecreaseRate,
        Keys.minCycleInterval
      )
      Keys.cycleIntervalInSeconds = Keys.cycleInterval / 1000
      Keys.timer = Keys.timer - Keys.cycleIntervalInSeconds
    end
  end
  if Keys.cycleRight and not Keys.cycleLeft then
    Keys.timer = Keys.timer + dt
    if Keys.timer >= Keys.cycleIntervalInSeconds then
      Keys.moveRight()
      Keys.cycleInterval = math.max(
        Keys.cycleInterval - Keys.intervalDecreaseRate,
        Keys.minCycleInterval
      )
      Keys.cycleIntervalInSeconds = Keys.cycleInterval / 1000
      Keys.timer = Keys.timer - Keys.cycleIntervalInSeconds
    end
  end
end
