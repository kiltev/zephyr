local CLASS_NAME = "Arctic Zephyr"
local POOL_NAME = "Rimearc Pool"
local TOKEN_NAME = "Rimearc"
local TOKEN_IMAGE = "https://raw.githubusercontent.com/kiltev/zephyr/main/resources/icons/rimearc.png"
local DISK_MESH = "https://raw.githubusercontent.com/kiltev/zephyr/main/resources/rimearc_disk.obj"
local DISK_MESH_DIAMETER = 2
local DISK_MESH_HEIGHT = 0.2
local TOKEN_TAGS = { "Has Action", "Has Aid Tokens", "Has Conditions", "Has Health", "Terrain" }
local TOKEN_SCALE = { x = 0.35, y = 0.6, z = 0.35 }
local TOKEN_SHAPE = { Thickness = 0.2, MergeDistance = 15, Stackable = false }
local TOKEN_LOAD_TIMEOUT_SECONDS = 8
local MEASURING_DEPTH = -5
local CARDBOARD_MATERIAL = 3
local INFINITE_BAG_TYPE = 7
local SLOT_RIGHT_OF_LOCKED_MODIFIERS = { -0.192, 0.1, 0.912 }
local PLAYER_MAT_TAG = "Player Mat"
local OWNER_TAG_PREFIX = "Owner "
local REGISTER_DELAY_SECONDS = 0.5

local function poolExists()
    for _, object in ipairs(getObjects()) do
        if object.getName() == POOL_NAME then return true end
    end
    return false
end

local function playerMat(playerNumber)
    for _, object in ipairs(getObjectsWithTag(OWNER_TAG_PREFIX .. playerNumber)) do
        if object.hasTag(PLAYER_MAT_TAG) then return object end
    end
    return nil
end

local function transform(position, scale)
    return {
        posX = position.x, posY = position.y, posZ = position.z,
        scaleX = scale.x, scaleY = scale.y, scaleZ = scale.z,
    }
end

local function tokenData(position)
    return {
        Name = "Custom_Token",
        Nickname = TOKEN_NAME,
        Tags = TOKEN_TAGS,
        Transform = transform(position, TOKEN_SCALE),
        CustomImage = { ImageURL = TOKEN_IMAGE, ImageSecondaryURL = "", CustomToken = TOKEN_SHAPE },
    }
end

local function diskMesh()
    return {
        MeshURL = DISK_MESH, DiffuseURL = TOKEN_IMAGE, NormalURL = "", ColliderURL = "",
        Convex = true, MaterialIndex = CARDBOARD_MATERIAL, TypeIndex = INFINITE_BAG_TYPE, CastShadows = true,
    }
end

local function poolData(position, scale)
    return {
        Name = "Custom_Model_Infinite_Bag",
        Nickname = POOL_NAME,
        Transform = transform(position, scale),
        CustomMesh = diskMesh(),
        ContainedObjects = { tokenData(position) },
    }
end

local function diskScaleMatching(token)
    local size = token.getBounds().size
    return { x = size.x / DISK_MESH_DIAMETER, y = size.y / DISK_MESH_HEIGHT, z = size.z / DISK_MESH_DIAMETER }
end

local function isLoaded(token)
    return not token.spawning and not token.loading_custom
end

local function replaceWithPool(measuringToken, position)
    local scale = diskScaleMatching(measuringToken)
    measuringToken.destruct()
    spawnObjectData({ data = poolData(position, scale) })
end

local function spawnPool(position)
    local measuringData = tokenData({ x = position.x, y = MEASURING_DEPTH, z = position.z })
    measuringData.Locked = true
    spawnObjectData({
        data = measuringData,
        callback_function = function(token)
            Wait.condition(function() replaceWithPool(token, position) end, function() return isLoaded(token) end, TOKEN_LOAD_TIMEOUT_SECONDS)
        end,
    })
end

function onCharacterLoad(character, playerNumber)
    if character.class ~= CLASS_NAME or poolExists() then return end
    local mat = playerMat(playerNumber)
    if mat ~= nil then spawnPool(mat.positionToWorld(SLOT_RIGHT_OF_LOCKED_MODIFIERS)) end
end

function __callExtension(request)
    return _G[request.event](table.unpack(request.parameters))
end

function onLoad()
    Wait.time(function()
        Global.call("__registerExtensions", { __caller = self.getGUID() })
    end, REGISTER_DELAY_SECONDS)
end
