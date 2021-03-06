local ssid = "YOUR_SSID"
local pwd = "YOUR_PASSWORD"
local omloxhost = "OMLOX_HUB_HOSTNAME"
local omloxport = "8081"

local methodCallbackTable={}
local id=0

local socket=websocket.createClient()

socket:on("connection", function(socket)
    print("\n\tRPC - CONNECTED")
    initRPC(socket)
    registerFunction(socket, "getTemperature", function() return {temperature=bme280.temp()/100} end)
    sensorsetup()
end)
socket:on("close", function(socket)
    print("\n\tRPC - CONNECTION CLOSED")
    local timer = tmr.create()
    timer:register(5000,tmr.ALARM_SINGLE, function()
        socket:connect('ws://' .. omloxhost .. ':' .. omloxport .. '/v1/ws/rpc')
    end)
    timer:start()
end)


 wifi.eventmon.register(wifi.eventmon.STA_CONNECTED, function(T)
 print("\n\tSTA - CONNECTED".."\n\tSSID: "..T.SSID.."\n\tBSSID: "..
 T.BSSID.."\n\tChannel: "..T.channel)
    socket:connect('ws://' .. omloxhost .. ':' .. omloxport .. '/v1/ws/rpc')
 end)

 wifi.eventmon.register(wifi.eventmon.STA_DISCONNECTED, function(T)
 print("\n\tSTA - DISCONNECTED".."\n\tSSID: "..T.SSID.."\n\tBSSID: "..
 T.BSSID.."\n\treason: "..T.reason)
 end)

 wifi.eventmon.register(wifi.eventmon.STA_AUTHMODE_CHANGE, function(T)
 print("\n\tSTA - AUTHMODE CHANGE".."\n\told_auth_mode: "..
 T.old_auth_mode.."\n\tnew_auth_mode: "..T.new_auth_mode)
 end)

 wifi.eventmon.register(wifi.eventmon.STA_GOT_IP, function(T)
 print("\n\tSTA - GOT IP".."\n\tStation IP: "..T.IP.."\n\tSubnet mask: "..
 T.netmask.."\n\tGateway IP: "..T.gateway)
 end)

 wifi.eventmon.register(wifi.eventmon.STA_DHCP_TIMEOUT, function()
 print("\n\tSTA - DHCP TIMEOUT")
 end)

 wifi.eventmon.register(wifi.eventmon.AP_STACONNECTED, function(T)
 print("\n\tAP - STATION CONNECTED".."\n\tMAC: "..T.MAC.."\n\tAID: "..T.AID)
 end)

 wifi.eventmon.register(wifi.eventmon.AP_STADISCONNECTED, function(T)
 print("\n\tAP - STATION DISCONNECTED".."\n\tMAC: "..T.MAC.."\n\tAID: "..T.AID)
 end)

 wifi.eventmon.register(wifi.eventmon.AP_PROBEREQRECVED, function(T)
 print("\n\tAP - PROBE REQUEST RECEIVED".."\n\tMAC: ".. T.MAC.."\n\tRSSI: "..T.RSSI)
 end)

 wifi.eventmon.register(wifi.eventmon.WIFI_MODE_CHANGED, function(T)
 print("\n\tSTA - WIFI MODE CHANGED".."\n\told_mode: "..
 T.old_mode.."\n\tnew_mode: "..T.new_mode)
 end)

wifi.setmode(wifi.STATION)
wifi.sta.config {ssid=ssid, pwd=pwd}



 function sensorsetup()
    i2c.setup(0, 2, 1, i2c.SLOW)
    bme280.setup()
 end

 function registerFunction(ws, method, callback)
    id=id+1
    local websocketregister={jsonrpc="2.0", id=id, method="register", params={ method=method}}
    methodCallbackTable[method] = { callback=callback, id=id }
    local data
    local concat=""
    local encoder = sjson.encoder(websocketregister)
    
    while true do
        data = encoder:read(64)
        if not data then
            break
        end
        concat=concat..data
    end
    ws:send(concat)
    print("\n\tRPC - SENT MESSAGE\n\tMESSAGE: ".. concat)
    
 end
 
function initRPC(ws)
    local result={jsonrpc="2.0", result=nil}
    ws:on("receive", function(_, msg, opcode)
        print("\n\tRPC - GOT MESSAGE\n\tMESSAGE: " .. msg .. "\n\tOP-CODE: " .. opcode)
        local decoder=sjson.decoder()
        decoder:write(msg)
        local decoderresult=decoder:result()
        for i,v in pairs(methodCallbackTable) do
            if v.id==decoderresult.id then
                if decoderresult.result==true then
                    print("\n\tRPC - REGISTERED " .. i)
                else
                    print("\n\tRPC - REGISTRATION FAILED")
                end
            end
        end
        if methodCallbackTable[decoderresult.method]~=nil then
            local data
            local concat=""
            result.id=decoderresult.id
            result.result=methodCallbackTable[decoderresult.method].callback()
            local encoder = sjson.encoder(result)
            while true do
                data = encoder:read(64)
                if not data then
                    break
                end
                concat=concat..data
            end
            print("\n\tRPC - SENT MESSAGE\n\tMESSAGE: ".. concat)
            ws:send(concat)
        
        end
    end)
end
