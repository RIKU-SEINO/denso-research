function[EBP_M,n_EBP]=mixed_EBP(M_opt,U_v,U_ps,iter)

 [i, j, k] = size(M_opt);

EBP_M = zeros(i, j, k);
n_EBP = 0;


if all([i, j, k] >= 2)
    
    index = (M_opt == 1) ;

end

index(1,:,:)=0;
index(:,1,:)=0;
index(:,:,1)=0;


 for ii=2:i
     for jj=2:j
         for kk=2:k
             if (index(ii,jj,kk))&(U_v(ii,jj,kk)+U_ps(ii,jj,kk)<U_v(ii,jj,1)+U_ps(ii,jj,1))
                 EBP_M(ii,jj,kk)=1;
                 n_EBP=n_EBP+1;
%                   disp('iter')
%                  disp(iter)
%                  disp(U_v(ii,jj,kk)+U_ps(ii,jj,kk)-U_v(ii,jj,1)-U_ps(ii,jj,1))
%                  disp('ijk')
%                  disp(ii)
%                  disp(jj)
%                  disp(kk)
             end
         end
     end
 end


