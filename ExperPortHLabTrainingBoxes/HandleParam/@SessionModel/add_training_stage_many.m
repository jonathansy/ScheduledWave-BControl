function [obj] = add_training_stage_many(obj, in_train_set)
%
% Batch method to add multiple training stages at once.
% in_train_set should be an r-by-3 cell array, each row of which defines a
% training stage *** in the order in which SessionModel will evaluate them
% ***.
% see "add_training_stage.m" for the description of each row of this cell
% array.

% error-checking
if cols(in_train_set) < 3 | cols(in_train_set) > 5,
    error('The set of training stages should have either 3, 4, or 5 columns: the training stage string, the string to test for completion, whether the stage was previously completed, the stage name and the vars for the stage');
elseif ~iscell(in_train_set),
    error('The set of training stages should be a cell array with three cols');
end;

if cols(in_train_set) == 3 % convert
    for k = 1:rows(in_train_set)
        obj = add_training_stage(obj, ...
            'train_string', in_train_set{k,obj.train_string_COL}, ...
            'complete_test', in_train_set{k, obj.completion_test_COL}, ...
            'is_complete', in_train_set{k, obj.is_complete_COL}, ...
            'name', 'unnamed');
    end;
elseif cols(in_train_set) == 4
    % test and add each training stage without vars
    for k = 1:rows(in_train_set),
        obj = add_training_stage(obj, ...
            'train_string', in_train_set{k,obj.train_string_COL}, ...
            'complete_test', in_train_set{k, obj.completion_test_COL}, ...
            'is_complete', in_train_set{k, obj.is_complete_COL}, ...
            'name', in_train_set{k, obj.name_COL});
    end;
elseif cols(in_train_set) == 5
    % test and add each training stage WITH vars
    for k = 1:rows(in_train_set),
        obj = add_training_stage(obj, ...
            'train_string', in_train_set{k,obj.train_string_COL}, ...
            'complete_test', in_train_set{k, obj.completion_test_COL}, ...
            'is_complete', in_train_set{k, obj.is_complete_COL}, ...
            'name', in_train_set{k, obj.name_COL}, ...
            'vars', in_train_set{k, obj.vars_COL});
    end;
end;
