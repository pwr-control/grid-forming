% EARTHING_CASES  The earthing schemes of the LV star point (IT, HRG, TN) in pgfm_ctrl_analysis
% Runs the model to ec_stop (0.3 s) once per value of param.gnd.r_star, with the Simscape log of the earth
% paths (battery_1/HF and Ground Network, grid/grid_emulator/3ph_Dyg_ssc), and evaluates the last three grid
% periods: voltages of the battery poles and of the transformer star point to earth, current to earth and its
% content by frequency band (what a residual current monitor would see). Table in the Command Window and in
% <ec_out>/earthing_cases.txt, figure <ec_out>/hf_cases.png: the table and the figure of the section
% "Earthing" of the design note (repositories-documentation/repos_doc/parallel_of_gfms; copy the figure into
% its folder figures/ to update the note). Results also in the struct "earthing" of the workspace.
%
% Run init_model first. Optional, set before the call: ec_stop [s], ec_cases (struct array with fields
% name, r_star), ec_out (output folder, default tempdir/pgfm_earthing_cases). About 2 minutes per case.
% The logging settings are restored at the end; the model is not saved.
%
% Note: the Simscape log keeps only the last 5000 points by default (5 ms at tc = 1 us); the script sets the
% history to the whole analysis window.

ec_mdl = 'pgfm_ctrl_analysis';
assert(exist('param', 'var') == 1 && isfield(param, 'gnd'), 'earthing_cases: run init_model first');
if ~exist('ec_stop', 'var'), ec_stop = 0.3; end
if ~exist('ec_cases', 'var')
    ec_cases = struct('name', {'IT', 'HRG', 'TN'}, 'r_star', {1e9, 230, 0.1});
end
if ~exist('ec_out', 'var'), ec_out = fullfile(tempdir, 'pgfm_earthing_cases'); end
if ~exist(ec_out, 'dir'), mkdir(ec_out); end
ec_win = [ec_stop - 3/param.grid.fgrid, ec_stop];       % last three grid periods
ec_dt = param.sim.tc;

% ---- logging of the earth paths (restored at the end)
load_system(ec_mdl);
ec_hf = [ec_mdl '/battery_1/HF and Ground Network'];
ec_tr = [ec_mdl '/grid/grid_emulator/3ph_Dyg_ssc'];
ec_blk = [strcat([ec_hf '/'], {'Resistor3', 'Resistor2', 'Capacitor', 'Capacitor1'}), ...
          strcat([ec_tr '/'], {'C_lv_earth', 'R_star'})];
ec_log0 = get_param(ec_blk, 'LogSimulationData');
ec_cfg = {'SimscapeLogType', 'SimscapeLogName', 'SimscapeLogLimitData', 'SimscapeLogDataHistory'};
ec_cfg0 = cellfun(@(x) get_param(ec_mdl, x), ec_cfg, 'UniformOutput', false);
for ec_k = 1:numel(ec_blk), set_param(ec_blk{ec_k}, 'LogSimulationData', 'on'); end
set_param(ec_mdl, 'SimscapeLogType', 'local', 'SimscapeLogName', 'simlog', 'SimscapeLogLimitData', 'on', ...
    'SimscapeLogDataHistory', ceil(1.2*diff(ec_win)/ec_dt));

% ---- one run per case
ec_r_star0 = param.gnd.r_star;
earthing = struct();
for ec_c = 1:numel(ec_cases)
    param.gnd.r_star = ec_cases(ec_c).r_star;
    fprintf('earthing_cases: %s, r_star = %g Ohm, run to %g s\n', ec_cases(ec_c).name, param.gnd.r_star, ec_stop);
    ec_t0 = tic;
    ec_so = sim(ec_mdl, 'StopTime', num2str(ec_stop), 'ReturnWorkspaceOutputs', 'on');
    fprintf('  done in %.0f s\n', toc(ec_t0));
    ec_sl = ec_so.get('simlog');
    ec_get = @(path, v, u) earthing_cases_node(ec_sl, path, v, u);
    ec_vp = ec_get({'battery_1', 'HF and Ground Network', 'Resistor3'}, 'v', 'V');    % DC+ to earth
    ec_vn = ec_get({'battery_1', 'HF and Ground Network', 'Resistor2'}, 'v', 'V');    % DC- to earth
    ec_ip = ec_get({'battery_1', 'HF and Ground Network', 'Capacitor'}, 'i', 'A');    % C branch of DC+
    ec_in = ec_get({'battery_1', 'HF and Ground Network', 'Capacitor1'}, 'i', 'A');   % C branch of DC-
    ec_ic = ec_get({'grid', 'grid_emulator', '3ph_Dyg_ssc', 'C_lv_earth'}, 'i', 'A');
    ec_vs = ec_get({'grid', 'grid_emulator', '3ph_Dyg_ssc', 'R_star'}, 'v', 'V');     % star point to earth
    ec_is = ec_get({'grid', 'grid_emulator', '3ph_Dyg_ssc', 'R_star'}, 'i', 'A');
    % uniform grid over the window (the log follows the solver steps)
    ec_tg = (ec_win(1):ec_dt:ec_win(2) - ec_dt/2).';
    ec_u = @(s) interp1(s.t, s.y, ec_tg, 'linear');
    ec_e = struct('t', ec_tg, 'r_star', param.gnd.r_star);
    ec_e.v_dcp = ec_u(ec_vp); ec_e.v_dcn = ec_u(ec_vn); ec_e.v_star = ec_u(ec_vs); ec_e.i_star = ec_u(ec_is);
    ec_e.v_mid = (ec_e.v_dcp + ec_e.v_dcn)/2;
    ec_e.i_earth = ec_u(ec_ip) + ec_u(ec_in) + (ec_e.v_dcp + ec_e.v_dcn)/param.gnd.r_gnd_pole;    % DC side to earth
    ec_e.i_earth_ac = ec_u(ec_ic) + ec_e.i_star;                                               % AC side to earth
    earthing.(ec_cases(ec_c).name) = ec_e;
end
param.gnd.r_star = ec_r_star0;
for ec_k = 1:numel(ec_blk), set_param(ec_blk{ec_k}, 'LogSimulationData', ec_log0{ec_k}); end
for ec_k = 1:numel(ec_cfg), set_param(ec_mdl, ec_cfg{ec_k}, ec_cfg0{ec_k}); end

% ---- table: amplitude at 150 Hz, peak to peak, rms, rms by band (one-sided spectrum of the window)
ec_fid = fopen(fullfile(ec_out, 'earthing_cases.txt'), 'w');
ec_sig = {'v_dcp', 'DC+ to earth [V]'; 'v_mid', 'battery midpoint to earth [V]'; ...
          'v_star', 'LV star point to earth [V]'; 'i_earth', 'current to earth [A]'; 'i_star', 'current in R_star [A]'};
ec_bands = [0 2e3; 2e3 20e3; 20e3 0.5/ec_dt];
for ec_fh = [1, ec_fid]
    fprintf(ec_fh, 'earthing_cases: run to %g s, window %.3f-%.3f s, c_batt_pole %g F, r_batt_hf %g Ohm, r_gnd_pole %g Ohm, c_ac_phase %g F, r_ac_hf %g Ohm\n', ...
        ec_stop, ec_win, param.gnd.c_batt_pole, param.gnd.r_batt_hf, param.gnd.r_gnd_pole, param.gnd.c_ac_phase, param.gnd.r_ac_hf);
    fprintf(ec_fh, '%-30s %-5s %10s %10s %10s %10s %10s %10s %10s\n', 'quantity', 'case', 'pp', 'peak', 'rms(ac)', '|150 Hz|', ...
        '0-2k rms', '2-20k rms', '>20k rms');
    for ec_q = 1:size(ec_sig, 1)
        for ec_c = 1:numel(ec_cases)
            ec_e = earthing.(ec_cases(ec_c).name);
            ec_y = ec_e.(ec_sig{ec_q, 1}); ec_y = ec_y - mean(ec_y);
            ec_N = numel(ec_y); ec_Y = fft(ec_y)/ec_N; ec_fk = (0:ec_N - 1).'/(ec_N*ec_dt);
            ec_h = ec_fk > 0 & ec_fk < 0.5/ec_dt; ec_Pk = 2*abs(ec_Y(ec_h)).^2; ec_fk = ec_fk(ec_h);
            ec_b = arrayfun(@(k) sqrt(sum(ec_Pk(ec_fk > ec_bands(k, 1) & ec_fk <= ec_bands(k, 2)))), 1:3);
            ec_a150 = abs(2*mean(ec_y .* exp(-1j*2*pi*150*ec_e.t)));
            fprintf(ec_fh, '%-30s %-5s %10.3g %10.3g %10.3g %10.3g %10.3g %10.3g %10.3g\n', ec_sig{ec_q, 2}, ...
                ec_cases(ec_c).name, max(ec_y) - min(ec_y), max(abs(ec_y)), sqrt(mean(ec_y.^2)), ec_a150, ec_b);
        end
    end
end
fclose(ec_fid);

% ---- figure: last grid period, voltages to earth (top) and current to earth (bottom)
ec_f = figure('Visible', 'off', 'Units', 'pixels', 'Position', [0 0 1500 820]);
ec_tl = tiledlayout(ec_f, 2, numel(ec_cases), 'TileSpacing', 'compact', 'Padding', 'compact');
for ec_c = 1:numel(ec_cases)
    ec_e = earthing.(ec_cases(ec_c).name);
    ec_i = ec_e.t >= ec_win(2) - 1/param.grid.fgrid;
    ec_tm = (ec_e.t(ec_i) - ec_e.t(find(ec_i, 1)))*1e3;
    ec_ax = nexttile(ec_tl, ec_c); hold(ec_ax, 'on'); grid(ec_ax, 'on'); box(ec_ax, 'on');
    plot(ec_ax, ec_tm, ec_e.v_dcp(ec_i), 'Color', [0 0.447 0.741]);
    plot(ec_ax, ec_tm, ec_e.v_dcn(ec_i), 'Color', [0.85 0.325 0.098]);
    plot(ec_ax, ec_tm, ec_e.v_star(ec_i), 'Color', [0.3 0.3 0.3]);
    ylim(ec_ax, [-1300 1300]); xlim(ec_ax, [0 1e3/param.grid.fgrid]);
    if ec_e.r_star >= 1e6
        title(ec_ax, sprintf('%s: star point not earthed', ec_cases(ec_c).name), 'FontWeight', 'normal');
    else
        title(ec_ax, sprintf('%s: star point to earth, %g \\Omega', ec_cases(ec_c).name, ec_e.r_star), 'FontWeight', 'normal');
    end
    if ec_c == 1, ylabel(ec_ax, 'voltage to earth [V]'); legend(ec_ax, {'DC+', 'DC-', 'LV star'}, 'Location', 'southwest'); end
    ec_ax = nexttile(ec_tl, ec_c + numel(ec_cases)); hold(ec_ax, 'on'); grid(ec_ax, 'on'); box(ec_ax, 'on');
    plot(ec_ax, ec_tm, ec_e.i_earth(ec_i), 'Color', [0.494 0.184 0.556]);
    ylim(ec_ax, [-16 16]); xlim(ec_ax, [0 1e3/param.grid.fgrid]);
    xlabel(ec_ax, 't [ms] (last grid period of the run)');
    if ec_c == 1, ylabel(ec_ax, 'current to earth, DC side [A]'); end
end
exportgraphics(ec_f, fullfile(ec_out, 'hf_cases.png'), 'Resolution', 200);
close(ec_f);
fprintf('earthing_cases: table and figure in %s\n', ec_out);
clear('-regexp', '^ec_(?!stop$|cases$|out$)')   % keeps the inputs ec_stop, ec_cases, ec_out

% ---- local function
function s = earthing_cases_node(sl, path, v, unit)
% node of the Simscape log by block names: blanks of the names become underscores in the log, a name that
% starts with a digit gets a prefix, so the names are compared on their letters and digits only
key = @(x) regexprep(lower(x), '[^a-z0-9]', '');
nd = sl;
for k = 1:numel(path)
    ids = nd.childIds;
    kp = key(path{k});
    j = find(cellfun(@(x) strcmp(key(x), kp) || strcmp(key(x), ['x' kp]), ids), 1);
    assert(~isempty(j), 'earthing_cases: "%s" not found in the Simscape log under "%s"', path{k}, nd.id);
    nd = nd.child(ids{j});
end
x = nd.child(v);
[t, iu] = unique(x.series.time, 'last');
y = x.series.values(unit);
s = struct('t', t, 'y', y(iu));
end
