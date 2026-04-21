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
%[text] ### Settings for control loops
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
grid_nominal_power = 1000e3;
application_voltage = 690;

if application_voltage == 690
    % trafo data
    us1 = 690; 
    us2 = 690; 
    fgrid = 50;
    eta = 95; 
    p_iron = 1800;
    if ~exist('ucc_case', 'var')
        ucc_case = 50;
    end
    switch ucc_case 
        case 1
            ucc = 50;
        case 2
            ucc = 25;
        case 3
            ucc = 50/3;
        otherwise
            ucc = 5;
    end

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
hwdata.afe = three_phase_afe_hwdata(application_voltage, afe_pwr_nom, glb_time.fPWM_AFE); %[output:5294b408]
hwdata.inv = three_phase_inverter_hwdata(application_voltage, inv_pwr_nom, glb_time.fPWM_INV); %[output:816b471d]
hwdata.dab = single_phase_dab_hwdata(application_voltage, dab_pwr_nom, glb_time.fPWM_DAB, fres_dab); %[output:9ec6370b]
hwdata.three_phase_dab = three_phase_dab_hwdata(application_voltage, dab_pwr_nom, glb_time.fPWM_DAB, fres_dab); %[output:407f7bf5]
hwdata.cllc = single_phase_cllc_hwdata(application_voltage, dab_pwr_nom, glb_time.fPWM_CLLC, fres_cllc); %[output:0b50933f]
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
frt_data = frt_settings(test_index, test_subindex, asymmetric_error_type, enable_frt_1, enable_frt_2, start_time_LVRT);
grid_fault_generator;
frt_data.k_frt_ref = 0;
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
parasitic_dclink_data; %[output:146d185e]
%%
%[text] ## INVERTER Settings and Initialization
%[text] ### Mode of operation
motor_torque_mode = 1 - use_motor_speed_control_mode; % system uses torque curve for wind application
time_start_motor_control = 0.25;
%[text] ### IM Machine settings
im = im_calculus(); %[output:3bbce04e]
%[text] ### PSM Machine settings
psm = psm_calculus(); %[output:081f7cc8]
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
psm_ctrl.ekf = ekf_pmsm_setup(psm.Rs_norm, psm.Ls_norm, 1e6, glb_time.ts_inv); %[output:7f71d970]
psm_ctrl.kp_i = 0.25;
psm_ctrl.ki_i = 35;
%[text] #### Induction Motor Control
im_ctrl = ctrl_im_setup(glb_time.ts_inv, im.omega_bez, u_im_scale, im.Jm_norm);
im_ctrl.ekf = ekf_im_setup(im.alpha_norm, im.beta_norm, im.gamma_norm, im.sigma_norm, ... %[output:group:305b7c14] %[output:3baaba60]
        im.mu_norm, im.Lm_norm, im.Jm_norm, glb_time.ts_inv); %[output:group:305b7c14] %[output:3baaba60]
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
sogi = sogi_filter(omega_set, sogi_delta, kepsilon, glb_time.ts_afe); %[output:120b3b52]
%[text] #### Current control parameters DQ PI
dqvector_pi.kp_inv = 0.5;
dqvector_pi.ki_inv = 45;
dqvector_pi.pi_ctrl = dqvector_pi.kp_inv + dqvector_pi.ki_inv/s;
dqvector_pi.pid_ctrl = c2d(dqvector_pi.pi_ctrl, glb_time.ts_inv);
dqvector_pi.plant = 1/(s*grid_emu.trafo.Ld1 + 1);
dqvector_pi.plantd = c2d(dqvector_pi.plant, glb_time.ts_inv);

G = sogi.fltd.alpha * dqvector_pi.pid_ctrl * dqvector_pi.plantd;
figure; margin(G, options);  %[output:32a6ec83]
grid on %[output:32a6ec83]
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
lithium_ion_battery_1 = lithium_ion_battery_setup(nominal_battery_voltage, nominal_battery_power, initial_battery_soc, glb_time.ts_dab); %[output:13ac8729]
lithium_ion_battery_2 = lithium_ion_battery_setup(nominal_battery_voltage, nominal_battery_power, initial_battery_soc, glb_time.ts_dab); %[output:685a0eea]
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
%[output:5294b408]
%   data: {"dataType":"text","outputData":{"text":"Device AFE_THREE_PHASE: afe690V_250kW\nNominal Voltage: 690 V | Nominal Current: 270 A\nCurrent Normalization Data: 381.84 A\nVoltage Normalization Data: 563.38 V\n---------------------------\n","truncated":false}}
%---
%[output:816b471d]
%   data: {"dataType":"text","outputData":{"text":"Device INVERTER: inv690V_250kW\nNominal Voltage: 550 V | Nominal Current: 370 A\nCurrent Normalization Data: 523.26 A\nVoltage Normalization Data: 449.07 V\n---------------------------\n","truncated":false}}
%---
%[output:9ec6370b]
%   data: {"dataType":"text","outputData":{"text":"Single Phase DAB: DAB_1200V\nNominal Power: 250000 [W]\nNormalization Voltage DC1: 1200 [V] | Normalization Current DC1: 250 [A]\nNormalization Voltage DC2: 1200 [V] | Normalization Current DC2: 250 [A]\nInternal Tank Ls: 3.819719e-05 [H] | Internal Tank Cs: 1.151294e-04 [F]\n---------------------------\n","truncated":false}}
%---
%[output:407f7bf5]
%   data: {"dataType":"text","outputData":{"text":"Single Phase DAB: Three_phase_DAB_1200V\nNominal Power: 250000 [W]\nNormalization Voltage DC1: 1200 [V] | Normalization Current DC1: 750 [A]\nNormalization Voltage DC2: 1200 [V] | Normalization Current DC2: 750 [A]\nInternal Tank Ls: 1.200000e-04 [H] | Internal Tank Cs: 750 [F]\n---------------------------\n","truncated":false}}
%---
%[output:0b50933f]
%   data: {"dataType":"text","outputData":{"text":"Single Phase CLLC: CLLC_1200V\nNominal Power: 250000 [W]\nNormalization Voltage DC1: 1200 [V] | Normalization Current DC1: 250 [A]\nNormalization Voltage DC2: 1200 [V] | Normalization Current DC2: 250 [A]\nInternal Tank Ls: 1.548074e-05 [H] | Internal Tank Cs: 2.840705e-06 [F]\n---------------------------\n","truncated":false}}
%---
%[output:146d185e]
%   data: {"dataType":"image","outputData":{"dataUri":"data:image\/png;base64,iVBORw0KGgoAAAANSUhEUgAAAIYAAABRCAYAAAAXQt4GAAAQAElEQVR4AezdBbRVRRcA4H2xu1vXEltRxMZGxVZE7EAxsAO7FUxs7FbsVrAVA2yxFZcd2N1d\/O+b9Q\/r+v73+Hlxw8dlsd85Z86ciT17ds2eue1GVdm\/H374YdTNN988qkePHqNWXHHFBO6leVdlzW2zzWkXVfKvDsPxyCOPxDbbbBOffvppHH\/88XHTTTclOOWUU+LHH3+MrbfeOm677bYqaXHbbkbVEEYdN4jxxhsvbrzxxthtt91i\/vnnjxlnnDFB+\/btE8HUcY2YZZZZ2vaIVEnvqoYwppxyylhmmWXijTfeiC+++CJ++eWXuOaaa+LQQw9NV88IZ6mllqoS1LXtZlQNYfz5559x1FFHxbbbbhvrrbdebL\/99vHggw\/G0ksvHU899VScdtppQdy0ZDhefvnlRHx1ukustNJKscQSS8Tmm28eH3\/88VgXe\/7558f9998\/VvnlW2CBBaK4vqOPPjqJxZ9++ikR\/auvvjpWZZU7U9UQxjfffBOff\/553HnnnUmc\/P777wGJ3bt3T1d6x5dfftli\/HTq1CnuvvvuePjhh2P48OEx99xzp+cWF9xIAYsvvngqX32PPvpoytW\/f\/+YaKKJkh614IILprTm\/DFR\/vrrr+Z8+n+\/qRrC0EniZJJJJomJJ544IW788cdPHSBCIFKelNBKfxDf999\/n\/SYP\/74I0466aTEUYg099LAiSeeGETY6quvHs8991yqXVuuuuqqxHlWWGGFRLwU5PSykT\/61qtXr3jllVfizTffjJ133jlwMfrVvvvuG507d04ckrKtXul77bVXSqN49+7dO+XHtehh66+\/fjzxxBPx0EMPpXYst9xyiduOGDEiTbKNNtoocWHtwxmvuOKKWHXVVVN5uHEjzUzJFScMA4NT4AaQkVpVwj9PPvlkdOzYMeaaa67o0KFD0meIlXvuuSc++OCDMKvB119\/HbfccktI\/\/DDDxOH8ay9micPMfDAAw8ka2qyySaLwYMHh3djgmmnnTamn376MOg5H1E5zzzzpEFW3+uvvx6ffPJJXHLJJYGjeI\/LwFH+Rvuuvfba1Jf77rsvEOnjjz8eCE8Z8n333Xex5JJLpvbNOuusodwhQ4bEySefnNpKfMvXEFSEMLA\/ImO11VaLrl27xsYbbxxmAxaP6vfcc8946623AjIon\/369Yt33nmnofY3Oc2sfOmll1J5Zq3ZdOSRR8Zjjz0W66yzTkwwwQQJtOvpp5+OYcOGpXSzfYoppgj5VWqwDAzriTg655xz4vnnn\/eqybDKKqskPeSGG25I4gXBffbZZ0kRh49CoRCzzTZbLLLIIqPL7tKlS2gPLnvggQemvKeffnpcffXVQezKyKrD\/QqFQrRr1y61HfdFnL\/++muAaORf2QkDu6U7oP5BgwYlOU\/+UtQuuOCCxPrmmGOOAAhn+eWXD0hALBDRSD+alQxJK6+8ckIQqwdR5IJwr+LnnJ6vlEcDgmCBwezbt29+3ejVTMctcI2c6dJLLw19R2T77LNP4mRElQlkQOVzT\/S5LwaK86677hrwuemmm8ZOO+1U\/Pof92Pqzz8y1j2UnTDMvMMPPzxZH8UDPeGEE8bCCy+cZg6En3322Umuk+3AO3nq2txq\/yGfSKDTmFmIE0GAu+66K8xWdbuXRkEmOjSAtYR1G2RExaLioPOuMZDvvPPOi4UWWijpNTkfFr\/uuusGxdhAIzJ4wv61TztHjhwZOF3+Jl+\/+uqrxDlYcjhBbl9+39xr2QnDLEW5fBWb15mK5HsGZh0OQUHCJShPgNI3YMCAMEub29H83QsvvBBrr712UtaWXXbZJEIOOuig2GSTTQJiiQqAY6211lrRrVu3lI5ImNDZwUbUIBpXbfWt+1xPvlJWc33KNeAUzfzeVd3HHntsYvV0ADrQddddl8QrYiP+iNSZZppJ9n8A3WSaaaYJnG\/LLbdMRPfiiy8m0fKPjE18KDth5PbpjFm6xRZbBCSQr9zhPXv2TJ2DREgBlD7fISjX5gIZTTdQJvFFEaW0mZnKxqm8B+6lGch+dToOfePWW2+Nc889N+lF3hFv8oKcv7htCOW1115Lyp\/6nn322aDPTD755AGID22CBzoO7oAAcMvjjjsucCREq\/wzzjgj6QlE0C677BJAXdrHglK29iFexAV\/HIT0DPlYOtrjXp3q1gbPDUHFCANb\/uijjwIhGBjKFdOMhTL11FMHLT832EzBhrHtnDYuXDnHEAouSn9gsmaOVer+V4wwyHVaMe07d5J4YQ5KJ2fJW3DllVcGxatYJ8nftOUrvYr1hpvgOKyXcvW3YoRhkOkPOAbdgp6x2WabBdFCds8wwwzJXU3+8iMcc8wxgW2WCzHjej0VIwyIp7RddtllccABB8SZZ54ZfAEUNeYX+WiWmC3kLZ3EN9lGd1+D0mGgooRx8cUXx\/777x9cvCyOPn36RPfu3YMixd+Ru+2eo4nCdfvtt+fk2rWEGKgYYXD0MKtOOOGEoGzOO++8cf311wdPHiuEPOW2BmussUYyKznGeEhLiI9a0f\/FQMUIgyePAjrppJP+tymRHDUIY7\/99gvmIY8iYLbRzrPpNfqD2k3JMFAxwmCPUzAvv\/zyFJQjQIcuMd100yWHUsl6XCt4rDBQMcIoFArBb2EByiofMcGfQRHNy+1j1YNappJgoOyEQYTwV3BkcVhxO1te5oHk0uXIkqckvR2XCm1hX8tOGJROrmRL7RZ++C\/4M0BeE3nmmWcCwfD\/CyixYsjR1cK+1j5vAgbKThj0Cmsj9957byAEMRjWLgBrhFgZOHBgMF25yQWqiFSynQA3aULfallbgIGyE0ZuKzFioBFKTrMmIt0KrNgE6e6ZriwY76TVoPQYqBhhTDXVVPHbb7+lABViAlgTEXuACIS25e5bNxGIUnOJZ4yU\/loxwhDcy7lFdIjLyGsiREavXr1CNBQPKBf5HnvsESKbrK+UHiW1GmCg7IRBfOT1Ds4s8Qb110SsKvJviIAW2MrBteiii2pvDcqEgbITBh+F9Q7rHgJQrIPoKxOWpSJkTugbTmHdhLVCx8BV5JG3BqXHQNkJQ+ST9Y4jjjgixFIadOshopgsr7NULL8THawXIEBFBDdvaclRUqsgYaDshJFqrfvDFM0hc9ZDgFA7ZirrA6fgCQUcXwJhKaB1n9b+lwEDFSOMxvomEhwB2FeS84jyksZ0zWm1a2kxUHWEwYy1sdkWPJFdQFSXQGGR2KVFR630jIGqIwwNo3cMGzYsHX\/At8ErakuBdzUoDwYqShisjIMPPjjFdjJJhc2\/99576dkutK222iodmEIhLZVVsvu1r0Y1wYsXHBzf3NAvvjhnu1aD5pBSxQiDY8sucsvuGj777LOH3V6269mDmY9Zuuiii9IOblZLjvuUv7Vgv1sWimqALW5bNcAPQy+PV249P4Y+8UKrQXNwVTHCsMr6999\/B85gfyY3eO\/evdOhIpRM0VrAmomdW\/LaWtCcTo7pm7luHBXVACtc+0kUwzs9bw0wdN1rorlw5bKXBhhT\/xt713qE0VgNjaRb90AAP\/\/88+gcRAuC4QQbnVh343gCm5PqbseZ\/wetOWeAc7ZYMJoLt+2+WIDmIK1ihGHdg0K5++67p32WosV5PsVhbLjhhun8Co4vQNdwMk0pRElTkGahj4WEyzmToinf\/tvyVowwIIrb+4477gg6Be+me4tpjmx8++230xkWHF\/2lojJIE58VymwbsOVL27EPlOOuEq1pdT1VpQwHBHk+ICZZ545BgwYEGuuuWZQSA877LB4r846Ef4HbAzGUWz5LzVCxlQ+UedoSb4We2vtvx1T\/n\/zu4oRhmOA7CMhSkaOHJmUUAHB1k+cS2VXOWIBfBl2alfSwcWKEotKSTbgdCN9cN8WoWKEIUjHNnxRW8OHD0+Hohl8RyziImI1xGZksLBWXyltrQER9+F4glwesxnnsofWcQIOVKEoc9cjEPnoSLY6uG+LUDHCwI7tYN97773ToWRiM5xiR247dYZiKlA4QykcXNZfEB6uhQPkAaZLWOnldLO6ayvlu+++m\/a7OLeL5SS\/Nudv2tq1YoQhgsspMrR8B3\/MOeecScdwwIdjowXvFIMBKo4PbY2BwAWcascKKi6PO94yvxABq8BWeB2HRAdCtBTkzp07p8NPir9r3fvKllYxwtBtvgyRWViyMzEsmCESMZ5nnXVWOjnX1kSAtbe2g4v5a18s8aU9QOAQpTLHfhQKhWQ604MQCQJ1zpXv5G+rUDHCIKtxDGYo3aJHjx6jz8Hq169f2rboJJkMIrvM4HIMBE5CnyhHXdVaR8UIw6wkq+0vsYkZi3ZGpRmLdVt2d5JdBiuuOEypEckMpRRzZqlL1Dr9gmve87gCFSOMYgSzNgTjYNXOyaDxEyfFecp1XygUAhHSM1gnXPHa5nS8crWhGuqpGGGQ4RxbzFJOI5o\/D+j777+fTthlhRAfpbRKGhsAbnn6B1NVWOEOO+yQDqRtLH9bTK8YYRQKhRCLccghhyQfhuOVsHAOrewS59\/Ilgmlr7WtkjygdBzWUH6my9jWIIpd\/ThIfjeuXCtGGBBs7YMZyG9At5hvvvnCAa2UUpZIMVBIRXJh776tQWkxUDHCsPGIY8kP1Fgky4AwmK6cT07uJU4su8tvPwqiGTNKam9bAwMVIwweTqKDbsH7mIFIQRh+OoEp271793AqLi+pdyyZ1uh4rYwxY6BihMHyYH5asazfRISBEHK6xSuihu8jp9WupcVA2QmD95IX04GuiGKDDTZIv\/ST9QkxnrYoskoop9K322670T\/IUskV1tIORXWVXnbC4EByEHqfPn2CvmDlEpF4Bt5ZTMs\/08TzyU3uLG2ixU9aVBcK22Zryk4Y3M2W3C1zC+WjfBYKhfT7HYJ\/maRO8HM6\/tChQ9P5ns7o6tWrVxoBpmS6qf0pKQbKThisCxyCxYErWLqmeGb9gS7Bl2FbAUXTwbC4jAhyRFNSbNQKH42BshMGa8RA27RsqX3HHXdMPxxH99AqcQ4UU+8Rj7MyHOaGe\/hWnhqUHgNFhFH6ynIN9pHke1fEkDkGS4VVYn2CaLHcTfxYQ8Ft5G8qiBflD8nudVeHzTa1nGrLzzPrkH5cluuevlbcRv12TntxWr63MIgzN+YwrAhh5MY1dM3cwmqrFU0707p06ZJ0kJZYJMQV93YGAce5fiuoTOL8\/G+4IoZBgwZFc+NCrE8JLXD0REP9rQhhOCe8Y8eOKQBGJJTGudpD4mzPDh06hLULz4MHD04\/cSkO1CpsQ51obprZZHmfteNYpxEjRgTz2eIZc9msUrZodr+JhtPYFde3b98QvW6WuspjtpqhiMxhtvIqR4CzQfRemXbt225JZyIazVhWlzQBQyaEAXdwTOaiZjZQTwZxqiaRFemc1tgVd9QesNhii6X9wDiwwChbIRgD9b8tO2EQD5a07RcpBmwRu4dYX1uj8wAAA71JREFU1opOAJt7DJYQQH6P+h0Y22eHyCI0IGpMJLpvKbj591NtqvabKfaMGBgWk3M6WEV+s027DYSB9m1D4FshA6K8rO3QpxC3vNqPc8ljtjro1joRlz8dCvHAg4g255Q5uRDxWCaAB2VkkJ+\/Jz+7FvdRPw26dNwRp9RPep2lCO3SF\/0ntuUrhrITRnHl9e8poMLzmaYOZ8sbm12F+rVElFx44YWjNzD5OQw\/GKd+YsrMs48F8hAjpCJEp\/jgIiLZIbFQKKQfyuPK921DYGANADHIskJo+Yd6zVabt5nc6ie+BBwbdLqVpX46A+6UFxSZ7uqrHw+CYKQXt6G4jyadqLj8nn5mIdImLxNQOuKE74a2QVQNYTBFLZJBpAhtbBdrNltElHtPCdWhUgB2arsAYoBU0eCW\/yEfF8t1ctVj\/\/m5\/hWL9ouKygC4B9FTP19+VpbA6Pz87bffprBGUfI4FDHGOkM4OU9Tr9pvbw4c8iIXCoX\/W0TVEIaWGnh+C84vegcKd4UkJiuOIl8poH379qF8BAGRfqTu1FNPTQE6WL1ILum4CiKi75j5LCjpZL52mY24gBltltKNiBTvGgLEiAAQiAmhn8IeO3XqlPQYug8uVv9bQU5jEmnF+Ykr\/SFCtDm\/w7G03cTLaflaVYSRG+UqViMrX55LDUSFn8TApbjhBQbZp4qlUzKxZYoxAsFFsH3PthKwDOgiiEXQj8Hu2rVrEFPEn7TG2i+mtVAoBEWQ25\/\/hrgxWFlB91z\/e3XQkwxs\/XfFzwgOtxAZhwsjMlf6Dj1GX3CS4m\/cVxVhoGAzliZPzvKQslb8AgEdg5dUo5sKLJyGBsfAg1yeOimNZrwf6xOUXCgUwr6THE2GFRuMQqEQ1nXoFEOGDAmLf\/379w8z0qyXDogVaerXjlyXeqUZGOGNOKN61VUoFMKkMHDdunWLQuF\/WT8LBmfBZZShvcrL5buqT1u8o+fgdgDRIwZ9tX+mITFVNYSBgpmNEG+GaLyOYamUI+8Rjg63dWACIxAcyIaohvqLGHr27Bl0EITaUJ4xpTHFORZxvYbytWsosVJpOAKv6MCBA8PJfczWDCifaVWptuV6WRN0n\/xciiuTniKOAzU0m3OdrBx+kULhfzlKztPYlU5FbOJmDeWpGsLA2nAJrK4h8E6ehjpRS2t9DFQNYbR+12oltgQDNcJoCfba8Lc1wmjDg9uSrlUjYbSkP7VvWwkDNcJoJUS2tWJqhNHWRrSV+lMjjFZCZFsrpkYYbW1EW6k\/\/wEAAP\/\/WD1CPwAAAAZJREFUAwCLWZROax5s4gAAAABJRU5ErkJggg==","height":81,"width":134}}
%---
%[output:3bbce04e]
%   data: {"dataType":"text","outputData":{"text":"Induction Machine: ABB M3BP 355MLB 6 261kW\nIM Normalization Voltage Factor: 375.6 V | IM Normalization Current Factor: 581.2 A\nRotor Resistance: 0.00274 Ohm\nMagnetization Inductance: 0.00376 H\n---------------------------\n","truncated":false}}
%---
%[output:081f7cc8]
%   data: {"dataType":"text","outputData":{"text":"Permanent Magnet Synchronous Machine: WindGen\nPSM Normalization Voltage Factor: 365.8 V | PSM Normalization Current Factor: 486.0 A\nPer-System Direct Axis Inductance: 0.00624 H\nPer-System Quadrature Axis Inductance: 0.00756 H\n---------------------------\n","truncated":false}}
%---
%[output:7f71d970]
%   data: {"dataType":"text","outputData":{"text":"PSM EKF Fully controllable\nPSM EKF is stable.\n","truncated":false}}
%---
%[output:3baaba60]
%   data: {"dataType":"text","outputData":{"text":"IM EKF Fully controllable\nIM EKF is stable.\n","truncated":false}}
%---
%[output:120b3b52]
%   data: {"dataType":"image","outputData":{"dataUri":"data:image\/png;base64,iVBORw0KGgoAAAANSUhEUgAAAIYAAABRCAYAAAAXQt4GAAAQAElEQVR4AezdB6wcV9UH8LtL76aH\/kLvmB5aMIQqWghFISB4oiMkWuiiKAKBaCIgenXoLWCQ6C2miU5oooOpSqiG9Opvf2Of\/Y6vZ2Zn9z3HL46f\/N+5c++557b\/nFtnPN5\/\/\/23Bb74xS9u8\/fmN7956hdh+XrggQduO\/7447f95Cc\/2XbTm960kY2423b8HX744Y3\/wx72sG0nnHDCttAZcYnl+PSHLF3uuyBNcemYJZvTizy16ZU\/+tog\/\/LWFi\/8cjqz5HNa3KGj7Rp6lVe5yShzWz75ZX1tcllP6I56UUZ517bjb3\/72+VqV7ta8feud72rnHjiieWJT3xiedvb3sZrikMOOaQ8+9nPnt6vhuMmN7lJufvd776Lqrvd7W6t6dd5ErFNVj5BeMarX\/3qXfRe4hKXKJ\/85CebMmfZ7L74xS9ePvCBD+wSN2SktXnz5nKFK1yh8Qp5ddZ4pB9lUL\/hxc0v7l3Fo5N7Hmi7r33ta00UbTohUuPOPxNilRvd6EaN15\/\/\/OcyIUrjrn\/GCqNQv\/\/975vCKxQhFc4voFJ\/+9vfCppCw\/74xz8uZMhPAyYO8vxVKJ0qwL20pDkRaf6FnLCQFUAfvwC58JOmtMlB+IestMB9nV4tW+uirwt1XPpBWm1x5Fl4Bh21LL8sI948dR361LM6pKsud5sMOWlLj1tcOsiO\/WT89Kc\/LTe72c3KNa95zXLYYYc1FkQ4\/4lp4iy3vvWtp09H47HvZ6EaUKdrta53IsYZZ5xRdC2nnXZaU1Bu5ghJHvCAB5RJ\/1OY3kc96lFN+L6fldUAqxdd6Vqr652I8ZGPfKS89rWvbfrbz372s+XQQw8tF77whctRRx3VdBfMzTymd2XVdt6IHWZc3dbYU3Wtq58S49\/\/\/nd5\/\/vfXx760IeWpz71qeV617teeeELX1huc5vblI997GPlzDPP3C0ttXXr1rK1BVu2bClbKhx77LHl2IQcTsduyeB5VOmUGL\/73e\/KX\/\/612IwMhqNmuq4yEUuUm51q1uVH\/7wh+Xvf\/9749f287rXva504Ygjjih96IrHStUwe8jI4fRIxzXjrW99a9m4cWODIFVbGVbLb2\/RMyUGUpz\/\/Ocvl7nMZXYq2\/Wvf\/3yv\/\/9r\/zrX\/\/ayT\/feFq7kOXOCXedj+OOO6786le\/Kps3b27I+\/SnP73c5S53KXe6052aQfQtbnGLcsMb3rAZbBtL7Y1YpN6nxFCBpiqXu9zl5tYj7tLSUlkagPXr15f1Ldhvv\/0KEp566qnTLuSXv\/xlGYLoUmTcmMg1g9\/Sjrxt2LChSf\/a1752Ud5LXepS5YpXvGK5xjWuUW5729uWe97znuVFL3pRedOb3lS+9a1vTcdWdf9\/brnP9TCPe0qMeSLVsp\/\/\/OeLmcoQmN1oAA1xoQtdqHzve98rxxxzTPnQhz5U3vKWtzSzomhohMuIdBFLA0Z6L3\/5y8u73\/3u8uIXv7g85znPKY985CObcZK07nznOzcEiLiu69atK4iyYQdJuMvkT1qIqIt6xSteUSYrgVNs3Lhx2h1NRDv\/\/eEPf+gMi4A+mbaw2i\/fD3FHuvNcp8QwDT3llFPKf\/\/7313i62LOd77z7eI\/y0NFw+c+97miosOMq3Buft\/85jebAWWta7+JBUGAe93rXuUxj3lMM1v64Ac\/WEDjLy8vF2EGyWTr+Bpf\/A2TxreSaECNJKxDliWHGAcccEBDFvc5XP7hqKOOamZn8q0rUgb53zghjLFLjrM3uMfBOE+w9Yv3vve9Td+rrz3ooIPKZz7zmcbUtlV+rgCVhwCgwlSgygP3\/LsqkO7169cXDa3RTZkRwNX9Ix7xiCI8pxduS7zhjmvt537dunUFSaxSBkn4RZzobqRzwA6SHHzwwcV9yORrlBdhlDXI8vznP78gC3SVV36yruxuC6v98v0Qd9Y\/1D1+8pOfXP7xj38001OzEA1ixdM6xs1vfvNmH+GqV71qufSlL92qUwUhVRCgjwQIAJkAX\/3qVxsrECQQ1tUYrRlYwHPdDpIgCLAk\/EJVkGTr1q1laWmp6KImm1ON1dJ9yZ9yhHxc1QUgC2TCcG+cWBfoIkzoWQvX8V\/+8pfCnOsqzj777CZPF7vYxcrpp59eTj755HKBC1ygsCRnnXVWE1b\/tFUQGf4aGTz1Gh7pwD1\/FRwWS5wu9Mm0hdV++b52IwRLcv\/7378Zl1iizvlAjs2TGc2HP\/zhZmaDKLksyoMsoDw5briRBRmQBZAkLAw3sgCZnL+IX\/vl+yHu0DPPdcwSyLh1DDOChzzkIeXtb397YUYNAg3gjMD71jHs6mloDa7Swgq4B2Hr169vzdf+++\/f+Pf99Mm0hdV++b7PvW7dumafiIUIS5LzFSQ5YrI2Y63EQNUDsLy8XJYnyGXnRhboKrt6RwZkASR59KMf3Qx4uZEF6nFfXxkiv1km\/Oa5jv\/zn\/80VsE6BuugPzdTQBTjC2v5s9YxrHHMIsA8mVoLskiyYTJwRRIPR924NUmOmcysIt\/IQh5ZAEniYeFGFiATcfK1jTBdFibHW0332LjCYo\/MmNcvso4hQ0za3gBda10Oax02E81udDX1zCaTxJR706ZNpdbh3qyPLmMaeMpTnlKcgXnlK1\/ZTLMR8A53uEOxnqNOa2ij2sIgDCsPRx55ZDlyAgN96UGtY+j9GIOve93rDpXvlGO6FgGFs+L1ybSF1X75fpbbQLsrP3ZDdbF5ZrM0GZzSGTj++OOLza\/3vOc95Y9\/\/GMz\/a\/1kc1+jjHobp\/2tKc1U3MD3WxhEKbPwvzzn\/8sENsFJgC6JLjKVa5SEEqa82B8+9vfvpHfHesYjeIZPypohkhv8Lzxu+S7\/LsSj65Gg8V4hF+WN2jVWMYjuhpPew5vc+d87LdjLQcxcpfEwnigpQ1dXRL91qDo4Z4H0wUuU06zD2YxKzDAYjoXUZ71rMSdK2uInlq+vg8dXf4RPvSKEMYjCAK6CX4RX51mkrAkQ0gS8et8sjDIgCyAJNnCIAuQWXRXfByzjVhBxG4JW+BS2E9\/+tPN1rvZS2R0Na9D+sE+mbaw2i\/fD3GvpHwG8+oNQWAWSWpLkvMX+aj98n12G8MgA7JIF2FMKkLPPNexvsl08\/KXv3yzw2hN4wY3uEF5\/etfX7Zt21Z+\/etfl2td61plNNq+FT+P8vO6LKuxYTKzQRDQWPyiXmpLgiRmgxG+ousKI4\/ve9\/7lve9733FQZ0tW7aUW97yluUXv\/hFs9hjxmLA9f3vf3+3HdSpzWRbefpk2sJqv3w\/xN2Wh6F+WX+OgxBDSOLBZLWRRHvQUevM90PcdMyL5vUBo2xM\/dvf\/laMjGMdw7THwZ1ZB3XmTfS8Lj+UJBa9apKcU3U3HXzqi4xgFzmoI7P6ukXw9a9\/vXXOn3X1ybSF1X75fpa7bR0j52WWO+vvks0yxiQG\/pbkrZOwANaT1ClEd4Mkr3nNa4o1kk996lPTOsu62tx0LIIpMcx1ZWjRBS4FWgR96wahr0+mLaz2y\/ez3Dk80p\/nOiR+l4xu22Lj4Ycf3nTl9ZjEWNAayY9+9KOCHGY3Vqsjf1lvuBchhThTYrjZE1CoWen2ybSF1X75foh7Vn76wrP+Lrk+mQgb2t04JBXdzWj0\/xOE0NOVh1n+Y2cPTE0tmnhlLe4PSy8b6WIkTi77z1K+VsItU8t7xjlVjkjb0x9LA0Pq5ZnPfGYzS5RnC1zOpZrZAF3a5Oijj24OD+lCrJPobrRTHrh2pZVfdvrSl760i1inxfACzH3uc5\/ygx\/8oDmoY4ayS+xV8NAPz1LTJ9MWFn5MLwIgfZ2G8tn\/iEqJOLXcvPdD9PTJCEMgE4BI2wMb75iyJMYkj3vc44p9FzK5bfKYBEmsa\/AjNw8aYtzvfvcr3\/nOd4o9Ewd3nvWsZzU6ZMgOq3dLnM9sPDt+MHsROCU2K16fTFtY+OmzEUCWrcm4AnecPVHB0o84Bx100PRJ5T8vQk\/EC1Kqy7DGtUzIugpzJpa8vAYinyFDl4Gy8G984xuF9TD+cB9ACJt+ruE39NoQwwDGAteDHvSg8s53vrM50XXRi1600YG9D37wgxt3\/PzsZz9rzi3IJMgkRju3ETDCDvm4eqs7wuPa9lY3vwiPq7ihx9Xb3Bo9wtuuykNW\/pjOkPFUPve5zxVULnnJSzan1CKMTrqbwB0\/4tflIy+fO0Sai\/sod8ThJ5BOusXrg3Rud7vbidK8lR5vpl\/96ldvDkpHXLr4EXTkQTzd1le+8pWmeznppJMKwuhe7nrXuzZkD+soTo3cdWnThhghZCnVAZFPfOIT05eZWYsb3\/jGIdJkjnn2Hmt4yuTjH\/\/4Jk6Y749\/\/OMRPL2SkfnwkJl4osLPlZ8wbuAWlzvgiXJWRIOHX9f15z\/\/eTO9y+HWblSyp4xlEUYXnXS7Dyif7XDh4acc8hn3ru7byi1sKJBWfsnryoFbnjQ+9xB4e9DaVJZVh\/Kd\/bj51\/neiRgsB5P1hCc8oYzH24OCvRQEPAUqFeIJUXmQC9Ym5\/sNyKOS4+151oAuCH36WNYKyyPToU8FeSKR06sD9EXe8tVWtntyBnCeBGirHDroIpufbrujdp75Cycn77bG6ZYP+ZF3+eO3Elj5lJY0kRG46bTg6DoE4si7fGkXZRLPUUT1yh0QRoasOOI2ra\/iVVgA80USIRrKPdR+UfnCwNPnKZSIp5JfhoU0Z0mzH8YiAL94ydco28u18Z2InK71FmcNyHu6kJG7hlXbtsZSvihrpKtigA7v7EqbW3me9KQncZZIKzfe8573vOl7K06\/IUojvMAP0nlwRNWFmHICN794WLhngeWTd3LK4rA2d5vlEUZGeKTXEINHDQW0sxoRItzBjxh\/8LMlj2HcAQXU3UTluyJfhLuKZ4TNDchBDnQd\/CCIoUDyJBzIC\/d0ORzD3QbkRFJPtfi1DD3IEekoi7xlOW+tua\/Tkv8si7BXvvKViS4EBEc+kQ888MCGcHRy81MHysE9C\/UDG2Voi5fDpKcMDTFYBZWXkb+u0qasy4+Z0i96+lQy00Rv\/eQiHOK1NRYSmavT1ZXOvP4KrEzyArqv0DGPiRYnSMS9mghLRGe2atz8YN68irMIGmIsErErjkbFbKbfGCLMWVtl1o2FoKGXjvx0IJB7jVpDlxHx4pqtFuvlPsJcrWHIIzfEU1NbBWGRd0RnIULWNDBbK2nYiBRnXngI9P+z4g3tTiLPoS\/uowzh33VdPWJUKeRKM1hDkizCfOsSgFuY8QULI\/PuIUwiCwT8QHcjbpdlQTomkax4wB0IArvX0IgH7l\/ykpdMP\/sg7zHQ1Nfrg2NAiEQxIBXP8YU6Hf5DgPQeBrKsa03+eGjIkCXXB3mWdzKu7rnr7o9fG1adGLnSYibgqhJzBvITq5\/XyBCyGglYg6iULKdh6csDJ\/cZKjisQo4rnTDP0jBoRCQDSaRU+fzJ8AErZwAAC9hJREFURX74CyfHChrcSQsRlIVs6OQ\/L6KLkI46rOPHA8LfyfJ6AM8\/Q33Lu3y5uheeB9buu7DqxFBptodzghrIk81PpWvUvjEGIhgPaARxWJI8JuCnAlkXg0v3bZCG2Y3028LpzOnIO8sWZIo47vmzFhbGrEw6Y+kaMq7SkXfueaAb0UWIE1aJOwP55IOfAaqdVe4u1HmJ+vKgRZxY\/WV9HQr3opnvsAkfM1kq3k0fyJDNFUleZcb0NBJ1Jfvd7363PPaxjy3eprrsZS87\/dZENKaGp49shrTozgidISdNaWeZLrf0Il6+0lnHCTJlOeTib7BM3oqijSrrPj6\/ELIsTz3GiLRDh\/g16BZOj\/pQL30yyu5BizjSqOXdq0c6QZxcX9xWtFkQ2\/geMlPl3\/zmN0W8QRaDIFZJLAO7sCwOD1vn9yTZiyDnfVifanrgAx\/ods1g0fI4anfve9+7eYfVHgSC0BUF062Ae1PMtgYWttqQh0Xah3XTzYxGo+b9ZO3GssjfTGKYW3vznXCN+Mrfwx\/+8EKGabUJp8LK5M\/J8nvc4x7NOdLJ7Zr4t5Ly2JPwpBp\/MO0KxKzrx8E4hh+Tr9K5dzdWUh5W44IXvGDzPVdEtrUfr4l0EsN+iQpgbiVeF9Dh4T3xlb86H0PvV6s8jugz98YFtrXtRzDVGUy87mFo3haRayuPNKUtL76+OKR9WDXlcbzCbEd8+ekkho0z\/c+rXvWqYjpHOEOFWN5GHP2XF2h8BA3r9FkqLsvvafc85RmNtp+Ecs5BVxiHoY0frInY7jbecFxhNNouu\/rl69e40vL86U9\/Kj7y4o0AKbHuDEGsd3QS4zrXuU6xgqkraDsHihROETk8bEc2oEsxttC9eOHWdPINb3hDMZcm471Kg1EwRUMo503Lbv6bpzw5K14wjrf9dZ13vOMdm89Tqsgsd067V1oen1Zg\/XSFxhYOJWsL40Vl6SSGwD5oTGaojTQ5HjmZ8CEWCSODMwKAJMiCPEjkIKzdXJnbXZ9ZNDYwQDRlNi4IPOMZzygqx3s24edq3GANwCDNS1hvfOMbmxewhK0FDClPbo9we6gdyFIP1k2Um\/VX72R2IkbbLMMUhmAf4vsY3pcMWJABR8sgBjV9emTWZ44QzrE1y8+OsXkJSsP4zKKC6EMDX\/7yl6fT4C6\/LDPLncND3zzXIfH7ZNrCar98P8vdV99Who0vfLbSPo3p9mi0vWvciRhMpfcddQO6BLMM0yDL23UCpjVMEWtgjwAJlpeXy\/IOGMEDfWAfwFQWuPkJ1+DIJD4C1em49xola8PKhIXRFYHwfZivBjyAuvu+WFNidM0yPK0GkrFKFso8yW1vx0d435X1QAJk8OYbMiEJsmTiIAyQzfp0T0gCzmUgiC4qZKxQhts13w9xi7Mosv4uHX0ybWG1X74f4s75GPr1gikx8ixjNNpuTozKfbmPRWAdcgLejr\/Sla5UhnQ1Od4QdxAHYQBhwsogivCsB0GMV4xVkARxcvh53W1wqQ60o27Dcc1Zg+cpMfIsg5KAk+O+sWDwGH6u+fCwhtLdgLB50LZGUscnIw2WA1GQBJAkD34RAkkQBMKKiB86h7hDdpFr1t8Vv0+mLaz2y\/dD3O94xzuaWaFNQNNRS+Gj0faHvyuPU2KoVIO+XNFdkcJfI+nzfb7ZYg\/4oh3YSAs4Y2lLGjZt2tS8f2mr3ewAixWuD9Krw1kwq5B2NMFYhVwp23+VhxXxbSr7ADap6BDqCm1uaxTCFkXW2aWjT6YtrPbL97Pcwm0WHnzwwUWvYGZlDYR\/H6bE6BIyS\/DdT2OBWsYmksPDtb97DR5wmEWmwGIYGAV7vc4sw\/eqvIsJVt\/sHBrUjkajog+dBdNb+TM+YUVYF3kAA1fEsNtoQcfKHt1dOuOdz67wc5u\/OvBQqHvvCFnE4jcLU2LkWUYdadYoVkN7eoG5h6WlpbI0gYMhtb62e90QmH1oPI2pW2B9WCK7mdAWN\/stT2ZFuhlAkhzGitDJyulqWBRjEmlmuX3uUsZMsoqIWcYi3xJXsRs2bCgbJmDSQaOAdy19KxO4gT8ZRLJLGUSSjzYgDLJAJordTua6jsOP1UASVsSMR5pZDkmMQYIoFtiQxQtXQRblynGGuKU9S65Ppi2s9sv3Q9yz8tMWPrYXYtRqlmEW4kmzH2Adw4zEk8u8zhrFtimv\/VgPYEmQAZEQA0k0XCYPP8QhW+sJomhUXRFLwq+Wi3tlq0mCOBEeV2TRxdHLqkAQBmnCwiAOUiEOiBc69pbr2MkkAy4LHrFWYUxhFuL4mHGE9Yqub4mvtCL02VkH4kAQJxMGUSDLG8ewJLobQJJaZ763doIkHgAwFZaG9LLe7NbwgAxIA0iCOIA0QSDjGPf8yQAiBegwxglC0ZvTynkN\/9ov3w9xh555rmOZ9C6qwcmi3xKfJ8FaNpvCOizuySALCwNhWWqSsBpIYjaEIO7pEN8Vsls3ihCI4iu9uh0zHISJ7geRyIg7Cxo5oOGRABApgChIAwgESAXcZlGuwoH8C17wgpKJZXZHPxhYRr5y2bI7wue5Nh+ZNwuwjsE6WC+XGKIYxTr0GruL8yje3bJBlPjfjHLj1VbE4HhofkzXdTMIsby83HzKmVVBGkAa4BfkYXHIy4PdWPGHppflkMosylWjA2JF94ZciGIchDRgtoVUwB2kQnCy6om+nM4Q93RWctxxxzVvPqmYIRFrGQxdBPTMitcnI8yuqF3GQw45pHkL33oMf2A1EMOg1XoKd6QnvHbrVsOv7crKgE0+YxdWCxyMYXU0zste9rLmG+FOc2ugACL535rAGCpgdxOQCrQByN88yKSy9I1U8rkIUafEmCcDbbL6uj0NR9Us5MQ3rDzBOa\/WUxAj1k1YytFo57USA+3VLIc1lgCrwiKDdZfAS1\/60gLe\/YCPfvSjBVgoYKECYamQjKUCekF5IZfZqnW+H+puiKELWck6xtDE2uQ8lW3+2a9Ppi2MHxPqiTQ9NvOpZzcsifEI88yaGJdwIw4Tbiqc8zDULe1Zsn0ybWEslKceNDxLhQi6OtYKSYDFQhxkYq2QycMwKz9t4WMf2JDQStYx2hSvFT8EQQxPVhdJ5NW4BBkQwxQdSRDGTAf4GdBCEAe5xF2rQKSFLYYpqo0y5Njd6xhtFchst\/lnvz6ZtrDaL+6RRFeDJHlm46mrLUqkr\/EBGVgYQBLEQRjkAW6w2yyMDBIFxEc8sCZEZ6SRr5HXPr8sM8SddQ11j61PWKfYU+sYQzO6O+QQZcNktRaCLAawuiBkYba7CFPnR0ODhgdEQKIAoiAMIBAgFHAHhAN5CGK50kk3SAvqfKzW\/ZjFODesY3QVuK1Prv3y\/Sy3GQ1CIAuCBGHCwrjnjzhAFnkA0bry2eevgQMaHZAAgliuiII0EERCLHAf4yRymya72Mgkf31pd4WNnfI2Ol\/pOsaiB2O9vTYrbp9MW1jtl+9nuXN4nS8HZX3ojFVxcgysJWgY0DgaDY4++ujmS3q+pmcX2VoEGMMEnI0A6wxgnANdjdXnj1jiBqmkgUzGV33xusKaWYlAGfO0LDJ\/nuew7HlF1vGBgFNTX\/jCFwrY2wnYsARTVLBvBawTGCwHwlJlazXEYi1qxabEQI59WFs1oFEDuirdAujmAoiCNIBECAXcIHyRUjXE2JPrGItkel+c2TWQCTVbeleJsR1UU9VYx9BXZTFLq97vMCfO\/vvce3cNjH23AjEgTn07n6HYBjP6xyGnisnvw95TA2OfVXbiG7jt3C1yqnjvqZJ9JVEDY+vtHMBt+rXIqWLx92HvqYGxgWcUh9up73weY+ip4tCxCtd9KtZADTSzkjWQj31ZWGM1cI4Qw9davKm+xso+d3YMxuOrfd7pdQDHFwLmVrRGIvgQzKGHHlq8vL7LV\/t2Zx6dKHKayXe5TIt3Z1rnhG5f0ZGOb4zZh7DHZNbG79wIH9bzFqE3Au2v2Bn21T5lGWQxFv0qnB1bnyra277aZyzmYJNjePGpIpW5p7Bo+9jzsTI6Gu361b7\/AwAA\/\/9RyG1cAAAABklEQVQDACE3g0WZ0C63AAAAAElFTkSuQmCC","height":81,"width":134}}
%---
%[output:32a6ec83]
%   data: {"dataType":"image","outputData":{"dataUri":"data:image\/png;base64,iVBORw0KGgoAAAANSUhEUgAAAIYAAABRCAYAAAAXQt4GAAAQAElEQVR4AezdBbRVxdcA8H1RbLFbvyV2i43drdhd2N0BmGBiY7diYgu2YmE3BnZid3e97\/7m77Cuj\/eexI0nXBb7nXvmzJnYs2fPrpnTpqGV\/fv+++8bbrjhhob111+\/Yemll07gtzTPRqa5L7zwQsOiiy7asNRSS6VyF1xwwYZNNtmk4cMPPxzmYs8555yG\/v37D1N++WafffZ\/1NejR48G\/fjhhx8aunXr1vDyyy8PU1nVztQmWsm\/YsfjoYceiq233jo++eSTOPbYY+P6669PcNJJJ0URkbHlllvGzTffPFIt7tChQ9xxxx3x4IMPxpNPPhkzzzxzuh+pQlt4uUh8qXz1Pfzwwylnz549Y+yxx059nHPOOVPaiPyBsz\/\/\/HNEXv3Xd1oNYRRnUYwxxhhx3XXXxW677RbFmRZTTjllgvbt2yeCKXKNmGaaaf61U8Oa4bfffovvvvsu1fH777\/HCSecEIsttlgCv6WB448\/PhZZZJFYeeWV49lnn03FG5QrrrgilllmmShyoDjyyCMT8aaHzfwZd9xxo3PnzvHSSy\/FG2+8ETvvvHO8+OKLoe\/77bdfdOzYMYocLUwE9Urfa6+9UppJseOOO6b85557bsLR2muvHY899ljcf\/\/9qR1LLLFErLXWWjFo0KD47LPPYoMNNogjjjgitW\/TTTeNyy67LFZYYYVU3n333ddMK\/+X3GoIo127dmlAXn\/99fj888\/j559\/jquuuioOPvjgdHWPcAzQ\/5o+Yn8ff\/zxmG+++WKmmWaKueeeO9VlcO+88854\/\/33w6wGX331Vdx4440h\/YMPPkgcxj1CUrM8r7zyStx7772J040\/\/vjRr18\/j1qESSedNCaffPJEDDnjE088EbPMMksaZPW99tpr8fHHH8dFF10UOIrnuMwXX3yRXwnt69OnT+rL3XffHYj00UcfTYSnDBm\/\/fbbWHjhhVP7pp122lBucXmLE088MbX1jz\/+kK1JaDWEoZGoe5tttklUv9122wWqNoMg5pRTTgmztMleDEeiWVmUNeLtt99Os9ZsP\/zww+ORRx6JNdZYI9q2bZtgpZVWiqeeeioGDBiQ0s32CSecMM0+1WmTgcHZLEdnnXVWDBw40KPhhuWXXz6K8lRce+21aXlBcJ9++mmYJLhAoVCI6aabLuadd94hZS+33HKhPSbUQQcdlPKeeuqpceWVV4alWEYcFwcsFArRpk2b1HaTC3H+8ssvAaKZf62GML7++uvE\/m677ba0nGDz2PO6666b2LTOls6YZvozXMmQtOyyyyYE4UiIIheAlZfe5\/R8\/fHHH8OAIDBgMLt3754fN3s10y0RuEbOdPHFF8d5552Xls999903cTKTgPxgQOXzG078LoWPPvoodt1114CbjTfeOHbaaafSx\/\/43VJ\/\/pGxeNNqCAMiUL+ZOc444yThbMwxxyw2MZLsQViTJyWU6Y\/yLAnqM7PuueeeQBDg9ttvD7PV0uW3NMRr6VA9ToZ1G2REhdsRnj1rDuQrajUx11xzJbkm58Pi11xzzSAYG2hEBg\/Yv\/Zp5+DBgwOny+\/k65dffpk4B9kCJ8jty89H9FpzwrBmE5RQPOSPaEeG9b3nnnsuVl999SSsLb744mkJ6dKlS2y00UYBsZYWMMMMM8Rqq60WnTp1SumIxPKWhV9LDaJxxda963fjdhBWc33KNeAEzdJ86j766KMTqycDkIGuvvrqIGwito5FoZSsNdVUU5W+ln6TTSaZZJLA+TbffPNEdM8\/\/3xaWlKGEfxTE8LAFi0ZK664YkDmhhtumJBAjTQAe+65Z7z55ptB4IKQHj16JJlgBPs45DVrNNkAsqmPBFFCm5mJzVoaPAd+SzOQ6idv3HTTTXH22WenNnumnfKCnH9IZcUf+vbqq68m4U99zzzzTJBnJphgggCWD23Crcg4uIP+nnnmmXHMMccEjoRolX\/aaaclOcEStMsuuwQoVhHaR4NStvYhXsSFCAnv5Az5aDra47c61a0N7puCqhMGewTZAYfo27dvsiVAGjausViy2QoQzpJLLhlmpEEgbDXViVE1bY455khaGRyQH6ismWNVus9VJwwUfuihhwbto3SgxxprrJhnnnmSdG72mTVYdQbP5Kk0QlpT+fqMs+ImJg\/tpVrtqzph0ASwYbaKTYtGFzaEDFQ2s4MRBpdgoAEMS7169QqaQLUQM7rXU3XCyAgnMFlbN9tssyBo0eGZw7faaqskQFkjyQKAYcl7CMq1DpXHQM0Ig+pXdF4FQiD8MeAw\/9JQJp544mBJzN0njVP1qIY5rX6tLAZqRhhsByxvLHy5i5YX6qt0ujydHlx++eXBuFMqk+R36tfKYKBmhGGQyQ84BtmCnFF0gYelhcA5xRRTBBmEjs9XcdRRRyXVrDJoqJfaGAM1IwwNIWBecsklceCBB8bpp58e\/A2MQUy8dHCSOImcTk8m8Q7TuGsdKouBmhLGhRdeGAcccEBwI9M49tlnn+AbYaxh78hd95szi1Hnlltuycn1awUxUDPC4Exiuj3uuOOCsDnrrLPGNddcE\/wltBA6O9c4WGWVVZLpmmGMmbiC+KgX\/TcGakYYzOIE0PHGG+\/vpkRyBiGM\/fffP7m8eS0B0zBTcTbvDnmh\/qNiGKgZYbD5EzAvvfTSFJQj9oAsMdlkkyWnVcV6XC94mDBQM8IoFArBbiHIRZCOZYI9gyCa3e3D1IN6popgoOqEYQlhr2DIYrDi2hbCxsvJbcyQJU9Fejs6FTqSfa06YRA6eUq52gWXsF+wZ4DsE3n66acDwYgxEN4nKomhayT7Wn99ODBQdcIgV\/CN3HXXXSnqWgwGfwigjVhWevfuHVRXZnLBsKKhbSfATYajb\/WsI4GBqhNGbqtlxEAjlJzGJyKdB1aQrXS\/qa40GM+k1aHyGKgZYUw00UTx66+\/piBYywTgExHfiAiEz+fu85sI7BHLkdPq18pioGaEIbiXccvSUeoTsWR07tw5RFyzgDKR77HHHiF6mn+lsuiol54xUHXCsHxkfwdjlpjGxj4RkUvsG3ZZ2TzDwDX\/\/PPnNtevVcBA1QmDjYK\/g99DkCs\/iH5SYWkqwvKF1+MU\/Ca0FTIGriKPvHWoPAaqThiisPg7DjvssLBfw6Dzh4jm4l6nsnK\/WzpoL0AQrF1irKUVR0m9goSBqhNGqrX4hyqaw\/L5Q4Bwfmoq7QOnYAkFDF822xBAi6\/W\/1cBAzUjjOb6JhIcAdhXkvOI8pJGdc1po+v1va9+iePvejc6nTUwJt3v\/uhw9GPpvtz4aHWEQY21tcBRCCK7gKgugcJ2e5UbAf+l8hDFHn1eKRLCO\/HwW9+kpks7\/q53EqGkhDL9aXWEoV\/kjgEDBqTjD9g2WEVtKfBsdIZHisSQCaIxHqT3eeqTxskjfF9TwqBldO3aNcV2UkltMnr33XfTvV1oW2yxRTowhUBaKa1k9+IMbAlGGLNlftHygTO0VOy\/PW\/p3cbPakYYDFtOquF216jpp58+7TR3JIBzHvIxSxdccEE6L4PWkuM+5S8XPPjsq9ESWMdbAxh0y0bjfrdr80vsMcH9CTr9dkfaG2t\/bCk0fmdY7mtGGLysf\/31V+AMzoBgBqfGsmsQMkVrAT4Tu8PltbVgWDo1PHmWWXCOyPDiietFY\/jqlOWjtcD\/TTrOUF377q9x4swflk9w81irp7NExLaUwlAvDUNC+QhjGCorzcLvgQB++umnIcmWFgTDCDYksfjDEUg2JxV\/lv3\/WZvNGRnKXniZC+yyavsWS9xskfKdT1YzwuD3IFDuvvvu6SwH0eIsn+Iw1ltvvXRGFsMXIGs4\/a4SS0mLmG5FDzkZbz5l35hqwGHR9uNnh2oZbtJl1RmHSh\/RhJoRhgYze996661BpmDd9NsGI0c2vvXWW+lMDIYve0vEZFhOvDc6Ap8RN8Lj990Wi47zQcwwQUMgBtClyEmeO3TxsqKlpoThGELnYUw99dTRq1evWHXVVYNAesghh8S7Re1E+B9w+AiO4lihsvb+P1SYZdaxluw8S80xddyywyyBGECXMnKKjJKaEYajBu0jsZQMHjw4CaEEJv4TZ186uQaxALYMp8GMrgYuGpw4WAK6gSOXwZ\/flYKaEYYgHUf9iNpyQi911OAvtNBCgYuI1RCbkYFjrbFQWimkVLNcMSdUy1ync8hwTft3HQXhpCFCOlcBApGPfGabhd+VgpoRBpZoB\/vee++dDj5t165dOimXA83JdgRTgcIZKmXgqhRi\/61cvh9Ej2PiADk\/WYKXmcGPZ9k2znfeeSfttXGaMK1NfvjK71TiWjPCEMHlpDp+EIeLzTjjjEnGcIiYY6MF75QCJJXGh1YCGdUsExdwai8NrLRergAhBm3btk2HvvIuO+6R\/GXCEM47duwYuG3pe+X+XTPC0BG2DJFZ2KIzMTjMEIkYzzPOOCMdTGZrIsBeK2Hg0o5aANXbnlxLZ66fcc+BMjnupFAoJLWdDCZMweRwjqf38juVutaMMKyXOAY1lGyx\/vrrDzlrs0ePHmnbovO4MojsEuRTKUS0lnJxEvJErdtTM8IwM6yX9pfYxIxNOgfbrME+ud2dlpuBxxWHqTXCKlm\/46UsEYxZ6hExT77gFnBfTagZYZR2krYhGAe7dE4GqdtyUppndPhdKBTCBCBn0E64AeDF6b\/V7n\/NCMM6yrBFLWW4IX2zgL733nvpFH9aiOVjVNVKmhtoLgHyB1VVSOP2228fDsNtLn+l0mtGGIVCIbp27RrdunVL3ylxvBI2yqCVTeLsG1kzIXiNSlpJHlDyFU0s35OjbKkQQa\/vOEh+Vs1rzQhDJ\/k+qGJ0d7LFbLPNFg6BJ5TSREqBQCqSC4v1bh0qi4GaEYaNR4w7PlDDSZYBYVBdGYB8HcBywu0uv\/0oiKZllNSflgMDNSMMFk5LB9mCBTCDJQVh+DwTVXbdddcNJ++zknpGkylHx+tltIyBmhEGzYP6yWvYuIkIAyHkdA4kSw3bR06rXyuLgaoTBuslK6YDXRHFOuusk3wkWZ4Q42mLIq2EcCp92223HfLRt9HVw1pZMhi69KoTBiOOj63ss88+QV7gPUQk7oFnPjuZPwXJ8slM7nsdlhaftBi6G\/WUcmOg6oTB5MvlztUslI\/wWSgU0jfCBP9SSZ3g56M2DzzwQDrf0xldnTt3Tn2nzqUf9T8VxUDVCYN2gUPQOHAF7mOCZ5YfyBJsGTPPPHP6tqiDYXEZEeSIpqLYqBc+BANVJwzaiIG2aZmrfYcddkgfpyV7aJVYA4Kp54jHWRkOc8M9vCtPHSqPgRLCqHxluQb7SPJvV8SQOQZNhVbCR2Bp4XK2\/PCh4DbyDy+IF2UPyeZ1V4fNDm85rS0\/66hD+nFZ5nPyWmkb9ds57aVp+TfnHM7cnMGwJoSRG9fUNXML3lZeRTvTlltuuSSDjIxGYrliYs4g4DjXz4tJJc73\/4UrATdSigAABIJJREFUYujbt2+MaGwG\/xT3vqMnmupvTQjDpyp9W9SeEdFIGufq3tmec889d\/AfuO\/Xr1\/wNooD5YVtqhMjmmY2ce\/TdhzrNGjQoKA+c2BRl80qZYtm99lPnMauuO7du4fodbPUVR6z1QxFZA6zlVc5ApwNoufKtGtffCuZydJoxtK6pAnaMSEMuINjMhc1s4F6MogVNYl4pHNac1fcUXvAAgsskPYD48ACoxyhSRlo\/G7VCcPyYKDtFykFbBG7h1jaik4AWxgNlhBAdo\/GHRjWe4fIIjQgakwkundZUvv06RO4k03Vvpni+6cGhsbknA5akW+2abeBMNDebQq8K2RApBXfDnkKccur\/TiXPGarg275iZj8yVCIBx5EtDmnzMmFiIebAB6UkUF+9p5871raR\/006NJxR5xSP8l1XBHapS\/6b9mWrxSqThillTf+TQAVIk81dThb3tjsKtRvZJaS888\/f8gGJp\/D8FFa9VumzDz7WCAPMUIqQnSKDy4ikh0SC4VC+hgvU753mwIDawAQGs0KoQ0cODBlNVtt3qZyq9\/yJejXoJOtuNvJDLhTdihS3dXXOCYDwUhPBf\/9p7SPJp2ouL8fpYg4jkibvExA6YgTvpvaitBqCIMqykkGkaKksV2s2WwRUe45IVSHKgHYqZB9xACpIrK5\/yEfF8t1MtVj\/\/m+8RWL9t1YZQDcw9LTOF++V5bA6Hz\/zTffpEEUJY9DWcZoZwgn5xneq\/bbmwOHrMiFQuFfi2g1hKGlBp7dgvGL3IHCXSGJyoqjyFcJaN++fSgfQUCkD+GefPLJKUgGqxdNJR1XQUTkHTOfBiXdmq9dZiMuYEbToshGlhTPmgLEiAAQiAmhn8IeO3TokOQYsg8u1vhdQU4tLWml+S1X+mMJ0eb8DMfSdhMvp+VrqyKM3ChXsRpZ+HJfabBU+CQGLsUMLzDIXlEsnZCJLROMEQgugu27F85PMyCLIBaBNwZ7pZVWCsuU5U9ac+0X01ooFIIgyOzPfmO5MVhZQHff+H11kJMMbONnpfcIDrcQGYcLIzJX8g45Rl9wktJ3\/G5VhIGCzViSvHWWhZS24gsEZAxWUo0eXqDhNDU4Bh7k8tRJaDTjfaxPUHKhUAh7P3I0GVZsMAqFQvDrkCn69+8fnH89e\/YMM9Kslw4sK9LUrx25LvVKMzDCG3FG9aqrUCiESWHgOnXqFIXC0KyfBoOz4DLK0F7l5fJd1actnpFzcDuA6BGDvtrD0tQy1WoIAwVTGyHeDNF4HcNSCUeeIxwdHtWBCoxAcCCbkprqL2LYaqutggyCUJvK01IaVZxhEddrKl+bphJrlYYjsIr27t07nNxHbc2A8qlWtWpbrpc2QfbJ95W4UukJ4jhQU7M510nLYRcpFIbmKDlPc1cylWUTN2sqT6shDKwNl8DqmgLP5GmqE\/W08mOg1RBG+btWL3FkMFAnjJHB3ij8bp0wRuHBHZmutUbCGJn+1N8tEwbqhFEmRI5qxdQJY1Qb0TL1p04YZULkqFZMnTBGtREtU3\/+HwAA\/\/8MJ2LgAAAABklEQVQDAIyCAE5iOMGUAAAAAElFTkSuQmCC","height":81,"width":134}}
%---
%[output:13ac8729]
%   data: {"dataType":"image","outputData":{"dataUri":"data:image\/png;base64,iVBORw0KGgoAAAANSUhEUgAAAIYAAABRCAYAAAAXQt4GAAAQAElEQVR4AezdBZRdtdYA4NyB914pvFLcH8WLF3cp7s6iuGuBBSygOBR3FlYcVnFn4RQvFLfiVty9uLf\/fCmZ\/8xhZu69pzPTO+\/dWbNvTpKdZCd7ZyfZyclpGD0Wf3\/88cfoN954Y\/Rtt902evjw4aN\/++230fW\/\/44WaAgF\/r777rtwwgknhEMPPTRccskl4ZFHHgnXXHNNOPzww8NBBx0UBg4cGIYNG1Yg53qSWmmBQoLxj3\/8I\/z555\/h5ZdfDvPPP39YaqmlwhxzzBGeeOKJMOmkk4bevXuH4447rlbqWKejQAsUEozGISS888474cQTTwybbLJJWHPNNcPWW28dBg0aFF5\/\/fWwxhprhFNPPbUAOfUktdIChQTjl19+Cd9\/\/32YYIIJmtWD3zDz888\/h3\/\/+9\/N4uqertUChQRj8sknD\/PNN1\/Ye++9w7333hs+\/vjj8Mwzz4QjjzwyzDbbbGHUqFHh2GOP7VotUae2WQsUEoxSqRQGDBgQdthhh3DOOeeEfv36hQMPPDDMM8884YADDgiGmgUWWKBZQXVP12qBQoKhig888EDo379\/2HXXXcNDDz0U7r777rDddtuFK6+8MvTo0SNsv\/320KqCH374IWy22WYRPJ977rlxcvviiy9WlU9byPvuu29Ybrnlwueffx7ka\/KsnLbSVBOXx1WO8pSbj8v6xcODnw3PP3cEzSnPmWeeOY4AyiwsGOONN16Ycsopw0477RRkCPr06RPuvPPOuGKRebUw0UQTRcEiXJ6rTV+L+Cbo0003XTjiiCNqkbxIE3ODOeP5558fVlpppRjWgKGAxMaQ3E9WmuCR6rfffjucfPLJsdfRGqusskpMtfDCC4cPP\/ww2jRIPlxpgJ4pL3MS\/tRLk59LSySNcfvtt8dVD4LXXXfdJkmOBTX+wJcPt9HbrPenfMQDdKAHXoIvvvgi7L777nESjXnqjz50SgM8C5MGvcLAWmut1UyTyVsZ4kCiSfhTTz0Vll122ZAEXTlwEsCV94033hg++OCDsPLKK8e65PH45ZenOV9XeaE3D3k89MpP+eoPXyfn99yAyRtssEG45557IkECE0iIkLnnnju88MIL4eabbw4jR46MS1F2DHjTTjtt+PHHHz2Gp59+Onz11VcBEXvttVcMe\/zxxwPo2bNntG38+uuvMbzcD8L333\/\/uLpRbpLklM7kd4YZZggjRoyIQaTew4ILLhi12EcffRTLVbbwjTfeOAqyZzDFFFOEs846K+avHD2a7SVbV3jyJRzmUvC0g6FSHNBG8qYVxMFJDcyP2bPOOivUgGnaWX1Sux911FFB+wP1Ef\/ZZ58FgqIHJzwCJpM8zcpKdYWPycqBmwA\/snjZNtGO0sHlpnaOQ0kiXGQWEEgQksTPO++84fnnn48MNpTA7datW7B89UxzmHSyYyB2kUUWicONIWfo0KFxmPjXv\/4Fdayhe\/fuATPMbzCHi6kyZnjbdNNNm8pGBwZhlPiWQI82hIHLL7880FK0FVzCwWXIg6c9+IE85S1MHBxL9bvuuisAz1NNNRXUKMTylLeeSetqF+0TEf76wRwCgWk6CCH5K6qZw5akruonD\/iES1sQhoSc8KppkygYKYNKXZVFPPwvv\/wy9OrVy2NQyTnnnDPQDjGgA38wATM0DOYQRH52FI2fLToJftIu2bjsM3VNxet12fB8upRfFkcaaTE9X37CYwTUdvx6MHxl8meBhjKMLb744nF4yca19Exw5NUavg6epynVIV+3lH9FgpES65kkWGVoD5nMNNNMcVz0vOWWW8Z9kvHHH5832jdILkhzB2o4NU5EGosfvVNyPZNm49c78\/kn+lNjSJMHzKDGqXS9lbpP+eTTpfyyeVDD0iWgDbLxnrUZjUuQMVEYptIenhMMHjw4PqJBfmiKAa38GL7gJaD1dJyEXqRN2hQMTKeejW+EQoWozSWWWCJOPlPBDQ1jsiEQm2++eQym3vRmagx41qNZRyGkxsVU\/iKQ6NO46OQHnq+66qo4p0A3+qlYqra1cjReVtMZPlIvIxiehRFyqjrlI095p3pgst7LXW211eLkVo+Fr0PpWD\/99FMcVjGU8ClbfALlpedEf\/Jn3VRX9KCLcNM0+TlGwqumTcZwNFta5pnUMVzpjSSc+tPj99tvv7gnAnXHHXcMwLMJ2oQTThiM\/yqtoalWYLa9yy67hEQkZmrA1157TdLQ0g8NIFx6De05C+gjbMK4\/EDvNf9AMxB\/3XXXxTmH5wSJFsMAMAYnup577rk4MdXo8lAfOATBcJXyMLbLm\/CpjzaCa6iFS2hSJxAunfzgyu+UU04JNAkh0um0UxqO1TtNbMXpmFmaTZjVVZ7Kgi+9dhaWoJo2SWmiYMiIikNgikiuMHFJTQ0fPjzuoq699trRpQ2AeO5FF10Ul2YabGjjhFM4SKoVkVSdMHDbbbcFroZMceI9Z8sWn2jKumiXnpvCpZWHcIAO9IhHR\/Jn8YTLAz4477zz4kRbPvCycZar8kogb3lKB+CKE07YCJcezZ\/Fg5vqxeXX1rRKwuOiQRwctCQ\/mrN+OMKUnYc8nnzRA0++0nL5QRQMD9WApd4ZZ5wRuNWk66q4tJUebihQBxqANswPAeLyYH5gYqx35+Nq2V+VYBjvSLNGag3Ew6vlSldLm56kR6XeyM32uLby0yvhStMWXq3FVSUYqZIaqTXQCPBaqujo0aPjplvqeS3h1MNqowWqEowsycZMVjvzANpjySWXDBdccEFwFiOLl3123M\/4mA3zLH0dZm7ac2qvtph++S3DpPs8EGHYiJGaumIoJBi21Y8\/\/vi4HLzlllui6fnCCy+Mk9GTTjop0Ax5CoyzV1xxRdMKJh\/fmgaqtfD77rsvTpZrja6W6MGLfDtX6i8kGN98800071q2Wj4ZOuaaa65w2GGHhVdeeSWwhmYJ+P3334NlFRuHvZVsXP25g1qgMdv3v\/6l8bfYfyHBsE\/yz3\/+82\/b62ljLU8K449DwksvvXQ+qslvqdsVwO5xV6DzkeffDPe+9ElT+\/5n0m5Nz5U8FBKMSSaZJGCyndc77rgjmr5NOvfZZ59Aczj6ly1c3Omnnx5mmWWWuPPJiMREnsWheboCTD\/99NFIV6u0jjfxNOHxLycIJwz7ITzz0RiNsfQsPUOnCEapVIontAgGg5ajfZZjG264YTziVyqVsjyP5vM0BhpSrO1bmoQ2S1T3lG0BQwW46qlPQ\/+rXg3rnP1c6HP0Y\/F52FsjY\/qGn74MZ206Z3yu5qeQxnDI5ZBDDgmGFAxm2bv11lvDFltsEbxzUg0BddzWWwDTgRUF5oOsABACIExcEoaUIy0x0bCTqtYW0hcSDObVhRZaKNoknNpyKPjhhx8OJpkybQsYi2iXtnD+m+MwGmA2wFCAuUCvB5aZmA7WGfRc1ALi4RIAeeTbiSAYNgasOlO4ZbcFwvBDlgg0Rh6vEn8hwbBDutFGG4Wbbropntqy3W4jyeaQjaLsJlMlRHRVHMwBGAwwDZww5N0mRmIywOA8s\/MMlxbTQVttQgDApotMHcDZjUNFEoRb+i8QBqzaKyw9a8+2sigbV0gw8rnSILaPDS3vv\/\/+31Yrefxa8mMswFiAOQlaYvDagz+MBqO2mHzCkHdCygOTgTIqqTeGAz0f0wHGg8R8mgAIA3DGVhDytBUSDNbN66+\/Pqy\/\/vrxxSMvGtn2HTJkSLj66quDVUu+oI7ya\/AEbTGWGtZzQeq9LTK3cRIHF7TE4I+\/+6OqqmAywGiAiQBDAWYDjP761L6BC\/R88QA+wHx5VUVAQeRCgsEcbsfRasTBUieNvMPaUQKB8YnpGJZlLiYnyKpmeFnG6sF6LpBfte2FIWDaHuOHLIMHNI7nmJcAkwHm5hndGrM7k+GV1ruQYNhud0qoI4VBBTAQgzE+MT0xWBycagBjAcYCvTBBlsEYCzAXZBl869bThyyDBzSO5ykPLiYD5VRDW63hFhKMjq4EphvfCQRByJen0UGWuQMyPRdTEyTGZpmLsSD1cu6ADIMxFigD5Mv\/X\/DXnGAQit0bx3nDQGIA5gxoZDxm5xmMqWBAC4xNzE351N3KW6CQYJh8mltws0XxtxSexSn3TEOYB8AjEIRBr8d4jBZeh45vgaoEA+O9zGyyaSeV61XCBNdee2045phj4snoIqSbYCZNkYSiLgxFWnLs01QlGCybTz75ZADffvttdB2pT+A2nT322KPwWdATG9f\/qUpn9ZuzkCk3pa+7Y9cCVQlGjx494r0YtILdUq4LUiIce2y8LMVriqVS8020SkikLdIQYlJZ1xSVtFrH4VQlGEzddke9uGwr3dE+t\/RlwW1+8LIke1nHlryXkBZbbLF48w5bSBbnqqf+\/+zA\/o0TzWxc\/bnzW6AqwbBzysLppaJFF1003tbnpaAsCIeXrYrjf\/ZXTEwffPDBeH7DCzoJZ1T3yaMJmd\/coq4ttMS4haoEA3NtlLFw9u3bN97W58a+LAiHl60WYdltt93iNr3zouYqhqWEM6r7ZOmxcVNomqbn+sO4a4GqBCOR6b0R74+0dJpZuPiEy3Vhm1cGvTbg3UrvuLoXVBz4Y\/LenAizTPhzvCqyVo\/PdZWjfan9YqMW+CkkGA7\/mmOkU1lcl6Y4HOxVfybzlmhxDsPLzXZi3UGRcP6YfI74aBjZaOk5a\/ro3PQ1frQvf+QwNmyBn0KC0VI5Dvs6l9HSKXGrF++USGeYMdx4zY8fNAnGJNUdWJW2Dh3TAu0mGMh7991347smzmXwJzBZffTRR+M5DUYyE1BDjngmcC5YatZJOHWILTBufwoJhjkExubnGE5+e52f9shWy9WOn376aVzFSOdlYHhwmgnGLGN36kh+dWifFigkGGmO8dZbb4U333wzvpn1xhtvxAvcCEeeNHMKd4tbrrKamoSmJe0jf51mzqep+8dtCxQSDCTbM2Gw4vJ7RZEWeOmll3grhkdGfBNxTTzr9ovYFDXxU0gwWDJ9p4QpfMUVV4wVcavOVlttFdybYR4RAyv4ef+bMS\/FVIBaR+nEFigkGBjPUNWnT59QKo3ZFzHh9GoAUzfBqaQO5hcA7n\/qKxLNUDNQSDAmnnjieODXNjsrptp4b9U50HRiXFg1UF+RVNNaHY9bSDBc4nrwwQcHLxl5V9VeiZvyLr300sDIxVZRLelnHndou98PkV81tYff0Nke+XRWHtXyIeEXEgxawqqC9dJ3Srx4xE7hgnnm75R5OdeEMx3V+\/DBy+LqhhV17ODtej5vN2+DcnxoKb6QYJhDWHJ+8skn8RMUlq9sF6XSmPlGSwW1FUZA2oqvx3V+CxQSDHOMtdZaK35JkcZg8ErghWfzjc6vSr3E9myBQoLx9ddfhxtuuCF+rcDnr7zHmsDRPvHtSWQ9r85vgUKCYffUq4iuP8iDcPHlquKeLpNVZzVcwjJ48OC4l1IuXWfF+86bF6rQkIeI2gAACDlJREFU54072+35sq3CspNIw2seZ1z73Sjs9BwzQjW0VCUYhok999wzvPrqq\/E7aK5pzoNGhFeOiGeffTZ+I2XIkCHxq0j3339\/yJ7qKpe+I+PZaFxsRjCY8N0d5shi\/lsr7733XrxbLE2WHSvoSLqqyZutybdNttlmm2Cfqpq0cKsSDBPMI444IrgE\/cwzzwxebM6DcHgybwsIgfOfToPZS2Fed6ajrTSdFWcoNLF2Wk2Z7gIh7M668idwCZ35VvLXmsuE4C7yIuaDqgSDdRPTLVXZMny22zWNViUYbcnKwAWvXCONGDEiOPSS8NzPZds++cel62sBLp9zXAAdjiES3qxgGAoJhvdr3HWKAdXuE8m7o4AwOPfCxuTEXLXlZASj8qRU7eGHHx4nn4RCSieHzBOoYI0mrBwQrnI44yoebW0J+G+\/\/Ra\/GuDSW5+DMMQOHDgw0Czjiub2LLeQYCRVa1hxlhNBLKDeNWnpBJf4PPTq1SvYtk\/hnn2OIfnHpTvZZJPFt+nSaxBcn\/eaeuqpm8giODYNk9azb0RbFhnPmzKtoYdCgqFRqFoqN1sXE55SqRRPg4cyfz6G45sgjGXAs8Ytk6xTomlBDGejUSDX4SLzIX5gtm\/4IND8vrtCeKTj7+pQSDBMuHyHY+eddw6WaCagbtVx5tOHVMxDyjWMrx06zbX66quHVVddNRgPhZVL1xnxxmRLPFdcmyD7MhC\/cGHAB2q8EuHws0kq7Wn\/KCs8nUFrR5VRSDAQg6Emn4YSS08axJ2f2267reiyUCqVAlXskLBJq6sgS6ViJvWyhRVAcLU1m8wTTzwRP1PFLxtLV+C5b9++Af1Opnmxe5555hFcU2Bi7KM8hrlqCCssGAox4WT5dGDngAMOiJOxUql2mIvGOhRrgbESjGJF1lN1hRaoC0bHcalL51wXjC7Nvo4jvpBgMGDZADOxyW4iebbSsAVfjmS3\/oFyeFY9NqvK4VUSz\/jkIvxKabTxZOXFgFVJ\/h2BgwavZGjbStqrGhq0q3zlr5xs2kKCwRTsiuhBgwZFI1XaROIOHTr0b983zRY4Lp8Zn1gs0c5W0dG06EDtdTbFvSTps53tRbfD267LYu7P51lIMJiKfZPE\/kap1PYqxFLO+yYkk2s\/gaT6GC3QCxwV9Ny7d+\/gaKClq21vcb5t4iO30pBqqx947ulwtFDj5yvlTW\/GJ\/SxMXj3hRbzGQ0vVYvjz6bLpkGnvZ8U73NXLtNX7jnnnBNsCbRGMxppGbuxdp6V5+gjeoG9FfWBByqpT6KDq03k0a9fvzD77LPHXW5tJS6BfGkBbSYs7xdWDgoJBgMWabvsssuCQlsrRJy9BIYfFkIGIVvByyyzTHAZPdAL2Aqo68ceeyy+zcb07LIVcRtssEHc2nYI19tsyrILS9LZGdgRhCVQJmOT66y9HXf22WcHQjdy5MigbAY4NoesxmB5xSCn0twjhk5fUJaXOPejOxbg0xs+IEyIWqMZHdIYtu6+++74RQbDLnrZa2gs+cKrpD7w8uBsrUPXPt5rK4IQEtY83tj4CwmG3ka1MZzoBbRBguz4rTdrBGcafEdtnXXWCSSeST1LtC13DGQ11BNZVrPxng1fzOaMS4w1bCh6NgaJT+CsiMZ3mQvNxppqD8aJ9oSTdw2Bo0aNCr4+zbpJePbaa6\/47RW7lKy8dlinmWaauCPM9N0WzdI4y8El7HY40YtueXHt1FZSnzyt\/Msvv3xQL\/nLj+DavxLXXtBQJCO9zVxCg+ZBuHj5Grv0Cr1Hj3dSS68jMOITaCTqlfmZ5VSvTXHJlUblfb88CaG8zRsSDtdtgqVSqWm\/plQqBVZLAhda+UOfowSst1A0uCGIABOUbt26CW4GbdGcTeMoAUFIiRsaGuJLWpXWJ6XLuobIUmnMEK4ToTcb3x7PDUUzoQmoMN9bpSUIxGmnndZsaKElnNdwiRuzOUZefPHFf\/vKouFGDzQfueGGGwKm5OkqlUpxUuvEVxLGF154IRg2sriYaMIHhFOxmGN44m8J8mnQTbMZElrCF1YJzfB0DjR4BrQNf6lUWX2kyUN289KzuhLGhEfIu3fvnryF3EKCoWK+u+ocpK12Kpaq1JAuSRGPGr3CWE1lUtXC9Eoq3nPC01iOzamgyanJWoqDp7cbZpwcM\/ewi0vg0peV4CRwhZO8TBjlQSDNCZzCSjh5VxrDj\/Or0pi7SIfWPG7yl6M54VH7PiiIBtv3hl\/09+zZM56EK1eflE\/WNd9xvEE+Pj1mqNQ+CYemc+42TUrdSGASnOIrcRsqQcrj6FHOOx544IFhxhlnDNSjXodRhEW8NCapJpAOsVhtcPmF23DSSHqmYcQlsioozElzS2GrCasB6Vy2YrJqPDWvsYm3xhprBPeKKiuBBjn66KPjhNWs3a4oW4jd0ISTd6Wh1cxzCImGVzcNnMdN\/tZozs9laFS0AkOpdqBFdI5K6pPKy7o64sCBA4M2NHT2798\/Dk\/qCeCai1m1md\/Q0u4+E25+SMOnFYuwlqCQYKiUnkVDZDPVU0ulUtP4Hhr\/7EAaIqh\/Ln9jcPw8p5UIQaFtrBRItjOj6623XvywL1zLMuFWQXoFDcVvGLE7ixb5ZUGD+darMq1a5COeQY7gZcd84SClsXpi50ATPPjSwcn6xbdEMwHIptEmtuad10DzCiusEGjSUqkU3\/+tpD7KzoIzH3a20aoDEWzxDiMDz+pjVaTDaVMrI21o\/mfY9wyvNSgkGHq8mbtlHVVmxWA5xk6gV2BgawX+r4XrDLQLLWpe5n0cS8x0nrRW2+P\/AAAA\/\/91GbjVAAAABklEQVQDAP46nyLanr2NAAAAAElFTkSuQmCC","height":81,"width":134}}
%---
%[output:685a0eea]
%   data: {"dataType":"image","outputData":{"dataUri":"data:image\/png;base64,iVBORw0KGgoAAAANSUhEUgAAAIYAAABRCAYAAAAXQt4GAAAQAElEQVR4AezdBZRdtdYA4NyB914pvFLcH8WLF3cp7s6iuGuBBSygOBR3FlYcVnFn4RQvFLfiVty9uLf\/fCmZ\/8xhZu69pzPTO+\/dWbNvTpKdZCd7ZyfZyclpGD0Wf3\/88cfoN954Y\/Rtt902evjw4aN\/++230fW\/\/44WaAgF\/r777rtwwgknhEMPPTRccskl4ZFHHgnXXHNNOPzww8NBBx0UBg4cGIYNG1Yg53qSWmmBQoLxj3\/8I\/z555\/h5ZdfDvPPP39YaqmlwhxzzBGeeOKJMOmkk4bevXuH4447rlbqWKejQAsUEozGISS888474cQTTwybbLJJWHPNNcPWW28dBg0aFF5\/\/fWwxhprhFNPPbUAOfUktdIChQTjl19+Cd9\/\/32YYIIJmtWD3zDz888\/h3\/\/+9\/N4uqertUChQRj8sknD\/PNN1\/Ye++9w7333hs+\/vjj8Mwzz4QjjzwyzDbbbGHUqFHh2GOP7VotUae2WQsUEoxSqRQGDBgQdthhh3DOOeeEfv36hQMPPDDMM8884YADDgiGmgUWWKBZQXVP12qBQoKhig888EDo379\/2HXXXcNDDz0U7r777rDddtuFK6+8MvTo0SNsv\/320KqCH374IWy22WYRPJ977rlxcvviiy9WlU9byPvuu29Ybrnlwueffx7ka\/KsnLbSVBOXx1WO8pSbj8v6xcODnw3PP3cEzSnPmWeeOY4AyiwsGOONN16Ycsopw0477RRkCPr06RPuvPPOuGKRebUw0UQTRcEiXJ6rTV+L+Cbo0003XTjiiCNqkbxIE3ODOeP5558fVlpppRjWgKGAxMaQ3E9WmuCR6rfffjucfPLJsdfRGqusskpMtfDCC4cPP\/ww2jRIPlxpgJ4pL3MS\/tRLk59LSySNcfvtt8dVD4LXXXfdJkmOBTX+wJcPt9HbrPenfMQDdKAHXoIvvvgi7L777nESjXnqjz50SgM8C5MGvcLAWmut1UyTyVsZ4kCiSfhTTz0Vll122ZAEXTlwEsCV94033hg++OCDsPLKK8e65PH45ZenOV9XeaE3D3k89MpP+eoPXyfn99yAyRtssEG45557IkECE0iIkLnnnju88MIL4eabbw4jR46MS1F2DHjTTjtt+PHHHz2Gp59+Onz11VcBEXvttVcMe\/zxxwPo2bNntG38+uuvMbzcD8L333\/\/uLpRbpLklM7kd4YZZggjRoyIQaTew4ILLhi12EcffRTLVbbwjTfeOAqyZzDFFFOEs846K+avHD2a7SVbV3jyJRzmUvC0g6FSHNBG8qYVxMFJDcyP2bPOOivUgGnaWX1Sux911FFB+wP1Ef\/ZZ58FgqIHJzwCJpM8zcpKdYWPycqBmwA\/snjZNtGO0sHlpnaOQ0kiXGQWEEgQksTPO++84fnnn48MNpTA7datW7B89UxzmHSyYyB2kUUWicONIWfo0KFxmPjXv\/4Fdayhe\/fuATPMbzCHi6kyZnjbdNNNm8pGBwZhlPiWQI82hIHLL7880FK0FVzCwWXIg6c9+IE85S1MHBxL9bvuuisAz1NNNRXUKMTylLeeSetqF+0TEf76wRwCgWk6CCH5K6qZw5akruonD\/iES1sQhoSc8KppkygYKYNKXZVFPPwvv\/wy9OrVy2NQyTnnnDPQDjGgA38wATM0DOYQRH52FI2fLToJftIu2bjsM3VNxet12fB8upRfFkcaaTE9X37CYwTUdvx6MHxl8meBhjKMLb744nF4yca19Exw5NUavg6epynVIV+3lH9FgpES65kkWGVoD5nMNNNMcVz0vOWWW8Z9kvHHH5832jdILkhzB2o4NU5EGosfvVNyPZNm49c78\/kn+lNjSJMHzKDGqXS9lbpP+eTTpfyyeVDD0iWgDbLxnrUZjUuQMVEYptIenhMMHjw4PqJBfmiKAa38GL7gJaD1dJyEXqRN2hQMTKeejW+EQoWozSWWWCJOPlPBDQ1jsiEQm2++eQym3vRmagx41qNZRyGkxsVU\/iKQ6NO46OQHnq+66qo4p0A3+qlYqra1cjReVtMZPlIvIxiehRFyqjrlI095p3pgst7LXW211eLkVo+Fr0PpWD\/99FMcVjGU8ClbfALlpedEf\/Jn3VRX9KCLcNM0+TlGwqumTcZwNFta5pnUMVzpjSSc+tPj99tvv7gnAnXHHXcMwLMJ2oQTThiM\/yqtoalWYLa9yy67hEQkZmrA1157TdLQ0g8NIFx6De05C+gjbMK4\/EDvNf9AMxB\/3XXXxTmH5wSJFsMAMAYnup577rk4MdXo8lAfOATBcJXyMLbLm\/CpjzaCa6iFS2hSJxAunfzgyu+UU04JNAkh0um0UxqO1TtNbMXpmFmaTZjVVZ7Kgi+9dhaWoJo2SWmiYMiIikNgikiuMHFJTQ0fPjzuoq699trRpQ2AeO5FF10Ul2YabGjjhFM4SKoVkVSdMHDbbbcFroZMceI9Z8sWn2jKumiXnpvCpZWHcIAO9IhHR\/Jn8YTLAz4477zz4kRbPvCycZar8kogb3lKB+CKE07YCJcezZ\/Fg5vqxeXX1rRKwuOiQRwctCQ\/mrN+OMKUnYc8nnzRA0++0nL5QRQMD9WApd4ZZ5wRuNWk66q4tJUebihQBxqANswPAeLyYH5gYqx35+Nq2V+VYBjvSLNGag3Ew6vlSldLm56kR6XeyM32uLby0yvhStMWXq3FVSUYqZIaqTXQCPBaqujo0aPjplvqeS3h1MNqowWqEowsycZMVjvzANpjySWXDBdccEFwFiOLl3123M\/4mA3zLH0dZm7ac2qvtph++S3DpPs8EGHYiJGaumIoJBi21Y8\/\/vi4HLzlllui6fnCCy+Mk9GTTjop0Ax5CoyzV1xxRdMKJh\/fmgaqtfD77rsvTpZrja6W6MGLfDtX6i8kGN98800071q2Wj4ZOuaaa65w2GGHhVdeeSWwhmYJ+P3334NlFRuHvZVsXP25g1qgMdv3v\/6l8bfYfyHBsE\/yz3\/+82\/b62ljLU8K449DwksvvXQ+qslvqdsVwO5xV6DzkeffDPe+9ElT+\/5n0m5Nz5U8FBKMSSaZJGCyndc77rgjmr5NOvfZZ59Aczj6ly1c3Omnnx5mmWWWuPPJiMREnsWheboCTD\/99NFIV6u0jjfxNOHxLycIJwz7ITzz0RiNsfQsPUOnCEapVIontAgGg5ajfZZjG264YTziVyqVsjyP5vM0BhpSrO1bmoQ2S1T3lG0BQwW46qlPQ\/+rXg3rnP1c6HP0Y\/F52FsjY\/qGn74MZ206Z3yu5qeQxnDI5ZBDDgmGFAxm2bv11lvDFltsEbxzUg0BddzWWwDTgRUF5oOsABACIExcEoaUIy0x0bCTqtYW0hcSDObVhRZaKNoknNpyKPjhhx8OJpkybQsYi2iXtnD+m+MwGmA2wFCAuUCvB5aZmA7WGfRc1ALi4RIAeeTbiSAYNgasOlO4ZbcFwvBDlgg0Rh6vEn8hwbBDutFGG4Wbbropntqy3W4jyeaQjaLsJlMlRHRVHMwBGAwwDZww5N0mRmIywOA8s\/MMlxbTQVttQgDApotMHcDZjUNFEoRb+i8QBqzaKyw9a8+2sigbV0gw8rnSILaPDS3vv\/\/+31Yrefxa8mMswFiAOQlaYvDagz+MBqO2mHzCkHdCygOTgTIqqTeGAz0f0wHGg8R8mgAIA3DGVhDytBUSDNbN66+\/Pqy\/\/vrxxSMvGtn2HTJkSLj66quDVUu+oI7ya\/AEbTGWGtZzQeq9LTK3cRIHF7TE4I+\/+6OqqmAywGiAiQBDAWYDjP761L6BC\/R88QA+wHx5VUVAQeRCgsEcbsfRasTBUieNvMPaUQKB8YnpGJZlLiYnyKpmeFnG6sF6LpBfte2FIWDaHuOHLIMHNI7nmJcAkwHm5hndGrM7k+GV1ruQYNhud0qoI4VBBTAQgzE+MT0xWBycagBjAcYCvTBBlsEYCzAXZBl869bThyyDBzSO5ykPLiYD5VRDW63hFhKMjq4EphvfCQRByJen0UGWuQMyPRdTEyTGZpmLsSD1cu6ADIMxFigD5Mv\/X\/DXnGAQit0bx3nDQGIA5gxoZDxm5xmMqWBAC4xNzE351N3KW6CQYJh8mltws0XxtxSexSn3TEOYB8AjEIRBr8d4jBZeh45vgaoEA+O9zGyyaSeV61XCBNdee2045phj4snoIqSbYCZNkYSiLgxFWnLs01QlGCybTz75ZADffvttdB2pT+A2nT322KPwWdATG9f\/qUpn9ZuzkCk3pa+7Y9cCVQlGjx494r0YtILdUq4LUiIce2y8LMVriqVS8020SkikLdIQYlJZ1xSVtFrH4VQlGEzddke9uGwr3dE+t\/RlwW1+8LIke1nHlryXkBZbbLF48w5bSBbnqqf+\/+zA\/o0TzWxc\/bnzW6AqwbBzysLppaJFF1003tbnpaAsCIeXrYrjf\/ZXTEwffPDBeH7DCzoJZ1T3yaMJmd\/coq4ttMS4haoEA3NtlLFw9u3bN97W58a+LAiHl60WYdltt93iNr3zouYqhqWEM6r7ZOmxcVNomqbn+sO4a4GqBCOR6b0R74+0dJpZuPiEy3Vhm1cGvTbg3UrvuLoXVBz4Y\/LenAizTPhzvCqyVo\/PdZWjfan9YqMW+CkkGA7\/mmOkU1lcl6Y4HOxVfybzlmhxDsPLzXZi3UGRcP6YfI74aBjZaOk5a\/ro3PQ1frQvf+QwNmyBn0KC0VI5Dvs6l9HSKXGrF++USGeYMdx4zY8fNAnGJNUdWJW2Dh3TAu0mGMh7991347smzmXwJzBZffTRR+M5DUYyE1BDjngmcC5YatZJOHWILTBufwoJhjkExubnGE5+e52f9shWy9WOn376aVzFSOdlYHhwmgnGLGN36kh+dWifFigkGGmO8dZbb4U333wzvpn1xhtvxAvcCEeeNHMKd4tbrrKamoSmJe0jf51mzqep+8dtCxQSDCTbM2Gw4vJ7RZEWeOmll3grhkdGfBNxTTzr9ovYFDXxU0gwWDJ9p4QpfMUVV4wVcavOVlttFdybYR4RAyv4ef+bMS\/FVIBaR+nEFigkGBjPUNWnT59QKo3ZFzHh9GoAUzfBqaQO5hcA7n\/qKxLNUDNQSDAmnnjieODXNjsrptp4b9U50HRiXFg1UF+RVNNaHY9bSDBc4nrwwQcHLxl5V9VeiZvyLr300sDIxVZRLelnHndou98PkV81tYff0Nke+XRWHtXyIeEXEgxawqqC9dJ3Srx4xE7hgnnm75R5OdeEMx3V+\/DBy+LqhhV17ODtej5vN2+DcnxoKb6QYJhDWHJ+8skn8RMUlq9sF6XSmPlGSwW1FUZA2oqvx3V+CxQSDHOMtdZaK35JkcZg8ErghWfzjc6vSr3E9myBQoLx9ddfhxtuuCF+rcDnr7zHmsDRPvHtSWQ9r85vgUKCYffUq4iuP8iDcPHlquKeLpNVZzVcwjJ48OC4l1IuXWfF+86bF6rQkIeI2gAACDlJREFU54072+35sq3CspNIw2seZ1z73Sjs9BwzQjW0VCUYhok999wzvPrqq\/E7aK5pzoNGhFeOiGeffTZ+I2XIkCHxq0j3339\/yJ7qKpe+I+PZaFxsRjCY8N0d5shi\/lsr7733XrxbLE2WHSvoSLqqyZutybdNttlmm2Cfqpq0cKsSDBPMI444IrgE\/cwzzwxebM6DcHgybwsIgfOfToPZS2Fed6ajrTSdFWcoNLF2Wk2Z7gIh7M668idwCZ35VvLXmsuE4C7yIuaDqgSDdRPTLVXZMny22zWNViUYbcnKwAWvXCONGDEiOPSS8NzPZds++cel62sBLp9zXAAdjiES3qxgGAoJhvdr3HWKAdXuE8m7o4AwOPfCxuTEXLXlZASj8qRU7eGHHx4nn4RCSieHzBOoYI0mrBwQrnI44yoebW0J+G+\/\/Ra\/GuDSW5+DMMQOHDgw0Czjiub2LLeQYCRVa1hxlhNBLKDeNWnpBJf4PPTq1SvYtk\/hnn2OIfnHpTvZZJPFt+nSaxBcn\/eaeuqpm8giODYNk9azb0RbFhnPmzKtoYdCgqFRqFoqN1sXE55SqRRPg4cyfz6G45sgjGXAs8Ytk6xTomlBDGejUSDX4SLzIX5gtm\/4IND8vrtCeKTj7+pQSDBMuHyHY+eddw6WaCagbtVx5tOHVMxDyjWMrx06zbX66quHVVddNRgPhZVL1xnxxmRLPFdcmyD7MhC\/cGHAB2q8EuHws0kq7Wn\/KCs8nUFrR5VRSDAQg6Emn4YSS08axJ2f2267reiyUCqVAlXskLBJq6sgS6ViJvWyhRVAcLU1m8wTTzwRP1PFLxtLV+C5b9++Af1Opnmxe5555hFcU2Bi7KM8hrlqCCssGAox4WT5dGDngAMOiJOxUql2mIvGOhRrgbESjGJF1lN1hRaoC0bHcalL51wXjC7Nvo4jvpBgMGDZADOxyW4iebbSsAVfjmS3\/oFyeFY9NqvK4VUSz\/jkIvxKabTxZOXFgFVJ\/h2BgwavZGjbStqrGhq0q3zlr5xs2kKCwRTsiuhBgwZFI1XaROIOHTr0b983zRY4Lp8Zn1gs0c5W0dG06EDtdTbFvSTps53tRbfD267LYu7P51lIMJiKfZPE\/kap1PYqxFLO+yYkk2s\/gaT6GC3QCxwV9Ny7d+\/gaKClq21vcb5t4iO30pBqqx947ulwtFDj5yvlTW\/GJ\/SxMXj3hRbzGQ0vVYvjz6bLpkGnvZ8U73NXLtNX7jnnnBNsCbRGMxppGbuxdp6V5+gjeoG9FfWBByqpT6KDq03k0a9fvzD77LPHXW5tJS6BfGkBbSYs7xdWDgoJBgMWabvsssuCQlsrRJy9BIYfFkIGIVvByyyzTHAZPdAL2Aqo68ceeyy+zcb07LIVcRtssEHc2nYI19tsyrILS9LZGdgRhCVQJmOT66y9HXf22WcHQjdy5MigbAY4NoesxmB5xSCn0twjhk5fUJaXOPejOxbg0xs+IEyIWqMZHdIYtu6+++74RQbDLnrZa2gs+cKrpD7w8uBsrUPXPt5rK4IQEtY83tj4CwmG3ka1MZzoBbRBguz4rTdrBGcafEdtnXXWCSSeST1LtC13DGQ11BNZVrPxng1fzOaMS4w1bCh6NgaJT+CsiMZ3mQvNxppqD8aJ9oSTdw2Bo0aNCr4+zbpJePbaa6\/47RW7lKy8dlinmWaauCPM9N0WzdI4y8El7HY40YtueXHt1FZSnzyt\/Msvv3xQL\/nLj+DavxLXXtBQJCO9zVxCg+ZBuHj5Grv0Cr1Hj3dSS68jMOITaCTqlfmZ5VSvTXHJlUblfb88CaG8zRsSDtdtgqVSqWm\/plQqBVZLAhda+UOfowSst1A0uCGIABOUbt26CW4GbdGcTeMoAUFIiRsaGuJLWpXWJ6XLuobIUmnMEK4ToTcb3x7PDUUzoQmoMN9bpSUIxGmnndZsaKElnNdwiRuzOUZefPHFf\/vKouFGDzQfueGGGwKm5OkqlUpxUuvEVxLGF154IRg2sriYaMIHhFOxmGN44m8J8mnQTbMZElrCF1YJzfB0DjR4BrQNf6lUWX2kyUN289KzuhLGhEfIu3fvnryF3EKCoWK+u+ocpK12Kpaq1JAuSRGPGr3CWE1lUtXC9Eoq3nPC01iOzamgyanJWoqDp7cbZpwcM\/ewi0vg0peV4CRwhZO8TBjlQSDNCZzCSjh5VxrDj\/Or0pi7SIfWPG7yl6M54VH7PiiIBtv3hl\/09+zZM56EK1eflE\/WNd9xvEE+Pj1mqNQ+CYemc+42TUrdSGASnOIrcRsqQcrj6FHOOx544IFhxhlnDNSjXodRhEW8NCapJpAOsVhtcPmF23DSSHqmYcQlsioozElzS2GrCasB6Vy2YrJqPDWvsYm3xhprBPeKKiuBBjn66KPjhNWs3a4oW4jd0ISTd6Wh1cxzCImGVzcNnMdN\/tZozs9laFS0AkOpdqBFdI5K6pPKy7o64sCBA4M2NHT2798\/Dk\/qCeCai1m1md\/Q0u4+E25+SMOnFYuwlqCQYKiUnkVDZDPVU0ulUtP4Hhr\/7EAaIqh\/Ln9jcPw8p5UIQaFtrBRItjOj6623XvywL1zLMuFWQXoFDcVvGLE7ixb5ZUGD+darMq1a5COeQY7gZcd84SClsXpi50ATPPjSwcn6xbdEMwHIptEmtuad10DzCiusEGjSUqkU3\/+tpD7KzoIzH3a20aoDEWzxDiMDz+pjVaTDaVMrI21o\/mfY9wyvNSgkGHq8mbtlHVVmxWA5xk6gV2BgawX+r4XrDLQLLWpe5n0cS8x0nrRW2+P\/AAAA\/\/91GbjVAAAABklEQVQDAP46nyLanr2NAAAAAElFTkSuQmCC","height":81,"width":134}}
%---
