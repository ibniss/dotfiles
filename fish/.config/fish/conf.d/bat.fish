if status is-interactive
    # Keep typed cat/less convenient without shadowing the binaries for Fish code.
    if command -q bat
        abbr --add cat bat
        abbr --add less bat
    else if command -q batcat
        abbr --add cat batcat
        abbr --add less batcat
    end
end
