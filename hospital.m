clc
clear all
close all

m1= 1; m2=1; m3=1;

time=70;
% uncomment to open optimised or random arrival

%without optimisation
% open_system('hospital_scenario.slx')
% sim_out_a = sim('hospital_scenario.slx');
%with optimisation
open_system('hospital_scenario_optimisation.slx')
sim_out_a = sim('hospital_scenario_optimisation.slx');

%calculating AVG flow time
% Load time series data from workspace
time_depart = sim_out_a.p_depart.Time;
data_p_depart = sim_out_a.p_depart.Data;

% Initialize array for all flow times
flow_times = [];

% Calculate flow times for entities
for i = 1:length(data_p_depart)
    flow_time = time_depart(i);
    flow_times = [flow_times; flow_time];

end

% Calculate total average flow time
mean_flow_time = mean(flow_times);

% Display results
fprintf('\nSummary Statistics:\n');
fprintf('Number of processed entities: %d\n', length(flow_times));
    fprintf('Average flow time: %.4f\n', mean_flow_time);

% Create visualizations
figure;
histogram(flow_times, 'FaceColor', 'r', 'EdgeColor', 'k');
title('Flow Time Distribution');
xlabel('Flow Time');
ylabel('patients');