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
  -- if key == 'rshift' and not G.SETTINGS.paused then
  --   if (G.consumeables or {}).highlighted then
  --     local card = G.consumeables.highlighted[1]
  --     card.selected = not card.selected
  --     if card.selected then
  --       card.greyed = true
  --     else
  --       card.greyed = false
  --     end
  --   end
  -- end
  -- if key == 'rctrl' and not G.SETTINGS.paused then
  --   -- Get selected cards
  --   local selected_cards = {}
  --   for k, v in pairs(G.consumeables.cards) do
  --     if v.selected then
  --       table.insert(selected_cards, #selected_cards, v)
  --     end
  --   end
  --   if selected_cards then
  --     local sell_value = 0
  --     for k, v in pairs(selected_cards) do
  --       sell_value = sell_value + v.sell_cost
  --       v:remove()
  --     end
  --     G.E_MANAGER:add_event(Event({
  --       trigger = 'after',
  --       delay = 0.4,
  --       func = function()
  --         play_sound('timpani')
  --         ease_dollars(sell_value, true)
  --         return true
  --       end,
  --     }))
  --     delay(0.6)
  --   end
  -- end
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
