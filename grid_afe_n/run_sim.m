clc
clear;
ucc_case = 1;
init_model;
sim(grid_afe_n);
save sim_results_icc2inom_3.mat;

clc
clear;
ucc_case = 2;
init_model;
sim(grid_afe_n);
save sim_results_icc4inom_3.mat;

clc
clear;
ucc_case = 3;
init_model;
sim(grid_afe_n);
save sim_results_icc6inom_3.mat;

clc
clear;
ucc_case = 0;
init_model;
sim(grid_afe_n);
save sim_results_icc20inom_3.mat;