function [rp] = lunghao2(a)
% Class that implements a 2SoundRM1_2.rco

global private_lunghao2_list;

if nargin==0,
    rp = struct( ...
        'samprate',       48828,   ...
        'running1',       0,   ...
        'index1',         0,   ...
        'datain1',        0,   ...
        'datalngth1',     0,   ...
        'timer',          timer, ...
        'running2',       0,   ...
        'index2',         0,   ...
        'datain2',        0,   ...
        'datalngth2',     0,   ...
        'running3',       0,   ...
        'index3',         0,   ...
        'datain3',        0,   ...
        'datalngth3',     0,   ...
        'ch1in',          0,   ...
        'ch2in',          0,   ...
        'list_position',  0);
   rp = class(rp, 'lunghao2');
   set(rp.timer, 'TimerFcn', '1;'); % Null timer function...
   
   rp.list_position = length(private_lunghao2_list)+1;
   if isempty(private_lunghao2_list),
       private_lunghao2_list = {rp};
   else
       private_lunghao2_list = [private_lunghao2_list ; {rp}];
   end;
   return;
   
elseif isa(a, 'lunghao2'),
    rp = a;
    return;
    
else
    error('Don''t understand this argument for creation of a lunghao1');
end;

        
