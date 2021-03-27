% 1. Initialize a tracks object with types for singles, spurious and queens
%    (possibly converting formats), this involves user interaction in
%    several stages
% 2. scp the resulting mats to
%        clusterEntryHost:clusterWorkingDirectory/projectName/copy_for_cluster
%    along with a gridengine-ready sh file to
%        clusterEntryHost:clusterMatlabDirectory
% 3. qsub said sh file, which results in the
%    blob->conunts->timeSeries calculations being performed
%
%  !IMPORTANT:  THE VIDEOS CAN ONLY BE IN /fs3/home/casillas  IF THE
%  CLUSTER IS TO BE USED.
% Copy mat back to local /copy_for_cluster  with:
% ACHTUNG (do not copy to parent folder since this is the only place where original FERDA mat will be!!)
% scp casillas@bjoern22.ista.local:/cluster/home/casillas/COLONIESWD/PROJECTNAME+ WD/copy_for_cluster/*mat .
% Afterwards, get the csv files with:
%   scp casillas@bjoern22.ista.local:/cluster/home/casillas/COLONIESWD/PROJECTNAME/copy_for_cluster/*csv .
% And concatenate with:
%   cat *csv > timeSeries.csv    (in the above directory)
% The result is a 9 column csv, one row per (sampled) frame. The columns
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


%% CHANGE PARAMETERS HERE
%                             * Will be overiden if object was initialized
%                               in cluster.
msdthr=1.3; % in mm^2   *
singlethr=1.8; %area mm^2     *

speedThreshold=5; % [mm / s]
samplePeriodForTimeseries=6;  %How often will we take a frame to sample (5 , 6 for T6 & up !!!)
sizeParts=10;
%/cluster/home/casillas changed to /nfs/scistore12/cremegrp/casillas
clusterVideoDirectory='/fs3/home/casillas/ColonyExperiment'; 
clusterWorkingDirectory = '/nfs/scistore12/cremegrp/casillas/FINCOLWD/';
clusterEntryHost = 'casillas@bea81.ista.local' % previously casillas@bjoern22.ista.local
clusterMatlabDirectory = '/nfs/scistore12/cremegrp/casillas/colony_analysis/';
clusterCommand = 'sbatch'; %qsub previously
doJobSubmission = 1;    % 0 <--- TO TEST   !!!!!!!!!!!!!!!!!
runLocally = 0; % Set to 1 to run small tests locally. Will only work if doJobSubmission == 0
resume = 0;  %set to different than 0 to resume the current project after error

%Testing syats
%clusterWorkingDirectory = '/home/syats/barbara/tmpCluster/';y
%clusterEntryHost = 'syats@192.168.0.10';
%clusterMatlabDirectory = '/home/syats/barbara/tmpCluster/matlab';
%clusterCommand = 'nohup sh'

% projectName='S9T9WD' %83 ants % % works not so well with margin 3 int 50-80
% videoFileName='/fs3/home/casillas/ColonyExperiment/Film9/21.07.15/Camera 1.avi';
% video_start=500;

% projectName='C15T9'; %39 ants % works reasonably well with margin 3 int 50-80 (64/100 frames, all detected)
%                               % %(mean undetected over 100 frames 1.7%, max undetected 15%)
% videoFileName='/fs3/home/casillas/ColonyExperiment/Film9/21.07.15/Camera 3.avi';
% video_start=432670;

% projectName='S3T1'; %10 ants % works fine with margin 4 int 60-80
% videoFileName='/fs3/home/casillas/ColonyExperiment/Film1/12.09.14-1/Camera 1.avi';
% video_start=180700;

%  projectName='S18T1'; %20 ants % works fine with margin 4 int 60-80
%  videoFileName='/fs3/home/casillas/ColonyExperiment/Film1/15.09.14/Camera 1.avi';
%  video_start=580;

workingDir ='/home/casillas/Documents/COLONIESWD/missing_part2/';
%workingDir ='/fs3/home/casillas/COLONIESWD/T4/';
suffix = ''; %  'WD' or '',    Must match the directory created by FERDA

% Read projectName, videoFileName and video_start from metadatafile.
md=readtable(strcat(workingDir,'metadata_missing_part2.csv'));

mn=1;
projectName=char(strcat(md.projectName(mn)))

videoFileName=char(strcat(clusterVideoDirectory,(md.videoFileName(mn))));
%videoFileName=char(strcat('/run/user/10251/gvfs/smb-share:server=istsmb3.ist.local,share=casillas/ColonyExperiment',(md.videoFileName(mn))));
video_start=md.video_start(mn);
ants_counted=md.ants_counted(mn)

%%  --------------- S T A R T -------------------------------
%   ---------------------------------------------------------
close all
%% ------- LOADING FILES
%Correct video_start
% I noted down a frame t, and FERDA used t+1 as video_start_t
v=VideoReader(videoFileName);
video_start=video_start+1;

% NOTE: if partsDir == resulDir then part*.mat will be overwritten with trx,
% ie FERDA will disappear
partsDir=strcat(workingDir,projectName); % WD for T1
resulDir=strcat(workingDir,projectName,'/copy_for_cluster/'); %WD for T1
resetCount=0;

% Load file with arena info
load(strcat(resulDir,'arena.mat'));

% Load or create info file
infopath=strcat(resulDir,'info.mat');   
if (exist(infopath,'file')==0)
    % ask user to supply info (foraging arena, number of ants, petri size, etc)  
    INFO = getInfo(arena,v,video_start);
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


%% For cluster
if doJobSubmission == 1
    videoFileName=char(strcat(clusterVideoDirectory,(md.videoFileName(mn)))); %accessible in cluster
    writeShFileForClusterSlurm(clusterWorkingDirectory,projectName,resulDir,clusterMatlabDirectory,numel(trx.numTracksPerPart),suffix);
    disp('copying files, stand by.... ');
    rs01 = sprintf('ssh  %s mkdir %s%s%s',clusterEntryHost,clusterWorkingDirectory,projectName,suffix);
    rs02 = sprintf('ssh  %s mkdir %s%s%s/copy_for_cluster/',clusterEntryHost,clusterWorkingDirectory,projectName,suffix);
    system(rs01);
    system(rs02);
    rs1 = sprintf('scp -q %sobject.mat %s:%s%s%s/copy_for_cluster/',strrep(resulDir,' ','\ '),clusterEntryHost,clusterWorkingDirectory,projectName,suffix)
    system(rs1);
    rs1 = sprintf('scp -q %sinfo.mat %s:%s%s%s/copy_for_cluster/',strrep(resulDir,' ','\ '),clusterEntryHost,clusterWorkingDirectory,projectName,suffix)
    system(rs1);
    rs1 = sprintf('scp -q %sarena.mat %s:%s%s%s/copy_for_cluster/',strrep(resulDir,' ','\ '),clusterEntryHost,clusterWorkingDirectory,projectName,suffix)
    system(rs1);
    rs1 = sprintf('scp -q %sblob_parameters.mat %s:%s%s%s/copy_for_cluster/',strrep(resulDir,' ','\ '),clusterEntryHost,clusterWorkingDirectory,projectName,suffix)
    system(rs1);
    rs2 = sprintf('scp %ssubmitBlobs* %s:%s',strrep(resulDir,' ','\ '),clusterEntryHost,clusterMatlabDirectory)
    system(rs2);
    disp('files copied ');
    disp('enqueing ');
    rs3 = sprintf('ssh %s "%s %ssubmitBlobs_%s.sh "',clusterEntryHost,clusterCommand,clusterMatlabDirectory,projectName);
    disp(rs3);
    system(rs3);
else
    %% For running in local machine
    if runLocally==1
        for parn = 1:numel(trx.numTracksPerPart)    % <--- TO TEST   !!!!!!!!!!!!!!!!!
            trx=blobs2TimeSeries(resulDir , parn,trx);
        end
    end
end