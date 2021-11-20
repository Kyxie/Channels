function [Uindex, Bindex, Cindex, Min] = FindMinQ(Q)
    Min = 1;
    [U, B, C] = size(Q);
    for i = 1:U
        for j = 1:B
            for k = 1:C
                if((Q(i, j, k) <= Min) && (Q(i, j, k) ~= 0))
                    Min = Q(i, j, k);
                    Uindex = i;
                    Bindex = j;
                    Cindex = k;
                end
            end
        end
    end
end