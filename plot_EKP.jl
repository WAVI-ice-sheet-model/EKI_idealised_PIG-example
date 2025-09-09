include("shared.jl") # packages

function main()
    eki_path = ARGS[1]

    @info "Creating EKP ensemble plots..."
    
    # load current state 
    @load eki_path eki param_dict prior
    N_ensemble = eki.N_ens
    
    # Get the parameter evolution using EKP interface functions
    try
        # Try to get the current ensemble
        current_ensemble = get_u_final(eki)
        @info "Current ensemble size: $(size(current_ensemble))"
        
        # Get iteration count
        N_iterations = get_N_iterations(eki)
        @info "Number of iterations: $N_iterations"
        
        # Parameter names for labeling
        param_names = ["weertman_c_prefactor", "glen_a_ref_prefactor", "bump_amplitude", "melt_rate_prefactor", "per_century_trend"]
        
        # Create a simple plot showing final ensemble spread
        plots_array = []
        
        for (i, param_name) in enumerate(param_names)
            param_values = current_ensemble[i, :]
            
            p = plot(title="$param_name Final Distribution", 
                    xlabel="Ensemble Member", 
                    ylabel="Parameter Value",
                    legend=false)
            
            scatter!(p, 1:N_ensemble, param_values, 
                    color=:blue, alpha=0.7, markersize=6)
            
            # Add mean line
            mean_val = mean(param_values)
            hline!(p, [mean_val], color=:red, linewidth=2, linestyle=:dash)
            
            push!(plots_array, p)
        end
        
        # Combine all parameter plots
        final_plot = plot(plots_array..., layout=(3,2), size=(1200, 800))
        
        # Save the plot
        output_path = joinpath(dirname(eki_path), "ekp_final_ensemble.png")
        savefig(final_plot, output_path)
        @info "Final ensemble plot saved to: $output_path"
        
    catch e
        @error "Error creating plots: $e"
        @info "EKI object fields: $(fieldnames(typeof(eki)))"
    end
    
    @info "EKP plotting completed!"
end

main()
