    function varargout = TwoIzhikevichNetworkSimulator(varargin)

gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @TwoIzhikevichNetworkSimulator_OpeningFcn, ...
                   'gui_OutputFcn',  @TwoIzhikevichNetworkSimulator_OutputFcn, ...
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
% NOTE THAT NETWORK 1 IS CLASSIFED AS THE STRONGLY ADAPTING NETWORK, AND
% NETWORK 2 IS THE WEAKLY ADAPTING NETWORK.  


%These are the indidivdual parameters for the Izhikevich Neuron
C = str2double(get(handles.C_,'string')); %Capacitance
vr = str2double(get(handles.vrest_,'string')); %Resting Membrane Potential
b = str2double(get(handles.b_,'string')); %Resonator/Integrator Variable
k = str2double(get(handles.k_,'string')); %Spike Width Factor
vpeak = str2double(get(handles.vpeak_,'string')); %Spike peak
Tsyn = str2double(get(handles.Tsyn_,'string')); %Synaptic time constant
Smax = str2double(get(handles.Smax_,'string')); %Jump in the conductance
c = str2double(get(handles.vreset_,'string')); %voltage reset
T = str2double(get(handles.T_,'string')); %Total simulation time

vt=vr+40-(b/k); %threshold 
k1 = k;
k2 = k;
Er = 0 ; %Reversal Potential 
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

%This next comamnd is use to initialize the synaptic conductances
S11 = str2double(get(handles.s_11,'string'))*ones(N1,1);
S12 = str2double(get(handles.s_12,'string'))*ones(N1,1);
S21 = str2double(get(handles.s_21,'string'))*ones(N2,1);
S22 = str2double(get(handles.s_22,'string'))*ones(N2,1);


a1 = str2double(get(handles.a1_s,'string'));  %adaptation decay time in network 1
d1 = str2double(get(handles.d1_s,'string'));  %adaptation jump in network 1
a2 = str2double(get(handles.a2_s,'string'));  %adaptation decay time in network 2
d2 = str2double(get(handles.d2_s,'string'));  %adaptation jump in network 2

%-----------Euler integration parameters ------------------
dt = 0.01; % Euler Integration Step; 
%----------Other parameters

%-----Initialization---------------------------------------------
v1 = vr+(vpeak-vr)*rand(N1,1); %initial distribution network 1 
v2 = vr+(vpeak-vr)*rand(N2,1); %intiial distribtuion network 2
v1_ = v1; %These are just used for Euler integration
v2_ = v2;
%---------Storage matrices --------------------------------------
vstore = zeros(T/dt,2); %store v
ustore = zeros(T/dt,2); %store u 
sstore = zeros(T/dt,4); %store u 

Neuron_Number1 = ceil(N1*rand);  % Pick neurons from network 1 and network 2 to store data from
Neuron_Number2 = ceil(N2*rand);  
v1(Neuron_Number1) = c; v1_(Neuron_Number1) = c;  %initialize these two neurons with the same membrane potential
v2(Neuron_Number2) = c; v2_(Neuron_Number2) = c; 
handles.N1 = N1; handles.N2 = N2; %Share the parameters N1 and N2 among all the callbacks. 
in1 = zeros(N1,1); %Initialize the spike firing index for network 1 
tspike1 = zeros(N1,120); %storage matix for spike time 
in2 = zeros(N2,1); %Initialize the spike firing index for network 1 
tspike2= zeros(N2,120); %storage matix for spike time 

%Initialize k for both networks.  
%k1 = 2.5*ones(N1,1); 
%k2 = 2.5*ones(N2,1);   

%Normalization and synaptic connections matrices.  These can be modified if
%one wants to include sparsity.  
SMAX11 = Smax*ones(N1,N1);
A11 = N1/(N1+N2); 
n11 = N1; 

SMAX21 = Smax*ones(N2,N1);
A21 = N1/(N1+N2);
n21 = N1;

SMAX12 = Smax*ones(N1,N2);
A12 = N2/(N1+N2);
n12 = N2; 


SMAX22 = Smax*ones(N2,N2);
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
%   k1 = 5*(v1>vt) + (v1<vt)*0.15;
%   k2 = 5*(v2>vt) + (v2<vt)*0.15;

%-------------------Euler integration--------------------
v1 = v1 + dt*(( k1.*(v1-vr).*(v1-vt) - u1 + I1 + A11*g11*(Er-v1).*S11 + A12*g12*(Er-v1).*S12 )/C) ; % v(t) = v(t-1)+dt*v'(t-1)
v2 = v2 + dt*(( k2.*(v2-vr).*(v2-vt) - u2 + I2 + A21*g21*(Er-v2).*S21 + A22*g22*(Er-v2).*S22 )/C) ;
u1 = u1 + dt*(a1*(b*(v1_-vr)-u1)); %same with u, the v_ term makes it so that the integration of u uses v(t-1), instead of the updated v(t)
u2 = u2 + dt*(a2*(b*(v2_-vr)-u2)); %same with u, the v_ term makes it so that the integration of u uses v(t-1), instead of the updated v(t)
%--------------------------------------------------------



%-----Store spike times command ---------------------------------
logic = v1>vpeak; %Figure out which neurons are firing
in1 = in1 + (v1>vpeak); %Compute the total number of spikes fired
n = find(logic); %Find the neurons that specifically fired a spike
tspike1(n,in1(n)) = dt*i; %Store the time they fired it.  

logic = v2>vpeak; %Figure out which neurons are firing
in2 = in2 + (v2>vpeak); %Compute the total number of spikes fired
n = find(logic); %Find the neurons that specifically fired a spike
tspike2(n,in2(n)) = dt*i; %Store the time they fired it.  
%------------------------------------------------------------------

%% COMPUTE S, APPLY RESETS
index = find((v1>0).*(v1_<0)); %this command finds the neurons in network 1 that have crossed the reversal potential 
if isempty(index)==1  %If no spikes have fired, just implement the exponential decay in the conductances from network 1 to its postsynaptic connections
S11 = S11+dt*(-S11/Tsyn); 
S21 = S21+dt*(-S21/Tsyn); 
else
xs1 = SMAX11(:,index)'; %This command draws only the columns of SMAX that are from the presynaptic firing neurons 
xs2 = SMAX21(:,index)';
j = size(index); %Compute the number of neurons that have simultaneously fired in this network 
if j(1)>1, %If there are multiple neurons, we add the row sum to SIJ and implement exponential decay
S11 = S11 + dt*(-S11/Tsyn)+ sum(xs1)'/n11;
S21 = S21 + dt*(-S21/Tsyn)+ sum(xs2)'/n21;
else  %If only one neuron fired, simply add the relevant column of SMAXIJ to SIJ, and implement exponential decay
S11 = S11 + dt*(-S11/Tsyn) + xs1'/n11;
S21 = S21 + dt*(-S21/Tsyn) + xs2'/n21;%+ sum( (SMAX(:,index+1))')';
end
end

index = find((v2>0).*(v2_<0)); %All the commands below to the same thing, only with network 2 as the presynaptic network
if isempty(index)==1 
S12 = S12+dt*(-S12/Tsyn);
S22 = S22+dt*(-S22/Tsyn); 
else
xs1 = SMAX12(:,index)';
xs2 = SMAX22(:,index)';
j = size(index);
if j(1)>1, 
S12 = S12 + dt*(-S11/Tsyn)+ sum(xs1)'/n12;
S22 = S22 + dt*(-S21/Tsyn)+ sum(xs2)'/n22;
else
S12 = S12 + dt*(-S12/Tsyn) + xs1'/n12;
S22 = S22 + dt*(-S22/Tsyn) + xs2'/n22;
end
end

S11 = S11 + (1-S11).*(S11>1); %These commands bound each SIJ so that they cannot exceed 1.  
S12 = S12 + (1-S12).*(S12>1);
S22 = S22 + (1-S22).*(S22>1);
S21 = S21 + (1-S21).*(S21>1);

u1 = u1 + d1*(v1>vpeak);  %implements set u to u+d if v>vpeak, component by component. 
u2 = u2 + d2*(v2>vpeak);  %implements set u to u+d if v>vpeak, component by component. 

v1 = v1+(c-v1).*(v1>vpeak); %implements v = c if v>vpeak add 0 if false, add c-v if true, v+c-v = c
v1_ = v1;  % sets v(t-1) = v for the next itteration of loop
v2 = v2+(c-v2).*(v2>vpeak); %implements v = c if v>vpeak add 0 if false, add c-v if true, v+c-v = c
v2_ = v2;  % sets v(t-1) = v for the next itteration of loop



vstore(i+1,:) = [v1(Neuron_Number1),v2(Neuron_Number2)]; %store v
ustore(i+1,:) = [u1(Neuron_Number1),u2(Neuron_Number2)]; %sotre u 
sstore(i+1,:) = [g11*A11*S11(Neuron_Number1),g12*A12*S12(Neuron_Number1),g21*A21*S21(Neuron_Number2),g22*A22*S22(Neuron_Number2)]; %store the conductances
end
toc
% PLOTTING AND STORAGE
 tspike1 = tspike1(:,1:min(in1)); %resize spike time matrix to eliminate zeros
 tspike2 = tspike2(:,1:min(in2)); %resize spike time matrix to eliminate zeros 
% %---------------------------share data among the
% %callbacks------------
 handles.tspike1 = tspike1; 
 handles.tspike2 = tspike2; 

% 
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



figure(100)
subplot(3,1,1)
 set(0,'DefaultAxesColorOrder',[1 0 0;0 1 0;0 0 1],...
      'DefaultAxesLineStyleOrder','-|--|:')
 plot(0:dt:T,ustore), hold on %plotting u
ylabel('$W_m(t)$','Interpreter','LaTeX','FontSize',14)
legend('W_{SA}(t)','W_{WA}(t)')
subplot(3,1,2)
 set(0,'DefaultAxesColorOrder',[1 0 0;0 1 0;0 0 1],...
      'DefaultAxesLineStyleOrder','-|--|:')
 plot(0:dt:T,sstore(:,1:2)), hold on %plotting u
ylabel('$g_{SA,m}(t)$','Interpreter','LaTeX','FontSize',14)
legend('g_{SA,SA}(t)','g_{SA,WA}(t)')

subplot(3,1,3)
 set(0,'DefaultAxesColorOrder',[1 0 0;0 1 0;0 0 1],...
      'DefaultAxesLineStyleOrder','-|--|:')
 plot(0:dt:T,sstore(:,3:4)), hold on %plotting u
ylabel('$g_{WA,m}(t)$','Interpreter','LaTeX','FontSize',14)
legend('g_{WA,SA}(t)','g_{WA,WA}(t)')






guidata(hObject, handles);

function QSSA_Callback(hObject, eventdata, handles)
% hObject    handle to QSSA (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global hfig_graphics
C = str2double(get(handles.C_,'string')); %Capacitance
vr = str2double(get(handles.vrest_,'string')); %Resting Membrane Potential
b = str2double(get(handles.b_,'string')); %Resonator/Integrator Variable
k = str2double(get(handles.k_,'string')); %Spike Width Factor
vpeak = str2double(get(handles.vpeak_,'string')); %Spike peak
Tsyn = str2double(get(handles.Tsyn_,'string')); %Synaptic time constant
Smax = str2double(get(handles.Smax_,'string')); %Jump in the conductance
c = str2double(get(handles.vreset_,'string')); %voltage reset
T = str2double(get(handles.T_,'string')); %Total simulation time
vt=vr+40-(b/k); %threshold 
Er = 0; %Reversal Potential 


I1 = str2double(get(handles.I_1,'string')) ;  %Applied Current Network 1
I2 = str2double(get(handles.I_2,'string')) ;  %Applied Current Network 2
N1 = str2double(get(handles.N_1,'string')); %Number of neurons in network 1
N2 = str2double(get(handles.N_2,'string')); %Number of neurons in network 2

%Synaptic connections between the networks.  
g11 = str2double(get(handles.g_11,'string')); 
g12 = str2double(get(handles.g_12,'string')); 
g21 = str2double(get(handles.g_21,'string'));
g22 = str2double(get(handles.g_22,'string'));
a1 = str2double(get(handles.a1_s,'string'));  %adaptation decay time in network 1
d1 = str2double(get(handles.d1_s,'string'));  %adaptation jump in network 1
a2 = str2double(get(handles.a2_s,'string'));  %adaptation decay time in network 2
d2 = str2double(get(handles.d2_s,'string'));  %adaptation jump in network 2



%Dimensionless Parameters
alpha = 1+vt/abs(vr)
g11 = (g11/(k*abs(vr)))*(N1/(N1+N2))
g12 = (g12/(k*abs(vr)))*(N2/(N1+N2))
g21 = (g21/(k*abs(vr)))*(N1/(N1+N2))
g22 = (g22/(k*abs(vr)))*(N2/(N1+N2))
sint = [str2double(get(handles.s_11,'string')),str2double(get(handles.s_12,'string')),str2double(get(handles.s_21,'string')),str2double(get(handles.s_22,'string'))];
wint = [str2double(get(handles.u_1,'string')),str2double(get(handles.u_2,'string'))]/(k*vr^2);
I1 = I1/(k*vr^2)
I2 = I2/(k*vr^2)
er = 1+Er/abs(vr)
vpeak = 1 + vpeak/abs(vr)
vreset = 1 + c/abs(vr)
wjump1 = d1/(k*vr^2)
wjump2 = d2/(k*vr^2)
sjump = Smax
T = T*k*abs(vr)/C; 
ts = Tsyn*k*abs(vr)/C
tw1 = (1/a1)*(k*abs(vr))/C
tw2 = (1/a2)*(k*abs(vr))/C

%Run the mean-field approximation for the two subpopulation Izhikevich
%network case.  
[t,y] = ode45(@(t,y) TWOIZNETWORKQSSA(alpha,g11,g12,g21,g22,I1,I2,er,vpeak,vreset,ts,tw1,tw2,sjump,wjump1,wjump2,t,y)',[0,T],[sint,wint]');


%Plot the results in the main window 
 axes(hfig_graphics.uplot);
 plot(C*t/(k*abs(vr)),k*(vr^2)*y(:,end-1),'k','LineWidth',2), hold on %plotting u
  plot(C*t/(k*abs(vr)),k*(vr^2)*y(:,end),'k','LineWidth',2), hold on %plotting u
 ylabel('u')
% 

 axes(hfig_graphics.splot);
 plot(C*t/(k*abs(vr)),k*abs(vr)*g11*y(:,1),'k','LineWidth',2  ), hold on %plotting g
 plot(C*t/(k*abs(vr)),k*abs(vr)*g12*y(:,2),'k','LineWidth',2  ), hold on %plotting g
ylabel('g(t)')

 axes(hfig_graphics.rplot);
 plot(C*t/(k*abs(vr)),k*abs(vr)*g21*y(:,1),'k','LineWidth',2  ), hold on %plotting g
 plot(C*t/(k*abs(vr)),k*abs(vr)*g22*y(:,2),'k','LineWidth',2  ), hold on %plotting g
ylabel('g(t)')

 figure(100)
%Plot the mean-field equations in the new subwindow.  
 subplot(3,1,1)
plot(C*t/(k*abs(vr)),k*(vr^2)*y(:,end-1),'k','LineWidth',2), hold on %plotting u
plot(C*t/(k*abs(vr)),k*(vr^2)*y(:,end),'k','LineWidth',2), hold on %plotting u
xlabel('Time (ms)','FontSize',14)
ylabel('$W_m(t)$','Interpreter','LaTeX','FontSize',14)
subplot(3,1,2)
 plot(C*t/(k*abs(vr)),k*abs(vr)*g11*y(:,1),'k','LineWidth',2  ), hold on %plotting g
 plot(C*t/(k*abs(vr)),k*abs(vr)*g12*y(:,2),'k','LineWidth',2  ), hold on %plotting g
 xlabel('Time (ms)','FontSize',14)
ylabel('$g_{SA,m}(t)$','Interpreter','LaTeX','FontSize',14)
subplot(3,1,3)
plot(C*t/(k*abs(vr)),k*abs(vr)*g21*y(:,1),'k','LineWidth',2  ), hold on %plotting g
 plot(C*t/(k*abs(vr)),k*abs(vr)*g22*y(:,2),'k','LineWidth',2  ), hold on %plotting g
 xlabel('Time (ms)','FontSize',14)
ylabel('$g_{WA,m}(t)$','Interpreter','LaTeX','FontSize',14)
guidata(hObject,handles)


function rasterplots_Callback(hObject, eventdata, handles)
%This command plots the raster plots for 25 neurons in each subpopulation.
%
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






function TwoIzhikevichNetworkSimulator_OpeningFcn(hObject, eventdata, handles, varargin)
plots;
global hfig_graphics
handles.output = hObject;
guidata(hObject, handles);
function rplot_Callback(hObject, eventdata, handles)

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
function varargout = TwoIzhikevichNetworkSimulator_OutputFcn(hObject, eventdata, handles) 

plots
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


% --- Executes on button press in QSSA.
