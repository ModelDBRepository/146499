function dy = ONEIZNETWORKQSSADIM(g11,g12,g21,g22,I1,I2,Er1,Er2,vpeak1,vpeak2,vreset1,vreset2,TR1,TR2,TD1,TD2,tw1,tw2,wjump1,wjump2,eleak1,eleak2,vt1,vt2,gl1,gl2,delt1,delt2,C1,C2,t,y) 

s11 = y(1);
s12 = y(2); 
s21 = y(3); 
s22 = y(4); 
h11 = y(5);
h12 = y(6);
h21 = y(7);
h22 = y(8);
w1 = y(9);
w2 = y(10);

dv1 = (vpeak1-vreset1)/1000;
dv2 = (vpeak2-vreset2)/1000; 
v1 = vreset1:dv1:vpeak1;
v2 = vreset2:dv2:vpeak2;
dv1dt = -gl1*(v1 - eleak1) + gl1*delt1*exp( (v1-vt1)/delt1) + I1 + g11*s11*(Er1-v1) + g12*s12*(Er2-v1) - w1;
dv2dt = -gl2*(v2 - eleak2) + gl2*delt2*exp( (v2-vt2)/delt2) + I2 + g21*s21*(Er1-v2) + g22*s22*(Er2-v2) - w2;
 
 
if min(dv1dt)>0;
%J = quad(@(v) C1./(-gl1*(v - eleak1) + gl1*delt1*exp( (v-eleak1)/delt1) + I1 + g11*s11*(Er1-v) + g12*s12*(Er2-v) - w1),vreset1,vpeak1);
J = dv1*trapz(C1./dv1dt);
R1 = 1/J;
else R1 = 0; 
end

if min(dv2dt)>0;
%J = quad(@(v) C2./(-gl2*(v - eleak2) + gl2*delt2*exp( (v-eleak2)/delt2) + I2 + g21*s21*(Er1-v) + g22*s22*(Er2-v) - w2),vreset2,vpeak2);
J = dv2*trapz(C2./dv2dt);
R2 = 1/J;
else R2 = 0; 
end

dy(1) = -s11/TR1 + h11;
dy(2) = -s12/(TR2) + h12;
dy(3) = -s21/TR1 + h21;
dy(4) = -s22/(TR2) + h22;

dy(5) = -h11/TD1 + R1/(TR1*TD1);
dy(6) = -h12/(TD2) + (R2/(TR2*TD2));
dy(7) = -h21/TD1 + R1/(TR1*TD1);
dy(8) = -h22/(TD2) + (R2/(TR2*TD2));

dy(9) = -w1/tw1 + wjump1*R1;
dy(10) = -w2/tw2 + wjump2*R2;

if s11>=1, dy(1) = -s11/TR1; end
if s12>=1, dy(2) = -s12/(TR2); end
if s21>=1, dy(3) = -s21/TR1; end
if s22>=1, dy(4) = -s22/(TR2); end



end