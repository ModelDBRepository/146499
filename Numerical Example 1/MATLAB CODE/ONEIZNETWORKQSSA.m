function dy = ONEIZNETWORKQSSA(alpha,g,I,er,vpeak,vreset,ts,tw,sjump,wjump,t,y) 


H = I + g*er*y(1) - y(2) - ((alpha + g*y(1))^2)/4;

if H > 0 
x = (vpeak-0.5*(alpha+g*y(1)))/sqrt(H);
z = (vreset-0.5*(alpha+g*y(1)))/sqrt(H);
R = sqrt(H)/(atan(x)-atan(z)); 
else R = 0; 
end


dy(1) = -y(1)/ts + sjump*R;
dy(2) = -y(2)/tw + wjump*R;

end