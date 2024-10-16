# GovOptim.jl

function spending(P, B, Bp, τ, Q, p::Param)
#===================================================================================
This function computes government's consumption (g)
    g(P, B, B') = f(P, B, B', τ(P, B, B'), Q(P, B'), parameters)
===================================================================================# 
    f = firms(P, τ, p)
    hc = f[:hc]    
    c = consumption(P, τ, p)
    @unpack ϑ, ϱ, zcss, kcss = p  
    g = τ .* c .+ ϱ .* P .* zcss .* hc .^ ϑ .* kcss^(1 - ϑ) .+ Bp .* Q .- B
    g = max.(g, 0)
    return g
end