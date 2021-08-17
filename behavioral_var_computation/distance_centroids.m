function D = distance_centroids(tracklet1,f1,tracklet2,f2)
	Dx = (tracklet1.x(f1) - tracklet2.x(f2)).^2;
	Dy = (tracklet1.y(f1) - tracklet2.y(f2)).^2;
	D = sqrt(Dx+Dy);