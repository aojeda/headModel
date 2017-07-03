# Add your own inverse methods
New inverse methods can be easily added by implementing an interface between your method and the `headModel` object. We explain how this process works next.

1- Implement your interface function using the following prototype:
```matlab
function solver = solverName(hm)
%
% Your code goes here
%
end
```
where `solver` is an object that implements the method `update` with the following prototype:
```matlab
function x = update(obj, y)
%
% Implement the inverse mapping x = f(y) here.
%
end
```
2- Save the function `solverName.m` in `headModel/plugins/`.

### Example 1: Minimum Norm inverse solver
In this example, we write a plugin to compute the minimum norm (MN) source estimates using as prior source covariance the identity matrix. It is trivial to write this solver as it can be obtained from `loreta`, which is already implemented. Save the following function in `headModel/plugins/`:
```matlab
function solver = minimumNorm(hm)
    W = speye(size(hm.cortex.vertices,1));
    solver = loreta(hm, W);
end
```
Note that we do not need to implement the method `update` as it is already in the class `loreta`.

### Example 2: LASSO inverse solver
In this example, we implement source estimation subject to sparsity constraints using L1 regularization (see the [LASSO](https://statweb.stanford.edu/~tibs/lasso/lasso.pdf) paper). Fortunately, there is a `lasso` solver implemented in MATLAB since R2011b, which we can use. 

First, we write the following interface function:
```matlab
function solver = lassoSolver(hm)
    solver = inverseSolverLasso(hm);
end
```
and save it in `headModel/plugins/`.

Second, we implement the class `inverseSolverLasso` and save it in a folder that is on MATLAB's search path:
```matlab
classdef inverseSolverLasso < handle
    % Estimate EEG distributed sources using the LASSO method.
    properties
        H
    end
    methods
        function obj = inverseSolverLasso(hm)
            % Save the lead field matrix in H
            obj.H = hm.K;
        end
        function x = update(obj, y)
            % Call MATLAB's lasso solver
            x = lasso(obj.H, y);
        end
    end
end
```

MATLAB's [lassso](https://www.mathworks.com/help/stats/lasso.html) function has many options that can be incorporated into the wrapper class `inverseSolverLasso`, which could be of interest for EEG source estimation. 

Feel free to reach out to me if you need any question.