entity call_top is
end entity;

architecture rtl of call_top is
begin
    u_child : entity work.call_child;
end architecture;
