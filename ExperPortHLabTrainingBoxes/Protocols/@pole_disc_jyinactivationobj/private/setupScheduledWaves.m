task_periods_per_ms = 6;

%--------------------------------------------
% ao_chan_offset_in_volts = 0.075;
% ao_chan_offset_in_volts = -0.120; % Changed 13sep11
% ao_chan_max_volts = 10.0;
% ao_offset = (ao_chan_offset_in_volts / ao_chan_max_volts);

delay=onsetjitt*task_periods_per_ms;

ao_chan_offset_in_volts = -0.120;     % 9/7/11
ao_chan_max_volts = 10.0;
ao_offset = (ao_chan_offset_in_volts / ao_chan_max_volts);
ao_chan_aom_on = (stim_AOM_power / ao_chan_max_volts);
% ao_offset = 0;

% ao_offset = 0;
%--------------------------------------------


% Put these IDs in a Solo global variable...
wave_id_masking_flash_blue = 2; AO_chan_masking_flash_blue = 1;
% wave_id_masking_flash_orange = 3; AO_chan_masking_flash_orange = 7;
wave_id_x_galvo = 4; AO_chan_x_galvo = 2;
wave_id_y_galvo = 5; AO_chan_y_galvo = 3;
wave_id_aom_473 = 6; AO_chan_aom_473 = 5;
% wave_id_aom_594 = 7; AO_chan_aom_594 = 6;

% wave_id_cam_frame = 8; DIO_chan_cam_frame = 9;  % Handled in EmbC program, not here.
% wave_id_cam_gate = 9; DIO_chan_cam_gate = 8;   % Breakout box port 5.
wave_id_shutter = 1; DIO_chan_shutter = 11; % Breakout box port 6.

stim_event_record_chan = 3;

%-------------------------------------------------------------------------
% Define scheduled waves:
%-------------------------------------------------------------------------

%------------------------
% Make shutter schedule wave:
shutterDurationInSec = 4; DIO_shutter_loop = 0;
schedWv_Shutter1 = [wave_id_shutter -1 -1 DIO_chan_shutter 0 0 shutterDurationInSec 0 DIO_shutter_loop];

%------------------------
% Build full matrix for DIO scheduled waves:
digSchedWvAll = schedWv_Shutter1;

%------------------------
% Make masking flash waveform. Two seconds of 1 ms
% pulses, like the actual stim. 10 Hz frequency.
on1 = ones([1 1*task_periods_per_ms]); % 1 ms
off1 = zeros([1 99*task_periods_per_ms]); % 99 ms
wv = [on1, off1];
fullwv = repmat(wv, [1 40]); % 4 sec flash
schedWv_MaskFlash1 = [fullwv; zeros([1 numel(fullwv)])];

%------------------------
% see if it is grid or S1
if galvo==1
    switch StimType

        case {'5ms_grid', 'shiftgrid'}
            % interval
            interval=10*task_periods_per_ms; % intervals of mirror switching
            cycles=dur/1000*20;
            single=repmat(x'/ao_chan_max_volts, [interval, 1]);
            single=reshape(single, [], 1);
            fullwv=repmat(single', [1, cycles]);
            if delay>0
                fullwv=[-0.25*ones(1, delay) fullwv];
            end;
            schedWv_XGalvo1 = [fullwv; zeros([1 numel(fullwv)])];
            single=repmat(y'/ao_chan_max_volts, [interval, 1]);
            single=reshape(single, [], 1);
            fullwv=repmat(single', [1, cycles]);
            if delay>0
                fullwv=[0*ones(1, delay) fullwv];
            end;
            schedWv_YGalvo1 = [fullwv; zeros([1 numel(fullwv)])];

        case  {'grid_and_s1'} % inactivating both m1 and s1
            % interval
            interval=(1000/(20*6))*task_periods_per_ms; % intervals of mirror switching
            cycles=(dur/1000)*20;
            single=repmat(x'/ao_chan_max_volts, [interval, 1]);
            single=reshape(single, [], 1);
            fullwv=repmat(single', [1, cycles]);
            if delay>0
                fullwv=[-0.25*ones(1, delay) fullwv];
            end;
            schedWv_XGalvo1 = [fullwv; zeros([1 numel(fullwv)])];

            single=repmat(y'/ao_chan_max_volts, [interval, 1]); single=reshape(single, [], 1);
            fullwv=repmat(single', [1, cycles]);
            if delay>0
                fullwv=[0*ones(1, delay) fullwv];
            end;
            schedWv_YGalvo1 = [fullwv; zeros([1 numel(fullwv)])];


        case {'shift', 'constant_shift'} % directed to where s1 is.

            fullwv = repmat(x/ao_chan_max_volts' , [1 dur*task_periods_per_ms]); % 2 sec
            if delay>0
                fullwv=[-0.25*ones(1, delay) fullwv];
            end;
            schedWv_XGalvo1 = [fullwv; zeros([1 numel(fullwv)])];

            %------------------------
            % Make y-galvo waveform:
            fullwv = repmat(y/ao_chan_max_volts , [1 dur*task_periods_per_ms]); % 2 sec
            if delay>0
                fullwv=[0*ones(1, delay) fullwv];
            end;
            schedWv_YGalvo1 = [fullwv; zeros([1 numel(fullwv)])];

        case {'depblock'} % for every 100 ms, the first 10 ms laser targts M1, the next 90 ms laser targets S1
            Nalter_cycles=floor(dur*Testfreq/1000); % number of cycles
            tmove=1000/Testfreq-3;  % this is how long the mirror stays at S1 location
            singlex=[repmat(-.25, [1 3*task_periods_per_ms]) repmat(x/ao_chan_max_volts, [1 tmove*task_periods_per_ms])];

            fullwv = repmat(singlex , [1 Nalter_cycles]); % 2 sec
            if delay>0
                fullwv=[-0.25*ones(1, delay-2*task_periods_per_ms) fullwv];
            end;
            schedWv_XGalvo1 = [fullwv; zeros([1 numel(fullwv)])];

            %------------------------
            % Make y-galvo waveform:

            singley=[repmat(0, [1 3*task_periods_per_ms]) repmat(y/ao_chan_max_volts, [1 tmove*task_periods_per_ms])];
            fullwv = repmat(singley , [1 Nalter_cycles]); % 2 sec
            if delay>0
                fullwv=[0*ones(1, delay-2*task_periods_per_ms) fullwv];
            end;
            schedWv_YGalvo1 = [fullwv; zeros([1 numel(fullwv)])];
            
        case {'collision'}
            
            onsetdelay=(500+5+1)*task_periods_per_ms;
            stepdur=100*task_periods_per_ms;
            offdur=400*task_periods_per_ms;
            
            singlex=[repmat(x/ao_chan_max_volts, [1 stepdur]) repmat(-.25, [1 offdur])];
            fullwv_x=[repmat(-.25, [1 onsetdelay]) repmat(singlex, [1 6])];
            fullwv_x=[fullwv_x repmat(-.25, [1 dur*task_periods_per_ms-length(fullwv_x)])];
                
            schedWv_XGalvo1=[fullwv_x; zeros(1, length(fullwv_x))];

            singley=[repmat(y/ao_chan_max_volts, [1 stepdur]) repmat(0, [1 offdur])];
            fullwv_y=[repmat(0, [1 onsetdelay]) repmat(singley, [1 6])];
            fullwv_y=[fullwv_y repmat(0, [1 dur*task_periods_per_ms-length(fullwv_y)])];
            
            schedWv_YGalvo1=[fullwv_y; zeros(1, length(fullwv_y))];

        otherwise
            return;
    end;
else
    % Make x-galvo waveform:
    fullwv = repmat(-.25, [1 delay+stimdur*task_periods_per_ms]); % 2 sec
    schedWv_XGalvo1 = [fullwv; zeros([1 numel(fullwv)])];

    %------------------------
    % Make y-galvo waveform:
    fullwv = zeros([1 delay+stimdur*task_periods_per_ms]); % 2 sec
    schedWv_YGalvo1 = [fullwv; zeros([1 numel(fullwv)])];
end;

%------------------------
% Make AOM 473nm waveform:
% **** IMPORTANT: stim_dur_473 in globals.c MUST BE SET TO MATCH THE DURATION OF THIS WAVE****
% THIS IS A HACK TO COMPENSATE FOR COMEDI INABILITY TO CALIBRATE BOARD PROPERLY. THIS IS CURRENTLY
% DONE BY THE BCONTROL PROTOCOL.
%

if ismember(next_trial_type,{'Go','Nogo'})
    on = repmat(ao_offset, [1 floor(stim_pulse_dur_in_ms*task_periods_per_ms)]); % Dummy; for 'Go','Nogo', this doesn't matter since no stim is given anyway
else
    on = repmat(ao_chan_aom_on*Normfactor+ao_offset, [1 floor(stim_pulse_dur_in_ms*task_periods_per_ms)]);
end;
off = repmat(ao_offset, [1 floor(stim_pulse_ISI*task_periods_per_ms)]);

fullwv = [];

for i_pulse = 1:stim_num_pulse
    fullwv = cat(2,fullwv,on);
    fullwv = cat(2,fullwv,off);
end

if delay>0
    fullwv=[ao_offset*ones(1, delay) fullwv];
end;

%
if strcmp(StimType, 'depblock') && ~ismember(next_trial_type,{'Go','Nogo'})
    % test pulse duration is 2 ms
    on2 = repmat(ao_chan_aom_on+ao_offset, [1 floor(2*task_periods_per_ms)]);
    news_stim_pulse_ISI=1000/testfreq-2;
    off2 = repmat(ao_offset, [1 floor((news_stim_pulse_ISI)*task_periods_per_ms)]);
    test_num_pulse = floor(stim_pulse_dur*testfreq/1000);
    fullwvtest=[];
    for i_testpulse=1:test_num_pulse
        fullwvtest = cat(2,fullwvtest,on2);
        fullwvtest = cat(2,fullwvtest,off2);
    end;

    if delay>0
        fullwvtest=[ao_offset*ones(1, delay-2.5*task_periods_per_ms) fullwvtest];
    end;

    fullwv=[ao_offset*ones(1, .5*task_periods_per_ms) fullwv];
    fullwvtest=[fullwvtest ao_offset*ones(1, .5*task_periods_per_ms)];
    fullwv=fullwv(1:length(fullwvtest));
    coin=rand;
    if coin>0.5

        fullwv=max([fullwv; fullwvtest], [], 1);

    else
        fullwv=fullwvtest;
    end;

end;

if ramp>0
    vramp=ones(1, length(fullwv));
    tn=[0:length(fullwv)-1];
    tpeak=ramp; % 500 ms
    tpeak_num=tpeak*task_periods_per_ms;
    vramp(delay:tpeak_num+delay)=(tn(delay:delay+tpeak_num)-delay)*1/tpeak_num;
    vramp(tn>=tpeak_num+delay)=1;
    fullwv=fullwv.*vramp;
end;

fullwv=[fullwv(end-task_periods_per_ms+1:end) fullwv(1:end-task_periods_per_ms)]; % give the laser 1 ms delay

if strcmp(StimType, 'collision') && ~ismember(next_trial_type,{'Go','Nogo'}) % collision test 
    
    fullwv=[repmat(ao_offset, [1 500*task_periods_per_ms]) repmat(ao_chan_aom_on*Normfactor+ao_offset, [1, 5*task_periods_per_ms]),... % first M1 pulse
        repmat(ao_offset, [1 1*task_periods_per_ms]) repmat(ao_chan_aom_on*Normfactor+ao_offset, [1, 5*task_periods_per_ms]),... % first S1 pulse, 1ms following m1pulse
        repmat(ao_offset, [1 (500-11)*task_periods_per_ms]) repmat(ao_chan_aom_on*Normfactor+ao_offset, [1, 5*task_periods_per_ms]),...   % second m1 pulse         
        repmat(ao_offset, [1 2*task_periods_per_ms]) repmat(ao_chan_aom_on*Normfactor+ao_offset, [1, 5*task_periods_per_ms]),...% second s1 pulse, 2 ms following
        repmat(ao_offset, [1 (500-12)*task_periods_per_ms]) repmat(ao_chan_aom_on*Normfactor+ao_offset, [1, 5*task_periods_per_ms]),... % 3rd m1 pulse
        repmat(ao_offset, [1 5*task_periods_per_ms]) repmat(ao_chan_aom_on*Normfactor+ao_offset, [1, 5*task_periods_per_ms]),...% 3rd s1 pulse, 5 ms following
        repmat(ao_offset, [1 (500-15)*task_periods_per_ms]) repmat(ao_chan_aom_on*Normfactor+ao_offset, [1, 5*task_periods_per_ms]),... % 4th m1 pulse
        repmat(ao_offset, [1 10*task_periods_per_ms]) repmat(ao_chan_aom_on*Normfactor+ao_offset, [1, 5*task_periods_per_ms]),... % 4th s1 pulse, 10ms following
        repmat(ao_offset, [1 (500-20)*task_periods_per_ms]) repmat(ao_chan_aom_on*Normfactor+ao_offset, [1, 5*task_periods_per_ms]),...% 5th m1 pulse
        repmat(ao_offset, [1 20*task_periods_per_ms]) repmat(ao_chan_aom_on*Normfactor+ao_offset, [1, 5*task_periods_per_ms]),... % 5th s1 pulse, 20 ms following
        repmat(ao_offset, [1 (500-30)*task_periods_per_ms]) repmat(ao_chan_aom_on*Normfactor+ao_offset, [1, 5*task_periods_per_ms]),...% 6th m1 pulse
        repmat(ao_offset, [1 50*task_periods_per_ms]) repmat(ao_chan_aom_on*Normfactor+ao_offset, [1, 5*task_periods_per_ms])% 6th s1 pulase, 50 ms following
        ];
    
    fullwv=[fullwv repmat(ao_offset, [1, dur*task_periods_per_ms-length(fullwv)])];
end;

schedWv_AOM473nm1 = [fullwv; stim_event_record_chan zeros([1 numel(fullwv)-1])];

% plot the wave:
hf=figure(100); clf(hf); set(hf, 'Position', [1100 500 400 400])
ha1=subplot(2, 1, 1);set(gca, 'xlim', [0 stim_pulse_dur*1.2], 'ylim', [-.1 .6], 'nextplot', 'add');

twav=[0:size(schedWv_AOM473nm1, 2)-1]/6; % 6 point per ms
plot(twav, schedWv_AOM473nm1(1, :));

title('laser AOM')
xlabel('ms')
ylabel('AOM473')

ha2=subplot(2, 1, 2);set(gca, 'xlim', [0 stim_pulse_dur*1.2],'nextplot', 'add');

twav=[0:size(schedWv_XGalvo1, 2)-1]/6; % 6 point per ms
plot(twav, schedWv_XGalvo1(1, :), 'm');
plot(twav, schedWv_YGalvo1(1, :), 'g');

xlabel('ms')
ylabel('X Galvo')

linkaxes([ha1, ha2], 'x')

%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Set analog scheduled waves:
AOLoop = 0;
machine = SetScheduledWaves(machine, wave_id_masking_flash_blue, AO_chan_masking_flash_blue, AOLoop, schedWv_MaskFlash1);
machine = SetScheduledWaves(machine, wave_id_x_galvo, AO_chan_x_galvo, AOLoop, schedWv_XGalvo1);
machine = SetScheduledWaves(machine, wave_id_y_galvo, AO_chan_y_galvo, AOLoop, schedWv_YGalvo1);
machine = SetScheduledWaves(machine, wave_id_aom_473, AO_chan_aom_473, AOLoop, schedWv_AOM473nm1);

% Set digital scheduled waves:
DoSimpleCmd(machine,'SET DIO SCHED WAVE NUM COLUMNS 9'); %New FSMServer command "SET DIO SCHED WAVE NUM COLUMNS n" where n must be one of 8, 9, 10, or 11. The 9th col is for looping, 10th for triggering other sched waves, 11 for untriggering other sched waves. To allow looping. Put this somewhere else, doesn't need to be called every trial.
machine = SetScheduledWaves(machine, digSchedWvAll); % digital scheduled waves.

