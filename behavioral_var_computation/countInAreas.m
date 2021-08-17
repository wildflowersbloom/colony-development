function [inAreas,areInside] = countInAreas(trx,aliveNow,f,INFO,speedThreshold,samplePeriodForTimeseries,mm2px,s2f)
numAreas = numel(INFO.foragpolyx);
inAreas = zeros(1,numAreas);
ptsX = zeros(1,numel(aliveNow));
ptsY = zeros(1,numel(aliveNow));
counters = zeros(1,numel(aliveNow));
areInside = zeros(1,numel(aliveNow));

%We build a list with all the centers of the currently-living ants
for j = 1:numel(aliveNow)
    e = aliveNow(j);
    [trx,ae]=trx.get_tracklet(e);
    ptsX(j) = ae.x(f+ae.off);
    ptsY(j) = ae.y(f+ae.off);
    counters(j) = ae.counter(f+ae.off);
    thisAntsSpeed=getVelocityWindowMean(ae,samplePeriodForTimeseries,f);
    spe = thisAntsSpeed*(1/mm2px)*s2f;
    
    if spe > 0.25*speedThreshold
       ptsX(j) = -100;
       ptsY(j) = -100;
   end
end
%Now we check which of said points are in each of the areas 
for aN = 1:numAreas

   inP = inpolygon(ptsX,ptsY,INFO.foragpolyx{aN}, INFO.foragpolyy{aN});
   inAreas(aN) = sum(inP.*counters);
   areInside(find(inP))=1;
end