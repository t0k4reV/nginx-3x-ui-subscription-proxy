local http = require "resty.http"

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
            table.insert(configs, decoded_config)
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
