clear;
clc;
tic;
%% ����
N = 1000;               % �ظ�����
Op = 3;                 % ������
User = 10;              % ������
Normal = User - Op;     % ��ͨ����
Base = 2;               % ��վ��
Channel = 5;            % �ŵ���
Data = zeros(User, 5);  % User*5�ı�񣬸�ʽ����id | Q�е���id | ��վid | �ŵ�id | Q
SINR = zeros(1, 10);    % SINR
sigma = 10 ^ -16.2 * 180000;

%% �㷨
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

        % �������ŵ���Ϊ0
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
        % �ҵ�����ص��û�
        NonIntList = zeros(1, 1);
        for j = Op + 1:User
            if(ismember(Data(j, 4), OpChannel))
                continue;
            else
                NonIntList(1, j) = Data(j, 2);
            end
        end
        NonIntList(NonIntList == 0) = [];

        % �ҵ�ƥ���û�
        MatchList = zeros(1, 1);
        for j = Op + 1:User
            if(Data(j, 4) == Data(i, 4))
                MatchList(1, j) = Data(j, 2);
            end
        end
        MatchList(MatchList == 0) = [];

        % ����ƥ���û��ĸ���Q
        MatchInte = QMatch(MatchList, Data(i, 3), Data(i, 4));

        % ���������û��ĸ���Q
        OtherInte = zeros(1, User - 2 * Op);
        for j = 1:User - 2 * Op
            OtherInte(1, j) = QMatch(NonIntList(1, j), InvBase(Data(i, 3)), Data(i, 4));
        end

        % �ҵ������û�����Сֵ
        [~, UOtherIndex, ~, OtherMin] = FindMinQ(OtherInte);
        UOtherIndex = NonIntList(1, UOtherIndex);

        % �ҵ�ƥ��������ֱ��Ӧ��Data����һ��
        % ƥ����MatchList
        % ������UOtherIndex
        for j = 1:User
            if(Data(j, 2) == MatchList)
                MatchRow = Data(j, 1);
            end
            if(Data(j, 2) == UOtherIndex)
                OtherRow = Data(j, 1);
            end
        end

        % ���ƥ���û��ĸ���QС
        if(MatchInte < OtherMin)
            continue;
        % ����
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

%% ��ͼ
SINR = SINR / N;
bar(1:User, SINR);
grid on;
title("Two Phase Algrithm");
xlabel("Users");
ylabel("SINR");
time = toc;
%% �������ݵ�Excel
xlswrite('Results.xlsx', SINR', 1, 'D2:D11');
xlswrite('Results.xlsx', SINR(1:Op)', 2, 'D2:D4');
SINRNorAve = SINR(Op + 1:User);
SINRNorAve = mean(SINRNorAve);
SINRTotAve = mean(SINR);
xlswrite('Results.xlsx', SINRNorAve, 2, 'D5');
xlswrite('Results.xlsx', SINRTotAve, 2, 'D6');
xlswrite('Results.xlsx', time, 3, 'B4');