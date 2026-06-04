% =================
% File: CV_now.m
% =================
function CV = CV_now(t,CVS,CVD)
% CV_now.m
% Time-varying ventricular compliance.
% Same functional form as the class/homework LV model.

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
