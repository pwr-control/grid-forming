% =========================================================
%  video_plot_comparison.m
%  Finestra sinistra:  subplot 1 → tensioni trifase (Icc = 20 Inom)
%                      subplot 2 → correnti trifase (Icc = 20 Inom)
%  Finestra destra:  subplot 1 → tensioni trifase (Icc = 2 Inom)
%                      subplot 2 → correnti trifase (Icc = 2 Inom)
%  Author: 
% =========================================================
clear; close all; clc

load ..\sim_results_icc6inom_1.mat;
tc_eq = glb_time.tc*glb_time.decimation_tc;
tc = tc_eq;
t1 = 0.5;
t2 = 1.5;
N1 = floor(t1/tc);
N2 = floor(t2/tc);
N = N2 - N1 + 1;


ig_u_20 = ig_abc_sim(N1:N2,1);
ig_v_20 = ig_abc_sim(N1:N2,2);
ig_w_20 = ig_abc_sim(N1:N2,3);

vg_u_20 = ug_abc_sim(N1:N2,1);
vg_v_20 = ug_abc_sim(N1:N2,2);
vg_w_20 = ug_abc_sim(N1:N2,3);

load ..\sim_results_icc6inom_1.mat;

ig_u_2 = ig_abc_sim(N1:N2,1);
ig_v_2 = ig_abc_sim(N1:N2,2);
ig_w_2 = ig_abc_sim(N1:N2,3);

vg_u_2 = ug_abc_sim(N1:N2,1);
vg_v_2 = ug_abc_sim(N1:N2,2);
vg_w_2 = ug_abc_sim(N1:N2,3);

time = t_tc_sim(N1:N2);

% figure; 
% subplot 211
% plot(time, ig_u_20); 
% grid on
% subplot 212
% plot(time, ig_u_2); 
% grid on
% 
% return

%% Parametri
sim_duration   = t2-t1;
video_duration = 20.0;
fps            = 30;
output_file    = 'video_plot_comparison.mp4';

%% Colori
col_u  = [0.25  0.72  1.00];
col_v  = [1.00  0.55  0.10];
col_w  = [0.20  0.85  0.45];
col_P1p = [1.00  0.85  0.20];
col_P1n = [1.00  0.45  0.20];
col_Q1p = [0.75  0.30  1.00];
col_Q1n = [0.30  0.85  0.85];

%% Limiti assi (precalcolati)
lim = @(x) deal(min(x)*1.15, max(x)*1.15);
[yi_min, yi_max] = lim([ig_u_2; ig_v_2; ig_w_2]);
[yv_min, yv_max] = lim([vg_u_2; vg_v_2; vg_w_2]);

fix = @(a,b) deal(a-(a==b), b+(a==b));
[yi_min,   yi_max  ] = fix(yi_min,   yi_max  );
[yv_min,   yv_max  ] = fix(yv_min,   yv_max  );

n_frames = round(fps * video_duration);

%% Video writer
vw = VideoWriter(output_file, 'MPEG-4');
vw.FrameRate = fps;
vw.Quality   = 95;
open(vw);

%% ---- Figura SINISTRA: tensioni + correnti ----
W = 900;  H = 720;          % dimensioni di ciascuna finestra
fig_L = figure('Color','k', 'Position',[50,  100, W, H], ...
               'MenuBar','none','ToolBar','none');

ax_v = subplot(2,1,1,'Parent',fig_L);
setup_ax(ax_v);
hl_vu_20 = plot(ax_v,NaN,NaN,'Color',col_u,'LineWidth',1.2);
hl_vv_20 = plot(ax_v,NaN,NaN,'Color',col_v,'LineWidth',1.2);
hl_vw_20 = plot(ax_v,NaN,NaN,'Color',col_w,'LineWidth',1.2);
hc_v_20  = xline(ax_v,0,'r--','LineWidth',0.9,'Alpha',0.7);
legend(ax_v,{'v_{g,u}','v_{g,v}','v_{g,w}'},'TextColor','w', ...
       'Color','none','EdgeColor',[0.4 0.4 0.4],'Location','northeast','FontSize',8);
title(ax_v,'Grid Voltages (Icc = 20 Inom)','Color','w','FontSize',11,'FontWeight','normal');
ylabel(ax_v,'v_g  [V]','Color','w','FontSize',10);
xlim(ax_v,[t1,t2]); ylim(ax_v,[yv_min,yv_max]);
set(ax_v,'XTickLabel',{});
ht_v_20 = make_text(ax_v,'w');

ax_i = subplot(2,1,2,'Parent',fig_L);
setup_ax(ax_i);
hl_iu_20 = plot(ax_i,NaN,NaN,'Color',col_u,'LineWidth',1.2);
hl_iv_20 = plot(ax_i,NaN,NaN,'Color',col_v,'LineWidth',1.2);
hl_iw_20 = plot(ax_i,NaN,NaN,'Color',col_w,'LineWidth',1.2);
hc_i_20  = xline(ax_i,0,'r--','LineWidth',0.9,'Alpha',0.7);
legend(ax_i,{'i_{g,u}','i_{g,v}','i_{g,w}'},'TextColor','w', ...
       'Color','none','EdgeColor',[0.4 0.4 0.4],'Location','northeast','FontSize',8);
title(ax_i,'Grid Currents (Icc = 20 Inom)','Color','w','FontSize',11,'FontWeight','normal');
ylabel(ax_i,'i_g  [A]','Color','w','FontSize',10);
xlabel(ax_i,'Time  [s]','Color','w','FontSize',10);
xlim(ax_i,[t1,t2]); ylim(ax_i,[yi_min,yi_max]);
ht_i_20 = make_text(ax_i,'w');

%% ---- Figura DESTRA: tensioni + correnti ----
W = 900;  H = 720;          % dimensioni di ciascuna finestra
fig_R = figure('Color','k', 'Position',[50,  100, W, H], ...
               'MenuBar','none','ToolBar','none');

ax_v = subplot(2,1,1,'Parent',fig_R);
setup_ax(ax_v);
hl_vu_2 = plot(ax_v,NaN,NaN,'Color',col_u,'LineWidth',1.2);
hl_vv_2 = plot(ax_v,NaN,NaN,'Color',col_v,'LineWidth',1.2);
hl_vw_2 = plot(ax_v,NaN,NaN,'Color',col_w,'LineWidth',1.2);
hc_v_2  = xline(ax_v,0,'r--','LineWidth',0.9,'Alpha',0.7);
legend(ax_v,{'v_{g,u}','v_{g,v}','v_{g,w}'},'TextColor','w', ...
       'Color','none','EdgeColor',[0.4 0.4 0.4],'Location','northeast','FontSize',8);
title(ax_v,'Grid Voltages (Icc = 2 Inom)','Color','w','FontSize',11,'FontWeight','normal');
ylabel(ax_v,'v_g  [V]','Color','w','FontSize',10);
xlim(ax_v,[t1,t2]); ylim(ax_v,[yv_min,yv_max]);
set(ax_v,'XTickLabel',{});
ht_v_2 = make_text(ax_v,'w');

ax_i = subplot(2,1,2,'Parent',fig_R);
setup_ax(ax_i);
hl_iu_2 = plot(ax_i,NaN,NaN,'Color',col_u,'LineWidth',1.2);
hl_iv_2 = plot(ax_i,NaN,NaN,'Color',col_v,'LineWidth',1.2);
hl_iw_2 = plot(ax_i,NaN,NaN,'Color',col_w,'LineWidth',1.2);
hc_i_2  = xline(ax_i,0,'r--','LineWidth',0.9,'Alpha',0.7);
legend(ax_i,{'i_{g,u}','i_{g,v}','i_{g,w}'},'TextColor','w', ...
       'Color','none','EdgeColor',[0.4 0.4 0.4],'Location','northeast','FontSize',8);
title(ax_i,'Grid Currents (Icc = 2 Inom)','Color','w','FontSize',11,'FontWeight','normal');
ylabel(ax_i,'i_g  [A]','Color','w','FontSize',10);
xlabel(ax_i,'Time  [s]','Color','w','FontSize',10);
xlim(ax_i,[t1,t2]); ylim(ax_i,[yi_min,yi_max]);
ht_i_2 = make_text(ax_i,'w');

%% ---- Render ----
fprintf('Rendering %d frames...  ', n_frames);
t_prog = tic;

for k = 1:n_frames
    t_now = (k/n_frames) * sim_duration;
    idx   = min(round(t_now/tc)+1, N);
    t_str = sprintf('t = %.4f s', time(idx));

    % --- aggiorna figura sinistra ---
    set(hl_vu_20,'XData',time(1:idx),'YData',vg_u_20(1:idx));
    set(hl_vv_20,'XData',time(1:idx),'YData',vg_v_20(1:idx));
    set(hl_vw_20,'XData',time(1:idx),'YData',vg_w_20(1:idx));
    set(hc_v_20, 'Value',time(idx)); set(ht_v_20,'String',t_str);

    set(hl_iu_20,'XData',time(1:idx),'YData',ig_u_20(1:idx));
    set(hl_iv_20,'XData',time(1:idx),'YData',ig_v_20(1:idx));
    set(hl_iw_20,'XData',time(1:idx),'YData',ig_w_20(1:idx));
    set(hc_i_20, 'Value',time(idx)); set(ht_i_20,'String',t_str);

    % --- aggiorna figura destra ---
    set(hl_vu_2,'XData',time(1:idx),'YData',vg_u_2(1:idx));
    set(hl_vv_2,'XData',time(1:idx),'YData',vg_v_2(1:idx));
    set(hl_vw_2,'XData',time(1:idx),'YData',vg_w_2(1:idx));
    set(hc_v_2, 'Value',time(idx)); set(ht_v_2,'String',t_str);

    set(hl_iu_2,'XData',time(1:idx),'YData',ig_u_2(1:idx));
    set(hl_iv_2,'XData',time(1:idx),'YData',ig_v_2(1:idx));
    set(hl_iw_2,'XData',time(1:idx),'YData',ig_w_2(1:idx));
    set(hc_i_2, 'Value',time(idx)); set(ht_i_2,'String',t_str);

    % --- cattura e affianca i due frame ---
    fr_L = getframe(fig_L);
    fr_R = getframe(fig_R);

    % Ridimensiona alla stessa altezza se necessario
    hL = size(fr_L.cdata,1);
    hR = size(fr_R.cdata,1);
    if hL ~= hR
        fr_R.cdata = imresize(fr_R.cdata, [hL, size(fr_R.cdata,2)]);
    end

    combined = [fr_L.cdata, fr_R.cdata];   % affianca orizzontalmente
    writeVideo(vw, combined);

    if mod(k, round(n_frames/20)) == 0
        fprintf('%.0f%%  ', 100*k/n_frames);
    end
end

fprintf('\nDone in %.1f s\n', toc(t_prog));
close(vw);
close(fig_L); close(fig_R);
fprintf('Video salvato: %s\n', output_file);

%% ---- Funzioni locali ----
function setup_ax(ax)
    set(ax, 'Color','k','XColor','w','YColor','w', ...
            'GridColor','w','GridAlpha',0.15, ...
            'XGrid','on','YGrid','on','FontSize',9);
    hold(ax,'on');
end

function h = make_text(ax, col)
    h = text(ax, 0.02, 0.93, '', ...
             'Units','normalized','Color',col, ...
             'FontSize',9,'FontName','Consolas', ...
             'VerticalAlignment','top');
end