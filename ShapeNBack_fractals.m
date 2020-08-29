% % % % % % % % % % % % % % % % % % % % % % % % % 
% n-back task after Jaeggi et al. 2010
% Author: Pin-Chun Chen
% Apr 2019
% % % % % % % % % % % % % % % % % % % % % % % % % 
function ShapeNBack_fractals
try
    Screen('Preference', 'SkipSyncTests', 1); 
    % Preliminary stuff
    % Clear Matlab/Octave window:
    clc;
    
    % Reseed randomization
    rand('state', sum(100*clock));
    
    % check for Opengl compatibility, abort otherwise:
    AssertOpenGL;
    
    % General information about subject and session
    subNo = input('Subject #: '); %e.g. 999
    visitNo = input('Visit #: ');   
    sessionNo = input('Session #: ');   
    date  = str2num(datestr(now,'yyyymmdd'));
    time  = str2num(datestr(now,'HHMMSS'));
    
    % Get information about the screen and set general things
    Screen('Preference', 'SuppressAllWarnings',0);
    Screen('Preference', 'SkipSyncTests', 0);
    screens       = Screen('Screens');
    if length(screens) > 1
        error('Multi display mode not supported.');
    end
    rect          = Screen('Rect',0);
    screenRatio   = rect(3)/rect(4);
    pixelSizes    = Screen('PixelSizes', 0);
    startPosition = round([rect(3)/2, rect(4)/2]);
    HideCursor;
    
    % Experimental variables
    % Number of trials etc.
    if sessionNo==999 %run practice
        lowestLevel         = 1; % n
        highestLevel        = 3;
        numOfBlocks         = 1;
        targetsPerBlock     = 6;
        nonTargetsPerBlock  = 14; % + n
        trialsPerBlock      = []; % Number of trials for a block per level
        nTrial              = []; % Total number of trials per level
        % Output files
        datafilename = strcat('results/nBackPrac_',num2str(subNo),'_','Visit',num2str(visitNo),'_','Session',num2str(sessionNo),'.dat'); % name of data file to write to
        mSave        = strcat('results/nBackPrac_',num2str(subNo),'_','Visit',num2str(visitNo),'_','Session',num2str(sessionNo),'.mat'); % name of another data file to write to (in .mat format)
        mSaveALL     = strcat('results/nBackPrac_',num2str(subNo),'_','Visit',num2str(visitNo),'_','Session',num2str(sessionNo),'_all.mat'); % name of another data file to write to (in .mat format)
        xSave        = strcat('results/nBackPrac_',num2str(subNo),'_','Visit',num2str(visitNo),'_','Session',num2str(sessionNo),'.xls'); % name of another data file to write to (in .xls format)
        % Checks for existing result file to prevent accidentally overwriting
        % files from a previous subject/session (except for subject numbers > 99):
        if subNo<99 && fopen(datafilename, 'rt')~=-1
            fclose('all');
            error('Result data file already exists! Choose a different subject number.');
        else
            datafilepointer = fopen(datafilename,'wt'); % open ASCII file for writing
        end
    else
        lowestLevel         = 2; % n
        highestLevel        = 4;
        numOfBlocks         = 3;
        targetsPerBlock     = 6;
        nonTargetsPerBlock  = 14; % + n
        trialsPerBlock      = []; % Number of trials for a block per level
        nTrial              = []; % Total number of trials per level
        % Output files
        datafilename = strcat('results/nBack_',num2str(subNo),'_','Visit',num2str(visitNo),'_','Session',num2str(sessionNo),'.dat'); % name of data file to write to
        mSave        = strcat('results/nBack_',num2str(subNo),'_','Visit',num2str(visitNo),'_','Session',num2str(sessionNo),'.mat'); % name of another data file to write to (in .mat format)
        mSaveALL     = strcat('results/nBack_',num2str(subNo),'_','Visit',num2str(visitNo),'_','Session',num2str(sessionNo),'_all.mat'); % name of another data file to write to (in .mat format)
        xSave        = strcat('results/nBack_',num2str(subNo),'_','Visit',num2str(visitNo),'_','Session',num2str(sessionNo),'.xls'); % name of another data file to write to (in .xls format)
        % Checks for existing result file to prevent accidentally overwriting
        % files from a previous subject/session (except for subject numbers > 99):
        if subNo<99 && fopen(datafilename, 'rt')~=-1
            fclose('all');
            error('Result data file already exists! Choose a different subject number.');
        else
            datafilepointer = fopen(datafilename,'wt'); % open ASCII file for writing
        end
    end
    
    for n = lowestLevel:highestLevel
        trialsPerBlock(n) = nonTargetsPerBlock + targetsPerBlock + n;
        nTrial(n)         = trialsPerBlock(n)*numOfBlocks;
    end
    totalNTrial        = sum(nTrial);
    
    % Temporal variables
    ISI                 = 2.5;
    stimDuration        = 0.5;
    
    % Experimental data
    RT                  = zeros(1, totalNTrial)-99;
    response            = zeros(1, totalNTrial)+99;
    correctness         = zeros(1, totalNTrial)+99; % Hit = 1, False alarm =  2, Miss =  3,  Correct rejection = 4
    results             = cell(totalNTrial, 14); % SubNo, date, time, trial, stim, level, block, rightAnswer, response, correctness, RT, StimulusOnsetTime1, StimulusEndTime1, trial length
    
    % Colors
    %bgColor             = [255 255 255];
    bgColor             = [0 0 0];
    
    % Creating screen etc.
    try
        Screen('Preference', 'SkipSyncTests', 1); 
        [myScreen, rect]    = Screen('OpenWindow', 0, bgColor);
    catch
        try
            [myScreen, rect]    = Screen('OpenWindow', 0, bgColor);
        catch
            try
                [myScreen, rect]    = Screen('OpenWindow', 0, bgColor);
            catch
                try
                    [myScreen, rect]    = Screen('OpenWindow', 0, bgColor);
                catch
                    [myScreen, rect]    = Screen('OpenWindow', 0, bgColor);
                end
            end
        end
    end
    center              = round([rect(3) rect(4)]/2);
    
    % Keys and responses
    KbName('UnifyKeyNames');
    space               = KbName('space');
    right_control       = KbName('l');
    numberKeys          = [KbName('1!') KbName('2@') KbName('3#') KbName('4$') KbName('5%') KbName('6^')];
    
    % Loading stimuli and making texture
    [trialList, levels, blocks] = nBackCreateTrialList(lowestLevel, highestLevel,trialsPerBlock ,targetsPerBlock, numOfBlocks);
    images              = {};
    stimuli             = {};
    for i = 1:10
        images{i}  = imread(strcat('stimuli/stim_',num2str(i),'.jpeg'));
        stimuli{i} = Screen('MakeTexture', myScreen, images{i});
    end
    
    % Message for introdution
    lineLength   = 70; % Sets the maximal length of each line (in characters) to ensure a block text. 
    messageIntro = WrapString('N-Back \n\n In this task, you will see a sequence of figures appearing one after another in the center of the computer screen. The presentation rate is quite fast, there is a new figure every 3 seconds. The task is to decide if the current figure is exactly the same as the one presented N trials ago. \n\n For example, if you are asked to do a 2-back, you have to press the key "L" each time the current shape is exactly the same as the one presented before last (i.e. 2 positions back in the sequence). Otherwise, press the "A" key. The task starts easy and ends difficultly. \n\n You can take a short break after each block, and there are instructions for each block telling you which task you have to do (2, 3 or 4 back). Please try to work as accurately as possible.\n\n Please press the spacebar to continue.',lineLength);
    
    % Experimental loop
    for trial = 1:length(trialList)
        % Block and n-back information
        if trial == 1 % Shows introduction
            DrawFormattedText(myScreen, messageIntro, 'center', 'center',[255 255 255]);
            Screen('Flip', myScreen);
            [responseTime, keyCode] = KbWait;
            while keyCode(space) == 0
                [responseTime, keyCode] = KbWait;
            end
        end
        if trial == 1 || levels(trial) ~= levels(trial-1) || blocks(trial) ~= blocks(trial-1)
           if levels(trial) == 1 && blocks(trial) == 1
               % Instruction for block
               % Example array: 1 8 9 9 10 3
               % Correct answer = 4 (button press)
               exampleArray_img  = imread(strcat('stimuli/example_',num2str(levels(trial)),'.jpeg'));
               exampleArray_size = size(exampleArray_img);
               exampleArray_tex  = Screen('MakeTexture', myScreen, exampleArray_img);
               introResponse   = 4;
               messageBlockInfo         =  WrapString(horzcat( 'Block #', num2str(blocks(trial)),', N = ', num2str(levels(trial)),'.\n In this condition, you need to press the "L" key when the current figure has been shown ', num2str(levels(trial)),' trials before. Below is an example series of stimuli, as they could be presented individually in the experiment. Use the numbers at the top of the keyboard to indicate where in the experiment you would need to press the "L" key.'),lineLength);
               DrawFormattedText(myScreen, messageBlockInfo, 'center', 'center');
               Screen('DrawTexture', myScreen, exampleArray_tex, [] , round([center(1) - exampleArray_size(2)/2 rect(4)*0.8 - exampleArray_size(1)/2 center(1) + exampleArray_size(2)/2 rect(4)*0.8 + exampleArray_size(1)/2]));
                
               Screen('Flip', myScreen);
               WaitSecs(0.5);
               [~, keyCode] = KbWait;
               while keyCode(numberKeys(introResponse)) == 0
                    [~, keyCode] = KbWait;
               end
               
               % Start block
               DrawFormattedText(myScreen, horzcat('Block ', num2str(blocks(trial)),'. To start the block, please press the spacebar.'), 'center', 'center');
               Screen('Flip', myScreen);
               WaitSecs(0.5);
               [~, keyCode] = KbWait;
               while keyCode(space) == 0
                    [~, keyCode] = KbWait;
               end
           elseif levels(trial) == 2 && blocks(trial) == 1
               % Instruction for block
               % Example array: 4 8 9 7 4 7
               % Correct answer = 6 (button press)
               exampleArray_img  = imread(strcat('stimuli/example_',num2str(levels(trial)),'.jpeg'));
               exampleArray_size = size(exampleArray_img);
               exampleArray_tex  = Screen('MakeTexture', myScreen, exampleArray_img);
               introResponse     = 6;
               messageBlockInfo         =  WrapString(horzcat( 'Block #', num2str(blocks(trial)),', N = ', num2str(levels(trial)),'.\n In this condition, you need to press the "L" key when the current figure has been shown ', num2str(levels(trial)),' trials before. Otherwise, press the "A" key. Below is an example series of stimuli, as they could be presented individually in the experiment. Use the numbers at the top of the keyboard to indicate where in the experiment you would need to press the "L" key.'),lineLength);
               DrawFormattedText(myScreen, messageBlockInfo, 'center', 'center');
               Screen('DrawTexture', myScreen, exampleArray_tex, [] , round([center(1) - exampleArray_size(2)/2 rect(4)*0.8 - exampleArray_size(1)/2 center(1) + exampleArray_size(2)/2 rect(4)*0.8 + exampleArray_size(1)/2]));
                
               Screen('Flip', myScreen);
               WaitSecs(0.5);
               [~, keyCode] = KbWait;
               while keyCode(numberKeys(introResponse)) == 0
                    [~, keyCode] = KbWait;
               end
               
               % Start block
               DrawFormattedText(myScreen, horzcat('Block ', num2str(blocks(trial)),'. To start the block, please press the spacebar.'), 'center', 'center');
               Screen('Flip', myScreen);
               WaitSecs(0.5);
               [~, keyCode] = KbWait;
               while keyCode(space) == 0
                    [~, keyCode] = KbWait;
               end
           elseif levels(trial) == 3 && blocks(trial) == 1
               % Instruction for block
               % Example array: 8 6 1 8 7 2
               % Correct answer = 4 (button press)
               exampleArray_img  = imread(strcat('stimuli/example_',num2str(levels(trial)),'.jpeg'));
               exampleArray_size = size(exampleArray_img);
               exampleArray_tex  = Screen('MakeTexture', myScreen, exampleArray_img);
               introResponse     = 4;
               messageBlockInfo         =  WrapString(horzcat( 'Block #', num2str(blocks(trial)),', N = ', num2str(levels(trial)),'.\n In this condition, you need to press the "L" key when the current figure has been shown ', num2str(levels(trial)),' trials before. Otherwise, press the "A" key. Below is an example series of stimuli, as they could be presented individually in the experiment. Use the numbers at the top of the keyboard to indicate where in the experiment you would need to press the "L" key.'),lineLength);
               DrawFormattedText(myScreen, messageBlockInfo, 'center', 'center');
               Screen('DrawTexture', myScreen, exampleArray_tex, [] , round([center(1) - exampleArray_size(2)/2 rect(4)*0.8 - exampleArray_size(1)/2 center(1) + exampleArray_size(2)/2 rect(4)*0.8 + exampleArray_size(1)/2]));
                
               Screen('Flip', myScreen);
               WaitSecs(0.5);
               [~, keyCode] = KbWait;
               while keyCode(numberKeys(introResponse)) == 0
                    [~, keyCode] = KbWait;
               end
               
               % Start block
               DrawFormattedText(myScreen, horzcat('Block ', num2str(blocks(trial)),'. To start the block, please press the spacebar.'), 'center', 'center');
               Screen('Flip', myScreen);
               WaitSecs(0.5);
               [responseTime, keyCode] = KbWait;
               while keyCode(space) == 0
                    [responseTime, keyCode] = KbWait;
               end
           elseif levels(trial) == 4 && blocks(trial) == 1
               % Instruction for block
               % Example array: 10 9 8 8 10 6
               % Correct answer = 5 (button press)
               exampleArray_img  = imread(strcat('stimuli/example_',num2str(levels(trial)),'.jpeg'));
               exampleArray_size = size(exampleArray_img);
               exampleArray_tex  = Screen('MakeTexture', myScreen, exampleArray_img);
               introResponse     = 5;
               messageBlockInfo         =  WrapString(horzcat( 'Block #', num2str(blocks(trial)),', N = ', num2str(levels(trial)),'.\n In this condition, you need to press the "L" key when the current figure has been shown ', num2str(levels(trial)),' trials before. Otherwise, press the "A" key. Below is an example series of stimuli, as they could be presented individually in the experiment. Use the numbers at the top of the keyboard to indicate where in the experiment you would need to press the "L" key.'),lineLength);
               DrawFormattedText(myScreen, messageBlockInfo, 'center', 'center');
               Screen('DrawTexture', myScreen, exampleArray_tex, [] , round([center(1) - exampleArray_size(2)/2 rect(4)*0.8 - exampleArray_size(1)/2 center(1) + exampleArray_size(2)/2 rect(4)*0.8 + exampleArray_size(1)/2]));
                
               Screen('Flip', myScreen);
               WaitSecs(0.5);
               [~, keyCode] = KbWait;
               while keyCode(numberKeys(introResponse)) == 0
                    [~, keyCode] = KbWait;
               end
               
               % Start block
               DrawFormattedText(myScreen, horzcat('Block ', num2str(blocks(trial)),'. To start the block, please press the spacebar.'), 'center', 'center');
               Screen('Flip', myScreen);
               WaitSecs(0.5);
               [~, keyCode] = KbWait;
               while keyCode(space) == 0
                    [~, keyCode] = KbWait;
               end
           else 
               % Start block
               DrawFormattedText(myScreen, horzcat('Block ', num2str(blocks(trial)),'. To start the block, please press the spacebar.'), 'center', 'center');
               Screen('Flip', myScreen);
               WaitSecs(0.5);
               [~, keyCode] = KbWait;
               while keyCode(space) == 0
                    [~, keyCode] = KbWait;
               end
           end
        end
        startOfTrial = GetSecs;
        
        % Stimulus presentation
        Screen('DrawTexture', myScreen, stimuli{trialList(1,trial)});
        [VBLTimestamp StimulusOnsetTime1] = Screen('Flip', myScreen);
        % Response recording
        [keyIsDown, responseTime1, keyCode] = KbCheck; % saves whether a key has been pressed, seconds and the key which has been pressed.
        while keyCode(right_control) == 0 
            [keyIsDown, responseTime1, keyCode] = KbCheck;
            if responseTime1 - StimulusOnsetTime1 >= stimDuration
                [VBLTimestamp StimulusEndTime1]  = Screen('Flip', myScreen);
                if responseTime1 - StimulusOnsetTime1 >= stimDuration + ISI
                    break
                end
            end
        end
        
        if responseTime1 - StimulusOnsetTime1 < stimDuration
            WaitSecs(stimDuration - (responseTime1 - StimulusOnsetTime1));
            [VBLTimestamp StimulusEndTime1]  = Screen('Flip', myScreen); 
        end

        % Checking correctness
        if keyCode(right_control) == 1
            RT(trial) = (responseTime1 - StimulusOnsetTime1)*1000; % Converts to milliseconds
            response(trial) = 1;
            if trialList(2, trial) == 1
                correctness(trial) = 1; % Hit
            else
                correctness(trial) = 2; % False Alarm
            end
        else
            response(trial) = 0;
            if trialList(2, trial) == 1
                correctness(trial) = 3; % Miss
            else
                correctness(trial) = 4; % Correct rejection
            end
        end
        t2 = GetSecs;
        % Presenting blank screen for remaining time
        if t2 - StimulusEndTime1 < ISI
            WaitSecs(ISI - (t2 - StimulusEndTime1));
        end
        
        % SubNo, date, time, trial, stim, level, block, rightAnswer,
        % response, correctness, RT, StimulusOnsetTime1, StimulusEndTime1,
        % trial length
        endOfTrial = GetSecs;
        fprintf(datafilepointer,'%i %i %i %i %i %i %i %i %i %i %f %f %f %f\n', ...
            subNo, ...
            visitNo, ...
            date, ...
            time, ...
            trial, ...
            trialList(1,trial), ...
            levels(trial), ...
            blocks(trial), ...
            trialList(2, trial), ...
            response(trial),...
            correctness(trial),...
            RT(trial),...
            (StimulusOnsetTime1-startOfTrial)*1000,... % Calculating stimulus onset time
            (StimulusEndTime1-startOfTrial)*1000,...
            (endOfTrial-startOfTrial)*1000);   
        
        results{trial, 1}  = subNo;
        results{trial, 2}  = visitNo;
        results{trial, 3}  = date;
        results{trial, 4}  = time;
        results{trial, 5}  = trial;
        results{trial, 6}  = trialList(1,trial);
        results{trial, 7}  = levels(trial);
        results{trial, 8}  = blocks(trial);
        results{trial, 9}  = trialList(2, trial);%Correct answers
        results{trial, 10}  = response(trial);%Subject answers
        results{trial, 11} = correctness(trial);%Hit:1 %False Alarm:2 %Miss:3 %Correct rejection:4
        results{trial, 12} = RT(trial);
        results{trial, 13} = (StimulusOnsetTime1-startOfTrial)*1000;
        results{trial, 14} = (StimulusEndTime1-startOfTrial)*1000;
        results{trial, 15} = (endOfTrial-startOfTrial)*1000;
    end
    save(mSave, 'results');
    save(mSaveALL);
    xlswrite(xSave, results);  
    Screen('CloseAll')
    fclose('all')
catch
    rethrow(lasterror)
    Screen('CloseAll')
    save(mSave, 'results');
    save(mSaveALL);
    xlswrite(xSave, results);
    fclose('all')
end
end
% Changes:
% 4. Mapping der response keys?
% Response time?