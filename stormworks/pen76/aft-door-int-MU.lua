function onTick()

    -- Clear outputs
    output.setBool(1, false)
    output.setBool(2, false)
    output.setBool(3, false)
    output.setBool(4, false)
    output.setBool(5, false)
    output.setBool(6, false)
    output.setBool(7, false)
    output.setBool(8, false)

    -- Inputs 1-8 direct
    if input.getBool(1) then output.setBool(1, true) end
    if input.getBool(2) then output.setBool(2, true) end
    if input.getBool(3) then output.setBool(3, true) end
    if input.getBool(4) then output.setBool(4, true) end
    if input.getBool(5) then output.setBool(5, true) end
    if input.getBool(6) then output.setBool(6, true) end
    if input.getBool(7) then output.setBool(7, true) end
    if input.getBool(8) then output.setBool(8, true) end

    -- Inputs 9-16 swapped pairs
    if input.getBool(9)  then output.setBool(2, true) end
    if input.getBool(10) then output.setBool(1, true) end
    if input.getBool(11) then output.setBool(4, true) end
    if input.getBool(12) then output.setBool(3, true) end
    if input.getBool(13) then output.setBool(6, true) end
    if input.getBool(14) then output.setBool(5, true) end
    if input.getBool(15) then output.setBool(8, true) end
    if input.getBool(16) then output.setBool(7, true) end

    -- Inputs 17-24 direct
    if input.getBool(17) then output.setBool(1, true) end
    if input.getBool(18) then output.setBool(2, true) end
    if input.getBool(19) then output.setBool(3, true) end
    if input.getBool(20) then output.setBool(4, true) end
    if input.getBool(21) then output.setBool(5, true) end
    if input.getBool(22) then output.setBool(6, true) end
    if input.getBool(23) then output.setBool(7, true) end
    if input.getBool(24) then output.setBool(8, true) end

end
