function [numActiveThisFrame,meanSpeedAllThisFrame,meanSpeedActiveThisFrame,trx] =  getActivityPerFrame (trx,listAlive,expectedNumAnts,speedThreshold,mm2px, s2f,f,GT,samplePeriod)

numActiveThisFrame = 0;
meanSpeedAllThisFrame = 0;
meanSpeedActiveThisFrame = 0;


nowAlive =listAlive{f};
numNowAlive = numel(nowAlive);
numActive = 0;
numSurviving = 0;

for ant1N=1:numNowAlive
    ant1 = nowAlive(ant1N);
    [trx,this_tracklet]=trx.get_tracklet(ant1);
    ant1Off = this_tracklet.off;
    % Check ant is alive in next frame

    numSurviving = numSurviving + 1;
    
    thisAntsSpeed=getVelocityWindowMean(this_tracklet,samplePeriod,f);
    thisAntsSpeed = thisAntsSpeed*(1/mm2px)*s2f;  % in mm per sec
    this_counter=this_tracklet.counter;
    if GT==1
        this_counter=this_tracklet.counter+this_tracklet.underestimate-this_tracklet.overestimate;
        %[sum(this_tracklet.underestimate) sum(this_tracklet.overestimate)]
    end
    if isnan(thisAntsSpeed)
        continue
    end
    % Save speed of this ant
    meanSpeedAllThisFrame = meanSpeedAllThisFrame + thisAntsSpeed *this_counter(f+ant1Off) ;
    %The active workers must have only 1 to their count.. because big blobs can
%sometimes exhibit some displacement but only because they are changing
%shape

    if (thisAntsSpeed>=speedThreshold)& (this_counter(f+ant1Off)==1) %if it is moving counter=1
        numActive=numActive+1*this_counter(f+ant1Off);
        meanSpeedActiveThisFrame = meanSpeedActiveThisFrame + thisAntsSpeed*this_counter(f+ant1Off);
    end
end

meanSpeedAllThisFrame = meanSpeedAllThisFrame / expectedNumAnts;
numActiveThisFrame = numActive;
if (numActive > 0)
    meanSpeedActiveThisFrame = meanSpeedActiveThisFrame / numActive;
end

