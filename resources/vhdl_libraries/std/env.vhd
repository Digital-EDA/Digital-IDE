-- Package env as defined by IEEE 1076-2008

package env is
  procedure stop(status : integer);
  procedure stop;

  procedure finish(status : integer);
  procedure finish;

  function resolution_limit return delay_length;
end package;
