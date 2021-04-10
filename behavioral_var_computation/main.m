close all
clear
datadir='../sample_data/';
params_all_experiments = table2struct(readtable(strcat(datadir,'config.csv')));
workingdir=strcat(datadir,'working_directory/');
resume=1; % use resume=0 to start over, resume=1 to continue where you left off            
mkdir(datadir,'working_directory');

n_exp = 1;  % row in the csv file, could replace with for loop
params = params_all_experiments(n_exp);
projpath = strcat(workingdir,params.project_name,'/');

% copy ferda output files to working directory and update output path
mkdir(workingdir, params.project_name);
copyfile(strcat(datadir,params.path_FERDA_output,'*'), projpath);
params.path_FERDA_output = projpath;
params.path_video_file=strcat(datadir,params.path_video_file);
params.path_behavioral_timeseries=strcat(datadir,params.path_behavioral_timeseries);
% create memory-map object
trx = createTracksObject(params.path_FERDA_output, ...
                   params.number_of_parts, ...
                   params.size_of_parts, ...
                   params.msd_threshold, ...
                   params.single_threshold, ...
                   params.arena_diameter_mm, 0);

% visualize current state
% inspect_all_tracklets

% initialize parameters to find spurious detections, the queen,
% and workers foraging, moving, or aggregated near the queen
initBlobs2Counts

% compute time series of behaviours 
finaltable = table();
for parn = 1:numel(trx.numTracksPerPart)  
    [outputfilename, trx]=blobs2TimeSeries(resulDir , parn,trx,v);
    thistable = readtable(outputfilename, 'Delimiter',' ');
    finaltable = [finaltable ; thistable];
end
writetable(finaltable, strcat(params.path_behavioral_timeseries,'/timeSeries_',params.project_name,'.csv'));
% concatenate csv timpeseries output files

