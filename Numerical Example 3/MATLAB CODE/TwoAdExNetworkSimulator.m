    function varargout = TwoAdExNetworkSimulator(varargin)

gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @TwoAdExNetworkSimulator_OpeningFcn, ...
                   'gui_OutputFcn',  @TwoAdExNetworkSimulator_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end







function plotbutton_Callback(hObject, eventdata, handles)
global hfig_graphics

%% DECLARE PARAMETERS
%----------------Global Circuit Parameters------------------
%NOTE THAT NETWORK 1 CONTAINS  THE EXCITATORY NEURONS, AND NETWORK 2 CONTAINS THE
%INHIBITORY NEURONS.  



%These are the indidivdual parameters for the AdEx neuron 
C1 = str2double(get(handles.C1,'string')); %Capacitance
C2 = str2double(get(handles.C2,'string')); %Capacitance
gl1 = str2double(get(handles.gl1,'string')); %leak conductance 
gl2 = str2double(get(handles.gl2,'string'));

vt1 = str2double(get(handles.vt1,'string')); %Resting Membrane Potential
vt2 = str2double(get(handles.vt2,'string')); %Resting Membrane Potential

b1 = str2double(get(handles.b1,'string')); %Resonator/Integrator Variable
b2 = str2double(get(handles.b2,'string')); %Resonator/Integrator Variable
del1 = str2double(get(handles.del1,'string')); %Spike Width Factor
del2 = str2double(get(handles.del2,'string')); %Spike Width Factor

eleak1 = str2double(get(handles.eleak1,'string')); %leak voltage
eleak2 = str2double(get(handles.eleak2,'string')); %leak voltage
vpeak1 = str2double(get(handles.vpeak1,'string')); %Spike peak
vpeak2 = str2double(get(handles.vpeak2,'string')); %Spike peak

TR1 = str2double(get(handles.TR1,'string')); %Synaptic rise synapse 1
TR2 = str2double(get(handles.TR2,'string')); %Synaptic rise synapse 1 
TD1 = str2double(get(handles.TD1,'string')); %synaptic decay synapse 1
TD2 = str2double(get(handles.TD2,'string')); %synaptic decay synpase 2
vreset1 = str2double(get(handles.vreset1,'string')); %voltage reset
vreset2 = str2double(get(handles.vreset2,'string')); %voltage reset

T = str2double(get(handles.T_,'string')); %Total simulation time

Er1 = str2double(get(handles.Er1,'string'));
Er2 = str2double(get(handles.Er2,'string'));

%------------------------------------------------------------------
%------------Network Specific Parameters--------------------
I1 = str2double(get(handles.I_1,'string')) ;  %Applied Current Network 1
I2 = str2double(get(handles.I_2,'string')) ;  %Applied Current Network 2

N1 = str2double(get(handles.N_1,'string')); %Number of neurons in network 1
N2 = str2double(get(handles.N_2,'string')); %Number of neurons in network 2

%These four are the maximal conductances between networks
g11 = str2double(get(handles.g_11,'string')); 
g12 = str2double(get(handles.g_12,'string')); 
g21 = str2double(get(handles.g_21,'string'));
g22 = str2double(get(handles.g_22,'string'));

%This next command is used to initialize the mean adaptation variable
u1 = str2double(get(handles.u_1,'string'))*ones(N1,1);
u2 = str2double(get(handles.u_2,'string'))*ones(N2,1);

%This next comamnd is use to initialize the synaptic gating variables 
S11 = str2double(get(handles.s_11,'string'))*ones(N1,1);
S12 = str2double(get(handles.s_12,'string'))*ones(N1,1);
S21 = str2double(get(handles.s_21,'string'))*ones(N2,1);
S22 = str2double(get(handles.s_22,'string'))*ones(N2,1);
H11 = zeros(N1,1);
H12 = zeros(N1,1);
H21 = zeros(N2,1);
H22 = zeros(N2,1);

a1 = str2double(get(handles.a1_s,'string'));  %adaptation decay time in network 1
d1 = str2double(get(handles.d1_s,'string'));  %adaptation jump in network 1
a2 = str2double(get(handles.a2_s,'string'));  %adaptation decay time in network 2
d2 = str2double(get(handles.d2_s,'string'));  %adaptation jump in network 2

%-----------Euler integration parameters ------------------
dt = 0.01; % Euler Integration Step; 
%----------Other parameters

%-----Initialization---------------------------------------------
v1 = eleak1+(vpeak1-eleak1)*rand(N1,1); %initial distribution network 1 
v2 = eleak2+(vpeak2-eleak2)*rand(N2,1); %intiial distribtuion network 2
v1_ = v1; %These are just used for Euler integration
v2_ = v2;
%---------Storage matrices --------------------------------------
vstore = zeros(T/dt,2); %store v
ustore = zeros(T/dt,2); %store u 
sstore = zeros(T/dt,4); %store u 

Neuron_Number1 = ceil(N1*rand);  % Pick neurons from network 1 and network 2 to store data from
Neuron_Number2 = ceil(N2*rand);  
v1(Neuron_Number1) = vreset1; v1_(Neuron_Number1) = vreset1;  %initialize these two neurons with the same membrane potential
v2(Neuron_Number2) = vreset2; v2_(Neuron_Number2) = vreset2; 
handles.N1 = N1; handles.N2 = N2; %Share the parameters N1 and N2 among all the callbacks. 
in1 = zeros(N1,1); %Initialize the spike firing index for network 1 
tspike1 = zeros(N1,200); %storage matix for spike time 
in2 = zeros(N2,1); %Initialize the spike firing index for network 1 
tspike2= zeros(N2,200); %storage matix for spike time 
DTspike1 = size(tspike1); 
DTspike2 = size(tspike2); 



%Connection matrices and normalization constants.  These can be modified if
%one wants to consider sparse networks.  
SMAX11 = ones(N1,N1);
A11 = N1/(N1+N2); 
n11 = N1; 



SMAX21 = ones(N2,N1);
A21 = N1/(N1+N2);
n21 = N1;

SMAX12 = ones(N1,N2);
A12 = N2/(N1+N2);
n12 = N2; 


SMAX22 = ones(N2,N2);
A22 = N2/(N1+N2);
n22 = N2; 

%Store the initial conditions for the designated neurons 
sstore(1,:) = [g11*A11*S11(Neuron_Number1),A12*n12*S12(Neuron_Number1),g21*A21*S21(Neuron_Number2),g22*A22*S22(Neuron_Number2)];
vstore(1,:) = [v1(Neuron_Number1),v2(Neuron_Number2)]; %Store v
ustore(1,:) = [u1(Neuron_Number1),u2(Neuron_Number2)]; %Store u
%% SIMULATION
tic
for i = 0:T/dt; 
%% EULER INTEGRATE
%This command is used to change the value of k so that the subthreshold and
%superthreshold response are different enough to get the right spike width.


%-------------------Euler integration--------------------
v1 = v1 + dt*(( -gl1*(v1-eleak1) + gl1*del1*exp((v1-vt1)/del1) - u1 + I1 + A11*g11*(Er1-v1).*S11 + A12*g12*(Er2-v1).*S12 )/C1) ; % v(t) = v(t-1)+dt*v'(t-1)
v2 = v2 + dt*(( -gl2*(v2-eleak2) + gl2*del2*exp((v2-vt2)/del2) - u2 + I2 + A21*g21*(Er1-v2).*S21 + A22*g22*(Er2-v2).*S22 )/C2) ;
u1 = u1 + dt*(a1*(b1*(v1_-eleak1)-u1)); %same with u, the v_ term makes it so that the integration of u uses v(t-1), instead of the updated v(t)
u2 = u2 + dt*(a2*(b2*(v2_-eleak2)-u2)); %same with u, the v_ term makes it so that the integration of u uses v(t-1), instead of the updated v(t)
%--------------------------------------------------------



%-----Store spike times command ---------------------------------
logic = (v1>=vpeak1); %Figure out which neurons are firing
if sum(logic)>0 
in1 = in1 + (logic); %Compute the total number of spikes fired
if max(in1)>max(DTspike1(2))
     tspike1(:,end+1:end+10) = zeros(N1,10);
     DTspike1 = size(tspike1);
end
n = find(logic); %Find the neurons that specifically fired a spike
tspike1(sub2ind(DTspike1,n,in1(n)))=dt*i;
end

logic = (v2>=vpeak2); %Figure out which neurons are firing
if sum(logic)>0 
in2 = in2 + (logic); %Compute the total number of spikes fired
if max(in2)>max(DTspike2(2))
     tspike2(:,end+1:end+10) = zeros(N2,10);
     DTspike2 = size(tspike2);
end
n = find(logic); %Find the neurons that specifically fired a spike
tspike2(sub2ind(DTspike2,n,in2(n)))=dt*i;
end
%------------------------------------------------------------------

%% COMPUTE S, APPLY RESETS
index = find((v1>Er1).*(v1_<Er1)); %this command finds the neurons in network 1 that have crossed the reversal potential 
if isempty(index)==1  %If no spikes have fired, just implement the exponential decay in the conductances from network 1 to its postsynaptic connections
H11 = H11 + dt*(-H11/TD1); 
H21 = H21 + dt*(-H21/TD1);

else
xs1 = SMAX11(:,index)'; %This command draws only the columns of SMAX that are from the presynaptic firing neurons 
xs2 = SMAX21(:,index)';
j = size(index); %Compute the number of neurons that have simultaneously fired in this network 
if j(1)>1, %If there are multiple neurons, we add the row sum to SIJ and implement exponential decay
H11 = H11 + dt*(-H11/TD1)+ sum(xs1)'/(n11*TR1*TD1);
H21 = H21 + dt*(-H21/TD1)+ sum(xs2)'/(n21*TR1*TD1);

else  %If only one neuron fired, simply add the relevant column of SMAXIJ to SIJ, and implement exponential decay
H11 = H11 + dt*(-H11/TD1) + xs1'/(n11*TR1*TD1);
H21 = H21 + dt*(-H21/TD1) + xs2'/(n21*TR1*TD1);%+ sum( (SMAX(:,index+1))')';
end
end
S11 = S11+dt*(-S11/TR1 + H11); 
S21 = S21+dt*(-S21/TR1 + H21);



index = find((v2>Er2).*(v2_<Er2)); %this command finds the neurons in network 1 that have crossed the reversal potential 
if isempty(index)==1  %If no spikes have fired, just implement the exponential decay in the conductances from network 1 to its postsynaptic connections
H12 = H12 + dt*(-H12/TD2); 
H22 = H22 + dt*(-H22/TD2);

else
xs1 = SMAX12(:,index)'; %This command draws only the columns of SMAX that are from the presynaptic firing neurons 
xs2 = SMAX22(:,index)';
j = size(index); %Compute the number of neurons that have simultaneously fired in this network 
if j(1)>1, %If there are multiple neurons, we add the row sum to SIJ and implement exponential decay
H12 = H12 + dt*(-H12/TD2)+ sum(xs1)'/(n12*TR2*TD2);
H22 = H22 + dt*(-H22/TD2)+ sum(xs2)'/(n22*TR2*TD2);

else  %If only one neuron fired, simply add the relevant column of SMAXIJ to SIJ, and implement exponential decay
H12 = H12 + dt*(-H12/TD2) + xs1'/(n12*TR2*TD2);
H22 = H22 + dt*(-H22/TD2) + xs2'/(n22*TR2*TD2);%+ sum( (SMAX(:,index+1))')';
end
end
S12 = S12+dt*(-S12/TR2 + H12); 
S22 = S22+dt*(-S22/TR2 + H22);








S11 = S11 + (1-S11).*(S11>1); %These commands bound each SIJ so that they cannot exceed 1.  
S12 = S12 + (1-S12).*(S12>1);
S22 = S22 + (1-S22).*(S22>1);
S21 = S21 + (1-S21).*(S21>1);

u1 = u1 + d1*(v1>vpeak1);  %implements set u to u+d if v>vpeak, component by component. 
u2 = u2 + d2*(v2>vpeak2);  %implements set u to u+d if v>vpeak, component by component. 

v1 = v1+(vpeak1-v1).*(v1>vpeak1); %implements v = c if v>vpeak add 0 if false, add c-v if true, v+c-v = c
v1_ = v1;  % sets v(t-1) = v for the next itteration of loop
v2 = v2+(vpeak2-v2).*(v2>vpeak2); %implements v = c if v>vpeak add 0 if false, add c-v if true, v+c-v = c
v2_ = v2;  % sets v(t-1) = v for the next itteration of loop



vstore(i+1,:) = [v1(Neuron_Number1),v2(Neuron_Number2)]; %store v
ustore(i+1,:) = [u1(Neuron_Number1),u2(Neuron_Number2)]; %sotre u 
sstore(i+1,:) = [g11*A11*S11(Neuron_Number1),g12*A12*S12(Neuron_Number1),g21*A21*S21(Neuron_Number2),g22*A22*S22(Neuron_Number2)]; %store the conductances

v1 = v1+(vreset1-v1).*(v1>=vpeak1); %implements v = vreset if v>vpeak. add 0 if false, add vreset-v if true
v2 = v2+(vreset2-v2).*(v2>=vpeak2); %implements v = vreset if v>vpeak. add 0 if false, add vreset-v if true
end
toc
% PLOTTING AND STORAGE


 tspike1 = tspike1(:,1:min(in1)); %resize spike time matrix to eliminate zeros
 tspike2 = tspike2(:,1:min(in2)); %resize spike time matrix to eliminate zeros 
% %---------------------------share data among the
% %callbacks------------
 handles.tspike1 = tspike1; 
 handles.tspike2 = tspike2; 

%Plotting V
axes(hfig_graphics.vplot);
 set(0,'DefaultAxesColorOrder',[1 0 0;0 1 0;0 0 1],...
      'DefaultAxesLineStyleOrder','-|--|:')
  cla(hfig_graphics.vplot,'reset')
 plot(0:dt:T,vstore), hold on %plotting v 
 ylabel('v')
legend('v_1','v_2')



% %Plotting U
 axes(hfig_graphics.uplot);
 set(0,'DefaultAxesColorOrder',[1 0 0;0 1 0;0 0 1],...
      'DefaultAxesLineStyleOrder','-|--|:')
 cla(hfig_graphics.uplot,'reset')
 plot(0:dt:T,ustore), hold on %plotting u
ylabel('u')
legend('u1','u2')

 axes(hfig_graphics.splot);
 set(0,'DefaultAxesColorOrder',[1 0 0;0 1 0;0 0 1],...
      'DefaultAxesLineStyleOrder','-|--|:')
 cla(hfig_graphics.splot,'reset')
 plot(0:dt:T,sstore(:,1:2)), hold on %plotting u
ylabel('g(t)')
legend('g11(t)','g12(t)')




axes(hfig_graphics.rplot);
 set(0,'DefaultAxesColorOrder',[1 0 0;0 1 0;0 0 1],...
      'DefaultAxesLineStyleOrder','-|--|:')
 cla(hfig_graphics.rplot,'reset')
 plot(0:dt:T,sstore(:,3:4)), hold on %plotting u
ylabel('g(t)')
legend('g21(t)','g22(t)')



figure(101)
% subplot(3,1,1)
%  set(0,'DefaultAxesColorOrder',[1 0 0;0 1 0;0 0 1],...
%       'DefaultAxesLineStyleOrder','-|--|:')
% 
%  plot(0:dt:T,vstore,'LineWidth',1), hold on %plotting v 
%  ylabel('$v_{j,m}(t)$','Interpreter','LaTeX','FontSize',14)
% legend('v_{j,E}','v_{j,I}')

subplot(3,1,1)
 set(0,'DefaultAxesColorOrder',[1 0 0;0 1 0;0 0 1],...
      'DefaultAxesLineStyleOrder','-|--|:')
 plot(0:dt:T,ustore,'LineWidth',2), hold on %plotting u
ylabel('$W_m(t)$','Interpreter','LaTeX','FontSize',14)
legend('W_{E}(t)','W_{I}(t)')
subplot(3,1,2)
 set(0,'DefaultAxesColorOrder',[1 0 0;0 1 0;0 0 1],...
      'DefaultAxesLineStyleOrder','-|--|:')
 plot(0:dt:T,sstore(:,[1,3]),'LineWidth',2), hold on %plotting u
ylabel('$g_{E,m}(t)$','Interpreter','LaTeX','FontSize',14)
legend('g_{E,E}(t)','g_{I,E}(t)')

subplot(3,1,3)
 set(0,'DefaultAxesColorOrder',[1 0 0;0 1 0;0 0 1],...
      'DefaultAxesLineStyleOrder','-|--|:')
 plot(0:dt:T,sstore(:,[2,4]),'LineWidth',2), hold on %plotting u
ylabel('$g_{I,m}(t)$','Interpreter','LaTeX','FontSize',14)
legend('g_{E,I}','g_{I,I}(t)')
xlabel('Time (ms)','Interpreter','LaTeX','FontSize',14)


figure(102)
 set(0,'DefaultAxesColorOrder',[1 0 0;0 1 0;0 0 1],...
      'DefaultAxesLineStyleOrder','-|--|:')

 plot(0:dt:T,vstore,'LineWidth',1), hold on %plotting v 
 ylabel('$v_{j,m}(t)$','Interpreter','LaTeX','FontSize',14)
legend('v_{j,E}','v_{j,I}')
xlabel('Time (ms)','Interpreter','LaTeX','FontSize',14)



guidata(hObject, handles);

function QSSA_Callback(hObject, eventdata, handles)
% hObject    handle to QSSA (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



global hfig_graphics


%These are the indidivdual parameters for the Izhikevich Neuron
C1 = str2double(get(handles.C1,'string')); %Capacitance
C2 = str2double(get(handles.C2,'string')); %Capacitance
gl1 = str2double(get(handles.gl1,'string'));
gl2 = str2double(get(handles.gl2,'string'));

vthresh1 = str2double(get(handles.vt1,'string')); %Resting Membrane Potential
vthresh2 = str2double(get(handles.vt2,'string')); %Resting Membrane Potential

b1 = str2double(get(handles.b1,'string')); %Resonator/Integrator Variable
b2 = str2double(get(handles.b2,'string')); %Resonator/Integrator Variable
delt1 = str2double(get(handles.del1,'string')); %Spike Width Factor
delt2 = str2double(get(handles.del2,'string')); %Spike Width Factor

eleak1 = str2double(get(handles.eleak1,'string')); %leak voltage
eleak2 = str2double(get(handles.eleak2,'string')); %leak voltage
vpeak1 = str2double(get(handles.vpeak1,'string')); %Spike peak
vpeak2 = str2double(get(handles.vpeak2,'string')); %Spike peak

TR1 = str2double(get(handles.TR1,'string')); %Synaptic rise time
TR2 = str2double(get(handles.TR2,'string')); %Synaptic rise time
TD1 = str2double(get(handles.TD1,'string')); %synaptic decay time
TD2 = str2double(get(handles.TD2,'string')); %synaptic decay time
vreset1 = str2double(get(handles.vreset1,'string')); %voltage reset
vreset2 = str2double(get(handles.vreset2,'string')); %voltage reset

T = str2double(get(handles.T_,'string')); %Total simulation time


%Reversal potentials for the two kinds of synapses 
Er1 = str2double(get(handles.Er1,'string'));
Er2 = str2double(get(handles.Er2,'string'));


I1 = str2double(get(handles.I_1,'string')) ;  %Applied Current Network 1
I2 = str2double(get(handles.I_2,'string')) ;  %Applied Current Network 2

N1 = str2double(get(handles.N_1,'string')); %Number of neurons in network 1
N2 = str2double(get(handles.N_2,'string')); %Number of neurons in network 2

%These four are the maximal conductances between networks
g11 = str2double(get(handles.g_11,'string')); 
g12 = str2double(get(handles.g_12,'string')); 
g21 = str2double(get(handles.g_21,'string'));
g22 = str2double(get(handles.g_22,'string'));

%This next command is used to initialize the mean adaptation variable
uint1 = str2double(get(handles.u_1,'string'));
uint2 = str2double(get(handles.u_2,'string'));

%This next comamnd is use to initialize the synaptic conductances
S11 = str2double(get(handles.s_11,'string'));
S12 = str2double(get(handles.s_12,'string'));
S21 = str2double(get(handles.s_21,'string'));
S22 = str2double(get(handles.s_22,'string'));
H11 = 0;
H12 = 0;
H21 = 0;
H22 = 0;

a1 = str2double(get(handles.a1_s,'string'));  %adaptation decay time in network 1
d1 = str2double(get(handles.d1_s,'string'));  %adaptation jump in network 1
a2 = str2double(get(handles.a2_s,'string'));  %adaptation decay time in network 2
d2 = str2double(get(handles.d2_s,'string'));  %adaptation jump in network 2
 
%weight the synaptic conductances by the network sizes.  
 g11 = (g11)*N1/(N1+N2)
 g12= (g12)*N2/(N1+N2)
 g21 = (g21)*N1/(N1+N2)
 g22 = (g22)*N2/(N1+N2)
 
 tw1 = 1/a1; wjump1 = d1; 
 tw2 = 1/a2; wjump2 = d2;
 %Initialize the mean-field equations.  
 wint1 = uint1;
 wint2 = uint2; 
 wint = [wint1,wint2];
 sint = [S11,S12,S21,S22,H11,H12,H21,H22];
 
 %Integrate the meanfield ODE's 
[t,y] = ode45(@(t,y) TWOADEXNETWORKQSSADIM(g11,g12,g21,g22,I1,I2,Er1,Er2,vpeak1,vpeak2,vreset1,vreset2,TR1,TR2,TD1,TD2,tw1,tw2,wjump1,wjump2,eleak1,eleak2,vthresh1,vthresh2,gl1,gl2,delt1,delt2,C1,C2,t,y)',[0,T],[sint,wint]');


%%
 axes(hfig_graphics.uplot);
plot(t,y(:,end-1),'k','LineWidth',1), hold on %plotting u
plot(t,y(:,end),'k','LineWidth',1), hold on %plotting u
 ylabel('u')
% 
% 
 axes(hfig_graphics.splot);
 plot(t,g11*y(:,1),'k','LineWidth',1  ), hold on %plotting g
 plot(t,g12*y(:,2),'k','LineWidth',1  ), hold on %plotting g
ylabel('g(t)')

 axes(hfig_graphics.rplot);
plot(t,g21*y(:,3),'k','LineWidth',1  ), hold on %plotting g
 plot(t,g22*y(:,4),'k','LineWidth',1  ), hold on %plotting g
ylabel('g(t)')

 figure(101)
subplot(3,1,1)
plot(t,(y(:,end-1)),'k','LineWidth',2), hold on %plotting u
plot(t,(y(:,end)),'k','LineWidth',2), hold on %plotting u
xlabel('Time (ms)','FontSize',14)
ylabel('$W_m(t)$','Interpreter','LaTeX','FontSize',14)
subplot(3,1,2)
 plot(t,g11*y(:,1),'k','LineWidth',2  ), hold on %plotting g
 plot(t,g21*y(:,3),'k','LineWidth',2  ), hold on %plotting g
 xlabel('Time (ms)','FontSize',14)
ylabel('$g_{m,E}(t)$','Interpreter','LaTeX','FontSize',14)
subplot(3,1,3)
plot(t,g12*y(:,2),'k','LineWidth',2  ), hold on %plotting g
 plot(t,g22*y(:,4),'k','LineWidth',2  ), hold on %plotting g
 xlabel('Time (ms)','FontSize',14)
ylabel('$g_{m,I}(t)$','Interpreter','LaTeX','FontSize',14)



guidata(hObject,handles)


function rasterplots_Callback(hObject, eventdata, handles)
%Plot out the raster plots for 25 neurons in each network.  
figure(10)
subplot(1,2,1) 
if handles.N1>25; j = 25; else j = handles.N1; end
for ner = 1:j 
    plot(handles.tspike1(ner,:),ner*ones,'k*'), hold on    
end
xlabel('Time (ms)')
ylabel('Neuron Index')
subplot(1,2,2)
if handles.N2>25; j = 25; else j = handles.N2; end
for ner = 1:j
    plot(handles.tspike2(ner,:),ner*ones,'k*'), hold on    
end
xlabel('Time (ms)')
ylabel('Neuron Index')

guidata(hObject,handles)




function CLEARPLOTS_Callback(hObject, eventdata, handles)
%this call back plots the average derivative of a neuron in the network
%Plotting V
global hfig_graphics

axes(hfig_graphics.vplot);
cla(hfig_graphics.vplot,'reset')

axes(hfig_graphics.uplot);
cla(hfig_graphics.uplot,'reset')

axes(hfig_graphics.splot);
cla(hfig_graphics.splot,'reset')

axes(hfig_graphics.rplot);
cla(hfig_graphics.rplot,'reset')


guidata(hObject,handles)





function TwoAdExNetworkSimulator_OpeningFcn(hObject, eventdata, handles, varargin)
plots2;
global hfig_graphics
handles.output = hObject;
guidata(hObject, handles);
function rplot_Callback(hObject, eventdata, handles)
function globalu_Callback(hObject, eventdata, handles)
function alltoall_Callback(hObject, eventdata, handles)
function Tsyn__Callback(hObject, eventdata, handles)
function Tsyn__CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function Smax__Callback(hObject, eventdata, handles)
function Smax__CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function N_1_Callback(hObject, eventdata, handles)
function N_1_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function varargout = TwoAdExNetworkSimulator_OutputFcn(hObject, eventdata, handles) 

plots2
varargout{1} = handles.output;
function C__Callback(hObject, eventdata, handles)
function C__CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function k__Callback(hObject, eventdata, handles)
function k__CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function vreset__Callback(hObject, eventdata, handles)
function vreset__CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function vpeak__Callback(hObject, eventdata, handles)
function vpeak__CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function vrest__Callback(hObject, eventdata, handles)
function vrest__CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function a__Callback(hObject, eventdata, handles)
function a__CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function b__Callback(hObject, eventdata, handles)
function b__CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function d__Callback(hObject, eventdata, handles)
function d__CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function T__Callback(hObject, eventdata, handles)
function T__CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function rastplot_Callback(hObject, eventdata, handles)
function kde_Callback(hObject, eventdata, handles)
function qflux_Callback(hObject, eventdata, handles)
function pushbutton39_Callback(hObject, eventdata, handles)


function s_11_Callback(hObject, eventdata, handles)
function s_11_CreateFcn(hObject, eventdata, handles)
% hObject    handle to s_11 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function u_1_Callback(hObject, eventdata, handles)
function u_1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to u_1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function N_2_Callback(hObject, eventdata, handles)
function N_2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to N_2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function s_21_Callback(hObject, eventdata, handles)
function s_21_CreateFcn(hObject, eventdata, handles)
% hObject    handle to s_21 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function u_2_Callback(hObject, eventdata, handles)
function u_2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to u_2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function g_21_Callback(hObject, eventdata, handles)
function g_21_CreateFcn(hObject, eventdata, handles)
% hObject    handle to g_21 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function I_2_Callback(hObject, eventdata, handles)
function I_2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to I_2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function g_22_Callback(hObject, eventdata, handles)
function g_22_CreateFcn(hObject, eventdata, handles)
% hObject    handle to g_22 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function s_22_Callback(hObject, eventdata, handles)
function s_22_CreateFcn(hObject, eventdata, handles)
% hObject    handle to s_22 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function g_11_Callback(hObject, eventdata, handles)
function g_11_CreateFcn(hObject, eventdata, handles)
% hObject    handle to g_11 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function I_1_Callback(hObject, eventdata, handles)
function I_1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to I_1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function g_12_Callback(hObject, eventdata, handles)
function g_12_CreateFcn(hObject, eventdata, handles)
% hObject    handle to g_12 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function s_12_Callback(hObject, eventdata, handles)
function s_12_CreateFcn(hObject, eventdata, handles)
% hObject    handle to s_12 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function a2_s_Callback(hObject, eventdata, handles)
function a2_s_CreateFcn(hObject, eventdata, handles)
% hObject    handle to a2_s (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function d2_s_Callback(hObject, eventdata, handles)
function d2_s_CreateFcn(hObject, eventdata, handles)
% hObject    handle to d2_s (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function a1_s_Callback(hObject, eventdata, handles)
function a1_s_CreateFcn(hObject, eventdata, handles)
% hObject    handle to a1_s (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function d1_s_Callback(hObject, eventdata, handles)
function d1_s_CreateFcn(hObject, eventdata, handles)
% hObject    handle to d1_s (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function C2_Callback(hObject, eventdata, handles)
function C2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to C2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function gl2_Callback(hObject, eventdata, handles)
function gl2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to gl2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function vreset2_Callback(hObject, eventdata, handles)
function vreset2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to vreset2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function vpeak2_Callback(hObject, eventdata, handles)
function vpeak2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to vpeak2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function eleak2_Callback(hObject, eventdata, handles)
function eleak2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to eleak2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function b2_Callback(hObject, eventdata, handles)
function b2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to b2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function TR2_Callback(hObject, eventdata, handles)
function TR2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to TR2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function TD2_Callback(hObject, eventdata, handles)
function TD2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to TD2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function vt2_Callback(hObject, eventdata, handles)
function vt2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to vt2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function del2_Callback(hObject, eventdata, handles)
function del2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to del2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function C1_Callback(hObject, eventdata, handles)
function C1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to C1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function vreset1_Callback(hObject, eventdata, handles)
function vreset1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to vreset1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function vpeak1_Callback(hObject, eventdata, handles)
function vpeak1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to vpeak1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function eleak1_Callback(hObject, eventdata, handles)
function eleak1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to eleak1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function b1_Callback(hObject, eventdata, handles)
function b1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to b1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function TR1_Callback(hObject, eventdata, handles)
function TR1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to TR1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function TD1_Callback(hObject, eventdata, handles)
function TD1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to TD1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function vt1_Callback(hObject, eventdata, handles)
function vt1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to vt1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function gl1_Callback(hObject, eventdata, handles)
function gl1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to gl1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function del1_Callback(hObject, eventdata, handles)
function del1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to del1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function Er1_Callback(hObject, eventdata, handles)
function Er1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Er1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function Er2_Callback(hObject, eventdata, handles)
% hObject    handle to Er2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Er2 as text
%        str2double(get(hObject,'String')) returns contents of Er2 as a double


% --- Executes during object creation, after setting all properties.
function Er2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Er2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
