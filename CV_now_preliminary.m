function CV = CV_now(t,CVS,CVD)
% CV_now.m
% Time-varying ventricular compliance used by the TAPVR/PAPVR project model.
% Copied from the user's homework model so the LV timing stays consistent.

global T TS tauS tauD;

tc = rem(t,T);

if tc < TS
    e = (1-exp(-tc/tauS))/(1-exp(-TS/tauS));
    CV = CVD*(CVS/CVD)^e;
else
    e = (1-exp(-(tc-TS)/tauD))/(1-exp(-(T-TS)/tauD));
    CV = CVS*(CVD/CVS)^e;
end
end
