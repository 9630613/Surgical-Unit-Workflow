clc
clear all
close all

m1=10;
m2=10;
m3=10;
simtime=1000;
l_a=1; l_t=2;


% calling simulink 
open_system('emergency_scenario.slx');
sim_out_a = sim('emergency_scenario.slx');

% Load time series data from workspace
time_arrive = sim_out_a.p_arrive.Time;
time_depart = sim_out_a.p_depart.Time;
data_p_arrive = sim_out_a.p_arrive.Data;
data_p_depart = sim_out_a.p_depart.Data;

% Initialize array for all flow times
flow_times = [];

% Calculate flow times for each entity
for i = 1:length(data_p_arrive)
    arrival_time = time_arrive(i);
    entity_p = data_p_arrive(i);
    
    % Find matching departure
    departure_idx = find(data_p_depart == entity_p, 1, 'first');
    
    if ~isempty(departure_idx)
        departure_time = time_depart(departure_idx);
        flow_time = departure_time - arrival_time;
        flow_times = [flow_times; flow_time];
    end
end

% Calculate total average flow time
mean_flow_time = mean(flow_times);

% Display results
fprintf('\nSummary Statistics:\n');
fprintf('Number of processed entities: %d\n', length(flow_times));
    fprintf('Average flow time: %.4f\n', mean_flow_time);

%calculating avg flow time for each type

% For arrivals    
time_id_arrive = sim_out_a.id_arrive.Time;
data_id_arrive = sim_out_a.id_arrive.Data;
time_p_arrive = sim_out_a.p_arrive.Time;
data_p_arrive = sim_out_a.p_arrive.Data;

% For departures
time_id_depart = sim_out_a.id_depart.Time;
data_id_depart = sim_out_a.id_depart.Data;
time_p_depart = sim_out_a.p_depart.Time;
data_p_depart = sim_out_a.p_depart.Data;

% Initialize arrays to store flow times for each ID type
flow_times_id1 = [];
flow_times_id2 = [];
m=length(data_p_arrive);
% Calculate flow times for each entity
for i = 1:m
    arrival_time = time_id_arrive(i);
    entity_id = data_id_arrive(i);
    entity_p = data_p_arrive(i);
    
    % Find matching departure
    departure_idx = find(data_p_depart == entity_p, 1, 'first');
    
    if ~isempty(departure_idx)
        departure_time = time_id_depart(departure_idx);
        flow_time = departure_time - arrival_time;
        
        % Store flow time based on ID type
        if entity_id == 1
            flow_times_id1 = [flow_times_id1; flow_time];
        else
            flow_times_id2 = [flow_times_id2; flow_time];
        end
    end
end

% Calculate mean flow times
mean_flow_time_id1 = mean(flow_times_id1);
mean_flow_time_id2 = mean(flow_times_id2);

% Calculate total average flow time using arrival rates
lambda_A = 1;  % Appendectomy arrival rate (1/hour)
lambda_T = 2;  % Tonsillectomy arrival rate (2/hour)


% Display results
fprintf('\nResults:\n');
fprintf('Mean Flow Time for ID Type appendectomy: %.4f time units\n', mean_flow_time_id1);
fprintf('Mean Flow Time for ID Type tonsillectomy: %.4f time units\n', mean_flow_time_id2);

% Display additional statistics
fprintf('\nNumber of entities processed:\n');
fprintf('ID Type appendectomy: %d entities\n', length(flow_times_id1));
fprintf('ID Type tonsillectomy: %d entities\n', length(flow_times_id2));

% Create visualizations
figure;
subplot(2,1,1);
histogram(flow_times_id1, 'FaceColor', 'b', 'EdgeColor', 'k');
title('Flow Time Distribution - ID Type appendectomy');
xlabel('Flow Time');
ylabel('patients');

subplot(2,1,2);
histogram(flow_times_id2, 'FaceColor', 'r', 'EdgeColor', 'k');
title('Flow Time Distribution - ID Type tonsillectomy');
xlabel('Flow Time');
ylabel('patients');