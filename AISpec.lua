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
  SpecializationUtil.registerFunction(vehicleType, "vdAIApplyToImplements", AdditionalInputsSpec.vdAIApplyToImplements)
  SpecializationUtil.registerFunction(vehicleType, "vdAISetTurnLightState", AdditionalInputsSpec.vdAISetTurnLightState)

  -- public implement control API, also callable directly by other mods (e.g. vdTelemetry)
  SpecializationUtil.registerFunction(vehicleType, "vdAILowerFront", AdditionalInputsSpec.vdAILowerFront)
  SpecializationUtil.registerFunction(vehicleType, "vdAILowerBack", AdditionalInputsSpec.vdAILowerBack)
  SpecializationUtil.registerFunction(vehicleType, "vdAIFoldFront", AdditionalInputsSpec.vdAIFoldFront)
  SpecializationUtil.registerFunction(vehicleType, "vdAIFoldBack", AdditionalInputsSpec.vdAIFoldBack)
  SpecializationUtil.registerFunction(vehicleType, "vdAIActivateFront", AdditionalInputsSpec.vdAIActivateFront)
  SpecializationUtil.registerFunction(vehicleType, "vdAIActivateBack", AdditionalInputsSpec.vdAIActivateBack)
  SpecializationUtil.registerFunction(vehicleType, "vdAILowerVehicle", AdditionalInputsSpec.vdAILowerVehicle)
  SpecializationUtil.registerFunction(vehicleType, "vdAIFoldVehicle", AdditionalInputsSpec.vdAIFoldVehicle)
  SpecializationUtil.registerFunction(vehicleType, "vdAIActivateVehicle", AdditionalInputsSpec.vdAIActivateVehicle)
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
  if g_vdTelemetry ~= nil then
    local spec = self.spec_additionalInputs
    spec.debugger:trace(function()
      return "onEnterVehicle(" .. tostring(isControlling) .. ")"
    end)

    g_vdTelemetry:setCurrentVehicle(self)
  end
end

function AdditionalInputsSpec:onLeaveVehicle(wasEntered)
  if g_vdTelemetry ~= nil then
    local spec = self.spec_additionalInputs
    spec.debugger:trace(function()
      return "onLeaveVehicle(" .. tostring(wasEntered) .. ")"
    end)
    g_vdTelemetry:clearCurrentVehicle()
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
      self.spec_additionalInputs.debugger:trace("Turn off high beams, newMask: " .. tostring(newMask) .. " old: " .. tostring(sl.lightsTypesMask))
      self:setLightsTypesMask(newMask)
    else
      -- high beams are off, so this is a flash
      -- turn on high beams
      local newMask = bitOR(sl.lightsTypesMask, 2 ^ Lights.LIGHT_TYPE_HIGHBEAM)
      self.spec_additionalInputs.debugger:trace("Turn on high beams, newMask: " .. tostring(newMask) .. " old: " .. tostring(sl.lightsTypesMask))
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
      self.spec_additionalInputs.debugger:trace("Turn off high beams, newMask: " .. tostring(newMask) .. " old: " .. tostring(sl.lightsTypesMask))
      self:setLightsTypesMask(newMask)
    end
  end
end

---Toggle (or set) the lowered state of a single object.
---@param object table the vehicle or implement to act on
---@param jointDescIndex number|nil restrict to this attacher joint, nil to affect all
---@param targetState boolean|nil when set, forces this state instead of toggling
---@return boolean|nil newState the applied state, or nil if nothing was changed
local function lowerObject(object, jointDescIndex, targetState, isPowered, powerWarning, debugger)
  local newState = targetState
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
    object:setLoweredAll(newState, jointDescIndex)
    return newState
  elseif warning ~= nil then
    g_currentMission:showBlinkingWarning(warning, 2000)
  elseif powerWarning ~= nil then
    g_currentMission:showBlinkingWarning(powerWarning, 2000)
  end
end

---Toggle (or set) the folding state of a single object. Caller must ensure object.spec_foldable ~= nil.
---@param object table the vehicle or implement to act on
---@param targetState boolean|nil true folds, false unfolds; nil toggles
---@return boolean|nil newState the requested folded state, or nil if nothing was changed
local function foldObject(object, targetState, isPowered, powerWarning, debugger)
  local fSpec = object.spec_foldable
  if #fSpec.foldingParts > 0 then
    -- turnOnFoldDirection leads to the turn-on-able state, which requires the machine unfolded.
    local unfoldDirection = fSpec.turnOnFoldDirection

    -- Where the machine comes to rest: while an animation runs, the committed move direction is
    -- what it will end up as, so a command reversing an in-flight fold is not read as a no-op.
    local isFolded
    if fSpec.foldMoveDirection ~= 0 then
      isFolded = fSpec.foldMoveDirection ~= unfoldDirection
    else
      isFolded = not object:getIsUnfolded()
    end

    local newState = targetState
    if newState == nil then
      newState = not isFolded
    elseif newState == isFolded then
      -- already where it was asked to be; return the state so child implements still get the command
      debugger:trace("Fold already in requested state: %s", tostring(newState))
      return newState
    end

    local direction = newState and -unfoldDirection or unfoldDirection
    local allowed, warning = object:getIsFoldAllowed(direction, false)
    local requiresPower = fSpec.requiresPower

    if allowed and (not requiresPower or isPowered) then
      debugger:trace("Folding is allowed, newState: %s, direction: %s", tostring(newState), tostring(direction))
      if not newState then
        object:setFoldState(direction, true)
      else
        object:setFoldState(direction, false)

        if object:getIsFoldMiddleAllowed() and object.getAttacherVehicle ~= nil then
          local attacherVehicle = object:getAttacherVehicle()
          local attacherJointIndex = attacherVehicle:getAttacherJointIndexFromObject(object)

          if attacherJointIndex ~= nil then
            local moveDown = attacherVehicle:getJointMoveDown(attacherJointIndex)
            local targetMoveDown = direction == unfoldDirection

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
end

---Toggle (or set) the turned-on state of a single object.
---@param object table the vehicle or implement to act on
---@param targetState boolean|nil when set, forces this state instead of toggling
---@return boolean|nil newState the applied state, or nil if nothing was changed
local function activateObject(object, targetState, debugger)
  -- check if object has turned on thing
  local newState = targetState
  if object.getIsTurnedOn ~= nil and object:getCanToggleTurnedOn() and object:getCanBeTurnedOn() then
    if newState == nil then
      newState = not object:getIsTurnedOn()
    end
    object:setIsTurnedOn(newState)
    return newState
  end
end

---Toggle (or set) the lowered state of all implements attached at the given position.
---@param vehicle table
---@param position AttacherJointPosition
---@param forceState boolean|nil when set, forces this state instead of toggling
local function doLower(vehicle, position, forceState)
  local debugger = vehicle.spec_additionalInputs.debugger
  debugger:trace("doLower called with position: %s, forceState: %s", position, tostring(forceState))
  local isPowered, powerWarning = vehicle:getIsPowered()

  vehicle:vdAIApplyToImplements(position, function(object, attachedImplement, targetState)
    return lowerObject(object, attachedImplement.jointDescIndex, targetState, isPowered, powerWarning, debugger)
  end, forceState)
end

---Toggle (or set) the folding state of all implements attached at the given position.
---@param vehicle table
---@param position AttacherJointPosition
---@param forceState boolean|nil true folds, false unfolds; nil toggles
local function doFold(vehicle, position, forceState)
  local debugger = vehicle.spec_additionalInputs.debugger
  debugger:trace("doFold called with position: %s, forceState: %s", position, tostring(forceState))
  local isPowered, powerWarning = vehicle:getIsPowered()

  vehicle:vdAIApplyToImplements(position, function(object, attachedImplement, targetState)
    if object.spec_foldable == nil then
      -- not foldable itself, but keep cascading into its child implements
      return targetState
    end
    return foldObject(object, targetState, isPowered, powerWarning, debugger)
  end, forceState)
end

---Toggle (or set) the turned-on state of all implements attached at the given position.
---@param vehicle table
---@param position AttacherJointPosition
---@param forceState boolean|nil when set, forces this state instead of toggling
local function doActivate(vehicle, position, forceState)
  local debugger = vehicle.spec_additionalInputs.debugger
  debugger:trace("doActivate called with position: %s, forceState: %s", position, tostring(forceState))

  vehicle:vdAIApplyToImplements(position, function(object, attachedImplement, targetState)
    return activateObject(object, targetState, debugger)
  end, forceState)
end

---Toggle or set the lowered state of all implements attached at the front.
---@param forceState boolean|nil when set, forces this state instead of toggling
function AdditionalInputsSpec:vdAILowerFront(forceState)
  doLower(self, "FRONT", forceState)
end

---Toggle or set the lowered state of all implements attached at the back.
---@param forceState boolean|nil when set, forces this state instead of toggling
function AdditionalInputsSpec:vdAILowerBack(forceState)
  doLower(self, "BACK", forceState)
end

---Toggle or set the folding state of all implements attached at the front.
---@param forceState boolean|nil true folds, false unfolds; nil toggles
function AdditionalInputsSpec:vdAIFoldFront(forceState)
  doFold(self, "FRONT", forceState)
end

---Toggle or set the folding state of all implements attached at the back.
---@param forceState boolean|nil true folds, false unfolds; nil toggles
function AdditionalInputsSpec:vdAIFoldBack(forceState)
  doFold(self, "BACK", forceState)
end

---Toggle or set the turned-on state of all implements attached at the front.
---@param forceState boolean|nil when set, forces this state instead of toggling
function AdditionalInputsSpec:vdAIActivateFront(forceState)
  doActivate(self, "FRONT", forceState)
end

---Toggle or set the turned-on state of all implements attached at the back.
---@param forceState boolean|nil when set, forces this state instead of toggling
function AdditionalInputsSpec:vdAIActivateBack(forceState)
  doActivate(self, "BACK", forceState)
end

---Toggle or set the lowered state of the vehicle itself. No-op if the vehicle cannot be lowered.
---@param forceState boolean|nil when set, forces this state instead of toggling
function AdditionalInputsSpec:vdAILowerVehicle(forceState)
  local debugger = self.spec_additionalInputs.debugger
  debugger:trace("vdAILowerVehicle called with forceState: %s", tostring(forceState))
  local isPowered, powerWarning = self:getIsPowered()

  -- Self-propelled machines with an integrated pickup (baler, forage wagon, ...) lower the pickup
  -- through the Pickup spec, independent of folding.
  local pickupSpec = self.spec_pickup
  if pickupSpec ~= nil and self.setPickupState ~= nil then
    local doLower = forceState
    if doLower == nil then
      doLower = not pickupSpec.isLowered
    end
    if self:getCanChangePickupState(pickupSpec, doLower) then
      debugger:trace("Lowering vehicle pickup, doLower: %s", tostring(doLower))
      self:setPickupState(doLower)
    end
    return
  end

  -- Self-propelled machines (mower, ...) lower their integrated tool through the foldable
  -- "fold middle" mechanism, not the attacher-joint lowering used for attached implements.
  if self.getIsFoldMiddleAllowed ~= nil and self:getIsFoldMiddleAllowed() then
    if not isPowered then
      if powerWarning ~= nil then
        g_currentMission:showBlinkingWarning(powerWarning, 2000)
      end
      return
    end

    local doLower = forceState
    if doLower == nil and self.getIsLowered ~= nil then
      doLower = not self:getIsLowered()
    end
    debugger:trace("Lowering vehicle via fold middle, doLower: %s", tostring(doLower))
    self:setFoldMiddleState(doLower)
    return
  end

  -- Fallback: classic attacher-joint based lowering
  if self.getAllowsLowering == nil or self.setLoweredAll == nil then
    return
  end
  lowerObject(self, nil, forceState, isPowered, powerWarning, debugger)
end

---Toggle or set the folding state of the vehicle itself. No-op if the vehicle is not foldable.
---@param forceState boolean|nil true folds, false unfolds; nil toggles
function AdditionalInputsSpec:vdAIFoldVehicle(forceState)
  local debugger = self.spec_additionalInputs.debugger
  debugger:trace("vdAIFoldVehicle called with forceState: %s", tostring(forceState))
  if self.spec_foldable == nil then
    return
  end
  local isPowered, powerWarning = self:getIsPowered()
  foldObject(self, forceState, isPowered, powerWarning, debugger)
end

---Toggle or set the turned-on state of the vehicle itself. No-op if the vehicle cannot be turned on.
---@param forceState boolean|nil when set, forces this state instead of toggling
function AdditionalInputsSpec:vdAIActivateVehicle(forceState)
  local debugger = self.spec_additionalInputs.debugger
  debugger:trace("vdAIActivateVehicle called with forceState: %s", tostring(forceState))
  activateObject(self, forceState, debugger)
end

function AdditionalInputsSpec:actionEventLower(actionName, inputValue, callbackState, isAnalog)
  self.spec_additionalInputs.debugger:trace("actionEventLower called with actionName: %s, inputValue: %s, callbackState: %s, isAnalog: %s", actionName, inputValue, callbackState, isAnalog)
  doLower(self, string.endsWith(actionName, "FRONT") and "FRONT" or "BACK")
end

function AdditionalInputsSpec:actionEventFold(actionName, inputValue, callbackState, isAnalog)
  self.spec_additionalInputs.debugger:trace("actionEventFold called with actionName: %s, inputValue: %s, callbackState: %s, isAnalog: %s", actionName, inputValue, callbackState, isAnalog)
  doFold(self, string.endsWith(actionName, "FRONT") and "FRONT" or "BACK")
end

function AdditionalInputsSpec:actionEventActivate(actionName, inputValue, callbackState, isAnalog)
  self.spec_additionalInputs.debugger:trace("actionEventActivate called with actionName: %s, inputValue: %s, callbackState: %s, isAnalog: %s", actionName, inputValue, callbackState, isAnalog)
  doActivate(self, string.endsWith(actionName, "FRONT") and "FRONT" or "BACK")
end

---Applies a callback to every implement attached at the given position, cascading into child implements.
---@param position AttacherJointPosition target position "FRONT" or "BACK"
---@param callback function called as callback(object, attachedImplement, targetState); returns the new state to cascade, or nil to stop
---@param forceState boolean|nil target state handed to the callback; nil means toggle
---@param cascadeAll boolean|nil internal: when true, skip position estimation and apply to every attached implement (used while cascading)
function AdditionalInputsSpec:vdAIApplyToImplements(position, callback, forceState, cascadeAll)
  local ajSpec = self.spec_attacherJoints
  if ajSpec == nil then
    return
  end

  for _, attachedImplement in pairs(ajSpec.attachedImplements) do
    local matches
    if cascadeAll then
      matches = true
    else
      matches = self:vdAIGetAttacherJointPosition(attachedImplement) == position
    end

    if matches then
      local object = attachedImplement.object
      local newState = callback(object, attachedImplement, forceState)
      if newState ~= nil then
        AdditionalInputsSpec.vdAIApplyToImplements(object, position, callback, newState, true)
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
