function u_taxi = utility_taxi(l_taxi,l_ps,l_pc)
    global unit_cost unit_fare_ps unit_fare_pc
    u_taxi = (unit_fare_ps*l_ps + unit_fare_pc*l_pc - unit_cost*l_taxi)/l_taxi;
end