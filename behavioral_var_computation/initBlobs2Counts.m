
% The result of running blob2timeSeries is a 9 column csv, one row per (sampled) frame. The columns
% are:
%         1 f, frame number
%         2 numActiveThisFrame, ratio of expected ants which are active
%         3 meanSpeedActiveThisFrame, mean speed of the active ants
%         4 meanSpeedAllThisFrame, mean speed of all the ants
%         5 allworkersThisF, distance among every pair of workers (not with queen)
%         6 activeworkersThisF, distance among pairs of active workers
%         7 queenThisF, mean distance of all ants to the queen
%         8 meanToClosestThisF, mean distance of each ant to its closes ant
%         9 q,  the ID of the queen
%
% To plot mean speed of all ants, use:
%    plot(TS(:,1),TS(:,4),'x-')


projectName=params.project_name;
videoFileName=params.path_video_file;
video_start=params.video_start;
ants_counted=params.ants_counted;
msdthr=params.msd_threshold; 
speedThreshold=params.speedThreshold; % [mm / s]
singlethr=params.single_threshold; %[sqmm]
samplePeriodForTimeseries=params.fps/3;

%%  --------------- S T A R T -------------------------------
%   ---------------------------------------------------------
close all
%% ------- LOADING FILES
%Correct video_start
% I noted down a frame t, and FERDA used t+1 as video_start_t
v=VideoReader(videoFileName);
video_start=video_start+1;

resulDir=params.path_FERDA_output;
resetCount=0;

% Load file with arena info
load(strcat(resulDir,'arena.mat'));

% Load or create info file
infopath=strcat(resulDir,'info.mat');   
if (exist(infopath,'file')==0)
    % ask user to supply info (foraging arena, number of ants, petri size, etc)  
    INFO = getInfo(arena,v,video_start,params);
    save(infopath,'INFO','videoFileName','video_start');
    useRegions = 1; %a while ago we were using contours instead.
end
load(infopath);

% Load instance of class 'tracks'
load(strcat(resulDir,'object.mat'))
if resetCount==1
    disp('Resetting counts ')
    tic
    trx=trx.reset_counter();
    toc
end
trx.pathToParts=resulDir;

%% Check arena, and give a change to modify
if resume == 0
    % Print first frame ff
    ff=1;
    arena=modify_arena(arena,trx,v,video_start,ff);
    INFO.cx=arena.cx;
    INFO.cy=arena.cy;
    INFO.radius=arena.radius;
    save(strcat(resulDir,'arena.mat'),'arena')
end

%% Get some data we need out of said file
listAlive=trx.listAlivePerFrame;
trx.numFramesTotal
totframes=trx.numFramesTotal;
singles = find(trx.types==1);
single_areas = double(trx.mean_areas(singles));
single_mean=mean(single_areas);
single_sd=std(single_areas);


%% ------- GET SPURIOUS CONTOURS
% find frame with largest number of detections
pfdetections=cellfun(@length,listAlive);
[max_num,max_f]=max(pfdetections);
if resume == 0
    fprintf('please click on spurious detections \n')
    [trx , clicked]= initialize(trx,max_f,v,listAlive,video_start,'MARK SPURIOUS',INFO);
    [spuX,spuY]=getSpuriousContours(trx,clicked)
else
    spuX = [];
    spuY = [];
end
% save spuX spuY!!!Sep25


%% Queens
% annotate queen tracklet
[trx] = mark_queen(trx,v,listAlive,video_start,single_mean,INFO,spuX,spuY,resume);
save(strcat(resulDir,'object.mat'),'trx');

num_expected=INFO.nexpected;
%intensity_thr=automaticTresholdEstimation(trx,v,video_start,single_mean,arena);
intensity_thr=trySeveralThresholdsOnOneFrame(v,trx,arena,single_mean,single_sd, num_expected,video_start)


save(strcat(resulDir,'blob_parameters.mat'),'msdthr','singlethr','intensity_thr','single_mean','single_sd','speedThreshold','samplePeriodForTimeseries');
trx=trx.save_currentpart();
save(strcat(resulDir,'object.mat'),'trx');
save(infopath,'INFO','videoFileName','video_start');


        