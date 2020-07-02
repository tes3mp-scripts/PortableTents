local configuration = jsonConfig.Load("portable_tents", {
    limit = 0,
    allowInsideTents = true,
    allowInsideInteriors = false,
    localization = {
        AlreadyPlaced = "You have already placed this tent!",
        InputName = "Input a unique name for your tent:",
        UniqueName = "You've already used that name!",
        LimitExceeded = "You already have the maximum amount of tents!",
        InsideTentInterior = "You can't place a tent inside another tent!",
        InsideInterior = "You can't place tents inside interiors!"
    },
    tents = {
        tent_ashl_01 = {
            teleportToExit = true,
            cellName = "Tent",
            item = {
                collision = true,
                offset = {
                    posX = 0,
                    posY = 0,
                    posZ = -120,
                    rotX = 0,
                    rotY = 0,
                    rotZ = 0
                },
                inventory = {
                    model = "x\\Ex_Ashl_Tent_01.NIF",
                    icon = "n\\ingred_6th_corpusmeat_05.dds",
                    weight = 25,
                    name = "Large Ashlander tent",
                    value = 1000
                }
            },
            doors = {
                entrance = {
                    refId = "ex_ashl_door_01",
                    location = {
                        posX = 0,
                        posY = 0,
                        posZ = 0,
                        rotX = 0,
                        rotY = 0,
                        rotZ = 0
                    },
                    doorDestination = {
                        teleport = true,
                        posX = 0,
                        posY = -160,
                        posZ = 0,
                        rotX = -120,
                        rotY = 0,
                        rotZ = 0
                    }
                },
                exit = {
                    refId = "in_ashl_door_01",
                    location = {
                        posX = 0,
                        posY = 0,
                        posZ = 0,
                        rotX = 0,
                        rotY = 0,
                        rotZ = 0
                    },
                    doorDestination = {
                        teleport = true,
                        posX = 0,
                        posY = -400,
                        posZ = 0,
                        rotX = 0,
                        rotY = 0,
                        rotZ = 0
                    }
                }
            },
            interior = {
                place = {
                    {
                        refId = "in_ashl_tent_01",
                        location = {
                            posX = 0,
                            posY = 0,
                            posZ = 0,
                            rotX = 0,
                            rotY = 0,
                            rotZ = 0
                        },
                    },
                }
            }
        },
        tent_ashl_02 = {
            teleportToExit = true,
            cellName = "Tent",
            item = {
                collision = true,
                offset = {
                    posX = 0,
                    posY = 0,
                    posZ = -120,
                    rotX = 0,
                    rotY = 0,
                    rotZ = 0
                },
                inventory = {
                    model = "x\\Ex_Ashl_Tent_02.NIF",
                    icon = "n\\ingred_6th_corpusmeat_06.dds",
                    weight = 15,
                    name = "Ashlander tent",
                    value = 500
                }
            },
            doors = {
                entrance = {
                    refId = "ex_ashl_door_02",
                    location = {
                        posX = 0,
                        posY = 0,
                        posZ = 0,
                        rotX = 0,
                        rotY = 0,
                        rotZ = 0
                    },
                    doorDestination = {
                        teleport = true,
                        posX = 0,
                        posY = 0,
                        posZ = 0,
                        rotX = 0,
                        rotY = 0,
                        rotZ = 0
                    }
                },
                exit = {
                    refId = "in_ashl_door_02",
                    location = {
                        posX = 0,
                        posY = 0,
                        posZ = 0,
                        rotX = 0,
                        rotY = 0,
                        rotZ = 0
                    },
                    doorDestination = {
                        teleport = true,
                        posX = 0,
                        posY = -300,
                        posZ = 0,
                        rotX = 0,
                        rotY = 0,
                        rotZ = 0
                    }
                }
            },
            interior = {
                place = {
                    {
                        refId = "in_ashl_tent_02",
                        location = {
                            posX = 0,
                            posY = 0,
                            posZ = 0,
                            rotX = 0,
                            rotY = 0,
                            rotZ = 0
                        },
                    },
                }
            }
        }
    }
})

local RECORD_TYPE = "miscellaneous"

local tentStorage = storage.Load("urm_portable_tents", {
    records = {} --[[
        refId = {
            baseId = ,
            interiorDescription = ,
            exteriorDescription = ,
            entrance = ,
            exit = 
        }
    ]],
    objects = {} --[[
        uniqueIndex = refId
    ]],
    players = {} --[[
        accountName = { refId }
    ]],
    weights = {} --[[
        refId = weight
    ]],
    interiors = {} --[[
        cellDescription = refId
    ]],

})

--
-- helper functions
--

local locationAxis = { "posX", "posY", "posZ", "rotX", "rotY", "rotZ" }
local function sumLocations(loc1, loc2)
    local loc = {}
    for _, key in pairs(locationAxis) do
        loc[key] = loc1[key] + loc2[key]
    end
    loc.cell = loc1.cell or loc2.cell
    loc.teleport = loc1.teleport or loc2.teleport
    return loc
end
local function rotateLocationZ(loc, angle)
    local c = math.cos(angle)
    local s = math.sin(angle)
    local px =  loc.posX * c + loc.posY * s
    local py = -loc.posX * s + loc.posY * c
    loc.posX = px
    loc.posY = py
    loc.rotZ = loc.rotZ + angle
    return loc
end

local function givePlayerItems(pid, items)
    local player = Players[pid]
    for _, item in pairs(items) do
        item.count = item.count or 1
        item.charge = item.charge or -1
        item.enchantmentCharge = item.enchantmentCharge or -1
        item.soul = item.soul or ""
        inventoryHelper.addItem(
            player.data.inventory,
            item.refId,
            item.count,
            item.charge,
            item.enchantmentCharge,
            item.soul
        )
    end
    Players[pid]:LoadItemChanges(items, enumerations.inventory.ADD)
end

local function deleteObject(cellDescription, uniqueIndex)
    local cellData = LoadedCells[cellDescription].data
    cellData.objectData[uniqueIndex] = nil
    logicHandler.DeleteObjectForEveryone(cellDescription, uniqueIndex)
end

local function createDoor(cellDescription, object)
    local uniqueIndex = WorldInstance:GenerateUniqueIndex()
    local cell = LoadedCells[cellDescription]
    table.insert(cell.data.packets.doorDestination, uniqueIndex)
    table.insert(cell.data.packets.place, uniqueIndex)
    cell.data.objectData[uniqueIndex] = object
    local pid = next(Players)
    if pid then
        cell:LoadObjectsPlaced(pid, cell.data.objectData, {uniqueIndex}, true)
        cell:LoadDoorDestinations(pid, cell.data.objectData, {uniqueIndex}, true)
    end
    return uniqueIndex
end

--
-- getters/setters
--

local function getPlayerTents(accountName)
    if not tentStorage.players[accountName] then
        tentStorage.players[accountName] = {}
    end
    return tentStorage.players[accountName]
end

local function getTentRecord(refId)
    return tentStorage.records[refId]
end

local function getTentConfiguration(refId)
    return configuration.tents[getTentRecord(refId).baseId]
end

local function addTentRecord(accountName, refId, baseId, interiorDescription)
    tentStorage.records[refId] = {
        baseId = baseId,
        interiorDescription = interiorDescription
    }
    table.insert(getPlayerTents(accountName), refId)
end

local function addTentObject(uniqueIndex, refId)
    tentStorage.objects[uniqueIndex] = refId
end

local function removeTentObject(uniqueIndex)
    tentStorage.objects[uniqueIndex] = nil
end

local function getTentObject(uniqueIndex)
    return tentStorage.objects[uniqueIndex]
end

--
-- custom records
--

local function createTentRecord(baseId, cellName)
    local tentConfig = configuration.tents[baseId]
    local refId = RecordStores[RECORD_TYPE]:GenerateRecordId()
    RecordStores[RECORD_TYPE].data.generatedRecords[refId] = {
        baseId = baseId,
        name = cellName
    }
    if tentConfig.item.collision then
        table.insert(config.enforcedCollisionRefIds, refId)
        if next(Players) then
            logicHandler.SendConfigCollisionOverrides(next(Players), true)
        end
    end
    return refId
end

local function updateTentRecord(refId, extraWeight)
    local tentRecord = getTentRecord(refId)
    local tentConfig = getTentConfiguration(refId)
    local baseWeight = tentConfig.item.inventory.weight or 0
    local record = RecordStores[RECORD_TYPE].data.generatedRecords[refId]
    record.weight = baseWeight + extraWeight
    record.name = tentRecord.interiorDescription
    for pid, player in pairs(Players) do
        if tableHelper.containsValue(player.generatedRecordsReceived, refId) then
            RecordStores[RECORD_TYPE]:LoadRecords(pid, RecordStores[RECORD_TYPE].data.generatedRecords, {refId}, false)
        end
    end
end

local function unlinkTentRecordFromCell(refId, pid, cellDescription)
    Players[pid]:AddLinkToRecord(RECORD_TYPE, refId)
    LoadedCells[cellDescription]:RemoveLinkToRecord(RECORD_TYPE, refId)
end

local function linkTentRecordToCell(refId, pid, cellDescription)
    LoadedCells[cellDescription]:AddLinkToRecord(RECORD_TYPE, refId)
    Players[pid]:RemoveLinkToRecord(RECORD_TYPE, refId)
    local recordList = RecordStores[RECORD_TYPE].data.generatedRecords
    local idArray = { refId }
    for _, pid in pairs(LoadedCells[cellDescription].visitors) do
        if Players[pid] then
            RecordStores[RECORD_TYPE]:LoadRecords(pid, recordList, idArray, false)
        end
    end
end

--
-- core logic
--

local function isTentInterior(cellDescription)
    return tentStorage.interiors[cellDescription] ~= nil
end

local function reachedLimit(pid, attemptedRefId)
    if configuration.limit < 1 then return false end
    local playerTents = getPlayerTents(Players[pid].accountName)
    local counter = 0
    for _, refId in pairs(playerTents) do
        if refId ~= attemptedRefId then
            counter = counter + 1
            if counter >= configuration.limit then
                return true
            end
        end
    end
    return false
end

local function getInteriorDescription(pid, tentCellName)
    local baseDescription = string.format(
        "%s's %s",
        Players[pid].accountName,
        tentCellName
    )
    local fl = false
    local cellDescription = nil
    local playerTents = getPlayerTents(Players[pid].accountName)
    while not fl do
        fl = true
        local input = guiHelper.InputDialogAsync(pid, configuration.localization.InputName, baseDescription)
        cellDescription = string.trim(baseDescription .. " " .. input)
        for _, refId in pairs(playerTents) do
            if getTentRecord(refId).interiorDescription == cellDescription then
                fl = false
                break
            end
        end
        if not fl then
            guiHelper.MessageBox(pid, configuration.localization.UniqueName)
        end
    end
    return cellDescription
end

local function createExit(refId, exteriorDescription, exteriorLocation)
    local tentRecord = getTentRecord(refId)
    local tentConfig = getTentConfiguration(refId)
    local interiorDoor = tableHelper.deepCopy(tentConfig.doors.exit)
    interiorDoor.doorDestination = sumLocations(
        rotateLocationZ(interiorDoor.doorDestination, exteriorLocation.rotZ),
        exteriorLocation
    )
    --interiorDoor.location = rotateLocationZ(interiorDoor.location, exteriorLocation.rotZ)
    interiorDoor.doorDestination.cell = exteriorDescription
    local uniqueIndex = createDoor(tentRecord.interiorDescription, interiorDoor)
    tentRecord.exit = uniqueIndex
    return uniqueIndex
end

local function deleteExit(refId)
    local tentRecord = getTentRecord(refId)
    deleteObject(
        tentRecord.interiorDescription,
        tentRecord.exit
    )
    tentRecord.exit = nil
end

local function createEntrance(refId, exteriorDescription, exteriorLocation)
    local tentRecord = getTentRecord(refId)
    local tentConfig = getTentConfiguration(refId)
    local exteriorDoor = tableHelper.deepCopy(tentConfig.doors.entrance)
    exteriorDoor.location = sumLocations(exteriorDoor.location, exteriorLocation)
    exteriorDoor.doorDestination.cell = tentRecord.interiorDescription
    local uniqueIndex = createDoor(exteriorDescription, exteriorDoor)
    tentRecord.entrance = uniqueIndex
    return uniqueIndex
end

local function deleteEntrance(refId)
    local tentRecord = getTentRecord(refId)
    deleteObject(
        tentRecord.exteriorDescription,
        tentRecord.entrance
    )
    tentRecord.entrance = nil
end

local function createInteriorCell(pid, refId)
    local tentRecord = getTentRecord(refId)
    local tentConfig = getTentConfiguration(refId)
    local interiorDescription = tentRecord.interiorDescription
    RecordStores.cell.data.permanentRecords[interiorDescription] = {}
    RecordStores.cell:LoadRecords(pid, RecordStores.cell.data.permanentRecords, {interiorDescription}, true)
    logicHandler.LoadCell(interiorDescription)
    local interiorData = LoadedCells[interiorDescription].data
    for key, list in pairs(tentConfig.interior) do
        for _, object in pairs(list) do
            local uniqueIndex = WorldInstance:GenerateUniqueIndex()
            table.insert(interiorData.packets[key], uniqueIndex)
            local obj = tableHelper.deepCopy(object)
            interiorData.objectData[uniqueIndex] = obj
        end
    end
    tentRecord.interiorDescription = interiorDescription
    tentStorage.interiors[interiorDescription] = refId
    return true
end

local function shuntPlayer(pid, refId)
    local tentRecord = getTentRecord(refId)
    if not LoadedCells[tentRecord.interiorDescription] then
        logicHandler.LoadCell(tentRecord.interiorDescription)
    end
    local interior = LoadedCells[tentRecord.interiorDescription]
    local exitDoor = interior.data.objectData[tentRecord.exit]

    local player = Players[pid]
    player:SaveCell()
    local playerLoc = tableHelper.deepCopy(exitDoor.doorDestination)
    playerLoc.rotY = nil
    playerLoc.rotZ = player.data.location.rotZ
    playerLoc.rotX = player.data.location.rotX
    player.data.location = playerLoc
    player:LoadCell()
end

local function replaceTentObject(cellDescription, uniqueIndex, refId)
    local object = LoadedCells[cellDescription].data.objectData[uniqueIndex]
    local location = object.location
    deleteObject(cellDescription, uniqueIndex)
    return logicHandler.CreateObjectAtLocation(cellDescription, location, refId, "place")
end

local function placeTent(pid, exteriorDescription, uniqueIndex)
    if not LoadedCells[exteriorDescription] then
        logicHandler.LoadCell(exteriorDescription)
    end
    local object = LoadedCells[exteriorDescription].data.objectData[uniqueIndex]
    local refId = object.refId
    local tentRecord = getTentRecord(refId)
    tentRecord.exteriorDescription = exteriorDescription

    if tentRecord.entrance or tentRecord.exit then
        return false, configuration.localization.AlreadyPlaced
    end
    if reachedLimit(pid, refId) then
        return false, configuration.localization.LimitExceeded
    end

    local tent = configuration.tents[tentRecord.baseId]
    local exteriorLocation = object.location

    if not LoadedCells[tentRecord.interiorDescription] then
        logicHandler.LoadCell(tentRecord.interiorDescription)
    end
    createExit(refId, exteriorDescription, exteriorLocation)
    if tent.teleportToExit then shuntPlayer(pid, refId) end
    logicHandler.UnloadCell(tentRecord.interiorDescription)

    createEntrance(refId, exteriorDescription, exteriorLocation)

    linkTentRecordToCell(refId, pid, exteriorDescription)
    addTentObject(uniqueIndex, refId)

    return true
end

local function itemWeight(refId)
    if tentStorage.weights[refId] then
        return tentStorage.weights[refId]
    end
    local recordStore = logicHandler.GetRecordStoreByRecordId(refId)
    if recordStore then
        local record
        if logicHandler.IsGeneratedRecord(refId) then
            record = recordStore.data.generatedRecords[refId]
        else
            record = recordStore.data.permanentRecords[refId]
        end
        if record then
            if record.weight then
                return record.weight
            end
            if record.baseId then
                return itemWeight(record.baseId)
            end
        end
    end
    return 0
end

local function calculateExtraWeight(interiorDescription)
    local weight = 0
    local objectData = LoadedCells[interiorDescription].data.objectData
    for uniqueIndex, object in pairs(objectData) do
        if object.inventory then
            for _, item in pairs(object.inventory) do
                weight = weight + ( item.count or 1 ) * itemWeight(item.refId)
            end
        else
            weight = weight + ( object.count or 1 ) * itemWeight(object.refId)
        end
    end
    return weight
end

local function pickupTent(pid, exteriorDescription, uniqueIndex)
    local refId = getTentObject(uniqueIndex)
    local tentRecord = getTentRecord(refId)
    local interiorDescription = tentRecord.interiorDescription

    deleteEntrance(refId)

    if LoadedCells[interiorDescription] then
        for _, pid in pairs(LoadedCells[interiorDescription].visitors) do
            if Players[pid] then
                shuntPlayer(pid, refId)
            end
        end
    else
        logicHandler.LoadCell(interiorDescription)
    end
    deleteExit(refId)
    local interiorWeight = calculateExtraWeight(interiorDescription)
    logicHandler.UnloadCell(interiorDescription)

    updateTentRecord(refId, interiorWeight)

    unlinkTentRecordFromCell(refId, pid, exteriorDescription)
    removeTentObject(uniqueIndex)
    deleteObject(exteriorDescription, uniqueIndex)

    return true
end

customEventHooks.registerHandler("OnServerPostInit", function(eventStatus)
    if eventStatus.validCustomHandlers then
        for refId, tentConfig in pairs(configuration.tents) do
            RecordStores[RECORD_TYPE].data.permanentRecords[refId] = tentConfig.item.inventory
        end
    end
end)

customEventHooks.registerValidator("OnObjectPlace", function(eventStatus, pid, cellDescription, objects)
    if not eventStatus.validCustomHandlers then return end
    tableHelper.print(objects)
    for uniqueIndex, object in pairs(objects) do
        local tentRecord = getTentRecord(object.refId)
        local tentConfig = configuration.tents[object.refId]
        if tentRecord or tentConfig then
            local cancel = false
            if configuration.allowInsideTents and isTentInterior(cellDescription) then
                guiHelper.MessageBox(pid, configuration.localization.InsideTentInterior)
                cancel = true
            elseif not configuration.allowInsideInteriors and not LoadedCells[cellDescription].isExterior then
                guiHelper.MessageBox(pid, configuration.localization.InsideInterior)
                cancel = true
            elseif reachedLimit(pid) then
                guiHelper.MessageBox(pid, configuration.localization.LimitExceeded)
                cancel = true
            elseif tentConfig then -- using this tent for the first time
                object.location = sumLocations(
                    object.location,
                    tentConfig.item.offset
                )
            elseif tentRecord then -- placing a tent that was used before
                object.location = sumLocations(
                    object.location,
                    getTentConfiguration(object.refId).item.offset
                )
            end
            if cancel then
                givePlayerItems(pid, {{
                    refId = object.refId,
                    count = object.count
                }})
                return customEventHooks.makeEventStatus(false, false)
            elseif object.count > 1 then -- make sure there is only 1 tent
                givePlayerItems(pid, {{
                    refId = object.refId,
                    count = object.count - 1
                }})
                object.count = 1
            end
        end
    end
end)

customEventHooks.registerHandler("OnObjectPlace", function(eventStatus, pid, cellDescription, objects)
    if not eventStatus.validCustomHandlers then return end
    for uniqueIndex, object in pairs(objects) do
        local tentRecord = getTentRecord(object.refId)
        local tentConfig = configuration.tents[object.refId]
        if tentRecord then -- placing a tent that was used before
            local status, err = placeTent(pid, cellDescription, uniqueIndex)
            if not status then
                guiHelper.MessageBox(pid, tostring(err))
                givePlayerItems(pid, {{
                    refId = object.refId,
                    count = object.count or 1
                }})
                deleteObject(cellDescription, uniqueIndex)
            end
        elseif tentConfig then -- using this tent for the first time
            async.Wrap(function() -- wrap in a coroutine for `getInteriorDescription`
                local interiorDescription = getInteriorDescription(pid, tentConfig.cellName)
                local refId = createTentRecord(object.refId, interiorDescription)
                addTentRecord(Players[pid].accountName, refId, object.refId, interiorDescription)
                createInteriorCell(pid, refId)
                local tentUniqueIndex = replaceTentObject(cellDescription, uniqueIndex, refId)
                local status, err = placeTent(pid, cellDescription, tentUniqueIndex)
                if not status then -- should not happen under normal conditions
                    guiHelper.MessageBox(pid, tostring(err))
                    givePlayerItems(pid, {{
                        refId = object.refId,
                        count = object.count or 1
                    }})
                    deleteObject(cellDescription, tentUniqueIndex)
                end
            end)
        end
    end
end)

customEventHooks.registerHandler("OnObjectDelete", function(eventStatus, pid, cellDescription, objects)
    if not eventStatus.validCustomHandlers then return end
    for uniqueIndex, object in pairs(objects) do
        if getTentObject(uniqueIndex) then
            pickupTent(pid, cellDescription, uniqueIndex)
        end
    end
end)

customEventHooks.registerHandler("espParser_Start", function(_, files)
    tentStorage.weights = {}
end)

local statSubRecords = {
    MISC = "MCDT",
    WEAP = "WPDT",
    LIGH = "LHDT",
    ARMO = "AODT",
    CLOT = "CTDT",
    REPA = "RTDT",
    APPA = "AADT",
    LOCK = "LKDT",
    PROB = "PBDT",
    INGR = "IRDT",
    BOOK = "BKDT",
    ALCH = "ALDT"
}
customEventHooks.registerHandler("espParser_Record", function(_, record)
    if statSubRecords[record.name] then
        local statSubRecord = record.subRecords[statSubRecords[record.name]]
        if statSubRecord then
            local refId = record.subRecords.NAME
            local weight = record.subRecords[statSubRecords[record.name]].Weight
            weight = tonumber(weight) or 0
            tentStorage.weights[refId] = tonumber(weight) or 0
        end
    end
end)