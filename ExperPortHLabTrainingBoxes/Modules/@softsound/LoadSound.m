function [sm] = LoadSound(sm, trignum, sound, side, tau_ms, predelay_s)

   if nargin<6, predelay_s = 0; end;
   
   % note: we ignore tau_ms -- it is only provided for
   % compatibility with RTLSoundMachine
   if nargin<5, tau_ms = 0; end;
   
   if (tau_ms ~= 0), 
     warning(['Tau_ms ignored in softsm::LoadSound(),' ...
              ' it is only provided for compatibility with' ...
              ' the RTLSoundMachine!']); 
   end;
   
   
   if nargin<4, side = 'both'; end;
   mydata = get(sm.myfig, 'UserData');

   if (size(sound,1) > 2 | size(sound,1) < 1),
       error('Sound file must be 1xN or 2xN for stereo!!');
   end;
   
   % pad the predelay_s with zeroes...
   nsamps = predelay_s * mydata.samplerate;
   sound = horzcat(zeros(size(sound,1), nsamps), sound);

   if (trignum < 0), trignum = -trignum; end;
   
   if ~ismember(trignum, mydata.allowed_trigs),
      error(['trignum must be one of ' sprintf('%d ',mydata.allowed_trigs)]);
   end;

   if strcmp(side, 'both'),
     mydata.(['sound' num2str(trignum)]) = sound;
     set(sm.myfig, 'UserData', mydata);
     return;
   end;
   
   olddata = mydata.(['sound' num2str(trignum)]);
   olddata = rowize(olddata); sound = rowize(sound);
   if size(sound,1) > 1, 
      error('Can''t load single side sound with a stereo sound');
   end;

   switch side,
    case 'left',
     if size(olddata,1) < 2, % didn't have stereo previously
        nd = [sound; zeros(size(sound))]; 
     else
        if length(sound) ~= length(olddata), nd=[sound ; zeros(size(sound))];
        else                                 nd=[sound ; olddata(2,:)];
        end;
     end;
        
    case 'right',
     if size(olddata,1) < 2, % didn't have stereo previously
        nd = [zeros(size(sound)) ; sound]; 
     else
        if length(sound) ~= length(olddata), nd=[zeros(size(sound)) ; sound];
        else                                 nd=[olddata(1,:)       ; sound];
        end;
     end;
       
    otherwise, error(['Don''t know hot to do this side ' side]);
   end;

   mydata.(['sound' num2str(trignum)]) = nd;      
   set(sm.myfig, 'UserData', mydata);
   return;
   
   
   
   
% -----------------                   
                   
function [s] = rowize(s)
                   
   if size(s,1) > size(s,2), s = s'; end;
   