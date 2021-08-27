using BVHFiles # load package


print("Enter the name of a BVH file: ")
gname = readline()
print("Enter a name for the resulting RKA file: ")
rname = readline()

# load file, add joints and calculate positions
g = load(gname)
add_joint!(g, 1, "lPelvicCrest", [offset(g, find(g, "lThighBend"))[1], 0.0, 0.0])
add_joint!(g, 1, "rPelvicCrest", [offset(g, find(g, "rThighBend"))[1], 0.0, 0.0])
add_joint!(g, "lMetatarsals", "lAnkle", [0.0, offset(g, find(g, "lToe"))[2], offset(g, find(g, "lToe"))[3] * -0.3])
add_joint!(g, "rMetatarsals", "rAnkle", [0.0, offset(g, find(g, "rToe"))[2], offset(g, find(g, "rToe"))[3] * -0.3])
global_positions!(g)

function determine_number(v::Integer)
    nameᵥ = name(g, v)

    if nameᵥ |> endswith("End Site")
        nameᵥ₋₁ = name(g, inneighbors(g, v)[1])
        nameᵥ₋₁ |> endswith("lEar") && return 2
        nameᵥ₋₁ |> endswith("rEar") && return 3
        nameᵥ₋₁ |> endswith("lMetatarsals") && return 19
        nameᵥ₋₁ |> endswith("rMetatarsals") && return 21
    end

    nameᵥ |> endswith("neckUpper") && return 1
    nameᵥ |> endswith("lShldrBend") && return 4
    nameᵥ |> endswith("neckLower") && return 5
    nameᵥ |> endswith("rShldrBend") && return 6
    nameᵥ |> endswith("lForearmBend") && return 7
    nameᵥ |> endswith("rForearmBend") && return 8
    nameᵥ |> endswith("lHand") && return 9
    nameᵥ |> endswith("rHand") && return 10
    nameᵥ |> endswith("lPelvicCrest") && return 11
    nameᵥ |> endswith("rPelvicCrest") && return 12
    nameᵥ |> endswith("lThighBend") && return 13
    nameᵥ |> endswith("rThighBend") && return 14
    nameᵥ |> endswith("lShin") && return 15
    nameᵥ |> endswith("rShin") && return 16
    nameᵥ |> endswith("lMetatarsals") && return 17
    nameᵥ |> endswith("rMetatarsals") && return 18
    nameᵥ |> endswith("lAnkle") && return 20
    nameᵥ |> endswith("rAnkle") && return 22

    return false
end

function add_positions!(v::Integer, s::AbstractString)
    num = determine_number(v)

    if num != false
        p = positions(g, v)
    
        for f = 1:frames(g)
            s *= "$f\t$(num)\t$(['\t' * string(round(e, digits = 3)) for e ∈ p[f, :]]...)\n"
        end
    end
        
    for n in outneighbors(g, v)
        s = add_positions!(n, s)
    end

    return s
end

# extend the string using the positions of the vertices and save it to a file
open(rname, "w") do io
    print(io, add_positions!(1, ""))
end