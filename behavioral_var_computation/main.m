clear
params_all_experiments = table2struct(readtable('config.csv'));
workingdir='../sample_data/working_directory/';

mkdir('../sample_data','working_directory');

n_exp = 1;  % row in the csv file, could replace with for loop
params = params_all_experiments(n_exp);
projpath = strcat(workingdir,params.project_name,'/');

% copy files to working directory
mkdir(workingdir, params.project_name);
copyfile(strcat(params.path_FERDA_output,'*'), projpath);
params.path_FERDA_output = projpath;

% create memory-map object
trx = createTracksObject(params.path_FERDA_output, ...
                   params.number_of_parts, ...
                   params.size_of_parts, ...
                   params.msd_threshold, ...
                   params.single_threshold, ...
                   params.arena_diameter_mm, 0);

% visualize current state
inspect_all_tracklets
