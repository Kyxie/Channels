clear;
clc;
tic
%% 数据
N = 1000;               % 重复次数
Op = 3;                 % 病人数
User = 10;              % 总人数
Normal = User - Op;     % 普通人数
Base = 2;               % 基站数
Channel = 5;            % 信道数
SINR = zeros(1, 10);    % SINR
Data = zeros(User, 5);
sigma = 10 ^ -16.2 * 180000;

%% 算法
for iter = 1:N
    Q = Qfunc(User, Base, Channel);
    A = [1 1;
        1 2;
        1 3;
        1 4;
        1 5;
        2 1;
        2 2;
        2 3;
        2 4;
        2 5;];
    for i = 1:User
        [row, ~] = size(A);
        seed = floor(row * rand(1, 1)) + 1;
        Data(i, 1) = i;
        Data(i, 3) = A(seed, 1);
        Data(i, 4) = A(seed, 2);
        Data(i, 5) = Q(i, Data(i, 3), Data(i, 4));
        A(seed, :) = [];
    end

    % 计算SINR
    for i = 1:User
        Qsig = Data(i, 5);
        Basesig = Data(i, 3);
        Channelsig = Data(i, 4);
        for j = 1:User
            if((InvBase(Data(j, 3)) == Basesig) && (Data(j, 4) == Channelsig))
                Qinte = Q(j, Basesig, Channelsig);
            end
        end
        SINR(1, i) = SINR(1, i) + Qsig / (Qinte + sigma);
    end
end

%% 画图
SINR = SINR / N;
bar(1:User, SINR);
grid on;
title("Random");
xlabel("Users");
ylabel("SINR");
time = toc;
%% 保存数据到Excel
xlswrite('Results.xlsx', SINR', 1, 'B2:B11');
xlswrite('Results.xlsx', SINR(1:Op)', 2, 'B2:B4');
SINRNorAve = SINR(Op + 1:User);
SINRNorAve = mean(SINRNorAve);
SINRTotAve = mean(SINR);
xlswrite('Results.xlsx', SINRNorAve, 2, 'B5');
xlswrite('Results.xlsx', SINRTotAve, 2, 'B6');
xlswrite('Results.xlsx', time, 3, 'B2');