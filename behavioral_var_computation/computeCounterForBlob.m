function [counter , blob_area] = computeCounterForBlob(ae,single_mean,single_sd,thrI,f)

blob_area=ae.mean_area;

if blob_area < single_mean + single_sd  && ~isnan(blob_area)
    counter = round(ae.mean_area/(single_mean));
    return
end


% blob_area > single_mean + single_sd || isnan(blob_area) % larger clusters, count with model
xr= ae.region{f+ae.off}.x+1;
yr= ae.region{f+ae.off}.y+1;
bbB = zeros(size(thrI));
bbB(sub2ind(size(thrI),yr,xr)) = 1;
blob_mask = bbB .* thrI;
CC = bwconncomp(blob_mask);
count_cc=0;
disconnected_area=0;
for c=1:CC.NumObjects
    cc_size=numel(CC.PixelIdxList{c});
    if cc_size < single_mean - single_sd % smaller than smallest single ant
         disconnected_area=disconnected_area+cc_size;
         continue
    end
    count_cc=count_cc+count_model(cc_size, single_mean);
end
count_cc=count_cc+round(disconnected_area/single_mean); %add small disconnected cc ant-pixels
blob_area = sum(sum(blob_mask));
counter=count_cc;
