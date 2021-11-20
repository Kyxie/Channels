function Amw = Afunc(U, B)    % A与用户和基站有关
    distance = (600 - 300) * rand(U * B, 1) + 300;  % 生成U*B个随机数，范围在[300, 600]，distance为1*(U*B)的矩阵
    distance = reshape(distance, U, B); % 将distance修改shape，变为U*B的矩阵
    AdBm = 128 + 37.6 .* log10(distance ./ 1000);
    Amw = 10 .^ (-AdBm / 10);
end