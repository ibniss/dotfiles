if command -q bat then
    alias cat="bat"
    alias less="bat"
else if command -q batcat then
    alias cat="batcat"
    alias less="batcat"
end
