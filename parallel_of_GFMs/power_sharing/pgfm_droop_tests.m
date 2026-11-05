function res = pgfm_droop_tests(cases, out_dir)
%PGFM_DROOP_TESTS  Tests T0 to T5 of the design note on pgfm_droop.slx (three grid-forming modules, droop mode).
%
%   res = pgfm_droop_tests                  all the cases, results in ./results
%   res = pgfm_droop_tests(cases)           cases: name or cell array of names of init_pgfm_droop
%   res = pgfm_droop_tests(cases, out_dir)  folder of the results
%
%   For each case: param = init_pgfm_droop(case), simulation of pgfm_droop.slx (built by build_pgfm_droop when
%   missing), metrics and checks (printed and written to <case>.txt), a figure <case>.png and the signals with
%   1 ms resolution <case>.mat (MAT v7, also readable by scipy.io.loadmat) in out_dir.
%
%   Signals (pu of a module, Sb = 277.8 kVA): f = 50*w of the phase generator of each module (log 48, local time
%   base), p, q, P_f, Q_f (log 44:47), |u| bus voltage at the terminal of each module (m(10:12)), |i_s| converter
%   current (m(1:3)), E, dx, droop state (log 49, 54, 55).
%   Metrics of each event (opening of the grid breaker, load step, trip, setpoint step, black start):
%     before, after  means in the 0.15 s before the event and before the next event (or the end)
%     f_ext          frequency nadir (peak for a rise) after the event, mean of the running modules
%     rocof          max |df/dt| in the 0.2 s after the event (10 ms moving average of f)
%     u_min, u_max   extremes of the bus voltage |u| (module 1 terminal, 1 ms average) in the 0.2 s after the event
%     i_peak         peak of |i_s| of the running modules in that window: instantaneous (with the PWM ripple) and
%                    1 ms average
%     t_set, ovs     settling of P_f of the running modules into +-0.01 pu of the value after, overshoot of the
%                    mean P_f in % of its step
%   Checks (window: the last 0.2 s): in the island equal sharing (spread of P_f below 0.01 pu, of Q_f below
%   0.02 pu among the running modules; T0_off and T4_* only report the spread, the design note gives the expected
%   values), on the grid P_f = P* within 0.01 pu; f = 50(1 + mp(P* - P_f)) within 0.02 Hz; peak-to-peak of P_f
%   below 0.02 pu (damped); 1 ms average of |i_s| below droop_i_max + 0.05 pu after droop_t_sync + 20 ms.
%
%   See also init_pgfm_droop, build_pgfm_droop.

    all_cases = {'T1', 'T3', 'T5', 'black', 'T0_off', 'T0_on', 'T4_L1', 'T4_cable', 'T4_gain'};
    if nargin < 1 || isempty(cases)
        cases = all_cases;
    end
    if ischar(cases) || isstring(cases)
        cases = cellstr(cases);
    end
    here = fileparts(mfilename('fullpath'));
    if nargin < 2 || isempty(out_dir)
        out_dir = fullfile(here, 'results');
    end
    if ~exist(out_dir, 'dir')
        mkdir(out_dir);
    end
    mdl = 'pgfm_droop';
    if ~exist(fullfile(here, [mdl '.slx']), 'file')
        build_pgfm_droop;
    end
    load_system(fullfile(here, [mdl '.slx']));

    res = struct('name', {}, 'wall', {}, 'ev', {}, 'chk', {}, 'pass', {}, 'fin', {});
    for c = 1:numel(cases)
        name = cases{c};
        param = init_pgfm_droop(name);
        fprintf('%-9s %.2f s of simulation ... ', name, param.tb.t_end);
        try
            in = Simulink.SimulationInput(mdl);
            in = in.setVariable('param', param);
            t0 = tic;
            out = sim(in);
            wall = toc(t0);
            if ~isempty(out.ErrorMessage)
                error('pgfm_droop_tests:sim', '%s', out.ErrorMessage);
            end
            fprintf('%.0f s wall\n', wall);
            d = local_data(out, param);
            ev = local_events(d, param);
            [chk, pass, fin] = local_checks(d, param);
            r = struct('name', name, 'wall', wall, 'ev', ev, 'chk', {chk}, 'pass', pass, 'fin', fin);
            res(end + 1) = r; %#ok<AGROW>
            txt = local_text(r, param);
            fprintf('%s', txt);
            f = fopen(fullfile(out_dir, [name '.txt']), 'w');
            fprintf(f, '%s', txt);
            fclose(f);
            local_plot(d, param, ev, fullfile(out_dir, [name '.png']));
            local_save(d, r, fullfile(out_dir, [name '.mat']));
        catch err
            fprintf('error\n%s\n', getReport(err, 'extended', 'hyperlinks', 'off'));
            res(end + 1) = struct('name', name, 'wall', nan, 'ev', struct([]), 'chk', {{}}, 'pass', false, ...
                'fin', struct()); %#ok<AGROW>
        end
    end
    fprintf('\n%-9s %-6s %s\n', 'case', 'result', 'wall [s]');
    for c = 1:numel(res)
        fprintf('%-9s %-6s %.0f\n', res(c).name, local_tf(res(c).pass), res(c).wall);
    end
end

% --------------------------------------------------------------------------------------------------------------
function d = local_data(out, param)
%LOCAL_DATA  Logged signals of the three modules, one row per log sample (param.sim.ts_log).
    lg = cell(1, 3);
    m  = cell(1, 3);
    N  = inf;
    for k = 1:3
        ts = out.get(sprintf('log_%d', k));
        tm = out.get(sprintf('m_%d', k));
        lg{k} = local_rows(ts.Data, 55);
        m{k}  = local_rows(tm.Data, 17);
        N = min([N, size(lg{k}, 1), size(m{k}, 1)]);
        if k == 1
            t = ts.Time(:);
        end
    end
    d.t = t(1:N);
    for k = 1:3
        L = lg{k}(1:N, :);
        M = m{k}(1:N, :);
        d.f(:, k)     = 50*L(:, 48);
        d.p(:, k)     = L(:, 44);
        d.q(:, k)     = L(:, 45);
        d.pf(:, k)    = L(:, 46);
        d.qf(:, k)    = L(:, 47);
        d.E(:, k)     = L(:, 49);
        d.dx(:, k)    = L(:, 54);
        d.state(:, k) = L(:, 55);
        d.is(:, k)    = local_mag(M(:, 1:3));
        d.uc(:, k)    = local_mag(M(:, 4:6));
        d.u(:, k)     = local_mag(M(:, 10:12));
        d.udc(:, k)   = M(:, 13);
    end
    d.dt = param.sim.ts_log;
    n1 = max(1, round(1e-3/d.dt));
    d.is_avg = movmean(d.is, n1);
    d.u_avg  = movmean(d.u, n1);
end

function y = local_rows(x, n)
%LOCAL_ROWS  Data of a timeseries of an n-element signal as rows (samples) x n.
    x = squeeze(x);
    if size(x, 1) == n && size(x, 2) ~= n
        x = x.';
    end
    y = x;
end

function y = local_mag(x)
%LOCAL_MAG  Magnitude of the space vector of the phase values x (columns a, b, c; amplitude-invariant).
    y = sqrt(2/3*sum(x.^2, 2));
end

% --------------------------------------------------------------------------------------------------------------
function run = local_running(param, t)
%LOCAL_RUNNING  Modules connected to the bus at time t.
    run = find(param.tb.t_trip > t);
end

function ev = local_events(d, param)
%LOCAL_EVENTS  Events of the case and their metrics (see the header).
    tb = param.tb;
    c  = param.mod(1).ctrl;
    e  = {};
    if tb.t_open == 0
        e(end + 1, :) = {c.droop_t_sync, 'black start'};
    end
    if tb.t_open > 0 && tb.t_open < tb.t_end
        e(end + 1, :) = {tb.t_open, 'grid lost'};
    end
    if tb.t_step < tb.t_end
        e(end + 1, :) = {tb.t_step, sprintf('load step %+.0f kW', param.load.p_step/1e3)};
    end
    for k = 1:3
        if tb.t_trip(k) < tb.t_end
            e(end + 1, :) = {tb.t_trip(k), sprintf('trip of module %d', k)}; %#ok<AGROW>
        end
        if tb.sync_t(k) < tb.t_end
            e(end + 1, :) = {tb.sync_t(k), sprintf('setpoint step of module %d', k)}; %#ok<AGROW>
        end
    end
    if isempty(e)
        ev = struct([]);
        return
    end
    [~, o] = sort(cell2mat(e(:, 1)));
    e = e(o, :);
    t = d.t;
    n10 = max(1, round(10e-3/d.dt));
    for j = 1:size(e, 1)
        te = e{j, 1};
        if j < size(e, 1)
            tn = e{j + 1, 1};
        else
            tn = tb.t_end;
        end
        rb = local_running(param, te - 1e-6);
        ra = local_running(param, tn - 1e-6);
        wb = t >= te - 0.15 & t < te;
        wa = t >= tn - 0.15 & t < tn;
        w2 = t >= te & t < min(te + 0.2, tn);
        wn = t >= te & t < tn;
        x.t = te;
        x.label = e{j, 2};
        x.f_before  = local_mean(d.f(wb, rb));
        x.f_after   = local_mean(d.f(wa, ra));
        x.P_before  = mean(d.pf(wb, :), 1);
        x.P_after   = mean(d.pf(wa, :), 1);
        x.Q_before  = mean(d.qf(wb, :), 1);
        x.Q_after   = mean(d.qf(wa, :), 1);
        x.u_before  = mean(d.u(wb, 1));
        x.u_after   = mean(d.u(wa, 1));
        fa = mean(d.f(:, ra), 2);
        if x.f_after < x.f_before
            x.f_ext = local_nz(min(fa(wn)));
        else
            x.f_ext = local_nz(max(fa(wn)));
        end
        fs = movmean(fa, n10);
        dfdt = [0; diff(fs)]/d.dt;
        x.rocof = local_nz(max(abs(dfdt(w2 & t > te + 10e-3)), [], 'omitnan'));
        x.u_min = local_nz(min(d.u_avg(w2, 1)));
        x.u_max = local_nz(max(d.u_avg(w2, 1)));
        x.i_peak     = local_nz(max(max(d.is(w2, ra))));
        x.i_peak_avg = local_nz(max(max(d.is_avg(w2, ra))));
        pfin = mean(d.pf(wa, ra), 1);
        dev  = max(abs(d.pf(wn, ra) - pfin), [], 2);
        tw   = t(wn);
        last = find(dev > 0.01, 1, 'last');
        if isempty(last)
            x.t_set = 0;
        else
            x.t_set = tw(last) - te;
        end
        dP = mean(x.P_after(ra)) - mean(x.P_before(ra));
        if abs(dP) > 0.02 && ~isempty(wb) && any(wb)
            pm = mean(d.pf(wn, ra), 2);
            x.ovs = max(0, max(sign(dP)*(pm - mean(pfin))))/abs(dP)*100;
        else
            x.ovs = nan;
        end
        if strcmp(x.label, 'black start')
            u_end = x.u_after;
            k90 = find(t > te & d.u_avg(:, 1) >= 0.9*u_end, 1, 'first');
            if isempty(k90)
                x.t_rise = nan;
            else
                x.t_rise = t(k90) - te;
            end
            x.u_ovs = (max(d.u_avg(wn, 1))/u_end - 1)*100;
        else
            x.t_rise = nan;
            x.u_ovs = nan;
        end
        ev(j) = x; %#ok<AGROW>
    end
end

function m = local_mean(x)
    m = local_nz(mean(x(:)));
end

function v = local_nz(v)
%LOCAL_NZ  NaN for an empty result (window without samples), so that the text keeps its fields.
    if isempty(v)
        v = nan;
    end
end

% --------------------------------------------------------------------------------------------------------------
function [chk, pass, fin] = local_checks(d, param)
%LOCAL_CHECKS  Checks in the window at the end (see the header).
    tb = param.tb;
    t  = d.t;
    w  = t >= tb.t_end - 0.2;
    run = local_running(param, tb.t_end);
    c  = param.mod(1).ctrl;
    pref = zeros(1, 3);
    for k = 1:3
        pref(k) = param.mod(k).ctrl.droop_p_ref;
        if tb.sync_t(k) < tb.t_end
            pref(k) = pref(k) + tb.sync_after(2, k);
        end
    end
    fin.f = mean(d.f(w, :), 1);
    fin.P = mean(d.pf(w, :), 1);
    fin.Q = mean(d.qf(w, :), 1);
    fin.u = mean(d.u(w, :), 1);
    fin.dP = max(fin.P(run)) - min(fin.P(run));
    fin.dQ = max(fin.Q(run)) - min(fin.Q(run));
    island = tb.t_open < tb.t_end;
    report_only = any(strcmp(tb.name, {'T0_off', 'T4_L1', 'T4_cable', 'T4_gain'}));
    chk = {};
    if island
        txt = sprintf('P sharing: spread %.4f pu (%.1f %% of the mean)', fin.dP, 100*fin.dP/mean(fin.P(run)));
        chk(end + 1, :) = local_check(txt, fin.dP < 0.01, report_only);
        txt = sprintf('Q sharing: spread %.4f pu', fin.dQ);
        chk(end + 1, :) = local_check(txt, fin.dQ < 0.02, report_only);
    else
        err = max(abs(fin.P - pref));
        chk(end + 1, :) = local_check(sprintf('P_f = P* on the grid: max error %.4f pu', err), err < 0.01, false);
    end
    f_law = 50*(1 + c.droop_mp*(pref(run) - fin.P(run)));
    err = max(abs(fin.f(run) - f_law));
    chk(end + 1, :) = local_check(sprintf('f = 50(1 + mp(P* - P_f)): max error %.4f Hz', err), err < 0.02, ...
        strcmp(tb.name, 'T0_off'));
    pp = max(max(d.pf(w, run)) - min(d.pf(w, run)));
    chk(end + 1, :) = local_check(sprintf('damped: peak-to-peak of P_f %.4f pu', pp), pp < 0.02, false);
    a = t > c.droop_t_sync + 0.02;
    imax = max(max(d.is_avg(a, :)));
    chk(end + 1, :) = local_check(sprintf('|i_s| (1 ms average) below i_max + 0.05: max %.3f pu', imax), ...
        imax < c.droop_i_max + 0.05, false);
    pass = all(~strcmp(chk(:, 2), 'FAIL'));
end

function c = local_check(text, ok, report_only)
    if report_only
        c = {text, 'info'};
    else
        c = {text, local_tf(ok)};
    end
end

function s = local_tf(ok)
    if ok
        s = 'pass';
    else
        s = 'FAIL';
    end
end

% --------------------------------------------------------------------------------------------------------------
function txt = local_text(r, param)
%LOCAL_TEXT  Metrics and checks of one case as text.
    s = sprintf('case %s, %.2f s simulated in %.0f s\n', r.name, param.tb.t_end, r.wall);
    s = [s sprintf('  end: f %s Hz, P_f %s, Q_f %s, |u| %s pu\n', mat2str(r.fin.f, 5), mat2str(r.fin.P, 3), ...
        mat2str(r.fin.Q, 3), mat2str(r.fin.u, 3))];
    for j = 1:numel(r.ev)
        x = r.ev(j);
        s = [s sprintf('  %.3f s %s:\n', x.t, x.label)]; %#ok<AGROW>
        s = [s sprintf(['    f %.3f -> %.3f Hz (extreme %.3f), rocof %.2f Hz/s, |u| %.3f -> %.3f pu ' ...
            '(min %.3f, max %.3f)\n'], x.f_before, x.f_after, x.f_ext, x.rocof, x.u_before, x.u_after, ...
            x.u_min, x.u_max)]; %#ok<AGROW>
        s = [s sprintf('    P_f %s -> %s, Q_f %s -> %s pu\n', mat2str(x.P_before, 3), mat2str(x.P_after, 3), ...
            mat2str(x.Q_before, 3), mat2str(x.Q_after, 3))]; %#ok<AGROW>
        s = [s sprintf('    i_peak %.3f pu (1 ms average %.3f), P_f settled in %.3f s, overshoot %.1f %%', ...
            x.i_peak, x.i_peak_avg, x.t_set, x.ovs)]; %#ok<AGROW>
        if ~isnan(x.t_rise)
            s = [s sprintf(', |u| rise to 90 %% in %.3f s, overshoot %.1f %%', x.t_rise, x.u_ovs)]; %#ok<AGROW>
        end
        s = [s newline]; %#ok<AGROW>
    end
    for j = 1:size(r.chk, 1)
        s = [s sprintf('  %-4s %s\n', r.chk{j, 2}, r.chk{j, 1})]; %#ok<AGROW>
    end
    txt = s;
end

% --------------------------------------------------------------------------------------------------------------
function local_plot(d, param, ev, file)
%LOCAL_PLOT  Frequency, powers, voltage and current of one case, saved as PNG.
    fig = figure('Visible', 'off', 'Color', 'w', 'Position', [50 50 900 1050]);
    tl = tiledlayout(fig, 5, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
    title(tl, sprintf('pgfm\\_droop, case %s', strrep(param.tb.name, '_', '\_')));
    n1 = max(1, round(1e-3/d.dt));
    y = {d.f, d.pf, d.qf, d.u_avg, d.is_avg};
    lab = {'f [Hz]', 'P_f [pu]', 'Q_f [pu]', '|u| [pu], 1 ms', '|i_s| [pu], 1 ms'};
    for j = 1:5
        ax = nexttile(tl);
        plot(ax, d.t(1:n1:end), y{j}(1:n1:end, :), 'LineWidth', 1);
        grid(ax, 'on');
        ylabel(ax, lab{j});
        xlim(ax, [0 param.tb.t_end]);
        for e = 1:numel(ev)
            xline(ax, ev(e).t, ':', 'Color', [0.4 0.4 0.4]);
        end
        if j == 5
            ym = max(max(d.is_avg(d.t > 0.02, :)));
            if isfinite(ym) && ym > 0
                ylim(ax, [0 1.1*ym]);
            end
        end
        if j == 1
            legend(ax, {'module 1', 'module 2', 'module 3'}, 'Location', 'best');
            yl = [min(min(d.f(d.t > 0.15, :))) max(max(d.f(d.t > 0.15, :)))];
            if all(isfinite(yl)) && diff(yl) > 0
                ylim(ax, yl + [-0.1 0.1]*diff(yl));
            end
        end
    end
    xlabel(ax, 't [s]');
    exportgraphics(fig, file, 'Resolution', 150);
    close(fig);
end

function local_save(d, r, file)
%LOCAL_SAVE  Signals with 1 ms resolution and the metrics of one case (MAT v7).
    n1 = max(1, round(1e-3/d.dt));
    k = 1:n1:numel(d.t);
    s.t = d.t(k);
    s.f = d.f(k, :); s.p = d.p(k, :); s.q = d.q(k, :); s.pf = d.pf(k, :); s.qf = d.qf(k, :);
    s.u = d.u_avg(k, :); s.is = d.is_avg(k, :); s.E = d.E(k, :); s.dx = d.dx(k, :); s.state = d.state(k, :);
    s.name = r.name; s.wall = r.wall; s.fin = r.fin; s.ev = r.ev; s.chk = r.chk; %#ok<STRNU>
    save(file, '-struct', 's', '-v7');
end
