#sample_data details
##output ferda trajectories
The trajectories output by FERDA are matlab structures with the following fields:

* `x` d
* `y` d
* `area` d
* `mean_area` d
* `velocity_x` d
* `velocity_y` d
* `frame_offset` d
* `first_frame` d
* `last_frame` d
* `num_frames` d
* `region_id` d
and optionally they can also contain:
* `region` d
* `region_countour` d


##video data
This is a video of 3300 frames which contains 14 ants and a queen,
it is compressed in mpeg4 from the original. Note: motion
trajectories were obtained from uncompressed video.
The clip corresponds to replicate C5T1 (control-treated queen, at time point 1, week 9 after flight) in the paper.
