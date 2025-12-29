-- Style N&B - Photo Magazine App for FiveM
-- Server Script - QBCore Framework

local QBCore = exports['qb-core']:GetCoreObject()

-- ============================================
-- 雑誌一覧取得
-- ============================================
RegisterNetEvent('style_nb:getMagazines')
AddEventHandler('style_nb:getMagazines', function(callbackId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local citizenid = Player.PlayerData.citizenid

    -- 雑誌一覧と購入状態を取得
    exports.oxmysql:fetch([[
        SELECT
            m.id,
            m.title,
            m.description,
            m.cover_image,
            m.price,
            m.created_at,
            IFNULL(pm.citizenid, '') as purchased
        FROM style_magazines m
        LEFT JOIN style_purchased_magazines pm
            ON m.id = pm.magazine_id AND pm.citizenid = ?
        ORDER BY m.created_at DESC
    ]], {citizenid}, function(result)
        local eventName = 'style_nb:sendMagazines:' .. callbackId
        if result then
            TriggerClientEvent(eventName, src, result)
        else
            TriggerClientEvent(eventName, src, {})
        end
    end)
end)

-- ============================================
-- 雑誌詳細取得（写真付き）
-- ============================================
RegisterNetEvent('style_nb:getMagazineDetail')
AddEventHandler('style_nb:getMagazineDetail', function(magazineId, callbackId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local citizenid = Player.PlayerData.citizenid
    local eventName = 'style_nb:sendMagazineDetail:' .. callbackId

    -- 購入確認
    exports.oxmysql:fetch('SELECT citizenid FROM style_purchased_magazines WHERE magazine_id = ? AND citizenid = ?', {magazineId, citizenid}, function(purchaseResult)
        local isPurchased = purchaseResult and #purchaseResult > 0
        local isPhoto = Player.PlayerData.job.name == 'photo'

        -- photoジョブまたは購入済みの場合のみ詳細を返す
        if isPhoto or isPurchased then
            exports.oxmysql:fetch([[
                SELECT
                    m.id,
                    m.title,
                    m.description,
                    m.cover_image,
                    m.price,
                    m.created_at
                FROM style_magazines m
                WHERE m.id = ?
            ]], {magazineId}, function(magResult)
                if magResult and magResult[1] then
                    local magazine = magResult[1]

                    -- 写真リスト取得
                    exports.oxmysql:fetch([[
                        SELECT id, image_url, caption, page_order
                        FROM style_magazine_photos
                        WHERE magazine_id = ?
                        ORDER BY page_order ASC
                    ]], {magazineId}, function(photoResult)
                        magazine.photos = photoResult or {}
                        magazine.isPurchased = isPurchased
                        magazine.isPhoto = isPhoto
                        TriggerClientEvent(eventName, src, magazine)
                    end)
                else
                    TriggerClientEvent(eventName, src, nil)
                end
            end)
        else
            TriggerClientEvent(eventName, src, {error = 'not_purchased'})
        end
    end)
end)

-- ============================================
-- 雑誌作成（photoジョブのみ）
-- ============================================
RegisterNetEvent('style_nb:createMagazine')
AddEventHandler('style_nb:createMagazine', function(data, callbackId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local job = Player.PlayerData.job.name
    local eventName = 'style_nb:magazineCreated:' .. callbackId

    if job ~= 'photo' then
        TriggerClientEvent(eventName, src, {success = false, message = '権限がありません。'})
        return
    end

    -- 雑誌作成
    exports.oxmysql:insert(
        'INSERT INTO style_magazines (title, description, cover_image, price) VALUES (?, ?, ?, ?)',
        {data.title, data.description or '', data.coverImage, data.price},
        function(magazineId)
            if magazineId then
                -- 写真登録
                if data.photos and #data.photos > 0 then
                    local photoValues = {}
                    for i, photo in ipairs(data.photos) do
                        table.insert(photoValues, '(' .. magazineId .. ', "' .. photo.imageUrl .. '", "' .. (photo.caption or '') .. '", ' .. i .. ')')
                    end
                    local photoQuery = 'INSERT INTO style_magazine_photos (magazine_id, image_url, caption, page_order) VALUES ' .. table.concat(photoValues, ', ')
                    exports.oxmysql:execute(photoQuery, {}, function()
                        print('[Style N&B] Magazine created with ID:', magazineId)
                        TriggerClientEvent(eventName, src, {success = true, id = magazineId})
                    end)
                else
                    print('[Style N&B] Magazine created with ID:', magazineId)
                    TriggerClientEvent(eventName, src, {success = true, id = magazineId})
                end
            else
                print('[Style N&B] Failed to create magazine')
                TriggerClientEvent(eventName, src, {success = false, message = '作成に失敗しました。'})
            end
        end
    )
end)

-- ============================================
-- 雑誌更新（photoジョブのみ）
-- ============================================
RegisterNetEvent('style_nb:updateMagazine')
AddEventHandler('style_nb:updateMagazine', function(data, callbackId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local job = Player.PlayerData.job.name
    local eventName = 'style_nb:magazineUpdated:' .. callbackId

    if job ~= 'photo' then
        TriggerClientEvent(eventName, src, {success = false})
        return
    end

    -- 雑誌情報更新
    exports.oxmysql:execute(
        'UPDATE style_magazines SET title = ?, description = ?, cover_image = ?, price = ? WHERE id = ?',
        {data.title, data.description or '', data.coverImage, data.price, data.id},
        function()
            -- 既存写真を削除して再登録
            exports.oxmysql:execute('DELETE FROM style_magazine_photos WHERE magazine_id = ?', {data.id}, function()
                if data.photos and #data.photos > 0 then
                    local photoValues = {}
                    for i, photo in ipairs(data.photos) do
                        table.insert(photoValues, '(' .. data.id .. ', "' .. photo.imageUrl .. '", "' .. (photo.caption or '') .. '", ' .. i .. ')')
                    end
                    local photoQuery = 'INSERT INTO style_magazine_photos (magazine_id, image_url, caption, page_order) VALUES ' .. table.concat(photoValues, ', ')
                    exports.oxmysql:execute(photoQuery, {}, function()
                        print('[Style N&B] Magazine updated:', data.id)
                        TriggerClientEvent(eventName, src, {success = true})
                    end)
                else
                    TriggerClientEvent(eventName, src, {success = true})
                end
            end)
        end
    )
end)

-- ============================================
-- 雑誌削除（photoジョブのみ）
-- ============================================
RegisterNetEvent('style_nb:deleteMagazine')
AddEventHandler('style_nb:deleteMagazine', function(magazineId, callbackId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local job = Player.PlayerData.job.name
    local eventName = 'style_nb:magazineDeleted:' .. callbackId

    if job ~= 'photo' then
        TriggerClientEvent(eventName, src, {success = false})
        return
    end

    exports.oxmysql:execute('DELETE FROM style_magazines WHERE id = ?', {magazineId}, function(result)
        if result and result.affectedRows > 0 then
            print('[Style N&B] Magazine deleted:', magazineId)
            TriggerClientEvent(eventName, src, {success = true})
        else
            TriggerClientEvent(eventName, src, {success = false})
        end
    end)
end)

-- ============================================
-- 雑誌購入
-- ============================================
RegisterNetEvent('style_nb:purchaseMagazine')
AddEventHandler('style_nb:purchaseMagazine', function(magazineId, price, callbackId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local citizenid = Player.PlayerData.citizenid
    local eventName = 'style_nb:magazinePurchased:' .. callbackId

    -- 既に購入済みか確認
    exports.oxmysql:fetch('SELECT id FROM style_purchased_magazines WHERE magazine_id = ? AND citizenid = ?', {magazineId, citizenid}, function(result)
        if result and #result > 0 then
            TriggerClientEvent(eventName, src, {success = false, message = '既に購入しています。'})
            return
        end

        -- 所持金確認と引き落とし
        if Player.Functions.RemoveMoney('bank', price, 'style-nb-purchase') then
            -- 購入記録登録
            exports.oxmysql:insert('INSERT INTO style_purchased_magazines (magazine_id, citizenid) VALUES (?, ?)', {magazineId, citizenid}, function(id)
                if id then
                    -- photoアカウントに入金
                    exports['okokBanking']:AddMoney('photo', price)
                    print('[Style N&B] Magazine purchased:', magazineId, 'by', citizenid)
                    TriggerClientEvent(eventName, src, {success = true})
                else
                    TriggerClientEvent(eventName, src, {success = false, message = '購入処理に失敗しました。'})
                end
            end)
        else
            TriggerClientEvent(eventName, src, {success = false, message = '所持金が足りません。'})
        end
    end)
end)

-- ============================================
-- プレイヤージョブ取得
-- ============================================
RegisterNetEvent('style_nb:getPlayerJob')
AddEventHandler('style_nb:getPlayerJob', function(callbackId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local eventName = 'style_nb:sendPlayerJob:' .. callbackId
    if Player then
        TriggerClientEvent(eventName, src, {job = Player.PlayerData.job.name})
    end
end)
