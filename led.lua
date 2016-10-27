wifi.setmode(wifi.STATION)
-- print ap list
function listap(t)
      for k,v in pairs(t) do
        print(k.." : "..v)
      end
end
wifi.sta.getap(listap)


print(wifi.sta.getip())
--nil
wifi.setmode(wifi.STATION)
wifi.sta.config("mywifi","mypassword")
wifi.sta.connect()
tmr.alarm(1, 1000, 1, function()
     if wifi.sta.getip() == nil then
         print("Connecting...")
     else
         tmr.stop(1)
         print("Connected, IP is "..wifi.sta.getip())

          LED_PIN = 1

          m = mqtt.Client("nodemcu", 120)

          function printMessage(client, topic, data)

            gpio.mode(LED_PIN, gpio.OUTPUT)
            gpio.write(LED_PIN, gpio.HIGH)
            tmr.delay(500 * 1000)
            gpio.write(LED_PIN, gpio.LOW)

            print(topic .. ":" )
            if data ~= nil then
              print(data)
            end
          end

          function connected(client)
            print("connected")
            m:on("message", printMessage)
            m:subscribe("/led",0, function(client) print("subscribe success") end)


            tmr.alarm(1, 1000, 1, function()
              value = adc.read(0)
              m:publish("/light",value ,0,0, function(client) print("sent") end)
            end)

          end

          function showError(client, reason)
            print("failed reason: "..reason)
          end

          m:connect("192.168.1.123", 1883, 0, connected, showError)

     end
end)
