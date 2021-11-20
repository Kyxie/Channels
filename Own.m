clear;
clc;
tic
%% ����
N = 1000;               % �ظ�����
Op = 3;                 % ������
User = 10;              % ������
Normal = User - Op;     % ��ͨ����
Base = 2;               % ��վ��
Channel = 5;            % �ŵ���
UserExp = zeros(Base * Channel, 3, User);   % ������������ʽ����վ | �ŵ� | ����
SINR = zeros(1, 10);    % SINR
sigma = 10 ^ -16.2 * 180000;

%% �㷨
for iter = 1:N
    Q = Qfunc(User, Base, Channel);
%     disp(Q);
    QOp = Q(1:Op, :, :);
    QNormal = Q(Op + 1:User, :, :);
    QOther = Q;
    QLast = Q;

    Data = zeros(User, 5);  % User*5�ı�񣬸�ʽ����id | Q�е���id | ��վid | �ŵ�id | Q
    % ����������ѭ�����ҵ�ÿ������������Q��󣩵Ļ�վ�ŵ�
    for i = 1:User
        for j = 1:Base * Channel
            [~, Bindex, Cindex, Max] = FindMaxQ(Q(i, :, :));
            UserExp(j, 1, i) = Bindex;
            UserExp(j, 2, i) = Cindex;
            UserExp(j, 3, i) = Max;
            Q(i, Bindex, Cindex) = 0;
        end
    end

    % HaveBeenChosen��ʾ��ǰ����Ľ��
    HaveBeenChosen = zeros(User, 2);
    IntefereOp = zeros(User, 2);
    % DisOpDone��ʾ��û�гɹ�����Ĳ���������ʼֵΪ1:Op
    DisOpDone = 1:Op;
    while(length(DisOpDone))
        ZeroRow = FindFirstZero(Data);
        Data(ZeroRow, 1) = ZeroRow;
        Data(ZeroRow, 2) = DisOpDone(1, 1);
        Data(ZeroRow, 3) = UserExp(1, 1, DisOpDone(1, 1));
        Data(ZeroRow, 4) = UserExp(1, 2, DisOpDone(1, 1));
        Data(ZeroRow, 5) = UserExp(1, 3, DisOpDone(1, 1));
        HaveBeenChosen(ZeroRow, 1) = Data(ZeroRow, 3);
        HaveBeenChosen(ZeroRow, 2) = Data(ZeroRow, 4);
        IntefereOp(ZeroRow, 1) = InvBase(HaveBeenChosen(ZeroRow, 1));
        IntefereOp(ZeroRow, 2) = HaveBeenChosen(ZeroRow, 2);
        if(ZeroRow == 1)
            DisOpDone(:, 1) = [];
            continue;
        else
            Logic = ismember(HaveBeenChosen(ZeroRow, :), HaveBeenChosen(1:ZeroRow - 1, :), 'rows');
            LogicInte = ismember(HaveBeenChosen(ZeroRow, :), IntefereOp(1:ZeroRow - 1, :), 'rows');
            % �ظ������
            if((Logic == 1) || (LogicInte == 1))
                UserExp(:, :, Data(ZeroRow, 2)) = UpsideDown(UserExp(:, :, Data(ZeroRow, 2)), 1);
                Data(ZeroRow, :) = 0;
                HaveBeenChosen(ZeroRow, :) = 0;
                continue;
            else
                DisOpDone(:, 1) = [];
                continue;
            end
        end
    end

    % ��ÿ�������ҵ�������Ҫ����ͨ��
    % OpExpNormal����ͨ�˱�ţ������Ҫ�ҵ������ı�Ż���Ҫ+3
    OpExpNormal = zeros(Normal, 2, Op); % �� | ����
    for i = 1:Op
        BaseInte = InvBase(Data(i, 3));
        ChannelInte = Data(i, 4);
        QPre = QNormal(:, BaseInte, ChannelInte);
        for j = 1:Normal
            [UNormalIndex, ~, ~, NormalMin] = FindMinQ(QPre);
            OpExpNormal(j, 1, i) = UNormalIndex;
            OpExpNormal(j, 2, i) = NormalMin;
            QPre(UNormalIndex, 1) = 0;
        end
    end

    DisNorDone = 1:Op;
    NorHaveBeenChosen = zeros(Op, 1);
    % ����ǰ������ͨ��
    while(length(DisNorDone))
        ZeroRow = FindFirstZero(Data);
        Data(ZeroRow, 1) = ZeroRow;
        Data(ZeroRow, 2) = OpExpNormal(1, 1, ZeroRow - Op) + Op;
        Data(ZeroRow, 3) = InvBase(Data(ZeroRow - Op, 3));
        Data(ZeroRow, 4) = Data(ZeroRow - Op, 4);
        Data(ZeroRow, 5) = QNormal(OpExpNormal(1, 1, ZeroRow - Op), Data(ZeroRow, 3), Data(ZeroRow, 4));
        NorHaveBeenChosen(ZeroRow - Op, 1) = OpExpNormal(1, 1, ZeroRow - Op) + Op;
        if(ZeroRow == 1 + Op)
            DisNorDone(:, 1) = [];
            continue;
        else
            Logic = ismember(NorHaveBeenChosen(ZeroRow - Op, :), NorHaveBeenChosen(1:ZeroRow - Op - 1, :), 'rows');
            if(Logic == 1)
                OpExpNormal(:, :, ZeroRow - Op) = UpsideDown(OpExpNormal(:, :, ZeroRow - Op), 1);
                Data(ZeroRow, :) = 0;
                NorHaveBeenChosen(ZeroRow - Op, :) = 0;
            else
                DisNorDone(:, 1) = [];
                continue;
            end
        end
    end

    % ����ʣ���ĸ���
    DisOtherDone = zeros(User - 2 * Op, 1);
    OtherHaveBeenChosen = Data(1:2 * Op, 3:4);
    OtherExp = UserExp;
    for i = 1:2 * Op
        j = Data(i, 2);
        OtherExp(:, :, j) = 0;
    end
    for i = 1:User
        if(OtherExp(1, 1, i) ~= 0)
            DisOtherDone(i, 1) = i;
        end
    end
    DisOtherDone(DisOtherDone == 0) = [];
    while(length(DisOtherDone))
        ZeroRow = FindFirstZero(Data);
        Data(ZeroRow, 1) = ZeroRow;
        Data(ZeroRow, 2) = DisOtherDone(1, 1);
        Data(ZeroRow, 3) = OtherExp(1, 1, DisOtherDone(1, 1));
        Data(ZeroRow, 4) = OtherExp(1, 2, DisOtherDone(1, 1));
        Data(ZeroRow, 5) = OtherExp(1, 3, DisOtherDone(1, 1));
        OtherHaveBeenChosen(ZeroRow, 1) = Data(ZeroRow, 3);
        OtherHaveBeenChosen(ZeroRow, 2) = Data(ZeroRow, 4);
        if(length(DisOtherDone) == User - 2 * Op)
            LogicOther = ismember(OtherHaveBeenChosen(ZeroRow, :), OtherHaveBeenChosen(1:ZeroRow - 1, :), 'rows');
            if(LogicOther == 1)
                OtherExp(:, :, DisOtherDone(1, 1)) = UpsideDown(OtherExp(:, :, DisOtherDone(1, 1)), 1);
                Data(ZeroRow, :) = 0;
                OtherHaveBeenChosen(ZeroRow, :) = 0;
                continue;
            else
                DisOtherDone(1, :) = [];
                continue;
            end
        else
            [LogicOtherOther, ChosenIndex] = ismember(OtherHaveBeenChosen(ZeroRow, :), OtherHaveBeenChosen(1:ZeroRow - 1, :), 'rows');
            if(LogicOtherOther == 1)
                if(ChosenIndex <= 2 * Op)
                    OtherExp(:, :, DisOtherDone(1, 1)) = UpsideDown(OtherExp(:, :, DisOtherDone(1, 1)), 1);
                    Data(ZeroRow, :) = 0;
                    OtherHaveBeenChosen(ZeroRow, :) = 0;
                    continue;
                else
                    QFront = Data(ChosenIndex, 5);
                    QBack = Data(ZeroRow, 5);
                    if(QFront < QBack)
                        ShouldbeReplaced = Data(ChosenIndex, 2);
                        Data(ChosenIndex, :) = 0;
                        OtherHaveBeenChosen(ChosenIndex, :) = 0;
                        Data = UpsideDown(Data, ChosenIndex);
                        OtherHaveBeenChosen = UpsideDown(OtherHaveBeenChosen, ChosenIndex);
                        for i = ChosenIndex:ZeroRow - 1
                            Data(i, 1) = Data(i, 1) - 1;
                        end
                        OtherExp(:, :, ShouldbeReplaced) = UpsideDown(OtherExp(:, :, ShouldbeReplaced), 1);
                        DisOtherDone(1, :) = [];
                        DisOtherDone = [ShouldbeReplaced; DisOtherDone];
                    else
                        OtherExp(:, :, DisOtherDone(1, 1)) = UpsideDown(OtherExp(:, :, DisOtherDone(1, 1)), 1);
                        Data(ZeroRow, :) = 0;
                        OtherHaveBeenChosen(ZeroRow, :) = 0;
                        continue;
                    end
                end
            else
                DisOtherDone(1, :) = [];
                continue;
            end
        end
    end

    Data = sortrows(Data, 2);
    % ����SINR
    for i = 1:User
        Qsig = Data(i, 5);
        Basesig = Data(i, 3);
        Channelsig = Data(i, 4);
        for j = 1:User
            if((InvBase(Data(j, 3)) == Basesig) && (Data(j, 4) == Channelsig))
                Qinte = QLast(j, Basesig, Channelsig);
            end
        end
        SINR(1, i) = SINR(1, i) + Qsig / (Qinte + sigma);
    end
end

%% ��ͼ
SINR = SINR / N;
bar(1:User, SINR);
grid on;
title("Own Algrithm");
xlabel("Users");
ylabel("SINR");
time = toc;
%% �������ݵ�Excel
xlswrite('Results.xlsx', SINR', 1, 'F2:F11');
xlswrite('Results.xlsx', SINR(1:Op)', 2, 'F2:F4');
SINRNorAve = SINR(Op + 1:User);
SINRNorAve = mean(SINRNorAve);
SINRTotAve = mean(SINR);
xlswrite('Results.xlsx', SINRNorAve, 2, 'F5');
xlswrite('Results.xlsx', SINRTotAve, 2, 'F6');
xlswrite('Results.xlsx', time, 3, 'B6');