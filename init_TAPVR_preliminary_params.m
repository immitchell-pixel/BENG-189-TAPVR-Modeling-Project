function params = init_TAPVR_params()
% init_TAPVR_params.m
% Parameter set for a simplified closed-loop congenital circulation model.
% The model extends the LV homework structure by adding:
%   - right atrium (RA)
%   - left atrium (LA)
%   - pulmonary venous reservoir (PV)
%   - atrial septal communication (ASD)
%   - anomalous pulmonary venous return fraction (PAPVR/TAPVR)
%
% Units follow the homework convention as closely as possible:
%   time      : min
%   pressure  : mmHg
%   volume    : L
%   flow      : L/min
%   compliance: L/mmHg
%   resistance: mmHg/(L/min)

% Cardiac-cycle timing (copied from homework)
params.T    = 0.0125;
params.TS   = 0.0050;
params.tauS = 0.0025;
params.tauD = 0.0075;

% Time stepping
params.dt        = 0.01*params.T;
params.n_beats   = 30;
params.klokmax   = round(params.n_beats*params.T/params.dt);

% LV compliance (copied from the normal/homework scale, not severe AS tune)
params.CLVS = 0.00003;
params.CLVD = 0.0146;
params.VLV0 = 0.027;

% Arterial compartment (copied / lightly adapted from homework)
params.Csa  = 0.0020;
params.Vsa0 = 0.825;
params.Rs   = 17.86;
params.RAo  = 50.0;
params.RMi  = 0.01;

% Added atrial / pulmonary compartments
params.Cra  = 0.030;
params.Vra0 = 0.020;
params.Cla  = 0.025;
params.Vla0 = 0.020;
params.Cpv  = 0.080;
params.Vpv0 = 0.350;

% Added resistances
params.Rpul      = 1.2;   % RA -> lungs -> pulmonary venous reservoir
params.Rpv_norm  = 1.0;   % normal pulmonary venous return to LA
params.Rpv_anom  = 1.0;   % anomalous pulmonary venous return to RA
params.RASD      = 0.50;  % atrial communication (bidirectional)

% Oxygen settings (dimensionless saturation, 0 to 1)
params.S_pv_target = 0.98;  % pulmonary venous blood after oxygenation
params.S_sys_ven   = 0.65;  % systemic venous blood returning after tissue extraction

% Initial pressures
params.PRA0 = 5.0;
params.PLA0 = 6.0;
params.PLV0 = 6.0;
params.Psa0 = 85.0;
params.Ppv0 = 8.0;

% Initial chamber saturations
params.Sra0 = 0.72;
params.Sla0 = 0.95;
params.Slv0 = 0.95;
params.Ssa0 = 0.95;
end
