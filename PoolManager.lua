local Queue = require "Core/Collections/Queue"
local AssetManager = require "Core/AssetManager"
local Unity = require("Tools/UnityAPI")

local gameObjectType = typeof(Unity.GameObject)

local PoolManager = class()

local rootNode = nil
local nameMap = {}
local poolMap = {}
local parentMap = {}

local HasKey = function(path)
    return poolMap[path] ~= nil
end

local PathToName = function(path)
    if nameMap[path] == nil then
        local splitArray = string.split(path, "/")
        nameMap[path] = splitArray[#splitArray]
    end
    return nameMap[path]
end

local GetParent = function(name)
    if parentMap[name] == nil then
        local gameObject = Unity.GameObject(name .. "Pool")
        gameObject.transform:SetParent(rootNode)
        gameObject.transform.localPosition = Unity.Vector3.zero
        parentMap[name] = gameObject.transform
    end
    return parentMap[name]
end

local Contains = function(name, gameObject)
    if poolMap[name] == nil then
        return false
    end
    return poolMap[name]:Contains(gameObject)
end

PoolManager.Get = function(path, parent, action)
    local name = PathToName(path)

    if HasKey(name) == false then
        poolMap[name] = Queue.New()
    end

    if parent == nil then
        parent = GetParent(name)
    end

    local gameObject = nil

    if poolMap[name].count <= 0 then
        local asset = AssetManager.Load(path, gameObjectType)
        gameObject = AssetManager.Instantiate(asset, parent)
    else
        gameObject = poolMap[name].Dequeue()
        gameObject.transform:SetParent(parent)
        gameObject:SetActive(true)
    end

    if action ~= nil then
        action(gameObject)
    end

    return gameObject
end

PoolManager.Release = function(gameObject)
    if gameObject == nil then
        return
    end

    local name = gameObject.name
    local length = string.len(name) - 7
    name = string.sub(name, 0, length)

    if HasKey(name) == false then
        poolMap[name] = Queue.New()
    end

    if Contains(name, gameObject) then
        print("Internal error. Trying to destroy object that is already released to pool.")
        return
    end

    if gameObject.activeSelf then
        gameObject:SetActive(false)
    end

    poolMap[name]:Enqueue(gameObject)
end

PoolManager.Contains = Contains

PoolManager.ctor = function ()
    rootNode = Unity.GameObject("ObjectPool").transform
end

return PoolManager.new()