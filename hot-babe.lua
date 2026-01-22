--[[
    Draw hot-babe
]]--


local cairo = require('cairo')

local status, cairo_xlib = pcall(require, 'cairo_xlib')
if not status then
    cairo_xlib = setmetatable({}, { __index = _G })
end

local settings = require('settings')



cur_dir = debug.getinfo(1, 'S').source:match[[^@?(.*[\/])[^\/]-$]]
themes_dir = cur_dir .. "themes/"
layers = {}



local function load_theme(theme)
    local theme_dir = themes_dir .. theme
    local descr_path = theme_dir .. "/descr"
    local file = io.open(descr_path, "r")
    if not file then return end

    local num = tonumber(file:read("*line")) or 0

    for i = 1, num do
        line = file:read("*line")
        if line ~= "" then
            local path = theme_dir .. "/" .. line
            table.insert(layers, path)
        end
    end

    file:close()
end


local function get_cpu_load()
    local cpu_load = conky_parse('${cpu}')

    return tonumber(cpu_load) or 0
end


local function get_layers(cpu_load)
    if cpu_load <= 0 then
        return {
            {layers[1], 1}
        }
    end
    if cpu_load >= 100 then
        return {
            {layers[#layers], 100 / cpu_load}
        }
    end

    local idx = math.floor(cpu_load * (#layers - 1) / 100)
    local pct_per_layer = 100 / (#layers - 1)
    local rel_pct = 100 * (cpu_load / pct_per_layer - idx)
    idx = idx + 1
    local alpha = 1 - rel_pct / 100

    return {
        {layers[idx + 1], 1},
        {layers[idx], alpha}
    }
end


local function draw_layer(cr, layer)
    local path, alpha = table.unpack(layer)
    local image = cairo_image_surface_create_from_png(path)

    if cairo_surface_status(image) == CAIRO_STATUS_SUCCESS then
        cairo_set_source_surface(cr, image, 0, 0)
        cairo_paint_with_alpha(cr, alpha)
        cairo_surface_destroy(image)
    end
end


local function draw_hot_babe(cr)
    local cpu_load = get_cpu_load()
    local lrs = get_layers(cpu_load)

    for i = 1, #lrs do
        local layer = lrs[i]
        draw_layer(cr, layer)
    end
end



function conky_init()
    load_theme(settings.theme)
end


function conky_main()
    if conky_window == nil then return end

    local updates = conky_parse('${updates}')
    if tonumber(updates) < 2 then return end

    local cs = cairo_xlib_surface_create (conky_window.display,
                                          conky_window.drawable,
                                          conky_window.visual,
                                          conky_window.width,
                                          conky_window.height)
    local cr = cairo_create (cs)

    draw_hot_babe(cr) 

    cairo_destroy (cr)
    cairo_surface_destroy (cs) 
end
