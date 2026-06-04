% ================================
% File: run_TAPVR_final_project.m
% ================================
% BENG 189 Final TAPVR/PAPVR model.
%
% Final-version improvements compared with preliminary code:
%   1) Neonatal/infant parameter set is now the default.
%   2) Aortic resistance and chamber compliances were retuned so pressure
%      magnitudes are more physiologically reasonable than the preliminary
%      proof-of-concept model.
%   3) Added oxygen delivery index:
%          O2_index = mean(QAo) * mean(systemic arterial O2 saturation)
%      This is better than saturation alone because total oxygen delivery
%      depends on BOTH oxygen content and systemic blood flow.
%   4) Added normalized oxygen delivery index relative to normal circulation.
%   5) Added parameter sweeps for obstruction severity and ASD restriction.
%   6) Added patient profile option so the model can be interpreted as a
%      neonatal model instead of a generic adult/class model.
%
% Run with:
%   run('run_TAPVR_final_project.m')

clear; close all; clc;

%% Choose patient/model profile
% Main final-presentation model should use 'neonate'.
% Other option: 'classModel' if you want a parameter set closer to the
% original homework/class-scale model.
profile = 'neonate';
params = init_TAPVR_final_params(profile);

fprintf('\n==============================================================\n');
fprintf('BENG 189 FINAL TAPVR MODEL\n');
fprintf('Patient profile: %s\n', params.profileName);
fprintf('Heart rate used: %.1f bpm\n', 1/params.T);
fprintf('Body mass used for scaling: %.2f kg\n', params.body_mass_kg);
fprintf('==============================================================\n');

%% ============================================================
% PART 1: Main case comparison
% =============================================================
% frac_anom values:
%   0.00 = normal pulmonary venous return
%   0.50 = PAPVR-like partial anomalous return
%   1.00 = TAPVR-like total anomalous return
%
% Rpv_anom:
%   higher value = more obstruction of the anomalous PV pathway
%
% RASD:
%   higher value = more restrictive ASD-level shunt

cases = [ ...
    struct('name','Normal circulation',              'frac_anom',0.00,'Rpv_anom',params.Rpv_anom,'RASD',1e6), ...
    struct('name','PAPVR (50% anomalous return)',    'frac_anom',0.50,'Rpv_anom',params.Rpv_anom,'RASD',params.RASD), ...
    struct('name','TAPVR (unobstructed)',            'frac_anom',1.00,'Rpv_anom',params.Rpv_anom,'RASD',params.RASD), ...
    struct('name','TAPVR (obstructed)',              'frac_anom',1.00,'Rpv_anom',params.Rpv_obstructed,'RASD',params.RASD) ...
    ];

allOut = cell(1,numel(cases));
for i = 1:numel(cases)
    allOut{i} = simulate_TAPVR_final_case(params,cases(i));
end

% Normalize oxygen delivery to normal circulation.
normalO2Index = allOut{1}.summary.O2deliveryIndex;
for i = 1:numel(allOut)
    allOut{i}.summary.O2percentNormal = 100*allOut{i}.summary.O2deliveryIndex/normalO2Index;
end

%% Print main summary table
fprintf('\nMAIN CASE COMPARISON: FINAL-BEAT AVERAGES\n');
fprintf('------------------------------------------------------------------------------------------------------------\n');
fprintf('%-34s %7s %7s %7s %7s %8s %8s %10s %10s %8s\n', ...
    'Case','PRA','PLA','Ppv','Psa','Sat_sys','QAo','O2_Index','O2_%Norm','SV_mL');
fprintf('------------------------------------------------------------------------------------------------------------\n');
for i = 1:numel(allOut)
    s = allOut{i}.summary;
    fprintf('%-34s %7.2f %7.2f %7.2f %7.2f %8.3f %8.3f %10.3f %10.1f %8.2f\n', ...
        allOut{i}.name, s.meanPRA, s.meanPLA, s.meanPpv, s.meanPsa, ...
        s.meanSatSA, s.meanQAo, s.O2deliveryIndex, s.O2percentNormal, 1000*s.strokeVol);
end
fprintf('------------------------------------------------------------------------------------------------------------\n');

%% Figure 1: Main comparison bar plots
caseLabels = {allOut{1}.name, allOut{2}.name, allOut{3}.name, allOut{4}.name};
x = 1:numel(allOut);

meanPpv = zeros(1,numel(allOut));
meanPsa = zeros(1,numel(allOut));
meanQAo = zeros(1,numel(allOut));
meanSat = zeros(1,numel(allOut));
meanO2p = zeros(1,numel(allOut));

for i = 1:numel(allOut)
    meanPpv(i) = allOut{i}.summary.meanPpv;
    meanPsa(i) = allOut{i}.summary.meanPsa;
    meanQAo(i) = allOut{i}.summary.meanQAo;
    meanSat(i) = allOut{i}.summary.meanSatSA;
    meanO2p(i) = allOut{i}.summary.O2percentNormal;
end

figure(1);
subplot(2,2,1);
bar(x, meanO2p);
set(gca,'XTick',x,'XTickLabel',caseLabels,'XTickLabelRotation',25);
ylabel('O_2 delivery (% of normal)');
title('Oxygen delivery index');
grid on;

subplot(2,2,2);
bar(x, meanPpv);
set(gca,'XTick',x,'XTickLabel',caseLabels,'XTickLabelRotation',25);
ylabel('Ppv (mmHg)');
title('Pulmonary venous pressure');
grid on;

subplot(2,2,3);
bar(x, meanPsa);
set(gca,'XTick',x,'XTickLabel',caseLabels,'XTickLabelRotation',25);
ylabel('Psa (mmHg)');
title('Systemic arterial pressure');
grid on;

subplot(2,2,4);
bar(x, meanQAo);
set(gca,'XTick',x,'XTickLabel',caseLabels,'XTickLabelRotation',25);
ylabel('QAo (L/min)');
title('Aortic output');
grid on;

%% Figure 2: Time-series outputs
figure(2);
subplot(3,1,1); hold on;
for i = 1:numel(allOut)
    plot(allOut{i}.t, allOut{i}.Ppv, 'LineWidth', 1.5);
end
xlabel('Time (min)'); ylabel('Ppv (mmHg)'); title('Pulmonary venous pressure over time'); grid on;
legend(caseLabels,'Location','best');

subplot(3,1,2); hold on;
for i = 1:numel(allOut)
    plot(allOut{i}.t, allOut{i}.Psa, 'LineWidth', 1.5);
end
xlabel('Time (min)'); ylabel('Psa (mmHg)'); title('Systemic arterial pressure over time'); grid on;

subplot(3,1,3); hold on;
for i = 1:numel(allOut)
    plot(allOut{i}.t, allOut{i}.O2deliveryInst, 'LineWidth', 1.5);
end
xlabel('Time (min)'); ylabel('QAo \times S_{sys}'); title('Instantaneous oxygen delivery index'); grid on;

%% ============================================================
% PART 2: Obstruction severity sweep
% =============================================================
obstruction_values = params.obstruction_sweep_values;
sweepOut = cell(1,length(obstruction_values));

for i = 1:length(obstruction_values)
    sweepCase = struct( ...
        'name', ['TAPVR Rpv\_anom = ' num2str(obstruction_values(i))], ...
        'frac_anom', 1.00, ...
        'Rpv_anom', obstruction_values(i), ...
        'RASD', params.RASD);
    sweepOut{i} = simulate_TAPVR_final_case(params,sweepCase);
    sweepOut{i}.summary.O2percentNormal = 100*sweepOut{i}.summary.O2deliveryIndex/normalO2Index;
end

fprintf('\nTAPVR OBSTRUCTION SEVERITY SWEEP\n');
fprintf('--------------------------------------------------------------------------\n');
fprintf('%12s %10s %10s %10s %10s %10s\n', ...
    'Rpv_anom','Ppv','Psa','Sat_sys','QAo','O2_%Norm');
fprintf('--------------------------------------------------------------------------\n');
for i = 1:length(sweepOut)
    s = sweepOut{i}.summary;
    fprintf('%12.2f %10.2f %10.2f %10.3f %10.3f %10.1f\n', ...
        obstruction_values(i), s.meanPpv, s.meanPsa, s.meanSatSA, s.meanQAo, s.O2percentNormal);
end
fprintf('--------------------------------------------------------------------------\n');

meanPpv_sweep = zeros(1,length(sweepOut));
meanPsa_sweep = zeros(1,length(sweepOut));
meanQAo_sweep = zeros(1,length(sweepOut));
meanO2_sweep  = zeros(1,length(sweepOut));

for i = 1:length(sweepOut)
    meanPpv_sweep(i) = sweepOut{i}.summary.meanPpv;
    meanPsa_sweep(i) = sweepOut{i}.summary.meanPsa;
    meanQAo_sweep(i) = sweepOut{i}.summary.meanQAo;
    meanO2_sweep(i)  = sweepOut{i}.summary.O2percentNormal;
end

figure(3);
subplot(2,2,1);
plot(obstruction_values, meanPpv_sweep, '-o', 'LineWidth', 1.5);
xlabel('Rpv\_anom'); ylabel('Ppv (mmHg)'); title('Obstruction raises PV pressure'); grid on;

subplot(2,2,2);
plot(obstruction_values, meanPsa_sweep, '-o', 'LineWidth', 1.5);
xlabel('Rpv\_anom'); ylabel('Psa (mmHg)'); title('Obstruction lowers systemic pressure'); grid on;

subplot(2,2,3);
plot(obstruction_values, meanQAo_sweep, '-o', 'LineWidth', 1.5);
xlabel('Rpv\_anom'); ylabel('QAo (L/min)'); title('Obstruction lowers aortic output'); grid on;

subplot(2,2,4);
plot(obstruction_values, meanO2_sweep, '-o', 'LineWidth', 1.5);
xlabel('Rpv\_anom'); ylabel('O_2 delivery (% normal)'); title('Obstruction lowers O_2 delivery'); grid on;

%% ============================================================
% PART 3: ASD restriction sweep
% =============================================================
ASD_values = params.ASD_sweep_values;
asdOut = cell(1,length(ASD_values));

for i = 1:length(ASD_values)
    asdCase = struct( ...
        'name', ['TAPVR RASD = ' num2str(ASD_values(i))], ...
        'frac_anom', 1.00, ...
        'Rpv_anom', params.Rpv_anom, ...
        'RASD', ASD_values(i));
    asdOut{i} = simulate_TAPVR_final_case(params,asdCase);
    asdOut{i}.summary.O2percentNormal = 100*asdOut{i}.summary.O2deliveryIndex/normalO2Index;
end

fprintf('\nTAPVR ASD RESTRICTION SWEEP\n');
fprintf('--------------------------------------------------------------------------\n');
fprintf('%12s %10s %10s %10s %10s %10s\n', ...
    'RASD','QASD','Psa','Sat_sys','QAo','O2_%Norm');
fprintf('--------------------------------------------------------------------------\n');
for i = 1:length(asdOut)
    s = asdOut{i}.summary;
    fprintf('%12.2f %10.3f %10.2f %10.3f %10.3f %10.1f\n', ...
        ASD_values(i), s.meanQASD, s.meanPsa, s.meanSatSA, s.meanQAo, s.O2percentNormal);
end
fprintf('--------------------------------------------------------------------------\n');

meanQASD_asd = zeros(1,length(asdOut));
meanPsa_asd  = zeros(1,length(asdOut));
meanQAo_asd  = zeros(1,length(asdOut));
meanO2_asd   = zeros(1,length(asdOut));

for i = 1:length(asdOut)
    meanQASD_asd(i) = asdOut{i}.summary.meanQASD;
    meanPsa_asd(i)  = asdOut{i}.summary.meanPsa;
    meanQAo_asd(i)  = asdOut{i}.summary.meanQAo;
    meanO2_asd(i)   = asdOut{i}.summary.O2percentNormal;
end

figure(4);
subplot(2,2,1);
plot(ASD_values, meanQASD_asd, '-o', 'LineWidth', 1.5);
xlabel('RASD'); ylabel('QASD (L/min)'); title('ASD restriction lowers shunting'); grid on;

subplot(2,2,2);
plot(ASD_values, meanPsa_asd, '-o', 'LineWidth', 1.5);
xlabel('RASD'); ylabel('Psa (mmHg)'); title('ASD restriction lowers pressure'); grid on;

subplot(2,2,3);
plot(ASD_values, meanQAo_asd, '-o', 'LineWidth', 1.5);
xlabel('RASD'); ylabel('QAo (L/min)'); title('ASD restriction lowers output'); grid on;

subplot(2,2,4);
plot(ASD_values, meanO2_asd, '-o', 'LineWidth', 1.5);
xlabel('RASD'); ylabel('O_2 delivery (% normal)'); title('ASD restriction lowers O_2 delivery'); grid on;

%% Save final results
save('tapvr_final_results.mat','params','cases','allOut', ...
    'obstruction_values','sweepOut','ASD_values','asdOut');

fprintf('\nSaved final results to tapvr_final_results.mat\n');
fprintf('Main final-presentation plots: Figure 1, Figure 3, and Figure 4.\n');
