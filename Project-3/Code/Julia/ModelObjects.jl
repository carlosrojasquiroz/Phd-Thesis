# ModelObjects.jl

include("StatsFun.jl")

function Matrices(p::Param)
#===================================================================================
This function calculates the matrices of the model as the debt grid (B), the
commodity price grid (P) and the transition matrix (Π), the default cost function 
(P̂) and the debt price (Q)
===================================================================================#    
    @unpack bl, bh, Nb, ρo, μo, σo, Np, m, r, ψ, d0, d1, cost_fn = p    
    # Debt grid   
    B = collect(range(bl, stop=bh, length=Nb))
    # AR(1) - oil price
    P, Π = tauchen(m, μo, ρo, σo, Np)
    P = exp.(P)
    # Position of B = 0
    I0 = findfirst(B .>= 0)
    # Debt price
    Q = ones(Np, Nb) .* 1/(1 + r)
    # Cost function
    if cost_fn == 0
        P̂ = ψ .* P
    elseif cost_fn == 1
        P̂ = min.(ψ .* mean(P), P)   
    elseif cost_fn == 2
        P̂ = P - max(d0 .* P .+ d1 .* P.^2, 0);               
    end
    # Return results as a dictionary
    return Dict(
        :B => B,
        :P => P,
        :Π => Π,
        :I0 => I0,
        :Q => Q,
        :P̂ => P̂
    )  
end