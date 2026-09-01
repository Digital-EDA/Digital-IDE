entity invalid_vhdl is
end entity;

architecture rtl of invalid_vhdl is
    signal target : boolean := false;
begin
    missing_signal <= target;
end architecture;
