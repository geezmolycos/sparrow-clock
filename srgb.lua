local srgb = {}

function srgb.component_from_linear(x)
    if x <= 0.0031308 then
        return x * 12.92
    else
        return math.pow(x, 1.0/2.4) * 1.055 - 0.055
    end
end

function srgb.from_linear(r, g, b, a)
    if a then
        return srgb.component_from_linear(r),
               srgb.component_from_linear(g),
               srgb.component_from_linear(b),
               a
    elseif b then
        return srgb.component_from_linear(r),
               srgb.component_from_linear(g),
               srgb.component_from_linear(b)
    elseif type(r) == "table" and #r == 4 then
        return {
            srgb.component_from_linear(r[1]),
            srgb.component_from_linear(r[2]),
            srgb.component_from_linear(r[3]),
            r[4]
        }
    elseif type(r) == "table" and #r == 3 then
        return {
            srgb.component_from_linear(r[1]),
            srgb.component_from_linear(r[2]),
            srgb.component_from_linear(r[3])
        }
    end
    return srgb.component_from_linear(r)
end

function srgb.component_to_linear(x)
    if x <= 0.04045 then
        return x / 12.92
    else
        return math.pow((x + 0.055) / 1.055, 2.4)
    end
end

function srgb.to_linear(r, g, b, a)
    if a then
        return srgb.component_to_linear(r),
               srgb.component_to_linear(g),
               srgb.component_to_linear(b),
               a
    elseif b then
        return srgb.component_to_linear(r),
               srgb.component_to_linear(g),
               srgb.component_to_linear(b)
    elseif type(r) == "table" and #r == 4 then
        return {
            srgb.component_to_linear(r[1]),
            srgb.component_to_linear(r[2]),
            srgb.component_to_linear(r[3]),
            r[4]
        }
    elseif type(r) == "table" and #r == 3 then
        return {
            srgb.component_to_linear(r[1]),
            srgb.component_to_linear(r[2]),
            srgb.component_to_linear(r[3])
        }
    end
    return srgb.component_to_linear(r)
end

function srgb.interpolate(ratio, c1, c2)
    local r1, g1, b1 = c1[1], c1[2], c1[3]
    local r2, g2, b2 = c2[1], c2[2], c2[3]
    if type(ratio) == 'number' then
        return r1 * ratio + r2, g1 * ratio + g2, b1 * ratio + b2
    else
        local result = {}
        for i, it in ipairs(ratio) do
            local r, g, b = r1 * it + r2, g1 * it + g2, b1 * it + b2
            table.insert(result, {r, g, b})
        end
        return result
    end
end

function srgb.interpolate_in_linear(ratio, c1, c2)
    local r1l, g1l, b1l = srgb.to_linear(c1[1], c1[2], c1[3])
    local r2l, g2l, b2l = srgb.to_linear(c1[1], c1[2], c1[3])
    if type(ratio) == 'number' then
        return srgb.from_linear(r1l * ratio + r2l, g1l * ratio + g2l, b1l * ratio + b2l)
    else
        local result = {}
        for i, it in ipairs(ratio) do
            local r, g, b = srgb.from_linear(r1l * it + r2l, g1l * it + g2l, b1l * it + b2l)
            table.insert(result, {r, g, b})
        end
        return result
    end
end

function srgb.to_byte_range(r, g, b, a)
    if a then
        return r * 255, g * 255, b * 255, a * 255
    elseif b then
        return r * 255, g * 255, b * 255
    else
        return r * 255
    end
end

function srgb.to_float_range(r, g, b, a)
    if a then
        return r / 255, g / 255, b / 255, a / 255
    elseif b then
        return r / 255, g / 255, b / 255
    else
        return r / 255
    end
end

return srgb