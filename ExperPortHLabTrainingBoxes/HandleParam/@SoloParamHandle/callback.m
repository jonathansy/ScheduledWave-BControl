function [] = callback(sph, varargin)
% This gets called from the GUI. Thus, at this point in programming, the
% GUI handle has simply generated the callback; the internal
% paramater is still unchanged. This function should sync up the internal
% parameter to whatever the GUI says.

pairs = { ...
    'internal_cbk', 0 ;
    };
parse_knownargs(varargin, pairs);

global private_soloparam_list;

switch get_type(sph),
    case 'edit',
        private_soloparam_list{sph.lpos}.value = get(get_ghandle(sph), 'String');

    case 'textbox',
        private_soloparam_list{sph.lpos}.value = get(get_ghandle(sph), 'String');

    case 'numedit',
        d = str2double(get(get_ghandle(sph), 'String'));
        if isnan(d),
            private_soloparam_list{sph.lpos}.value = value(sph);
        else
            private_soloparam_list{sph.lpos}.value = d;
        end;

    case 'disp', return;

    case 'menu',
        menulist = get(get_ghandle(sph), 'String');
        private_soloparam_list{sph.lpos}.value = ...
            menulist{get(get_ghandle(sph), 'Value')};

    case 'listbox',
        boxlist = get(get_ghandle(sph), 'String');
        private_soloparam_list{sph.lpos}.value = ...
            boxlist{get(get_ghandle(sph), 'Value')};

    case 'pushbutton',

    case 'solotoggler',
        if ~internal_cbk,
            currval = value(private_soloparam_list{sph.lpos});
            if currval, private_soloparam_list{sph.lpos}.value = 0;
            else        private_soloparam_list{sph.lpos}.value = 1;
            end;
        end;

    case 'slider',
        private_soloparam_list{sph.lpos}.value = get(get_ghandle(sph), 'Value');

    case 'logslider',
        gval  = get(get_ghandle(sph), 'Value');
        mmin  = get(get_ghandle(sph), 'Min');
        mmax  = get(get_ghandle(sph), 'Max');
        % Interpret GUI as a number linearly scaled in graphics between 0
        % and 1:
        gval = (gval - mmin)/(mmax - mmin);

        % Now turn it into log scale.
        private_soloparam_list{sph.lpos}.value = mmin*exp(gval*log(mmax/mmin));

    case 'saveable_nonui',
        % do nothing
    case '',
        % Not a GUI: may not have any callbacks associated with it and
        % therefore we return and do nothing.
        return;

    otherwise,
        error(['Don''t know how to deal with type ' get_type(sph)]);
end;

% If owned by object:
%   (a) check to see if 'callback' property is not empty; if so,
%       calls that function, with an embty obj as param
%   (b) elseif, a function with the name of the SoloParam exists,
%       calls that, with empty obj as param
%   (c) else does nothing.
%
% Elseif, if not owned by an object -- not defined yet
%

owner = get_owner(sph);
if ~isempty(owner), % Are we owned (i.e., by an object)?
    cbck = get_callback(private_soloparam_list{sph.lpos});
    if owner(1) == '@'  &&  ...
            (~isempty(cbck) || ...
            exist([owner filesep get_name(sph) '.m'], 'file')),

        % Ok, there is a callback fn to be called; try to make empty object
        try
            obj = feval(owner(2:end),  'empty');
        catch
            fprintf(2, ['When a SoloParamHandle is owned by an object, ' ...
                'that object must allow constuction with a single '...
                ' (''empty'') argument\n']);
            rethrow(lasterror)
        end;

        % We have an object!
        parse_and_call_sph_callback(obj, owner, get_name(sph), cbck)
    end;
end;


