%mark queen
function [trx]=mark_queen(trx,v,listAlive,video_start,single_mean,arena,spuX,spuY,resume_marking)
totframes=trx.numFramesTotal;
numFramesToAverage=10; % number of frames to include for queen stats
sizeChangeThreshold = 5;  %In standard deviations of the queen areas (1)
distanceThreshold = 5;  %In standard deviation of the queen’s displacements (2)
jaccardThreshold = 0.5;  %The jaccard index of the overlap between the last queen and a candidate to consider the candidate good enough to be queen
framesThreshold = 50;
markSpuriousEvery = 40000;%20000 to ask just ~5 times in total
numFramesPerPart = mode(trx.globalLastFrames(2:end)-trx.globalLastFrames(1:end-1));
backupfilename = 'temporal_file_for_backup_of_queenmarking.mat';
thrsholdsave = 2*numFramesPerPart;

if (resume_marking == 0) || (exist(strcat(trx.pathToParts,backupfilename),'file') ~=2 )
    
    % initialize queens
    queensForAverage=0;
    F=1;
    [trx,listAlive] = findAndRemoveSpuriousFromLoadedPart(trx,spuX,spuY,listAlive,arena,1);
    [trx,listAlive] = findAndRemoveSpuriousFromLoadedPart(trx,spuX,spuY,listAlive,arena,1);
    areasQueen = zeros(numFramesToAverage,1);
    centroidsQueenX = zeros(numFramesToAverage,1);
    centroidsQueenY = zeros(numFramesToAverage,1);
    lastDetectedQueen =  0;  %stores the number of the tracklet of the last seen queen
    totQueenFrames = 0;
    % ("while" since we are not sure that all frames have a queen detection)
    while queensForAverage<numFramesToAverage
        fprintf('Please initialize queen detection >>click close to polygon!! %d\n', queensForAverage)
        [trx, clickedAll ,side]= initialize2(trx,F,v,listAlive,video_start,strcat('MARK QUEEN: ',num2str(queensForAverage+1),'/',num2str(numFramesToAverage),'_(right for spurious)'),arena);
        clicked = clickedAll(side==1);
        clickedSpu = clickedAll(side==3);
        [spuX,spuY]=getSpuriousContours(trx,clickedSpu,spuX,spuY);
        [trx,listAlive] = findAndRemoveSpuriousFromLoadedPart(trx,spuX,spuY,listAlive,arena,1);
        if numel(clicked)>0
            qu=clicked(1);
            queensForAverage=queensForAverage+1;
            [trx, aq]=trx.get_tracklet(qu);
            %mark'queen';
            trx=trx.modify_property(qu,'type',2);
            qX = aq.x(F+aq.off);
            qY = aq.y(F+aq.off);
            centroidsQueenX(queensForAverage)=qX;
            centroidsQueenY(queensForAverage)=qY;
            areasQueen(queensForAverage)=aq.area(F+aq.off);
            lastDetectedQueen=aq;
            F=aq.endframe;
            lastDetectedQueenFrame=F;
            lastInputFrame = F;
            totQueenFrames = totQueenFrames + aq.nframes;
        end
        F=F+1;
        if F >= totframes
            return
        end
    end
    
    meanAreaQueen = mean(areasQueen);
    stdArea  = std(double(areasQueen));
    areasZscore = (areasQueen - meanAreaQueen)/stdArea;  %Number of standard deviations away from the mean area (initialization)
    %sizeChangeThreshold =range(areasZscore)<< this didn't really work.
    displacementsQueen = sqrt ( ( centroidsQueenX(2:end) - centroidsQueenX(1:end-1) ).^2 + ( centroidsQueenY(2:end) - centroidsQueenY(1:end-1) ).^2  );
else
    
    fprintf('Realoading from %s  ',strcat(trx.pathToParts,backupfilename));
    backup = load(strcat(trx.pathToParts,backupfilename));
    saved = backup.toSave;
    
    trx.listAlivePerFrame = saved.listAlive;
    trx.types = saved.types;
    displacementsQueen = saved.displacementsQueen;
    areasQueen = saved.areasQueen;
    lastDetectedQueen = saved.lastDetectedQueen;
    lastDetectedQueenFrame = saved.lastDetectedQueenFrame;
    F = saved.frame;
    %F = 19000
    totQueenFrames = saved.totQueenFrames;
    lastInputFrame = F - framesThreshold-10;
    spuX = saved.spuX;
    spuY = saved.spuY;
    fprintf('Resumed from frame %d \t spu: %d\n',F,numel(spuX));
    
    fprintf('Last queen  detected in frame %d. This tracklet dies in frame %d\n',lastDetectedQueenFrame,lastDetectedQueen.endframe);
    %   showVideo(trx,128849,128851,v,video_start,arena);
    %     modify_arena=input('Press any key to continue','s');
    
    
end


%Now that have numFramesToAverage detections of the queen,
%find queens in all other frames which fall within queen statistics
f = F;
inspected = 0;
foundQueens = 0;
numExtraInspections = 0;
lastFrameForSpurious = f; %last frame where user marked spurious
save_frame = -1;
while f <= totframes
    f;
    % Save the necessary stuff for resuming if error ocurs
    if (trx.currentPartNum > 3) && (save_frame < 0)
        saved_backup=false;
        toSave = struct();
        toSave.listAlive = trx.listAlivePerFrame;
        toSave.types = trx.types;
        toSave.displacementsQueen = displacementsQueen;
        toSave.areasQueen = areasQueen;
        toSave.lastDetectedQueen = lastDetectedQueen;
        toSave.lastDetectedQueenFrame=lastDetectedQueenFrame;
        toSave.frame = f;
        toSave.totQueenFrames = totQueenFrames;
        toSave.spuX = spuX;
        toSave.spuY = spuY;
        
        save_frame = f;
    end
    if (save_frame > 1) && (f-save_frame) > thrsholdsave
        save(strcat(trx.pathToParts,backupfilename),'toSave');
        saved_backup=true;
        save_frame = -1;
    end
    
    [trx,listAlive] = findAndRemoveSpuriousFromLoadedPart(trx,spuX,spuY,listAlive,arena,0);
    
    %In every frame, we take the mean areas and displacements of the last queens
    stdDisplacement = std(displacementsQueen);
    meanDisplacement = mean(displacementsQueen);
    meanArea = mean(areasQueen);
    stdArea  = std(double(areasQueen));
    
    inspected = inspected + 1;
    
    dTreshold = distanceThreshold * stdDisplacement;
    sTreshold = sizeChangeThreshold * stdArea;
    
    aliveNow = listAlive{f};
    if numel(aliveNow) == 0
        f=f+1;
        continue
    end
    vstatus = trx.types(aliveNow);
    if numel(find(vstatus==2))>=1
        f=f+1;
        continue
    end
    bestQueen = 0;
    bestDistance = Inf;
    
    allDistances = zeros(1,numel(aliveNow));    % Difference between mean displacement and the displacement between a putative queen and the last queen
    allAreas     = zeros(1,numel(aliveNow));    % Difference between mean queen area and the area of a putative queen
    
    for an = 1:numel(aliveNow)
        a=aliveNow(an);
        [trx,aa]=trx.get_tracklet(a);
        ldq=lastDetectedQueen;
        %[trx,ldq]=trx.get_tracklet(lastDetectedQueen);
        %see if it has moved a lot from the last detected queen
        Da = distance_centroids(aa, f+aa.off , ldq , lastDetectedQueenFrame+ldq.off);
        allDistances(an) = Da;
        
        sA = aa.area(f+aa.off);
        allAreas(an) = sA;
    end %end for an=1:numel…   looping through living ants
    
    
    allAreasZ     = abs(allAreas-meanArea);
    allDistancesZ = abs(allDistances - meanDisplacement);
    %     [ma , simA] = min(allAreasZ);
    %     [md , simD] = min(allDistancesZ);
    inds = 1:numel(aliveNow);
    
    
    
    candidatesByArea = find((allAreasZ < sTreshold) & (allAreas > 2*single_mean));
    candidatesByArea = find(allAreas > 8*single_mean);
    candidatesByDisplacement = find(allDistancesZ < dTreshold);
    %candidatesByDisplacement = find(allDistances < sqrt(meanArea/pi));
    
    candidatesBothA = zeros(1,numel(aliveNow));
    candidatesBothA(candidatesByArea) = candidatesBothA(candidatesByArea)+1;
    candidatesBothA(candidatesByDisplacement) = candidatesBothA(candidatesByDisplacement)+1;
    candidatesBoth = find(candidatesBothA==2);
    candidatesSome = find(candidatesBothA==1);
    
    if (numel(candidatesBoth)==0) && (numel(candidatesSome)==1)
        polyLastQueen = ldq.contour{lastDetectedQueenFrame+ldq.off};
        [trx,possibleCandidate]=trx.get_tracklet(aliveNow(candidatesSome(1)));
        polyCandidate = possibleCandidate.contour{possibleCandidate.off +f};
        jaccard=areaOfPoligonIntersection(polyLastQueen,polyCandidate);
        if jaccard > jaccardThreshold
            candidatesBoth = [candidatesSome(1)];
        else
            [jaccard];
        end
    end
    if f - lastFrameForSpurious > markSpuriousEvery
        [trx , clickedAll , side]= initialize2(trx,f-1,v,listAlive,video_start,'MARK right for spurious)',arena);
        clicked = clickedAll(side==1);
        clickedSpu = clickedAll(side==3);
        [spuX,spuY]=getSpuriousContours(trx,clickedSpu,spuX,spuY);
        [trx,listAlive] = findAndRemoveSpuriousFromLoadedPart(trx,spuX,spuY,listAlive,arena,0);
        lastFrameForSpurious = f;
    end
    f = f+1;
    if numel(candidatesBoth) == 0
        %disp('no candidates ');
        [f-1 meanArea stdArea]
        if f-lastInputFrame > framesThreshold || ( ( numel(candidatesSome)==1 ) && (possibleCandidate.nframes > framesThreshold/3  )  )
            lastInputFrame = f-1;
            numExtraInspections = numExtraInspections + 1;
            [trx , clickedAll , side]= initialize2(trx,f-1,v,listAlive,video_start,strcat('MARK QUEEN X: ',num2str(numExtraInspections),'_(right for spurious)'),arena);
            clicked = clickedAll(side==1);
            clickedSpu = clickedAll(side==3);
            [spuX,spuY]=getSpuriousContours(trx,clickedSpu,spuX,spuY);
            if numel(clicked) ~= 1
                continue
            end
            clickN = find(aliveNow==clicked(1));
            candidatesBoth = [clickN];
            lastFrameForSpurious = f;
        else
            %testQueenDetectoin(f-1,video_start,v,listAlive,candidatesByArea,candidatesByDisplacement,trx);
            continue
        end
    end
    bestArea = 0;
    bestDistance = Inf;
    for can = 1:numel(candidatesBoth)
        ca = candidatesBoth(can);
        if allDistances(ca) < bestDistance
            simA = ca;
            bestQueen    = aliveNow(simA);
            bestDistance = allDistances(simA);
            bestArea     = allAreas(simA);
        end
    end
    
    
    
    if bestQueen > 0
        foundQueens = foundQueens + 1;
        [trx,bq]=trx.get_tracklet(bestQueen);
        %mark 'queen';
        trx=trx.modify_property(bestQueen,'type',2);
        lastDetectedQueen = bq;
        lastDetectedQueenFrame=bq.endframe ;
        
        bestArea = bq.area(end);
        f = bq.endframe + 1;
        %We remove the oldest queen’s displacement and area, and replace it
        %with the just detected one
        if bq.nframes > 1
            lastInputFrame = lastDetectedQueenFrame;
            framesToSample = min(bq.nframes,numFramesToAverage - 2);
            framesToGetArea = randi([1,bq.nframes],framesToSample,1);
            sampleOfAreas = bq.area(framesToGetArea);
            displacementsQueen = [displacementsQueen(2:end) ; bestDistance];
            areasQueen = [areasQueen(framesToSample+1:end); sampleOfAreas'];
        end
        totQueenFrames = totQueenFrames + bq.nframes;
    else
        testQueenDetectoin(f-1,video_start,v,listAlive,candidatesByArea,candidatesByDisplacement,trx);
        
    end%end if bestqueen
    
    
    
end  %end looping trough frames

findAndRemoveSpuriousFromLoadedPart(trx,spuX,spuY,listAlive,arena,1);
end   %end function

