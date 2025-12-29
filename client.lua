-- Style N&B - Photo Magazine App for FiveM
-- Client Script

-- ============================================
-- lb-phoneへのアプリ登録
-- ============================================
local added, errorMessage = exports["lb-phone"]:AddCustomApp({
    identifier = "style_nb",
    name = "Style N&B",
    description = "フォト雑誌アプリ",
    ui = GetCurrentResourceName() .. "/ui/dist/index.html",
    icon = "https://cfx-nui-" .. GetCurrentResourceName() .. "/ui/icon.png",
    defaultApp = false,
    fixBlur = true
})

if not added then
    print("Failed to add Style N&B app: " .. errorMessage)
end

local QBCore = exports['qb-core']:GetCoreObject()

-- ============================================
-- コールバック管理
-- ============================================
local pendingCallbacks = {}

local function generateCallbackId()
    return 'cb_' .. math.random(100000, 999999)
end

local function registerTempCallback(eventName, callback)
    local callbackId = generateCallbackId()
    local fullName = eventName .. ':' .. callbackId

    RegisterNetEvent(fullName, function(...)
        pendingCallbacks[callbackId] = nil
        callback(...)
    end)

    pendingCallbacks[callbackId] = fullName
    return callbackId
end

-- ============================================
-- NUIコールバック登録
-- ============================================

-- 雑誌一覧取得
RegisterNUICallback('getMagazines', function(data, cb)
    local callbackId = registerTempCallback('style_nb:sendMagazines', function(magazines)
        cb({ success = true, magazines = magazines })
    end)
    TriggerServerEvent('style_nb:getMagazines', callbackId)
end)

-- 雑誌詳細取得
RegisterNUICallback('getMagazineDetail', function(data, cb)
    local callbackId = registerTempCallback('style_nb:sendMagazineDetail', function(magazine)
        cb({ success = true, magazine = magazine })
    end)
    TriggerServerEvent('style_nb:getMagazineDetail', data.id, callbackId)
end)

-- 雑誌作成
RegisterNUICallback('createMagazine', function(data, cb)
    local callbackId = registerTempCallback('style_nb:magazineCreated', function(result)
        cb(result)
    end)
    TriggerServerEvent('style_nb:createMagazine', data, callbackId)
end)

-- 雑誌更新
RegisterNUICallback('updateMagazine', function(data, cb)
    local callbackId = registerTempCallback('style_nb:magazineUpdated', function(result)
        cb(result)
    end)
    TriggerServerEvent('style_nb:updateMagazine', data, callbackId)
end)

-- 雑誌削除
RegisterNUICallback('deleteMagazine', function(data, cb)
    local callbackId = registerTempCallback('style_nb:magazineDeleted', function(result)
        cb(result)
    end)
    TriggerServerEvent('style_nb:deleteMagazine', data.id, callbackId)
end)

-- 雑誌購入
RegisterNUICallback('purchaseMagazine', function(data, cb)
    local callbackId = registerTempCallback('style_nb:magazinePurchased', function(result)
        cb(result)
    end)
    TriggerServerEvent('style_nb:purchaseMagazine', data.id, data.price, callbackId)
end)

-- プレイヤージョブ取得
RegisterNUICallback('getPlayerJob', function(data, cb)
    local callbackId = registerTempCallback('style_nb:sendPlayerJob', function(result)
        cb(result)
    end)
    TriggerServerEvent('style_nb:getPlayerJob', callbackId)
end)

-- UIを閉じる（フォーカス解除）
RegisterNUICallback('closeUI', function(data, cb)
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'closeApp' })
    cb('ok')
end)

-- 画像をゲーム画面全体に表示
RegisterNUICallback('showImage', function(data, cb)
    if data.imageUrl then
        TriggerEvent('gmc_style_nb:client:ShowImage', data.imageUrl)
    end
    cb('ok')
end)

-- ============================================
-- デバッグコマンド
-- ============================================
RegisterCommand('openstyleapp', function()
    SendNUIMessage({ action = 'openApp' })
    SetNuiFocus(true, true)
end, false)
