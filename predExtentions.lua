local predictionExtentions = {}

function predictionExtentions:GetMissileTime(Position, input) -- returns time in seconds
    local missleTime = (player.pos:distance(Position) / input.speed + input.delay)

    print("Missle time is " .. missleTime .. " seconds")

    return missleTime
end

function predictionExtentions:GetGlobalPrediction(target, input)
    local localInput = input

    localInput.range = 0

    local prediction = pred.getPrediction(target, localInput)

    return prediction
end

function predictionExtentions:GetMissileSpeed(Position, time, delay) -- returns time in seconds
    if time - delay <= 0 then return 0 end

    local speed = player.pos:distance(Position)/(time-delay)

    return speed
end

return predictionExtentions
