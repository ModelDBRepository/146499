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
