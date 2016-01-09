%% Creates plot of lick probability vs. pole position using mouse whisking data
% Created 2014-12-4 by J. Sy
% Version 0.1, unfortunately I'm going to be hardcoding variables in here,
% less lazy versions to follow
% Future additions: input options for array name, bin size (currently
% hard-coded for 18 bins)

motorPositionDat = cell2mat(saved_history.MotorsSection_motor_position); %Note: I coded this at home from memory, please check if correct matrix spelling 
totalTrials = numel(motorPositionDat); %Do I need this???
lickingArray = lickArrayMaker(saved_history); %Uses lickArrayMaker code I wrote to make a matrix of whether a lick occurs

motorPosBins = 10000:10000:180000; %Makes bins 

lickProb = zeros(1,18);
for motorPosIndex = 1:18; %Loop command for each bin 
    motorRangeStart = motorPosIndex*10000 - 10000; % Subtract 10,000 so as to start at 0 and go by increments of 10,000
    motorRangeEnd = motorPosIndex*10000; 
    trialsInRangeArray = (motorPositionDat >= motorRangeStart & motorPositionDat < motorRangeEnd);  
    trialsInRange = sum(trialsInRangeArray);
    
    
    licksInRangeArray = zeros(1,totalTrials);
    for lickIndex = 1:totalTrials; %Loop command for all trials, forms array with all licks that occur within specified range
        if (lickingArray(lickIndex) == 1) && (motorPositionDat(lickIndex) >= motorRangeStart) && (motorPositionDat(lickIndex) < motorRangeEnd)
            licksInRangeArray(lickIndex) = 1;
        else licksInRangeArray(lickIndex) = 0; 
        end 
    end 
    licksInRange = sum(licksInRangeArray); 
    
    lickProb(motorPosIndex) = licksInRange/trialsInRange;
end 

lickPercent = 100*lickProb; 

scatter(motorPosBins,lickPercent) % Crude scatterplot, note that axes will not quite be accurate, since they'll be listed by the last value in the range, not the range itself)
