#!/usr/bin/env luajit

local ffi = require("ffi")

ffi.cdef[[
    unsigned int sleep(unsigned int seconds);
    void usleep(unsigned long usec);
]]

print("[LARPGIT WATCHER] Iniciando monitor optimizado con corutinas y caché ligera...")

-- Función rápida para obtener la lista de archivos sin bloquear masivamente
local function get_recursive_files(dir)
    local files = {}
    local handle = io.popen(string.format("find %s -type f ! -name '*.mpr' ! -path '*/.*' 2>/dev/null", dir))
    if handle then
        for filename in handle:lines() do
            table.insert(files, filename)
        end
        handle:close()
    end
    return files
end

-- Obtener mtime usando stat ultra-rápido
local function get_file_mtime(filepath)
    local handle = io.popen(string.format("stat -c %%Y '%s' 2>/dev/null", filepath))
    if handle then
        local result = handle:read("*all")
        handle:close()
        return tonumber(result)
    end
    return nil
end

-- Generador basado en Corutinas para escanear archivos en lotes y no congelar el ciclo
local function file_scanner_coroutine(files, batch_size)
    return coroutine.create(function()
        while true do
            local cache = {}
            for i = 1, #files, batch_size do
                -- Procesar en lotes pequeños (ej. 20 archivos por iteración)
                local end_idx = math.min(i + batch_size - 1, #files)
                for j = i, end_idx do
                    local filepath = files[j]
                    local mtime = get_file_mtime(filepath)
                    if mtime then
                        cache[filepath] = mtime
                    end
                end
                -- Ceder el control brevemente al bucle principal entre lotes
                coroutine.yield(false, cache)
            end
            -- Ciclo de escaneo completo terminado
            coroutine.yield(true, cache)
        end
    end)
end

local files = get_recursive_files("./")
print(string.format("[WATCHER] Monitoreando %d archivos de forma asíncrona.", #files))

local file_timestamps = {}
-- Inicializar caché inicial
for _, f in ipairs(files) do
    local m = get_file_mtime(f)
    if m then file_timestamps[f] = m end
end

-- Instanciar la corutina procesando en lotes de 30 archivos
local batch_size = 30
local co = file_scanner_coroutine(files, batch_size)
local changed = false

while true do
    -- Reanudar la corutina para auditar el siguiente lote
    local status, is_complete, batch_cache = coroutine.resume(co)
    
    if status and batch_cache then
        -- Fusionar resultados parciales y comparar cambios al vuelo
        for filepath, mtime in pairs(batch_cache) do
            local old_mtime = file_timestamps[filepath]
            if not old_mtime or mtime > old_mtime then
                print(string.format("[WATCHER] Cambio detectado en: %s", filepath))
                file_timestamps[filepath] = mtime
                changed = true
            end
        end
    end
    
    -- Si el lote terminó, evaluamos si hubo cambios para disparar el sync
    if is_complete then
        if changed then
            print("[WATCHER] Sincronizando modelo con bypass...")
            local res = os.execute("./bypass sync dark_kitchen_model.json")
            if res then
                print("[WATCHER] ¡Sincronización completada con éxito!\n")
            else
                print("[WATCHER ERROR] Falló la sincronización.\n")
            end
            changed = false
        end
        
        -- Actualizamos la lista de archivos por si se crearon/eliminaron nuevos recursos
        files = get_recursive_files("./")
        co = file_scanner_coroutine(files, batch_size)
        
        -- Pausa ligera de 500 microsegundos o 1 segundo usando FFI para liberar CPU
        ffi.C.usleep(500000) -- 0.5 segundos de respiro
    end
end

--[[local socket = require("socket")
local os = require("os")

local PORT = 8080
local server = socket.tcp_server(PORT, 10)

print(string.format("[LARPGIT SERVER] Servidor FFI corriendo en http://localhost:%d", PORT))
print("[LARPGIT SERVER] Esperando peticiones de sincronización...")

while true do
    local client_fd = server:accept()
    if client_fd then
        local request = socket.recv(client_fd, 2048)
        if request then
            print("[SERVER] Petición recibida.")
            
            -- Si la petición es para sincronizar o hacer dump
            local response = "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\n\r\nLarpWare Bypass FFI Server Active\n"
            
            if request:find("GET /sync") then
                print("[SERVER] Ejecutando sincronización remota vía HTTP...")
                local status = os.execute("./bypass sync dark_kitchen_model.json")
                if status then
                    response = "HTTP/1.1 200 OK\r\n\r\n[OK] Sincronizacion completada con exito.\n"
                else
                    response = "HTTP/1.1 500 Internal Server Error\r\n\r\n[ERROR] Falló la sincronización.\n"
                end
            end
            
            socket.send(client_fd, response)
        end
        socket.close(client_fd)
    end
end
]]