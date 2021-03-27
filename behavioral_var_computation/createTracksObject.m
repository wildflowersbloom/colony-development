% This function creates the tracks object for a set of mat files containing
% FERDA variables, as exported by Ferda. Simultaneously, each tracklet is
% checked to see if it a single ant according to the supplied values. 
% Arguments:
    % pathToParts
    % numParts
    % sizeParts
    % msdthr   %1.3  in mm^2
    % singlethr   %1.8  area in mm^2
    % arenaDiameter   %90 in mm  (is used for computing scale factors)
    % forceRecreate  if 1, the FERDA variables are re-loaded thus erasing
    % anything that was previously computed on the trx variables


function trx = createTracksObject(resulDir,numParts,sizeParts,msdThr,singleThr,arenaDiam,forceR)
  trx=tracks(resulDir,numParts,sizeParts,msdThr,singleThr,arenaDiam,forceR);
  save(strcat(resulDir,'object.mat'),'trx');
  load(strcat(resulDir,'arena.mat'));
  arena.arenaDiameter = arenaDiam;
  msdthr = msdThr;
  singlethr = singleThr;
  save(strcat(resulDir,'arena.mat'),'arena','msdthr','singlethr');