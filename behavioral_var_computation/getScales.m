function [mm2px , s2f , expectedNumAnts] = getScales(scaleFile)
    da = load(scaleFile);
    INFO = da.INFO;
    mm2px = INFO.scalefactor;
    s2f   = INFO.fps;
    expectedNumAnts = INFO.nexpected;
end