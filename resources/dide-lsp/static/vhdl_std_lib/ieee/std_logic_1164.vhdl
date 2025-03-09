-- --------------------------------------------------------------------
--
-- Copyright © 2008 by IEEE. All rights reserved.
--
-- This source file is an essential part of IEEE Std 1076-2008, 
-- IEEE Standard VHDL Language Reference Manual. Verbatim copies of This
-- source file may be used and distributed without restriction.
-- Modifications to this source file as permitted in IEEE Std 1076-2008
-- may also be made and distributed. All other uses require permission
-- from the IEEE Standards Department(stds-ipr@ieee.org). 
-- All other rights reserved.
-- 
--   Title     :  Standard multivalue logic package
--             :  (STD_LOGIC_1164 package declaration)
--             :
--   Library   :  This package shall be compiled into a library
--             :  symbolically named IEEE.
--             :
--   Developers:  IEEE model standards group (PAR 1164),
--             :  Accellera VHDL-TC, and IEEE P1076 Working Group
--             :
--   Purpose   :  This packages defines a standard for designers
--             :  to use in describing the interconnection data types
--             :  used in vhdl modeling.
--             :
--   Limitation:  The logic system defined in this package may
--             :  be insufficient for modeling switched transistors,
--             :  since such a requirement is out of the scope of this
--             :  effort. Furthermore, mathematics, primitives,
--             :  timing standards, etc. are considered orthogonal
--             :  issues as it relates to this package and are therefore
--             :  beyond the scope of this effort.
--             :
--   Note      :  This package may be modified to include additional data
--             :  required by tools, but it must in no way change the
--             :  external interfaces or simulation behavior of the
--             :  description. It is permissible to add comments and/or
--             :  attributes to the package declarations, but not to change
--             :  or delete any original lines of the package declaration.
--             :  The package body may be changed only in accordance with
--             :  the terms of Clause 16 of this standard.
--             :
-- --------------------------------------------------------------------
-- $Revision: 1.5 $
-- $Date: 2016/04/08 07:56:22 $
-- --------------------------------------------------------------------

use STD.TEXTIO.all;

package std_logic_1164 is

  -------------------------------------------------------------------    
  -- logic state system  (unresolved)
  -------------------------------------------------------------------    
  type STD_ULOGIC is ( 'U',             -- Uninitialized
                       'X',             -- Forcing  Unknown
                       '0',             -- Forcing  0
                       '1',             -- Forcing  1
                       'Z',             -- High Impedance   
                       'W',             -- Weak     Unknown
                       'L',             -- Weak     0       
                       'H',             -- Weak     1       
                       '-'              -- Don't care
                       );

  -------------------------------------------------------------------    
  -- Directives for synthesis of std_ulogic.
  -- Declare the type encoding attribute and set the value for std_ulogic
  -- Directives for the resolution function and all other function are 
  -- in the package body
  -------------------------------------------------------------------    
  ATTRIBUTE logic_type_encoding : string ;
  ATTRIBUTE logic_type_encoding of std_ulogic:type is
    -- ('U','X','0','1','Z','W','L','H','-') 
    ('X','X','0','1','Z','X','0','1','X') ; 

  -------------------------------------------------------------------    
  -- Declare the synthesis-directive attribute; to be set on 
  -- basic functions that are difficult for synthesis 
  -------------------------------------------------------------------    
  ATTRIBUTE synthesis_return : string ;
  ATTRIBUTE is_signed : boolean ;

  -------------------------------------------------------------------    
  -- unconstrained array of std_ulogic for use with the resolution function
  -- and for use in declaring signal arrays of unresolved elements
  -------------------------------------------------------------------    
  type STD_ULOGIC_VECTOR is array (NATURAL range <>) of STD_ULOGIC;

  -------------------------------------------------------------------    
  -- resolution function
  -------------------------------------------------------------------    
  function resolved (s : STD_ULOGIC_VECTOR) return STD_ULOGIC;


  -------------------------------------------------------------------    
  -- logic state system  (resolved)
  -------------------------------------------------------------------    
  subtype STD_LOGIC is resolved STD_ULOGIC;

  -- Xilinx begin (160405)
  -- Begin: VIPER #9548/8783: Mixed dialect: vhdl-1993 package specific additions
  type STD_LOGIC_VECTOR_93 is array (NATURAL range <>) of STD_LOGIC ;
  -- Xilinx end (160405)
  -------------------------------------------------------------------    
  -- unconstrained array of resolved std_ulogic for use in declaring
  -- signal arrays of resolved elements
  -------------------------------------------------------------------    
  subtype STD_LOGIC_VECTOR is (resolved) STD_ULOGIC_VECTOR;

  -------------------------------------------------------------------    
  -- common subtypes
  -------------------------------------------------------------------    
  subtype X01 is resolved STD_ULOGIC range 'X' to '1';    -- ('X','0','1') 
  subtype X01Z is resolved STD_ULOGIC range 'X' to 'Z';   -- ('X','0','1','Z') 
  subtype UX01 is resolved STD_ULOGIC range 'U' to '1';   -- ('U','X','0','1') 
  subtype UX01Z is resolved STD_ULOGIC range 'U' to 'Z';  -- ('U','X','0','1','Z') 

  -------------------------------------------------------------------    
  -- overloaded logical operators
  -------------------------------------------------------------------    

  function "and"  (l : STD_ULOGIC; r : STD_ULOGIC) return UX01;
  function "nand" (l : STD_ULOGIC; r : STD_ULOGIC) return UX01;
  function "or"   (l : STD_ULOGIC; r : STD_ULOGIC) return UX01;
  function "nor"  (l : STD_ULOGIC; r : STD_ULOGIC) return UX01;
  function "xor"  (l : STD_ULOGIC; r : STD_ULOGIC) return UX01;
  function "xnor" (l : STD_ULOGIC; r : STD_ULOGIC) return UX01;
  function "not"  (l : STD_ULOGIC) return UX01;

  -------------------------------------------------------------------    
  -- vectorized overloaded logical operators
  -------------------------------------------------------------------    
  function "and"  (l, r : STD_ULOGIC_VECTOR) return STD_ULOGIC_VECTOR;
  function "nand" (l, r : STD_ULOGIC_VECTOR) return STD_ULOGIC_VECTOR;
  function "or"   (l, r : STD_ULOGIC_VECTOR) return STD_ULOGIC_VECTOR;
  function "nor"  (l, r : STD_ULOGIC_VECTOR) return STD_ULOGIC_VECTOR;
  function "xor"  (l, r : STD_ULOGIC_VECTOR) return STD_ULOGIC_VECTOR;
  function "xnor" (l, r : STD_ULOGIC_VECTOR) return STD_ULOGIC_VECTOR;
  function "not"  (l    : STD_ULOGIC_VECTOR) return STD_ULOGIC_VECTOR;

  function "and"  (l : STD_ULOGIC_VECTOR; r : STD_ULOGIC) return STD_ULOGIC_VECTOR;
  function "and"  (l : STD_ULOGIC; r : STD_ULOGIC_VECTOR) return STD_ULOGIC_VECTOR;

  function "nand" (l : STD_ULOGIC_VECTOR; r : STD_ULOGIC) return STD_ULOGIC_VECTOR;
  function "nand" (l : STD_ULOGIC; r : STD_ULOGIC_VECTOR) return STD_ULOGIC_VECTOR;

  function "or"   (l : STD_ULOGIC_VECTOR; r : STD_ULOGIC) return STD_ULOGIC_VECTOR;
  function "or"   (l : STD_ULOGIC; r : STD_ULOGIC_VECTOR) return STD_ULOGIC_VECTOR;

  function "nor"  (l : STD_ULOGIC_VECTOR; r : STD_ULOGIC) return STD_ULOGIC_VECTOR;
  function "nor"  (l : STD_ULOGIC; r : STD_ULOGIC_VECTOR) return STD_ULOGIC_VECTOR;

  function "xor"  (l : STD_ULOGIC_VECTOR; r : STD_ULOGIC) return STD_ULOGIC_VECTOR;
  function "xor"  (l : STD_ULOGIC; r : STD_ULOGIC_VECTOR) return STD_ULOGIC_VECTOR;

  function "xnor" (l : STD_ULOGIC_VECTOR; r : STD_ULOGIC) return STD_ULOGIC_VECTOR;
  function "xnor" (l : STD_ULOGIC; r : STD_ULOGIC_VECTOR) return STD_ULOGIC_VECTOR;

  function "and"  (l : STD_ULOGIC_VECTOR) return STD_ULOGIC;
  function "nand" (l : STD_ULOGIC_VECTOR) return STD_ULOGIC;
  function "or"   (l : STD_ULOGIC_VECTOR) return STD_ULOGIC;
  function "nor"  (l : STD_ULOGIC_VECTOR) return STD_ULOGIC;
  function "xor"  (l : STD_ULOGIC_VECTOR) return STD_ULOGIC;
  function "xnor" (l : STD_ULOGIC_VECTOR) return STD_ULOGIC;

  -------------------------------------------------------------------
  -- shift operators
  -------------------------------------------------------------------

  function "sll" (l : STD_ULOGIC_VECTOR; r : INTEGER) return STD_ULOGIC_VECTOR;
  function "srl" (l : STD_ULOGIC_VECTOR; r : INTEGER) return STD_ULOGIC_VECTOR;
  function "rol" (l : STD_ULOGIC_VECTOR; r : INTEGER) return STD_ULOGIC_VECTOR;
  function "ror" (l : STD_ULOGIC_VECTOR; r : INTEGER) return STD_ULOGIC_VECTOR;

  -------------------------------------------------------------------
  -- conversion functions
  -------------------------------------------------------------------
  function To_bit       (s : STD_ULOGIC; xmap : BIT        := '0') return BIT;
  function To_bitvector (s : STD_ULOGIC_VECTOR; xmap : BIT := '0') return BIT_VECTOR;

  function To_StdULogic       (b : BIT) return STD_ULOGIC;
  function To_StdLogicVector  (b : BIT_VECTOR) return STD_LOGIC_VECTOR;
  function To_StdLogicVector  (s : STD_ULOGIC_VECTOR) return STD_LOGIC_VECTOR;
  function To_StdULogicVector (b : BIT_VECTOR) return STD_ULOGIC_VECTOR;
  function To_StdULogicVector (s : STD_LOGIC_VECTOR) return STD_ULOGIC_VECTOR;

  alias To_Bit_Vector is
    To_bitvector[STD_ULOGIC_VECTOR, BIT return BIT_VECTOR];
  alias To_BV is
    To_bitvector[STD_ULOGIC_VECTOR, BIT return BIT_VECTOR];
  
  alias To_Std_Logic_Vector is
    To_StdLogicVector[BIT_VECTOR return STD_LOGIC_VECTOR];
  alias To_SLV is
    To_StdLogicVector[BIT_VECTOR return STD_LOGIC_VECTOR];

  alias To_Std_Logic_Vector is
    To_StdLogicVector[STD_ULOGIC_VECTOR return STD_LOGIC_VECTOR];
  alias To_SLV is
    To_StdLogicVector[STD_ULOGIC_VECTOR return STD_LOGIC_VECTOR];

  alias To_Std_ULogic_Vector is
    To_StdULogicVector[BIT_VECTOR return STD_ULOGIC_VECTOR];
  alias To_SULV is
    To_StdULogicVector[BIT_VECTOR return STD_ULOGIC_VECTOR];

  alias To_Std_ULogic_Vector is
    To_StdULogicVector[STD_LOGIC_VECTOR return STD_ULOGIC_VECTOR];
  alias To_SULV is
    To_StdULogicVector[STD_LOGIC_VECTOR return STD_ULOGIC_VECTOR];

  -------------------------------------------------------------------    
  -- strength strippers and type convertors
  -------------------------------------------------------------------    

  function TO_01 (s : STD_ULOGIC_VECTOR; xmap : STD_ULOGIC := '0')
    return STD_ULOGIC_VECTOR;
  function TO_01 (s : STD_ULOGIC; xmap : STD_ULOGIC := '0')
    return STD_ULOGIC;
  function TO_01 (s : BIT_VECTOR; xmap : STD_ULOGIC := '0')
    return STD_ULOGIC_VECTOR;
  function TO_01 (s : BIT; xmap : STD_ULOGIC := '0')
    return STD_ULOGIC;

  function To_X01 (s : STD_ULOGIC_VECTOR) return STD_ULOGIC_VECTOR;
  function To_X01 (s : STD_ULOGIC) return X01;
  function To_X01 (b : BIT_VECTOR) return STD_ULOGIC_VECTOR;
  function To_X01 (b : BIT) return X01;

  function To_X01Z (s : STD_ULOGIC_VECTOR) return STD_ULOGIC_VECTOR;
  function To_X01Z (s : STD_ULOGIC) return X01Z;
  function To_X01Z (b : BIT_VECTOR) return STD_ULOGIC_VECTOR;
  function To_X01Z (b : BIT) return X01Z;

  function To_UX01 (s : STD_ULOGIC_VECTOR) return STD_ULOGIC_VECTOR;
  function To_UX01 (s : STD_ULOGIC) return UX01;
  function To_UX01 (b : BIT_VECTOR) return STD_ULOGIC_VECTOR;
  function To_UX01 (b : BIT) return UX01;

  function "??" (l : STD_ULOGIC) return BOOLEAN;

  -------------------------------------------------------------------    
  -- edge detection
  -------------------------------------------------------------------    
  function rising_edge  (signal s : STD_ULOGIC) return BOOLEAN;
  function falling_edge (signal s : STD_ULOGIC) return BOOLEAN;

  -------------------------------------------------------------------    
  -- object contains an unknown
  -------------------------------------------------------------------    
  function Is_X (s : STD_ULOGIC_VECTOR) return BOOLEAN;
  function Is_X (s : STD_ULOGIC) return BOOLEAN;

  -------------------------------------------------------------------
  -- matching relational operators
  -------------------------------------------------------------------
  -- the following operations are predefined

  --  function "?=" (l, r : STD_ULOGIC) return STD_ULOGIC;
  --  function "?=" (l, r : STD_ULOGIC_VECTOR) return STD_ULOGIC;

  --  function "?/=" (l, r : STD_ULOGIC) return STD_ULOGIC;
  --  function "?/=" (l, r : STD_ULOGIC_VECTOR) return STD_ULOGIC;

  --  function "?<" (l, r  : STD_ULOGIC) return STD_ULOGIC;
  --  function "?<=" (l, r : STD_ULOGIC) return STD_ULOGIC;
  --  function "?>" (l, r  : STD_ULOGIC) return STD_ULOGIC;
  --  function "?>=" (l, r : STD_ULOGIC) return STD_ULOGIC;
  
  -------------------------------------------------------------------
  -- string conversion and write operations
  -------------------------------------------------------------------
  -- the following operations are predefined

  -- function to_string (value : STD_ULOGIC) return STRING;
  -- function to_string (value : STD_ULOGIC_VECTOR) return STRING;

  -- explicitly defined operations

  alias TO_BSTRING is TO_STRING [STD_ULOGIC_VECTOR return STRING];
  alias TO_BINARY_STRING is TO_STRING [STD_ULOGIC_VECTOR return STRING];
  function TO_OSTRING (VALUE : STD_ULOGIC_VECTOR) return STRING;
  alias TO_OCTAL_STRING is TO_OSTRING [STD_ULOGIC_VECTOR return STRING];
  function TO_HSTRING (VALUE : STD_ULOGIC_VECTOR) return STRING;
  alias TO_HEX_STRING is TO_HSTRING [STD_ULOGIC_VECTOR return STRING];

  procedure READ (L : inout LINE; VALUE : out STD_ULOGIC; GOOD : out BOOLEAN);
  procedure READ (L : inout LINE; VALUE : out STD_ULOGIC);

  procedure READ (L : inout LINE; VALUE : out STD_ULOGIC_VECTOR; GOOD : out BOOLEAN);
  procedure READ (L : inout LINE; VALUE : out STD_ULOGIC_VECTOR);

  procedure WRITE (L         : inout LINE; VALUE : in STD_ULOGIC;
  JUSTIFIED : in    SIDE := right; FIELD : in WIDTH := 0);

  procedure WRITE (L         : inout LINE; VALUE : in STD_ULOGIC_VECTOR;
  JUSTIFIED : in    SIDE := right; FIELD : in WIDTH := 0);

  alias BREAD is READ [LINE, STD_ULOGIC_VECTOR, BOOLEAN];
  alias BREAD is READ [LINE, STD_ULOGIC_VECTOR];
  alias BINARY_READ is READ [LINE, STD_ULOGIC_VECTOR, BOOLEAN];
  alias BINARY_READ is READ [LINE, STD_ULOGIC_VECTOR];

  procedure OREAD (L : inout LINE; VALUE : out STD_ULOGIC_VECTOR; GOOD : out BOOLEAN);
  procedure OREAD (L : inout LINE; VALUE : out STD_ULOGIC_VECTOR);
  alias OCTAL_READ is OREAD [LINE, STD_ULOGIC_VECTOR, BOOLEAN];
  alias OCTAL_READ is OREAD [LINE, STD_ULOGIC_VECTOR];

  procedure HREAD (L : inout LINE; VALUE : out STD_ULOGIC_VECTOR; GOOD : out BOOLEAN);
  procedure HREAD (L : inout LINE; VALUE : out STD_ULOGIC_VECTOR);
  alias HEX_READ is HREAD [LINE, STD_ULOGIC_VECTOR, BOOLEAN];
  alias HEX_READ is HREAD [LINE, STD_ULOGIC_VECTOR];

  alias BWRITE is WRITE [LINE, STD_ULOGIC_VECTOR, SIDE, WIDTH];
  alias BINARY_WRITE is WRITE [LINE, STD_ULOGIC_VECTOR, SIDE, WIDTH];
  
  procedure OWRITE (L         : inout LINE; VALUE : in STD_ULOGIC_VECTOR;
  JUSTIFIED : in    SIDE := right; FIELD : in WIDTH := 0);
  alias OCTAL_WRITE is OWRITE [LINE, STD_ULOGIC_VECTOR, SIDE, WIDTH];
  
  procedure HWRITE (L         : inout LINE; VALUE : in STD_ULOGIC_VECTOR;
  JUSTIFIED : in    SIDE := right; FIELD : in WIDTH := 0);
  alias HEX_WRITE is HWRITE [LINE, STD_ULOGIC_VECTOR, SIDE, WIDTH];

  -- Begin: VIPER #9548/8783: Mixed dialect: vhdl-1993 package specific additions
  -- Xilinx begin (160405)
  -- type STD_LOGIC_VECTOR_93 is array (NATURAL range <>) of STD_LOGIC ;
  -- Xilinx end (160405)

  -- Viper #10710: Following two are redundant. To_StdULogicVector and 
  -- To_StdLogicVector already declared before w.r.t. STD_LOGIC_VECTOR 
  -- function To_StdULogicVector (s : STD_LOGIC_VECTOR_93) return STD_ULOGIC_VECTOR;
  -- function To_StdLogicVector  (s : STD_ULOGIC_VECTOR) return STD_LOGIC_VECTOR_93;

  FUNCTION "and"   ( l, r : std_logic_vector_93  ) RETURN std_logic_vector_93 ;
  FUNCTION "nand"  ( l, r : std_logic_vector_93  ) RETURN std_logic_vector_93 ;
  FUNCTION "or"    ( l, r : std_logic_vector_93  ) RETURN std_logic_vector_93 ;
  FUNCTION "nor"   ( l, r : std_logic_vector_93  ) RETURN std_logic_vector_93 ;
  FUNCTION "xor"   ( l, r : std_logic_vector_93  ) RETURN std_logic_vector_93 ;
  FUNCTION "xnor"  ( l, r : std_logic_vector_93  ) RETURN std_logic_vector_93 ;
  FUNCTION "not"   ( l : std_logic_vector_93  ) RETURN std_logic_vector_93 ;
  FUNCTION To_bitvector ( s : std_logic_vector_93 ; xmap : BIT := '0') RETURN BIT_VECTOR ;
  FUNCTION To_X01  ( s : std_logic_vector_93  ) RETURN  std_logic_vector_93 ;
  FUNCTION To_X01  ( b : BIT_VECTOR        ) RETURN  std_logic_vector_93 ;
  FUNCTION To_X01Z ( s : std_logic_vector_93  ) RETURN  std_logic_vector_93 ;
  FUNCTION To_X01Z ( b : BIT_VECTOR        ) RETURN  std_logic_vector_93 ;
  FUNCTION To_UX01 ( s : std_logic_vector_93  ) RETURN  std_logic_vector_93 ;
  FUNCTION To_UX01 ( b : BIT_VECTOR        ) RETURN  std_logic_vector_93 ;
  FUNCTION Is_X    ( s : std_logic_vector_93  ) RETURN  BOOLEAN ;

  -- Read and Write procedures for STD_LOGIC_VECTOR_93
  procedure READ(L:inout LINE; VALUE:out STD_LOGIC_VECTOR_93);
  procedure READ(L:inout LINE; VALUE:out STD_LOGIC_VECTOR_93; GOOD: out BOOLEAN);
  procedure WRITE(L:inout LINE; VALUE:in STD_LOGIC_VECTOR_93;
                  JUSTIFIED:in SIDE := RIGHT; FIELD:in WIDTH := 0);

  procedure HREAD(L:inout LINE; VALUE:out STD_LOGIC_VECTOR_93);
  procedure HREAD(L:inout LINE; VALUE:out STD_LOGIC_VECTOR_93; GOOD: out BOOLEAN);
  procedure HWRITE(L:inout LINE; VALUE:in STD_LOGIC_VECTOR_93;
                   JUSTIFIED:in SIDE := RIGHT; FIELD:in WIDTH := 0);

  procedure OREAD(L:inout LINE; VALUE:out STD_LOGIC_VECTOR_93);
  procedure OREAD(L:inout LINE; VALUE:out STD_LOGIC_VECTOR_93; GOOD: out BOOLEAN);
  procedure OWRITE(L:inout LINE; VALUE:in STD_LOGIC_VECTOR_93;
                   JUSTIFIED:in SIDE := RIGHT; FIELD:in WIDTH := 0);
  -- End: VIPER #9548/8783: Mixed dialect: vhdl-1993 package specific additions

end package std_logic_1164;
