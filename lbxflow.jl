const root = dirname(@__FILE__);

println(readall(abspath(joinpath(root, "banner.txt"))));

require(abspath(joinpath(root, "inc", "api.jl")));
require(abspath(joinpath(root, "inc", "boundary.jl")));
require(abspath(joinpath(root, "inc", "collision.jl")));
require(abspath(joinpath(root, "inc", "lattice.jl")));
require(abspath(joinpath(root, "inc", "lbxio.jl")));
require(abspath(joinpath(root, "inc", "multiscale.jl")));
require(abspath(joinpath(root, "inc", "simulate.jl")));

function main(inputfile)
  println("Load simulation defintions from inputfile $inputfile");
  const def = load_sim_definitions(inputfile);

  println("Definitions: ", def);

  lat = Lattice(def["dx"], def["dt"], def["ni"], def["nj"], def["rhoo"]);
  msm = MultiscaleMap(def["nu"], lat, def["rhoo"]);

  #! Initialize velocity at inlet
  #=
  for j=1:def["nj"]
    msm.u[1,j,1] = def["u_inlet"];
  end

  #! Zero y-component of velocity at outlet
  zero_v_at_outlet!(msm::MultiscaleMap, k::Int) = begin
    ni, nj = size(msm.u);
    for j=1:nj
      msm.u[ni,j,2] = 0.0;
    end
  end
  =#

  #! Correct density at inlet
  #=correct_rho_inlet!(msm::MultiscaleMap, k::Int) = begin
    ni, nj = size(msm.u);
    for j=1:nj
      msm.u[ni,j,2] = 0.0;
    end
  end
  =#

  #! Extract velocity profile cut parallel to y-axis
  #=
  extract_prof_f(i::Int) = begin

    return (msm::MultiscaleMap) -> begin
      const nj = size(msm.u)[2];
      x = Array(Float64, (nj, 3));

      for j=1:nj
        x[j,:] = [j, msm.u[i,j,1], msm.u[i,j,2]];
      end

      return x;
    end;

  end

  const nito5 = convert(Int, round(def["ni"]/5.));
  const nito4 = convert(Int, round(def["ni"]/4.));
  const nito2 = convert(Int, round(def["ni"]/2.));
  =#

  # TODO: make this less problem specific
  # TODO: move this to inputfile
  #! Collect callback functions for end of each iteration
  callbacks! = [
    write_datafile_callback("u", def["stepout"],
      ((msm::MultiscaleMap) -> return msm.u[:,:,1]), def["datadir"]),
    write_datafile_callback("v", def["stepout"],
      ((msm::MultiscaleMap) -> return msm.u[:,:,2]), def["datadir"]),
    write_datafile_callback("u_mag", def["stepout"], u_mag, def["datadir"]),
    (msm::MultiscaleMap, k::Int) -> begin
      if k % 5 == 0
        println("step $k");
      end
    end
  ]

  # if data directory does not exist, create it
  if !isdir(def["datadir"])
    println(def["datadir"], " does not exist. Creating now...");
    mkdir(def["datadir"]);
  end

  println("Starting simulation...");
  println();

  if in("test_for_term", keys(def))
    const n = simulate!(lat, msm, def["col_f"], def["bcs"], def["nsteps"],
      def["test_for_term"], callbacks!);
  else
    const n = simulate!(lat, msm, def["col_f"], def["bcs"], def["nsteps"],
      callbacks!);
  end

  println("Steps simulated: $n");

end

# parsing arguments and user interface
if length(ARGS) != 1
  println("usage: julia lbxflow.jl inputfile.js");
  exit(1);
end

if !isfile(ARGS[1])
  println(ARGS[1], " not found. Please use valid path to input file.");
end

main(ARGS[1]);
