function SINR = SINRCal(Data, i)
    sigma = 10 ^ -16.2 * 180000;
    Base = Data(i, 3);
    Channel = Data(i, 4);
    Qsig = Data(i, 5);
    for i = 1:10
    end
    SINR = Qsig / (Qinte + sigma);
end