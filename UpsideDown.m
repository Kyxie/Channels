function NewUserExp = UpsideDown(UserExp, RowIndex)
    Row = UserExp(RowIndex, :);
    UserExp(RowIndex, :) = [];
    NewUserExp = [UserExp; Row];
end