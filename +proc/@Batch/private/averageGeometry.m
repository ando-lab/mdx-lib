function DE = averageGeometry(InputGeometry,RefinedGeometry)

AllCrystal = [RefinedGeometry.Crystal];
AllDetector = [RefinedGeometry.Detector];
AllSpindle = [RefinedGeometry.Spindle];
AllSource = [RefinedGeometry.Source];

AverageRefinedGeometry = geom.DiffractionExperiment();

if ~isempty(AllCrystal)
    AverageRefinedGeometry.Crystal = geom.Crystal(...
        'spaceGroupNumber',[],...
        'a',mean([AllCrystal.a]),...
        'b',mean([AllCrystal.b]),...
        'c',mean([AllCrystal.c]),...
        'alpha',mean([AllCrystal.alpha]),...
        'beta',mean([AllCrystal.beta]),...
        'gamma',mean([AllCrystal.gamma]),...
        'a_axis',mean(reshape([AllCrystal.a_axis],3,[]),2)',...
        'b_axis',mean(reshape([AllCrystal.b_axis],3,[]),2)',...
        'c_axis',mean(reshape([AllCrystal.c_axis],3,[]),2)');
end

if ~isempty(AllDetector)
     AverageRefinedGeometry.Detector = geom.Detector(...
        'orgx',mean([AllDetector.orgx]),...
        'orgy',mean([AllDetector.orgy]),...
        'f',mean([AllDetector.f]));
end

if ~isempty(AllSpindle)
    AverageRefinedGeometry.Spindle = geom.Spindle(...
        'rotationAxis',mean(reshape([AllSpindle.rotationAxis],3,[]),2)',...
        'startingFrame',[],...%AllSpindle(1).startingFrame,...
        'startingAngle',[],...%AllSpindle(1).startingAngle,...
        'oscillationRange',[]); %AllSpindle(1).oscillationRange),...
end

if ~isempty(AllSource)
    AverageRefinedGeometry.Source = geom.Source(...
        'direction',mean(reshape([AllSource.direction],3,[]),2)',...
        'wavelength',mean([AllSource.wavelength]));
end
   
DE = InputGeometry.update(AverageRefinedGeometry);

if ~isempty(AllSpindle)

% store total frame range in Spindle object
DE.Spindle = geom.RotationSeries(DE.Spindle);
DE.Spindle.seriesFrameRange = ...
    [AllSpindle(1).seriesFrameRange(1),AllSpindle(end).seriesFrameRange(2)];

end

end