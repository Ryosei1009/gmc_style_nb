-- Style N&B - Photo Magazine App for FiveM
-- Server Script - QBCore Framework

local QBCore = exports['qb-core']:GetCoreObject()

local function normalizeText(value)
    if value == nil then
        return ''
    end

    return tostring(value):gsub('^%s*(.-)%s*$', '%1')
end

local function isPhotoJob(player)
    if not player or not player.PlayerData or not player.PlayerData.job then
        return false
    end

    local jobName = player.PlayerData.job.name
    return jobName == 'photo'
end

CreateThread(function()
    -- 既存環境でも新機能が動くように起動時にマイグレーション
    exports.oxmysql:execute('ALTER TABLE style_magazines ADD COLUMN IF NOT EXISTS is_public TINYINT(1) NOT NULL DEFAULT 1', {})
    exports.oxmysql:execute('ALTER TABLE style_magazines ADD COLUMN IF NOT EXISTS purchase_password VARCHAR(100) NULL', {})
end)

-- ============================================
-- 雑誌一覧取得
-- ============================================
RegisterNetEvent('style_nb:getMagazines')
AddEventHandler('style_nb:getMagazines', function(callbackId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local citizenid = Player.PlayerData.citizenid
    local isPhoto = Player.PlayerData.job.name == 'photo'
    local canViewPrivate = isPhotoJob(Player)

    -- 雑誌一覧と購入状態を取得（photoジョブの場合は購入数も取得）
    exports.oxmysql:fetch([[
        SELECT
            m.id,
            m.title,
            m.description,
            m.cover_image,
            m.price,
            m.is_public,
            CASE WHEN COALESCE(m.purchase_password, '') <> '' THEN 1 ELSE 0 END as requires_password,
            m.created_at,
            IFNULL(pm.citizenid, '') as purchased,
            (SELECT COUNT(*) FROM style_purchased_magazines WHERE magazine_id = m.id) as purchase_count
        FROM style_magazines m
        LEFT JOIN style_purchased_magazines pm
            ON m.id = pm.magazine_id AND pm.citizenid = ?
        WHERE m.is_public = 1 OR ? = 1
        ORDER BY m.created_at DESC
    ]], {citizenid, canViewPrivate and 1 or 0}, function(result)
        local eventName = 'style_nb:sendMagazines:' .. callbackId
        if result then
            -- photoジョブでない場合は購入数を隠す
            if not isPhoto then
                for i, magazine in ipairs(result) do
                    result[i].purchase_count = nil
                end
            end
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
    local isPhoto = Player.PlayerData.job.name == 'photo'
    local canViewPrivate = isPhotoJob(Player)

    exports.oxmysql:fetch([[
        SELECT
            m.id,
            m.title,
            m.description,
            m.cover_image,
            m.price,
            m.is_public,
            m.purchase_password,
            m.created_at
        FROM style_magazines m
        WHERE m.id = ?
    ]], {magazineId}, function(magResult)
        if not magResult or not magResult[1] then
            TriggerClientEvent(eventName, src, nil)
            return
        end

        local magazine = magResult[1]

        if tonumber(magazine.is_public) == 0 and not canViewPrivate then
            TriggerClientEvent(eventName, src, {error = 'private_restricted'})
            return
        end

        -- 購入確認
        exports.oxmysql:fetch('SELECT citizenid FROM style_purchased_magazines WHERE magazine_id = ? AND citizenid = ?', {magazineId, citizenid}, function(purchaseResult)
            local isPurchased = purchaseResult and #purchaseResult > 0

            -- photoジョブまたは購入済みの場合のみ詳細を返す
            if isPhoto or isPurchased then
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
                    magazine.requires_password = normalizeText(magazine.purchase_password) ~= ''

                    if not isPhoto then
                        magazine.purchase_password = nil
                    end

                    TriggerClientEvent(eventName, src, magazine)
                end)
            else
                TriggerClientEvent(eventName, src, {error = 'not_purchased'})
            end
        end)
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

    local isPublic = data.isPublic == false and 0 or 1
    local purchasePassword = normalizeText(data.purchasePassword)
    if purchasePassword == '' then
        purchasePassword = nil
    end

    -- 雑誌作成
    exports.oxmysql:insert(
        'INSERT INTO style_magazines (title, description, cover_image, price, is_public, purchase_password) VALUES (?, ?, ?, ?, ?, ?)',
        {data.title, data.description or '', data.coverImage, data.price, isPublic, purchasePassword},
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

    local isPublic = data.isPublic == false and 0 or 1
    local purchasePassword = normalizeText(data.purchasePassword)
    if purchasePassword == '' then
        purchasePassword = nil
    end

    -- 雑誌情報更新
    exports.oxmysql:execute(
        'UPDATE style_magazines SET title = ?, description = ?, cover_image = ?, price = ?, is_public = ?, purchase_password = ? WHERE id = ?',
        {data.title, data.description or '', data.coverImage, data.price, isPublic, purchasePassword, data.id},
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
AddEventHandler('style_nb:purchaseMagazine', function(magazineId, price, purchasePassword, callbackId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    if callbackId == nil then
        callbackId = purchasePassword
        purchasePassword = nil
    end

    local citizenid = Player.PlayerData.citizenid
    local eventName = 'style_nb:magazinePurchased:' .. callbackId
    local canViewPrivate = isPhotoJob(Player)
    local inputPassword = normalizeText(purchasePassword)

    exports.oxmysql:fetch('SELECT id, price, is_public, purchase_password FROM style_magazines WHERE id = ?', {magazineId}, function(magResult)
        if not magResult or not magResult[1] then
            TriggerClientEvent(eventName, src, {success = false, message = '記事が見つかりません。'})
            return
        end

        local magazine = magResult[1]
        local dbPrice = tonumber(magazine.price) or 0
        local requiredPassword = normalizeText(magazine.purchase_password)

        if tonumber(magazine.is_public) == 0 and not canViewPrivate then
            TriggerClientEvent(eventName, src, {success = false, message = 'この非公開記事は購入できません。'})
            return
        end

        if requiredPassword ~= '' and inputPassword ~= requiredPassword then
            TriggerClientEvent(eventName, src, {success = false, message = '購入パスワードが違います。'})
            return
        end

        -- 既に購入済みか確認
        exports.oxmysql:fetch('SELECT id FROM style_purchased_magazines WHERE magazine_id = ? AND citizenid = ?', {magazineId, citizenid}, function(result)
            if result and #result > 0 then
                TriggerClientEvent(eventName, src, {success = false, message = '既に購入しています。'})
                return
            end

            -- 所持金確認と引き落とし
            if Player.Functions.RemoveMoney('bank', dbPrice, 'style-nb-purchase') then
                -- 購入記録登録
                exports.oxmysql:insert('INSERT INTO style_purchased_magazines (magazine_id, citizenid) VALUES (?, ?)', {magazineId, citizenid}, function(id)
                    if id then
                        -- photoアカウントに入金
                        exports['okokBanking']:AddMoney('photo', dbPrice)
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
