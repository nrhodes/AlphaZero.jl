#####
##### Loss Plot
#####

function plot_losses(getlosses, range, title)
  fields = fieldnames(Report.Loss)
  labels = [string(f) for _ in 1:1, f in fields]
  data = [[getfield(getlosses(i), f) for i in range] for f in fields]
  return Plots.plot(range, data,
    label=labels, title=title, ylims=(0, Inf))
end

#####
##### Iteration summary plots
#####

function learning_iter_plot(rep::Report.Learning, params::Params)
  losses_plot = plot_losses(0:length(rep.epochs), "Losses") do i
    if i == 0
      rep.initial_status.loss
    else
      rep.epochs[i].status_after.loss
    end
  end
  checkpoints_plot = Plots.hline(
    [0, params.arena.update_threshold],
    title="Checkpoints")
  Plots.plot!(checkpoints_plot,
    [c.epoch_id for c in rep.checkpoints],
    [c.reward for c in rep.checkpoints],
    t=:scatter,
    legend=:none)
  return Plots.plot(losses_plot, checkpoints_plot, layout=(2, 1))
end

function performances_plot(rep::Report.Iteration)
  # Global
  global_labels = []
  global_content = []
  push!(global_labels, "Self Play")
  push!(global_content, rep.perfs_self_play.time)
  if !isnothing(rep.memory)
    push!(global_labels, "Memory Analysis")
    push!(global_content, rep.perfs_memory_analysis.time)
  end
  push!(global_labels, "Learning")
  push!(global_content, rep.perfs_learning.time)
  glob = Plots.pie(global_labels, global_content, title="Global")
  # Self-play details
  self_play =
    let gcratio =
      rep.perfs_self_play.gc_time / rep.perfs_self_play.time
    let itratio = rep.self_play.inference_time_ratio
      Plots.pie(
        ["Inference", "MCTS", "GC"],
        [(1 - gcratio) * itratio, (1 - gcratio) * (1 - itratio), gcratio],
        title="Self Play") end end
  # Learning details
  learning = Plots.pie(
    ["Samples Conversion", "Loss computation", "Optimization", "Evaluation"],
    [ rep.learning.time_convert,
      rep.learning.time_loss,
      rep.learning.time_train,
      rep.learning.time_eval],
    title="Learning")
  return Plots.plot(glob, self_play, learning)
end

function plot_iteration(
    report::Report.Iteration,
    params::Params,
    dir::String)
  isdir(dir) || mkpath(dir)
  # Learning plot
  lplot = learning_iter_plot(report.learning, params)
  Plots.savefig(lplot, joinpath(dir, "summary"))
  # Performances plot
  pplot = performances_plot(report)
  Plots.savefig(pplot, joinpath(dir, "performances"))
end
# To test:
# params, ireps, vreps = AlphaZero.get_reports("sessions/connect-four")
# AlphaZero.plot_iteration(ireps[end], params, "TEST")

#####
##### Training summary plots
#####

function plot_benchmark(
    params::Params,
    benchs::Vector{Benchmark.Report},
    dir::String)
  isempty(benchs) && return
  n = length(benchs) - 1
  nduels = length(benchs[1])
  nduels >= 1 || return
  @assert all(length(b) == nduels for b in benchs)
  isdir(dir) || mkpath(dir)
  labels = ["$(d.player) / $(d.baseline)" for _ in 1:1, d in benchs[1]]
  # Average reward
  avgz_data = [[b[i].avgz for b in benchs] for i in 1:nduels]
  avgz = Plots.plot(0:n,
    avgz_data,
    title="Average Reward",
    ylims=(-1.0, 1.0),
    legend=:bottomright,
    label=labels,
    xlabel="iteration")
  Plots.savefig(avgz, joinpath(dir, "benchmark_reward"))
  # Percentage of lost games
  if params.ternary_rewards
    function compute_ploss(b)
      stats = Benchmark.TernaryOutcomeStatistics(b)
      return ceil(Int, 100 * (stats.num_lost / length(b.rewards)))
    end
    ploss_data = [[compute_ploss(b[i]) for b in benchs] for i in 1:nduels]
    ploss = Plots.plot(0:n,
      ploss_data,
      title="Percentage of Lost Games",
      ylims=(0, 100),
      legend=:topright,
      label=labels,
      xlabel="iteration")
    Plots.savefig(ploss, joinpath(dir, "benchmark_lost_games"))
  end
end

function plot_training(
    params::Params,
    iterations::Vector{Report.Iteration},
    dir::String)
  n = length(iterations)
  iszero(n) && return
  isdir(dir) || mkpath(dir)
  plots, files = [], []
  # Exploration depth
  expdepth = Plots.plot(1:n,
    [it.self_play.average_exploration_depth for it in iterations],
    title="Average Exploration Depth",
    ylims=(0, Inf),
    legend=:none,
    xlabel="iteration")
  # Number of samples
  nsamples = Plots.plot(0:n,
    [0;[it.self_play.memory_size for it in iterations]],
    title="Experience Buffer Size",
    label="Number of samples",
    xlabel="iteration")
  Plots.plot!(nsamples, 0:n,
    [0;[it.self_play.memory_num_distinct_boards for it in iterations]],
    label="Number of distinct boards")
  # Performances during evaluation
  arena = Plots.plot(1:n, [
    maximum(c.reward for c in it.learning.checkpoints)
    for it in iterations],
    title="Arena Results",
    ylims=(-1, 1),
    t=:bar,
    legend=:none,
    xlabel="iteration")
  Plots.hline!(arena, [0, params.arena.update_threshold])
  # Plots related to the memory analysis
  if all(it -> !isnothing(it.memory), iterations)
    # Loss on last batch
    losses_last = plot_losses(1:n, "Loss on last batch") do i
      iterations[i].memory.latest_batch.status.loss
    end
    losses_fullmem = plot_losses(1:n, "Loss on full memory") do i
      iterations[i].memory.all_samples.status.loss
    end
    # Loss per game stage
    nstages = minimum(length(it.memory.per_game_stage) for it in iterations)
    colors = range(colorant"blue", stop=colorant"red", length=nstages)
    losses_ps = Plots.plot(
      title="Loss per Game Stage", ylims=(0, Inf), xlabel="iteration")
    for s in 1:nstages
      Plots.plot!(losses_ps, 1:n, [
          it.memory.per_game_stage[s].samples_stats.status.loss.L
          for it in iterations],
        label="$s",
        color=colors[s])
    end
    append!(plots, [losses_last, losses_fullmem, losses_ps])
    append!(files, ["loss_last_batch", "loss_fullmem", "loss_per_stage"])
  end
  # Policies entropy
  entropies = Plots.plot(1:n,
    [it.learning.initial_status.Hp for it in iterations],
    ylims=(0, Inf),
    title="Policy Entropy",
    label="MCTS")
  Plots.plot!(entropies, 1:n,
    [it.learning.initial_status.Hpnet for it in iterations],
    label="Network")
  # Assembling everything together
  append!(plots, [arena, entropies, nsamples, expdepth])
  append!(files, ["arena", "entropies", "nsamples", "exploration_depth"])
  for (file, plot) in zip(files, plots)
    Plots.savefig(plot, joinpath(dir, file))
  end
end
# To test:
# AlphaZero.plot_training("sessions/connect-four")