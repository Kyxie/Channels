function [MinQ, MinIndex] = FindMinIntQ(NonInt)
    [row, ~] = size(NonInt);
    Min = 1;
    for i = 1:row
        if(NonInt(i, 3) <= Min)
            Min = NonInt(i, 3);
            MinIndex = i;
        end
    end
    MinQ = Min;
end