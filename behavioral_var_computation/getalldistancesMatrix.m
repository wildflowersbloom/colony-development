%% Distance matrix given elements as trx-indices and frames. elem1 has for each row: ID, frame, Area
function [meanToClosest,queen,allworkers,activeworkers,trx] = getalldistances(trx, listAlive,i,queenID,workersID,expected,mm2px,s2f,speedThreshold,GT,samplePeriod)

meanToClosest = NaN;
queen  = NaN;
allworkers  = NaN;
activeworkers  =   NaN;

% queen info
qu = queenID;
if numel(qu) > 1
    qu = qu(1);
end
% if there is no queen identified, we skip this frames
if isempty(qu)
    return;
end
[trx queenTracklet] = trx.get_tracklet(qu);
if GT==0
    queencounter=queenTracklet.counter;
else
    queencounter=queenTracklet.counter+queenTracklet.underestimate-queenTracklet.overestimate;
end
qoff=queenTracklet.off;
a2X=queenTracklet.x(i+qoff);
a2Y=queenTracklet.y(i+qoff);
% workers
wo=workersID; % detections which do not contain queen
numwo=expected-queencounter(i+qoff);% number of workers in detections which do not contain queen
% set lists


CountQueen = queencounter(i+qoff);
PosQueen = [a2X,a2Y];
PosWorkers = zeros(numel(wo),2);
CountWorkers = zeros(numel(wo),1);
SpeedsWorkers = zeros(numel(wo),1);

if numel(wo) < 1
    return
end

for j2 = 1:numel(wo)
    a2=wo(j2);
    
    [trx a2Tracklet] = trx.get_tracklet(a2);
    a2off=a2Tracklet.off;
    a2X=a2Tracklet.x(i+a2off);
    a2Y=a2Tracklet.y(i+a2off);
    PosWorkers(j2,:) = [ a2X,a2Y ];
    if GT==0
        a2counter=a2Tracklet.counter;
    else
        a2counter=a2Tracklet.counter+a2Tracklet.underestimate-a2Tracklet.overestimate;
    end
    CountWorkers(j2) =  a2counter(i+a2off);
    thisAntsSpeed=getVelocityWindowMean(a2Tracklet,samplePeriod,i);
    SpeedsWorkers(j2) = thisAntsSpeed*(1/mm2px)*s2f;
end



distanceMatrix = pdist2(PosWorkers,PosWorkers)*(1/mm2px);
repeatedWorkerCounts = repmat(CountWorkers,1,numel(CountWorkers));
distancesToQueen = pdist2(PosWorkers,PosQueen)*(1/mm2px);

sumQueen  = sum(CountWorkers .* distancesToQueen);
sumNonQueen = 0.5*sum(sum( distanceMatrix .* repeatedWorkerCounts .* repeatedWorkerCounts' ));
sumAllWorkers    = sumNonQueen + CountQueen*sumQueen;

%The active workers must have only 1 to their count.. because big blobs can
%sometimes exhibit some displacement but only because they are changing
%shape
CountWorkersFast = CountWorkers;


CountWorkersFast(SpeedsWorkers<speedThreshold) = 0;
CountWorkersFast(isnan(SpeedsWorkers))=0;
CountWorkersFast(CountWorkers>1)=0;

repeatedWorkerCountsFast = repmat(CountWorkersFast,1,numel(CountWorkersFast));
sumActive = 0.5*sum(sum( distanceMatrix .* repeatedWorkerCountsFast .* repeatedWorkerCountsFast' ));
numActive = sum(CountWorkersFast);

areNotBlobs = CountWorkers<=1;
repeatedAreNotBlobs = repmat(areNotBlobs,1,numel(areNotBlobs));
distanceMatrix = distanceMatrix .* repeatedAreNotBlobs';



distancesToClosestAnts = min( distanceMatrix+diag(inf(size(distanceMatrix,1),1)) );
meanToClosest = sum(distancesToClosestAnts.*CountWorkers')/expected;
queen  = sumQueen/expected;
allworkers  = sumAllWorkers/(expected*(expected-1)/2);
activeworkers  =   sumActive  / (numActive*(numActive-1)/2);

