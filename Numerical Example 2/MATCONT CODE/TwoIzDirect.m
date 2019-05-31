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