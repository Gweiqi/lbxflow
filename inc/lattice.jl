# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

abstract Lattice

#! D2Q9 lattice
type LatticeD2Q9 <: Lattice
  dx::AbstractFloat
  dt::AbstractFloat
  cc::AbstractFloat
  cs::AbstractFloat
  cssq::AbstractFloat
  f::Array{Float64, 3}
  c::Matrix{Int64}
  w::Vector{Float64}
  n::Int

  # Default lattice speed vectors and associated weights
  const cdef = [1 0; 0 1; -1 0; 0 -1; 1 1; -1 1; -1 -1; 1 -1; 0 0]';
  const wdef = [1.0/9.0; 1.0/9.0; 1.0/9.0; 1.0/9.0; 1.0/36.0; 1.0/36.0;
                1.0/36.0; 1.0/36.0; 4.0/9.0];
  const n = length(wdef);

  # Lattice functions for computing `c`, `cs`, and `cssq`
  cf(dx, dt)    = dx/dt;
  csf(dx, dt)   = cf(dx, dt) / sqrt(3);
  cssqf(dx, dt) = csf(dx, dt) * csf(dx, dt);

  LatticeD2Q9(dx::AbstractFloat, dt::AbstractFloat, ni::Int, nj::Int) =
    new(dx, dt, cf(dx, dt), csf(dx, dt), cssqf(dx, dt),
        zeros(Float64, (n, ni, nj)), cdef, wdef, n);

  LatticeD2Q9(dx::AbstractFloat, dt::AbstractFloat, f::Array{Float64, 3}) =
    new(dx, dt, cf(dx, dt), csf(dx, dt), cssqf(dx, dt), f, cdef, wdef, n);

  function LatticeD2Q9(dx::AbstractFloat, dt::AbstractFloat, ni::Int, nj::Int,
                       rho::AbstractFloat)
    f = zeros(Float64, (n, ni, nj));
    for k=1:n
      f[k,:,:] = fill(rho * wdef[k], (ni, nj));
    end
    new(dx, dt, cf(dx, dt), csf(dx, dt), cssqf(dx, dt), f, cdef, wdef, n);
  end
end

#! D2Q4 lattice
type LatticeD2Q4 <: Lattice
  dx::AbstractFloat
  dt::AbstractFloat
  cc::AbstractFloat
  cs::AbstractFloat
  cssq::AbstractFloat
  f::Array{Float64, 3}
  c::Matrix{Int64}
  w::Vector{Float64} 
  n::Int

  # Default lattice speed vectors and associated weights
  const cdef = [1 0; -1 0; 0 1; 0 -1]';
  const n = size(cdef, 2);
  const wdef = fill(1.0/4.0, n);

  # Lattice functions for computing `c`, `cs`, and `cssq`
  cf(dx, dt)    = dx/dt;
  csf(dx, dt)   = cf(dx, dt) / sqrt(2);
  cssqf(dx, dt) = csf(dx, dt) * csf(dx, dt);

  LatticeD2Q4(dx::AbstractFloat, dt::AbstractFloat, ni::Int, nj::Int) =
    new(dx, dt, cf(dx, dt), csf(dx, dt), cssqf(dx, dt),
        zeros(Float64, (n, ni, nj)), cdef, wdef, n);

  LatticeD2Q4(dx::AbstractFloat, dt::AbstractFloat, f::Array{Float64, 3}) =
    new(dx, dt, cf(dx, dt), csf(dx, dt), cssqf(dx, dt), f, cdef, wdef, n);

  function LatticeD2Q4(dx::AbstractFloat, dt::AbstractFloat, ni::Int, nj::Int,
                   rho::Float64)
    f = zeros(Float64, (n, ni, nj));
    for k=1:n
      f[k,:,:] = fill(rho * wdef[k], (ni, nj));
    end
    new(dx, dt, cf(dx, dt), csf(dx, dt), cssqf(dx, dt), f, cdef, wdef, n);
  end
end

#! Opposite direction lattice vector index
#!
#! \param lat Lattice
#! \param k Index of lattice vector
#! \return Index of opposite direction
function opp_lat_vec(lat::LatticeD2Q9, k::Int)
  if k == 1
    return 3;
  elseif k == 2
    return 4;
  elseif k == 3
    return 1;
  elseif k == 4
    return 2;
  elseif k == 5
    return 7;
  elseif k == 6
    return 8;
  elseif k == 7
    return 5;
  elseif k == 8
    return 6;
  elseif k == 9
    return 9;
  else
    error("$k > 9 for a D2Q9 lattice. Only nine vectors (1-9) possible");
  end
end

#! Opposite direction lattice vector index
#!
#! \param lat Lattice
#! \param k Index of lattice vector
#! \return Index of opposite direction
function opp_lat_vec(lat::LatticeD2Q4, k::Int)
  error("not yet implemented");
end

#! Helper function for initializing lattice
function _fill_lat(lat::Lattice, i_range::UnitRange{Int}, j_range::UnitRange{Int}, 
                   rho::Real)
  for k=1:lat.n, j=j_range, i=i_range
    lat.f[k, i, j] = rho * lat.w[k];
  end
end
