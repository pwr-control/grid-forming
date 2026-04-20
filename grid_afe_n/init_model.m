clear;
[model, options] = init_environment('grid_afe_n');

CTRPIFF_CLIP_RELEASE = 0.001;
s = tf('s');
%[text] ### Global timing
% simulation length
simlength = 2.5;

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

%[text] ### Enable one/two modules
number_of_modules = 2;
enable_two_modules = number_of_modules;
%[text] ### Settings for speed control or wind application
use_torque_curve = 1; % for wind application
use_speed_control = 1-use_torque_curve; %
use_mtpa = 1; %
use_psm_encoder = 1; % 
use_im_encoder = 1; % 
use_load_estimator = 0; %
use_estimator_from_mb = 0; %mb model based
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

% reactive current references 
enable_i_react_pos_steps = 1;
if enable_i_react_pos_steps
    time_i_react_pos_ref_1 = 1.5;
    time_i_react_pos_ref_2 = 2.0;
    i_react_pos_ref_1 = 0;
    i_react_pos_ref_2 = ixi_ref_mod1*tan(acos(0.9));
    i_react_pos_ref_3 = -ixi_ref_mod1*tan(acos(0.9));
else
    time_i_react_pos_ref_1 = 0;
    time_i_react_pos_ref_2 = 0;
    i_react_pos_ref_1 = 0;
    i_react_pos_ref_2 = 0;
    i_react_pos_ref_3 = 0;
end
%[text] ### Settings for CCcaller versus Simulink
use_ekf_bemf_module_1 = 1;
use_ekf_bemf_module_2 = 1;
use_observer_from_simulink_module_1 = 0;
use_observer_from_ccaller_module_1 = 0;
use_observer_from_simulink_module_2 = 0;
use_observer_from_ccaller_module_2 = 0;

use_current_controller_from_simulink_module_1 = 0;
use_current_controller_from_ccaller_module_1 = 1;
use_current_controller_from_simulink_module_2 = 1;
use_current_controller_from_ccaller_module_2 = 0;

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
grid_nominal_power = 20*1000e3;
application_voltage = 690;

if application_voltage == 690
    % trafo data
    us1 = 690; us2 = 690; fgrid = 50;
    eta = 95; ucc = 100;
    p_iron = 1800;
elseif application_voltage == 480
    % trafo data
    us1 = 480; us2 = 480; fgrid = 60;
    eta = 95; ucc = 4.5;
    p_iron = 1400;
else
    % trafo data
    us1 = 400; us2 = 400; fgrid = 50;
    eta = 95; ucc = 4.5;
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

grid_emu = grid_three_phase_emulator('Dyn11-690V-690V', grid_nominal_power, application_voltage, us1, us2, fgrid, ...
                eta, ucc, i1m, p_iron, n1, n2, core_area, core_length, mur, ...
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
hwdata.afe = three_phase_afe_hwdata(application_voltage, afe_pwr_nom, glb_time.fPWM_AFE); %[output:9524e25f]
hwdata.inv = three_phase_inverter_hwdata(application_voltage, inv_pwr_nom, glb_time.fPWM_INV); %[output:06bebcb3]
hwdata.dab = single_phase_dab_hwdata(application_voltage, dab_pwr_nom, glb_time.fPWM_DAB, fres_dab); %[output:099a842e]
hwdata.three_phase_dab = three_phase_dab_hwdata(application_voltage, dab_pwr_nom, glb_time.fPWM_DAB, fres_dab); %[output:1f382d2c]
hwdata.cllc = single_phase_cllc_hwdata(application_voltage, dab_pwr_nom, glb_time.fPWM_CLLC, fres_cllc); %[output:0afd27f9]
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
enable_frt_1 = 1; % faults generated from abc
enable_frt_2 = 0; % faults generated from xi_eta_pos and xi_eta_neg
start_time_LVRT = 0.75;
asymmetric_error_type = 1;
frt_data = frt_settings(test_index, test_subindex, asymmetric_error_type, enable_frt_1, enable_frt_2, start_time_LVRT);
grid_fault_generator;
%[text] #### DClink Lstray model (partial loop inductance)
parasitic_dclink_data; %[output:2f8b031f]
%%
%[text] ## INVERTER Settings and Initialization
%[text] ### Mode of operation
motor_torque_mode = 1 - use_motor_speed_control_mode; % system uses torque curve for wind application
time_start_motor_control = 0.25;
%[text] ### IM Machine settings
im = im_calculus(); %[output:34adf327]
%[text] ### PSM Machine settings
psm = psm_calculus(); %[output:3ae321bd]
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
psm_ctrl.ekf = ekf_pmsm_setup(psm.Rs_norm, psm.Ls_norm, 1e6, glb_time.ts_inv); %[output:0449785c]
psm_ctrl.kp_i = 0.25;
psm_ctrl.ki_i = 35;
%[text] #### Induction Motor Control
im_ctrl = ctrl_im_setup(glb_time.ts_inv, im.omega_bez, u_im_scale, im.Jm_norm);
im_ctrl.ekf = ekf_im_setup(im.alpha_norm, im.beta_norm, im.gamma_norm, im.sigma_norm, ... %[output:group:4a660fa7] %[output:95e2dc4a]
        im.mu_norm, im.Lm_norm, im.Jm_norm, glb_time.ts_inv); %[output:group:4a660fa7] %[output:95e2dc4a]
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
afe_ctrl.res_pi.kp_rpi = 0.6;
afe_ctrl.res_pi.ki_rpi = 35;

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
sogi = sogi_filter(omega_set, sogi_delta, kepsilon, glb_time.ts_afe); %[output:4e85626c]
%[text] #### Current control parameters DQ PI
dqvector_pi.kp_inv = 0.5;
dqvector_pi.ki_inv = 45;
dqvector_pi.pi_ctrl = dqvector_pi.kp_inv + dqvector_pi.ki_inv/s;
dqvector_pi.pid_ctrl = c2d(dqvector_pi.pi_ctrl, glb_time.ts_inv);
dqvector_pi.plant = 1/(s*grid_emu.trafo.Ld1 + 1);
dqvector_pi.plantd = c2d(dqvector_pi.plant, glb_time.ts_inv);

G = sogi.fltd.alpha * dqvector_pi.pid_ctrl * dqvector_pi.plantd;
figure; margin(G, options);  %[output:3bb9ae7f]
grid on %[output:3bb9ae7f]
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
heatsink_liquid_2kW;
%[text] ### DEVICES settings (IGBT)
% infineon_FF650R17IE4D_B2;
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
% nominal_battery_voltage_1 = hwdata.dab.udc1_bez;
% nominal_battery_voltage_2 = hwdata.cllc.udc2_bez;
% nominal_battery_voltage_2 = hwdata.dab.udc2_bez;
nominal_battery_voltage = grid_emu.udc_nom;
nominal_battery_power = 250e3;
initial_battery_soc = 0.85;
lithium_ion_battery_1 = lithium_ion_battery_setup(nominal_battery_voltage, nominal_battery_power, initial_battery_soc, glb_time.ts_dab); %[output:5189b20c]
lithium_ion_battery_2 = lithium_ion_battery_setup(nominal_battery_voltage, nominal_battery_power, initial_battery_soc, glb_time.ts_dab); %[output:85659eea]
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
%   data: {"layout":"onright","rightPanelPercent":10.3}
%---
%[output:9524e25f]
%   data: {"dataType":"text","outputData":{"text":"Device AFE_THREE_PHASE: afe690V_250kW\nNominal Voltage: 690 V | Nominal Current: 270 A\nCurrent Normalization Data: 381.84 A\nVoltage Normalization Data: 563.38 V\n---------------------------\n","truncated":false}}
%---
%[output:06bebcb3]
%   data: {"dataType":"text","outputData":{"text":"Device INVERTER: inv690V_250kW\nNominal Voltage: 550 V | Nominal Current: 370 A\nCurrent Normalization Data: 523.26 A\nVoltage Normalization Data: 449.07 V\n---------------------------\n","truncated":false}}
%---
%[output:099a842e]
%   data: {"dataType":"text","outputData":{"text":"Single Phase DAB: DAB_1200V\nNominal Power: 250000 [W]\nNormalization Voltage DC1: 1200 [V] | Normalization Current DC1: 250 [A]\nNormalization Voltage DC2: 1200 [V] | Normalization Current DC2: 250 [A]\nInternal Tank Ls: 3.819719e-05 [H] | Internal Tank Cs: 1.151294e-04 [F]\n---------------------------\n","truncated":false}}
%---
%[output:1f382d2c]
%   data: {"dataType":"text","outputData":{"text":"Single Phase DAB: Three_phase_DAB_1200V\nNominal Power: 250000 [W]\nNormalization Voltage DC1: 1200 [V] | Normalization Current DC1: 750 [A]\nNormalization Voltage DC2: 1200 [V] | Normalization Current DC2: 750 [A]\nInternal Tank Ls: 1.200000e-04 [H] | Internal Tank Cs: 750 [F]\n---------------------------\n","truncated":false}}
%---
%[output:0afd27f9]
%   data: {"dataType":"text","outputData":{"text":"Single Phase CLLC: CLLC_1200V\nNominal Power: 250000 [W]\nNormalization Voltage DC1: 1200 [V] | Normalization Current DC1: 250 [A]\nNormalization Voltage DC2: 1200 [V] | Normalization Current DC2: 250 [A]\nInternal Tank Ls: 1.548074e-05 [H] | Internal Tank Cs: 2.840705e-06 [F]\n---------------------------\n","truncated":false}}
%---
%[output:2f8b031f]
%   data: {"dataType":"image","outputData":{"dataUri":"data:image\/png;base64,iVBORw0KGgoAAAANSUhEUgAAAFIAAAAxCAYAAABJTP5vAAAAAXNSR0IArs4c6QAACRBJREFUaEPtmnWMVMkWxs\/g7gQI7u4a3IIFCAQGd4fBIUBwd4fFJegCQUKAPxYIEjS4BIfFHQZ3e\/mdt9XvTr9hp7f3ztxL0pVMuud23ZKvjn6ngn78+PFDXNTevn0ro0ePlg4dOkiOHDl0Zffu3ZPZs2fL0KFDJVGiRC5a7f+WEuQ2IFna8ePHZcSIERIzZkxd6bt372TcuHFSsmRJV4LIolwJJAv7+vWrPHv2TL5\/\/y4pUqSQWLFiuRZEx4F88eKFLFu2TG7duqWqfOnSJalQoYKMHz9e1dna0qVLpyqfNGlSWwEN+f3S\/403MnSyPksZstznuRyTSCRu2rRpkjVrVtm\/f78MHjxYdu3aJa9evZImTZpI9OjRdROvX7+WPXv2SIwYMaR58+ae5z7vMIKOfwYHhenxIEZqeRg9tT4LXn3a52kcAzI0NFQWLFggrVq1kilTpqhNjB07tsyaNUu6dOkiyZIl82wC0NesWSP169ePdGdzJ\/SjTPrjps79W9Pc7gcS7zxv3jxp2LChggeQHz580O\/e3vn+\/fuyYsUK6d69e6QD6TNyXh0dk0jWcfDgQVXvly9fStGiRdVbDxo0SBYtWiRnz571LDVXrlwSEhIitWrVkqCgsKro78Z\/9t7Tp09lzJgx8vDhQ+nTp4+ULl3apykcBZIVIpnXrl2TT58+SbZs2VSl379\/L\/Hjx\/eARqhLCBQvXjyJFi2aTxvzt9OWLVskQ4YMkjNnTlm+fLm0bdtWEiRIEOFwjgKJBOJgWrZsKUOGDJEbN26ozXz06JF68bhx4+oGcECLFy+W\/v37h7GdEe7Ojw5Lly5VyU+TJo1Yv0c0lGNAIomTJ0+WTp06aahz5coVSZ8+vUyfPl09NCplAnI2kTdvXqlcubL+Flnt27dvGo41aNBAD2zu3LlSvXp1yZ49e4RTOgYkXhsp69mzp6xevVqKFSumKSFAsvgiRYrYChox6u7du6VHjx4KCpEADmzt2rVqMoYNGybFixdXda5Tp46kTJlSQTXfI0LSMSA\/f\/4skyZNUnuIKuNk8OKEQEgrxt7a\/A3IMQsbNmyQzZs3S8WKFWXgwIE6LLGriV\/JoEhB+Q1zg41ECgm52rRp4zExfwemY0CyKBzI+fPnJVWqVCoBe\/fu1czGTmKCgP7ixYty4cIFTTkNkBximTJlpGzZsoIzmzBhgpQvX161Aq\/N4f4yXhv1evPmjW6ERhy5bt06DbyPHDkiT5488QhB4sSJpVGjRj550PAk5+jRoyqBAMk8pJtkSvny5dPuzEto1bhx44i0ONzfHZNIQCSz2bFjh6aBSZIkUTVv1qyZnDt3TgoXLuyh0Vg5Kl+gQAH99Kd5Azl27Fhp3bq1Z45fFkgIizlz5kjfvn01l86dO7d66a1btyqgvXv39sk2+QqqFUirKhvVRtWrVKmiDsef5phEWoFE5ZInTy4FCxaUmTNnSsKECTXUyZMnjz97CvcdK5DG2Zw4cUJ69eqlthMgUfvUqf9LWPzT5hiQSMXChQvV4VStWlWWLFmiwKHWHz9+lEOHDmlcaRyPv17bAOINpAl\/1q9fr1kU7JO\/0sgcjgHJ5JC2qDFx3MmTJ5WPrFmzpnrwX605CiRScfnyZSUtTANcniGp1ob9JFzJnz+\/rYG6XQfmGJCQFIQgeOwsWbJ49oOaASJ2q1q1akLatn37dkmbNq2GSXHixFE6zW3NMSANsYuxBzzTAHb+\/PlKmxnWhWfkvYQrEAnDhw93G47O2UgkEsCCg4NV2qxAzpgxQ3NwU5\/Bw0+dOlWZc3LhAJB\/8Y\/kvuTAqO++ffukUqVKGv7QyGBQX3jBUqVKKf945swZqV27ttZrHjx4EFBt46kB8Wf3EkjTAPP58+dK+OJ8kFhKsnzHDEQmleavzXDERkIIwPRAWJBZtGvXLkyZ9ebNm+pg8Oo0zMD169e1SGZ3OdZf4Lzfi3IgAQV2Bf6xRIkSChgqPmDAAJU0CAUoLX4j84CXvHv3rhQqVEjKlStn175tHyfKgfT21vwPU05mQRZjJXwpQxAaodqQwN26dfOb\/bEdOa8BowxIAOrcubPGjQTg5LQ4EsgJSFfKsdD7kLqocMeOHfUGBpkPTodqI6GStd4d2eD4Oj5cQZQCOWrUKA1rNm7cqJ8UtwCY5wAJlYazQaVhhOALkVSKYty+6Nq1q+scDeXblStXOgMk1UBr3dp68hS5WrRooUQrzqZGjRp6iQBJZMHUWCAwMmXKpHn57du39XUIWWNfCdwzZ86s\/QmjsL1UKuvWrSubNm1SxpxSBgdUr149PSCIEq4OEo4RHVD6OHbsmKalsPZoysiRI6V9+\/ZK+Zm2bds21awolUgWYQWQwhLBNakiFNrp06fl6tWrqv6UH5BOHBFA8D9sNhsEsH79+qm3\/xmQhE6w77DqpJnYYYBnfC4mUFoAMOYmizpw4IAeHDUaQKY\/6wNMHCHjUSxDc0yZmLoT41B1jFIgjQpb7ZyRIsoLXFe5c+eO\/rFJc6sCCQNMair80ZBYpDI8IDEJ\/L5q1aowZo5Nm2ZKCqSeJARIetOmTT2lB+JcbDnvQD7v3LlTQy\/ANc2qAa4BErC4mcbCqXOjdpQWUD0YH8oSpljFRiiVwl+GBySAACLv4qhobJrMCFU3poBPgER1Ad6UHgARaaasQbSQMWNGgc8kRYUjdT2QlEBROzaLPUKtuYHBJSrCIID2Vm0yoMePH6ua0w\/7i7qeOnVKQUaa8PwTJ07U6yc89waSOjoVTFNgQ\/0NOULkQFxL3EvUYM2qMAVwAKSvrpJIgGRx5OKQE3wHQPJr2GtsE0V+q7Phd26vASb16C9fvqj9pA\/ZE\/0xEeYSFmOHByQpKOUGGHrSUMbEbuNkOAwOyki31V7gbGhRBqQvMRl2Eaki20EqUW08NtmN99VnSgSoXHib82UuX\/uQzlJHop4TXnpK+IP6uwZIqDJUB1XlAhUpovGOeuJ\/kRnmNlpUAMmtC0wLXpu60s\/a4cOH3QUkoZD33XGz+H9b\/PJVAv3t5xqJ9HcDbnkvAKRNJxEAMgCkTQjYNExAIgNA2oSATcMEJDIApE0I2DRMQCJtAvI\/TBrM2WIjVs4AAAAASUVORK5CYII=","height":49,"width":82}}
%---
%[output:34adf327]
%   data: {"dataType":"text","outputData":{"text":"Induction Machine: ABB M3BP 355MLB 6 261kW\nIM Normalization Voltage Factor: 375.6 V | IM Normalization Current Factor: 581.2 A\nRotor Resistance: 0.00274 Ohm\nMagnetization Inductance: 0.00376 H\n---------------------------\n","truncated":false}}
%---
%[output:3ae321bd]
%   data: {"dataType":"text","outputData":{"text":"Permanent Magnet Synchronous Machine: WindGen\nPSM Normalization Voltage Factor: 365.8 V | PSM Normalization Current Factor: 486.0 A\nPer-System Direct Axis Inductance: 0.00624 H\nPer-System Quadrature Axis Inductance: 0.00756 H\n---------------------------\n","truncated":false}}
%---
%[output:0449785c]
%   data: {"dataType":"text","outputData":{"text":"PSM EKF Fully controllable\nPSM EKF is stable.\n","truncated":false}}
%---
%[output:95e2dc4a]
%   data: {"dataType":"text","outputData":{"text":"IM EKF Fully controllable\nIM EKF is stable.\n","truncated":false}}
%---
%[output:4e85626c]
%   data: {"dataType":"image","outputData":{"dataUri":"data:image\/png;base64,iVBORw0KGgoAAAANSUhEUgAAAFIAAAAxCAYAAABJTP5vAAAAAXNSR0IArs4c6QAACthJREFUaEPtmnmIzd0fx89FlgjJlnWGGUt2ETWEFEq2CFnKmj3JLvs6ZMmSrFljGPuWJXui\/GFNjGVsyb5FKNyn1\/n9Pvc59zjf770zdzwP5jl1u\/d+v+d8zjnv89nPJxAfHx+sX7++GjVqlKpXr54KBAIqu7fbt2+r3r17qydPnqg2bdqo5ORklS9fPmU+HzBggBo7dmwIqkB6enpw9+7dasuWLWrVqlWqTp062R1Hvf+5c+eqlStXOrEoVaqUWrdunUpMTPwbyGAwGPzy5YuaNGmSKlSokEY5V65c\/4GZQQQCAMmYlJQUtXXrVrVmzRpVrFgxTzJv376NOIWrj\/2scOHCmk5cXFxEer9DhxCQFy5c0HrSZllzE9OmTfspe\/r8+bPikzdvXv0pX768nqd27dr68zu0XwJIGyhAffr0qYKL+Xz9+lV\/UEEC+j8J7vHjx1V8fLzvlBkCsmfPnqpTp06aIBulXb58WW\/O1byeFy1aVOthxLpkyZLqzZs36tmzZ540mIuPSY9xfGrVqhXiXnS8a8Pp6elhz83\/rt88o0GL382bN1f37t2LHkgMzfr1652LYSMtWrRQ3bt315sCwGgam0U8S5curapXr643\/+nTJ+fGrl27pl69eqVOnz7tC+r9+\/c9pzYBlt82wD8VSIzNoUOH1LJly1TBggWdC23WrJnvBkSvwSUCYDRgu\/og0hxWLKCadGU9JUqU0AcrIEezvgoVKkTHkXDIuHHjVEJCgho6dKinU964cWMtkiZIsYC2bds2NX78+LC9mA6wvIADAfXKlSvOfYsurVKliu4nascPpPfv32uVkj9\/ftWxY8eQmnExgAmk6V+y97Vr16oiRYqoQFpaWhC3h5PHIa9YsaLn\/JUqVVJHjhzxPcTHjx+rMmXK\/NDHfH737l3tap08edKT1oIFCxS6FFqMpeEyMRagvHQqHAdDIM63bt1SL1++VFevXtW6zmwCZO7cuVXx4sVVzpw5w94zV7Vq1RTvd+zYoWm8fv1a9e3bN+xACWQaNmyoAoSIiDKc0blzZ98QMRoWj0ZUcLW6deumu8pC+G2GYOZp8842GCL6Dx48UC6dCRDQ4FtcKNNA8hsOj1bXC7PZEiShogayQ4cO6syZM2Ehokvsvn\/\/\/sOiTVDYsA2AC1gRD5cYy7x2GMaG8WNN8ZbxuEUi+gCclpamzp8\/H5oaq5snTx5tA2TMvn37NPOw3jlz5mjARS0wh3gKEMH1Onr0qFZ\/+\/fvV02aNNG0kWLZrwaSh3Xr1tVxNpYbsfKKM81g3SsedcWiJkdNmDBBR1LSD70rrobrGxXApp8\/f\/7DuZhzMcepU6fUjBkzfNVTnz59tMjPnz9foVc3b96s9Zys0XR\/Ll68qMV5586doUQGwNOEO5GqQHJychDQatasqb59+6YmTpyoRo4cqTMfptgJaHICnLqIJ4S7dOmi3RqMFRu3uc0EkiQJc9iNZ0OGDAnbEMpfaJrc7srQIB3kDCRrw0Zv3rypNm7cqAGm4bsmJSVpKwzXlitXTi1evFhzlgtI8SPZI\/Tk4KAlGSKYKwQkRubDhw\/6NKdOnaoXY+swdCRePg0xgXM50dmzZ2vlTkM8AAQFzuResbSM92IdaKPbhB795JmMERoy140bN3Qfe24ceVJhZ8+e1YaoQYMGISAxaIg+32DAwWGwzMZ7GAOxFgbhvYg6hxASbQFy6dKlatasWU5Xg\/yGsL1fmkkWYXK0F2DierFIuzEeYwInAM6mTZvCUle20ZK+Lj1t6mXo4aEQfAiQxPjSxFDBBHxQNwQUMJdIH31NOxJISUkJQliARAxwOQRte3OyyNWrV3vqUReQXtEEfU2Rwq0RldG1a1ctctECiQFB97os\/vbt2\/V64aiBAwdqdwa6uHSoE0TdlbUqUKCA2rt3b8gF82KIMNGGOzh1O161ue\/\/mTftKvE7o1l1GeMaa9Nm4ULf7o8XkSNHDr0GGt\/mf3Nd9pz2WPoCGqIv8Ts0UQuoM4yTXwskJSUFYVm4EPbt16+f6t+\/\/w\/60VTuiBzN5QvaRglraDfzYGzxN8UFMWrbtm2YLpJIwmVscNxdVwQmTZf7IzTNdYqfCofj+tBMsZa+speQjkQvIEqYesD0CsdMa+ynJ12TyuSuCMEG2+uuxO5nu1qRdHe0QNpAuVw6+oieDqSmpgbHjBmjx40YMUINGzZMuzEuHWlf+JiEZGKvCV1i4XL66ecyUi7wvZx\/my6HSvQjOhILbjrkLo5kHeacruDB7BNITEwMEiuOHj1a1ahRw1cP\/K4vTcbwAiTWvYUSu7ES+hXGm+6QKT3mcz+VE8se\/igg\/XxSQIomD5BZMP8oIDMLQlaMyxCQZsopIxnmrFjor05Duz\/Rlqx4XTUAKk3AlVj1d7pOjfWgMlSy4ndn47cQ8nlECGSXoikwiHVTWT3e7wbxxYsXavr06UqLdrQlK6Ta5s2bF7oTkXS\/JEGjuSthkyQKWrdurXr16qX3bMbaXnlJ+kW6W7az6ALoz7yO5bKQqDCsZIXMDykjEDYbHIUDSyVGpPtdEqFly5YNXdkC9uHDhz2ZpFWrVjo07dGjhy+g\/zaQcsC2GiRURZWFgDxw4IDOI7Zv315XYpmNvN+UKVN02R8uBME9zfyW33YuT+gQ9J87d07\/JZtiN7iUhGu7du2coHtdqmW1GLvoCXM1atRIuSr3cLsCx44dC5IMBVl0GBdgJpDctpGh5iQImaJtxO58qOMxL6AYjwqAS7mRdKkDjBQHJqJvin+082dlPxLa3F6SIfJSg4GHDx8GSYiSn1uyZInmCBPI69ev6\/wdYk8MLJyXmYVKwpQkKmGpgEqGxcWlvMcTIFcKxzZt2lSP8Sqs+qd0pFTuLV++XJHnRIpDos2N2ODBgzWQXB1IO3HihL69I5ts1sCY1lcu6OUZByPPvAAXUAGF38Kl0V6Rerlcpn+bVb6ufQ0tlXsktxF1Xeks9ZEkdLFAWNPJkyeH9k8mhRMgQ8KASMbGBk7yejz3Kj8BSK44zftnMVAbNmzIDPM7x5jgC7fzLXrd9Z5nXkBSAsnaZ86c+T8gUZZkf+7cuaPFhxSaNBtIufzy2l2kSgsu2C5duvRD5QP0EPnKlSvrMhIy1UIL9UJ79+6dzlTzodhKfmcZ0h6E8FpSU1O1mqG5akkDcXFxQU6EFH3VqlX1HYZZZH7w4EG1aNEiXYAK10TiyGj0lPQh5EQNuKodTEMlhadefqRZQcFmzct9Ng6DfPz4MaSTASbS1YGNqVleA5B25V4gISEhSDKW08bhpt7FBBLuIdm7YsUKnfaPBGRmuCNS5Rk0MXJSU8nVr3gFvIulfNr0GlyBBX7wnj17wio3XJV7ociG6gcUPQbFrG+hYotbtpYtW2qj8zOANMEnk83HS5\/6HZTUpZvfct\/OOBN8138v2qb741W5F2ZsFi5cqK8r7chm165d+uIHvRQJyIyItizcK0SUwlM41q8CLTNSYI8BZEQerqdOCAkg9GNurqi56MO39arcC3N\/Bg0apIG0IxszRMyKRcdCw4ymRPmblpf3sfi6XmujyOzRo0fa\/3Vdy2SohjwWAP6tseLbmt+mD4xtoHm9FxUwfPhw3y388UDGcoAmuJEMWhiQfsX4sSwoO4wNS6NFKsbPDoBkdo+hyCaaYvzMTpIdxmWoGD87AJLZPWaLSovMgpORcX8BV8p7sf8YLmYAAAAASUVORK5CYII=","height":49,"width":82}}
%---
%[output:3bb9ae7f]
%   data: {"dataType":"image","outputData":{"dataUri":"data:image\/png;base64,iVBORw0KGgoAAAANSUhEUgAAAFIAAAAxCAYAAABJTP5vAAAAAXNSR0IArs4c6QAACPRJREFUaEPtmgVsVFkUhk\/R4qVocbcgXbYFFrdQXAIBGtyCFIdQFtcUTXAJwYMmQFJ0kQChUEILXbRZoMgixSnusPnO5pHZYYaW7Jt5QzI3aRimr\/fd+9\/zn\/Ofc67Ply9fvoiF4+XLlzJlyhTp3bu3lCpVSldy+\/ZtWbBggYwbN06yZs3qltX9\/eStbIq5J8evPpWohCQp5O8rocEBEh5SJEXv97EaSFYZExMjEydOlLRp0+qiX716JdOnT5eqVaumaBP\/9yFAHLgpXgG0HzWL+0lk2C\/JvsIjgGSVHz9+lEePHsnnz58lZ86cki5dumQXb9YDWGLYpnin0y0OLSuhwXm\/+zpLgXz69KksWbJE9uzZI5kyZZK3b9+Kn5+fpE6dWgoUKKCUz549u1l4fTOPAd7xhCTBKp0NaP7nuN88E0gscO7cuVKsWDE5ePCgDB06VI4ePapWmTdvXrXITp06KahmDv\/hh3W6rKn+BS6Lz7cA3vnkJ78HxEpEYpA+49FAPnnyRJYtWyZdu3aV2bNnq49Mnz69zJ8\/XwPP3r17pU2bNqYHG6wQqtqOwGnRP69FEq2hdbt27RQ8gHzz5o1+7tWrl2zbtk0GDhxoOpCOrDs5HxkeUjTZ6G2pj4yKipKZM2fKlStX5N27d7pH1Fi5cuUkLCxMmjZtKj4+PmYy2+lcLRfHfRu13zyTHH9tlcAcH2TYsGFSvXp1p39vKZCs6vnz53LhwgUFrGTJkhqxARMJlDFjRkmVKpVbgOQlM\/+4IZtiEr++L+jzeenf7FcpXbq0rF69Wnr06CGZM2d2uB5LgcQid+7cKZ8+fZJbt27pT\/\/+\/aVmzZqyYsUKGTlypPj7+7sNSPsXrVy5UlkREBAgtp8dLcgyIPGRAIW8OX36tOTJk0fKli0rp06dkmrVqknlypWlfv36kiZNGkuA5HBXrVolbdu21cNctGiRhISEKGs8CkiiNlbXt29fDTqNGjVSIAk2\/fr1c6klxsfHq+QaNGiQYoIUW7t2rWzcuFHdyfjx4yU4OFjp3KJFC8mVK5eCanz2KCDv37+vUTlfvnwSHR2ti8Uvvn79WqlUqFAh0wX5s2fPZOvWrbJ9+3apW7euhIeHKyboV37GjBmjOpb0lN+RurIOrHDDhg3SvXt3yZAhg2dZJKsBuPPnzyutAfLw4cNSp04dl0keAtulS5fk4sWLCpgBJMqhRo0a6psJdBEREVK7dm0tokydOlXu3bvn2VEbSr148UKg+aFDhyQxMVE3GRgYqNlN+\/btnUbJ\/+M4T548qRYIkGhXUlGyqPLly+u0mzdvVhXRoUOHFL\/GsmADiGQ2RG3KZlmyZNHF4ysJMviqihUrarZj9rAHctq0adKtW7evZbyfCkgKFgsXLlRthkUMHjxYwTxw4IB+58pobQukLZUNakP1Bg0aaMBJ6bDMIg0gARA\/xKJbtWqlBd0+ffq4NGrbAmkEm9jYWBkyZIj6ToCE9riXlA7LgMQSli9fLo8fP5Zz584JG8mWLZs6e0poRYoUMT1qG6DYA2nIny1btmg5j+j9I9bIvJYBycsp4iJ38IeIcvRdkyZNNIL\/bMNSILGEM2fOSGRkpEohBr4xd+7cqteQJBUqVHCpvzTrwCwDkmoPQSYpKUl\/0HjFixdXAEkfoTY09\/X1VeHu6cMyII3Cbs+ePTU9o2xmVFYAldwWSUKxYMKECZ6Oo3U+EotcunSp+kR0G9Hb6M8Q0efMmaM5N\/muF0gHdgRtyXfJe5EaR44ckcKFC8vNmzclf\/78Sm18Z+vWrbVfc\/fuXS+1HfGRSA2I9vcSkEHXrl3TSE6OS8DhM3LEleLcLJ9hiY+kCEDpjIIF2QRZxLFjx9QSGdD+6tWr2hRzZTvWLBAt0ZGARCYTFBQkVapUkR07dsju3bs1m4mLi9OCLpVyChe1atUyc68uncvtFmlEa9IxaJuQkKA+kMhNxkGfG19J0XfAgAEuqf64AlGXAwlwVMHJYGj6Q98HDx5oJZyWAtZHb5sCBnqS5\/ieywOAbWXPJjnAKcXRnIM5bgFy8uTJ2rcGFKPFgNwhQvN\/PpcoUUIvBpDnYqUdO3bURpinBpqHDx\/KunXrlDXswxIguQBw9uxZhwfOomg\/cMuCcho31Ix+ilHMQHsilxgUXynO0h5AwBctWlQ3iO\/lELp06SItW7bUCwdUxykec1DIKw6K+0ZUnJBhqITRo0drA470lGo9cm3SpEl6aYGekjGoo2KNzZo1E4odbgHSHjiaSFghG0crYqlQmoyGtgMFXlxA586dtZRllLgAbMSIEUI25AxILhtQdae6Tidw1qxZKvovX74stH9pIwAY6SnZlKEW6McAMs+zPsAcNWqUXl7gIGGU0a95\/\/69zkOHkaq624C0pbZxoiyahaAXAfT69evqJ20HvhWL5J4kMolBFkQe7ghI2gX8fv369f+Zh00bw2gfkILWq1dPO4ehoaFf2wzoW3w1fzN8+HDZv3+\/SjDANYYtA2iMWQoki6HE37hxY71pQU4NQPS6kUAMLAraGY0pvqMtypUWR0ACCCBCWwIWg\/dg9VDdcAX8C5BQF+CNNgMgYs20N1ANZFwoCVLVggULei6Qhl\/jVKEY1lGmTBnZt2+fbgbqQSMaYliHLbXJhGjpQvM7d+7oAUBXynKAzPO4ixkzZqiv5Xt7IGn407mkoIwrgP5GkeTGjRvqd9G7qAfboIfboRbQvHlz66ltTw8AwwrWrFmjvhJBTgUdQI3LqLbBBr3JHXPApPf84cMH9Z88w\/NcAMDXGpexyO8dAcldI1oLVOnRtcxZqVIlDTIcBgdlWLetvyDYMKC8W6j9PS2G08eadu3apdSja8g1P6jt7Oozi4Zyjjb3vXf96O9IY+fNm6e9G0dpKvKHgydoUv5zedR2tgFKZVAGiqIfSRdtbzFgTVDO\/jaaO4DkhsXYsWM1ajds2NDpGZw4cUJ\/x3U\/S4GkzkhP29Fwxx3yH7XS7z1vGZBmbsIT5vICadIpeIH0AmkSAiZN47VIL5AmIWDSNF6L9AJpEgImTeO1SJOA\/AdEFrSbIJMrSQAAAABJRU5ErkJggg==","height":49,"width":82}}
%---
%[output:5189b20c]
%   data: {"dataType":"image","outputData":{"dataUri":"data:image\/png;base64,iVBORw0KGgoAAAANSUhEUgAAAFIAAAAxCAYAAABJTP5vAAAAAXNSR0IArs4c6QAACjVJREFUaEPtm3doVM8Wx2etPysau2gURcUCPhv6sPGsoKiof9iwR0Vj\/dlL7L037AUVK6LYuy92saAGscRfRGPBLlhidx+f85j7m73e7CZ710T5ZWCJd\/fOzDnf+Z4yZ0aP1+v1qrTmGgFPGpCuMZQB0oAMDY5pQIYIxzQg04AMFQIhGsevj\/zw4YMaMWKETDV9+nS1e\/dutWjRIrV27VpVqlSpkIgwY8YMdf78ebV69Wr18uVL1bVrV9WvXz\/Vpk2bkIxvH+TVq1eqe\/fuqkaNGmr48OGJzmHKFRYWluh7d+7cEZmTFWy2bt362wMJQI8fPxZiZMmSJXRAnjt3ztu+fXs1bdo0YQHs4HnTpk2qYsWKFiNbtWolyOvG76yqbmY\/vtcrBbuaN28u4+zZs0deZ1wYyErrlZ81a5YaOnSounbtmrzTq1cvpedEcVrhwoUta2BRR44cKd\/Xrl1bxcXFWb9p1umxtKz6+7Zt21qMZ\/7ly5f76HX\/\/n1rbD3njh07fN5Dvh49egi7mccTHR3tBaBAQAYybbuQmr1Lly5Vq1atUvHx8QIejclpPK9cudLRtDX42q08fPjQMvvKlStb\/9bvXb58WYDMkyePjB8eHm65IwAHTJomCYtttzDTnE25YmNjffo5uSNPUhkZCEjTn44bN05NmDBBBI+IiFC9e\/f28XuaBSh34sSJgD7SZB8LTjN9tQkIfta0MG0ZzZo1k35YhfbxJhvtFubkI02ma6vSfj1kQCKkVmj27NlisphQsWLFfBTT78ESQLl3716iQNrNjr66jwkIbmXIkCECkAbS7vwwRTuQGmTtOrRLIQg5sc587wcgY2JivCZjEvORgRiJEObqa0X53h6Jk8JIbb4wCcVMn5sURtoZRh\/mNRdAg62tSftwu6Vg5nYm2zMNT2xsrPhILbCppBlskgKkKRDj0YdGoEmuj2zYsKFPmqLNG0aaLE\/MR+r0xiSG3Ufazdd0EQQXDdaRI0csV6J9sPbxlmknJCR4zYhKBDx16tQPURtQtMOH4k4rbjdbnQvaV9wpahN4SEe0LJhi8eLFreiJ34uOjlZVqlTxCSJJido6kNoDoj26M5bWSy8AUXvBggVq8uTJEp2RnUAGQ83MJll5pN3v\/CrPyclveffs2bMB88jk6uYKyHfv3qmFCxeqY8eOqfTp06uWLVuqLl26+E10kyug0\/uaLbDWHhj87UIYK6k7m+TK6QrIffv2SRDo37+\/+vLli5oyZYr42mrVqiVXjhR5P\/7Vx6DnCQ\/7w29fV0A+ePBAZc6cWeXPn1\/BToDs1KmTKlu2rELozRefqDN\/vRYB4l\/\/rYQbhYJGwmXHV3P\/8\/OA1CPrSE9AID\/Mli2b\/BT2539div\/rdL865t\/KHytdMdJU89OnT2r+\/PkSaXW0\/tfkc9Yr4bn9m4Y5VtEAZvQz4Q0P+7GQAYDtqhX8eYxctmyZql69uqpUqZJMQtpERNTlKUw4kG\/5maCk5NiuGLl+\/Xr19etXidQEG\/ItgK1bt25K6vBLzOUKSJ3+wMTPnz+rDh06SLDJkCHDL6FcSgrhCkgnQTkm37t3r7CTiE7Njm1cunTpXOn1\/PlzqSjdvHlTlStXTo0ePVoVLOjrt3R+qSfSeaariZVST548UWvWrFGDBg1KNEcOOZAoyiYfpT0ejxo\/frzq2LGjbK2CbbiPmTNnSiG5Xr16Unrjw3YyU6ZM1rA7d+5UhQoV8ik4Bzsn\/QigjMmHRfNXVQ85kGzBYCUlNNqWLVvkr34ORjF2I9Q4x44dq\/Lly6dg58SJE61nPSb7dXx0hQoVgpnmhz4AGRMTo+7evauuXr0q8yV2PBFyIMkp2dnAHNrp06fVmTNn\/B40BdKa3RPHAbA7e\/bs6v3795L8U7XSh3AsHscVKH779m2RYfDgwapkyZKBhg\/4O\/OvW7dO3EmKAlmzZk1Vq1atkAJJ0RZFSPadgCTYHTp0SADEDK9cuSIuBsBz584dECx\/L6QKkHZT5pmgQ0Ej2GY3ZZ4pjUVFRSUKEhkFpS\/Ob9weHacKkAQb8kvYQzP338ECSbCZM2eOBBFyVH3Og+nqVIvIit8cNWqUKlKkiLpx44Ziw8D8OXLkCHZq6ZcqQOr0ByX4d2RkpGrSpIlEcDdNsxL\/R1FkzJgxEnj2798vwzLHxYsXxY9+\/\/5dCikEqBIlSriZNvWAdC31bzpAyKP2b4qDa7HTgHQN4f8HSAMyDcgQIRCiYdIYGWog2SPTAt1LZAtILmfeRAtWltevX8vRxNOnT63baf7G4nycvLBz586uk+xgZTbP6PV5uY+PTA0gSXSnTp0qyXagY1SEdQskeS0fNyU9DWS7du18yOSJi4vzPnv2TC460UC5devWsjuhpvjx40dJdtkxHD9+3Lr5oG8ZLFmyRN6lmMA7Tsn3o0ePhElHjx6VIgI7EP7qu4XmzQvNFLNP1apVZTvIeRDjlC5dWi5MURViTuSlOcmMXPQhMd+1a5fighf3H0nWaVSl2BWR4NMC6WMHEgKCnycqKsrLINTctGmz4d+wYYPsEtgnm4da2rQpV7F7SUhIUH369LGUGjhwoHWGo1kECPXr11eNGzeWygyKsQ\/meMKpqsI+mVpjo0aNVNOmTdXJkycVd3EoY9GvQIECasCAATInsvPdixcvHGXWd4O4eoJslMTmzp0rumEFAMe9JAiELEnRB9k0IwFyxYoVf6c\/pmlTSeHDaqIUoDIp\/lMDWaZMGTVs2DD56KIABQoE6datm+WCrl+\/LhNhwoyHaSE02zzqhk5AcrGTxaOQmjNnTimw3rp1SxjJdxxp0Nc0dS5WOckMkFiA7mOXkbmQoW\/fvrJQgfRxYiQMlxu7derUUdu2bbMYae5rMQlqcAQXE0jMS5um6bjt5X3K\/5s3b\/apLlO2pxzG1T0nIJ36OPlIE8hcuXIJYDDelBkgzQAFEcwjY12Q4GojYOrr0lonuz5OQEqwiYiI8FLGP3z4sAXk4sWLpWLCQRbFBlaRv3ZGUuEh6hYtWlT6MgnNLH7iJqhcwyQYSSVn0qRJEvnp5wSkvc\/bt2+lOEGxGL+to7YJJLVIJ5ntQKJb3rx5rYo9FrNx40a5doNcgfRxAhLieSIjI72Y3YEDB6wjAqIoJoWJQlvOqXHoOGZWlMItDEUpTJ5A9ebNG2EEYOuiLqCS4nDJnncAjzIblWzGASAnIOnDnJgjY23fvl0q35gdfZ2A5L+uOMncokULH0Zy1xy5cS+wGPAABz+LCwqkjxOQQrQLFy54qSrDgp49e8oVYoQnGmJiWhkUwzHj1HHaAMBpHne5iZasMk6Y4GBPL3DwBAXGK1++vPgi5vRX59N9Ll26pBo0aCD1TZQ0zdRkZNasWR1lnjdvnjp48KAFPhaBG2MhsRDcE3MxPsEvkD5OQHKc8o\/b2QDEt2\/fBEQapo0PZ3HJUAI1JyC5B\/+PAxKrwCfC7IwZM4qVUSAmHiSlJQbk\/wBNv7TM0cyYeQAAAABJRU5ErkJggg==","height":49,"width":82}}
%---
%[output:85659eea]
%   data: {"dataType":"image","outputData":{"dataUri":"data:image\/png;base64,iVBORw0KGgoAAAANSUhEUgAAAFIAAAAxCAYAAABJTP5vAAAAAXNSR0IArs4c6QAACjVJREFUaEPtm3doVM8Wx2etPysau2gURcUCPhv6sPGsoKiof9iwR0Vj\/dlL7L037AUVK6LYuy92saAGscRfRGPBLlhidx+f85j7m73e7CZ710T5ZWCJd\/fOzDnf+Z4yZ0aP1+v1qrTmGgFPGpCuMZQB0oAMDY5pQIYIxzQg04AMFQIhGsevj\/zw4YMaMWKETDV9+nS1e\/dutWjRIrV27VpVqlSpkIgwY8YMdf78ebV69Wr18uVL1bVrV9WvXz\/Vpk2bkIxvH+TVq1eqe\/fuqkaNGmr48OGJzmHKFRYWluh7d+7cEZmTFWy2bt362wMJQI8fPxZiZMmSJXRAnjt3ztu+fXs1bdo0YQHs4HnTpk2qYsWKFiNbtWolyOvG76yqbmY\/vtcrBbuaN28u4+zZs0deZ1wYyErrlZ81a5YaOnSounbtmrzTq1cvpedEcVrhwoUta2BRR44cKd\/Xrl1bxcXFWb9p1umxtKz6+7Zt21qMZ\/7ly5f76HX\/\/n1rbD3njh07fN5Dvh49egi7mccTHR3tBaBAQAYybbuQmr1Lly5Vq1atUvHx8QIejclpPK9cudLRtDX42q08fPjQMvvKlStb\/9bvXb58WYDMkyePjB8eHm65IwAHTJomCYtttzDTnE25YmNjffo5uSNPUhkZCEjTn44bN05NmDBBBI+IiFC9e\/f28XuaBSh34sSJgD7SZB8LTjN9tQkIfta0MG0ZzZo1k35YhfbxJhvtFubkI02ma6vSfj1kQCKkVmj27NlisphQsWLFfBTT78ESQLl3716iQNrNjr66jwkIbmXIkCECkAbS7vwwRTuQGmTtOrRLIQg5sc587wcgY2JivCZjEvORgRiJEObqa0X53h6Jk8JIbb4wCcVMn5sURtoZRh\/mNRdAg62tSftwu6Vg5nYm2zMNT2xsrPhILbCppBlskgKkKRDj0YdGoEmuj2zYsKFPmqLNG0aaLE\/MR+r0xiSG3Ufazdd0EQQXDdaRI0csV6J9sPbxlmknJCR4zYhKBDx16tQPURtQtMOH4k4rbjdbnQvaV9wpahN4SEe0LJhi8eLFreiJ34uOjlZVqlTxCSJJido6kNoDoj26M5bWSy8AUXvBggVq8uTJEp2RnUAGQ83MJll5pN3v\/CrPyclveffs2bMB88jk6uYKyHfv3qmFCxeqY8eOqfTp06uWLVuqLl26+E10kyug0\/uaLbDWHhj87UIYK6k7m+TK6QrIffv2SRDo37+\/+vLli5oyZYr42mrVqiVXjhR5P\/7Vx6DnCQ\/7w29fV0A+ePBAZc6cWeXPn1\/BToDs1KmTKlu2rELozRefqDN\/vRYB4l\/\/rYQbhYJGwmXHV3P\/8\/OA1CPrSE9AID\/Mli2b\/BT2539div\/rdL865t\/KHytdMdJU89OnT2r+\/PkSaXW0\/tfkc9Yr4bn9m4Y5VtEAZvQz4Q0P+7GQAYDtqhX8eYxctmyZql69uqpUqZJMQtpERNTlKUw4kG\/5maCk5NiuGLl+\/Xr19etXidQEG\/ItgK1bt25K6vBLzOUKSJ3+wMTPnz+rDh06SLDJkCHDL6FcSgrhCkgnQTkm37t3r7CTiE7Njm1cunTpXOn1\/PlzqSjdvHlTlStXTo0ePVoVLOjrt3R+qSfSeaariZVST548UWvWrFGDBg1KNEcOOZAoyiYfpT0ejxo\/frzq2LGjbK2CbbiPmTNnSiG5Xr16Unrjw3YyU6ZM1rA7d+5UhQoV8ik4Bzsn\/QigjMmHRfNXVQ85kGzBYCUlNNqWLVvkr34ORjF2I9Q4x44dq\/Lly6dg58SJE61nPSb7dXx0hQoVgpnmhz4AGRMTo+7evauuXr0q8yV2PBFyIMkp2dnAHNrp06fVmTNn\/B40BdKa3RPHAbA7e\/bs6v3795L8U7XSh3AsHscVKH779m2RYfDgwapkyZKBhg\/4O\/OvW7dO3EmKAlmzZk1Vq1atkAJJ0RZFSPadgCTYHTp0SADEDK9cuSIuBsBz584dECx\/L6QKkHZT5pmgQ0Ej2GY3ZZ4pjUVFRSUKEhkFpS\/Ob9weHacKkAQb8kvYQzP338ECSbCZM2eOBBFyVH3Og+nqVIvIit8cNWqUKlKkiLpx44Ziw8D8OXLkCHZq6ZcqQOr0ByX4d2RkpGrSpIlEcDdNsxL\/R1FkzJgxEnj2798vwzLHxYsXxY9+\/\/5dCikEqBIlSriZNvWAdC31bzpAyKP2b4qDa7HTgHQN4f8HSAMyDcgQIRCiYdIYGWog2SPTAt1LZAtILmfeRAtWltevX8vRxNOnT63baf7G4nycvLBz586uk+xgZTbP6PV5uY+PTA0gSXSnTp0qyXagY1SEdQskeS0fNyU9DWS7du18yOSJi4vzPnv2TC460UC5devWsjuhpvjx40dJdtkxHD9+3Lr5oG8ZLFmyRN6lmMA7Tsn3o0ePhElHjx6VIgI7EP7qu4XmzQvNFLNP1apVZTvIeRDjlC5dWi5MURViTuSlOcmMXPQhMd+1a5fighf3H0nWaVSl2BWR4NMC6WMHEgKCnycqKsrLINTctGmz4d+wYYPsEtgnm4da2rQpV7F7SUhIUH369LGUGjhwoHWGo1kECPXr11eNGzeWygyKsQ\/meMKpqsI+mVpjo0aNVNOmTdXJkycVd3EoY9GvQIECasCAATInsvPdixcvHGXWd4O4eoJslMTmzp0rumEFAMe9JAiELEnRB9k0IwFyxYoVf6c\/pmlTSeHDaqIUoDIp\/lMDWaZMGTVs2DD56KIABQoE6datm+WCrl+\/LhNhwoyHaSE02zzqhk5AcrGTxaOQmjNnTimw3rp1SxjJdxxp0Nc0dS5WOckMkFiA7mOXkbmQoW\/fvrJQgfRxYiQMlxu7derUUdu2bbMYae5rMQlqcAQXE0jMS5um6bjt5X3K\/5s3b\/apLlO2pxzG1T0nIJ36OPlIE8hcuXIJYDDelBkgzQAFEcwjY12Q4GojYOrr0lonuz5OQEqwiYiI8FLGP3z4sAXk4sWLpWLCQRbFBlaRv3ZGUuEh6hYtWlT6MgnNLH7iJqhcwyQYSSVn0qRJEvnp5wSkvc\/bt2+lOEGxGL+to7YJJLVIJ5ntQKJb3rx5rYo9FrNx40a5doNcgfRxAhLieSIjI72Y3YEDB6wjAqIoJoWJQlvOqXHoOGZWlMItDEUpTJ5A9ebNG2EEYOuiLqCS4nDJnncAjzIblWzGASAnIOnDnJgjY23fvl0q35gdfZ2A5L+uOMncokULH0Zy1xy5cS+wGPAABz+LCwqkjxOQQrQLFy54qSrDgp49e8oVYoQnGmJiWhkUwzHj1HHaAMBpHne5iZasMk6Y4GBPL3DwBAXGK1++vPgi5vRX59N9Ll26pBo0aCD1TZQ0zdRkZNasWR1lnjdvnjp48KAFPhaBG2MhsRDcE3MxPsEvkD5OQHKc8o\/b2QDEt2\/fBEQapo0PZ3HJUAI1JyC5B\/+PAxKrwCfC7IwZM4qVUSAmHiSlJQbk\/wBNv7TM0cyYeQAAAABJRU5ErkJggg==","height":49,"width":82}}
%---
