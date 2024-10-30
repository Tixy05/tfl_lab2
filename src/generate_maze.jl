include("definitions.jl")

using Random
using StatsBase
using DataStructures
using Setfield

"""
Creates random binary planar maze automaton.
Algorithm based on the fact that graph is planar iff it's chromatic
number is less or equal than 3. And that fact is a corollary of the 
Pontryagin-Kuratowski theorem since K_{3, 3} and K_5 are not 
3-colorable graphs.
"""
function create_maze(intersections, exits)
    Q = Set(1:intersections+exits)
    Σ = ('L', 'R')
    q0 = State(1)
    F = Set()
    δ = Dict()

    vertex_colors = Dict(q => no_color for q ∈ Q)

    uncolored = copy(Q)

    vertex_colors[q0] = red
    delete!(uncolored, q0)
    v = q0
    while !isempty(uncolored)
        neighbors = sample([uncolored...], length(uncolored) > 1 ? 2 : 1; replace=false)

        for (index, neighbor) ∈ enumerate(neighbors)
            δ[(v, Σ[index])] = neighbor
        end

        colors = map(neighbors) do _
            neighbour_color = red
            while neighbour_color == vertex_colors[v]
                neighbour_color = rand(
                        delete!(Set(instances(Color)), no_color)
                    )
            end
            neighbour_color
        end

        for (n, c) ∈ zip(neighbors, colors)
            vertex_colors[n] = c
        end

        delete!(uncolored, v)
        for n ∈ neighbors
            delete!(uncolored, n)
        end

        v = neighbors[1]
    end
    
    # mark final states
    exits_found = 0
    for q ∈ Q
        exits_found == exits && break

        is_final = true
        for letter ∈ Σ 
            if haskey(δ, (q, letter))
                is_final = false
                break
            end
        end

        if is_final 
            exits_found += 1; push!(F, q) 
        end
    end

    crossroads = setdiff(Q, F) 
    for q ∈ crossroads, letter ∈ Σ
        if !haskey(δ, (q, letter))
            v = rand(Q)
            while vertex_colors[v] == vertex_colors[q]
                v = rand(Q)
            end
            δ[(q, letter)] = v
        end
    end

    DFA(Q, Σ, δ, q0, F, vertex_colors)
end

maze = create_maze(60, 2)

maze = minimize(maze)

open("automaton.dot", "w") do io
    show(io, maze)
end
for (index, class) ∈ enumerate(equivalence_classes(maze))
    println(index, " ", class)
end
