function ZeroRow = FindFirstZero(Data)
    [row, ~] = size(Data);
    for i = 1:row
        if(Data(i, 1) == 0)
            ZeroRow = i;
            break;
        end
    end
end