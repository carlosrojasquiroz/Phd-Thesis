# StatsFun.jl

function cdf_normal(x::Float64)
#===================================================================================
This function computes the Normal's cdf
===================================================================================#     
    return 0.5 * erfc(-x / sqrt(2))
end
    
function tauchen(m₀::Float64, μ₀::Float64, ρ₀::Float64, σ₀::Float64, N::Int64)
#===================================================================================
This function discretize an AR(1) stochastic process
===================================================================================#        
    s = range(μ₀ / (1 - ρ₀) - m₀ * sqrt(σ₀^2 / (1 - ρ₀^2)), μ₀ / (1 - ρ₀) + m₀ * sqrt(σ₀^2 / (1 - ρ₀^2)), length = N) |> collect
    Π = zeros(N, N)
    step = (s[N] - s[1]) / (N - 1)
    for j in 1 : N
        sⱼ = ρ₀ * s[j]
        for k in 1 : N
            mid = (s[k] - μ₀ - sⱼ) / σ₀
            if k == 1
                Π[j, k] = cdf_normal(mid + step / (2 * σ₀))
            elseif k == N
                Π[j, k] = 1 - cdf_normal(mid - step / (2 * σ₀))
            else
                Π[j, k] = cdf_normal(mid + step / (2 * σ₀)) - cdf_normal(mid - step / (2 * σ₀))
            end
        end
    end
    return s, Π
end