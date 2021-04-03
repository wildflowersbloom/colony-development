function thisAntsSpeed=getVelocityWindowMean(this_tracklet,samplePeriod,f)
ant1Off = this_tracklet.off;
velWindowStart = f+ant1Off - floor(samplePeriod/2);
velWindowEnd   = f+ant1Off + floor(samplePeriod/2);
if velWindowStart < 1
    velWindowStart = 1;
end
if velWindowEnd > numel(this_tracklet.velocity)
    velWindowEnd = numel(this_tracklet.velocity);
end

velWindow = this_tracklet.velocity(velWindowStart:velWindowEnd);
thisAntsSpeed = nanmean(velWindow);

% Xi = this_tracklet.x(velWindowStart);
% Xf = this_tracklet.x(velWindowEnd);
% Yi = this_tracklet.y(velWindowStart);
% Yf = this_tracklet.y(velWindowEnd);
% displacement = sqrt( (Xi-Xf)^2 + (Yi-Yf)^2);
% 
% thisAntsSpeed = displacement / (velWindowEnd-velWindowStart+1);

