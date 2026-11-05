function mdl = build_pgfm_droop(do_save)
%BUILD_PGFM_DROOP  Build pgfm_droop.slx, the light companion model of parallel_of_GFMs for the power sharing.
%
%   build_pgfm_droop          build the model and save it next to this file (overwrites pgfm_droop.slx)
%   build_pgfm_droop(false)   build it and leave it open without saving
%
%   The model (route A of the design note repos_doc/parallel_of_gfms of pwr-control/repositories-documentation):
%     t_master     Digital Clock at param.sim.tc, the master time of the three modules
%     module_1..3  library block grid_forming_dqctrl_mod1 (p = param.mod(k), droop mode), its ideal DC source
%                  (floating, param.mod(k).hw.udc_nom), the sync input as a step of the setpoint offsets
%                  (param.tb.sync_t(k), param.tb.sync_after(:, k)), the trip switch of the output
%                  (param.tb.t_trip(k)) and a cable (param.cable.L(k), param.cable.R(k)); logs log_k (ctrl_log,
%                  55x1) and m_k (measurements, 17x1) at param.sim.ts_log, timeseries
%     network      bus of the three modules: local load per phase R // (L + R) to the earthed star
%                  (param.load.R, L, RL), load step R_step through a switch closing at param.tb.t_step, grid
%                  (source param.grid.u_peak at param.grid.f behind param.grid.R + param.grid.L, earthed star)
%                  through a breaker opening at param.tb.t_open (0: open from the start, inf: never)
%   Simscape Foundation blocks only (no Specialized Power Systems), one Solver Configuration with the local
%   backward-Euler solver at param.sim.tc; fixed step param.sim.tc, stop time param.tb.t_end. The struct param
%   comes from init_pgfm_droop (base workspace or Simulink.SimulationInput/setVariable).
%
%   Requirements on the MATLAB path: the library repository (pwr-control/library) with grid_forming_dqctrl.slx in
%   the droop mode (November 2026) and afe_ssc_lib; Simscape.
%
%   See also init_pgfm_droop, pgfm_droop_tests.

    if nargin < 1
        do_save = true;
    end
    mdl  = 'pgfm_droop';
    here = fileparts(mfilename('fullpath'));
    lib  = 'grid_forming_dqctrl';
    blk  = [lib '/grid_forming_dqctrl_mod1'];

    load_system(lib);
    cfg = get_param([blk '/afe_dq_forming_ctrl_pwm'], 'MATLABFunctionConfiguration');
    assert(contains(cfg.FunctionScript, 'droop_mp'), ...
        'build_pgfm_droop: %s has no droop mode (library older than November 2026): update the library', ...
        which(lib));
    load_system('fl_lib');
    load_system('nesl_utility');

    if bdIsLoaded(mdl)
        close_system(mdl, 0);
    end
    new_system(mdl);
    set_param(mdl, 'SolverType', 'Fixed-step', 'Solver', 'ode1', 'FixedStep', 'param.sim.tc', ...
        'StartTime', '0', 'StopTime', 'param.tb.t_end', 'EnableMultiTasking', 'off', ...
        'SaveTime', 'off', 'SaveOutput', 'off', 'SaveState', 'off', 'SaveFinalState', 'off', ...
        'SignalLogging', 'off', 'ReturnWorkspaceOutputs', 'on');
    try
        set_param(mdl, 'SimscapeLogType', 'none');
    catch
    end
    set_param(mdl, 'Description', ['Light companion model of parallel_of_GFMs: three grid-forming modules ' ...
        '(library block grid_forming_dqctrl, droop mode) on one bus with a local load and a grid breaker. ' ...
        'Built by build_pgfm_droop.m, parameters init_pgfm_droop.m, tests pgfm_droop_tests.m.']);

    add_block('simulink/Sources/Digital Clock', [mdl '/t_master'], 'SampleTime', 'param.sim.tc', ...
        'Position', [40 352 100 378]);

    % ---- modules
    for k = 1:3
        y0  = 60 + 200*(k - 1);
        sys = sprintf('%s/module_%d', mdl, k);
        add_block('built-in/Subsystem', sys, 'Position', [500 y0 640 y0 + 120]);
        local_module(sys, k, blk);
        add_line(mdl, 't_master/1', sprintf('module_%d/1', k), 'autorouting', 'on');
    end

    % ---- network
    net = [mdl '/network'];
    add_block('built-in/Subsystem', net, 'Position', [200 120 320 500]);
    local_network(net);
    for k = 1:3
        pn = get_param(net, 'PortHandles');
        pm = get_param(sprintf('%s/module_%d', mdl, k), 'PortHandles');
        for ph = 1:3
            add_line(mdl, pn.RConn(ph), pm.LConn(ph), 'autorouting', 'on');
        end
    end

    local_note(mdl, [40 20], sprintf(['pgfm_droop: three grid-forming modules in the droop mode (control V1), ' ...
        'local load, grid breaker.\nparam = init_pgfm_droop(''T3''); then run, or pgfm_droop_tests. ' ...
        'Model built by build_pgfm_droop.m: change the script, not the model.']));

    if do_save
        save_system(mdl, fullfile(here, [mdl '.slx']));
    end
end

% --------------------------------------------------------------------------------------------------------------
function local_module(sys, k, blk)
%LOCAL_MODULE  One module: library block, DC source, sync step, trip switches, cable, logs.
    add_block('built-in/Inport', [sys '/t_master'], 'Port', '1', 'Position', [300 43 330 57]);
    ph_names = {'a', 'b', 'c'};
    for i = 1:3
        add_block('built-in/PMIOPort', [sys '/' ph_names{i}], 'Side', 'Left', ...
            'Position', [20 158 + 50*(i - 1) 50 172 + 50*(i - 1)]);
    end

    g = [sys '/gfm'];
    add_block(blk, g, 'Position', [420 30 600 290]);
    set_param(g, 'p', sprintf('param.mod(%d)', k));

    add_block('simulink/Sources/Step', [sys '/sync'], 'Time', sprintf('param.tb.sync_t(%d)', k), ...
        'Before', 'zeros(5, 1)', 'After', sprintf('param.tb.sync_after(:, %d)', k), ...
        'SampleTime', 'param.sim.tc', 'VectorParams1D', 'off', 'Position', [300 85 340 115]);
    add_block('fl_lib/Electrical/Electrical Sources/DC Voltage Source', [sys '/Vdc'], ...
        'v0', sprintf('param.mod(%d).hw.udc_nom', k), 'Position', [700 190 740 230]);
    add_block('simulink/Sinks/To Workspace', [sys '/log'], 'VariableName', sprintf('log_%d', k), ...
        'SaveFormat', 'Timeseries', 'SampleTime', 'param.sim.ts_log', 'MaxDataPoints', 'inf', ...
        'Position', [700 90 770 110]);
    add_block('simulink/Sinks/To Workspace', [sys '/meas'], 'VariableName', sprintf('m_%d', k), ...
        'SaveFormat', 'Timeseries', 'SampleTime', 'param.sim.ts_log', 'MaxDataPoints', 'inf', ...
        'Position', [700 40 770 60]);
    add_block('simulink/Sinks/Terminator', [sys '/sync_out'], 'Position', [700 140 720 160]);

    add_block('simulink/Sources/Step', [sys '/trip_cmd'], 'Time', sprintf('param.tb.t_trip(%d)', k), ...
        'Before', '1', 'After', '0', 'SampleTime', 'param.sim.tc', 'Position', [100 330 140 360]);
    add_block('nesl_utility/Simulink-PS Converter', [sys '/trip_sps'], 'Position', [180 335 210 355]);
    local_sps_zero(sys, 'trip_sps');
    for i = 1:3
        y = 150 + 50*(i - 1);
        add_block('fl_lib/Electrical/Electrical Elements/Inductor', [sys '/cable_' ph_names{i}], ...
            'l', sprintf('param.cable.L(%d)', k), 'r', sprintf('param.cable.R(%d)', k), ...
            'Position', [100 y 140 y + 30]);
        add_block('fl_lib/Electrical/Electrical Elements/Switch', [sys '/trip_' ph_names{i}], ...
            'R_closed', '1e-4', 'G_open', '1e-6', 'Threshold', '0.5', 'Position', [240 y 280 y + 30]);
    end

    % signals
    add_line(sys, 't_master/1', 'gfm/1', 'autorouting', 'on');
    add_line(sys, 'sync/1', 'gfm/2', 'autorouting', 'on');
    add_line(sys, 'gfm/1', 'meas/1', 'autorouting', 'on');
    add_line(sys, 'gfm/2', 'log/1', 'autorouting', 'on');
    add_line(sys, 'gfm/3', 'sync_out/1', 'autorouting', 'on');
    add_line(sys, 'trip_cmd/1', 'trip_sps/1', 'autorouting', 'on');

    % physical: port -> cable -> trip switch -> ug of the block; DC source on Udc(+), Udc(-)
    pg = get_param(g, 'PortHandles');
    for i = 1:3
        sw = local_switch(sys, ['trip_' ph_names{i}], 'trip_sps');
        local_connect(sys, local_pmio(sys, ph_names{i}), local_pc(sys, ['cable_' ph_names{i}], 'L', 1));
        local_connect(sys, local_pc(sys, ['cable_' ph_names{i}], 'R', 1), sw(1));
        local_connect(sys, sw(2), pg.LConn(i));
    end
    local_connect(sys, pg.RConn(1), local_pc(sys, 'Vdc', 'L', 1));
    local_connect(sys, pg.RConn(2), local_pc(sys, 'Vdc', 'R', 1));
end

% --------------------------------------------------------------------------------------------------------------
function local_network(net)
%LOCAL_NETWORK  Bus a, b, c: local load, load step, grid breaker, grid; earth, solver configuration.
    ph_names = {'a', 'b', 'c'};
    shift = {'0', '-120', '120'};
    for i = 1:3
        add_block('built-in/PMIOPort', [net '/' ph_names{i}], 'Side', 'Right', ...
            'Position', [940 78 + 200*(i - 1) 970 92 + 200*(i - 1)]);
    end
    add_block('fl_lib/Electrical/Electrical Elements/Electrical Reference', [net '/earth'], ...
        'Position', [480 700 520 740]);
    add_block('nesl_utility/Solver Configuration', [net '/solver'], 'Position', [380 650 440 690]);
    set_param([net '/solver'], 'UseLocalSolver', 'on', 'LocalSolverChoice', 'NE_BACKWARD_EULER_ADVANCER', ...
        'LocalSolverSampleTime', 'param.sim.tc', 'DoFixedCost', 'on', ...
        'MaxNonlinIter', 'param.sim.nonlinear_iterations', 'MaxModeIter', '2', 'DoDC', 'on');

    add_block('simulink/Sources/Step', [net '/step_cmd'], 'Time', 'param.tb.t_step', 'Before', '0', ...
        'After', '1', 'SampleTime', 'param.sim.tc', 'Position', [560 640 600 670]);
    add_block('nesl_utility/Simulink-PS Converter', [net '/step_sps'], 'Position', [630 645 660 665]);
    local_sps_zero(net, 'step_sps');
    add_block('simulink/Sources/Step', [net '/breaker_cmd'], 'Time', 'param.tb.t_open', 'Before', '1', ...
        'After', '0', 'SampleTime', 'param.sim.tc', 'Position', [40 640 80 670]);
    add_block('nesl_utility/Simulink-PS Converter', [net '/breaker_sps'], 'Position', [110 645 140 665]);
    local_sps_zero(net, 'breaker_sps');
    add_line(net, 'step_cmd/1', 'step_sps/1', 'autorouting', 'on');
    add_line(net, 'breaker_cmd/1', 'breaker_sps/1', 'autorouting', 'on');

    earth = local_pc(net, 'earth', 'L', 1);
    local_connect(net, local_pc(net, 'solver', 'R', 1), earth);
    for i = 1:3
        y  = 50 + 200*(i - 1);
        x  = ph_names{i};
        bus = local_pmio(net, x);
        % local load: R // (L + R)
        add_block('fl_lib/Electrical/Electrical Elements/Resistor', [net '/R_load_' x], 'R', 'param.load.R', ...
            'Position', [820 y 860 y + 30], 'Orientation', 'down');
        add_block('fl_lib/Electrical/Electrical Elements/Inductor', [net '/L_load_' x], 'l', 'param.load.L', ...
            'r', 'param.load.RL', 'Position', [760 y 800 y + 30], 'Orientation', 'down');
        % load step
        add_block('fl_lib/Electrical/Electrical Elements/Switch', [net '/S_step_' x], 'R_closed', '1e-4', ...
            'G_open', '1e-6', 'Threshold', '0.5', 'Position', [640 y 680 y + 30]);
        add_block('fl_lib/Electrical/Electrical Elements/Resistor', [net '/R_step_' x], 'R', 'param.load.R_step', ...
            'Position', [580 y + 60 620 y + 90], 'Orientation', 'down');
        % grid breaker, grid impedance, source
        add_block('fl_lib/Electrical/Electrical Elements/Switch', [net '/breaker_' x], 'R_closed', '1e-4', ...
            'G_open', '1e-6', 'Threshold', '0.5', 'Position', [360 y 400 y + 30]);
        add_block('fl_lib/Electrical/Electrical Elements/Inductor', [net '/L_grid_' x], 'l', 'param.grid.L', ...
            'r', 'param.grid.R', 'Position', [240 y 280 y + 30]);
        add_block('fl_lib/Electrical/Electrical Sources/AC Voltage Source', [net '/U_grid_' x], ...
            'amp', 'param.grid.u_peak', 'shift', shift{i}, 'frequency', 'param.grid.f', ...
            'Position', [120 y 160 y + 30]);

        local_connect(net, bus, local_pc(net, ['R_load_' x], 'L', 1));
        local_connect(net, local_pc(net, ['R_load_' x], 'R', 1), earth);
        local_connect(net, bus, local_pc(net, ['L_load_' x], 'L', 1));
        local_connect(net, local_pc(net, ['L_load_' x], 'R', 1), earth);

        sw = local_switch(net, ['S_step_' x], 'step_sps');
        local_connect(net, bus, sw(2));
        local_connect(net, sw(1), local_pc(net, ['R_step_' x], 'L', 1));
        local_connect(net, local_pc(net, ['R_step_' x], 'R', 1), earth);

        sw = local_switch(net, ['breaker_' x], 'breaker_sps');
        local_connect(net, bus, sw(2));
        local_connect(net, sw(1), local_pc(net, ['L_grid_' x], 'R', 1));
        local_connect(net, local_pc(net, ['L_grid_' x], 'L', 1), local_pc(net, ['U_grid_' x], 'L', 1));
        local_connect(net, local_pc(net, ['U_grid_' x], 'R', 1), earth);
    end
end

% --------------------------------------------------------------------------------------------------------------
function t = local_switch(sys, sw, sps)
%LOCAL_SWITCH  Connect the PS output of the Simulink-PS converter sps to the control port of the Foundation switch
%   sw and return the handles of its two electrical terminals [t1 t2]. The control port is found by trying the
%   connection (add_line refuses a physical signal on an electrical port).
    ph  = get_param([sys '/' sw], 'PortHandles');
    src = local_pc(sys, sps, 'R', 1);
    all_p = [ph.LConn ph.RConn];
    ctrl = [];
    for h = [ph.RConn(1) ph.LConn ph.RConn(2:end)]
        try
            add_line(sys, src, h, 'autorouting', 'on');
            ctrl = h;
            break
        catch
        end
    end
    assert(~isempty(ctrl), 'build_pgfm_droop: control port of %s/%s not found', sys, sw);
    t = all_p(all_p ~= ctrl);
    assert(numel(t) == 2, 'build_pgfm_droop: %s/%s has %d terminals', sys, sw, numel(t));
end

function local_sps_zero(sys, b)
%LOCAL_SPS_ZERO  Simulink-PS converter with piecewise-constant input (no filter), unit 1.
    try
        set_param([sys '/' b], 'FilteringAndDerivatives', 'zero');
    catch
    end
end

function h = local_pc(sys, b, side, n)
%LOCAL_PC  Handle of the physical port n on the side 'L' or 'R' of the block b of sys.
    ph = get_param([sys '/' b], 'PortHandles');
    if side == 'L'
        h = ph.LConn(n);
    else
        h = ph.RConn(n);
    end
end

function h = local_pmio(sys, b)
%LOCAL_PMIO  Handle of the port of the Connection Port block b of sys.
    ph = get_param([sys '/' b], 'PortHandles');
    h = [ph.LConn ph.RConn];
    h = h(1);
end

function local_connect(sys, h1, h2)
    add_line(sys, h1, h2, 'autorouting', 'on');
end

function local_note(sys, xy, text)
%LOCAL_NOTE  Annotation at xy (top left) of the system sys.
    try
        a = Simulink.Annotation(sys, text);
        a.Position = [xy xy + [600 40]];
    catch
        try
            a = Simulink.Annotation([sys '/note']);
            a.Text = text;
            a.Position = [xy xy + [600 40]];
        catch
        end
    end
end
