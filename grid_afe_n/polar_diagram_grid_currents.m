% =========================================================
% Polar diagram of three-phase currents iu, iv, iw
% Balanced three-wire system: iu + iv + iw = 0
% =========================================================

clear; close all; clc;
load sim_results_icc6inom.mat;

%% --- Fundamental phasors (DFT at f0) ---
% Complex phasor = (2/N) * sum( x(t)*exp(-j*2*pi*f*t) )

tc_eq = glb_time.tc*glb_time.decimation_tc;
N2 = glb_time.Nc;
N1 = N2 - 10/grid_emu.fgrid_nom/tc_eq + 1;
time = t_tc_sim(N1:N2);
iu = ig_abc_sim(N1:N2,1);
iv = ig_abc_sim(N1:N2,2);
iw = ig_abc_sim(N1:N2,3);

N = length(time);
k1  = round(grid_emu.fgrid_nom * N * tc_eq); 

phasor = @(x) (2/N) * sum(x .* exp(-1j*2*pi*(0:N-1)*k1/N));  

Iu = phasor(iu);
Iv = phasor(iv);
Iw = phasor(iw);

figure; plot(time, iu, time, iv, time, iw); grid on

%% --- Polar plot ---
figure('Name','Three-phase current phasors','Color','w','Position',[100 100 600 600]);

ax = polaraxes;
hold(ax,'on');

% colors = {'#0072BD', '#D95319', '#77AC30'};   % U=blue, V=orange, W=green
colors = {[0.25 0.25 0.25], [0.5 0.5 0.5], [0.75 0.75 0.75]};
labels = {'$i_u$','$i_v$','$i_w$'};
phasors = [Iu, Iv, Iw];

for k = 1:3
    theta = angle(phasors(k));
    r     = abs(phasors(k));

    % Draw arrow from origin to phasor tip
    polarplot(ax, [0 theta], [0 r], '-', ...
        'LineWidth', 2.5, 'Color', colors{k});

    % Phasor tip marker
    polarplot(ax, theta, r, 'o', ...
        'MarkerSize', 7, 'MarkerFaceColor', colors{k}, 'Color', colors{k});

    % Label (slightly beyond tip)
    text(ax, theta, r*1.10, labels{k}, ...
        'Interpreter','latex','FontSize',14, ...
        'HorizontalAlignment','center','Color',colors{k});
end

% Reference circle at Im (peak value)
theta_c = linspace(0, 2*pi, 360);
polarplot(ax, theta_c, ones(size(theta_c)), '--', ...
    'Color',[0.6 0.6 0.6],'LineWidth',0.8);

% title(ax, sprintf('Three-phase phasors:  freq = %d Hz', grid_emu.fgrid_nom), ...
%     'Interpreter','latex','FontSize',13);
title(ax, sprintf('Three-phase phasors'), ...
    'Interpreter','latex','FontSize',13);
ax.ThetaZeroLocation = 'right';   % 0° on the right (standard convention)
ax.ThetaDir          = 'counterclockwise';     % counter-clockwise positive
ax.GridAlpha         = 0.3;
ax.FontSize          = 11;

hold(ax,'off');