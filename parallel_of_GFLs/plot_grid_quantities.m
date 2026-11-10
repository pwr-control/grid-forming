clear;
close all;
clc;

load sim_results_icc20inom.mat;
tc_eq = glb_time.tc*glb_time.decimation_tc;
tc = tc_eq;
N = glb_time.Nc;

ig_u = ig_abc_sim(:,1);
ig_v = ig_abc_sim(:,2);
ig_w = ig_abc_sim(:,3);

vg_u = ug_abc_sim(:,1);
vg_v = ug_abc_sim(:,2);
vg_w = ug_abc_sim(:,3);

P1p = P1p_global_sim;
Q1p = Q1p_global_sim;
P1n = P1n_global_sim;
Q1n = Q1n_global_sim;

time = t_tc_sim;

sim_duration = simlength;


tratto1 = 2;
tratto2 = 2;
tratto3 = 2;
colore1 = [0.25 0.25 0.25];
colore2 = [0.50 0.50 0.50];
colore3 = [0.75 0.75 0.75];
t1 = 0.5;
t2 = 1.5;
t1c = t1;
t2c = t2;

fontsize_title = 14;
fontsize_legend = 14;
fontsize_axis = 12;

figure;
subplot 211
plot(time,ig_u,'-','LineWidth',tratto2,'Color',colore1);
hold on
plot(time,ig_v,'-','LineWidth',tratto2,'Color',colore2);
hold on
plot(time,ig_w,'-','LineWidth',tratto2,'Color',colore3);
hold off
title('Grid Currents','Interpreter','latex','FontSize',fontsize_title);
legend('$i_{g}^{u}$','$i_{g}^{v}$','$i_{g}^{w}$','Location','best',...
    'Interpreter','latex','FontSize',fontsize_legend);
% xlabel('Time - [s]','Interpreter','latex','FontSize', fontsize_axis);
ylabel('Current - [A]','Interpreter','latex','FontSize', fontsize_axis);
set(gca,'ylim',[-3000 3000]);
set(gca,'xlim',[t1c t2c]);
grid on
chH = get(gca,'Children');
set(gca,'Children',[chH(1); chH(2); chH(3)]);
subplot 212
plot(time,vg_u,'-','LineWidth',tratto2,'Color',colore1);
hold on
plot(time,vg_v,'-','LineWidth',tratto2,'Color',colore2);
hold on
plot(time,vg_w,'-','LineWidth',tratto2,'Color',colore3);
hold off
title('Grid Voltages','Interpreter','latex','FontSize',fontsize_title);
legend('$u_{g}^{u}$','$u_{g}^{v}$','$u_{g}^{w}$','Location','best',...
    'Interpreter','latex','FontSize',fontsize_legend);
xlabel('Time - [s]','Interpreter','latex','FontSize', fontsize_axis);
ylabel('Voltage - [V]','Interpreter','latex','FontSize', fontsize_axis);
set(gca,'ylim',[-750 750]);
set(gca,'xlim',[t1c t2c]);
grid on
chH = get(gca,'Children');
set(gca,'Children',[chH(1); chH(2); chH(3)]);
grid on
h=gcf;
set(h,'PaperOrientation','landscape');
set(h,'PaperUnits','normalized');
set(h,'PaperPosition', [0 0 1 1]);
print('grid_voltages_currents','-depsc');

figure;
subplot 211
plot(time,P1p.*1e-3,'-','LineWidth',tratto2,'Color',colore1);
hold on
plot(time,P1n.*1e-3,'-','LineWidth',tratto2,'Color',colore2);
hold off
title('Grid Active Power - positive and negative sequence',...
    'Interpreter','latex','FontSize',fontsize_title);
legend('$P_1^p$','$P_1^n$','Location','best',...
    'Interpreter','latex','FontSize',fontsize_legend);
% xlabel('Time - [s]','Interpreter','latex','FontSize', fontsize_axis);
ylabel('Active Power - [kW]','Interpreter','latex','FontSize', fontsize_axis);
set(gca,'ylim',[-1.5e3 1.5e3]);
set(gca,'xlim',[t1c t2c]);
grid on
% chH = get(gca,'Children');
% set(gca,'Children',[chH(2); chH(1)])
subplot 212
plot(time,Q1p.*1e-3,'-','LineWidth',tratto2,'Color',colore1);
hold on
plot(time,Q1n.*1e-3,'-','LineWidth',tratto2,'Color',colore2);
hold off
title('Grid Reactive Power - positive and negative sequence',...
    'Interpreter','latex','FontSize',fontsize_title);
legend('$Q_1^p$','$Q_1^n$','Location','best',...
    'Interpreter','latex','FontSize',fontsize_legend);
xlabel('Time - [s]','Interpreter','latex','FontSize', fontsize_axis);
ylabel('Reactive Power - [kVAr]','Interpreter','latex','FontSize', fontsize_axis);
set(gca,'xlim',[t1c t2c]);
set(gca,'ylim',[-1.5e3 1.5e3]);
grid on
h=gcf;
set(h,'PaperOrientation','landscape');
set(h,'PaperUnits','normalized');
set(h,'PaperPosition', [0 0 1 1]);
print('grid_power_sequences','-depsc');