const State = Unsigned 
const Letter = AbstractString

struct DFA
    Q::Set{State}  # States
    Σ::Set{Letter}  # Alphabet
    δ::Dict{Tuple{State, Letter}, State}  # Transition function
    q0::State  # Initital state
    F::Set  # Final states
end