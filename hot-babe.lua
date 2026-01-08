--[[

]]--


require 'cairo'

local status, cairo_xlib = pcall(require, 'cairo_xlib')
if not status then
    cairo_xlib = setmetatable({}, { __index = _G })
end



cur_dir = debug.getinfo(1, 'S').source:match[[^@?(.*[\/])[^\/]-$]]
layers_dir = cur_dir .. "hb01/"
layers = {
    layers_dir .. "hb01_4.png",
    layers_dir .. "hb01_3.png",
    layers_dir .. "hb01_2.png",
    layers_dir .. "hb01_1.png",
    layers_dir .. "hb01_0.png"
}



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
