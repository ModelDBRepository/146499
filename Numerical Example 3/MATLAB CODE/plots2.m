function varargout = plots2(varargin)
% PLOTS2 MATLAB code for plots2.fig
%      PLOTS2, by itself, creates a new PLOTS2 or raises the existing
%      singleton*.
%
%      H = PLOTS2 returns the handle to a new PLOTS2 or the handle to
%      the existing singleton*.
%
%      PLOTS2('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in PLOTS2.M with the given input arguments.
%
%      PLOTS2('Property','Value',...) creates a new PLOTS2 or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before plots2_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to plots2_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help plots2

% Last Modified by GUIDE v2.5 01-Jun-2012 11:21:17

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @plots2_OpeningFcn, ...
                   'gui_OutputFcn',  @plots2_OutputFcn, ...
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
% End initialization code - DO NOT EDIT


% --- Executes just before plots2 is made visible.
function plots2_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to plots2 (see VARARGIN)
global hfig_graphics
hfig_graphics = handles;

% Choose default command line output for plots2
handles.output = hObject;


set(hObject,'toolbar','figure');
% Update handles structure
guidata(hObject, handles);

% UIWAIT makes plots2 wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = plots2_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
