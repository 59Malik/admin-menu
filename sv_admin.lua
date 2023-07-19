ESX = nil 
SetRoutingBucketPopulationEnabled(0, false)
TriggerEvent("esx:getSharedObject", function(result)
    ESX = result
end)

AddEventHandler('onResourceStart', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
      return
    end
    local loadFile = LoadResourceFile(GetCurrentResourceName(), "./files/data.json")
    warnings = json.decode(loadFile)
end)

ESX.RegisterServerCallback('GetAllPlayers', function(source, cb)
    local xPlayers = ESX.GetPlayers()
    local players = {}

    for i=1, #xPlayers, 1 do
        local xPlayer = ESX.GetPlayerFromId(xPlayers[i])
        table.insert(players, {
            name = GetPlayerName(xPlayer.source),
            id = xPlayer.source
        })
    end

    cb(players)
end)

ESX.RegisterServerCallback('getPlayerInfo', function(source, cb, id)
    local xPlayer = ESX.GetPlayerFromId(id)
    local identifiers = ExtractIdentifiers(id)
    local playerGroup = xPlayer.getGroup()
    -- Get user name
    local result = MySQL.Sync.fetchAll('SELECT firstname, lastname FROM users WHERE identifier = @identifier', {
        ['@identifier'] = identifiers.steam
    })

    local data = {
        id = id,
        ip = identifiers.ip,
        name = GetPlayerName(id),
        playerGroup = group,
        firstname = result[1].firstname,
        lastname = result[1].lastname,
    }

    cb(data)
end)


RegisterServerEvent('zAdmin:sendPrivateMessage')
AddEventHandler('zAdmin:sendPrivateMessage', function(target, msg)
    TriggerClientEvent('esx:showNotification', target, ("~b~Modération.~s~\n"..msg.."."))
end)

RegisterServerEvent('admin:PlayerEvent')
AddEventHandler("admin:PlayerEvent",function(name, source, r, a, b, c)
    TriggerClientEvent(name, source, r, a, b, c)
end)

RegisterServerEvent("KickPlayer")
AddEventHandler("KickPlayer", function(player, reason)
    DropPlayer(player, reason)
end)


ESX.RegisterServerCallback('getSanction', function(source, cb, id)
    local identifier = GetPlayerIdentifiers(id)[1]
    if not warnings[identifier] then warnings[identifier] = {} end
    cb(warnings[identifier])
end)

RegisterServerEvent('ScreenshotAdmin')
AddEventHandler('ScreenshotAdmin', function(target)
    TriggerClientEvent('ScreenshotAdmin', target)
    TriggerClientEvent('esx:showNotification', source, '~g~Informations~s~ \nRendez vous sur le discord Logs pour voir le screenshot du joueur')
end)

RegisterServerEvent('zAdmin:SetSanction')
AddEventHandler('zAdmin:SetSanction', function(target, reason)
    local identifier = GetPlayerIdentifiers(target)[1]
    local name = GetPlayerName(target)
    local warner = GetPlayerName(source)
    local date = os.date("%d/%m/%Y %H:%M")
    local data = {
        identifier = identifier,
        name = name,
        date = date,
        warner = warner,
        reason = reason
    }
    if not warnings[identifier] then warnings[identifier] = {} end
    table.insert(warnings[identifier], data)
    TriggerClientEvent('esx:showNotification', source, 'Vous avez averti ~b~'..name..' ~w~pour la raison suivante ~b~: '..reason)
    SaveResourceFile(GetCurrentResourceName(), "./files/data.json", json.encode(warnings, {indent=true}), -1)
end)

ESX.RegisterServerCallback('admin:GetGroup', function(source, cb)
	local xPlayer = ESX.GetPlayerFromId(source)

	if xPlayer ~= nil then
		local playerGroup = xPlayer.getGroup()

        if playerGroup ~= nil then 
            cb(playerGroup)
        else
            cb(nil)
        end
	else
		cb(nil)
	end
end)

function ExtractIdentifiers(src)
    local identifiers = {
        steam = "",
        ip = "",
        discord = "",
        license = "",
        xbl = "",
        live = ""
    }

    for i = 0, GetNumPlayerIdentifiers(src) - 1 do
        local id = GetPlayerIdentifier(src, i)

        if string.find(id, "steam") then
            identifiers.steam = id
        elseif string.find(id, "ip") then
            identifiers.ip = id
        elseif string.find(id, "discord") then
            identifiers.discord = id
        elseif string.find(id, "license") then
            identifiers.license = id
        elseif string.find(id, "xbl") then
            identifiers.xbl = id
        elseif string.find(id, "live") then
            identifiers.live = id
        end
    end

    return identifiers
end


RegisterNetEvent("AnnonceAdmin")
AddEventHandler("AnnonceAdmin", function(msg)
    local xPlayer = ESX.GetPlayerFromId(source)

    if xPlayer.getGroup() == 'superadmin' or xPlayer.getGroup() == 'admin' or xPlayer.getGroup() == 'moderator' then
        TriggerClientEvent('esx:showNotification', -1, "~b~Annonce Serveur~s~\n"..msg)
    else
        DropPlayer(source, "cheat AnnonceAdmin")
    end
end)

RegisterServerEvent("admin:DeleteBan")
AddEventHandler("admin:DeleteBan", function(banId, name)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    MySQL.Async.execute('DELETE FROM blacklist WHERE id = @id', {
        ['@id'] = banId
    }, function(rowsChanged)
        TriggerClientEvent('esx:showNotification', xPlayer.source, "Vous ~r~avez~s~ de ~r~révoquer le bannissement~s~ de : ~r~" .. name .. "~s~")
    end)
end)

RegisterServerEvent("admin:Ban")
AddEventHandler("admin:Ban", function(player, raison, pName)
    if not raison then
        raison = "Aucune raison"
    end
    local time = os.date()
    local IDS = ExtractIdentifiers(player)
    local SteamDec = tostring(tonumber(IDS.steam:gsub("steam:", ""), 16));
    local Type = Type2 or "false"
    local Other = Other2 or "false"
    local token = {}
    token[IDS.discord] = {}

    for i = 0, GetNumPlayerTokens(player) do 
        table.insert(token[IDS.discord], GetPlayerToken(player, i))
    end

    MySQL.Async.execute("INSERT INTO blacklist (Steam, SteamLink, SteamName, DiscordUID, DiscordTag, GameLicense, ip, xbl, live, BanType, Other, Date, Banner, Token) VALUES ('" .. IDS.steam .. "', '" .. "https://steamcommunity.com/profiles/" .. SteamDec .. "', '" .. GetPlayerName(player) .. "', '" .. IDS.discord .. "', '<@" .. IDS.discord:gsub('discord:', '') .. ">', '" .. IDS.license .. "', '".. IDS.ip .."', '".. IDS.xbl .."', '".. IDS.live .."', 'Modérateur', '" .. raison .. "', '" .. time .. "', '"..pName.."', '"..json.encode(token[IDS.discord]).."');", {}, function()
        DropPlayer(player, 'Vous avez été bannis du serveur')
    end)
    ActualizebanList()
end)

function SearchBDDBan(source, target)
    if target ~= "" then
        MySQL.Async.fetchAll('SELECT * FROM baninfo WHERE playername like @playername',
        {
            ['@playername'] = ("%"..target.."%")
        }, function(data)
            if data[1] then
                if #data < 50 then
                    for i=1, #data, 1 do
                        TriggerClientEvent('esx:showNotification', source, "Id: ~b~"..data[i].id.." ~s~Nom: ~b~"..data[i].playername)
                    end
                else
                    TriggerClientEvent('esx:showNotification', source, "~r~Trop de résultats, veillez être plus précis.")
                end
            else
                TriggerClientEvent('esx:showNotification', source, "~r~Le nom n'est pas valide.")
            end
        end)
    else
        TriggerClientEvent('esx:showNotification', source, "~r~Le nom n'est pas valide.")
    end
end

RegisterServerEvent('admin:SearchBanOffline')
AddEventHandler('admin:SearchBanOffline', function(target)
    SearchBDDBan(source, target)
end)

function BanPlayerOffline(sources, permId, reason, pName)
    if permId ~= "" then
        local target = permId
        local sourceplayername = ""
        if sources ~= 0 then
            sourceplayername = GetPlayerName(sources)
        else
            sourceplayername = "Console"
        end

        if target ~= "" then
            MySQL.Async.fetchAll('SELECT * FROM baninfo WHERE id = @id',
            {
                ['@id'] = target
            }, function(data)
                if not reason then
                    reason = "Aucune raison"
                end
                if not time then
                    time = "00/00/0000"
                end
                if data[1] then
                    if not reason then
                        reason = "Aucune raison"
                    end

                    local xPlayers   = ESX.GetPlayers()
                    steamid = {}
                    license = {}
                    discord = {}
                    ip = {}

                    steamid = {}
                    license = {}
                    discord = {}
                    ip = {}


                    for i=1, #xPlayers, 1 do

                        for z = 0, GetNumPlayerIdentifiers(xPlayers[i]) - 1 do
                            local id = GetPlayerIdentifier(xPlayers[i], z)

                            if string.find(id, "ip") then
                                ip = id
                            elseif string.find(id, "discord") then
                                discord = id
                            elseif string.find(id, "license") then
                                license = id
                            end
                        end

                        if ((tostring(data[1].license)) == tostring(license) or (tostring(data[1].discord)) == tostring(discord) or (tostring(data[1].playerip)) == tostring(ip)) then
                            DropPlayer(xPlayers[i], 'A component of your computer is preventing you from being able to play FiveM.\nPlease wait out your original ban (expiring in 21 days + 23:59:55) to be able to play FiveM.\nThe associated correlation ID is 78e546-cgh8j-478Jd-c832-dax9246_01cd.')
                        end
                    end

                    TriggerEvent('admin:BanOff', data[1].identifier or 0, data[1].license or 0, data[1].discord or 0, data[1].playername, reason, pName, data[1].playerip or 0, data[1].xblid or 0, data[1].liveid or 0, data[1].Token or 0)
                    TriggerClientEvent('esx:showNotification', sources, "Vous avez banni ~b~"..data[1].playername.."~s~.")
                end
            end)
        end
    end
end

RegisterServerEvent('admin:BanPlayerOffline')
AddEventHandler('admin:BanPlayerOffline', function(permId, reason, pName)
    BanPlayerOffline(source, permId, reason, pName)
end)

RegisterServerEvent("admin:BanOff")
AddEventHandler("admin:BanOff", function(steam, license, discord, name, raison, pName, ip, xbl, live, token)
    MySQL.Async.execute("INSERT INTO blacklist (Steam, SteamLink, SteamName, DiscordUID, DiscordTag, GameLicense, ip, xbl, live, BanType, Other, Date, Banner, Token) VALUES ('" .. steam .. "', '" .. "https://steamcommunity.com/profiles/offline', '" .. name .. "', '" .. discord .. "', '<@" .. discord .. ">', '" .. license .. "', '".. ip .."', '".. xbl .."', '".. live .."', 'Modérateur', '" .. raison .. "', 'Offline', '"..pName.."', '"..token.."');", {}, function()
    end)

    ActualizebanList()
end)

AddEventHandler('es:playerLoaded', function(source)
    CreateThread(function()
        Wait(5000)
        local license, steamID, liveid, xblid, discord, playerip
        local playername = GetPlayerName(source)

        for k, v in ipairs(GetPlayerIdentifiers(source)) do
            if string.sub(v, 1, string.len("license:")) == "license:" then
                license = v
            elseif string.sub(v, 1, string.len("steam:")) == "steam:" then
                steamID = v
            elseif string.sub(v, 1, string.len("live:")) == "live:" then
                liveid = v
            elseif string.sub(v, 1, string.len("xbl:")) == "xbl:" then
                xblid = v
            elseif string.sub(v, 1, string.len("discord:")) == "discord:" then
                discord = v
            elseif string.sub(v, 1, string.len("ip:")) == "ip:" then
                playerip = v
            end
        end

        token = {}
        token[discord] = {}
    
        for i = 0, GetNumPlayerTokens(source) do 
            table.insert(token[discord], GetPlayerToken(source, i))
        end

        MySQL.Async.fetchAll('SELECT * FROM `baninfo` WHERE `license` = @license', {
            ['@license'] = license
        }, function(data)
            local found = false
            for i = 1, #data, 1 do
                if data[i].license == license then
                    found = true
                end
            end
            if not found then
                MySQL.Async.execute('INSERT INTO baninfo (license,identifier,liveid,xblid,discord,playerip,playername,Token) VALUES (@license,@identifier,@liveid,@xblid,@discord,@playerip,@playername,@token)',
                    {
                        ['@license'] = license,
                        ['@identifier'] = steamID,
                        ['@liveid'] = liveid,
                        ['@xblid'] = xblid,
                        ['@discord'] = discord,
                        ['@playerip'] = playerip,
                        ['@playername'] = playername,
                        ['@token'] = json.encode(token[discord]),
                    },
                    function()
                end)
            else
                MySQL.Async.execute('UPDATE `baninfo` SET `identifier` = @identifier, `liveid` = @liveid, `xblid` = @xblid, `discord` = @discord, `playerip` = @playerip, `playername` = @playername, `Token` = @token WHERE `license` = @license',
                    {
                        ['@license'] = license,
                        ['@identifier'] = steamID,
                        ['@liveid'] = liveid,
                        ['@xblid'] = xblid,
                        ['@discord'] = discord,
                        ['@playerip'] = playerip,
                        ['@playername'] = playername,
                        ['@token'] = json.encode(token[discord]),
                    },
                    function()
                end)
            end
        end)
    end)
end)

BanList = {}
BannedTokens = {}

RegisterCommand("co", function(source, args, rawCommand)
	local player = source
    local ped = GetPlayerPed(player)
    local playerCoords = GetEntityCoords(ped)
end)