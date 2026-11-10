% clear 
[model, options] = init_environment('grid_afe_n');

CTRPIFF_CLIP_RELEASE = 0.001;
s = tf('s');
%[text] ### Global timing
% simulation length
simlength = 3;

fpwm = 4e3;

fpwm_afe = fpwm;
trgo_afe = 1; % double update

fpwm_inv = fpwm;
trgo_inv = 1; % double update

fpwm_single_phase_inv = fpwm;
trgo_single_phase_inv = 1; % double update

fpwm_dab = 3 * fpwm;
trgo_dab = 1; % double update

fpwm_psfbc = fpwm;
trgo_psfbc = 1; % double update

fpwm_isop_rail = fpwm;
trgo_isop_rail = 1; % double update

fpwm_cllc = 3 * fpwm;
trgo_cllc = 0; % double update

t_measure = simlength;
tc_factor = 200; % tc is ts_afe / tc_factor
tc_decimation = 1;
delay_pwm = 0;

dead_time_afe = 3e-6;
dead_time_inv = 3e-6;
dead_time_single_phase_inv = 3e-6;
dead_time_dab = 2e-6;
dead_time_psfbc = 3e-6;
dead_time_isop_rail = 3e-6;
dead_time_cllc = 2e-6;

glb_time = timing_setup(fpwm_afe, trgo_afe, fpwm_inv, trgo_inv, fpwm_single_phase_inv, trgo_single_phase_inv, fpwm_dab, trgo_dab, ...
    fpwm_psfbc, trgo_psfbc, fpwm_isop_rail, trgo_isop_rail, fpwm_cllc, trgo_cllc, t_measure, tc_factor, tc_decimation, delay_pwm, dead_time_afe, ...
    dead_time_inv, dead_time_single_phase_inv, dead_time_dab, dead_time_psfbc, dead_time_isop_rail, dead_time_cllc);
%[text] ## Settings for simulink model initialization and data analysis
%[text] ### Settings Enable devices with thermal model
use_mosfet_thermal_model = 0;
use_thermal_model = 0;

nonlinear_iterations = 3;  % for simscape solver
if (use_mosfet_thermal_model || use_thermal_model)
    nonlinear_iterations = 5; % for simscape solver
end

%[text] ### Enable specific settings for the simulation
load_step_time = 1.25;
transmission_delay = 125e-6*2;
sst_num_of_modules = 2;
%[text] ### Enable one/two modules
number_of_modules = 1;
enable_two_modules = number_of_modules;
%[text] ### Control Mode Settings
use_torque_curve = 1; 
use_speed_control = 1-use_torque_curve; %
use_mtpa = 1; %
use_psm_encoder = 0; % 
use_im_encoder = 1; % 
use_load_estimator = 0; %
use_estimator_from_mb = 0; % mb model based
use_motor_speed_control_mode = 0; 

% advanced dqPLL
use_dq_pll_fht_pll = 1; % 
use_dq_pll_fht_simulink_pll = 0; % 
use_dq_pll_mod1 = 0; % 
use_dq_pll_ccaller_mod1 = 0; % 
use_dq_pll_ccaller_mod2 = 0; % 

% dqPLL
use_dq_pll_mode1 = use_dq_pll_mod1;
use_dq_pll_mode2 = use_dq_pll_ccaller_mod1;
use_dq_pll_mode3 = use_dq_pll_fht_simulink_pll;
use_dq_pll_mode4 = use_dq_pll_fht_pll;

use_dq_pll_mode1_modn = 0; % simulink dqPLL
use_dq_pll_mode2_modn = 0; % ccaller dqPLL
use_dq_pll_mode3_modn = 1; % fht simulink dqPLL
use_dq_pll_mode4_modn = 0; % fht ccaller dqPLL

% single phase inverter
rpi_enable = 0; % use RPI otherwise DQ PI
system_identification_enable = 0;
use_current_controller_from_ccaller_mod1 = 1;
use_phase_shift_filter_from_ccaller_mod1 = 1;
use_sogi_from_ccaller_mod1 = 1;

% four modules in parallel connected to a dc microgrid
ixi_ref_mod1 = -0.85;
ixi_ref_mod2 = -0.85;
ixi_ref_mod3 = -0.85;
ixi_ref_mod4 = -0.85;

% common mode voltage control for hard parallelization
en_parallel_mode = 1;
   u_cm_comp_mod1 = 0;
   u_cm_comp_mod2 = 0;
   u_cm_comp_mod3 = 0;
   u_cm_comp_mod4 = 0;

if en_parallel_mode
   u_cm_comp_mod2 = -1;
   u_cm_comp_mod3 = -1;
   u_cm_comp_mod4 = -1;
end
%[text] ### Settings for CCcaller versus Simulink
use_ekf_bemf_module_1 = 1;
use_ekf_bemf_module_2 = 1;
use_observer_from_simulink_module_1 = 0;
use_observer_from_ccaller_module_1 = 0;
use_observer_from_simulink_module_2 = 0;
use_observer_from_ccaller_module_2 = 0;

% current controllers
use_current_controller_from_simulink_module_1 = 0;
use_current_controller_from_ccaller_module_1 = 1;
use_current_controller_from_simulink_module_2 = 1;
use_current_controller_from_ccaller_module_2 = 0;

% moving average filters
use_moving_average_from_ccaller_mod1 = 1;
use_moving_average_from_ccaller_mod2 = 0;
use_moving_average_from_ccaller_mod3 = 0;
use_moving_average_from_ccaller_mod4 = 0;

use_single_phase_inverter_based_FHT = 0;
use_single_phase_inverter_based_SOGI = 0;
use_single_phase_inverter_based_PHSH = 0;
use_single_phase_inverter_based_SOGI_ccaller = 1;
use_single_phase_inverter_based_PHSH_ccaller = 0;

use_system_identification_based_FHT = 0;
use_system_identification_based_SOGI = 0;
use_system_identification_based_PHSH = 0;
use_system_identification_based_SOGI_ccaller = 0;
use_system_identification_based_PHSH_ccaller = 1;


%[text] ### Single phase inverter control
iph_grid_pu_ref_1 = 1/3;
iph_grid_pu_ref_2 = 1/3.;
iph_grid_pu_ref_3 = 1/3;
time_step_ref_1 = 0.025;
time_step_ref_2 = 0.5;
time_step_ref_3 = 1;
%[text] ### Setting global behavioural (system identification versus normal functioning) and operative frequency
frequency_set = 50; % default
if system_identification_enable
    frequency_set = 300;
end
omega_set = frequency_set*2*pi;
%[text] ### Settings average filters
mavarage_filter_frequency_base_order = 2; % 2 means 100Hz, 1 means 50Hz
dmavg_filter_enable_time = 0.025;
%%
%[text] ### Grid Emulator Settings
grid_nominal_power = 1250e3;
application_voltage = 690;
grid_nominal_current = grid_nominal_power/application_voltage/sqrt(3);

% Transformer Dyn11
delta_star = 1;

if application_voltage == 690
    % trafo data
    us1 = 690; us2 = 690; fgrid = 50;
    eta = 95; ucc = 5;
    p_iron = 1800;
elseif application_voltage == 480
    % trafo data
    us1 = 480; us2 = 480; fgrid = 60;
    eta = 95; ucc = 5;
    p_iron = 1400;
else
    % trafo data
    us1 = 400; us2 = 400; fgrid = 50;
    eta = 95; ucc = 5;
    p_iron = 1000;
end

n2 = 14; n1 = floor(n2*sqrt(3));
core_area = 0.05; core_length = 2.5;
mu0 = 4*pi*1e-7; mur = 10e3;

% two simple calculation:
Lm1 = (n1^2 * mu0 * mur * core_area) / core_length;
% Lm1 = u1_nom/sqrt(3)/i1m/(2*pi*fgrid);
i1m = us1/sqrt(3)/Lm1/(2*pi*fgrid);

% reference for the voltage sequence
up_xi_pu_ref = 1; up_eta_pu_ref = 0; un_xi_pu_ref = 0; un_eta_pu_ref = 0;

% grid impedance
Lgrid_base = us1/sqrt(3)*ucc/100/2/pi/fgrid/grid_nominal_current;
if ~exist('ucc_factor', 'var')
    ucc_factor = 1;
end
eq_grid_inductance = Lgrid_base*ucc_factor; % [H]
eq_grid_resistance = 2e-3; % [Ohm]

grid_emu = grid_three_phase_emulator('Dyn11', delta_star, grid_nominal_power, application_voltage, us1, us2, fgrid, ...
                eq_grid_inductance, eq_grid_resistance, eta, ucc, i1m, p_iron, n1, n2, core_area, core_length, mur, ...
                up_xi_pu_ref, up_eta_pu_ref, un_xi_pu_ref, un_eta_pu_ref);
%[text] ## Global Hardware Settings
%[text] ### Rail Catenary Voltage Model
catenary_nominal_power = 2*5.4e6; % per 12km
catenary_nominal_voltage = 3000;
catenary_maximum_voltage = 4000;
catenary_nominal_current = catenary_nominal_power/catenary_nominal_voltage;

isop_rail_pwr_nom = 250e3; % nominal per system
number_of_systems = 4;
full_bridge_application_voltage = catenary_maximum_voltage/number_of_systems;
hwdata.isop_rail = isop_rail_aux_application(full_bridge_application_voltage, isop_rail_pwr_nom, glb_time.fPWM_ISOP_RAIL);
%[text] ### Hardware Settings
single_phase_inverter_pwr_nom = 225e3;
afe_pwr_nom = 250e3;
inv_pwr_nom = 250e3;
dab_pwr_nom = 250e3;
three_phase_dab_pwr_nom = 3*dab_pwr_nom;
cllc_pwr_nom = 250e3;
psfbc_pwr_nom = 275e3;
fres_dab = glb_time.fPWM_DAB/5;
fres_cllc = glb_time.fPWM_CLLC*1.2;

hwdata.single_phase_inverter = single_phase_inverter_hwdata(application_voltage, single_phase_inverter_pwr_nom, glb_time.fPWM_INV);
hwdata.afe = three_phase_afe_hwdata(application_voltage, afe_pwr_nom, glb_time.fPWM_AFE); %[output:3cc89de2]
hwdata.inv = three_phase_inverter_hwdata(application_voltage, inv_pwr_nom, glb_time.fPWM_INV); %[output:1001385e]
hwdata.dab = single_phase_dab_hwdata(application_voltage, dab_pwr_nom, glb_time.fPWM_DAB, fres_dab); %[output:285e0d10]
hwdata.psfbc = single_phase_psfbc_hwdata(application_voltage, psfbc_pwr_nom, glb_time.fPWM_PSFBC); %[output:3c8fbcdd]
hwdata.three_phase_dab = three_phase_dab_hwdata(application_voltage, three_phase_dab_pwr_nom, glb_time.fPWM_DAB, fres_dab); %[output:483a813d]
hwdata.cllc = single_phase_cllc_hwdata(application_voltage, dab_pwr_nom, glb_time.fPWM_CLLC, fres_cllc); %[output:23717450]

% modifications
hwdata.afe.CFu = 120e-6;
% hwdata.afe.CFu = 200e-6;
%[text] ### Sensors endscale, and quantization
adc_quantization = 1/2^11;
adc12_quantization = adc_quantization;
adc16_quantization = 1/2^15;

Imax_adc = 1049.835;
CurrentQuantization = Imax_adc/2^11;

Umax_adc = 1500;
VoltageQuantization = Umax_adc/2^11;
%[text] ## AFE Settings and Initialization
%[text] ### Behavioural Settings

time_gain_afe_module_1 = 1.0002;
time_gain_afe_module_2 = 1.0015;
time_gain_afe_module_3 = 0.9988;
time_gain_afe_module_4 = 1.0020;

time_gain_inv_module_1 = 1.0005;
time_gain_inv_module_2 = 1.001;
wnp = 0;
white_noise_power_afe_mod1 = wnp;
white_noise_power_inv_mod1 = wnp;
white_noise_power_afe_mod2 = wnp;
white_noise_power_inv_mod2 = wnp;

trgo_th_generator = 0.025;

afe_pwm_phase_shift_mod1 = 0;
white_noise_power_afe_pwm_phase_shift_mod1 = 0.0;
inv_pwm_phase_shift_mod1 = 0;
white_noise_power_inv_pwm_phase_shift_mod1 = 0.0;

afe_pwm_phase_shift_mod2 = 0;
white_noise_power_afe_pwm_phase_shift_mod2 = 0.0;
inv_pwm_phase_shift_mod2 = 0;
white_noise_power_inv_pwm_phase_shift_mod2 = 0.0;

afe_pwm_phase_shift_mod3 = 0;
white_noise_power_afe_pwm_phase_shift_mod3 = 0.0;
inv_pwm_phase_shift_mod3 = 0;
white_noise_power_inv_pwm_phase_shift_mod3 = 0.0;

afe_pwm_phase_shift_mod4 = 0;
white_noise_power_afe_pwm_phase_shift_mod4 = 0.0;
inv_pwm_phase_shift_mod4 = 0;
white_noise_power_inv_pwm_phase_shift_mod4 = 0.0;
%[text] ### FRT Settings
test_index = 25; % type of fault: index
test_subindex = 4; % type of fault: subindex
% test_subindex = 1; % type of fault: subindex
enable_frt_1 = 1; % faults generated from abc
enable_frt_2 = 0; % faults generated from xi_eta_pos and xi_eta_neg
start_time_LVRT = 0.75;
asymmetric_error_type = 1;
deepPOSxi = 1;
deepPOSeta = -0.4;
deepNEGxi = 0.4;
deepNEGeta = 0.4;
frt_data = frt_settings(test_index, test_subindex, asymmetric_error_type, ...
    enable_frt_1, enable_frt_2, start_time_LVRT, deepPOSxi, deepPOSeta, deepNEGxi, deepNEGeta);
grid_fault_generator;
%[text] ### Reactive Current References Settings
% reactive current references 
enable_i_react_pos_steps = 1;
    time_i_react_pos_ref_1 = 0; % default
    time_i_react_pos_ref_2 = 0; % default
    i_react_pos_ref_1 = 0; % default
    i_react_pos_ref_2 = 0; % default
    i_react_pos_ref_3 = 0; % default

if enable_i_react_pos_steps
    time_i_react_pos_ref_1 = start_time_LVRT + error_length + 0.335;
    time_i_react_pos_ref_2 = time_i_react_pos_ref_1 + 0.5;
    i_react_pos_ref_2 = -ixi_ref_mod1*tan(acos(0.95));  % cos(phi) = 0.9
    i_react_pos_ref_3 = ixi_ref_mod1*tan(acos(0.95)); % cos(phi) = 0.9
end
%[text] #### UPQC Series Transformer
name = 'UPQC Series Transformer';
pwr_nom = 3*125e3;
u1_nom = 400;
u2_nom = 690;
f_nom = 50;
eta = 98;
ucc = 4;
p_iron = 5e3;
n12 = u1_nom/u2_nom;
n2 = 8;
n1 = n12*n2;
core_area = 0.04;
core_length = 0.25;
mur = 35e3;

Lm1 = (n1^2 * mu0 * mur * core_area) / core_length;
i1m = u1_nom/sqrt(3)/Lm1/f_nom/2/pi;

delta_star = 0;

upqc_st = three_phase_transformer_setup(name, delta_star, pwr_nom, u1_nom, u2_nom, f_nom, eta, ucc, ...
    i1m, p_iron, n1, n2, core_area, core_length, mur);
upqc_st.Lm1;
upqc_st.Ld1;
upqc_ctrl.kp_p = 1;
upqc_ctrl.ki_p = 35;
upqc_ctrl.kp_n = 1;
upqc_ctrl.ki_n = 35;
upqc_ctrl.lim = 4;
%[text] #### DClink Lstray model (partial loop inductance)
parasitic_dclink_data; %[output:61f2e687]
%%
%[text] ## INVERTER Settings and Initialization
%[text] ### Mode of operation
motor_torque_mode = 1 - use_motor_speed_control_mode; % system uses torque curve for wind application
time_start_motor_control = 0.25;
%[text] ### IM Machine settings
im = im_calculus(); %[output:70048be9]
%[text] ### PSM Machine settings
psm = psm_calculus(); %[output:64e9b7ec]
n_sys = psm.number_of_systems;

% load
b = psm.load_friction_m;
% external_load_inertia = 6*psm.Jm_m;
external_load_inertia = 1;
%[text] ### Motor Voltage to Udc Scaling
u_psm_scale = 2/3*hwdata.inv.udc_nom/psm.ubez;
u_im_scale = 2/3*hwdata.inv.udc_nom/im.ubez;

u_psm_scale_ekf = sqrt(3)/2 * 2/3 * hwdata.inv.udc_nom/psm.ubez;
u_im_scale_ekf = (2/3)^2 * hwdata.inv.udc_nom/im.ubez;
%[text] ## **CONTROL Settings and Initialization**
%[text] #### Permanent magnet synchronous motor control with EKF based observer
psm_ctrl = ctrl_pmsm_setup(glb_time.ts_inv, psm.omega_bez, u_psm_scale, psm.Jm_norm);
% psm_ctrl.ekf = ekf_pmsm_setup(psm.Rs_norm, psm.Ls_norm, psm.Jm_norm, glb_time.ts_inv);
psm_ctrl.ekf = ekf_pmsm_setup(psm.Rs_norm, psm.Ls_norm, 1e6, glb_time.ts_inv); %[output:80e64617]
psm_ctrl.kp_i = 0.25;
psm_ctrl.ki_i = 35;
%[text] #### Induction Motor Control
im_ctrl = ctrl_im_setup(glb_time.ts_inv, im.omega_bez, u_im_scale, im.Jm_norm);
im_ctrl.ekf = ekf_im_setup(im.alpha_norm, im.beta_norm, im.gamma_norm, im.sigma_norm, ... %[output:group:73a6a65d] %[output:26e0189a]
        im.mu_norm, im.Lm_norm, im.Jm_norm, glb_time.ts_inv); %[output:group:73a6a65d] %[output:26e0189a]
%[text] #### AFE control (with sequences)
afe_ctrl = ctrl_afe_setup(glb_time.ts_afe, grid_emu.omega_grid_nom);

afe_ctrl.kp_udc_ctrl = 2;

kp_udc = 0.5;
ki_udc = 18.0;
kp_idc = 0.5;
ki_idc = 18.0;

%% gain for weak grids
afe_ctrl.res_pi.kp_rpi = 0.25;
afe_ctrl.res_pi.ki_rpi = 18;

%% gains for LVRT
% afe_ctrl.res_pi.kp_rpi = 0.6;
% afe_ctrl.res_pi.ki_rpi = 35;

%[text] #### DCDC Control
dab_ctrl = ctrl_dab_setup(kp_udc, ki_udc, kp_idc, ki_idc);
psfbc_ctrl = ctrl_dab_setup(kp_udc, ki_udc, kp_idc, ki_idc);
cllc_ctrl = ctrl_cllc_setup(kp_udc, ki_udc, kp_idc, ki_idc);

% special settings
psfbc_ctrl.kp_idc = 1;
dab_ctrl.ki_udc = 35;

isop_rail_ctrl = ctrl_isop_rail_setup(kp_udc, ki_udc, kp_idc, ki_idc);
dab_ctrl.kp_idc = 0.02;
dab_ctrl.ki_idc = 1.0;
%[text] ### 
%[text] #### Resonant PI settings
pres_ctrl.kp_rpi = 0.75;
pres_ctrl.ki_rpi = 45;
pres_ctrl.delta_rpi = 0.025;
pres_ctrl.omega_set = omega_set;
pres_ctrl.res_nom = s/(s^2 + 2*pres_ctrl.delta_rpi*pres_ctrl.omega_set*s + (pres_ctrl.omega_set)^2);

pres_ctrl.Ares_nom = [0 1; -omega_set^2 -2*pres_ctrl.delta_rpi*pres_ctrl.omega_set];
pres_ctrl.Aresd_nom = eye(2) + pres_ctrl.Ares_nom*glb_time.ts_inv;
pres_ctrl.a11d = 1;
pres_ctrl.a12d = glb_time.ts_inv;
pres_ctrl.a21d = -pres_ctrl.omega_set^2*glb_time.ts_inv;
apres_ctrl.a22d = 1 -2*pres_ctrl.delta_rpi*pres_ctrl.omega_set*glb_time.ts_inv;

pres_ctrl.Bres = [0; 1];
pres_ctrl.Cres = [0 1];
pres_ctrl.Bresd = pres_ctrl.Bres*glb_time.ts_inv;
pres_ctrl.Cresd = pres_ctrl.Cres;
%[text] #### SOGI (second order generalized integrator)
sogi_delta = 1;
kepsilon = 2;
sogi = sogi_filter(omega_set, sogi_delta, kepsilon, glb_time.ts_afe); %[output:8834c3b4]
%[text] #### Current control parameters DQ PI
dqvector_pi.kp_inv = 0.5;
dqvector_pi.ki_inv = 45;
dqvector_pi.pi_ctrl = dqvector_pi.kp_inv + dqvector_pi.ki_inv/s;
dqvector_pi.pid_ctrl = c2d(dqvector_pi.pi_ctrl, glb_time.ts_inv);
dqvector_pi.plant = 1/(s*grid_emu.trafo.Ld1 + 1);
dqvector_pi.plantd = c2d(dqvector_pi.plant, glb_time.ts_inv);

G = sogi.fltd.alpha * dqvector_pi.pid_ctrl * dqvector_pi.plantd;
figure; margin(G, options);  %[output:28696d4e]
grid on %[output:28696d4e]
%[text] #### Single phase inverter - with resonant PI and virtual DQ
single_phase_inverter_ctrl = ctrl_single_phase_inverter_setup(glb_time.ts_inv, pres_ctrl.omega_set, ...
    dqvector_pi.kp_inv, dqvector_pi.ki_inv, pres_ctrl.kp_rpi, pres_ctrl.ki_rpi, pres_ctrl.delta_rpi);
%[text] #### 
%[text] ### Local time alignment to master time
kp_align = 0.25;
ki_align = 18;
lim_up_align = 0.05;
lim_down_align = -0.05;
%[text] ### Simulation parameters: speed reference, load torque for energy production application
run('n_sys_generic_1M5W_torque_curve');
torque_overload_factor = 1;
%[text] ### Simulation parameters: speed reference, load torque for driver application
% rpm_sim = 3000;
rpm_sim = 17.8;
% rpm_sim = 15.2;
omega_m_sim = psm.omega_m_bez;
omega_sim = omega_m_sim*psm.number_poles/2;
tau_load_sim = psm.tau_bez/5; %N*m
b_square = 0;
%[text] ### Settings Global Filters
filters = setup_global_filters(glb_time.ts_afe, glb_time.ts_inv, glb_time.ts_dab, glb_time.tc);
%[text] ## Power semiconductors modelization, IGBT, MOSFET,  and snubber data
%[text] ### Diode rectifier
% ABB 5SDF 0131Z0401 (slow recovery)
diode.rectifier.Vf = 0.977;
diode.rectifier.Rdon = 22e-6;
diode.rectifier.Cj = 0;             % F
diode.rectifier.Irm = -75;          % A
diode.rectifier.didt = -30;         % A/us
diode.rectifier.trr = 5;            % us
diode.rectifier.Qrr = 325e-6;       % C
diode.rectifier.Ifm = 2000;         % A
diode.rectifier.Vr = -50;           % V
diode.rectifier.Err = 15e-3;        % J
diode.rectifier.Rth_JC = 0.004;     % W/K
diode.rectifier.Rth_CH = 0.003;     % W/K

diode.rectifier.Rsnubber = 1e4;     % Ohm
diode.rectifier.Csnubber = 1e-12;     % F
%[text] ### HeatSink settings
% Aluminum plate liquid cooled with a size fit for primepack2
% heat exchange made by an aluminum plate with a liquid flow > 28 l/min
% "A" as "ambient" here means water: so HA means delta temperature between water and
% heatsink surface
% moreover the delta temperature between water in and water out is maximum
% 5K assuming a overall power losses of 2kW 

weight = 0.150;                         % kg
no_weight = 0.150/10;                   % kg - when /10 is applied thermal inertia is not accounted 
cp_al = 900;                            % specific heat_capacity J/K/kg - aluminum
heat_capacity_hs = cp_al * weight;      % J/K
thermal_conductivity_al = 160;          % W/(m K) - aluminum
Rth_switch_HA = 15/1000;                % K/W 
Rth_mosfet_HA = Rth_switch_HA;          % K/W
Rth_diode_HA = Rth_switch_HA;           % K/W
Tambient = 40;                          % degC - water temperature
DThs_init = 0;                          % degC

heatsink = liquid_cooled_plate_2kw_setup(weight, no_weight, cp_al, heat_capacity_hs, thermal_conductivity_al, ...
    Rth_switch_HA, Rth_mosfet_HA, Rth_diode_HA, Tambient, DThs_init);
%[text] ### DEVICES settings (IGBT)
used_device = 'infineon_FF1200R17IP5';

igbt.inv = device_igbt_setup(used_device, glb_time.fPWM_INV, hwdata.inv.udc_nom);
igbt.afe = device_igbt_setup(used_device, glb_time.fPWM_AFE, hwdata.afe.udc_nom);
igbt.dab = device_igbt_setup(used_device, glb_time.fPWM_DAB, hwdata.dab.udc1_nom);
igbt.psfbc = device_igbt_setup(used_device, glb_time.fPWM_PSFBC, hwdata.psfbc.udc1_nom);
igbt.cllc = device_igbt_setup(used_device, glb_time.fPWM_CLLC, hwdata.cllc.udc1_nom);
igbt.isop_rail = device_igbt_setup(used_device, glb_time.fPWM_ISOP_RAIL, hwdata.isop_rail.udc1_nom);

%[text] ### DEVICES settings (MOSFET)
used_device = 'danfoss_SKM1700MB20R4S2I4';

mosfet.inv = device_mosfet_setup(used_device, glb_time.fPWM_INV, hwdata.inv.udc_nom);
mosfet.afe = device_mosfet_setup(used_device, glb_time.fPWM_AFE, hwdata.afe.udc_nom);
mosfet.dab = device_mosfet_setup(used_device, glb_time.fPWM_DAB, hwdata.dab.udc1_nom);
mosfet.psfbc = device_mosfet_setup(used_device, glb_time.fPWM_PSFBC, hwdata.psfbc.udc1_nom);
mosfet.cllc = device_mosfet_setup(used_device, glb_time.fPWM_CLLC, hwdata.cllc.udc1_nom);
mosfet.isop_rail = device_mosfet_setup(used_device, glb_time.fPWM_ISOP_RAIL, hwdata.isop_rail.udc1_nom);
%[text] ### 
%[text] ### DEVICES settings (Ideal switch)
used_device = 'silicon_high_power_ideal_switch';
ideal_switch = device_ideal_switch_setting(used_device, glb_time.fPWM_AFE, hwdata.afe.udc_nom);
ideal_switch.afe = device_ideal_switch_setting(used_device, glb_time.fPWM_AFE, hwdata.afe.udc_nom);
ideal_switch.inv = device_ideal_switch_setting(used_device, glb_time.fPWM_INV, hwdata.inv.udc_nom);
ideal_switch.dab = device_ideal_switch_setting(used_device, glb_time.fPWM_DAB, hwdata.dab.udc1_nom);
ideal_switch.psfbc = device_ideal_switch_setting(used_device, glb_time.fPWM_PSFBC, hwdata.psfbc.udc1_nom);
ideal_switch.cllc = device_ideal_switch_setting(used_device, glb_time.fPWM_CLLC, hwdata.cllc.udc1_nom);
ideal_switch.isop_rail = device_ideal_switch_setting(used_device, glb_time.fPWM_ISOP_RAIL, hwdata.isop_rail.udc1_nom);
%[text] ### 
%[text] ### Setting Global Faults
time_aux_power_supply_fault = 1e3;
%[text] ### Lithium Ion Battery
% nominal_battery_voltage_1 = hwdata.cllc.udc1_bez;
nominal_battery_voltage_1 = hwdata.dab.udc1_bez;
% nominal_battery_voltage_1 = hwdata.afe.udc_nom;
% nominal_battery_voltage_2 = hwdata.cllc.udc2_bez;
nominal_battery_voltage_2 = hwdata.dab.udc2_bez;
% nominal_battery_voltage_2 = hwdata.afe.udc_nom;
nominal_battery_power = 250e3;

% nominal_battery_voltage_1 = catenary_nominal_voltage * 1.5;
% nominal_battery_voltage_2 = catenary_nominal_voltage * 1.5;
% nominal_battery_power = catenary_nominal_power;

initial_battery_soc = 0.85;
lithium_ion_battery_1 = lithium_ion_battery_setup(nominal_battery_voltage_1, nominal_battery_power, initial_battery_soc, glb_time.ts_dab); %[output:5a532cea]
lithium_ion_battery_2 = lithium_ion_battery_setup(nominal_battery_voltage_2, nominal_battery_power, initial_battery_soc, glb_time.ts_dab); %[output:079b8d53]

% special settings for simulation
lithium_ion_battery_1.R0 = lithium_ion_battery_1.R0/2;
lithium_ion_battery_1.R1 = lithium_ion_battery_1.R1/2;
lithium_ion_battery_2.R0 = lithium_ion_battery_2.R0/2;
lithium_ion_battery_2.R1 = lithium_ion_battery_2.R1/2;
lithium_ion_battery_1.C1 = lithium_ion_battery_1.C1/200;
lithium_ion_battery_2.C1 = lithium_ion_battery_2.C1/200;

%[text] ### Setting for Load Transformer
% special settings
trafo_load_name = 'Load Single Phase Transformer';
trafo_load_pwr_nom = 225e3;
trafo_load_u1_nom = 400;
trafo_load_n1 = 50;
trafo_load_n2 = 1;
trafo_load_u2_nom = trafo_load_u1_nom/trafo_load_n1*trafo_load_n2;
% trafo_load_f_nom = 50;
trafo_load_f_nom = frequency_set;
trafo_load_eta = 98;
trafo_load_ucc = 5;
trafo_load_i1m = 10;
trafo_load_p_iron = 2e3;

output_transformer = single_phase_transformer_setup(trafo_load_name, trafo_load_pwr_nom, trafo_load_u1_nom, ...
    trafo_load_u2_nom, trafo_load_n1, trafo_load_n2, trafo_load_f_nom, trafo_load_eta, trafo_load_ucc, ...
    trafo_load_i1m, trafo_load_p_iron);

uload = 2;
rload = uload / output_transformer.i2_nom;
lload = 250e-6 / output_transformer.n12^2;

% rload = 0.86/m12_load_trafo^2;
% lload = 3e-3/m12_load_trafo^2;
%[text] ### C-Caller Settings
open_system(model);
Simulink.importExternalCTypes(model,'Names',{'mavgflt_output_t'});
Simulink.importExternalCTypes(model,'Names',{'dsmavgflt_output_t'});
Simulink.importExternalCTypes(model,'Names',{'mavgflts_output_t'});
Simulink.importExternalCTypes(model,'Names',{'bemf_obsv_output_t'});
Simulink.importExternalCTypes(model,'Names',{'bemf_obsv_load_est_output_t'});
Simulink.importExternalCTypes(model,'Names',{'dqvector_pi_output_t'});
Simulink.importExternalCTypes(model,'Names',{'sv_pwm_output_t'});
Simulink.importExternalCTypes(model,'Names',{'sv_pwm_cm_output_t'});
Simulink.importExternalCTypes(model,'Names',{'global_state_machine_output_t'});
Simulink.importExternalCTypes(model,'Names',{'first_harmonic_tracker_output_t'});
Simulink.importExternalCTypes(model,'Names',{'dqpll_thyr_output_t'});
Simulink.importExternalCTypes(model,'Names',{'dqpll_grid_output_t'});
Simulink.importExternalCTypes(model,'Names',{'rpi_output_t'});
Simulink.importExternalCTypes(model,'Names',{'phase_shift_flt_output_t'});
Simulink.importExternalCTypes(model,'Names',{'sogi_flt_output_t'});
Simulink.importExternalCTypes(model,'Names',{'linear_double_integrator_observer_output_t'});

%[text] ### Remove Scopes Opening Automatically
open_scopes = find_system(model, 'BlockType', 'Scope');
for i = 1:length(open_scopes)
    set_param(open_scopes{i}, 'Open', 'off');
end

%[text] ### Enable/Disable Subsystems
% if use_mosfet_thermal_model
%     set_param('afe_inv_psm_n/afe_abc_inv_psm_mod1/afe/three_phase_inverter_mosfet_based_with_thermal_model', 'Commented', 'off');
%     set_param('afe_inv_psm_n/afe_abc_inv_psm_mod1/afe/three_phase_inverter_igbt_based_with_thermal_model', 'Commented', 'on');
%     set_param('afe_inv_psm_n/afe_abc_inv_psm_mod1/afe/three_phase_inverter_ideal_switch_based_model', 'Commented', 'on');
%     set_param('afe_inv_psm_n/afe_abc_inv_psm_mod1/inverter/inverter/three_phase_inverter_mosfet_based_with_thermal_model', 'Commented', 'off');
%     set_param('afe_inv_psm_n/afe_abc_inv_psm_mod1/inverter/inverter/three_phase_inverter_igbt_based_with_thermal_model', 'Commented', 'on');
%     set_param('afe_inv_psm_n/afe_abc_inv_psm_mod1/inverter/inverter/three_phase_inverter_ideal_switch_based_model', 'Commented', 'on');
% else
%     if use_thermal_model
%         set_param('afe_inv_psm_n/afe_abc_inv_psm_mod1/afe/three_phase_inverter_mosfet_based_with_thermal_model', 'Commented', 'on');
%         set_param('afe_inv_psm_n/afe_abc_inv_psm_mod1/inverter/inverter/three_phase_inverter_mosfet_based_with_thermal_model', 'Commented', 'on');
%         set_param('afe_inv_psm_n/afe_abc_inv_psm_mod1/afe/three_phase_inverter_igbt_based_with_thermal_model', 'Commented', 'off');
%         set_param('afe_inv_psm_n/afe_abc_inv_psm_mod1/afe/three_phase_inverter_ideal_switch_based_model', 'Commented', 'on');
%         set_param('afe_inv_psm_n/afe_abc_inv_psm_mod1/inverter/inverter/three_phase_inverter_igbt_based_with_thermal_model', 'Commented', 'off');
%         set_param('afe_inv_psm_n/afe_abc_inv_psm_mod1/inverter/inverter/three_phase_inverter_ideal_switch_based_model', 'Commented', 'on');
%     else
%         set_param('afe_inv_psm_n/afe_abc_inv_psm_mod1/afe/three_phase_inverter_mosfet_based_with_thermal_model', 'Commented', 'on');
%         set_param('afe_inv_psm_n/afe_abc_inv_psm_mod1/inverter/inverter/three_phase_inverter_mosfet_based_with_thermal_model', 'Commented', 'on');
%         set_param('afe_inv_psm_n/afe_abc_inv_psm_mod1/afe/three_phase_inverter_igbt_based_with_thermal_model', 'Commented', 'on');
%         set_param('afe_inv_psm_n/afe_abc_inv_psm_mod1/afe/three_phase_inverter_ideal_switch_based_model', 'Commented', 'off');
%         set_param('afe_inv_psm_n/afe_abc_inv_psm_mod1/inverter/inverter/three_phase_inverter_igbt_based_with_thermal_model', 'Commented', 'on');
%         set_param('afe_inv_psm_n/afe_abc_inv_psm_mod1/inverter/inverter/three_phase_inverter_ideal_switch_based_model', 'Commented', 'off');
%     end
% end

% if use_torque_curve
%     set_param('afe_inv_psm_n/fixed_speed_setting', 'Commented', 'off');
%     set_param('afe_inv_psm_n/motor_load_setting', 'Commented', 'on');
% else
%     set_param('afe_inv_psm_n/fixed_speed_setting', 'Commented', 'on');
%     set_param('afe_inv_psm_n/motor_load_setting', 'Commented', 'off');
% end

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"onright","rightPanelPercent":18.5}
%---
%[output:3cc89de2]
%   data: {"dataType":"text","outputData":{"text":"Device AFE_THREE_PHASE: afe690V\nNominal Voltage: 690 V | Nominal Current: 2.324276e+02 A\nCurrent Normalization Data: 328.70 A\nVoltage Normalization Data: 563.38 V\n---------------------------\n","truncated":false}}
%---
%[output:1001385e]
%   data: {"dataType":"text","outputData":{"text":"Device INVERTER: inv690V_250kW\nNominal Voltage: 550 V | Nominal Current: 370 A\nCurrent Normalization Data: 523.26 A\nVoltage Normalization Data: 449.07 V\n---------------------------\n","truncated":false}}
%---
%[output:285e0d10]
%   data: {"dataType":"text","outputData":{"text":"Single Phase DAB: DAB_1200V\nNominal Power: 250000 [W]\nNormalization Voltage DC1: 1200 [V] | Normalization Current DC1: 250 [A]\nNormalization Voltage DC2: 1200 [V] | Normalization Current DC2: 250 [A]\nInternal Tank Ls: 3.819719e-05 [H] | Internal Tank Cs: 1.151294e-04 [F]\n---------------------------\n","truncated":false}}
%---
%[output:3c8fbcdd]
%   data: {"dataType":"text","outputData":{"text":"Single Phase PSFBC: PSFBC_1200V\nNominal Power: 275000 [W]\nNormalization Voltage DC1: 1200 [V] | Normalization Current DC1: 250 [A]\nNormalization Voltage DC2: 1200 [V] | Normalization Current DC2: 250 [A]\nInternal Tank Ls1: 3.030303e-05 [H] | Internal Tank Ls2: 3.030303e-05 [H]\n---------------------------\n","truncated":false}}
%---
%[output:483a813d]
%   data: {"dataType":"text","outputData":{"text":"Single Phase DAB: Three_phase_DAB_1200V\nNominal Power: 750000 [W]\nNormalization Voltage DC1: 1200 [V] | Normalization Current DC1: 750 [A]\nNormalization Voltage DC2: 1200 [V] | Normalization Current DC2: 750 [A]\nInternal Tank Ls: 4.000000e-05 [H] | Internal Tank Cs: 750 [F]\n---------------------------\n","truncated":false}}
%---
%[output:23717450]
%   data: {"dataType":"text","outputData":{"text":"Single Phase CLLC: CLLC_1200V\nNominal Power: 250000 [W]\nNormalization Voltage DC1: 1200 [V] | Normalization Current DC1: 250 [A]\nNormalization Voltage DC2: 1200 [V] | Normalization Current DC2: 250 [A]\nInternal Tank Ls: 2.580123e-05 [H] | Internal Tank Cs: 4.734509e-06 [F]\n---------------------------\n","truncated":false}}
%---
%[output:61f2e687]
%   data: {"dataType":"image","outputData":{"dataUri":"data:image\/png;base64,iVBORw0KGgoAAAANSUhEUgAAAQQAAACdCAYAAABSFgY1AAAQAElEQVR4AeydC7xNVf7Af1uPuXKbIgoNLqnQwxUKKY8xKiIUg5mkh7oYDQojlavkGanxrNRfeTSkQkTe45ZHyTtEXJlCCEkuMvd\/vyvrdO6Zc84959y9z9nn3OXjd\/fea63922v99lm\/\/Vu\/1yqUbf4ZChgKGAqco0AhMf8MBQwFDAXOUcAwhHOEMAdDAUMBEcMQzK\/AUCBBKGDHMAxDsIOKBoehQIJQwDCEBHmRZhiGAnZQwDAEO6hocBgKJAgFDENIkBdphhHfFHBL7w1DcMubMP0wFHABBQxDcMFLMF0wFHALBQxDcMubMP0wFHABBQxDcMFLMF2IbwokUu8NQ0ikt2nGYiiQTwoYhpBPArrt9k2bNsktt9wit912m9x+++1SvXp1adu2rXz33Xchd3X8+PGyaNGikNrTrlKlSrme99xzz8lPP\/0kJ06ckKeeekq2bt0aEi7TKPYUMAwh9u\/A9h6kpqbKRx99JP\/+979lzZo1ctVVV6lr2x90DuFNN92k8PO8jIwMVTpkyBD53e9+J4MGDZLKlSurskj+ZGdny9mzZyO51dwTAQUMQ4iAaPF0y+nTp+XHH3+Uyy+\/XM6cOSPDhg1TEgRSBOeUAUOHDpWaNWvKn\/70J\/niiy\/UEJmMkydPVpJG3bp1RX\/5VWWAP4ULF5aOHTvKli1bZMeOHfLYY48JUsvx48elZ8+eUqtWLbn55pvlxRdfVP2h\/PHHH1dlf\/3rX6VTp06qPVJKly5dpFmzZrJy5UpZunSp6kedOnXk7rvvls2bN8v3338v9957r\/Tv31\/oH5LQW2+9JQ0bNlT4lixZEqCXvxWbs9wUMAwhNz0S4mrVqlVy4403SoUKFeS6666TgwcPqsk0f\/582bt3r\/AVB3744Qd57733hPL\/\/Oc\/SqLgGgYCIWiDuL948WJZsWKFFClSRGbNmkVVUChWrJgUL15cmOy64erVq6VixYpqcvO87du3y759+2TixIlKgqAeqeLQoUP6FqF\/06ZNU2P5+OOPBeb06aefKoYDDhoeO3ZMatSoofpXunRpAe\/ChQtl+PDhqq+\/\/PILzQyESAHDEEIkVDw14yu8ceNG2bVrl\/pK8\/V89tln5ZNPPpEmTZrIBRdcoKBRo0by2WefyfLly1U5X\/eLL75YfW0ZL5OUCXnttdeqZceYMWNk3bp1VIUNDRo0UHqG6dOnq2UEjObAgQPy1VdfCV99y7LkyiuvlBtuuMGDu379+kJ\/fv\/730vv3r1V25deekmmTJki+\/fvV+2QfJB2LMuSQoUKqb6fd955AlPKysoSQMy\/kClgGELIpIrPhkyOevXqqYlx8uRJxQj0SFgqwBz0te8RpSATEcYCMInT09N9m\/3PNV92pAOkBF35xhtvyIQJEwTm0qNHDyW5sCRBP8BEph3nLHE49wYUop07dxakhzZt2sijjz7qXZ3rPNh4cjU0F34pYBiCX7IkTiGTDtE\/KSlJ6Q6wCsAIgHnz5qmvM7oDzik7cuSIsESAAqz1EdGZ3DAT1uosHagLBLQbN26cVKlSRektdDtE+aZNmwoKTyY4zAWJBDGf\/tHPPXv2CJKNvkcfDx8+rCQFdAd8+XX\/dL052kcBwxDso6VrMK1fv17uuusupTeoXbu2Wir06dNHWrdurURplhBAmTJl5M4775TmzZurckT3hx56SEqVKqXGwpICZsER8Z3JyLmq9PqDElI\/D7xMdBSIXk3UswcOHKhEetb46DjeeecdpUSEydTKUTZiorziiiu8b1Pn6B6KFi0qSDrt27dXzGbDhg1qCaEamD+2UcB1DAH7NYottMfY0QHOKaPOtpEnKCLW4Kz9mWSYAVEwoozjS4w4zRKAeoBzypjAAwYMUPqE999\/X8aOHStMfOq6desmtAV0e2\/S0W7btm1Kqcfz1q5dK+grkpOTBWCZQJ9Y56PDQBpg4o8ePVpeeOEFQQKBWYH\/5ZdfVnoAlhppaWkC8Cz6h0UE3PQPpgVTgflMnTrVI4lguaA\/3MMzeTZ94NpAaBRwDUNAZORH3KFDB6Uwwn797rvvCsCLhhlglpo9e3ZoIzOt4oICODXBIG699VZBP8A71hJKXAwgwTrpGobAOhUF2IwZMwT7M8onNMhA+fLlBUYxc+ZMjzibYO+hwA1HD\/j666+XuXPnqmUNEgbWCF1njtGngGsYAqYlxErMUNjNUU4hDvL14Mg1DIM1bfTJZJ5oKFAwKOAahoADCVrsBx54QHmisU7E0wxNN+vLkSNHCsuKgvFazCgNBWJDAdcwBMxduKIiPrJswB6Nq2yLFi2UyyyOKNihY0Mm81RDgYJBAdcwBL7+LBvQKGMzJzDm\/PPPV2+BpQLXtFEF5k9MKWAenrgUcA1DSFwSm5EZCsQPBVzFEHCPxR5OkMvXX38tHFEqUkZd\/JDV9NRQID4p4BqGQBALTjB4xP3xj39Uzi0csU9TRh1t4pPMpteGAvFBAdcwhAsvvFCwSWNW9AfU0SY+yOreXpqeGQoEo4BrGAIRckgB9913nzI7apdl3JZJ2jFq1CiVkivYYEydoYChQP4o4BqGUKJECSHYZcGCBSprDynAcGUGiGNgmPjWczRgKGAo4AwFXMMQ9PBwYcYrEQahy4iAo4w6XWaOhgKGAvZTwHUM4ZJLLpFTp06pZBrEzQNvv\/224KhU0JWK9r9+g9FQIDcFXMcQcEAaPHiw4Mrctm1bFUdPvr\/nn39ecFrK3X1zZShgKGAnBVzDEFgS4J7M4PBYJEae6Ddi6ImbJ0EGdboN5wYMBQwF7KWAaxgCbspz5sxRSTEIZiL\/gR4q5yQCJWEGbXS5ORoKGArYSwHXMAQsCOTkf+aZZ4T8fsTFk0YcaNy4sYqXJ9iJNvaSIDrYzFMMBeKBAq5hCJpYpOLGVZn04LgrA6TZwoWZZCm6nTkaChgK2E8B1zEE+4doMBoKGAqESoGEZwiETLO9F4lWSMo5adIks1dgqL8O0y5qFPjlYKYcX\/Z\/cnDMg1F7pr8HJTxDIEU4GXrxgMT7kSxMLEc0MdBR5AWmvoLaFs7QwT461KlUVjrXvFzGNbxY3r+zsHzTpbxseqmTZMx5xy+t9e\/V6aMrGcLmzZuF\/QLIw88EZqceHJQiIQaTn1yNmC1xbCJw6vPPP8+FCj2FncBGInbiA5cTOJ3C60RfncAZ7fF\/tXqJrB3ygGR0KCeTb9grvVIOStNKxaVus7ZSOn2p1Jl1RlrOP6m24KNv3gAzlij8cx1DwB+BfPrdu3dXe\/1VrlxZmjVrpvYDpC5cmuzcuVP+8Ic\/eG676qqrJDMz03P9U93e8qcRK22FB6btsRUf\/Xv0vf2243QKbyh9vT59hQSDYj2XijdU\/2dmrmvu7fvOOvlkww7ZvXt3xIDTW37u93cvPy5V\/sUK2T3jRdk19D7Z1dpSUsCRRa9LVuHLxGozXKxhu+RsryXyU5NnZd9F5YKOAZzRANcxBOIV8FYkDTsEIH0aJkjSqlFHWbgAvkD3FPr5kFxT+lJboXyJIrbis7t\/bsB3f+0y4g82p98mwA8jG0gw4N4th0WaTfqPtJyyX0jVHwnwsYjkPn\/3lEm2pPie5ZI87zn53aSHJHvw7XLe0jGSdPKwlOj6ppICKry6Vyr0eVfKt34yrD4H+v3aXe46hoBYj5MSW4XrwbIPIAlWI3FdTklJEbIvaVycI3Xo64u+eEPGtKtsK6Q3Km4rPvr3ZK0k23E6hTeUvva5I0X8gX4vvke+uN5l3Du7azXFNG696lIlPaQOXOndxPFzFIHAkekD5Lv0BkoCQCl4fMMiKVylvmIAZcfuVseL63eUpOvqO96n\/D7AdQyBSc\/uPenp6cLWXewZ+Le\/\/U169OghMItgA8ZfgSxLWBSaNGki6CJq1aoleDeiOyD7EufsKxgMjxvr+CI50S8n8EYbJ4xt\/dO1pWzRJMUYhi7IdIJUCicMQFsDUAQCXF9QIkVJARVmZAtSQNE2\/eOCAahBef1xHUOgb2RHwiqwcuVKmT9\/vtr\/r2rVqlQFBNK4\/\/Of\/xS2fVuzZo107txZXnnlFRUlSaAUnpD\/\/e9\/BeA6ICJTEZcUKFssSZAYZnepJtM+2ydIC3YxBiY8X34tBRzJkQggkpr8OQwAKYAlAVIA5fEMrmEI7NZEdCOZkgAsDC1atBAyJqFDoI42gYhNXUpKilx99dWqCUzl8OHDipm0bNlSHWEw99xzj5I8VCPzJ+EoULfipYK00K5mKRm6YLdiDJEMkkkPA0AZyPnJLcvUMgAmoBlAJHjdfo9rGAJbjfOFnz59utqe\/OGHHxYyKAEsIVgCFC9ePCA9r7nmGiFsOjk5Wc6cOSNkWSLJClpkFEf6Rl8rA+WsT+0EnmknPnCROYqj3eAEXjfgbHNNtsx54A9yV8VflxHX51g1\/NHO866wBvyjtrIGKCbgZQ3AEgAcrdkhqCVA43di\/PxOowGuYQhYE5jAHAlxRjIoXbq0AO3bt5eNGzcKikVNFHZ5QorAPvvkk0\/qYmFvyDZt2sj27duFHAooKINZGbiRNa+dAAOyEx+4nMDpFF4n+hoJzlurXi2D21ZTEkOFEsmC6XL6V5Z4WwOufOV2ye5dQVkDLi5TSZAAFERoDXCKpvxOowGuYQh6sGRWZuLjP6DLDhw4oJgBzEKXEei0fPly5cSB3iA7O1twUe7atauSMHBkooxlxLvvvisoGnFdZps4bdLUuOLhyA\/NiX46gddtOLV+YWHRV6XC2y0FReCGCX3lzMFM5QsAA7BzGeDE+J149\/5wuo4hkEKNDV+7dOkit912m4J27dpJhw4dhGWFv0FQhuiHBYHNXVBInjp1imLBQ3H9+vUyc+ZMgRkgacB0VKX5k7AU8FYEsgSACZQ6u18aNW8hMx7ZLc1LTZUm5w+SV1cfTVgaRDIwxxhCJJ3R96BE5Os\/depUIZ8ia7KGDRvqar9HJArMjDATlg179+5Vlgb8GVJTUwWmwjKE8x9\/\/NEvDjcXsj51on9O4I0mzqwcZZ\/v5IcBoAhEAsAfQEsAuAdjDsSHQSseJ6w5Klgk7KStE+O3s3\/BcLmOIWAtwKKAP8Ff\/vIXJRmwLwNl1AUaDExk5MiRcv\/998vcuXPlpptuknHjxgn6CFyfMzIylKUBprBnz55AaFxb7pQY6gReO3Ey2ZnceP95m\/6Y9ACWAOqxAnj7ArAE0AzA30tlGQFjWNstRbBIFOu5VDGGjJ35lxjsHL+\/vjtZ5jqGwLIAawPrfuC1116Tu+++W2655RYl\/mti+CoVWTLgs0AglLeugfbBlIqLqu\/2aJb5gdkBKKnswGNwWHJw6jOC\/\/\/xvdsEIA7gl3LV1dqfWAAACwBATMChcvVCsgTwFQf43WiLRInCIs3HrlMxI9S5CfgdRwNcxxCYzFgbUBoCKAB79uypHIq8RX3qWFYQEYZScdu2bcojsXr16lKrVi1ZtWqV2vAFz0fclTUxOfd2XL5EXwAAEABJREFUXW60tvxvmuUZ2bac8yNFTLUTnMBJ\/5zAaytOtP05YD02VSoMWaniAFQsQPnyYcUC8NX2B9p6gUVi4RO1ZXaXanLwpHgsEv7uyauM31pebcKtB2c0wC9DiMaDw3kG+oBvv\/026C2NGjUSlgUwg8suu0ylbEfSwBEJZWPNmjUlnl2Xgw7eVNpGAe3Y1OeO8srjkaWEbcjjAJHrGIL3UgAfAwBdAjoBLAaBaIo78vDhw6VVq1by4YcfqtBpnJy0q3K8uy7zRQk09vyUO4E3XnAGo1ufO1KU\/0KfHMYAU0DxOHRBZrBbPHVOjN+D3OET1zEEvu6zZ89WEYosBwD2ZkAxyOQORA\/8DtgwFmsEW7+hWMQxiYxJxnU5ENVMeV4U6HOOMaB41K7Q0z7bn9dtcVvvKobA\/gt4GPbr109IYoK0AKAfwBuR2IRAlD527JhyWSY7M9GMWBuOHj0qmCNZJ+r7\/Lku6zo3H1FwOdE\/J\/DGC85Q6aktEtpU2XXaVmWRCHS\/E+MP9Kw8y8Ns4CqGQLqz119\/Xb788ksZO3asjBo1SgG+COgIsEDo8cEovF2X8W6EmRADgfMRy4y+ffsqJhHMygA+XqCdgObaTnzgcgKnU3id6KsTOMMd\/9lj+6TNuRgJLBIsJcg65Zu1yYm+8juNBriKIeBLwLZtI0aMUIFKgwYNUqnTOP75z38W4hI0UXytDAQ+1ahRQ7QFATNloUKFpFSpUmr5oe\/ztTJQzprPTkAisRMfuPDa5Gg3OIE3XnBCy0jelbZIIDEUTkpSWZumf2V5rB5OjJ\/faTTANQwBpyOYAcehQ4cKugDCoDW0bdtWqAtElJSUFEGPgENTnTp1pGPHjoIikfuNlSEQ1Ux5fijAUsI7BwMSQ6iKx\/w818l7XcMQ8D1Ad1C2bFkh5JmNXr2BMtoEIgYhz0gQbBRrWZb8\/PPPQoYl4hawQMAcUEoCXAfC49ZyxFsn+uYE3njBaRc9657LwdAnxyKB4pFQa1sYg10dDAOPaxiCd5\/RD+BDgIJQA1KDt2OSd3t9zuQfNmyY8kdgiUHoNCnXjZVBU8gcnaRAn3MWiWaVkj3JWeKNMbiOIZBZuXv37kLKdRyJNBC+zFc+0AtF4ciyAkaAJWHatGkqoClRrAysdwONPT\/lTuCNF5z5oVuge1lG6BwM3qZKO2IkAj3TzvKYMwS++kgEAOcwAr7shD83bdpUNKBwxA1ZD5723lYG\/BXIh8DuTCgOMVPi0szyIBGsDIjhBnaHFacQCr2csAjwXG+LRNUrzvfESPhaJGgbCujfvdPHmDCEs2fPqohEFICYE++77z4BGjduLGRHgjFs2bIl6Nh9rQwwBByS0EFYliVYHPBbKFmyZEJYGSAGX167wQm88YITWkZiZeC+YKDGfy7WAovEpE41ldejtki8uCpLzruklMcqEQyXrgNnNCDqDAHno+eee05lQPrggw9kzZo1opWHBCRpPwTyF7BMwEoAsBwIZmUoU6aMskKQXQnCkcIdJSRSxLp164SlCMB5amoqTTyAe7SdAKOzEx+4nMDpFF4n+uoEzmiOv36NKrJ5xL2SnDFM\/rV8s3Js4vmhgufH6vBJ1BkCYv\/TTz8tJDLBCuA7vpQc8yFBSjt27MjFLPKyMpBkFVMjEgZmx8mTJwtRkgQ7wRTY3+GOO+4Qlh7ERejnIlkY2KVS0Rk6OE+Hb9Z8JIfGt5Y+ORaJcOmtf7NOHqPOEAhvRjnI156vPl9\/b9BLiN69e4u2MHAcMGCAkDkJ86I\/gliWJcQ7IG2wYcu\/\/vUvJZJZlqWSrMBkKCeDs2VZ\/lCYMkOBqFGgT45FImoPC+NBUWcIum9ELuJNyNKArz9WAXZ8hjlgPiSgqXbt2io5KuHPKBtxMBo4cKBGYY6GAs5QoABjjRlDYKclchwQhIRV4corr5THH39c6QFwLiJ\/AV\/8Fi1ayMsvv6x2YGI3JiIaC\/D7MkM3FHCUAjFjCElJSZKVlSVaCcgoWUYw4ZEGqKMMwCqBMhITItcGDAUMBZyhQMwYAgpFEp4iIRAMwlIBpyLW+PgNYA34xz\/+ofQIDz74oDIjokPAAckZUhishgKGAjFjCJC+fv368uabb0qvXr1kwoQJQoYjrAGEPs+aNUsFOOGpiDsyuzGxhMBCwb0GDAX8UsAU5osCMWUI+BzgUTh+\/HjBGQmXZTwNMTnCIJYtWyYoFydOnCgdO3ZUA8VCoU7MH0MBQwHbKRAzhoCuYMOGDSrvwaWXXqpMhKNHjxZSryMREI9Am6uvvlqKFCkinTp1EhyNJMi\/pUuXCksPrBf4IOCIxHZuuDTj5MRWbpMmTRJ0EkHQmCpDgQJLgZgxBCYlisWLLrrIQ3z0CiQ1gQGgX8DseP3110u3bt1kWY60wAT3NPY5wTSJJMFuT3g8wki4JqfiwoULhe3dkD6WLFkiZGbyud1cGgoYCuRQIGYMgQxHfPH5YmNVYPs1EqRQRs4CrA\/EK+zZs0dwZjpx4oSKgMzps9\/\/RDVyLxmSLMsSpIGtW7eq3ZqQGPB7gOFgziQk2i8SUxhbCpinx5wCMWMIlmUpvwOWBpgTiW\/AHwGvxNatW6tt2Nik5Y033pD6OcpHmEMwC0O5cuWEfRwBpI\/ly5erBKswGgJYNKV5XmZmpr40R0OBiClwZPoA8QdsOecERNzRMG6MOkNgsuJvQPgySwC8ExHtiT0gDgFpAT0AocsEfmBtYHL3798\/V05F3zESFUZiVdyhiV9gT8dKlSoJSxDMmL7t9TXPMFBBChINOte8XNLrFpNxDS+W9+8srODTey4IeUs\/2gJbpwwUf5Ax5x1xAvRv1slj1BkCikJ0AoQ7s2cjkx99AR6JBCU1aNBACEaiHCDKjd2XcHGGkQQiBlIGywR8FdARwGhIqVaxYsU8w5\/DDTLJq\/3ixYttDxZyAifjcAKvm3CuHfKAZHQoJ+zhqaFvzSLy0I2XyD2315CqDZpK3WZtpc6sMyFv40fbYJA67ktpOf+krfDEV6UC\/fRtLY86Q2CdT+wCSj52dUbRxyRGEkhJSVH6ApyT0C1gcdBASrVgSwaWCrg24w6NlEFwE4FSMBmcnJBGAM5TU1NtJWI0kCEBOfEc2\/B6dS5WOH85mKlE+O\/SG3i+9seX\/Z9cUCJFSnR90zPhy47dLUDp9KVitRmu6ry6n+9TJ8af706FiCDqDEH3i8nJxIVBUMZx5syZKpiJNT6iPz4K69evl0suuUSoR7lIW39APgQkDhyY0DlwjZRAqHO9evUEhyd\/4c\/+cJmy+KFA1pZlwnp9V2tLvulSXjQDqDAjWzEAJj7M4OL6HeNnUDHsacwYApP81KlTykOR9OkAJkPW++gLMB0OGDBAOJKSnWUGzkuBaGVZliBZEOK8evVqIXwaJybLshIi\/Jk0W4HGnp9yJ\/BGA6dmAkgDJ3OYQtHW6bkYQH5okt97nRh\/fvsU6v0xYwhM\/MGDBwtrf6QBLAvkt2M\/RpKoYHqkLtSBJHo7p8RQJ\/DajZOlQPE9y3NJAmdylgfeUkDRNv1d8xOwe\/zRHFjUGQLLBCwADJIw5z59+qgUargoY3pkSzaO+A7AHLAY4EyEDoH23BcOZGdni\/FUzINiLqxG9EcKQAJgKYB5TzMBlgGs\/13Y7bjvUtQZApp\/Ep2kpaUJoj1hzVARC0KTJk1U6vSVK1cKEgOmRxSAx44dU3kSMFnSNhwwnorhUCs2bb0nP7oAAGbAUgCFIJKAYQLReTdRZwis64lLeOaZZ2TevHkqxyE2cCQCvBJJkYauYO7cuSoTM+ZJAB0CJstwyYIJEtzx7qno1LrUCbwaJ191JrYGvvYAE94baKcnPwpAGAAAE+Cad65xcu52iKe++tIy6gxBd4AMSSgNmbDYw4Ft27YJAU8sH8iN6A2YKrE06PtDPeLSHMxTEdu094\/TjvPs3hU8Zi878IHDCZxO4aWvGe1KyZb3x8v2jPlyfO82Of7TcckqfJkCTH3WsF2i4WyvJQL81ORZOVSunt+9F9AvMdHsBifwOoEz1N97ftvFjCHkt+Ph3I8CM1D7RmvLK+00XyS7gB+6XbjyxHPOvBaNdjMe2S2+MKLVl+IN3et\/IcCwuvPkb9e9p6DG6UFS40BXD1RfWV1aTtmv4O\/zjsr0ryxZdaiwinhFIecPSKLjrzy\/ZXws8ovD934n+hro92t3ecIzhJSUlDw9Fe0maqLiI1OwL4xpV1m8YXbXaqJh\/dO11QYlP4xsIL7QrmYpAaDVtM\/2SddpW6VYz6Vqv4KhC0ysCXSJBSQ8QyCEGu9EHKEAzlFUxoLY+XkmonJ+7g90rxN4Q8GpGQvMA8ahGQZM4pOdRzzMQfc7FJy6bayP8dRXX1rFlCFgWSBvIn4IOBSRIEVbHXw7Gul1ongqIpZGSoNg9zmBNz84YRQwCRgEzEFLDd+eLRpsGK6qy8\/4Yz2QmDEEnI7Y4p1wZIjAWg4Lw\/Dhw5WzEmV2gGW52FPRjgEmMA6YA9IDjKH52HUJPFL3DC1mDAETIt6IRDMSokz2pE6dOqk9GKmLhESJnELNKTHUCbx24ixbLElgDK+2KqmWEc3HuJ8x2Dn+SOZBfu6JGUPAPZlgpZ9\/\/tnTf5YQMAOclzyFIZ6YFGohEipOm1W\/Mklmd6kmGV8flXhgCnFKZokZQyCdGUFLXbt2FbIaEdmIAxJ7MwQLcw5E6J07d6qIyERNoebUutQJvE7hrFvxUg9TcLMlwonxB\/rd210eM4bAQAhJ\/vDDD+Wll15SkYqcU0ZduBD1FGrhdtC0t4UCMAUUjkMX7JaMnUdtwWmQ\/EaBmDIE1vyEOpcsWVJGjRol5C8gh+Jv3Qt8Rgo28hzg9ox0AVeOJIUaT2DNZyc44alGEhk7+6hxOYE3GjhZQqRN3uTXq1GPLZRjvLwrfqfRgJgxBAKWyGrEkoEYBpSLixYtEoKR0CPkNXiSrpJrEZdngqCwWkSaQg1mYidgMbETH7icwOkUXif66otz4RO1pUKJZMHTkXFECr54I8XjfZ8TOPOaD3bVx4whkBwlOTlZrrjiClmzZo0QgISi8cILL4zI7GhSqEX2k+CHHNmdge+KFs7R7SqLG5WMTow\/MLXtrYkZQyBj0unTp+Xvf\/+7EO6Mi\/F7772ntn1H4RjuMEmZFnIKtZtuChe9ae9CCmCSRJ8AU3Bh9+KySzFjCAQcDRw4UOU\/YOs2nfyE5ChICuFS07JMCrVwaUZ71tkc7YRo48QciUejW8yRTozfzvcTDFfMGAKdYuJXrVpVLrvsMsnKyhKixGAO+CNQb8BQIBQKYHnAo5G2qQNXcjAQIQVixhBQAiIhNGvWTEiX3qpVK5UlCYsDm7\/mNR7u79evn2zatMnTFKsFezmQer19+\/ZC4tZESaHm1LrUCbyxwMnygRgI3JyRFmAMsfJVcGL8nh+5wycxYwhHjhwRrAnsz\/DEE0+ordumTJmiJAXLsgaTrRwAAAsKSURBVAIPO6cGa0SHDh2Ee3Mu1X9wvfnmmzJp0iQhwQp7PpCHEavFwoULVVv2gCA\/I0lZ1E3mT8JRADdnpAUYA74KsWYO8UbgQm7oMK7KBw4cELIokWSVyR2sXywx8GrEGcm7HZaLo0ePqiKWICgnmfxYMEwKNUWW\/\/njxHo31jiRFmAMKBw1c\/jkXEg1DAJAgkDnkL7okNgtSTgx\/v95cQ4VxIwhFC9eXFgekIodEev1119XHouI+egWgo23WrVq0rhxYwGHboe7M2HUuD4TQTlt2jSlsNy5c6dgF9btqMvMzNSX6ohzk52AT4Wd+MDlBE6n8DrR10hx1q9RRSZ0biibR9wrl37wsAe+\/3S6fD73LfloxVoZMWW+CpyCUYQCxdNmSDC4pf8CubzDeFvhp7q91W\/V6T8xYwiWZQm5EPr27at8ENiGDb8Ewp\/5snsPHE9Efrx4JuKh6F2nz3FQIt06y4Kvv\/5auEc7LGHR0O18j9xnYJfte1G6nabfzXtJgO\/fShMAaSJUODS+tQC9WtYUf9D6rnriBPj+dp24ji5D8BkB4c\/bt2+X+fPnC4lRrrnmGhXoxN4N3k2Z2PzAli9fLngoetfpc+pxcipbtqxYliU1atSQw4cPKykEBqHbcV65cmV9aY6GAhFTgGWJP\/BOKWfnecQdDePGmDEEJj1uyyNHjlRKQBSBAF6LJEoJYwyqKY5JmCvRRVCwdu1aFf2IVEHaNNKnAZynpqbSJGrAMqhdu3aC2Pvxxx9H7bnmQeFTYOvWrcLSEysVPjH8TsPHEr93xIwhMDlZIqA7GDRokGhgJyftpBQOWZEuOnbsKLxIzI6TJ0+Wnj17Sq1atQSmQBRlrDZ7RQJKS0sTPDEzMjJUEphwxmbaRo8CSKp8qNhn9Nlnn5W89FnR61l0nhQzhoCeAGLzVY9kqDCTCRMmyA033KButyxL8GlgLwfyMxI4Vb58ebV8wETJRKScDWEtK7hZUyG08Q9jpC+4axcpUkQwudqI3qCykQJ8qPBxsRFlXKEKnSHYNCx2ZSKX4vPPP6+2Z7vnnnvksccek6eeekoBdbSx6XExR8OPiy3okpKSVF\/IEEWkp7owf1xHAcKhX3nlFWnRooUgZeLY5rpOOtihQg7i9ouaL+RDDz0k3bt3FzwVcTKCOXANUEcbvze7rBA9BWKl7ha6DxhazZo1hVBsxkaaOO8ITiQj\/Cj0PeYYHQqE8q6Y\/LjPT5w4UTGD9evXC6n5otNDdzwl6gyBCYIDERMJ5yKUipZlKesBFgS2a6ONO8jjvxc4T6HzYK3JF1+3QlfAF4alCVvPoR\/BSQUfiR07dijPTNpHoiPRzzDH8CgQ7rv68ssv1TITUzXLUsuK7vIyvNHZ3zrqDAGtLRIBG6jgN8DkYHIhWts\/PGcwwrAwa7Zs2TLXAzCLsoM1G9ridVm6dGnBrIoyc9y4cSpWAyUnP7RcN5oLxygQ7rvi94hzGxYhTNjeTm2OdTLqiAM\/MOoMAaUNS4J7771XUlJS5JFHHlFa93jSG+AGjadk9erVPZRFO42yUHtPWpYlOFORDQrmgMSwePFi5WHpucmcOE6BcN8VSwZMwyinWb5alpEQHH9J7MPg\/RDE6HiSELz77n3O1wh9gXeZOXcnBcy78v9eoi4h+O9G\/Jci9bAUwAmJ0aCgQn9w7bXXcmnARRQw7yrwy4gJQyAC8cYbb1QiNWvqVatWKQciRGyciALFKwQeRuxrLMuSBg0aCHoErA3ffvut4DVZsWLF2HfO9CAXBSzLiuN3lWsotl9EnSFgSWDSEHvgD6ijje0jjQJC0sizZsXkiMfkww8\/LLhUR+HR5hFhUsC8K\/8EizpD8N+N+Cwl0xOBV7r3WBdwvV69erWglEJi0HXmGFsKmHcVGv0NQwiNTqaVoUCBoIBhCAXiNZtBuoMC7u+FYQjuf0emh4YCUaOAYQhRI7V5kKGA+ylgGIL735HpoaFA1ChgGELUSG0eFN8UKBi9NwyhYLxnM0pDgZAoYBhCSGQyjQwFCgYFDEMoGO\/ZjNJQICQKGIYQEpnc34h9KG6++WZhb0sNL7zwgvs7nkcP8fpkiz7Cy3EHJwuV9y2Me\/z48d5FnnOCy0aNGiVnzpzxlJmT4BQwDCE4feKqlkQzuExr6Nevn6f\/RF+S29FTEAcnMIEPPvgg4hwSJLYlHJ3guTgYriu6aBiCK16Dc53g69mlSxeVkXrlypWyefNmIbEtAVjsP8BXlKcvXbpUSF+PdEH6+vT0dCHqlK8yR9rwdeaLDHMhASltwcP+BUxe6sFJlmv20+zUqZNKfkP057Bhw9QOXSSVIXsUE71Hjx6i82DwJQd4jgbyIJKDkgQzuizQEWmI\/gBs9UcfTpw4ISQ8If09afsC3WvKf6OAYQi\/0SLuzx599FEVUk4YedWqVWXTpk1qTGyey16X5GYYPXq0jBkzRkhLz4QkpyX7X5JYdPr06Sp8mwnIBFc3+\/nDvWxoQgaoFStWCPkFZs2apVqSch5JhTZ8nT\/\/\/HMh1yTJSpctWyYwDZYBJJrdv3+\/7Nu3TzENEpqStkwhOfeH9lWqVDl39evBe4yMk8lODdIQkhHjJBMX+S7pF2Nh\/ISi085AcAoYhhCcPnFV++qrr3r2aNywYYNnz4r69esLX9rMzEwVhclXlMnEblIbN25UUgPb4DF5LMsSIgNJ9hJo8ExoJh4Mhs1zYTDsiEV7vs7kISTykz0zWKaQdJbJzj4chIejE0AaYXOd9evXq+37eJ5v7gjS7SUnJ4PWA95jJHy+VatWnjrydQ4YMEDYlAd9ChUwJVLgm9T3UCNvMAwhbxolTAvEZlLEwwSYTGSCnj17tjAZWQbogZ4+fVoQ8\/W17xFRvHfv3h7mg7SQnrPE8G2nr8FFFmN9ffToUWHyNmzYUEkkLFdIugvD0G3CPdL\/t99+W23f9+CDD6rMyeHiMO1FDEMoQL8ClGwks4URMIHmzp0rI0aMUElcEOnJ8kQ5ojfM4\/zzzxe+9FlZWUI5a3rIxdeXrz5fcCZ2\/\/79haUDdf4AJkTiGxgDaeq7deumdq9KTU1Vegp0G0gtvveWLFlSbQLsW+7vmmUJ42GpQJ91GyQU+s6uWbrMHANTwDCEwLRJuBqWBL169RIUg7feequQCTotLU0Q3VEeIn6Twg7GgNSAeM9169atlaYfXQNMgiUFk5wjyxH2neA8EMGaNm2qvtgo+Nq0aSNk3GZZwSTVqfS49r2fZ6AHYUL71nlfw2iQDr755hu1USvMBeUm+gz0FIyF\/T687zHn\/ilgGIJ\/usRdKZmb\/E1KJjygB8TaHWUgX3g2NGXvCMuyhD0m2Hkb6QCRm0loWZaQihydwcKFC+W1116TIUOGKKmBrzzlAMsHvso8n37oZ6WlpXn0EYMHDxbMfzyXZ1mWpSwMTNjmzZsrhqHv00csEqS2R6pgUtNfnqHrOfI8+kIdegz6D8DsYAKMlb0y8rMc4TkFBQxDKChv2mXjxJQJY0DiYNMbf92DCdx\/\/\/2CjgEG5a9NsDJMqqT4R8oJ1s7U\/UaBQr+dmjNDgV8pgHUAbf2vV878JZHunDlzlMQR7OuN1QKfAsuywu4IOhOWR0gvYd9cQG8wDKGAvngzbEMBfxQwDMEfVUyZiBgiFEQKGIZQEN+6GbOhQAAKGIYQgDCm2FCgIFLAMISC+NbNmA0FAlDAMIQAhInvYtN7Q4HIKGAYQmR0M3cZCiQkBQxDSMjXagZlKBAZBQxDiIxu5i5DgYSkwP8DAAD\/\/0nrkj0AAAAGSURBVAMAWcYevxraUHYAAAAASUVORK5CYII=","height":157,"width":260}}
%---
%[output:70048be9]
%   data: {"dataType":"text","outputData":{"text":"Induction Machine: ABB M3BP 355MLB 6 261kW\nIM Normalization Voltage Factor: 375.6 V | IM Normalization Current Factor: 581.2 A\nRotor Resistance: 0.00274 Ohm\nMagnetization Inductance: 0.00376 H\n---------------------------\n","truncated":false}}
%---
%[output:64e9b7ec]
%   data: {"dataType":"text","outputData":{"text":"Permanent Magnet Synchronous Machine: WindGen\nPSM Normalization Voltage Factor: 365.8 V | PSM Normalization Current Factor: 486.0 A\nPer-System Direct Axis Inductance: 0.00624 H\nPer-System Quadrature Axis Inductance: 0.00756 H\n---------------------------\n","truncated":false}}
%---
%[output:80e64617]
%   data: {"dataType":"text","outputData":{"text":"PSM EKF Fully controllable\nPSM EKF is stable.\n","truncated":false}}
%---
%[output:26e0189a]
%   data: {"dataType":"text","outputData":{"text":"IM EKF Fully controllable\nIM EKF is stable.\n","truncated":false}}
%---
%[output:8834c3b4]
%   data: {"dataType":"image","outputData":{"dataUri":"data:image\/png;base64,iVBORw0KGgoAAAANSUhEUgAAAQQAAACdCAYAAABSFgY1AAAQAElEQVR4AeydeYxVRfbHT\/9cBkETREUEHRsXXFBh3HBcIW4YNK4xbomMiQbHGYlGUJyoGBNxHZcJEdfBPTou8Q8XkIniqFGJCoJxR0fAcd9wXKKJv\/4UnJ7T1fe9u7zXr1+\/ewjfvrWcqjr1rapTVXep93+\/+j9nwBlwBlYz8H\/i\/5wBZ8AZWM2AG4TVRPjFGXAGRNwgeC9wBlqEgXpUww1CPVj0PJyBFmHADUKLNKRXwxmoBwNuEOrBoufhDLQIA24QWqQhvRp9m4Fm0d4NQrO0hOvhDDQBA24QmqARXAVnoFkYcIPQLC3hejgDTcBAIYNwzjnnyBZbbFERJ5xwgnz33Xd1rd6sWbNCefvtt598+umnNeW9ePFiGTVqVMiPeiTpG9dx3rx5NZVZj8T15CCLPj1RHjzCuUU92jRLfWy7o0eWNMgoD+hMvyEfwhVctb8k9SXiq4H8yJf88+hVLU+NYxyiE3nfdtttXfo9YTEKGQQtrNL1hRdekAkTJtQ8cCvlX+\/wFStWyPfff9+ZLSR+9NFHnf5mdvRkZ6p3vRk0p512Wrdsly1bJnvssYcw8LpF9nIAfeGZZ57p1GLlypXy3HPPdfqb3fH+++\/L66+\/LptttplsueWWqerWZBBoxNdee02WLl3aiZtuuikUSiM\/9NBDwd3sf9CVeqieSuKmm24q6623ngb3+nXSpEmB5\/nz58vgwYN7XZ88CmC4nnzyyZBk6tSpoR70GyYPOisRN9xwgyCHuyew4447yqJFi0LZBxxwQKYi0A9YYQwEhsKGNav79ttvF4zY8ccfL4MGDepUk3EK\/wr6P+O5JoPQmbtxbLzxxhUHETOEXaKwTErqAIQRp7KkM0V0cbLEUjmueZefRx11VMjv3XffDVf+fPLJJ4HE7bbbDm83xGVSbpKOsRwyzILIq562rsgjQ7wCeVUAN+GaFv\/hhx8edEWG2ZflIZ1V81E\/8YA05AG\/lE0YwE0YcYD0hCcBPZFRqD5JshrGrErHZPAr58Rh2C644AKcoR5wHzyr\/6CHlsMVHdF1dXTnJdaJdFpX1Y90pCcf5DsTV3E88cQTIRa9GTB4mHGZNHBXAttayqUs9EAf3Ipq5afJ2npofnE7oxc6LFiwIIzHvfbai6CKWHfddWXo0KH1\/5ZBG56St9pqKy7hfgIKxysGOggdGsKCYMcfiCKMuA5v+E+6K664IrjtH4hjENgwZvsDDzww80yzySabBMKs1ddOMGLECJt1cKNrXCYR6EgdGYz4qUcsh0xSPZAHyCODW4E8Zaq\/J67o2ijOaR9mI1sPZmudqXATB4\/wGfNBv0BXywn6wx3pFKSDO\/VXulYL1wGFzG677SannHIKzmC46OfBk+EPeqCPFUVfWweNIzxJljoiw5X6wwN+BauYeJsOz\/A9cuRIGT58uIomXrWuNa0QUGKnnXbqvDmHtaLylMiyUBv3rrvuEmQJ16UKyqrF1aUiSl1yySWIhT0PaegopAmB5g\/EKHGUhZzmCVkzZswIhsgkSXQOGTJEBg4cKHofgY7I\/QNmBGYTm4g4DAdh6E55lKv66cyRpx7kpaBMrfMjjzwSDBVxlEnZuC3YQlg59LjnnnsEa2\/lqrnz6FoL58xQuv2i09NXAEY9Sb+e6DNJ5VQLo30ZUMiMHz9e6Ou0Ef5KbUJcDOpNO9FXaF\/N49577+12n404ZJAlDWnJjxuC9AGdrJLk0BWdkUeWNLgxZHGfsG1AO9CfSV+TQaCwStDK0uFwI8dSUY0ECk6bNi10egYwFpfKoBSyLCNZTuImDWlxK3SJDzEaR55UHhkdnLirgS0O1v\/rr78WlqvcXMQ4DBs2rNvAIn8GHI3FFb\/Nm3qQR5562PTs87TOWHQsu43vCXceXWvhnP371Vdf3a0KGHU6JNAZs6f6TLfCUwLs4MMY0Db0FZJl7V\/IsmKl\/rjJg3bGTV+Hf9wK4pDBn9QHrrrqqnAPZH6F+0jaRmxp0JHxge7klwU1GQSsChVigCiYpSiYyrJaYIAw2AjTLQRuwGBkdsatFcGNVSQOtyJOq\/KUgx50KIDlI40OTtxpIG\/krVFiPzVgwIDEpHRcylJombFwlnrYNOihfowNOqi\/p69ZdK2Vcwy79hM14rZe9Be47ak+Y8tKc2OU2H8jhxHQQcpKgTDtL7jToGlUzrazhunVxlXqA6zUtO9xTdpC0JfR0equZXBlnGpbcGUcM45qMghkHINMAeEQ+uWXX+LMBO1wmYTrKKSNQPmArONGJAywxKXj4tatil3aEa554G529JauOtPRGS1\/LMV\/+OGHTLQh1FP6M0CYbCjDrmKs8UdXlubINAoYTNUBowp\/bDFYCagO6IRuGPmTTz5Zg6teMT6srutuEOJSN9xww7BHJzxuvHgm0IGJZSOONIo4rYZjfGg8iInBjKRy1a4sqSAUA6ZExisU0nN3Vx+dYWHZwxOOruiMGxSpB+l6Amx\/2AZVyruIrkU4x5Aym3HnndnX6hMvjZmNk1aOpIFru+Isoj\/5VAMDSvff1eRYkrM0ryZDXNx31c+ATepnpEnC559\/Lrr9ZjLCqCJnOcGPgQBsOeGWsKyou0FAEYACLFdQin0Rfiwtyx3ckM6NPwYSxHDTSQcm8dxc1I5DGtISrtAZnLKAhlfreCoTX\/v37y\/cM2BGIC86Y1pDaaNSj7jz5KlHrEu9\/DpQqBMGk3zhUzsUfpBH11o4t\/rEbQnnAH3YJrW3t0tP9BnyzwIGOYMdWZ2F7WTDYCSOvsvSHHc16E1zZJhU8OPO0s+QS4L2P+L0XQPcQO997Lvvvt3ugxGfBO3HNRkEGpEOheVX6HKGQa7LlZNOOim8iYYixCNLOtITdvrppws3XZgZuJlIGB2ZmQhZ0hBmwexPYxFGPHJAOxsdivyITwPLJTqiymHIktJibTFwyLFtoDxbD8IBaSkfd1o9kKkX4IFHdTSuDkDyJhxd4RN9CFOgayM4t31AuUMngH7owypNB5uVJx45y7XtM\/XmmkHOYEcnNYK4FUxe9G\/8GFgMLe5KIC\/2+dSBK35k4R3+cWcBq236JrL0c\/IDuAkDtD0rXfRDT8KSoJySHii3NRmEpIIIo+NBKoMcPwOOu\/I6gAlT2KU3YQx0wnAr6CRA\/XplyRTLQgR7Ul3Oq2za1Ta8HUw2HfW49tprwyNRDadOGDY6M2GsFmgUyo91QzapHqQrCjjmLnacPolHyo91Il2SLHoC4i2Kcg539AEt3+aJm7LsnXOVR2fiLcgDfjUMN2Hq50o68sSdB7Qd20bS0KYMFNwWdmLAwOoKzMpYN3qgj4ZpH4V3Dct6nT59eufkShrGGv2PK\/67775b0Ik+Qd8gLA8KGQQ6hV1CxW4angaNFUlKl0QKYTZPGhwQZjsN+ceyvJqaRgTxyJEf6eN8KIuwJDksOjqQFlAnG2brTt7IKJC1S71KZRAOkCet5ole+CmfMpEBKkecyhKeVL6GUX\/qhxzQcPIAlAVwx+XFsnFe5FcJcVryB5SVlMbWDTlAHrEsYcQpSJeHa82PfguH5BPXO0kGOcqmPNykJQ+V1avGIxPzRTsQRhx5aRqumk7zJW\/cyALc9AWu+F999dXwWJJ0pLew5SCbhEIGwRbi7u4MsE\/kpSaWYrqER4pwvSnJ0o+GJNxRnAE4da6L8xendIMQM1IHP5aYJRtZsZxj2Ylx0P0jS0a9v4KMozgDznVx7pJSukFIYqUOYSzZkpZkhLE8pCPXoZheyaLZCm1Grln9seWgvStth5qNR\/QpvUH44IMP5IMmwMKFC2VhHZGnTm+++abEQJePP\/5YqoEO5GgtBkpvEHiG2wzgyUg9kadO9913n8RAlxtvvFEsrrvuOrHgW5SzzjpLLHgcaIFMDCuP++KLL5YYNg1lXn755VINs2fPltkZwDP6NGAM01DNUGpcXzQVpTcIfbHRekvnfv36SQxerrHg61GLWB6\/lcedVB\/kFLyZ+OOPP0oMwhVvvfWWALZjFi+++KJYYOhi44ffGlAMT2yg8Fsj9Yc\/\/CG8PMU7EJUwbtw4yYJ99tlHsiCJp3qHld4gxEvlIn5eKa0GZoy0httggw0kCeuss05n+DbbbCPVwNkOvIxSCRz4onHcmbfg2br6OWpLQZ68tWmx\/vrrhzfgeAQGGLjSC\/8oNwYGxsIaJ3XzJmSMbbfdVixGjx4toyPwrN9i7NixMjaCjVd3nA9+W9YOO+wgvPuSBE7tUjSC4tIbhJdfflmqwc4uldyPPvqoVMOcOXPEzkBJ7r\/+9a+SBD5m0fDzzz9fquGyyy4T3kCrhPPOO68z\/uyzzxYLXnhR\/4UXXigK8uTNQgtezpo5c6Yo2FbEdXrwwQclBjzE4AU2Czu7q5v3CSwwsDF4ociiEYMnqYzYQOEfOHBg+J5noLkOGTJELNrb26U9AdZwJJVX77DSG4S3335bqoG7xI7\/nZmZlQve3ovx\/PPPS4y5c+eKBa\/hxrjzzjvFgm8BYlx55ZVicdFFF0mMyZMnSwwe\/8bg8bAFH2QlgZneImlAWyOAu94DuN75ld4g1JtQz695GWBAxkgaxHaQ4463Beq3RgN3bFjwxwYoNlL4Yxn8pLUg\/0Yw6wahESzXqQzPpjUZiI0U\/thQYZgaUXs3CI1g2ctwBvoIA24Q+khDuZrOQCMYcIPQCJa9DGegjzDgBqFBDeXFOAN9gQE3CH2hlVxHZ6BBDLhBaBDRXowz0BcYcIOQ0kq8xchbeyliHp2RAd4m5I3JMWPGyC677CK8Afnzzz9nTO1iSQzwS2PHHXecwOmee+4pN998sxTl1A1CEsMdYXybcOmll8oZZ5wh1Y4x7xD1\/zkY4BVvxJ999ll5+umnZcmSJeHtRcIcxRjAABx88MHh5xL5eIszId95551CmbW8QeDwDI5mj9nBgkIkR5lxmtH+++8vTz31lPz6669BdI011pBdd91VjjzyyOD3P10ZKMor5zQccsghstZaa4Wf8eNd\/TfeeKNr5iX1FeWUA1x5k7GtrU1++umn0Ic5lasIjS1tEDhf\/\/HHH0\/k5f7775drrrlGTjzxREGG5RarAWYu6fjHF30HHXRQWNZ2eP2\/YaAWXs8991zhuwCy4xsSjHCj3sKjzGZFLZxy+tbaa68tnN\/JbzFsv\/324cOpInVtSYPw8MMPh6OqOcEWomNi+Hk5jqs+9thjw8cufFLMGfm77767PPDAA\/LLL7\/ESdzfwUC9eOWn2jg2feLEiXLmmWeGvW9H9qX8Xy9O+Qydk5e558VHZRzfVoTQljQIfF\/OAOfrN74xj4l57733hJ84w2C0tbWFaM4dYIvwyiuvSNoPb4QEJfxTD165AcZMtnz58vDJ+GGHHSZtbavaoISUSq2cfvjhh+GTeN12sbLlHAY+Fy\/CZ0sahK233lomTJggLPn5tRuJ\/mEM1lxzTRk0aFCXGPaz3377rXzxxRddwt2zioF68MpWtlp1KwAAEABJREFUbe+99w5HptF5V+Vc3r+1cvrNN98IKy5+eo77X1999ZVw\/Bv3xoqw2pIGIY0IDtdgiZVkLNLSenxlBtJ45Qg0VmAcWcZ9BPa7gO1b5VzLHZPGKRPblClThDMkOA3r0EMPFVa+O++8cyHiSmkQ8jAFudz9zZPGZZMZ6Nevn9xxxx3y0ksvCY\/GFNzYTU7hoVkY4HdJuX\/A4TOcPsXvYra1FduGNbVByEJGERkeybDMYrkVp8fi8sgxDnd\/OgPOazpHeSUazWkpDcLmm28entdyYq9tIA5Y5TBRzrqz4e7OxoDzmo2nPFKN5rSUBoHHjJwmzJKVGzE0EK\/UsuTi0aPf7IKR\/HBe83OWlqLRnJbSIGy00UZy9NFHy6233iq33HKL8IOhnLnPo5pjjjmm1I\/B0jpotXjntRo7xeIazWmPGYRi1W9cKl6K4VeDeEHmiCOOEN5NuP7668Nz4cZp0XolTZw4MfySk\/Nav7ZtJKctbRB4tMjd16SnBLxLf+qpp8qCBQuCMXjsscfC243i\/1IZcF5TKcot0CyctrRByN0qnsAZKDkDbhBK3gG8+s6AZSDRIFgBdzsDzkB5GHCDUJ629po6A6kMuEFIpcgFnIHyMOAGoTxt7TUtIwM56+wGISdhLu4MtDIDbhBauXW9bs5ATgbcIOQkzMWdgVZmwA1CK7eu161vM9AL2rtB6AXSvUhnoFkZcIPQrC3jejkDvcCAG4ReIN2LdAaalQE3CM3aMq5X32agj2rvBqGPNpyr7Qz0BANuEHqCVc\/TGeijDLhB6KMN52o7Az3BgBuEnmDV8+zbDJRYezcIJW58r7ozEDPgBiFmxP3OQIkZcINQ4sb3qjsDMQNuEGJG3N+3GXDta2LADUJN9HliZ6C1GHCD0Frt6bVxBmpiwA1CTfR5YmegtRhwg9Ba7dm3a+Pa9zoDbhB6vQlcAWegeRhwg9A8beGaOAO9zkCvGoRzzjlHtthii4o44YQT5LvvvqsrSYsXL5ZRo0aFMufNm1dT3p9++qnst99+Ia+kesT6a33j8JqUaFDiWbNmdatno+qhZcM1nGetsvJN2ySlJS\/CiaeMrPmqXD37kuapV\/o9\/KLbbbfd1tln8Seh1r6s5faqQVAlKl1feOEFmTBhgtBwlWSaObyv6w+32jGvuOIKvF1A\/XbaaScJnbFLTO976DMLFizoVGTZsmXy2muvdfqb3fH+++\/L66+\/LptttplsueWWqeqedtppUsSoqdHE+NDWTWEQ9thjj9BYS5cuFcVNN90USKAhH3rooeBu5j9HHXVUp+7UYerUqUHdvqJ\/UDbhD4MeEEWbUDfwyCOPyHrrrUewXHLJJT1qtCdNmhS4nT9\/vgwePDiUmfaHPgP3Vu6JJ56w3qZ233777bJy5Uo5\/vjjZdCgQZ262jagHTByjB8E7r333prboSkMApWJsfHGG3d2uDgOSxgvm5JmKSwelk9lWR5+8skncXbBb5d\/yLOtICxEFviz1157der\/7rvvdsthyZIlXZaB6Im+VlCtN\/ookuqZxAdhNi\/cpNV8uMIHMylxlaCDiE4HVG7HHXeU008\/PXi\/\/vprsbySJ3lThiKpfiRGT5Xhil\/rrWkII448yZt01QCPzzzzTBAZOXKkADysGNLSE085lEe5qgt+AIfklYQ0WfoT\/Yp8FFpHmx86oCsGl35k42L3uuuuK0OHDo2Dgx9dtRyu1Iu8ieSKH8OJH6PPaq9pDcJzzz0XLCTKbrXVVlwCID1p+cqSibgg1PGHCrPdoKId3vCfGQM5LG8IWP2Hhj\/88MM7yyMYGcIgFX89gU50BMrQfAlDNzozIF4bS2W4IoO+uAF1TuKDMOKQAbhJi1sBHwceeKDQUTWs0pXlK8tYG68z96JFiwQDQRx5kSd541dQPzo38RpGPdBT\/VzxJ9WbuKxAT\/RFnj4AcKMTMyruLEjSBQ7RO05PeKw3Ydp\/uNKfbJuTB7ygH\/0VP0BHdMWQDR8+nKCKIB3GA4Fhw4ZJ\/\/79cUrR9m4KgwApWCesmILGoGYsvQ844ACcYa+qpBPOkgmwXEeAOIjHTXpIxa3LLMphT0aYgg56ww03BC\/5kB\/ATWDR5XAlg0aeIEl\/9AO2QyfJMfthNND9ySefJDvROlrd6Sh0GDiBGwQ1PzodMz4ddMaMGRVv3o4fP55kwVjSobV9kgYFOs3oyIs84Zm6oI9uLwgnHjl0V97RA32QRb9QYA1\/lHudYTFEuMlSVzy400AadEcv6kKdSJO0NCcOGWRJQ1pkuSFIfbXcJDn6KfVHHlnS4D7llFOEFQBuBUZG24Ar3JGefK+99togn6W9MRzzO7Zg2s\/JBx2awiBoZZOuSr4lCuVPOumkTnE6EYQQAPEMAgYDfiqsBoX95wUXXEBwJ1jq0lFpwJNPPrkzHDdhkA1RnREVHAw4GkiBQUIUvdABtyIO00Gn8cy2zLp0LmZhDdfrihUr5Pvvv1dvuNJR6Ah4rrrqqi57bt2y2HLpaHQ45JlNMUK4Y8Ad\/Mbh1E\/rquUyIACy8AzfuKmPbi+0LDtop02bFjoysrQr7Yu7COgnGEzS6gzLLIubMPoF\/QN3GljpoDty1IX9PO6kPkEcMsTb8vCDuE0Is9A2oh3giLZikrQy1dzoRB9ERvMiD+17Wdu7KQwCHYBBxwBQMONROSpK52MAMBAIY89EBXEDrB3LJdwfffRRl8FitxvEx\/cmlDyMgp0BcRNGGpXBnQfU69FHH+12Iwxd0VnzinUinI7NtkEHHVdtcOIB6QYOHIgzAKOAHGDJGAI7\/qj+cIlOxAPkO6LD7I9hxJ0EjBLtQhuRPpYhH4yCloMhRTcrp+0Ap7Ys9LeytCvta9PmceuAIs2+++4bDA154iYMDqgH7jTEhlrrkJTOxlFeUh3gCN4Vto9pnmood9ttt279BhnGBW2hoC7aJqy4WHlpO1BX4rQ82ok84jYgTNEUBkGVsVcqAgjDqn\/22Wc4M4EZgBtdmYTrJIQl1kbS6z333BM6ZN4i0J99JbMtg4slKHnGMzUzEgZHebLlYDy4aUReNrwWNx2dOqELoHNqfqzM1J3lqp02i2weGR1QpGEi0cGAmzCQV1fS1Aq2WDogta\/QvszimjeTAKsb2pwVqoZXu9ImutJjoFP\/avJpcU1rEGLFBwwYIMyshLMKgDzcIF49tLe3CzMPcXHHY3aCOOIsaBgaiI4egxnSyva0m8GMdUcn7hHosjWuC3qs23GX2Q5SOhvhgDyYQXADDAf+uH742RogYwHHukrhit\/Gs6RFRw3TWRJ+4VnDuarudHZWBCqL4baylEH7kiYvMH5sMdPSMcEgmyanOquc+rUOGp52\/fzzz0X1wqizfSAN9ab+uAH9D7C9YdtBWC3I296U1bQGAWIASrJ8YpCrJST8rrvuIioA60\/nx8Myj5mTNPgZXCzVcNMJuEmIW6E3nEiPrIZj0ZldeEzEMkzDG3mls9BpKBMdMA64FdQLHQFuwulsrCjotPgBnHCFN4AbsK0gbaWVBLOPLn1JB0ingC94w88ApwMC\/PAM37jRneUsbu3syjvGQ280Ek+7xuUQngUYO9WHgYehs1BjiQyyaXmiM7ojxxU\/biYbjBruvFCjQjp91wA30JUL2xu4JywNGFC9CUmbw2vR9qaspjAIdABmGzqnQpdXVFKXT8xi2qgYAZWlY1IZ4pDBTYfQ2Yu8kKWz0hmIVzD76g0vmyduZOyNJfyNAI1KvRks7DPRnSt+Wz6cxXW0stQXwAnckFa5QE55szfEkLFI4pG0QDmiDG4G0om5QYju8Ew4cqo74cQjB+9wS1m2\/TVPwvNCBxTlwGGcXgcK4QwiVpa4KwG+0d3WAVl7wxR\/GjbccEOxExT5AeWf9AxsVi6VdEcG2PYjD\/oA\/BEHn\/BapL3Jg7yawiBQmSTQodgTUUmNZwakk6pfr4QRp35WCf\/4xz\/Cq58aRn4sryFdw7iyJYhnVcLZI9s8CWsEqO\/VV1\/dpSh0AQQy2OhM1LHSPQQMAHVl8JGGemh6\/AAeqDf1x58EyuDxFPwmxZOnLQfdWcmoodI0+AknXsPQKc4XP7qrTNYrqxEGFPK6CsFtQYdHD8K4k\/\/vf\/8bZ0XEuihfDLiKiSpETJ8+Xeh\/Go2bQciVsLvvvltoVx3UhOUB7QCfmgY3Yernqvrb9mayJZx40KsGAaXtki52246GsgoqFMsSpvF61c6ssuRHA+gjPduwdFQNV3kbr3naq82futi4JDcy5I0eYaCuFrJla5lckVXgB+rX+pIP+Wm4XilrdfadF5seOepL2Z0CVRyUR5oY5Bkns7yoPEaF8Fg2zpeVRnwPQWUq5UGe5E085cEHvBBuYWWoO1slTUMZVlbd8EiegDSWL9yEERfzoOlUF\/TBjSzAjT5c8b\/66qvhUTHptGy92nKQTUJcPmkJs7LoSl7EKfATrnK9ahBUKb+WjwHuebDkBdzLUAaYNQH+PHtp5B21M+AGoXYOPYcCDLBSAyRl+4NhAOyRCWNpX2TrQFpHcQbcIBTnzlPWwEC8hNYlq15ZyrOkrqGIQkkpk7LRo9I2olDGfSRR6Q0Cd6YtFi5cKAuzoIrMxx9\/LFnQR\/qIq1kiBkpvEC6\/\/HKxOOuss6RW8BgvC8aNGyeVUCl9rJvVffbs2TLbQA2dNXBqqErUx72qORgovUEYO3asjK0B7IPzYPTo0TK6CrbddlsBAwcODG9bDuy49uvXTxS8rKRgcOtg50YcjxDBfffdJ+C6664Lxs4aETU0sSHaZ599RPH73\/9eLHiGrth5550lCTzSq4Ttt99e0jBixAjJC+45lAk5xnVh0dIbhMLMrU6oAzXrlQFeDUOGDJEY7e3t0p4ADIfCGhlroKyxs+FWnjx22GEH4W1DgF9BuYSBTTfdVDbffPMu4I09wGvlFhtssIEoiE+DTZvVHetS1L\/LLrtIPXHwwQdLLeA18RhwubrL9eilnAbBUMqrpJxZl4a0Dl0pnptn\/TpmeK6VYNTpUSd6KKxRUgPE4I+hhoGrNSLqtkbGuq0hSnJb2axuLbPolTokgTcJ86JSWxL+448\/Slboas9e33vvPYmBQe7RzrE689IbBN6EvPDCCyUNvFJbBDNnzpQbb7xRuFYC77Qn4cEHH5QkzJkzRyyog4KXTCwweIDthYLXZMHqPtArFzVMea7WiBVxq+GrxzU2nEX9SQaqUlgjGqr0BoHHS80KPsBJwvPPPy8Wc+fOFQXP9C3uvPNOAXyYo7jyyisFXHTRRaKYPHmyWPBKqwXv9Fvwll8Sqs3eeQZNkQFPmkYMmlYuo\/QGoZUbN0\/dGEwW8eCNB3rSNoAwazRitzUwaW5rnPK41cDV45qn3CyyaXWuFg+XedqzqGzfMwhFa+rpnIGcDFgDWQ93bGTz+DHIOdUvJO4GoRBtnsgZaE0G3CC0Zrt6rZyBQgy4QShEmydyBlqTgcYahIRJobsAAAdKSURBVNbk0GvlDLQMA24QWqYpvSLOQO0MuEGonUPPwRloGQbcIKQ05csvvxzeYkwR8+iMDPCG5HnnnSdjxowJ3w\/w9ufPP\/+cMbWLJTHAkXPHHXdc4HTPPfeUm2++WYpymt0gJGnSwmGcpX\/ppZfKGWec0eWXoFq4yg2pGofCUtCzzz4rTz\/9tCxZsiS8dUmYoxgDGAA+ptIvXvmxl3feeadQZi1vEDi00p7ZpyxhQSGSz3r5hHb\/\/feXp556Sn799dcgssYaa8iuu+4qRx55ZPD7n64MFOX1gw8+kEMOOUTWWmst4bRf3tt\/4403umZeUl9RTjlqjjcZ29ra5Keffgp9GG6L0NjSBoHf+Xv88ccTebn\/\/vvlmmuukRNPPFGQYQnLaoCZSzr+rb\/++nLQQQeFZW2H1\/8bBmrh9dxzzxW+gSC7t99+OxjhRr2FR5nNilo45eTktddeW\/hkmoNpOXuCD7iK1LUlDcLDDz8czsDnGGqIjon58ssvhXPwjz322PBBzzbbbCP8+Mbuu+8uDzzwgPzyyy9xEvd3MFAvXn\/44QfhNwMmTpwoZ555Ztj7dmRfyv\/14pTPrjnSnXtefBDHuZCVCa0c05IGgcM+GOB80Zf0HTnfmq9YsUIwGG1tbYGdddZZJ2wRXnnlFeFHP0Kg\/+nCQD145QYYM9ny5cuF+wmHHXaYtLWtaoMuhZXEUyunH374oZx\/\/vmi2y5WtpwvwSfvRShsSYOw9dZby4QJE8KSn4MvJPqHMVhzzTVl0KBBXWLYz3777bfyxRdfdAl3zyoG6sErW7W9995bLr74YqHzrsq5vH9r5fSbb74RVlz8EhX3v7766ivhWD3ujRVhtSUNQhoRHBTCEivJWKSl9fjKDKTxyilCrMA475H7COx3Adu3yrmWOyaNUya2KVOmCGdg8HuWhx56aFj5cu5lEeZKaRDyEMW2gru\/edK4bDIDnI50xx13yEsvvSQ8GlNwYzc5hYd2Z6B7yNChQ4X7Bxyaw8lZ\/BxeW1uxbVgpDQKPZFhmsdyK6cXi8sgxDnd\/OgPOazpHeSUazWkpDQKn8\/K8loMtbQO9+eabwmGpRR\/Z2LzK6HZe69\/qjea0lAaBx4ybbLJJWLZyI4Zm5JVallw8evSbXTCSH85rfs7SUjSa01IahI022kiOPvpoufXWW+WWW26RxYsXy7Rp04RHNcccc0ypH4OlddBq8c5rNXaIy49Gc1pKg0Cz8FIMv2jECzJHHHFEOAf\/+uuvF54LE+8oxsDEiRPDT+E5r8X4S0rVSE5b2iDwaJG7r0lPCXiX\/tRTT5UFCxYEY\/DYY4+FtxvF\/6Uy4LymUpRboFk4bWmDkLtVPIEzUHIG3CCUvAN49bMyUA45NwjlaGevpTOQiQE3CJlociFnoBwMuEEoRzt7LZ2BTAy4QchEkwv1bQZc+6wMuEHIypTLOQMlYMANQgka2avoDGRlwA1CVqZczhkoAQNuEErQyEWryMnUvOXJIZ4caGKPluPcyT\/96U8yffr08C3IqFGjZNasWYlF8eEYx6bFeSQKdwv0gEYy4AahkWz3sbL+85\/\/CIeAcoovZ1Tybb5WgbMR+Shs3LhxGuTXFmDADUILNGJPVYEDZJjdGfScHMVBtFrWokWLhMNkRowYoUF+bQEG3CC0QCP2RBVY\/vPjHytXrhR+bs0u9zlDguPPOLevyGEy8+bNE34cJwm2nJ6ol+dZnQE3CNX5KW0sv2Q1depU4RxEPg\/nXoFuGTj4k8NSOSC1re1\/Z\/f997\/\/DUfYc69hFT4N\/s8++0y4H6Fkjhw5Uv72t791wR\/\/+Mew4mhvb5f+\/furqF8bzIAbhAYT3leK43hwTvHlM3G2BWwbdMvALy5Rj\/gXl2bOnBk+Ied3ASwwLvyACGkAp1VxTL6CfObMmROOZf\/LX\/4ifAqMnKPxDLhBaDznfb5EfqR1u+22Ewa2rQw\/hccPjsb45z\/\/WfEn8Vg5YEiWLVsWnlhgfGye7m4sA24QGst3ny+Nn8F78cUXw9n\/3FS0FRowYIAMHjy4GzgGjJWGRP+4F\/H3v\/9d+J2GyZMny\/jx4yMJ9zaaATcIjWa8z5SXrCg\/g8e9Au4DJEtkD+UXhlgdsDWp5bcEspfokmkMuEFIY8jjuzAwf\/584f7Cb3\/72y7heT38nB43LVlRzJgxQ\/SGZd58XL6+DLhBqC+fLZ0b7yXwy0A8XfjNb35TuK7cN7jsssuE+wZnn322DBs2rHBenrC+DLhBqC+fLZ0bx9TzCPF3v\/tdTfWcPXu2cKjtmDFjhPsI\/Aq0Yu7cucIPltZUgCcuzIAbhMLUNXPCntGNE6rZKgwfPrymAt56661gCP71r38J30P8+c9\/FsWUKVNk+fLlNeXviYsz4AahOHctn5KPmnhFedKkSaGuXDnWPn5PIJYLwuYP8qTj\/gP3DPhgaunSpZIEyiM\/k9ydDWTADUIDyfainIFmZ8ANQrO3kOvnDDSQgf8HAAD\/\/1mKjN4AAAAGSURBVAMAqUbbKdJoSCsAAAAASUVORK5CYII=","height":157,"width":260}}
%---
%[output:28696d4e]
%   data: {"dataType":"image","outputData":{"dataUri":"data:image\/png;base64,iVBORw0KGgoAAAANSUhEUgAAAQQAAACdCAYAAABSFgY1AAAQAElEQVR4AeydC7yVU\/rHnzczJgrJraKcFCMTUqLrTKURxZFbU0iRLiIql2OIyi3llr9KLjElNdO4dVKKTBeHLjRd6SI6FV1QHRFRw\/98l9bpPdt+99n7nL3f\/e69nz495123d71r\/d69nvdZz3rWs8r9ov8UAUVAEdiHQDnRf4qAIqAI7ENAGcI+IPSiCCgCIsoQ9FegCKQJAvHohjKEeKCodSgCaYKAMoQ0eZHaDUUgHggoQ4gHilqHIpAmCChDSJMXqd1IbQSC0nplCEF5E9oORSAACChDCMBL0CYoAkFBQBlCUN6EtkMRCAACyhAC8BK0CamNQDq1XhlCOr1N7YsiUEYElCGUEcCg3b58+XI5++yzpXnz5vLnP\/9ZGjRoIB07dpRNmzZF3dTRo0fLzJkzoypPuZNPPrnY8+6991757rvvZNeuXXLnnXfKypUro6pLCyUfAWUIyX8HcW9BvXr15M0335S5c+fKwoULpVatWiYe9wftq7B+\/fqmfp6Xl5dnUh966CH5wx\/+IA8++KDUqVPHpJXmzy+\/\/CL\/+9\/\/SnOr3lMKBJQhlAK0VLrlp59+kp07d8rRRx8te\/bskWHDhhkJAimCMGnQ0KFDpWHDhvLXv\/5V\/vvf\/5ouMhjHjx9vJI1mzZqJ\/fKbTI8\/Bx10kHTt2lU++ugj+eSTT6Rnz56C1PLtt99K\/\/79pVGjRnLWWWfJI488YtpD+k033WTSrrrqKunevbspj5TSu3dvufDCC2XevHkya9Ys044mTZrIBRdcICtWrJAvv\/xSLr30Uhk4cKDQPiShcePGSatWrUx9\/\/nPfzxauT9ZQ8URUIZQHI+0iM2fP19OO+00OeGEE+RPf\/qTfPXVV2YwTZ8+XTZu3Ch8xaHt27fLq6++KqR\/\/vnnRqIgDgMBCMog7r\/zzjvy7rvvSoUKFWTy5MlkRaTKlSvLkUceKQx2W3DBggVSu3ZtM7h53urVq2Xz5s0yZswYI0GQj1Tx9ddf21uE9k2cONH05a233hKY0\/vvv28YDnVQ8JtvvpEzzzzTtK9atWpCvW+\/\/bY8\/PDDpq179+6lmFKUCChDiBKoVCrGV3jZsmXy2Wefma80X8977rlH3nvvPWnbtq38\/ve\/N9S6dWv54IMPZM6cOSadr\/shhxxivrb0l0HKgPzjH\/9oph0jR46UxYsXkxUztWzZ0ugZJk2aZKYRMJqtW7fKmjVrhK++4zhy7LHHyqmnnlpUd4sWLYT2HHrooXL77bebso8\/\/ri89NJLsmXLFlMOyQdpx3EcKVeunGn7AQccIDCl3bt3CyT6L2oElCFEDVVqFmRw\/OUvfzED44cffjCMwPaEqQLMwcZDrygFGYgwFohBPGjQoNBiv4nzZUc6QEqwmc8\/\/7w8\/fTTAnPp16+fkVyYkqAfYCBTjjBTHMJuQiF6\/fXXC9JDhw4dpEePHu7sYuFI\/SlWUCNhEVCGEBaW9Elk0CH6ly9f3ugOWBWAEUDTpk0zX2d0B4RJ27FjhzBFAAHm+ojoDG6YCXN1pg7keRHlnnrqKTnllFOM3sKWQ5Rv166doPBkgMNckEgQ82kf7Vy\/fr0g2dh77HXbtm1GUkB3wJffts\/m6zV+CChDiB+WgalpyZIlcv755xu9QePGjc1UIScnRy6\/\/HIjSjOFgKpXry7nnXeeZGdnm3RE92uvvVaqVq1q+sKUAmbBFfGdwUjYZLr+oIS0z6NeBjoKRFcR8+z777\/fiPTM8dFx\/POf\/zRKRJhMo0JlI0uUxxxzjPs2E0b3cPjhhwuSzhVXXGGYzdKlS80UwhTQP3FDQBlC3KAMRkXMwZn7M8hYBkTBiDKOLzHiNFMA8iHCpDGABw8ebPQJr732mowaNUoY+OT16dNHKAvZ8u6eUm7VqlVGqcfzFi1aJOgrKlasKBDTBNrEPB8dBtIAA3\/EiBHywAMPCBIIzIr6n3jiCaMHYKrRq1cvgXgW7WNFhLppH0wLpgLzmTBhQpEkwsoF7eEensmzaQNxpegQUIYQHU5aKkEIYNQEg2jatKmgH2Dp0UooCXqkVhsBAWUIEcDRrMQhYGuuW7euTJ061UxrkDBYjbB5evUfAWUI\/mOuT1QEAouAMoTAvhptmCLgPwKBYwhsisFaDpNUNudAhEkjz3+I9ImKQOYgEBiGwDo0mvGrr77aWKGxKebll18WCO0xzACFU25ubua8nYD2VJuVvggEhiFg\/IJV3b\/\/\/W9hUwsWbZilQjVr1hQYxSuvvFK0Rp6+r0R7pggkD4HAMATs1VmrxradzThYvLHGzJIUV+IwDAxlkgeXPlkRSG8EAsMQ2JWGaWyXLl3M9laMT9i+ivksRiuPPfaYMK1I79ehvVMEkotAYBgCNvTsb2dNmmkDm1zYf9++fXuzD5\/dbWxuSS5cqf907YEiEAmBwDAEvv5MGzBTZSMO3nZ+97vfmbYzVSBOGZOgfxQBRSAhCASGISSkd1qpIqAIxIRAoBgCe+7ZZIPnnE8\/\/VS4olQkjbyYeqaFFQFFIGYEAsMQ8IzDzjq22Z5zzjlmxxxXNr2QRh5lYu5hGt2gXVEEEo1AYBjCgQceKGx0YVkxHJFHmUQDovUrApmMQGAYAm63kAIuu+wys+xoTZYxW8YT8PDhw42f\/0x+Wdp3RSDRCASGIRx11FGCB50ZM2YYV+CcK4ApM8Q+BoDAYQdXJUVAEUgMAoFhCLZ7mDBjlQiDsGm41SKNPJuWaldtryKQCggEjiEcdthh8uOPPxoPvTjjhF588UXBUEmViqnwk9I2pjICgWMIGCANGTJEMGXu2LGjcc7JISL33XefYLSUymBr2xWBoCMQGIbAlADzZADDYhHHm7jUwjEnzjjxukueLUNYSRFQBOKLQGAYAmbKU6ZMMZ522cyE\/wPbVcKcLoQXXsrYdL+u+hxFIFMQCAxDYAWhe\/fucvfddwuHhuBsk7MJoXPPPdc44WSzE2Uy5eVoPxUBvxEIDEOwHed8P0yVOXMQc2UI3\/2YMOMsxZaL9sqGqHHjxgnbqPHjP3bsWOHIsGjv13KKQCYhEDiGEG\/wOVWIQz2wb8C2AR8LMJt4P0frUwTSAYG0ZwgMfjwxoZRk2RKz6A8\/\/DAd3p32QRGIOwJpzxDWrl0rxx13XBFwtWrVkvz8\/KK4BhQBRWA\/AoFkCCtWrBAOIeVwT0T8Hj16CAZK+5sdWwjbBq87UFp269ZNIhFlIHcZ4pA7zStMOcidTxxyp3mFKQe584lD7jSvMOUgdz5xyJ3mFaYc5M4nDrnTwoUpA7nziFtyp4cLhytn07iGu8edRhkoXFpouruMDVMGsnGuxPEA3rNnz2K\/m379+gnnX7IaRjmIshBhS8Qt2TSvqy3H1es3HM\/0wDEE7BE4pLNv376CgrFOnTpy4YUXCm7ZyYu181lZWYJvBXsfYeq0ca5jxoyRSIRiE3KXIQ7ZtAEDBnjWQTnIluVKHCJcElEOcpcjDrnTvMKUg9z5xCF3mleYcpA7nzjkTgsXpgzkziNuyZ0eLhyunE3jyj2lxd7eTx1eRBnInU+cTXdMRd3p7dq1k9NPP11Qitt0ykI2zpW4JeKRyJbjd+oHBY4hsF+BLzpu2AEA92ksQeJWjTzSYqHGjRvL4sWLhXshwvXq1Yuliowou27duozoZ2gnh87Il8r9Z0m9++eFZvkWDxL2gWMIKP4wUtq8eXPRC1m5cqXgYLU0psv169cXph7nn3++tGnTRmAupBVVrgGDAGdfmEAG\/YEZTPxgs2x\/rKWM6FjHMIYbJq70HYEgYR84hsCgZ342aNAgWbRokTCQb7zxRmF+BrOI9W05jmMOecnLyxPsGajbcZxYq9HyaYTAhu27xTKDJQMam541q13JMIaJH2wRyCRm4J\/AMQTeAd6RsBuYN2+eTJ8+3Qxk5mbkKSkCZUEARpA9anHhoN8slhm46xvZqY4gJeStLXAnZ0w4YQwhVgQ5rYndjXhKghDzOZMB5Q1iPnmUibVeLR8dAkGax0bX4uhL8cVnkKMnYIoAI4DC1dCpYRUjKcA0\/GIKQcI+MAyhcuXK8uSTT8qkSZMkOzvbLOfgQQlCzG\/btq0ceeSR4d5hSqTZH2X2yMVGgYUiK0jU4Ml8M4cOUpuibUtJbR86Y51sLJwmwASgaH4wMAY\/mUI0bfKjTGAYAqsJeEniyhZnJINq1aoJdMUVV8iyZcuMYtEPUOL1DOaqfJn4YdsfZfXK5Y2oiiJLqaX5GpcVh0V9siLWAxPIveGMmF4rUwfa5QdTUKVihFeDZ2VWFLAwtMW2bt1qmAHMwqYF\/cpcFRGVdvLDsj9KfmikKaUGAlZSCG3txRdfLJw\/Gpqe6vGwEkIyO4ULtS5dukjv3r2lefPmhjp16mRWCphWJLNt0T4bRsBcFUaQKgwgSPPYaHH2oxzvD6aAlJeo5wUJ+8AxBEBHiThnzhyZMGGC4E8Rz8utWrUiK9CEEoofTo3Dy5tpQaAbG9K4IImtIU1LetTNFNAFIf01f2CW0bnA\/ImXpZFBwj5wDIGVBFYUOLXpyiuvNJIB5zKQRl5ZgE\/kvc8sKBDmmzltakqs89VEtkvrjg8CMIVmtSqZJUn0QR9t+7Ve9ETEURb\/mpLafwPHEJgWsNrw8ssvC\/Tss8+ag1uwG2cLcxDh5gsxZdV3RrGV0yYriE0ssU1BEltLbGySCnQ6q6rnk\/M+LZDcj7\/1zE9aRowPDhxDQHHIagPekSD2NPTv319+\/vln2blzZ1TdY78CG6K+\/PJLSbTHJJgB+oIpXY6Lqm1aKHURmLhwvzl9uF5M23RIuOQS04LEjAPHEMKht3HjRvniiy\/CZf0mjWnF0KFDZffu3SYvkR6TLDPADt48LIX\/BGkeG1QYkQIS0bYgYR84hsBXHStF9n9bQpfAhqSSpgx79uyRESNGCEZMSBm8vER5TGLOiGTAciJ28DxLKb0RqFG5fHp3sLB3gWMIRxxxhOTm5hofBnYvOGczMAVg2lDYZs\/\/M2fOlIMPPticDWkLYc8QT49JKJHQLG\/YsTvlVhIsJuGuQRJbw7UvCGk5hQrjSO1odMT3kbI98zyx97wjcRmBYgicv7B69Wq56667JD8\/X5AWoFWrVsmtt94q27btU+0W4kG6lSTI43QnNkL16NFD0EMUFin6j3+FokiYAC8kGnpv6SfS9v8+MKdKvXZlFXHfw\/Pd8VQLp3L7\/Wp7oyN\/kAbHeksJ7Wv+JN9\/\/72Z3sby\/qNpf5ifbUKSyiWk1lJWinj\/3HPPyccffyyjRo2S4cOHG8IWoXXr1sIKhK0ahSO2CkgRjzzyiMA0OMSlQYMG0qhRI5k\/f76RFNhOjZckex\/hUI9JzOFKoklrHLlw7OeyYlBzQ6HlkUJC01IpjhFYKrXX3VY\/sX\/7lsaCpMD0wRJxfl93fFjJSKh4+nK3r6RwNNhTvx9Uzo+HRPsMDJI4tu3RRx8VznfEbZqlv\/3tb4LjFK+6YBgwm\/lJZQAAEABJREFUBwhmAFPA\/Xr79u3L5DGJKYJVHtoX79UGTc8MBHIKl5bRHVkijlXqOcenvp+NwDAEVgdgBlxZJcAykW3QlkprmIQykqkFjlZi9ZgEI0BfYJWHvPh0\/ckj4qZr3\/zq1+Un\/rL\/UTGEgoR90hkCtgXoA7AX6NOnj9SoUUPY8jx37lxxE2l25aAkrJlOYPbM1XGi85iESSo7EyFWEDBBhhHA+fkSlPRMzVcE0gGBpDAEjlKbOnWqYJ6MqH\/ZZZcJxBmOmCkzmJ944gnh+DZLSA0wj3iDXtB+jLFJx\/z0vU8LzL55tihnGiNgnhtvbLW+6BAIEva+MwRWEji0lS3Or7\/+uixcuLBIEmDujwIRc+U33nhDmjZtWkSczciBsNFBHH2pSq93MybHSAEQ+xCwW4++Bi2pCKQPAr4zBLT++NFni3M4p6nlypUTVgrYx4Cfe0soHLk3faAPVk+CNI9NOjI+NyBI2PvOELAR4EuP8hBFoVUa2itWifn5+eLn+YvWIrIsV6Y\/Zbk\/2femcvuD0vannnpKOGkMBXYs7zOa9vvFo3xnCLZjmCGzgxHnJygMJ06cKOedd56Qhoek6667TpgmWEYB84CJ2PvjdWWZUukzUQzKjsErr7xiTu9i\/0wi8IzXbz5SPUljCDt27DAWXZ07dzZ+EzHmuOmmm8ympHHjxgkuqtz6BZhGtKsMkTqseYqAIuCNQNIYAkezsSMRacA2DwkAB6ujR482h7TYFQaugwcPFjwnsYHJlterIvAbBDShTAgkjSGgUMSzMhICpptMDbBGvPzyy80eARgG5zIybWD78w8\/\/CCYJt9\/\/\/1l6rDerAgoAt4IJI0h0KQWLVrICy+8ILfddps8\/fTT5kwGmAO26ZzPwA5HTI+xSfjpp5\/k+uuvl+3bt3OrkiKgCCQAgaQyBDYysVORKQJGR3379pV33nlHGPyQ7S+GTNgv7N271ybpVRFQBBKAQNIYAl\/6pUuXmk1MlSpVEqy1cG6CT4OTTz5ZWFW44447jLXiNddcI2eeeabRIbh3PIr+Sy8EtDdJRyBpDIGvPnoCHJpYFNArYKPQoUMHYaWBDU5YKw4bNkxIYwqBUZMtr1dFQBGILwJJYwic08gy4tixYwWF4Zo1a4TdjnhMYrMTOoXZs2cL3pLGjBkjXbt2NT2HYZiA\/lEEFIG4I5A0huA4jmB3UKtWLeOBiP0NnOPIiU24YSedacWJJ54oFSpUkO7duwsMJO4IaIWKgCJQhIDvDIGpAvYGSAHffvutsU5EAhg\/frxwqCtMoGLFisKSJMuOdevWFbZFIy1QvqjlGggWAtqatEDAd4bAgGeAs935ggsuEOwPGPwQW59ZhmRFAYMl\/BmsX7\/e+EjctWuXmVrEG\/VYbM617AmiGHhjwG+4W7duglOeeOMU79+9V32+MwTEfsyQZ8yYYXwevvnmm2b1ACvEV199VdARYLbMRhEOaXn++eelRYsWAnMozQoDjldQUGLg1KxZM0FngZTiBiQeducsl8ajnmTVkcrtD0rbsZNBEc5vOpb3GE37YTDu32yiwr4zBNsRxH+UiTAIm3bMMccYKQAOi+NUQJg8ebLMmTNHBg4cGNGnoq0j9MpGE3wrwoB4UexGw5lraLlExPG6BOGFKRH1x7NOln3jWZ\/WFT0CQcI+aQyBY99\/\/PFHY6G4adMmWb58uTlghYF7ySWXmKkE0wm2hl500UXCrkh0D9HD\/GtJBj87KNldybJmw4YNfdlanbe2wDQAz0sEYAz4Z8Q929AZ+SQFhzKgJTBlsOc9WOJ92PeUARBE1cWkMQTOSsCzMtaHGCFxngJSA1LCtddea0R7nKRYYuWhNFOGeB\/UEhWqhYXe+7RAcNNdGBQ8MMEYOjWsSlRw12Z\/lFz5YfJjhfjhugnmEYlMhWn0J1JfQ\/MsToNmfi2EwQ8CT3C1RJz3Ub1yeeMdi3cB8T6yRy1OI\/TK3hXfGQLTBHY00vRDDz1UcnJyjAu1efPmmS839gccXMEmJ8yalyxZIkgTTC1wrsJ9sRLMx+uenecOlbqD3g1L9gdV0pX7u0xcbzZl4f0G+njDV3LUQVIsrcNJv8gTbSvJoj5Zxej82uXl8AP3GlqzqUDcNHPFZnlx3kZP4tnxoJMHzA6LQTzqjqWOSH0NzbM4rftql8HMYgiebow5VAe6tVH537yPZy6pYnxqvpy3slge7zBWKigoKNVBLejPSnqW+PTPd4bA2QrsWuzVq5csWLBAWFGwfYVZMH2AkBgGDx5sDlxBUcPKBPsdbNlor1lZWeZYOFs+9KCWQ9\/KMQev2ANY3Fe+ItFQ58bVpekJh8nN0wqkwZP5hpZu3SsnVatkTLKZI0aiIR3PkLHdGxriIJBQcrcpUeE3ux3viUOinlnWei1OYzsdL4QthuAZCW933mXN6kinhlWkx6tb5IDDqkb1vtz3u8OY4GN5i28Pd3pJYTbzlVRGfPrnO0NgFQEjo7vvvlumTZsmLVu2LFrKwusylokYKbF8w3SirDhgy8Dx8ExHIML16tUra7XF7ue8hh5nVxIctMJActrUlKa1KpmpQrGCiYjEqU5+kHGqKuWqYUrXrPB93ThxZVLaHiTsfWcIFnG4KBIASj+7RIPoxFSB3Y9NmjSR++67zxzLxsoAOgSmGPb+aK+sWJT2oJZonxFaLqdNVkoxg9D2Z2IcZp5XqPdBB5GJ\/bd9ThpDsA2wV1YQ2LzEzkZEKGwVWHrka\/7NN98I+aH2A\/beSFfHceTqq6+WvLw8ef\/99+Wqq64Sx0n9I7ci9bk0ecxhS3NfOt2DG\/4NO3YbnYKf\/QoS9oFhCLwAJADcsP\/jH\/8Q3LRjzWgJHQJWjpRTij8CQRJb49+76GpkVQimkFM45WNlAmUy1+juLn2pIGEfGIbAKgJSwdyQI9xsnDzKlB72AN6pTQokAjmFUz4YA\/ogdEF+MYYggJFUhsA0ACco2CEgzuMgxb3qEAkgFI533XWXMWiy5WbNmmUMmtA\/sFGK1YpoTJft\/XpVBEIRQOEIc+jUsKrvU4nQtvgRTxpDYEBzXiPbnOkoegM8Kj\/88MNmOzRpXoRXJfQCWDXaMkwn2Bg1duxY40OBjVIoIpNpumzblgrXIM1jg4YXUwkrNaB0jPc0IkjYJ40hMIB\/\/vlnc+AregO8J7EcydIgeZF+FDhRQbdw\/PHHFyuGKTTGISTi4h1TZVYxkmG6TBtSiYI0jw0qbjAGViNqHF5eYAp5+8zTy9reIGGfNIbAOY1YHn7\/\/fdFeDKFgBlgvFSUGCZwxhlnCDYLeF2y2Zg1M\/XAlTtSBydBsf+hJNNlVh3uuece8SK4NxSav27dOmPZZtORTmw49Mr9kDudOORO8wpTDnLnE4fcaV5hykHufOKQO80rTDnInU8ccqd5hSkHufOJQ+40rzDlIHc+cYi0SNiTTzmIsCXikI1HulIOsmXqbX3NWKH2Gr+82O8Gfdfq1atl5MiRxdK5F7L3cyUOES6JKGd\/54m+Jo0h8PXGAvGGG24Q3KdhpsxXnwHN4HZ3nDx2PmJPgGMVd54NY8vANmd2NGKNyD0sWzI1iWS6jGMWDKG8qGbNmsZ6LTQ\/NJ3l0tAyNh5alvRwaaSHo3Blw6WFu5e0cGVD01K5\/ZHaHm3\/KedFoVhRDsvITTv3yrY6nYQ4xGY8tuzzmyZuKdz97rRo2m9\/54m+Jo0h0DEOxXzjjTfk8ccfN\/YBhEkjz00MbAb8nDlzjF8Ed54Nk8\/GqBo1ahg7A7w0b9u2TapUqRLRdNner1dFIFYEcnufIRM\/2CLxmjrE+vxElE8qQ2BVAD8HDNrhw4cLh73iEKU0Ha1evboxXsLTEvcvWrTI+GBEqsBcGd0ERBhjJ8oo7UeAL9b+mIaiQaBZ7UqCyfOwGeuiKe5ZJkjYJ40hYH34r3\/9SxCvcJOG3wNWD1gVQI\/giZ5HxkknnSRdu3Y1fhlZdmQq0L9\/f2P6DFNA8mjTpo3ZO1G\/fn2PWjRZEYgNAZSMmDwjKcR2ZzBLJ40hsCKAM1XE\/IULFworASgaDzzwwBKXHYGSe9kqfeqppxI10wRMn1HsYNMAs4HzOo6aLhuASvjjp+KqhKakXHanhlWMj4vSNjxI2CeNIeDjgOPabr75ZsEXQlZWluBTkTQUjqUFV+9TBPxGAOOlDdt3y5Ite\/x+dNyflzSGgOafk5xZGuRkJvYx0Ds0s0gKhMMRlodMB3CaytSAVQnLYbFMxEIRaaNdu3ayYsUKoTyrD5T3crIa7jmZloY0lWl9jmd\/0SW8s\/7nUlUZJOyTxhBAjoF\/+umnC4ZGGBJx8jPMAXsE8sPR2rVrhdWI3NxcY5GI\/8VnnnnGTDOwciQ+f\/58wQELm6Q+\/PBDSZaT1XDt17T0RKDTWVVlwbaDU75zSWMI2AcgITDvb926tTCQ8YXAikOlSpU8gcUY6e9\/\/7uge6AQCkjCSAeEsW1wHMesWLDXgdUGJAa\/nazStlQiK2WlUpuD1Fb0CFgyloYpBAn7pDGEHTt2CAN4xowZcssttwjnMLz00kuCpOA43v4KGNhIFfiyxyKR6QNWi6xasBfizjvvlNNOO006d+4smDGXZKkohf8weiorsUpS1jqSeX8qtz8obS9Y9Z7MXbNNWNGK5V1G0\/7Cn6kv\/5PGENy9w1QZ+wG8KH399deGUbjzsToEYJYPraUiUgUWiThpZZMUjlkxG8X12rJly+TKK68UJAmYBPoKd33uMAZNSp+JYlB2DPLH3ypLRlwnLJ0nAk\/37zZRYX8ZgqsXiP5MD4YMGWJMg5977jljsYjoj27BVVTcloqYOT\/wwAMm23EcadCggbCEiXNLrBPr1Klj8pgmsGmqatWqaqloENE\/ikDJCCSNITiOI\/hC4CvO4OUYLGwLUAxGWnaEWXz00UeCJMEKAjoCtk4zTYAxfPLJJ6bXK1euFOpBqsA6EStFiLCflorPPvtskc8GtmZj744xFm0xDdU\/CUGADwsrWIjjb731VkKekY6VJo0hACbbnxHzp0+fbtyxY22IBIA7dvLDEU5T27ZtK9nZ2YJH5UmTJgkWiegWmFoMGDBAmjZtanQSMJxGjRoJTIF5nZ+WijAnlJoYT9GPzZs3m01c6Exox+zZs0lWShAC\/KZYacK2BX+ayoCjAzppDIFBz5fyscceM8uHuF+HsFpk3u\/VfMdxzEYorBFZXkSpWK1aNVO8bt26MnXqVFMfLtdY33Wc5FgqordgaoM9BI1DomG\/BRIO7friiy9IVkoQAixdgzMGcBUqVBCU2Al6VFpVGz1DiHO34dhMEdAdPPjgg2IJJaE1UorzI5NaHRaY6DlsI5AYbFiv8UWAJW08dJcvX95UjM8NVqFMRP9ERCBpDIH5PV9LOHnEFgYgkx8Y4v\/y5cuLWsMcFStJLCBxzMIqB\/ksiWItGeobkj0a6DxsBaya2LBeo0cAnREORewdSJOsMjVs2FCwROrzB8kAAAfXSURBVGWDHI53wJv3Rjl+axi\/EVaKjIDvDIHj2HiBHMICM7joooukZ8+egv0ARB5lIjfbv1x+YKH+G\/mhofyEITDFYYmTdqMDWbp0qUyYMEGQftytZFXF6kdQfLLE6s7XcGQEmHIhRTLN5ItvS6MrgBkzhWSaiMSJoQ9OdsAZWxfKp6PUaTGI59V3hsB8jtOd+\/btK1gqMuBgDsQh8igTz06WpS6+LHhycvtv5EeGyI\/CkrpZ+oS54ZCFeDhiiRVDKhSKGFWxshKunKaFR4CvPsvKF198cbECOM1BycwRgTBZ9EkoqsEZYzesX3lPoQy6WCUZF\/HusO8MgReLBh6xj4GGUtFxHOMJ6eijjzZOTSjj3WR\/c8L5b8SICpHUMi6+Poil4RjC4MGDhS3ajuMIzI7t2fjco7y\/PUntp7GKhEUqzNf2hGkZykKkL9IcxxGmYvjXgDkgMcB8uY98pZIR8J0hsLqARMCSIbsQGUyIgojhJTc3OCVYRQgS4woOMv62hHcAc\/b3qen7NN8ZAqsLfFkvvfRSycrKkuuuu05IC5LeoKTXzTTC3Wbazh4MpgUl3av58UOA3xFTARS81IrSFv0Bjk6JK8WOgO8MgSZiUszVEkqfVJIQmNpgHYnGmz5wZcclYi1xJX8QcBzHuMRDj8BqA7YdTOdq167tTwOS8pTEPjQpDCGxXUp87WzGwjqS3ZkoBzkDgjjpiX+6PsGNAI55YcQsObLcy+Y2DMDcZTQcPQJJYQicpsTeAxRAaICxOORKHDNju6Mx+m4ktiRiKSbIKAftk9Bmo7RasGCBWWYkbvP0mjgE2OXKZjf7BFYXMGbjPaCwbdmypc3SaykQ8J0hIG4j4nltDyWPMqXoi96iCCgCZUTAd4ZQxvbq7YpACiMQ\/KYrQwj+O9IWKgK+IaAMwTeo9UGKQPARUIYQ\/HekLVQEfENAGYJvUOuDUhuBzGi9MoTMeM\/aS0UgKgSUIUQFkxZSBDIDAWUImfGetZeKQFQIKEOICqbgF8LBLN6b8OpsCZ+OwW955BZigfjCCy8YJ7yYJuM\/w30H\/R49erQ7qSjMRqfhw4fLnj17itI0EBkBZQiR8UmpXLaRY75rCbdvtgPsBMTPoI2nwhV\/B6+\/\/rqU1p8BTlbZGo1pfCr0NwhtVIYQhLeQwDbw9ezdu7dwhua8efNkxYoVgts6NgPhC5KvKI+fNWuWNGnSRJAu2Kg1aNAgYU8JX2WulOHrzBcZ5oK3a8pSz7333mu+4ORTJy7n2PTVvXt3s7WdnYjDhg0T0nBwgicjBnq\/fv3MIb3UzZccImyJXaQ4ksHZiU3zuiIN0R4Ipza0YdeuXdK8eXPBFTtOebzu1fT9CChD2I9Fyod69OhhPAaxSQxnrzh9pVO4fGNHJn4CRowYIXhs4qwCBiQeqzj\/csyYMcIZF+wlYQDydebecMS9HISDN6J3331X8EswefJkUxRXckgqlOHrzOnb+D3cuHGjzJ49W2AaTAPwKbFlyxbBFR2+JZYsWSIcqmIq2feH8qeccsq+2K8Xdx\/pJ4OdHKQhJCP6iZ8NfC\/SLvpC\/9kWTTmlyAgoQ4iMT0rlciy+3TSGs1e7O7NFixbmFKv8\/Hxh0PAVZTBxshHnYCI14M+BweM4jrCjkB2eXp1nQDPwYDD4iYTBcCIW5fk64yuCXYg8n2kKDlAZ7HjZZqsyOgGkEZzSwghwPsvzQv0YwCgqVqxItUXk7iN9veSSS4ry8MaFyzoO5UGfQgZMCXfs6oYdNEomZQglY5Q2JRCbcVcOE2Aw4ZU4NzfXeIhmGmA7yhkSiPk2HnpFFL\/99tuFOiCkhUGFU4zQcjZOXbics\/GCggJh8LZq1UqQSJiu4FIPhmHLxHql\/S+++KLxyXnNNdeI4zixVqHlCxFQhlAIQqb8R8mGuzcYAQOIU64effRRwaEIIj0eh0hHioB54PCFLz3u4UhnTg9WfH356vMFZ2APHDhQmDqQF45gQgx8GAMu0\/v06WNOUuKMTfQT6DaQWkLvxSVdpKmLuzzTEvrDVIE22zwkFNrOCU42Ta\/eCChD8MYm7XKYEtx2222CYpDzL3HwwvmHiO4oDxG\/cVADY0CER7wnjitzNP3oGmASTCkY5FyZjnAGAmEvwDjOznEco+Dr0KGD4E+TaQWD1DrKIR56P89AD8KADs1zx2E0SAcbNmwQlJowF67oM9BT0JejjjrKfYuGPRBQhuABTKol40Uo3KBkwEO2P8zdUQbyhedAGTw9OY4jnHfAoTNIB4jcDELHcYzreHQGb7\/9tnCS9UMPPSR8gfnKkw4xfSCN59MO+6xevXoV6SOGDBkiLP\/xXJ7lOI5ZYWDAZmdnhxXxWZHAzTpSBYOa9vIMWz9XnkdbyEOPQfshmB1MgL5ybkNZpiM8J1NIGUKmvOmA9ZOpAowBiYMDWMI1DybQuXNnQccAgwpXJlIaS6o48EXKiVRO8\/YjUG5\/UEOKwK8IsDqAtv7XWGL+4iZvypQpgsQR6evNqgU2BY4Tu5IQnQnTI6SXxPQi\/WpVhpB+71R7pAiUGgFlCKWGLt1v1P5lIgLKEDLxrWufFQEPBJQheACjyYpAJiKgDCET37r2WRHwQEAZggcwqZ2srVcESoeAMoTS4aZ3KQJpiYAyhLR8rdopRaB0CChDKB1uepcikJYI\/D8AAAD\/\/5vdLAMAAAAGSURBVAMATp8GOEW+pLUAAAAASUVORK5CYII=","height":157,"width":260}}
%---
%[output:5a532cea]
%   data: {"dataType":"image","outputData":{"dataUri":"data:image\/png;base64,iVBORw0KGgoAAAANSUhEUgAAAQQAAACdCAYAAABSFgY1AAAQAElEQVR4AeydD7zV8\/3H36eMFpK0qUmTiGwpUlhC\/hRJYaR\/YxrJEE26LT+WWVQaQv7UtEWSlaQsGaGUSCphpKiF0kalKaHxu8+P3mef872fc+65555z7une933c9\/l8v5\/\/n9f3835\/\/r8\/1b61P0PAEDAEdiBQTezPEDAEDIEdCJhA2AGEGYaAISBiAsFqgSFQSRDIRjFMIGQDRYvDEKgkCJhAqCQf0ophCGQDARMI2UDR4jAEKgkCJhACH\/LZZ5+VAw88UDADzuWyIk4\/7gEDBsgJJ5wg\/\/rXv8oVrx\/4888\/lx49ejji+Y033pDmzZvLfffd53vLyXO0fMkSIS\/kibwl86P2ZfGrYdIxwQac+B58h3TC4EfDEZZn7MpLmYQHu+OPP14wMwkfCmMCIYDKKaecIu+\/\/75gBpzLZUWcuYq7XBnLQmCE2k033SQDBw7MCXZZyGJCFKtWrZK33npLzjnnHBk5cmSC287w0qxZMyf0r7jiiqw1KBUmELQlQTpDtAJS\/EelosVE+mLihol9sbP798P6bmrfqVMn18ITNpXkJ038KKlfjQeTdEkDN4h80SoglWnhNCx+8EsY7IibzOo7ZvQdP1OnTpUPPvhATj311BKSnjDEhUlYTZNwvGOPu5La46b0ySefCBXmP\/\/5j4wYMUIoA26YGg6Td+whnrGjfLRAWjbcKDsY4A75aS5btkw2bdokbdq0waurpITFH8SzYkReyFOXLl1cT0zLhj+ItLGjjFG\/RE66+IPID\/nCPkrEQVz4gygbfsiH4sI3UHvclKJhNf\/q\/uGHH7qyEq\/vRl7IE\/ZK5JdwmOTn4Ycfdr02yoc96eMXtyjm5JX4cYc0DOHAGswpA+\/lpQSBEE2YxFNRpolToD59+riWhNaSFoWPDlgaJ5L77rvvlieeeMJVMtxx88NSAffbbz8577zzXOXDHTr00ENdC4\/kf+aZZ0owGn6IhzhJW\/MAqNjjHiXcIOyVyX7yk58IeYjmET\/pUN++fV3rtP\/++wv5ROL74Q4\/\/HDBbeXKlc56\/vz5zqQSkM\/SMMRz3bp1BRz33HNPhzctIWEpy5gxY+I4vfrqqw5D3408xWIxonFERSfNjz76SF5++WUhPBjqd5s1a5bUrl1b9t13X8Hv1VdfLXwfMMI\/keCfXhK4kyewO+aYY+SWW24RH0\/8Ut6oX95Jj3hIn3jJD\/kiTcIpwdC9evVywpZvjH\/KDfP98Ic\/lMmTJzt8qSfgouEw4QUEhp8nGI90cYc+++wzmTBhQryOEjf22FF\/KRtlp3xz5851mOCOILz++usFk\/dUmJMP6rfiCG6UlTCEBWsw1zqCXXkoQSAQEQkDMgCmIvzgPxOi4lDR+RCEp4JTOQBt69atWLnK0ahRI4FJaD21whIWv4TZY489BGlKCwvwLmDxz2mnnVb8K3LQQQc5M\/QDgBoP7jAn5aXC8R4l8kuZJ06c6D4klYO0yQN5fP3117Pe7axZs6ZjKHChYmBSQcEFHMhTCMMtW7ZEs5\/wThkpKwKHlkcrMp40XtxgmlatWmHtSLvY2OGGH\/JAvlavXi18I+oP+eY7wqhgdsYZZ7jwc+bMCWIEhuAKwUz0GpRZXEDvB6YnPdIlffJBfmBA8ud5FQQK7xdeeCGG4J9w5BM8nWWSn\/Xr17uGKNU31m8RZUrqEvWBqKmnYMCzTzA234BvkQpz6jX1W\/NBfNRbwvjxrV27Ni5wfPuyPicIBBLq16+fYJYWUTp+QnHwQcm876aAUoFKq8yEo7JQaei9+BIbt1yRVvRcxR+KF0ahIlDZqRjgwzt+U2H4xRdf4CUp0XLSNaXlorKpR5g4Gm9IqCJAwD4aXuPBhFG7d+\/OoxsS4Zcw2rI5B++HVhv3dL8n+dY4yY8XVfwRoR9\/KX5AUPEdEeYwfLFVTv4pI2WhjlJXQ4koriF+UDc\/HLikivNHP\/qRUF\/8MJk8JwgEMn\/vvfe6btC\/\/\/3vlPF9\/\/vfT+mezJFMk3nfnY\/DR+Jj7b777r6Tk3rRSoqUR+oiYZWQtAkB03ihvKSNV\/2ImLynQ1rhaG1oaanUCLdMhWUoTVoE7GkRwIj30jAs7duMHz+eKF1XF\/y0lwHDRL+NltEF2PGjrRthIVp2wu5wjhu0lLjTdVZMmHQEr7in4gcEFMMT8hH1X+wc\/EcYICTxD9Ei01PzPUcZC4GHUKWLzXfy\/SZ71vKTZ\/3GyfxiD4OPGzfODUWoo+SRvOIWotC31DR9\/wx3KKeSDnGov9QL7RX7YTJ5ThAIfLQzzzxTZs6cKccdd5y0b99epkyZ4rrImUSeLAyZR8KrZKdrB3PS+mnFolWkCwjxTLeQVkfDAjTxw4R8KD4Y7+kSjEV5YTTCYCJo6FbynorostNd1K4neaE85E3D6UclXrXLxNS0wIo0eSce0iJN7Hn3MYwKVdx98hkF3CiHuuNGvJQp6kba5IEuOxUfRqanwZieb8M3guFgPMLyXfg+MCr5gzEQ+vqNNU2YEybVd\/xSH\/TdN2Eg6gl1grpBPpjAg3j2\/fKNeVcBSJkoG\/kkv7glIy0r2FAWDQvuycJgT\/58oUoeyStuySgV5tRH6qXWIxosegqYxEfZ+CZgy3t5KUEg0LKce+658vjjj8uiRYvk6uJJoenTp8tRRx3lJu4QFFHQM8kArTkST7tBmLQ6tCga31577SVMCNHtorLgjpuGZWIFYGhZmDQr7QMT1icq6WWXXSYwVFnj4aP\/9re\/dWNMPgR5IX\/kTSuSxvvOO+\/4yZZ4poJRSZkngcGiHkgLBsAek3eeSas0DPEHaZ7AGQalJQZTsNUJK\/JApecb4E6ZyNO3335LFI5ImzR5oaISHj+EwY6y0FrRavE9mDhTHPCPsLjjjjtc11aZlThIl+GF+l2yZIkbtqrg8f3CCKTHtyNsNF7yocQ3Zk6COsI3pkyUTVtX\/CUjyprsGycLo\/bMWYADdWPw4MHSsGFDt7yJcFA\/vkl5yBf5A08fc3Bk8hPBpGXQukZ9WbhwoZBP8uvHmelzgkDwI6H17Nixozz44INuJp0Z17FjxwoTREhM328mz1Ro7f5gAoofT4MGDdykEG5ziiejAEbd\/bB+V1HtMfFLnL47dj7hTvyQ74\/w2GGSLunTLfZBp7IRBn8QcRE3fvCLHfTkk0+6mXziwh0Te0z\/nbiIE7soETdhMH034sBeSd01D+SDZ4hn\/MEMWibetWw8Ex\/x44d38tS6dWus4uTHhR\/8qiMMQGtFC48d8eFHibRIGzfKSvy44Y+88wzdf\/\/9ght5Jr2oX8L7\/v14cfPJD0vcfn7JC2F9u1RhSRN38kTeIJ6j8fhpzpgxQyDKgz1xkA\/KTFxK5AF7\/EUx1\/hxh4iDcMSH0MTkPRuUVCAQ+X\/\/+19ZsWKFINWLiopk3bp1bpkMYYF7iJDuDDtCQgM7upFIOohn7ELxmF3FIED3n2+DSW+Q+ZtQNz+UO5ijd+\/ebr8DLXnIj9mVRACsM8W8ZGzlsykhEBACMPV1110nSHzGZl9++aU88sgjsmDBArnqqquEoUUoWSYihw8fLtu2bQs5C+v3J598smsxkXRIZ6Sf75l37FX6+m72nHsEaH34NpgwON8B4jmd1Gn5CI+Zjn\/zIwLWYIYJzuAN8ZxvfBIEAgzNOPCCCy6Qr776ym08Yab0hhtuEMahsVgsaf6+\/vprtwGGYcYPfvCDoL8NGzZIrVq1gm5maQiUFQHzn30EEgQCEmn06NGyePFiufXWW+WII46Q6tWrp5UqXURmj5kUSRaAmWPGU8zysooxadIkoUfi+6frZHRgfOu1YWFYUAeSTUj6vJON5wSBwJiRGXtmSEuLnN6E+mFPN8sizJKmEiA1atSQIUOGCDOjrGRMmzZN5s2bp9HETbpPRu\/Hh1YVhQUfpKLStnQTvz9Dbb5HrilBILDcwfo5+8pZLklF+NHMsbRGy9+yZUs378Awg54CyyLqB7Ndu3bStm1bicViwrCCOYq3334bJ6MCRGD27NkFmCvLUi4RSBAIrB5ce+21gjRi7TcV4UczxgSSSnSEAYzO2q+\/HLJ9+3bp37+\/2+iE4Nm4caMbmrRo0UKjMbMKIWBFLUwEEgQCqwe04uw1SIfSKRLHPKFddtlFEDbsfERgED87IY8++uh0ojE\/hoAhkAcEEgRCNtJj2ZAlE0zi69mzp0A8s6WTicRXXnlFXnrpJbcTMRZLvnJBGCNDwBDIHwJZFwj5y7qlZAgYAtlGwARCthGtAvFZESsvAikFAodRGP+z+3DNmjXCe+WFwkpmCBgCSQXCU089JWeffba88MILwlZizjFccskl7nSgwWYIGAKVE4GgQEBXHGcXOHU2dOhQpyevUaNGQk9h2rRpgnvlhMNKZQhUbQSCAoHDTJxlQHGFDw\/v7CfA3be3550HAcupIZAKgaBAqFOnjtSvX9+dcFQdhxxe+utf\/yp77723oLwkVaTmZggYAjsnAkGBwCYiTjgykcjmIXYfoq2Hcwcci95tt912ztJarg0BQyAlAkGBQAh6AqNGjZI333zT6eBHkwubithchLuRIWAIVD4EggKBI8mcZkSbkU4gquJM7HDDT+WDo7BLZLmrmgg88urHsumsB6TOb54XnnOJQlAgoMiEo8zoLOjcubOgeJXr0Y499ljhHRVpHHzKZcYsbkPAECiJwP571yhpmUWboEDYu3jisHHjxvLHP\/7RDRdQ5Mj5g9tvv11OP\/10p8OAuYQs5sOiMgQMgQJAICgQ6CGgXNM\/iRiLxZyug+XLlwvuvlsBlMOyYAgYAllAICgQ0IuAOjXUoulcAToMWG345ptvhFWGpUuXZiH5qhOFldQQyBSBNRvCSoszjS9VuKBAQC8Cy45cwYWefbQcHXnkkcKuRS6FYDly2LBhqeI1N0PAENgJEQgKBMrBRSmPPvqo03\/42GOPyd\/\/\/nenw4Cru9CE9Nxzz+HNyBAwBPKIQMM6FTCpqOVD6arescCQ4d133xVucGLZUf1kYrLrEe1JXFCRSXgLYwgYArlBIGkPgRtsUcOOujMlTj+iOZkhRXmywxZoTlCWJ458hrW0DIGqgkBQILCKgJJUVKVDl19+ubvSjVubmjZtKkw4ZgoQk5EsYZ5\/\/vmZRmHhDIEqhcD8lRvj5a2QIQMnGmOxmKAXEXXpH3\/8sbuerUuXLm4PAgIjnsMyPHBRy\/jx492wY\/fdd08akkspjFZJRWPAfRsVnQdLf5W8\/MorjldyLQxIJNhD0GVHegnf+973BEZGKKxfv142bdpU4rYlIiqNmIOYMGGCu5ehSZMmKb2je8Gokbs+ryJxYGK5ItO3tBtJ9b3qy\/a6hzh+aZjjXYokEhQIzBGwvLho0SJ3QSs9A9Smd+3aVbi7sW7duoQtE3GM+sUXX5QBAwa4a8pGjBjhbgnmvUwRldGzeTcEdmYEhj+9Kp79gR0axZ9z9RAUCCSGdGarMnMGbFfmys1uHwAAEABJREFUFqa33npLUKMWi5Vddfoee+whqGfXC10GDhwo0MiRI0nOyBAwBCIIcJAJwrra1k\/kuINq85hTCgoETjT26NFDMDV1hg6ffPKJdOvWLcFe3c00BAyB7CEw\/OnVcvkj\/7vmsMY707MXeYqYEgQCAuCEE05wZxbYpsxyIzfPKnH6kclAbnlOEWdaTn379hUoLc\/myRCoIgiwTRlB4A8VioqHCruumZ8XBBIEAqsKc+bMEZYFOe6MqV18NR944IFyLTuWpVTm1xCoCgggBBgadB69RFr8YUFc5wGrCgiDog4H5A2GBIGgqbLUeOeddwqm2plpCBgC2UNAhQC9AYQA5rz3NsUTQBhM\/\/URkk9hQOIJAkGHDDpECJkMKfBHYCNDwBBIDwFfAGhPACFAz8CPAUEwuntTWfp\/xwrPvls+nhMEgg4ZdHgQMhlS4C8fmbM0DIGdDQEYH4LRYXiYH9Vn2gvA3u8JUD4Yv6h4noAeAYKge6t6WFcIJQiEaA7YJcbS4+DBg4Ur3crSM4jGZe+GQGVCAKaft3KTG+\/D+BDMD+NDvIeYHwwQADA9PQEVAkXF8wT5WFYk\/VSUVCBwlRvnDeglEAE9A\/YjYM+7kSFQmRGA4aEQ02uL3\/meJW5pEMaHoi0\/+MD8UFQAIAywKwQhQD6VggIBTcsPPfSQ3HXXXY5uvvlmGTNmjNxzzz3u8ha2MmsEZhoCOyMCMDukDK\/r\/n4rT0ufDtNr+ZXxYXQYXlt\/hgG8Y19oAkDzrmZQIOhVbexWVI+YvHPw6YsvvuDVyBAoSARgdCjE7DC8tvA+w7Pur608YZMVDKY\/rnFtgblhcgjG33BbOzcRyDuEe6Ezf6iMQYHAVW1oXkZvAcpMCIhuRYYLnHPg8BN2RoZAPhGAUWFyCObVVp3xOowOg5fG7KFuvV8GGB6CoSGYG4aHlOmnX36EYI87tDMyvl9m\/zkoEFCiipp1DiOhLg2dii1atHDDhUGDBglCwY\/Eng2BTBGAySFlchgdBodgcggmh2B4uvAQ7tqqEwZGJ55U+YDRIW3hi4pn9mFsmB1ShtcuPm7K8JWJ6VNhFBQIBODKNl+nIpOK9BAOPvhgnI0MgSACMCXkM3i0JYfJYW5lcp6VyWF0GByCyaFgQhFLn9Fh4lTMri18UfHMPn5hdigSZZV8DQoElhdRl\/b73\/9ePv30U7djkRuhY7Gyn3KskqhWokLD3JDP4DArjAvB3BBMnYzBoy05TE6cpcEEk0PaosO8RZFWndZcW3ZldFr2ImP27+At429QIOyzzz5OVwFDh1\/84hfCFW7c4oQGHRSdlDEN814gCMCESj6DJ2vBW9612u2th9n9FhxBgFCAYG6IeNMpJgwOhZgcRqbr7jM5z6kYnbjSSdf8pIdAUCBUr15dGBoUFRU5lWkzZsyQBg0aSO\/eveWss86S8mpdTi9r5isVAjCgUjrM7bfeUQbPtAUnfzAkBINDtOIQzA3B4BCMrS05zyEmJxxdd+IjbqP8IxAUCJoNVhZWrFghkydPFk45oj6tdevWNqmoAGXJ9Bm7Ipmb4sCMEMx9ZtM93PIajApzQzA3BFNHGdxncsJAMDhEnMRvVNgIBAXC5s2bhdWEFsUrCyhKQTHK6NGjZcGCBcLqA9qPCrtYFZM7ZWzMdBibltpvuemWQ3TJofK03CAAE0IwNwSDQkU7xuGlMfiQU+q65TX8EQ6CuSHiJQ2jHCJQAVEHBQI9gwMOOECmTp0qKErhWjeGEAwlKiCPFZYkjA2lw9w+Y8Po6TA2cadbOBgQgrEhmBNKl7n91rtox4Qb4WFuiLjTzYv5q7wIBAUCm5LQZpSuEGCiEY3KDCd+9rOfCWcgOBgVhY3VC45P67FqnrGL+svHO8zoMzotMrPlEAztM3g6zF2WPMN8kM\/YMCctsZJ2y0vrmhtzlwV581saAkGBUFqgqPvKlSvlySeflOnTp8v8+fPlnHPOcWcfov4Yepx88snCgSmIvQ35OEoN8zMjrkyvzO4zOu7MlkP4j+Y99A5TQzA2BFNDRSm65NFxtwoATMIqaatN\/KG0zc4QyAUCWREIqGVHbfu+++7r8shFLvrsLHb8YF+rVq0db8kNehflpfmvr5A7Z74hp\/5xgVs6Qxgo0ydL+Ue1dhGo5X41hAk16NLWtYWxNDTmnHoCzbiwgbx25QHyeM96jkZ1rC3QgGNqCNS1ybdyTN0vHO1XfaNA\/\/1sXYVfvFJWTFlmLmsY87\/jgp1V2TPpUSers9m2DwoE5hBgXkw\/Qd5D9gwxmjdvLrNnz5bGjRsLw4f27dv7Qd0zpyRZwmzVqpWgsHXSpEnBS184RJUpcbHFyJe3yZnjP5Qhz34ir320zaWtP7S4EC0xrTJE95yW+80hbQV65ppjZfwlrRzd0u0I6dexmaNzj2sqUJvmB1f4JSqZ4lOWcCw1l8W\/+c3N5Tr0prX+5tpMEAgwPHsMli9fLpdeeqlgMsZX4m4G7mVg92IoY6eccoq89957wv6F4cOHy+eff57grUaNGjJkyBBZuHChcGfktGnT3D6HBE8ZvtDNZ4MN4396AhqNz\/wwPmNyCEGAUIDonqt\/Mw2BqoxAgkCg9b\/yyiulT58+smzZMmeee+65otSvXz+3a5EegQ\/avHnzZOjQoc4qFotJy5YthSPUW7dudXb6065dO3eVWywWc9uhUfP+9ttvq3PGJsKg8z1LhGU6jQRBUFQ8lveZ3xhf0THTEAgjkCAQ0LJMN37mzJlyzTXXCObcuXPFJ65e49IWPzpOP3KrE5OGrDi89tprbmcj5x\/UH3oU+vfvL1OmTBH8bNy4URYvXiwtWrRQLxmZ9AboFSAUiMAXBEXFy2vYGRkCZUKgCntOEAgMGeglwOAcbtq2bZu7pUmHDJgMKfDnY3bkkUdKx44dpXPnzq4HgR6F3\/zmN7LLLrs4XYzoY+T52muvdQKBnsEZZ5whzDMcffTRflRlekYYMFmogYp29AiKTBAoJGYaAmVCIEEgIAwY47OMyNBBhwq+iT3+\/FRisZj06tVLXnrpJbeRiUlFjk\/jp2fPngLxjB09EC6AwS9hYrHMTlDSI4gKAxMEoGxkCGSOQIJAYMjABS1c8Arj+kMFfcYef5knWf6QCAPmDDSmouKeQZH1ChQOMw2BjBFIEAgaC0MChgYMEaKEPe7qtyJMJg8RCqTNKoEJA5AwcgjYT7kQCAoEhgQMDfyhAjsM0YvACgTu5Uq1HIHn7dCFTxRMILJ8yLORIWAIlB+BoEBgSMDQQIcJmCxDjhs3TpgQjC47lj8b6cWwZsM2GfH0qrjnu7s1jT\/bgyFgCJQfgaBACEUbi8Xc\/gKGDBXVQ5j\/3ibhrAH5Y6hg+wpAwsgQyB4CQYHAHAGMH50\/mDVrlluGZFkye1lIP6ZHFq5znhkqdG9V3z3bTyVCwIpS4QgEBQI9gOgcAvMJbCrCviLuZWDuQHsHbRrXFusdVHjdsQxUQgSCAiE0h8A8AvMKrVq1qhAY\/LkD6x1UyCewRKsAAkGBQLk5xtq9e3dBZwHv48ePd2rVGErwnk9iMlF7B+gdsN5BPtG3tKoSAkGBwN2Nt9xyi6D9iINKAMK25F133VW4+JVzCdjli5hM1LS6t7a5A8WioEzLTKVAICgQ0FvA0WVUoalCVZYaUau2bt06YY4hn6VPnEysl8+kLS1DoEohEBQINWvWFE40cmrRR2P16tVCLyGfqwz+cKHh3jX87NizIWAIZBmBoECgV8BpxRtvvFHQYcAzpxnRh\/DLX\/5S8rnK4A8XBnZolOXiW3SGgCHgIxAUCHhAJdqcOXOEuQS2LaMz8fnnn5eTTjoJ57yRDhdI0CYTQSEHZFEaAjsQCAoE5glYYUDhCVuV0V3Qtm3bvPYMyJ8\/XGB1ATsjQ8AQyB0CQYFQr149OfXUU90Vbkww5i751DEjENRHm4P21kczDQFDIEcIBAUCew3Yd4BuBIYOqIFWKs\/lKmvXrpVu3boJWpJY0hw7dqx8\/fXXSYvmzx+wOzGpR3MwBAyBrCAQFAhcnsL8Aeqfo4Q97pmkjgDo0KGD06r0xBNPOF2NXCabLK75Kzc6J84u2PyBg6Lkj9kYAllEIEEgcKiJPQa02vQSooebeMcef5nkgRudunTpIrFYzGllRtlqshULhgu6O9GWGzNB28IYAmVHIEEgIAwy0amYbrLNmjVz+xh69Oghxx9\/vBx22GHCfEU0PNumP\/jgg7j1T\/aRne7WI8qws5Pd3LSqIOodw\/U4M+T4IUEgcKiJeYNc6lRkj8PEiROFTU8oXWEIEi0jNwDN+\/h7ceszjsrNjTikY5Qc2wYNGlSJG6oKvQ4wbI8zQ44fEgSCnxatG0uPyrBMMg4aNEgYMvj+0n3esmWLDB48WPRiFrZCs6S5cuXKYBRrNnwRt2cOIf5SmR6sLIZAgSEQFAi5ONy02267CfFyoQtzB1zUsnTpUkl2nPqDDd\/dyYgwgAoMN8uOIVApEQgKBPYeZPtwk17UMnXqVGnTpo106tRJuAuSS16iyNqEYhQRezcE8oNAUCDk6nATF7Uwf8AlLfPnz3eXu8RiJS9qQSBo8W1DkiJhpiGQewSCAoGJPw403VgAh5sKdkNS7r+NpWAI5B2BoEAgF+xQZEKxIg43+TsUyYuRIWAI5AeBpAKB5JkIZCUg34eb5tsOReA3MgTyjkBKgZD33OxIcM3GHSsMphBlByJmGAL5QaDgBMI3NeuKP6mYExgsUkPAEAgiUIACYZ94Rm2FIQ6FPRgCeUEgqUD46KOPZOTIkW53ITsMlYYPHy6bN2\/OS+ZshSEvMFsihkAcgaBAYGMSy44cMOLGZzYSKbVu3dopYI3HkOWH7XUPzXKMFp0hYAiki0BQILDFOBaLSVFRkZx55pnCKoMSSldzqXV5e91D4nkP6kCIu9qDIWAIZBuBoECoU6eOO+WG2vVsJ5hufHZ+IV2kzJ8hkD0EqoWi2rp1q9NbcPnll0ufPn0S5hFyPYegPQRTihL6MmZnCOQWgaBA4JKWE088Uf7whz8IGo50\/gAzl3MI\/nLj\/nXsUpbcfnqL3RAoiUC1klYizBEwV6DzBr6JPe6hcKXaleLBFwgN63y\/FN\/mbAgYAtlGICgQSITjzwwP0I6MpmXONdx+++2CPe65JltyzDXCFr8hUBKBoEDYvn27DBs2TNCpN2rUKKlfv76bZGQ5cujQoYJ7yajKb2OHmsqPocVgCJQHgaBAQJvRP\/\/5T+H6th\/\/+MdSrVo1qVGjhlx88cVOSOBenkSThTW1acmQMXtDID8IBAVC9erVXS+AHkE8G8UPX375pVOhjnvxa9b\/TW1a1iG1CA2BMiEQFAjsQ+Aqt1\/\/+teChiPueORilSuuuEKOO+44QUFqNBW0IJ188snCKkTHjh3lzTffjHoR7nVgPgK10hDP2JXwaBaGgCFQIQgEBQI5ueiii9xZBlRAb9u2TVB5ds01152fuTAAAAxYSURBVMivfvUr10vAjxJDiLvuusv5X7hwoVx22WWCOnd2PKofTAQLQoM4ISYq\/Vug7GIWUDIyBCoOgaQCIRaLSYsWLWTIkCEyZcoUx+AnnXSShIYLqGY\/4IAD5OCDD3Yl+elPfyqffvqpRIccGzZskFq1ajk\/0R9\/yXHvXbcXxAUZqKKvysSkclUuf6GUnd50lF\/K9548dFKBQJcfrcgsO3IFG0OBs88+2zFqNLomTZoIqtbQxcg1cGhW5tKXvfbaK8ErAmLGjBlO9TpDj0mTJknoWrjDGv7ArWoU+gUalT1\/dlFL8kts8vnt6U0nMFIOX4ICgb0Gt956qxsecI\/CvHnz5I033hC6++xejA4FNH\/vvvuudO3aVZYvXy433XSToIJN3TBZqaDHwbDi8ccfl2nTpglx4+bTXbdcL0hFowMrFAe+t32Div0Gir\/PH7l8DgoEzjLQ0tND0CEC25lhdoQBLb2fKS5eefDBB4WzDxybvvfee4Uegu+H53bt2knbtm3dHATu6GvUm5wa1qkhG25rJ0v\/71j58IWHBKlo9L7h8L5hoHwAD+WaggKBVYZDDz1UXnnlFYHZNRPcx8jdCrirHSZjTYYCY8aMcQyvQgQ3JTYz9e\/f381HECcTkYsXL3bzFOoHE8GAaWQIGAIhBHJrFxQIMOuSJUuEVQUUpBx\/\/PFuufHqq692XXwmF7HTrK1cudItM15wwQWCPdStWzdhsvHhhx8WSG9uYoKSngHnI9q3by9HH320RmOmIWAIVDACQYHA5GC\/fv2EswvXX3+9U5TCrsXbbrtN9B3lKZp3hgJ0\/V988UWZO3euIyYMGRb07NlTIPzSu8Cengf7Fnr16uWGD7gZGQKGQMUjEBQInGaEyWnFGfNzISvzCbz7VPHZtxwYAoZANhEICgQSWLt2rZx\/\/vlujE8X\/7DDDhN2LjIMwN3IEDAEyopA4fsPCgTOLHCqkd4BS4jMcr7++uvSuHFjufnmm905h8IvmuXQEDAEyopAUCB89tlnbqchG5JYbiRS5hW6d+8u69atE3YcYpctYokT3QsMTdiw9OyzzyasbmQrHYsnEQFWe1guZtMZuI8fPz64UYzvoevhmAMGDEiMyN5yjgArfDfccEPO0wkKBDYU7brrrrJ+\/fqEDLAdmUrEikGCQzlfZs2a5Y5VM9HIpOOf\/vSn4I7IciZjwSMIsOz7zDPPyNNPPy1PPfWUPPfcc\/Lqq69GfIlwFJ4lZXqKEPd1lPBkFjlBgPM\/9MrZ48P+oJwk4kUaFAhsOaY3cOmll8p1110n7DGgBedgU4cOHSS6D8GLL6PHOXPmCCck6Y3st99+wmoEQ5WMIrNAaSMA87Psy+nVPffc020pX7RoUYnwVErqRAmHKmVRMYVlT89RRx0lHBvIRw6CAoGETz\/9dHn00Uelbt26smDBAteFf+CBB+Siiy7COWvENmn2PZAOkcZiMbddl1aJd6PcIcD+Ec4raArMEa1evVpfnUmPEIFAd7VZs2Zy3nnnuT0nztF+co4Awpr9Oi1btsx5WiSQVCDgyAEOdhfSZRk0aJBQIWKxGE5ZJaQgQ5SsRmqRpYUAw8NUHr\/66iv33ceOHevOs7A\/5cYbb3SbzlKFM7edE4GUAiEfRdp9992FCUuWOUmPFoljp4cccgivRjlEgCPr7733XjwFnps2bRp\/5wGBwQ5U7UlwJJ7v9fHHH+NsVMkQqHCBEIvFpF27dsI8AqsNXDLLZOZBBx1UyaAuvOKwLZ0t6hxWg3iG4f2ccr8nwwSEBfbvvPOOoDBHBQR2hU+Ww3QRqHCBQEZPO+00p5aNpa8ePXq4Y9f7778\/TkY5RODII48U1NgxX8RkMYIZO5Lk\/AnEd2BD2oUXXihsUBsyZIibaGZsiz+jyoVAQQgEVhc4G8EZB85CUDErF8yFWZpYLCYMB9BJwZKvf7aE8ycQOed74Ofll1+Wv\/3tb4JGLOyN8ocARwfysdxbEAIhf7BaSoaAIZAKARMIqdAxtwJAwLKQTwRMIOQTbUvLEChwBEwgFPgHsuwZAvlEwARCPtG2tAyBAkfABEKBf6CdO3uW+50NARMIOfpi9913n0ClRY96ew6RcaajNL\/purOEePjhh0tZjilzxLks\/tPNSyb+yAvHrNkjkYur\/jR+9rxkE\/dMylpoYUwgFNoXyUJ+li1bJhyIyce6tWaXLeehS3fUvawmm6DY8+Bf9VfWOJL5Z02fu0o54ZnMT1W1N4FQji8PE3A0nMrLSUE0TXMmgxZoxIgRAtFLwN+ECROEVht\/HPXmZixaPy7QRSdBnz59hNYKFXUcM+daPOJ9\/vnngzlkmzcHjogTv9yHwfZjTZvbs0ItPvFfeeWV7to94ofpNAEU43B4iTyiO5MzJbiRFmVBNT9psYGJcuJGGggetGuRV\/xyzyd+2Xn6u9\/9Lt5TAQcu6EERDvFonoknGYEJPag77rjD7ZQkXvJCOtEwlN1v9aPvUf\/2XhIBEwglMUnbhgM+MPpDDz0k3FoFA8CktEADBw4UqG\/fvsIxY1okCH8IhL\/85S9C63f33XcLN22jgIRTn+ifOOKII+Qf\/\/iHjB492gkVwkQzRWWfPXu2U2xCj4BDSGjJ5rYl0oVgVD8cd2Nw8xbasAkD495zzz3CeQX8LV26VH7+85+7m7fatGkjaFPCnh2kDG04Bk+4evXqyfTp03FyhA4FBCPlRtkNehbwC\/OjUMV5Kv5htyNH6DlWTzyaZwRFsXPSfwQdGoNQ4kK5GRKRTtIA5pAxAiYQMoZOnG5JdAVwNR03WtHa0yJGo+RUIQyPib\/atWtHvbh3WmRacJiS7dycK+D0IcLBedjxA2PTstMjQaEMWrJ5RgMS+dnhrYRBj2TNmjWC8hvCIHg4m8DpRTyjLKVNmzaCRizUqsGI2NOiI5w4v0DLHFWWQtq4wdj0ElC9xzuChxabOKCZM2dKp06dnL4L0ifcihUrZPPmzTgnpWrVqglnKYiTQ1UctuIwXNIA5pAxAiYQMoZOhIM\/XFv3wgsvCJfi0vKz3z8aJacDuesSJoMZOa8R9cM7Y3BaVJiSSTW67tOmTRN6IrgrER96LZWRsYdZaHFhSt5DhAo8hIkyNIwPsxMW\/9y9iR3PPhGOIQ0CAwU5UW1Wmo8tW7a4vOo7cSDYMCGECd19ygahBQgBhVJf3JMRR+T33XffuLP\/HLe0h6wgYAKhHDCicJZWlNafo8MXX3yx3H\/\/\/QJj+NHSvYYZ6OrStYYRfHd9ZshAj4AuOIIBohsPE6ofTJisZs2abs6Bd4gj47SkCAXeQwTDY49AwaS38uc\/\/9nps+Q9GTEMQnAg7B577DE3lg\/51XxRVnVnDkCfcUcwUi4IwYLAoyehfkIm+WV+Q90YgoUmBCkfaag\/M8uOgAmEsmMWD0FlHzZsmJsjUEsYUltZWmPsqdC0grwzXke78TfffCPamvOMv4YNG7obsxkf01tgqMCJw+gcAmlwAhGFtAwxyAfPtODftf7EVpLobtevX9+dWCQvjMcRVsRX0vf\/bDT\/5InJUOYGCP8\/H989EQ\/X+E2cOFFQi\/fhhx8KcwbfuYq75g+BiM4LhNGdd97p5kiIV\/2ETAQM8w4MLRhWkecTTzyxhFd0fZJX4iYMymNLeDKLlAiYQEgJT2pHlLh06dLFTcQxa05PgXkEGIMjwvQWWGXADxW0efPmwsx67969hdZ23LhxwgQdTE2XnNS4D4MK36RJE8HfVVddFTxu3LVrV2GOgdl9lHAiXFidII5kxLh9yJAhThkNGqmYF+DYeWktNHmbP3++0HuhTKxSMBnJfEE0LeYPEDwMj7p16+b0LagflkIZVqF\/gdURhgtMfqoAVX8hk2EDd4p27tzZKRxliIY\/8GWeAqHINwAT0kC\/A0Mh7UkwKYqwwiScURgBEwhhXNKyjcViwhIcM+Z0gWnZEQQEZsWByscqAwpk6ZrT0k+ePNntEWD4AAPDjHSbaVUZe8NMtPZoKEJoMHMfi5XUY0nXGGZCgxHEvZta+UkTIh9RQqO1xk9+WXrED+n4qxL+e6NGjVyvgglAVibOOusstwpCL4Uw+CUOiN4OKyX4ZVUBoUlecWNIhP4F8MJ91KhRTjEObqURaTCUAtNLLrlENE7Kqdhhh4BjlQOV8oMHD3ZDOHBFHyhzN5ilpVWV3U0gVOWvn4Oyw5z0Qui20\/NhP4S25jlIzqLMMgL\/DwAA\/\/+L9w2HAAAABklEQVQDAKhVjVXB5vWiAAAAAElFTkSuQmCC","height":157,"width":260}}
%---
%[output:079b8d53]
%   data: {"dataType":"image","outputData":{"dataUri":"data:image\/png;base64,iVBORw0KGgoAAAANSUhEUgAAAQQAAACdCAYAAABSFgY1AAAQAElEQVR4AeydD7zV8\/3H36eMFpK0qUmTiGwpUlhC\/hRJYaR\/YxrJEE26LT+WWVQaQv7UtEWSlaQsGaGUSCphpKiF0kalKaHxu8+P3mef872fc+65555z7une933c9\/l8v5\/\/n9f3835\/\/r8\/1b61P0PAEDAEdiBQTezPEDAEDIEdCJhA2AGEGYaAISBiAsFqgSFQSRDIRjFMIGQDRYvDEKgkCJhAqCQf0ophCGQDARMI2UDR4jAEKgkCJhACH\/LZZ5+VAw88UDADzuWyIk4\/7gEDBsgJJ5wg\/\/rXv8oVrx\/4888\/lx49ejji+Y033pDmzZvLfffd53vLyXO0fMkSIS\/kibwl86P2ZfGrYdIxwQac+B58h3TC4EfDEZZn7MpLmYQHu+OPP14wMwkfCmMCIYDKKaecIu+\/\/75gBpzLZUWcuYq7XBnLQmCE2k033SQDBw7MCXZZyGJCFKtWrZK33npLzjnnHBk5cmSC287w0qxZMyf0r7jiiqw1KBUmELQlQTpDtAJS\/EelosVE+mLihol9sbP798P6bmrfqVMn18ITNpXkJ038KKlfjQeTdEkDN4h80SoglWnhNCx+8EsY7IibzOo7ZvQdP1OnTpUPPvhATj311BKSnjDEhUlYTZNwvGOPu5La46b0ySefCBXmP\/\/5j4wYMUIoA26YGg6Td+whnrGjfLRAWjbcKDsY4A75aS5btkw2bdokbdq0waurpITFH8SzYkReyFOXLl1cT0zLhj+ItLGjjFG\/RE66+IPID\/nCPkrEQVz4gygbfsiH4sI3UHvclKJhNf\/q\/uGHH7qyEq\/vRl7IE\/ZK5JdwmOTn4Ycfdr02yoc96eMXtyjm5JX4cYc0DOHAGswpA+\/lpQSBEE2YxFNRpolToD59+riWhNaSFoWPDlgaJ5L77rvvlieeeMJVMtxx88NSAffbbz8577zzXOXDHTr00ENdC4\/kf+aZZ0owGn6IhzhJW\/MAqNjjHiXcIOyVyX7yk58IeYjmET\/pUN++fV3rtP\/++wv5ROL74Q4\/\/HDBbeXKlc56\/vz5zqQSkM\/SMMRz3bp1BRz33HNPhzctIWEpy5gxY+I4vfrqqw5D3408xWIxonFERSfNjz76SF5++WUhPBjqd5s1a5bUrl1b9t13X8Hv1VdfLXwfMMI\/keCfXhK4kyewO+aYY+SWW24RH0\/8Ut6oX95Jj3hIn3jJD\/kiTcIpwdC9evVywpZvjH\/KDfP98Ic\/lMmTJzt8qSfgouEw4QUEhp8nGI90cYc+++wzmTBhQryOEjf22FF\/KRtlp3xz5851mOCOILz++usFk\/dUmJMP6rfiCG6UlTCEBWsw1zqCXXkoQSAQEQkDMgCmIvzgPxOi4lDR+RCEp4JTOQBt69atWLnK0ahRI4FJaD21whIWv4TZY489BGlKCwvwLmDxz2mnnVb8K3LQQQc5M\/QDgBoP7jAn5aXC8R4l8kuZJ06c6D4klYO0yQN5fP3117Pe7axZs6ZjKHChYmBSQcEFHMhTCMMtW7ZEs5\/wThkpKwKHlkcrMp40XtxgmlatWmHtSLvY2OGGH\/JAvlavXi18I+oP+eY7wqhgdsYZZ7jwc+bMCWIEhuAKwUz0GpRZXEDvB6YnPdIlffJBfmBA8ud5FQQK7xdeeCGG4J9w5BM8nWWSn\/Xr17uGKNU31m8RZUrqEvWBqKmnYMCzTzA234BvkQpz6jX1W\/NBfNRbwvjxrV27Ni5wfPuyPicIBBLq16+fYJYWUTp+QnHwQcm876aAUoFKq8yEo7JQaei9+BIbt1yRVvRcxR+KF0ahIlDZqRjgwzt+U2H4xRdf4CUp0XLSNaXlorKpR5g4Gm9IqCJAwD4aXuPBhFG7d+\/OoxsS4Zcw2rI5B++HVhv3dL8n+dY4yY8XVfwRoR9\/KX5AUPEdEeYwfLFVTv4pI2WhjlJXQ4koriF+UDc\/HLikivNHP\/qRUF\/8MJk8JwgEMn\/vvfe6btC\/\/\/3vlPF9\/\/vfT+mezJFMk3nfnY\/DR+Jj7b777r6Tk3rRSoqUR+oiYZWQtAkB03ihvKSNV\/2ImLynQ1rhaG1oaanUCLdMhWUoTVoE7GkRwIj30jAs7duMHz+eKF1XF\/y0lwHDRL+NltEF2PGjrRthIVp2wu5wjhu0lLjTdVZMmHQEr7in4gcEFMMT8hH1X+wc\/EcYICTxD9Ei01PzPUcZC4GHUKWLzXfy\/SZ71vKTZ\/3GyfxiD4OPGzfODUWoo+SRvOIWotC31DR9\/wx3KKeSDnGov9QL7RX7YTJ5ThAIfLQzzzxTZs6cKccdd5y0b99epkyZ4rrImUSeLAyZR8KrZKdrB3PS+mnFolWkCwjxTLeQVkfDAjTxw4R8KD4Y7+kSjEV5YTTCYCJo6FbynorostNd1K4neaE85E3D6UclXrXLxNS0wIo0eSce0iJN7Hn3MYwKVdx98hkF3CiHuuNGvJQp6kba5IEuOxUfRqanwZieb8M3guFgPMLyXfg+MCr5gzEQ+vqNNU2YEybVd\/xSH\/TdN2Eg6gl1grpBPpjAg3j2\/fKNeVcBSJkoG\/kkv7glIy0r2FAWDQvuycJgT\/58oUoeyStuySgV5tRH6qXWIxosegqYxEfZ+CZgy3t5KUEg0LKce+658vjjj8uiRYvk6uJJoenTp8tRRx3lJu4QFFHQM8kArTkST7tBmLQ6tCga31577SVMCNHtorLgjpuGZWIFYGhZmDQr7QMT1icq6WWXXSYwVFnj4aP\/9re\/dWNMPgR5IX\/kTSuSxvvOO+\/4yZZ4poJRSZkngcGiHkgLBsAek3eeSas0DPEHaZ7AGQalJQZTsNUJK\/JApecb4E6ZyNO3335LFI5ImzR5oaISHj+EwY6y0FrRavE9mDhTHPCPsLjjjjtc11aZlThIl+GF+l2yZIkbtqrg8f3CCKTHtyNsNF7yocQ3Zk6COsI3pkyUTVtX\/CUjyprsGycLo\/bMWYADdWPw4MHSsGFDt7yJcFA\/vkl5yBf5A08fc3Bk8hPBpGXQukZ9WbhwoZBP8uvHmelzgkDwI6H17Nixozz44INuJp0Z17FjxwoTREhM328mz1Ro7f5gAoofT4MGDdykEG5ziiejAEbd\/bB+V1HtMfFLnL47dj7hTvyQ74\/w2GGSLunTLfZBp7IRBn8QcRE3fvCLHfTkk0+6mXziwh0Te0z\/nbiIE7soETdhMH034sBeSd01D+SDZ4hn\/MEMWibetWw8Ex\/x44d38tS6dWus4uTHhR\/8qiMMQGtFC48d8eFHibRIGzfKSvy44Y+88wzdf\/\/9ght5Jr2oX8L7\/v14cfPJD0vcfn7JC2F9u1RhSRN38kTeIJ6j8fhpzpgxQyDKgz1xkA\/KTFxK5AF7\/EUx1\/hxh4iDcMSH0MTkPRuUVCAQ+X\/\/+19ZsWKFINWLiopk3bp1bpkMYYF7iJDuDDtCQgM7upFIOohn7ELxmF3FIED3n2+DSW+Q+ZtQNz+UO5ijd+\/ebr8DLXnIj9mVRACsM8W8ZGzlsykhEBACMPV1110nSHzGZl9++aU88sgjsmDBArnqqquEoUUoWSYihw8fLtu2bQs5C+v3J598smsxkXRIZ6Sf75l37FX6+m72nHsEaH34NpgwON8B4jmd1Gn5CI+Zjn\/zIwLWYIYJzuAN8ZxvfBIEAgzNOPCCCy6Qr776ym08Yab0hhtuEMahsVgsaf6+\/vprtwGGYcYPfvCDoL8NGzZIrVq1gm5maQiUFQHzn30EEgQCEmn06NGyePFiufXWW+WII46Q6tWrp5UqXURmj5kUSRaAmWPGU8zysooxadIkoUfi+6frZHRgfOu1YWFYUAeSTUj6vJON5wSBwJiRGXtmSEuLnN6E+mFPN8sizJKmEiA1atSQIUOGCDOjrGRMmzZN5s2bp9HETbpPRu\/Hh1YVhQUfpKLStnQTvz9Dbb5HrilBILDcwfo5+8pZLklF+NHMsbRGy9+yZUs378Awg54CyyLqB7Ndu3bStm1bicViwrCCOYq3334bJ6MCRGD27NkFmCvLUi4RSBAIrB5ce+21gjRi7TcV4UczxgSSSnSEAYzO2q+\/HLJ9+3bp37+\/2+iE4Nm4caMbmrRo0UKjMbMKIWBFLUwEEgQCqwe04uw1SIfSKRLHPKFddtlFEDbsfERgED87IY8++uh0ojE\/hoAhkAcEEgRCNtJj2ZAlE0zi69mzp0A8s6WTicRXXnlFXnrpJbcTMRZLvnJBGCNDwBDIHwJZFwj5y7qlZAgYAtlGwARCthGtAvFZESsvAikFAodRGP+z+3DNmjXCe+WFwkpmCBgCSQXCU089JWeffba88MILwlZizjFccskl7nSgwWYIGAKVE4GgQEBXHGcXOHU2dOhQpyevUaNGQk9h2rRpgnvlhMNKZQhUbQSCAoHDTJxlQHGFDw\/v7CfA3be3550HAcupIZAKgaBAqFOnjtSvX9+dcFQdhxxe+utf\/yp77723oLwkVaTmZggYAjsnAkGBwCYiTjgykcjmIXYfoq2Hcwcci95tt912ztJarg0BQyAlAkGBQAh6AqNGjZI333zT6eBHkwubithchLuRIWAIVD4EggKBI8mcZkSbkU4gquJM7HDDT+WDo7BLZLmrmgg88urHsumsB6TOb54XnnOJQlAgoMiEo8zoLOjcubOgeJXr0Y499ljhHRVpHHzKZcYsbkPAECiJwP571yhpmUWboEDYu3jisHHjxvLHP\/7RDRdQ5Mj5g9tvv11OP\/10p8OAuYQs5sOiMgQMgQJAICgQ6CGgXNM\/iRiLxZyug+XLlwvuvlsBlMOyYAgYAllAICgQ0IuAOjXUoulcAToMWG345ptvhFWGpUuXZiH5qhOFldQQyBSBNRvCSoszjS9VuKBAQC8Cy45cwYWefbQcHXnkkcKuRS6FYDly2LBhqeI1N0PAENgJEQgKBMrBRSmPPvqo03\/42GOPyd\/\/\/nenw4Cru9CE9Nxzz+HNyBAwBPKIQMM6FTCpqOVD6arescCQ4d133xVucGLZUf1kYrLrEe1JXFCRSXgLYwgYArlBIGkPgRtsUcOOujMlTj+iOZkhRXmywxZoTlCWJ458hrW0DIGqgkBQILCKgJJUVKVDl19+ubvSjVubmjZtKkw4ZgoQk5EsYZ5\/\/vmZRmHhDIEqhcD8lRvj5a2QIQMnGmOxmKAXEXXpH3\/8sbuerUuXLm4PAgIjnsMyPHBRy\/jx492wY\/fdd08akkspjFZJRWPAfRsVnQdLf5W8\/MorjldyLQxIJNhD0GVHegnf+973BEZGKKxfv142bdpU4rYlIiqNmIOYMGGCu5ehSZMmKb2je8Gokbs+ryJxYGK5ItO3tBtJ9b3qy\/a6hzh+aZjjXYokEhQIzBGwvLho0SJ3QSs9A9Smd+3aVbi7sW7duoQtE3GM+sUXX5QBAwa4a8pGjBjhbgnmvUwRldGzeTcEdmYEhj+9Kp79gR0axZ9z9RAUCCSGdGarMnMGbFfmys1uHwAAEABJREFUFqa33npLUKMWi5Vddfoee+whqGfXC10GDhwo0MiRI0nOyBAwBCIIcJAJwrra1k\/kuINq85hTCgoETjT26NFDMDV1hg6ffPKJdOvWLcFe3c00BAyB7CEw\/OnVcvkj\/7vmsMY707MXeYqYEgQCAuCEE05wZxbYpsxyIzfPKnH6kclAbnlOEWdaTn379hUoLc\/myRCoIgiwTRlB4A8VioqHCruumZ8XBBIEAqsKc+bMEZYFOe6MqV18NR944IFyLTuWpVTm1xCoCgggBBgadB69RFr8YUFc5wGrCgiDog4H5A2GBIGgqbLUeOeddwqm2plpCBgC2UNAhQC9AYQA5rz3NsUTQBhM\/\/URkk9hQOIJAkGHDDpECJkMKfBHYCNDwBBIDwFfAGhPACFAz8CPAUEwuntTWfp\/xwrPvls+nhMEgg4ZdHgQMhlS4C8fmbM0DIGdDQEYH4LRYXiYH9Vn2gvA3u8JUD4Yv6h4noAeAYKge6t6WFcIJQiEaA7YJcbS4+DBg4Ur3crSM4jGZe+GQGVCAKaft3KTG+\/D+BDMD+NDvIeYHwwQADA9PQEVAkXF8wT5WFYk\/VSUVCBwlRvnDeglEAE9A\/YjYM+7kSFQmRGA4aEQ02uL3\/meJW5pEMaHoi0\/+MD8UFQAIAywKwQhQD6VggIBTcsPPfSQ3HXXXY5uvvlmGTNmjNxzzz3u8ha2MmsEZhoCOyMCMDukDK\/r\/n4rT0ufDtNr+ZXxYXQYXlt\/hgG8Y19oAkDzrmZQIOhVbexWVI+YvHPw6YsvvuDVyBAoSARgdCjE7DC8tvA+w7Pur608YZMVDKY\/rnFtgblhcgjG33BbOzcRyDuEe6Ezf6iMQYHAVW1oXkZvAcpMCIhuRYYLnHPg8BN2RoZAPhGAUWFyCObVVp3xOowOg5fG7KFuvV8GGB6CoSGYG4aHlOmnX36EYI87tDMyvl9m\/zkoEFCiipp1DiOhLg2dii1atHDDhUGDBglCwY\/Eng2BTBGAySFlchgdBodgcggmh2B4uvAQ7tqqEwZGJ55U+YDRIW3hi4pn9mFsmB1ShtcuPm7K8JWJ6VNhFBQIBODKNl+nIpOK9BAOPvhgnI0MgSACMCXkM3i0JYfJYW5lcp6VyWF0GByCyaFgQhFLn9Fh4lTMri18UfHMPn5hdigSZZV8DQoElhdRl\/b73\/9ePv30U7djkRuhY7Gyn3KskqhWokLD3JDP4DArjAvB3BBMnYzBoy05TE6cpcEEk0PaosO8RZFWndZcW3ZldFr2ImP27+At429QIOyzzz5OVwFDh1\/84hfCFW7c4oQGHRSdlDEN814gCMCESj6DJ2vBW9612u2th9n9FhxBgFCAYG6IeNMpJgwOhZgcRqbr7jM5z6kYnbjSSdf8pIdAUCBUr15dGBoUFRU5lWkzZsyQBg0aSO\/eveWss86S8mpdTi9r5isVAjCgUjrM7bfeUQbPtAUnfzAkBINDtOIQzA3B4BCMrS05zyEmJxxdd+IjbqP8IxAUCJoNVhZWrFghkydPFk45oj6tdevWNqmoAGXJ9Bm7Ipmb4sCMEMx9ZtM93PIajApzQzA3BFNHGdxncsJAMDhEnMRvVNgIBAXC5s2bhdWEFsUrCyhKQTHK6NGjZcGCBcLqA9qPCrtYFZM7ZWzMdBibltpvuemWQ3TJofK03CAAE0IwNwSDQkU7xuGlMfiQU+q65TX8EQ6CuSHiJQ2jHCJQAVEHBQI9gwMOOECmTp0qKErhWjeGEAwlKiCPFZYkjA2lw9w+Y8Po6TA2cadbOBgQgrEhmBNKl7n91rtox4Qb4WFuiLjTzYv5q7wIBAUCm5LQZpSuEGCiEY3KDCd+9rOfCWcgOBgVhY3VC45P67FqnrGL+svHO8zoMzotMrPlEAztM3g6zF2WPMN8kM\/YMCctsZJ2y0vrmhtzlwV581saAkGBUFqgqPvKlSvlySeflOnTp8v8+fPlnHPOcWcfov4Yepx88snCgSmIvQ35OEoN8zMjrkyvzO4zOu7MlkP4j+Y99A5TQzA2BFNDRSm65NFxtwoATMIqaatN\/KG0zc4QyAUCWREIqGVHbfu+++7r8shFLvrsLHb8YF+rVq0db8kNehflpfmvr5A7Z74hp\/5xgVs6Qxgo0ydL+Ue1dhGo5X41hAk16NLWtYWxNDTmnHoCzbiwgbx25QHyeM96jkZ1rC3QgGNqCNS1ybdyTN0vHO1XfaNA\/\/1sXYVfvFJWTFlmLmsY87\/jgp1V2TPpUSers9m2DwoE5hBgXkw\/Qd5D9gwxmjdvLrNnz5bGjRsLw4f27dv7Qd0zpyRZwmzVqpWgsHXSpEnBS184RJUpcbHFyJe3yZnjP5Qhz34ir320zaWtP7S4EC0xrTJE95yW+80hbQV65ppjZfwlrRzd0u0I6dexmaNzj2sqUJvmB1f4JSqZ4lOWcCw1l8W\/+c3N5Tr0prX+5tpMEAgwPHsMli9fLpdeeqlgMsZX4m4G7mVg92IoY6eccoq89957wv6F4cOHy+eff57grUaNGjJkyBBZuHChcGfktGnT3D6HBE8ZvtDNZ4MN4396AhqNz\/wwPmNyCEGAUIDonqt\/Mw2BqoxAgkCg9b\/yyiulT58+smzZMmeee+65otSvXz+3a5EegQ\/avHnzZOjQoc4qFotJy5YthSPUW7dudXb6065dO3eVWywWc9uhUfP+9ttvq3PGJsKg8z1LhGU6jQRBUFQ8lveZ3xhf0THTEAgjkCAQ0LJMN37mzJlyzTXXCObcuXPFJ65e49IWPzpOP3KrE5OGrDi89tprbmcj5x\/UH3oU+vfvL1OmTBH8bNy4URYvXiwtWrRQLxmZ9AboFSAUiMAXBEXFy2vYGRkCZUKgCntOEAgMGeglwOAcbtq2bZu7pUmHDJgMKfDnY3bkkUdKx44dpXPnzq4HgR6F3\/zmN7LLLrs4XYzoY+T52muvdQKBnsEZZ5whzDMcffTRflRlekYYMFmogYp29AiKTBAoJGYaAmVCIEEgIAwY47OMyNBBhwq+iT3+\/FRisZj06tVLXnrpJbeRiUlFjk\/jp2fPngLxjB09EC6AwS9hYrHMTlDSI4gKAxMEoGxkCGSOQIJAYMjABS1c8Arj+kMFfcYef5knWf6QCAPmDDSmouKeQZH1ChQOMw2BjBFIEAgaC0MChgYMEaKEPe7qtyJMJg8RCqTNKoEJA5AwcgjYT7kQCAoEhgQMDfyhAjsM0YvACgTu5Uq1HIHn7dCFTxRMILJ8yLORIWAIlB+BoEBgSMDQQIcJmCxDjhs3TpgQjC47lj8b6cWwZsM2GfH0qrjnu7s1jT\/bgyFgCJQfgaBACEUbi8Xc\/gKGDBXVQ5j\/3ibhrAH5Y6hg+wpAwsgQyB4CQYHAHAGMH50\/mDVrlluGZFkye1lIP6ZHFq5znhkqdG9V3z3bTyVCwIpS4QgEBQI9gOgcAvMJbCrCviLuZWDuQHsHbRrXFusdVHjdsQxUQgSCAiE0h8A8AvMKrVq1qhAY\/LkD6x1UyCewRKsAAkGBQLk5xtq9e3dBZwHv48ePd2rVGErwnk9iMlF7B+gdsN5BPtG3tKoSAkGBwN2Nt9xyi6D9iINKAMK25F133VW4+JVzCdjli5hM1LS6t7a5A8WioEzLTKVAICgQ0FvA0WVUoalCVZYaUau2bt06YY4hn6VPnEysl8+kLS1DoEohEBQINWvWFE40cmrRR2P16tVCLyGfqwz+cKHh3jX87NizIWAIZBmBoECgV8BpxRtvvFHQYcAzpxnRh\/DLX\/5S8rnK4A8XBnZolOXiW3SGgCHgIxAUCHhAJdqcOXOEuQS2LaMz8fnnn5eTTjoJ57yRDhdI0CYTQSEHZFEaAjsQCAoE5glYYUDhCVuV0V3Qtm3bvPYMyJ8\/XGB1ATsjQ8AQyB0CQYFQr149OfXUU90Vbkww5i751DEjENRHm4P21kczDQFDIEcIBAUCew3Yd4BuBIYOqIFWKs\/lKmvXrpVu3boJWpJY0hw7dqx8\/fXXSYvmzx+wOzGpR3MwBAyBrCAQFAhcnsL8Aeqfo4Q97pmkjgDo0KGD06r0xBNPOF2NXCabLK75Kzc6J84u2PyBg6Lkj9kYAllEIEEgcKiJPQa02vQSooebeMcef5nkgRudunTpIrFYzGllRtlqshULhgu6O9GWGzNB28IYAmVHIEEgIAwy0amYbrLNmjVz+xh69Oghxx9\/vBx22GHCfEU0PNumP\/jgg7j1T\/aRne7WI8qws5Pd3LSqIOodw\/U4M+T4IUEgcKiJeYNc6lRkj8PEiROFTU8oXWEIEi0jNwDN+\/h7ceszjsrNjTikY5Qc2wYNGlSJG6oKvQ4wbI8zQ44fEgSCnxatG0uPyrBMMg4aNEgYMvj+0n3esmWLDB48WPRiFrZCs6S5cuXKYBRrNnwRt2cOIf5SmR6sLIZAgSEQFAi5ONy02267CfFyoQtzB1zUsnTpUkl2nPqDDd\/dyYgwgAoMN8uOIVApEQgKBPYeZPtwk17UMnXqVGnTpo106tRJuAuSS16iyNqEYhQRezcE8oNAUCDk6nATF7Uwf8AlLfPnz3eXu8RiJS9qQSBo8W1DkiJhpiGQewSCAoGJPw403VgAh5sKdkNS7r+NpWAI5B2BoEAgF+xQZEKxIg43+TsUyYuRIWAI5AeBpAKB5JkIZCUg34eb5tsOReA3MgTyjkBKgZD33OxIcM3GHSsMphBlByJmGAL5QaDgBMI3NeuKP6mYExgsUkPAEAgiUIACYZ94Rm2FIQ6FPRgCeUEgqUD46KOPZOTIkW53ITsMlYYPHy6bN2\/OS+ZshSEvMFsihkAcgaBAYGMSy44cMOLGZzYSKbVu3dopYI3HkOWH7XUPzXKMFp0hYAiki0BQILDFOBaLSVFRkZx55pnCKoMSSldzqXV5e91D4nkP6kCIu9qDIWAIZBuBoECoU6eOO+WG2vVsJ5hufHZ+IV2kzJ8hkD0EqoWi2rp1q9NbcPnll0ufPn0S5hFyPYegPQRTihL6MmZnCOQWgaBA4JKWE088Uf7whz8IGo50\/gAzl3MI\/nLj\/nXsUpbcfnqL3RAoiUC1klYizBEwV6DzBr6JPe6hcKXaleLBFwgN63y\/FN\/mbAgYAtlGICgQSITjzwwP0I6MpmXONdx+++2CPe65JltyzDXCFr8hUBKBoEDYvn27DBs2TNCpN2rUKKlfv76bZGQ5cujQoYJ7yajKb2OHmsqPocVgCJQHgaBAQJvRP\/\/5T+H6th\/\/+MdSrVo1qVGjhlx88cVOSOBenkSThTW1acmQMXtDID8IBAVC9erVXS+AHkE8G8UPX375pVOhjnvxa9b\/TW1a1iG1CA2BMiEQFAjsQ+Aqt1\/\/+teChiPueORilSuuuEKOO+44QUFqNBW0IJ188snCKkTHjh3lzTffjHoR7nVgPgK10hDP2JXwaBaGgCFQIQgEBQI5ueiii9xZBlRAb9u2TVB5ds01152fuTAAAAxYSURBVMivfvUr10vAjxJDiLvuusv5X7hwoVx22WWCOnd2PKofTAQLQoM4ISYq\/Vug7GIWUDIyBCoOgaQCIRaLSYsWLWTIkCEyZcoUx+AnnXSShIYLqGY\/4IAD5OCDD3Yl+elPfyqffvqpRIccGzZskFq1ajk\/0R9\/yXHvXbcXxAUZqKKvysSkclUuf6GUnd50lF\/K9548dFKBQJcfrcgsO3IFG0OBs88+2zFqNLomTZoIqtbQxcg1cGhW5tKXvfbaK8ErAmLGjBlO9TpDj0mTJknoWrjDGv7ArWoU+gUalT1\/dlFL8kts8vnt6U0nMFIOX4ICgb0Gt956qxsecI\/CvHnz5I033hC6++xejA4FNH\/vvvuudO3aVZYvXy433XSToIJN3TBZqaDHwbDi8ccfl2nTpglx4+bTXbdcL0hFowMrFAe+t32Div0Gir\/PH7l8DgoEzjLQ0tND0CEC25lhdoQBLb2fKS5eefDBB4WzDxybvvfee4Uegu+H53bt2knbtm3dHATu6GvUm5wa1qkhG25rJ0v\/71j58IWHBKlo9L7h8L5hoHwAD+WaggKBVYZDDz1UXnnlFYHZNRPcx8jdCrirHSZjTYYCY8aMcQyvQgQ3JTYz9e\/f381HECcTkYsXL3bzFOoHE8GAaWQIGAIhBHJrFxQIMOuSJUuEVQUUpBx\/\/PFuufHqq692XXwmF7HTrK1cudItM15wwQWCPdStWzdhsvHhhx8WSG9uYoKSngHnI9q3by9HH320RmOmIWAIVDACQYHA5GC\/fv2EswvXX3+9U5TCrsXbbrtN9B3lKZp3hgJ0\/V988UWZO3euIyYMGRb07NlTIPzSu8Cengf7Fnr16uWGD7gZGQKGQMUjEBQInGaEyWnFGfNzISvzCbz7VPHZtxwYAoZANhEICgQSWLt2rZx\/\/vlujE8X\/7DDDhN2LjIMwN3IEDAEyopA4fsPCgTOLHCqkd4BS4jMcr7++uvSuHFjufnmm905h8IvmuXQEDAEyopAUCB89tlnbqchG5JYbiRS5hW6d+8u69atE3YcYpctYokT3QsMTdiw9OyzzyasbmQrHYsnEQFWe1guZtMZuI8fPz64UYzvoevhmAMGDEiMyN5yjgArfDfccEPO0wkKBDYU7brrrrJ+\/fqEDLAdmUrEikGCQzlfZs2a5Y5VM9HIpOOf\/vSn4I7IciZjwSMIsOz7zDPPyNNPPy1PPfWUPPfcc\/Lqq69GfIlwFJ4lZXqKEPd1lPBkFjlBgPM\/9MrZ48P+oJwk4kUaFAhsOaY3cOmll8p1110n7DGgBedgU4cOHSS6D8GLL6PHOXPmCCck6Y3st99+wmoEQ5WMIrNAaSMA87Psy+nVPffc020pX7RoUYnwVErqRAmHKmVRMYVlT89RRx0lHBvIRw6CAoGETz\/9dHn00Uelbt26smDBAteFf+CBB+Siiy7COWvENmn2PZAOkcZiMbddl1aJd6PcIcD+Ec4raArMEa1evVpfnUmPEIFAd7VZs2Zy3nnnuT0nztF+co4Awpr9Oi1btsx5WiSQVCDgyAEOdhfSZRk0aJBQIWKxGE5ZJaQgQ5SsRmqRpYUAw8NUHr\/66iv33ceOHevOs7A\/5cYbb3SbzlKFM7edE4GUAiEfRdp9992FCUuWOUmPFoljp4cccgivRjlEgCPr7733XjwFnps2bRp\/5wGBwQ5U7UlwJJ7v9fHHH+NsVMkQqHCBEIvFpF27dsI8AqsNXDLLZOZBBx1UyaAuvOKwLZ0t6hxWg3iG4f2ccr8nwwSEBfbvvPOOoDBHBQR2hU+Ww3QRqHCBQEZPO+00p5aNpa8ePXq4Y9f7778\/TkY5RODII48U1NgxX8RkMYIZO5Lk\/AnEd2BD2oUXXihsUBsyZIibaGZsiz+jyoVAQQgEVhc4G8EZB85CUDErF8yFWZpYLCYMB9BJwZKvf7aE8ycQOed74Ofll1+Wv\/3tb4JGLOyN8ocARwfysdxbEAIhf7BaSoaAIZAKARMIqdAxtwJAwLKQTwRMIOQTbUvLEChwBEwgFPgHsuwZAvlEwARCPtG2tAyBAkfABEKBf6CdO3uW+50NARMIOfpi9913n0ClRY96ew6RcaajNL\/purOEePjhh0tZjilzxLks\/tPNSyb+yAvHrNkjkYur\/jR+9rxkE\/dMylpoYUwgFNoXyUJ+li1bJhyIyce6tWaXLeehS3fUvawmm6DY8+Bf9VfWOJL5Z02fu0o54ZnMT1W1N4FQji8PE3A0nMrLSUE0TXMmgxZoxIgRAtFLwN+ECROEVht\/HPXmZixaPy7QRSdBnz59hNYKFXUcM+daPOJ9\/vnngzlkmzcHjogTv9yHwfZjTZvbs0ItPvFfeeWV7to94ofpNAEU43B4iTyiO5MzJbiRFmVBNT9psYGJcuJGGggetGuRV\/xyzyd+2Xn6u9\/9Lt5TAQcu6EERDvFonoknGYEJPag77rjD7ZQkXvJCOtEwlN1v9aPvUf\/2XhIBEwglMUnbhgM+MPpDDz0k3FoFA8CktEADBw4UqG\/fvsIxY1okCH8IhL\/85S9C63f33XcLN22jgIRTn+ifOOKII+Qf\/\/iHjB492gkVwkQzRWWfPXu2U2xCj4BDSGjJ5rYl0oVgVD8cd2Nw8xbasAkD495zzz3CeQX8LV26VH7+85+7m7fatGkjaFPCnh2kDG04Bk+4evXqyfTp03FyhA4FBCPlRtkNehbwC\/OjUMV5Kv5htyNH6DlWTzyaZwRFsXPSfwQdGoNQ4kK5GRKRTtIA5pAxAiYQMoZOnG5JdAVwNR03WtHa0yJGo+RUIQyPib\/atWtHvbh3WmRacJiS7dycK+D0IcLBedjxA2PTstMjQaEMWrJ5RgMS+dnhrYRBj2TNmjWC8hvCIHg4m8DpRTyjLKVNmzaCRizUqsGI2NOiI5w4v0DLHFWWQtq4wdj0ElC9xzuChxabOKCZM2dKp06dnL4L0ifcihUrZPPmzTgnpWrVqglnKYiTQ1UctuIwXNIA5pAxAiYQMoZOhIM\/XFv3wgsvCJfi0vKz3z8aJacDuesSJoMZOa8R9cM7Y3BaVJiSSTW67tOmTRN6IrgrER96LZWRsYdZaHFhSt5DhAo8hIkyNIwPsxMW\/9y9iR3PPhGOIQ0CAwU5UW1Wmo8tW7a4vOo7cSDYMCGECd19ygahBQgBhVJf3JMRR+T33XffuLP\/HLe0h6wgYAKhHDCicJZWlNafo8MXX3yx3H\/\/\/QJj+NHSvYYZ6OrStYYRfHd9ZshAj4AuOIIBohsPE6ofTJisZs2abs6Bd4gj47SkCAXeQwTDY49AwaS38uc\/\/9nps+Q9GTEMQnAg7B577DE3lg\/51XxRVnVnDkCfcUcwUi4IwYLAoyehfkIm+WV+Q90YgoUmBCkfaag\/M8uOgAmEsmMWD0FlHzZsmJsjUEsYUltZWmPsqdC0grwzXke78TfffCPamvOMv4YNG7obsxkf01tgqMCJw+gcAmlwAhGFtAwxyAfPtODftf7EVpLobtevX9+dWCQvjMcRVsRX0vf\/bDT\/5InJUOYGCP8\/H989EQ\/X+E2cOFFQi\/fhhx8KcwbfuYq75g+BiM4LhNGdd97p5kiIV\/2ETAQM8w4MLRhWkecTTzyxhFd0fZJX4iYMymNLeDKLlAiYQEgJT2pHlLh06dLFTcQxa05PgXkEGIMjwvQWWGXADxW0efPmwsx67969hdZ23LhxwgQdTE2XnNS4D4MK36RJE8HfVVddFTxu3LVrV2GOgdl9lHAiXFidII5kxLh9yJAhThkNGqmYF+DYeWktNHmbP3++0HuhTKxSMBnJfEE0LeYPEDwMj7p16+b0LagflkIZVqF\/gdURhgtMfqoAVX8hk2EDd4p27tzZKRxliIY\/8GWeAqHINwAT0kC\/A0Mh7UkwKYqwwiScURgBEwhhXNKyjcViwhIcM+Z0gWnZEQQEZsWByscqAwpk6ZrT0k+ePNntEWD4AAPDjHSbaVUZe8NMtPZoKEJoMHMfi5XUY0nXGGZCgxHEvZta+UkTIh9RQqO1xk9+WXrED+n4qxL+e6NGjVyvgglAVibOOusstwpCL4Uw+CUOiN4OKyX4ZVUBoUlecWNIhP4F8MJ91KhRTjEObqURaTCUAtNLLrlENE7Kqdhhh4BjlQOV8oMHD3ZDOHBFHyhzN5ilpVWV3U0gVOWvn4Oyw5z0Qui20\/NhP4S25jlIzqLMMgL\/DwAA\/\/+L9w2HAAAABklEQVQDAKhVjVXB5vWiAAAAAElFTkSuQmCC","height":157,"width":260}}
%---
