#!/bin/bash

# Get number of iterations from user
echo "Enter number of EKI iterations (or press Enter for default 20):"
read -r MAX_ITERS
if [ -z "$MAX_ITERS" ]; then
    MAX_ITERS=20
fi
echo "Using $MAX_ITERS iterations"

sed -i "s/max_iters: [0-9]*/max_iters: $MAX_ITERS/g" ensemble.yaml
sed -i "s/check_max.sh [0-9]*/check_max.sh $MAX_ITERS/g" ensemble.yaml

# Get job name prefix from user
echo "Enter a name for your ensemble jobs (or press Enter to use your username):"
read -r JOB_PREFIX
if [ -z "$JOB_PREFIX" ]; then
    JOB_PREFIX=$USER
fi
echo "Using job prefix: $JOB_PREFIX"

# Reset ensemble_member job prefix if any previous changes have occurred and insert the new one
sed -i "s/[a-zA-Z0-9_]*_ensemble_member/ensemble_member/g" ensemble.yaml
sed -i "s/ensemble_member/${JOB_PREFIX}_ensemble_member/g" ensemble.yaml

source venv/bin/activate
# Setup Julia packages
echo "  Setting up Julia packages..."
/users/miradh/.julia/juliaup/julia-1.11.6+0.x64.linux.gnu/bin/julia --project=. -e "
using Pkg;
Pkg.activate(\".\");
Pkg.add(url=\"https://github.com/WAVI-ice-sheet-model/WAVI.jl\", rev=\"Alex-EKF\");
Pkg.instantiate();
"
echo "Package setup complete"

echo "running model_ensemble -p -rt 30 -st 10 -ct 30 -v ensemble.yaml ..." 
#nohup model_ensemble -rt 1 -st 1 -ct 1 -p -v ensemble.yaml dummy > output.log 2>&1 &
nohup model_ensemble -rt 30 -st 10 -ct 30 -p -v ensemble.yaml > output.log 2>&1 &




