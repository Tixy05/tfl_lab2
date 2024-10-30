const State = Int 
const Letter = AbstractChar
const Word = AbstractString

@enum Color begin
    no_color
    red
    green
    blue
end

struct DFA
    Q::Set{State}  # States
    Σ::Tuple{Vararg{Letter}}  # Alphabet
    δ::Dict{Tuple{State, Letter}, State}  # Transition function
    q0::State  # Initital state
    F::Set{State}  # Final states
    color_mapping::Dict{State, Color}

    function DFA(Q, Σ, δ, q0, F, color_mapping=Dict())
        new(Q, Σ, δ, q0, F, color_mapping)
    end
end

"""
Note that visualizing big .dot file (over couple hundred vertices) may 
result in very long processing time. Also, even if graph is planar in theory, 
it may be not rendered as a planar.  
"""
function Base.show(io::IO, automaton::DFA)
    res = ""
    for q ∈ automaton.Q
        if q ∈ automaton.F
            res *= "$q [shape=doublecircle]"
        else
            res *= "$q [shape=circle]"
        end
        if haskey(automaton.color_mapping, q) && automaton.color_mapping[q] ≠ no_color
            res *= " [color=$(automaton.color_mapping[q])]"
        end
        res *= "\n"
    end

    res *= "start [shape=point]\n"
    res *= "start -> $(automaton.q0)\n"
    for ((start_state, letter), end_state) ∈ automaton.δ
        res *= "$start_state -> $end_state [label=$letter]\n"
    end
    res = "digraph Automaton {\n" * res * "}\n"
    print(io, res)
end

"""
Dumb implementation of the Hopcroft minimization algorithm.
Runs at O(|Σ||E|log|E|) time.
"""
function equivalence_classes(α::DFA)
    P = Set()
    W = Set()
    push!(P, α.F, setdiff(α.Q, α.F))
    push!(W, α.F, setdiff(α.Q, α.F))

    while !isempty(W)
        A = rand(W)
        delete!(W, A)
        for c ∈ α.Σ
            X = Set()
            for q ∈ α.Q
                !haskey(α.δ, (q, c)) && continue
                α.δ[(q, c)] ∈ A && push!(X, q)
            end
            for Y ∈ P
                if isempty(X ∩ Y) || isempty(setdiff(Y, X))
                    continue
                end
                delete!(P, Y)
                push!(P, X ∩ Y, setdiff(Y, X))
                if Y ∈ W
                    delete!(W, Y)
                    push!(W, X ∩ Y, setdiff(Y, X))
                else
                    if length(X ∩ Y) <= length(setdiff(Y, X))
                        push!(W, X ∩ Y)
                    else
                        push!(W, setdiff(Y, X))
                    end
                end
            end
        end
    end

    P
end

function minimize(α::DFA)::DFA
    classes = [equivalence_classes(α)...]
    state_to_class = Dict()
    for (index, class) ∈ enumerate(classes), state ∈ class
        state_to_class[state] = index
    end

    new_Q = Set(eachindex(classes))
    new_Σ = α.Σ
    new_δ = Dict()
    new_F = Set()
    new_q0 = state_to_class[α.q0]
    for (index, class) ∈ enumerate(classes), c ∈ α.Σ
        q = rand(class)
        if q ∈ α.F
            push!(new_F, index)
            continue
        end
        new_δ[(index, c)] = state_to_class[α.δ[(q, c)]]
        
    end

    DFA(new_Q, new_Σ, new_δ, new_q0, new_F)
end

# function DFA_from_Lstar(
#         main_prefixes, 
#         complementary_prefixes, 
#         suffixes, 
#         values
#     )
#     Q = Set(1:rows)
# end