function param = init_pgfm_droop(case_name)
%INIT_PGFM_DROOP  Parameters of pgfm_droop.slx: three grid-forming modules in the droop mode (control V1).
%
%   param = init_pgfm_droop            case T2 (loss of the grid)
%   param = init_pgfm_droop(case_name) cases of the design note (Section "Tests"), see below
%
%   pgfm_droop.slx is the light companion model of parallel_of_GFMs for the power sharing (route A of the design
%   note repos_doc/parallel_of_gfms of pwr-control/repositories-documentation): three library blocks
%   grid_forming_dqctrl (two-level bridge, LCL filter, control in one MATLAB Function) with p.ctrl.droop = 1, each
%   on its own ideal DC source, on one 690 V bus with a local load (R in parallel with L + R per phase, star
%   earthed) and a grid (source behind R + L, 10 % on 1 MVA) through a breaker; a switch in each module output
%   (trip) with an optional cable, a switched load step. Built by build_pgfm_droop.m, tests in
%   pgfm_droop_tests.m. The model reads the struct param from the workspace (base, or setVariable).
%
%   Module: 690 V, 250 kW (Sb = 250 kW/0.9 = 277.8 kVA), L1 500 uH, Cf 200 uF, L2 80 uH, udc 1070 V (the AFE of
%   parallel_of_GFMs with a small grid-side choke), 4 kHz PWM with double update; the control parameters are those
%   of grid_forming_param_example.m (library) with droop = 1, P* = 0.4 pu.
%
%   Cases (param.tb.name):
%     T1        on the grid, P* of module 1 from 0.4 to 0.8 pu at 0.6 s (sync(2) of module 1)
%     T2        600 kW + 200 kvar on the bus, modules at P* = 0.4 pu, the breaker opens at 1.0 s
%     T3        as T2, then +150 kW at 1.5 s in the island (contains T2)
%     T5        450 kW + 150 kvar, the breaker opens at 1.0 s, trip of module 3 at 1.5 s
%     black     no grid: black start of the three modules on 600 kW + 200 kvar
%     T0_off    island (black start), clock gains 1.0002, 1.0015, 0.9988 (those of pgfm_ctrl_analysis),
%               alignment of the local clocks off (kp_align = ki_align = 0)
%     T0_on     same, alignment on (gains of the library example)
%     T4_L1     island, module 3 with L1 +20 %
%     T4_cable  island, module 3 behind a cable of 0.01 pu (55 uH + 0.5 mOhm)
%     T4_gain   island, module 3 with ug_ref = 1/1.01 (same effect as +1 % gain error of its voltage measurements)
%
%   See also build_pgfm_droop, pgfm_droop_tests, grid_forming_param_example.

    if nargin < 1
        case_name = 'T2';
    end

    % ---- simulation
    param.sim.tc     = 1e-6;                    % [s] fixed step = step of the Simscape local solver = p.pwm.tc
    param.sim.ts_log = 125e-6;                  % [s] sample time of the logs (control period)
    param.sim.nonlinear_iterations = 3;         % Simscape local solver (as parallel_of_GFMs)

    % ---- modules
    for k = 1:3
        p = grid_forming_param_example(param.sim.tc);
        p.hw.L1p = 500e-6; p.hw.L10 = 500e-6; p.hw.R1 = 157*0.05*500e-6;
        p.hw.Cf  = 200e-6; p.hw.Rcf = 50e-3;
        p.hw.L2p = 80e-6;  p.hw.L20 = 80e-6;  p.hw.R2 = 157*0.05*80e-6;
        p.hw.ubez    = 690*sqrt(2/3);           % [V] peak phase voltage
        p.hw.ibez    = 250e3/sqrt(3)/690/0.9*sqrt(2);   % [A] peak phase current of Sb = 250 kW/0.9
        p.hw.udc_nom = 1070;                    % [V]
        p.ctrl.droop        = 1;
        p.ctrl.droop_p_ref  = 0.4;              % [pu] 111 kW
        p.ctrl.droop_t_sync = 0.1;              % [s] the grid transient at t = 0 (DC offsets) is over
        p.ctrl.droop_t_ramp = 0.1;              % [s]
        mods(k) = p; %#ok<AGROW>
    end
    param.mod = mods;
    param.sb  = 250e3/0.9;                      % [VA] base power of a module

    % ---- grid, load (690 V, star values per phase)
    u_ll = 690;
    param.grid.u_peak = u_ll*sqrt(2/3);         % [V] peak phase voltage of the source
    param.grid.f      = 50;                     % [Hz]
    x_g = 0.1*u_ll^2/1e6;                       % [Ohm] 10 % on 1 MVA
    param.grid.L = x_g/(2*pi*50);               % [H]
    param.grid.R = x_g/10;                      % [Ohm]
    param.load.p = 600e3; param.load.q = 200e3; % [W] [var] at 690 V
    param.load.p_step = 150e3;                  % [W] load step
    param.cable.L = 1e-7*ones(1, 3);            % [H] cable of each module (negligible by default)
    param.cable.R = 1e-5*ones(1, 3);            % [Ohm]

    % ---- test bench
    tb.name   = case_name;
    tb.t_end  = 2.0;                            % [s]
    tb.t_open = 1.0;                            % [s] opening of the grid breaker (inf: never; 0: open from the start)
    tb.t_step = inf;                            % [s] load step
    tb.t_trip = [inf inf inf];                  % [s] trip of each module (output switch opens)
    tb.sync_t = [inf inf inf];                  % [s] time of the step of the sync input of each module
    tb.sync_after = zeros(5, 3);                % sync after that time: [-; dP*; dQ*; dU*; dw*]
    switch case_name
        case 'T1'
            tb.t_end = 1.4; tb.t_open = inf; tb.sync_t(1) = 0.6; tb.sync_after(2, 1) = 0.4;
        case 'T2'
        case 'T3'
            tb.t_end = 2.5; tb.t_step = 1.5;
        case 'T5'
            tb.t_end = 2.5; param.load.p = 450e3; param.load.q = 150e3; tb.t_trip(3) = 1.5;
        case 'black'
            tb.t_end = 1.2; tb.t_open = 0;
        case {'T0_off', 'T0_on'}
            tb.t_end = 1.2; tb.t_open = 0;
            kt = [1.0002 1.0015 0.9988];
            for k = 1:3
                param.mod(k).ctrl.k_time = kt(k);
                if strcmp(case_name, 'T0_off')
                    param.mod(k).ctrl.kp_align = 0;
                    param.mod(k).ctrl.ki_align = 0;
                end
            end
        case 'T4_L1'
            tb.t_end = 1.2; tb.t_open = 0;
            param.mod(3).hw.L1p = 1.2*500e-6; param.mod(3).hw.L10 = 1.2*500e-6;
        case 'T4_cable'
            tb.t_end = 1.2; tb.t_open = 0;
            zb = param.mod(3).hw.ubez/param.mod(3).hw.ibez;
            param.cable.L(3) = 0.01*zb/(2*pi*50); param.cable.R(3) = 0.01*zb/10*0.03;
        case 'T4_gain'
            tb.t_end = 1.2; tb.t_open = 0;
            param.mod(3).ctrl.ug_ref = 1/1.01;
        otherwise
            error('init_pgfm_droop: unknown case %s', case_name);
    end
    param.tb = tb;
    param.load.R      = u_ll^2/param.load.p;    % [Ohm] per phase (star)
    param.load.L      = u_ll^2/param.load.q/(2*pi*50);  % [H]
    param.load.RL     = u_ll^2/param.load.q/10; % [Ohm] series resistance of the load inductor (X/R = 10)
    param.load.R_step = u_ll^2/param.load.p_step;
end
