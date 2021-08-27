using BVHFiles # load package


print("Enter the name of a BVH file: ")
gname = readline()
print("Enter a name for the resulting RKA file: ")
rname = readline()

# load file, add joints and calculate positions
g = load(gname)
o = offset(g, outneighbors(g, find(g, "J_Atlas"))[1])
add_joint!(g, "J_Atlas", "J_L_Ear", [offset(g, find(g, "J_L_Shoulder"))[1] / 2, 0.0, o[3] / 2])
add_joint!(g, "J_Atlas", "J_R_Ear", [offset(g, find(g, "J_R_Shoulder"))[1] / 2, 0.0, o[3] / 2])
add_joint!(g, 1, "J_L_PelvicCrest", [offset(g, find(g, "J_L_Hip"))[1], 0.0, 0.0])
add_joint!(g, 1, "J_R_PelvicCrest", [offset(g, find(g, "J_R_Hip"))[1], 0.0, 0.0])
global_positions!(g)

function determine_number(v::Integer)
    nameᵥ = name(g, v)

    if nameᵥ |> endswith("End Site")
        nameᵥ₋₁ = name(g, inneighbors(g, v)[1])

        nameᵥ₋₁ |> endswith("J_Atlas") && return 1
        nameᵥ₋₁ |> endswith("J_L_Bale") && return 19
        nameᵥ₋₁ |> endswith("J_L_Ankle") && return 20
        nameᵥ₋₁ |> endswith("J_R_Bale") && return 21
        nameᵥ₋₁ |> endswith("J_R_Ankle") && return 22
    end

    nameᵥ |> endswith("J_L_Ear") && return 2
    nameᵥ |> endswith("J_R_Ear") && return 3
    nameᵥ |> endswith("J_L_Shoulder") && return 4
    nameᵥ |> endswith("J_C5") && return 5
    nameᵥ |> endswith("J_R_Shoulder") && return 6
    nameᵥ |> endswith("J_L_Elbow") && return 7
    nameᵥ |> endswith("J_R_Elbow") && return 8
    nameᵥ |> endswith("J_L_Hand") && return 9
    nameᵥ |> endswith("J_R_Hand") && return 10
    nameᵥ |> endswith("J_L_PelvicCrest") && return 11
    nameᵥ |> endswith("J_R_PelvicCrest") && return 12
    nameᵥ |> endswith("J_L_Hip") && return 13
    nameᵥ |> endswith("J_R_Hip") && return 14
    nameᵥ |> endswith("J_L_Knee") && return 15
    nameᵥ |> endswith("J_R_Knee") && return 16
    nameᵥ |> endswith("J_L_Ankle") && return 17
    nameᵥ |> endswith("J_R_Ankle") && return 18

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