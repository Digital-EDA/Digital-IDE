entity top_vhdl is
    port (
        input_signal  : in boolean;
        output_signal : out boolean
    );
end entity;

architecture rtl of top_vhdl is
    signal target : boolean := false;
begin
    target <= input_signal;
    output_signal <= target;
end architecture;
