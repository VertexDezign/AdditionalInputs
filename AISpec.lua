---@class AdditionalInputsSpecSpec
---@field debugger GrisuDebug
---@field actionEvents table

---@alias AttacherJointPosition "FRONT" | "BACK"


---@class AdditionalInputsSpec : Vehicle
---@field spec_additionalInputs AdditionalInputsSpecSpec
AdditionalInputsSpec = {}

function AdditionalInputsSpec.prerequisitesPresent(specializations)
  return SpecializationUtil.hasSpecialization(Enterable, specializations)
end

function AdditionalInputsSpec.registerEventListeners(vehicleType)
  SpecializationUtil.registerEventListener(vehicleType, "onLoad", AdditionalInputsSpec)
  SpecializationUtil.registerEventListener(vehicleType, "onEnterVehicle", AdditionalInputsSpec)
  SpecializationUtil.registerEventListener(vehicleType, "onLeaveVehicle", AdditionalInputsSpec)
  SpecializationUtil.registerEventListener(vehicleType, "onUpdate", AdditionalInputsSpec)
  SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", AdditionalInputsSpec)
end

function AdditionalInputsSpec.registerFunctions(vehicleType)
  SpecializationUtil.registerFunction(vehicleType, "vdAIGetCenterNode", AdditionalInputsSpec.vdAIGetCenterNode)
  SpecializationUtil.registerFunction(vehicleType, "vdAIGetAttacherJointPosition", AdditionalInputsSpec.vdAIGetAttacherJointPosition)
  SpecializationUtil.registerFunction(vehicleType, "vdAIActionEvent", AdditionalInputsSpec.vdAIActionEvent)
  SpecializationUtil.registerFunction(vehicleType, "vdAISetTurnLightState", AdditionalInputsSpec.vdAISetTurnLightState)
end

function AdditionalInputsSpec:onLoad(savegame)
  self.spec_additionalInputs = {
    debugger = GrisuDebug:create("AdditionalInputsSpec"),
    actionEvents = {},
    -- indicator tip
    indicatorTipActive = false,
    indicatorTipDirection = nil, -- Lights.TURNLIGHT_LEFT or Lights.TURNLIGHT_RIGHT
    indicatorTipTimer = 0,
    indicatorTipDuration = 3000 -- 3 seconds in milliseconds
  }
  self.spec_additionalInputs.debugger:setLogLvl(g_vdAdditionalInputs.specLogLevel)
  self.spec_additionalInputs.debugger:trace("onLoad")
end

function AdditionalInputsSpec:onEnterVehicle(isControlling)
  if g_gameGlass ~= nil then
    local spec = self.spec_additionalInputs
    spec.debugger:trace(function()
      return "onEnterVehicle(" .. tostring(isControlling) .. ")"
    end)

    --spec.debugger:tPrint("vehicle.self.spec_motorized", self.spec_motorized)

    g_gameGlass:setCurrentVehicle(self)
  end
end

function AdditionalInputsSpec:onLeaveVehicle(wasEntered)
  if g_gameGlass ~= nil then
    local spec = self.spec_additionalInputs
    spec.debugger:trace(function()
      return "onLeaveVehicle(" .. tostring(wasEntered) .. ")"
    end)
    g_gameGlass:clearCurrentVehicle()
  end
end

---Called on update
---@param dt number time since last call in ms
---@param isActiveForInput boolean true if vehicle is active for input
---@param isSelected boolean true if vehicle is selected
function AdditionalInputsSpec:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
  local spec = self.spec_additionalInputs

  -- Handle indicator tip function
  if spec.indicatorTipActive then
    spec.indicatorTipTimer = spec.indicatorTipTimer + dt

    -- If the tip duration has passed, turn the indicator off
    if spec.indicatorTipTimer >= spec.indicatorTipDuration then
      -- Turn off the indicator
      self:vdAISetTurnLightState(Lights.TURNLIGHT_OFF)

      -- Reset tip function state
      spec.indicatorTipActive = false
      spec.indicatorTipDirection = nil
      spec.indicatorTipTimer = 0

      spec.debugger:trace("Tip function completed, indicator turned off")
    end
  end

end

function AdditionalInputsSpec:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
  if self.isClient then
    local spec = self.spec_additionalInputs
    self:clearActionEventsTable(spec.actionEvents)

    if not self:getIsActiveForInput(true) then
      return
    end

    -- indicators
    self:addActionEvent(spec.actionEvents, "VD_AI_INDICATOR_LEFT_ON", self, AdditionalInputsSpec.actionEventIndicatorOn, false, true, false, true, nil)
    self:addActionEvent(spec.actionEvents, "VD_AI_INDICATOR_RIGHT_ON", self, AdditionalInputsSpec.actionEventIndicatorOn, false, true, false, true, nil)
    self:addActionEvent(spec.actionEvents, "VD_AI_INDICATOR_OFF", self, AdditionalInputsSpec.actionEventIndicatorOff, false, true, false, true, nil)

    -- light
    self:addActionEvent(spec.actionEvents, "VD_AI_LOW_BEAM_ON", self, AdditionalInputsSpec.actionEventLowBeamOn, false, true, false, true, nil)
    self:addActionEvent(spec.actionEvents, "VD_AI_LOW_BEAM_OFF", self, AdditionalInputsSpec.actionEventLowBeamOff, false, true, false, true, nil)
    self:addActionEvent(spec.actionEvents, "VD_AI_FRONT_WORK_LIGHT_ON", self, AdditionalInputsSpec.actionEventFrontWorkLightOn, false, true, false, true, nil)

    self:addActionEvent(spec.actionEvents, "VD_AI_HIGH_BEAM_ON", self, AdditionalInputsSpec.actionEventHighBeamOn, false, true, false, true, nil)
    self:addActionEvent(spec.actionEvents, "VD_AI_HIGH_BEAM_OFF_FLASH_TRIGGER", self, AdditionalInputsSpec.actionEventHighBeamOffTrigger, false, true, false, true, nil)
    self:addActionEvent(spec.actionEvents, "VD_AI_HIGH_BEAM_OFF_FLASH_RELEASE", self, AdditionalInputsSpec.actionEventHighBeamOffRelease, false, true, false, true, nil)

    -- implements
    self:addActionEvent(spec.actionEvents, "VD_AI_LOWER_FRONT", self, AdditionalInputsSpec.actionEventLower, false, true, false, true, nil)
    self:addActionEvent(spec.actionEvents, "VD_AI_LOWER_BACK", self, AdditionalInputsSpec.actionEventLower, false, true, false, true, nil)
    self:addActionEvent(spec.actionEvents, "VD_AI_FOLD_FRONT", self, AdditionalInputsSpec.actionEventFold, false, true, false, true, nil)
    self:addActionEvent(spec.actionEvents, "VD_AI_FOLD_BACK", self, AdditionalInputsSpec.actionEventFold, false, true, false, true, nil)
    self:addActionEvent(spec.actionEvents, "VD_AI_ACTIVATE_FRONT", self, AdditionalInputsSpec.actionEventActivate, false, true, false, true, nil)
    self:addActionEvent(spec.actionEvents, "VD_AI_ACTIVATE_BACK", self, AdditionalInputsSpec.actionEventActivate, false, true, false, true, nil)

    for _, actionEvent in pairs(spec.actionEvents) do
      if actionEvent.actionEventId ~= nil then
        g_inputBinding:setActionEventTextVisibility(actionEvent.actionEventId, false)
        g_inputBinding:setActionEventTextPriority(actionEvent.actionEventId, GS_PRIO_VERY_LOW)
      end
    end
  end

end

function AdditionalInputsSpec:actionEventIndicatorOn(actionName, inputValue, callbackState, isAnalog)
  local spec = self.spec_additionalInputs

  local direction = nil
  if actionName == "VD_AI_INDICATOR_LEFT_ON" then
    direction = Lights.TURNLIGHT_LEFT
  else
    direction = Lights.TURNLIGHT_RIGHT
  end

  -- Store the direction and current time
  spec.lastIndicatorOnDirection = direction
  spec.lastIndicatorOnTime = g_time

  -- Call the existing turn light function (assuming it exists)
  if direction ~= nil then
    self:vdAISetTurnLightState(direction)
  end

  spec.debugger:trace(function()
    return "actionEventIndicatorOn: " .. tostring(direction)
  end)

end

function AdditionalInputsSpec:actionEventIndicatorOff(actionName, inputValue, callbackState, isAnalog)
  local spec = self.spec_additionalInputs

  -- Check if indicator was turned on recently (within 300ms)
  if spec.lastIndicatorOnTime ~= nil and g_time - spec.lastIndicatorOnTime < 500 then
    -- Activate the tip function
    spec.indicatorTipActive = true
    spec.indicatorTipDirection = spec.lastIndicatorOnDirection
    spec.indicatorTipTimer = 0

    spec.debugger:trace(function()
      return "Tip function activated for direction: " .. tostring(spec.indicatorTipDirection)
    end)
  else
    -- Regular indicator off behavior
    -- Call the existing turn light function (assuming it exists)
    self:vdAISetTurnLightState(Lights.TURNLIGHT_OFF)

    -- reset tip indicator variables
    spec.indicatorTipActive = false
    spec.indicatorTipDirection = nil
    spec.indicatorTipTimer = 0
  end

  -- Reset the tracking variables
  spec.lastIndicatorOnDirection = nil
  spec.lastIndicatorOnTime = nil

  spec.debugger:trace("actionEventIndicatorOff")
end

function AdditionalInputsSpec:vdAISetTurnLightState(targetState)
  local sl = self.spec_lights
  if sl == nil then
    return
  end

  self.spec_additionalInputs.debugger:trace("sl.turnLightState: " .. tostring(sl.turnLightState) .. ", target: " .. tostring(targetState))
  if sl.turnLightState ~= targetState and sl.turnLightState ~= Lights.TURNLIGHT_HAZARD then
    self:setTurnLightState(targetState)
  end
end

function AdditionalInputsSpec:actionEventLowBeamOn(actionName, inputValue, callbackState, isAnalog)
  local sl = self.spec_lights
  if sl == nil then
    return
  end
  -- we can toggle the light and it is currently off
  if self:getCanToggleLight() and (bitAND(sl.lightsTypesMask, 2 ^ Lights.LIGHT_TYPE_DEFAULT) == 0 or bitAND(sl.lightsTypesMask, 2 ^ Lights.LIGHT_TYPE_WORK_FRONT) ~= 0) then
    if sl.numLightTypes >= 1 then
      -- turn on frontLight
      local newMask = bitOR(sl.lightsTypesMask, 2 ^ Lights.LIGHT_TYPE_DEFAULT)
      -- turn off work light front
      newMask = bitAND(newMask, bitNOT(2 ^ Lights.LIGHT_TYPE_WORK_FRONT))
      self:setLightsTypesMask(newMask)
    end
  end
end

function AdditionalInputsSpec:actionEventLowBeamOff(actionName, inputValue, callbackState, isAnalog)
  local sl = self.spec_lights
  if sl == nil then
    return
  end
  -- we can toggle the light and it is currently off
  if self:getCanToggleLight() and bitAND(sl.lightsTypesMask, 2 ^ Lights.LIGHT_TYPE_DEFAULT) ~= 0 then
    if sl.numLightTypes >= 1 then
      -- turn of front light
      local newMask = bitAND(sl.lightsTypesMask, bitNOT(2 ^ Lights.LIGHT_TYPE_DEFAULT))
      self:setLightsTypesMask(newMask)
    end
  end
end

function AdditionalInputsSpec:actionEventFrontWorkLightOn(actionName, inputValue, callbackState, isAnalog)
  local sl = self.spec_lights
  if sl == nil then
    return
  end
  -- we can toggle the light and it is currently off
  if self:getCanToggleLight() and bitAND(sl.lightsTypesMask, 2 ^ Lights.LIGHT_TYPE_WORK_FRONT) == 0 then
    if sl.numLightTypes >= 1 then
      -- turn on front work lights
      local newMask = bitOR(sl.lightsTypesMask, 2 ^ Lights.LIGHT_TYPE_WORK_FRONT)
      self:setLightsTypesMask(newMask)
    end
  end
end

function AdditionalInputsSpec:actionEventHighBeamOn(actionName, inputValue, callbackState, isAnalog)
  self.spec_additionalInputs.debugger:trace("actionEventHighBeamOn")
  local sl = self.spec_lights
  if sl == nil then
    return
  end
  -- we can toggle the light and it is currently off
  if self:getCanToggleLight() and bitAND(sl.lightsTypesMask, 2 ^ Lights.LIGHT_TYPE_HIGHBEAM) == 0 then
    if sl.numLightTypes >= 1 then
      -- turn on high beams
      local newMask = bitOR(sl.lightsTypesMask, 2 ^ Lights.LIGHT_TYPE_HIGHBEAM)
      self:setLightsTypesMask(newMask)
    end
  end
end

function AdditionalInputsSpec:actionEventHighBeamOffTrigger(actionName, inputValue, callbackState, isAnalog)
  self.spec_additionalInputs.debugger:trace("actionEventHighBeamOffTrigger")
  local sl = self.spec_lights
  if sl == nil then
    return
  end
  -- we can toggle the light and it is currently off
  if self:getCanToggleLight() and sl.numLightTypes >= 1 then
    if bitAND(sl.lightsTypesMask, 2 ^ Lights.LIGHT_TYPE_HIGHBEAM) ~= 0 then
      -- if high beams are on, we turn them off
      -- turn off high beams
      local newMask = bitAND(sl.lightsTypesMask, bitNOT(2 ^ Lights.LIGHT_TYPE_HIGHBEAM))
      self.spec_additionalInputs.debugger:error("Turn off high beams, newMask: " .. tostring(newMask) .. " old: " .. tostring(sl.lightsTypesMask))
      self:setLightsTypesMask(newMask)
    else
      -- high beams are off, so this is a flash
      -- turn on high beams
      local newMask = bitOR(sl.lightsTypesMask, 2 ^ Lights.LIGHT_TYPE_HIGHBEAM)
      self.spec_additionalInputs.debugger:error("Turn on high beams, newMask: " .. tostring(newMask) .. " old: " .. tostring(sl.lightsTypesMask))
      self:setLightsTypesMask(newMask)
    end
  end
end

function AdditionalInputsSpec:actionEventHighBeamOffRelease(actionName, inputValue, callbackState, isAnalog)
  self.spec_additionalInputs.debugger:trace("actionEventHighBeamOffReleased")
  local sl = self.spec_lights
  if sl == nil then
    return
  end
  -- we can toggle the light and it is currently off
  if self:getCanToggleLight() and bitAND(sl.lightsTypesMask, 2 ^ Lights.LIGHT_TYPE_HIGHBEAM) ~= 0 then
    if sl.numLightTypes >= 1 then
      -- turn of front light
      local newMask = bitAND(sl.lightsTypesMask, bitNOT(2 ^ Lights.LIGHT_TYPE_HIGHBEAM))
      self.spec_additionalInputs.debugger:error("Turn off high beams, newMask: " .. tostring(newMask) .. " old: " .. tostring(sl.lightsTypesMask))
      self:setLightsTypesMask(newMask)
    end
  end
end

function AdditionalInputsSpec:actionEventLower(actionName, inputValue, callbackState, isAnalog)
  self.spec_additionalInputs.debugger:trace("actionEventLower called with actionName: %s, inputValue: %s, callbackState: %s, isAnalog: %s", actionName, inputValue, callbackState, isAnalog)
  local isPowered, powerWarning = self:getIsPowered()

  local debugger = self.spec_additionalInputs.debugger
  self:vdAIActionEvent(actionName, function(object, attachedImplement, forceState)
    local newState = forceState
    --getAllowsLowering is not to be implemented for pickup and foldable (this uses getIsFoldMiddleAllowed for lowering), but getIsLowered is
    local allowsLowering, warning = object:getAllowsLowering()

    --TODO improve this if
    if isPowered and (allowsLowering
        or object.spec_pickup ~= nil
        or (object.getIsFoldMiddleAllowed ~= nil
        and object:getIsFoldMiddleAllowed())) then
      if newState == nil then
        newState = not object:getIsLowered()
      end
      debugger:trace("Lowering is allowed, newState: %s", newState)
      object:setLoweredAll(newState, attachedImplement.jointDescIndex)
      return newState
    elseif warning ~= nil then
      g_currentMission:showBlinkingWarning(warning, 2000)
    elseif powerWarning ~= nil then
      g_currentMission:showBlinkingWarning(powerWarning, 2000)
    end
  end)
end

function AdditionalInputsSpec:actionEventFold(actionName, inputValue, callbackState, isAnalog)
  self.spec_additionalInputs.debugger:trace("actionEventFold called with actionName: %s, inputValue: %s, callbackState: %s, isAnalog: %s", actionName, inputValue, callbackState, isAnalog)
  local isPowered, powerWarning = self:getIsPowered()

  self:vdAIActionEvent(actionName, function(object, attachedImplement, forceState)
    if object.spec_foldable == nil then
      return forceState
    end

    local fSpec = object.spec_foldable
    if #fSpec.foldingParts > 0 then
      local direction = object:getToggledFoldDirection()
      local allowed, warning = object:getIsFoldAllowed(direction, false)
      local requiresPower = fSpec.requiresPower
      local newState = forceState

      if allowed and (not requiresPower or isPowered) then
        if newState == nil then
          newState = direction == fSpec.turnOnFoldDirection
        end
        if newState then
          object:setFoldState(direction, true)
        else
          object:setFoldState(direction, false)

          if object:getIsFoldMiddleAllowed() and object.getAttacherVehicle ~= nil then
            local attacherVehicle = object:getAttacherVehicle()
            local attacherJointIndex = attacherVehicle:getAttacherJointIndexFromObject(object)

            if attacherJointIndex ~= nil then
              local moveDown = attacherVehicle:getJointMoveDown(attacherJointIndex)
              local targetMoveDown = direction == fSpec.turnOnFoldDirection

              if targetMoveDown ~= moveDown then
                attacherVehicle:setJointMoveDown(attacherJointIndex, targetMoveDown)
              end
            end
          end
        end
        return newState
      elseif warning ~= nil then
        g_currentMission:showBlinkingWarning(warning, 2000)
      elseif powerWarning ~= nil then
        g_currentMission:showBlinkingWarning(powerWarning, 2000)
      end
    end
  end)
end

function AdditionalInputsSpec:actionEventActivate(actionName, inputValue, callbackState, isAnalog)
  self.spec_additionalInputs.debugger:trace("actionEventActivate called with actionName: %s, inputValue: %s, callbackState: %s, isAnalog: %s", actionName, inputValue, callbackState, isAnalog)

  self:vdAIActionEvent(actionName, function(object, attachedImplement, forceState)
    -- check if object has turned on thing
    local newState = forceState
    if object.getIsTurnedOn ~= nil and object:getCanToggleTurnedOn() and object:getCanBeTurnedOn() then
      if newState == nil then
        newState = not object:getIsTurnedOn()
      end
      object:setIsTurnedOn(newState)
      return newState
    end
  end)
end

---@param actionName string
---@param callback function
---@param forceState boolean
function AdditionalInputsSpec:vdAIActionEvent(actionName, callback, forceState)
  local ajSpec = self.spec_attacherJoints
  if ajSpec == nil then
    return
  end
  local targetPosition
  if string.endsWith(actionName, "FRONT") then
    targetPosition = "FRONT"
  else
    targetPosition = "BACK"
  end

  for index, attachedImplement in pairs(ajSpec.attachedImplements) do
    local position
    if forceState ~= nil then
      position = targetPosition
    else
      position = self:vdAIGetAttacherJointPosition(attachedImplement)
    end
    local object = attachedImplement.object

    if position == targetPosition then
      local newState = callback(object, attachedImplement, forceState)
      if newState ~= nil then
        AdditionalInputsSpec.vdAIActionEvent(object, actionName, callback, newState)
      end
    end
  end
end

function AdditionalInputsSpec:vdAIGetCenterNode()
  return self.rootNode
end

---@return AttacherJointPosition
function AdditionalInputsSpec:vdAIGetAttacherJointPosition(attachedImplement)
  local ajSpec = self.spec_attacherJoints
  --try to estimate if implement is in the front or back
  local jointDesc = ajSpec.attacherJoints[attachedImplement.jointDescIndex]

  local wx, wy, wz = getWorldTranslation(jointDesc.jointTransform)
  local _, _, lz = worldToLocal(self:vdAIGetCenterNode(), wx, wy, wz)

  local position
  if lz > 0 then
    position = "FRONT"
  else
    position = "BACK"
  end
  return position
end