% ==================================
% File: init_TAPVR_final_params.m
% ==================================
function params = init_TAPVR_final_params(profile)
% init_TAPVR_final_params.m
% Returns parameter values for the final TAPVR/PAPVR model.
%
% profile options:
%   'neonate'    = default final-presentation model; tuned to an infant-sized
%                  circulation with higher HR, smaller volumes, and lower CO.
%   'classModel' = closer to the original homework-scale model, but with
%                  tuned aortic resistance to avoid unrealistically high LV pressure.
%
% Units:
%   time       : min
%   pressure   : mmHg
%   volume     : L
%   flow       : L/min
%   compliance : L/mmHg
%   resistance : mmHg/(L/min)

if nargin < 1
    profile = 'neonate';
end

switch lower(profile)
    case 'neonate'
        params.profileName = 'neonate / infant-scaled model';
        params.body_mass_kg = 3.5;

        % Heart rate = 140 bpm. Since T is in minutes, HR = 1/T.
        params.T    = 1/140;
        params.TS   = 0.40*params.T;
        params.tauS = 0.20*params.T;
        params.tauD = 0.60*params.T;

        % Neonatal-sized LV compliance and unstressed volume.
        params.CLVS = 0.000004;
        params.CLVD = 0.001800;
        params.VLV0 = 0.004;

        % Systemic arterial compartment.
        params.Csa  = 0.000350;
        params.Vsa0 = 0.080;
        params.Rs   = 100.0;

        % Valve resistances.
        % RAo was the major pressure-magnitude tuning parameter. The preliminary
        % version inherited a high aortic resistance that produced unrealistic
        % LV pressures. This lower value gives more reasonable LV pressures.
        params.RAo  = 1.0;
        params.RMi  = 0.05;

        % Atrial and pulmonary venous compartments.
        params.Cra  = 0.0040;
        params.Vra0 = 0.0040;
        params.Cla  = 0.0035;
        params.Vla0 = 0.0040;
        params.Cpv  = 0.0120;
        params.Vpv0 = 0.0350;

        % Pulmonary and venous pathway resistances.
        params.Rpul     = 8.0;
        params.Rpv_norm = 8.0;
        params.Rpv_anom = 8.0;
        params.Rpv_obstructed = 25.0;

        % ASD-level shunt resistance.
        % Higher RASD = smaller/more restrictive atrial communication.
        params.RASD = 4.0;

        % Sweeps for final analysis.
        params.obstruction_sweep_values = [8 12 16 20 25 30];
        params.ASD_sweep_values = [2 4 6 8 12];

        % Initial pressures.
        params.PRA0 = 4.5;
        params.PLA0 = 5.0;
        params.PLV0 = 5.0;
        params.Psa0 = 65.0;
        params.Ppv0 = 8.0;

    case 'classmodel'
        params.profileName = 'class/homework-scale model with tuned RAo';
        params.body_mass_kg = 70;

        % Original homework timing, HR = 80 bpm.
        params.T    = 0.0125;
        params.TS   = 0.0050;
        params.tauS = 0.0025;
        params.tauD = 0.0075;

        params.CLVS = 0.00003;
        params.CLVD = 0.0146;
        params.VLV0 = 0.027;

        params.Csa  = 0.0020;
        params.Vsa0 = 0.825;
        params.Rs   = 17.86;

        % Tuned from the preliminary 50.0 value to reduce unrealistic LV pressure.
        params.RAo  = 1.0;
        params.RMi  = 0.01;

        params.Cra  = 0.030;
        params.Vra0 = 0.020;
        params.Cla  = 0.025;
        params.Vla0 = 0.020;
        params.Cpv  = 0.080;
        params.Vpv0 = 0.350;

        params.Rpul     = 1.2;
        params.Rpv_norm = 1.0;
        params.Rpv_anom = 1.0;
        params.Rpv_obstructed = 6.0;
        params.RASD = 0.50;

        params.obstruction_sweep_values = [1 2 4 6 8];
        params.ASD_sweep_values = [0.25 0.50 1.00 2.00];

        params.PRA0 = 5.0;
        params.PLA0 = 6.0;
        params.PLV0 = 6.0;
        params.Psa0 = 85.0;
        params.Ppv0 = 8.0;

    otherwise
        error('Unknown profile. Use ''neonate'' or ''classModel''.');
end

%% Shared oxygen assumptions
params.S_pv_target = 0.98;  % oxygenated pulmonary venous saturation
params.S_sys_ven   = 0.65;  % systemic venous saturation after tissue extraction

%% Initial oxygen saturations
params.Sra0 = 0.72;
params.Sla0 = 0.95;
params.Slv0 = 0.95;
params.Ssa0 = 0.95;

%% Simulation settings
params.dt      = 0.01*params.T;
params.n_beats = 40;
params.klokmax = round(params.n_beats*params.T/params.dt);
end
