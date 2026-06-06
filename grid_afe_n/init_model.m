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
trgo_dab = 1; % double update
fpwm_psfbc = 1 * fpwm;
trgo_psfbc = 1; % double update
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
dead_time_psfbc = 3e-6;
dead_time_cllc = 2e-6;

glb_time = timing_setup(fpwm_afe, trgo_afe, fpwm_inv, trgo_inv, fpwm_dab, trgo_dab,  fpwm_psfbc, trgo_psfbc, ...
                fpwm_cllc, trgo_cllc, t_measure, tc_factor, tc_decimation, delay_pwm, dead_time_afe, ...
                dead_time_inv, dead_time_dab, dead_time_psfbc, dead_time_cllc);

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
application_voltage = 480;
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



%%
%[text] ## Global Hardware Settings
single_phase_inverter_pwr_nom = 225e3;
afe_pwr_nom = 250e3;
inv_pwr_nom = 250e3;
dab_pwr_nom = 250e3;
cllc_pwr_nom = 250e3;
psfbc_pwr_nom = 275e3;
fres_dab = glb_time.fPWM_DAB/5;
fres_cllc = glb_time.fPWM_CLLC*1.2;

hwdata.single_phase_inverter = single_phase_inverter_hwdata(application_voltage, single_phase_inverter_pwr_nom, glb_time.fPWM_INV);
hwdata.afe = three_phase_afe_hwdata(application_voltage, afe_pwr_nom, glb_time.fPWM_AFE); %[output:4a50f0a2]
hwdata.inv = three_phase_inverter_hwdata(application_voltage, inv_pwr_nom, glb_time.fPWM_INV); %[output:2db503b0]
hwdata.dab = single_phase_dab_hwdata(application_voltage, dab_pwr_nom, glb_time.fPWM_DAB, fres_dab); %[output:398e68dc]
hwdata.psfbc = single_phase_psfbc_hwdata(application_voltage, psfbc_pwr_nom, glb_time.fPWM_PSFBC); %[output:50ab329d]
hwdata.three_phase_dab = three_phase_dab_hwdata(application_voltage, dab_pwr_nom, glb_time.fPWM_DAB, fres_dab); %[output:58c3d75e]
hwdata.cllc = single_phase_cllc_hwdata(application_voltage, dab_pwr_nom, glb_time.fPWM_CLLC, fres_cllc); %[output:1998f882]

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
%[text] #### UPQC Series Transformer
name = 'UPQC Series Transformer';
pwr_nom = 250e3;
u1_nom = 690;
u2_nom = 690;
f_nom = 50;
eta = 98;
ucc = 2;
p_iron = 5e3;
n2 = 8;
n1 = 8;
core_area = 0.04;
core_length = 0.25;
mur = 35e3;

Lm1 = (n1^2 * mu0 * mur * core_area) / core_length;
i1m = u1_nom/sqrt(3)/Lm1/f_nom/2/pi;

delta_star = 0;

upqc_st = three_phase_transformer_setup(name, delta_star, pwr_nom, u1_nom, u2_nom, f_nom, eta, ucc, ...
    i1m, p_iron, n1, n2, core_area, core_length, mur);
upqc_st.Lm1 %[output:5c827f36]
upqc_st.Ld1 %[output:1328f9a8]
upqc_ctrl.kp = 2;
upqc_ctrl.ki = 18;
upqc_ctrl.lim = 4;
%[text] #### DClink Lstray model (partial loop inductance)
parasitic_dclink_data; %[output:502f41c7]
%%
%[text] ## INVERTER Settings and Initialization
%[text] ### Mode of operation
motor_torque_mode = 1 - use_motor_speed_control_mode; % system uses torque curve for wind application
time_start_motor_control = 0.25;
%[text] ### IM Machine settings
im = im_calculus(); %[output:58b41b2c]
%[text] ### PSM Machine settings
psm = psm_calculus(); %[output:0fd658eb]
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
psm_ctrl.ekf = ekf_pmsm_setup(psm.Rs_norm, psm.Ls_norm, 1e6, glb_time.ts_inv); %[output:623dffc8]
psm_ctrl.kp_i = 0.25;
psm_ctrl.ki_i = 35;
%[text] #### Induction Motor Control
im_ctrl = ctrl_im_setup(glb_time.ts_inv, im.omega_bez, u_im_scale, im.Jm_norm);
im_ctrl.ekf = ekf_im_setup(im.alpha_norm, im.beta_norm, im.gamma_norm, im.sigma_norm, ... %[output:group:43a7054c] %[output:578aead0]
        im.mu_norm, im.Lm_norm, im.Jm_norm, glb_time.ts_inv); %[output:group:43a7054c] %[output:578aead0]
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
psfbc_ctrl = ctrl_dab_setup(kp_udc, ki_udc, kp_idc, ki_idc);
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
sogi = sogi_filter(omega_set, sogi_delta, kepsilon, glb_time.ts_afe);
%[text] #### Current control parameters DQ PI
dqvector_pi.kp_inv = 0.5;
dqvector_pi.ki_inv = 45;
dqvector_pi.pi_ctrl = dqvector_pi.kp_inv + dqvector_pi.ki_inv/s;
dqvector_pi.pid_ctrl = c2d(dqvector_pi.pi_ctrl, glb_time.ts_inv);
dqvector_pi.plant = 1/(s*grid_emu.trafo.Ld1 + 1);
dqvector_pi.plantd = c2d(dqvector_pi.plant, glb_time.ts_inv);

G = sogi.fltd.alpha * dqvector_pi.pid_ctrl * dqvector_pi.plantd;
figure; margin(G, options); 
grid on
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

diode.rectifier.Vf = 0.75;
diode.rectifier.Rdon = 29e-6;
diode.rectifier.Irm = -135;         % A
diode.rectifier.didt = -135;        % A/us
diode.rectifier.trr = 15;           % us
diode.rectifier.Qrr = 0.95;         % C
diode.rectifier.Ifm = 1000;         % A
diode.rectifier.Rth_JC = 0.025;     % W/K
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
used_device = 'infineon_FF1200R17IP5';

igbt.inv = device_igbt_setup(used_device, glb_time.fPWM_INV, hwdata.inv.udc_nom);
igbt.afe = device_igbt_setup(used_device, glb_time.fPWM_AFE, hwdata.afe.udc_nom);
igbt.dab = device_igbt_setup(used_device, glb_time.fPWM_DAB, hwdata.dab.udc1_nom);
igbt.psfbc = device_igbt_setup(used_device, glb_time.fPWM_PSFBC, hwdata.psfbc.udc1_nom);
igbt.cllc = device_igbt_setup(used_device, glb_time.fPWM_CLLC, hwdata.cllc.udc1_nom);
%[text] ### DEVICES settings (MOSFET)

% wolfspeed_CAB760M12HM3
% infineon_FF1000UXTR23T2M1;
% danfoss_SKM1700MB20R4S2I4
used_device = 'danfoss_SKM1700MB20R4S2I4';

mosfet.inv = device_mosfet_setup(used_device, glb_time.fPWM_INV, hwdata.inv.udc_nom);
mosfet.afe = device_mosfet_setup(used_device, glb_time.fPWM_AFE, hwdata.afe.udc_nom);
mosfet.dab = device_mosfet_setup(used_device, glb_time.fPWM_DAB, hwdata.dab.udc1_nom);
mosfet.psfbc = device_mosfet_setup(used_device, glb_time.fPWM_PSFBC, hwdata.psfbc.udc1_nom);
mosfet.cllc = device_mosfet_setup(used_device, glb_time.fPWM_CLLC, hwdata.cllc.udc1_nom);
%[text] ### DEVICES settings (Ideal switch)
used_device = 'silicon_high_power_ideal_switch';
ideal_switch = device_ideal_switch_setting(used_device, glb_time.fPWM_AFE, hwdata.afe.udc_nom);
ideal_switch.afe = device_ideal_switch_setting(used_device, glb_time.fPWM_AFE, hwdata.afe.udc_nom);
ideal_switch.inv = device_ideal_switch_setting(used_device, glb_time.fPWM_INV, hwdata.inv.udc_nom);
ideal_switch.dab = device_ideal_switch_setting(used_device, glb_time.fPWM_DAB, hwdata.dab.udc1_nom);
ideal_switch.psfbc = device_ideal_switch_setting(used_device, glb_time.fPWM_PSFBC, hwdata.psfbc.udc1_nom);
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
lithium_ion_battery_1 = lithium_ion_battery_setup(nominal_battery_voltage_1, nominal_battery_power, initial_battery_soc, glb_time.ts_dab);
lithium_ion_battery_2 = lithium_ion_battery_setup(nominal_battery_voltage_2, nominal_battery_power, initial_battery_soc, glb_time.ts_dab);
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
%[output:4a50f0a2]
%   data: {"dataType":"text","outputData":{"text":"Device AFE_THREE_PHASE: afe480V_250kW\nNominal Voltage: 480 V | Nominal Current: 360 A\nCurrent Normalization Data: 509.12 A\nVoltage Normalization Data: 391.92 V\n---------------------------\n","truncated":false}}
%---
%[output:2db503b0]
%   data: {"dataType":"text","outputData":{"text":"Device INVERTER: inv480V_250kW\nNominal Voltage: 400 V | Nominal Current: 470 A\nCurrent Normalization Data: 664.68 A\nVoltage Normalization Data: 326.60 V\n---------------------------\n","truncated":false}}
%---
%[output:398e68dc]
%   data: {"dataType":"text","outputData":{"text":"Single Phase DAB: DAB_800V\nNominal Power: 250000 [W]\nNormalization Voltage DC1: 800 [V] | Normalization Current DC1: 350 [A]\nNormalization Voltage DC2: 800 [V] | Normalization Current DC2: 350 [A]\nInternal Tank Ls: 1.697653e-05 [H] | Internal Tank Cs: 2.590412e-04 [F]\n---------------------------\n","truncated":false}}
%---
%[output:50ab329d]
%   data: {"dataType":"text","outputData":{"text":"Single Phase PSFBC: PSFBC_800V\nNominal Power: 275000 [W]\nNormalization Voltage DC1: 800 [V] | Normalization Current DC1: 350 [A]\nNormalization Voltage DC2: 30 [V] | Normalization Current DC2: 12000 [A]\nInternal Tank Ls1: 2.314981e-05 [H] | Internal Tank Ls2: 5.787452e-08 [H]\n---------------------------\n","truncated":false}}
%---
%[output:58c3d75e]
%   data: {"dataType":"text","outputData":{"text":"Single Phase DAB: Three_phase_DAB_800V\nNominal Power: 250000 [W]\nNormalization Voltage DC1: 800 [V] | Normalization Current DC1: 1050 [A]\nNormalization Voltage DC2: 800 [V] | Normalization Current DC2: 1050 [A]\nInternal Tank Ls: 5.333333e-05 [H] | Internal Tank Cs: 1050 [F]\n---------------------------\n","truncated":false}}
%---
%[output:1998f882]
%   data: {"dataType":"text","outputData":{"text":"Single Phase CLLC: CLLC_800V\nNominal Power: 250000 [W]\nNormalization Voltage DC1: 800 [V] | Normalization Current DC1: 350 [A]\nNormalization Voltage DC2: 800 [V] | Normalization Current DC2: 350 [A]\nInternal Tank Ls: 6.880327e-06 [H] | Internal Tank Cs: 6.391587e-06 [F]\n---------------------------\n","truncated":false}}
%---
%[output:5c827f36]
%   data: {"dataType":"textualVariable","outputData":{"name":"ans","value":"   0.450378722818633"}}
%---
%[output:1328f9a8]
%   data: {"dataType":"textualVariable","outputData":{"name":"ans","value":"     6.061893472484110e-05"}}
%---
%[output:502f41c7]
%   data: {"dataType":"image","outputData":{"dataUri":"data:image\/png;base64,iVBORw0KGgoAAAANSUhEUgAAAU0AAADJCAYAAACnpmC+AAAQAElEQVR4AeydC5xVU\/vHnx15J6KL0sVbpiTykomGJtFF6YKK1NuE3N7S5Y2Exr2ipBJ5FXJLSfWmF9VfIVRMulK5RdJFd9EF3ST9+y7t6TTOmTln5py99jnn8fHM3mfvtdez1m+f8+tZaz3reYoc0P8UAUVAEVAEwkagiOh\/ioAioAgoAmEjoKQZNlRaUBFQBBQBkZiTpoKsCCgCikAiIaCkmUhvU\/uiCCgCMUdASTPmEKsCRUARSCQE4p80E+ltaF8UAUXA9wgoafr+FWkDFQFFwE8IKGn66W1oWxQBRcD3CChp5vuKtIAioAgoAocRUNI8jIWeKQKKgCKQLwJKmvlCpAUUAUVAETiMgJLmYSxsnaleRUARiCMElDTj6GXFS1M\/\/\/xzueCCC+Siiy6Siy++WM477zxp3769bNiwIewuPPvss\/Lee++FVZ5yZ5xxxhH6HnroIfn1119l586dcu+998qyZcvCqksLKQL5IaCkmR9Cer9ACKSlpcn06dPlww8\/lAULFsipp55qPheosjAeOvfcc0396MvOzjZPPProo\/K3v\/1NHnnkEalRo4a5VpA\/Bw4ckP379xfkUX0mARFQ0kzAl5q7S7Y\/\/\/bbb\/Lzzz\/LSSedJPv27ZPBgwcbSxRrlHOuIYMGDZL09HRp0qSJfPrpp6bZENbYsWONxVqvXj1xLUhzM8SfYsWKyQ033CBffvmlfPvtt3LLLbcI1u8vv\/wivXr1kjp16sj5558vjz32mGkP12+99VZz7dprr5VOnTqZ8li73bp1kyuuuELmzp0rM2fONO2oW7euXH755fLFF1\/IDz\/8IG3atJE+ffoI7cOiHjNmjDRq1MjU98EHH4RopV6OVwSUNOP1zfm83fPmzZOaNWtK1apV5R\/\/+Ids2bLFEM7bb78ta9euFaxBZOvWrfL6668L19etW2csUz5DsnSRMgyt33\/\/ffnoo4\/kuOOOk8mTJ3MrTyldurSUKVNGIES34Pz586VatWqGANH3zTffyMaNG+XFF180lij3sU5\/\/PFH9xGhfePHjzd9effddwUC\/\/jjjw0pUwcFd+zYIbVr1zbtq1ixolDvjBkzZMiQIaatv\/\/+O8VUEgQBJc0EeZF+6wbW3GeffSYrV6401h5W2IMPPihz5syRFi1aSNGiRY00btxYFi5cKLNnzzbXsRKPP\/54Y7XRJ4gM0jr99NPNEH\/EiBGyePFibkUsDRs2NPOeEydONEN2yHjz5s2yfPlywXp0HEdOPvlkOfvss3PqbtCggdCeE044QXr37m3KPvHEE\/Lqq6\/Kpk2bTDksaKxmx3GkSJEipu1HHXWUQNx79uwRRPS\/hEFASTNhXqXFjuSjGgKpX7++IY\/du3cbsnQfYVgOgbqfcx9ZyIGsIF8Eouvbt2\/uYn\/5jIWIlYm16d586aWXZOTIkQIB33777cYCZvjPfCVkRznOmU7gPFBYxOratatghbZr1046d+4cePuI87z6c0RB\/RCXCChpxuVri69GQ0wMs1NSUsxcJqvdkCUybdo0Y+Uxl8k517Zt2yYMx+klc48MhyFACJe5Q4bp3AsllHvmmWfkzDPPNPOobjmGzZdddpmwSAUJQsBYtgypaR\/tXLNmjWAhu8+4x59++slYnMxlYkG67XPv6zF5EFDSTJ537WlPlyxZIs2bNzfzmBkZGWZYnpWVJW3btjXDVobrSKVKlaRZs2bSsmVLc51h8k033SQVKlQw7WX4DqFyZKgMYXFubgb8YeHI1Ue9kCGLPgFFjO7+\/fub4TNzjsy5TpgwwSz8QMR1Di4Q4Z5Urly5wMfMOXOhpUqVEizmDh06GEJeunSpGa6bAvonaRBQ0kyaV+1dR5kTZC4SIsIFiEUhFlCw6Bi6MtzmPsI51yC5fv36mfnNN954Q55++mmBHLnXo0cPoSzilg\/sDeW+\/vprsxCDvk8++USYPy1evLggDMlpE\/OOzKliVUKOw4cPlwEDBgiWLIRO\/U8++aSZl2RY36VLF0HQRftY6adu2gexQ7wQ9Lhx43IsWlbkaQ\/PoBPdtIHPKomBgJJmYrxH7UUhEMAxHhK98MILhflK3I5cS7cQ1eqjCYqAkmaCvljtVvgInHXWWfLWW2+ZKQQsVVbZw39aSyYbAkqayfbGtb\/BENBrikDYCChphg2VFlQEFAFFQERJU78FioAioAhEgICSZgRgaVFFoKAI6HOJg4CSZuK8S+2JIqAIeICAkqYHIKsKRUARSBwElDQT511qT5IZAe27ZwgoaXoGtSpSBBSBREDAd6RJigLiKRLYlVQJCOdc414igK59UAQUgfhFwDekSYQZ9ip37NjRxCkkRcGkSZMEYT8vhMn2tilTpsQv2tpyRSBuEdCGuwj4hjQJ\/UXcxddee01IMUDMQ4K7IlWqVBHI9H\/\/+19O9Bu3A3pUBBQBRcBLBHxDmkTGJgoNUbRJjUBMRKLHEEiBI58hVcKEeQmQ6lIEFAFFIBAB35AmeVQIMHv99debpFWE3iIpFUFoCdn1+OOPC0P4wMbruSKgCCQMAnHTEd+QJtG6yexHtBmG6KQcIPNg69atTQZC8rGQaiBukNWGKgKKQEIi4BvSxIpkiE6wV9Ii\/O1vf5Ojjz7agM6wnM+UMRf0jyKgCCgClhDwDWla6r+qVQQUgSRBIFrd9BVpkm2QlAePPvqofPfdd8KRhSCucS9andZ6FAFFQBEoKAK+Ic3jjz9eevToISTPuuSSS0yOF46kIOAa9yhT0I7qc4qAIqAIRAMB35DmMcccI6QdwKUomHCPMtHotNahCCgC\/kLg9y2rZdvEfv5qVIjWhCTNEOVjdnnr1q3G0rz66quNy5G7fZItlE2aNJFhw4bJzp07o66\/atWqoqIY6HfA++9A3TMqS9f0k+SNZsXk+25VZNmr\/cP6LUadBCKs0DekWbZsWZkwYYK88847AklOnz7dpGRlayX7zulX0aJFOUQkrLiPGTNG8Pck3ero0aNl\/\/79R9TBfKmXgnIv9bm63n\/\/fXHPvTra0EnfkklvPH2fls\/\/QJa+9KBkdzxFxp69Vu5JP07qXdFeKvadKXUn78v3+0lfbYtvSNMFgu2U7P6BRN1r5cqVE65xz70W7vHTTz8V8lNDxhAxDvMLFy4M9\/GYlOMHHZOK86mU7aj5FIn6bRs66UQy6fX794mh9y+zXpYNfRsai5JheNGyqYYoKz+9Ssp2HyUp\/2jAa4sLsUeaIeApUaKE7N27V0aOHCkbNmww8sorrwjO7gVZCIIg2Z5ZqlQp4XnmSxctWhRCu15WBBSBaCCQaEQZiInvSBMn9oEDBwrbKtu3by9t27aVdevWycMPPyw4vgc2PpzzFStWyN\/\/\/vecoqeeeqqsXr065\/Ouc2+S7uOXeSp93\/vRU31e9y+W+lqOWCxeSlr\/uZJbSveaKZEIzw965\/B3LufLl2AniUyUga\/KN6TJ8JutkjSOnUFZWVny4Ycfypw5c2TAgAGCpcg9twzn4QpEHKrsH8eWkdemz5blG7Z7Jqu27PRMV2C\/Pl+12XO90dZZ6pjfJRw5Zt+OsMrlV1fzainiyhvXlBfkkx6pEkomX3n0X+7x\/KB3VslZfT+SeyYsllWrVkVVMCqiXWc49bHesOrTj2TVa4\/JyrszzNB7y7gHZE+xE8VpN0T23\/WB\/NriQdl47ClR6S+LdaF+x15e9w1psmVy6tSp0qVLFyFAB\/EzXSA4nz17trlHGfd63sc\/76amphpH+T8\/iTmvUaOG+1GKZw+WH8Z0kRl3ZHgmozNP8UxXYL9s6I22ztGd0iUcGdLqlLDK5VfXwPa1xBXmSfMTRjW5y\/D81scbynUZlWTkgu1y5aubZP3+UpK7XEE\/B9NZ0LrCea5ScUfKrJktJ7\/VWw4MvFiOmjlCjq90hpmbrPrcWqmaNUmqtL0zav1z28QCX84P1+KJb0iTlfFOnTrJAw88INOmTZOGDRvmuB9ceumlxuIkgAdlIsErIyNDFi9eLCwiIZynpaVFUkXClOXL53VnbOikj37Um9U0VSDPyqVSpOXTi80UDW2NB3GH3ltG3GgsShZzXKJ0F3OOb3BDPHSl0G30DWm6PTn55JOlX79+wgIO\/7IgH3\/8sbCdkoDEbrlwj+eee67Ur19fmjdvLk2bNjVkzLVwn9dyikC0EZjSvZZM6VZLxi\/cJMx3Zq\/YHm0VUakvGFFScdmDq93JRpT02xXfkabbsGgdHccxUd+zs7MF8iVlhuM40ag+7upgnsrrRtvQSR\/9rrdetZKy5P4Mca1OvywURUKUtjDm\/dqUhCdNm+D6TbeNIasNneAeD3orl04RrM6splWEhSK8Ami7DcGPMnDoTRvysyhtYUzbbEpCkSaWJEE+2P3TokUL+eKLL0y09\/x2BNl8AapbEcg6NNcJEl4P1yHKlW0dYY5y35bVZjEnmYfevIP8xJekCdk1a9bMzEWyg6dz587GyT2vzhD5\/amnnhIyVy5YsEC6du0q\/\/nPf2TevHm+2xGUVz8C7+l5ciGA1ZmZXsEsEsWq565FCVGy3zuQKNnKmCyLOYXB13ekib8mu4F69uwpLArhHnTFFVfII488YrZShuosydhSU1PltNNOM0WIivTTTz+ZVfcLLrjA+Hkm+44gG3NQNnTyBYhXvVidLBLhPB9NqzOURVkYorSFMe\/XpviONHELwhmdFL4AQ6oL3I9IgcE9rgWT6tWrCzuJihcvLvv27ROCfLB\/Hcdf\/NjcZ3LvCHKv61ER8AsC0VgkUosydm\/Td6SJNYij+8aNG3N6vWzZMiGpWuA2SpKw4UrELoE777wzpywpgNu1ayfffPON2XpJXZBwToEgJ9TBv5peCUTula5APXQ98POqKO9MCVa3DZ20I9717t+xUZ5sUVJuOb+kWSRqMnSuzFn6bdCdNeb75O7MGXS1MPRmZ84va7\/O2Zmz9\/qX5MdT6gd9HrwKIl5jzO8UnbbFd6QJMeIW1LdvX\/nkk0+Mf+W\/\/\/1vuf32203ADRcwfDbZJYQfJ\/OYBw4cEBZ8unfvLr169ZJnnnlGsDQZspM6w32Oc4b87meO1MFKoFeC5euVLtVTJeo7U7zElN1EuCYVS0mRK0av+0tfzM6cj5\/M2ZmTsvsns5hjduY8OjcmO3O87H+gLn6n\/F5ti+9IE0CYjySU29y5c+Xtt982\/pXnnHMOt0IK\/9qyxfK5556Tiy66SBjWU1h3BIHCn4I18eeZd39t6KR3iaQ30DXprFvHy3NDHpXAOUrZtt4QJavehZmjBLdIxBbGkbQxFmV9Q5os5BDViIjtCEPv1q1bC5HbmdPkHmVCgUA0I1bdO3bsKDyP8EzlypWFunRHkBgrJRR+sbluRyd9wULh6LXESi9zlDet6CdTNnaQMz99UmbNXSLLmz4hEKVzyzixseodq756\/c4i1ecb0ixdurTgMjRx4kRp2bKl3HzzzSaSO9HcGa7jd1mmTJmQ\/YNYS5sXnAAAEABJREFUmfsk8grRkRCeZYgOkeqOoJDQ6Q0fIuDuzCFwL3OU2w7lz6n62gGpN36jrLzuDenwVd6jLx92KyGa5BvSZDgNwXEk\/BsWZsWKFQXp0KGDfPbZZ2YxKCFQ104oArkQcEmSYTdEiQ8lREmE88CdOe5jga5JzHW61\/UYewR8Q5puV8k4yUo5w2332ubNmw1hQqjutbyORDLCt5MVdneBiF1C9erVk2A5gvKqK5Hu2ZiDirHOkK8nXvRCjC5JQpi7v5wlxc5sIFiUDL0hzFBDb9c1qcLxRwt+nV7vX7eFcciX7tEN35Em6S6uv\/566datm1nQYVEnMzPTBN1gCJ8fLsx7Dho0SPbs2WOK+jFHkGmY\/kkqBPYcJEPmJSFGSJIhN8I1rElIEoEoS7XrEzY2LBI9d1V5GZFZw7gmRdMhPuxGJFlB35Em+DM\/iTvRuHHjhPxAzFM2atSIW3kKTu3Dhw8X5j8Z6lOYEHO6Iwgk7CzK2FossKUXFyCIEQkkR86xKtm2mJsksSb\/fEMF\/5uZXl5wTXKjJhW8pvCftIVx+C2MTUnfkSaWIqveBN645pprjIVJSl+ucS8vGN577z059thjTQpgtxzDfPwi3c+5dwTdlbrFuG\/wJfdKDky8y3OdXvUtXD2QSDwIc4uBgnWYl0CMDLFzk6NrReISFA2SlCD\/YXWyfz2raRUzXMfqDFJMLxUSAd+RJkNwVtEnTZokyPPPPy+XX365uNai21\/mK3ElYpcAO4Lw08Snk+Aeuec+89oRVP6Y3yV76gRh94RXsnfTSk\/1uf36ccVSz\/WG0kkemVjK1j+KmVw1hdXxe1orCRRn8ErJS9ZkjjG5cdiBQ34c5v1iLXz3A3W0q35Apl7\/dylbTAx5xiIvEfoYAXL0Svitu79\/m0ffkSaEx9CaHT8Ie9DZ4fPHH3\/Izz\/\/nIMV9xjCs0uAHUFff\/214Nx+3nnnSZ06dUx0IyxUdhixC8h9kPPAHUF3LK8gV769W6o+OtczSbn1f57pCuxXjSc+9VxvSJ1Zk0wuGfLJxELOemhadOrvPEyqBghD0ryEOfi87sfiHiOp3PVeeM5pJg8VVmcs8hKhz+u+8lt3f8c2j74jzWBgrF27VtavXx\/sVs61xo0bC6AihIODOGfMmCGtW7fWHEE5KOmJ7xCIcYOymqZ6PtcZ4y5Zr953pBk47K5atapJrsbcJnl9SpUqFTFgPMcwXncEiQnWEDGAhXyAoVshqyjQ48mmNy+QYjXXaQvjvPrqxT3fkeaJJ54oU6ZMEYbRWI3InDlzBL9LhujhgMLQnZV3jo7jmMUk3REUDnJaJpERCLQ6bfh1Jgq2viLNX3\/91YR0u++++2T16tWC1YkwX8liD0GFEwV4G\/1gHsprvTZ00sdk00ufg8uRVwOtTjcv0fdb\/\/RpPrJk\/p9sYZx\/y2JbwlekiU\/lCy+8IF999ZU8\/fTTMmzYMCP4ajJnycp6XnBs2LBB2HLJSvtll12mOYLyAkvvJTUCrtUJCOqaBArhi69IE6f2AQMGyNChQ00UdlJcuPLPf\/5TCCgcqmu\/\/\/67DBkyRK666iqzct6lSxd5+eWXZdGiRcKCEKHmpk+fLuQcgpxD1ZPI123MQdnQyTtMNr30OVIJtDoZrpMNMxKr0xbGkfYz2uV9Q5o4rkOYHNkGyQ4gwru5kp9zO1bm1q1bheccxxESszHMJ5AxlieLSESFT09PN0QabSC1PkUgXhFwrc7vt+0RrM4I97DHa7cL3G7fkCa+mZAc8S8J6UZot0DhGmVC9XTHjh0mN9C9994rNWvWlOuuu062b98u+e0IkiT6z8YclA2dvNJk00ufCyNYnUvuz5CsplXMHnaszvzqs4Vxfu2K9f0isVZQkPpZ\/GFXEAToCtZnoHM7ZXAlwi2JRSIiI5EXiDichJHDTemee+4xRJrXjiDaRx0MNbyS3Ds4vNKrelYZt6tEwyGa3yd2ExEAZOWWX+Wsvh9JrHYTFeQd8Dvl92pbfEeaZJzs2bOnSdd74YUXiiuEditatGgOXrgTBe4IIkBx7dq1xd3tw5C8SJEiUqFCBeO+5D6IK5Nbxr2GWxP\/anolwXZweKGb\/nqhJ1CHDZ3oTya90f4+XV2vhnzR9yK5LqOSsJvotmnbTdR\/cA0UrzB2dfI7Radt8R1p7t692wQeJjQcK+CusEjElshQgJFAbe\/evfLtt9+aIkRxZw4Ta5T4mpAxwnlaWpopo38UAUUgNAJZTVNlSrda4s51Zq\/YHrpwEt3xHWniVsTcJaQXyXuAIBmm33\/\/\/cY6JRvl3XffbfahQ5y6I0hDw0XyfSpoWayigj7rx+fqVStptmFmpleQlk8vlsC5zkTra7j4+440t23bZlyGWC1nSB7u6jkdJovlW2+9JewgYuGIl+o4uiMIbFQUgcIg4Fqd2d9tNyvsCWV1RgiM70gTK\/ONN94w85ALFiwQdwUdEuRehP3T4gEIMPke8NGTUxs66Viy6aXPsZbcVuf1zy+MtUpf1u870mSFnJVyd9XcPfbr10+I30d09lBIzpw5U7BM69ata3YG4bupOYJCoaXXFYHIEcA1ybU6py77NSmtTt+RJivkLOjgQpSRkSEM0QkNxwIR8TL79+8f9E3j2D5q1CiTOI3hObE0cVvSHEGH4WK64vAnb85s6KRnyaaXPnsprtXpptfoPn6Zl+qt6oqcNGPcXMgRa5MtkUQ2at26tTz55JPy22+\/SdeuXQVyDNUEyBaHdu6TWI3FIbZM4n6kO4JARUURiB4CWJ2k12CFffzCTUljdfqONHmlEB4kyTmyf\/9+IQIS+8v5HExYdWfxiD3q5AEaP368kMVSdwQdRsvGPJ8NnfQ42fTSZ6\/FxTi31TnondVeN8VTfb4jTciPwMEQIC5DzGneeOONguM6c5rcB6HcO4JwfB0zZowQlAMHdtyPSIMB0eqOoD93wkRz5wg\/mHDEhk7alUx6\/dDX\/Ts2ypMtSkrfxmXMNkx2E03KXhbVHVi6IwjmCyoiN910k0CABN9gR9DgwYOlXbt2JhAxfpg8lntHEKRZrlw5Ye+64ziGZIm\/Wb58ebMSzzMIhJqsO4K8zunCvKINncmmN9o7gsAvHAn2bm9tcbawh71q2eLS+fVNMnG5E3Q3UTj15y7Db5zfsG3xnaUJIDi2jxw5UmbNmmV8Ll988UW54YYbuCUsFJmTXH8qVaokREjavHmzuUN0I1yUcGxnFxC7gRDOdUeQgUj\/KAIxQcCd6xyRWcNYnUROSiS\/Tt+RJnOXw4YNE+YlWfQ57bTT5LjjjpNOnToJJBjqLVevXt0QK0GIcTkaO3askMWyTp06AnH6aUfQJZdcEqobMb3OsDWmCoJUbkMnzUgmvX79PmWmlzdWp7vCnihznb4jzV27dgmr3m3atBFcjtjl06NHD8HqxFLkBxFMHMcxw3ec4T\/++GP573\/\/a4YFjvOXHUHiOM4RVTBX4qWg3Et9ri5+XO65V0cbOulbMun18\/epQe0z5YuhbSTl6ynG6izT5TWTLJF3VBChr7bFd6RJUA5WzxlmM2+5Zs0aOeqoo2Tnzp0m8lG0AWOeRGWlKAaKQSy\/AxumPWGszrpnVyv0dy3aHBBpfb4jTdfKJODG6aefLi+99JI0aNBAIFB35TzSTmp5RUARsI+AO9dpvyWFa4HvSJPuNGzYUHAXwnyfPHmyEDezT58+eeYI4jm\/iLZDEVAEEhcB35AmK9\/4ZrJ3PFCYm2rVqpVxVKdM4r4K7ZkioAjEAwK+IU3AYvtkSkqKWQUfPXq0TJo0KUfYR67Dc1BSUQQUAZsI+IY0cSciIMeIESOEHQ5YnezqWbJkiZQoUcK4G7EgZBMs3+jWhigCioA1BHxDmiAAKeKX+eCDD5pAxISDmzdvnrAzCLcjLFHKqSgCioAiYAsBX5FmIAh\/\/PGHsG888JqeKwKKgCJgGwFfkSbRjEiM9tBDDwm7eh5++GGT4+eDDz4Q5jRPOOEE23gliX7tpiKgCIRCwDekyco48TOJaEQAAtJb4HbEPvEdO3aYfeWQaqiO6HVFQBFQBLxAwDppMk9JmDcitbPHvEiRIvLyyy\/L9ddfL1dffXWOMKfJXvS8QHHTXRB0mH3nbLvUdBd5Iab3FAFFIFIErJAmFiNZI\/HBbNy4sSHGW265RUhrQezLrKwsgQDZR+4Klicr7KE6yLNEQxo3bpxZRGJBic+a7iIUYlavq3JFIG4R8Jw0iWLEnCWW5ZtvvimBGSdZKScTJZbnbbfdFhGoRGiHVCtUqGACctSrV08IMUfwDixPTXcREZxaWBFQBEIg4DlpEpCDQMIMv9lnnrtdxYsXF+Y1yQuU+15en0855RTZuHGjESzZ2bNnC0S6fPlyYY7UfZaQc6tXr3Y\/6lERUASCIPDLrJcllGyb2E9CyZYRN0qsJUhzPb3kOWnii0kgYRZ+cGAP3DLJ+aWXXipDhw4VFn8kgv+I8nzNNdcIdRJDc9OmTXLGGWcIc6QM+UNVxf52laqFCtflR\/ySvU1965WWZxodb+SNZsUE+bhVUVnZ1glLQhHf5090kmWv9g8p2VMnSKwl1G\/Zq+uek6bbMYbLDJtJfsZ8JYnQmjVrZiIalS9fXvr27esWDeuITydDcvIIkYGSuo4++mipVq1aWOkuYhkWK3fddCj3NS8+v\/\/++4UOyxVpO23opI2Jrnf+HfUFye54irx33qojZFazA3JTzRLS6uLacnWbq6XeFe2N1Ljmfqn62oFCSd3J+8SVCsOW55y71658e7fEUu5YXoGfj1WxRprbtm2T9evXy3XXXScVK1aUk08+WW699VaTohcfTQgvEmQYmpPilzpJA0wQYhaZqIsUF6ykI5ynpaVFUnXUy\/KDjnqlYVSINR5GsagWsaGTDiSKXobIWH0b+jbMsRC\/71ZFdn85i25K0bKp4rQbcgQRVn56lSAV+86Ust1H5Uipdn3MM9H6YwvjaLW\/oPVYI00Cc7jBht3GM2RngYj0vYh7PZwjOYIuv\/xyk4CN+Jt8xtoks6Xf0l2E0x8t43MEYtS837esNvOFLklCmBAk5AgBYilCiAifEandJkat0WqDIWCNNFkEIqUFliZZ7ZjP\/Oc\/\/ykIbkY1a9YM1t6Q1xzHkWuvvVZYLZ8\/f7707t3bJGFzHEc6duwo2dnZ5h5lHOfIdBchK9UbioAHCECUkCPzjViRWJe5SRJyPL7BDR60RlXkh4A10qRhDRo0kFGjRsldd90lZJ+cOHGikACN1fPOnTtTRCWKCNhINmZDJ5D5XS9EyQo0JIlgTZZq29cMs10r0u8kaQtj3q9NsUqaL7zwghD+7dlnnxV2BvXs2VOmT5+uEdptfiNUd0wRwIpk6A1Rcg4xMvcIUR455xjTZmjlhUDAGmmyJXLp0qUycOBAKVmypDCpPHz4cMHhnXui\/0UdATCOeqX5VGhDJ03ym17XquTI0Nudm4QoU1IS2FQAABAASURBVP7RgCbHndjC2DZQ1kgTB3QWg4499tgcDJjnxIcT96Gci3qiCMQhAgy\/sSTduUrOsSqxKJmfjMMuaZMPIWCNNMuUKSNsexw9erRJzcvOnQEDBsiJJ54omtbi0NuJ8sHGHJQNncBmTe+nH\/25+t2noTnSFp8Ov2laocQWxoVqdBQetkaajuMYv0y2NWJZsh8df00WhSL10YwCDklRhY3hlA2dvEyv9WJJMld5YODFZvshVmXFfjONj2S8Dr\/BMS\/xGuO82uLlPc9Jk2E5\/pgE5cDZHF9KohGNHTtWOnToYKxOyngJgupSBCJFwB1+Q5S4CgWbqzy6bGqk1Wr5OEDAc9JkkYfYmMTKxBkd\/0z8NZEmTZrIsGHDZOfOnXEAnTYxmRBwSZI5SoiS1W+XKJmj1LnKv34bEvWK56TJPCZ7zd955x2BJHExYr848vrrrxucWQwyJ1H4c+DAARkzZoycf\/75wt505lCT1ZK1MQdlQydfm8Lq3fPlLDPMDiRJzvGnDFz9hjAZiqMTKaxe6ogXSaa+Br4Tz0nTVc7QnD3ikKh7rVy5cmZ4zj33WmGPGoS4sAgm9vPMRUKGWI8IQ22EcyzJfVtWS7EzGxinc9dNCKJMbFS0d3khYI00S5QoIXv37jU7gTZs2CDIK6+8Iuw5x\/Uor0ZHco+IR0RTIqoS9aanp8uiRYsiqSJhytqYuI+1TkgPcnMFAkSKT3tIID6EoTREGEx4zrUeXQsSckQYcrPyjS9luF+CWPc33HZ4Uc56X73oZBAd1kiTGJc4trNyTgzMtm3byrp16+Thhx8WAhUHaWuBLhGIOK8gxITVCvZjiuW1A72r5kSsiaWeZKh76ch75Ms3njWy7b0X5Je1X\/8pv\/4ie4qdaOT3tFbiDF4ZVPbf9YEgv7Z4UBCGnPEm\/G7irc0FaS8xUgtEAlF+yHPSZEhOgGD6ccIJJwj5gAjQMWfOHMFPE4uQe24ZzgsrEHSoOhp\/UiVn6IV14YXwA\/ZCT24dhdE7v\/dGyU9e+9cqyS3Pt\/n0L9dyl8nr89CrvpLc0rPBp+LK4HrT5N\/\/eN3IVZUnSu3fHvlTNneX2q583UrOe2q1kStf3STIbdO2y2Pz9sjE5Y7ZjYbVFA3hexaNeiKpA6MgkvLRKut1X4mTik7b4jlp4oM5depU6dKlixCNiJxBLgicz54929yjjHu9MMfU1NR8gxAXpv54epYfS0Hbm5leXvKTrKapklsGtq\/1l2u5y+T1eURmDcktU7rXkkBZcn+GuLL18YYSSqgnM73CwX5UkEqlU2Tt1j0yfuFGKd1rZo6k9Z8ryKB3CpYSpTAYF\/Td2Hou8fsaHFnPSZOV8U6dOskDDzwg06ZNk4YNG+akWiDVBRYnju6UCd7kyK5mZGQIgYdZXEI4T0tLi6wSLZ0QCGQeJH6XoCFQiBeydUl2SrdahlAzDxLrnBXbjiDSgpJoQgCnnTgCAc9J09VOpPZ+\/foJCzWY3QixMO+991456aST3GKFPmoQ4kJDmDQV1KtWMscqhlBdMoVEXYvUtUK\/P2ilJg0w2tEjELBGmke0IoYfHEeDELvwMvnunnt1tKGTvkVTL9YpFikCgQ56Z1XIIXw09dIPP0sy9TXwPUSRNAOr1XNFIPEQqHxwHhQCxQLNalolZz5Uh+6J967z6pGSZl7oJNg9GxP3NnTy2mKtN+vgoheWZ9ZB8sTybDliMWrNSrw5SYI\/scbYrxBaJU0Cd9x9992CnybzmQQhZgXdr2BpuxSB3AhkHSJPrjPfmb1iO6cqCYyANdLEqX3QoEFCaDjwxdds3759MmTIEOEe13KJfiwkAjbmoGzoBCYv9TJsZ+GocqkU6TL2c9QnhXiJsZ8AtUaaRDv6448\/5JJLLpEiRYoIUdxxM8ItiHt+AilR2mJjOGVDJ+\/Lhl6Is2rZ4oLFSRsSXWxg7AdMrZEmWyWPOuoo2bVrVw4ODNchTBzgcy7qiSIQRwhAnFic7hxnHDVdmxomAtZIk+AZjRo1ku7duwupLshKSYxN8p7bSncRJmZxW8zGcMqGTl6QTb3DM2tI9nfbJdFX1W1hzPu1KdZIk043b95c\/u\/\/\/k+eeOIJufbaa80517hXEJk5c6YQ1JioRr169RKG+hpPsyBI6jOFQcDMcXardZA0V4kuDBUGSX8+a5U0Ibk+ffpI+fLlTcR2Ul+89NJLBUJq7dq1QtqMcePGybx58+S0004znzWe5mE4bcxB2dBJj23rZXdRvVNLyr8nLKM5CSm2MLYNpjXS3LFjh\/z3v\/81w\/M1a9aYBaH33ntPIDnmNSMFZsWKFSa7ZYUKFcRxHBOlfdmyZYIrE5Yn0ZOYErAaTzPSTmn5uEaA+c3vt+45aHEWLPhHXHc+gRtvjTQJQFy8eHEhWvuCBQsEYmNx6JhjjimQy9Epp5wiGzduNEI6C6IlQaTMl+LO5L5DXJxWr17tfkyqo405KBs6eal+0UtgEJzfsxPQf9MWxrxfm2KNNIncTpT22267TebOnSupqalCjiCuYRHmBwrZLOvXr28iJLGIxFDhmmuuMY7yderUEeJxnnHGGcadKa94mughuClfAK\/EVtBYG3pt6OQ9+kVvnTK75byTU6Tf5GVCu2IhfulrLPoWWCe\/U36vtsUaaUJk\/fv3l8zMTBk8eLAQkBgwCAuHxcl5XkIkJKxJoiM99thjxjolcRoJ2oicxPworkvVqlXLN54mdUC6XgmWb2x0VTHb+ELVfdFFF+V5P9RzhbluQyft9ZPeF2+sJZ+s3yPzfiwWE\/yT5fvE7zQvTvDqnjXSpIOQ4znnnCMnnnii7NmzR\/iiQ6D4a3I\/EmFo3rVrV1m\/fr1JzsZ8aePGjaVu3boaTzMSILVs1BFgNT2raRXpPn6ZMMcZdQVaoacIWCNNtkpiaV5xxRUCuV111VVCniBW0kuWLBkxCJUqVZLLL79c2rVrJw0aNBA+Y21qPM3DUDLUOfzJmzMbOumZ3\/RmNU0Vs5p+kDhpXyKILYxtY2eNNLdt2yaskpP\/\/I477pBnnnlGXn31VWNxOo4TMS6O4xhfT1bLSaPRu3dvIUq84zjSsWNHyc7ONivp+IM6TuT1R9ygxHxAe1UIBFyn90RcFCoELHH3qDXSDESKucfNmzcL0dx\/\/PFHQ6aB9\/U8Oggw1xedmsKvxYZOWudHve4wveXTixPC6d0Wxrxfm2KNNMuUKWOc2knjC\/gvvPCC2Rm0YcOGqKbwtQmu6lYEciOQM0xPYKf33H1OtM\/WSNNxHCGW5j333GN8NFnEwW+T0HDhuBwl2ovwoj825qAi1RktHPysF6f3JfdnxH00JFsYR+s7UtB6rJEmDSY03DfffCNvv\/22EHy4evXqJnjH7t27ua2iCCQ0AkRDSpYwcon0Iq2RJsRIhKPHH39cSNvrCruDCEacSCD7pS9Mg3jdFhs66WM86MXihDhL95op4xduotlxJbYwtg2SNdIkAhHDceYyH3nkEXElKysrx9HdNjiqPwER8FmXIM6sQz6cxOBUP06fvaAgzbFGmsxb4txeEEf2IP3QS2EgYGMOyoZOoIgnvVlNU2VKt1ry\/bY9Zp6TOJzxQJ62MOb92hTPSfPnn38WcgM9\/PDDAmG2atVKbrnlFrn33nuNcI8yNkFR3YqA1wgQSo7FoayDVuf4hRsNeep8p9dvITx9npPmcccdJzfddJP07NlT2BFEODgIlM8I9yiTX\/PZUXTffffJ558fTmRFfE6CELN1skOHDoL7kgYhPoykjTkoGzrpsT29VVBfYMlqmiqQ59bHG0pmegVhvhOBQLFAC1xxDB60hXEMuhJRlZ6TJnmBCAv34IMPCuktWAhyHEcIwIGULVtWKJNXLyBadvmwm8gtx+6iUaNGyejRo83CUpMmTeSpp54y8TlnzJghlJ0+fbp88MEHQkAP9zk9KgJ+RQAChTwZukOgc1ZsO4JEmQOFSJ+bv92vXUjIdnlOmqyaY1lmZGTImDFjzKIPi0BYjuEiTIAPCJcYmoHPQMbbt283lwgAwrwpBEmsTj8FISYDp2mkx39szEHZ0AmsiaSXoTsEyqIRVqhLohdWKyUQ6cgF23PIFKsUwTKFVBEChUCuCNhES2xhHK32F7Qez0mTVXOG323atBFiaP7rX\/8yuXwimcesVauWXHrppcKuIrfjJGNr3769kJiNQMPjx483YedWrFghhM5yy3EvdxBi4vR5KbTFS32uLsjaPffqaEMnfUtUvQ1qnykdLz1XRnZtZOSLoW2k5Js350jx7MGS8vUU+eHjibLorTGyYOZb8tr02TLkjYVGINTCSJkur4kr6YMW5Zy7107q+KzEUn6t15ufj1XxnDTpbZEiR6rdtWuXiYfJvWBCkGF+CAQdJvhwsDLE2sNyZQj+3XffCc+4cTaJ3RnsGa7xnMpKUQwSA4PvF0yXDdOeyJFNk+6XH8Z0kR+fbWuE4X44QsT5YHLXlemSl9xxTTNp27x+TIXfrU05kr1stiQP3ZAfP+rZs2ebuc9gRblP6ozKlSubHEG1a9eWn376yexvh0TdZzivUaOG+1GPioAiEASBzPTyBxei\/ipME+Qnwcg2mteCNNfTS1ZIk3nGmjVrmlQVpKYgeyTH\/KzJvJAhfiYuTERLotwnn3xiEq1hnS5evNhMATA1wHlaWhpFfCWs9BPFnmHlu+++66u2aWPiDwGSCjJdhRcJ2RBYSwi3F1oubwQ8J01WyLEYsQyDCfcok3ez\/3qXfes33HCD8CXB5Wjs2LHSq1cvgYwhzubNm0vTpk2lYcOGQmDiv9Zg9wr777t06WLyJBH7E4K32yLVHs8IEMuBbcrjxo0TPFXYSBLP\/fFT2z0nzWh1ni2YI0eOlLPPPttU6TiOEAX+ww8\/NMGGSXdRpUoVM1THPQkiIkCxX4MQYyXTXhLOsVBGkGbTMf2jCBQAAf7RjcQjpQAqkvaRuCXNRHpjfLlJO5ySkmK6xcLYjh07zLn+UQQKggAZKv\/zn\/9I69athVEXmzwKUk9MnonzSovEeft933zmVhkeuQ0lghNbRdPT06VevXqCoz7O\/Mccc0yOBwH+pfiius\/oURFwEQjn+wRBkqTwxRdfNIS5ZMkSWbt2rVuFHguJgJJmIQEM9ThpO3DaZ14Jy9Etx9wlVgBTBRMmTBCiPOEkjJ\/pt99+a1J9UP6EE05wH9GjIiCRfp+++uorMzWFux1TWY6jebGi9TVS0owWkrnqwXrE7enKK6884g4LXS1atDBJ38iJVLFiRSEQM4tUJJcjIyeLV3zRj3hQPyQ1ApF+n\/hHl40eeGPghhe4wSPxgYxtD5U0Y4Qv2zbZtXTeeeflaGBFkwUedyeT4zjG7WrNmjUmqRyW5\/vvv292O+U8pCeKwEEEIv0+MTzHdY2FUYLgOI5amgdhjMr\/SppRgTH8SrAYmL8M\/wktqQiERkC\/T6GxidUdJc1YIRukXlyJGHbjyM5pKE8BAAAGlklEQVRtJuyZzzz99NP5qKIIRISAfp8igitqhYuIRK0urSgfBBzHMc71zGuyir5+\/XphB1O1atXyeVJvKwJ\/RcBx9Pv0V1Rif0UtzdhjfISGZs2aCfNTuBuxe+nmm28WtoAeUUg\/KAJhIqDfpzCBimIxJc0oghmsqsaNGwsBR9x7RYsWFZLHzZ8\/X5ikZ1une0+PikB+COj3KT+EYn+\/SOxViKpQBBQBRSBhEFDSTJhXqR1RBBQBLxBQ0vQCZdWhCCgCCYNAQpBmwrwN7YgioAj4HgElTd+\/Im2gIqAI+AkBJU0\/vQ1tiyKgCPgeASXNcF6RllEEFAFF4BACSpqHgNCDIqAIKALhIKCkGQ5KWkYRUAQUgUMIKGkeAsLuITG033nnnXL++efLxRdfnCMDBgyI+86xe2vUqFFCaD+2vhJtP7BT9PvZZ58NvJRzTkCWYcOGCbEGci7qSVwjoKQZ16\/Pf40nWj3bQ1257777chpJVCdyIeVciIMTiPLNN98scIxTkuURCnDevHlx0FttYjgIKGmGg5KWKRQCWGHdunUz2ULnzp0rX3zxhbRq1crkSGrfvr1gjaFg5syZQvplLFXSL\/ft21d++OEHk5aZI2Ww8rDsIGAShlGW4CcPPfSQsQS5T51kIL3gggukU6dOQmZGLL3BgwcL1wgMTZR8yPD222\/Pyc2ERYigxxVy8pCziSj77rVQR6xq2oPUqlVLaMPOnTuFgMCvv\/667N27N9Sjej2OEFDSjKOXVYimevZo586dTTT6qlWryjnnnCOff\/650b1161YZP368EDt0+PDhMmLECMnOzhZI6\/HHH5cVK1YIicAmTpwohM6DpLDyzMNB\/vDssmXLhEj3H330kRBbcvLkyabkli1bBIuXMlh5ixYtEnIzkVxs1qxZJpkdQ26S123atEk2btxoiJUEZKSHMJUc+kP5M88889CnPw+BfaSfECJ3sKqxsOlnamqqkB+KdtEX+k8YQMqpxDcCSprx\/f581\/rnnntOVq5caWTp0qVy9tlnmzY2aNBAsNhWr15tojthjUE4mZmZ8tlnnxnrs1y5cibth+M4QjQfAjabh4P8gfQgJ0j41FNPNSS8ePFiUxIrj5w4RJRCP1MCJLKDEIsVK2ZC8zFHiVVbvXp1WbJkiSxfvlzQlzu2KVYq103Fh\/4E9pG+XnXVVYfuiOzevVv69esnzZs3N\/O73IC4U1JSZMeOHXxUiXMElDTj\/AXGW\/MZopK+GKKEcMjAOWXKFENYDLnd\/vz22295Lp4w7O3du7chZ+rB6ux7cDjvPp\/7yPCczIzu9e3btxuCa9SokbFsmRrIyMgQSNUtE+mR9r\/yyitStmxZufHGG002yEjr0PL+R0BJ0\/\/vKC5aGG4jq1SpIj\/\/\/LNAlpDMW2+9JUOHDjWBmBk+E82e6wxzIdijjz5asBj37NkjXGeOEV2s0mM9Ygli3fXp00cYpnMvmEDUDPshz3Xr1kmPHj2EJHdpaWlm3pS5Vqzf3M+WL1\/ezJXmvh7sM1MA9IdhOW12y2Dp0vYSJUq4l\/QYxwgoacbxy4vHpjO\/d9dddwmLORdeeKGQgbNLly7CMBl3Hoa69evXF8iTYTFR7vnctm1bs4LN3CdEyvAdIuTI0L906dJmSB8Kk8suu8xYfizKtGvXTtq0aSMM4SGymjVrmnlYPud+Hh3My0J6ue8FfoaMsTK\/\/\/57YSEKAubI\/CrzpvQFCzTwGT2PTwSUNOPzvfmy1USoh8RyNw5SRNzrzCWygIOlOG7cOKlYsaIhtCuvvFIWLFhg5jxvPDi8hagcxxFS0DKHOWPGDHn++efl0UcfNdYn1iLXEYbqWHfopx2uLvRyDdIaOHCg4PqDXnQ5jmNWziG1li1bmja4z7lHVtqxSLFOqYP2Up97nyP6aAv3mFfFSkb4BwGipK8tWrQo1NAfPSr+QEBJ0x\/vQVuRHwIxuI8bE+SJ5Vq7du2gGiDK6667TpjzhMSDFsrjIu5Uu3btEqzlPIrprThCoEgctVWbmkQIsOrNKnQsu3zSSSfJ1KlTjeWa1wIQq\/H4XDqOE3FzmMNlKgIrOOKH9QFfIqCk6cvXoo1SBBQBvyKgpOnXN6Pt8hgBVacIhIeAkmZ4OGkpRUARUAQMAkqaBgb9owgoAopAeAgoaYaHk5ZSBAqLgD6fIAgoaSbIi9RuKAKKgDcIKGl6g7NqUQQUgQRBQEkzQV6kdkMRUAS8QUBJ0xucVYsioAgkCAL\/DwAA\/\/8npAcEAAAABklEQVQDAIYvKuMbKfy+AAAAAElFTkSuQmCC","height":201,"width":333}}
%---
%[output:58b41b2c]
%   data: {"dataType":"text","outputData":{"text":"Induction Machine: ABB M3BP 355MLB 6 261kW\nIM Normalization Voltage Factor: 375.6 V | IM Normalization Current Factor: 581.2 A\nRotor Resistance: 0.00274 Ohm\nMagnetization Inductance: 0.00376 H\n---------------------------\n","truncated":false}}
%---
%[output:0fd658eb]
%   data: {"dataType":"text","outputData":{"text":"Permanent Magnet Synchronous Machine: WindGen\nPSM Normalization Voltage Factor: 365.8 V | PSM Normalization Current Factor: 486.0 A\nPer-System Direct Axis Inductance: 0.00624 H\nPer-System Quadrature Axis Inductance: 0.00756 H\n---------------------------\n","truncated":false}}
%---
%[output:623dffc8]
%   data: {"dataType":"text","outputData":{"text":"PSM EKF Fully controllable\nPSM EKF is stable.\n","truncated":false}}
%---
%[output:578aead0]
%   data: {"dataType":"text","outputData":{"text":"IM EKF Fully controllable\nIM EKF is stable.\n","truncated":false}}
%---
