# Description
This example describes how to install and use [EnsembleKalmanProcesses][1] alongside the [model-ensembler][2], using an idealised Pine Island example. This example is derived from the code in the original library example for learning parameterisations of a sine wave (examples/SinusoidInterface). This current set up is for use on the BAS HPC, using an old version of julia (1.8.3) which is not compatible with later versions of EnsembleKalmanProcesses (versions 2.4.0 and later). This example should therefore default to using version 2.3.1 if not specified in the Project.toml file. 

### Setup

First, clone this repository.

Then, inside it:

```
python -m venv venv
source venv/bin/activate
pip install --upgrade setuptools pip
pip install -r requirements.txt 


# Enter julia REPL
module load hpc/julia/1.8.3
julia
]
activate .
add https://github.com/RJArthern/WAVI.jl#Alex-EKF
instantiate
Ctrl+D
```

### Running overview 
```
# Back in bash
model_ensemble -rt 1 -st 1 -ct 1 -p -v ensemble.yaml dummy
# Or for SLURM
model_ensemble -p -rt 30 -st 10 -ct 30 -v ensemble.yaml
```

# Idealised Pine Island example using Kalman Ensembling

This example using Kalman Ensembling to constrain several parameters: weertman_c_prefactor (basal sliding prefactor), glen_a_prefactor (ice viscosity prefactor), bump_amplitude (magnitude of the 1940s pycnocline displacement), melt_rate_prefactor (ice-shelf basal melt rate exponent prefactor), per_century_trend (per-century-trend in pycnocline height in metres). These parameters are taken from [Bradley et al. 2025][3]. The priors for these parameters are given in ```Priors.toml```.

To run, 

```
./run_EKP.sh
```

This will set up the necessary julia packages and run the EKP.

## Key Files

```generate_data.jl``` - creates the synthetic ‘truth’ data used as observations in this example.

```initialize_EKP.jl``` - generates parameter values using Priors.toml, and sets up the EKP object which gets populated at each iteration. 

```ensemble.yaml``` - sets up the workflow. This defines the jobs, uses templates to insert parameter combinations into each driver script for each ensemble member, and defines how many iterations should be run.

```run_computer_model.jl``` - runs WAVI for each ensemble member and iteration. Calls parameter_to_data_map() in WAVI_driver.jl. 

```WAVI_driver.jl``` - driver script that sets up the WAVI ice sheet model.

```update_EKP.jl``` performs the Ensemble Kalman Update. 



## License

This is a derived example from the Julia library and thus the original attribution license is in LICENSE.example, with the workflow being additionally licensed using the Apache 2.0 license, contained under LICENSE.


[1]: https://github.com/CliMA/EnsembleKalmanProcesses.jl
[2]: https://github.com/JimCircadian/model-ensembler
[3]: https://egusphere.copernicus.org/preprints/2025/egusphere-2025-2315/

