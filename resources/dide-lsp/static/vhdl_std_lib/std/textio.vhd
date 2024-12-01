-- Package texio as defined by IEEE 1076-2008

package textio is
  type LINE is access STRING;
  type TEXT is file of STRING;

  procedure FILE_REWIND (file F: TEXT);
  function  FILE_MODE (file F: TEXT) return FILE_OPEN_KIND;
  function  FILE_SIZE (file F: TEXT) return INTEGER;

  type SIDE is (RIGHT, LEFT);
  subtype WIDTH is NATURAL; -- For specifying widths of output fields.

  function JUSTIFY (VALUE: STRING; JUSTIFIED: SIDE := RIGHT; FIELD: WIDTH := 0 ) return STRING;
  -- Standard text files:
  file INPUT: TEXT open READ_MODE is "STD_INPUT";
  file OUTPUT: TEXT open WRITE_MODE is "STD_OUTPUT";

  -- Input routines for standard types:
  procedure READLINE (file F: TEXT; L: inout LINE);
  procedure READ (L: inout LINE; VALUE: out BIT; GOOD: out BOOLEAN);
  procedure READ (L: inout LINE; VALUE: out BIT);
  procedure READ (L: inout LINE; VALUE: out BIT_VECTOR; GOOD: out BOOLEAN);
  procedure READ (L: inout LINE; VALUE: out BIT_VECTOR);
  procedure READ (L: inout LINE; VALUE: out BOOLEAN; GOOD: out BOOLEAN);
  procedure READ (L: inout LINE; VALUE: out BOOLEAN);
  procedure READ (L: inout LINE; VALUE: out CHARACTER; GOOD: out BOOLEAN);
  procedure READ (L: inout LINE; VALUE: out CHARACTER);
  procedure READ (L: inout LINE; VALUE: out INTEGER; GOOD: out BOOLEAN);
  procedure READ (L: inout LINE; VALUE: out INTEGER);
  procedure READ (L: inout LINE; VALUE: out REAL; GOOD: out BOOLEAN);
  procedure READ (L: inout LINE; VALUE: out REAL);
  procedure READ (L: inout LINE; VALUE: out STRING; GOOD: out BOOLEAN);
  procedure READ (L: inout LINE; VALUE: out STRING);
  procedure READ (L: inout LINE; VALUE: out TIME; GOOD: out BOOLEAN);
  procedure READ (L: inout LINE; VALUE: out TIME);
  procedure SREAD (L: inout LINE; VALUE: out STRING; STRLEN: out NATURAL);
  alias STRING_READ is SREAD [LINE, STRING, NATURAL];
  alias BREAD is READ [LINE, BIT_VECTOR, BOOLEAN];
  alias BREAD is READ [LINE, BIT_VECTOR];
  alias BINARY_READ is READ [LINE, BIT_VECTOR, BOOLEAN];
  alias BINARY_READ is READ [LINE, BIT_VECTOR];
  procedure OREAD (L: inout LINE; VALUE: out BIT_VECTOR; GOOD: out BOOLEAN);
  procedure OREAD (L: inout LINE; VALUE: out BIT_VECTOR);
  alias OCTAL_READ is OREAD [LINE, BIT_VECTOR, BOOLEAN];
  alias OCTAL_READ is OREAD [LINE, BIT_VECTOR];
  procedure HREAD (L: inout LINE; VALUE: out BIT_VECTOR; GOOD: out BOOLEAN);
  procedure HREAD (L: inout LINE; VALUE: out BIT_VECTOR);
  alias HEX_READ is HREAD [LINE, BIT_VECTOR, BOOLEAN];
  alias HEX_READ is HREAD [LINE, BIT_VECTOR];

  -- Output routines for standard types:
  procedure WRITELINE (file F: TEXT; L: inout LINE);
  procedure TEE (file F: TEXT; L: inout LINE);
  procedure WRITE (L: inout LINE; VALUE: in BIT; JUSTIFIED: in SIDE:= RIGHT; FIELD: in WIDTH := 0);
  procedure WRITE (L: inout LINE; VALUE: in BIT_VECTOR; JUSTIFIED: in SIDE:= RIGHT; FIELD: in WIDTH := 0);
  procedure WRITE (L: inout LINE; VALUE: in BOOLEAN; JUSTIFIED: in SIDE:= RIGHT; FIELD: in WIDTH := 0);
  procedure WRITE (L: inout LINE; VALUE: in CHARACTER; JUSTIFIED: in SIDE:= RIGHT; FIELD: in WIDTH := 0);
  procedure WRITE (L: inout LINE; VALUE: in INTEGER; JUSTIFIED: in SIDE:= RIGHT; FIELD: in WIDTH := 0);
  procedure WRITE (L: inout LINE; VALUE: in REAL; JUSTIFIED: in SIDE:= RIGHT; FIELD: in WIDTH := 0; DIGITS: in NATURAL:= 0);
  procedure WRITE (L: inout LINE; VALUE: in REAL; FORMAT: in STRING);
  procedure WRITE (L: inout LINE; VALUE: in STRING; JUSTIFIED: in SIDE:= RIGHT; FIELD: in WIDTH := 0);
  procedure WRITE (L: inout LINE; VALUE: in TIME; JUSTIFIED: in SIDE:= RIGHT; FIELD: in WIDTH := 0; UNIT: in TIME:= ns);
  alias SWRITE is WRITE [LINE, STRING, SIDE, WIDTH];
  alias STRING_WRITE is WRITE [LINE, STRING, SIDE, WIDTH];
  alias BWRITE is WRITE [LINE, BIT_VECTOR, SIDE, WIDTH];
  alias BINARY_WRITE is WRITE [LINE, BIT_VECTOR, SIDE, WIDTH];
  procedure OWRITE (L: inout LINE; VALUE: in BIT_VECTOR; JUSTIFIED: in SIDE := RIGHT; FIELD: in WIDTH := 0);
  alias OCTAL_WRITE is OWRITE [LINE, BIT_VECTOR, SIDE, WIDTH];
  procedure HWRITE (L: inout LINE; VALUE: in BIT_VECTOR; JUSTIFIED: in SIDE := RIGHT; FIELD: in WIDTH := 0);
  alias HEX_WRITE is HWRITE [LINE, BIT_VECTOR, SIDE, WIDTH];

end package;
