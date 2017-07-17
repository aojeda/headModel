classdef sgt < ParametricEmpiricalBayes
    properties
        B
    end
    methods 
        function obj = sgt(H, B)
            numberOfBasis = size(B,2);
            
            % Form covariance components
            e = zeros(numberOfBasis,1);
            PriorCov = cell(numberOfBasis,1);
            sqrtPriorCov = cell(numberOfBasis,1);
            blocks = logical(eye(numberOfBasis,numberOfBasis));
            for k=1:numberOfBasis
                e(k) = 1;
                PriorCov{k} = sparse(e*e');
                sqrtPriorCov{k} = PriorCov{k};
                e(k) = 0;
            end
            
            % Configure algorithm options
            options = ParametricEmpiricalBayes.initOptions();
            options.lb.verbose = false;
            options.lb.lambda0 = 1;
            options.lb.gamma0 = 1;
            options.peb.verbose = false;
            options.peb.maxIter = 0;
            options.peb.minGamma = 1e-12;
            options.peb.useGPU = false;
            
            % Call base constructor
            obj@ParametricEmpiricalBayes(H*B, PriorCov,sqrtPriorCov,blocks, options)
            obj.B = B;
        end
        function [x, logE] = update(obj,y)
            [x, logE] = update@ParametricEmpiricalBayes(obj,y);
            x = obj.B*x;
        end
    end
end
