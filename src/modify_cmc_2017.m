function [M,P] = modify_cmc_2017(M,P,i_model,factor)
%MODIFY_CMC_2017 Modifications as in Adams et al. (2022)
% Modifies M.cmcj and P.G.
switch(i_model)
    case 1
        M.cmcj = [3 5 6 8 9 11 12 13];
        P.G = ones(1,8) * factor;
    case 2
        M.cmcj = [6 11];
        P.G = ones(1,2) * factor;
    case 3
        M.cmcj = 4;
        P.G = factor;
    case 4
        M.cmcj = 4;
        P.G = -factor;
    case 5
        M.cmcj = 7;
        P.G = -factor;
    otherwise
        error('Model %d does not exists. Choose 1,2,3,4,5.', i_model) 
end
end

