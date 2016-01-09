function [] = make_and_upload_state_matrix(obj, action)

GetSoloFunctionArgs;


switch action
 case 'init'
   clear global autosave_session_id;
   SoloParamHandle(obj, 'state_matrix');
   
   SoloParamHandle(obj, 'RealTimeStates', 'value', struct(...
     'wait_for_startlick', 0, ...  
     'poles_descend_and_sample', 0, ...  
     'wait_for_answerlick', 0, ... 
     'reward',  0, ...
     'extra_iti', 0,...
     'miss',0, ...
     'correct_nogo', 0, ...
     'poles_ascend', 0, ...
     'airpuff',0));
 
   SoloFunctionAddVars('RewardsSection', 'ro_args', 'RealTimeStates');
   
   make_and_upload_state_matrix(obj, 'next_matrix');

   return;
   
 case 'next_matrix',
   % SAVE EVERYTHING before anything else is done!
   %autosave(value(MouseName));
   SavingSection(obj, 'autosave');
   
   % ----------------------------------------------------------------------
   % - Set parameters used in matrix:
   % ----------------------------------------------------------------------
   
   % DHO origianl
%    wvid = 2^0; % water valve
%    LEDid = 2^1; % lickport LED
% %    snd1 = 2^2; % ID of audio noise.
% %    snd2 = 2^3; % ID of low tone.
% %    snd3 = 2^2 + 2^3; % ID of high tone.
%    puffid = 2^4; % Airpuff valve ID.
%    pvid = 2^5; % Pneumatic (Festo) valve ID.
%    cmid = 2^7; % AOS hi speed camera trigger ID. 
%    etid = 2^3; % EPHUS (electrophysiology) trigger ID.
%    slid = 2^2; % Signal line for signaling trial numbers and fiducial marks.

   % Settings S. Peron
   wvid = 2^6; % water valve
   LEDid = 2^1; % lickport LED
   puffid = 2^3; % Airpuff valve ID.
   pvid = 2^2; % Pneumatic (Festo) valve ID.
   etid = 2^4; % EPHUS (electrophysiology) trigger ID.
   slid = 2^5; % Signal line for signaling trial numbers and fiducial marks.
   cmid = 2^7; % AOS hi speed camera trigger ID. 
   
   wvtm = WaterValveTime; % Defined in ValvesSection.m.  
   
   % Compute answer period time as 2 sec minus SamplingPeriodTime (from TimesSection.m) , 
   % unless SamplingPeriodTime is > 1 s (for training purposes), in which case it is 1 sec.
   % MOVED THIS PART TO TIMESECTION. - NX 4/9/09
      
      
      
   % program starts in state 40
   stm = [0 0  40 0.01  0 0];
   stm = [stm ; zeros(40-rows(stm), 6)];
   stm(36,:) = [35 35  35 1   0 0];
   b = rows(stm); 

   RealTimeStates.wait_for_startlick = b; 
   RealTimeStates.poles_descend_and_sample = b+1;
   RealTimeStates.wait_for_answerlick = b+2;
   RealTimeStates.reward = b+3;
   RealTimeStates.extra_iti = b+5;
   RealTimeStates.miss = b+6;
   RealTimeStates.correct_nogo = b+7;
   RealTimeStates.poles_ascend = b+8;
   RealTimeStates.airpuff = b+9;                             
   
   next_side = SidesSection(obj, 'get_next_side');
   
   % ----------------------------------------------------------------------
   % - Build matrix:
   % ----------------------------------------------------------------------
   switch SessionType % determined by SessionTypeSection
        
      case 'Water-Valve-Calibration'
             % On beam break (eg, by hand), trigger ndrops water deliveries
             % with delay second delays.
             ndrops = 100; delay = 1;
             openvalve = [b+1 b+1 b+2 wvtm wvid 0]; 
             closevalve = [b+1 b+1 b+2 delay 0 0];
             onecycle = [openvalve; closevalve];
             m = repmat(onecycle, ndrops, 1);    
             x = [repmat((0:(2*ndrops-1))',1,3) zeros(2*ndrops,3)];
             m = m+x; m = [b+1 b 35 999 0 0; m];
             m(end,3) = 35; stm = [stm; m];
             
       case 'Licking'
           onlk1 = RealTimeStates.reward(1);
           %Cin Cout Tup  Tim   Dou Aou  (Dou is bitmask format)
           stm = [stm ;
               onlk1   b    35  5    0     0  ; ... % wait for lick  (This is state 40)
               b+1   b+1    35  1      0     0  ; ... % irrelevant
               b+2   b+2    35  1      0     0  ; ... % irrelevant
               b+3   b+3    35  wvtm  wvid   0  ; ... % reward
               ];
           
       case 'Beam-Break-Indicator'
             %Cin   Cout   Tup  Tim  Dou   Aou  (Dou is bitmask format)
           stm = [stm ;
               b+1   b      35  999  0      0  ; ...
               b+1   b      35  999  LEDid  0  ; ...  
               ];
           
           %        case 'Discrim'
           %             onlk1 = RealTimeStates.poles_descend_and_sample(1);
           %             if next_side=='r' % Defined as side w/ pole closest to mouse
           %                 onlk2 = RealTimeStates.reward(1);
           %                 tmout = RealTimeStates.miss(1);
           %             else
           %                 onlk2 = RealTimeStates.airpuff(1);
           %                 tmout = RealTimeStates.correct_nogo(1);
           %             end
           %
           %             stm = [stm ;
           %                 b    b     b+1  .5   0   0  ; ... %
           %                 b+1   b+1  b+2 sptm  pvid+cmid 0  ; ... % trigger camera, wait for poles to descend, wait duration of sampling period.
           %                 onlk2 onlk2  tmout aptm   pvid   0  ; ... % wait for lick for aptm seconds.
           %                 b+3   b+3  b+4  wvtm  pvid+wvid 0  ; ... % reward tone + water - HIT
           %                 b+4   b+4  b+8  2-wvtm  pvid 0  ; ... % Give 3 s drinking time.
           %                 b+9   b+5  b+8  eiti  pvid   0 ; ... % incorrect lick, extra ITI - FALSE ALARM
           %                 b+6   b+6  b+8  .001    pvid    0  ; ... % didn't lick before timeout - MISS
           %                 b+7   b+7  b+8  .001    pvid    0  ; ... % correct nogo.
           %                 b+8   b+8  35    .75       0    0  ; ... % raise poles by unsetting pvid, then go state 35 for new trial
           %                 b+9   b+9  b+5  pfdr    pvid+puffid   0 ; ... % FALSE ALARM. Second extra ITI state, to retrigger extra ITI.
           %                 ];
           %
       case 'Pole-conditioning'
           sptm = SamplingPeriodTime;  % Defined in TimesSection.m
           prmv = PoleRetractTime; % time for pole to be removed, defined in TimesSection.
           aptm = value(AnswerPeriodTime); % Defined in TimesSection.m
           onlk1 = RealTimeStates.reward(1);
           supp_iti = 2;     % supplementary ITI, if time up for licking
           %Cin     Cout   Tup   Tim   Dou Aou  (Dou is bitmask format)
           stm = [stm ;
               %b   b      35  999       0     0  ; ... % wait for lick  (This is state 40)
               b     b     b+1   sptm    pvid     0  ; ... % whisker sensing state. sptm should be greater than 0.2 for the pole to descend
               b+1   b+1   b+2   prmv    0        0; ...  %  pole remove state.
               onlk1 onlk1 b+5    aptm    0          0  ; ... % remove the pole and wait for lick for aptm seconds
               b+3   b+3   b+4   wvtm    wvid       0  ; ... % reward tone + water - HIT
               b+4   b+4   35    3        0        0;  ... % Drinking time. Animal can drink also in ITI.
               b+5   b+5   35    supp_iti 0        0   ... % supplementary ITI, if time up for licking
              ];

       case 'Discrim_DHO' % Task designed to replicate Dan O'Connor's task for his physiology paper
           disp('made it to discrim')
           pfdr = 0.2; % Duration of airpuff.
           eiti = max(.01,ExtraITIOnError); % Defined in TimesSection.m.
           sptm = SamplingPeriodTime;  % Defined in TimesSection.m.
           
           prepause = PreTrialPauseTime; % before dropping pole ; s
           postpause = PostTrialPauseTime ; % before next trial ; s
           
           if value(SamplingPeriodTime)>1
               aptm = 1;
           else
               aptm = 2 - value(SamplingPeriodTime);
           end
           AnswerPeriodTime.value = aptm;
           
           onlk1 = RealTimeStates.poles_descend_and_sample(1);
           if next_side=='r' % 'r' means a go trial.
               onlk2 = RealTimeStates.reward(1);
               tmout = RealTimeStates.miss(1);
           else
               onlk2 = RealTimeStates.airpuff(1);
               tmout = RealTimeStates.correct_nogo(1);
           end
           
           stm = [stm ;
               %Cin Cout    Tup   Tim       Dou Aou  (Dou is bitmask format)
               b     b      101   .01       etid   0  ; ... % trigger camera and EPHUS; 10 ms later jump to state 101 to give trial num bit code.
               b+1   b+1    b+2   sptm      pvid        0  ; ... % wait for poles to descend, wait duration of sampling period.
               onlk2 onlk2  tmout aptm      pvid        0  ; ... % wait for lick for aptm seconds.
               b+3   b+3    b+4   wvtm      pvid+wvid   0  ; ... % reward tone + water - HIT
               b+4   b+4    b+8   2-wvtm    pvid        0  ; ... % Drinking time.
               b+9   b+5    b+8   eiti      pvid        0 ; ... % incorrect lick, extra ITI - FALSE ALARM
               b+6   b+6    b+8  .001       pvid        0  ; ... % didn't lick before timeout - MISS
               b+7   b+7    b+8  .001       pvid        0  ; ... % correct nogo.
               b+8   b+8    35    postpause 0           0  ; ... % raise poles by unsetting pvid, then go state 35 for new trial
               b+9   b+9    b+5   pfdr      pvid+puffid 0 ; ... % FALSE ALARM. Second extra ITI state, to retrigger extra ITI.
               b+10  b+10   b+1   prepause  0           0 ; ... % FALSE ALARM. Second extra ITI state, to retrigger extra ITI.
               ];
           
           %------ Signal trial number on digital output given by 'slid':
           % Requires that states 101 through 101+2*numbits be reserved
           % for giving bit signal.
           
           trialnum = n_done_trials + 1;
           
           %             trialnum = 511; %63;
           % Should maybe make following 3 SPHs in State Machine Control
           % GUI:
           bittm = 0.002; % bit time
           gaptm = 0.005; % gap (inter-bit) time
           numbits = 10; %2^10=1024 possible trial nums
           
           
           x = double(dec2binvec(trialnum)');
           if length(x) < numbits
               x = [x; repmat(0, [numbits-length(x) 1])];
           end
           % x is now 10-bit vector giving trial num, LSB first (at top).
           x(x==1) = slid;
           
           % Insert a gap state between bits, to make reading bit pattern clearer:
           x=[x zeros(size(x))]';
           x=reshape(x,numel(x),1);
           
           y = (101:(100+2*numbits))';
           t = repmat([bittm; gaptm],[numbits 1]);
           m = [y y y+1 t x zeros(size(y))];
           m(end,3) = b+10; % jump back to state that triggers pole descent.
           
           stm = [stm; zeros(101-rows(stm),6)];
           stm = [stm; m];
           
           % AOS camera now does *not* need to save pre-trigger buffer.
           % Alternatively, if AOS camera can record signal events during
           % pretrial buffer, then maybe better to trigger with
           % pre-trigger buffer in order to make sure that
           % pre-pole-descent record time doesn't vary when trial signal
           % code is changed.
           %
           % Maybe put slid high at end of trial too to get fiducial marks
           % for clock slip correction.
       case 'Detection_SP' % Task more tailored to imaging with, e.g., pre-pauses for F_0 collection
           % ---- assign gui variables
           ap_t = value(AnswerPeriodTime);
           sp_t = SamplingPeriodTime;
           eto_t = max(.01,ExtraITIOnError);
           pr_t = PoleRetractTime;
           pa_t = PreAnswerTime;
           prep_t = PreTrialPauseTime;
           postp_t = PostTrialPauseTime;
           
           puff_t = AirpuffTime;
           water_t = WaterValveTime; % Defined in ValvesSection.m.  
           
           % puff disabled? can't have 0 time or RT freaks; set valve id
           % off instead
           if (puff_t == 0)
               puff_t = 0.01;
               puffid = 0;
           end
           
           % Adjust prepause based on bitcode, initial trigger
           prep_t = prep_t - 0.01 - 0.07; % 2 ms bit, 5 ms interbit, 10 bits
       
           % Adjust extra time out basd on airpuf tmie
           eto_t = eto_t - puff_t;
           eto_t = max(eto_t,.01);
           
           % trial-type dependent variables
           if next_side=='r' % 'r' means a go trial.
               onlick = RealTimeStates.reward(1); % reward water (b+3 should bE)
               on_nolick = RealTimeStates.miss(1); % log miss (shuold be b+6)
           else
               onlick = RealTimeStates.airpuff(1); % puff (b+9)
               on_nolick = RealTimeStates.correct_nogo(1); % log correct reject (b+7)
           end  
           

           stm = [stm ;
               %CinSt   CoutSt TimeupSt Time       Dou        Aou  (Dou is bitmask format)
               % line b: trigger camera, ephus 10 ms, then bitcode
               b        b      101      .01        cmid+etid  0 ; ...
           ... % b+1: pole move and sampling period
               b+1      b+1    b+10     pr_t+sp_t  pvid       0 ; ...
           ... % b+2: answer period
               onlick  onlick on_nolick ap_t       0          0 ; ...
           ... % b+3: water valve open ; done afer this
               b+3      b+3    b+8     water_t     wvid       0 ; ...
           ... % b+4: prepause - bitcode brings yuo here
               b+4      b+4    b+1     prep_t      0          0 ; ...
           ... % b+5: extra timeout after airpuff
               b+9      b+5    b+8     eto_t       0          0 ; ...
           ... % b+6: log the miss
               b+6      b+6    b+8     0.001       0          0 ; ...
           ... % b+7: log correct rejectino
               b+7      b+7    b+8     0.001       0          0 ; ...
           ... % b+8: final step - wait posttrial pause and then 35
               b+8      b+8    35      postp_t     0          0 ; ...
           ... % b+9: airpuff
               b+9      b+9    b+5     puff_t      puffid     0 ; ...
           ... % b+10: preanswer pause - no pole, but also no answr
               b+10     b+10   b+2     pr_t+pa_t   0          0 ; ...
               ];
          
           
           %------ Signal trial number on digital output given by 'slid':
           % Requires that states 101 through 101+2*numbits be reserved
           % for giving bit signal.
           
           trialnum = n_done_trials + 1;
           
           %             trialnum = 511; %63;
           % Should maybe make following 3 SPHs in State Machine Control
           % GUI:
           bittm = 0.002; % bit time
           gaptm = 0.005; % gap (inter-bit) time
           numbits = 10; %2^10=1024 possible trial nums
           
           
           x = double(dec2binvec(trialnum)');
           if length(x) < numbits
               x = [x; repmat(0, [numbits-length(x) 1])];
           end
           % x is now 10-bit vector giving trial num, LSB first (at top).
           x(x==1) = slid;
           
           % Insert a gap state between bits, to make reading bit pattern clearer:
           x=[x zeros(size(x))]';
           x=reshape(x,numel(x),1);
           
           y = (101:(100+2*numbits))';
           t = repmat([bittm; gaptm],[numbits 1]);
           m = [y y y+1 t x zeros(size(y))];
           m(end,3) = b+4; % jump back to PREPAUSE.
           
           stm = [stm; zeros(101-rows(stm),6)];
           stm = [stm; m];
           
      case 'Detection_SP_leaveUp' % Detection_SP that leaves pole in reach during reward
           % ---- assign gui variables
           ap_t = value(AnswerPeriodTime);
           sp_t = SamplingPeriodTime;
           eto_t = max(.01,ExtraITIOnError);
           pr_t = PoleRetractTime;
           pa_t = PreAnswerTime;
           prep_t = PreTrialPauseTime;
           postp_t = PostTrialPauseTime;
           
           puff_t = AirpuffTime;
           water_t = WaterValveTime; % Defined in ValvesSection.m.  
           
           % puff disabled? can't have 0 time or RT freaks; set valve id
           % off instead
           if (puff_t == 0)
               puff_t = 0.01;
               puffid = 0;
           end
           
           % Adjust prepause based on bitcode, initial trigger
           prep_t = prep_t - 0.01 - 0.07; % 2 ms bit, 5 ms interbit, 10 bits
       
           % Adjust extra time out basd on airpuf tmie
           eto_t = eto_t - puff_t;
            eto_t = max(eto_t,.01);
            
           % trial-type dependent variables
           if next_side=='r' % 'r' means a go trial.
               onlick = RealTimeStates.reward(1); % reward water (b+3 should bE)
               on_nolick = RealTimeStates.miss(1); % log miss (shuold be b+6)
           else
               onlick = RealTimeStates.airpuff(1); % puff (b+9)
               on_nolick = RealTimeStates.correct_nogo(1); % log correct reject (b+7)
           end  
           

           stm = [stm ;
               %CinSt   CoutSt TimeupSt Time       Dou        Aou  (Dou is bitmask format)
               % line b: trigger camera, ephus 10 ms, then bitcode
               b        b      101      .01        cmid+etid  0 ; ...
           ... % b+1: pole move and sampling period
               b+1      b+1    b+10     pr_t+sp_t  pvid       0 ; ...
           ... % b+2: answer period
               onlick  onlick on_nolick ap_t       pvid          0 ; ...
           ... % b+3: water valve open ; done afer this
               b+3      b+3    b+8     water_t     wvid+pvid       0 ; ...
           ... % b+4: prepause - bitcode brings yuo here
               b+4      b+4    b+1     prep_t      0          0 ; ...
           ... % b+5: extra timeout after airpuff
               b+9      b+5    b+8     eto_t       pvid          0 ; ...
           ... % b+6: log the miss
               b+6      b+6    b+8     0.001       0          0 ; ...
           ... % b+7: log correct rejectino
               b+7      b+7    b+8     0.001       0          0 ; ...
           ... % b+8: final step - wait posttrial pause and then 35
               b+8      b+8    35      postp_t     0          0 ; ...
           ... % b+9: airpuff
               b+9      b+9    b+5     puff_t      puffid+pvid     0 ; ...
           ... % b+10: preanswer pause - pole, but also no answr
               b+10     b+10   b+2     pr_t+pa_t   pvid          0 ; ...
               ];
          
           
           %------ Signal trial number on digital output given by 'slid':
           % Requires that states 101 through 101+2*numbits be reserved
           % for giving bit signal.
           
           trialnum = n_done_trials + 1;
           
           %             trialnum = 511; %63;
           % Should maybe make following 3 SPHs in State Machine Control
           % GUI:
           bittm = 0.002; % bit time
           gaptm = 0.005; % gap (inter-bit) time
           numbits = 10; %2^10=1024 possible trial nums
           
           
           x = double(dec2binvec(trialnum)');
           if length(x) < numbits
               x = [x; repmat(0, [numbits-length(x) 1])];
           end
           % x is now 10-bit vector giving trial num, LSB first (at top).
           x(x==1) = slid;
           
           % Insert a gap state between bits, to make reading bit pattern clearer:
           x=[x zeros(size(x))]';
           x=reshape(x,numel(x),1);
           
           y = (101:(100+2*numbits))';
           t = repmat([bittm; gaptm],[numbits 1]);
           m = [y y y+1 t x zeros(size(y))];
           m(end,3) = b+4; % jump back to PREPAUSE.
           
           stm = [stm; zeros(101-rows(stm),6)];
           stm = [stm; m];
           
       case 'FlashLED'
           
           timeon = 1;
           timeoff = 1;
              %Cin   Cout   Tup  Tim     Dou Aou  (Dou is bitmask format)
           stm = [stm;
               b     b      b+1  timeoff  0      0  ; ...
               b+1   b+1    b    timeon   1  0  ; ...
               ];
       case 'testOutputs'
           
           timeon = 1;
           timeoff = 1;
           stm = [stm;
               b     b      b+1    2    0      0  ; ...
               b+1   b+1    b+2    .1   1  0  ; ...
               b+2   b+2    b+3    .2   2  0  ; ...
               b+3   b+3    b+4    .3   4  0  ; ...
               b+4   b+4    b+5    .4   8  0  ; ...
               b+5   b+5    b+6    .5   16  0  ; ...
               b+6   b+6    b+7    .6   32  0  ; ...
               b+7   b+7    b+8    .7   64  0  ; ...
               b+8   b+8    b      .8   0  0  ; ...
               ];
       otherwise
           error('Invalid training session type')
   end
   
   stm = [stm; zeros(512-rows(stm),6)];
   
   
   rpbox('send_matrix', stm);
   state_matrix.value = stm;
   return;

   
 case 'reinit',
      % Delete all SoloParamHandles who belong to this object and whose
      % fullname starts with the name of this mfile:
      delete_sphandle('owner', ['^@' class(obj) '$'], ...
                      'fullname', ['^' mfilename]);

      % Reinitialise 
      feval(mfilename, obj, 'init');
   
   
 otherwise
   error('Invalid action!!');
   
end;

   