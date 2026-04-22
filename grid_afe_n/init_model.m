% clear 
[model, options] = init_environment('grid_afe_n');

CTRPIFF_CLIP_RELEASE = 0.001;
s = tf('s');
%[text] ### Global timing
% simulation length
simlength = 3;

fpwm = 4e3;
fpwm_afe = fpwm; % for PWM
trgo_afe = 1; % double update
fpwm_inv = fpwm; % for MPC
trgo_inv = 1; % double update
fpwm_dab = 3 * fpwm;
trgo_dab = 0; % double update
fpwm_cllc = 5 * fpwm;
trgo_cllc = 0; % double update
% t_measure = 0.648228176318064;
t_measure = simlength;
tc_factor = 100; % tc is ts_afe / tc_factor
tc_decimation = 20;
delay_pwm = 0;
dead_time_afe = 0;
dead_time_inv = 0;
dead_time_dab = 2e-6;
dead_time_cllc = 2e-6;

glb_time = timing_setup(fpwm_afe, trgo_afe, fpwm_inv, trgo_inv, fpwm_dab, trgo_dab, ...
                fpwm_cllc, trgo_cllc, t_measure, tc_factor, tc_decimation, delay_pwm, dead_time_afe, ...
                dead_time_inv, dead_time_dab, dead_time_cllc);

% fPWM_AFE = glb_time.fPWM_AFE;
% TRGO_AFE_double_update = glb_time.TRGO_AFE_double_update;
% fPWM_INV = glb_time.fPWM_INV;
% TRGO_INV_double_update = glb_time.TRGO_INV_double_update;
% fPWM_DAB = glb_time.fPWM_DAB;
% TRGO_DAB_double_update = glb_time.TRGO_DAB_double_update;
% fPWM_CLLC = glb_time.fPWM_CLLC;
% TRGO_CLLC_double_update = glb_time.TRGO_CLLC_double_update;
% 
% ts_afe = glb_time.ts_afe;
% ts_inv = glb_time.ts_inv;
% ts_dab = glb_time.ts_dab;
% ts_cllc = glb_time.ts_cllc;
% tc = glb_time.tc;
% 
% Nc = glb_time.Nc;
% Ns_afe = glb_time.Ns_afe;
% Ns_inv = glb_time.Ns_inv;
% Ns_dab = glb_time.Ns_dab;
% Ns_cllc = glb_time.Ns_cllc;


%[text] ### Settings for simulink model initialization and data analysis
use_mosfet_thermal_model = 0;
use_thermal_model = 0;

if (use_mosfet_thermal_model || use_thermal_model)
    nonlinear_iterations = 5;
else
    nonlinear_iterations = 3;
end
load_step_time = 1.25;
transmission_delay = 125e-6*2;
sst_num_of_modules = 2;

%[text] ### 
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
ixi_ref_mod1 = -0.88;
ixi_ref_mod2 = -0.88;
ixi_ref_mod3 = -0.88;
ixi_ref_mod4 = -0.88;

% common mode voltage control for hard parallelization
en_parallel_mode = 1;
if en_parallel_mode
   u_cm_comp_mod1 = 0;
   u_cm_comp_mod2 = -1;
   u_cm_comp_mod3 = -1;
   u_cm_comp_mod4 = -1;
else
    u_cm_comp_mod1 = 0;
    u_cm_comp_mod2 = 0;
    u_cm_comp_mod3 = 0;
    u_cm_comp_mod4 = 0;
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
if system_identification_enable
    frequency_set = 300;
else
    frequency_set = 50;
end
omega_set = frequency_set*2*pi;
%[text] ### Settings average filters
mavarage_filter_frequency_base_order = 2; % 2 means 100Hz, 1 means 50Hz
dmavg_filter_enable_time = 0.025;
%%
%[text] ### Grid Emulator Settings
grid_nominal_power = 1000e3;
application_voltage = 690;
grid_nominal_current = grid_nominal_power/application_voltage/sqrt(3);

% Transformer Dyn11

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

grid_emu = grid_three_phase_emulator('Dyn11', grid_nominal_power, application_voltage, us1, us2, fgrid, ...
                eq_grid_inductance, eq_grid_resistance, eta, ucc, i1m, p_iron, n1, n2, core_area, core_length, mur, ...
                up_xi_pu_ref, up_eta_pu_ref, un_xi_pu_ref, un_eta_pu_ref);



%%
%[text] ## Global Hardware Settings
single_phase_inverter_pwr_nom = 225e3;
afe_pwr_nom = 250e3;
inv_pwr_nom = 250e3;
dab_pwr_nom = 250e3;
cllc_pwr_nom = 250e3;
fres_dab = glb_time.fPWM_DAB/5;
fres_cllc = glb_time.fPWM_CLLC*1.2;

hwdata.single_phase_inverter = single_phase_inverter_hwdata(application_voltage, single_phase_inverter_pwr_nom, glb_time.fPWM_INV);
hwdata.afe = three_phase_afe_hwdata(application_voltage, afe_pwr_nom, glb_time.fPWM_AFE); %[output:56d9a48c]
hwdata.inv = three_phase_inverter_hwdata(application_voltage, inv_pwr_nom, glb_time.fPWM_INV); %[output:261d0f7f]
hwdata.dab = single_phase_dab_hwdata(application_voltage, dab_pwr_nom, glb_time.fPWM_DAB, fres_dab); %[output:5f8f2c3c]
hwdata.three_phase_dab = three_phase_dab_hwdata(application_voltage, dab_pwr_nom, glb_time.fPWM_DAB, fres_dab); %[output:015ed9ab]
hwdata.cllc = single_phase_cllc_hwdata(application_voltage, dab_pwr_nom, glb_time.fPWM_CLLC, fres_cllc); %[output:3ff6c0a7]

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
if enable_i_react_pos_steps
    time_i_react_pos_ref_1 = start_time_LVRT + error_length + 0.335;
    time_i_react_pos_ref_2 = time_i_react_pos_ref_1 + 0.5;
    i_react_pos_ref_1 = 0;
    i_react_pos_ref_2 = -ixi_ref_mod1*tan(acos(0.95));  % cos(phi) = 0.9
    i_react_pos_ref_3 = ixi_ref_mod1*tan(acos(0.95)); % cos(phi) = 0.9
else
    time_i_react_pos_ref_1 = 0;
    time_i_react_pos_ref_2 = 0;
    i_react_pos_ref_1 = 0;
    i_react_pos_ref_2 = 0;
    i_react_pos_ref_3 = 0;
end
%[text] #### 
%[text] #### DClink Lstray model (partial loop inductance)
parasitic_dclink_data; %[output:93171f35]
%%
%[text] ## INVERTER Settings and Initialization
%[text] ### Mode of operation
motor_torque_mode = 1 - use_motor_speed_control_mode; % system uses torque curve for wind application
time_start_motor_control = 0.25;
%[text] ### IM Machine settings
im = im_calculus(); %[output:44c16bec]
%[text] ### PSM Machine settings
psm = psm_calculus(); %[output:6528d9dd]
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
psm_ctrl.ekf = ekf_pmsm_setup(psm.Rs_norm, psm.Ls_norm, 1e6, glb_time.ts_inv); %[output:99d192f6]
psm_ctrl.kp_i = 0.25;
psm_ctrl.ki_i = 35;
%[text] #### Induction Motor Control
im_ctrl = ctrl_im_setup(glb_time.ts_inv, im.omega_bez, u_im_scale, im.Jm_norm);
im_ctrl.ekf = ekf_im_setup(im.alpha_norm, im.beta_norm, im.gamma_norm, im.sigma_norm, ... %[output:group:235af82e] %[output:7d7bb37c]
        im.mu_norm, im.Lm_norm, im.Jm_norm, glb_time.ts_inv); %[output:group:235af82e] %[output:7d7bb37c]
%[text] #### AFE control (with sequences)
afe_ctrl = ctrl_afe_setup(glb_time.ts_afe, grid_emu.omega_grid_nom);

kp_udc = 0.5;
ki_udc = 18.0;
kp_idc = 0.5;
ki_idc = 18.0;

%% gain for weak grids
afe_ctrl.res_pi.kp_rpi = 0.5;
afe_ctrl.res_pi.ki_rpi = 18;

%% gains for LVRT
% afe_ctrl.res_pi.kp_rpi = 0.6;
% afe_ctrl.res_pi.ki_rpi = 35;

%[text] #### DCDC Control
dab_ctrl = ctrl_dab_setup(kp_udc, ki_udc, kp_idc, ki_idc);
cllc_ctrl = ctrl_cllc_setup(kp_udc, ki_udc, kp_idc, ki_idc);
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
%[text] #### Sogi
sogi_delta = 1;
kepsilon = 2;
sogi = sogi_filter(omega_set, sogi_delta, kepsilon, glb_time.ts_afe); %[output:18ddae64]
%[text] #### Current control parameters DQ PI
dqvector_pi.kp_inv = 0.5;
dqvector_pi.ki_inv = 45;
dqvector_pi.pi_ctrl = dqvector_pi.kp_inv + dqvector_pi.ki_inv/s;
dqvector_pi.pid_ctrl = c2d(dqvector_pi.pi_ctrl, glb_time.ts_inv);
dqvector_pi.plant = 1/(s*grid_emu.trafo.Ld1 + 1);
dqvector_pi.plantd = c2d(dqvector_pi.plant, glb_time.ts_inv);

G = sogi.fltd.alpha * dqvector_pi.pid_ctrl * dqvector_pi.plantd;
figure; margin(G, options);  %[output:78cfe014]
grid on %[output:78cfe014]
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
Vf_diode_rectifier = 0.35;
Rdon_diode_rectifier = 3.5e-3;
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
% infineon_FF650R17IE4D_B2;
% infineon_FF650R17IE4;
% infineon_FF1200R17IP5;
% danfoss_DP650B1700T104001;
% infineon_FF1200XTR17T2P5;
% infineon_FF1800R23IE7;
% infineon_FF900R12IE4
used_device = 'infineon_FF900R12IE4';

igbt.inv = device_igbt_setup(used_device, glb_time.fPWM_INV, hwdata.inv.udc_nom);
igbt.afe = device_igbt_setup(used_device, glb_time.fPWM_AFE, hwdata.afe.udc_nom);
igbt.dab = device_igbt_setup(used_device, glb_time.fPWM_DAB, hwdata.dab.udc1_nom);
igbt.cllc = device_igbt_setup(used_device, glb_time.fPWM_CLLC, hwdata.cllc.udc1_nom);
%[text] ### DEVICES settings (MOSFET)

% wolfspeed_CAB760M12HM3
% infineon_FF1000UXTR23T2M1;
% danfoss_SKM1700MB20R4S2I4
used_device = 'danfoss_SKM1700MB20R4S2I4';

mosfet.inv = device_mosfet_setup(used_device, glb_time.fPWM_INV, hwdata.inv.udc_nom);
mosfet.afe = device_mosfet_setup(used_device, glb_time.fPWM_AFE, hwdata.afe.udc_nom);
mosfet.dab = device_mosfet_setup(used_device, glb_time.fPWM_DAB, hwdata.dab.udc1_nom);
mosfet.cllc = device_mosfet_setup(used_device, glb_time.fPWM_CLLC, hwdata.cllc.udc1_nom);
%[text] ### DEVICES settings (Ideal switch)
used_device = 'silicon_high_power_ideal_switch';
ideal_switch = device_ideal_switch_setting(used_device, glb_time.fPWM_AFE, hwdata.afe.udc_nom);
ideal_switch.afe = device_ideal_switch_setting(used_device, glb_time.fPWM_AFE, hwdata.afe.udc_nom);
ideal_switch.inv = device_ideal_switch_setting(used_device, glb_time.fPWM_INV, hwdata.inv.udc_nom);
ideal_switch.dab = device_ideal_switch_setting(used_device, glb_time.fPWM_DAB, hwdata.dab.udc1_nom);
ideal_switch.cllc = device_ideal_switch_setting(used_device, glb_time.fPWM_CLLC, hwdata.cllc.udc1_nom);
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
initial_battery_soc = 0.85;
lithium_ion_battery_1 = lithium_ion_battery_setup(nominal_battery_voltage_1, nominal_battery_power, initial_battery_soc, glb_time.ts_dab); %[output:80dcfda6]
lithium_ion_battery_2 = lithium_ion_battery_setup(nominal_battery_voltage_2, nominal_battery_power, initial_battery_soc, glb_time.ts_dab); %[output:849ae871]
lithium_ion_battery_1.R0 = lithium_ion_battery_1.R0/2;
lithium_ion_battery_1.R1 = lithium_ion_battery_1.R1/2;
lithium_ion_battery_2.R0 = lithium_ion_battery_2.R0/2;
lithium_ion_battery_2.R1 = lithium_ion_battery_2.R1/2;
lithium_ion_battery_1.C1 = lithium_ion_battery_1.C1/50;
lithium_ion_battery_2.C1 = lithium_ion_battery_2.C1/50;

%[text] ### Load
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
%[output:56d9a48c]
%   data: {"dataType":"text","outputData":{"text":"Device AFE_THREE_PHASE: afe690V_250kW\nNominal Voltage: 690 V | Nominal Current: 270 A\nCurrent Normalization Data: 381.84 A\nVoltage Normalization Data: 563.38 V\n---------------------------\n","truncated":false}}
%---
%[output:261d0f7f]
%   data: {"dataType":"text","outputData":{"text":"Device INVERTER: inv690V_250kW\nNominal Voltage: 550 V | Nominal Current: 370 A\nCurrent Normalization Data: 523.26 A\nVoltage Normalization Data: 449.07 V\n---------------------------\n","truncated":false}}
%---
%[output:5f8f2c3c]
%   data: {"dataType":"text","outputData":{"text":"Single Phase DAB: DAB_1200V\nNominal Power: 250000 [W]\nNormalization Voltage DC1: 1200 [V] | Normalization Current DC1: 250 [A]\nNormalization Voltage DC2: 1200 [V] | Normalization Current DC2: 250 [A]\nInternal Tank Ls: 3.819719e-05 [H] | Internal Tank Cs: 1.151294e-04 [F]\n---------------------------\n","truncated":false}}
%---
%[output:015ed9ab]
%   data: {"dataType":"text","outputData":{"text":"Single Phase DAB: Three_phase_DAB_1200V\nNominal Power: 250000 [W]\nNormalization Voltage DC1: 1200 [V] | Normalization Current DC1: 750 [A]\nNormalization Voltage DC2: 1200 [V] | Normalization Current DC2: 750 [A]\nInternal Tank Ls: 1.200000e-04 [H] | Internal Tank Cs: 750 [F]\n---------------------------\n","truncated":false}}
%---
%[output:3ff6c0a7]
%   data: {"dataType":"text","outputData":{"text":"Single Phase CLLC: CLLC_1200V\nNominal Power: 250000 [W]\nNormalization Voltage DC1: 1200 [V] | Normalization Current DC1: 250 [A]\nNormalization Voltage DC2: 1200 [V] | Normalization Current DC2: 250 [A]\nInternal Tank Ls: 1.548074e-05 [H] | Internal Tank Cs: 2.840705e-06 [F]\n---------------------------\n","truncated":false}}
%---
%[output:93171f35]
%   data: {"dataType":"image","outputData":{"dataUri":"data:image\/png;base64,iVBORw0KGgoAAAANSUhEUgAAANYAAACBCAYAAAC8aERhAAAQAElEQVR4AeydCZxP1fvHn6uUoppKtpKZSSIVWcpSMW1ERDJpIUuWFEmhlSFrQoutBSlLEVmyy5aIyP4XwiBLqcgSoubvferM7+vr+\/3OzHe7937nzOv1zP3ee8+595zn3s99nvOc53lOjjTzZzhgOBB2DuQQ82c4YDgQdg4YYIWdpeaChgMiBljmLTAciAAHDLAiwFRzybBwwNUXMcBy9eMzjXcqBwywnPpkTLtczQEDLFc\/PtN4p3LAAMupT8a0y9UcMMBy9ePLqPHmvF0cMMCyi\/PmvjHNAQOsmH68pnN2ccAAyy7Om\/vGNAcMsGx8vOvWrZNbb71Vbr\/9drnjjjukbNmy0qBBA9mzZ0+mWzV06FCZO3dupspTrnjx4mfcr1u3bnLkyBE5evSovPzyy7Jx48ZMXcsUCswBxwGLhzxx4kSpV6+eetl44fjNMc4F7k4Ezkb4kqVLl5YZM2bIokWLZPny5XLNNdeo\/UjdtkyZMur63G\/x4sXqNr1795bzzz9fevbsKSVKlFDHgvmXlpYmf\/\/9dzBVY66OY4DFQ\/n666+lUaNGsm\/fPvWQP\/\/8c4HefPNN9VV9\/PHHZcqUKTH3EHSH\/vrrLzl06JDky5dPTp48KW+88YaSaEg1fnMM6tOnj5QvX17uuece+f7771V1+Ddq1Cj1MbrttttESyJ10s+\/Cy64QBo3biwbNmyQLVu2SMuWLQUpevjwYWnfvr1UqFBBbrnlFoH\/3Jfjbdu2Vcd4Fs2bN1flkZqtW7eWWrVqydKlS2X+\/PmqHZUqVZL7779f1q9fL7\/88ov6WHbp0kVoX4PTkvnjjz+WO++8U11v3rx5flrpzsOOARYP7ZxzzpHx48cLD+m6665TLxgvWUJCggLchAkTpGDBgu7ktJ9Wf\/vtt3LTTTdJYmKilCxZUvbv369eypkzZ8quXbsEqQL9\/vvvgtTm+E8\/\/aQkHPsAkUtTBjXuq6++Ej5QuXPnlsmTJ3MqIF122WWSN29egf+64LJly6Ro0aIKJNxv06ZNsnfvXhk2bJiSaJxHyv3666+6itC+sWPHqr7Mnj1bAPmSJUsUcLkGBf\/44w8pV66cal+hQoWE686ZM0f69u2r2nrq1CmKxQQ5BlgXX3yx+jpv3rxZvVzHjh2TMWPGKL2fLfsAjy91THD+v04gFdauXSvbtm1TUoOveefOneWbb76RGjVqSM6cORXdfffd8t1338nChQvVcaTNRRddpL7+XIqXnRebDxLq5KBBg2TVqlWcyjIlJSWpcdi4ceOU5gBgf\/75Z+HZIIUsy5Irr7xSbrzxxvRrV61aVWgPz7Fjx46q7IABA2T06NGCBkJBPpJIX8uyJEeOHKrtPFPAffz4cYEkRv4cAyy+VqgJTzzxhFIfmjZtKqgHqCK8NP379xfUnRjhu89u8JJVqVJFvWB8SACVLogq5rmvj+stxgdeaAAKAYaUlBR92u8WSYO0QmrpQsOHD5f33ntPAOlzzz2nJCm8Z\/wEICjHb1RXfnsShpennnpKkGbJycnSokULz9Nn\/A7UnzMKunAnKsDKDF8OHDig9PBp06YpdZCHxjihTp06arzAV4+HlZlrubUMLy8qXa5cuZT0xooHoKDp06cL0gKJzW+OwTNUP\/rLBwjVC5AASj5SqISc80eUGzJkiFx\/\/fVK7dblUNFq1qwpGFYACiBFQqK+0T7auWPHDkHS6jp6+9tvvynJxdgKSaTbp89nl61jgMXDQo3gAfJiYaU699xz1XPgS84+ZdSBGPq3evVque+++9S4qmLFikoF7NSpk9SvX194MVENocKFC0v16tWldu3a6jggQ6rrMSeqIqBji1pGXX57swpjh74f14XfGCo8y3Hv7t27K1WNMRBjwE8\/\/VQwVgDWCqeNGpjm8+fP71lN\/WZsdumllwqS99FHH1WgXbNmjVINVYFs8s8xwMom\/D6jm4xRUHN5WTF\/Y8hg0I9kQE1CteM8xG+OAYSuXbuq8dYXX3whgwcPFgDEuTZt2ghlIV3e84aU++GHH5TxgPutXLlSGM\/lyZNHINQ\/2sQ4iDEe0gkADRw4UHr06CFIREDP9d9++201TkKFbNWqlUDci\/ZhweTatA\/wA05AzFiZcRblsDTSHn5zT+5NG9iPBXIUsBgb8NJgcdq6dauw5cFyjHOxwHA394HJZZ5H5cqVhfETJnctMd3cr0i03THAwqLEFxc15q677lJfUrY8RI5xjjKRYIK5ZuY4cMMNNwhjYKQZEg\/rYeZqOrdUpFrmGGCdd955woNjnOCLOEeZSDHCXNdwIJwccAywMPsilR566CFlbteuTLgz4WHw1ltvKX+2cHbeXMtwIFIccAywrrjiCsHyNGvWLOWqg\/8cg3oIDwMYwACdrSHDAadzwDHA0ozS8zAATR\/DrMucC+f0MbM1HHAyBxwHrEsuuUROnDihZv6ZnIQ++eQTYcLYGC8c+SqZRvnggOOAxURwr169BBenBg0aqIlSnE5ff\/11YY7ERx\/MIcMBx3HAMcBC1cNtCQ7hgcFEJCZdTLtMTjKbzzldht+GDAecygHHAAv3palTp6oZfGb2PYMa+Y1XN7P7lHEqM027DAc0BxwDLCx++KK99tprgpMpk4\/EKEH33nuv8qHDKZcyuvFmazjgVA44BliaQcT54MJE7BFuTBA+arjSaD8zXTZ2tqYnscYBxwEr1hhs+pM9OWCAlT2fu+l1hDlggBVhBpvLZ08OOBJYZPUhqI9gOcLzCe9mojh7PiLTazdywHHAYj6LoLd27dqphCXkuSOtFjnvOOeXyeaE4YCDOOA4YOEPiPcFiUzgE2H5mN4J1+ccxwwZDjidA44DFv6ATBaTx04zj2QmJJIJxqWJPBkkhiTZCuHhI0eONNlaNWPNNmIccBywAA8h36TuIm8CiU+eeeYZIQ0XoMsqJ0ieQs4FwlEIRWHMxhxZVq9jyhsOZIUDjgMWjSdaGCCQrpgsqkwQlypVilNZJkBEchR8DQEm0ckrVqzI8nVMBfdy4NT+VIEOL\/hI9g9qEpWOnAGsqNzRz01IrYw3O5HDEBZBcgoSQcwYi3OU8VNdHQaA5MlA7SOLLNbFH3\/8UVJTU1V+cFRB0jZv375dlecfLlOGElWK61jhQ91SheSp8vlkyJ0XyRfVL5CdrRMUrRvQXLbMHnVWX3kPwk2OARZ58N59910hrTG585o1a6YiiokqRjUEKKTa8scAkldSn7RarNpBNtZ33nlHpasGYEhAVEGS\/jNe09c5WGeYGAovDy5sNFIe7jlBSNYZUfp8pHzVp7XMbVlG5ibnl7lltyvqV2yvdLj5fKl2yw1SKqmmWMl9xWo5Rgq+tVmRd5v4oOj3IVxbxwAL6x9Rw2wJDUFSkV8PIvEjWVc9AeHNAKRZfHy8XHvtteoU6iRZWQmaBJBaFQTAOk0yBeMmNZPf+ycFTSvbxAddl\/u6vb6vPjSsWFhm\/Hhcyr6bKnVH7xMWtQhEPIdA5zlX8M8dknfHQskzvZucP7KppHVMlLRed0jauA4iW5fJRYWLyxVPj5BCKfMlcXyaJL6\/SxJ7L5XETp9LQv0XJOHuR\/y2g\/uHmxwDLN0xMjEBIFQ4fYyE\/BwDdPqY97ZYsWJCgCRJHxlXPfzww0JcF17zOPIytiKVGmpgWlqad3WzH0YOdKoWL6tfrag+OI+ULyiXtZ+vqM+s1Ezf5cC4rmo8hBq3rb4le1KShGMn96dKzivizwCR9dIitX9R1caSq2TVTN8jkgUdByxC81kYgaV8WOkQeuSRR9QyPkgbzQzWW6pSpYrSl1944QV9WMgm26RJE5XRqWPHjoLpnmhkAPbPP\/8I5A0swBYsEd0cbF3q0XC2wZLd9Wl3oDYkF0sTpHLK3Xnl\/3buVwC7IeVroZ6i8W8KUmfbixUFAGk6MPdDOXzksJwqUlasN7YJ9HeHeXLiieFypEZn+bVIFdl7YRF1nUD3V\/c4PaYOtKV+uMl2YLG+EyCB+E0Hk5KS1HI1pCQm3wWZmligjHOaCCFZuHChWv6GcRVgGTFihAqUfPDBB9U6TZdffrmas0KaYdjAysgSN56qINdD1QiWrrrqKr8qRrDXjMV6TS5cKW\/+NVhmnHpZhm5K\/leVO63O7Z7YT1au25quyik1Tqtyp9U4pcolJESUx7wD4SZbgMUSMGRUxYJH\/m5yCUIENAIgvX3ssceUpCKvYEZWQSQHk794bXBtxmTkKQdETlYF+ZKG8lDtrk\/baQNqGqZsCLUN0tKHLeePbVggidcVl1Ite\/07DjoNoG8aL5WW+frLPQdayOATwalx3J92OImiDizC7IkEZsw0adIkte7uokWL1AqFqHEk0sc3kDzhLJP6wQcfqASeei5KMw8J56kKIpF27Nihsjnh\/kRWJyaVMV4EUgWxJPHggyUG0cHWpZ7b66s+nDYiKNVtzVw5vOsHOX7B5YpQ3zShxkFajQMMkFYV7yuaS+au35uuKr706Sql5lEmI+KdyKhMoPPUDzdFHVh4Vrz66qvCOIoJW+8OMcYiIy7r2qLu4TPIMjOMjbSqSB3OeaqCnLcsS1iOE3copCJrSLFKYCBV8O6VCelfz3Q15PSXNLO\/eXEyWzZmy2GB0\/SfJS6rKlyvBjfLnOf\/NXhk1aoYqurM+xRuijqwsOxhSMA8jnrHZLAnoQb269dPAUR3lknd3bt3612fW8zrgBBpRQFUQJaTAahGFYQj4vMfX3KfJ7JwMNRreNfv9J9VEcuip1Xx6bEbfbbKu77PQlE+GHVg6f4xr4R6h8WPSeCxY8dK9erVlYcERouyZcsqix+Td4y1ypQpI9TR9b1VQZirl\/7BSIEFEcmI5AqkCnI96gZLjO2CrUs9t9ePZB\/+\/mOvaFWx5S1xwjAC0z1WRVTFb9ZsUepiqDzkHQg32QYsPCWQQg0bNhQmgUki07ZtWyHmCute3bp1lcUPaUNuQcZdqHuaAd6qIBbA3LlzC1vOsSohc2KMtQKpglwvFFUiVKsg0wmh3N\/u+rQ9Gm1AVRzZvLwgxbSqWGvkT2oCesmfhUOyGvIOhJtyhPuCmb0eKhvjHyZ\/dR2MDxCqIMBDKkFY95irwpNCl\/XespxngQIF1NgNk\/r48eOFLVbCgwcPCrFcEOM0TPPe9c2+Ozhw9WW5xFtV7DNruzJ6lO6+1DGdsA1YGC7q1asnSCy+eIyzUPkYg+Hbx7I+LN0DMZeFWR71TnMOwHlaBRmzIdHi4+OFVQbxuuBa1ClZsqRa57datWrCb1yc9HXYos4ES6GqIczRBXtv6tld3842aFVxct1zZeoTVwmWRU9V8fPFG5WqSBsDEe9AuMk2YNERVmpE7evQoYNaBAHz+0cffaR+T5gwQQjH14SLEl4U1INQ9zytgqiMqCU42qI6EtyIRESKsTA26+likkflJNyfa2hiPi1zdJd4l8O66X0sK\/tur09fndCHhnWryWcv15OLZ3eS35dPNjcDugAAEABJREFUlGHTl0mLifukfJ8VZz0z2uxJEoE\/W4H14YcfCioepvWdO3dKcnKyMHeFJwUTxUgxTVgQkUri5w\/wcF6rlgRJ4tSLVFu1alW6Ksjv0qVLp18FQBralj6edTsvUtcvlz3TB8gvH7dS47EOdctnqm8S5j\/bgIWqt2bNGuU4GxcXJzfffLOwwBySZfDgwWrCWE8cs8VyCFD89R8DRePGjQVP+EqVKsmoUaOE+a8KFSoI4CISGVUQdyksjP6uY47HDgf0eMyOHtkGLMzgGDAuvPDC9H4z7mKOi7ARYqtIK62pT58+guEhvbDXD8uyBMshIETl++yzz5SlyLIs5RYFYDlObJdlWV61za7hQHg5YBuwMCAggfDvw8S+efNmYbkejA6shcUxwjw0ERUM6MLbfXM1w4HIcCD6wPqvH5ZlCfNWmMSZwMV\/kPksVhPBwEDYSM2aNUUTKhzuUP9VNxvDAUdzIOrAQgXEyIC5nHklvC2GDRumxkSMj1APmeQl5ZmjOWcaZzgQgANRBxZGizZt2ghhIvfff79g9at3ej4LIjwEiyAuSVgBUf84D7EPIAP0xZwyHHAMB6IOLMZVWPhI7gKQmHdikhPCKojEwvCA39\/y5cvTrYPUoa5jOGcaYjgQgANRB5ZuC2ogBgpPsOTPn19Z\/nr37i3aGqi3Xbt2FcBHKIi+hvd2\/vz5SgLi3IupnXvgvsRkMdKP9GcYS1BHveuafcMBCSMLbAMW4RwEIbIAAiuJQLguYcjANYlAyIoVKypvd8JGAOHUqVOle\/fuPrtPGcZqeMYTMEm2JvZNJlyf7DIHI8wB24CFc2yvXr0EIDF+whsdvzvcmwBR37591bxUnTp15O2331aRweQKZIzmiydkdUL64SdoWZYgnTCAMHeFBCPkhHkysjWZTLi+OGiOhZMDUQcWoGECmE4wZ9WpUyc1jsK\/j3msuLg4wccPkFEGQnUjFgcQsu+LihQpIkQOQ5THjxCwMT9GaIeug3mfzLh632ydzYED47qKJvJpRIrCzYWoAwtHWlS6Vq1aybJly1Twmu4U4CFTLYYLvN5ffPFFNdZq0qSJlCtXTo2x8FbX5T23CQkJgnc80g83JsBL3gwiiZGOnmU9fxNIaSgxPag0UrzQKZ912mdyZQSiJQ\/kFGjj6O6iacvsUbJ46qcRIc93Ihy\/ow4svCeYBH7ttddk+vTpkpSUlP5QCctHcmFgAHw44uJ5QYg9Drq4LBEV7KvjSDPUPwwcJOxkfgwQFy1aVDn2auMFcVqE8HteIxTHU9IVh1I\/1urq\/ix7voosblREpXwmYc9L5XNLzeJ55aF6D8lttRpkmGek0uST4ovqzjwm4abnNxf0fB3C8jvqwNKtxrsCSx8g0A+D8RBWQAIaMWosWLBAABpGiMaNG6uqAFP98PqHCsgYjKhk1E1M9jqGa\/Xq1UIYCqAiLRqRxV7VbdslTiiUm9td\/\/CCj2Tb++1Uplotgchee3J\/qspYqxPoXD14u0CkgYY8+2x3HzzbEq7ftgHLXwdQBwluZCyEoQLrHiH3SDmME\/7qETbChDOSrWrVqsI+UgvHXcJEyK3BJDS\/OebvOua4fw7o8c2elKT0rLUckxUTzgJRoZT5Ku2z\/6vF9hnHAevPP\/8UrHeAAHM72Zfw1EB6MS\/l73FYliV4riP1GLuRXhrpxngNFVJ7t3PdHTt2pF+mQ\/x+lSOcFyQYIj1yMPWowwtKgn+2wVKw9ZEq0Dl971RL3Ghp429L2WMbFoi3JFIS6f1dIYGI8bGE8Bdq\/RBu7beq44CFoy1WQQIWiRIGBITYHz16VCWa8duTACcCGS8KnHdKJZkk0WQwdGLftqDrbz95idhFk86\/SzTVyPexlCs8LyBRptk1Y+Td4v1V7nTUt1ihAK9O0KdsBRa+f1j+sOQhaQYOHCiWZQlSZciQIYKRYfjw4VL1tGoHyPxZBHXvfXlexMfHC1HJ\/owXDFwTSTIZJOVqO+Hf5WKCqF+5xyQp9OQAYetBWdoPtn7bAR8KVKvtK7I+5XZhOZ5A1LBiYSlWKE42\/CZqeR7PJXrgP1IjWHJCfdoQTrINWFjxCF5kLEWHmGvCXYmJYZLL4IyL6Xfy5MlqgYQuXbqolUMo64v8eV4wMbx6tXONF7yMvvqT2WPRqk9mpEGPlJApT9+sQEgaMp1MkzWwFv94MLNNPqtctPpw1o0jeMA2YGGYwHWJpB7MNaHqIbWw3lWpUkX5\/OHVzvkHHnhAMD4g4fzxgslgjBvenhdYGEuXLq3qIwn5fejQIX+XMcczyQEd9q4BVnvwKqk9aFUma8d+MduAxViKsRPGCs1mwJaWlqZAwFwWKpwmQvUDqYL+PC+2bNmiXKP8GS\/0ve3aMk4J5d521wdgycXSlBRbvPVgUOCyuw+h8N9fXduAheWPCeCnn35acDvCb\/DgwYPy\/PPPCwBj3EUGJ9Q4HHaRRgBRd4RASSQb6iLlUCeC8bzgejzYYAnXq2DrUs\/t9T37wAJzx44flxs8F5bLYNE3z\/r8DoZC5SHvQLjJNmDRETInffnllzJgwABlKud306ZNpXPnzmplRiaQ8VQHgJjcPVU4pBeeFozBGI8xZuOaqJU5c+YUvNoZs2XG8wJQBkuMDYOtSz3Gk2yDJbvr027PNrBiSOIVeZSBY9xmSyX0oUwg8qwfqJy\/c6HW570JN9kKLKx4GCVIqsmkMBO6WAHpJOMvDRb2PWnu3Lkq8xLBkvo4nuy4O2EQ4TwAY9wGAJF6jN2c6Hmh2x9LWwwcnaolCKmfS3dfenqbGkvdy1RfbAMW61jhdoQqyFwVRgqAQvoy3JrIDUi2Jhxq582bJ4yx8IanV+TEILSfcRX7EC5SgIgENfgf5smTR3DCRcphsMD44UTjBaoP7Q+W7K5Pu321oVO1eDXuwnI49ru9QupnCKCxHE+fWf8Dm6\/6XDezFGr9zN4nK+VsAxZBjrz8RA0vX75cgYBUxfgOFihQQAjFR8UDFIAQiyDhIHSO5J447JJCjX0IsAEqXZbASTwxMvK8oC7jtGCJD0Kwdann9voZ9eG9p+6UQ8Mfk7hJzSTXD1PklyXjZPyMhdL3i+\/SwcacGKDzpLytxosvytdoqHjTrV1mnXXMu0yg\/SO3deQ1CCvZBiwMEiyx8+yzzwrJY\/DtY5\/ejRs3Tq0aglSCGGMRrIixAqMFZbwJR15C8MmhAZgwaABM1MlAnhfUMxSdFNOkfoZI\/\/zr0PpKovmblOY86aG9qf59VSQS5P0+hbrvH1ihXjmD+rzshNmjohEWEh8fL8RdEfaBaRyVUBOrj\/DycxwPDF+X5jzS7+qrr1beG8RvMYeF9ANoug6\/S5QooXfN1sEcQJ30JiapI0HhZoNtwKIjzGWVKlVKLRaHfyDWHUC2f\/9+TmeJkHjUw8eQipldFIGy4SRUUD4WqHizZ88O56XNtVzEAduAhYqGxKpVq5YQN\/Xggw8KeS+QMHFxcVlmoVMWRZg5c6YQHU0qNyRsII\/8LHfSVHANB2wDFis2MhGMJZBJYZxuR48erfJdWFbGixZg+CAY8sYbb1TMtixnLIqA1GS+hTEkcWT0UzXQ\/MtWHLANWJ5cJoQeFQ6TOWnPAJznebf8RgpjuSTpKG3GXQsrJb8NhZEDLriUbcDCVI7ahysTX3gWocMDgzEKYy+n8Y4xGx4hul14dTAZTTo1PECYlMblirB\/AEY53LaYBuC3oezFAduAZVmWEIv10ksvCaZ08lWg3hE2wgvplMeABO3Zs6cwkY0E0u1iLIWPGh75zLnxYWCikklqHH+RupTXk9q6ntlmDw7YBizYi9vSpk2bhJeUXBcYIHDIJRkM551ASCFM93Xr1j2jOeQtrFGjhhD+jwrLEkT0hVUjGS9iiMFrhI\/FGRXNTrbggG3AAjxIgf79+6tMTGRjgvDCQM1yCvcJlMTLo2zZsulN4iOAUQJ1loOWZakUbrhmATIkGGnRqMd5Q9mPA7YBCzM0X3NUKFQtTWTGdYP6hCRjPOXWV8a0O7IcsA1YjKMwUmCejmwXw391zOh8FDC0cHWCMxlfkaODfUOGA1EHFt7mWNPwXAdUhN23bNlSpZLGq51zlHHyo7EsS2XwZZyF2rp7925huoDYLye327QtehyIOrD42hPM2K5dO7UkD2ZqQMY+xDnKRI8Fwd2pevXqwvgLUztLvDZr1kwlCQ3uaqZWrHEg6sBibELICHNCeK5jvLAsS3CuhbxD8J3CcNyu8JbX7cEayHiQ5KA4CxMDps+ZreFA1IGFNRAJRZZbwjwwVGC40JOqLnokpqmGA345EHVgYQ1E1SOal1CRJ598Ujjm9HGVXw6aE4YDPjgQdWDRBvJRsNWEh4KRWJobZhsLHLAFWLHAONMHw4FAHLAFWOS1uOmmm5S3Am4\/pDhjS\/6EQOH3gTpizhkOOIkDUQcWlj\/mfwil37bt7FwLnKOMk5hk2mI4kFUORB1YWW2gKW844EYOGGC58amZNjueAwZYjn9EpoFu5IABlg1PjZyHLITHMkWaevToYUNLwntLvFBGjBghhNXg5oW7mucd6PfQoUM9D6X\/xomZNOP4XqYftPVHaDc3wAqNf0HXxtsEVyhNr7zySvq18JYnd0b6ARf8AEyTJk2SYGPQSM9AGA4WYhd0N8MmGmBlyKLoFeBr3rp1a7WeF9mBSVSK9z+OvixrxFed1rCYBLntkXbt27eXlJQUIUMwUoItZZAWSAhAOmrUKLWQH9fp1q2bkiic55qNGjVSqRGaN2+uPGCQGOR2JF0CwZ1EQwOY5557TvQkPpIF4j6ayAlCKBCBnvqYvy3SmbZDpAunDSxgQV5J0sbhS+qvrluOG2DZ9KRatGih5vGYuyNp6bp161RLyJUxduxYIbZr4MCBMmjQICE\/IS82DsusXDls2DAhDTdTE7zISAtV2cc\/6rISCxHNZBnGnYyljyhK2A6SkzJIixUrVqg0CSw7u2DBAgF8qHckxNm3b5\/s3btXgY\/VW0hIyjU0Uf7666\/Xu2rr2Uf6CWg4gXRGUtNP3NqIJKdd9IX+E4JDOTeTAZZNT+\/9998XPZe3Zs0a0fkRq1atKnz5U1NThZePrzovJdl1165dK0gxUmnzElqWpZKdEnTprxsAgxcYoLLeM0BdterfJU2RFqzvhac+90f9JDkOoCEIlbAYxkxIR\/KRrF69Wi0SyP28Y8\/w9+S4Zzs8+0hfScqqz+OMzfpnrJHGeJPjgJvUcbGQMs4AiyfqQEIdIrUaYOKlJPPTlClThJcX9U43mYUkUN\/0vvcWFatjx47pIEZ6pZxWHb3L6X2uRV59vc8qm4CAhSmQkKihRCYAPF3G79bPCdr\/ySefCCFCTZo0Ubn2\/RR17WEDLIc+OgbzePwDKF7EadOmSb9+\/VQwJaoaUcscR6oBQpKeInnIgc9xxjx0DWmAFEKiABAW+kMl5JwvAswACICR3q1NmzZC4hXrub8AAAHlSURBVByWU2L8xtgPKepdlxyRgVRSz\/Jk5aI\/qIC0WZ9DYtJ2sgjrY27dGmA59Mmh6nXo0EEwQFSuXFmtF9aqVStBJcNIgVqFXyUAQ4qhtrFP2jUsc4zFABsBmoCFLWomeQ\/57a\/bNWvWVBIEQ0JycrIQ3oO6yMuu\/TvZ967PPRgnAgzvc577ABZptXPnTsF4AkjZMt5jHEdfkGSeddz42wDLhqdGJLKvlxvgQLpJjG0wOiBxxowZI+QutCxLyHFImjikFaoUL7NlWUJaA8ZUc+bMkQ8++EB69+6t8h4idTgOoRYiJbg\/7dD34r4c48UmOzFmb+7LvSzLUhZBXvzatWsr4Ol6eosFEcmGlOMatJfr6fNsuR9t4RzjPNoPkS4OMNFXcjWGomZyHyeQAZYTnoLD24AKCMCQgCQv9dVcwNSwYUNhDAbQfZUJdIypBOLykLqByrnlXA63NDS7tjOjfmPNw7qWUblQzhNtMHXqVCUBA0kTrIzMSVlWxqvFeLeHMSVqL9LU+5wb9w2w3PjUTJsdzwEDLMc\/ItNAN3LAAMuNT8202fEcMMBy\/CMyDXQjB7IDsNz4XEybXc4BAyyXP0DTfGdywADLmc\/FtMrlHDDAcvkDNM13JgcMsJz5XEyrXM6B\/wcAAP\/\/d+hNZAAAAAZJREFUAwByF1yp1zm\/mAAAAABJRU5ErkJggg==","height":129,"width":214}}
%---
%[output:44c16bec]
%   data: {"dataType":"text","outputData":{"text":"Induction Machine: ABB M3BP 355MLB 6 261kW\nIM Normalization Voltage Factor: 375.6 V | IM Normalization Current Factor: 581.2 A\nRotor Resistance: 0.00274 Ohm\nMagnetization Inductance: 0.00376 H\n---------------------------\n","truncated":false}}
%---
%[output:6528d9dd]
%   data: {"dataType":"text","outputData":{"text":"Permanent Magnet Synchronous Machine: WindGen\nPSM Normalization Voltage Factor: 365.8 V | PSM Normalization Current Factor: 486.0 A\nPer-System Direct Axis Inductance: 0.00624 H\nPer-System Quadrature Axis Inductance: 0.00756 H\n---------------------------\n","truncated":false}}
%---
%[output:99d192f6]
%   data: {"dataType":"text","outputData":{"text":"PSM EKF Fully controllable\nPSM EKF is stable.\n","truncated":false}}
%---
%[output:7d7bb37c]
%   data: {"dataType":"text","outputData":{"text":"IM EKF Fully controllable\nIM EKF is stable.\n","truncated":false}}
%---
%[output:18ddae64]
%   data: {"dataType":"image","outputData":{"dataUri":"data:image\/png;base64,iVBORw0KGgoAAAANSUhEUgAAANYAAACBCAYAAAC8aERhAAAQAElEQVR4AezdCbSuU\/0H8P2ef\/M8TxpuGbLQsBCSdCkypAglWrqlDCUlQ1jLtJCUVigrijJEiUoDKixDIsmQskqpTFGhgUij\/\/k81++073Oe57z7Hc6557jvXfd7nr1\/+7en37O\/e+9nP\/vZ79gD2b\/ddtvtgRe+8IUPrL322g\/84Q9\/eOAzn\/nMIv5QPffccyv5S1\/60geuvfbaEC9yJRcuPfrS5ieXtjze9ra3PXDZZZc9QB56iySSeaRBB7iBG7gz1QfkRS4Peckz8lCn0L3nnnseUAa6rvzC+SMu3Tx+nlfkE3HpQqQhT3HFkSZw0wlEGpFfxA1\/6IknfqQZ8vo19Og2QfrisIs86CgDWUCZ5SOMfp4md+i5iktPWtLM49Z16ddRjy88ZMogPTIIedhbfvKVvzA6AeUmB+WQjvT4hYWeey49clf+CMuvTfFDpgzKQj9kYyn7t8wyy2S+lG644YbKf8stt6Q11lgjvehFL6qw\/fbbV\/LxQqTxBCt3tz\/Spv+DH\/wgjWeepPmc5zwnPfaxj22Meswxx1R51fOsKz\/+8Y9Pz3zmMxcRy2sRQebJwx73uMclZciCp9VZUtZBbf66170u\/eY3v6nw5je\/eVJ9PvaxjyW2dd\/+8pe\/VOG5TQjY80lPehLnRBvgKSk\/vVL88Y9\/TFdccUWl\/opXvCI94xnPqNwbbLBBdY32Unm6\/Ik4oVavU8hd87C2NnDeeect0v7e9KY3JeURP6Atk+Vlj7BFiBXC6bhGZTQckEfdGGSw++67Jw2Ae88996wayTe+8Y3kxpJBpME927G4ynr44YdXtkO03H4XX3xx+vvf\/15stukqf3SwCvK1r31toiFHx02urH\/72984Zww6niiDzon9fvjDH6bnPe95E2VQJmXTJt\/xjndMyMOxCLHaDGi0YgQZ1KGHjMSmuo4Pw1XB9FBRID1jPc5Pf\/rTND50V+LPfvazaccdd6zceli9Q+UZ\/xNEJRM2Lpr431aPCYUhO373u9+l++67rzXVfsraj811SEb417zmNclokBdofKqTVlxxxQmR0aFpVKLAnvlo1k\/5pTMVNMzPf\/7zU6lUYdddd1367W9\/W7mn+lO\/5+HX8JvaWVtad955Z\/rSl75UBevUdU48uU34EQ3YlG3JcozFDTD06TXywBhRJAARNtUNDJ369TGPeUxaaqmlqimgtNzUbhUO4zTdhCCqfA466KCJhtRUDzrTgWhwprU6HnmwZ9wYfuilrIPYPC9P\/V6yOSiP6e+8efPS+DMFb6LLbjxsfeihh1bTHo3yVa96Veql\/NIoAbIgDd0YFfJOe8899xRUlcOUq\/JM8Wf8uSnplKm48nOXtDN6TYj2J+zEE0+sysIN3\/nOd1zS+PNVMp2sPNmfMT2jXi6GviwsGY1Umkw4PXAjyNwYPR93N8jcDQ29pnmpMOzXC3CbDsrPjY1GQQ7ylT+3hj1VPegMC+yw9dZbJw0wGrK0yZVVOZSHLKCs++67b+UVRoeuOJUw+zOIzd\/+9rdXz8KSC9vJByIv0xk9MZ1cXzi93NY77bRTeslLXlI9+wzb1shitqEc0ZlwBxAasfl1VDos7jZIy3OQOrjy02V39ucuwdOe9rSkbdLVzqUH3GTg3pt5KZ9yktUxMRVkbKgrGApNyXK5BM3ZY5qWh03lzg2YN8o8DgIeccQR1bQx5MiNWBoFmSmEysm\/Xja6TfUQr19oXOutt96k6EjQlH9dJmKTrnKC8Bz92pztTj311NSUv\/TlddFFF1VE4Q99NuPPIQ32DRk3WfhdxZMmdy9w7zwOiOOeIjN3jryD1RnFjCDXyd3KoTwhizbK7iErvR5wwAETHZQ4OkLtz5X\/lFNOqWZe2oS2QVbHWAy\/DAf8ufFFUDjywE9+8pOqJxPWBhnSE0d8eq78IC+yJj09jDLQAw0tl2k8GoX4eZqhmw\/hdJryIAdpixdpKhe\/\/OVJB0JPWOiSN+UfMvWXNz0IuTRAXsBdz6+uW09Lem2ox5U+yKspTl43eiCNui6ZsIB4vdg60nPv2FA69Xo36dCTt\/y4xZVG6MY1wunU7eU+kAmTVsRxjXiRrrS56QK3tuDKf\/XVV1eLQuKJnyPymRix8sC54DaPftnLXlatJMXUTLnJY\/HDkM4g5CP0bwE2Hdm6N\/v1Tax\/\/etf6XOf+1w1HzUHfe1rX5suuOCCNP6SrLcS9KmtZzAUi26YNp1Qjphfmwo0LYPSX3IwnJqObN27Hfsm1le+8pX0yU9+Mm2zzTbpnHPOSauvvnp63\/vely655JI0U\/8MxYbmJhj2NYiZKstDPZ\/ZaGuzEVNJ979tmru47stYPxn\/6U9\/Sh7g3vKWt6QPfOAD6cUvfnGy+rLaaqulM844I\/373\/\/uJ9lpj+PdTBNuvPHGdGMDrrnmmnRNDXU96U17wUcZzDkL9EWsX\/\/618lLUQ+BnU6nqvSjH\/3otOqqq6arrrpq4p1SFVD7YzWxBN4blODII49MTTjwwANTHU16ZG35NJWzrit+5MMt\/MILL0wXjuPMM89MJ5xwQvLOA5D097\/\/fc0iI+9D0QJ9EQupHvawh6WnPOUpi9hk+eWXT3fffXe66667FpHnHo2rBPWRoc1vxGhCnudMuZVDOU1PwHT0pptuStynnXZa1QF4H7TOOuukV7\/61RUssKy88srVS9gVVlihWozxrDjCwn2pM2WHYbeRvoil17Uk6WXasAvUlJ63591gJ0ETXv7yl6eXN8C2nxyeEefNm5ce9ahHpV\/84hf\/Q4sbgQLsgVTQVH5pShvmz59fvSPxHo\/92PGJT3xieupTn1ptJn7BC15QPa\/usMMOab\/99qt2RXiGqOP888+vlnzr8pF\/4QbkXuzQdM8GlfVFrEEyNVXaf\/\/9Uy\/wHNcNVgCbYJWwDiS6\/\/770+WXX55M90zlDjvssIlpG6K0Qd2f9axnJaMzvPWtb03Sj7y5lZUfcZFanBxBNGFeOroiXejI29SRrXbddddkhDPSccfU8vrrrw\/10XUWWqAvYlnKtjv6r3\/966QqmSL+3\/\/93yT5TAnsQYu8NFDTTo0UcTTMaKT85MJDP78+a5w8GvwGG2yQPvzhD1croF4n2F6zyy67VDJy4UA38KQnPSl57WB0QjSdCLIhmvdBeT5IRn\/e+GhJXxrcuQ531OXEE09Myg5RF2SDtrqI3w9yW\/YavzRuiV6bTqm8Sa9J1msdp9Lvi1imK\/\/4xz9SfepjCmVjrUY5VabTEabhIYqeXKNDoujl+YU1NTxlBeRAFK8QgkDcZMI0+Ci37TbhbrvWdZAHcTbddNNqtA6ikedp8CMWXXlyG\/24c71wqzeygToH2bgHJVu9DpFnybU0bolem06pvEmvSVZSr1Kdvohlef3Zz352st9Lzywz+78uvfTSZMn9yU9+MtG0QENCEERBGA0oGhM\/CKNTLwACaaCIgjCIYwQCfnLh9XjT4Ucg5EEwMJohUZ4XHTIzAyNflFdZ+dvKGjaqk01Hg2zQZJ8875F7MAv0RaynP\/3pafPNN0\/HH398Ou6446rt+nvvvXf1tekWW2yROp2FS\/BRtH6uGgcgCbIgkIYB3GTC2hoIEiGK3j4aJAJxa5jC2hpmP+UdJA4CIZmyBsnIIk0zg4suuqh6HrS6aPro2Uxd8tFV\/LZ6sSUgG7BhdEjcyAZt9oyyjK5lFuiLWJJesGBBckPseN50002Td1tHHXVUWmmllQT3BDccSQBhpItAwE\/uhtOrJ4xACKJBIQxEY+NeMF5O4fTqcev+0nl3iV6bTjc5Qs2fPz+98Y1vrF6+G8nIoqxBsu9+97vV8v2F4+\/LEE0d1VWdc8IhGwiPNPIrm7ItsgHbB+F8NoJsYf88Xjd3Wz3r8Ur02nRK5U16TbJ62Qbx902shz\/84ek973lPdWYBUp199tnVMnKa4p+baHnZjUKY\/CbygzA3up4MYkAQSOMxAgG3BiXMNLUed676EQrJjGJg4YMs6hMk82IakIwswtkL2YCNosPhRjaYinCemZHNfanfK4Rzn9zTyG90\/Z8FWollY+tGG22Ull566bTsssumrbbaKuUs72cTrhvtfY0b1UYgRaOHJIAwGgICAT+5BkGPfo5BHkpL45botemUyut6CGVmgGCAZHm9Ecp0EcGgTrLQZTO2QzZg2yAc2wbZ6EWc\/IpI7h3CIZtZRYxw7msQzk6cPF6bu17PJr02nVJ5k16TrCnvfmWNxPK9iQ21z33uc9O3vvWtdOyxxyY3juyOO+6o8up3E26+j9DNc5MRxU2t32QyYXSqTEd\/KgsgGWLly\/hVwIN\/3Ks6yR4Mar24F2wdZNOJNRGuLYESwiGkUa4tjcUhn648JxHLKp8Pup7\/\/OdX70tss1l33XXTIYcckm699dbkk+pBNuFa4coJxD1MAuWjaurxX2ncEr02nVJ5k16TDMlMF5HMaOOZLK92kOzAAw+ceCbLw6dyy69OuCAb4skPpur4csIZ0Yxy+Qjna\/FuhFOOpnKWypv0mmRNefQrm0Sse++9t9pgy1j5srlPqPkZyjOV\/YL9bMK1LC\/tfgvcLd4gQ3xp3BK9Np1SeZNekyy3h6V5JDNVRLC6nXslWVt+yAZGN9A55oTTUZYSzs6XOuGQz5QSjHBt5SiVN+k1yXJbDuqeRCwHaH76059Ou+222yJpO3fgz3\/+c7JogVR2WPSzCXeRREeeabFAjGLedQXJkC7PrFeS5XHb3MgG+ZSyH8Ihk2c4QLIY4biRDei0lWM2yCcRq9PpVLvWrd5FAU0BDz744OSB1K5so5Zwm0hDp5erYXiE31aLQf3awT0piasztFPGMV0OW\/FsZndMfr9ykjms8swzzxyobPVy2f4GVmyNpLaEORAInCa13XbbVfst7b1sa1PaHDIhGyAZwm255ZbJawFTSjCtrOffzZ\/bYljuScTKE46Vvw033DDddttt1X655ZZbLlfpy20Yni4oUL9pl8Yt0WvTKZU36eUyC0u91tMX1Ztuuml1CGrbSOZgSp+7nHTSScm7Mp+9dMknNYXnZW0KDxkiOYbtgx\/8YHIW4Omnn14d8eAZLqaUjhirT2ulDw7Y9FrAlBJMK9\/1rnelffbZp4JFNnJb3TzfR77i5m7+YWIs\/97FQZyROJb7QvijH\/1o9d2Qc9XWXHPNKng2b8KtCjj609UCMV30LDQVyawuWvgwSljC75rwkBTyKaURLX+O41ZuU902whnhwAiGWAgXo5xXBEZKU0rwgn1IxZ5IZsz7qoDvf4R4hnKAow8WTz755HT00UdXp9gKA1OL2bYJV7lAL+TaD0rjlui16ZTKm\/SaZP3Usx6nhGS+PeuFZKVlLdHLdRAOmRYsWJCMckgWz3HcCAd06vUMP8IZ5XQWYGpMFuHDuI45kCPwhCc8ofrcwelLEjccG6U6nUX3\/pkrL65NuMo1FYy0U4VPFVYat0SvTadU3qTXJJuqMQ3HBAAAEABJREFUPv2E5STzTOaZqL7wUUKy0rKW6LXp5PKccMqMZEE4o1NMKxEOctt4typ+LhvUPekZy5z1+9\/\/fnW8tBVAR\/vmsFw+E5twB63YKP7gFrBANX\/+\/GQEaJsu5iSLHR+D5zy8FBDGc1y+Uol0Fk4MHNyevYaX48KUJhHLzgqrRHZb2EFdxxe\/+MUqpqHYnHUYm3CrBIf0J5829JpkadwSvTadZnmqFgDy8jbpNcnyOMN25\/nlI1kbybSbmC5+85vfTCXPZHkebeVv0ymVN+mRIZ3Ry2DRlne\/8knEstPiyiuvbD1PYccHf1bHaNbrJtx+CzmKN7ss0CvJZuNINt0WnUSs6c5wutPP59295lUat0SvTadU3qTXJOu1jr3ol+Q3KMlK8mjTKZU36TXJerFNN90iYlnM8DLOs1YkGO+4HN9lyX6mj5iOcoyus8cCOcnaFj7y6aKRzDuz2VOD4ZWkK7F+9rOfVT8L89\/\/\/neRXL148+C3OI+YXqRAD3rMnR909nwpjVui16ZTKm\/Sa5L1XMkeIgySn5fR8xsWPpAPFAPJEMt7MiTzTEYmLEdbOUrlTXpNsjzPQd1TEss2FF8FW4bPMxpkd3uezlDdo8RmrQUQKUhmhdG2qvoSPkJZ+EAwaCPZrK1krWBTEstuC1uZLFLk8QbZ3Z6nMx3uQebOpXFL9Np0SuVNek2y6bBhpDlIfm1xc5JZXUQyK3ORp2udZPYukgnL0ZZHXV73S6NJRj4stBLrl7\/8ZfWBoxdr3gPkGdqZMcjudpWaLpRuTm3KvzRuiV6bTqm8SS+X5e6mugxDNkgeJXFtEPZFuZ9g8kyGZL5Yz9saQpkuGsU+8YlPJCTze13q15ZHXV731+Pm+Q3L3UgsCxOf+tSnqh8ufuUrXzkpL9s\/vDysE26SYovA\/Ha6YPd9v2mXxi3Ra9MplTfp5bJ+NuH2apc8v+mKG3l4JrNB2IZcI5ndE5A3Ie+bkMxMynuy\/\/znP8k3gvWyRZohr\/vJc1mex7DcjcTyOb7p3nvf+95kZBpWZqN0RhYosUBMFz2Xdfsy2kgGs+2ZbJHd7Xa3GyZtun3\/+9+fnvOc5zTaYTbvblf+xkIXCEvjlui16ZTKm\/SaZAXV6ltlkPxK45boOS5i\/vgKYynJTBdttYqKN+XRJAv9YVwn7W43UsnUwTHeT4Gd7r4gtr0J+Wbz7vZhGGWUxuy1gNXEIJnnsvp0MZ7J7FqPkcw3ZjNdo0m728094zOSuPqZTKPXt7\/97eqnZWbz7nbz536NWBq3RK9Np1TepNck67euJfEGya80bolem47nsiBZPJfl9UIyS\/g+2AySxUjWlmYefxD3pGesRz7ykSk+I4mr91h+QcRiBfdod\/sgJh\/FnQ4LxHOZ6eJUJMtHsiDZdJRnErFKM5mtu9tNY0vrUNcrjVui16ZTKm\/Sa5LV6zBM\/yD5lcYt0aPTVK82uWX8fCSzjJ\/Hj5EsSOY9GlmuM6i7iFiOOTOkGsEiw0F2t3tumy7Ys9hv2qVxS\/TadErlTXq5LHf3W99u8QbJozRuiV6bTol85ZVXTh\/60IcSEn31q19NluujDbsiFOK58g8LRcQaVmbS6eUnLEe6vf\/s58hm7Ta79tprq5+erU8XTSMtimifw8KME2tYBR+lM7LAIBZApny6OEhaTXFHxGqyykg2ssCAFhgRa0ADzqHoo6LOoAVGxJpBY4+yWnIsMCLWknOvRzWdQQuMbb311smu4WHmaVu\/JUzLueedd95ASTsOwLYVaTWhXn5brujV5QMVYoYiOzdd2XPMVD0ib7Zm89Iqh72VuSmutMiFy6M03dAbZluKNOOq3bOvsjkOLdosfxN6acvVXsGNN944MUBkOJeutl3N5fKzddxgB0vy51A\/3yv1clPz+NPp1mauuOKKiSzsJ7WkPSGY5Q4vmK+77rrkJ6rq34E1Fd2e2dLOoZoKMohvXJoSm00ymy7z9zR77rlnVbyZK3+V3dD\/IA9I2DmNUUdnjvuSgPyggw6a1s7PsXbyrW8EkHcbtBm2z8OdlZ77Z7PbS+N77rknOcs9\/0mq\/B6wic7CBnR1ccinDoV7KozFjasrYWZ9OGzqNaO3DV3Dfttu4nxYp2\/oJcvzdqZhnCGfy5vcfoUiyn\/DDTdMUnEQjjzkBYZ95c0V86kMHWiqZ5M9yPK0uMWVRoA9ut2IaIxuHkgHbDL1EzXcdgbkdpWmtCMf16ifOu61115p9dVXT6usskrVcIQHlDvqHXHIhEtT2vKcCvK4+OKLK5UVV1wxAY8RrFt84fKRn3yjLPzAhtJqQjdd7Sm\/59KLOubpKYOyaj\/aUR6Wux1N8e53vztdffXVlfjuu+9OjqSuPON\/lFUeAfWS9hjGjoenZZZZxqWCwjdNSwyFwiql8T8SMA2L3nZclPRg9CJdMmBAvw6Ry7nJFM7R1h\/5yEeSz1Xuu+8+UQaCMjGoPCIhMmXTKEC4XjfC40pHecOvzk32IBOW64kbflf2WG+99ZIbzj8VTEtMT3KdGElsxUE0YdKSprT5A+qnkTjFmOySSy5J2267bbr88st5J6DcTfWeUChwKKfyUtUGgFuZ9PDcJWgqCxvm9o90yOvlJtN+6LhqT\/k9J2cX5dNe+UEZlVWHMNVOd0f\/sWls5\/NtGLJJw72XP3dAmu5NNRU0pbIfUKDCReHJDYVgGiZcGB1uRpEQdwyfTuF5zGMeQzQBDcFvHxE84hGPcKmOVPaDCzymOTZOrrrqqmmzzTYjKoLfQw4j5h1DRG4qPyND3jCa9PTGyKfs5557bpVk1DG3h17PDWMTtqEY6bl5RiBlPPTQQ1sXiZwrLh49DSN6P8R384QFlEkHRLfTWfhjFRrGvvvum\/S+5MphV4Ff1PBQLq7nCOVRduUjGwRhe3lqeMAtzRiBubtBHFNe5XJflFOcpimXMDp0xRGXrjqyS+TbpKed+nUS+nTF4dZe5aUDijPckSXugemiY\/7E90Mgfh\/Or5N0u98VsSSsceQZahDOH5A5uBkKzK0C9DUqfqRDTI1Vg\/SwTR4whXHDsR1xzjnnnGqa8uMf\/7j6lUiF9gNn66+\/fjV1iXj1qwYTFXZFbDrKpQzcgbosGm+E6\/2NAm6SUSHkcXVgTn3kZHAGpeMbNXHjmSSmonm+zgXxI2j09e7sw10H27FvXa4RRZ0jX7IYgfTCYcuPf\/zjKeroPi611FLVD7Gze6fTSTvssENSHnm4r2ussQZnX5C++yxy9PjIzU2mXWgf3N2gd3cv6BkVPO9waxM6Au6AMDr8eX78UL8nZBBnYrIFv\/vgfrhX3IjDdmEfOk24\/fbbK7Ez37vd74pYKqGRakgalNg+bMwzMgq5WcIMhXS5wW9luVEaiIL6SdXoTYSHgTqdTjrttNPShhtumL785S+nf\/7zn8nZhXSioNy9QL5nnXVW9Q1ZHk9ZlTlkepm8TOQaiFEBSQMasrCAePaVhR+5QjcfTaL8bKlMoUNfXDdVB8PdBORG1EMOOaTxnBHpIFfY0lkk5v4+OjVarbbaaim+L5KXcgQBHbhiJ3jk6766v+Hv9eoea5jirb322hVhpclNJu8oJ\/9U0KDz8KaZR4TnYfJrqgMbhe1dzQDuvffeSKK6xmhrAHAojR9YRFrfHFLw+wWbbLJJclKZe6Iu7qmwq666Kp100kmp2\/0eiwh6Gb80InIJ9EgeqOlqfG6uXjOvvDBwwKfroDAqqWiOU089tbqxvaat\/Hp8IwDCmVpItz5y6CERN+yU54OE8bCaywdxmw7rQfW+bJnna6YQtvTZTqezcCqoIxPPsQqRt\/gaOP9jH\/vY1Oks1OUfFNEwpaND1oCBmwyU1XUm4blMByRPbcWXwwcffHDKV\/x0pkZb93yttdZKBhIDQqfzP\/ssu+yyCYFuvvnm6udW2TFmHkY\/P3Mlj6lQjVih4Abo6fmNSgrBDUYoheDWU9hmHz05gmmkpnK+MjYK6TXpQsxdEVBD1oDBM4sKatR6bLozBaRgMNMBz1AxHYmeKC+H3hGBlRnctAiXhh4t\/IjAT68ONzD04srGMWq6msfnttQolDH042c92TgfAZdffvmJZzjPsc7U33zzzato7k+uK0\/3twrs8Y8OyaNDt2g6arrd9Or2Dr92ob10ix\/hFr+iXDpHHQuCuK9mRqGn\/YFpq0cTIz8bR7iro+Ws\/mm37Gx0pisM8vvRdr+rF8SU3QhkCWbKPH4LS7jeSCPiNnzrycXh10gNwdwqoWFxBxzKyO3m0uUGzwcIaBi2SEA208gbnTIgWV4G9dIbA7cwN01n4ObzA5u4shtwg+miuG0jG9LqqOiKB9wBz55hdyOYPBFHuEWfaLz0TMnJke\/888+vPu7jZ2MP7gjF777W8yEvgXsb5dGA651HdDp06HZL06IWu9Nz5efWafdCLHECQU5+iw9Rb\/4YSU1b3Xv2NxgIqwPp9thjj+R3Cnbeeecq2NEVW265Zep2v6sRy82yOiKmXjWMg0waBQQhhNGhy7DBXkOwOash1OgmPOBhz1kZ\/HmaX\/\/614mqhQw9C4+0NVzu6USsYml05uHq6Mqf56tOeR3pQeiuMb4IAMrNNuKyBR0Iu+k8dEbC66jbUTz5avx6S\/rysOjgxnpm0iA0XnL6ns06nU7yXOl3oy0MiR9l8lwkTbrugTT7QTRMbYYN62lEgyO38lZvC+Q52JstlcuVX7hHizZ7Ca8DOfKOXnoQ9qfvIFojaVvZE6VxOP5POZTHdJEtxR0PSmYT7NjtflfPWObM0bBF1rDdbO4cZMJCpuKnn356tSUkZArtpCfXXKaXdbpuLhdu+rnbbrtxzijU15HFeaampkCm0bop6tj2jKXRmiJq5OKwTcTnB\/U1uk011ZWH1UX2FacOaUY+0nMCrPcrQfjQ73Q6yXOGuoVMmerp8it76JRejY4aJn1TKStz3Dk0uiiXTsFImofX3fWyqB97abh13W7+Aw44IOloQo9b5xKE07m4r7ESKS9TPVO+iDPV1X1gz9DhJgu\/qzSVfyxuGGEODaE+zJPlOtzRKOga+hncKU6xlM1AcQ4h3ZDTdxaBm2BEk1YTxNHo6KtIk04uo0O3Xi+NLfJWJnFc6Qb4IfxRX8SRXsjjKi\/p5Mjj05OnvHOdNrf8xAG21DAQQJoRJ2w5NjaWwi702dIKoRWt0I1rni5dI1\/9GSt0pMnmETe\/kguXBnuwSx7OneuouylwxJEHnTrYUZogTm4vbjJhuR2kEfGiLMrDTRe4lef444+vCGelj1w88cOWpoR5PmzpmdVIRT9Qz18aZBHuqqzSqqaCFKYTbriHcqsx8RBo3nvppZcmy8SmNtOZ\/0Mp7V5s6ZnQdAg864Ud9OLA71lDg+Re0tCLLXu1zYwQywhmhUrPcdxxx1Xbe\/bee+\/qXcAWW2wx1KXgXg0w1\/R7saURD9TRtBbBwDMgmdmCEZF7SUQvtuzVPjNCLIWarZ+cqTkAABAASURBVOcQKttcQ6ktjUSmQ6YoTTBFM1UaZv1L0pKnvJWpbXpYks4wdEpt2WteQyVW3MiYw+aF8ULTD9h56Ha+m\/1ulvf9JFCuN3IvtECJLS0keCl89tlnV88QC2OO\/tYtsDhsOVRi1SvU5N91111TwBI0rLPOOinAD6Fz2GGHpRNOOGEClnuvueaadM04mtIfyUYWmA0WmHFidau0EQwQBxDJS74AogXpgoyW98GP5Dn5FCz7WiHzTDHCi9LIBlPboFu77DV8xol11113JT+\/6oV0wEtFcIY2WH6H0sp4Qw52HDzxiU9MYLeHN\/eWVMFHf174+YgSPMyb489V2FkxV8s+28pd2s560ZtxYllmR6IFCxakBQ8C0cDmU7DnCy644IIE3CCMXhDSFRGhGxFjFIyRz6hnxItp5wnj000jZC\/GmybdUbIPAQvMOLH6sRnSAALVSYlsgHhIaLsOd05A8cRvyjsnXE62qYjmDX5TWrmsTadU3qTXJMvzHLZ7kPxK45botemUypv0mmTDtN+cIFYvFbZ9BYlyAubEQzp+ox0dpKunj2xGtjrRyOk2beUhz9GmUypv0muS5XkO2z1IfqVxS\/TadErlTXpNsmHar29i2ZRo6VxD9mDsQzojRuysGGYhh5kW0iGTaahRDcmQDZBNWD0\/hEI000YwmpHV9Ub+kQXCAn0Ty1Z6jXKbbbZJPv+wOOAgGAeYpDn2D9kA2dRJB9FGNISqk2yOVXdU3BmwQF\/E8hXrKaecknzS7Gcp7bmyzd++vzPOOGOR46FmoA6LZLFw7ryIqNiTx82JhmQIZ0TLEwuSWQSpj2J5WnmcUnmTXpMsT3vY7kHyK41botemUypv0muSDdN+fRHL235fE9vZ2+ks\/KQ5Pg\/3PZbPC4ZZyMWdFpKZIhrRjGbbbbdd8nyWl2s0iuXWGLn7IhZSeW9U\/6TZVnufNHtXtbhMO8hDaWlcn114PjOSGcUQL+obo9g+++yT6qMYnbY86vK6f6q4wqYDTWUozac0bolem06pvEmvSVZatxK9voil8dh\/5avNkkxyHV+d+jT8zDPPTGc+CJ83gE8ZAj7TNlzPZvhIzvdG9j1a5vcCOurKRjGK+ZT7iCOOSMOsy6233jrU9IZZtrmWVtyzYV77ItYgBXBug6mkD8ICvmAGp+oE7IxwzBQ4ogp8zwU+AvRlKvj6s9PpJN90RS\/k2g\/UqyRek57VUedKxChGJ+CgE1+VGsVcTZvr+dDNZXW\/sFzmwBOy6USeX6\/5lMYt0WvTKZU36eUy7mGjnVhT5OTzY721Rl1XM0WM89nqYf36feEJN954Y3V2nh0SPjsADdXIcOSRR6YDDzwwISA32YUXXpguHAf9G8fjdstf4+mmI3wqPdPCBQsWTOwYyZ\/FjGLKa8ke8qliPc26v1u+woeNpjKU5lEat0SvTadU3qTXJCutW4leX8Sy986JQBp7nokjje3P07hyee7W4K0kBjyjgGkUmFoFLBjMmzcvzRuHU3vydNrcygSIhHigMcsX8eqko9eW1qBydsifxfL0kEyZEAyQTAeQ64zcc9cCfRHL8vogn9ojSQBpAIlg\/vz5af6DQDSkA0Tcf\/\/9E3ADOZ06EaXddkvqpNO4g3BGN6DTFr8fOYLlo5hy5+kEyez0QDLXEdFyC809d1\/Ems5PmktMiDgQhMyJ6AwHpMsJGORDXHGa8kAmoxsY1cBIh2h1fQ\/ndVnd36ZjCh0ka3s3ZuRCeATLieYTmno+0+lvq0NJnqVxS\/TadErlTXpNspJ6ler0RSyJaxxuvOOfNt1002RB4qijjkorrbSS4FkB5AOEQj4EM1oE6biNdk1kQzQNHNHyEY18WJVTrgULFj6PWVVUHrI8faOZciCab9G8jEY2+kY1EJ7Heci750AF+yZWfGo\/2z4PL30oRTiEmj9\/ftKgg2zIh2zC8\/uHUEhmJLNAYiQjy3Vyd1s52uRWFZHMKGZl0bOZctWJJg9k8zyLbKCDQzhAOn6EA6Mc4okjbi9oK2tJGqVxS\/TadErlTXpNspJ6leqM+eWPpp0S3idttNFGaemll06+xj3iiCMmfhlE4rN1E+4gQ7zf6NKQkc10EpCMTJ0DCBUkQzQki7C4tpWjRO6ZzHNsEM1uD2RD+jayRb4IhEgIB0Y5REO4IB43mTDkgyCguNKQXltZhXVDadwSvTadUnmTXpOsW516CR9rOgLYz5doVM4U9xLX+5cvfOELya+JxO71h9Im3DaDGbWQTIM2omnUiJbr5yRDMP48fFhuZFOOIJvjm5HNCKdcoAOgN1WeSAMIhEzIB0iGbIB4SOgcf24gpwOICOKDtEC6U+W9JIU1TgXdMC9c\/QqhUz232mqr5BhoPxjgjf9s3oQ7yBDfLW5MHZEMwTTkaCwIlY9iN910UwQtcm3Loy6v+yVSlyGRMiAbIJl7FyMcd0wpEc87NfriSa8EyAKIg0SAiIBkgHSAgAgJdVIKpwtIGbj++uurg4GkD\/Kql6te7wgvlTfpNcki3WFcJxHLS18VdDCL1b\/IxA8mC\/OD2RYq7BdcUjbhhg3ya4xkRnYky8NykhnF8rCZciMPIBPSAZIF+XLykYFwBATxkBCk00+5kQS0J0BKQMoAoiFdICcngvJDhNMPUrpKT9oB+fVT1mHHaSSWZy5bZvLMvLcyiumJkcoOi9m4CXeQuXNp3FwvpotGMSTTEMNuQbBYVXTz87ih51qX1\/1NOmSDAGFAmQGZEBCQbJdddkkIZ+RDROAOCKMHyBiQjg3Z0pQ+9FtORAG2A0QKUroiWpDOFQkRErhhp512SvQQMWC\/qvSk3W\/ZporXSCwHvthd0RZRYfrdhCtNjWa6YKrab9qlcdv0LH5Y6HFsc32qgWTei3k29dxa32RcT7PuV6dclruFTQea8vAeLuA0LIssYNQO+E7Pj+ghpg3K4JkQvCYIIOQ73\/nO5DMc8AwJNmoDcoLOq58N39opWEGtE9Jx50FEbZ2etjksTCLWsBKeKh2NbrrgfMF+0y6N203Pc+m2225b7RLR2DSMsMf999+fbD62ydiyvRmAmUA9zbpfnXKZGQXZdCLPr9d82uJ6rRAwsrGTz3DAJmbw86bgR+jA76j5uSgjJuQjZoyaMVq6StdoCaWjZale3Mdu10nEcjafHzfz64tNkb2\/mulNuE3lmCsyz2KmiIBkebmNYvmCh+exGws2C+dpLIluJADEAURasGBBWvAgjIQIB0iIjMAN5HSQEMzQhm3HScRy0KVh9\/bbb18kL35L84Z9Q2e\/m3AXSXQaPKZE\/SZbGvdBvSmzqesYteaPv4zWQ09FMs8Nnsn8KF6daPU0pyzAEAIHya80bolem06pPPSQEZBROw4iTseHuZOIZVri7ArfR3lmiPtz2WWXJaRTILCY4duoeK+F9aPfuwprTX0Nklnw0GPWRzKx2dNoFkTzIto9qZON7gizzwKTiNXpdJLfrPLg6oAYD9mOOTPX9RtXluCB2wPgbPu9K88C\/Zq5NG6JXptOXT5v3rxkJEOyGMnIUu2faaPXHEE2H4AiG1gUQTirXMOcStbLWivSlN7SuCV6bTql8ia9JtmUFeoxcBKxxLeR1u8FO2PbBlsbbXfeeedk6BQO3FZVhNFx02fbJlzlnEuIkcwolhPN1KWpHsgGCIVwCJaPcEjHj3RAD\/HEaUpvJBueBcbcED8EVk9yjTXWSH53CWFstPXbVhYuQo+bTBgduuJE+OK6xny6n\/xL45botemUyukF0SxBI5plfKQzdfTCft68ea3VRB5AJPcYgngI5zkOuAEBhSMgIKH9ouJLB1ozawhQ\/gbxJFGJXptOqbxJr0k2qXADCMaWXXbZZMtSPSNGnf5NuAOUfAmM6t0hMpk6IhaSIZwpJCAg0hnh6CFmNzMhDCAQMiEgIJnzRxAO8QARgRuEAV1kDEhHZytNkH63cjzUwseOPfbYpOJOsb3jjjuq+s3lTbiDzJ1L45botemUypv0mmRuGAIBQiEdgiEdsuXEI0M8oIt8IK50SqG9ANIAIiFjANEstCAdICFCBvhBmAUw+hDEdJWmtKHT6VRttF6+NnvU5XW\/dJpk5MPC2LrrrpsOOeSQZLGCMdL4P2v9Vgfn4ibc8eKP\/tcsgDiARIgHQT5kqxOQn5wOEgYGIWNeJKQEpAEkgiCmK6IhXgAR68QkE04XEBKkBdKWD+T5z4S7Wrx43vOeVx0fZluHjbYKNVc34dantL0YsTRuiV6bTqm8Sa9J1kv9uukiXwAJbVlCwgCiIRwgn9EwwA\/CwJYk+jkp68SUV7cyNYUjSgB5tFdASEAyQDrkA6R0BfJjjjkm0UFE5WrKZxBZRaxbbrkleWdlQQKxpnsTrl8nmS741ZN+0y6NW6LXplMqb9LLZbm73\/p2i9dLHn6eFsyAYPvtt08WW3w+AlaQQQMHDRw0cvCD7wHPdmAGZftX4IYbbkhgAADv+npp\/DkZ7SwKMnpenZzOYJIxU0D7shwiaX8XYimw3RVtSauUB2k7NNp02uSW8Ef4TRrZYFEbOIQ1YKMBfO9730v2VAZOPvnkBN6pgg9v6yNmjJr5aGnUNCoZhaE+Utb9bW23F3n1af5tt91WfR6w3HLL9RJ3pDuywKyxAHIEkAeRYgrrimimqIB8COkKwoZdkTGjlB5hzTXXrNIebcKtzDD6swRYICfisKs7dvTRR6elllpqIl37AU3xbLqdEI47+OfCJtzxoo7+jyyw2C0w1uks\/H2rKIll9tEm3LDG6DqQBZbgyGNWAAMWLTqdub0Jdwm+l6OqzyILjNnfF3AOgLKNNuGywggjC\/RvgbF82XfHHXecSAnZbKy158tGWxtuvecKBW4yYXToihPho+vIAkuyBaoXxEuyAUZ1H1lgOiww64h15ZVXpv3222866jon0+yn0J6V99prr7T66qunVVZZJTkVyZHg\/aS1pMfxjtfXH2zplZSPfktsOWuIdeeddybHZNllb1l\/Sb+hg9T\/rLPOqqJfcsklyV44h6zayVAJR396sgAivf71r08+o7K30G78X\/3qV13TGDqxDj\/88LT77rtPyhjLFdLRV\/ao2Yfm5Jw4M8PPq6666qpps802mxR3SRX0a0sbU\/3YhedgJ2o5m+\/nP\/\/5kmrGqt792tJ+RzszOp1OcoCS9sqmVaJT\/Bkqsey+Pueccxqzc1ClY6e22WabRMfQanTSq6bxf96frb\/++tXUZdy7xP8fxJaO9rI\/jhF9W6cDs8WHf0nEILZ0RuQjHvGItPXWWyc\/arjCCiskJz11s+NQiOVARSuCznJXiXqms\/lHFOplXdz+YdnSabXOI3E2iRNpdWSLu24znf+wbGnD+amnnpo8\/9so7NOUbnUZCrG893Kik93GyyyzzKQ8Lcc77x3xOp2FOz3spjf1u+qqq5IX1JMiDU8wp1Iahi09cOthfbngeWuTTTZJnc5Cu88pYwxY2EEK68eIAAAA9klEQVRtefPNNyc\/YRXTaLMqA4hPV7oVbSjEcm7GxhtvnEzl7DOsZ4pUs\/VHFOplXdz+YdjStHuttdZKvnvSGBZ3nRZX\/oPa0idURv7rrrsuebbyzaJvuKwTdKvTUIjVLZNBvt\/qlvaSFt7Nls6GNws47bTTkucszwVwyimnLGmm6lrfbrY0GOyxxx7VN2G+iH7DG96QzLp80Nkt8RkhVrdC5OEKbgUnl43c5RZ41KMelRzm+aMf\/ShZGg5YNCpPZaQZFvCrpp6vvK7wRbMfb+h0uk+rZ4RYlicNqYbWKHBc9QqW2sM\/uk5tgZEtp7ZPL6HTacv\/BwAA\/\/\/wvu0AAAAABklEQVQDAFRjra\/lXPo\/AAAAAElFTkSuQmCC","height":129,"width":214}}
%---
%[output:78cfe014]
%   data: {"dataType":"image","outputData":{"dataUri":"data:image\/png;base64,iVBORw0KGgoAAAANSUhEUgAAANYAAACBCAYAAAC8aERhAAAQAElEQVR4AezdC9xmU\/UH8PVMJSEkYiqZQSq33I00NaNClK5EIpcwiKhQITMuMa75u00pPpOYioymIkqaULmFhlyrYSRFDFGjlL\/vzn4783qe9zbv+1ze2fOZ9Z5z9uWcvdc5v2etvfbaa494tvwrHCgcGHQOjIjyr3CgcGDQOVCANegsLTcsHIgowCpfQeHAEHCgAGsImFpuOSgc6OibFGB19OsrjW9XDhRgteubKe3qaA4UYHX06yuNb1cOFGC165sp7epoDhRgdfTr663xJb9VHCjAahXny3OHNQcKsIb16y2daxUHCrBaxfny3GHNgQKsFr7eWbNmxcYbbxxjx46Nt73tbbH++uvH9ttvHw8++GCfWzVlypT4yU9+0qfyyr3xjW+c73lHHnlkPPnkk\/HUU0\/FF77whbjjjjv6dK9SqGcOFGD1zJ+IIc5fZ5114rLLLouf\/\/zncf3118cqq6ySrofqseutt166v+ddc8016THHHXdcvPSlL40vfelL8aY3vSmlDeTPs88+G\/\/+978HUnXY1SnAaqNX+s9\/\/jOeeOKJeNWrXhX\/+te\/4vjjj08SjVRzLg1Nnjw5Ntxww3jXu94Vv\/71r1MPfNTf\/OY3k+R761vfGlkSpcwGf172spfFLrvsErfffnvcc889sddeewUp+re\/\/S0+\/elPx5gxY2KjjTaKE088MbVH+v7775\/SPvaxj8Uee+yRypOa++yzT7z3ve+NX\/7yl3HVVVeldrzlLW+J97znPXHbbbfFX\/7yl\/jQhz4URxxxRGgfyfyNb3wjNttss3S\/n\/70pw1a2ZnJBVgtfm+\/+tWvYu21146VV1451lhjjXj44YfTR\/mjH\/0o5syZE6QKevTRR+Piiy8O6Q888ECScK4BUReUocZdeeWVcfXVV8fiiy8e3\/ve92T1SMsss0wsu+yyATS54HXXXRerrrpqAonn3XXXXfGnP\/0pvv71ryeJJp+Ue+SRR3KV0L5p06alvlxxxRUB5L\/4xS8ScN1Dwccffzw22GCD1L5Xv\/rV4b4\/\/vGP44QTTkhtfeaZZxQbFlSA1eLXSCr85je\/id\/\/\/vdJavg1\/+IXvxjXXnttbLXVVvGSl7wk0Tvf+c644YYbYubMmSmdtHn5y1+efv11wcfuw37DG96Q1Mkzzjgjbr75Zln9pvHjx6dx2He+852kHgLsn\/\/857j77ruDFKrVavGa17wm1lprra57jxs3LrRnySWXjIMPPjiVPeWUU+L888+Phx56KJUjiUnfWq0WI0aMSG1\/0YteFMA9b968QDFM\/hVgtdGL9JG9\/e1vTx\/YP\/7xjwSo3DwqIJDl6+5HxgcfNIAiYJg4cWL3Yi+4JmlIK1IrZ55zzjnxla98JYD0wAMPTJKUqmn8BBDKOae6Oq8Sw8vee+8dpNl2220Xe+65ZzV7vvOe+jNfwQ68aAqw+sMXFioqDn2cpQw5lyavP\/fqtLI+XirdoosumsZWrHgAhS699NIkLYytnEt77LHHguqnn8ZCVC8gAUpjGSqhvEak3FlnnRWrr756GtflclS0rbfeOhhWAAVISUjqm\/Zp53333Rckba6Tj3\/961+T5DK2Ioly+3L+wnJsG2B5WT6EnXfeOakOLFQXXXRRIINnoDJgnjFjxrB6N7fccku8+93vTuOqTTbZJKmAhxxySGy77bZJRaIaohVXXDG23HLL2GabbVI6lWy33XaLkSNHJn5QFYHOkVrmo3aeMit\/GDvy89wXYBgqKkXSs48++uikqhkDGQN+61vfSsYK72jMc0YNpvnll1++Wi2dG5u94hWvCJL3ox\/9aALtrbfemlTDVGAh+dM2wPJLSxW68MILg4WJGkInR6NHjw6A++53v9v1IQ2H92OMYmzkY2X+Zsgw6CcZqElUO\/nIuTRAmDRpUhpvTZ8+Pc4888wAIHn77bdfKIty+SqflLvzzjuT8cDzbrrppjCeW2KJJQJR\/7TJOMgYj3QCoNNPPz2OOeaYIBGB3v1PPfXUNE6iQk6YMCGQZ2kfC6Z7ax\/wAycQX3DBBV2S0Y+l9qjjmZ6tDa6HA7UNsAx6vVADZJYxaooX4cU6ugY8v8rDgfGd2AeTy97HpptuGsZPNIgsMTuxP0PZ5rYBFlOrccHHP\/7xNPfhl87chrGDX8iTTz45qItDyYxy7545sOaaa8YPf\/jDpK6SeKyHPddo\/9yhamHbAMtA3CSiF0cdZHEyyfn+978\/TXYy2bI0DRUjyn0LBwaTA20DLNKIOkhHZxXjYvPiF7849ZUK6FqZlFD+FA60OQfaBlhtzqfSvMKBfnGgrYBlYpPFi7vM7373u3A0WJYmr189K4ULB1rIgbYBFncY5mJzMO94xzuSGdiRBUqaPGVayKvy6PocKKl1ONA2wFpkkUWC1Yk5vR7JU6ZOH0pS4UDbcaBtgMVnjVT68Ic\/nMzt2ZWJO5PlEV\/+8pfTYry242BpUOFAHQ60DbCWW2654DZz+eWXp3VGFv\/xSED8BLWdd4FjocKBdudA2wArM4prEy8LQMtpfNKkyctp5Vg40M4caDtgLbXUUvH000+nZQs8q9F5550XJoyHr\/GinT+R0raBcKDtgGUi+Nhjjw0uTttvv33ytLZi9qijjgqTxwPpZKlTONBsDrQNsKh63JYwgAcGL2r+aLyseVZbiiAvl3FeqHCgXTnQNsDivvT9738\/LT\/gdGv9VWaac0vSLU1QJqeXY+FAu3KgbYDF4ifqz+GHHx5WyPKcFmAFbb755smjmlOuMu3KzNKuwoHMgbYBVm6QICVcmARO4caELLDj2mTRYy73gmNJKBxoIw60HbDaiDelKYUDA+ZAAdaAWVcqFg405kABVmPelJzCgQFzoC2BJSSxiEQi\/VieLzadieIB97JULBxoMgfmA1aTn133ceazROw54IADUrRVQfrFBBcOTV7dSiWxcKDNONB2wOIPyPtC+DO8siyf6d1yfXnSChUOtDsH2g5Y\/AFNFgvCn5knEqtAMgNxaRInw64Woj2JbTd16tSy1UxmbDkOGQfaDljAI16duOOCPora+slPfjLEEAe6\/nJC5FcBIy1HsRTFmM0cWX\/vU8oXDvSHA20HLI23WhgQ7LVkCxgTxG9+85tl9ZuASCBQvoaAaXXyjTfe2O\/7lAqt5UCnPb1tgCX6LW92K4cRi6CYglYQG2PJU6a\/DL733nvjta99bVc1OybOnj2767qcFA4MBQfaBliC+J922mlhTyaB\/3ffffe0otiqYqqhvaLECR8IExhDGtXznN6IvyKqlnONqmmNzpVD1XzXqJrW6Fw5VM13jappjc6VQ9V816iaVu9cGVTNc52pml7vvF65nOaY62y676mRz6tHZVBOE2veNbIxhBj1n\/rUp+rWVUc55DyT60zSnDf6Pgaa3nJg2ZFQBFzbvwAAK6ClISSVzQGQXStsGcOA0d+Ojho1KoRSy\/WcM+Hna9t62qmwJ+KviKplXKNqWqNz5VA13zWqpjU6Vw5V812jalqjc+VQNd81qqbVO1cGVfNcZ6qmV88PO+ywtANkvXI5zXG17Q6P6Ut9LJ4auVE63jT6E6levpcyKF97b66RDSQMEWgzOb\/7UTlUTXedSbp7Dja1BFg2LRNKWngzO04IIIN4sWMSK6DNEXJn7SYIVECX0\/p6tDWOnQ2Z6pFz+z71tX4pN7gcmHbDQ7HvtDtimzNujmU+fVVMu+FP8ejJ4+OWwzZJtMOGI1O6MvnJ9z86LyZfPjvVOf3J8bHO0b9M1zm\/HY9NB5a1VZZ\/AMoll1ySdoq3oBHZxsa+uX6FqH9jx45NW3busMMOaRsf6mJ\/mWiXeOM11sUtttgijNek9fc+3cv\/4Q9\/mC8pv3gfS5tS+mCb1bb1T5td93mTL\/9DzHkOKCsus2gXoDIjX\/dc2iFbjErp1\/5ubgIQUH3yOSCqd81zacpKc73D1Ltd9om6v68+VVqAQk0HFnM6NcGuIqx03dtujyReFszktu8R70Kkps0226x70YbXpBJvDSpmLiRmxogRI9Ic1n\/+85+cPOCjPbv8+lZ\/efPH4hd4Yaeb9vsvQLrzgWSase+6ccYOb+qR98qRXqRTBlT3Cvf87aVx3V8X655c99r7qpsxRIlNBxZ1zqJGFj5qHwtglaiHJnIdd9xxxySpxBVUVp3e+KDM5MmTY968eakogA72PJZfTICirmQw+RB6+1hSg8qfPnOA9HrrKkv3WP7SB1\/eY36rMpsOrNxR80rml6h5LH\/Tpk0Ljrck00477RRrrLFG2ib17LPPTgE8lVUn1693tC+v3QdZEHP4tMGcx8qA8iv6ikWeSSpLu4Cp2apOPf4PRVojadXfZzWbPy0Dlv2w\/vjHPwYQsfxZObz\/\/vuHdEYMKqEVw3wG7ZFLfWNB7ImhNsNebLHFUsDPXG4w5rEAinQCqPsfm5cANfGdy+ZHlOMQcsC4awhvP2S3bhmwONVS11j8cu+ocYwaxkMop8+ZMyeAMF87Gj8xSpiD+OxnPxtCpPHSsMSEuqlMJmb8fF7v6NesHl176z3x8bNvCICaedcjcdN+o2L6jiuEsu7j2C7Ubu3xPgaDN7utt4SuNaT1l3w8TNX09iw3aFRG3mBTy4DFcGGuisRi\/TPO+shHPpLUQeqhgDJAg4y1WPKqqiBpNnPmzDAfceKJJ8add94ZIjitv\/76MWbMmGBhNDZjLDF3lRnnvDqPJd3Atkq\/euRl8alL58Z7pz4Qt\/75vyrfbRPHRrVMOR\/dIz94uwwGj\/bfaq1oNM5aZpF\/xzYrzYtXvvKVPbalt3b4BgabWgYsHbE9z7nnnhsHHXRQinzL62LbbbcNxgYAABoktiArH3VQvXpkPkxZBFTA5T7colgJzWEh5+uss07XLZ7YfHKSSFUzNFNu1SjRVbhy4tevctny03Zrz2AyhBXxkC1GB7Uwk+sr9ly5z49pNn9aCqyvfe1rQY2bMmVKGD8ZY51zzjlxxBFHxOzZs4O6h0gj5Yj8PnPy+YIkHZWx0TzWklccEk+cs2MsfcnuXeT6skO3DtKyEbFaNsprRfpwb89X9t4svSfvBrk212m1wtFHH93ju\/I+euLP85\/KoB5aBizb9tx6660hnPTSSy+dRDm1kASbNWtWnHnmmWHrHmQui0Tq6wQxNdEcmGOtVksm+2uuuSZ4yXsZtVot8j8SrtDvk0rdaXzwPrkk8eJZ0Lbn72Gwjs0H1vMt59bEgMGK93xSsAbyuiCxAM5EcSbjLwsgc9lyLBxoZw60DFg81c01WdErloX5pu222y5tfCDmhfksBo1MfZ0gbmdml7YtPBxoGbBqtVoYU1kfZWeRU089NYyD+BF++9vfDr6DVTKJDIgLz6spPe1kDjQdWFTAhx9+OBkmWOm23HLLtEzAEgDLQ0gv8S6szRJWOhM3JQaOTmZ2afvCw4GmA4vRoqe9hk844YSwcA3ANt1008gkGAwfw4Xn1ZSeGk6FpgAAEABJREFUNp0Dg\/jApgOLOketE9PCBK4AL7zX0cUXX5w2nOPitM8++8TWW2\/dRZZ7mOwdxL6XWxUODBkHmg6s3BNqIKkEaDlt+eWXD+HKllpqqbDYMaeXY+FAp3GgZcACnqeffjp5XAgfjcxXWQjJO4IVkPrXyCrI4HHooYeGOa\/MdMvslRcLwXjNPQG1xBXMHCrHZnGgZcDiGGuuCkCAiCsTx83jjz8+ZsyYkeJUXH\/99V3WQepjlm682HfeeeegTmZGGbuZXGa+5wJFzWQAGYr1WPmZ5Vg40IgDIxplDFU69U+wGPdfcsklo\/tewzzTWQAPOOCAyBZBx0mTJoVxmDVXnC7FyFhppZXcpotIwLlz56ZrnvMcfc2P5bVcrktcwcSeIftTbvxfDjQdWLwneKFPmDAhrrvuuqD6\/bcpkc6lMWj89re\/DYFgqIOWjQCkevzC1l133eSlYZI51+XuRPLx0DA3ZuEkL\/ne1mNZZ9VXmnz57ED5meVYONCIA00HFpP5HnvsEYcffnhYGsLax0kScWkilUTCvfDCC4NHO+90k8fWZ+29995B5avXGb5ixlJAyTOe067lJFRNEXUB1JL\/n\/3sZ8lAku9x4WUzo6900vk\/ihOm3xDLTrjwBYFSRq25Ua+OoPpYaOVB45OxtLiArMcLytf8PQzWsenAyg23Yph6R1UDCsSpkgqoDCA5IpPKJBuQuK5H6rMqvu51r4tarRYbbLBBWgCnrGUkxmNARyIuvvjikhMtcc3x8ZdvTOgzPTJl20DVICludOy5MzrSkRXfhoKuvPLKIecHpwKub4ITLUgfvL\/BppYBq1FHqHSWelDrPve5z6Vx1q677pqAQprJr1d3xRVXDB4deUWyDRUYO8x9UT+ResZwxmnOB4usEbKGq6iJg8XRzr9P2wELS3fbbbeg1vk14nnBUshBl2ro10mZ7rTaaqvFLrvsEszsVAS\/ZmJlAJGFjfwQxRWkEkrrXr+\/19WFc7cctknssOHIuPbex16gIlrWn0lkpz5QCkxZLdeXMaAQAn0pN5Ay1bb09XzPix\/q6kfuf3Uxaffz\/vK\/v+Wr76u\/dQdSvi2BZXKYh7vxENO5NTdAo4PGaI6WnFSNF7VaLQSgkYdIJiZ956QV1VJcQauQzW1Jz4Tp\/SV1q3W2W+3ZOHWrpUM8vSq9e9VFI5PITgOhux+cG73Rg08802uZ3u7RKH8gbV7qRU9Hrpf7X+VL9VxgnjUnXh2oytPezlmX\/\/73vyeVv7ey3d9Xtby8waaWAovqRt2j9hlfCV1GlbO4kWWPoeL1r399GBMxeFDtMKA\/81iA2NMYy\/1Gj+45fsOC5B+7\/bqRaeoeG8ZA6Mef2SRaSQNp8wnvW6mrr7n\/jfgorsWl+28YO22yYoig+4HzH0oxRxqVz+krrLBCWM9n+iWnDeToGxhsahmwGCLMVwGQTgk+QkU76aSTEpAEmmFuZyHktEt6cYNSFiP7Oo9FcpFYSF3XnuN8Qcgv3oLUH+y67dae\/vbPOPWQ58NLU6vVr6qLVFBpA6Vm86dlwCKNqGViEVDRqHakkvkqy0NILkvr77vvvgCGp556KuRhbH\/msUwU9zTGMh6bPn16NCLPQ9V815mq6fXOG5VrlN79Ho3KdU9n2OleN193Lyu9Xpr07lSvXE5z7F4+X1fboxzKeY6ukfPutNrfb45dXz07vj52bqJDthgdgvsAmvGa8uoi6qAQD9IakXKomu8aSfMNOB9MahmwWOsAho6cO0Q1JJXsj3XWWWeFYJ2Cy4wZMybEDOT2BHAME+PGjQvhzz7\/+c+nOH\/MrYLTiKC73HLLBdDaS4lkJK0ajbGomdZ\/NSK\/dKiaLx6HNndPr5bJ58qgfJ2P0lC+bnRUBnXPl4ZyuumIfF49+lFRTpur6dJQNa3euTKomude0lA1vXou8I\/rBX2++savazx2VRy96h2xyuLzYverl07xHoHKD6dvyLPqkfra6X1V86Uhab4B+YNJLQMW9yJWv3333Tds2WNCl3rHcwKwTO6a9LP7iLknk76ARJr94Ac\/CKuMRV8aP358fPWrX4177rknRdE1XjOmIv1Ed2KocN1oHkuINEtUGlHW2bvnN0rva7nhXt\/EPl406mejdHWq1L3cdw8cnzZU+P4dT4Yx1qhRo5KHTrVO9TzXd6yXLs03MJigcq+WAcvDmcCB5JRTTglgMrnLMZeHeiaq4vve977gnkSisQSSUtRE9wA0E8MsgH61SaxarRa8582HGdySWEh5UrKMsXCic2mHDVeIGfusGxucfl\/YcaQvPSGd+lJusMq0FFiWeYjI5JeH1LFro3EU0zov9YsuuihtjODIU93ksGi4IjkxZpBC3KK4QslzH\/NdDCLUQKHOgIg6AMSN5rFIxv4SwPe3zlCWX9jas\/Pm68Vivz4n\/u\/uVwb\/0d542xN\/BgtM1fu0DFiPP\/54UueoggwUPnpzViTOvffeG1Q66uEtt9ySYg9uvPHGQXUUwFMHTBb7FeJzyLootju9furUqWnJyTHHHBNnnHFGAJaYhDmuIEmofiZjs0KdGVfwgZ+dlzao6Ky4gvnLG6KjJR4mdKlx1l0BjmuSh7+gcRFfQkf5HC15txuPAY1m1Wq1EKvdvah8\/ANzXHb3Y20cOXJkApryyFgtl3FdqHBgKDjQMollDMRSJ3AM73ODUDEvpDFssOqx6HXvNGvi7bffHnYlYZjgE2gObO211w4AY8RQh\/eG+zBwWJHM2oicUw2VKdRcDljRbaxMLbviiiua+\/AmP61lwGJsoBtjNF9Aix6ByfhKpCZzC0cddVTaOUR87tNOOy2UYZCwsRxjhwlkGynwCTT2ojryJeRfyFzPq4OpHrjyGIsV0T2azOfyuOc4YMpkwoQJ4QeUau6H7rnkYfm\/ZcDCTdKHIYInhTGS+SlL7kkzS\/GZ3EkX4zEWQctHarVaMEpwgaImqiOqk\/vx0qBvG6upz8Raq\/Ucu129Qs3hgHfonXi\/5o5sMticJzf\/KS0DFjWPxGKEYFywYO3+++8Pvn2sgDb\/Nq+ViVsTb43ms6g8cTA44H37YVx00UXT7Uzq+sFMF\/390wHlWwYsv1aAwmT+mc98JkVrYpygGjLDV8NLOyeBshNuB\/B1oWqica7pjdxplliWWvFFrNrmNG3+cJFFFklxI5Uz\/qWpOB+O1DJgVZlp8parklXFjBIAV80v5+3JAe\/KbjCmTEig3EpjKRG3qOt+ELmamRph8WVc8n6VN2bOdYbbsWXA4kFhQpenBb0b83lgsBwZew03Rg\/H\/pBCpjg+8IEPzNe9mTNnBgMTtd6PpTHwXXfdFeYqGZX4fDIqmV6Zr+IwumgZsGq1WrDacU8y5yRQDEazCFIThhGPh21XWGJ5vZhLzJ3kVkbN98MprVarpeAxnACAjAQTD0M9+cOVWgYsDGVe90tGdfBCLK83AcytSX6hoePAUN6ZJDOeGspntPu9WwYs4KGbn3zyycE8nomXhcFvuzOutK8+B5jRaR5UeiVM4htfWQLkemGhlgHL5KAXYGxlAJxJZNzhPKgd7h9WrVYLk\/DGWX4gzU8yTK266qrDvevz9a9lwDKOYqQwaThfi8pFx3PAZoLGX0ztomaZoxSeruM71o8ONB1Y1k+Z4+CuBFTWWu21114pfqAY7fKU6UcfStEWc8AEPy+Z3AzWQJqHBarmIEmwnLewHJsOLDq4uIE82HlemDwEMtdInjId8AJKEwsHGnKg6cBiMeKFbqaeuxLjRa1WCyuCEe8KZRq2uGQUDnQAB5oOLNZAEopnumi3DBUMF3zJOoBfpYmFA33iQNOBxRpI1RM30BqsT3ziEyGtjKv69L5KoQ7hQNOBhS9W9jpm4jdWJFbmRjkOBw60BFj\/Y1w5KxwYnhxoCbDsiWUpvcg6nDEtWHR0bbVvDhgzPFleerUwcKDpwGL5MyvfKDKSPGUWBuaXPg5fDjQdWMOXlaVnhQP\/40AB1v940bQzQW9sgCfGYaYc0q1pjRiCB\/G0OPfcc9Mm7VyZTP5XH6PfU6ZMqSZ1nXPUtX0T\/8KuxJaeLNjDC7AWjH8Drm3ujrtPpkMPPbTrXjzCxYfoSuiAE8t+LrnkkhjoOiuLXS01Md7ugO722sQCrF5Z1LwCfs0F6RdgR6zF2267LfhScmYVGdivutaICSI8HGkn9NvEiRODwYeUcFSGtCAhgFQkK2Xd58gjj0wSRb57ioploalNJMwnkhjC0UmzgNGKX4A58MADu+JVkCzIczKJe8Gx2mLGnNboSDprD7IlkzbYpmns2LEpNBrPnEZ1OyW9AKtFb2rPPfdMK2tZQoWAmzVrVmqJeBDTpk1LWxjZ4VKYbDH4fNjcv4TftnWseIoMPT5k0iJVrvNHXcFLrdq1Z5XJeTu4KMoJmuRUhrS48cYbw6LTOXPmhNj4wEe9E\/TFljm2vAE+Yb8F3XSPTMqvvvrq+TIdq33UT\/EEZZDOJLV+chKwLk+79EX\/LTNRrpOpAKtFb88mENkyauO0tdZaK7Vk3Lhx4Zd\/9uzZ4ePzq+6jFL3KphGkmLDcPsJarRY8y61rS5Xr\/AEMH7CFhjaLAFTRgBUlLUQR5o3u+dRPAWCAxpIeSz+MmUhHq7sBygpvz+u+vgrgpLtvpmof9fWDH\/xgzkqbCE6aNCkEUjXelAHcwqMNh7BoBVjeaBsSdUj4MGDyUYpuNGPGjLSBOfUuN1lIbupbvu5+pGIdfPDB4R6I9KI6di+Xr91LlOJ8PXfu3AQCG1KQkNRQfp6Al8s0PDbI0P7zzjsvOFzvuuuuUavVGpTs3OQCrDZ9dwbz\/CcByocowu9JJ50UFgxS1azMlU6qAaEQciSPHQ6lG\/PoGmlACpEoHKBtm0QllFePgBmAAEwIM4FSBYcRkdj4zdiPFO1eV8StnlTSannqpv5QAbU555GY2i5Sbk7r1GMBVpu+OareQQcdFAwQYtGLbjRhwoSgkjFSUKt4qQAYFYza5lpoMZY5YzFgoyoCiyM1U2w\/5426bVeXWq0WDAn2GuMsTV30sWdvGdfd63uGcSJgdM+rXgMsaSXqMeMJkDoa7xnH6QtJVq3TiecFWC14a1bb1vu4AQflJhnbMDqQOBdccEGIz1er1UIcP0F3SCuqlI+5VquFRaLGVLb+PPvss+O4445LIbtJHemIWkhKeL525Gd5rjQftliPzN6e61m1Wi1ZBH34NqOo1V6ourEgkmyknHtor\/vl+zt6nrbIM87TfuRHA5j0VTzCBVEzPacdqACrHd5Cm7eBCghgJKAAnfWaC0w77bRTGIMBer0yPaWZSrDKgdTtqVyn5I3olIYurO3srd+seaxrvZVbkHy+m+Lqk4A9SRNWRnNStdoLJVpvzzempPaSpr2V7YT8AqxOeEuljR3HgQKsjntlpcGdwIECrE54S6WNHceBAqyOe2WlwZ3AgYUBWJ3wHkobhxkHCrCG2Qst3WkPDk3hfPIAAAAlSURBVBRgtcd7KK0YZhwowBpmL7R0pz04UIDVHu+htGKYceD\/AQAA\/\/94LvCRAAAABklEQVQDAGE9GG2oUwh3AAAAAElFTkSuQmCC","height":129,"width":214}}
%---
%[output:80dcfda6]
%   data: {"dataType":"image","outputData":{"dataUri":"data:image\/png;base64,iVBORw0KGgoAAAANSUhEUgAAANYAAACBCAYAAAC8aERhAAAQAElEQVR4AezdCbynU\/0H8PMzqmnI1ghhmrFTWbJEpCa7GBQyiChbCJGr\/GlKsmaJkSXKTrKNsmRrMFkbYynLjCViKDGEkPjf9zHnen7PPL+7ze\/euXfm3Nf9\/p7nOed7tu9zPmf5nu85z2zvFv5ef\/31dy+55JJ3N99883eXWmqpd9dbb734\/MorrxS48m2WQJZARxKYLRT+PvzhD4ctt9wyXH755eGee+4J++67bxgzZkxYZZVVwlZbbRWuvvrq8OqrrxZC5NssgSyBKgnUAavI8JGPfCRsvPHG4Zxzzgn3339\/2GuvvcIZZ5wRvvzlL4d\/\/OMfRdZ8nyWQJVCSQENg4fvf\/\/4XJk6cGE444YTQ0tISJk+eHL7yla8EoOOfKUsgS6BaAtMAC5juvffecPDBB4fVV189bLvttuHNN98MF154Ybj99tvDPvvsEwwZq6PLrlkCTZNAv46oDlj\/\/Oc\/w4Ybbhh22GGH8NZbb4XTTz893HHHHeHQQw8Nw4YNC7VarV8XNmc+S6C3JFAHrDnnnDOMHj06jB8\/PhxzzDFhpZVWCgMGDOitvOR0sgRmGgnUAYvG7+STTw5TpkzpsIB6tw6ZeoHhhhtuCIsttlhwbXZy4izGfcABB4QvfOELTVXekLnhNnL\/wAMPhBVWWCGceuqpzS7ONPGVyzcNw1QHeZEneZvq1PDSFd6GkVR4kA0ZeR\/eQwVLpVMKJ6z7SqYecKwDVqtuPkyaNCkcccQR4Qc\/+EG7hKcH8tPlKNddd93w+OOPB9cuB+4ggDh7Ku4Oku5xb5rdww47LBx44IE9IrtmF+CJJ54If\/nLX6Ly7Nhjj2129E2Prw5YtH3f+973wjrrrBPWXHPNNpprrrnCRRdd1EatC8mRx8vRgmsNXLUmrtxTTlOrWPZL7ptssknscfi31xJpCfEkSrwpHlfpSp8fki+tlJZWi5vC4sErDDdxy296di0\/47nsssvC008\/HVoXzoM48SQSRlyu3PhLUzjP3PknSu78Er3wwgtxWePf\/\/53OProo4My8HNN4Vw9c0fuuUlr7bXXrutRX3311ah84o+KaVpCMTLxnsVDHuSCD7nnJt\/yIk+bbbZZHBmksuFD0uZWxStu6eJD6Z1wL5M4xIUPKRse+bDcIw\/eQXLnl6gcNuU\/+f\/973+P9Vm8RT\/1Q564J5Jf4Vzl5\/zzz4+jCOXjLn28\/Moyl1fx1wGLtm\/48OFxrcp6FfrQhz4UlRhaNq23q0VjFUwiSEtiCHnllVfGYaQXwV1Gdt1119gqepELL7xwXGiWOH+0zDLLxB6HGv\/666+fpsLiEY84pZ3yQMDc+ZeJH+KeKusnP\/nJuB5XziOeztDuu+8eW8tFF100yOenP\/3pumDLL7984KfH5zFu3DiX+DLlM8kh5V95vLjINPVn8ODBgRw1cMqqZRZWWSiShCWnu+++Ow5Hi37yVKu9r1xSYaT5zDPPRAWU8MU0r7322jDPPPOEBRZYIC7677vvvsH78Z4orGQJv15bXuSJ7FZv1RQbrRTliVd5y7yelVE80hev\/MiX\/AmXCDC233772GgpJ37lVok\/9rGPhUsuuSTKV\/nJJYVzVZ8Ar5gnjYZ0+aOXX345nHfeeUEZ+ImbOzf1l7uyK98tt9wSZcIfmA855JDg6rk9mcsHQwpyrAOWgGXyAlQYBeKnhSNkieu5uCnQsFatocqmNU8vXli8wlCMQDdAKoBwiBbSdYkllnCpJJU1xYNBJSd8L85zmeTXS7zggguiQAhS2vIgj\/fdd18ov5xyHF19HjRoUKyY5ELArkku5CBPVTJ87bXX2k1KGZUVcLWEqUIIlOLlp\/KtuuqqnCOloRM3fnjkQb6efPLJ4B2pAPLtParwZKYxFcHYsWMrZUSG5IpUSr1YqnTCFQl4pCdd6cuH\/KjI8lfkBUzPO+64o0vAL5x8kmd0bPDz\/PPPxwa9vXec3oWGRIOiTolOXVIf3KunZOC+SBoW78C7aE\/m6rX6LR\/tAotgnn322WIasYWTMS+io0ohIKETvq6z2ILw6ylKFaan4q+KV4UjUJWGgMnHM972ZPif\/\/wHS0PSkhtyaEm9tMQIDOV4qxonQCT7cvgUj6sKP3LkSLdxqItXGK1zdCz96EX4d\/Z9yneKU35K0cXHVNHjQ+sPwHuPGkXAaXXqkX9lVBZ1VF2tSiTJtQoPya8YjlzaBZbK8vGPf7wYJiikwir0HHPMUedXlbBWRysA8Ykgvy5gJx4UWtpYkzBcPXeG0ovT+mn5VQ6tl56wM+E7w6PFw6dVIyPPHcnQ8FuYRnT22WdHL0MV8ku9nopXfjepjDHA1J\/U2gqL9DTCTvVuu2i5+UsnyYRyg7zamFpvAN2wUz7K\/K3elf9ApbHBj\/QQRg5F5nIF1XBonDTi3lORt9F9Kr88p3fciJe7+nrWWWfFIaY6Ko\/yyq+Kqt5lSrPIbxjbLrAUbODAgbEVkwHPumyVXGucXpBWWteO3OvutYKGeVorGZawyqzACu65s6SCetkqrDCuAGu44Lk9MkQ1DEhDCnmRJ3lL4ZJwxJvc2q5duElpaZWl6VlwaUmTu+eiDMuNE\/8iFSscuSlH8ucnXmUq+0lbHgzFVCCA0POZ83g33pH3qQIL6714Pyq8\/KlgGs\/0jlOaKrnKnp7xqg\/puXhVEdUTdULdkA+KAuS+yOsde04NiTIpm3zKL79GlMpKNsqSwpJ7ozDc5a\/YOMmjvPJrRO3JXH1UL9WjhsC65pprwhZbbBF7KAKGws9\/\/vNRW6UV1MKlxOeee+5g4qk7JXT+\/PRMwpms6m61dCbnHQlK2CJ52XvssUdQMbsaD+F9\/\/vfD3oQlUVe5E\/e0gtJ8T788MPFZKe596K8bPNIFbXMIC0ViburZ\/fSIgdDBPl3lYeiDPGhlCc8KrqegUzJNk2M5UHlEZ6\/MsmT5RJxIGlL070XLjweYbgpC5kYBXgfJuhJDviB7oQTTgjiSZVeHNI1bEy8zN80egnARV4jCul5d8KW45WPRN6xOZs6QkbKpGydmQvLY6N3nOJvdDWnIwd1wxLTkCFDolofyKrCKI98yR95FmVOjpQsAF4JLBoUtoGnnXZaOPzww9u6SsOEtdZaKxBsMdFFFlkkaLl082NbJ70SSP4qFXdUHAIkd1e8Mlz051Yk\/uJART7hublKV\/qGO4SdwntpwuBD4uKHBy839Lvf\/S5qKMXF35W7a\/FZXOLkViZxC+Na9BMH90TJP+VBPtwj9\/hUqlQmz6ls7sUnfjye5Wm11Vbj1EbFuPDgTZ4qkh7Ne+MmPjyJpCVtfsoqfn745N09Ukf4ybP0yrzCF\/mL8fIrUjGsuIv5lRdhi27thZUmf3mSN+S+HE8xzauuuiog5eEuDvlQZnElkgfu+MoyT\/FXAovRLVtB3X6KzNXz22+\/HY1yPWeasRIwrNO6uxpaUWYYXZSHb1W5VMl23nnnOALRs1TxZLdpJUDWnZF5JbDmm2++sNBCC0WL9qT5++9\/\/xt+85vfhHnnnTcY+kkyoTO1Btwy9Z4EUovqCijeA3LfmVxoibW8rp3hzzwhkDWZuZIzeSP3RflUAmv22WePFu1PPfVUWH\/99eMCoznDbbfdFreTWDQuRtLRffbPEpjVJFAJLELQM5144onhwQcfjMAynmTWVNSi4Gs26WYzLdZm5pVl0bOyWOSLXw\/zfffmSLdN6tj4vLP1vRJYNjuyXqe6pMgQWVLLcuOHh3tPkK420+NRkdJZOXgPneXNfO\/L1vYosms2VQLrxRdfDNSJNIAjRoyIB8wwll1jjTWC50033TTawDU7Mzm+7kvgxhtv7H7gHLLpEqgElmHg4osvHn72s5\/FYaA1ijvvvDMcf\/zxYaONNgpprtX03OQIswR6WQI9lVwlsPRYVLef\/exn29Kt1WrxDIxHHnkk8C\/6tTHlmyyBfiaBp158o0dyXAksK+nUh9Y30lzKCjN7qnfeeSfQCk6YMKHbGaK6t+\/LmkC3I8kBswT6sAQqgcUw1AEyLC2szjNl+sxnPhOtMJiOUMMfeeSR3S6W9TCr6N2OIAfMEmiSBJ568f3dBUPmG9ikWEOoBJbYmSldfPHF4a677gqXXnpp+MMf\/hD+9Kc\/xZ2UzD1uuukmbF0mPZ352te+9rWGYdlpZXoidEUGdsh2hT\/zviffS64ZG+shUKH40ISfhsASNzOZN954bwxqKPjoo4\/GrePU7fy7SqygWS\/b7dmeVTdD1EzD4pFznZWDhrCzvE3m61I++1LaA+ZeKLw9eOmuVuNO8TcElm0ijj9jrJmItbttJIaKnYq9wASYrJcNK5daaqmCT77NEpgxEigqLkauulBTM1EJrBdb17GY7\/s4Atpzzz3jUdNOwV122WXjVoKu5oLN4a233hoPSGFNYFsEsjWiq3Fl\/iyB6ZUAUO110UMxmtlefyGsufg88b5ZP5XAYsFeq9UCI9v5558\/PPfcc8GQ0J4aa1iA19UMzDnnnIGxYlr1tx8JMcHvalyZP0tgeiQAVCNOuTe4imf2Fx4Jay3RC8BK6na91gc+8IF4IAtw2RQ3ZcqUkFTwMpUpS6C\/SACQjrruybDiT25vAxWFxaDxZzW9CJU9ljkUtbpvZDk+TE\/l9J6tt946ftrHMV3TmxNm92h645k5wudS9JQEgOnCu58LI0bfGwF11HVPtCXVssGwMOH\/1mh7buZNJbAkQHvDhMmcihmTrejOA9hll13yxxEIKFOflAAgIT1TAtOeFz4UbntsSlt+9VJA1bLB0Da3Zt9UAosFuwM\/XFOChoR6r2222SYeFpnc8zVLYEZKAIj0SMCTgGSop2cqgkkeAWr0yGVjL9WToJJWHbAAyWk91OvMl1xp8BKxdrf+1Jmt3yLPlCXQLAkAkP1SRRDZRwVEQMW9CkhrtWr7WqYO+Qz7Rq66YLOy1G48dcCiBWRqxDLCNhHXpMVL1zPPPLNb6vZ2c5E9swRaJVAEj6EcwOiFEoBo8rhVgag1eNAjARLwjPn2SrFnGrPnSqGldcjHD09vUR2wUqJU7D\/\/+c+Da3Lr89ecwT4vAcBBgIGABHBQGTyGcnjKvVAqJKAkEBneFYHkudnq85RuZ691wEpDwTT0q7oaKuLrbAKZb9aQAMCgNFwr9jhF4KShG1Al4DQCD8k1ApBhnd4IiPRQMxpI8lqkOmCloWAa9lVdDRXxFSPJ9zO3BIqAAYb2QJOGa8UepyPglMEDLHqgF48b3jac45YAhL+vS7wOWOXMsoCmcndCqG8E5Z6qLKH++wwsKPUwVYDRu5SHaHqazoKGdIAApWFbS6siAUgAR6+TqNj7JAAJ31+pIbAcMW1rh15L4fRU1rO4e87U9yQAKAhYUBEsAGFIVgSL+9TD8C8DRlztlRJgUAINQCTQAE7qcYAnAaelVZGAz9BN2Pbi789+dcBKBXEy07nnnhtOOumkSD\/96U\/jx+dOOeWUeIindCboggAAEABJREFU7R+JN197VgIqN0pAaQSWlU96z1QngSUBJoFFOEMycXWUYxUelQGTQAMoVaDhn0ADOB2lMzP7VwLLEdMKzfrCNZFnBrodfdMp8efrtBJQsRGgIBUe6TGQXgUBSBqGuU9AwdMdsMgJsKDuAiaBRhziy9RYApXAcoS0k5psoXc+heAMbw0D2REy0uWWKURjzu4CpQgW4EJ6FSTOzshXJUcrLzwwqPiopTCPMSTrqIcRRg8jns6kmXk6lkAlsBwWc\/DBBwf7p2zDtzlxxRVXjMPAgw46KABXx1H3Tw4VGhV7k6QF01voTZBepNyjNBMoehWk0iPDLAQoqAyW07+yYOCPWgrzmAyYGVMPK4ElK46SLp55QXmhx1pyySV511HaHeyTJp\/73OcCpQeNYh1T6wOtonWwtD7mnlurV4\/\/AwtKgElgARJUBRRAQuWhV3d6FCBBQIIAAAEJKgPFZB\/hQcIgQEGzWu\/S4xWkyQlUAktltw3\/xz\/+cfjXv\/4VLTB8gaRWq1UmP2nSpODbUmPGjInfyfJhrvTRs2IARrzrrLNO29HJwNoTa2JFAAFGAg7wpF4lgQVIkDDFvDa6V6ERkCCVHan8CEhQBkojCc4a7pXA+uhHPxq\/m2RI+PWvfz04WtqpuE4C0juVRWN\/lv1bvp\/Fzw7jdO85Efe55porPTb1ChjmKAlECUDcAKdRYkCCgAQBScvUOUoGSiOpZfeOJFAJrAEDBgRDvpaWlnictK\/cLbLIIsGHyjbffPNQPqWJosP3bZ0f7mhqh8b4\/E85cWp6cfmuLEt5Xy+hFCnzGUZ2lsbdNzF8\/6L3NrHpnapA9PG5Zg+bLjtnpFHrDg7mI+jPew8Nl2+3YKQTN54noANWHxi2XurdsPrg\/0RaeMBLAf3v5cldOo6ss\/lvFp9Gr1lxzUrxmJaU618zniuBlSJW6SdOnBh8V5VV+5QpU4J5VCPlhQ+YPfbYYwEgjzrqqOD4tBSXqxOeRo0aFc8qdEjNFVdcEYHLr0jU+p0hx1ftedUL4bS7phSDBz2QXseQzHrLg6M+H87eZdVI39n402HLtZaN1Jk0+guPhq+\/5LUv5TMZQNRVoCY8VALrlVdeCbR\/NIE2PJobjR49Otx+++3xw3MOhimm7YAZ3yrmVqvVwsorrxyshfn0D7dEw4cPDzSMtVotztvs93rooYeSd5eulA\/mTIaAAiYwmdugllbNmEk+v0xRAvmnFyVQCSw91dChQ8Nll10WvzbiuGlDQ0PEqrzpwWzbB0BzsD\/\/+c9BC0rhkfgtLO+3337ht7\/9bcDz0ksvhfHjxwfgTTydvQIV5UPib2mdE+mdWlrBBGDJPV+zBGaUBCqBZc7koJf2wFTMsHPdN9544\/jtLIoOC8vf\/e53w+yzzx4Y7yL3PoQAWHoqh9OYh3X1qyXU5QlUQNTSCqqWDKji68j3fUAClcDqar5qtVrYfvvt49nutvRTXlgHE892220XkHtuFBZ2JjsHXpharVqFj79Mhn3pkEV+I1ddKO4OdZ8pS6AvSaApwOqtAumpgEt6I1ddMIOKIDL1SQlUAsscy5qTazHXnqvcizw9dW8IaE1K\/IaA1pjc9y7l1LIEOieBOmABjjUqX23cbbfdgisrjETOFnSuIGuMzkXfPK6jCwctnrzNss2LOMeUJdADEqgDlt5o7733Drvuumu4\/\/7743XLLbcMib7zne9EKwzKjR7IS8Mo9VZp4Zd1RFajNxRV9ugjEqgDllOZKBeuvvrqsP\/++wfXW265JRTJ10Ec3tmb+S\/2Vge2agF7M+2cVpZAdyRQByxDQb2WdSlGuL4wkoaB6WqoiK87iXUnDGVF6q3MrXJv1R0p5jC9LYE6YAEVkyPW6oaEaQhYvHLH1+2MdjHguMKZ2yNb1etdDJ7ZswRmiATqgGUo6KBOH0IwJCwOAdM9d3y9ldsL75ock9JbtbQuBMeH\/JMl0MclUAeslFdDPUO+NPwrXrnzT7w9ea0bBs47sCeTynFnCTRVApXAMtQz5CsOAW1QZK5EY8i\/qbloEBlgJa81l5g33eZrlkCfl0AlsAz1DPnS8M+V+t0Hv9n59Za6vagNXHPx5n7Kss+\/mZzB3pdAE1OsBFZV\/LVaLW4HMRTsrR4r5cP8KmsDkzTytT9IoBJY5lAAVJxbub\/22mvjR+eo43u6cIaBbWr2PL\/qaXHn+JssgUpg6ZHKcyzzLVs+uPfGuYKAlcqaF4WTJPK1v0igElhVcyzzLPMu51V0t3DPPvts8KlVe7Ack3bGGWeEdCBoOc7i+lXZLz9nCfR1CVQCS6YdKDJy5MjgiDLPZ599dtyub4jouTsESBtssEHclXzllVdGUylnalTFNW7SS9E5z6+iGPrNT87oexKoBJaz2Y844oigV3F+BdYRI0aED37wg8EHEmyz59ZVct7gZpttFmq1WjwTwxb9qmGlk5fS\/Gr+D4c+fTqSBqgvUD6l6Ylu1ZNePaXJMWVOWHKibTo4horddv3JkycHc7Cuggq\/46qB0wE1a6+9dlhuueXCggsuyKuO3p1j\/rbndT+1UOhLp\/r01bw4Y6Sv5q0v56tXT2kaNGhQYMHuUJi2Gt568+STT8Zea3q0goB6wQUXBHFbGxs7dmxrzI3\/8\/pVY9lkn74rgcqhoMrvMJgf\/ehHwZFl7h0WYz\/WN77xjVA1fOuoiK+99lrwZch03Jke0GLzpEmTpgmaFRfTiCQ79DMJVAJLGZxsqzcx12LO5Ajpm2++OXzpS1\/i3WVyXLW5m2PSzK0cfzZhwoRQpWUcN2srLros2xyg70mgEljmUTSCzgnUqziqzEGb3empUpHT8WfOKlxzzTXDJptsEpyc6+i0xJOuT730RrwdkheGoxzyT\/+TQCWwKBTWW2+9eLQ0RUaziuX4M\/MrR5+NGzcuHplWq9Uff\/bOoMHxY27NSjPHkyUwIyRQCSxrVdat7M0yJKSSTNTT37R6Z9BH2+SQLdrbRJFv+pkEKoHlm1XmV1SRZeLOv6fKqcdKcWeNYJJEvvY3CdQBi\/GtNSpmRnothrdl4o6vpwpaBFb308ghswRmrATqgAVUo0aNCpNaVeCMbRnelok7vp7K9tuDl26LOm8VaRNFvulnEqgDFuNb86q+cOYFG8F+Jsuc3SyBNgnUAavNtfWG\/RuVuzlV62OgzPDNLENBzz1FqcfKqvaeknCOtzckUAksC7kWhptthNtRgYp7sBadb2BH7Nk\/S6DPSqASWNauXn311dBsI9yuSGHIfB\/uCnvmzRLoUxKoBFZPGuG2V\/pijzUk91jtiSr79XEJVAKrJ4xwOyOHovHtotmcqTMiyzx9VAKVwJJXFhcUF+ZazTDCFWdXKPdYXZFW5u1rEmgILBllkd4sI1zxdUTjplq148vAIoVMlRLoB47tAmtG5T+DakZJPqfbLAk0DVgs1g0ZV1tttWBT5IMPPjhNHplHMeJtZNCbt4tMI7Ls0E8l0BRg2bR40kknhWOPPTbcddddYY899ggsOKyHFeVifxfwJcNec7iiQW9RK1gMl++zBPqbBBoC65lnnolAsZ2+SEcddVR45ZVX6srJGmPo0KFhySWXjO6f+tSngu8UWw+LDlN\/2BjONddcU5\/qL0VQzfvBt7t14g5rkVmV8ilN\/eSUJudcPP300\/Gbw3b8JjLUc9BMERZLLbVUoD2kpmcZb5cwu8O55567yBYA7aqrrorb8ddaa63gANAqS\/nlhsyfT2YaNqxLMujqKU19+eSk3syb0VNdJW3SQ2WPZQhXq9VCS0tL2HTTTYOt+YkcLtPolKZHH300bL311uGRRx4Jhx12WKBVLOZz4MCBgfW84eLll18errjiinDbbbcVWeL9SUccEtI8LF8X65QsDLGzrDonq7KcYqVr8k8lsOabb77YWjrurDPpORzmnHPOCXvuuWfQ0\/3iF78IeqxyWKB0dkatVov+VPnp1CaawBePGx4m\/N8a4e9\/PDdoSTI9nuXweO\/IoFxXp\/d5tqoIXn\/99Xh+IKD40FxHcyzje0O8008\/PQDOgAEDponW6bn77bdf8GEFQKTwGD9+fFhxxRXreAGsziE\/ZAn0QwlUAssc6otf\/GL4yU9+EhwJneZXrlVzrEmTJgXq9R122CE44Rb5+AGlxvnnnx9QOqUJsPRUhpbrr79+8IGEfii3nOUsgXYlMFuVrzmUYZvKXybu\/IvhuBnS3XrrrfFDB+nLJIaD2223XUD4ndJEYXHnnXcG617bb799PMedXz+knOUsgYYSqAQWbme3U63bk2VR15rT8ccfH7jzz5QlkCXQWAKVwDIfOvLII4O504knnhgWWmihqMygLj\/88MMD\/8ZRZp8sgSyBSmBRLPztb38LjpX+xCc+EWabbbZAVf6tb30rgo1\/Fl2WQJZAYwlUAotWT6+khyoGffPNN+OciH\/RfXrvLSobdjrH3cLxDTfcEGgOpzfemS08mVjWoEAiJ+eQVC2wk19xreaAAw6Y2UTR1PL48s2hhx7a1DgrgWUdyxHT3\/72t4Mjodn4+QLjXnvtFbzQeeedt0mZeC+aa6+9NvaEFBqUG7\/85S+jSdN7vvk3ScDyxPXXXx+uu+66cM0114Sbbrop3H333cm77Wq0YekjrQOy4WzzzDdtElCvfUjRspIlpjaPJtxUAku8O+20U7QV9HLeeOON4Kz1\/fffP3zzm9+MvRaeZhHFCIt4av6FF1440B6y3mhW\/DNLPEBkeULD5gMVevh77rlnmuKpMGVzsmmYskMw8lpllVXCFlts0XRpNARWrVaLi7dMkKw9sVb3CR+ZaWYuaBnN2QYPHhyjrdVq0YRHqxsd8k+bBKwXsglMDosvvngoW8cYLgKWoY0vaG611VZxjTGFydf3JaCBspaaPgf8vs\/03zUElgVfn9mhbvftYON6yGY9Pv3J1scArD6hWu+an6okULa\/LPO89dZbAaDOOOOM8MADDwQfC\/QBQYv1Zd783HMSqASWXuSYY46Jwz4fimMo6yUx9GSNwUi3WVmaY445Aqv4Z599NkapxQXepZdeOj7nn\/clMHTo0PDYY4+1Obh3anGbQ+sN4LGAST0bkzHyfe6551p983\/nJTB9nJXAMpGjqdNj6U0kYf7Dch2oytpC\/t2lWq0Whg8fHsyzpGkf2PPPPx+WWGKJ7kY504ZbY401wr333hu333gH7gGnWGBbfQz\/gI77ww8\/HMyRE9C4Zep5CVQCi1ZwmWWWCUyP9CApG9SSFAv8k1szrhtuuGEw3qVx3HbbbWNPueiiizYj6pkqDl+\/ZAWz0UYbhQ022CA2SNwUkj0mIjfa3B133DGwyTRHPvjgg6N88WXqHQlUAosyQWtIC6iVZFSr0u+7775x\/xQlBrdmZVFvaO8XILMz1IM1K+6ZKZ5arRYM8wzNLU0UbS3ZYyLlJT88d9xxR\/j9738f7OjmnqlaAkZmzV6SqASWMblJL9vAQw45JI+R6qYAAAatSURBVG54ZIVx3HHHhfQMCNXZzK5ZAlkClcBiva7VY9luf5X1Eqj2XKQsviyBdiUwC3tWAos8aOl8FMHk2Fh9ueWWC8buWW1LOpmyBNqXQCWw2ASyYtdbsYBgfXHfffcFC5JMQNgRth9t9s0SmLUlUAmsl19+OR5fZmGYYoGIzLt8iG7y5MnBMWbcMmUJZAlUS6ASWBYZWUJYTyoGc1Yg9btt9kX3\/n5\/6qmnBtRROSyS77bbbk3d7Em7t\/zyy4euWKCzXu8Kf0flmh5\/eWFJbxnAScfTE1dV2BS\/ZRiGC1U8fdGtElgMOPVOKpE1EAfF2NbBANf6SbPXsfqiYHorT\/fff39gr9ZI3dsT+dA4Vm036W5a5uDU+sVTjbsbVzkcpZmdFYyOy359+bkSWDJsEfLiiy8OjGNvv\/32uD\/qzDPPDDvttBPvfkcqkwZCJTBXdNgNBY0W8eijjw5Ir4XvvPPOC3oRfKzu2U1qjW2bsW3DyVVaT4ocjY0TgMV78803V8qFRQnbPXHidUQcy4mUtgNOq3og8e+9997xhGHxq7wpAcN1SyLySFPLDIyftJTFAr+0rHUpJz9pALC5s7zidTQ4XuuUP\/zhD9t6TnJw9iONsHhSnsXTiMhEY3zCCSfExWnxyot0ymGUvdgLlZ\/L\/P3tuSGwFMSJpI4so7A46KCDonFnrVbj1e+IrRzAnHvuucHBoiqSyq5FPPDAAwPafffdAwtyLSTCB1i\/\/vWvg9b45JNPDvap2evE1EtvvtJKK4W\/\/vWvYfTo0RGcwpSFo9LceOONcQ+VHspQ2xoh20vpIhW+GI6CiF2mA3mEAYBTTjklMFnCN2HChPDVr341Ho7q9CwbILlbZDdk1RgKt+CCC4YxY8bwimSbiQZGue2DsxUFLxBRUkWm1h8LzBpSjat4Up4BrtW74b8Gg4WO\/WLKbagrnYYBZlKPdoE1M5VZRbWdwim87B31PlrochkZugKOK7555pmnzBKf9RB6FJWbgodpEYNYIIsMU3+kq6fRQ9prZo3QvU2L8jOVbZqLHvKpp54KhuTCAPCoUaOiwTJm+7IAynzXzgMVmrseBsiZiOkpDOu5J5I2PwDRa1FQeQZgPUjiu\/rqq8Mmm2wSt\/BIX7iJEydOc25\/4k9XxzgwpxIn+0R2i+xAk\/+scp1lgMWGzgm9f\/zjH4OtMHoiJj\/lF81g1fHYKqtKzcSqzOPZHEULr3KbvBuSXXHFFUHPyD+R+GhRaVWTm0qnB1C5k1v5SlEElAkYAAQ0wuJ1Bgk390USzlAV8AzbLZcU\/VM+XnvttZjX9IxHA+GKgNIwTtmQLUOAbimGfyOyW2GBBRZo8y7etznOAjezArDia7RMoFXXG7GDdDDOaaedFlSwyDD1x7BJpTKEMWRSoaZ61V0MBfVQhlYAhgzPVOYio8o6aNCgOk0ibauWHbiKvMV7wPEMmK56z1\/96lfxCAPPjcjwFgA1Gpdeemmc61Txpnwpa\/I3R0r3\/DUwyoUAVMOhZ0s8VVf5Nf9LfobWVYoH5ZNG4pvZrrMMsFQaR7p50eklqtip1dc7cFcxtMqezWfOPvvs8M4774TUu7jHN2TIkPjRB\/MHvZchICPY8hxLGsOHD49fVjF0lA\/neuhRUm8kvjIZRjl2zjBSXsxXgF58Zd7ic8q\/PFG6mDsJX+RxLx6G1M40YXTtqDtzKn6In4bFNh6gtoNcDyZe\/o0IUM3LfOrJcFmenapc5qdZlldxC+McjzJPf36eZYBlf5fjss2JaLn0XOZZKhjrb70XrSAeL3qFFVaIH3jYeeedg9b\/rLPOChQBwGGo5aWzTlFxfMYI3z777FNpSW4fmzkYbZwzFoCUNlEcjci8ZlTrnGrs2LHBpk\/zJobPHfUY8uZ8Er2pMtEqUnqYT5XTMr8CYMPebbbZJliLSjyWAAyXaYdpMw0DKVlSQ5T4qq6Gg3ZAjBgxIp4nYeiNj3zN4zQu3gGZSMMSjiFu6tkoXwDbVbj+SLMMsGq1WqB6puEytNHTAJSXRkPoJdIKWl4w5NLzXHLJJXGNybAQEFRqwyGtvLmJSqn3sakQ+GjaarVptaaGPCqlTYfILoFUiaSJ5KNM9r6l+OWXyh2PdIpaxOLzsGHD4lYRigaaxM033zxqLfWawuAVB9L70mzipQXU+MgrP0NdW1TIi7+DW1V+fh2RNAyRyXSXXXYJKU7lTLLjpqGglXTalA9vaAjI1dEC5rauHaXVV\/1nGWD11RcwI\/OlkusVDcf0xNbTUu8yI\/M1M6T9\/wAAAP\/\/9h7tnAAAAAZJREFUAwCm7tB7O\/G9tgAAAABJRU5ErkJggg==","height":129,"width":214}}
%---
%[output:849ae871]
%   data: {"dataType":"image","outputData":{"dataUri":"data:image\/png;base64,iVBORw0KGgoAAAANSUhEUgAAANYAAACBCAYAAAC8aERhAAAQAElEQVR4AezdCbynU\/0H8PMzqmnI1ghhmrFTWbJEpCa7GBQyiChbCJGr\/GlKsmaJkSXKTrKNsmRrMFkbYynLjCViKDGEkPjf9zHnen7PPL+7ze\/euXfm3Nf9\/p7nOed7tu9zPmf5nu85z2zvFv5ef\/31dy+55JJ3N99883eXWmqpd9dbb734\/MorrxS48m2WQJZARxKYLRT+PvzhD4ctt9wyXH755eGee+4J++67bxgzZkxYZZVVwlZbbRWuvvrq8OqrrxZC5NssgSyBKgnUAavI8JGPfCRsvPHG4Zxzzgn3339\/2GuvvcIZZ5wRvvzlL4d\/\/OMfRdZ8nyWQJVCSQENg4fvf\/\/4XJk6cGE444YTQ0tISJk+eHL7yla8EoOOfKUsgS6BaAtMAC5juvffecPDBB4fVV189bLvttuHNN98MF154Ybj99tvDPvvsEwwZq6PLrlkCTZNAv46oDlj\/\/Oc\/w4Ybbhh22GGH8NZbb4XTTz893HHHHeHQQw8Nw4YNC7VarV8XNmc+S6C3JFAHrDnnnDOMHj06jB8\/PhxzzDFhpZVWCgMGDOitvOR0sgRmGgnUAYvG7+STTw5TpkzpsIB6tw6ZeoHhhhtuCIsttlhwbXZy4izGfcABB4QvfOELTVXekLnhNnL\/wAMPhBVWWCGceuqpzS7ONPGVyzcNw1QHeZEneZvq1PDSFd6GkVR4kA0ZeR\/eQwVLpVMKJ6z7SqYecKwDVqtuPkyaNCkcccQR4Qc\/+EG7hKcH8tPlKNddd93w+OOPB9cuB+4ggDh7Ku4Oku5xb5rdww47LBx44IE9IrtmF+CJJ54If\/nLX6Ly7Nhjj2129E2Prw5YtH3f+973wjrrrBPWXHPNNpprrrnCRRdd1EatC8mRx8vRgmsNXLUmrtxTTlOrWPZL7ptssknscfi31xJpCfEkSrwpHlfpSp8fki+tlJZWi5vC4sErDDdxy296di0\/47nsssvC008\/HVoXzoM48SQSRlyu3PhLUzjP3PknSu78Er3wwgtxWePf\/\/53OProo4My8HNN4Vw9c0fuuUlr7bXXrutRX3311ah84o+KaVpCMTLxnsVDHuSCD7nnJt\/yIk+bbbZZHBmksuFD0uZWxStu6eJD6Z1wL5M4xIUPKRse+bDcIw\/eQXLnl6gcNuU\/+f\/973+P9Vm8RT\/1Q564J5Jf4Vzl5\/zzz4+jCOXjLn28\/Moyl1fx1wGLtm\/48OFxrcp6FfrQhz4UlRhaNq23q0VjFUwiSEtiCHnllVfGYaQXwV1Gdt1119gqepELL7xwXGiWOH+0zDLLxB6HGv\/666+fpsLiEY84pZ3yQMDc+ZeJH+KeKusnP\/nJuB5XziOeztDuu+8eW8tFF100yOenP\/3pumDLL7984KfH5zFu3DiX+DLlM8kh5V95vLjINPVn8ODBgRw1cMqqZRZWWSiShCWnu+++Ow5Hi37yVKu9r1xSYaT5zDPPRAWU8MU0r7322jDPPPOEBRZYIC7677vvvsH78Z4orGQJv15bXuSJ7FZv1RQbrRTliVd5y7yelVE80hev\/MiX\/AmXCDC233772GgpJ37lVok\/9rGPhUsuuSTKV\/nJJYVzVZ8Ar5gnjYZ0+aOXX345nHfeeUEZ+ImbOzf1l7uyK98tt9wSZcIfmA855JDg6rk9mcsHQwpyrAOWgGXyAlQYBeKnhSNkieu5uCnQsFatocqmNU8vXli8wlCMQDdAKoBwiBbSdYkllnCpJJU1xYNBJSd8L85zmeTXS7zggguiQAhS2vIgj\/fdd18ov5xyHF19HjRoUKyY5ELArkku5CBPVTJ87bXX2k1KGZUVcLWEqUIIlOLlp\/KtuuqqnCOloRM3fnjkQb6efPLJ4B2pAPLtParwZKYxFcHYsWMrZUSG5IpUSr1YqnTCFQl4pCdd6cuH\/KjI8lfkBUzPO+64o0vAL5x8kmd0bPDz\/PPPxwa9vXec3oWGRIOiTolOXVIf3KunZOC+SBoW78C7aE\/m6rX6LR\/tAotgnn322WIasYWTMS+io0ohIKETvq6z2ILw6ylKFaan4q+KV4UjUJWGgMnHM972ZPif\/\/wHS0PSkhtyaEm9tMQIDOV4qxonQCT7cvgUj6sKP3LkSLdxqItXGK1zdCz96EX4d\/Z9yneKU35K0cXHVNHjQ+sPwHuPGkXAaXXqkX9lVBZ1VF2tSiTJtQoPya8YjlzaBZbK8vGPf7wYJiikwir0HHPMUedXlbBWRysA8Ykgvy5gJx4UWtpYkzBcPXeG0ovT+mn5VQ6tl56wM+E7w6PFw6dVIyPPHcnQ8FuYRnT22WdHL0MV8ku9nopXfjepjDHA1J\/U2gqL9DTCTvVuu2i5+UsnyYRyg7zamFpvAN2wUz7K\/K3elf9ApbHBj\/QQRg5F5nIF1XBonDTi3lORt9F9Kr88p3fciJe7+nrWWWfFIaY6Ko\/yyq+Kqt5lSrPIbxjbLrAUbODAgbEVkwHPumyVXGucXpBWWteO3OvutYKGeVorGZawyqzACu65s6SCetkqrDCuAGu44Lk9MkQ1DEhDCnmRJ3lL4ZJwxJvc2q5duElpaZWl6VlwaUmTu+eiDMuNE\/8iFSscuSlH8ucnXmUq+0lbHgzFVCCA0POZ83g33pH3qQIL6714Pyq8\/KlgGs\/0jlOaKrnKnp7xqg\/puXhVEdUTdULdkA+KAuS+yOsde04NiTIpm3zKL79GlMpKNsqSwpJ7ozDc5a\/YOMmjvPJrRO3JXH1UL9WjhsC65pprwhZbbBF7KAKGws9\/\/vNRW6UV1MKlxOeee+5g4qk7JXT+\/PRMwpms6m61dCbnHQlK2CJ52XvssUdQMbsaD+F9\/\/vfD3oQlUVe5E\/e0gtJ8T788MPFZKe596K8bPNIFbXMIC0ViburZ\/fSIgdDBPl3lYeiDPGhlCc8KrqegUzJNk2M5UHlEZ6\/MsmT5RJxIGlL070XLjweYbgpC5kYBXgfJuhJDviB7oQTTgjiSZVeHNI1bEy8zN80egnARV4jCul5d8KW45WPRN6xOZs6QkbKpGydmQvLY6N3nOJvdDWnIwd1wxLTkCFDolofyKrCKI98yR95FmVOjpQsAF4JLBoUtoGnnXZaOPzww9u6SsOEtdZaKxBsMdFFFlkkaLl082NbJ70SSP4qFXdUHAIkd1e8Mlz051Yk\/uJART7hublKV\/qGO4SdwntpwuBD4uKHBy839Lvf\/S5qKMXF35W7a\/FZXOLkViZxC+Na9BMH90TJP+VBPtwj9\/hUqlQmz6ls7sUnfjye5Wm11Vbj1EbFuPDgTZ4qkh7Ne+MmPjyJpCVtfsoqfn745N09Ukf4ybP0yrzCF\/mL8fIrUjGsuIv5lRdhi27thZUmf3mSN+S+HE8xzauuuiog5eEuDvlQZnElkgfu+MoyT\/FXAovRLVtB3X6KzNXz22+\/HY1yPWeasRIwrNO6uxpaUWYYXZSHb1W5VMl23nnnOALRs1TxZLdpJUDWnZF5JbDmm2++sNBCC0WL9qT5++9\/\/xt+85vfhHnnnTcY+kkyoTO1Btwy9Z4EUovqCijeA3LfmVxoibW8rp3hzzwhkDWZuZIzeSP3RflUAmv22WePFu1PPfVUWH\/99eMCoznDbbfdFreTWDQuRtLRffbPEpjVJFAJLELQM5144onhwQcfjMAynmTWVNSi4Gs26WYzLdZm5pVl0bOyWOSLXw\/zfffmSLdN6tj4vLP1vRJYNjuyXqe6pMgQWVLLcuOHh3tPkK420+NRkdJZOXgPneXNfO\/L1vYosms2VQLrxRdfDNSJNIAjRoyIB8wwll1jjTWC50033TTawDU7Mzm+7kvgxhtv7H7gHLLpEqgElmHg4osvHn72s5\/FYaA1ijvvvDMcf\/zxYaONNgpprtX03OQIswR6WQI9lVwlsPRYVLef\/exn29Kt1WrxDIxHHnkk8C\/6tTHlmyyBfiaBp158o0dyXAksK+nUh9Y30lzKCjN7qnfeeSfQCk6YMKHbGaK6t+\/LmkC3I8kBswT6sAQqgcUw1AEyLC2szjNl+sxnPhOtMJiOUMMfeeSR3S6W9TCr6N2OIAfMEmiSBJ568f3dBUPmG9ikWEOoBJbYmSldfPHF4a677gqXXnpp+MMf\/hD+9Kc\/xZ2UzD1uuukmbF0mPZ352te+9rWGYdlpZXoidEUGdsh2hT\/zviffS64ZG+shUKH40ISfhsASNzOZN954bwxqKPjoo4\/GrePU7fy7SqygWS\/b7dmeVTdD1EzD4pFznZWDhrCzvE3m61I++1LaA+ZeKLw9eOmuVuNO8TcElm0ijj9jrJmItbttJIaKnYq9wASYrJcNK5daaqmCT77NEpgxEigqLkauulBTM1EJrBdb17GY7\/s4Atpzzz3jUdNOwV122WXjVoKu5oLN4a233hoPSGFNYFsEsjWiq3Fl\/iyB6ZUAUO110UMxmtlefyGsufg88b5ZP5XAYsFeq9UCI9v5558\/PPfcc8GQ0J4aa1iA19UMzDnnnIGxYlr1tx8JMcHvalyZP0tgeiQAVCNOuTe4imf2Fx4Jay3RC8BK6na91gc+8IF4IAtw2RQ3ZcqUkFTwMpUpS6C\/SACQjrruybDiT25vAxWFxaDxZzW9CJU9ljkUtbpvZDk+TE\/l9J6tt946ftrHMV3TmxNm92h645k5wudS9JQEgOnCu58LI0bfGwF11HVPtCXVssGwMOH\/1mh7buZNJbAkQHvDhMmcihmTrejOA9hll13yxxEIKFOflAAgIT1TAtOeFz4UbntsSlt+9VJA1bLB0Da3Zt9UAosFuwM\/XFOChoR6r2222SYeFpnc8zVLYEZKAIj0SMCTgGSop2cqgkkeAWr0yGVjL9WToJJWHbAAyWk91OvMl1xp8BKxdrf+1Jmt3yLPlCXQLAkAkP1SRRDZRwVEQMW9CkhrtWr7WqYO+Qz7Rq66YLOy1G48dcCiBWRqxDLCNhHXpMVL1zPPPLNb6vZ2c5E9swRaJVAEj6EcwOiFEoBo8rhVgag1eNAjARLwjPn2SrFnGrPnSqGldcjHD09vUR2wUqJU7D\/\/+c+Da3Lr89ecwT4vAcBBgIGABHBQGTyGcnjKvVAqJKAkEBneFYHkudnq85RuZ691wEpDwTT0q7oaKuLrbAKZb9aQAMCgNFwr9jhF4KShG1Al4DQCD8k1ApBhnd4IiPRQMxpI8lqkOmCloWAa9lVdDRXxFSPJ9zO3BIqAAYb2QJOGa8UepyPglMEDLHqgF48b3jac45YAhL+vS7wOWOXMsoCmcndCqG8E5Z6qLKH++wwsKPUwVYDRu5SHaHqazoKGdIAApWFbS6siAUgAR6+TqNj7JAAJ31+pIbAcMW1rh15L4fRU1rO4e87U9yQAKAhYUBEsAGFIVgSL+9TD8C8DRlztlRJgUAINQCTQAE7qcYAnAaelVZGAz9BN2Pbi789+dcBKBXEy07nnnhtOOumkSD\/96U\/jx+dOOeWUeIindCboggAAEABJREFU7R+JN197VgIqN0pAaQSWlU96z1QngSUBJoFFOEMycXWUYxUelQGTQAMoVaDhn0ADOB2lMzP7VwLLEdMKzfrCNZFnBrodfdMp8efrtBJQsRGgIBUe6TGQXgUBSBqGuU9AwdMdsMgJsKDuAiaBRhziy9RYApXAcoS0k5psoXc+heAMbw0D2REy0uWWKURjzu4CpQgW4EJ6FSTOzshXJUcrLzwwqPiopTCPMSTrqIcRRg8jns6kmXk6lkAlsBwWc\/DBBwf7p2zDtzlxxRVXjMPAgw46KABXx1H3Tw4VGhV7k6QF01voTZBepNyjNBMoehWk0iPDLAQoqAyW07+yYOCPWgrzmAyYGVMPK4ElK46SLp55QXmhx1pyySV511HaHeyTJp\/73OcCpQeNYh1T6wOtonWwtD7mnlurV4\/\/AwtKgElgARJUBRRAQuWhV3d6FCBBQIIAAAEJKgPFZB\/hQcIgQEGzWu\/S4xWkyQlUAktltw3\/xz\/+cfjXv\/4VLTB8gaRWq1UmP2nSpODbUmPGjInfyfJhrvTRs2IARrzrrLNO29HJwNoTa2JFAAFGAg7wpF4lgQVIkDDFvDa6V6ERkCCVHan8CEhQBkojCc4a7pXA+uhHPxq\/m2RI+PWvfz04WtqpuE4C0juVRWN\/lv1bvp\/Fzw7jdO85Efe55porPTb1ChjmKAlECUDcAKdRYkCCgAQBScvUOUoGSiOpZfeOJFAJrAEDBgRDvpaWlnictK\/cLbLIIsGHyjbffPNQPqWJosP3bZ0f7mhqh8b4\/E85cWp6cfmuLEt5Xy+hFCnzGUZ2lsbdNzF8\/6L3NrHpnapA9PG5Zg+bLjtnpFHrDg7mI+jPew8Nl2+3YKQTN54noANWHxi2XurdsPrg\/0RaeMBLAf3v5cldOo6ss\/lvFp9Gr1lxzUrxmJaU618zniuBlSJW6SdOnBh8V5VV+5QpU4J5VCPlhQ+YPfbYYwEgjzrqqOD4tBSXqxOeRo0aFc8qdEjNFVdcEYHLr0jU+p0hx1ftedUL4bS7phSDBz2QXseQzHrLg6M+H87eZdVI39n402HLtZaN1Jk0+guPhq+\/5LUv5TMZQNRVoCY8VALrlVdeCbR\/NIE2PJobjR49Otx+++3xw3MOhimm7YAZ3yrmVqvVwsorrxyshfn0D7dEw4cPDzSMtVotztvs93rooYeSd5eulA\/mTIaAAiYwmdugllbNmEk+v0xRAvmnFyVQCSw91dChQ8Nll10WvzbiuGlDQ0PEqrzpwWzbB0BzsD\/\/+c9BC0rhkfgtLO+3337ht7\/9bcDz0ksvhfHjxwfgTTydvQIV5UPib2mdE+mdWlrBBGDJPV+zBGaUBCqBZc7koJf2wFTMsHPdN9544\/jtLIoOC8vf\/e53w+yzzx4Y7yL3PoQAWHoqh9OYh3X1qyXU5QlUQNTSCqqWDKji68j3fUAClcDqar5qtVrYfvvt49nutvRTXlgHE892220XkHtuFBZ2JjsHXpharVqFj79Mhn3pkEV+I1ddKO4OdZ8pS6AvSaApwOqtAumpgEt6I1ddMIOKIDL1SQlUAsscy5qTazHXnqvcizw9dW8IaE1K\/IaA1pjc9y7l1LIEOieBOmABjjUqX23cbbfdgisrjETOFnSuIGuMzkXfPK6jCwctnrzNss2LOMeUJdADEqgDlt5o7733Drvuumu4\/\/7743XLLbcMib7zne9EKwzKjR7IS8Mo9VZp4Zd1RFajNxRV9ugjEqgDllOZKBeuvvrqsP\/++wfXW265JRTJ10Ec3tmb+S\/2Vge2agF7M+2cVpZAdyRQByxDQb2WdSlGuL4wkoaB6WqoiK87iXUnDGVF6q3MrXJv1R0p5jC9LYE6YAEVkyPW6oaEaQhYvHLH1+2MdjHguMKZ2yNb1etdDJ7ZswRmiATqgGUo6KBOH0IwJCwOAdM9d3y9ldsL75ock9JbtbQuBMeH\/JMl0MclUAeslFdDPUO+NPwrXrnzT7w9ea0bBs47sCeTynFnCTRVApXAMtQz5CsOAW1QZK5EY8i\/qbloEBlgJa81l5g33eZrlkCfl0AlsAz1DPnS8M+V+t0Hv9n59Za6vagNXHPx5n7Kss+\/mZzB3pdAE1OsBFZV\/LVaLW4HMRTsrR4r5cP8KmsDkzTytT9IoBJY5lAAVJxbub\/22mvjR+eo43u6cIaBbWr2PL\/qaXHn+JssgUpg6ZHKcyzzLVs+uPfGuYKAlcqaF4WTJPK1v0igElhVcyzzLPMu51V0t3DPPvts8KlVe7Ack3bGGWeEdCBoOc7i+lXZLz9nCfR1CVQCS6YdKDJy5MjgiDLPZ599dtyub4jouTsESBtssEHclXzllVdGUylnalTFNW7SS9E5z6+iGPrNT87oexKoBJaz2Y844oigV3F+BdYRI0aED37wg8EHEmyz59ZVct7gZpttFmq1WjwTwxb9qmGlk5fS\/Gr+D4c+fTqSBqgvUD6l6Ylu1ZNePaXJMWVOWHKibTo4horddv3JkycHc7Cuggq\/46qB0wE1a6+9dlhuueXCggsuyKuO3p1j\/rbndT+1UOhLp\/r01bw4Y6Sv5q0v56tXT2kaNGhQYMHuUJi2Gt568+STT8Zea3q0goB6wQUXBHFbGxs7dmxrzI3\/8\/pVY9lkn74rgcqhoMrvMJgf\/ehHwZFl7h0WYz\/WN77xjVA1fOuoiK+99lrwZch03Jke0GLzpEmTpgmaFRfTiCQ79DMJVAJLGZxsqzcx12LO5Ajpm2++OXzpS1\/i3WVyXLW5m2PSzK0cfzZhwoRQpWUcN2srLros2xyg70mgEljmUTSCzgnUqziqzEGb3empUpHT8WfOKlxzzTXDJptsEpyc6+i0xJOuT730RrwdkheGoxzyT\/+TQCWwKBTWW2+9eLQ0RUaziuX4M\/MrR5+NGzcuHplWq9Uff\/bOoMHxY27NSjPHkyUwIyRQCSxrVdat7M0yJKSSTNTT37R6Z9BH2+SQLdrbRJFv+pkEKoHlm1XmV1SRZeLOv6fKqcdKcWeNYJJEvvY3CdQBi\/GtNSpmRnothrdl4o6vpwpaBFb308ghswRmrATqgAVUo0aNCpNaVeCMbRnelok7vp7K9tuDl26LOm8VaRNFvulnEqgDFuNb86q+cOYFG8F+Jsuc3SyBNgnUAavNtfWG\/RuVuzlV62OgzPDNLENBzz1FqcfKqvaeknCOtzckUAksC7kWhptthNtRgYp7sBadb2BH7Nk\/S6DPSqASWNauXn311dBsI9yuSGHIfB\/uCnvmzRLoUxKoBFZPGuG2V\/pijzUk91jtiSr79XEJVAKrJ4xwOyOHovHtotmcqTMiyzx9VAKVwJJXFhcUF+ZazTDCFWdXKPdYXZFW5u1rEmgILBllkd4sI1zxdUTjplq148vAIoVMlRLoB47tAmtG5T+DakZJPqfbLAk0DVgs1g0ZV1tttWBT5IMPPjhNHplHMeJtZNCbt4tMI7Ls0E8l0BRg2bR40kknhWOPPTbcddddYY899ggsOKyHFeVifxfwJcNec7iiQW9RK1gMl++zBPqbBBoC65lnnolAsZ2+SEcddVR45ZVX6srJGmPo0KFhySWXjO6f+tSngu8UWw+LDlN\/2BjONddcU5\/qL0VQzfvBt7t14g5rkVmV8ilN\/eSUJudcPP300\/Gbw3b8JjLUc9BMERZLLbVUoD2kpmcZb5cwu8O55567yBYA7aqrrorb8ddaa63gANAqS\/nlhsyfT2YaNqxLMujqKU19+eSk3syb0VNdJW3SQ2WPZQhXq9VCS0tL2HTTTYOt+YkcLtPolKZHH300bL311uGRRx4Jhx12WKBVLOZz4MCBgfW84eLll18errjiinDbbbcVWeL9SUccEtI8LF8X65QsDLGzrDonq7KcYqVr8k8lsOabb77YWjrurDPpORzmnHPOCXvuuWfQ0\/3iF78IeqxyWKB0dkatVov+VPnp1CaawBePGx4m\/N8a4e9\/PDdoSTI9nuXweO\/IoFxXp\/d5tqoIXn\/99Xh+IKD40FxHcyzje0O8008\/PQDOgAEDponW6bn77bdf8GEFQKTwGD9+fFhxxRXreAGsziE\/ZAn0QwlUAssc6otf\/GL4yU9+EhwJneZXrlVzrEmTJgXq9R122CE44Rb5+AGlxvnnnx9QOqUJsPRUhpbrr79+8IGEfii3nOUsgXYlMFuVrzmUYZvKXybu\/IvhuBnS3XrrrfFDB+nLJIaD2223XUD4ndJEYXHnnXcG617bb799PMedXz+knOUsgYYSqAQWbme3U63bk2VR15rT8ccfH7jzz5QlkCXQWAKVwDIfOvLII4O504knnhgWWmihqMygLj\/88MMD\/8ZRZp8sgSyBSmBRLPztb38LjpX+xCc+EWabbbZAVf6tb30rgo1\/Fl2WQJZAYwlUAotWT6+khyoGffPNN+OciH\/RfXrvLSobdjrH3cLxDTfcEGgOpzfemS08mVjWoEAiJ+eQVC2wk19xreaAAw6Y2UTR1PL48s2hhx7a1DgrgWUdyxHT3\/72t4Mjodn4+QLjXnvtFbzQeeedt0mZeC+aa6+9NvaEFBqUG7\/85S+jSdN7vvk3ScDyxPXXXx+uu+66cM0114Sbbrop3H333cm77Wq0YekjrQOy4WzzzDdtElCvfUjRspIlpjaPJtxUAku8O+20U7QV9HLeeOON4Kz1\/fffP3zzm9+MvRaeZhHFCIt4av6FF1440B6y3mhW\/DNLPEBkeULD5gMVevh77rlnmuKpMGVzsmmYskMw8lpllVXCFlts0XRpNARWrVaLi7dMkKw9sVb3CR+ZaWYuaBnN2QYPHhyjrdVq0YRHqxsd8k+bBKwXsglMDosvvngoW8cYLgKWoY0vaG611VZxjTGFydf3JaCBspaaPgf8vs\/03zUElgVfn9mhbvftYON6yGY9Pv3J1scArD6hWu+an6okULa\/LPO89dZbAaDOOOOM8MADDwQfC\/QBQYv1Zd783HMSqASWXuSYY46Jwz4fimMo6yUx9GSNwUi3WVmaY445Aqv4Z599NkapxQXepZdeOj7nn\/clMHTo0PDYY4+1Obh3anGbQ+sN4LGAST0bkzHyfe6551p983\/nJTB9nJXAMpGjqdNj6U0kYf7Dch2oytpC\/t2lWq0Whg8fHsyzpGkf2PPPPx+WWGKJ7kY504ZbY401wr333hu333gH7gGnWGBbfQz\/gI77ww8\/HMyRE9C4Zep5CVQCi1ZwmWWWCUyP9CApG9SSFAv8k1szrhtuuGEw3qVx3HbbbWNPueiiizYj6pkqDl+\/ZAWz0UYbhQ022CA2SNwUkj0mIjfa3B133DGwyTRHPvjgg6N88WXqHQlUAosyQWtIC6iVZFSr0u+7775x\/xQlBrdmZVFvaO8XILMz1IM1K+6ZKZ5arRYM8wzNLU0UbS3ZYyLlJT88d9xxR\/j9738f7OjmnqlaAkZmzV6SqASWMblJL9vAQw45JI+R6qYAAAatSURBVG54ZIVx3HHHhfQMCNXZzK5ZAlkClcBiva7VY9luf5X1Eqj2XKQsviyBdiUwC3tWAos8aOl8FMHk2Fh9ueWWC8buWW1LOpmyBNqXQCWw2ASyYtdbsYBgfXHfffcFC5JMQNgRth9t9s0SmLUlUAmsl19+OR5fZmGYYoGIzLt8iG7y5MnBMWbcMmUJZAlUS6ASWBYZWUJYTyoGc1Yg9btt9kX3\/n5\/6qmnBtRROSyS77bbbk3d7Em7t\/zyy4euWKCzXu8Kf0flmh5\/eWFJbxnAScfTE1dV2BS\/ZRiGC1U8fdGtElgMOPVOKpE1EAfF2NbBANf6SbPXsfqiYHorT\/fff39gr9ZI3dsT+dA4Vm036W5a5uDU+sVTjbsbVzkcpZmdFYyOy359+bkSWDJsEfLiiy8OjGNvv\/32uD\/qzDPPDDvttBPvfkcqkwZCJTBXdNgNBY0W8eijjw5Ir4XvvPPOC3oRfKzu2U1qjW2bsW3DyVVaT4ocjY0TgMV78803V8qFRQnbPXHidUQcy4mUtgNOq3og8e+9997xhGHxq7wpAcN1SyLySFPLDIyftJTFAr+0rHUpJz9pALC5s7zidTQ4XuuUP\/zhD9t6TnJw9iONsHhSnsXTiMhEY3zCCSfExWnxyot0ymGUvdgLlZ\/L\/P3tuSGwFMSJpI4so7A46KCDonFnrVbj1e+IrRzAnHvuucHBoiqSyq5FPPDAAwPafffdAwtyLSTCB1i\/\/vWvg9b45JNPDvap2evE1EtvvtJKK4W\/\/vWvYfTo0RGcwpSFo9LceOONcQ+VHspQ2xoh20vpIhW+GI6CiF2mA3mEAYBTTjklMFnCN2HChPDVr341Ho7q9CwbILlbZDdk1RgKt+CCC4YxY8bwimSbiQZGue2DsxUFLxBRUkWm1h8LzBpSjat4Up4BrtW74b8Gg4WO\/WLKbagrnYYBZlKPdoE1M5VZRbWdwim87B31PlrochkZugKOK7555pmnzBKf9RB6FJWbgodpEYNYIIsMU3+kq6fRQ9prZo3QvU2L8jOVbZqLHvKpp54KhuTCAPCoUaOiwTJm+7IAynzXzgMVmrseBsiZiOkpDOu5J5I2PwDRa1FQeQZgPUjiu\/rqq8Mmm2wSt\/BIX7iJEydOc25\/4k9XxzgwpxIn+0R2i+xAk\/+scp1lgMWGzgm9f\/zjH4OtMHoiJj\/lF81g1fHYKqtKzcSqzOPZHEULr3KbvBuSXXHFFUHPyD+R+GhRaVWTm0qnB1C5k1v5SlEElAkYAAQ0wuJ1Bgk390USzlAV8AzbLZcU\/VM+XnvttZjX9IxHA+GKgNIwTtmQLUOAbimGfyOyW2GBBRZo8y7etznOAjezArDia7RMoFXXG7GDdDDOaaedFlSwyDD1x7BJpTKEMWRSoaZ61V0MBfVQhlYAhgzPVOYio8o6aNCgOk0ibauWHbiKvMV7wPEMmK56z1\/96lfxCAPPjcjwFgA1Gpdeemmc61Txpnwpa\/I3R0r3\/DUwyoUAVMOhZ0s8VVf5Nf9LfobWVYoH5ZNG4pvZrrMMsFQaR7p50eklqtip1dc7cFcxtMqezWfOPvvs8M4774TUu7jHN2TIkPjRB\/MHvZchICPY8hxLGsOHD49fVjF0lA\/neuhRUm8kvjIZRjl2zjBSXsxXgF58Zd7ic8q\/PFG6mDsJX+RxLx6G1M40YXTtqDtzKn6In4bFNh6gtoNcDyZe\/o0IUM3LfOrJcFmenapc5qdZlldxC+McjzJPf36eZYBlf5fjss2JaLn0XOZZKhjrb70XrSAeL3qFFVaIH3jYeeedg9b\/rLPOChQBwGGo5aWzTlFxfMYI3z777FNpSW4fmzkYbZwzFoCUNlEcjci8ZlTrnGrs2LHBpk\/zJobPHfUY8uZ8Er2pMtEqUnqYT5XTMr8CYMPebbbZJliLSjyWAAyXaYdpMw0DKVlSQ5T4qq6Gg3ZAjBgxIp4nYeiNj3zN4zQu3gGZSMMSjiFu6tkoXwDbVbj+SLMMsGq1WqB6puEytNHTAJSXRkPoJdIKWl4w5NLzXHLJJXGNybAQEFRqwyGtvLmJSqn3sakQ+GjaarVptaaGPCqlTYfILoFUiaSJ5KNM9r6l+OWXyh2PdIpaxOLzsGHD4lYRigaaxM033zxqLfWawuAVB9L70mzipQXU+MgrP0NdW1TIi7+DW1V+fh2RNAyRyXSXXXYJKU7lTLLjpqGglXTalA9vaAjI1dEC5rauHaXVV\/1nGWD11RcwI\/OlkusVDcf0xNbTUu8yI\/M1M6T9\/wAAAP\/\/9h7tnAAAAAZJREFUAwCm7tB7O\/G9tgAAAABJRU5ErkJggg==","height":129,"width":214}}
%---
