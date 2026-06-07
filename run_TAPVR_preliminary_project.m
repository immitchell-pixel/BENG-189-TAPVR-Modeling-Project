% run_TAPVR_project.m
% BENG 189 TAPVR/PAPVR project model.
%
% This script starts from the homework-style time-varying LV compliance model
% but expands it into a simplified closed-loop circulation with:
%   - RA, LA, LV, systemic arteries, pulmonary venous reservoir
%   - atrial septal communication (ASD-level shunt)
%   - PAPVR/TAPVR switch via fraction of anomalous pulmonary venous return
%   - optional obstruction of the anomalous pulmonary venous pathway
%
% Suggested use for the presentation:
%   1) Run the script.
%   2) Show the comparison plots.
%   3) Use the printed summary table as your preliminary results.

clear; close all; clc;

params = init_TAPVR_params();

cases = [ ...
    struct('name','Normal circulation','frac_anom',0.00,'Rpv_anom',params.Rpv_anom,'RASD',1e6), ...
    struct('name','PAPVR (50% anomalous return)','frac_anom',0.50,'Rpv_anom',params.Rpv_anom,'RASD',params.RASD), ...
    struct('name','TAPVR (unobstructed)','frac_anom',1.00,'Rpv_anom',params.Rpv_anom,'RASD',params.RASD), ...
    struct('name','TAPVR (obstructed)','frac_anom',1.00,'Rpv_anom',6.0,'RASD',params.RASD) ...
    ];

allOut = cell(1,numel(cases));
for i = 1:numel(cases)
    allOut{i} = simulate_TAPVR_case(params,cases(i));
end

%% Print summary table
fprintf('\nBENG 189 TAPVR/PAPVR PROJECT SUMMARY (final beat averages)\n');
fprintf('--------------------------------------------------------------------------\n');
fprintf('%-28s %8s %8s %8s %8s %8s %8s\n', ...
    'Case','PRA','PLA','Ppv','Psa','Sat_sys','QAo');
fprintf('--------------------------------------------------------------------------\n');
for i = 1:numel(allOut)
    s = allOut{i}.summary;
    fprintf('%-28s %8.2f %8.2f %8.2f %8.2f %8.3f %8.2f\n', ...
        allOut{i}.name, s.meanPRA, s.meanPLA, s.meanPpv, s.meanPsa, s.meanSatSA, s.meanQAo);
end
fprintf('--------------------------------------------------------------------------\n\n');

%% Figure 1: systemic arterial saturation
figure(1);
hold on;
for i = 1:numel(allOut)
    plot(allOut{i}.t, allOut{i}.Ssa, 'LineWidth', 1.5);
end
xlabel('Time (min)');
ylabel('Systemic arterial O_2 saturation');
title('Effect of PAPVR/TAPVR on systemic oxygen delivery');
legend({allOut{1}.name,allOut{2}.name,allOut{3}.name,allOut{4}.name}, 'Location','best');
grid on;

%% Figure 2: pressures
figure(2);
subplot(3,1,1); hold on;
for i = 1:numel(allOut)
    plot(allOut{i}.t, allOut{i}.PRA, 'LineWidth', 1.5);
end
xlabel('Time (min)'); ylabel('PRA (mmHg)'); title('Right atrial pressure'); grid on;
legend({allOut{1}.name,allOut{2}.name,allOut{3}.name,allOut{4}.name}, 'Location','best');

subplot(3,1,2); hold on;
for i = 1:numel(allOut)
    plot(allOut{i}.t, allOut{i}.Ppv, 'LineWidth', 1.5);
end
xlabel('Time (min)'); ylabel('Ppv (mmHg)'); title('Pulmonary venous pressure'); grid on;

subplot(3,1,3); hold on;
for i = 1:numel(allOut)
    plot(allOut{i}.t, allOut{i}.Psa, 'LineWidth', 1.5);
end
xlabel('Time (min)'); ylabel('Psa (mmHg)'); title('Systemic arterial pressure'); grid on;

%% Figure 3: key flows for the TAPVR cases only
figure(3);
titles = {'TAPVR (unobstructed)','TAPVR (obstructed)'};
case_ids = [3 4];
for k = 1:2
    i = case_ids(k);
    subplot(2,1,k); hold on;
    plot(allOut{i}.t, allOut{i}.QAo,  'LineWidth', 1.5);
    plot(allOut{i}.t, allOut{i}.QASD, 'LineWidth', 1.5);
    plot(allOut{i}.t, allOut{i}.QpvRA,'LineWidth', 1.5);
    xlabel('Time (min)'); ylabel('Flow (L/min)');
    title(['Key flows: ' titles{k}]);
    legend('Aortic outflow QAo','ASD shunt QASD','Anomalous PV return QpvRA','Location','best');
    grid on;
end

%% Figure 4: LV pressure-volume loop (obstructed vs unobstructed TAPVR)
figure(4);
plot(allOut{3}.VLV, allOut{3}.PLV, 'LineWidth', 1.8); hold on;
plot(allOut{4}.VLV, allOut{4}.PLV, 'LineWidth', 1.8);
xlabel('LV volume (L)');
ylabel('LV pressure (mmHg)');
title('LV pressure-volume loop under TAPVR');
legend(allOut{3}.name, allOut{4}.name, 'Location','best');
grid on;

%% Save all results for later use in the next presentation
save('tapvr_project_results.mat','params','cases','allOut');

disp('Saved results to tapvr_project_results.mat');
