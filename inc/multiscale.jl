__multiscale_root__ = dirname(@__FILE__);
require(abspath(joinpath(__multiscale_root__, "lattice.jl")));

type MultiscaleMap
  dx::FloatingPoint;
  dt::FloatingPoint;
  omega::FloatingPoint;
  u::Array{Float64,3};
  rho::Array{Float64,2};

  MultiscaleMap(nu::FloatingPoint, dx::FloatingPoint, dt::FloatingPoint,
    ni::Unsigned, nj::Unsigned) =
    new(dx, dt, 1.0/(3 * nu * dt / (dx*dx) + 0.5),
      zeros(Float64, (ni, nj, 2)), zeros(Float64, (ni, nj)));

  function MultiscaleMap(nu::FloatingPoint, lat::Lattice, rho::FloatingPoint)
    dx = lat.dx;
    dt = lat.dt;
    ni, nj = size(lat.f);

    new(dx, dt, 1.0/(3 * nu * dt / (dx*dx) + 0.5),
      zeros(Float64, (ni, nj, 2)), fill(rho, (ni, nj)));
  end

  function MultiscaleMap(nu::FloatingPoint, lat::Lattice)
    dx = lat.dx;
    dt = lat.dt;
    ni, nj = size(lat.f);

    new(dx, dt, 1.0/(3 * nu * dt / (dx*dx) + 0.5),
      zeros(Float64, (ni, nj, 2)), zeros(Float64, (ni, nj)));
  end

end

#! Map particle distribution frequencies to macroscopic variables
function map_to_macro!(lat::Lattice, msm::MultiscaleMap)
  ni, nj = size(lat.f);
  nk = length(lat.w);

  for i=1:ni, j=1:nj
    msm.rho[i,j] = 0;

    for k=1:nk
      msm.rho[i,j] += lat.f[i,j,k];
    end

    msm.u[i,j,1] = 0;
    msm.u[i,j,2] = 0;

    for k=1:nk
      msm.u[i,j,1] += lat.f[i,j,k] * lat.c[k,1];
      msm.u[i,j,2] += lat.f[i,j,k] * lat.c[k,2];
    end

    for a=1:2
      msm.u[i,j,a] = msm.u[i,j,a] / msm.rho[i,j];
    end
  end

end

#! Reynold's number
#!
#! \param u Magnitude of macroscopic flow
#! \param l Characteristic length of flow
#! \param nu Kinematic viscosity
#! \return Reyond's number
function reynolds(u::Number, l::Number, nu::Number)
  return u * l / nu;
end

#! Calculate the magnitude of velocity at each lattice node
#!
#! \param msm Multiscale map
#! \return Velocity magnitudes
function u_mag(msm::MultiscaleMap)
  ni, nj = size(msm.u);
  u_mag_res = Array(Float64, (ni, nj));

  for i = 1:ni, j = 1:nj
    u = msm.u[i,j,1];
    v = msm.u[i,j,2];
    u_mag_res[i,j] = sqrt(u*u + v*v);
  end

  return u_mag_res;
end