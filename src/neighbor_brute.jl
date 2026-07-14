# brute-force O(N²) neighbor search , exhaustive, for testing and validation

struct BruteForce <: AbstractNeighborSearch end

function update!(system, ::BruteForce)
    particles = system.particles
    walls = system.walls
    empty!(system.contacts)
    n = length(particles)

    # particle-particle
    @inbounds for i in 1:n
        pi = particles[i]
        for j in (i + 1):n
            pj = particles[j]
            dist_vec = pi.position - pj.position
            dist = norm(dist_vec)
            overlap = pi.radius + pj.radius - dist
            if overlap > 0
                normal = dist > 0 ? dist_vec / dist : SA[1.0, 0.0, 0.0]
                cp = pi.position - (pi.radius - overlap / 2) * normal
                push!(system.contacts,
                    Contact(
                        i, j, overlap, normal, cp,
                        pi.position - cp,
                        SA[0.0, 0.0, 0.0]
                    ))
            end
        end
    end

    # particle-wall
    @inbounds for i in 1:n
        pi = particles[i]
        for (w_idx, w) in enumerate(walls)
            dist_from_plane = dot(pi.position - w.point, w.normal)
            overlap = pi.radius - dist_from_plane
            if overlap > 0
                cp = pi.position - w.normal * (pi.radius - overlap / 2)
                push!(system.contacts,
                    Contact(
                        i, 0, overlap, w.normal, cp,
                        pi.position - cp,
                        SA[0.0, 0.0, 0.0]
                    ))
            end
        end
    end

    return system.contacts
end
