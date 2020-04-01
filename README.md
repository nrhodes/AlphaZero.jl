# AlphaZero.jl

[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://jonathan-laurent.github.io/AlphaZero.jl/dev)
[![Build Status](https://travis-ci.com/jonathan-laurent/AlphaZero.jl.svg?branch=master)](https://travis-ci.com/jonathan-laurent/AlphaZero.jl)
[![Codecov](https://codecov.io/gh/jonathan-laurent/AlphaZero.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/jonathan-laurent/AlphaZero.jl)
[![Gitter](https://badges.gitter.im/alphazero-jl/community.svg)](https://gitter.im/alphazero-jl/community?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge)

This package provides a _generic_, _simple_ and _fast_ implementation of
Deepmind's AlphaZero algorithm:

* The core algorithm is only 2,000 lines of pure, hackable Julia code.
* Generic interfaces make it easy to add support for new games or new learning
  frameworks.
* Being between one and two orders of magnitude faster than competing
  alternatives written in Python, this implementation enables to solve
  nontrivial games on a standard desktop computer with a GPU.

### Why should I care about AlphaZero?

Beyond its much publicized success in attaining superhuman level at games
such as Chess and Go, DeepMind's AlphaZero algorithm illustrates a more
general methodology of combining learning and search to explore large
combinatorial spaces effectively. We believe that this methodology can
have exciting applications in many different research areas.

### Why should I care about this implementation?

Because AlphaZero is resource-hungry, successful open-source
implementations (such as [Leela Zero](https://github.com/leela-zero/leela-zero))
are written in low-level languages (such as C++) and optimized for highly
distributed computing environments.
This makes them hardly accessible for students, researchers and hackers.

The motivation for this project is to provide an implementation of
AlphaZero that is simple enough to be widely accessible, while also being
sufficiently powerful and fast to enable meaningful experiments on limited
computing resources.
We found the [Julia language](https://julialang.org/) to be instrumental in achieving this goal.

### Training a Connect Four Agent

To download AlphaZero.jl and start training a Connect Four agent, just run:

```
git clone https://github.com/jonathan-laurent/AlphaZero.jl.git
cd AlphaZero.jl
julia --project -e "import Pkg; Pkg.instantiate()"
julia --project --color=yes scripts/alphazero.jl --game connect-four train
```

<div>
<img src="./docs/src/assets/img/ui-first-iter-cut.png" width="48%" />
<img src="./docs/src/assets/img/explorer.png" width="48%" />
</div>
<!--
<img 
  src="./docs/src/assets/img/ui-first-iter.png"
  width="100%"/>
  -->

<br/>

Each training iteration takes between 60 and 90 minutes on a desktop
computer with an Intel Core i5 9600K processor and an 8GB Nvidia RTX
2070 GPU. We plot below the evolution of the win rate of our AlphaZero agent against two baselines (a vanilla MCTS baseline and a minmax agent that plans at depth 5 using a handcrafted heuristic):

<br/>
<div align="center">
<img 
  src="./docs/src/assets/img/connect-four/plots/benchmark_won_games.png"
  width="60%"/>
</div>
<br/>

Note that the AlphaZero agent is not exposed to the baselines during training and
learns purely from self-play, without any form of supervision or prior knowledge.

We also evaluate the performances of the neural network alone against the same
baselines. Instead of plugging it into MCTS, we play the action that is
assigned the highest prior probability at each state:

<br/>
<div align="center">
<img 
  src="./docs/src/assets/img/connect-four/net-only/benchmark_won_games.png"
  width="60%"/>
</div>
<br/>

Unsurprisingly, the network alone is initially unable to win a single game.
However, it ends up being competitive with the minmax agent despite not being
able to perform any search.

For more information on training a Connect Four agent using AlphaZero.jl, see our full [tutorial](https://jonathan-laurent.github.io/AlphaZero.jl/dev/tutorial/connect_four/).

### Resources

- [Documentation Home](https://jonathan-laurent.github.io/AlphaZero.jl/dev/)
- [An Introduction to AlphaZero](https://jonathan-laurent.github.io/AlphaZero.jl/dev/tutorial/alphazero_intro/)
- [Package Overview](https://jonathan-laurent.github.io/AlphaZero.jl/dev/tutorial/package_overview/)
- [Connect-Four Tutorial](https://jonathan-laurent.github.io/AlphaZero.jl/dev/tutorial/connect_four/)
- [Hyperparameters Documentation](https://jonathan-laurent.github.io/AlphaZero.jl/dev/reference/params/)

### Contributing

Contributions to AlphaZero.jl are most welcome. Many contribution ideas are available in our [contribution guide](https://jonathan-laurent.github.io/AlphaZero.jl/dev/contributing/guide/).
Please do not hesitate to open a Github
[issue](https://github.com/jonathan-laurent/AlphaZero.jl/issues) to share
any idea, feedback or suggestion.



### Acknowledgements

This material is based upon work supported by the United States Air Force and
DARPA under Contract No. FA8750-18-C-0092. Any opinions, findings and
conclusions or recommendations expressed in this material are those of the
author(s) and do not necessarily reflect the views of the United States
Air Force and DARPA.