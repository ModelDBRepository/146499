function out = IzhikevichMeanField
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
function dydt = fun_eval(t,y,I1,g11)
alpha=0.624; er=1; vreset=0.1538; sjump=0.8; ts=1.4;  vpeak = 1.4615; 
g12 = 0.3692;
g21 = 0.8615;
g22 = 0.3692;
tw1 = 65;
tw2 = 6.5;
wjump1 = 0.0189;
wjump2 = 0.0095;
I2 = 0.113;

H1 = I1 + g11*er*y(1) + g12*er*y(2) - y(3) - ((alpha + g11*y(1) + g12*y(2))^2)/4;
H2 = I2 + g21*er*y(1) + g22*er*y(2) - y(4) - ((alpha + g21*y(1) + g22*y(2))^2)/4;

if H1 > 0 
x = (vpeak-0.5*(alpha +  g11*y(1) + g12*y(2)  ))/sqrt(H1);
z = (vreset-0.5*(alpha + g11*y(1)+g12*y(2)))/sqrt(H1);
R1 = sqrt(H1)/(atan(x)-atan(z)); 
else R1 = 0; 
end

if H2 > 0 
x = (vpeak-0.5*(alpha+ g21*y(1) + g22*y(2)  ))/sqrt(H2);
z = (vreset-0.5*(alpha+g21*y(1)+g22*y(2)))/sqrt(H2);
R2 = sqrt(H2)/(atan(x)-atan(z)); 
else R2 = 0; 
end



dy(1) = -y(1)/ts + sjump*R1;
dy(2) = -y(2)/ts + sjump*R2;
dy(3) = -y(3)/tw1 + wjump1*R1;
dy(4) = -y(4)/tw2 + wjump2*R2;
dydt = dy'; 

% --------------------------------------------------------------------------
function [tspan,y0,options] = init
handles = feval(IzhikevichMeanField);
y0=[0,0];
options = odeset('Jacobian',[],'JacobianP',[],'Hessians',[],'HessiansP',[]);
tspan = [0 10];

% --------------------------------------------------------------------------
function jac = jacobian(t,kmrgd,I,alpha,g,er,vpeak,vreset,ts,tw,wjump,sjump)
% --------------------------------------------------------------------------
function jacp = jacobianp(t,kmrgd,I,alpha,g,er,vpeak,vreset,ts,tw,wjump,sjump)
% --------------------------------------------------------------------------
function hess = hessians(t,kmrgd,I,alpha,g,er,vpeak,vreset,ts,tw,wjump,sjump)
% --------------------------------------------------------------------------
function hessp = hessiansp(t,kmrgd,I,alpha,g,er,vpeak,vreset,ts,tw,wjump,sjump)
%---------------------------------------------------------------------------
function tens3  = der3(t,kmrgd,I,alpha,g,er,vpeak,vreset,ts,tw,wjump,sjump)
%---------------------------------------------------------------------------
function tens4  = der4(t,kmrgd,I,alpha,g,er,vpeak,vreset,ts,tw,wjump,sjump)
%---------------------------------------------------------------------------
function tens5  = der5(t,kmrgd,I,alpha,g,er,vpeak,vreset,ts,tw,wjump,sjump)
