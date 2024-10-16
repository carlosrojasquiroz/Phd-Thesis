# HouseholdsOptim.jl

function consumption(P, τ, p::Param)
#===================================================================================
This function computes households' consumption (c)
    c(P) = f(P, parameters)
===================================================================================#    
    f = firms(P, τ, p)
    hm = f[:hm]
    hc = f[:hc]
    wm = f[:wm]
    wc = f[:wc]
    pim = f[:pim]
    pic = f[:pic]      
    c = (wm .* hm .+ wc .* hc .+ pim .+ pic) ./ (1 .+ τ)
    c = max.(c, 0)
    return c
end

function utility(P, B, Bp, τ, Q, p::Param)
#===================================================================================
This function computes households' utility (u)
    u(P, B, B') = f(P, B, B', τ(P, B, B'), Q(P, B'), parameters)
===================================================================================# 
    f = firms(P, τ, p)
    hm = f[:hm]
    hc = f[:hc]
    c = consumption(P, τ, p)
    g = spending(P, B, Bp, τ, Q, p)
    @unpack ϕ, ωm, γm, ωc, γc, σ = p  
    u = ϕ .* (c .- ωm .* hm .^ (1 + γm) ./ (1 + γm) .- ωc .* hc .^ (1 + γc) ./ (1 + γc)).^ (1 - σ) ./ (1 - σ) .+ (1 - ϕ) .* g .^ (1 - σ) ./ (1 - σ)
    if isa(u, Float64)
        if c == 0 || g == 0 
            u = - Inf
        end
    else
    u[c .<= 0] .= -Inf
    u[g .<= 0] .= -Inf
    end
    return u
end