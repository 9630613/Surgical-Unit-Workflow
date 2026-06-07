clc
clear all
close all

l_a=1; l_t=2;
simtime=1000;


% Initialize variables
best_m1 = 0;
best_m2 = 0;
best_m3 = 0;
min_cost = inf;
avg_flow_time = inf;

% % relaxed solution
for m = 10:-1:1
    % Set parameters for the Simulink model
    m1 = m;  m2 = m;  m3 = m; 
      
    % Open and run the Simulink model
    open_system('emergency_scenario.slx');
    sim_out_a = sim('emergency_scenario.slx');

    % Load time series data from workspace
    time_arrive = sim_out_a.p_arrive.Time;
    time_depart = sim_out_a.p_depart.Time;
    data_p_arrive = sim_out_a.p_arrive.Data;
    data_p_depart = sim_out_a.p_depart.Data;

    % Initialize array for flow times
    flow_times = [];

    % Calculate flow times for each entity
    for i = 1:length(data_p_arrive)
        arrival_time = time_arrive(i);
        entity_p = data_p_arrive(i);

        % Find the matching departure for the current entity
        departure_idx = find(data_p_depart == entity_p, 1, 'first');

        if ~isempty(departure_idx)
            departure_time = time_depart(departure_idx);
            flow_time = departure_time - arrival_time;
            flow_times = [flow_times; flow_time];
        end
    end

    % Calculate total average flow time
    avg_S = mean(flow_times);
    fprintf('For m = %d, Average Flow Time: %.2f\n', m, avg_S);

    % Check if average flow time meets the threshold
    if avg_S >= 20
        fprintf('critical m found: %d, Average Flow Time: %.2f\n', m, avg_S);
        break; % Exit the loop once the optimal m is found
    end
end
                


% findging optimal greedy algorithm

% Cost parameters (in thousands of euros)
cost_m1 = 10;  % 10k euros per stage-1 room
cost_m2 = 50;  % 50k euros per stage-2 room
cost_m3 = 2;   % 2k euros per stage-3 room

% Maximum reasonable number of rooms to try for each stage
max_rooms = m+1;

% Try different combinations of rooms
for m1 = max_rooms:-1:1
    for m2 = max_rooms:-1:1
        for m3 = max_rooms:-1:1
            % Calculate total cost for this configuration
            total_cost = m1*cost_m1 + m2*cost_m2 + m3*cost_m3;

            % Skip if cost is already higher than current minimum
            if total_cost >= min_cost
                break;
            end

            % calling simulink 
            open_system('emergency_scenario.slx')
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
            avg_S = mean(flow_times);
            fprintf('Stage-1 rooms (m1): %d\n', m1);
            fprintf('Stage-1 rooms (m2): %d\n', m2);
            fprintf('Stage-1 rooms (m3): %d\n', m3);
            fprintf('avg: %d\n', avg_S);
            % Skip if flow time is higher than 20
            if avg_S >= 20
                fprintf('avg exceeded\n');
                break;
                
            end
            
            % Check if this configuration meets the requirement S ≤ 20
            if avg_S <= 20
                if total_cost < min_cost
                    min_cost = total_cost;
                    best_m1 = m1;
                    best_m2 = m2;
                    best_m3 = m3;
                    avg_flow_time = avg_S;
                end
            end
        end
        if (avg_S >= 20 & m3==max_rooms)
            fprintf('avg exceeded\n');
            break;
        end
    end
    if (avg_S >= 20 & m3==max_rooms & m2==max_rooms)
        fprintf('avg exceeded\n');
        break;
    end

end

% Display results
fprintf('\nOptimal configuration found:\n');
fprintf('Stage-1 rooms (m1): %d\n', best_m1);
fprintf('Stage-2 rooms (m2): %d\n', best_m2);
fprintf('Stage-3 rooms (m3): %d\n', best_m3);
fprintf('Total cost: %.2f k€\n', min_cost);
fprintf('Average flow time: %.2f hours\n', avg_flow_time);


