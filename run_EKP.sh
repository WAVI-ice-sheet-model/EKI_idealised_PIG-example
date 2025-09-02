#!/bin/bash

source venv/bin/activate
# Setup Julia packages
echo "  Setting up Julia packages..."
module load hpc/julia/1.8.3
/hpcpackages/julia/1.8.3/bin/julia --project=. -e "
using Pkg;
Pkg.activate(\".\");
Pkg.add(url=\"https://github.com/RJArthern/WAVI.jl\", rev=\"Alex-EKF\");
Pkg.instantiate();
"
echo "Package setup complete"

echo "running model_ensemble -p -rt 30 -st 10 -ct 30 -v ensemble.yaml ..." 
#nohup model_ensemble -rt 1 -st 1 -ct 1 -p -v ensemble.yaml dummy > output.log 2>&1 &
model_ensemble -p -rt 30 -st 10 -ct 30 -v ensemble.yaml




