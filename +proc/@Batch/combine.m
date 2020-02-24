function [tf, errorMessage] = combine(varargin)

options = struct(...
    'workingDirectory','./',...
    'exportIn',{'export.mat'},...
    'matOut','combine.mat',...
    'logOut','combine.log',...
    'mergeNeighbors',false,... 
    'combineBragg',false,...
    'neighborMaxSep',0.5,... % max separation of neighbors in fractions of a wedge
    'fractionRangeBragg',[0.95,1.05],...
    'nws',100,... % some default parameters to pass to ScalingModel
    'nwx',9,...
    'nwy',9);

BatchProcess = proc.Batch('proc.Batch.combine',options,varargin{:});
options = BatchProcess.options; % get post-processed options

try
    BatchProcess.start();
    
    if ischar(options.exportIn)
        options.exportIn = {options.exportIn};
    end
    
    nBatches = length(options.exportIn);
    
    for j=1:nBatches
        
        if options.combineBragg
            [dt,bt,ag] = BatchProcess.readFromMatFile(options.exportIn{j},...
                'diffuseTable','braggTable','AverageGeometry');
            batch(j) = struct(...
                'diffuseTable',dt,...
                'braggTable',bt,...
                'AverageGeometry',ag);
        else
            [dt,ag] = BatchProcess.readFromMatFile(options.exportIn{j},...
                'diffuseTable','AverageGeometry');
            batch(j) = struct(...
                'diffuseTable',dt,...
                'AverageGeometry',ag);
        end
        
    end
    clear dt ag bt % clear up memory
    
    [diffuseTable,braggTable,ScalingModel] = combineScript(1,options,batch);
    
    if options.combineBragg
        BatchProcess.saveToMatFile(options.matOut,...
            'options',options,...
            'diffuseTable',diffuseTable,...
            'braggTable',braggTable,...
            'ScalingModel',ScalingModel);
    else
        BatchProcess.saveToMatFile(options.matOut,...
            'options',options,...
            'diffuseTable',diffuseTable,...
            'ScalingModel',ScalingModel);
    end
    
    BatchProcess.finish;
    
catch errorMessage
    BatchProcess.stop(errorMessage);
end

tf = BatchProcess.hasCompleted;
errorMessage = BatchProcess.errorMessage;

end