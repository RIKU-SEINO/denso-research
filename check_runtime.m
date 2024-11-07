clear
tic
for i = 1:1
n = 2;
U = zeros(n,n,n);

U(2:n,2:n,2:n) = rand(n-1,n-1,n-1)-0.8;

[M,u] = triplet_MILP(U);
M = round(M);M
u = u;
end
toc