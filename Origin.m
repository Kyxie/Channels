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
Data = zeros(User, 5);  % User*5�ı�񣬸�ʽ����id | Q�е���id | ��վid | �ŵ�id | Q
SINR = zeros(1, 10);    % SINR
sigma = 10 ^ -16.2 * 180000;
%% �㷨
for iter = 1:N
    Q = Qfunc(User, Base, Channel);
    QOp = Q(1:Op, :, :);
    QNormal = Q(Op + 1:User, :, :);

    % �Բ��˷���Q
    for i = 1:Op
        [Uindex, Bindex, Cindex, Max] = FindMaxQ(QOp);
        Data(i, 1) = i;
        Data(i, 2) = Uindex;
        Data(i, 3) = Bindex;
        Data(i, 4) = Cindex;
        Data(i, 5) = Max;

        % �������ŵ���Ϊ0
        QOp(:, :, Cindex) = 0;
        QOp(Uindex, :, :) = 0;

        QPre = zeros(Normal, 2);
        for j = 1:Normal
            QPre(j, 1) = j;
            QPre(j, 2) = QNormal(j, InvBase(Data(i, 3)), Data(i, 4));
        end

        [UNorIndex, ~, ~, Min] = FindMinQ(QPre);
        Data(i + Op, 1) = i + Op;
        Data(i + Op, 2) = UNorIndex + Op;
        Data(i + Op, 3) = InvBase(Data(i, 3));
        Data(i + Op, 4) = Data(i, 4);
        Data(i + Op, 5) = QNormal(UNorIndex, InvBase(Data(i, 3)), Data(i, 4));
        QNormal(UNorIndex, :, :) = 0;
        QNormal(:, Data(i + Op, 3), Data(i + Op, 4)) = 0;
        QNormal(:, Data(i, 3), Data(i, 4)) = 0;
    end

    for i = 1:User - 2 * Op
        [UOtherIndex, BOtherIndex, COtherIndex, OtherMax] = FindMaxQ(QNormal);
        Data(i + 2 * Op, 1) = i + 2 * Op;
        Data(i + 2 * Op, 2) = UOtherIndex + Op;
        Data(i + 2 * Op, 3) = BOtherIndex;
        Data(i + 2 * Op, 4) = COtherIndex;
        Data(i + 2 * Op, 5) = Max;

        QNormal(UOtherIndex, :, :) = 0;
        QNormal(:, BOtherIndex, COtherIndex) = 0;
    end

    Data = sortrows(Data, 2);
    % ����SINR
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

%% ��ͼ
SINR = SINR / N;
bar(1:User, SINR);
grid on;
title("Origin Algrithm");
xlabel("Users");
ylabel("SINR");
time = toc;
%% �������ݵ�Excel
xlswrite('Results.xlsx', SINR', 1, 'C2:C11');
xlswrite('Results.xlsx', SINR(1:Op)', 2, 'C2:C4');
SINRNorAve = SINR(Op + 1:User);
SINRNorAve = mean(SINRNorAve);
SINRTotAve = mean(SINR);
xlswrite('Results.xlsx', SINRNorAve, 2, 'C5');
xlswrite('Results.xlsx', SINRTotAve, 2, 'C6');
xlswrite('Results.xlsx', time, 3, 'B3');