function [M, fval] = matching_prog(A,B)

length(A)

f = A + B;

[M, fval] = intlinprog(f,);
end