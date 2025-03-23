-- AdditionalInputs
--
-- @author  Grisu118 - VertexDezign.net
-- @history     v1.0.0.0 - 2025-03-23 - Initial implementation
-- @Descripion: Registers additional input bindings
-- @web: https://grisu118.ch or https://vertexdezign.net
-- Copyright (C) Grisu118, All Rights Reserved.

local modDirectory = g_currentModDirectory
local modName = g_currentModName

---@class AdditionalInputs
---@field debugger GrisuDebug
---@field settingsXmlFile string
AdditionalInputs = {}
-- Increase this if breaking changes requires an update of GameGlass
AdditionalInputs.MAJOR_VERSION = 1
-- Increase this if a new feature is added and a depending mod requires it
AdditionalInputs.MINOR_VERSION = 0
AdditionalInputs.SETTINGS_XML = "additionalInputsSettings.xml"
AdditionalInputs.SETTINGS_XML_VERSION = 1

local AdditionalInputs_mt = Class(AdditionalInputs)

---@return AdditionalInputs
function AdditionalInputs.init()
  ---@type AdditionalInputs
  local self = {}

  setmetatable(self, AdditionalInputs_mt)

  self.debugger = GrisuDebug:create("AdditionalInputs")
  self.debugger:setLogLvl(GrisuDebug.TRACE)

  self.specLogLevel = GrisuDebug.TRACE

  local modSettingsDir = getUserProfileAppPath() .. "modSettings/"
  self.settingsXmlFile = modSettingsDir .. AdditionalInputs.SETTINGS_XML

  if not fileExists(self.settingsXmlFile) then
    self:writeDefaultSettings()
  end
  self:loadSettingsFromFile()

  self.debugger:info("AdditionalInputs initialized")
  return self
end

function AdditionalInputs:writeDefaultSettings()
  self.debugger:trace("writeDefaultSettings")
  local xml = XMLFile.create("AI", self.settingsXmlFile, "AI")

  xml:setInt("AI#version", 1)
  xml:setString("AI.logging.level", "INFO")
  xml:setString("AI.logging.specLevel", "INFO")

  xml:save()
  xml:delete()
end

function AdditionalInputs:loadSettingsFromFile()
  self.debugger:trace("loadSettingsFromFile")
  local xml = XMLFile.load("AI", self.settingsXmlFile)

  local version = xml:getInt("AI#version", 0)
  if version ~= AdditionalInputs.SETTINGS_XML_VERSION then
    --TODO proper handling?
    self.debugger:error("Unknown settings xml version, setting defaults values")
    self:writeDefaultSettings()
  end

  local logLevel = xml:getString("AI.logging.level", "INFO")
  local specLogLevel = xml:getString("AI.logging.specLevel", "INFO")

  local parseLogLevel = GrisuDebug.parseLogLevel(logLevel)
  self.debugger:setLogLvl(parseLogLevel)
  self.specLogLevel = GrisuDebug.parseLogLevel(specLogLevel)

  xml:delete()
end

function AdditionalInputs:installSpec(typeManager)
  -- register spec
  g_specializationManager:addSpecialization("AdditionalInputsSpec", "AdditionalInputsSpec", Utils.getFilename("AISpec.lua", modDirectory), nil)

  -- add spec to vehicle types
  local totalCount = 0
  local modified = 0
  for typeName, typeEntry in pairs(typeManager:getTypes()) do
    totalCount = totalCount + 1
    if SpecializationUtil.hasSpecialization(Enterable, typeEntry.specializations) and
        not SpecializationUtil.hasSpecialization(Rideable, typeEntry.specializations) and
        not SpecializationUtil.hasSpecialization(ParkVehicle, typeEntry.specializations) then
      typeManager:addSpecialization(typeName, modName .. ".AdditionalInputsSpec")
      modified = modified + 1
      self.debugger:trace("Adding AdditionalInputs spec to " .. typeName)
    else
      self.debugger:trace("Not adding AdditionalInputs spec to " .. typeName)
    end
  end

  self.debugger:info(string.format("Inserted AdditionalInputs spec into %i of %i vehicle types", modified, totalCount))
end

local function installSpec(typeManager)
  if typeManager.typeName == "vehicle" then
    g_additionalInputs:installSpec(typeManager)
  end
end

local function init()
  g_additionalInputs = AdditionalInputs.init()
  -- install spec
  TypeManager.validateTypes = Utils.prependedFunction(TypeManager.validateTypes, installSpec)
end

init()