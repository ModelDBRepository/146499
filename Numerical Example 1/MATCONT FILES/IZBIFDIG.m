%% Numerical Continuation for Unstable Hopf-Cycle.   
clc
clear all
%Parameter values for plotting switching manifold 
alpha=0.624; er=1; vreset=0.1538; sjump=0.8; ts=1.4; wjump = 0.0189;
tw = 65; vpeak=1.4615; er =1;
%Bifurcation parameters 
I = 0.4; 
g = 1.2308

%Run an initial simulation to determine the equilibrium point
int = [0,0]
[t,y] = ode45(@(t,y) IzDIRECT(t,y,I,g),[0,200],int');
init
xeq = y(end,:)
[x0,v0]=init_EP_EP(@Izmeanfield2,xeq',[I;g],[1])

%Configure Numerical Constants for continuation
opt=contset;
  % opt=contset(opt,'Adapt',10000);
opt=contset(opt,'Backward',1);
opt=contset(opt,'MaxStepSize',0.001);
opt=contset(opt,'MinStepSize',0.00001); 
   %opt=contset(opt,'MaxNumPoints',10000);
opt=contset(opt,'Singularities',2);
% opt=contset(opt,'Increment',1e-5); 
opt =contset(opt,'Eigenvalues',1);

%Equilibrium continuation 
  [x,v,s,h,f]=cont(@equilibrium,x0,[],opt);
  
%Equilibrium point, Parameter at Hopf Bifurcation Point 
x1 = x(1:2,s(2).index); p =[x(end,s(2).index);g];
[x0,v0]=init_H_LC(@Izmeanfield2,x1,p,[1],1e-6,20,4);
     
%Change some numerical constants/parameters for numerical continuation
%of a limit cylce
opt = contset(opt,'MaxNumPoints',50);
opt = contset(opt,'Multipliers',1);
opt=contset(opt,'MaxStepSize',100);
opt=contset(opt,'MinStepSize',0.1); 
opt=contset(opt,'Adapt',50);

%Numerical continuation of a limit cycle, and plotting results.  Plots the
%unstable limit cylce in Blue
[xlc,vlc,slc,hlc,flc]=cont(@limitcycle,x0,v0,opt);
xlc(end,:) = xlc(end,:)*2.5*65*65;  x(end,:) = x(end,:)*2.5*65*65; %(dimensionalization, I_app = I * k*vr*vr
plotcycle(xlc,vlc,slc,[size(xlc,1) 1 2]), hold on
cpl(x,v,s,[size(x,1),1,2])
    
 %% Direct Simulations for Bursting Limit Cycle
 I1min = min(xlc(end,:))/(2.5*65*65); %Range of I values
 I1max = max(xlc(end,:))/(2.5*65*65);
 dI = (I1max-I1min)/(20);  %step over the range

 I1 = I1min; %Initialize at min and increase in increments of DI 
tspan = 0:1:100; %Times to compute the limit cycle.  
index = 0; 
REC1 = []; REC2 = []; REC3 = []; 
  while I1<I1max 
      index = index + 1; 
 I1 = I1 + dI ;
 [t,y] = ode45(@(t,y) IzDIRECT(t,y,I1,g),[0,200],zeros(2,1)); %Run direct simulations, get rid of initial transient
 ynot = y(end,:);
 [t,y] = ode45(@(t,y) IzDIRECT(t,y,I1,g),tspan,ynot'); %Stable Limit Cycle 
 %drawnow
 if mod(index,2) == 1 
 plot3(I1*2.5*65*65 + 0*y(:,1),y(:,1),y(:,2),'k'), hold on %Plot the limit cycle for fixed I in 3 dimensions.  
 end
 %We need to save these to generate the bursting limit cycle surface.  
REC1(:,index) =  I1*2.5*65*65 + 0*y(:,1);
REC2(:,index) = y(:,1);
REC3(:,index) = y(:,2); 

  end
  %Plot the switching manifold in RED 
  axis([I1min*2.5*65*65,I1max*2.5*65*65+20,0,0.3,0.05,0.15])
  s = 0.2*(0:0.1:1); u = 0.2*(0:0.1:1);
  s = ones(11,1)*s; u = ones(11,1)*u;
  I = -2.5*65*65*(-u' + g*er*s - 0.25*(alpha+g*s).^2);
  surf(I,s,u','FaceColor','red','EdgeColor','none')
  clear alpha 
colormap hsv


%Plot the stable bursting limit cycle manifold in Green 
surf(REC1,REC2,REC3,'FaceColor','green','EdgeColor','none')
  clear alpha 
colormap hsv
alpha(.2)
% for i = 1:10
%     plot3(REC1(10*i,:),REC2(10*i,:),REC3(10*i,:),'k'), hold on 
% end
xlabel('$I_{app}$','Interpreter','LateX','FontSize',14)
 ylabel('$s$','Interpreter','LateX','FontSize',14)
 zlabel('$\langle w \rangle$','Interpreter','LateX','FontSize',14)
