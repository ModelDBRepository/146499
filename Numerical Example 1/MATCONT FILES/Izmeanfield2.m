function out = Izmeanfield2
out{1} = @init;
out{2} = @fun_eval;
out{3} = [];
out{4} = [];
out{5} = [];
out{6} = [];
out{7} = [];
out{8} = [];
out{9} = [];

% --------------------------------------------------------------------------
function dydt = fun_eval(t,kmrgd,I,g)
alpha=0.624; er=1; vreset=0.1538; sjump=0.8; ts=1.4; wjump = 0.0189;
tw = 65; vpeak=1.4615; er =1;
H=I+g*er*kmrgd(1)-kmrgd(2)-0.25*(alpha+g*kmrgd(1))^2;
if H>0

x=(vpeak-0.5*(alpha+g*kmrgd(1)))/sqrt(H);
y=(vreset-0.5*(alpha+g*kmrgd(1)))/sqrt(H);
R=sqrt(H)/(atan(x)-atan(y)); else R = 0; 
end
dydt=[-kmrgd(1)/ts+sjump*R;
-kmrgd(2)/tw+wjump*R];

% --------------------------------------------------------------------------
function [tspan,y0,options] = init
handles = feval(Izmeanfield2);
y0=[0,0];
options = odeset('Jacobian',[],'JacobianP',[],'Hessians',[],'HessiansP',[]);
tspan = [0 10];

% --------------------------------------------------------------------------
function jac = jacobian(t,kmrgd,I,g,er,vpeak,alpha,vreset,ts,tw,wjump,sjump)
% --------------------------------------------------------------------------
function jacp = jacobianp(t,kmrgd,I,g,er,vpeak,alpha,vreset,ts,tw,wjump,sjump)
% --------------------------------------------------------------------------
function hess = hessians(t,kmrgd,I,g,er,vpeak,alpha,vreset,ts,tw,wjump,sjump)
% --------------------------------------------------------------------------
function hessp = hessiansp(t,kmrgd,I,g,er,vpeak,alpha,vreset,ts,tw,wjump,sjump)
%---------------------------------------------------------------------------
function tens3  = der3(t,kmrgd,I,g,er,vpeak,alpha,vreset,ts,tw,wjump,sjump)
%---------------------------------------------------------------------------
function tens4  = der4(t,kmrgd,I,g,er,vpeak,alpha,vreset,ts,tw,wjump,sjump)
%---------------------------------------------------------------------------
function tens5  = der5(t,kmrgd,I,g,er,vpeak,alpha,vreset,ts,tw,wjump,sjump)
