import subprocess
import sys

def install_if_missing(package):
    try:
        __import__(package)
    except ImportError:
        print(f"{package} not found. Installing...")
        subprocess.check_call([sys.executable, "-m", "pip", "install", package])

# List of packages used in your script
packages = ["xarray", "matplotlib", "numpy", "netCDF4", "Dask", "toml"]  # add others if needed

for pkg in packages:
    install_if_missing(pkg)

import glob
import re
import os
import xarray as xr
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import matplotlib.lines as mlines
from matplotlib.cm import ScalarMappable
from matplotlib.colors import Normalize
import toml
import numpy as np
from matplotlib.cm import tab10

import site
site.addsitedir('/users/miradh/.local/lib/python3.10/site-packages')

# Combine all netcdfs from all ensemble members for one iteration, for each iteration.

base_dir = "/data/hpcflash/users/miradh/EKI_idealised_PIG-example/ensemble/output"

iteration_dirs = sorted([d for d in os.listdir(base_dir) if d.startswith("iteration_")])

for iteration in iteration_dirs:
    iteration_path = os.path.join(base_dir, iteration)
    file_paths = sorted(glob.glob(os.path.join(iteration_path, "member_*/outfile.nc")))

    if not file_paths:
        print(f"No member NetCDFs found in {iteration_path}")
        continue

    # Extract member numbers to use as a new dimension
    member_numbers = [
        int(re.search(r"member_(\d+)", f).group(1)) for f in file_paths
    ]

    combined = xr.open_mfdataset(
        file_paths,
        combine="nested",
        concat_dim="run"
    )
    combined = combined.assign_coords(run=("run", member_numbers))

    output_path = os.path.join(iteration_path, "combined_outfile.nc")
    if os.path.exists(output_path):
        print(f"File {output_path} already exists. Deleting it.")
        os.remove(output_path)

    combined.to_netcdf(output_path)
    print(f"Combined NetCDF written to {output_path}")

### Plot iterations ###


# Observations
obs_times = [285, 290, 295, 300]
obs_volumes = [13.77, 13.37, 12.97, 12.52]
yerr = [0.1*v for v in obs_volumes]

base_dir = "/data/hpcflash/users/miradh/EKI_idealised_PIG-example/ensemble/output"
iteration_files = sorted(glob.glob(os.path.join(base_dir, "iteration_*/combined_outfile.nc")))
if not iteration_files:
    raise FileNotFoundError(f"No iteration files found in {base_dir}")

num_iterations = len(iteration_files)

# Open all datasets at once (if feasible)
datasets = [xr.open_dataset(f) for f in iteration_files]
ds0 = datasets[0]
n_members = ds0.sizes['run']
dx = float(ds0.x[1] - ds0.x[0])
dy = float(ds0.y[1] - ds0.y[0])
grid_area = dx * dy

# Setup plot
fig, ax = plt.subplots(figsize=(12, 7))
iter_cmap = plt.colormaps['plasma_r']
norm = Normalize(vmin=1, vmax=num_iterations)

for iter_idx, ds in enumerate(datasets):
    for member_idx in range(n_members):
        h = ds['h'].isel(run=member_idx)
        volume_1e12_m3 = (h * grid_area).sum(dim=['x','y']) / 1e12
        color = iter_cmap(norm(iter_idx + 1))
        ax.plot(ds['TIME'], volume_1e12_m3, color=color)

# Observations
plt.errorbar(obs_times, obs_volumes, yerr=yerr, fmt='o', markersize=7,
             color='red', ecolor='black', elinewidth=2, capsize=0, 
             markeredgecolor='black', label='Observations')

# Colorbar
sm = ScalarMappable(norm=norm, cmap=iter_cmap)
sm.set_array([])
fig.colorbar(sm, ax=ax, label='Iteration', pad=0.02)

# Legend
obs_handle = mlines.Line2D([], [], color='red', marker='o', linestyle='None',
                           markeredgecolor='black', markersize=8, label='Observations')
ax.legend(handles=[obs_handle], loc='upper left', bbox_to_anchor=(1.05, 1))

ax.set_xlabel('Time (years)')
ax.set_ylabel('Ice Volume (×10¹² m³)')
ax.set_ylim(0, 18)
ax.set_yticks(range(0, 19, 2))
fig.tight_layout()

# Save the figure
output_plot_path = os.path.join(base_dir, "ensemble.png")
fig.savefig(output_plot_path, dpi=300, bbox_inches='tight')
print(f"Plot saved to {output_plot_path} as ensemble.png")

### Plot parameter evolution over time ###
n_members = 10
member_colors = {idx: tab10(idx % 10) for idx in range(n_members)}

param_names = [
    "melt_rate_prefactor",
    "bump_amplitude",
    "per_century_trend",
    "weertman_c_prefactor",
    "glen_a_ref_prefactor"
]

base_dir = "/data/hpcflash/users/miradh//EKI_idealised_PIG-example/ensemble/output"

iteration_dirs = sorted(glob.glob(os.path.join(base_dir, "iteration_*")))
num_iterations = len(iteration_dirs)

# Store parameter values: param_name -> member_idx -> list of values over iterations
param_values = {
    param: {member_idx: [] for member_idx in range(n_members)} for param in param_names
}

# Load parameter values
for iter_path in iteration_dirs:
    for member_idx in range(n_members):
        member_str = f"member_{member_idx + 1:03d}"
        param_path = os.path.join(iter_path, member_str, "parameters.toml")
        if not os.path.exists(param_path):
            for param in param_names:
                param_values[param][member_idx].append(np.nan)
            continue
        data = toml.load(param_path)
        for param in param_names:
            value = data[param]["value"]
            param_values[param][member_idx].append(value)


fig, axes = plt.subplots(nrows=2, ncols=3, figsize=(16, 10))
axes = axes.flatten()

for i, param in enumerate(param_names):
    ax = axes[i]
    for member_idx in range(n_members):
        values = param_values[param][member_idx]
        ax.plot(range(num_iterations), values, color=member_colors[member_idx], alpha=0.7)
    ax.set_title(param)
    ax.set_xlabel("Iteration")
    ax.set_ylabel("Parameter Value")
    ax.grid(True, linestyle=':', alpha=0.5)

# Remove empty subplot if extra
if len(param_names) < len(axes):
    fig.delaxes(axes[-1])

plt.tight_layout()
output_plot_path = os.path.join(base_dir, "parameter_evolution.png")
fig.savefig(output_plot_path, dpi=300, bbox_inches='tight')
print(f"Plot saved to {output_plot_path} as parameter_evolution.png")

