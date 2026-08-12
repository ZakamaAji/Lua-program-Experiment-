-- chat.lua
-- Mini app de chat para CC:Tweaked usando rednet

local PROTOCOLO = "chat"

-- Buscar y abrir un modem automáticamente
local modem = peripheral.find("modem")
if not modem then
    print("Error: no se encontro ningun modem conectado.")
    return
end

rednet.open(peripheral.getName(modem))

-- Pedir nombre de usuario
term.clear()
term.setCursorPos(1, 1)
write("Tu nombre: ")
local nombre = read()

-- Anunciarse en la red bajo el protocolo "chat"
rednet.host(PROTOCOLO, nombre)

term.clear()
term.setCursorPos(1, 1)
print("=== Chat CC:Tweaked (" .. nombre .. ") ===")
print("Escribe un mensaje y presiona Enter para enviarlo (broadcast).")
print("Escribe /msg <id> <mensaje> para enviar privado.")
print("Escribe /salir para cerrar.")
print("----------------------------------------")

-- Hilo que escucha mensajes entrantes
local function recibir()
    while true do
        local id, mensaje, protocolo = rednet.receive(PROTOCOLO)
        if protocolo == PROTOCOLO then
            print("[" .. id .. "] " .. tostring(mensaje))
        end
    end
end

-- Hilo que maneja lo que el usuario escribe
local function enviar()
    while true do
        write("> ")
        local entrada = read()

        if entrada == "/salir" then
            rednet.unhost(PROTOCOLO)
            print("Cerrando chat...")
            return
        elseif entrada:sub(1, 5) == "/msg " then
            -- /msg <id> <mensaje>
            local idStr, msg = entrada:match("^/msg%s+(%d+)%s+(.+)$")
            if idStr and msg then
                local idDestino = tonumber(idStr)
                rednet.send(idDestino, nombre .. ": " .. msg, PROTOCOLO)
                print("(privado a " .. idDestino .. "): " .. msg)
            else
                print("Uso: /msg <id> <mensaje>")
            end
        elseif entrada ~= "" then
            rednet.broadcast(nombre .. ": " .. entrada, PROTOCOLO)
        end
    end
end

-- Correr ambos hilos en paralelo
parallel.waitForAny(recibir, enviar)

rednet.close(peripheral.getName(modem))