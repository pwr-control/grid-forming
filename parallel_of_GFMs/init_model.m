%[text] # pgfm\_ctrl\_analysis.slx: three modules in parallel, model initialization (param structure by subsystem)
% Rev. 02, 2026-11-05. Three AFE modules (afe_abc_inv_psm_mod1..3) on the grid emulator, DC side on one
% lithium-ion battery (battery_1). Every module has its own clock (global timing: time_afe1..3, gains
% param.afe.behav.time_gain_module_1..3), aligned to time_master by its phase_compensation_1, and its own
% references (param.afe.ref.ixi_ref_modN, u_cm_comp_modN, param.afe.behav.pwm_phase_shift_modN).
% The init comes from the AFE init (afe_rst_ctrl.slx): the groups param.inv, param.psm and param.load are
% computed but not read by this model, the template extras are off.
%
% Home license: at most 1000 non-virtual blocks. The model has about 998 (non_virtual_blocks_counting.m),
% the scopes inside modules 2 and 3 are commented out for this reason: every new block counts.
%
% Earthing (2026-11-05): battery referenced to earth through battery_1/HF and Ground Network, star point
% of the emulator transformer secondary not earthed (IT), HF parasitic capacitances on both sides
% (param.gnd). Design note: repositories-documentation/repos_doc/parallel_of_gfms (link "Design note" in
% the model, PDF on the path when the documentation repository sits next to this one).
%
% Everything the model needs is in the struct "param", one group per subsystem:
%   param.sim       simulation settings (stop time, fixed step, solver, module count, thermal model choice)
%   param.time      timing settings shared by all stages, and the PWM data of the stages not in this model
%   param.glb_time  timing_setup object (built from param.time, param.afe.pwm, param.inv.pwm)
%   param.grid      grid emulator inputs;              param.grid.emu     grid_three_phase_emulator object
%   param.frt       FRT test inputs;                   param.frt.data     frt_settings + grid_fault_generator data
%   param.afe       active front end: .pwm .hw_in (hardware numbers) .hw (hw_afe_three_phase_setup object)
%                   .ctrl .uvw (parameter struct of the library blocks afe_uvw_ctrl) .ref .behav .igbt .mosfet .ideal_switch
%   param.inv       machine-side inverter: .pwm .hw_in .hw (hw_inverter_three_phase_setup) .behav .igbt .mosfet .ideal_switch
%   param.psm       machine and its control: .machine_in (machine numbers) .machine (pmsm_setup object)
%                   .mode .impl .ctrl (.ctrl.ekf) and the voltage scaling
%   param.load      torque curve, speed reference, load torque, external inertia
%   param.meas      ADC end scale and quantization
%   param.ctrl      control settings common to all modules (time alignment, filters, PI clip release)
%   param.thermal   heatsink inputs;                   param.thermal.heatsink  liquid_cooled_plate_2kw_setup object
%   param.dclink    DC-link stray inductance (Bode check only, not read by the model)
%   param.dev       names of the semiconductor datasets
%   param.battery   DC source of the three modules: .pack_1 (lithium_ion_battery_setup), read by battery_1
%   param.gnd       HF parasitic capacitances to earth and earthing resistances (battery_1, grid emulator)
%
% Naming rule: the leaf name of the old workspace variable is kept (kp_align -> param.ctrl.kp_align),
% except that inside param.afe and param.inv the afe_/inv_ tag becomes redundant and is dropped
% (fpwm_afe -> param.afe.pwm.fpwm, afe_pwm_phase_shift_mod1 -> param.afe.behav.pwm_phase_shift_mod1).
% Library objects keep their name as a field: hwdata.afe -> param.afe.hw, afe_ctrl -> param.afe.ctrl,
% psm -> param.psm.machine, psm_ctrl -> param.psm.ctrl, frt_data -> param.frt.data, grid_emu -> param.grid.emu.
%
% Library dependence (2026-09-30): the library provides classes and algorithms (timing_setup,
% hw_afe_three_phase_setup, hw_inverter_three_phase_setup, pmsm_setup, ctrl_*_setup, device_*_setup,
% liquid_cooled_plate_2kw_setup...), the model's numbers stay in this file (param.afe.hw_in,
% param.inv.hw_in, param.psm.machine_in, the torque curve in param.load); the *_hwdata, psm_calculus and
% torque-curve functions of the library are no longer called. The device datasets (device_igbt_setup...)
% stay in the library: they describe components, not this model. A function that must be frozen or
% changed for this model only goes in ./private with the same name: MATLAB resolves private functions
% before the path, for the files of this folder only, and the list of such overrides is printed at
% every run (see below).

clear;
[model, options] = init_environment('pgfm_ctrl_analysis');
s = tf('s');
param = struct();

% functions overridden for this model: ./private takes precedence over the library
overrides = dir(fullfile(fileparts(mfilename('fullpath')), 'private', '*.m'));
if ~isempty(overrides)
    fprintf('%s init: local overrides in private/: %s\n', model, strjoin({overrides.name}, ', '));
end
clear overrides

% design note of this model on the path: the link "Design note" of the model opens parallel_of_gfms.pdf from
% repositories-documentation/repos_doc/parallel_of_gfms when that repository sits next to this one
% (C:\github\pwr-control\repositories-documentation), otherwise the copy on GitHub
doc_dir = fullfile(fileparts(fileparts(fileparts(mfilename('fullpath')))), 'repositories-documentation', ...
    'repos_doc', 'parallel_of_gfms');
if isfolder(doc_dir), addpath(doc_dir); end
clear doc_dir
%[text] ## Simulation
param.sim.simlength = 1.75;                 % [s] model StopTime
param.sim.tc = 1e-6;                     % [s] fixed step (model FixedStep) and logging base
param.sim.load_step_time = 1.25;            % [s]
param.sim.transmission_delay = 125e-6*2;    % [s]
param.sim.sst_num_of_modules = 2;
param.sim.time_aux_power_supply_fault = 1e3;    % [s] never, in this run

% modules in parallel: the model has three (afe_abc_inv_psm_mod1..3), wired in the diagram
param.sim.number_of_modules = 3;

% power stage model: MOSFET with thermal model, IGBT with thermal model, or ideal switch
param.sim.use_mosfet_thermal_model = 0;
param.sim.use_thermal_model = 0;

param.sim.nonlinear_iterations = 3;         % Simscape solver
if (param.sim.use_mosfet_thermal_model || param.sim.use_thermal_model)
    param.sim.nonlinear_iterations = 5;     % Simscape solver
end

% white noise power used by the module behaviour settings (clock and PWM phase noise)
param.sim.wnp = 0;

% stages of the shared init template not present in this model (DAB, CLLC, PSFBC, ISOP rail,
% single-phase inverter, UPQC, IM, load transformer): see add_template_extras at the end. The battery,
% which this model uses, is set in the main body (section Battery)
param.sim.build_template_extras = false;
%[text] ## Timing
param.time.fpwm = 4e3;                              % [Hz] base PWM frequency
param.time.t_measure = param.sim.simlength;         % [s]
param.time.tc_factor = 1/param.time.fpwm/param.sim.tc/2;    % ts_afe/tc, so that glb_time.tc = param.sim.tc
param.time.tc_decimation = 1;
param.time.delay_pwm = 0;
param.time.trgo_th_generator = 0.025;

% stages not in this model, needed by the shared timing object only
param.time.fpwm_single_phase_inv = param.time.fpwm;
param.time.trgo_single_phase_inv = 1;               % double update
param.time.dead_time_single_phase_inv = 3e-6;
param.time.fpwm_dab = 3*param.time.fpwm;
param.time.trgo_dab = 1;                            % double update
param.time.dead_time_dab = 2e-6;
param.time.fpwm_psfbc = param.time.fpwm;
param.time.trgo_psfbc = 1;                          % double update
param.time.dead_time_psfbc = 3e-6;
param.time.fpwm_isop_rail = param.time.fpwm;
param.time.trgo_isop_rail = 1;                      % double update
param.time.dead_time_isop_rail = 3e-6;
param.time.fpwm_cllc = 3*param.time.fpwm;
param.time.trgo_cllc = 0;                           % single update
param.time.dead_time_cllc = 2e-6;
%[text] ### AFE and inverter PWM
param.afe.pwr_nom = 250e3;                          % [W]
param.afe.pwm.fpwm = param.time.fpwm;               % [Hz]
param.afe.pwm.trgo = 1;                             % double update
param.afe.pwm.dead_time = 3e-6;                     % [s]

param.inv.pwr_nom = 250e3;                          % [W]
param.inv.pwm.fpwm = param.time.fpwm;               % [Hz]
param.inv.pwm.trgo = 1;                             % double update
param.inv.pwm.dead_time = 3e-6;                     % [s]
%[text] ### Global timing object
t = param.time;
param.glb_time = timing_setup(param.afe.pwm.fpwm, param.afe.pwm.trgo, param.inv.pwm.fpwm, param.inv.pwm.trgo, ...
    t.fpwm_single_phase_inv, t.trgo_single_phase_inv, t.fpwm_dab, t.trgo_dab, ...
    t.fpwm_psfbc, t.trgo_psfbc, t.fpwm_isop_rail, t.trgo_isop_rail, t.fpwm_cllc, t.trgo_cllc, ...
    t.t_measure, t.tc_factor, t.tc_decimation, t.delay_pwm, param.afe.pwm.dead_time, param.inv.pwm.dead_time, ...
    t.dead_time_single_phase_inv, t.dead_time_dab, t.dead_time_psfbc, t.dead_time_isop_rail, t.dead_time_cllc);
clear t
%[text] ## Grid
param.grid.grid_nominal_power = 1000e3;             % [W]
param.grid.application_voltage = 690;               % [V] 690, 480 or 400
param.grid.grid_nominal_current = param.grid.grid_nominal_power/param.grid.application_voltage/sqrt(3);

% coupling transformer Dyn11
param.grid.delta_star = 1;

if param.grid.application_voltage == 690
    param.grid.us1 = 690; param.grid.us2 = 690; param.grid.fgrid = 50;
    param.grid.eta = 95; param.grid.ucc = 5;
    param.grid.p_iron = 1800;
elseif param.grid.application_voltage == 480
    param.grid.us1 = 480; param.grid.us2 = 480; param.grid.fgrid = 60;
    param.grid.eta = 95; param.grid.ucc = 5;
    param.grid.p_iron = 1400;
else
    param.grid.us1 = 400; param.grid.us2 = 400; param.grid.fgrid = 50;
    param.grid.eta = 95; param.grid.ucc = 5;
    param.grid.p_iron = 1000;
end

param.grid.n2 = 14;
param.grid.n1 = floor(param.grid.n2*sqrt(3));
param.grid.core_area = 0.05;                        % [m^2]
param.grid.core_length = 2.5;                       % [m]
param.grid.mu0 = 4*pi*1e-7;
param.grid.mur = 10e3;

% magnetizing inductance from the core geometry, line no-load current from it (the delta primary coil Lm1 sees the line voltage)
param.grid.Lm1 = (param.grid.n1^2 * param.grid.mu0 * param.grid.mur * param.grid.core_area) / param.grid.core_length;
param.grid.i1m = sqrt(3)*param.grid.us1/param.grid.Lm1/(2*pi*param.grid.fgrid);

% reference for the voltage sequences
param.grid.up_xi_pu_ref = 1;
param.grid.up_eta_pu_ref = 0;
param.grid.un_xi_pu_ref = 0;
param.grid.un_eta_pu_ref = 0;

% grid impedance (ucc_factor can be preset only if the clear at the top is removed, e.g. in a sweep)
param.grid.Lgrid_base = param.grid.us1/sqrt(3)*param.grid.ucc/100/2/pi/param.grid.fgrid/param.grid.grid_nominal_current;
if exist('ucc_factor', 'var')
    param.grid.ucc_factor = ucc_factor;
else
    param.grid.ucc_factor = 1;
end
param.grid.eq_grid_inductance = param.grid.Lgrid_base*param.grid.ucc_factor;    % [H]
param.grid.eq_grid_resistance = 2e-3;                                             % [Ohm]

% transformer of the grid emulator: block configurable_trafo of the library (Dyn11, one delta primary, star secondary
% with the star point grounded, three-limb core). It reads the per-unit data param.grid.emu.trafo.pu.* (r1, l1, r3,
% l3, lm, lm0, rfe, clock3) that the class three_phase_transformer_setup computes from the nameplate above, next to
% the SI data of one coil (Rd1, Ld1, Lm1, Rfe1, Rd2, Ld2) of the former three single-phase transformers.
param.grid.lm0_pu = 0.5;                            % [pu] zero-sequence magnetizing inductance of the three-limb core
                                                    % (lm0 = lm would be a bank of three single-phase units)
g = param.grid;
param.grid.emu = grid_three_phase_emulator('Dyn11', g.delta_star, g.grid_nominal_power, g.application_voltage, ...
    g.us1, g.us2, g.fgrid, g.eq_grid_inductance, g.eq_grid_resistance, g.eta, g.ucc, g.i1m, g.p_iron, ...
    g.n1, g.n2, g.core_area, g.core_length, g.mur, ...
    g.up_xi_pu_ref, g.up_eta_pu_ref, g.un_xi_pu_ref, g.un_eta_pu_ref, g.lm0_pu);
clear g
%[text] ## FRT
param.frt.test_index = 25;                  % type of fault: index
param.frt.test_subindex = 4;                % type of fault: subindex
param.frt.enable_frt_1 = 0;                 % faults generated from abc
param.frt.enable_frt_2 = 1;                 % faults generated from xi_eta_pos and xi_eta_neg
param.frt.start_time_LVRT = 0.75;           % [s]
param.frt.asymmetric_error_type = 1;        % 0: variant C (two-phase), 1: variant D (single-phase)
param.frt.deepPOSxi = 1;
param.frt.deepPOSeta = -0.4;
param.frt.deepNEGxi = 0.4;
param.frt.deepNEGeta = 0.4;

f = param.frt;
param.frt.data = frt_settings(f.test_index, f.test_subindex, f.asymmetric_error_type, ...
    f.enable_frt_1, f.enable_frt_2, f.start_time_LVRT, f.deepPOSxi, f.deepPOSeta, f.deepNEGxi, f.deepNEGeta);

% grid_fault_generator is a function: it returns the fault waveform data (amplitudes, phase shift,
% error_length, end_time_LVRT, t_ramp, k_lvrt, load levels), merged here into param.frt.data
frt_gen = grid_fault_generator(param.frt.data, f.start_time_LVRT);
for fn = fieldnames(frt_gen)'
    param.frt.data.(fn{1}) = frt_gen.(fn{1});
end
clear f frt_gen fn
%[text] ## AFE
%[text] ### Hardware
% The numbers are the model's own (param.afe.hw_in), the library provides only the setup class
% hw_afe_three_phase_setup (normalization ubez/ibez). Same data sets as three_phase_afe_hwdata of the
% library, selected by the application voltage; DC-link capacitors and their ESR are the same for all.
if param.grid.application_voltage == 690
    param.afe.hw_in.name = 'afe690V';
    param.afe.hw_in.uafe_nom = 690;                 % [V] line-to-line
    param.afe.hw_in.iafe_freq = 50;                 % [Hz]
    param.afe.hw_in.udc = 1070;                     % [V] DC-link
    param.afe.hw_in.LFu = 500e-6;                   % [H] grid-side filter inductor
    param.afe.hw_in.LFu_cm = 500e-6;                % [H] common-mode inductor
    param.afe.hw_in.CFu = 200e-6;                   % [F] filter capacitor
    param.afe.hw_in.Rbrake = 4;                     % [Ohm]
elseif param.grid.application_voltage == 480
    param.afe.hw_in.name = 'afe480V';
    param.afe.hw_in.uafe_nom = 480;
    param.afe.hw_in.iafe_freq = 60;
    param.afe.hw_in.udc = 750;
    param.afe.hw_in.LFu = 330e-6;
    param.afe.hw_in.LFu_cm = 330e-6;
    param.afe.hw_in.CFu = 360e-6;
    param.afe.hw_in.Rbrake = 2.5;
else
    param.afe.hw_in.name = 'afe400V';
    param.afe.hw_in.uafe_nom = 400;
    param.afe.hw_in.iafe_freq = 50;
    param.afe.hw_in.udc = 660;
    param.afe.hw_in.LFu = 330e-6;
    param.afe.hw_in.LFu_cm = 330e-6;
    param.afe.hw_in.CFu = 360e-6;
    param.afe.hw_in.Rbrake = 2.5;
end
param.afe.hw_in.iafe_nom = param.afe.pwr_nom/sqrt(3)/param.afe.hw_in.uafe_nom/0.9;    % [A] at cos(phi) = 0.9
param.afe.hw_in.CFi = 7.2e-3;                       % [F] DC-link capacitance; the two banks of the three-level stages
param.afe.hw_in.CFi1 = 2*param.afe.hw_in.CFi;
param.afe.hw_in.CFi2 = 2*param.afe.hw_in.CFi;
param.afe.hw_in.RCFi = 1e-3;                        % [Ohm] ESR
param.afe.hw_in.RCFi1 = param.afe.hw_in.RCFi/2;
param.afe.hw_in.RCFi2 = param.afe.hw_in.RCFi/2;
param.afe.hw_in.RLFu = 157*0.05*param.afe.hw_in.LFu;        % [Ohm] 5 % of the reactance at 25 Hz
param.afe.hw_in.RLFu_cm = 157*0.05*param.afe.hw_in.LFu_cm;  % [Ohm]
param.afe.hw_in.RCFu = 50e-3;                       % [Ohm]

h = param.afe.hw_in;
param.afe.hw = hw_afe_three_phase_setup(h.name, param.afe.pwr_nom, h.uafe_nom, h.iafe_nom, h.iafe_freq, h.udc, ...
    param.glb_time.fPWM_AFE, h.CFi, h.RCFi, h.CFi1, h.RCFi1, h.CFi2, h.RCFi2, h.LFu, h.RLFu, h.LFu_cm, h.RLFu_cm, ...
    h.CFu, h.RCFu, h.Rbrake);
param.afe.hw.displayInfo(); %[output:7b3b50a3]
clear h
%[text] ### Control (with sequences)
param.afe.ctrl = ctrl_afe_setup(param.glb_time.ts_afe, param.grid.emu.omega_grid_nom);
param.afe.ctrl.kp_udc_ctrl = 2.5;

% resonant PI gains for weak grids
% param.afe.ctrl.res_pi.kp_rpi = 0.5;
% param.afe.ctrl.res_pi.ki_rpi = 18;

% resonant PI gains for LVRT
param.afe.ctrl.res_pi.kp_rpi = 0.6;
param.afe.ctrl.res_pi.ki_rpi = 35;
%[text] ### Current references and parallel operation
% four modules in parallel connected to a dc microgrid
param.afe.ref.ixi_ref_mod1 = -0.85;
param.afe.ref.ixi_ref_mod2 = -0.85;
param.afe.ref.ixi_ref_mod3 = -0.85;
param.afe.ref.ixi_ref_mod4 = -0.85;

% common mode voltage control for hard parallelization
param.afe.ref.en_parallel_mode = 1;
param.afe.ref.u_cm_comp_mod1 = 0;
param.afe.ref.u_cm_comp_mod2 = 0;
param.afe.ref.u_cm_comp_mod3 = 0;
param.afe.ref.u_cm_comp_mod4 = 0;
if param.afe.ref.en_parallel_mode
    param.afe.ref.u_cm_comp_mod2 = -1;
    param.afe.ref.u_cm_comp_mod3 = -1;
    param.afe.ref.u_cm_comp_mod4 = -1;
end

% reactive current steps after the LVRT
param.afe.ref.enable_i_react_pos_steps = 1;
param.afe.ref.time_i_react_pos_ref_1 = 0;   % default
param.afe.ref.time_i_react_pos_ref_2 = 0;   % default
param.afe.ref.i_react_pos_ref_1 = 0;        % default
param.afe.ref.i_react_pos_ref_2 = 0;        % default
param.afe.ref.i_react_pos_ref_3 = 0;        % default

if param.afe.ref.enable_i_react_pos_steps
    param.afe.ref.time_i_react_pos_ref_1 = param.frt.data.start_time_LVRT + param.frt.data.error_length + 0.335;
    param.afe.ref.time_i_react_pos_ref_2 = param.afe.ref.time_i_react_pos_ref_1 + 0.5;
    param.afe.ref.i_react_pos_ref_2 = -param.afe.ref.ixi_ref_mod1*tan(acos(0.95));   % cos(phi) = 0.95
    param.afe.ref.i_react_pos_ref_3 =  param.afe.ref.ixi_ref_mod1*tan(acos(0.95));   % cos(phi) = 0.95
end
%[text] ### Module behaviour (clock mismatch, noise, PWM phase shift)
param.afe.behav.time_gain_module_1 = 1.0002;
param.afe.behav.time_gain_module_2 = 1.0015;
param.afe.behav.time_gain_module_3 = 0.9988;
param.afe.behav.time_gain_module_4 = 1.0020;

param.afe.behav.white_noise_power_mod1 = param.sim.wnp;
param.afe.behav.white_noise_power_mod2 = param.sim.wnp;

param.afe.behav.pwm_phase_shift_mod1 = 0;
param.afe.behav.white_noise_power_pwm_phase_shift_mod1 = 0.0;
param.afe.behav.pwm_phase_shift_mod2 = 0;
param.afe.behav.white_noise_power_pwm_phase_shift_mod2 = 0.0;
param.afe.behav.pwm_phase_shift_mod3 = 0;
param.afe.behav.white_noise_power_pwm_phase_shift_mod3 = 0.0;
param.afe.behav.pwm_phase_shift_mod4 = 0;
param.afe.behav.white_noise_power_pwm_phase_shift_mod4 = 0.0;
%[text] ## Battery
% DC source shared by the three modules (block battery_1, library lithium_ion_battery): it reads
% param.battery.pack_1 and param.battery.nominal_battery_voltage_1. Same numbers as the template extras
% this section comes from: a pack sized as one module (250 kW), while the three modules together can
% draw up to three times that.
param.battery.nominal_battery_voltage_1 = param.afe.hw.udc_nom;   % [V]
param.battery.nominal_battery_power = 250e3;                       % [W]
param.battery.initial_battery_soc = 0.85;
% lithium_ion_battery_setup takes the charge capacity [Ah] as third argument: 1C rating,
% capacity = rated current x 1 h
param.battery.charge_capacity_1 = param.battery.nominal_battery_power/param.battery.nominal_battery_voltage_1;

b = param.battery;
param.battery.pack_1 = lithium_ion_battery_setup(b.nominal_battery_voltage_1, b.nominal_battery_power, ...
    b.charge_capacity_1, b.initial_battery_soc, param.glb_time.ts_dab);
clear b

% special settings for simulation
param.battery.pack_1.R0 = param.battery.pack_1.R0/2;
param.battery.pack_1.R1 = param.battery.pack_1.R1/2;
param.battery.pack_1.C1 = param.battery.pack_1.C1/200;
%[text] ## HF parasitics and earthing
% Earthing scheme of a BESS with an LV/MV transformer: battery referenced to earth, LV side of the
% transformer not earthed (IT). The common-mode voltage of the bridges divides on the capacitances to
% earth of the two sides: with the battery much larger than the AC side, the battery stays almost still
% and the LV winding carries the common mode. Values for about 1 MW at 1.1 kV DC, derivation in the
% design note (section Earthing and parasitics).
% DC side, per pole (battery_1/HF and Ground Network: C + R from each pole to earth, R from each pole to earth)
param.gnd.c_batt_pole = 150e-9;     % [F] cells to racks and cooling plates, DC cables and busbars, to earth
                                    %     (about 0.3 uF for a 250 kWh string, half per pole; scale with the strings)
param.gnd.r_batt_hf = 10;           % [Ohm] damping of the HF path (earth conductors, losses of the CM chokes)
param.gnd.r_gnd_pole = 100e3;       % [Ohm] symmetric high-resistance earthing of the DC poles: first-fault
                                    %       current udc/r = 12 mA, 7 W of losses; with an insulation monitor
                                    %       (IEC 61557-8) use 1 MOhm or more: the IMD sees r/2 as insulation
% AC side, per phase (grid/grid_emulator/3ph_Dyg_ssc: C with series R from each LV terminal to earth)
param.gnd.c_ac_phase = 10e-9;       % [F] transformer LV winding to core and screen, LV cables, AC nodes of the
                                    %     IGBT modules to the heatsinks
param.gnd.r_ac_hf = 10;             % [Ohm] series resistance of that path (capacitor block parameter r)
% star point of the transformer LV winding to earth
param.gnd.r_star = 1e9;             % [Ohm] 1e9: IT (not earthed); about 230: high-resistance earthing
                                    %       (first-fault current 1.7 A); 0.1: TN (solidly earthed, the battery
                                    %       then carries the common mode)
%[text] ## Inverter
%[text] ### Hardware
% Same data sets as three_phase_inverter_hwdata of the library (the 480 V set keeps the 400 V machine
% side with a 750 V DC link), class hw_inverter_three_phase_setup for the normalization.
if param.grid.application_voltage == 690
    param.inv.hw_in.name = 'inv690V_250kW';
    param.inv.hw_in.u_inv_nom = 550;                % [V] machine-side line-to-line
    param.inv.hw_in.i_inv_nom = 370;                % [A]
    param.inv.hw_in.udc = 1070;                     % [V] DC-link
    param.inv.hw_in.LFi = 230e-6;                   % [H] machine-side filter inductor
    param.inv.hw_in.LFi_cm = 230e-6;                % [H] common-mode inductor
elseif param.grid.application_voltage == 480
    param.inv.hw_in.name = 'inv480V_250kW';
    param.inv.hw_in.u_inv_nom = 400;
    param.inv.hw_in.i_inv_nom = 470;
    param.inv.hw_in.udc = 750;
    param.inv.hw_in.LFi = 160e-6;
    param.inv.hw_in.LFi_cm = 160e-6;
else
    param.inv.hw_in.name = 'inv400V_250kW';
    param.inv.hw_in.u_inv_nom = 400;
    param.inv.hw_in.i_inv_nom = 470;
    param.inv.hw_in.udc = 660;
    param.inv.hw_in.LFi = 160e-6;
    param.inv.hw_in.LFi_cm = 160e-6;
end
param.inv.hw_in.i_inv_freq = 15.6;                  % [Hz] nominal machine frequency
param.inv.hw_in.RLFi = 157*0.05*param.inv.hw_in.LFi;        % [Ohm]
param.inv.hw_in.RLFi_cm = 157*0.05*param.inv.hw_in.LFi_cm;  % [Ohm]

h = param.inv.hw_in;
param.inv.hw = hw_inverter_three_phase_setup(h.name, param.inv.pwr_nom, h.u_inv_nom, h.i_inv_nom, h.i_inv_freq, ...
    h.udc, param.glb_time.fPWM_INV, h.LFi, h.RLFi, h.LFi_cm, h.RLFi_cm);
param.inv.hw.displayInfo(); %[output:4194a2b3]
clear h
%[text] ### Module behaviour (clock mismatch, noise, PWM phase shift)
param.inv.behav.time_gain_module_1 = 1.0005;
param.inv.behav.time_gain_module_2 = 1.001;

param.inv.behav.white_noise_power_mod1 = param.sim.wnp;
param.inv.behav.white_noise_power_mod2 = param.sim.wnp;

param.inv.behav.pwm_phase_shift_mod1 = 0;
param.inv.behav.white_noise_power_pwm_phase_shift_mod1 = 0.0;
param.inv.behav.pwm_phase_shift_mod2 = 0;
param.inv.behav.white_noise_power_pwm_phase_shift_mod2 = 0.0;
param.inv.behav.pwm_phase_shift_mod3 = 0;
param.inv.behav.white_noise_power_pwm_phase_shift_mod3 = 0.0;
param.inv.behav.pwm_phase_shift_mod4 = 0;
param.inv.behav.white_noise_power_pwm_phase_shift_mod4 = 0.0;
%[text] ## Power semiconductors
param.dev.used_device_igbt = 'infineon_FF1200R17IP5';          % alternative: 'mitsubishi_CM1200DW_34T'
param.dev.used_device_mosfet = 'danfoss_SKM1700MB20R4S2I4';
param.dev.used_device_ideal_switch = 'silicon_high_power_ideal_switch';

% IGBT
param.afe.igbt = device_igbt_setup(param.dev.used_device_igbt, param.glb_time.fPWM_AFE, param.afe.hw.udc_nom);
param.inv.igbt = device_igbt_setup(param.dev.used_device_igbt, param.glb_time.fPWM_INV, param.inv.hw.udc_nom);

% MOSFET
param.afe.mosfet = device_mosfet_setup(param.dev.used_device_mosfet, param.glb_time.fPWM_AFE, param.afe.hw.udc_nom);
param.inv.mosfet = device_mosfet_setup(param.dev.used_device_mosfet, param.glb_time.fPWM_INV, param.inv.hw.udc_nom);

% ideal switch
param.afe.ideal_switch = device_ideal_switch_setting(param.dev.used_device_ideal_switch, param.glb_time.fPWM_AFE, param.afe.hw.udc_nom);
param.inv.ideal_switch = device_ideal_switch_setting(param.dev.used_device_ideal_switch, param.glb_time.fPWM_INV, param.inv.hw.udc_nom);
%[text] ## PSM and its control
%[text] ### Machine
% Machine data of psm_calculus of the library (wind generator, six three-phase systems), class pmsm_setup
param.psm.machine_in.name = 'WindGen';
param.psm.machine_in.number_of_systems = 6;
param.psm.machine_in.pwr_nom = 1600e3;             % [W]
param.psm.machine_in.i_nom = 2062;                 % [A]
param.psm.machine_in.rpm_nom = 17.8;               % [rpm]
param.psm.machine_in.number_poles = 104;
param.psm.machine_in.eta = 96;                     % [%]
param.psm.machine_in.Ld = 1.04e-3;                 % [H] per system
param.psm.machine_in.Lq = 1.26e-3;                 % [H] per system
param.psm.machine_in.Jm = 900e3/6;                 % [kg m^2]
param.psm.machine_in.h5_percent = 0;               % [%] 5th and 7th back-EMF harmonics
param.psm.machine_in.h7_percent = 0;

m = param.psm.machine_in;
param.psm.machine = pmsm_setup(m.name, m.number_of_systems, m.pwr_nom, m.i_nom, m.rpm_nom, m.number_poles, ...
    m.eta, m.Ld, m.Lq, m.Jm, m.h5_percent, m.h7_percent);
param.psm.machine.displayInfo(); %[output:5e8021e3]
clear m
param.psm.number_of_systems = 1;
param.psm.n_sys = param.psm.machine.number_of_systems;
%[text] ### Motor voltage to Udc scaling
param.psm.u_psm_scale = 2/3*param.inv.hw.udc_nom/param.psm.machine.ubez;
param.psm.u_psm_scale_ekf = sqrt(3)/2 * 2/3 * param.inv.hw.udc_nom/param.psm.machine.ubez;
%[text] ### Control modes
param.psm.mode.use_torque_curve = 1;                                        % (variant) energy production
param.psm.mode.use_speed_control = 1 - param.psm.mode.use_torque_curve;     % (variant) drive
param.psm.mode.use_mtpa = 1;                                                % (variant)
param.psm.mode.use_psm_encoder = 0;                                         % (variant)
param.psm.mode.use_im_encoder = 1;
param.psm.mode.use_load_estimator = 0;
param.psm.mode.use_estimator_from_mb = 0;                                   % mb: model based
param.psm.mode.use_motor_speed_control_mode = 0;
param.psm.mode.motor_torque_mode = 1 - param.psm.mode.use_motor_speed_control_mode;   % torque curve for wind application
param.psm.mode.time_start_motor_control = 0.25;                             % [s]
%[text] ### C-caller versus Simulink implementation
% observers
param.psm.impl.use_ekf_bemf_module_1 = 1;                                   % (variant)
param.psm.impl.use_ekf_bemf_module_2 = 1;
param.psm.impl.use_observer_from_simulink_module_1 = 0;                     % (variant)
param.psm.impl.use_observer_from_ccaller_module_1 = 0;                      % (variant)
param.psm.impl.use_observer_from_simulink_module_2 = 0;
param.psm.impl.use_observer_from_ccaller_module_2 = 0;

% current controllers
param.psm.impl.use_current_controller_from_simulink_module_1 = 0;           % (variant)
param.psm.impl.use_current_controller_from_ccaller_module_1 = 1;            % (variant)
param.psm.impl.use_current_controller_from_simulink_module_2 = 0;
param.psm.impl.use_current_controller_from_ccaller_module_2 = 0;
%[text] ### Control with EKF based observer
param.psm.ctrl = ctrl_pmsm_setup(param.glb_time.ts_inv, param.psm.machine.omega_bez, param.psm.u_psm_scale, param.psm.machine.Jm_norm);
% param.psm.ctrl.ekf = ekf_pmsm_setup(param.psm.machine.Rs_norm, param.psm.machine.Ls_norm, param.psm.machine.Jm_norm, param.glb_time.ts_inv);
param.psm.ctrl.ekf = ekf_pmsm_setup(param.psm.machine.Rs_norm, param.psm.machine.Ls_norm, 1e6, param.glb_time.ts_inv); %[output:83178410]
param.psm.ctrl.kp_i = 0.25;
param.psm.ctrl.ki_i = 35;
%[text] ## Mechanical load, speed reference and torque curve
param.load.b = param.psm.machine.load_friction_m;
param.load.external_load_inertia = 1;       % alternative: 6*param.psm.machine.Jm_m

% energy production: torque curve of the 1.5 MW generic generator (was the library script
% n_sys_generic_1M5W_torque_curve), total torque divided among the n_sys systems
param.load.rpm_base = [6 7 8 9 10 11 12 13 14 15 16 17 17.8 18.0 18.2];                        % [rpm]
param.load.torque_base = 1e3/param.psm.n_sys*[50 75 100 125 150 175 200 225 275 350 450 600 750 885 885];   % [N*m]
param.load.torque_overload_factor = 1.15;

% drive application: speed reference and load torque
param.load.rpm_sim = 17.8;                  % alternatives: 3000, 18, 15.2
param.load.omega_m_sim = param.psm.machine.omega_m_bez;
param.load.omega_sim = param.load.omega_m_sim*param.psm.machine.number_poles/2;
param.load.tau_load_sim = param.psm.machine.tau_bez/5;  % [N*m]
param.load.b_square = 0;
%[text] ## Sensors end scale and quantization
param.meas.adc_quantization = 1/2^11;
param.meas.adc12_quantization = param.meas.adc_quantization;
param.meas.adc16_quantization = 1/2^15;

param.meas.Imax_adc = 1049.835;             % [A]
param.meas.CurrentQuantization = param.meas.Imax_adc/2^11;

param.meas.Umax_adc = 1500;                 % [V]
param.meas.VoltageQuantization = param.meas.Umax_adc/2^11;
%[text] ## Control settings common to all modules
% local time alignment to master time
param.ctrl.kp_align = 0.25;
param.ctrl.ki_align = 18;
param.ctrl.lim_up_align = 0.05;
param.ctrl.lim_down_align = -0.05;

% filters and PI clip release
param.ctrl.CTRPIFF_CLIP_RELEASE = 0.001;
param.ctrl.mavarage_filter_frequency_base_order = 2;   % 2 means 100 Hz, 1 means 50 Hz
param.ctrl.dmavg_filter_enable_time = 0.025;           % [s]
param.ctrl.filters = setup_global_filters(param.glb_time.ts_afe, param.glb_time.ts_inv, param.glb_time.ts_dab, param.glb_time.tc);
%[text] ## AFE control in uvw: parameters of the library blocks (afe\_uvw\_ctrl)
% The five MATLAB Function blocks of the library package masked_models/afe_uvw_ctrl
% (grid_voltage_sequences, frt_vde4110, grid_current_sequences_q_ctrl, current_ctrl_uvw and
% islanding_detector) read one struct: the mask parameter p of every block is param.afe.uvw.
% The field names are those of afe_uvw_ctrl_param_example.m of the library (see the README of the
% package), the numbers come from this init (param.afe.ctrl, param.frt.data, param.ctrl); the FRT
% thresholds were constants inside the old subsystems. This section comes after "Control settings
% common to all modules" because it reads param.ctrl. The blocks inherit the sample time of the
% triggered subsystem afe_control: uvw.ts must be its period.
c = param.afe.ctrl;
uvw = struct();
uvw.ts        = param.glb_time.ts_afe;              % [s] control period: integration step of all blocks
uvw.omega_nom = param.grid.emu.omega_grid_nom;      % [rad/s] nominal grid pulsation: base of omega_pu

% grid voltage sequences: xi-eta of the positive and negative sequence, moving average
uvw.vseq.avg_order    = param.ctrl.mavarage_filter_frequency_base_order;  % window = grid period/avg_order (2: half period)
uvw.vseq.omega_pu_min = 0.1;                        % [pu] limits of the measured pulsation used for the window
uvw.vseq.omega_pu_max = 2;
uvw.vseq.t_enable     = param.ctrl.dmavg_filter_enable_time;   % [s] averages are zero before this time

% grid current sequences and reactive power control: PIs on the averaged sequences
uvw.iseq.avg_order    = uvw.vseq.avg_order;
uvw.iseq.omega_pu_min = uvw.vseq.omega_pu_min;
uvw.iseq.omega_pu_max = uvw.vseq.omega_pu_max;
uvw.iseq.t_enable     = uvw.vseq.t_enable;
uvw.iseq.kp_pos       = c.kp_rc_pos_grid;           % PI of the positive-sequence eta grid current
uvw.iseq.ki_pos       = c.ki_rc_pos_grid;           % [1/s]
uvw.iseq.kp_neg       = c.kp_rc_neg_grid;           % PIs of the negative-sequence xi and eta grid currents
uvw.iseq.ki_neg       = c.ki_rc_neg_grid;           % [1/s]
uvw.iseq.lim_pos_eta  = c.ieta_pos_ref_lim;         % [pu] limits of the stack current references
uvw.iseq.lim_neg_xi   = c.ieta_pos_ref_lim;         % [pu] (the old subsystem used the positive limit here too)
uvw.iseq.lim_neg_eta  = c.ieta_neg_ref_lim;         % [pu]
uvw.iseq.err_sign     = -1;                         % error = -(reference - measured): grid current measured towards the converter

% FRT (VDE-AR-N 4110): voltage-rate observers, fault detection, power limitation, reactive current references
uvw.frt.obs_kx        = c.vr_obs.kx;                % gains of the voltage-rate observers of ctrl_afe_setup (poles [-0.1 -0.4]*omega_base)
uvw.frt.obs_kv        = c.vr_obs.kv;
uvw.frt.t_obs_release = 0.025;                      % [s] observers held at zero before this time
uvw.frt.v_pos_low     = 0.85;                       % [pu] fault when the positive sequence is below this ...
uvw.frt.v_pos_high    = 1.15;                       % [pu] ... or above this ...
uvw.frt.v_neg_max     = 0.1;                        % [pu] ... or the negative sequence is above this
uvw.frt.v_hyst        = 0.1;                        % [pu] band narrowing to leave the fault
uvw.frt.v_pos_dot_max = 2.0;                        % [pu/s] the voltage must also change faster than this
uvw.frt.v_neg_dot_max = 2.0;                        % [pu/s]
uvw.frt.t_rearm       = 0.125;                      % [s] idle time needed before a new detection
uvw.frt.t_hold_max    = 7.625;                      % [s] a fault longer than this ends in the state EXCEEDED
uvw.frt.pwrlim_v_pos  = 0.8;                        % [pu] active power limited (pwr_lim_enable) when v_pos < this ...
uvw.frt.pwrlim_v_neg  = 0.1;                        % [pu] ... or v_neg > this
uvw.frt.pwrlim_hyst   = 0.1;                        % [pu] released when v_pos > pwrlim_v_pos + hyst ...
uvw.frt.pwrlim_v_neg_release = 0.7;                 % [pu] ... and v_neg < this
uvw.frt.reddyn_enabled = 0;                         % reduced dynamic grid support (off, as in the old subsystem)
uvw.frt.reddyn_v_pos  = 0.7;                        % [pu]
uvw.frt.reddyn_v_neg  = 0.2;                        % [pu]
uvw.frt.k_frt_ref     = param.frt.data.k_frt_ref;   % [pu/pu] reactive current per voltage change
uvw.frt.t_avg_prefault = 0.5;                       % [s] window of the pre-fault voltage averages
uvw.frt.t_avg_start   = 0.05;                       % [s] the pre-fault averages start here
uvw.frt.lim_pos_eta   = c.i_grid_pos_eta_lim;       % [pu] limits of the grid current references
uvw.frt.lim_neg_xi    = c.i_grid_neg_xi_lim;
uvw.frt.lim_neg_eta   = c.i_grid_neg_eta_lim;
uvw.frt.lim_pos_eta_red = c.i_grid_pos_eta_red_lim; % [pu] the same with reduced dynamic support
uvw.frt.lim_neg_xi_red  = c.i_grid_neg_xi_red_lim;
uvw.frt.lim_neg_eta_red = c.i_grid_neg_eta_red_lim;
uvw.frt.f_lpf_ref     = 161;                        % [Hz] low pass of the references

% current control in uvw: resonant PI per phase, zero-sequence PI
uvw.ictrl.kp        = c.res_pi.kp_rpi;              % resonant PI kp + ki*s/(s^2 + 2*delta*w*s + w^2)
uvw.ictrl.ki        = c.res_pi.ki_rpi;              % [1/s]
uvw.ictrl.delta_res = 0.005;                        % damping of the resonator. The class value 0.015 was tuned
                                                    % with the forward Euler resonator of the old subsystem (poles
                                                    % outside the unit circle, gain 10.8 at omega); the library block
                                                    % uses forward-backward Euler (poles inside) and 0.005 gives
                                                    % about the same gain at omega (11.1): same current loop as before
uvw.ictrl.omega_res = c.omega_base;                 % [rad/s] resonance pulsation
uvw.ictrl.mag_lim   = 1;                            % [pu] the alpha/beta output vector is scaled down above this length
uvw.ictrl.mag_scale_max = 10;                       % largest scaling factor
uvw.ictrl.out_delay = 1;                            % 1: alpha/beta output one step late (as the old subsystem), 0: no delay
uvw.ictrl.kp_z      = c.kp_is_z;                    % zero-sequence current PI
uvw.ictrl.ki_z      = c.ki_is_z;                    % [1/s]
uvw.ictrl.u_z_lim   = 1;                            % [pu] limit of u_gamma
uvw.ictrl.iz_ref    = 0;                            % [pu] zero-sequence current reference

% islanding detector (passive): U<, U>, f<, f>, ROCOF and 5th/7th harmonic criteria with on-delays.
% Thresholds of the network protection of VDE-AR-N 4105 / 4110 for a 50 Hz grid; the slow U< stage
% (2.7 s) lets the converter ride through a grid fault (frt_vde4110) without an islanding trip.
uvw.island.h_avg_order  = 1;                        % harmonic averaging window = grid period/h_avg_order
uvw.island.omega_pu_min = 0.5;                      % [pu] limits of the measured pulsation used for the window
uvw.island.omega_pu_max = 1.5;
uvw.island.t_enable     = 0.1;                      % [s] no detection before this time
uvw.island.tau_f        = 0.02;                     % [s] low pass of the frequency
uvw.island.obs_poles    = [-20 -80];                % [rad/s] poles of the ROCOF observer (double integrator, as vr_obs)
Ad = [1 uvw.ts; 0 1];
L = acker(Ad', [1 0]', exp(uvw.island.obs_poles*uvw.ts))';
uvw.island.obs_kx = L(1)/uvw.ts;
uvw.island.obs_kv = L(2)/uvw.ts;
uvw.island.u_valid      = 0.5;                      % [pu] frequency and harmonic criteria only above this voltage
uvw.island.u_min        = 0.8;                      % [pu] under-voltage ...
uvw.island.t_trip_u_min = 2.7;                      % [s] ... for this time
uvw.island.u_max        = 1.15;                     % [pu] over-voltage ...
uvw.island.t_trip_u_max = 0.1;                      % [s] ... for this time
uvw.island.f_min        = 47.5/param.grid.fgrid;    % [pu] under-frequency (47.5 Hz) ...
uvw.island.f_max        = 51.5/param.grid.fgrid;    % [pu] over-frequency (51.5 Hz) ...
uvw.island.t_trip_f     = 0.1;                      % [s] ... for this time
uvw.island.rocof_max    = 2.5;                      % [Hz/s] rate of change of frequency ...
uvw.island.t_trip_rocof = 0.1;                      % [s] ... for this time
uvw.island.h_max        = 0.1;                      % [pu/pu] sqrt(u5^2 + u7^2)/u1 above this ...
uvw.island.t_trip_h     = 0.1;                      % [s] ... for this time
uvw.island.latch        = 1;                        % the output stays 1 until enable goes to 0

param.afe.uvw = uvw;
clear c uvw Ad L
%[text] ## Thermal model
% aluminium plate, liquid cooled, sized for PrimePACK2; liquid flow > 28 l/min
% "A" (ambient) is the water: HA is the temperature rise from water to heatsink surface;
% water in/out rise max 5 K with 2 kW total losses
param.thermal.weight = 0.150;                                   % [kg]
param.thermal.no_weight = 0.150/10;                             % [kg] /10: thermal inertia not accounted
param.thermal.cp_al = 900;                                      % [J/(kg K)] specific heat, aluminium
param.thermal.heat_capacity_hs = param.thermal.cp_al * param.thermal.weight;   % [J/K]
param.thermal.thermal_conductivity_al = 160;                    % [W/(m K)] aluminium
param.thermal.Rth_switch_HA = 15/1000;                          % [K/W]
param.thermal.Rth_mosfet_HA = param.thermal.Rth_switch_HA;      % [K/W]
param.thermal.Rth_diode_HA = param.thermal.Rth_switch_HA;       % [K/W]
param.thermal.Tambient = 40;                                    % [degC] water temperature
param.thermal.DThs_init = 0;                                    % [K]

t = param.thermal;
param.thermal.heatsink = liquid_cooled_plate_2kw_setup(t.weight, t.no_weight, t.cp_al, t.heat_capacity_hs, ...
    t.thermal_conductivity_al, t.Rth_switch_HA, t.Rth_mosfet_HA, t.Rth_diode_HA, t.Tambient, t.DThs_init);
clear t
%[text] ### Library workaround: thermal sources read the base workspace
% Inside the thermal bridges of the library (masked_models/semiconductors_bridges/*.slx) the temperature
% source has T = DThs_init+Tambient and the initial temperatures read Tambient, instead of the mask
% parameters DThs_init_m / Tambient_m that the instance sets: the two flat names must exist in the base
% workspace. Delete this section once the library is fixed (tools/fix_library_thermal_source_refs.m).
Tambient = param.thermal.Tambient;
DThs_init = param.thermal.DThs_init;
%[text] ## DC-link stray inductance (partial loop inductance)
% same data as the library script parasitic_dclink_data.m; not read by the model, Bode check only
param.dclink.Lstray_dclink = 100e-9;                            % [H]
param.dclink.RLstray_dclink = 10e-3;                            % [Ohm]
param.dclink.C_HF_Lstray_dclink = 15e-6;                        % [F]
param.dclink.R_HF_Lstray_dclink = 22000;                        % [Ohm]
param.dclink.Z_HF_Lstray_dclink = 1/s/param.dclink.C_HF_Lstray_dclink + param.dclink.R_HF_Lstray_dclink;
param.dclink.Z_LF_Lstray_dclink = s*param.dclink.Lstray_dclink + param.dclink.RLstray_dclink;
param.dclink.Z_Lstray_dclink = param.dclink.Z_HF_Lstray_dclink*param.dclink.Z_LF_Lstray_dclink/ ...
    (param.dclink.Z_HF_Lstray_dclink + param.dclink.Z_LF_Lstray_dclink);
param.dclink.ZCFi = 7/s/param.afe.hw.CFi;
param.dclink.sys_dclink = minreal(param.dclink.ZCFi/(param.dclink.ZCFi + param.dclink.Z_Lstray_dclink));
figure; bode(param.dclink.sys_dclink, param.dclink.Z_Lstray_dclink, options); grid on %[output:65c69798]
%[text] ## Template extras (not used by pgfm\_ctrl\_analysis.slx)
if param.sim.build_template_extras %[output:group:7a6c4b56]
    param = add_template_extras(param, options); %[output:4ab8b4aa] %[output:6debe77d] %[output:32ef08ab] %[output:6ac8e065] %[output:98c8ccfa]
end %[output:group:7a6c4b56]
%[text] ## Model setup
open_system(model);
%[text] ### C-Caller types
ctypes = {'mavgflt_output_t', 'dsmavgflt_output_t', 'mavgflts_output_t', 'bemf_obsv_output_t', ...
    'bemf_obsv_load_est_output_t', 'dqvector_pi_output_t', 'sv_pwm_output_t', 'sv_pwm_cm_output_t', ...
    'global_state_machine_output_t', 'first_harmonic_tracker_output_t', 'dqpll_thyr_output_t', ...
    'dqpll_grid_output_t', 'rpi_output_t', 'phase_shift_flt_output_t', 'sogi_flt_output_t', ...
    'linear_double_integrator_observer_output_t'};
for k = 1:numel(ctypes)
    Simulink.importExternalCTypes(model, 'Names', ctypes(k));
end
clear ctypes k
%[text] ### Scopes closed at start
open_scopes = find_system(model, 'BlockType', 'Scope');
for k = 1:numel(open_scopes)
    set_param(open_scopes{k}, 'Open', 'off');
end
clear open_scopes k
%[text] ### CREATE\_POWER\_METER\_BUS
% Simulink.Bus for output "m" of the MATLAB Function block three_phase_power_meter_iec
% (Symbols pane: Type = Bus: PowerMeterIecBus). Bus objects stay in the base workspace.
names = {'Q1p', 'Q1n', 'P1n', 'P1p', 'U1n', 'U1p', ...
    'i_act_1n', 'i_react_1n', 'i_act_1p', 'i_react_1p'};

elems = Simulink.BusElement.empty(0,1);
for k = 1:numel(names)
    e            = Simulink.BusElement;
    e.Name       = names{k};
    e.Dimensions = 1;
    e.DataType   = 'double';
    e.Complexity = 'real';
    elems(k,1)   = e;
end

PowerMeterIecBus          = Simulink.Bus;
PowerMeterIecBus.Elements = elems;
assignin('base', 'PowerMeterIecBus', PowerMeterIecBus);
clear names elems e k
%[text] ## Local functions
function param = add_template_extras(param, options)
% Parts of the shared init template not used by pgfm_ctrl_analysis.slx, kept so that nothing of the
% legacy init_model.m is lost. Enabled by param.sim.build_template_extras = true.
% Same convention: one group per stage (param.spinv, param.dab, param.psfbc, param.cllc,
% param.isop_rail, param.upqc, param.im, param.battery, param.trafo_load), each with .hw, .ctrl, devices.
% param.battery.pack_1 is also set in the main body (section Battery) with the same numbers.

s = tf('s');
ts = param.glb_time.ts_inv;

% ---------------------------------------------------------------- single-phase inverter
% global behaviour: system identification versus normal operation
param.spinv.system_identification_enable = 0;
param.spinv.frequency_set = 50;             % default
if param.spinv.system_identification_enable
    param.spinv.frequency_set = 300;
end
param.spinv.omega_set = param.spinv.frequency_set*2*pi;

param.spinv.rpi_enable = 0;                 % use RPI otherwise DQ PI
param.spinv.impl.use_current_controller_from_ccaller_mod1 = 1;
param.spinv.impl.use_phase_shift_filter_from_ccaller_mod1 = 1;
param.spinv.impl.use_sogi_from_ccaller_mod1 = 1;

param.spinv.impl.use_single_phase_inverter_based_FHT = 0;
param.spinv.impl.use_single_phase_inverter_based_SOGI = 0;
param.spinv.impl.use_single_phase_inverter_based_PHSH = 0;
param.spinv.impl.use_single_phase_inverter_based_SOGI_ccaller = 1;
param.spinv.impl.use_single_phase_inverter_based_PHSH_ccaller = 0;

param.spinv.impl.use_system_identification_based_FHT = 0;
param.spinv.impl.use_system_identification_based_SOGI = 0;
param.spinv.impl.use_system_identification_based_PHSH = 0;
param.spinv.impl.use_system_identification_based_SOGI_ccaller = 0;
param.spinv.impl.use_system_identification_based_PHSH_ccaller = 1;

% current references
param.spinv.ref.iph_grid_pu_ref_1 = 1/3;
param.spinv.ref.iph_grid_pu_ref_2 = 1/3;
param.spinv.ref.iph_grid_pu_ref_3 = 1/3;
param.spinv.ref.time_step_ref_1 = 0.025;
param.spinv.ref.time_step_ref_2 = 0.5;
param.spinv.ref.time_step_ref_3 = 1;

param.spinv.pwr_nom = 225e3;
param.spinv.hw = single_phase_inverter_hwdata(param.grid.application_voltage, param.spinv.pwr_nom, param.glb_time.fPWM_INV);

% ---------------------------------------------------------------- rail catenary and ISOP rail
param.isop_rail.catenary_nominal_power = 2*5.4e6;   % per 12 km
param.isop_rail.catenary_nominal_voltage = 3000;
param.isop_rail.catenary_maximum_voltage = 4000;
param.isop_rail.catenary_nominal_current = param.isop_rail.catenary_nominal_power/param.isop_rail.catenary_nominal_voltage;
param.isop_rail.pwr_nom = 250e3;                    % nominal per system
param.isop_rail.number_of_systems = 4;
param.isop_rail.full_bridge_application_voltage = param.isop_rail.catenary_maximum_voltage/param.isop_rail.number_of_systems;
param.isop_rail.hw = isop_rail_aux_application(param.isop_rail.full_bridge_application_voltage, ...
    param.isop_rail.pwr_nom, param.glb_time.fPWM_ISOP_RAIL);

% ---------------------------------------------------------------- isolated DC/DC stages
uapp = param.grid.application_voltage;
param.dab.pwr_nom = 250e3;
param.dab.fres = param.glb_time.fPWM_DAB/5;
param.dab.hw = single_phase_dab_hwdata(uapp, param.dab.pwr_nom, param.glb_time.fPWM_DAB, param.dab.fres);
param.three_phase_dab.pwr_nom = 3*param.dab.pwr_nom;
param.three_phase_dab.hw = three_phase_dab_hwdata(uapp, param.three_phase_dab.pwr_nom, param.glb_time.fPWM_DAB, param.dab.fres);
param.psfbc.pwr_nom = 275e3;
param.psfbc.hw = single_phase_psfbc_hwdata(uapp, param.psfbc.pwr_nom, param.glb_time.fPWM_PSFBC);
param.cllc.pwr_nom = 250e3;
param.cllc.fres = param.glb_time.fPWM_CLLC*1.2;
param.cllc.hw = single_phase_cllc_hwdata(uapp, param.dab.pwr_nom, param.glb_time.fPWM_CLLC, param.cllc.fres);  % legacy init passes dab_pwr_nom (same value)
% modifications
% param.afe.hw.CFi = 2 * param.psfbc.hw.Cdc_dc1;

% ---------------------------------------------------------------- UPQC series transformer
param.upqc.name = 'UPQC Series Transformer';
param.upqc.pwr_nom = 3*125e3;
param.upqc.u1_nom = 400;
param.upqc.u2_nom = 690;
param.upqc.f_nom = 50;
param.upqc.eta = 98;
param.upqc.ucc = 4;
param.upqc.p_iron = 5e3;
param.upqc.n12 = param.upqc.u1_nom/param.upqc.u2_nom;
param.upqc.n2 = 8;
param.upqc.n1 = param.upqc.n12*param.upqc.n2;
param.upqc.core_area = 0.04;
param.upqc.core_length = 0.25;
param.upqc.mur = 35e3;
param.upqc.Lm1 = (param.upqc.n1^2 * param.grid.mu0 * param.upqc.mur * param.upqc.core_area) / param.upqc.core_length;
param.upqc.i1m = param.upqc.u1_nom/sqrt(3)/param.upqc.Lm1/param.upqc.f_nom/2/pi;
param.upqc.delta_star = 0;

u = param.upqc;
param.upqc.st = three_phase_transformer_setup(u.name, u.delta_star, u.pwr_nom, u.u1_nom, u.u2_nom, u.f_nom, ...
    u.eta, u.ucc, u.i1m, u.p_iron, u.n1, u.n2, u.core_area, u.core_length, u.mur);
param.upqc.ctrl.kp_p = 1;
param.upqc.ctrl.ki_p = 35;
param.upqc.ctrl.kp_n = 1;
param.upqc.ctrl.ki_n = 35;
param.upqc.ctrl.lim = 4;

% ---------------------------------------------------------------- induction machine
param.im.machine = im_calculus();
param.im.u_im_scale = 2/3*param.inv.hw.udc_nom/param.im.machine.ubez;
param.im.u_im_scale_ekf = (2/3)^2 * param.inv.hw.udc_nom/param.im.machine.ubez;
param.im.ctrl = ctrl_im_setup(ts, param.im.machine.omega_bez, param.im.u_im_scale, param.im.machine.Jm_norm);
param.im.ctrl.ekf = ekf_im_setup(param.im.machine.alpha_norm, param.im.machine.beta_norm, param.im.machine.gamma_norm, ...
    param.im.machine.sigma_norm, param.im.machine.mu_norm, param.im.machine.Lm_norm, param.im.machine.Jm_norm, ts);

% ---------------------------------------------------------------- DC/DC control
param.dcdc.kp_udc = 0.5;
param.dcdc.ki_udc = 18.0;
param.dcdc.kp_idc = 0.5;
param.dcdc.ki_idc = 18.0;
d = param.dcdc;
param.dab.ctrl = ctrl_dab_setup(d.kp_udc, d.ki_udc, d.kp_idc, d.ki_idc);
param.psfbc.ctrl = ctrl_dab_setup(d.kp_udc, d.ki_udc, d.kp_idc, d.ki_idc);
param.cllc.ctrl = ctrl_cllc_setup(d.kp_udc, d.ki_udc, d.kp_idc, d.ki_idc);
param.isop_rail.ctrl = ctrl_isop_rail_setup(d.kp_udc, d.ki_udc, d.kp_idc, d.ki_idc);
% special settings
param.psfbc.ctrl.kp_idc = 1;
param.dab.ctrl.ki_udc = 35;
param.dab.ctrl.kp_idc = 0.02;
param.dab.ctrl.ki_idc = 1.0;

% ---------------------------------------------------------------- resonant PI
param.spinv.pres_ctrl.kp_rpi = 0.75;
param.spinv.pres_ctrl.ki_rpi = 45;
param.spinv.pres_ctrl.delta_rpi = 0.025;
param.spinv.pres_ctrl.omega_set = param.spinv.omega_set;
w = param.spinv.pres_ctrl.omega_set;
dr = param.spinv.pres_ctrl.delta_rpi;
param.spinv.pres_ctrl.res_nom = s/(s^2 + 2*dr*w*s + w^2);
param.spinv.pres_ctrl.Ares_nom = [0 1; -w^2 -2*dr*w];
param.spinv.pres_ctrl.Aresd_nom = eye(2) + param.spinv.pres_ctrl.Ares_nom*ts;
param.spinv.pres_ctrl.a11d = 1;
param.spinv.pres_ctrl.a12d = ts;
param.spinv.pres_ctrl.a21d = -w^2*ts;
param.spinv.pres_ctrl.a22d = 1 - 2*dr*w*ts;         % legacy init writes it to apres_ctrl (typo)
param.spinv.pres_ctrl.Bres = [0; 1];
param.spinv.pres_ctrl.Cres = [0 1];
param.spinv.pres_ctrl.Bresd = param.spinv.pres_ctrl.Bres*ts;
param.spinv.pres_ctrl.Cresd = param.spinv.pres_ctrl.Cres;

% ---------------------------------------------------------------- SOGI
param.spinv.sogi_delta = 1;
param.spinv.kepsilon = 2;
param.spinv.sogi = sogi_filter(param.spinv.omega_set, param.spinv.sogi_delta, param.spinv.kepsilon, param.glb_time.ts_afe);

% ---------------------------------------------------------------- DQ PI current control
param.spinv.dqvector_pi.kp_inv = 0.5;
param.spinv.dqvector_pi.ki_inv = 45;
param.spinv.dqvector_pi.pi_ctrl = param.spinv.dqvector_pi.kp_inv + param.spinv.dqvector_pi.ki_inv/s;
param.spinv.dqvector_pi.pid_ctrl = c2d(param.spinv.dqvector_pi.pi_ctrl, ts);
param.spinv.dqvector_pi.plant = 1/(s*param.grid.emu.trafo.Ld1 + 1);
param.spinv.dqvector_pi.plantd = c2d(param.spinv.dqvector_pi.plant, ts);
param.spinv.dqvector_pi.G = param.spinv.sogi.fltd.alpha * param.spinv.dqvector_pi.pid_ctrl * param.spinv.dqvector_pi.plantd;
figure; margin(param.spinv.dqvector_pi.G, options); grid on

% ---------------------------------------------------------------- single-phase inverter control
param.spinv.ctrl = ctrl_single_phase_inverter_setup(ts, param.spinv.pres_ctrl.omega_set, ...
    param.spinv.dqvector_pi.kp_inv, param.spinv.dqvector_pi.ki_inv, param.spinv.pres_ctrl.kp_rpi, ...
    param.spinv.pres_ctrl.ki_rpi, param.spinv.pres_ctrl.delta_rpi);

% ---------------------------------------------------------------- devices of the other stages
dev = param.dev;
param.dab.igbt = device_igbt_setup(dev.used_device_igbt, param.glb_time.fPWM_DAB, param.dab.hw.udc1_nom);
param.psfbc.igbt = device_igbt_setup(dev.used_device_igbt, param.glb_time.fPWM_PSFBC, param.psfbc.hw.udc1_nom);
param.cllc.igbt = device_igbt_setup(dev.used_device_igbt, param.glb_time.fPWM_CLLC, param.cllc.hw.udc1_nom);
param.isop_rail.igbt = device_igbt_setup(dev.used_device_igbt, param.glb_time.fPWM_ISOP_RAIL, param.isop_rail.hw.udc1_nom);

param.dab.mosfet = device_mosfet_setup(dev.used_device_mosfet, param.glb_time.fPWM_DAB, param.dab.hw.udc1_nom);
param.psfbc.mosfet = device_mosfet_setup(dev.used_device_mosfet, param.glb_time.fPWM_PSFBC, param.psfbc.hw.udc1_nom);
param.cllc.mosfet = device_mosfet_setup(dev.used_device_mosfet, param.glb_time.fPWM_CLLC, param.cllc.hw.udc1_nom);
param.isop_rail.mosfet = device_mosfet_setup(dev.used_device_mosfet, param.glb_time.fPWM_ISOP_RAIL, param.isop_rail.hw.udc1_nom);

param.dab.ideal_switch = device_ideal_switch_setting(dev.used_device_ideal_switch, param.glb_time.fPWM_DAB, param.dab.hw.udc1_nom);
param.psfbc.ideal_switch = device_ideal_switch_setting(dev.used_device_ideal_switch, param.glb_time.fPWM_PSFBC, param.psfbc.hw.udc1_nom);
param.cllc.ideal_switch = device_ideal_switch_setting(dev.used_device_ideal_switch, param.glb_time.fPWM_CLLC, param.cllc.hw.udc1_nom);
param.isop_rail.ideal_switch = device_ideal_switch_setting(dev.used_device_ideal_switch, param.glb_time.fPWM_ISOP_RAIL, param.isop_rail.hw.udc1_nom);

% ---------------------------------------------------------------- diode rectifier
% ABB 5SDF 0131Z0401 (slow recovery)
param.diode.rectifier.Vf = 0.977;           % [V]
param.diode.rectifier.Rdon = 22e-6;         % [Ohm]
param.diode.rectifier.Cj = 0;               % [F]
param.diode.rectifier.Irm = -75;            % [A]
param.diode.rectifier.didt = -30;           % [A/us]
param.diode.rectifier.trr = 5;              % [us]
param.diode.rectifier.Qrr = 325e-6;         % [C]
param.diode.rectifier.Ifm = 2000;           % [A]
param.diode.rectifier.Vr = -50;             % [V]
param.diode.rectifier.Err = 15e-3;          % [J]
param.diode.rectifier.Rth_JC = 0.004;       % [K/W]
param.diode.rectifier.Rth_CH = 0.003;       % [K/W]
param.diode.rectifier.Rsnubber = 1e4;       % [Ohm]
param.diode.rectifier.Csnubber = 1e-12;     % [F]

% ---------------------------------------------------------------- lithium-ion battery
param.battery.nominal_battery_voltage_1 = param.afe.hw.udc_nom;   % alternatives: param.cllc.hw.udc1_bez, param.dab.hw.udc1_bez
param.battery.nominal_battery_voltage_2 = param.afe.hw.udc_nom;   % alternatives: param.cllc.hw.udc2_bez, param.dab.hw.udc2_bez
param.battery.nominal_battery_power = 250e3;
% alternative: both voltages catenary_nominal_voltage*1.5, power catenary_nominal_power
param.battery.initial_battery_soc = 0.85;
% lithium_ion_battery_setup takes the charge capacity [Ah] as third argument.
% ASSUMPTION (not in the legacy init): 1C rating, capacity = rated current x 1 h
param.battery.charge_capacity_1 = param.battery.nominal_battery_power/param.battery.nominal_battery_voltage_1;
param.battery.charge_capacity_2 = param.battery.nominal_battery_power/param.battery.nominal_battery_voltage_2;

b = param.battery;
param.battery.pack_1 = lithium_ion_battery_setup(b.nominal_battery_voltage_1, b.nominal_battery_power, ...
    b.charge_capacity_1, b.initial_battery_soc, param.glb_time.ts_dab);
param.battery.pack_2 = lithium_ion_battery_setup(b.nominal_battery_voltage_2, b.nominal_battery_power, ...
    b.charge_capacity_2, b.initial_battery_soc, param.glb_time.ts_dab);

% special settings for simulation
param.battery.pack_1.R0 = param.battery.pack_1.R0/2;
param.battery.pack_1.R1 = param.battery.pack_1.R1/2;
param.battery.pack_2.R0 = param.battery.pack_2.R0/2;
param.battery.pack_2.R1 = param.battery.pack_2.R1/2;
param.battery.pack_1.C1 = param.battery.pack_1.C1/200;
param.battery.pack_2.C1 = param.battery.pack_2.C1/200;

% ---------------------------------------------------------------- load transformer and RL load
param.trafo_load.name = 'Load Single Phase Transformer';
param.trafo_load.pwr_nom = 225e3;
param.trafo_load.u1_nom = 400;
param.trafo_load.n1 = 50;
param.trafo_load.n2 = 1;
param.trafo_load.u2_nom = param.trafo_load.u1_nom/param.trafo_load.n1*param.trafo_load.n2;
param.trafo_load.f_nom = param.spinv.frequency_set;     % alternative: 50
param.trafo_load.eta = 98;
param.trafo_load.ucc = 5;
param.trafo_load.i1m = 10;
param.trafo_load.p_iron = 2e3;

tl = param.trafo_load;
param.trafo_load.output_transformer = single_phase_transformer_setup(tl.name, tl.pwr_nom, tl.u1_nom, ...
    tl.u2_nom, tl.n1, tl.n2, tl.f_nom, tl.eta, tl.ucc, tl.i1m, tl.p_iron);

param.trafo_load.uload = 2;
param.trafo_load.rload = param.trafo_load.uload / param.trafo_load.output_transformer.i2_nom;
param.trafo_load.lload = 250e-6 / param.trafo_load.output_transformer.n12^2;
% alternative: rload = 0.86/m12_load_trafo^2; lload = 3e-3/m12_load_trafo^2;
end

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"onright","rightPanelPercent":14.8}
%---
%[output:7b3b50a3]
%   data: {"dataType":"text","outputData":{"text":"Device AFE_THREE_PHASE: afe690V\nNominal Voltage: 690 V | Nominal Current: 2.324276e+02 A\nCurrent Normalization Data: 328.70 A\nVoltage Normalization Data: 563.38 V\n---------------------------\n","truncated":false}}
%---
%[output:4194a2b3]
%   data: {"dataType":"text","outputData":{"text":"Device INVERTER: inv690V_250kW\nNominal Voltage: 550 V | Nominal Current: 370 A\nCurrent Normalization Data: 523.26 A\nVoltage Normalization Data: 449.07 V\n---------------------------\n","truncated":false}}
%---
%[output:5e8021e3]
%   data: {"dataType":"text","outputData":{"text":"Permanent Magnet Synchronous Machine: WindGen\nPSM Normalization Voltage Factor: 365.8 V | PSM Normalization Current Factor: 486.0 A\nPer-System Direct Axis Inductance: 0.00624 H\nPer-System Quadrature Axis Inductance: 0.00756 H\n---------------------------\n","truncated":false}}
%---
%[output:83178410]
%   data: {"dataType":"text","outputData":{"text":"PSM EKF Fully controllable\nPSM EKF is stable.\n","truncated":false}}
%---
%[output:65c69798]
%   data: {"dataType":"image","outputData":{"dataUri":"data:image\/png;base64,iVBORw0KGgoAAAANSUhEUgAAAHgAAABkCAYAAABNcPQyAAAQAElEQVR4AezdBZhVRRsH8PfY3V2P2Indhd2ILRagotjYrWB3dyd2oVgYYKEYGPioqCh2d9f38ZvnO3jdb3fZu3Hv3d3Lw7vn3DlzzpmZ\/8w7b82ccf5T\/demW2CcqP5r0y1QBbhNwxtRBbgKcBtvgTZeveoIrgJc2hb48ccf44477ojNN988Vl111UTOpblW2tK0\/rdVzAgeravEE088ETvuuGN8+umnceKJJ8Ztt92W6PTTTw\/gbr\/99tG\/f\/\/W3+olrEHFAPzDDz\/EuOOOG7feemvsscceMf\/888cMM8yQqEOHDgn422+\/PWaeeebmaJ5284yKAXiKKaaI5ZZbLkaMGBFffPFF\/PLLL9GvX784\/PDD09FvHWCZZZZpN+A0R0UrBuA\/\/\/wzjjnmmOjWrVtstNFGsdNOO8Wjjz4ayy67bDz77LNx5plnBjbeHJVuT8+oGIC\/+eab+Pzzz2PAgAGJTf\/+++9x7LHHRpcuXdLRvPzll1+2J2yapa4VA7DRiU1PPPHEMdFEE8WEE04Y4403Xqok1uy3PClhLH9effXVxO5XWWWVJIUvtdRSsc0228THH388ljv\/uXzxxRfHww8\/\/E9CPWfyLbDAAlH4Pp2TYPjTTz+laeb111+v5wktd6liAG7uKi6++OJx\/\/33x+OPPx5Dhw6NueeeO\/1u7vfkz1tyySXT873vySefTMknn3xy6qg0ggUXXDClNeaPjv3XX3815tbKMlWOHDky+vbtGxrmnXfeSUdCljTXGlXD0Tdh999\/\/32SyP\/444849dRT0wgn1DmXhk455ZQgxK299trx4osvjr4z0rx\/\/fXXJ06w8sorp+nCyEwX6\/iDC3Xv3j1ee+21eOutt2K33XYLXIWmsP\/++8fyyy+fZAvqn\/dK32effVIaVbBnz54pPy5Co9h4441jyJAh8dhjj6VyrLjiiklOGT58eJrW2AnIL8qHU1177bWxxhprpOdVzAiefPLJY++9945OnTrFmmuuGUcffXQ6rrTSSinNNXnqaNP\/S37mmWeiY8eOMddcc8XCCy+cJHOGkwceeCA++OCDMMrQ119\/nQwr0j\/88MM04hlVdAgPlQd7feSRR5KePumkk8bdd9\/tUr00zTTTxHTTTRfAyzMSFueZZ54Elve9+eab8cknn8QVV1wRRrjrOnehrKF8N954Y6rLQw89FDrb008\/HTqQZ3j2d999F0svvXQq3yyzzBKeO3DgwDjttNMqZwRPMMEEscgii6QRZBTVJNfkUaGGkFHyyiuvhJFvFOndOs1TTz0VG2ywQYw\/\/viJ1lprrXjuuedi8ODBKd3o05Hk9x6NroHp5dj8BRdcEMOGDXOpaFp99dXTPH3LLbckQ46O89lnnyXV0KjMsixmnXXWWHTRRcc8W4dXHvLJwQcfnPKeddZZccMNNwTBU0b2Atwoy7IYZ5xxQtnJLTpZjREcZfunpxqlW2yxRWI\/RhvWg7DMs88+OwgsjSmgyq622mrx66+\/Jv0auPlzsMjC33l6fvRODaujIKD06dMnv1znUX2MXqM4z3TllVfGJZdckow4++23X+Is+fwKGPnMtaYU54VEQNx9993D6N5qq61i1113Lbz8r\/PC+lQMwNNPP33cdNNN8eCDDwZACUhMlwjLVIPCgvvdUNKIWC3pXE8n9QIW3XfffWH04BjOpVHZsGTPp4djicBibDHXKZNrdZF8F110USy00EJp3s\/zYZ0bbrhhEAABprPgGNiq8innqFGjAufJ78mPX331VRjJbARGZl6+\/Hpdx4oBOC9g3pAAz9NmnHHGNPJcy9PGdnzppZdi\/fXXT0LJCiusEFjzIYccEltuuWVoIGwMzT777LHeeutF586dUzqwGVlykygWDnxH7NK9zmu+n1CWv89zAUegKszn3ccff3xioeZIMoJOTajSaZYfLXwRKtW38D7n5u6pp546cKJtt902dZ6XX345sWzX66KKA3jKKaeM3377LbEyvRxdd911gW3pwXVVpDDdHGbu1GjUFgIX4cRIwQWwXNeRc2kA6Ttagjcf33nnnXHhhRcGIF0zdciL8vyF75PvjTfeSEKO973wwgtJSJxssskCYcvKhHvoaEYrIM8\/\/\/w44YQTAofQ+Tz\/nHPOSfMo1t6rV69A3qV8JH7PVj6dUCfRmZh0zcPykcyVx7l3VhzADBonnXRSMF1uM9o4odeTbo877rhQSQVva8RIAnAag\/mVqpRzkKbWtWIANm\/lUiGJUY82GvR4vRx7Utk8j\/O2QjQEJlp1VWfSdnPVrWIAZpa85557EkvCqgqNCc6pMdiVPM1V+fbwnLIDzKDAyUBy3XrrreOoo44K0qxezEiB1llnnSQkse8SSNoDMM1Vx7IATNfDklisCAR0XwRIFhqqCcGI3okIIeaoXJBorsr\/85y2e1ZygLFbI5HCftdddyVHgHkHAZWEaETvu+++bbfVS1izkgNMEj7yyCOTY782tYda0aNHj6AulLAd2uyrSg4wsyHdUlgONYhJspCw6TPOOCMY0Ntsq5ewYiUHOK8btYfi37Vr12SiZNBnUWIt+vvvv5MHidVG2A67K4NHfm\/12PAWKBvApOaPPvoodthhh2Bh4kXhEzWy2WjZcaVxo\/GHcprTlRtetWpOLVA2gBn+eXe4yxQEAddvbNxcLc356qPdbPIXY4t2b5XKuPiMgMUVaATnsUz0YETCNqpzgIxoaTnoeXr1OPYWKNsIVjTz7VVXXRUHHXRQci5whG+yySbB38roz7DOQ7PXXnsF\/6lO4b4qNbwF6ge44c9pVM7LL788DjzwwBB7xKLVu3fvFLi22GKLJb+wOCRhKQwd0hr1knZ+U9kAFvHAn8lzNNVUUwUHQ5ZlwYfKq0KC7tKlS1qEZg6mUpmj2zleRVe\/bAAzVxKcJplkklRoIPNlApcuvPPOOyf1iUOc+0wcFR9pylz90+AWKBvAwBK1cc0116RoDWGyHOMiJhg5CGAELSSCQRgLQavBNatmTC1QNoCzLAt6r0hFzn32aWCah7Hvt99+OxXQH6oTcKlMflep4S1QcoCxZnMphwK9lvVKXLCQGiOVGZPqJOCb+oRYu6wbNrobXrVqTi1QcoCNTjFO3IMiBNmhsWMkmlJ4rCC3wYMHp2Wj4rHEVonUV+AqFdcCJQfYvEtwqis8lnWLgMVXvN1226WF34CvStHFAZvnLjnA+YuxZ7ZlgOdpwkU5GszH+fYNl112WQqE55jgoMjzNtdxzxtfj\/+jFk475cH3AtVVh29u6Rs5fXFBj8iprvz1pZcN4LrCYwWezznnnClgXASHJSN0Y8AzhtRXmcZcO+COhaLUtOXlHQKN3DKLmvRk15njtTsvHkODhrwU6Ml7bkrrrDhdiqln2QAuJjzWYjGep2Iq1tC8c936n6gkWvnGT+KD\/YfFU92HJBq5w50xaMN+sekDv6R1VkKXGlo3+UoOMLach76yXtUMjzWCWbFsvCLgDpmLrb9tCRatESqNui4zUxyy7pxj6IKuCza6iCUHeGzhsdbUWqZx2GGHpR4r6E68MJ8wNt3omrbTG0sOMD23Z8+etYbHkpbvvffeyLIsLUCjKyPLQjglLMBqpzg1utolBzgvqWiNvv9bC2SUIgKEFXbOrQ2iEyO6sPDaqqEjb72GH8sGcG1F5DWyTEXQHS8TwHMSCIC913ZfNa3uFqgYgJkvgetorwyWK1aunKqGjrpBrO9KUQDX96CmXmPwOOKII2KOOeZIbkKB8IXE+iVPU9\/T3u4vK8BG66GHHpr2sBK1Yb2slQ8Eq\/POOy\/tL0XvQ0Z1Sxg62jrgZQOYixBo3IUaebbZZgs6sDnXshX6Mud\/TtYrkcDlbc1UmwkyN0U29FhM\/csGMK8SvZZTwQYkojuoT99++21MO+20acdZ+1nkRABriajKmqbClvxdaIZkfmwstQqAgcWB\/\/PPP48pL5ZtVxvRHkJlx1xowZNSmimZIXPKTZDMkA2l61a4MlAxzVG2ESwElqS85557po1EGDL4iMVeCcYjNWPLbVWKZopkgiyG+u+5RKBWAbBCinlmubKxl8A65\/RdS0jFaA0dOjTtPEearkrRWqx4KtsIVlR7L9p3aqaZZgoWK+E7LFiEL5JzIbF6iewgiLm31GTxm9AhMoMtBUv9\/sa+r2wAi5y8+eabA4seNWpU2pfSBmU27XRNkJ39rbBp7kJStf057DPV2Mo29j73CcC3R4hN2WyDJGBBeqVT2QC2F5bF3qI4sGIRG7ngRd+1kSYPkuB3i8Htk2UrP9J3ORqVAMiFKVDBhqRWR5ajHMW+s2wAayig0XktURHFYXRIoyM75pURickAIj1PK+XRe5WBKue9JH9cxnmlU9kAFtGB3ZrX7ODG+a+xbKeLLZOiWbnMw7Z0yLfLbW6PkgVudqH1bmSOJwOI7LSLnGmDOmenW0DLQwOgqzuvdCobwBoGS7aoTGOJphQDDWysOd\/UmiVLmh3gpNvfw71NJXM8qxkZwIjMn2eutbMe0ynJ3QK5d999N+1jaVtiU4T8eYfM76vUY9kANhqMYKDx9W622WZpo1AStZAey1gGDRqU9scSGN+9e\/fUhs1lrjQqcYVNN900PTf\/Ix6bLu49fNZWW9gldt111w07yNpa0aah5If8nko+lg1gQorRID76gAMOSI1nk2sC1rnnnpu+seD6vPPOG4QaZszm9CaJ77LIzQc7coDM88rFkiYty7IUyUjKB7YRbRtf97neGqhsABc2Dke+9UcakSfJ\/GylAzXJPo5WQhjNpVBNjGzzbWH5WvN52QA2SrBjkRvUD3MdixZ1BPsGuLhoo0ejs1HThVuysXEKrJdRw3uED5l\/xWb73RqpKQA3qb5ZlgUpWfQkHZiOq3F94Yy50nynYW2D36lTpxQI39wSdM0KZFkWvFbmYdK0WGwdTZRnzbyt5XfZANZA3IUEGJKr+W+++eZLjgdCjMXgYqJ94USDM2li5e5rSWIuNT9Tkax2tE7KrvAt+c6WfHbZAMZuqShGrLhnwos1SQwfwmdzLxLbr41Z6MvYd3M3BgleZ8qfS3oWjG9LY04OIzq\/1hqPZQOYwIQlm3vpo1g1fdi8bLt6K\/\/zBWiOQnhamkW3RgDHVuayAcwaxNCRj0oqEGeC7xIxNLBk8RH7uAazpuuErbFVqHr93y1QcoDpuUyBvsEAXOzXp9+YJG0Gzh7du3fvsLUwF6GjwACqknv\/Xfzqr7G1QMkBpopgwUBkyWLrBbbfyDV5CGDUpbFVoHq9\/hYoOcDYLFchA78QHUJWlmVJDTIHC7oTAO\/7RYAnUdtx1hzcWuy\/9Td5aa+WHGDSM+BYqTgUgEbI8pFGdukePXqEEFpmQdKtr4RxzWHnXHalbZ5a39aqEksOMOkZC2aK5APeZZddQho9GNhCaK+++uro1q1bGOE5mYPZpltV61ZAYUsOsDoD0TEn7jeSslFL96yNXCNJWZawUwAAA9pJREFU5\/dUjw1rgbIA3LCiFZ+LWiVYIDeSOJrPi39SZd3B6GJXXlyOdY1gWlhC9baha2Fafl4WgG0V3LFjx+SKI0RRhRyZJm3fwKOUF7DYo\/m8kANY0JY\/g\/Ogtc3jQPV1msa6KEsOMA8R27JF3rWRa\/LkoDTHUe+2cx4hTvzX8OHDg\/7N3sygwmPkPcJ4Se9Gvp19+vTpEzqbUeMoj9FjxOgsdueT13OYWYHhumfamY8ThR+bjMF5ITJFGh80Zwrg7IOdq4NCh5H35CSkiFGIKzVPq+uIWykPWmKJJdIeYyUHuK7CNVe6D3jgBEg4kDBczyag+fAHD5VVjCxmwl81MFXN3pgiR2xKrpNpUIC5tzZyr+U1bOjitQmOHCPykvhxEnn4lp9\/\/vngUBH+O2jQoNAJsF1qoegVGoROwGrH9u4ZOcnv+xX5b8fCOqon45B03Ar3Uk8CLFt\/mwP40ksvHbN5iyUwPrGq8lyORsJ7772XVkvo5RqHE8NOtka1EF7AZlmWPi3LVu7e2ghAGlKHsUJShxk2bFjKavRQ9TguvN+0IMYLeMyzvFXmVNyCBw2wI0aMSJ+iremaBHzNchTWERcU7pRePPoPNZQF0KoR8kibA3h0Hev9z8giYhKoGkcgXf\/+\/VPjYrv5zcJ2sdX8d82jAATfEvYMZDT3Gc3Sa+bLf3uWSJX8N4MOMJhhcQzTA9uADpDnKfao\/PYzoW2wJ2RZFs0IcLSKfx06dAg2bcBqkAEDBoQ9Qfh8sVBOfulYnc7AB20kivqUbk5UUaPDqDTCAMVfjVW7VhvpVIAENGcKvV78F0OO+Z1sgKvUvJd3rb6pojC\/aUB9sGZldq3dAYwF+wgIQUlILv26V69egVUSprA7kjygsUbs1G\/RlCRZczXQ+ZGB5oj9c2U616i1kXXOWZaF0GAhwAw92Dj9P9co\/K55r3eQI3SumtcKf+s4Ru\/777+fdkzQWQh7bQpgps3aGhmAKG8Qcx\/hyAjs169f+jBXlmUhhNYyGqMXi9OoWZYFB4g5d+DAgWFzVMH5RohRKB1h19K8Xznyd3mvNJ1F\/BmV0Hu9K8uyIEETtDp37pz2B8vvy48kbiPdqPcM5fW8\/Lqj9ymLa+QA5Uc6b5sCWGVbE2HNgMYRxGjXVnag2iDdHK3D1ZanvrQqwHW0DumXNFrH5WZJpu8LcsAR6hOuSOX06izLin5vFeCim6x13VAFuHXhVXRpqwAX3WSt64YqwE3Gq7IfUAW4svFpcumqADe5CSv7AVWAKxufJpeuCnCTm7CyH1AFuLLxaXLpqgA3uQkr+wH\/BQAA\/\/94atjNAAAABklEQVQDABTSs6z3nFhAAAAAAElFTkSuQmCC","height":100,"width":120}}
%---
%[output:4ab8b4aa]
%   data: {"dataType":"text","outputData":{"text":"Single Phase DAB: DAB_1200V\nNominal Power: 250000 [W]\nNormalization Voltage DC1: 1200 [V] | Normalization Current DC1: 250 [A]\nNormalization Voltage DC2: 1200 [V] | Normalization Current DC2: 250 [A]\nInternal Tank Ls: 3.819719e-05 [H] | Internal Tank Cs: 1.151294e-04 [F]\n---------------------------\nSingle Phase DAB: Three_phase_DAB_1200V\nNominal Power: 750000 [W]\nNormalization Voltage DC1: 1200 [V] | Normalization Current DC1: 750 [A]\nNormalization Voltage DC2: 1200 [V] | Normalization Current DC2: 750 [A]\nInternal Tank Ls: 4.000000e-05 [H] | Internal Tank Cs: 750 [F]\n---------------------------\nSingle Phase PSFBC: PSFBC_1200V\nNominal Power: 275000 [W]\nNormalization Voltage DC1: 1200 [V] | Normalization Current DC1: 250 [A]\nNormalization Voltage DC2: 1200 [V] | Normalization Current DC2: 250 [A]\nInternal Tank Ls1: 3.030303e-05 [H] | Internal Tank Ls2: 3.030303e-05 [H]\n---------------------------\nSingle Phase CLLC: CLLC_1200V\nNominal Power: 250000 [W]\nNormalization Voltage DC1: 1200 [V] | Normalization Current DC1: 250 [A]\nNormalization Voltage DC2: 1200 [V] | Normalization Current DC2: 250 [A]\nInternal Tank Ls: 2.580123e-05 [H] | Internal Tank Cs: 4.734509e-06 [F]\n---------------------------\nInduction Machine: ABB M3BP 355MLB 6 261kW\nIM Normalization Voltage Factor: 375.6 V | IM Normalization Current Factor: 581.2 A\nRotor Resistance: 0.00274 Ohm\nMagnetization Inductance: 0.00376 H\n---------------------------\n","truncated":false}}
%---
%[output:6debe77d]
%   data: {"dataType":"image","outputData":{"dataUri":"data:image\/png;base64,iVBORw0KGgoAAAANSUhEUgAAAHgAAABkCAYAAABNcPQyAAAQAElEQVR4AezdB4weRxUH8Pk+WkAU0wMEcOid0EMLDgQIPfQqMFWhg0IXRaH3LkKopgdECUi0AMKBUESTSeglmCpCNR0Eifl+47zL83r3dvc73\/mcnOX37eybN2Xn\/+bNzNvZuen++++\/\/aCDDtp+yimnbPfvM5\/5zHY8FPwTTzxx+7Wuda3KF08u6Igjjqj8+973vtv\/9re\/bT\/qqKPqfaQl15U+ZJUV+aqHtHjKlDbzxLmXrzTkUPAzT5gcinqGHF6Tcn2Ec7y8lIPkJY6MeyQeTxtoC7x56u95pZM+8pRvk7Jc1CfLRN2mZfbvl7\/8ZTnwwAPL5S53ufKIRzxixlm+\/\/K\/3\/3uV\/7+97+XK1zhCgsF4StfPdRnIWIWuNjFLlae9axnzUKliCNDVprKTD+HHHJIudvd7lY54smhD3\/4w5U3a\/wiv3rT+HnAAx5Q2wH7pS99aW0PaZG88C996UuXpzzlKYIly4snNwOnfPWrX63xj3zkI8s1r3nNWp5yMfvqT2YIfelLXyozZaqihx56aL3mn5ve9KblfOc7X5m+6U1vyvzaOPEAO0Us4cZD3vrWt94lB2C0ld\/kSdgmq55IfKaXv\/zlpZmHh\/3oRz9aDj\/88Cy6U\/i85z1vee9737tL2hBS1vHHH18Bwwv5UCi8IOXnsoTxIt5VOnkKjyGd4wtf+EJNQuEoVb1JPzMLUK5+9auXqYY7+eSTS5DG+clPfpJES9XCb3\/721WGfI4kL62G8cAexH1uCPIhJy5k8eWHF0QueMqkHORQ8ENWWch9s7ymbDMv+XVRM638kbLa0qiz+EzyaMriZRnpxrR15KedtaG8ms\/dlJkyK0zmn\/\/85\/LmN7+5XOc61ykf\/OAHqxztuOhFL1rDaz\/zt8BJJ51Urn3ta1eTr631QLnhz8ZZwXKDG9xgwTJUxm76qWOwMeN617teedGLXlT+8pe\/lOl0Ws5+9rOXb3zjG+WEE04oa\/+W1gKsUAxR2ppJ1bHucpe71HHU8PGgBz1oaYV0pJ62jQF67mc\/+9k64dCb\/\/e\/\/3UkX2MPbQHmuKut9WJKMDSvMXJT48r73\/\/+OuN65zvfWcdZdv0yl7lMuf71r1++9a1vld\/97ndj8lyT7WgBbW3czKStu2b1HdmMYlcT\/etf\/7qa5Atd6EI7Jb7KVa5S\/vrXv5Y\/\/vGPO\/F31822bdvKtgZt3bq1bE20ZcuWsuV0Cr40S6zDWSZ5Bfi3v\/1tMTO7yEUuMvrB3\/GOd5QmveY1ryltdOSRR5ZMbTLNvCxtgiJOOvm44rFARx99dNm0aVP51Kc+VRVi9IOcSRNUgJfybNGr8lUPa6PFyomZ5WIyzThlKPcHP\/hBoaQ\/\/OEPC7Cf\/vSnl4MPPrjc\/OY3L9e97nXL1a52tTqDNbHZ2+lnP\/tZsxkWva8Am8X961\/\/qjPoprTZ9NnOdrYme+EeMOvWrSvrWmj9+vVlfQsdcMAB5YAGGe\/\/\/e9\/F2AtRgBFAAXwQkVmgX322aeWx9OF9ttvv3KBC1ygXPziFy+Xvexly41udKPy7Gc\/u\/Bqfe5zn6vzjTwe7g3hW93qVrMnHf6\/Auzh\/\/Of\/9TxMCfV0Bpn3333zeydwh\/60IfK4x\/\/+FYy9W8jywONrVzr782bN5c3vvGN1cUHuCYpUB0oxb3vfe9a1nOe85zyqle9qoaVcYtb3ILYAgHbHALQ62dKJkK+TPoTn\/jE8pCHPKRwHzLrW7ZsEX2mpArwla985XKJS1yicH\/NHNb1QfXML3\/5y+WGN7xhueAFL1h5S\/nRuBpSg\/LRalwNrcHxc97A5Et96lOfWkF83\/veV6\/3ute9yqEzvyugyUhDQdbPANywYUMBunTixSFAiz9w5mt3xQtSJ+WrB5OuTurXrE\/Iu\/aZyK74Nn7m9YVzvHoMpQowb9Vhhx1WTFSsx\/bff\/+6Bv7e975X7n73u5fJZDI0vwU5jaehNJgG1HiuGpRlWBCcBYAFFD1RrwTo85\/\/\/BJgzkTqf\/WqgfTT5HEHshCsSu7VTaD17pRNDaqz+qlnF+DN8mrC9NMV38bPvL5wjk\/F9Qanv\/\/976vQec5znqL3Ip6sc5zjHMW43BznqnDLj8Yxg33JS15SNFAGFNA5SQYUmAiwGzduLIDOsvOG161bVzbMenUX0N5k6fGf\/\/znC8VqK9cz9QE+b\/1WKt3Ua6c\/\/elP5Zhjjin3v\/\/9y3e+853y05\/+tDDPN77xjatfusuTpQEufOELLwAKXCAvBiggM6DAXs6H7QLaEHT88cfXZdv69evrEABsdRsLOCulLZbzOebNe6piAOXsOOSQQxbM8bnPfe5eTxZwrJ\/HAKqnDBlP2mSG8LJMhF0DaK\/osunWcAH05tlkjylnSSjiUMD1chYLmV8AvNkm6qCsTJnXF87xOY++8JQpBq7l0DyeLL0b0MbL5qRIQwG0rxIrGU8hme4HPvCBpQ1ozhNAx9Dk2TxHAG4jgB6OmvXWWcwvAG6YyuO4NXpTfiXup5wBKubB5\/FknXLKKYVZAy6QhwA6ZMLQJjOEl2UiHFcNmsOANg4DWg8Xj\/RoQAMqgMZHXusBHEUP9+wAb3t2bSsfw1cALqyXe3MnT5Tr1RbOPPJDaXqlK11pqGyrnB7cGrEXMQEdk7EM9NatWxdcrk2TG4+nh1NsgOvllN11McDNU4CulzPrrgDvKiPKmudal0lL8WQp1Pgwhr74xS+WPvk2mSG8LBPhuCozwr\/61a92qQPHy53vfOdy29vetvrmPRvSi\/nDX\/GKVxRv3OTTRT\/+8Y+r94xVeNzjHlfe9ra3FWZd77V8k18mPRywATi5u971ruWZz3xmefWrX71QXtQ7px0SrgB7sHk9WQphPsaQYaFPvk1mCC\/LRDiuyowwN6b7Njpw5hQ54ogjqpcsm10zb8B+7GMfKz\/\/+c9LW9rIP8cx61ykT3jCE0qY9cV6OYWyuqFUb3\/728sznvGM8oY3vKEYOgyl2nwoVYBXwpM1tEKrSY651uuY7ww0ADS2cdqEbGydmXX5hVkP0Jl11MxPL0d6uWWpHt+U6bqf0kqeLB6rt771reUtb3lLsVfIGxkbwu5xj3ssLJ26MhnL1wv60rTJDOFlmQjHVZk57H4IZaDtrYo0AfSRs9eggHbflX8bP\/M4lQCOmPUYyykYZYgyzXnyffC7rtN3v\/vdNY6Tg2PjxS9+cbnTne5UjjvuuPLgBz+4br2sAmfqn2EPB2gA69HG2JwqejTTCugcN084ejmAmfMAPc+8h+Rbt+wQ\/MhHPlK+8pWvlMc+9rHl05\/+dPVBv+51r1uWTXfGJ2UuRm0yQ3hZJsJxVV4Oux9L0gO6a+bNacR0o2xKpWuWlXl9YfFAZ3Gb+Sx2X8dgrsr3vOc9xdsa2mlM9iWBN0lrm+66m28xoPVikyRAM9\/duSxvTAWY1vFmeRMzmex4czTEVTlv1fLY05VHm8wQXpaJcFyVlcPux1JX+ujRXKF5jAQ0822J1QQ659UXzvFj6lwBBu68rsoxhZ0VZC1jjJssYR6nmVZAR48G\/Eq0RwXYFFzF5nFVzlNJ40lfujaZIbwsE+G4KjOH3Y+lvvQR3zTfUQ5gA2hraffiIl1XOMeTGUoV4KHCXXLMx95GbZ6s5XgGO044kphuM\/DchgE08+1DgyHl5\/RDwhXgpboqadcYUrE++TaZIbwsE+G4KjPCi3myyHVRpB8bz0IedthhdVsR062Hywsx35ZX4SHDi\/wjnK\/CQ2n6pCc9qe44XIqrcmhha3I7WqBvQmbXZ3NCtiPl+N8pH6llUeumu9246S5XjXbm+7Zwm8wQXpaJcFyVk8Pux1Jf+q74Nr79b30TMuO0Oralx++j6fnPf\/6y0q7Kvkqd1eKZ6+jVzHc8vwmYcTq7QiNu6LWOwYQ3btxY91b5Ct1YYW382te+tlzjGtcQvVvJZKIvwzaZIbwsE+G4KjOH3Y+lvvRd8W38zBMOoE3IMtDqCGhLLK8yt87eU+MNoQWAbd15+MMfXr7+9a\/XTXef+MQn6tbZMuDf2M9B7M7vS9MmM4SXZSIcV2VGOK54Y6gvXVd8Gz\/zcpjZtjHf2yMnE5iEBQzclREecp3mL84lMOnywE2+uDZaTZ97tH1\/693uiSeeuOyfqUTZvq32kffQdtFbo13b0vri42tf+1r9wM\/bPTtAUaTpu05V5g53uMNe\/Q0wDaeQdk40H9jz+aLeOrMZt6fvfXfNYkY9nMBDGeO+efXVRtv74qZcvq8mWsam5jlibwoDEamzOUT0Hs5+a3z85z3vecuqxIcffni1EsbKoR90a3Ntr35B9mtFeHdcp9EAun8zQ5vgeV+YbKSX6C1ZLky6+KC23sLURHxc8XJewtJGvKvJBk0X10XRKMwxCjnLEPuU3ZuR2gEqjOQpb2UEtT0fWfUMGVf38dyRBk+cPOUt3WKkHX0LRsZxR0hYj+5LL145ylNu1MU90obyQrUHCzRJj1D5OGxLPJ4Dv1QOiaeF4jKRUXDwVKDNfOKJy3LSxr0rDXeAiV0m7hej7373u3UjXZaJnmWyAnBx8pKnvN0HeT5m8KSTTgpW\/epRPRcYs4D7tueeRQ3+b9asvhIYIpGwOi1mpslkaquLNoz2nwaAvtXJCYVNHMLcxWRAI6BcwTY52kkJNKZDRuSXzWfkFxpL66LRIj8PqkeqoxOA5CefJtm2ikfODJQWo3hIcUHykBfZPKkJc44vnpy6H3XUUTWpeqiP9lC\/ylzCD9ekslhQSoWEZRkWSbiPpFF39YKLZ5LGlh89vfZgzGhwkajJi0YUh\/QGvULGegleJq8g\/\/nPf2ZWPSYRkJhOnZE2xqwYInK5\/LeWC+RpO6USbpL32G2NTrsBjaJcjYDkYVNDjJeeJ8x5lJVBsEdNfaTLRxi6H0uURweQjmnmpULCeKH0wn3EEqk7Oc9in7VwWIIpzfz4xz++yyFcl7rUpYovDgkjH4LTFuEgFWWmNWBQ9MKQkc4CPu6Zj5DN5jkAVjF1Chny0tL2PIbiZaJkFEYvkz7HCcsHyFGOZ1E3cUFhxZplqX+WBfQlL3nJSDb6SlEpkYQHHXRQ3YMtT2E8beA5hPuo2fHiGSLd1JF4Mg\/G0Kvub9zQGzRWmIlmT6JVFKit0SmDyYK8hpbbJ+dZPBOwkWEh0owxfdKEMgjvTgrLIM9sZYTx0Ni6StNG1US3RfTxgEPTmFRjbJiJZqN885vfrDv7c6Pn4UAeWVspgnvgNIkpbtYrWxHWxH2WsQZWx+CFhjd7qfiou90tFJU3D3\/btm0lWw9l\/OY3vxE1miiz8bEv4VAzHXWWnzo997nPFazkE+C5Aa45zH7yw5uUAHvGLqeeemrhy37oQx9abM1lcplIccZfPV7Pd4\/C1LAICA8x49J29XQ9NsyldEi6oFBE98ClQMh9Xhure0yoHFnhkBZfFfgYnjLExEs6z9MsB38IUV5KTZYSNZU49jyizgAADThJREFUlJ8MWXKLkTqrOxl1jA\/6tYlhoBdgYGhkGWRyiMo5z3nOetZizFxdNQa5yWRSD+DEi7HcOAgshE9WYyO9Mx4uywFIfiYPzL1wkzRU9NKcVjlh9pRhcnSuc52rOL7BSQYaEZ9c1IdP\/lGPelQ9l8QzXv7yl6\/FAZQ1IBt51oiRP2F6KbeZczN5KDq+vdB5oqrTODD2dre7XfnFL35BZKf2NxR6ry\/iMY95TPEsiwLsXeQnP\/lJ8ruQ8zs0Uo6Qoc1meGbRTsjzrQ5HuobEzwRQplsvxKdMeczE0xB6u0mU+zYCvNk4oNvi5RnlfOADH6inGTzsYQ8r+zZOD6IkPvIKd+CPfvSjctppp5X73Oc+O2WrHHXfiTnghnlmeomaMZs5C2cyoYtjq\/RAGES8Hm0TvLK9v8cnmxVFW3oD6Hsm54PtArBGtkeI6fClnRmfjIyxsSxyuJh91HqV14pkVcaXEcIaxjVAAbwGxsukLHln0pOzjDKVnWW6wma6wJ5Mdmz91RDykqc0ef+3BjBGqbfZq685mGXpfUZCKbxC9YXgC17wguqGlBdiCYx38gzyrOIomjyCn6\/44slpD2BEvA8PdALHROmp6u7ZDU3SOPmXxbF3nXJqU2kppQ\/3o80pga0\/5j7CuwAsEQ2wRnzZy16207H74hBQ9VANN5nsaMzl3EetzCG0O+oNOJM1m\/L0VBaJmc7DFHON1IlyZKDw5qF56q4ce8scGMtkU9rvf\/\/72HWIoTCtAF\/xilcslkC3uc1tSttWWuCaadKckv4Z25bz8NJUVGtwd9SbCb\/ZzW5WD2ehwBpJYeYCxl9knMfTe\/Q04aXSvHW3G0eb+2aJ5WGRDJ12c\/p0phXgvsqu9D7qvvoMje+rt6MU9QbnXTKNt7\/97YuenL9UiLIAb1LD7AZvOa99ddfhnvzkJ9djGo3Jd7zjHQsFnQvgMQ+ikLaxdkweKyW7zz771C\/qvWDnSgzSe42bmZpj6ErVUTmUyrisPmbUeMjSSL3MLThTzBXmAtjMljlgFpgBRMPc0yQzOwWuNsr1btZtNddbXeet+1wA26lvvcXJ4cQYh4iYUb\/+9a8vdmnaBegeX\/ymTZvKphlZA1IGFd4TlOudy3f0kRl4c9mUZfZ0eN66zwVw3ket5zYf3noPH5hAtXkMARvoB59+lrNllSUXsmYzgdkdxCFhlsu05vycjcW5YimS+a985SsLkB1pnPl7ItxXd+d9mERpcy5T5thnvrxveE1aAPi\/\/\/1v\/bM6MvBgnBPGoGYC92ZuceQDZwbHQNChp58G2zYxkTaISTTmOc8Z6UG0lPfIZnzgGGOWi6x5h+a9muRgM+aYjQWALQ94SRzlwHuloa39mOEAJV83nr6PmhYJBzkUTD7I4SKIc929OIpgltelAHq+3q6nM\/NMO56yw+kiHNTk5fsIx1WaHHY\/lvrSd8W38TOvL5zjOWGG7l2vAGcPj4U9E8zRoetbnzm3o9kQPCn2UTf5bffGNoDq3RTBUcEAz+ADnkxOD1hgAxqZOeZ44aa7L99HOK5t8nhjKOfVlq4rvo2feX3hHM\/dydnkbZflWls9glcBJsx5YUkzmaysZyrAB3yA7grwqKRrBluvxluj\/haoAAPXmLhaPFN6MsCjh+v58ShrQEdLDLtWgDUaf2qbW3JYNuOk8njSlTJk9HBjt3HcK72QV2fm+573vGcxWw9+pHMf4bhmnvA8lPNqS98V38bPvL5wjm8rt4tXAe6KHML3Ev3YY48tx87IC33LE+QltEq1EfdfGz\/zmjIcK\/6+onexGeg\/\/OEP9aM5G+aMTTldhOMq\/wjHFW8M9aXrim\/jZ15fOOKHYJJlKsDzeklkZEbstRbiHnPGFrLMcXCnV1fIksu7TaS8yWTSetajyQTyHtk1E55lnDMf9ehsuq1jvf1Rrjdb0pHP1xz2Fsb9WIo8u9J1xbfxM68vHPHafAxVgK0\/wzOVE2s061NmMvMj3LWEinhXMsgnj2bByAt85pXHyyeR7jdv3lzISDOE1ClMtzE70jDXZtyIkyX4Z9VrBdiySINpbD3EYnrDhg3F2xJLpQ4vSbH7IP5uklkvYj69iUEa3pdw5LoaGPhAAXwGnckXl9MxpflemOk260aeAQ8Zo3nOAO1YXvf4bXngD6W+9F3xbfzM6wvn+KF1JTfl9uKZAioTe9WrXrVulsO3S8DL7slkx9JJgiZxdAAQkAioG2bKgYANdGtrJ6u7InwKQL6Zn3vAMvkUDund+Myia6bgKZfZBrRwyACWhQA0okhLWWZFeZF\/89oV38bPvL5wjm+Wudj91ODN0cE8msTYEQAE45itMraKOOF0sUyGxlEEBAAKAPwAXrgNdGADhTkHtPvFypM3kIEtzywLbFYC+WIC4DxmAGdFxGf5M0N46gtCjg5bVUxezETdG784PrwA9\/JgOR8W6HpzgE7BHFUA8FwuoPVoAAXQTdMV98x1rKUB3gRbvgAFrPwADXAvQlzdAx5pC3LkI3\/p26grvosfeXTFBz+uIT\/0OjWrXWlHR19lAW5yB3BgAxovHoq1ATTTa4gIfvMa5XiZEWBbZgHbMKG3N9O4ByRAAY+M5QAHfPR8YTxxlCDIMCetPOS1GEX9mjJd\/KbckPs6yVKZlXR0DBlPQgawATRg3MeDaUjLIqY7eJHOfYTjimcSCWwA69lMOZI3Ajoi20XaCylf76YEQQ5VBzwFYA2QsA1x+CiUgkWSXj42S0R5ub4RjmvIDL1WgIcK72k5ZlyPBkQGWkPp0RnooXVlyhHQEdBRuEmBbzmmTGTtTQGkGVoGZUCAREANhQA20BFlQBQC4YkP6yCtV6xDyyVX\/zAWx4PlRtYikYiPum8LDpMyhmwu75NvkwmeGb49204fUEdkTAa0BrHEkn\/IxzXzTC7dL0baBFlGGibQTW5yk2Kv9Atf+ML6F1V8fcDsI4rgL6awDkEcQXabZoVU38WIMiCAZmUAuKFL3GLpc9xU5ed1dERGzMcYGuJFapNp8rwTtUtDw0dd7Iy0xOI9sxnBGj6ni3Bcx9Sb7H777beLB47ZR3q3DfQmq0Fejfp+yK4RVgGxCohCBFGIsBAUostCWNF0xUUb5GsFGMg+heBO1DsImLz0bQchNw9pqL50bTJdvBijM9B6NKCZbmAz33htefTVJcf3pe+Kz3wAIQoRRCEMEQCnEBQgK4NhQ9w\/\/vGPXJ3e8JSTA+kNRx99dLH2VRkvkn1\/ZGvOZNLt6OgtYYUEmMA2oBUPWOYb2AjYwBe32okiIOM+ZfAsY+pcPVkS+AJQ70U+mbRjw\/gzNkN59ZFxbx6ZtnRNnh39gOZAMf5pmFyW5wE2gDlPAG7CA3RkCZblm+FmeUPj29JlXl84xzfLXOx+wZN1zDHHFPuxwvHBPNv1uDf\/UQ5uVmObz0uYb9RsDIADFegI2IBHAb71NvCRD8HJN\/NZrfcLnizODp6ryWSHOeaqtI10OTxZhoC+BmmTGcLLMhE27OjVSM+21DIDB7ilV1ddAnyzWeAjr0KbSpAVgeOIIiDpKAMy2WuWE\/XD7wvnePJDaY94soZWbrnkjNcABriZa4AuDHQEeNRXB0qAgAhQShCk51MGRAnCKggjfDKUAUkvH9RX7tD46uiwrlpJT9aQ8aRNZggvy0Q4rholh90HAR2gQEfARgG+Xu\/euE4BkPFdGmkjn74rZQgCJFDbFIIyIN9qUwTHRlACZfaVkeMrwJkxT9irxjFkU32ffJvMEF6WiXBclRnhuOL1kS8v0C1vect61hd\/NOJ4AEL0RkB4P46Ycn5pZEKHHJiiMyHL0CFtTY4ieAFEEVieIelCZsmerDN2\/Z+801fwZ1W+r+qRSepxxx1XEH85ete73lWscZGP65vWgYUwKWQdEOuAAizXMdaCfHV0LNWTJaM1mq8FAIYAiZhgQwQCOKIIyDBBAcaUVAFeaU\/WmAquyZ7RAqEIZ3D6QwueLB4rr7rGfNjUn\/2axJ5ugYVJFj+oScOYD5v2dOXXyu9vgQWAuSZ9TBZbdoZ82NSf\/ZrEnm6BBYD3dEXWyl+eFlgDeHnaddXkugbwkqFY3RksO8CO1HMkw+puhjNqx3P0tKc9rTjhwD5xW3Ecb3GGxOoN2frsXE11t7XIwaXLBrCv\/uxbevSjH13yiamrt3l21MznOkInnHBC4fv1+pRXCm+1E0DtJ\/d1p5cYduj0AuwQM2d1NB+OVsvQXiS+XL5dW0xsGCBro57XjTahuV9pmrfe\/L4OF7OqsBnR\/ihfe6xk\/eetu\/fePF2TyaT4mBAWiwLszYsDWdoeru3QFr2V5pP3\/tNZl8yc+5WkpdTbvid+YPX1bRal5T50vxK0lLp77+0Mb4epOiTV0VStAMfRtjYAKLD5YL5lcpywo235R7k649CWPbkDZHfV21YlDh\/OH1tkjWnNNtjd97ur7l77Os7Q3MdLj1aA5znadjl3gAxtzN1RbxMVPcC+aeOxbbCTyY5dLkPrMY\/cUuvedZzw\/wEAAP\/\/Ul2aSAAAAAZJREFUAwClviRaeUEIDwAAAABJRU5ErkJggg==","height":100,"width":120}}
%---
%[output:32ef08ab]
%   data: {"dataType":"image","outputData":{"dataUri":"data:image\/png;base64,iVBORw0KGgoAAAANSUhEUgAAAHgAAABkCAYAAABNcPQyAAAQAElEQVR4AezdBZAdRfMA8F4+3N35F8HdXRPcCe6QoMGDhqAJ7lK4u7sEC5LgrqFwSHB3t\/93v6ma1Mt9d5fT994dL5W+fTs7uzszPS3T3dM7xv\/X\/nXpERgjav+69AjUENyl0RtRQ3ANwV18BLp492oUXENwFx+BLt69GgXXENwlR+Bf06kaBXdxVNcQXENweUfgp59+iltuuSU22mijWGGFFRL4rcy18ram87+taii4ziAcjz76aGy77bbx2WefxbHHHhs33XRTgpNPPjkgd+utt4477rhjtKP+6quvxpJLLhnLL798miCLLrpobL755vHJJ5+M9t5c4bzzzosHHnggnzZ5VG+uueYa5X1HHnlkavPPP\/8cBx98cLz++utNPqOjLlYNgn\/88cf4z3\/+EzfeeGPstttuMeecc8bUU0+doFu3bgnxN998c0w33XTNGouFFloo7rnnnnjkkUfimWeeiVlnnTWdN+vmVlRaZJFF0vO977HHHktPOP7442OcccZJk3XuuedOZa35Y\/L\/\/fffrbm1ekyVE088caK6t956K7788sv49ddf45prrkmz39G5CbD44ou3uKN\/\/PFH\/PDDD2my\/Pnnn3HiiSemd6Fyv5WBE044ITx\/1VVXjRdeeCG9x+BeddVViRMst9xykSkzXWzkz3jjjRe9evWK1157Ld5+++3YZZddAlcxiffdd99YaqmlYokllgicyXuV77XXXqkMl9ppp51SfVzEZF933XXjySefjIcffji1Y5lllol11lknhg0bFl988UUSZ0cccURoH051xRVXxEorrZSeVzUU\/Ndff4VGbrfddqnx22+\/fTz00EOpkU8\/\/XSceuqpYbAbGdP\/KX7qqadigQUWiFlmmSXmnXfeNGnI9HvvvTc+\/PDDQGXgm2++STJf+UcffZQonrw3ITxUHez1wQcfTCJkggkmiNtvv92lJmHyySePKaecMiAvV9SP2WabLSHL+95888349NNP4+KLLw4U7jqq\/+qrr\/ItoX3XXntt6sv9998fJtsTTzyRJpBnqPj999\/HYostlto3\/fTTh+cOHjw4TjrppOqh4G+\/\/TbNxkGDBiU2jepQS8+ePRPVkMulHdexpgCVvPLKK\/Hee+8lKjK7Dz\/88Hj88cdjrbXWirHGGivBKqusEs8++2wMHTo0laO+iSaaKFGD5xt0A0xkYPNnn312vPjiiy61GHr06JHk9A033JDYtonz+eefB66FKouiiBlmmCHmn3\/+kc\/u3r17aA8Od+CBB6a6p512Wlx99dVhTFQkynCjoihijDHGSG3H7UyyehQcFfuHOnXCAI877rhJdo055pipPRpLlqmTClr4x\/0rrrhi\/Pbbb4n1Q25+BBZZep7L85GSZGBNFAApAwYMyJcbPaI81IuKc6VLLrkkzj\/\/\/KRf7LPPPomz6BP5CjHq+W1y+10KFMRdd901TPJNN900dt5559LLo\/wu7U\/VIHiUFrbziUHEak0cM53WC7Hg7rvvDtRD9vqtDDfBkjWDrMQSIYseQIzQ9l1rDNQ799xzY5555klyP9fDOtdee+2gAEKYyWJCY6vap50jRowInCffk49ff\/11omSyF2Xm9uXrjR2rCsEoZODAgUEOvfvuu+loiaHMtcY60VD5Sy+9FGuuuWZSSpZeeunEmvv16xebbLJJGCAsG8w000yxxhprxHrrrZfKIZv8z9o6Fg75jtile\/2u\/05KWX6f50Ichaq0nncfffTRiYWSkXSE6667LihVJs1SdcqX\/k4zzTSlt6XfZPdkk00WONGWW26ZJs\/LL7+cWHaq0MifqkEwObPnnnuGQVx55ZWDvHRcdtllU5lr6jTSj1GKyTCy06BZtlC4KCcoBfvCcl0HfiuDEBOJPL711lvjnHPOCYh0zbvVBbl+6QvVe+ONN5KS433PP\/98av+EE04YAFvWJtyDDoBaIfKss86KY445JnAIk8\/zzzjjjCRHsfY+ffoE8C7to\/F7tvaZhCaJyWSVQQ6rRzPXHr+9s2oQPPbYY8d8882Xlikopj64po6GdzVgJIFwk5l8tVTKHKStfa0aBFNKUMrGG2+clkmWNEyUwLr09NNPDwpPWztcjfebvFYPqBsHoG23VzurBsFTTTVVkEf33XdfQCgrFBYLrEt1GLt0rEHzR6DiCGZQYI0BfmdtFcJzNygdNFPXclnt2LwRqAiCrfWwJEoUhQBbBquttlrQEIcPHx6WGZYS4Morrwxrw+YqWc3remmtrvu77AjmFWKhsmC\/7bbbkiOA3AG0XWVYNFa9eZ0HyNKCCfGoo44KmmTXRUXH9KzsCIakQw89NNicSykSC2Z6s6xgsYFgSKd4WEpYAxoCdRxr0LwRKDuCmQ0pSzxGKJS2DLBnhgIaJQMB1py7gOrZiq0J77zzzlxcOzZjBMqO4NwmFGnhv8UWWyTtmQaNHbMo8bCQzTxBAPJRMtbO6pOfUTuOfgQqhmD23o8\/\/ji22WabYGHiReETpUyJ5mCzZZ4ELD0MAdlaM\/pu1WrkEagYghn+eXe4y3JjsG3KFySDXF47tn4EKoZgChYrFQrOsVObbbZZAMoVQ3zru1W7M49AxRCsARwLl156aRxwwAHJT8oRTtHq3bt3k\/5O99ageSPQNIKb94xW17roooti\/\/33D7FHrFh9+\/ZNgWs8M1x4XGPCdji3S7XqVr\/wX3hjxRDMucCfedxxx8Wkk04aIie5z0ROnnnmmQHZFC+xSoLOKF7WylH716IRqBiCmSspWuOPP\/7IBpPLRVGkWCkxUC5YN\/fo0SPUrdmijUjLoGII5tDmULj88stTnJTAMxYrSyFItxbOXRHaQrtmBctltWPzRqBiCC6KIqx7RSoKmWXEsB7u379\/CnIX2CZ6gdK1xx57hCA1FN68btVq5REoO4KxZutd7kEslzIlLlhIDU8SOUvuskUL9hb7y9Cx4IIL5jbXji0YgbIjmHLVUOSG+GcBb+Qt7Rkos1ZWxm5tYrSgb7WqdSNQdgSTu+zOKJRbsDRyQ4C5MmbKHXbYYaSNWoySYHVyu67Ntf8tGIGyIzi3DXvGjiFcGW0Za\/7999+DjRrlkskA6xYrTNFSt8OhC72gYgieZJJJAjKFlDJiAJEbZLS9Nu+8887IYWavhlyTYGRh7UezRqBiCLYVhZGDBk2+chWK3BD0LubXrjo2asClaN+woPNm9aoTVvrgm9\/ihPuGx3pnvxiT7\/twLHT0k+m8rV0pO4Kx5RyVYS+SgG\/OBf5e62B+YkoVu7SAblQtstJ2yLZ2tlrvh9w9rn29DqHvx2PvfpeaqeyE+95PCE8FrfxTdgTbUCYqQ3SGSH7RGrntftvBbzO1PThbbbVVWhNTvFB5V9WiH69DakZsHot8VI6y83lLj2VHsHAdURmHHXZY2OyFWkVtAJEbNkrbGmkvrBQOF154YQqEF\/2Bulvawc5QH6U21c5rn\/20qctNXis7gnNrOBLyXiBRG4BB45BDDkmboZksAZu0GK1\/\/vkn7dLP97fXcY69rgswY9+7kuwj\/8oJ3osdN9UfuollIxBO3FTd+tcqhuD6DWnq3I58S6em6rT22qpLLxjgo9PXiW9O7VF28N7\/m3zcJps\/44wzpiwALH4iTpusXO9i1SGYCZMVC8vOQBaTyx3Bos\/eYu4A9calrKdbLN50YpnRXW+qsS1CcFMPaq9rU0wxRUqVZH8wtg1o2HzC2HR7vaeantNv9ZljuVknbbBJqNv1Bi82o7CiCKYVH3TQQSmHFfkr0Yr8F+Sw7SuoGYjwEPlhl3sz+tQpq9yx+8LRb\/VuAaEZnL906NJt6k\/FEMzAIW0Rd6EekDMjRowI62Lph2zAtmUUWAuLk+4IQ8fudevPhkCbyg396igZQjM4b2sbKoZgXiUs1wY0CUhEbDB02NlgCcXKJUwng2hLa+i2drj+\/Y+88EY0BOXUpBt618z735OyBMh0kHURv0H9PjR1XjEEi85gW\/7ll19S+7BfyyZWLqmKWK5sacnQUYaOV0\/aIBqCSmjUpe\/cddW5U\/oogRD0EOA3SAPWzD8VQ7DoDEjcfffdUyIRFCuCslevXiHwjvmyFLgYs+epmX3r1NXagz0bgIoh2MuF49x1110hsRefr9\/KKFYiK21XyUBeC611Xw2aPwIVRbDci\/JOTTvttEGZEr7DUtO3b98UiCcpSQb5qpg5m9+1zlWTu5TXjE7CTNtera8Ygvl8r7\/++sCiac86JkGZfFPWwtyFIjsysFmT2+3V8ZY8pxx1xZ5xwMhHIs2SgIj2eG\/FEMzZb7O3\/BvS\/XImQKAyyyGhsu3Rwc7yDDYBwf8CISQ8tfuyPdpeMQTriB2Ee++9d8q+OvPMM6esr1yGjB20Zmy5o7Xo9hjEtj6DTUAki6WiZ1lZ4HB+txUqhmARHdL6kTsyuE088cSpL5QpPmGmSpSdNenOqkWL7S5du8qFqY8SvclSRyxZLkryBtEGwQqDmPK7rVAxBGs4lizeWWfsFRaew9hhQLL2nI\/WyCI7DJB7qx3EkDHS0DFQZG4vWcv9xzRr0tqA9\/7776c8mZKHMwCpnyd8vq+1x4oh2GxFwZwIzJAbbrhhShQqhV9RFCltriSi2DR3oVAfkSDuaW1ny3kfqpSke4MNNhjltUOHDk15qa0I+MRFjcpCu\/rqq6fUUWLTJCWli4xyYytPKoZgSoTZKj56v\/32S50TyUEG0yBlK4f8nj17hgSd5DVfqHta2dey3sa1KULFB0Hyi\/VNv3N8d1EUKSO9VQRko2hpgt2X72nrsWIILm04G7PQWJ1ksmTQgNBchwJicFB9LuusR5RN3par\/RVDsFnMwMFEaXlAFrFoQbBZT4vmSiSDe\/fuPfKbBJZQ5Rqc9n6P5Q\/Wy6jh2RKAk7\/Ckpx3BLQFwW1qT1EUAYH9+\/dPX0DBfnUea\/Y7fzmEJYuWLc0uli2JWpteXMGbi6KIHj16pO9DUBaFIeFckn13VLMqhmAd4i6kYNAsseA55pgjOR6sg+14GDJkSMrULhapV50Twj2UE8fOCsyx5LMlki05Aulkne+o\/lQMwbRiSwhRHEJyMjDTSeUgEIBCNfvsswfWJtS2M3qTrBBkYc8INEEFNYgJt8ZH0flaRxwrhmCaMpZM9lovZvARKTPc5jPLJAEAtpuiZvd0xCB05WdWDMGsNQwdbLClA6yM0YNsEhdtCUHzlO0d1ZfWrf0e\/QiUHcGWQEx10gND7vrrr58+\/UZbBmKx+IS5DWmXvjXUvXv39HmazqxBjx4VHVOj7AgmT+0e5PNllWKLhWznwDWKCLklFsln5Fh\/+I2tlztmGLruU8uOYOyWq5C9WZZ3SlZRFFEURUrKQvZSPLIXiZ8YlXNKoPiui4qO6VnZEUyOolgKlLUuozoFi5UK++YysySSXsnmswxCeKqERXcMJjroqWVHME0Ym0apfMA77rhjKOM+5EwQUcnbwpIl2N0XAbV6wgAABDtJREFUzPiOLZFQfweNQ5d9bNkRbCTFQTtm4B5DwRBo3Yt9+37DwIEDw1H0paUSCs\/31I7NG4GKILg5TWPlgvTm1M11UDz3YpbfjvzL+XpnPTKKyMrL2sf6RTEt7Yt+S+haWpZ\/VwTBvg8oHzQtme8TlTo6lyuLjdqRrFYuXpoMJq9zwxs7kucsRBnsc8p1Gfd5pvJ5ZzhCqi\/RtNaFWHYEM15Y9ojULwWzdK655kofZmST5hu1VPIpVvFJNOjWIsfsFqXJWSF73rBhw4Jmzh5M1vPoQLYwXhML5dt0PmDAgBCjjWoc1UE9KMZkkZ1PXc+x4wAyXPdMSWMEEjKx0jE4FzhNlPGWWedDnBSNmVMJHQbek0HID6MQV2oua+yIW2kPWHjhhVP6i7IjuLHGKUeh5PNll10WPrtjGZWBDGabVq8pkFsaJwDCgaSEUN+9Eq0xnrB1U+bYvQ2wpZq0TZwakr+YgAYUwtzbELhX5CcHvVAiiqM1u7omI06iDt\/vc889FxwqIlOGDBkSJoEJLVTJVh2JV00CCqVloWdkUN93iPO5Y2kf9VOorXLcCufSTwosW3\/VIJiWjGo1sCFwTR0daQouuOCCyJxBPmqfWFWfNQwlDB8+PDzfLDc41teSrKFqIbwQWxRF+rQsW7l7GwIIMpAmDMeICcMLpi7qsVuSY8H7cR4xWJDHFMvWTqbiFrgVxMq26331XYcQr9xzM5T2UV+FO+VrlqGUU9ZA+kjVIDg3sKOPjCwiGiHV4Ah0E8VpELHd\/H4RJdhqPq9\/ZBv3LWHPAKh5QB1Lr18vn3uWpWA+\/+6779LuDSsEHIN4YBswAXKdlh6131ZbhCBIoiiKaEcER6f4161bt5TMBWINyKBBg+KUU04JPlkslBNeOSo3GZhHUSIHiHIyUUdRB6pEYaiGKRWrdq0hMKkgEqKt84kc8Vl0DPKdboCr1L9X1EtToqK0PjGgP1izNrv2r0MwFuwjIBQl0SJYf58+fQKrpExhd3KEQDSqxk6di3akyZLVkM7PC2mO2D8rm98GtSGwBacoihAaLDqFoQcbZ8TJKwrn9e\/1DnqEyVX\/Wum5iYN6P\/jgg5QxwWSh7HUpBNO6GxpkCAR5QMg+yhEKlE1P6GpRFCHENQfbY3EGtSiK4AAhcwcPHhzydkm3iEJQoXKAXSvzfu3I7\/JeZSaL+DNLQu\/1rqIoggZN0fLFt6Io8m0jjzRulI7qPUN7PW9khbof3qctrtEDcB9g8nYpBNf1tVP9x5ohGkcQQ91Q4yHVt6XIaBOuoTpNldUQ3Mjo0H5po41cbpdiNgH2dxyhKeWKVm5dXRT\/S+Gja0gNwaMboU5+vYbgTo7A0TW\/huDRjVAnv15DcJsRWN0PqCG4uvHT5tbVENzmIazuB9QQXN34aXPraghu8xBW9wNqCK5u\/LS5dTUEt3kIq\/sB\/wUAAP\/\/2JylhAAAAAZJREFUAwBTM0CsZu4wLQAAAABJRU5ErkJggg==","height":100,"width":120}}
%---
%[output:6ac8e065]
%   data: {"dataType":"image","outputData":{"dataUri":"data:image\/png;base64,iVBORw0KGgoAAAANSUhEUgAAAHgAAABkCAYAAABNcPQyAAAQAElEQVR4AezdB5RdRRkH8O8FVIgKCUEFIRCKEKwRBYyAEhuKBrBwDCoqloDEylGwgIBGI1HwaCCKJZ6IGht6RFSCIgSB0GPovfcayqGGYH5jZs\/N5e2++2727W7C27Pfm3unfvP9Z77pc4c91f1bpSUwLLp\/q7QEugCv0vBGrBDATzzxRFx55ZVxyimnxAMPPBCPP\/74Ki6ulS97tQFeuHBh7LjjjvGhD30opk6dGgsWLIjdd989zj777JVPCqswx7UAfuihh+LII4+MQw45JE444YR40YteFFtttVUceOCBMXPmzOC+CstspcpaS4D\/9a9\/xaabbhrMnLOHH344qOfXvOY12SqZQGbPPVn08qMAfOADHwjk+cc\/\/nG86lWviosuuqiXEO1bf\/GLX4w3vvGNceedd6Z4xS+d9mOqFkI60pNuXyG488d\/X\/7Ioj94bgnwW97ylrj22muDmRl6\/vOfH8973vPirLPOiieffDJbx\/nnnx\/PetazYvjw4dHXn7C\/+c1vAnnuy+\/K4jZ9+vTYYIMN4tBDDx1SLPcAnEuM2opyKVNzvTOR5z\/96U9x8cUXxze\/+c3YZZddYv78+fG6170upkyZkkC+7rrrUo3nN9eaHJap1qq96G9\/+1sQzoMPPhi77bZbCleUEP\/iYbLPfIo3x8MdZZ75y3TXXXfFpz\/96RC\/dNSgiy66KGkMYZCaIl5hxMsOvetd70r+sptaJw1uKPPE\/txzz403vOENqeCLRzr8ZOJX3GR30003xVvf+takWcr+vIuvzHM5r+KSTpnK\/hLAOcKXvexlceGFF8Zf\/vKXWLRoURJ8OQLvBx98cNx+++2x1157xZgxY2LdddeNWbNmxemnnx6jRo2KadOmxWOPPcZrSyKwAw44IGgF6RY1hcCvfOUrY\/To0XH11Vd7jTPOOCOZW2+9dUyePDluueWWpEloEw577LFHUsue0Qte8II46qijUvzSUcPwV8wrf+IF5I9+9KPgjxzWWmstTonISNxqKTd+pA8470DbfPPNk1\/C\/+c\/\/5nkSPu95z3vSZWBieSH+x133BEA\/8lPfpK0JDcFRSRlnqWV88q\/wiodfjMBt+iPTBLAEgJoLoGveMUrQi\/5e9\/7Xg67nDlx4sTYZ599Qk0leOCcdNJJSZDbb799bLnllnHNNdcsF6buC3VPqKeddloCjgkc8V1yySWx5557xgtf+MJE22yzTRA0gXNvRpoETQP61a9+lbSG2s0vkJnywB95eEfiFDc7bvzI94knnhjIs84mv2QizqyRyHHevHmJR+6ZFGYFQCFW0IGd3YomOcur\/Mkr\/woJWQA1+83+ijJJAGcPVU0lVdt7xRVXxLOf\/ezEOFANkdZZZ50YO3Zs\/PGPf6waXZ\/+CJNQZZCQlWLvxt2EWAyML+8EzOyNqEGqUy0o+imHy\/EV\/QgjLPDK6Wd\/H\/nIR5LG8K5G8S9N70WiMTQPmjeFp+jW7FkBEFdv\/lXUMk\/LAZwzSB0pUc2YkvCSJUtS7aWqATBs2LB473vfG0qqmoGRz372sz2ZFGZFSG0RXk2habyrLWoN+0yZ\/2bAZD+ESj1Sh2qPZiHHUw6X48thmdSjcJnkmX2RsgZUIIHBjUyoc8+ZZs+enR7xID48JYtefjQL\/GUia\/LP3pvJJAG8ySabBLVH\/wMXY0rU29\/+9hx2OXPx4sWp00J1UhtqF\/Vw9913pxktdmqyQFlIwPFehzJ\/hIRP78jznDlzkurGN\/6pLiqst3QIYcSIET3O1HIu9QD2zI7qowKzR3GKO+cDWGoTk5yEU4P4VzFUEMNFIABGIZI290zSy8+Z\/\/xeNHNe8YMvhVTNL7fB2V9RJglgpeArX\/lK6lgpcdQKprQRxYTys3ZRhr\/whS\/E+PHjU02lsrTLG2+8cZrd+t3vfpcKDVAI4vLLL8\/Bn2aqkSzFQWCei4Q\/apkd0ztSmxQyPCPuf\/jDH1KT4TlTzjj1irRRmS8zcIRPeOKQb37kTzOQ49D2iVshkp+ijPgFfi7M4hBOfPyK74gjjgg1W2FQefSizRsobPKdO3DcVLAizzqG8ipOafEv\/L777suqh5rJJAHMh8R1rHL1z4GBzI6JPH\/qU59Ks1af+MQn0liWilYaqWXqRg3fdtttkxv\/yIwXUxwYUbKR52La3PFTJvwIz8xuwoqDPZpX6MhQnfm96I+9OPhHxxxzTOpQioe\/opthUk6LCWRxCof4zfYKjUKihpX98ZvzxfRO1mp5jo+JB2784CW\/47n4zg87aZep7K8H4LLHVu+rrbZavOMd74jjjjsuZEwv+mMf+1gC1fDi4x\/\/eKsohpw77aHGUbGYUyPVsLJq5VYm7acOoNpWdhvM9xLA1VmxgpRVEKGgcePGxT\/+8Y\/lZreqxzj4PtUcQGX1rTNmPKpGtuKOH7Wwt5rVKnyn3GsBrEPxi1\/8Ir7+9a+HtkF79J\/\/\/CcmTZqUJh9GjhzZKX47Hi+AqEBEjWo+Op5oBxOoBfAjjzwS2tnXvva1scUWW6TOmdksbdJf\/\/rX1MPuIM\/dqNuQQC2A11xzzVh99dXT9KFGXcdCj9Pkh6GCAlCVB6q9S5umFbtWcthwp71inf1PSTTn3NsribgWwIYVe++9d1o50a3Xddf9137p+ucxcJGDp556Kszz5g5M0Y06HGp08sknp\/nhocTXd7\/73R6xjR65Rs9zXw+1ABbhhAkTQs\/ZgFuPWW9a5+Swww5LtZufIlmI0O0v2nWfOy+BWgCbdbHUx8SiIdOYMWPiOc95Tnzwgx9MM0vsMxk+\/PrXv45PfvKT2aprDpAE2gIYoAbnhkeWopjFdmOHHXaI5z73ucst+NvhoacN+Be\/+MUDlK1uMlkCbQGcx3pWjczyMMtt1M9\/\/vOeRW+JmLvVJgPf+9CklYOrG+99tG1G2wI4x24R\/Yc\/\/GEws11vpsH\/D37wg9hss83SGFk7Tb0X\/VuoGGp08803pxWzocTXpTfe1SO2jdbpQCcrq+iiWi4\/U+H8ZU6KEwdUtZ52ubNlYn2o0YYbbhhDiafV1l4\/Ft6xOIkVuCi9tPhpqwZnFV1Wy8V3NZa\/Ful2nduQANVs3MsUbPvNRjAqUVsAF2M0uWHTnak8tfj1r399\/PSnP42+JjnM9arRxXi6z71LAKCA3XXmgjh87nXJ47CH744Dd94kPVf5qQWwacrvfOc7aTh0\/PHHp01vP\/vZz9KpBoNxkxpVEu\/6eboEgHr61YuWAnp9AHbKnMuCHZ\/U8vALZgXTexWqBfB9992Xpim\/9KUvpXaKSn7pS1+aFh8uvfTSsLOjSuJdP5HAA2iqqUcviHFT5ydg1dgMLDntuc16cfx+r47V777Ca2WqBbCJDZvtzD0XUyq\/F926z8uDqWbuWgDU++nXLFpOTGpqBvboPbdqq+bmiGoBPHLpcqBxrc3Zf\/\/73+PWW28Nnav9998\/1GQrSzmBZ5qp1iE1EgEOkBYJcu1kx60ZoEVQ\/3vQ+ADsDptX71SV5d03wGXfy94bjUaYfwawiQ3rwDpPdlba29VoNJb5XDUNACIgIYABEYCZ2CHuZSCzVDKYQKR+AYq8rwioOX5mLYAdBznooIOCqjamPe2008I6sKOkziaJeGUm4N36wOIADgIUAmKuiYBkh\/gBonDN8g3IHZYObahb4AHz3iMnRAaTfX8BWk6\/FsDWgJ0stPxn0d\/mOzs6zDuXExhq70BAuWMDHCABD2UAJ86+OdgjfhAQe8sPEBGwUBnI46e8Oqlbbp0CsxlvtQC24P++970v\/vznP8d5552XzijZUmrxwZZRi\/\/NEhsIu2bgAQl4al2mPAThlsHrC0C8AzDXRGPRMoj\/XdZmsh9oIPHXjGoBXI5IjbYJgMq+8cYbO7bpDngIIAg4KIOXa18ZPH6BJ2yZ9\/yewcsA7rPtiFTjqFPAZZWaa+KBO4+JoQJizkMzsxbAZqucPXr3u98ddnN84xvfSObcuXPjt7\/9behlN0usXTuAUKVFENVA7whwqBV40s0AAgWpZSgDCETgIfaTtxvRA6Cw4lgZqRbApintIdZ7ti5ss\/v73\/\/+fgOWIAGnJiLPQGTfjACQa14z8Mq1D4D8Ie2h8M3iXRXsagFsmdC5mP4GNQv08LnXpw6OGpztgJBBBFCuec9k8LJs+jJrAdxXhCvqBlzTdOIBqlqWwczqk11Ha57EVxEaUgBrb4vgHrh01URtBeYqIu8Bz0YtgHWytL3MIsfem9kX\/fT1PH3Zkhg\/R03aKnVyPHepvgTaAhiAziTpVDm2wnSJSqbf\/\/738a1vfavWyQa1N3ektLXdWlsf1GLItgA2U3XOOecEuv\/++5PpsHQmVzp85jOfqbRXq8iE52LtPWCpambXpRWXQFsAr7XWWulcsFpqIx3z29\/+dhTpbW97WzQa7S026C3n2qtj1a29Kw5sjqEtgE1B2jh3zz33pOVBW3a++tWvRpEOP\/zwdI1DTqCKCeDsb89t1s+PXbMfJNAWwFaKzFzZ3O4Ev6sXysSev3Z4O6Ow0N3OhrJ20nim+m0LYIsMFhRMRTqb9M53vjPKxJ6\/dgR6xtX3Je9d9ZzE0K8\/bQGcU7bv2f5nuynLxJ579uuwuJ0ebt7Zbrvtwry1qc7svmT4utHT\/lY8MZfDds3WEqgFsE12tugU90NbNrQJzyVgpjJz0nZdqtHGx6eeemra3uOmmuxeNLfffOW9GaCYj6H0XAvgZhlw\/sjdleVdldrk\/fbbL+3+sN3WUEtvPMexZPio\/Bjd9rdHFP320G8A4+j6669Pe6WtC3tHL3nJS9I1uw5+O0vsZgDXHnJDi9cdy+hShyRQC2BtrLa23P46VOakv9pc5temPDfi2RjgEtDsvnjdLfNjbLDafUPmwNdQPHzmIFyPsCo+1AI4t8FulL3qqqvSVQc+zuGGNiAX0zYZ4nQ\/O22xXvbVy64GZpdJD3ooHfYaaofPsmyyvKqatQAWuTlpPWOmd0dX1F4XhXvPZMx85plnpm085rJ1tNT+7J5r8EbdHnQWSb+atQA29HFPlinKN7\/5zYkh1zN8+MMfDueGAZksl\/7YP+3ycBMigHVrnIKw1Ckd22Ci0RXPu\/LbpeoSqAUwAPWIx40b1zPvrGPl9KAxrgKQWdDm+kKLYZJFCp2tPNNVnKLcaJ01c5AhZ67MDNUCeO211077rywPGvYQgHNJ9mnlHZbs2qGNujW4HXFV9lsLYLfpfO1rXwub3Z1Fon7d3fzLX\/4yTHboTFXhoDgHPbrbBlcRWdt+agGs1lKzhjs+pWMDvI6Ui0iNe9vmYmmAbg1eKoQO\/NcCWBurLb3tttvCrJRhk7Fvo9HuOvAjPVnqAtwjin59qAWwNtg1StZ+1WATH5kcTNMeV+HypmXXAnXBrSKten5qAXzvvfemi8B9O8C1\/s4pZbJlh3s9drqh+lsCtQC2WuSIimOjZWLPvQqjN973aPLWneRIYujIIj\/xGgAACVRJREFUT1sAU7++y3DZZZely799IKNMjrPwV4Xb4ji4iv+un\/Yl0BbAOlKHHnpo+ADHjBkz0sevHEIr0owZM4K\/VqwUwe3OYrWSVn33tgA2WwU8QyRjYZ\/OcZOsXrRFfEMlEx38tcPSRt1ZrHbE1ZbftgDOMZumPOSQQ9LXM4HL3mrH7Nmzo+o9WcUaLHyXOiOBWgDrJRsDU9c+TIU1M1r2Spd3dHBrRhsVpiZnTDu40pX25fXnTr5bROlk\/HXjbibLvuxqAUw9uyfL9xmKkVuEaDQaaXtOtPgDsKOf6OZTj01rysU9Xt3na3uVSQvRLudcC2ATHb705VN2ZrR0suyWtCfLJ9e008ul0n0ZNAnUAhi3vnqmk0VFX3DBBekzs+7M2nvvvTl3aYhIoDbA+NexMpNl4f\/LX\/5y+vhio9F6PtplpVae7Lh0Y57OWdXpTen2J7mlz00FeDGGtxerHL9l0GKbSWuV\/QzUu6\/c2Gdu3b1KmisEcJUEmvlR4302bu7cuelTeP\/+97\/DMKuZ307aGQ3o9QPYZgTflTC\/Xv48\/Q033JC+8LasXxA2EHaSr2Zx69\/4zN5HP\/rRsEOmmZ9mdoMCMDCdchg5cmTY8WFvl43zzRjspF0eDTiOIx2Xu5mFc7jOeya35+p35PfBMq2577HHHlF1vR2fgwKwXZV2LWIA+Z6DPdWeB5KMAowGbAyUrqVPBa4IsOYEwA68u\/ycgMsbC4XtNAF1woQJYXOFveVV06sFsExrQ2W42DZ5trHO0mErBgy1WvkZCHd89DXz9vjjj6e+hdvsrZ6Zi\/fxLzV9IPhb0TRqAaxEu7pw5syZYW90bpuY8+bNizy71RtzY8aMSeGyuzh8Ei+\/D5Q5atSodN2Ec8\/SZD766KOx3nrreU2kANgtmjWOjYamY9tpB1NEg\/RTC2Al3p3QVGuj0brXXM7b+PHjY8GCBUm4dod4Jriyv06\/K4iAs2lBWkzbevUNvCO9VmpZIfR++eWXh0IgnPehTrUANpFhi+yxxx4bVbvrRUFsvfXWQZUbS++8886hbWFX9DMQz9oyQw6f3dPpmzNnTnhnzw6NHj06HJ5zalJnzPSsDYfFQjAQvNZNoxbA2lhXORxzzDHpjkptbybAce+LoUajEdSeIy1WoNwz3Wi0rwn6SqOqm8\/t2aTgK27uvvYurCET8qwA4tXebjcKvfzlL2c9KKTfQ+6aiSoM1AKYatPWanPLxJ57lcS7fjovgVoAY4tqNinge0lq7bx58+L73\/9+LZUtvi51RgK1ADYD5LtJpvUsEa6\/\/vrp8zo6TE4Tcu8Mu91Y25VALYB9N8n0nQ9wbLzxxjFs2LBYY401wtX+QOfeLiNd\/52RQC2ADZPUUjW2yJY53Eajsdx6sGuHUbT4M4FvUr+Ft0rOJiF8AUbT0arDJ0LNjaVPExneB4Pw4Gy1zmoVeVXlsRbAhknWfQ0f9DxNfLi30md2rA4N9hDCJIQZKJMxA9HhM7PXX6thRif77rtvVfxa+qsFsFit+1pV0Ys28Dd8cH+lttn41nytGjl9+vRASqUzTZ7Hjh0bzjAZHlmu4+a7wpMnTw5hlGbLj\/y5eM0ZKEKUbpFcaWASwoSLMarD6Gqsgua6CG7eewvjnLKFj+x+8sknh6\/ISNcXZWip3njGo1qvo2nrsPSc0cIvMnctP\/yhKvnJfDDJRByTJk2KLbbYIm1TJitumcSr1pMZu\/I7u9oANxqNtH2WED\/3uc+ldtiuDjM+aralrR133DF8hQUplcaa1OD8+fPDdQ+mBF2zxM13hZVee6GcJ8acFSaawTjVOJRdJpkx6eC7Ea6POProo1NBWrRoUUibhlHoijVYk0LQjt24OBWfRxxxROr5c\/NBEUuXvgF1wgknhALUG8\/4EEZzcNJJJ4WCYH4ev8b2NAge+auSH\/7K5DCf05oLFy5MX5RTmBS6sr++3msDLHErG9OmTQunG0zhObZCOLvuumsogeZxi4lbFgQEFU4gzZbgqHtTlyYZDOZtKlDTCLoYl833hOimPX0CM2Hmsx1pLforPtM2S5YsiYkTJ4bZKoXg85\/\/fNgGbLXGNiQrSkYFpiJppr54FsZaMlOhJQ\/84ltcTCtTVfJT5DM\/77TTTiFf4hefAmiJM7tXMYdV8VT2QxWbpgSibxcaKlnAHzduXJrqk1FAl9WqzFJbpgWpeLWoHLcwMrHbbrv17LRUA7SrRb94aDQaPR26RqMRZqEUnOjlT20DpiVCXgiOalcQAW4kwL5IffH8\/zBrJO+WOwGaXpb+GFk0Go2omp+lQZ72r+lpNP4\/w6cy4PdpnlpY1AJYzZE5JxzEb1hkA7zdESY+7JmeNWtWqI3cM1lyUyNM+R133HFBuNktm41GI61G2e2hxiHqnDrOfpjA0LFB3qkuQqb2vTejchh8K6RUbTP\/7KrwzJ91ZDx4Rmq\/90ajWn6EKZP16mznWV7JPdsprMOHD8+vTc1aAFtJ0r7qQdtKopTqcGn7XHKmtKklVKdUZZQp04ZSGNUJ0ynJbtzVPupbwdE2i1vBMb4uq17piEvHSBy2AWkz7coQVzMSRuHUpAijbRcOr838s2vFMz+IOqXN8GDZ0Xwx\/keMGJH6Kq3yI44y6Q\/YZy4estYEkU\/2R\/M46Jc7X6600tnL7sxhftolqk7P1o06tpHoeeoQEZidldoLvVPDKRPzMqumUM9uh8coO222NWW9X3FYTHfNkk6Z9kZvVI98l112CReNF\/mUsalTp6a9UnqZVoGMpa3+FP0Vn4Vxx7V+ALAJ0GQNQRX9FZ9747lc4GguvCJDRaMEtVohr5KfYpr5WV\/gsMMOCzLUJE2ZMiVdeiOfiD99FVhoFmlNtwmyN3owD1ALYAvl9kJTtX2RhGRWz1lPWQdEz1ZJc0ht9913DyXUao3hAHvLkEqpdt079WzliaDEVyQZP\/HEE9MGcb1s8XDva8Ulh9HbN07Gk7ZTgRNO+OI792Y8A7IYhjaxpKiziec3velNqf1tNBrpwpoq+ZF2kXT0bE3Gq4qggHKnLZFn+dGLV3HIVE+eDI0eLPzUApiwNfgyaFijLQWWIYJSK3KEgWcKKehqu3bd8Egfw3GevN9rsORQC2DtlwkNakDbInNuujOU0dHSJg9WhgYrXbVGE0X70ADkYwhWlR9htLPiEYbGy7XUe136HwAAAP\/\/YfRL\/QAAAAZJREFUAwBW5CZQXlqRvAAAAABJRU5ErkJggg==","height":100,"width":120}}
%---
%[output:98c8ccfa]
%   data: {"dataType":"image","outputData":{"dataUri":"data:image\/png;base64,iVBORw0KGgoAAAANSUhEUgAAAHgAAABkCAYAAABNcPQyAAAQAElEQVR4AezdB5RdRRkH8O8FVIgKCUEFIRCKEKwRBYyAEhuKBrBwDCoqloDEylGwgIBGI1HwaCCKJZ6IGht6RFSCIgSB0GPovfcayqGGYH5jZs\/N5e2++2727W7C27Pfm3unfvP9Z77pc4c91f1bpSUwLLp\/q7QEugCv0vBGrBDATzzxRFx55ZVxyimnxAMPPBCPP\/74Ki6ulS97tQFeuHBh7LjjjvGhD30opk6dGgsWLIjdd989zj777JVPCqswx7UAfuihh+LII4+MQw45JE444YR40YteFFtttVUceOCBMXPmzOC+CstspcpaS4D\/9a9\/xaabbhrMnLOHH344qOfXvOY12SqZQGbPPVn08qMAfOADHwjk+cc\/\/nG86lWviosuuqiXEO1bf\/GLX4w3vvGNceedd6Z4xS+d9mOqFkI60pNuXyG488d\/X\/7Ioj94bgnwW97ylrj22muDmRl6\/vOfH8973vPirLPOiieffDJbx\/nnnx\/PetazYvjw4dHXn7C\/+c1vAnnuy+\/K4jZ9+vTYYIMN4tBDDx1SLPcAnEuM2opyKVNzvTOR5z\/96U9x8cUXxze\/+c3YZZddYv78+fG6170upkyZkkC+7rrrUo3nN9eaHJap1qq96G9\/+1sQzoMPPhi77bZbCleUEP\/iYbLPfIo3x8MdZZ75y3TXXXfFpz\/96RC\/dNSgiy66KGkMYZCaIl5hxMsOvetd70r+sptaJw1uKPPE\/txzz403vOENqeCLRzr8ZOJX3GR30003xVvf+takWcr+vIuvzHM5r+KSTpnK\/hLAOcKXvexlceGFF8Zf\/vKXWLRoURJ8OQLvBx98cNx+++2x1157xZgxY2LdddeNWbNmxemnnx6jRo2KadOmxWOPPcZrSyKwAw44IGgF6RY1hcCvfOUrY\/To0XH11Vd7jTPOOCOZW2+9dUyePDluueWWpEloEw577LFHUsue0Qte8II46qijUvzSUcPwV8wrf+IF5I9+9KPgjxzWWmstTonISNxqKTd+pA8470DbfPPNk1\/C\/+c\/\/5nkSPu95z3vSZWBieSH+x133BEA\/8lPfpK0JDcFRSRlnqWV88q\/wiodfjMBt+iPTBLAEgJoLoGveMUrQi\/5e9\/7Xg67nDlx4sTYZ599Qk0leOCcdNJJSZDbb799bLnllnHNNdcsF6buC3VPqKeddloCjgkc8V1yySWx5557xgtf+MJE22yzTRA0gXNvRpoETQP61a9+lbSG2s0vkJnywB95eEfiFDc7bvzI94knnhjIs84mv2QizqyRyHHevHmJR+6ZFGYFQCFW0IGd3YomOcur\/Mkr\/woJWQA1+83+ijJJAGcPVU0lVdt7xRVXxLOf\/ezEOFANkdZZZ50YO3Zs\/PGPf6waXZ\/+CJNQZZCQlWLvxt2EWAyML+8EzOyNqEGqUy0o+imHy\/EV\/QgjLPDK6Wd\/H\/nIR5LG8K5G8S9N70WiMTQPmjeFp+jW7FkBEFdv\/lXUMk\/LAZwzSB0pUc2YkvCSJUtS7aWqATBs2LB473vfG0qqmoGRz372sz2ZFGZFSG0RXk2habyrLWoN+0yZ\/2bAZD+ESj1Sh2qPZiHHUw6X48thmdSjcJnkmX2RsgZUIIHBjUyoc8+ZZs+enR7xID48JYtefjQL\/GUia\/LP3pvJJAG8ySabBLVH\/wMXY0rU29\/+9hx2OXPx4sWp00J1UhtqF\/Vw9913pxktdmqyQFlIwPFehzJ\/hIRP78jznDlzkurGN\/6pLiqst3QIYcSIET3O1HIu9QD2zI7qowKzR3GKO+cDWGoTk5yEU4P4VzFUEMNFIABGIZI290zSy8+Z\/\/xeNHNe8YMvhVTNL7fB2V9RJglgpeArX\/lK6lgpcdQKprQRxYTys3ZRhr\/whS\/E+PHjU02lsrTLG2+8cZrd+t3vfpcKDVAI4vLLL8\/Bn2aqkSzFQWCei4Q\/apkd0ztSmxQyPCPuf\/jDH1KT4TlTzjj1irRRmS8zcIRPeOKQb37kTzOQ49D2iVshkp+ijPgFfi7M4hBOfPyK74gjjgg1W2FQefSizRsobPKdO3DcVLAizzqG8ipOafEv\/L777suqh5rJJAHMh8R1rHL1z4GBzI6JPH\/qU59Ks1af+MQn0liWilYaqWXqRg3fdtttkxv\/yIwXUxwYUbKR52La3PFTJvwIz8xuwoqDPZpX6MhQnfm96I+9OPhHxxxzTOpQioe\/opthUk6LCWRxCof4zfYKjUKihpX98ZvzxfRO1mp5jo+JB2784CW\/47n4zg87aZep7K8H4LLHVu+rrbZavOMd74jjjjsuZEwv+mMf+1gC1fDi4x\/\/eKsohpw77aHGUbGYUyPVsLJq5VYm7acOoNpWdhvM9xLA1VmxgpRVEKGgcePGxT\/+8Y\/lZreqxzj4PtUcQGX1rTNmPKpGtuKOH7Wwt5rVKnyn3GsBrEPxi1\/8Ir7+9a+HtkF79J\/\/\/CcmTZqUJh9GjhzZKX47Hi+AqEBEjWo+Op5oBxOoBfAjjzwS2tnXvva1scUWW6TOmdksbdJf\/\/rX1MPuIM\/dqNuQQC2A11xzzVh99dXT9KFGXcdCj9Pkh6GCAlCVB6q9S5umFbtWcthwp71inf1PSTTn3NsribgWwIYVe++9d1o50a3Xddf9137p+ucxcJGDp556Kszz5g5M0Y06HGp08sknp\/nhocTXd7\/73R6xjR65Rs9zXw+1ABbhhAkTQs\/ZgFuPWW9a5+Swww5LtZufIlmI0O0v2nWfOy+BWgCbdbHUx8SiIdOYMWPiOc95Tnzwgx9MM0vsMxk+\/PrXv45PfvKT2aprDpAE2gIYoAbnhkeWopjFdmOHHXaI5z73ucst+NvhoacN+Be\/+MUDlK1uMlkCbQGcx3pWjczyMMtt1M9\/\/vOeRW+JmLvVJgPf+9CklYOrG+99tG1G2wI4x24R\/Yc\/\/GEws11vpsH\/D37wg9hss83SGFk7Tb0X\/VuoGGp08803pxWzocTXpTfe1SO2jdbpQCcrq+iiWi4\/U+H8ZU6KEwdUtZ52ubNlYn2o0YYbbhhDiafV1l4\/Ft6xOIkVuCi9tPhpqwZnFV1Wy8V3NZa\/Ful2nduQANVs3MsUbPvNRjAqUVsAF2M0uWHTnak8tfj1r399\/PSnP42+JjnM9arRxXi6z71LAKCA3XXmgjh87nXJ47CH744Dd94kPVf5qQWwacrvfOc7aTh0\/PHHp01vP\/vZz9KpBoNxkxpVEu\/6eboEgHr61YuWAnp9AHbKnMuCHZ\/U8vALZgXTexWqBfB9992Xpim\/9KUvpXaKSn7pS1+aFh8uvfTSsLOjSuJdP5HAA2iqqUcviHFT5ydg1dgMLDntuc16cfx+r47V777Ca2WqBbCJDZvtzD0XUyq\/F926z8uDqWbuWgDU++nXLFpOTGpqBvboPbdqq+bmiGoBPHLpcqBxrc3Zf\/\/73+PWW28Nnav9998\/1GQrSzmBZ5qp1iE1EgEOkBYJcu1kx60ZoEVQ\/3vQ+ADsDptX71SV5d03wGXfy94bjUaYfwawiQ3rwDpPdlba29VoNJb5XDUNACIgIYABEYCZ2CHuZSCzVDKYQKR+AYq8rwioOX5mLYAdBznooIOCqjamPe2008I6sKOkziaJeGUm4N36wOIADgIUAmKuiYBkh\/gBonDN8g3IHZYObahb4AHz3iMnRAaTfX8BWk6\/FsDWgJ0stPxn0d\/mOzs6zDuXExhq70BAuWMDHCABD2UAJ86+OdgjfhAQe8sPEBGwUBnI46e8Oqlbbp0CsxlvtQC24P++970v\/vznP8d5552XzijZUmrxwZZRi\/\/NEhsIu2bgAQl4al2mPAThlsHrC0C8AzDXRGPRMoj\/XdZmsh9oIPHXjGoBXI5IjbYJgMq+8cYbO7bpDngIIAg4KIOXa18ZPH6BJ2yZ9\/yewcsA7rPtiFTjqFPAZZWaa+KBO4+JoQJizkMzsxbAZqucPXr3u98ddnN84xvfSObcuXPjt7\/9behlN0usXTuAUKVFENVA7whwqBV40s0AAgWpZSgDCETgIfaTtxvRA6Cw4lgZqRbApintIdZ7ti5ss\/v73\/\/+fgOWIAGnJiLPQGTfjACQa14z8Mq1D4D8Ie2h8M3iXRXsagFsmdC5mP4GNQv08LnXpw6OGpztgJBBBFCuec9k8LJs+jJrAdxXhCvqBlzTdOIBqlqWwczqk11Ha57EVxEaUgBrb4vgHrh01URtBeYqIu8Bz0YtgHWytL3MIsfem9kX\/fT1PH3Zkhg\/R03aKnVyPHepvgTaAhiAziTpVDm2wnSJSqbf\/\/738a1vfavWyQa1N3ektLXdWlsf1GLItgA2U3XOOecEuv\/++5PpsHQmVzp85jOfqbRXq8iE52LtPWCpambXpRWXQFsAr7XWWulcsFpqIx3z29\/+dhTpbW97WzQa7S026C3n2qtj1a29Kw5sjqEtgE1B2jh3zz33pOVBW3a++tWvRpEOP\/zwdI1DTqCKCeDsb89t1s+PXbMfJNAWwFaKzFzZ3O4Ev6sXysSev3Z4O6Ow0N3OhrJ20nim+m0LYIsMFhRMRTqb9M53vjPKxJ6\/dgR6xtX3Je9d9ZzE0K8\/bQGcU7bv2f5nuynLxJ579uuwuJ0ebt7Zbrvtwry1qc7svmT4utHT\/lY8MZfDds3WEqgFsE12tugU90NbNrQJzyVgpjJz0nZdqtHGx6eeemra3uOmmuxeNLfffOW9GaCYj6H0XAvgZhlw\/sjdleVdldrk\/fbbL+3+sN3WUEtvPMexZPio\/Bjd9rdHFP320G8A4+j6669Pe6WtC3tHL3nJS9I1uw5+O0vsZgDXHnJDi9cdy+hShyRQC2BtrLa23P46VOakv9pc5temPDfi2RjgEtDsvnjdLfNjbLDafUPmwNdQPHzmIFyPsCo+1AI4t8FulL3qqqvSVQc+zuGGNiAX0zYZ4nQ\/O22xXvbVy64GZpdJD3ooHfYaaofPsmyyvKqatQAWuTlpPWOmd0dX1F4XhXvPZMx85plnpm085rJ1tNT+7J5r8EbdHnQWSb+atQA29HFPlinKN7\/5zYkh1zN8+MMfDueGAZksl\/7YP+3ycBMigHVrnIKw1Ckd22Ci0RXPu\/LbpeoSqAUwAPWIx40b1zPvrGPl9KAxrgKQWdDm+kKLYZJFCp2tPNNVnKLcaJ01c5AhZ67MDNUCeO211077rywPGvYQgHNJ9mnlHZbs2qGNujW4HXFV9lsLYLfpfO1rXwub3Z1Fon7d3fzLX\/4yTHboTFXhoDgHPbrbBlcRWdt+agGs1lKzhjs+pWMDvI6Ui0iNe9vmYmmAbg1eKoQO\/NcCWBurLb3tttvCrJRhk7Fvo9HuOvAjPVnqAtwjin59qAWwNtg1StZ+1WATH5kcTNMeV+HypmXXAnXBrSKten5qAXzvvfemi8B9O8C1\/s4pZbJlh3s9drqh+lsCtQC2WuSIimOjZWLPvQqjN973aPLWneRIYujIIj\/xGgAACVRJREFUT1sAU7++y3DZZZely799IKNMjrPwV4Xb4ji4iv+un\/Yl0BbAOlKHHnpo+ADHjBkz0sevHEIr0owZM4K\/VqwUwe3OYrWSVn33tgA2WwU8QyRjYZ\/OcZOsXrRFfEMlEx38tcPSRt1ZrHbE1ZbftgDOMZumPOSQQ9LXM4HL3mrH7Nmzo+o9WcUaLHyXOiOBWgDrJRsDU9c+TIU1M1r2Spd3dHBrRhsVpiZnTDu40pX25fXnTr5bROlk\/HXjbibLvuxqAUw9uyfL9xmKkVuEaDQaaXtOtPgDsKOf6OZTj01rysU9Xt3na3uVSQvRLudcC2ATHb705VN2ZrR0suyWtCfLJ9e008ul0n0ZNAnUAhi3vnqmk0VFX3DBBekzs+7M2nvvvTl3aYhIoDbA+NexMpNl4f\/LX\/5y+vhio9F6PtplpVae7Lh0Y57OWdXpTen2J7mlz00FeDGGtxerHL9l0GKbSWuV\/QzUu6\/c2Gdu3b1KmisEcJUEmvlR4302bu7cuelTeP\/+97\/DMKuZ307aGQ3o9QPYZgTflTC\/Xv48\/Q033JC+8LasXxA2EHaSr2Zx69\/4zN5HP\/rRsEOmmZ9mdoMCMDCdchg5cmTY8WFvl43zzRjspF0eDTiOIx2Xu5mFc7jOeya35+p35PfBMq2577HHHlF1vR2fgwKwXZV2LWIA+Z6DPdWeB5KMAowGbAyUrqVPBa4IsOYEwA68u\/ycgMsbC4XtNAF1woQJYXOFveVV06sFsExrQ2W42DZ5trHO0mErBgy1WvkZCHd89DXz9vjjj6e+hdvsrZ6Zi\/fxLzV9IPhb0TRqAaxEu7pw5syZYW90bpuY8+bNizy71RtzY8aMSeGyuzh8Ei+\/D5Q5atSodN2Ec8\/SZD766KOx3nrreU2kANgtmjWOjYamY9tpB1NEg\/RTC2Al3p3QVGuj0brXXM7b+PHjY8GCBUm4dod4Jriyv06\/K4iAs2lBWkzbevUNvCO9VmpZIfR++eWXh0IgnPehTrUANpFhi+yxxx4bVbvrRUFsvfXWQZUbS++8886hbWFX9DMQz9oyQw6f3dPpmzNnTnhnzw6NHj06HJ5zalJnzPSsDYfFQjAQvNZNoxbA2lhXORxzzDHpjkptbybAce+LoUajEdSeIy1WoNwz3Wi0rwn6SqOqm8\/t2aTgK27uvvYurCET8qwA4tXebjcKvfzlL2c9KKTfQ+6aiSoM1AKYatPWanPLxJ57lcS7fjovgVoAY4tqNinge0lq7bx58+L73\/9+LZUtvi51RgK1ADYD5LtJpvUsEa6\/\/vrp8zo6TE4Tcu8Mu91Y25VALYB9N8n0nQ9wbLzxxjFs2LBYY401wtX+QOfeLiNd\/52RQC2ADZPUUjW2yJY53Eajsdx6sGuHUbT4M4FvUr+Ft0rOJiF8AUbT0arDJ0LNjaVPExneB4Pw4Gy1zmoVeVXlsRbAhknWfQ0f9DxNfLi30md2rA4N9hDCJIQZKJMxA9HhM7PXX6thRif77rtvVfxa+qsFsFit+1pV0Ys28Dd8cH+lttn41nytGjl9+vRASqUzTZ7Hjh0bzjAZHlmu4+a7wpMnTw5hlGbLj\/y5eM0ZKEKUbpFcaWASwoSLMarD6Gqsgua6CG7eewvjnLKFj+x+8sknh6\/ISNcXZWip3njGo1qvo2nrsPSc0cIvMnctP\/yhKvnJfDDJRByTJk2KLbbYIm1TJitumcSr1pMZu\/I7u9oANxqNtH2WED\/3uc+ldtiuDjM+aralrR133DF8hQUplcaa1OD8+fPDdQ+mBF2zxM13hZVee6GcJ8acFSaawTjVOJRdJpkx6eC7Ea6POProo1NBWrRoUUibhlHoijVYk0LQjt24OBWfRxxxROr5c\/NBEUuXvgF1wgknhALUG8\/4EEZzcNJJJ4WCYH4ev8b2NAge+auSH\/7K5DCf05oLFy5MX5RTmBS6sr++3msDLHErG9OmTQunG0zhObZCOLvuumsogeZxi4lbFgQEFU4gzZbgqHtTlyYZDOZtKlDTCLoYl833hOimPX0CM2Hmsx1pLforPtM2S5YsiYkTJ4bZKoXg85\/\/fNgGbLXGNiQrSkYFpiJppr54FsZaMlOhJQ\/84ltcTCtTVfJT5DM\/77TTTiFf4hefAmiJM7tXMYdV8VT2QxWbpgSibxcaKlnAHzduXJrqk1FAl9WqzFJbpgWpeLWoHLcwMrHbbrv17LRUA7SrRb94aDQaPR26RqMRZqEUnOjlT20DpiVCXgiOalcQAW4kwL5IffH8\/zBrJO+WOwGaXpb+GFk0Go2omp+lQZ72r+lpNP4\/w6cy4PdpnlpY1AJYzZE5JxzEb1hkA7zdESY+7JmeNWtWqI3cM1lyUyNM+R133HFBuNktm41GI61G2e2hxiHqnDrOfpjA0LFB3qkuQqb2vTejchh8K6RUbTP\/7KrwzJ91ZDx4Rmq\/90ajWn6EKZP16mznWV7JPdsprMOHD8+vTc1aAFtJ0r7qQdtKopTqcGn7XHKmtKklVKdUZZQp04ZSGNUJ0ynJbtzVPupbwdE2i1vBMb4uq17piEvHSBy2AWkz7coQVzMSRuHUpAijbRcOr838s2vFMz+IOqXN8GDZ0Xwx\/keMGJH6Kq3yI44y6Q\/YZy4estYEkU\/2R\/M46Jc7X6600tnL7sxhftolqk7P1o06tpHoeeoQEZidldoLvVPDKRPzMqumUM9uh8coO222NWW9X3FYTHfNkk6Z9kZvVI98l112CReNF\/mUsalTp6a9UnqZVoGMpa3+FP0Vn4Vxx7V+ALAJ0GQNQRX9FZ9747lc4GguvCJDRaMEtVohr5KfYpr5WV\/gsMMOCzLUJE2ZMiVdeiOfiD99FVhoFmlNtwmyN3owD1ALYAvl9kJTtX2RhGRWz1lPWQdEz1ZJc0ht9913DyXUao3hAHvLkEqpdt079WzliaDEVyQZP\/HEE9MGcb1s8XDva8Ulh9HbN07Gk7ZTgRNO+OI792Y8A7IYhjaxpKiziec3velNqf1tNBrpwpoq+ZF2kXT0bE3Gq4qggHKnLZFn+dGLV3HIVE+eDI0eLPzUApiwNfgyaFijLQWWIYJSK3KEgWcKKehqu3bd8Egfw3GevN9rsORQC2DtlwkNakDbInNuujOU0dHSJg9WhgYrXbVGE0X70ADkYwhWlR9htLPiEYbGy7XUe136HwAAAP\/\/YfRL\/QAAAAZJREFUAwBW5CZQXlqRvAAAAABJRU5ErkJggg==","height":100,"width":120}}
%---
