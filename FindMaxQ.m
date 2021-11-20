function [Uindex, Bindex, Cindex, Max] = FindMaxQ(Q)
    Max = 0;
    [U, B, C] = size(Q);
    for i = 1:U
        for j = 1:B
            for k = 1:C
                if(Q(i, j, k) >= Max)
                    Max = Q(i, j, k);
                    Uindex = i;
                    Bindex = j;
                    Cindex = k;
                end
            end
        end
    end
end