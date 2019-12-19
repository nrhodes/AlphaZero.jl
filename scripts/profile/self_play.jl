ENV["CUARRAYS_MEMORY_POOL"] = "split" # "binned" / "split"

using Revise
using AlphaZero
using AlphaZero.Log
using Formatting

#####
##### Profiling utilities
#####

function profile_self_play(network, params, n)
  player = AlphaZero.MctsPlayer(network, params)
  time = @elapsed for i in 1:n
    AlphaZero.play(player, player)
  end
  itr = MCTS.inference_time_ratio(player.mcts)
  aed = MCTS.average_exploration_depth(player.mcts)
  return (time / n, itr, aed)
end

function profile_self_play(configs::Vector)
  log  = Logger()
  time = Log.ColType(10, x -> format("{:.1f} min", x * 100 / 60))
  itr  = Log.ColType(5,  x -> format("{}%", round(Int, x * 100)))
  expd = Log.ColType(5,  x -> format("{:.1f}", x))
  tab  = Log.Table([
    ("T100", time, s -> s[1]),
    ("ITR",  itr,  s -> s[2]),
    ("EXPD", expd, s -> s[3])])
  for (title, net, params) in configs
    profile_self_play(net, params, 1) # Compilation
    rep = profile_self_play(net, params, 50)
    Log.table_row(log, tab, rep, [title])
  end
end

#####
##### Main
#####

include("../game_module.jl")
@game_module SelectedGame
using .SelectedGame: Game, Training

function config(nblocks, nfilters, niters, nworkers)
  title = "$nblocks blocks, $nfilters filters, $niters iters, $nworkers workers"
  network = ResNet{Game}(ResNetHP(Training.netparams,
    num_blocks=nblocks, num_filters=nfilters))
  params = MctsParams(Training.params.self_play.mcts,
    num_iters_per_turn=niters,
    num_workers=nworkers)
  return (title, network, params)
end

# We want 5000 games per iteration?
# Iteration: self-play=1h
# Therefore, we want to simulate 100 games per minute

profile_self_play([
  config(7, 128, 400, 64),
  config(7, 128, 800, 64),
  config(7, 128, 800, 128),
])
