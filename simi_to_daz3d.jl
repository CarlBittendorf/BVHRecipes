using BVHFiles # load package


print("Enter the name of the Simi file that should be transformed: ")
gname = readline()
print("Enter the name of a DAZ3D file: ")
dname = readline()
print("Enter a name for the resulting BVH file: ")
rname = readline()

# custom load-function for the additional degrees of freedom
function load_simi(filename::AbstractString)
    list = read(filename, String) |> split((' ', '\t', '\n', '\r'))
    g = BVHGraph(1, name = filename, 
                    offset = [parse(Float64, e) for e in list[6:8]],
                    sequence = BVHFiles.shorten(list[11:13]))

    name!(g, 1, "ROOT" * ' ' * list[3])
    sequence!(g, 1, BVHFiles.shorten(list[14:16]))
    i = 17

    function add_joint(v₋₁::Integer)
        while true
            v = add_vertex!(g, name = list[i] * ' ' * list[i + 1])
            add_edge!(g, v₋₁, v, offset = [parse(Float64, e) for e in list[i + 4:i + 6]])
        
            if list[i] == "JOINT"
                sequence!(g, v, BVHFiles.shorten(list[i + 12:i + 14]))
                i += 15
                add_joint(v)
                i += 1
            else
                i += 8
            end
        
            list[i] != "JOINT" && list[i] != "End" && break
        end
    end

    add_joint(1)
    frames = parse(Int64, list[i + 3])
    frames!(g, frames)
    frametime!(g, parse(Float64, list[i + 6]))
    positions!(g, zeros(Float64, frames, 3))

    for v in vertices(g)
        outneighbors(g, v) != [] && rotations!(g, v, zeros(Float64, frames, 3))
        outneighbors(g, v) != [] && positions!(g, v, zeros(Float64, frames, 3))
    end

    i += 7
    
    function add_frame(v::Integer, f::Integer)
        positions(g, v)[f, :] = [parse(Float64, e) for e in list[i:i + 2]]
        rotations(g, v)[f, :] = [parse(Float64, e) for e in list[i + 3:i + 5]]
        i += 6
        
        for n in outneighbors(g, v)
            outneighbors(g, n) != [] && add_frame(n, f)
        end
    end

    for f in 1:frames
        positions(g)[f, :] = [parse(Float64, e) for e in list[i:i + 2]]
        rotations(g, 1)[f, :] = [parse(Float64, e) for e in list[i + 3:i + 5]]
        i += 6

        for n in outneighbors(g, 1)
            outneighbors(g, n) != [] && add_frame(n, f)
        end
    end

    return g
end

# load file
g = load_simi(gname)

dict = Dict(
    "Pelvis" => "pelvis", 
    "Hip,_left" => "lThighBend", 
    "Hip,_right" => "rThighBend", 
    "Knee,_left" => "lShin", 
    "Knee,_right" => "rShin", 
    "Ankle,_left" => "lFoot", 
    "Ankle,_right" => "rFoot", 
    "Torso" => "abdomenLower", 
    "Spine,_low" => "chestLower", 
    "Spine,_high" => "chestUpper", 
    "Shoulder,_left" => "lShldrBend", 
    "Shoulder,_right" => "rShldrBend", 
    "Elbow,_left" => "lForearmBend", 
    "Elbow,_right" => "rForearmBend", 
    "Wrist,_left" => "lHand", 
    "Wrist,_right" => "rHand", 
    "Neck" => "neckLower", 
    "Skullbase" => "neckUpper")

# add joints and change the names of joints to their DAZ3D counterpart
g |>
    rename!(dict) |>
    add_joint!("lThighBend", "lShin", "lThighTwist") |>
    add_joint!("rThighBend", "rShin", "rThighTwist") |>
    add_joint!("lShldrBend", "lForearmBend", "lShldrTwist") |>
    add_joint!("rShldrBend", "rForearmBend", "rShldrTwist") |>
    add_joint!("lForearmBend", "lHand", "lForearmTwist") |>
    add_joint!("rForearmBend", "rHand", "rForearmTwist")

# add additional joints and rename ROOT
name!(g, 1, "ROOT hip")
add_joint!(g, "chestUpper", "lCollar", [offset(g, find(g, "lShldrBend"))[1] / 3, offset(g, find(g, "lShldrBend"))[2], 0.0], [find(g, "lShldrBend")])
add_joint!(g, "chestUpper", "rCollar", [offset(g, find(g, "rShldrBend"))[1] / 3, offset(g, find(g, "rShldrBend"))[2], 0.0], [find(g, "rShldrBend")])
offset!(g, find(g, "abdomenLower"), [0.0, 2.0, -2.0])
add_joint!(g, "abdomenLower", "chestLower", "abdomenUpper")
ofoot = offset(g, find(g, "lShin"), find(g, "lFoot"))
add_joint!(g, "lFoot", "lMetatarsals", [0.0, ofoot[2] / 70, ofoot[2] / 70])
add_joint!(g, "rFoot", "rMetatarsals", [0.0, ofoot[2] / 70, ofoot[2] / 70])
offset!(g, find(g, "pelvis"), [0.0, 5.0, 0.0])
offset!(g, 6, [0.0, 0.0, 10.0])
offset!(g, 10, [0.0, 0.0, 10.0])
offset!(g, 17, [0.0, -10.0, 0.0])
offset!(g, 21, [0.0, -10.0, 0.0])
exclude = [find(g, "lCollar"), find(g, "rCollar"), find(g, "lThighBend"), find(g, "rThighBend")]

# replace the offsets of the Simi hierarchy
replace_offsets!(g, load(dname), exclude)

# load a DAZ3D hierarchy, add the necessary frames and transfer the rotations from Simi to DAZ3D
d = load(dname) |>
    zero! |>
    add_frames!(frames(g) - frames(load(dname))) |>
    project!(g)

# save the DAZ3D hierarchy to a file
save(d, rname)