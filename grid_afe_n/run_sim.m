clc
clear;
ucc_factor = 1;
init_model;
sim(grid_afe_n);
save sim_results_icc20inom_3.mat;

clc
clear;
ucc_factor = 10/3;
init_model;
sim(grid_afe_n);
save sim_results_icc6inom_3.mat;

clc
clear;
ucc_factor = 5;
init_model;
sim(grid_afe_n);
save sim_results_icc4inom_3.mat;

clc
clear;
ucc_factor = 20/3;
init_model;
sim(grid_afe_n);
save sim_results_icc3inom_3.mat;

clc
clear;
ucc_factor = 10;
init_model;
sim(grid_afe_n);
save sim_results_icc2inom_3.mat;


