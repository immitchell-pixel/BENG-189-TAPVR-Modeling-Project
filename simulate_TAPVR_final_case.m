% ===================================
% File: simulate_TAPVR_final_case.m
% ===================================
function out = simulate_TAPVR_final_case(params,caseDef)
% simulate_TAPVR_final_case.m
% Runs one simulation case for the final TAPVR/PAPVR model.
%
% caseDef fields:
%   name      = case name
%   frac_anom = fraction of pulmonary venous return draining abnormally
%               0   = normal
%               0.5 = PAPVR-like
%               1   = TAPVR-like
%   Rpv_anom  = anomalous pulmonary venous pathway resistance
%   RASD      = ASD-level shunt resistance

%% Make LV compliance timing available to CV_now
% This keeps the same style as the original homework model.
global T TS tauS tauD;
T    = params.T;
TS   = params.TS;
tauS = params.tauS;
tauD = params.tauD;

n  = params.klokmax;
dt = params.dt;

%% Initial volumes from pressure-volume relationships
Vra = params.Cra*params.PRA0 + params.Vra0;
Vla = params.Cla*params.PLA0 + params.Vla0;
Vlv = params.CLVD*params.PLV0 + params.VLV0;
Vsa = params.Csa*params.Psa0 + params.Vsa0;
Vpv = params.Cpv*params.Ppv0 + params.Vpv0;

%% Initial oxygen content variables
% M = saturation * volume.
Mra = params.Sra0*Vra;
Mla = params.Sla0*Vla;
Mlv = params.Slv0*Vlv;
Msa = params.Ssa0*Vsa;

%% Storage
out.name      = caseDef.name;
out.frac_anom = caseDef.frac_anom;

out.t     = zeros(1,n);
out.PRA   = zeros(1,n);
out.PLA   = zeros(1,n);
out.PLV   = zeros(1,n);
out.Psa   = zeros(1,n);
out.Ppv   = zeros(1,n);

out.Sra   = zeros(1,n);
out.Sla   = zeros(1,n);
out.Slv   = zeros(1,n);
out.Ssa   = zeros(1,n);

out.Qsys  = zeros(1,n);
out.Qpul  = zeros(1,n);
out.QpvLA = zeros(1,n);
out.QpvRA = zeros(1,n);
out.QASD  = zeros(1,n);
out.QMi   = zeros(1,n);
out.QAo   = zeros(1,n);

out.VRA   = zeros(1,n);
out.VLA   = zeros(1,n);
out.VLV   = zeros(1,n);
out.VSA   = zeros(1,n);
out.VPV   = zeros(1,n);
out.CLV   = zeros(1,n);
out.O2deliveryInst = zeros(1,n);

%% Time loop
for k = 1:n
    t = (k-1)*dt;
    CLV = CV_now(t,params.CLVS,params.CLVD);

    %% Pressures
    PRA = max((Vra - params.Vra0)/params.Cra, 0);
    PLA = max((Vla - params.Vla0)/params.Cla, 0);
    PLV = max((Vlv - params.VLV0)/max(CLV,1e-8), 0);
    Psa = max((Vsa - params.Vsa0)/params.Csa, 0);
    Ppv = max((Vpv - params.Vpv0)/params.Cpv, 0);

    %% Saturations
    Sra = clamp01(Mra/max(Vra,1e-8));
    Sla = clamp01(Mla/max(Vla,1e-8));
    Slv = clamp01(Mlv/max(Vlv,1e-8));
    Ssa = clamp01(Msa/max(Vsa,1e-8));

    %% Flow equations
    Qsys  = max(Psa/params.Rs,0);
    Qpul  = max(PRA/params.Rpul,0);
    QpvRA = max(caseDef.frac_anom*(Ppv - PRA)/caseDef.Rpv_anom,0);
    QpvLA = max((1 - caseDef.frac_anom)*(Ppv - PLA)/params.Rpv_norm,0);

    % Positive QASD means RA -> LA. Negative means LA -> RA.
    QASD = (PRA - PLA)/caseDef.RASD;

    QMi = max((PLA - PLV)/params.RMi,0);
    QAo = max((PLV - Psa)/params.RAo,0);

    %% Volume balances
    dVra = Qsys + QpvRA - Qpul - QASD;
    dVla = QpvLA + QASD - QMi;
    dVlv = QMi - QAo;
    dVsa = QAo - Qsys;
    dVpv = Qpul - QpvRA - QpvLA;

    %% Oxygen-content balances
    % For QASD:
    %   max(QASD,0)  = RA -> LA
    %   max(-QASD,0) = LA -> RA
    dMra = Qsys*params.S_sys_ven ...
         + QpvRA*params.S_pv_target ...
         + max(-QASD,0)*Sla ...
         - Qpul*Sra ...
         - max(QASD,0)*Sra;

    dMla = QpvLA*params.S_pv_target ...
         + max(QASD,0)*Sra ...
         - QMi*Sla ...
         - max(-QASD,0)*Sla;

    dMlv = QMi*Sla - QAo*Slv;
    dMsa = QAo*Slv - Qsys*Ssa;

    %% Euler update
    Vra = max(Vra + dt*dVra, params.Vra0 + 1e-8);
    Vla = max(Vla + dt*dVla, params.Vla0 + 1e-8);
    Vlv = max(Vlv + dt*dVlv, params.VLV0 + 1e-8);
    Vsa = max(Vsa + dt*dVsa, params.Vsa0 + 1e-8);
    Vpv = max(Vpv + dt*dVpv, params.Vpv0 + 1e-8);

    Mra = max(Mra + dt*dMra, 1e-10);
    Mla = max(Mla + dt*dMla, 1e-10);
    Mlv = max(Mlv + dt*dMlv, 1e-10);
    Msa = max(Msa + dt*dMsa, 1e-10);

    %% Store outputs
    out.t(k)     = t;
    out.PRA(k)   = PRA;
    out.PLA(k)   = PLA;
    out.PLV(k)   = PLV;
    out.Psa(k)   = Psa;
    out.Ppv(k)   = Ppv;

    out.Sra(k)   = Sra;
    out.Sla(k)   = Sla;
    out.Slv(k)   = Slv;
    out.Ssa(k)   = Ssa;

    out.Qsys(k)  = Qsys;
    out.Qpul(k)  = Qpul;
    out.QpvLA(k) = QpvLA;
    out.QpvRA(k) = QpvRA;
    out.QASD(k)  = QASD;
    out.QMi(k)   = QMi;
    out.QAo(k)   = QAo;

    out.VRA(k)   = Vra;
    out.VLA(k)   = Vla;
    out.VLV(k)   = Vlv;
    out.VSA(k)   = Vsa;
    out.VPV(k)   = Vpv;
    out.CLV(k)   = CLV;
    out.O2deliveryInst(k) = QAo*Ssa;
end

%% Final-beat summary statistics
steps_per_beat = max(1,round(params.T/dt));
idx = max(1,n-steps_per_beat+1):n;

out.summary.meanPRA   = mean(out.PRA(idx));
out.summary.meanPLA   = mean(out.PLA(idx));
out.summary.meanPpv   = mean(out.Ppv(idx));
out.summary.meanPsa   = mean(out.Psa(idx));
out.summary.maxPsa    = max(out.Psa(idx));
out.summary.minPsa    = min(out.Psa(idx));
out.summary.maxPLV    = max(out.PLV(idx));

out.summary.meanQAo   = mean(out.QAo(idx));
out.summary.meanQASD  = mean(out.QASD(idx));
out.summary.meanSatRA = mean(out.Sra(idx));
out.summary.meanSatSA = mean(out.Ssa(idx));

out.summary.strokeVol = max(out.VLV(idx)) - min(out.VLV(idx));
out.summary.O2deliveryIndex = out.summary.meanQAo*out.summary.meanSatSA;
out.summary.O2deliveryPerKg = out.summary.O2deliveryIndex/params.body_mass_kg;
out.summary.cardiacIndex = out.summary.meanQAo/params.body_mass_kg;

end

%% Helper function
function y = clamp01(x)
y = min(max(x,0),1);
end
