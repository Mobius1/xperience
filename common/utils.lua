function PrintTable(table, nb)
    if nb == nil then
        nb = 0
    end

    if type(table) == 'table' then
        local s = ''
        for i = 1, nb + 1, 1 do
            s = s .. "    "
        end
    
        s = '{\n'
        for k,v in pairs(table) do
            if type(k) ~= 'number' then k = '"'..k..'"' end
            for i = 1, nb, 1 do
                s = s .. "    "
            end
            s = s .. '['..k..'] = ' .. PrintTable(v, nb + 1) .. ',\n'
        end
    
        for i = 1, nb, 1 do
            s = s .. "    "
        end
    
        return s .. '}'
    else
        return tostring(table)
    end
end

function TableSize(t)
    local count = 0

    for _,_ in pairs(t) do
        count = count + 1
    end

    return count
end