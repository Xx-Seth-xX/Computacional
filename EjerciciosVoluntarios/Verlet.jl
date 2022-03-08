module Verlet
    using DataFrames
    #Estructura que almacena toda la información necesaria de una partícula
    struct Particle
        x::Vector{Float64}
        v::Vector{Float64}
        a::Vector{Float64}
        mass::Float64
        Particle(x, v, mass) = new(x, v,  zeros(Real, length(x)) ,mass)
        Particle(x, v, a, mass) = new(x, v, a, mass)
    end

    #Microestado del sistema en un tiempo t
    struct Frame
        t::Float64
        particles::Vector{Particle}
    end

    function dataFrameRowFromFrame(frame::Frame)::DataFrame
        df = DataFrame()
        insertcols!(df, "time" => [frame.t])
        for (id, p) in enumerate(frame.particles)
            for (i, x) in enumerate(p.x)
                insertcols!(df, ("p"*string(id)*"x"*string(i)) => [x])
            end
            for (i, v) in enumerate(p.v)
                insertcols!(df, ("p"*string(id)*"v"*string(i)) => [v])
            end
        end
        return df
    end
    function addFrameRowToDataFrame!(df::DataFrame, frame::Frame)::DataFrame
        append!(df, dataFrameRowFromFrame(frame))
    end

    function stepFrame(frame::Frame, step::Float64, acceleration::Function, update::Function)::Frame
        aux_particles = Vector{Particle}(undef, 0)
        new_particles = Vector{Particle}(undef, 0)

        for p in frame.particles
            initial_a = acceleration(p, frame)
            aux_w = p.v .+ step/2 .* initial_a
            new_x = p.x .+ step .* aux_w
            push!(aux_particles, Particle(new_x, p.v, initial_a,p.mass))
        end

        if update ≢ nothing
            aux_frame = update(frame)::Frame
        end
        aux_frame = Frame(frame.t + step, aux_particles)
        for p in aux_frame.particles
            new_a = acceleration(p, aux_frame)::Vector{Float64}
            aux_w = p.v .+ step/2 .* p.a
            new_v = aux_w .+ step/2 .* new_a
            push!(new_particles, Particle(p.x, new_v, p.mass))
        end

        return update(Frame(frame.t + step, new_particles))::Frame
    end

    function stepFrame(frame::Frame, step::Float64, acceleration::Function)::Frame
        stepFrame(frame, step, acceleration, (x) -> x)
    end

    #Funciones mecánicas adicionales
    calculateMomentum(p::Particle)::Vector{Float64} = p.v * p.mass
    calculateMomentum(f::Frame)::Vector{Float64} = sum(calculateMomentum, f.particles)
end