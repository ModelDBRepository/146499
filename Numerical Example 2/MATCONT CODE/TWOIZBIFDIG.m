%par1 = I1, par2 = g11 
clc
clear all

%% Parameter Continuation for a Two-Izhikevich Subpop Network
I1 = 0.2;  %Initial Parameter value for I
g11 = 0.8615; 

%Run an initial simulation to find the equilibrium point
[t,y] = ode45(@(t,y) TwoIzDirect(t,y,I1,g11),[0,40],zeros(4,1));
init
xeq = y(end,:);
[x0,v0]=init_EP_EP(@TwoIzMeanField,xeq',[I1;g11],[1]);

%Numerical continuation parameters
opt=contset;
  % opt=contset(opt,'Adapt',10000);
opt=contset(opt,'Backward',1);
opt=contset(opt,'MaxStepSize',0.001);
opt=contset(opt,'MinStepSize',0.00001); 
   %opt=contset(opt,'MaxNumPoints',10000);
opt=contset(opt,'Singularities',2);
% opt=contset(opt,'Increment',1e-5); 
opt =contset(opt,'Eigenvalues',1);
  %Numerical continuation of an equilibrium point
[x,v,s,h,f]=cont(@equilibrium,x0,[],opt);
  
x1 = x(1:4,s(2).index); p =[x(end,s(2).index);g11];
   %Initialize the limit cycle
[x0,v0]=init_H_LC(@TwoIzMeanField,x1,p,[1],1e-6,20,4);
    %Numerical continuation parameters
opt = contset(opt,'MaxNumPoints',50);
opt = contset(opt,'Multipliers',1);
opt = contset(opt,'MaxStepSize',100);
opt = contset(opt,'MinStepSize',0.1); 
opt = contset(opt,'Adapt',50);
    
    %Limit cycle numerical continuation 
[xlc,vlc,slc,hlc,flc]=cont(@limitcycle,x0,v0,opt);
xlc(end,:) = xlc(end,:)*2.5*65*65;  x(end,:) = x(end,:)*2.5*65*65;


   %Plot cycle and equilibrium points
plotcycle(xlc,vlc,slc,[size(xlc,1) 1 2]), hold on
cpl(x,v,s,[size(x,1),1,2])


%% Numerically Compute the Stable Bursting Limit Cycle via Direct Simulations.  

I1 = 0.14; I1min = I1;  %Initial Current 
I1max = xlc(end,end)/(2.5*65*65); %Nondimensionalize the Current 
dI = (I1max-I1)/(20); %Current Step Size

%manually plot the stable bursting limit cycle in GREEN 
REC1 = []; REC2 = []; REC3 = []; 
index = 0; 
tspan = 0:1:100; %Number of time points to compute limit cycle at.  
 while I1<I1max
     index = index + 1; 
I1 = I1 + dI;
%Run the equations to eliminate any initial transient.
[t,y] = ode45(@(t,y) TwoIzDirect(t,y,I1,g11),[0,200],zeros(4,1));
ynot = y(end,:); 
%Compute the stable bursting limit cycle.  
[t,y] = ode45(@(t,y) TwoIzDirect(t,y,I1,g11),tspan,ynot');


 if mod(index,2) == 1 
 plot3(I1*2.5*65*65 + 0*y(:,1),y(:,1),y(:,2),'k'), hold on %Plot the bursting limit cycle in black 
 end
 % We need these to generate the surface.  
REC1(:,index) =  I1*2.5*65*65 + 0*y(:,1);
REC2(:,index) = y(:,1);
REC3(:,index) = y(:,2); 


axis([I1min*2.5*65*65,I1max*2.5*65*65,min(y(:,1)),max(y(:,1)),min(y(:,2)),max(y(:,2))])

 end
%Labels and plotting the surface in Green.  
xlabel('$I_{app}$','Interpreter','LateX','FontSize',14)
ylabel('$s_{SA}$','Interpreter','LateX','FontSize',14)
zlabel('$s_{WA}$','Interpreter','LateX','FontSize',14)
surf(REC1,REC2,REC3,'FaceColor','green','EdgeColor','none')
  clear alpha 
colormap hsv
alpha(.2)
