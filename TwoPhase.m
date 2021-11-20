clear;
clc;
tic;
%% 数据
N = 1000;               % 重复次数
Op = 3;                 % 病人数
User = 10;              % 总人数
Normal = User - Op;     % 普通人数
Base = 2;               % 基站数
Channel = 5;            % 信道数
Data = zeros(User, 5);  % User*5的表格，格式：人id | Q中的人id | 基站id | 信道id | Q
SINR = zeros(1, 10);    % SINR
sigma = 10 ^ -16.2 * 180000;

%% 算法
for iter = 1:N
    Q = Qfunc(User, Base, Channel);
    QOp = Q(1:Op, :, :);
    QNormal = Q(Op + 1:User, :, :);
    QMatch = Q;
%     disp(QMatch);

    for i = 1:Op
        [Uindex, Bindex, Cindex, Max] = FindMaxQ(QOp);
        Data(i, 1) = i;
        Data(i, 2) = Uindex;
        Data(i, 3) = Bindex;
        Data(i, 4) = Cindex;
        Data(i, 5) = Max;

        % 将整个信道变为0
        QOp(:, :, Cindex) = 0;
        QNormal(:, Bindex, Cindex) = 0;
        QOp(Uindex, :, :) = 0;
    end

    for i = 1:Normal
        [UNorIndex, BNorIndex, CNorIndex, NormalMax] = FindMaxQ(QNormal);
        Data(i + Op, 1) = i + Op;
        Data(i + Op, 2) = UNorIndex + Op;
        Data(i + Op, 3) = BNorIndex;
        Data(i + Op, 4) = CNorIndex;
        Data(i + Op, 5) = NormalMax;

        QNormal(:, BNorIndex, CNorIndex) = 0;
        QNormal(UNorIndex, :, :) = 0;
    end

    for i = 1:Op
        OpChannel = Data(1:Op, 4);
        % 找到不相关的用户
        NonIntList = zeros(1, 1);
        for j = Op + 1:User
            if(ismember(Data(j, 4), OpChannel))
                continue;
            else
                NonIntList(1, j) = Data(j, 2);
            end
        end
        NonIntList(NonIntList == 0) = [];

        % 找到匹配用户
        MatchList = zeros(1, 1);
        for j = Op + 1:User
            if(Data(j, 4) == Data(i, 4))
                MatchList(1, j) = Data(j, 2);
            end
        end
        MatchList(MatchList == 0) = [];

        % 计算匹配用户的干扰Q
        MatchInte = QMatch(MatchList, Data(i, 3), Data(i, 4));

        % 计算其他用户的干扰Q
        OtherInte = zeros(1, User - 2 * Op);
        for j = 1:User - 2 * Op
            OtherInte(1, j) = QMatch(NonIntList(1, j), InvBase(Data(i, 3)), Data(i, 4));
        end

        % 找到其他用户的最小值
        [~, UOtherIndex, ~, OtherMin] = FindMinQ(OtherInte);
        UOtherIndex = NonIntList(1, UOtherIndex);

        % 找到匹配和其他分别对应着Data的哪一行
        % 匹配是MatchList
        % 其他是UOtherIndex
        for j = 1:User
            if(Data(j, 2) == MatchList)
                MatchRow = Data(j, 1);
            end
            if(Data(j, 2) == UOtherIndex)
                OtherRow = Data(j, 1);
            end
        end

        % 如果匹配用户的干扰Q小
        if(MatchInte < OtherMin)
            continue;
        % 交换
        else
            Data(MatchRow, 2) = UOtherIndex;
            Data(OtherRow, 2) = MatchList;
            Data(MatchRow, 5) = QMatch(UOtherIndex, Data(MatchRow, 3), Data(MatchRow, 4));
            Data(OtherRow, 5) = QMatch(MatchList, Data(OtherRow, 3), Data(OtherRow, 4));
        end
    end
    
    Data = sortrows(Data, 2);
    for i = 1:User
        Qsig = Data(i, 5);
        Basesig = Data(i, 3);
        Channelsig = Data(i, 4);
        for j = 1:User
            if((InvBase(Data(j, 3)) == Basesig) && (Data(j, 4) == Channelsig))
                Qinte = QMatch(j, Basesig, Channelsig);
            end
        end
        SINR(1, i) = SINR(1, i) + Qsig / (Qinte + sigma);
    end
end

%% 画图
SINR = SINR / N;
bar(1:User, SINR);
grid on;
title("Two Phase Algrithm");
xlabel("Users");
ylabel("SINR");
time = toc;
%% 保存数据到Excel
xlswrite('Results.xlsx', SINR', 1, 'D2:D11');
xlswrite('Results.xlsx', SINR(1:Op)', 2, 'D2:D4');
SINRNorAve = SINR(Op + 1:User);
SINRNorAve = mean(SINRNorAve);
SINRTotAve = mean(SINR);
xlswrite('Results.xlsx', SINRNorAve, 2, 'D5');
xlswrite('Results.xlsx', SINRTotAve, 2, 'D6');
xlswrite('Results.xlsx', time, 3, 'B4');