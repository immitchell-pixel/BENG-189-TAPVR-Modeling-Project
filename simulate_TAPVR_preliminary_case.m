function out = simulate_TAPVR_case(params,caseDef)
% simulate_TAPVR_case.m
% Runs one case of the simplified congenital circulation model.
%
% caseDef fields:
%   .name             display name
%   .frac_anom        fraction of pulmonary venous return draining abnormally
%                     0 = normal, 0.5 = PAPVR-like, 1 = TAPVR-like
%   .Rpv_anom         anomalous pathway resistance
%   .RASD             atrial septal communication resistance

% Make timing globals available to CV_now (same pattern as homework)
global T TS tauS tauD;
T    = params.T;
TS   = params.TS;
tauS = params.tauS;
tauD = params.tauD;

n  = params.klokmax;
dt = params.dt;

% Initial volumes from pressure/compliance definitions
Vra = params.Cra*params.PRA0 + params.Vra0;
Vla = params.Cla*params.PLA0 + params.Vla0;
Vlv = params.CLVD*params.PLV0 + params.VLV0;
Vsa = params.Csa*params.Psa0 + params.Vsa0;
Vpv = params.Cpv*params.Ppv0 + params.Vpv0;

% Initial oxygen mass = saturation * volume
Mra = params.Sra0*Vra;
Mla = params.Sla0*Vla;
Mlv = params.Slv0*Vlv;
Msa = params.Ssa0*Vsa;

% Storage
out.name      = caseDef.name;
out.frac_anom = caseDef.frac_anom;
out.t         = zeros(1,n);
out.PRA       = zeros(1,n);
out.PLA       = zeros(1,n);
out.PLV       = zeros(1,n);
out.Psa       = zeros(1,n);
out.Ppv       = zeros(1,n);
out.Sra       = zeros(1,n);
out.Sla       = zeros(1,n);
out.Slv       = zeros(1,n);
out.Ssa       = zeros(1,n);
out.Qsys      = zeros(1,n);
out.Qpul      = zeros(1,n);
out.QpvLA     = zeros(1,n);
out.QpvRA     = zeros(1,n);
out.QASD      = zeros(1,n);
out.QMi       = zeros(1,n);
out.QAo       = zeros(1,n);
out.VLV       = zeros(1,n);
out.VRA       = zeros(1,n);
out.VLA       = zeros(1,n);
out.VPV       = zeros(1,n);
out.CLV       = zeros(1,n);

for k = 1:n
    t = (k-1)*dt;
    CLV = CV_now(t,params.CLVS,params.CLVD);

    % Pressures from current volumes
    PRA = max((Vra-params.Vra0)/params.Cra,0);
    PLA = max((Vla-params.Vla0)/params.Cla,0);
    PLV = max((Vlv-params.VLV0)/max(CLV,1e-8),0);
    Psa = max((Vsa-params.Vsa0)/params.Csa,0);
    Ppv = max((Vpv-params.Vpv0)/params.Cpv,0);

    % Current saturations from oxygen masses
    Sra = clamp01(Mra/max(Vra,1e-8));
    Sla = clamp01(Mla/max(Vla,1e-8));
    Slv = clamp01(Mlv/max(Vlv,1e-8));
    Ssa = clamp01(Msa/max(Vsa,1e-8));

    % Flows
    Qsys  = max(Psa/params.Rs,0);                    % systemic outflow returning venously
    Qpul  = max(PRA/params.Rpul,0);                  % RA -> lungs
    QpvRA = max(caseDef.frac_anom*(Ppv-PRA)/caseDef.Rpv_anom,0);
    QpvLA = max((1-caseDef.frac_anom)*(Ppv-PLA)/params.Rpv_norm,0);
    QASD  = (PRA-PLA)/caseDef.RASD;                  % signed: + means RA -> LA
    QMi   = max((PLA-PLV)/params.RMi,0);
    QAo   = max((PLV-Psa)/params.RAo,0);

    % Volume balances
    dVra = Qsys + QpvRA - Qpul - QASD;
    dVla = QpvLA + QASD - QMi;
    dVlv = QMi - QAo;
    dVsa = QAo - Qsys;
    dVpv = Qpul - QpvRA - QpvLA;

    % Oxygen balances
    % Qsys leaves arteries oxygenated but returns to RA partially desaturated
    dMra = Qsys*params.S_sys_ven + QpvRA*params.S_pv_target ...
         + max(-QASD,0)*Sla - (Qpul + max(QASD,0))*Sra;
    dMla = QpvLA*params.S_pv_target + max(QASD,0)*Sra ...
         - (QMi + max(-QASD,0))*Sla;
    dMlv = QMi*Sla - QAo*Slv;
    dMsa = QAo*Slv - Qsys*Ssa;

    % Update states with explicit Euler
    Vra = max(Vra + dt*dVra, params.Vra0 + 1e-6);
    Vla = max(Vla + dt*dVla, params.Vla0 + 1e-6);
    Vlv = max(Vlv + dt*dVlv, params.VLV0 + 1e-6);
    Vsa = max(Vsa + dt*dVsa, params.Vsa0 + 1e-6);
    Vpv = max(Vpv + dt*dVpv, params.Vpv0 + 1e-6);

    Mra = max(Mra + dt*dMra, 1e-9);
    Mla = max(Mla + dt*dMla, 1e-9);
    Mlv = max(Mlv + dt*dMlv, 1e-9);
    Msa = max(Msa + dt*dMsa, 1e-9);

    % Store outputs
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
    out.VLV(k)   = Vlv;
    out.VRA(k)   = Vra;
    out.VLA(k)   = Vla;
    out.VPV(k)   = Vpv;
    out.CLV(k)   = CLV;
end

% Final-beat summary statistics
steps_per_beat = max(1,round(params.T/dt));
idx = max(1,n-steps_per_beat+1):n;
out.summary.meanPRA   = mean(out.PRA(idx));
out.summary.meanPLA   = mean(out.PLA(idx));
out.summary.meanPpv   = mean(out.Ppv(idx));
out.summary.meanPsa   = mean(out.Psa(idx));
out.summary.meanQAo   = mean(out.QAo(idx));
out.summary.meanQASD  = mean(out.QASD(idx));
out.summary.meanSatRA = mean(out.Sra(idx));
out.summary.meanSatSA = mean(out.Ssa(idx));
out.summary.strokeVol = max(out.VLV(idx)) - min(out.VLV(idx));
out.summary.minSatSA  = min(out.Ssa(idx));
out.summary.maxPpv    = max(out.Ppv(idx));
end

function y = clamp01(x)
y = min(max(x,0),1);
end
