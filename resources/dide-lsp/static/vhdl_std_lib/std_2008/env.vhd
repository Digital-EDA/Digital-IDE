package ENV is
  procedure STOP (STATUS: INTEGER);
  procedure STOP;
  procedure FINISH (STATUS: INTEGER);
  procedure FINISH;
  function RESOLUTION_LIMIT return DELAY_LENGTH;
  attribute foreign of ENV: package is "NO C code generation";
  attribute foreign of STOP[INTEGER] : procedure is "vhdl_stop";
  attribute foreign of FINISH[INTEGER] : procedure is "vhdl_finish";
  attribute foreign of RESOLUTION_LIMIT : function is "vhdl_resolution_limit";
end package ENV;

package body ENV is

  procedure STOP (STATUS: INTEGER) is
  begin
  end;
  
  procedure STOP is
  begin
    stop(0);
  end;

  procedure FINISH (STATUS: INTEGER) is
  begin
  end;

  procedure FINISH is
  begin
    finish(0);
  end;

  function RESOLUTION_LIMIT return DELAY_LENGTH is
  begin
    return 0 ns;
  end;

end package body ENV;
