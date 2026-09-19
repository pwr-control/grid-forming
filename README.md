# Grid-Forming

Investigation on grid-forming control architectures, starting from the behaviour of a
grid-tied active front end on progressively weaker grids.

The model depends on the companion [library](https://github.com/pwr-control/library) repository
(custom Simscape components, C-Caller control code and the setup functions called by
`init_model.m`), which must be on the MATLAB path with subfolders.

## Contents

### `grid_afe_n/`
Three-phase AFE modules connected to an emulated grid through a Dyn11 transformer, with
fault-ride-through tests and reactive-current reference steps.

- `grid_afe_n.slx` — the Simulink/Simscape model; `init_model.m` sets every parameter and opens
  it. Grid emulator 1.25 MVA at 690 V / 50 Hz (400 V and 480 V branches available), AFE 250 kW,
  fPWM = 4 kHz with double update, 3 µs deadtime, 3 s simulation.
- Up to four modules in parallel are parameterized (per-module current references, common-mode
  compensation for hard paralleling, individual clocks and PWM phase shifts); the committed
  configuration runs one.
- Control: DC-link voltage PI over resonant PI current control with gains tuned for weak grids,
  FHT-based dq-PLL, SOGI, positive and negative sequence handling. The FRT layer is active
  (test 25.4, dip at 0.75 s, asymmetric fault type 1) followed by two reactive-current steps at
  cos φ = 0.95.
- `run_sim.m` — runs the model for five grid strengths, `ucc_factor` = 1, 10/3, 5, 20/3, 10,
  i.e. short-circuit ratio Icc/Inom = 20, 6, 4, 3, 2, saving `sim_results_icc<N>inom_3.mat`
  (the `.mat` files are ignored by git).
- `plot_grid_quantities.m` — grid currents and voltages around the fault, and the
  positive/negative sequence active and reactive powers.
- `plot_voltage_dip_reference.m` — line voltages versus grid voltages during the dip, full window
  and a 40 ms zoom; the two EPS in `figures/` are its output.
- `video_plots/` — animated versions of the same plots (grid and line quantities, sequence
  powers after the reactive-current steps, the voltage dip), exported as MP4.

### `dead_zone_oscillator.m`
Standalone script: a mass with damping and a piecewise-linear restoring force that is zero inside
a dead zone, integrated with `ode45`; plots the response and the phase portrait.

## Status

The parameter file configures a grid-following AFE (PLL, resonant PI current control); the
grid-forming control law under investigation lives inside the model and is not exposed as
parameters yet.
