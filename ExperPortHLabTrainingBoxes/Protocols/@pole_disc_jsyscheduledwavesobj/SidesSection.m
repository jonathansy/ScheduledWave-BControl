% [x, y] = SidesSection(obj, action, x, y)
%
% Section that takes care of choosing the next correct side and keeping
% track of a plot of sides and hit/miss history.
%
% PARAMETERS:
% -----------
%
% obj      Default object argument.
%
% action   One of:
%            'init'      To initialise the section and set up the GUI
%                        for it; also calls 'choose_next_side' and
%                        'update_plot' (see below)
%
%            'reinit'    Delete all of this section's GUIs and data,
%                        and reinit, at the same position on the same
%                        figure as the original section GUI was placed.
%
%            'choose_next_side'  Picks what will be the next correct
%                        side. 
%
%            'get_next_side'  Returns either 'l' for left or 'r' for right.
%
%            'update_plot'    Update plot that reports on sides and hit
%                        history
%
% x, y     Relevant to action = 'init'; they indicate the initial
%          position to place the GUI at, in the current figure window
%
% RETURNS:
% --------
%
% [x, y]   When action == 'init', returns x and y, pixel positions on
%          the current figure, updated after placing of this section's GUI. 
%
% x        When action = 'get_next_side', x will be either 'l' for
%          left or 'r' for right.
%

function [x, y] = SidesSection(obj, action, x, y)
   
   GetSoloFunctionArgs;
   
   switch action
    
    case 'init',   % ------------ CASE INIT ----------------
      % Save the figure and the position in the figure where we are
      % going to start adding GUI elements:
      SoloParamHandle(obj, 'my_gui_info', 'value', [x y gcf]);

      % List of intended correct sides
      SoloParamHandle(obj, 'previous_sides', 'value', []);
      
      % Give read-only access to AnalysisSection.m:
      SoloFunctionAddVars('AnalysisSection', 'ro_args', 'previous_sides');
      
      
      % 'Auto trainer' max # of FAs
      NumeditParam(obj, 'autotrain_max_fas', 0, x, y, 'label', ...
          'AutoTrain max FAs'); 
      next_row(y);
      
      NumeditParam(obj, 'autotrain_min_crs', 3, x, y, 'label', ...
          'AutoTrain min CRs'); 
      next_row(y);
      
      % For trackin # of CRs and FAs in row ...
      SoloParamHandle(obj, 'num_consecutive_fas', 'value', 0);
      SoloParamHandle(obj, 'num_consecutive_crs', 'value', 0);
      SoloParamHandle(obj, 'autotraining', 'value', 0); % 1 if in autotran

            
      % Max number of times same side can appear
      MenuParam(obj, 'MaxSame', {'1' '2' '3' '4' '5' '6' '7' '8' 'Inf'}, ...
                '3', x, y);
      next_row(y);
      % Prob of choosing left as correct side
      NumeditParam(obj, 'NoGoProb', 0.5, x, y); 
      next_row(y, 1);

      SubheaderParam(obj, 'sidestitle', 'Go trial probability', x, y);
      next_row(y);

      pos = get(gcf, 'Position');
      SoloParamHandle(obj, 'myaxes', 'saveable', 0, 'value', axes);
      set(value(myaxes), 'Units', 'pixels');
      set(value(myaxes), 'Position', [90 pos(4)-140 pos(3)-130 100]);
      set(value(myaxes), 'YTick', [1 2], 'YLim', [0.5 2.5], 'YTickLabel', ...
                        {'Go', 'No-go'});
      NumeditParam(obj, 'ntrials', 100, x, y, ...
                   'position', [5 pos(4)-100 40 40], 'labelpos', 'top', ...
                   'TooltipString', 'How many trials to show in plot');
      set_callback(ntrials, {mfilename, 'update_plot'});      
      xlabel('trial number');
      SoloParamHandle(obj, 'previous_plot', 'saveable', 0);
      
      SidesSection(obj, 'choose_next_side');
      SidesSection(obj, 'update_plot');
      
      
      
    case 'choose_next_side', % --------- CASE CHOOSE_NEXT_SIDE -----
      % 108/l : nogo ; 114/r: go
        
      % Is autotrainer on? if so, that means only nogo allowed
      if (value(autotraining) == 1) 
          next_side = 'l';
          disp('AUTOTRAINER ON -- only nogos.');
      else
          % If MaxSame doesn't apply yet, choose at random
          if strcmp(value(MaxSame), 'Inf') | MaxSame > n_started_trials,
             if rand(1)<=NoGoProb, next_side = 'l'; else next_side = 'r'; end;
          else 
             % MaxSame applies, check for its rules:
             % If there's been a string of MaxSame guys all the same, force change:
             if all(previous_sides(n_started_trials-MaxSame+1:n_started_trials) == ...
                    previous_sides(n_started_trials))
                if previous_sides(n_started_trials)=='l', next_side = 'r';
                else                                      next_side = 'l';
                end;
             else
                % Haven't reached MaxSame limits yet, choose at random:
                if rand(1)<=NoGoProb, next_side = 'l'; else next_side = 'r'; end;
             end;
          end;
      end
      

    %  session_type = SessionTypeSection(obj,'get_session_type'); 
      switch SessionType
          
          case {'Licking','Pole-conditioning'}
            next_side = 'r'; % Make it always the go-trial position, so mouse doesn't have to unlearn anything.
      end

      previous_sides(n_started_trials+1) = next_side;


      
    case 'get_next_side',   % --------- CASE GET_NEXT_SIDE ------
      if isempty(previous_sides),
         error('Don''t have next side chosen! Did you run choose_next_side?');
      end;
      x = previous_sides(length(previous_sides));
      return;
      
    case 'reinit',   % ------- CASE REINIT -------------
      currfig = gcf; 

      % Get the original GUI position and figure:
      x = my_gui_info(1); y = my_gui_info(2); figure(my_gui_info(3));

      delete(value(myaxes));
      
      % Delete all SoloParamHandles who belong to this object and whose
      % fullname starts with the name of this mfile:
      delete_sphandle('owner', ['^@' class(obj) '$'], ...
                      'fullname', ['^' mfilename]);

      % Reinitialise at the original GUI position and figure:
      [x, y] = feval(mfilename, obj, 'init', x, y);

      % Restore the current figure:
      figure(currfig);      
   end;
   
   
      