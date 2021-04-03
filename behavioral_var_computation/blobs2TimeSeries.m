%% output is a file called timeSeries_partnum.csv with the following columns:
%         1 f, frame number
%         2 numActiveThisFrame
%         3 meanSpeedActiveThisFrame, mean speed of the active ants
%         4 meanSpeedAllThisFrame, mean speed of all the ants
%         5 allworkersThisF, distance among every pair of workers (not with queen)
%         6 activeworkersThisF, distance among pairs of active workers
%         7 queenThisF, mean distance of all ants to the queen
%         8 meanToClosestThisF, mean distance of each ant to its closes ant
%         9 q,  number of ants estimated to be in the queen's blob
%         10 number foraging
%         11 queen area     
%

%% 
function [outputfilename , trx]=blobs2TimeSeries(resulDir,partNum,trx,v)
outputheader='frame numActive speedActive speedAll distAll distActive distQueen distClosest queenCount numForager queenArea\n';

outputfilename = strcat(resulDir,'timeSeries_',num2str(partNum, '%10.5d\n'),'.csv');
fid = fopen(outputfilename,'W'); %W is for buffered output
fprintf(fid,outputheader);
%load all necesary files
load(strcat(resulDir,'info.mat'));   %info on the project and video (inc. videoFilename and video_start)f=initialFrame:samplePeriodForTimeseries:finalFrame
load(strcat(resulDir,'arena.mat'));  %arena data
load(strcat(resulDir,'blob_parameters.mat'));   %the blob parameters extracted from the original marks of singles

trx.currentPartNum = 0;
trx = trx.load_part(partNum);
initialFrame = min(getstructarrayfield(trx.currentStruct,'firstframe'));
finalFrame   = max(getstructarrayfield(trx.currentStruct,'endframe'));

listAlive=trx.listAlivePerFrame;
totframes=trx.numFramesTotal;

num_expected=INFO.nexpected;
[mm2px , s2f, expectedNumAnts] = getScales(strcat(resulDir,'info.mat'));

se=strel('square',1);

plotframes = 0;

tic
for f=initialFrame+2:samplePeriodForTimeseries:finalFrame;
    aliveNow=listAlive{f};
    n_singles=0;
    missingThisF = NaN;
    in_blobs=0;
    vstatus = trx.types(aliveNow);    % [2,1,0,3....] corresponding to ['queen' 'single' 'blob' 'spurious' ...]
    % skip if queen blob was not found
    if sum(vstatus==2)~=1
        continue
    end
    % count singles
    n_singles=numel(find(vstatus==1));
    % list blobs
    listBlobs = aliveNow(find(vstatus==0));
    I=read(v,f+video_start);
    I=I(arena.y1:arena.y2,arena.x1:arena.x2,:);

    %%
    if n_singles >0
        listSingles = aliveNow(find(vstatus==1));
        for j = 1:n_singles
            e=listSingles(j);
            [trx,ae]=trx.get_tracklet(e);
            blob_area = ae.area(f+ae.off);
            % frame type count area x y            
        end
    end
    %%
    if numel(listBlobs) > 0
        intI=(I(:,:,2)); % green channel intensity image, contrast is best
        thrI=intI<intensity_thr; %logical
        %thrI=imdilate(thrI,se); %dilation
        trackletBlobs = {};
        %% It is in three different for loops to allow for paralellization
        for j=1:numel(listBlobs)
            e=listBlobs(j);
            [trx,ae]=trx.get_tracklet(e);
            trackletBlobs{j} = ae;
        end
        countersBlobls = zeros(numel(listBlobs),1);
        areasBlobls = zeros(numel(listBlobs),1);
        %we explicitly name this variables so that parfor can work
        singleMean = single_mean;
        singleSD   = single_sd;
        for j=1:numel(listBlobs)
            
            ae = trackletBlobs{j};                        
            [counter , blob_area] = computeCounterForBlob(ae,singleMean,singleSD,thrI,f);
            countersBlobls(j) = counter;
            areasBlobls(j) = blob_area;
            in_blobs=in_blobs+counter;
            % frame type count area x y
           
        end
        for j = 1:numel(listBlobs)
            e=listBlobs(j);
            trx=trx.modify_property(e,'true_area',f,double(areasBlobls(j)));
            trx=trx.modify_property(e,'counter',f,countersBlobls(j));
        end
        
        
        %%
    end
    % queen counter
    for k = find(vstatus==2)
        q=aliveNow(k);
        [trx, aq]=trx.get_tracklet(q);
        counter_queen = num_expected-in_blobs-n_singles;
        trx=trx.modify_property(q,'counter',f, counter_queen);
        missingThisF =  num_expected-in_blobs-n_singles;
        queen_area = aq.area(f+aq.off);        
        %[q num_expected-in_blobs-n_singles in_blobs sum(countersBlobls)]
    end
    
    
    GT=0;
    %Computing the activity-time-series point for this frame
    [numActiveThisFrame,meanSpeedAllThisFrame,meanSpeedActiveThisFrame,trx] = getActivityPerFrame(trx,listAlive,num_expected,speedThreshold,mm2px,s2f,f,GT,samplePeriodForTimeseries);
    
    %Computing the distance-time series point for this frame
    qu = aliveNow(find(vstatus==2));
    wo = aliveNow(find(vstatus<2));
    [meanToClosestThisF,queenThisF,allworkersThisF,activeworkersThisF,trx] = getalldistancesMatrix(trx, listAlive,f,qu,wo,num_expected,mm2px,s2f,speedThreshold,GT,samplePeriodForTimeseries);
    
    activeworkersThisF;

        
    [inAreas,areInside] = countInAreas(trx,aliveNow,f,INFO,speedThreshold,samplePeriodForTimeseries,mm2px,s2f);
    
    fprintf(fid,'%d %f %f %f %f %f %f %f %d %d %f', ...
        f, ...
        numActiveThisFrame, ... 
        meanSpeedActiveThisFrame, ...
        meanSpeedAllThisFrame, ...
        allworkersThisF, ...
        activeworkersThisF, ...
        queenThisF, ...
        meanToClosestThisF,...
        missingThisF,...
        inAreas,...
        queen_area);
    fprintf(fid,'\n');
    

    
    
    %% Only for testing purposes
    if plotframes==1
        hold off
        q=aliveNow(find(vstatus==2));
        [trx,ae]=trx.get_tracklet(q);
        plot(ae.contour{f+ae.off}.x,ae.contour{f+ae.off}.y)
        xlim([0 1024])
        ylim([0 1024])
        imshow(I);
        hold on
        for pn = 1:numel(INFO.foragpolyx)
        plot(INFO.foragpolyx{pn},INFO.foragpolyy{pn},'g-')
         text(INFO.foragpolyx{pn}(1)+10,INFO.foragpolyy{pn}(1)+10,num2str(inAreas(pn)),'Color','green')
        end
        for j = 1:numel(aliveNow)
            e = aliveNow(j);
            [trx,ae]=trx.get_tracklet(e);
            thisAntsSpeed=getVelocityWindowMean(ae,samplePeriodForTimeseries,f);
            spe = thisAntsSpeed*(1/mm2px)*s2f;
            text(ae.x(f+ae.off)+10,ae.y(f+ae.off)+10, strcat(num2str(spe),'X',num2str(ae.nframes)))
            plot(ae.x(f+ae.off),ae.y(f+ae.off),'b*')
            if spe > speedThreshold
                plot(ae.contour{f+ae.off}.x,ae.contour{f+ae.off}.y,'r-')
            else
                plot(ae.contour{f+ae.off}.x,ae.contour{f+ae.off}.y,'w-')
            end
            if areInside(j)==1
                plot(ae.x(f+ae.off),ae.y(f+ae.off),'g*')
            end
        end
        
    end
    
    
end
toc



trx=trx.save_currentpart();
fclose(fid);

