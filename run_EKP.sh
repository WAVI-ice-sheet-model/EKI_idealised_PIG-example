#!/bin/bash

source venv/bin/activate
# Setup Julia packages
echo "  Setting up Julia packages..."
/data/hpcdata/users/thozwa/.juliaup/bin/julia --project=. -e "
using Pkg;
Pkg.activate(\".\");
Pkg.add(url=\"https://github.com/WAVI-ice-sheet-model/WAVI.jl\", rev=\"Alex-EKF\");
Pkg.instantiate();
"
echo "Package setup complete"

echo "running model_ensemble -p -rt 30 -st 10 -ct 30 -v ensemble.yaml ..." 
nohup model_ensemble -rt 30 -st 10 -ct 30 -p -v ensemble.yaml > output.log 2>&1 &
#model_ensemble -p -rt 30 -st 10 -ct 30 -v ensemble.yaml




