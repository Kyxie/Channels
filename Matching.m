clear;
clc;
tic
%% 数据
N = 1000;                                   % 重复次数
Op = 3;                                     % 病人数
User = 10;                                  % 总人数
Normal = User - Op;                         % 普通人数
Base = 2;                                   % 基站数
Channel = 5;                                % 信道数
UserExp = zeros(Base * Channel, 3, User);   % 人物期望表，格式：基站 | 信道 | 能量
ChannelExp = zeros(User, 4, Base * Channel);% 信道期望表，格式：基站 | 信道 | 人 | 能量
SINR = zeros(1, 10);                        % SINR
sigma = 10 ^ -16.2 * 180000;
%% 算法
for iter = 1:N
    Q = Qfunc(User, Base, Channel);
%     disp(Q);
    QBC = Q;
    QOp = Q;
    
    Data = zeros(User, 5);                      % User*5的表格，格式：人id | Q中的人id | 基站id | 信道id | Q
    
    % 对所有人做循环，找到每个人最期望（Q最大）的基站信道
    for i = 1:User
        for j = 1:Base * Channel
            [~, Bindex, Cindex, Max] = FindMaxQ(Q(i, :, :));
            UserExp(j, 1, i) = Bindex;
            UserExp(j, 2, i) = Cindex;
            UserExp(j, 3, i) = Max;
            Q(i, Bindex, Cindex) = 0;
        end
    end

    for i = 1:Base * Channel
        % ChannelExp初始化
        ChannelExp(:, 1, i) = floor(i / (Channel + 1)) + 1;
        if(i <= Channel)
            ChannelExp(:, 2, i) = mod(i, Channel + 1);
        elseif(i == Base * Channel)
            ChannelExp(:, 2, i) = Channel;
        else
            ChannelExp(:, 2, i) = mod(i, Channel);
        end

        % 对基站信道做循环，找到每个[基站，信道]最期望（Q最小）的人
        for j = 1:User
            [UBCindex, ~, ~, BCMin] = FindMinQ(QBC(:, InvBase(ChannelExp(1, 1, i)), ChannelExp(1, 2, i)));
            ChannelExp(j, 3, i) = UBCindex;
            ChannelExp(j, 4, i) = BCMin;
            QBC(UBCindex, InvBase(ChannelExp(1, 1, i)), ChannelExp(1, 2, i)) = 0;
        end
    end

    % HaveBeenChosen表示当前分配的结果
    HaveBeenChosen = zeros(User, 2);
    % DisOpDone表示还没有成功分配的病人数，初始值为1:Op
    DisOpDone = 1:User;
    while(length(DisOpDone))
        ZeroRow = FindFirstZero(Data);
        Data(ZeroRow, 1) = ZeroRow;
        Data(ZeroRow, 2) = DisOpDone(1, 1);
        Data(ZeroRow, 3) = UserExp(1, 1, DisOpDone(1, 1));
        Data(ZeroRow, 4) = UserExp(1, 2, DisOpDone(1, 1));
        Data(ZeroRow, 5) = UserExp(1, 3, DisOpDone(1, 1));
        HaveBeenChosen(ZeroRow, 1) = Data(ZeroRow, 3);
        HaveBeenChosen(ZeroRow, 2) = Data(ZeroRow, 4);
        % 第一个人不需要查重
        if(ZeroRow == 1)
            DisOpDone(:, 1) = [];
            continue;
        else
            [Logic, ChosenIndex] = ismember(HaveBeenChosen(ZeroRow, :), HaveBeenChosen(1:ZeroRow - 1, :), 'rows');
            % 有重复
            if(Logic == 1)
                QFront = QOp(ChosenIndex, InvBase(HaveBeenChosen(ZeroRow, 1)), HaveBeenChosen(ZeroRow, 2));
                QBack = QOp(ZeroRow, InvBase(HaveBeenChosen(ZeroRow, 1)), HaveBeenChosen(ZeroRow, 2));
                % 守擂成功
                if(QFront < QBack)
                    % 先把第ZeroRow个人的UserExp的第一行调至最后一行（最不想要）
                    UserExp(:, :, Data(ZeroRow, 2)) = UpsideDown(UserExp(:, :, Data(ZeroRow, 2)), 1);
                    % 再把刚才分配的变0（第一列不能变）
                    Data(ZeroRow, :) = 0;
                    HaveBeenChosen(ZeroRow, :) = 0;
                    continue;
                else
                    ShouldbeReplaced = Data(ChosenIndex, 2);
                    % 先把ChosenIndex那一行变0
                    Data(ChosenIndex, :) = 0;
                    HaveBeenChosen(ChosenIndex, :) = 0;
                    % 再把这一行放到最后
                    Data = UpsideDown(Data, ChosenIndex);
                    HaveBeenChosen = UpsideDown(HaveBeenChosen, ChosenIndex);
                    % 修改Data第一列的序号
                    for i = ChosenIndex:ZeroRow - 1
                        Data(i, 1) = Data(i, 1) - 1;
                    end
                    % 再把第ChosenIndex个人的UserExp的第一行调至最后一行（最不想要）
                    UserExp(:, :, ShouldbeReplaced) = UpsideDown(UserExp(:, :, ShouldbeReplaced), 1);

                    DisOpDone(:, 1) = [];
                    % 最后把第ChosenIndex个人加入DisOpDone的最前面
                    DisOpDone = [ShouldbeReplaced, DisOpDone];
                    continue;
                end 
            else
                DisOpDone(:, 1) = [];
                continue;
            end
        end
    end

%     % DisNormalDone表示还没有成功分配的普通人数，初始值为1:Normal 
%     DisNormalDone = 1:Normal;
%     while(length(DisNormalDone))
%         ZeroRow = FindFirstZero(Data);
%         Data(ZeroRow, 1) = ZeroRow;
%         Data(ZeroRow, 2) = DisNormalDone(1, 1) + Op;
%         Data(ZeroRow, 3) = UserExp(1, 1, DisNormalDone(1, 1) + Op);
%         Data(ZeroRow, 4) = UserExp(1, 2, DisNormalDone(1, 1) + Op);
%         Data(ZeroRow, 5) = UserExp(1, 3, DisNormalDone(1, 1) + Op);
%         HaveBeenChosen(ZeroRow, 1) = Data(ZeroRow, 3);
%         HaveBeenChosen(ZeroRow, 2) = Data(ZeroRow, 4);
%         % 这里第一个人也需要查重了
%         [Logic, ChosenIndex] = ismember(HaveBeenChosen(ZeroRow, :), HaveBeenChosen(1:ZeroRow - 1, :), 'rows');
%         % 有重复
%         if(Logic == 1)
%             % 普通人无权干涉病人的选择
%             if(ChosenIndex <= Op)
%                 % 普通人的期望改变
%                 UserExp(:, :, DisNormalDone(1, 1) + Op) = UpsideDown(UserExp(:, :, DisNormalDone(1, 1) + Op), 1);
%                 % 将刚才分配的变为0
%                 Data(ZeroRow, :) = 0;
%                 HaveBeenChosen(ZeroRow, :) = 0;
%                 continue;
%             else
%                 QFront = QOp(Data(ChosenIndex, 2), InvBase(HaveBeenChosen(ZeroRow, 1)), HaveBeenChosen(ZeroRow, 2));
%                 QBack = QOp(ZeroRow, InvBase(HaveBeenChosen(ZeroRow, 1)), HaveBeenChosen(ZeroRow, 2));
%                 % 守擂成功
%                 if(QFront < QBack)
%                     % 先把刚才分配的变0（第一列不能变）
%                     Data(ZeroRow, :) = 0;
%                     HaveBeenChosen(ZeroRow, :) = 0;
%                     % 再把第DisNormalDone(1, 1) + Op个人的UserExp的第一行调至最后一行（最不想要）
%                     UserExp(:, :, DisNormalDone(1, 1) + Op) = UpsideDown(UserExp(:, :, DisNormalDone(1, 1) + Op), 1);
%                     continue;
%                 else
%                     % 先把ChosenIndex那一行变0
%                     Data(ChosenIndex, :) = 0;
%                     HaveBeenChosen(ChosenIndex, :) = 0;
%                     % 再把这一行放到最后
%                     Data = UpsideDown(Data, ChosenIndex);
%                     HaveBeenChosen = UpsideDown(HaveBeenChosen, ChosenIndex);
%                     % 修改Data第一列的序号
%                     for i = ChosenIndex:ZeroRow - 1
%                         Data(i, 1) = Data(i, 1) - 1;
%                     end
%                     % 再把第ChosenIndex个人的UserExp的第一行调至最后一行（最不想要）
%                     UserExp(:, :, Data(ChosenIndex, 2)) = UpsideDown(UserExp(:, :, Data(ChosenIndex, 2)), 1);
% 
%                     DisNormalDone(:, 1) = [];
%                     % 最后把第ChosenIndex个人加入DisOpDone的最前面
%                     DisNormalDone = [Data(ChosenIndex, 2) - Op, DisNormalDone];
%                     continue;
%                 end
%             end
%         else
%             DisNormalDone(:, 1) = [];
%             continue;
%         end
%     end
    
%     Data = sortrows(Data, 2);
    % 计算SINR
    for i = 1:User
        Qsig = Data(i, 5);
        Basesig = Data(i, 3);
        Channelsig = Data(i, 4);
        for j = 1:User
            if((InvBase(Data(j, 3)) == Basesig) && (Data(j, 4) == Channelsig))
                Qinte = QOp(j, Basesig, Channelsig);
            end
        end
        SINR(1, i) = SINR(1, i) + Qsig / (Qinte + sigma);
    end
end

%% 画图
SINR = SINR / N;
bar(1:User, SINR);
grid on;
title("Matching Algrithm");
xlabel("Users");
ylabel("SINR");
time = toc;
% 删掉第二列
Data(:, 2) = [];

%% 保存数据到Excel
xlswrite('Results.xlsx', SINR', 1, 'E2:E11');
xlswrite('Results.xlsx', SINR(1:Op)', 2, 'E2:E4');
SINRNorAve = SINR(Op + 1:User);
SINRNorAve = mean(SINRNorAve);
SINRTotAve = mean(SINR);
xlswrite('Results.xlsx', SINRNorAve, 2, 'E5');
xlswrite('Results.xlsx', SINRTotAve, 2, 'E6');
xlswrite('Results.xlsx', time, 3, 'B5');