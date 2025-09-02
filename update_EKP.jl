include("shared.jl") # packages

function main()

    output_dir = ARGS[1]
    eki_path = joinpath(output_dir, ARGS[2])

    # Parameters
    iteration = parse(Int64, ARGS[3])

    @info "Updating EKP parameters in $(iteration) to $(output_dir)"

    # load current state
    @load eki_path eki param_dict prior
    N_ensemble = eki.N_ens
    dim_output = 4 # size(eki.observation_series.observations)[1] # size(eki.obs_mean)[1]

    # Wait for all ensemble members to complete
    @info "Waiting for all ensemble members to complete iteration $iteration..."
    max_wait_time = 3600  # 1 hour timeout
    start_time = time()

    while time() - start_time < max_wait_time
        all_complete = true
        for member in 1:N_ensemble
            member_path = path_to_ensemble_member(output_dir, iteration, member)
            output_file = joinpath(member_path, "output.jld2")
            if !isfile(output_file)
                all_complete = false
                break
            end
        end

        if all_complete
            @info "All ensemble members completed!"
            break
        else
            @info "Still waiting for ensemble members... ($(round(time() - start_time, digits=1))s elapsed)"
            sleep(30)  # Wait 30 seconds before checking again
        end
    end

    if time() - start_time >= max_wait_time
        error("Timeout: Not all ensemble members completed within $max_wait_time seconds")
    end

    # load data from the ensemble
    G_ens = zeros(dim_output, N_ensemble)
    for member in 1:N_ensemble
        member_path = path_to_ensemble_member(output_dir, iteration, member)
        @load joinpath(member_path, "output.jld2") model_output
        G_ens[:, member] = model_output
    end

    # perform the update
    EKP.update_ensemble!(eki, G_ens)

    # save the parameter ensemble and EKP
    save_parameter_ensemble(
        get_u_final(eki), # constraints applied when saving
        prior,
        param_dict,
        output_dir,
        "parameters",
        iteration + 1, #save for next iteration
    )

    #save new state
    @save eki_path eki param_dict prior

end

main()

