% =========================================================
% Polar diagram of three-phase currents iu, iv, iw
% Balanced three-wire system: iu + iv + iw = 0
% =========================================================

clear; close all; clc;

%% --- Signal parameters ---
f  = 50;          % Fundamental frequency [Hz]
T  = 1/f;         % Period [s]
Fs = 10e3;        % Sampling frequency [Hz]
t  = 0 : 1/Fs : T - 1/Fs;   % One period time vector

Im1  = 100;        % Peak current amplitude [A]
Im2  = 80;        % Peak current amplitude [A]
phi1 = 0;          % Initial phase of iu [rad]  (adjust as needed)
phi2 = pi/6;          % Initial phase of iu [rad]  (adjust as needed)

%% --- Three-phase currents (120° displaced) ---
iu = Im1 * cos(2*pi*f*t + phi1);
iv = Im2 * cos(2*pi*f*t + phi2 - 2*pi/3);
% iw = Im3 * cos(2*pi*f*t + phi + 2*pi/3);   % = -(iu+iv), guaranteed
iw = -(iu+iv);   % = -(iu+iv), guaranteed

% Sanity check: max residual of Kirchhoff's current law
fprintf('Max |iu+iv+iw| = %.2e A  (should be ~0)\n', max(abs(iu+iv+iw)));

%% --- Fundamental phasors (DFT at f0) ---
% Complex phasor = (2/N) * sum( x(t)*exp(-j*2*pi*f*t) )
N   = length(t);
k1  = round(f * N / Fs);    % DFT bin index for f0

phasor = @(x) (2/N) * sum(x .* exp(-1j*2*pi*(0:N-1)*k1/N));

Iu = phasor(iu);
Iv = phasor(iv);
Iw = phasor(iw);

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
polarplot(ax, theta_c, 2*max(Im1,Im2)*ones(size(theta_c)), '--', ...
    'Color',[0.6 0.6 0.6],'LineWidth',0.8);

title(ax, sprintf('Three-phase phasors:  freq = %d Hz', f), ...
    'Interpreter','latex','FontSize',13);

ax.ThetaZeroLocation = 'right';   % 0° on the right (standard convention)
ax.ThetaDir          = 'counterclockwise';     % counter-clockwise positive
ax.GridAlpha         = 0.3;
ax.FontSize          = 11;

hold(ax,'off');