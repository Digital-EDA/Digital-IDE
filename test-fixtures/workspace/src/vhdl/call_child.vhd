entity call_child is
end entity;

architecture rtl of call_child is
begin
    u_leaf : entity work.call_leaf;
end architecture;
