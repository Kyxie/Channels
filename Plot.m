clear;
clc;
%% 画第一个图
figure
Data = xlsread('Results.xlsx', 1);
bar(Data(1:10, 2:6));
title('ABC');
xlabel('User ID');
ylabel('SINR');
legend('Random','Origin','Two Phase','Matching','Own');
set(gca,'ygrid','on');

%% 画第二个图
figure
Data = xlsread('Results.xlsx', 2);
x = 1:5;
y = Data(1:5, 2:6);
for i = 1:4
    plot(x, y(i, :), '-*', 'LineWidth', 2);
    hold on;
end
plot(x, y(5, :), '--*', 'LineWidth', 2);
set(gca,'XTick',1:5);
set(gca,'XTickLabel',{'Random','Origin','Two Phase','Matching','Own'});
title('ABC');
xlabel('Algorithms');
ylabel('SINR');
legend('Patient 1', 'Patient 2', 'Patient 3', 'Normal');
set(gca,'ygrid','on');

%% 画第三个图
figure
Data = xlsread('Results.xlsx', 3);
x = 1:5;
y = Data;
plot(x, y, '-*', 'LineWidth', 2);
set(gca,'XTick',1:5);
set(gca,'XTickLabel',{'Random','Origin','Two Phase','Matching','Own'});
title('ABC');
xlabel('Algorithms');
ylabel('Time (s)');
set(gca,'ygrid','on');