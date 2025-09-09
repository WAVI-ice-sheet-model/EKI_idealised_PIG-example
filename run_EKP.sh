#!/bin/bash

# Install required Python packages
pip install ruamel.yaml

# Get number of iterations from user
echo "Enter number of EKI iterations (or press Enter for default 20):"
read -r MAX_ITERS
if [ -z "$MAX_ITERS" ]; then
    MAX_ITERS=20
fi
echo "Using $MAX_ITERS iterations"

sed -i "s/max_iters: [0-9]\+/max_iters: $MAX_ITERS/g" ensemble.yaml
sed -i "s/check_max.sh [0-9]\+/check_max.sh $MAX_ITERS/g" ensemble.yaml

# Get number of ensemble members from user
echo "Enter number of ensemble members (or press Enter for default 10):"
read -r N_MEMBERS
if [ -z "$N_MEMBERS" ]; then
    N_MEMBERS=10
fi
echo "Using $N_MEMBERS ensemble members"

sed -i "s/initialize_EKP.jl output truth.jld2 eki.jld2 ..\/priors.toml [0-9]\+/initialize_EKP.jl output truth.jld2 eki.jld2 ..\/priors.toml $N_MEMBERS/g" ensemble.yaml

# add correct number of members to runs in ensemble.yaml
python3 -c "
import sys
from ruamel.yaml import YAML
 
f = 'ensemble.yaml'
n = int(sys.argv[1])
 
yaml = YAML()
yaml.preserve_quotes = True
data = yaml.load(open(f))
 
# Update runs: works for top-level or nested ensemble->batches
if 'ensemble' in data and 'batches' in data['ensemble']:
    for batch in data['ensemble']['batches']:
        batch['runs'] = [{} for _ in range(n)]
else:
    data['runs'] = [{} for _ in range(n)]
 
yaml.dump(data, open(f, 'w'))
" $N_MEMBERS


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




