
clear; close all; clc;
load sim_results_icc4inom.mat;

tc_eq = glb_time.tc*glb_time.decimation_tc;

%% plot with positive reactive current 
N2 = floor(simlength/tc_eq);
N1 = N2 - 10/grid_emu.fgrid_nom/tc_eq + 1;

time = t_tc_sim(N1:N2);

ig_a = ig_abc_sim(N1:N2,1);
ig_b = ig_abc_sim(N1:N2,2);
ig_c = ig_abc_sim(N1:N2,3);
ug_a = ug_abc_sim(N1:N2,1);
ug_b = ug_abc_sim(N1:N2,2);
ug_c = ug_abc_sim(N1:N2,3);

N = length(time);

[ig_alpha, ig_beta] = abc2alphabeta(ig_a, ig_b, ig_c);
[ug_alpha, ug_beta] = abc2alphabeta(ug_a, ug_b, ug_c);

figure; plot(ig_alpha, ig_beta); grid on
set(gca, 'xlim', [-1500 1500]);
set(gca, 'ylim', [-1500 1500]);
axis equal;

%% plot with zero reactive current 
N2 = floor(time_i_react_pos_ref_1/tc_eq);
N1 = N2 - 10/grid_emu.fgrid_nom/tc_eq + 1;

time = t_tc_sim(N1:N2);

ig_a = ig_abc_sim(N1:N2,1);
ig_b = ig_abc_sim(N1:N2,2);
ig_c = ig_abc_sim(N1:N2,3);
ug_a = ug_abc_sim(N1:N2,1);
ug_b = ug_abc_sim(N1:N2,2);
ug_c = ug_abc_sim(N1:N2,3);

N = length(time);

[ig_alpha, ig_beta] = abc2alphabeta(ig_a, ig_b, ig_c);
[ug_alpha, ug_beta] = abc2alphabeta(ug_a, ug_b, ug_c);

figure; plot(ig_alpha, ig_beta); grid on
set(gca, 'xlim', [-1500 1500]);
set(gca, 'ylim', [-1500 1500]);
axis equal;

%% plot with negative reactive current 
N2 = floor(time_i_react_pos_ref_2/tc_eq);
N1 = N2 - 10/grid_emu.fgrid_nom/tc_eq + 1;

time = t_tc_sim(N1:N2);

ig_a = ig_abc_sim(N1:N2,1);
ig_b = ig_abc_sim(N1:N2,2);
ig_c = ig_abc_sim(N1:N2,3);
ug_a = ug_abc_sim(N1:N2,1);
ug_b = ug_abc_sim(N1:N2,2);
ug_c = ug_abc_sim(N1:N2,3);

N = length(time);

[ig_alpha, ig_beta] = abc2alphabeta(ig_a, ig_b, ig_c);
[ug_alpha, ug_beta] = abc2alphabeta(ug_a, ug_b, ug_c);

figure; plot(ig_alpha, ig_beta); grid on
set(gca, 'xlim', [-1500 1500]);
set(gca, 'ylim', [-1500 1500]);
axis equal;