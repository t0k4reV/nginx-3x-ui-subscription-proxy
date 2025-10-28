local http = require "resty.http"

-- Функция для обработки vless ключей
local function process_vless_keys(config)
    local lines = {}
    for line in config:gmatch("[^\r\n]+") do
        if line:match("^vless://") then
            -- Находим позицию @ для извлечения домена
            local at_pos = line:find("@")
            if at_pos then
                -- Извлекаем часть после @
                local after_at = line:sub(at_pos + 1)
                -- Находим позицию : после @ для получения домена
                local colon_pos = after_at:find(":")
                if colon_pos then
                    local domain = after_at:sub(1, colon_pos - 1)
                    -- Находим позицию # для замены названия
                    local hash_pos = line:find("#")
                    
                    if hash_pos then
                        -- Проверяем домен и заменяем часть после #
                        if domain == "kosss.ru" then
                            line = line:sub(1, hash_pos) .. "Sweden"
                        elseif domain == "france.kosss.ru" then
                            line = line:sub(1, hash_pos) .. "France"
                        end
                    end
                end
            end
        end
        table.insert(lines, line)
    end
    return table.concat(lines, "\n")
end

-- Получаем список серверов из переменной окружения
local servers_str = os.getenv("SERVERS")
if not servers_str then
    ngx.log(ngx.ERR, "No servers found in environment variable")
    ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
end

-- Разделяем строку на таблицу серверов
local servers = {}
for server in string.gmatch(servers_str, "[^%s]+") do
    table.insert(servers, server)
end

local httpc = http.new()
local configs = {}

-- Запрашиваем конфигурацию с каждого сервера
for _, base_url in ipairs(servers) do
    local url = base_url .. ngx.var.sub_id
    local res, err = httpc:request_uri(url, {
        method = "GET",
        ssl_verify = false,  -- Параметр для пропуска проверки SSL-сертификатов (если необходимо)
    })

    if res and res.status == 200 then
        -- Декодируем ответ
        local decoded_config = ngx.decode_base64(res.body)
        if decoded_config then
            -- Обрабатываем ключи vless для kosss.ru
            local processed_config = process_vless_keys(decoded_config)
            table.insert(configs, processed_config)
        else
            ngx.log(ngx.ERR, "Failed to decode base64 from ", url)
        end
    else
        ngx.log(ngx.ERR, "Error fetching from ", url, ": ", err)
    end
end

-- Возвращаем объединённые конфигурации клиенту
if #configs > 0 then
    -- Объединяем без добавления новой строки между конфигурациями
    local combined_configs = table.concat(configs)
    local encoded_combined_configs = ngx.encode_base64(combined_configs)
    ngx.header.content_type = "text/plain; charset=utf-8" -- Устанавливаем Content-Type
    ngx.print(encoded_combined_configs) -- Возвращаем клиенту результат без лишней новой строки
else
    ngx.status = ngx.HTTP_BAD_GATEWAY
    ngx.say("No configs available")
end
