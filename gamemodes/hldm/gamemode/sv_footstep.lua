if not HLDM_SOUNDS or not HLDM_SOUNDS.Footsteps then
    return
end

for mat, sounds in pairs(HLDM_SOUNDS.Footsteps) do
    for _, soundpath in pairs(sounds) do
        --print(soundpath)
        resource.AddFile("sound/" .. soundpath)
    end
end
