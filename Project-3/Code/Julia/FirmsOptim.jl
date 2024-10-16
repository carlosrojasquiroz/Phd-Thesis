# FirmsOptim.jl

function firms(P, τ, p::Param)
#===================================================================================
This function computes optimal labor (hm, hc) and intermediate input (m) demands
from firms. It also calculates wages in equilibrium for both sectors (wm, wc)
as well as profit functions (pim, pic), respectively.
===================================================================================#
    @unpack ϑ, ϱ, ωc, zcss, kcss, γc, α, θ, ωm, zmss, kmss, γm, rkss = p    
    # Labor in commodity sector
    hc = ((1 .- ϱ) .* ϑ ./ (ωc .* (1 .+ τ)) .* P .* zcss .* kcss^(1 .- ϑ)).^(1 / (1 - ϑ + γc))
    hc = clamp.(hc, 0, 1)
    # Labor in manufacturing sector
    hm = (α ./ (ωm .* (1 .+ τ))).^((1 - θ) / ((1 - θ) * γm + 1 - α - θ)) .* ((zmss * θ^θ * kmss^(1 - α - θ)) ./ (P .^ θ)).^(1 / ((1 - θ) * γm + 1 - α - θ))
    hm = clamp.(hm, 0, 1)   
    # Intermediate input in manufacturing sector
    m = (θ * zmss .* hm .^ α .* kmss^(1 - α - θ) ./ P).^(1 / (1 - θ))    
    # Wages in equilibrium
    wm = hm .^ γm .* ωm .* (1 .+ τ)
    wc = hc .^ γc .* ωc .* (1 .+ τ)    
    # Profits in equilibrium
    pim = zmss .* hm .^ α .* m .^ θ .* kmss^(1 - α - θ) .- P .* m .- wm .* hm .- rkss .* kmss
    pic = (1 .- ϱ) .* P .* zcss .* hc .^ ϑ .* kcss^(1 - ϑ) .- wc .* hc .- rkss .* kcss    
    # Return results as a dictionary
    return Dict(
        :hc => hc,
        :hm => hm,
        :m  => m,
        :wm => wm,
        :wc => wc,
        :pim => pim,
        :pic => pic
    )
end