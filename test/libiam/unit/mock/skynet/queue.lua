local queue = function()
    local func = function(func_input)
        func_input()
    end
    return func
end
return queue