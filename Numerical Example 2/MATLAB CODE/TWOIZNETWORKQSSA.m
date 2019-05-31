function dy = TWOIZNETWORKQSSA(alpha,g11,g12,g21,g22,I1,I2,er,vpeak,vreset,ts,tw1,tw2,sjump,wjump1,wjump2,t,y) 


H1 = I1 + g11*er*y(1) + g12*er*y(2) - y(5) - ((alpha + g11*y(1) + g12*y(2))^2)/4;
H2 = I2 + g21*er*y(3) + g22*er*y(4) - y(6) - ((alpha + g21*y(3) + g22*y(4))^2)/4;

if H1 > 0 
x = (vpeak-0.5*(alpha +  g11*y(1) + g12*y(2)  ))/sqrt(H1);
z = (vreset-0.5*(alpha + g11*y(1)+g12*y(2)))/sqrt(H1);
R1 = sqrt(H1)/(atan(x)-atan(z)); 
else R1 = 0; 
end

if H2 > 0 
x = (vpeak-0.5*(alpha+ g21*y(3) + g22*y(4)  ))/sqrt(H2);
z = (vreset-0.5*(alpha+g21*y(3)+g22*y(4)))/sqrt(H2);
R2 = sqrt(H2)/(atan(x)-atan(z)); 
else R2 = 0; 
end



dy(1) = -y(1)/ts + sjump*R1;
dy(2) = -y(2)/ts + sjump*R2;
dy(3) = -y(3)/ts + sjump*R1;
dy(4) = -y(4)/ts + sjump*R2;
dy(5) = -y(5)/tw1 + wjump1*R1;
dy(6) = -y(6)/tw2 + wjump2*R2;
end