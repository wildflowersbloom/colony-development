classdef tracks
  %TRACKS Summary of this class goes here
  %   Detailed explanation goes here
  
  properties
    pathToParts
    numTracksPerPart
    numTracksTotal
    numFramesTotal
    listAlivePerFrame
    currentPartNum
    currentStruct
    globalFirstFrames
    globalLastFrames
    partStarts
    partEnds
    types
    msds
    mean_areas
    lastPartSingle
  end
  
  methods
    
    function obj = reset_counter(obj)
      numParts = numel(obj.numTracksPerPart);
      for pn = 1:numParts
        obj=obj.load_part(pn);
        for i=1:size(obj.currentStruct,2)
          nframes=obj.currentStruct(i).nframes;
          obj.currentStruct(i).counter=zeros(1,nframes);
          obj.currentStruct(i).overestimate=zeros(1,nframes);
          obj.currentStruct(i).underestimate=zeros(1,nframes);
        end
        
      end
      obj=obj.save_currentpart();
      obj.types=zeros(obj.numTracksTotal,1);
    end
    
    
    function obj = modify_property(obj,trackletNum,property,varargin)
      %usage: obj = obj.modif_property(5,'counter',zeros(1,100));
      % obj = obj.modif_property(5,'counter',3,20);
      [obj, thisTracklet]=get_tracklet(obj,trackletNum); %we reload the tracklet
      
      %compute index of trackletNum in the trx in which it is
      %stored (which is obj.currentStruct)
      upperLimit=cumsum(obj.numTracksPerPart);
      if obj.currentPartNum > 1
        localTrackletNum = trackletNum - upperLimit(obj.currentPartNum-1);
      else
        localTrackletNum = trackletNum;
      end
      if strcmp(property,'type')
        obj.types(trackletNum) = varargin{1};
      end
      %If there's only one argument, we set that as the property.
      %If there are two arguments, the first one is assumed to be an
      %index, the second the value of that index. Doesn't check that
      %the property already exists, so beware.
      nVarargs = length(varargin);
      if nVarargs == 1
        vectValue = varargin{1};
        obj.currentStruct(localTrackletNum).(property) = vectValue;
      else
        scalarValue = varargin{2};
        index = varargin{1}+obj.currentStruct(localTrackletNum).off;
        obj.currentStruct(localTrackletNum).(property)(index) = scalarValue;
        
        
      end
      
    end
    
    function obj=remove_tracklets(obj,globalIndices)
      Limits = [0 cumsum(obj.numTracksPerPart)];
      numParts = numel(obj.numTracksPerPart);
      for pn = 1:numParts
        Abv = globalIndices > Limits(pn);
        Bel = globalIndices <= Limits(pn+1);
        In = find(Abv  & Bel);  %entries in global indices that are in part pn
        if numel(In) > 0
          for f=obj.globalFirstFrames(pn):obj.globalLastFrames(pn)  %we go only through the frames of part pn
            obj.listAlivePerFrame{f} = setdiff(obj.listAlivePerFrame{f},globalIndices(In));
            %and remove the globalIndices that are in part pn
          end
        end
      end
    end
    
    function [obj, thisTracklet]=get_tracklet(obj,globalIdx)
      if numel(globalIdx)>1
        globalIdx=globalIdx(1);
        fprintf ('Warning, more than one tracklet referenced')
      end
      upperLimit=cumsum(obj.numTracksPerPart);
      partNum=find(globalIdx<=upperLimit,1);
      obj=obj.load_part(partNum);
      if partNum==1
        localIdx=globalIdx;
      else
        localIdx=globalIdx-upperLimit(obj.currentPartNum-1);
      end
      thisTracklet=obj.currentStruct(localIdx);
    end
    
    function obj=load_part(obj,partNum)
      if (partNum~=obj.currentPartNum)
        
        % PURGE part loaded in object before sending to cluster,
        % so that new (blobs counted) part is loaded always.
        
        % We want to be able to force the tracks object to load a
        % given part number, regardless of the currently loaded
        % part. The way to achieve this is to forcefully set
        % obj.currentPartNum to 0, so that any partNum passed to
        % load_part is different than obj.currentPartNum. Doing
        % this causes some problems when trying to save part 0, so
        % we put the following "if" to escape said problems.
        
        
        if obj.currentPartNum > 0
          %First save the currently loaded trx into its file
          obj=save_currentpart(obj);
        end
        
        %Now load the trx specified by partNum
        newPartStart=obj.partStarts(partNum);
        if partNum < numel(obj.partStarts) || obj.lastPartSingle == 0
          newPartEnd=obj.partEnds(partNum);
          load(strcat(obj.pathToParts,'/out_',num2str(newPartStart),'-',num2str(newPartEnd),'.mat'));
        else  %if the last part doesn’t have ending
          fileName = strcat(obj.pathToParts,'/out_',num2str(newPartStart),'.mat');
          load(fileName);
        end
        obj.currentPartNum=partNum;
        obj.currentStruct=trx;
        %disp(strcat('File out_',num2str(partStart),'-',num2str(partEnd),'.mat is loaded'));
        %disp(strcat('...corresponding to frames [ ',num2str(obj.globalFirstFrames(partNum)),' to  ',num2str(obj.globalLastFrames(partNum)),']'));
      else
        %disp(strcat('Part ',num2str(partNum), 'is already loaded'));
      end
    end
    function obj=save_currentpart(obj)
      oldPartStart = obj.partStarts(obj.currentPartNum);
      oldPartEnd   = obj.partEnds(obj.currentPartNum);
      if obj.currentPartNum < numel(obj.numTracksPerPart) || obj.lastPartSingle==0
          oldFileName = strcat(obj.pathToParts,'/out_',num2str(oldPartStart),'-',num2str(oldPartEnd),'.mat');
      else
          oldFileName = strcat(obj.pathToParts,'/out_',num2str(oldPartStart),'.mat');
      end
      
      trx = obj.currentStruct;
      save(oldFileName,'trx','-append');
    end
    
    %contructor method
    %Arguments:
    % pathToParts
    % numParts
    % sizeParts
    % [msdthr]
    % [singlethr]
    % [arenaDiameter]
    % [forceRecreate]
    %
    %The four optional arguments must all be provided (ie. either
    %provide all or none of them). Including the optional arguments
    %indicates that single tracklets must be marked in this function.
    %if ForceRecreate == 1, the FERDA files are loaded and re-converted to
    %trx, thus deleting any existing info
    
    function obj=tracks(pathToParts, numParts, sizeParts,varargin)
      if numel(varargin) == 4
        doMarkSingles = 1;
        msdthr = varargin{1};
        singlethr = varargin{2};
        arenaDiameter = varargin{3};
        forceRecreate = varargin{4};
        if exist(strcat(pathToParts,'arena.mat'),'file')==2
          load(strcat(pathToParts,'arena.mat'));
        else
          copyfile(strcat(pathToParts,'_arena.mat'),strcat(pathToParts,'arena.mat'));
          load(strcat(pathToParts,'arena.mat'));
        end
        SF  = (2*arena.radius) / arenaDiameter;
        SF2 = SF^2;
      end
      
      obj.pathToParts=pathToParts;
      obj.numTracksPerPart=zeros(1,numParts);
      obj.partStarts=zeros(1,numParts);
      obj.partEnds=zeros(1,numParts);
      obj.globalFirstFrames=zeros(1,numParts);
      obj.globalLastFrames=zeros(1,numParts);
      obj.listAlivePerFrame={};
      obj.mean_areas=[];
      obj.msds=[];
      obj.types = [];
      partStart=0;
      for i=1:numParts
        partEnd= partStart+sizeParts-1;
        obj.partStarts(i)=partStart;
        obj.partEnds(i)=partEnd;
        if i == numParts
          obj.lastPartSingle = 1;
          for lastCounter = 0:sizeParts
            fileName = strcat(pathToParts,'/out_',num2str(partStart),'-',num2str(partEnd-lastCounter),'.mat');
            ori_fileName=strsplit(fileName,'/');
            ori_fileName=strjoin([ori_fileName(1:end-2),ori_fileName(end)],'/');
            if exist(fileName,'file') == 2 | exist(ori_fileName,'file') == 2
              obj.partEnds(i) = partEnd-lastCounter;
              obj.lastPartSingle = 0;
              break
            end %if exists
          end  %for lastCounter
          if obj.lastPartSingle == 1
            fileName = strcat(pathToParts,'/out_',num2str(partStart),'.mat');
          end
          
        else
          fileName = strcat(pathToParts,'/out_',num2str(partStart),'-',num2str(partEnd),'.mat');
        end
        clear trx
        clear FERDA
        
        if exist(fileName)~=2 % out*.mat is not in copy_for_cluster, thus not converted yet
          break
        else
          load(fileName);
        end
        if (~exist('trx','var')) || (forceRecreate==1)
          trx= convertFormat(FERDA);
          save(fileName,'trx','FERDA');
        end
        
        partStart=partStart+sizeParts;
        obj.numTracksPerPart(i)=numel(trx);
        deaths = getstructarrayfield(trx,'endframe');
        births = getstructarrayfield(trx,'firstframe');
        maxFrameThisPart = max(deaths);
        nframes=maxFrameThisPart -min(births)+1;
        firstFrame=min(births);
        listAliveThisPart = cell(nframes,1);
        trackletsOffset = sum(obj.numTracksPerPart)-size(trx,2);
        listAliveThisPart{1} = find(births==1+firstFrame-1) + trackletsOffset;
        for f=2:nframes
          listAliveThisPart{f} = find((births<=f+firstFrame-1) & (deaths>=f+firstFrame-1)) + trackletsOffset;
        end
        %obj.listAlivePerFrame=[obj.listAlivePerFrame ; listAliveThisPart];
        for fex=numel(obj.listAlivePerFrame)+1 : maxFrameThisPart
            a{fex} = [];
        end
        sizeThisListAlive = numel(listAliveThisPart);
        obj.listAlivePerFrame(maxFrameThisPart-sizeThisListAlive+1:maxFrameThisPart)=listAliveThisPart;
        obj.globalFirstFrames(i)=firstFrame;
        obj.globalLastFrames(i)=firstFrame+nframes-1;
        obj.mean_areas = [obj.mean_areas, trx.mean_area];
        obj.msds=[obj.msds,trx.msd];
        if doMarkSingles
          theseTypes = zeros(1,numel(trx));
          for t=1:numel(trx)
            at = trx(t);
            if trx(t).msd > msdthr*SF2 && trx(t).mean_area < SF2*singlethr
              theseTypes(t) = 1;
              trx(t).counter = ones(1,at.nframes);
            end
          end          
          obj.types = [obj.types,theseTypes];
          save(fileName,'trx','-append');
        else
          obj.types = [obj.types,zeros(1,numel(trx))];
        end
      end
      obj.currentPartNum=i;
      obj.currentStruct=trx;
      % from last part loaded
      obj.numFramesTotal = numel(obj.listAlivePerFrame);
      obj.numTracksTotal = sum(obj.numTracksPerPart);
      
    end % constructor
  end % methods
  
end




