--------------------------------------------------------------------------
--                                                                      --
-- Copyright (c) 1990, 1991 by Synopsys, Inc.  All rights reserved.     --
--                                                                      --
-- This source file may be used and distributed without restriction     --
-- provided that this copyright statement is not removed from the file  --
-- and that any derivative work contains this copyright notice.         --
--                                                                      --
--	Package name: ARITHMETIC
--
--	Purpose: 
--	 A set of arithemtic, conversion, and comparison functions 
--	 for SIGNED, UNSIGNED, and MVL7_VECTOR.
--
--------------------------------------------------------------------------
-- Exemplar : Added Synthsis directives for the functions in this package.
--            These are attributes that operate like the Synopsys pragmas. 
--------------------------------------------------------------------------

library synopsys;
use synopsys.types.all;

package arithmetic is

    type UNSIGNED is array (INTEGER range <>) of MVL7;
    type SIGNED is array (INTEGER range <>) of MVL7;
    subtype SMALL_INT is INTEGER range 0 to 1;

    function "+"(L: UNSIGNED; R: UNSIGNED) return UNSIGNED;
    function "+"(L: SIGNED; R: SIGNED) return SIGNED;
    function "+"(L: UNSIGNED; R: SIGNED) return SIGNED;
    function "+"(L: SIGNED; R: UNSIGNED) return SIGNED;
    function "+"(L: UNSIGNED; R: INTEGER) return UNSIGNED;
    function "+"(L: INTEGER; R: UNSIGNED) return UNSIGNED;
    function "+"(L: SIGNED; R: INTEGER) return SIGNED;
    function "+"(L: INTEGER; R: SIGNED) return SIGNED;
    function "+"(L: UNSIGNED; R: MVL7) return UNSIGNED;
    function "+"(L: MVL7; R: UNSIGNED) return UNSIGNED;
    function "+"(L: SIGNED; R: MVL7) return SIGNED;
    function "+"(L: MVL7; R: SIGNED) return SIGNED;

    function "-"(L: UNSIGNED; R: UNSIGNED) return UNSIGNED;
    function "-"(L: SIGNED; R: SIGNED) return SIGNED;
    function "-"(L: UNSIGNED; R: SIGNED) return SIGNED;
    function "-"(L: SIGNED; R: UNSIGNED) return SIGNED;
    function "-"(L: UNSIGNED; R: INTEGER) return UNSIGNED;
    function "-"(L: INTEGER; R: UNSIGNED) return UNSIGNED;
    function "-"(L: SIGNED; R: INTEGER) return SIGNED;
    function "-"(L: INTEGER; R: SIGNED) return SIGNED;
    function "-"(L: UNSIGNED; R: MVL7) return UNSIGNED;
    function "-"(L: MVL7; R: UNSIGNED) return UNSIGNED;
    function "-"(L: SIGNED; R: MVL7) return SIGNED;
    function "-"(L: MVL7; R: SIGNED) return SIGNED;

    function "+"(L: UNSIGNED) return UNSIGNED;
    function "+"(L: SIGNED) return SIGNED;
    function "-"(L: SIGNED) return SIGNED;
    function "ABS"(L: SIGNED) return SIGNED;

    function "*"(L: UNSIGNED; R: UNSIGNED) return UNSIGNED;
    function "*"(L: SIGNED; R: SIGNED) return SIGNED;
    function "*"(L: SIGNED; R: UNSIGNED) return SIGNED;
    function "*"(L: UNSIGNED; R: SIGNED) return SIGNED;

    function "<"(L: UNSIGNED; R: UNSIGNED) return BOOLEAN;
    function "<"(L: SIGNED; R: SIGNED) return BOOLEAN;
    function "<"(L: UNSIGNED; R: SIGNED) return BOOLEAN;
    function "<"(L: SIGNED; R: UNSIGNED) return BOOLEAN;
    function "<"(L: UNSIGNED; R: INTEGER) return BOOLEAN;
    function "<"(L: INTEGER; R: UNSIGNED) return BOOLEAN;
    function "<"(L: SIGNED; R: INTEGER) return BOOLEAN;
    function "<"(L: INTEGER; R: SIGNED) return BOOLEAN;

    function "<="(L: UNSIGNED; R: UNSIGNED) return BOOLEAN;
    function "<="(L: SIGNED; R: SIGNED) return BOOLEAN;
    function "<="(L: UNSIGNED; R: SIGNED) return BOOLEAN;
    function "<="(L: SIGNED; R: UNSIGNED) return BOOLEAN;
    function "<="(L: UNSIGNED; R: INTEGER) return BOOLEAN;
    function "<="(L: INTEGER; R: UNSIGNED) return BOOLEAN;
    function "<="(L: SIGNED; R: INTEGER) return BOOLEAN;
    function "<="(L: INTEGER; R: SIGNED) return BOOLEAN;

    function ">"(L: UNSIGNED; R: UNSIGNED) return BOOLEAN;
    function ">"(L: SIGNED; R: SIGNED) return BOOLEAN;
    function ">"(L: UNSIGNED; R: SIGNED) return BOOLEAN;
    function ">"(L: SIGNED; R: UNSIGNED) return BOOLEAN;
    function ">"(L: UNSIGNED; R: INTEGER) return BOOLEAN;
    function ">"(L: INTEGER; R: UNSIGNED) return BOOLEAN;
    function ">"(L: SIGNED; R: INTEGER) return BOOLEAN;
    function ">"(L: INTEGER; R: SIGNED) return BOOLEAN;

    function ">="(L: UNSIGNED; R: UNSIGNED) return BOOLEAN;
    function ">="(L: SIGNED; R: SIGNED) return BOOLEAN;
    function ">="(L: UNSIGNED; R: SIGNED) return BOOLEAN;
    function ">="(L: SIGNED; R: UNSIGNED) return BOOLEAN;
    function ">="(L: UNSIGNED; R: INTEGER) return BOOLEAN;
    function ">="(L: INTEGER; R: UNSIGNED) return BOOLEAN;
    function ">="(L: SIGNED; R: INTEGER) return BOOLEAN;
    function ">="(L: INTEGER; R: SIGNED) return BOOLEAN;

    function "="(L: UNSIGNED; R: UNSIGNED) return BOOLEAN;
    function "="(L: SIGNED; R: SIGNED) return BOOLEAN;
    function "="(L: UNSIGNED; R: SIGNED) return BOOLEAN;
    function "="(L: SIGNED; R: UNSIGNED) return BOOLEAN;
    function "="(L: UNSIGNED; R: INTEGER) return BOOLEAN;
    function "="(L: INTEGER; R: UNSIGNED) return BOOLEAN;
    function "="(L: SIGNED; R: INTEGER) return BOOLEAN;
    function "="(L: INTEGER; R: SIGNED) return BOOLEAN;

    function "/="(L: UNSIGNED; R: UNSIGNED) return BOOLEAN;
    function "/="(L: SIGNED; R: SIGNED) return BOOLEAN;
    function "/="(L: UNSIGNED; R: SIGNED) return BOOLEAN;
    function "/="(L: SIGNED; R: UNSIGNED) return BOOLEAN;
    function "/="(L: UNSIGNED; R: INTEGER) return BOOLEAN;
    function "/="(L: INTEGER; R: UNSIGNED) return BOOLEAN;
    function "/="(L: SIGNED; R: INTEGER) return BOOLEAN;
    function "/="(L: INTEGER; R: SIGNED) return BOOLEAN;

    function SHL(ARG: UNSIGNED; COUNT: UNSIGNED) return UNSIGNED;
    function SHL(ARG: SIGNED; COUNT: UNSIGNED) return SIGNED;
    function SHR(ARG: UNSIGNED; COUNT: UNSIGNED) return UNSIGNED;
    function SHR(ARG: SIGNED; COUNT: UNSIGNED) return SIGNED;

    function CONV_INTEGER(ARG: INTEGER) return INTEGER;
    function CONV_INTEGER(ARG: UNSIGNED) return INTEGER;
    function CONV_INTEGER(ARG: SIGNED) return INTEGER;
    function CONV_INTEGER(ARG: MVL7) return SMALL_INT;
    function CONV_UNSIGNED(ARG: INTEGER; SIZE: INTEGER) return UNSIGNED;
    function CONV_UNSIGNED(ARG: UNSIGNED; SIZE: INTEGER) return UNSIGNED;
    function CONV_UNSIGNED(ARG: SIGNED; SIZE: INTEGER) return UNSIGNED;
    function CONV_UNSIGNED(ARG: MVL7; SIZE: INTEGER) return UNSIGNED;
    function CONV_SIGNED(ARG: INTEGER; SIZE: INTEGER) return SIGNED;
    function CONV_SIGNED(ARG: UNSIGNED; SIZE: INTEGER) return SIGNED;
    function CONV_SIGNED(ARG: SIGNED; SIZE: INTEGER) return SIGNED;
    function CONV_SIGNED(ARG: MVL7; SIZE: INTEGER) return SIGNED;

    function "and" (L, R: UNSIGNED) return UNSIGNED;
    function "nand" (L, R: UNSIGNED) return UNSIGNED;
    function "or" (L, R: UNSIGNED) return UNSIGNED;
    function "nor" (L, R: UNSIGNED) return UNSIGNED;
    function "xor" (L, R: UNSIGNED) return UNSIGNED;
    function nxor (L, R: UNSIGNED) return UNSIGNED;
    function "not" (R: UNSIGNED) return UNSIGNED;
    function buf (R: UNSIGNED) return UNSIGNED;

    function "and" (L, R: SIGNED) return SIGNED;
    function "nand" (L, R: SIGNED) return SIGNED;
    function "or" (L, R: SIGNED) return SIGNED;
    function "nor" (L, R: SIGNED) return SIGNED;
    function "xor" (L, R: SIGNED) return SIGNED;
    function nxor (L, R: SIGNED) return SIGNED;
    function "not" (R: SIGNED) return SIGNED;
    function buf (R: SIGNED) return SIGNED;

    function AND_REDUCE(ARG: MVL7_VECTOR) return MVL7;
    function NAND_REDUCE(ARG: MVL7_VECTOR) return MVL7;
    function OR_REDUCE(ARG: MVL7_VECTOR) return MVL7;
    function NOR_REDUCE(ARG: MVL7_VECTOR) return MVL7;
    function XOR_REDUCE(ARG: MVL7_VECTOR) return MVL7;
    function XNOR_REDUCE(ARG: MVL7_VECTOR) return MVL7;

-- Declare Exemplar Synthesis Directive attributes
    attribute SYNTHESIS_RETURN : STRING ;
    attribute IS_SIGNED : BOOLEAN ;
end arithmetic;

package body arithmetic is

    function max(L, R: INTEGER) return INTEGER is
    begin
	if L > R then
	    return L;
	else
	    return R;
	end if;
    end;


    function min(L, R: INTEGER) return INTEGER is
    begin
	if L < R then
	    return L;
	else
	    return R;
	end if;
    end;

    -- synopsys synthesis_off
    type tbl_type is array (MVL7) of MVL7;
    constant tbl_BINARY : tbl_type :=
	('0', '0', '1', '0', '0', '0', '1');
    -- synopsys synthesis_on

    function MAKE_BINARY(A : MVL7) return MVL7 is
	-- synopsys built_in SYN_FEED_THRU
        variable result : MVL7 ;
        -- Exemplar synthesis directive attribute for this function
        attribute SYNTHESIS_RETURN of result:variable is "FEED_THROUGH" ;
    begin
	-- synopsys synthesis_off
	    result := tbl_BINARY(A);
            return result ;
	-- synopsys synthesis_on
    end;

    function MAKE_BINARY(A : UNSIGNED) return UNSIGNED is
	-- synopsys built_in SYN_FEED_THRU
	-- variable one_bit : MVL7;
	variable result : UNSIGNED (A'range);
        -- Exemplar synthesis directive attribute for this function
        attribute SYNTHESIS_RETURN of result:variable is "FEED_THROUGH" ;
    begin
	-- synopsys synthesis_off
	    for i in A'range loop
		result(i) := tbl_BINARY(A(i));
	    end loop;
	    return result;
	-- synopsys synthesis_on
    end;

    function MAKE_BINARY(A : UNSIGNED) return SIGNED is
	-- synopsys built_in SYN_FEED_THRU
	-- variable one_bit : MVL7;
	variable result : SIGNED (A'range);
        -- Exemplar synthesis directive attribute for this function
        attribute SYNTHESIS_RETURN of result:variable is "FEED_THROUGH" ;
    begin
	-- synopsys synthesis_off
	    for i in A'range loop
		result(i) := tbl_BINARY(A(i));
	    end loop;
	    return result;
	-- synopsys synthesis_on
    end;

    function MAKE_BINARY(A : SIGNED) return UNSIGNED is
	-- synopsys built_in SYN_FEED_THRU
	-- variable one_bit : MVL7;
	variable result : UNSIGNED (A'range);
        -- Exemplar synthesis directive attribute for this function
        attribute SYNTHESIS_RETURN of result:variable is "FEED_THROUGH" ;
    begin
	-- synopsys synthesis_off
	    for i in A'range loop
		result(i) := tbl_BINARY(A(i));
	    end loop;
	    return result;
	-- synopsys synthesis_on
    end;

    function MAKE_BINARY(A : SIGNED) return SIGNED is
	-- synopsys built_in SYN_FEED_THRU
	-- variable one_bit : MVL7;
	variable result : SIGNED (A'range);
        -- Exemplar synthesis directive attribute for this function
        attribute SYNTHESIS_RETURN of result:variable is "FEED_THROUGH" ;
    begin
	-- synopsys synthesis_off
	    for i in A'range loop
		result(i) := tbl_BINARY(A(i));
	    end loop;
	    return result;
	-- synopsys synthesis_on
    end;



    -- Type propagation function which returns a signed type with the
    -- size of the left arg.
    function LEFT_SIGNED_ARG(A,B: SIGNED) return SIGNED is
      variable Z: SIGNED (A'left downto 0);
      -- pragma return_port_name Z
    begin
      return(Z);
    end;
	
    -- Type propagation function which returns an unsigned type with the
    -- size of the left arg.
    function LEFT_UNSIGNED_ARG(A,B: UNSIGNED) return UNSIGNED is
      variable Z: UNSIGNED (A'left downto 0);
      -- pragma return_port_name Z
    begin
      return(Z);
    end;
	
    -- Type propagation function which returns a signed type with the
    -- size of the result of a signed multiplication
    function MULT_SIGNED_ARG(A,B: SIGNED) return SIGNED is
      variable Z: SIGNED ((A'length+B'length-1) downto 0);
      -- pragma return_port_name Z
    begin
      return(Z);
    end;
	
    -- Type propagation function which returns an unsigned type with the
    -- size of the result of a unsigned multiplication
    function MULT_UNSIGNED_ARG(A,B: UNSIGNED) return UNSIGNED is
      variable Z: UNSIGNED ((A'length+B'length-1) downto 0);
      -- pragma return_port_name Z
    begin
      return(Z);
    end;

    function mult(A,B: SIGNED) return SIGNED is

      variable BA: SIGNED((A'length+B'length-1) downto 0);
      variable PA: SIGNED((A'length+B'length-1) downto 0);
      variable AA: SIGNED(A'length downto 0);
      variable neg: MVL7;
      constant one : UNSIGNED(1 downto 0) := "01";
      
      -- pragma map_to_operator MULT_TC_OP
      -- pragma type_function MULT_SIGNED_ARG
      -- pragma return_port_name Z

        -- Exemplar synthesis directive attributes for this function
        attribute IS_SIGNED of A:constant is TRUE ;
        attribute IS_SIGNED of B:constant is TRUE ;
		attribute is_signed of PA:variable is TRUE ;
        attribute SYNTHESIS_RETURN of PA:variable is "MULT" ;
      begin
        PA := (others => '0');
        neg := B(B'left) xor A(A'left);
        BA := CONV_SIGNED(('0' & ABS(B)),(A'length+B'length));
        AA := '0' & ABS(A);
        for i in 0 to A'length-1 loop
          if AA(i) = '1' then
            PA := PA+BA;
          end if;
          BA := SHL(BA,one);
        end loop;
        if (neg= '1') then
          return (-PA);
        else 
          return (PA);
        end if;
      end;

    function mult(A,B: UNSIGNED) return UNSIGNED is

      variable BA: UNSIGNED((A'length+B'length-1) downto 0);
      variable PA: UNSIGNED((A'length+B'length-1) downto 0);
      constant one : UNSIGNED(1 downto 0) := "01";
      
      -- pragma map_to_operator MULT_UNS_OP
      -- pragma type_function MULT_UNSIGNED_ARG
      -- pragma return_port_name Z

        -- Exemplar synthesis directive attributes for this function
        attribute SYNTHESIS_RETURN of PA:variable is "MULT" ;
      begin
        PA := (others => '0');
        BA := CONV_UNSIGNED(B,(A'length+B'length));
        for i in 0 to A'length-1 loop
          if A(i) = '1' then
            PA := PA+BA;
          end if;
          BA := SHL(BA,one);
        end loop;
        return(PA);
      end;

    -- subtract two signed numbers of the same length
    -- both arrays must have range (msb downto 0)
    function minus(A, B: SIGNED) return SIGNED is
	variable carry: MVL7;
	variable BV: MVL7_VECTOR (A'left downto 0);
	variable sum: SIGNED (A'left downto 0);

	-- pragma map_to_operator SUB_TC_OP

	-- pragma type_function LEFT_SIGNED_ARG
        -- pragma return_port_name Z

        -- Exemplar synthesis directive attributes for this function
        attribute IS_SIGNED of A:constant is TRUE ;
        attribute IS_SIGNED of B:constant is TRUE ;
		attribute is_signed of sum:variable is TRUE ;
        attribute SYNTHESIS_RETURN of sum:variable is "SUB" ;
    begin
	carry := '1';
	BV := not MVL7_VECTOR(B);

	for i in 0 to A'left loop
	    sum(i) := A(i) xor BV(i) xor carry;
	    carry := (A(i) and BV(i)) or
		    (A(i) and carry) or
		    (carry and BV(i));
	end loop;
	return sum;
    end;

    -- add two signed numbers of the same length
    -- both arrays must have range (msb downto 0)
    function plus(A, B: SIGNED) return SIGNED is
	variable carry: MVL7;
	variable BV, sum: SIGNED (A'left downto 0);

	-- pragma map_to_operator ADD_TC_OP
	-- pragma type_function LEFT_SIGNED_ARG
        -- pragma return_port_name Z

        -- Exemplar synthesis directive attributes for this function
        attribute IS_SIGNED of A:constant is TRUE ;
        attribute IS_SIGNED of B:constant is TRUE ;
		attribute is_signed of sum:variable is TRUE ;
        attribute SYNTHESIS_RETURN of sum:variable is "ADD" ;
    begin
	carry := '0';
	BV := B;

	for i in 0 to A'left loop
	    sum(i) := A(i) xor BV(i) xor carry;
	    carry := (A(i) and BV(i)) or
		    (A(i) and carry) or
		    (carry and BV(i));
	end loop;
	return sum;
    end;


    -- subtract two unsigned numbers of the same length
    -- both arrays must have range (msb downto 0)
    function unsigned_minus(A, B: UNSIGNED) return UNSIGNED is
	variable carry: MVL7;
	variable BV: MVL7_VECTOR (A'left downto 0);
	variable sum: UNSIGNED (A'left downto 0);

	-- pragma map_to_operator SUB_UNS_OP
	-- pragma type_function LEFT_UNSIGNED_ARG
        -- pragma return_port_name Z

        -- Exemplar synthesis directive attributes for this function
        attribute SYNTHESIS_RETURN of sum:variable is "SUB" ;
    begin
	carry := '1';
	BV := not MVL7_VECTOR(B);

	for i in 0 to A'left loop
	    sum(i) := A(i) xor BV(i) xor carry;
	    carry := (A(i) and BV(i)) or
		    (A(i) and carry) or
		    (carry and BV(i));
	end loop;
	return sum;
    end;

    -- add two unsigned numbers of the same length
    -- both arrays must have range (msb downto 0)
    function unsigned_plus(A, B: UNSIGNED) return UNSIGNED is
	variable carry: MVL7;
	variable BV, sum: UNSIGNED (A'left downto 0);

	-- pragma map_to_operator ADD_UNS_OP
	-- pragma type_function LEFT_UNSIGNED_ARG
        -- pragma return_port_name Z

        -- Exemplar synthesis directive attributes for this function
        attribute SYNTHESIS_RETURN of sum:variable is "ADD" ;
    begin
	carry := '0';
	BV := B;

	for i in 0 to A'left loop
	    sum(i) := A(i) xor BV(i) xor carry;
	    carry := (A(i) and BV(i)) or
		    (A(i) and carry) or
		    (carry and BV(i));
	end loop;
	return sum;
    end;

-- All of the following actual different forms of arithmetic operations
-- will be compiled as is by Exemplar.

    function "*"(L: SIGNED; R: SIGNED) return SIGNED is
	-- pragma label_applies_to mult
    begin
          return     mult(CONV_SIGNED(L, L'length),
		          CONV_SIGNED(R, R'length)); -- pragma label mult 
    end;
      
    function "*"(L: UNSIGNED; R: UNSIGNED) return UNSIGNED is
	-- pragma label_applies_to mult
    begin
          return   mult(CONV_UNSIGNED(L, L'length),
                        CONV_UNSIGNED(R, R'length)); -- pragma label mult 
    end;
        
    function "*"(L: UNSIGNED; R: SIGNED) return SIGNED is
	-- pragma label_applies_to plus
    begin
 	return       mult(CONV_SIGNED(L, L'length+1),
		          CONV_SIGNED(R, R'length)); -- pragma label mult 
    end;

    function "*"(L: SIGNED; R: UNSIGNED) return SIGNED is
	-- pragma label_applies_to plus
    begin
	return      mult(CONV_SIGNED(L, L'length),
		         CONV_SIGNED(R, R'length+1)); -- pragma label mult 
    end;


    function "+"(L: UNSIGNED; R: UNSIGNED) return UNSIGNED is
	-- pragma label_applies_to plus
	constant length: INTEGER := max(L'length, R'length);
    begin
	return unsigned_plus(CONV_UNSIGNED(L, length),
			     CONV_UNSIGNED(R, length)); -- pragma label plus
    end;


    function "+"(L: SIGNED; R: SIGNED) return SIGNED is
	-- pragma label_applies_to plus
	constant length: INTEGER := max(L'length, R'length);
    begin
	return plus(CONV_SIGNED(L, length),
		    CONV_SIGNED(R, length)); -- pragma label plus
    end;


    function "+"(L: UNSIGNED; R: SIGNED) return SIGNED is
	-- pragma label_applies_to plus
	constant length: INTEGER := max(L'length + 1, R'length);
    begin
	return plus(CONV_SIGNED(L, length),
		    CONV_SIGNED(R, length)); -- pragma label plus
    end;


    function "+"(L: SIGNED; R: UNSIGNED) return SIGNED is
	-- pragma label_applies_to plus
	constant length: INTEGER := max(L'length, R'length + 1);
    begin
	return plus(CONV_SIGNED(L, length),
		    CONV_SIGNED(R, length)); -- pragma label plus
    end;


    function "+"(L: UNSIGNED; R: INTEGER) return UNSIGNED is
	-- pragma label_applies_to plus
	constant length: INTEGER := L'length + 1;
        -- It does not make sense to extend L one bit and eliminate
        -- the MSB result bit. For Exemplar : build a length-1
        -- adder. R will be interpreted as (signed) integer.
        variable result : UNSIGNED(length-2 downto 0) ;
        attribute SYNTHESIS_RETURN of result:variable is "ADD" ;
    begin
	result := CONV_UNSIGNED(
		plus( -- pragma label plus
		    CONV_SIGNED(L, length),
		    CONV_SIGNED(R, length)),
		length-1);
        return result ;
    end;


    function "+"(L: INTEGER; R: UNSIGNED) return UNSIGNED is
	-- pragma label_applies_to plus
	constant length: INTEGER := R'length + 1;
        -- It does not make sense to extend R one bit and eliminate
        -- the MSB result bit. For Exemplar : build a length-1
        -- adder. L will be interpreted as (signed) integer.
        variable result : UNSIGNED(length-2 downto 0) ;
        attribute SYNTHESIS_RETURN of result:variable is "ADD" ;
    begin
	result := CONV_UNSIGNED(
		plus( -- pragma label plus
		    CONV_SIGNED(L, length),
		    CONV_SIGNED(R, length)),
		length-1);
        return result ;
    end;


    function "+"(L: SIGNED; R: INTEGER) return SIGNED is
	-- pragma label_applies_to plus
	constant length: INTEGER := L'length;
    begin
	return plus(CONV_SIGNED(L, length),
		    CONV_SIGNED(R, length)); -- pragma label plus
    end;


    function "+"(L: INTEGER; R: SIGNED) return SIGNED is
	-- pragma label_applies_to plus
	constant length: INTEGER := R'length;
    begin
	return plus(CONV_SIGNED(L, length),
		    CONV_SIGNED(R, length)); -- pragma label plus
    end;


    function "+"(L: UNSIGNED; R: MVL7) return UNSIGNED is
	-- pragma label_applies_to plus
	constant length: INTEGER := L'length;
    begin
	return unsigned_plus(CONV_UNSIGNED(L, length),
		     CONV_UNSIGNED(R, length)) ; -- pragma label plus
    end;


    function "+"(L: MVL7; R: UNSIGNED) return UNSIGNED is
	-- pragma label_applies_to plus
	constant length: INTEGER := R'length;
    begin
	return unsigned_plus(CONV_UNSIGNED(L, length),
		     CONV_UNSIGNED(R, length)); -- pragma label plus
    end;


    function "+"(L: SIGNED; R: MVL7) return SIGNED is
	-- pragma label_applies_to plus
	constant length: INTEGER := L'length;
    begin
	return plus(CONV_SIGNED(L, length),
		    CONV_SIGNED(R, length)); -- pragma label plus
    end;


    function "+"(L: MVL7; R: SIGNED) return SIGNED is
	-- pragma label_applies_to plus
	constant length: INTEGER := R'length;
    begin
	return plus(CONV_SIGNED(L, length),
		    CONV_SIGNED(R, length)); -- pragma label plus
    end;





    function "-"(L: UNSIGNED; R: UNSIGNED) return UNSIGNED is
	-- pragma label_applies_to minus
	constant length: INTEGER := max(L'length, R'length);
    begin
	return unsigned_minus(CONV_UNSIGNED(L, length),
		      	      CONV_UNSIGNED(R, length)); -- pragma label minus
    end;


    function "-"(L: SIGNED; R: SIGNED) return SIGNED is
	-- pragma label_applies_to minus
	constant length: INTEGER := max(L'length, R'length);
    begin
	return minus(CONV_SIGNED(L, length),
		     CONV_SIGNED(R, length)); -- pragma label minus
    end;


    function "-"(L: UNSIGNED; R: SIGNED) return SIGNED is
	-- pragma label_applies_to minus
	constant length: INTEGER := max(L'length + 1, R'length);
    begin
	return minus(CONV_SIGNED(L, length),
		     CONV_SIGNED(R, length)); -- pragma label minus
    end;


    function "-"(L: SIGNED; R: UNSIGNED) return SIGNED is
	-- pragma label_applies_to minus
	constant length: INTEGER := max(L'length, R'length + 1);
    begin
	return minus(CONV_SIGNED(L, length),
		     CONV_SIGNED(R, length)); -- pragma label minus
    end;


    function "-"(L: UNSIGNED; R: INTEGER) return UNSIGNED is
	-- pragma label_applies_to minus
	constant length: INTEGER := L'length + 1;
        -- It does not make sense to extend L one bit and eliminate
        -- the MSB result bit. For Exemplar : build a length-1
        -- subtractor. R will be interpreted as (signed) integer.
        variable result : UNSIGNED(length-2 downto 0) ;
        attribute SYNTHESIS_RETURN of result:variable is "SUB" ;
    begin
	result := CONV_UNSIGNED(
		minus( -- pragma label minus
		    CONV_SIGNED(L, length),
		    CONV_SIGNED(R, length)),
		length-1);
        return result ;
    end;


    function "-"(L: INTEGER; R: UNSIGNED) return UNSIGNED is
	-- pragma label_applies_to minus
	constant length: INTEGER := R'length + 1;
        -- It does not make sense to extend R one bit and eliminate
        -- the MSB result bit. For Exemplar : build a length-1
        -- subtractor. L will be interpreted as (signed) integer.
        variable result : UNSIGNED(length-2 downto 0) ;
        attribute SYNTHESIS_RETURN of result:variable is "SUB" ;
    begin
	result := CONV_UNSIGNED(
		minus( -- pragma label minus
		    CONV_SIGNED(L, length),
		    CONV_SIGNED(R, length)),
		length-1);
        return result ;
    end;


    function "-"(L: SIGNED; R: INTEGER) return SIGNED is
	-- pragma label_applies_to minus
	constant length: INTEGER := L'length;
    begin
	return minus(CONV_SIGNED(L, length),
		     CONV_SIGNED(R, length)); -- pragma label minus
    end;


    function "-"(L: INTEGER; R: SIGNED) return SIGNED is
	-- pragma label_applies_to minus
	constant length: INTEGER := R'length;
    begin
	return minus(CONV_SIGNED(L, length),
		     CONV_SIGNED(R, length)); -- pragma label minus
    end;


    function "-"(L: UNSIGNED; R: MVL7) return UNSIGNED is
	-- pragma label_applies_to minus
	constant length: INTEGER := L'length + 1;
        -- It does not make sense to extend L one bit and eliminate
        -- the MSB result bit. For Exemplar : build a length-1
        -- subtractor. R is unsigned since CONV_SIGNED does zero-extend
        -- for MVL7.
        variable result : UNSIGNED(length-2 downto 0) ;
        attribute SYNTHESIS_RETURN of result:variable is "SUB" ;
    begin
	result := CONV_UNSIGNED(
		minus( -- pragma label minus
		    CONV_SIGNED(L, length),
		    CONV_SIGNED(R, length)),
		length-1);
        return result ;
    end;


    function "-"(L: MVL7; R: UNSIGNED) return UNSIGNED is
	-- pragma label_applies_to minus
	constant length: INTEGER := R'length + 1;
        -- It does not make sense to extend R one bit and eliminate
        -- the MSB result bit. For Exemplar : build a length-1
        -- subtractor. L is unsigned since CONV_SIGNED does zero-extend
        -- for MVL7.
        variable result : UNSIGNED(length-2 downto 0) ;
        attribute SYNTHESIS_RETURN of result:variable is "SUB" ;
    begin
	result := CONV_UNSIGNED(
		minus( -- pragma label minus
		    CONV_SIGNED(L, length),
		    CONV_SIGNED(R, length)),
		length-1);
        return result ;
    end;


    function "-"(L: SIGNED; R: MVL7) return SIGNED is
	-- pragma label_applies_to minus
	constant length: INTEGER := L'length;
    begin
	return minus(CONV_SIGNED(L, length),
		     CONV_SIGNED(R, length)); -- pragma label minus
    end;


    function "-"(L: MVL7; R: SIGNED) return SIGNED is
	-- pragma label_applies_to minus
	constant length: INTEGER := R'length;
    begin
	return minus(CONV_SIGNED(L, length),
		     CONV_SIGNED(R, length)); -- pragma label minus
    end;




    function "+"(L: UNSIGNED) return UNSIGNED is
    begin
	return L;
    end;


    function "+"(L: SIGNED) return SIGNED is
    begin
	return L;
    end;


    function "-"(L: SIGNED) return SIGNED is
	-- pragma label_applies_to minus
        variable result : SIGNED(L'RANGE) ;
        -- Exemplar synthesis directive attributes for this function
        attribute SYNTHESIS_RETURN of result:variable is "UMINUS" ;
    begin
	result := 0 - L; -- pragma label minus
        return result ;
    end;


    function "ABS"(L: SIGNED) return SIGNED is
        variable result : SIGNED(L'RANGE) ;
        -- Exemplar synthesis directive attributes for this function
        attribute IS_SIGNED of L:constant is TRUE ;
        attribute SYNTHESIS_RETURN of result:variable is "ABS" ;
    begin
	if L(L'left) = '0' then
	    result := L;
	else
	    result := 0 - L;
	end if;
        return result ;
    end;


    -- Type propagation function which returns the type BOOLEAN
    function UNSIGNED_RETURN_BOOLEAN(A,B: UNSIGNED) return BOOLEAN is
      variable Z: BOOLEAN;
      -- pragma return_port_name Z
    begin
      return(Z);
    end;
	
    -- Type propagation function which returns the type BOOLEAN
    function SIGNED_RETURN_BOOLEAN(A,B: SIGNED) return BOOLEAN is
      variable Z: BOOLEAN;
      -- pragma return_port_name Z
    begin
      return(Z);
    end;
	

    -- compare two signed numbers of the same length
    -- both arrays must have range (msb downto 0)
    function is_less(A, B: SIGNED) return BOOLEAN is
	constant sign: INTEGER := A'left;
	variable a_is_0, b_is_1, result : boolean;

	-- pragma map_to_operator LT_TC_OP
	-- pragma type_function SIGNED_RETURN_BOOLEAN
        -- pragma return_port_name Z

        -- Exemplar synthesis directive attributes for this function
        attribute IS_SIGNED of A:constant is TRUE ; 
        attribute IS_SIGNED of B:constant is TRUE ; 
        attribute SYNTHESIS_RETURN of result:variable is "LT" ;
    begin
	if A(sign) /= B(sign) then
	    result := A(sign) = '1';
	else
	    result := FALSE;
	    for i in 0 to sign-1 loop
		a_is_0 := A(i) = '0';
		b_is_1 := B(i) = '1';
		result := (a_is_0 and b_is_1) or
			  (a_is_0 and result) or
			  (b_is_1 and result);
	    end loop;
	end if;
	return result;
    end;


    -- compare two signed numbers of the same length
    -- both arrays must have range (msb downto 0)
    function is_less_or_equal(A, B: SIGNED) return BOOLEAN is
	constant sign: INTEGER := A'left;
	variable a_is_0, b_is_1, result : boolean;

	-- pragma map_to_operator LEQ_TC_OP
	-- pragma type_function SIGNED_RETURN_BOOLEAN
        -- pragma return_port_name Z

        -- Exemplar synthesis directive attributes for this function
        attribute IS_SIGNED of A:constant is TRUE ; 
        attribute IS_SIGNED of B:constant is TRUE ; 
        attribute SYNTHESIS_RETURN of result:variable is "LTE" ;
    begin
	if A(sign) /= B(sign) then
	    result := A(sign) = '1';
	else
	    result := TRUE;
	    for i in 0 to sign-1 loop
		a_is_0 := A(i) = '0';
		b_is_1 := B(i) = '1';
		result := (a_is_0 and b_is_1) or
			  (a_is_0 and result) or
			  (b_is_1 and result);
	    end loop;
	end if;
	return result;
    end;



    -- compare two unsigned numbers of the same length
    -- both arrays must have range (msb downto 0)
    function unsigned_is_less(A, B: UNSIGNED) return BOOLEAN is
	constant sign: INTEGER := A'left;
	variable a_is_0, b_is_1, result : boolean;

	-- pragma map_to_operator LT_UNS_OP
	-- pragma type_function UNSIGNED_RETURN_BOOLEAN
        -- pragma return_port_name Z

        -- Exemplar synthesis directive attributes for this function
        attribute SYNTHESIS_RETURN of result:variable is "LT" ;
    begin
	result := FALSE;
	for i in 0 to sign loop
	    a_is_0 := A(i) = '0';
	    b_is_1 := B(i) = '1';
	    result := (a_is_0 and b_is_1) or
		      (a_is_0 and result) or
		      (b_is_1 and result);
	end loop;
	return result;
    end;


    -- compare two unsigned numbers of the same length
    -- both arrays must have range (msb downto 0)
    function unsigned_is_less_or_equal(A, B: UNSIGNED) return BOOLEAN is
	constant sign: INTEGER := A'left;
	variable a_is_0, b_is_1, result : boolean;

	-- pragma map_to_operator LEQ_UNS_OP
	-- pragma type_function UNSIGNED_RETURN_BOOLEAN
        -- pragma return_port_name Z

        -- Exemplar synthesis directive attributes for this function
        attribute SYNTHESIS_RETURN of result:variable is "LTE" ;
    begin
	result := TRUE;
	for i in 0 to sign loop
	    a_is_0 := A(i) = '0';
	    b_is_1 := B(i) = '1';
	    result := (a_is_0 and b_is_1) or
		      (a_is_0 and result) or
		      (b_is_1 and result);
	end loop;
	return result;
    end;

-- All of the following actual different forms of relational operations
-- will be compiled as is by Exemplar.


    function "<"(L: UNSIGNED; R: UNSIGNED) return BOOLEAN is
	-- pragma label_applies_to lt
	constant length: INTEGER := max(L'length, R'length);
    begin
	return unsigned_is_less(CONV_UNSIGNED(L, length),
				CONV_UNSIGNED(R, length)); -- pragma label lt
    end;


    function "<"(L: SIGNED; R: SIGNED) return BOOLEAN is
	-- pragma label_applies_to lt
	constant length: INTEGER := max(L'length, R'length);
    begin
	return is_less(CONV_SIGNED(L, length),
			CONV_SIGNED(R, length)); -- pragma label lt
    end;


    function "<"(L: UNSIGNED; R: SIGNED) return BOOLEAN is
	-- pragma label_applies_to lt
	constant length: INTEGER := max(L'length + 1, R'length);
    begin
	return is_less(CONV_SIGNED(L, length),
			CONV_SIGNED(R, length)); -- pragma label lt
    end;


    function "<"(L: SIGNED; R: UNSIGNED) return BOOLEAN is
	-- pragma label_applies_to lt
	constant length: INTEGER := max(L'length, R'length + 1);
    begin
	return is_less(CONV_SIGNED(L, length),
			CONV_SIGNED(R, length)); -- pragma label lt
    end;


    function "<"(L: UNSIGNED; R: INTEGER) return BOOLEAN is
	-- pragma label_applies_to lt
	constant length: INTEGER := L'length + 1;
    begin
	return is_less(CONV_SIGNED(L, length),
			CONV_SIGNED(R, length)); -- pragma label lt
    end;


    function "<"(L: INTEGER; R: UNSIGNED) return BOOLEAN is
	-- pragma label_applies_to lt
	constant length: INTEGER := R'length + 1;
    begin
	return is_less(CONV_SIGNED(L, length),
			CONV_SIGNED(R, length)); -- pragma label lt
    end;


    function "<"(L: SIGNED; R: INTEGER) return BOOLEAN is
	-- pragma label_applies_to lt
	constant length: INTEGER := L'length;
    begin
	return is_less(CONV_SIGNED(L, length),
			CONV_SIGNED(R, length)); -- pragma label lt
    end;


    function "<"(L: INTEGER; R: SIGNED) return BOOLEAN is
	-- pragma label_applies_to lt
	constant length: INTEGER := R'length;
    begin
	return is_less(CONV_SIGNED(L, length),
			CONV_SIGNED(R, length)); -- pragma label lt
    end;




    function "<="(L: UNSIGNED; R: UNSIGNED) return BOOLEAN is
	-- pragma label_applies_to leq
	constant length: INTEGER := max(L'length, R'length);
    begin
	return unsigned_is_less_or_equal(CONV_UNSIGNED(L, length),
			     CONV_UNSIGNED(R, length)); -- pragma label leq
    end;


    function "<="(L: SIGNED; R: SIGNED) return BOOLEAN is
	-- pragma label_applies_to leq
	constant length: INTEGER := max(L'length, R'length);
    begin
	return is_less_or_equal(CONV_SIGNED(L, length),
				CONV_SIGNED(R, length)); -- pragma label leq
    end;


    function "<="(L: UNSIGNED; R: SIGNED) return BOOLEAN is
	-- pragma label_applies_to leq
	constant length: INTEGER := max(L'length + 1, R'length);
    begin
	return is_less_or_equal(CONV_SIGNED(L, length),
				CONV_SIGNED(R, length)); -- pragma label leq
    end;


    function "<="(L: SIGNED; R: UNSIGNED) return BOOLEAN is
	-- pragma label_applies_to leq
	constant length: INTEGER := max(L'length, R'length + 1);
    begin
	return is_less_or_equal(CONV_SIGNED(L, length),
				CONV_SIGNED(R, length)); -- pragma label leq
    end;


    function "<="(L: UNSIGNED; R: INTEGER) return BOOLEAN is
	-- pragma label_applies_to leq
	constant length: INTEGER := L'length + 1;
    begin
	return is_less_or_equal(CONV_SIGNED(L, length),
				CONV_SIGNED(R, length)); -- pragma label leq
    end;


    function "<="(L: INTEGER; R: UNSIGNED) return BOOLEAN is
	-- pragma label_applies_to leq
	constant length: INTEGER := R'length + 1;
    begin
	return is_less_or_equal(CONV_SIGNED(L, length),
				CONV_SIGNED(R, length)); -- pragma label leq
    end;


    function "<="(L: SIGNED; R: INTEGER) return BOOLEAN is
	-- pragma label_applies_to leq
	constant length: INTEGER := L'length;
    begin
	return is_less_or_equal(CONV_SIGNED(L, length),
				CONV_SIGNED(R, length)); -- pragma label leq
    end;


    function "<="(L: INTEGER; R: SIGNED) return BOOLEAN is
	-- pragma label_applies_to leq
	constant length: INTEGER := R'length;
    begin
	return is_less_or_equal(CONV_SIGNED(L, length),
				CONV_SIGNED(R, length)); -- pragma label leq
    end;




    function ">"(L: UNSIGNED; R: UNSIGNED) return BOOLEAN is
	-- pragma label_applies_to gt
	constant length: INTEGER := max(L'length, R'length);
    begin
	return unsigned_is_less(CONV_UNSIGNED(R, length),
				CONV_UNSIGNED(L, length)); -- pragma label gt
    end;


    function ">"(L: SIGNED; R: SIGNED) return BOOLEAN is
	-- pragma label_applies_to gt
	constant length: INTEGER := max(L'length, R'length);
    begin
	return is_less(CONV_SIGNED(R, length),
		       CONV_SIGNED(L, length)); -- pragma label gt
    end;


    function ">"(L: UNSIGNED; R: SIGNED) return BOOLEAN is
	-- pragma label_applies_to gt
	constant length: INTEGER := max(L'length + 1, R'length);
    begin
	return is_less(CONV_SIGNED(R, length),
		       CONV_SIGNED(L, length)); -- pragma label gt
    end;


    function ">"(L: SIGNED; R: UNSIGNED) return BOOLEAN is
	-- pragma label_applies_to gt
	constant length: INTEGER := max(L'length, R'length + 1);
    begin
	return is_less(CONV_SIGNED(R, length),
		       CONV_SIGNED(L, length)); -- pragma label gt
    end;


    function ">"(L: UNSIGNED; R: INTEGER) return BOOLEAN is
	-- pragma label_applies_to gt
	constant length: INTEGER := L'length + 1;
    begin
	return is_less(CONV_SIGNED(R, length),
		       CONV_SIGNED(L, length)); -- pragma label gt
    end;


    function ">"(L: INTEGER; R: UNSIGNED) return BOOLEAN is
	-- pragma label_applies_to gt
	constant length: INTEGER := R'length + 1;
    begin
	return is_less(CONV_SIGNED(R, length),
		       CONV_SIGNED(L, length)); -- pragma label gt
    end;


    function ">"(L: SIGNED; R: INTEGER) return BOOLEAN is
	-- pragma label_applies_to gt
	constant length: INTEGER := L'length;
    begin
	return is_less(CONV_SIGNED(R, length),
		       CONV_SIGNED(L, length)); -- pragma label gt
    end;


    function ">"(L: INTEGER; R: SIGNED) return BOOLEAN is
	-- pragma label_applies_to gt
	constant length: INTEGER := R'length;
    begin
	return is_less(CONV_SIGNED(R, length),
		       CONV_SIGNED(L, length)); -- pragma label gt
    end;




    function ">="(L: UNSIGNED; R: UNSIGNED) return BOOLEAN is
	-- pragma label_applies_to geq
	constant length: INTEGER := max(L'length, R'length);
    begin
	return unsigned_is_less_or_equal(CONV_UNSIGNED(R, length),
				 CONV_UNSIGNED(L, length)); -- pragma label geq
    end;


    function ">="(L: SIGNED; R: SIGNED) return BOOLEAN is
	-- pragma label_applies_to geq
	constant length: INTEGER := max(L'length, R'length);
    begin
	return is_less_or_equal(CONV_SIGNED(R, length),
				CONV_SIGNED(L, length)); -- pragma label geq
    end;


    function ">="(L: UNSIGNED; R: SIGNED) return BOOLEAN is
	-- pragma label_applies_to geq
	constant length: INTEGER := max(L'length + 1, R'length);
    begin
	return is_less_or_equal(CONV_SIGNED(R, length),
				CONV_SIGNED(L, length)); -- pragma label geq
    end;


    function ">="(L: SIGNED; R: UNSIGNED) return BOOLEAN is
	-- pragma label_applies_to geq
	constant length: INTEGER := max(L'length, R'length + 1);
    begin
	return is_less_or_equal(CONV_SIGNED(R, length),
				CONV_SIGNED(L, length)); -- pragma label geq
    end;


    function ">="(L: UNSIGNED; R: INTEGER) return BOOLEAN is
	-- pragma label_applies_to geq
	constant length: INTEGER := L'length + 1;
    begin
	return is_less_or_equal(CONV_SIGNED(R, length),
				CONV_SIGNED(L, length)); -- pragma label geq
    end;


    function ">="(L: INTEGER; R: UNSIGNED) return BOOLEAN is
	-- pragma label_applies_to geq
	constant length: INTEGER := R'length + 1;
    begin
	return is_less_or_equal(CONV_SIGNED(R, length),
				CONV_SIGNED(L, length)); -- pragma label geq
    end;


    function ">="(L: SIGNED; R: INTEGER) return BOOLEAN is
	-- pragma label_applies_to geq
	constant length: INTEGER := L'length;
    begin
	return is_less_or_equal(CONV_SIGNED(R, length),
				CONV_SIGNED(L, length)); -- pragma label geq
    end;


    function ">="(L: INTEGER; R: SIGNED) return BOOLEAN is
	-- pragma label_applies_to geq
	constant length: INTEGER := R'length;
    begin
	return is_less_or_equal(CONV_SIGNED(R, length),
				CONV_SIGNED(L, length)); -- pragma label geq
    end;




    -- for internal use only.  Assumes SIGNED arguments of equal length.
    function bitwise_eql(L: MVL7_VECTOR; R: MVL7_VECTOR)
						return BOOLEAN is
	-- pragma built_in SYN_EQL
        variable result : BOOLEAN := TRUE ;
        -- Exemplar synthesis directive attributes for this function
        attribute SYNTHESIS_RETURN of result:variable is "EQ" ;
    begin
	for i in L'range loop
	    if L(i) /= R(i) then
		result := FALSE;
                exit ;
	    end if;
	end loop;
	return result;
    end;

    -- for internal use only.  Assumes SIGNED arguments of equal length.
    function bitwise_neq(L: MVL7_VECTOR; R: MVL7_VECTOR)
						return BOOLEAN is
	-- pragma built_in SYN_NEQ
        variable result : BOOLEAN := FALSE ;
        -- Exemplar synthesis directive attributes for this function
        attribute SYNTHESIS_RETURN of result:variable is "NEQ" ;
    begin
	for i in L'range loop
	    if L(i) /= R(i) then
		result := TRUE;
                exit ;
	    end if;
	end loop;
	return result ;
    end;

-- All of the following actual different forms of relational operations
-- will be compiled as is by Exemplar.


    function "="(L: UNSIGNED; R: UNSIGNED) return BOOLEAN is
	constant length: INTEGER := max(L'length, R'length);
    begin
	return bitwise_eql( MVL7_VECTOR( CONV_UNSIGNED(L, length) ),
		MVL7_VECTOR( CONV_UNSIGNED(R, length) ) );
    end;


    function "="(L: SIGNED; R: SIGNED) return BOOLEAN is
	constant length: INTEGER := max(L'length, R'length);
    begin
	return bitwise_eql( MVL7_VECTOR( CONV_SIGNED(L, length) ),
		MVL7_VECTOR( CONV_SIGNED(R, length) ) );
    end;


    function "="(L: UNSIGNED; R: SIGNED) return BOOLEAN is
	constant length: INTEGER := max(L'length + 1, R'length);
    begin
	return bitwise_eql( MVL7_VECTOR( CONV_SIGNED(L, length) ),
		MVL7_VECTOR( CONV_SIGNED(R, length) ) );
    end;


    function "="(L: SIGNED; R: UNSIGNED) return BOOLEAN is
	constant length: INTEGER := max(L'length, R'length + 1);
    begin
	return bitwise_eql( MVL7_VECTOR( CONV_SIGNED(L, length) ),
		MVL7_VECTOR( CONV_SIGNED(R, length) ) );
    end;


    function "="(L: UNSIGNED; R: INTEGER) return BOOLEAN is
	constant length: INTEGER := L'length + 1;
    begin
	return bitwise_eql( MVL7_VECTOR( CONV_SIGNED(L, length) ),
		MVL7_VECTOR( CONV_SIGNED(R, length) ) );
    end;


    function "="(L: INTEGER; R: UNSIGNED) return BOOLEAN is
	constant length: INTEGER := R'length + 1;
    begin
	return bitwise_eql( MVL7_VECTOR( CONV_SIGNED(L, length) ),
		MVL7_VECTOR( CONV_SIGNED(R, length) ) );
    end;


    function "="(L: SIGNED; R: INTEGER) return BOOLEAN is
	constant length: INTEGER := L'length;
    begin
	return bitwise_eql( MVL7_VECTOR( CONV_SIGNED(L, length) ),
		MVL7_VECTOR( CONV_SIGNED(R, length) ) );
    end;


    function "="(L: INTEGER; R: SIGNED) return BOOLEAN is
	constant length: INTEGER := R'length;
    begin
	return bitwise_eql( MVL7_VECTOR( CONV_SIGNED(L, length) ),
		MVL7_VECTOR( CONV_SIGNED(R, length) ) );
    end;




    function "/="(L: UNSIGNED; R: UNSIGNED) return BOOLEAN is
	constant length: INTEGER := max(L'length, R'length);
    begin
	return bitwise_neq( MVL7_VECTOR( CONV_UNSIGNED(L, length) ),
		MVL7_VECTOR( CONV_UNSIGNED(R, length) ) );
    end;


    function "/="(L: SIGNED; R: SIGNED) return BOOLEAN is
	constant length: INTEGER := max(L'length, R'length);
    begin
	return bitwise_neq( MVL7_VECTOR( CONV_SIGNED(L, length) ),
		MVL7_VECTOR( CONV_SIGNED(R, length) ) );
    end;


    function "/="(L: UNSIGNED; R: SIGNED) return BOOLEAN is
	constant length: INTEGER := max(L'length + 1, R'length);
    begin
	return bitwise_neq( MVL7_VECTOR( CONV_SIGNED(L, length) ),
		MVL7_VECTOR( CONV_SIGNED(R, length) ) );
    end;


    function "/="(L: SIGNED; R: UNSIGNED) return BOOLEAN is
	constant length: INTEGER := max(L'length, R'length + 1);
    begin
	return bitwise_neq( MVL7_VECTOR( CONV_SIGNED(L, length) ),
		MVL7_VECTOR( CONV_SIGNED(R, length) ) );
    end;


    function "/="(L: UNSIGNED; R: INTEGER) return BOOLEAN is
	constant length: INTEGER := L'length + 1;
    begin
	return bitwise_neq( MVL7_VECTOR( CONV_SIGNED(L, length) ),
		MVL7_VECTOR( CONV_SIGNED(R, length) ) );
    end;


    function "/="(L: INTEGER; R: UNSIGNED) return BOOLEAN is
	constant length: INTEGER := R'length + 1;
    begin
	return bitwise_neq( MVL7_VECTOR( CONV_SIGNED(L, length) ),
		MVL7_VECTOR( CONV_SIGNED(R, length) ) );
    end;


    function "/="(L: SIGNED; R: INTEGER) return BOOLEAN is
	constant length: INTEGER := L'length;
    begin
	return bitwise_neq( MVL7_VECTOR( CONV_SIGNED(L, length) ),
		MVL7_VECTOR( CONV_SIGNED(R, length) ) );
    end;


    function "/="(L: INTEGER; R: SIGNED) return BOOLEAN is
	constant length: INTEGER := R'length;
    begin
	return bitwise_neq( MVL7_VECTOR( CONV_SIGNED(L, length) ),
		MVL7_VECTOR( CONV_SIGNED(R, length) ) );
    end;



    function SHL(ARG: UNSIGNED; COUNT: UNSIGNED) return UNSIGNED is
	constant control_msb: INTEGER := COUNT'length - 1;
	variable control: UNSIGNED (control_msb downto 0);
	constant result_msb: INTEGER := ARG'length-1;
	subtype rtype is UNSIGNED (result_msb downto 0);
	variable result, temp: rtype;
        -- Exemplar synthesis directive attributes for this function
        attribute SYNTHESIS_RETURN of result:variable is "SLL" ;
    begin
	control := MAKE_BINARY(COUNT);
	result := ARG;
	for i in 0 to control_msb loop
	    if control(i) = '1' then
		temp := rtype'(others => '0');
		if 2**i < result_msb then
		    temp(result_msb downto 2**i) := 
				    result(result_msb - 2**i downto 0);
		end if;
		result := temp;
	    end if;
	end loop;
	return result;
    end;

    function SHL(ARG: SIGNED; COUNT: UNSIGNED) return SIGNED is
	constant control_msb: INTEGER := COUNT'length - 1;
	variable control: UNSIGNED (control_msb downto 0);
	constant result_msb: INTEGER := ARG'length-1;
	subtype rtype is SIGNED (result_msb downto 0);
	variable result, temp: rtype;
        -- Exemplar synthesis directive attributes for this function
        attribute SYNTHESIS_RETURN of result:variable is "SLL" ;
    begin
	control := MAKE_BINARY(COUNT);
	result := ARG;
	for i in 0 to control_msb loop
	    if control(i) = '1' then
		temp := rtype'(others => '0');
		if 2**i < result_msb then
		    temp(result_msb downto 2**i) := 
				    result(result_msb - 2**i downto 0);
		end if;
		result := temp;
	    end if;
	end loop;
	return result;
    end;


    function SHR(ARG: UNSIGNED; COUNT: UNSIGNED) return UNSIGNED is
	constant control_msb: INTEGER := COUNT'length - 1;
	variable control: UNSIGNED (control_msb downto 0);
	constant result_msb: INTEGER := ARG'length-1;
	subtype rtype is UNSIGNED (result_msb downto 0);
	variable result, temp: rtype;
        -- Exemplar synthesis directive attributes for this function
        attribute SYNTHESIS_RETURN of result:variable is "SRL" ;
    begin
	control := MAKE_BINARY(COUNT);
	result := ARG;
	for i in 0 to control_msb loop
	    if control(i) = '1' then
		temp := rtype'(others => '0');
		if 2**i < result_msb then
		    temp(result_msb - 2**i downto 0) := 
					result(result_msb downto 2**i);
		end if;
		result := temp;
	    end if;
	end loop;
	return result;
    end;

    function SHR(ARG: SIGNED; COUNT: UNSIGNED) return SIGNED is
	constant control_msb: INTEGER := COUNT'length - 1;
	variable control: UNSIGNED (control_msb downto 0);
	constant result_msb: INTEGER := ARG'length-1;
	subtype rtype is SIGNED (result_msb downto 0);
	variable result, temp: rtype;
	variable sign_bit: MVL7;
        -- Exemplar synthesis directive attributes for this function
        attribute SYNTHESIS_RETURN of result:variable is "SRA" ;
    begin
	control := MAKE_BINARY(COUNT);
	result := ARG;
	sign_bit := ARG(ARG'left);
	for i in 0 to control_msb loop
	    if control(i) = '1' then
		temp := rtype'(others => sign_bit);
		if 2**i < result_msb then
		    temp(result_msb - 2**i downto 0) := 
					result(result_msb downto 2**i);
		end if;
		result := temp;
	    end if;
	end loop;
	return result;
    end;




    function CONV_INTEGER(ARG: INTEGER) return INTEGER is
    begin
	return ARG;
    end;

    function CONV_INTEGER(ARG: UNSIGNED) return INTEGER is
	variable result: INTEGER;
	-- synopsys built_in SYN_UNSIGNED_TO_INTEGER;
        -- Exemplar synthesis directive attributes for this function
        attribute SYNTHESIS_RETURN of result:variable is "FEED_THROUGH" ;
    begin
	-- synopsys synthesis_off
	assert ARG'length <= 31
	    report "ARG is too large in CONV_INTEGER"
	    severity FAILURE;
	result := 0;
	for i in ARG'range loop
	    result := result * 2;
	    if tbl_BINARY(ARG(i)) = '1' then
		result := result + 1;
	    end if;
	end loop;
	return result;
	-- synopsys synthesis_on
    end;


    function CONV_INTEGER(ARG: SIGNED) return INTEGER is
	variable result: INTEGER;
	-- synopsys built_in SYN_SIGNED_TO_INTEGER;
        -- Exemplar synthesis directive attributes for this function
        attribute IS_SIGNED of ARG:constant is TRUE ;
        attribute SYNTHESIS_RETURN of result:variable is "FEED_THROUGH" ;
    begin
	-- synopsys synthesis_off
	assert ARG'length <= 32
	    report "ARG is too large in CONV_INTEGER"
	    severity FAILURE;
	result := 0;
	for i in ARG'range loop
	    if i /= ARG'left then
		result := result * 2;
		if tbl_BINARY(ARG(i)) = '1' then
		    result := result + 1;
		end if;
	    end if;
	end loop;
	if tbl_BINARY(ARG(ARG'left)) = '1' then
	    if ARG'length = 32 then
		result := (result - 2**30) - 2**30;
	    else
		result := result - (2 ** (ARG'length-1));
	    end if;
	end if;
	return result;
	-- synopsys synthesis_on
    end;


    function CONV_INTEGER(ARG: MVL7) return SMALL_INT is
    begin
	if MAKE_BINARY(ARG) = '0' then
	    return 0;
	else
	    return 1;
	end if;
    end;


    -- convert an integer to a unsigned MVL7_VECTOR
    function CONV_UNSIGNED(ARG: INTEGER; SIZE: INTEGER) return UNSIGNED is
	variable result: UNSIGNED(SIZE-1 downto 0);
	variable temp: integer;
	-- synopsys built_in SYN_INTEGER_TO_UNSIGNED
        -- Exemplar synthesis directive attributes for this function
        attribute SYNTHESIS_RETURN of result:variable is "FEED_THROUGH" ;
    begin
	-- synopsys synthesis_off
	temp := ARG;
	for i in 0 to SIZE-1 loop
	    if (temp mod 2) = 1 then
		result(i) := '1';
	    else 
		result(i) := '0';
	    end if;
	    if temp > 0 then
		temp := temp / 2;
	    else
		temp := (temp - 1) / 2; -- simulate ASR
	    end if;
	end loop;
	return result;
	-- synopsys synthesis_on
    end;


    function CONV_UNSIGNED(ARG: UNSIGNED; SIZE: INTEGER) return UNSIGNED is
	constant msb: INTEGER := min(ARG'length, SIZE) - 1;
	subtype rtype is UNSIGNED (SIZE-1 downto 0);
	variable new_bounds: UNSIGNED (ARG'length-1 downto 0);
	variable result: rtype;
	-- synopsys built_in SYN_ZERO_EXTEND
        -- Exemplar synthesis directive attributes for this function
        attribute SYNTHESIS_RETURN of result:variable is "FEED_THROUGH" ;
    begin
	-- synopsys synthesis_off
	result := rtype'(others => '0');
	new_bounds := MAKE_BINARY(ARG);
	result(msb downto 0) := new_bounds(msb downto 0);
	return result;
	-- synopsys synthesis_on
    end;


    function CONV_UNSIGNED(ARG: SIGNED; SIZE: INTEGER) return UNSIGNED is
	constant msb: INTEGER := min(ARG'length, SIZE) - 1;
	subtype rtype is UNSIGNED (SIZE-1 downto 0);
	variable new_bounds: UNSIGNED (ARG'length-1 downto 0);
	variable result: rtype;
	-- synopsys built_in SYN_SIGN_EXTEND
        -- Exemplar synthesis directive attributes for this function
        attribute IS_SIGNED of ARG:constant is TRUE ;
        attribute SYNTHESIS_RETURN of result:variable is "FEED_THROUGH" ;
    begin
	-- synopsys synthesis_off
	new_bounds := MAKE_BINARY(ARG);
	result := rtype'(others => new_bounds(new_bounds'left));
	result(msb downto 0) := new_bounds(msb downto 0);
	return result;
	-- synopsys synthesis_on
    end;


    function CONV_UNSIGNED(ARG: MVL7; SIZE: INTEGER) return UNSIGNED is
	subtype rtype is UNSIGNED (SIZE-1 downto 0);
	variable result: rtype;
	-- synopsys built_in SYN_ZERO_EXTEND
        -- Exemplar synthesis directive attributes for this function
        attribute SYNTHESIS_RETURN of result:variable is "FEED_THROUGH" ;
    begin
	-- synopsys synthesis_off
	result := rtype'(others => '0');
	result(0) := MAKE_BINARY(ARG);
	return result;
	-- synopsys synthesis_on
    end;


    -- convert an integer to a 2's complement MVL7_VECTOR
    function CONV_SIGNED(ARG: INTEGER; SIZE: INTEGER) return SIGNED is
	variable result: SIGNED (SIZE-1 downto 0);
	variable temp: integer;
	-- synopsys built_in SYN_INTEGER_TO_SIGNED
        -- Exemplar synthesis directive attributes for this function
        attribute SYNTHESIS_RETURN of result:variable is "FEED_THROUGH" ;
    begin
	-- synopsys synthesis_off
	temp := ARG;
	for i in 0 to SIZE-1 loop
	    if (temp mod 2) = 1 then
		result(i) := '1';
	    else 
		result(i) := '0';
	    end if;
	    if temp > 0 then
		temp := temp / 2;
	    else
		temp := (temp - 1) / 2; -- simulate ASR
	    end if;
	end loop;
	return result;
	-- synopsys synthesis_on
    end;


    function CONV_SIGNED(ARG: UNSIGNED; SIZE: INTEGER) return SIGNED is
	constant msb: INTEGER := min(ARG'length, SIZE) - 1;
	subtype rtype is SIGNED (SIZE-1 downto 0);
	variable new_bounds : SIGNED (ARG'length-1 downto 0);
	variable result: rtype;
	-- synopsys built_in SYN_ZERO_EXTEND
        -- Exemplar synthesis directive attributes for this function
        attribute SYNTHESIS_RETURN of result:variable is "FEED_THROUGH" ;
    begin
	-- synopsys synthesis_off
	result := rtype'(others => '0');
	new_bounds := MAKE_BINARY(ARG);
	result(msb downto 0) := new_bounds(msb downto 0);
	return result;
	-- synopsys synthesis_on
    end;

    function CONV_SIGNED(ARG: SIGNED; SIZE: INTEGER) return SIGNED is
	constant msb: INTEGER := min(ARG'length, SIZE) - 1;
	subtype rtype is SIGNED (SIZE-1 downto 0);
	variable new_bounds : SIGNED (ARG'length-1 downto 0);
	variable result: rtype;
	-- synopsys built_in SYN_SIGN_EXTEND
        -- Exemplar synthesis directive attributes for this function
        attribute IS_SIGNED of ARG:constant is TRUE ;
        attribute SYNTHESIS_RETURN of result:variable is "FEED_THROUGH" ;
    begin
	-- synopsys synthesis_off
	new_bounds := MAKE_BINARY(ARG);
	result := rtype'(others => new_bounds(new_bounds'left));
	result(msb downto 0) := new_bounds(msb downto 0);
	return result;
	-- synopsys synthesis_on
    end;


    function CONV_SIGNED(ARG: MVL7; SIZE: INTEGER) return SIGNED is
	subtype rtype is SIGNED (SIZE-1 downto 0);
	variable result: rtype;
	-- synopsys built_in SYN_ZERO_EXTEND
        -- Exemplar synthesis directive attributes for this function
        attribute SYNTHESIS_RETURN of result:variable is "FEED_THROUGH" ;
    begin
	-- synopsys synthesis_off
	result := rtype'(others => '0');
	result(0) := MAKE_BINARY(ARG);
	return result;
	-- synopsys synthesis_on
    end;




	function "and" (L, R: UNSIGNED) return UNSIGNED is
	  -- pragma built_in SYN_AND
--synopsys synthesis_off
		alias LV: UNSIGNED (L'length-1 downto 0) is L;
		alias RV: UNSIGNED (R'length-1 downto 0) is R;
		variable result: UNSIGNED (L'length-1 downto 0);
                -- Exemplar synthesis directive attributes for this function
                attribute SYNTHESIS_RETURN of result:variable is "AND" ;
--synopsys synthesis_on
	begin
--synopsys synthesis_off
		assert L'length = R'length;
		for i in result'range loop
			result (i) := LV (i) and RV (i);
		end loop;
		return result;
--synopsys synthesis_on
	end "and";


	function "nand" (L, R: UNSIGNED) return UNSIGNED is
	  -- pragma built_in SYN_NAND
--synopsys synthesis_off
		alias LV: UNSIGNED (L'length-1 downto 0) is L;
		alias RV: UNSIGNED (R'length-1 downto 0) is R;
		variable result: UNSIGNED (L'length-1 downto 0);
                -- Exemplar synthesis directive attributes for this function
                attribute SYNTHESIS_RETURN of result:variable is "NAND" ;
--synopsys synthesis_on
	begin
--synopsys synthesis_off
		assert L'length = R'length;
		for i in result'range loop
			result (i) := not(LV (i) and RV (i));
		end loop;
		return result;
--synopsys synthesis_on
	end "nand";


	function "or" (L, R: UNSIGNED) return UNSIGNED is
	  -- pragma built_in SYN_OR
--synopsys synthesis_off
		alias LV: UNSIGNED (L'length-1 downto 0) is L;
		alias RV: UNSIGNED (R'length-1 downto 0) is R;
		variable result: UNSIGNED (L'length-1 downto 0);
                -- Exemplar synthesis directive attributes for this function
                attribute SYNTHESIS_RETURN of result:variable is "OR" ;
--synopsys synthesis_on
	begin
--synopsys synthesis_off
		assert L'length = R'length;
		for i in result'range loop
			result (i) := LV (i) or RV (i);
		end loop;
		return result;
--synopsys synthesis_on
	end "or";


	function "nor" (L, R: UNSIGNED) return UNSIGNED is
	  -- pragma built_in SYN_NOR
--synopsys synthesis_off
		alias LV: UNSIGNED (L'length-1 downto 0) is L;
		alias RV: UNSIGNED (R'length-1 downto 0) is R;
		variable result: UNSIGNED (L'length-1 downto 0);
                -- Exemplar synthesis directive attributes for this function
                attribute SYNTHESIS_RETURN of result:variable is "NOR" ;
--synopsys synthesis_on
	begin
--synopsys synthesis_off
		assert L'length = R'length;
		for i in result'range loop
			result (i) := not(LV (i) or RV (i));
		end loop;
		return result;
--synopsys synthesis_on
	end "nor";


	function "xor" (L, R: UNSIGNED) return UNSIGNED is
	  -- pragma built_in SYN_XOR
--synopsys synthesis_off
		alias LV: UNSIGNED (L'length-1 downto 0) is L;
		alias RV: UNSIGNED (R'length-1 downto 0) is R;
		variable result: UNSIGNED (L'length-1 downto 0);
                -- Exemplar synthesis directive attributes for this function
                attribute SYNTHESIS_RETURN of result:variable is "XOR" ;
--synopsys synthesis_on
	begin
--synopsys synthesis_off
		assert L'length = R'length;
		for i in result'range loop
			result (i) := LV (i) xor RV (i);
		end loop;
		return result;
--synopsys synthesis_on
	end "xor";


	function nxor (L, R: UNSIGNED) return UNSIGNED is
	  -- pragma built_in SYN_XNOR
--synopsys synthesis_off
		alias LV: UNSIGNED (L'length-1 downto 0) is L;
		alias RV: UNSIGNED (R'length-1 downto 0) is R;
		variable result: UNSIGNED (L'length-1 downto 0);
                -- Exemplar synthesis directive attributes for this function
                attribute SYNTHESIS_RETURN of result:variable is "XNOR" ;
--synopsys synthesis_on
	begin
--synopsys synthesis_off
		assert L'length = R'length;
		for i in result'range loop
			 result(i) := not(LV(i) xor RV(i));
		end loop;
		return result;
--synopsys synthesis_on
	end nxor;


	function "not" (R: UNSIGNED) return UNSIGNED is
	  -- pragma built_in SYN_NOT
--synopsys synthesis_off
		alias RV: UNSIGNED (R'length-1 downto 0) is R;
		variable result: UNSIGNED (R'length-1 downto 0);
                -- Exemplar synthesis directive attributes for this function
                attribute SYNTHESIS_RETURN of result:variable is "NOT" ;
--synopsys synthesis_on
	begin
--synopsys synthesis_off
		for i in result'range loop
			result (i) := not RV(i);
		end loop;
		return result;
--synopsys synthesis_on
	end "not";


	function buf (R: UNSIGNED) return UNSIGNED is
	  -- pragma built_in SYN_BUF
--synopsys synthesis_off
		alias RV: UNSIGNED (R'length-1 downto 0) is R;
		variable result: UNSIGNED (R'length-1 downto 0);
                -- Exemplar synthesis directive attributes for this function
                attribute SYNTHESIS_RETURN of result:variable is "FEED_THROUGH" ;
--synopsys synthesis_on
	begin
--synopsys synthesis_off
		for i in result'range loop
			 -- only portable way to perform buf
		 	 result(i) := not( not RV(i) );
		end loop;
		return result;
--synopsys synthesis_on
	end buf;




	function "and" (L, R: SIGNED) return SIGNED is
	  -- pragma built_in SYN_AND
--synopsys synthesis_off
		alias LV: SIGNED (L'length-1 downto 0) is L;
		alias RV: SIGNED (R'length-1 downto 0) is R;
		variable result: SIGNED (L'length-1 downto 0);
                -- Exemplar synthesis directive attributes for this function
                attribute SYNTHESIS_RETURN of result:variable is "AND" ;
--synopsys synthesis_on
	begin
--synopsys synthesis_off
		assert L'length = R'length;
		for i in result'range loop
			result (i) := LV (i) and RV (i);
		end loop;
		return result;
--synopsys synthesis_on
	end "and";


	function "nand" (L, R: SIGNED) return SIGNED is
	  -- pragma built_in SYN_NAND
--synopsys synthesis_off
		alias LV: SIGNED (L'length-1 downto 0) is L;
		alias RV: SIGNED (R'length-1 downto 0) is R;
		variable result: SIGNED (L'length-1 downto 0);
                -- Exemplar synthesis directive attributes for this function
                attribute SYNTHESIS_RETURN of result:variable is "NAND" ;
--synopsys synthesis_on
	begin
--synopsys synthesis_off
		assert L'length = R'length;
		for i in result'range loop
			result (i) := not(LV (i) and RV (i));
		end loop;
		return result;
--synopsys synthesis_on
	end "nand";


	function "or" (L, R: SIGNED) return SIGNED is
	  -- pragma built_in SYN_OR
--synopsys synthesis_off
		alias LV: SIGNED (L'length-1 downto 0) is L;
		alias RV: SIGNED (R'length-1 downto 0) is R;
		variable result: SIGNED (L'length-1 downto 0);
                -- Exemplar synthesis directive attributes for this function
                attribute SYNTHESIS_RETURN of result:variable is "OR" ;
--synopsys synthesis_on
	begin
--synopsys synthesis_off
		assert L'length = R'length;
		for i in result'range loop
			result (i) := LV (i) or RV (i);
		end loop;
		return result;
--synopsys synthesis_on
	end "or";


	function "nor" (L, R: SIGNED) return SIGNED is
	  -- pragma built_in SYN_NOR
--synopsys synthesis_off
		alias LV: SIGNED (L'length-1 downto 0) is L;
		alias RV: SIGNED (R'length-1 downto 0) is R;
		variable result: SIGNED (L'length-1 downto 0);
                -- Exemplar synthesis directive attributes for this function
                attribute SYNTHESIS_RETURN of result:variable is "NOR" ;
--synopsys synthesis_on
	begin
--synopsys synthesis_off
		assert L'length = R'length;
		for i in result'range loop
			result (i) := not(LV (i) or RV (i));
		end loop;
		return result;
--synopsys synthesis_on
	end "nor";


	function "xor" (L, R: SIGNED) return SIGNED is
	  -- pragma built_in SYN_XOR
--synopsys synthesis_off
		alias LV: SIGNED (L'length-1 downto 0) is L;
		alias RV: SIGNED (R'length-1 downto 0) is R;
		variable result: SIGNED (L'length-1 downto 0);
                -- Exemplar synthesis directive attributes for this function
                attribute SYNTHESIS_RETURN of result:variable is "XOR" ;
--synopsys synthesis_on
	begin
--synopsys synthesis_off
		assert L'length = R'length;
		for i in result'range loop
			result (i) := LV (i) xor RV (i);
		end loop;
		return result;
--synopsys synthesis_on
	end "xor";


	function nxor (L, R: SIGNED) return SIGNED is
	  -- pragma built_in SYN_XNOR
--synopsys synthesis_off
		alias LV: SIGNED (L'length-1 downto 0) is L;
		alias RV: SIGNED (R'length-1 downto 0) is R;
		variable result: SIGNED (L'length-1 downto 0);
                -- Exemplar synthesis directive attributes for this function
                attribute SYNTHESIS_RETURN of result:variable is "XNOR" ;
--synopsys synthesis_on
	begin
--synopsys synthesis_off
		assert L'length = R'length;
		for i in result'range loop
			 result(i) := not(LV(i) xor RV(i));
		end loop;
		return result;
--synopsys synthesis_on
	end nxor;


	function "not" (R: SIGNED) return SIGNED is
	  -- pragma built_in SYN_NOT
--synopsys synthesis_off
		alias RV: SIGNED (R'length-1 downto 0) is R;
		variable result: SIGNED (R'length-1 downto 0);
                -- Exemplar synthesis directive attributes for this function
                attribute SYNTHESIS_RETURN of result:variable is "NOT" ;
--synopsys synthesis_on
	begin
--synopsys synthesis_off
		for i in result'range loop
			result (i) := not RV(i);
		end loop;
		return result;
--synopsys synthesis_on
	end "not";


	function buf (R: SIGNED) return SIGNED is
	  -- pragma built_in SYN_BUF
--synopsys synthesis_off
		alias RV: SIGNED (R'length-1 downto 0) is R;
		variable result: SIGNED (R'length-1 downto 0);
                -- Exemplar synthesis directive attributes for this function
                attribute SYNTHESIS_RETURN of result:variable is "FEED_THROUGH" ;
--synopsys synthesis_on
	begin
--synopsys synthesis_off
		for i in result'range loop
			 -- only portable way to perform buf
		 	 result(i) := not( not RV(i) );
		end loop;
		return result;
--synopsys synthesis_on
	end buf;




    function AND_REDUCE(ARG: MVL7_VECTOR) return MVL7 is
	variable result: MVL7;
        -- Exemplar synthesis directive attributes for this function
        attribute SYNTHESIS_RETURN of result:variable is "REDUCE_AND" ;
    begin
	result := '1';
	for i in ARG'range loop
	    result := result and ARG(i);
	end loop;
	return result;
    end;

    function NAND_REDUCE(ARG: MVL7_VECTOR) return MVL7 is
    begin
	return not AND_REDUCE(ARG);
    end;

    function OR_REDUCE(ARG: MVL7_VECTOR) return MVL7 is
	variable result: MVL7;
        -- Exemplar synthesis directive attributes for this function
        attribute SYNTHESIS_RETURN of result:variable is "REDUCE_OR" ;
    begin
	result := '0';
	for i in ARG'range loop
	    result := result or ARG(i);
	end loop;
	return result;
    end;

    function NOR_REDUCE(ARG: MVL7_VECTOR) return MVL7 is
    begin
	return not OR_REDUCE(ARG);
    end;

    function XOR_REDUCE(ARG: MVL7_VECTOR) return MVL7 is
	variable result: MVL7;
        -- Exemplar synthesis directive attributes for this function
        attribute SYNTHESIS_RETURN of result:variable is "REDUCE_XOR" ;
    begin
	result := '0';
	for i in ARG'range loop
	    result := result xor ARG(i);
	end loop;
	return result;
    end;

    function XNOR_REDUCE(ARG: MVL7_VECTOR) return MVL7 is
    begin
	return not XOR_REDUCE(ARG);
    end;

end arithmetic;
