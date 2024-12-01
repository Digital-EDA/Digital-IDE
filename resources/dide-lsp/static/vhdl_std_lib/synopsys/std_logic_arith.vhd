--------------------------------------------------------------------------
--                                                                      --
-- Copyright (c) 1990,1991,1992 by Synopsys, Inc.  All rights reserved. --
--                                                                      --
-- This source file may be used and distributed without restriction     --
-- provided that this copyright statement is not removed from the file  --
-- and that any derivative work contains this copyright notice.         --
--                                                                      --
--	Package name: STD_LOGIC_ARITH					--
--									--
--	Purpose: 							--
--	 A set of arithemtic, conversion, and comparison functions 	--
--	 for SIGNED, UNSIGNED, SMALL_INT, INTEGER, 			--
--	 STD_ULOGIC, STD_LOGIC, and STD_LOGIC_VECTOR.			--
--									--
--------------------------------------------------------------------------
-- Exemplar : Added synthesis directive attributes for the functions in 
--            this package.
--            These work similar to the Synopsys pragmas
--------------------------------------------------------------------------
--------------------------------------------------------------------------
-- Modifications :
-- Attributes added and sources modified for Xilinx specific optimizations
-- function has_x(s : unsigned) added for detecting 'x' in an unsigned array
--------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;

package std_logic_arith is

    type UNSIGNED is array (NATURAL range <>) of STD_LOGIC;
    type SIGNED is array (NATURAL range <>) of STD_LOGIC;
    subtype SMALL_INT is INTEGER range 0 to 1;

    function "+"(L: UNSIGNED; R: UNSIGNED) return UNSIGNED;
    function "+"(L: SIGNED; R: SIGNED) return SIGNED;
    function "+"(L: UNSIGNED; R: SIGNED) return SIGNED;
    function "+"(L: SIGNED; R: UNSIGNED) return SIGNED;
    function "+"(L: UNSIGNED; R: INTEGER) return UNSIGNED;
    function "+"(L: INTEGER; R: UNSIGNED) return UNSIGNED;
    function "+"(L: SIGNED; R: INTEGER) return SIGNED;
    function "+"(L: INTEGER; R: SIGNED) return SIGNED;
    function "+"(L: UNSIGNED; R: STD_ULOGIC) return UNSIGNED;
    function "+"(L: STD_ULOGIC; R: UNSIGNED) return UNSIGNED;
    function "+"(L: SIGNED; R: STD_ULOGIC) return SIGNED;
    function "+"(L: STD_ULOGIC; R: SIGNED) return SIGNED;

    function "+"(L: UNSIGNED; R: UNSIGNED) return STD_LOGIC_VECTOR;
    function "+"(L: SIGNED; R: SIGNED) return STD_LOGIC_VECTOR;
    function "+"(L: UNSIGNED; R: SIGNED) return STD_LOGIC_VECTOR;
    function "+"(L: SIGNED; R: UNSIGNED) return STD_LOGIC_VECTOR;
    function "+"(L: UNSIGNED; R: INTEGER) return STD_LOGIC_VECTOR;
    function "+"(L: INTEGER; R: UNSIGNED) return STD_LOGIC_VECTOR;
    function "+"(L: SIGNED; R: INTEGER) return STD_LOGIC_VECTOR;
    function "+"(L: INTEGER; R: SIGNED) return STD_LOGIC_VECTOR;
    function "+"(L: UNSIGNED; R: STD_ULOGIC) return STD_LOGIC_VECTOR;
    function "+"(L: STD_ULOGIC; R: UNSIGNED) return STD_LOGIC_VECTOR;
    function "+"(L: SIGNED; R: STD_ULOGIC) return STD_LOGIC_VECTOR;
    function "+"(L: STD_ULOGIC; R: SIGNED) return STD_LOGIC_VECTOR;

    function "-"(L: UNSIGNED; R: UNSIGNED) return UNSIGNED;
    function "-"(L: SIGNED; R: SIGNED) return SIGNED;
    function "-"(L: UNSIGNED; R: SIGNED) return SIGNED;
    function "-"(L: SIGNED; R: UNSIGNED) return SIGNED;
    function "-"(L: UNSIGNED; R: INTEGER) return UNSIGNED;
    function "-"(L: INTEGER; R: UNSIGNED) return UNSIGNED;
    function "-"(L: SIGNED; R: INTEGER) return SIGNED;
    function "-"(L: INTEGER; R: SIGNED) return SIGNED;
    function "-"(L: UNSIGNED; R: STD_ULOGIC) return UNSIGNED;
    function "-"(L: STD_ULOGIC; R: UNSIGNED) return UNSIGNED;
    function "-"(L: SIGNED; R: STD_ULOGIC) return SIGNED;
    function "-"(L: STD_ULOGIC; R: SIGNED) return SIGNED;

    function "-"(L: UNSIGNED; R: UNSIGNED) return STD_LOGIC_VECTOR;
    function "-"(L: SIGNED; R: SIGNED) return STD_LOGIC_VECTOR;
    function "-"(L: UNSIGNED; R: SIGNED) return STD_LOGIC_VECTOR;
    function "-"(L: SIGNED; R: UNSIGNED) return STD_LOGIC_VECTOR;
    function "-"(L: UNSIGNED; R: INTEGER) return STD_LOGIC_VECTOR;
    function "-"(L: INTEGER; R: UNSIGNED) return STD_LOGIC_VECTOR;
    function "-"(L: SIGNED; R: INTEGER) return STD_LOGIC_VECTOR;
    function "-"(L: INTEGER; R: SIGNED) return STD_LOGIC_VECTOR;
    function "-"(L: UNSIGNED; R: STD_ULOGIC) return STD_LOGIC_VECTOR;
    function "-"(L: STD_ULOGIC; R: UNSIGNED) return STD_LOGIC_VECTOR;
    function "-"(L: SIGNED; R: STD_ULOGIC) return STD_LOGIC_VECTOR;
    function "-"(L: STD_ULOGIC; R: SIGNED) return STD_LOGIC_VECTOR;

    function "+"(L: UNSIGNED) return UNSIGNED;
    function "+"(L: SIGNED) return SIGNED;
    function "-"(L: SIGNED) return SIGNED;
    function "ABS"(L: SIGNED) return SIGNED;

    function "+"(L: UNSIGNED) return STD_LOGIC_VECTOR;
    function "+"(L: SIGNED) return STD_LOGIC_VECTOR;
    function "-"(L: SIGNED) return STD_LOGIC_VECTOR;
    function "ABS"(L: SIGNED) return STD_LOGIC_VECTOR;

    function "*"(L: UNSIGNED; R: UNSIGNED) return UNSIGNED;
    function "*"(L: SIGNED; R: SIGNED) return SIGNED;
    function "*"(L: SIGNED; R: UNSIGNED) return SIGNED;
    function "*"(L: UNSIGNED; R: SIGNED) return SIGNED;

    function "*"(L: UNSIGNED; R: UNSIGNED) return STD_LOGIC_VECTOR;
    function "*"(L: SIGNED; R: SIGNED) return STD_LOGIC_VECTOR;
    function "*"(L: SIGNED; R: UNSIGNED) return STD_LOGIC_VECTOR;
    function "*"(L: UNSIGNED; R: SIGNED) return STD_LOGIC_VECTOR;

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
    function CONV_INTEGER(ARG: STD_ULOGIC) return SMALL_INT;

    function CONV_UNSIGNED(ARG: INTEGER; SIZE: INTEGER) return UNSIGNED;
    function CONV_UNSIGNED(ARG: UNSIGNED; SIZE: INTEGER) return UNSIGNED;
    function CONV_UNSIGNED(ARG: SIGNED; SIZE: INTEGER) return UNSIGNED;
    function CONV_UNSIGNED(ARG: STD_ULOGIC; SIZE: INTEGER) return UNSIGNED;

    function CONV_SIGNED(ARG: INTEGER; SIZE: INTEGER) return SIGNED;
    function CONV_SIGNED(ARG: UNSIGNED; SIZE: INTEGER) return SIGNED;
    function CONV_SIGNED(ARG: SIGNED; SIZE: INTEGER) return SIGNED;
    function CONV_SIGNED(ARG: STD_ULOGIC; SIZE: INTEGER) return SIGNED;

    function CONV_STD_LOGIC_VECTOR(ARG: INTEGER; SIZE: INTEGER) 
						       return STD_LOGIC_VECTOR;
    function CONV_STD_LOGIC_VECTOR(ARG: UNSIGNED; SIZE: INTEGER) 
						       return STD_LOGIC_VECTOR;
    function CONV_STD_LOGIC_VECTOR(ARG: SIGNED; SIZE: INTEGER) 
						       return STD_LOGIC_VECTOR;
    function CONV_STD_LOGIC_VECTOR(ARG: STD_ULOGIC; SIZE: INTEGER) 
						       return STD_LOGIC_VECTOR;
    -- zero extend STD_LOGIC_VECTOR (ARG) to SIZE, 
    -- SIZE < 0 is same as SIZE = 0
    -- returns STD_LOGIC_VECTOR(SIZE-1 downto 0)
    function EXT(ARG: STD_LOGIC_VECTOR; SIZE: INTEGER) return STD_LOGIC_VECTOR;

    -- sign extend STD_LOGIC_VECTOR (ARG) to SIZE, 
    -- SIZE < 0 is same as SIZE = 0
    -- return STD_LOGIC_VECTOR(SIZE-1 downto 0)
    function SXT(ARG: STD_LOGIC_VECTOR; SIZE: INTEGER) return STD_LOGIC_VECTOR;
    

    function mult(A,B: SIGNED) return SIGNED;    
    function mult(A,B: UNSIGNED) return UNSIGNED;
    function plus(A, B: SIGNED) return SIGNED;
    function unsigned_plus(A, B: UNSIGNED) return UNSIGNED;
    function minus(A, B: SIGNED) return SIGNED;
    function unsigned_minus(A, B: UNSIGNED) return UNSIGNED;
    function is_less(A, B: SIGNED) return BOOLEAN;
    function is_less_or_equal(A, B: SIGNED) return BOOLEAN;
    function unsigned_is_less(A, B: UNSIGNED) return BOOLEAN;
    function unsigned_is_less_or_equal(A, B: UNSIGNED) return BOOLEAN;
    
    --attribute foreign of mult[SIGNED, SIGNED return SIGNED]:function is "ieee_std_logic_arith_mult_signed"; 
    --attribute foreign of mult[UNSIGNED, UNSIGNED return UNSIGNED]:function is "ieee_std_logic_arith_mult_unsigned";
    --attribute foreign of plus[SIGNED, SIGNED return SIGNED]:function is "ieee_std_logic_arith_plus_signed";
    --attribute foreign of unsigned_plus[UNSIGNED, UNSIGNED return UNSIGNED]:function is "ieee_std_logic_arith_plus_unsigned";
    --attribute foreign of minus[SIGNED, SIGNED return SIGNED]:function is "ieee_std_logic_arith_minus_signed";
    --attribute foreign of unsigned_minus[UNSIGNED, UNSIGNED return UNSIGNED]:function is "ieee_std_logic_arith_minus_unsigned";
    
    --attribute foreign of is_less[SIGNED, SIGNED return BOOLEAN]:function is "ieee_std_logic_arith_signed_is_less";
    --attribute foreign of is_less_or_equal[SIGNED, SIGNED return BOOLEAN]:function is "ieee_std_logic_arith_signed_is_less_or_equal";
    --attribute foreign of unsigned_is_less[UNSIGNED, UNSIGNED return BOOLEAN]:function is "ieee_std_logic_arith_unsigned_is_less";
    --attribute foreign of unsigned_is_less_or_equal[UNSIGNED, UNSIGNED return BOOLEAN]:function is "ieee_std_logic_arith_unsigned_is_less_or_equal";

    --attribute foreign of CONV_INTEGER[UNSIGNED return INTEGER]:function is "ieee_std_logic_arith_conv_integer_unsigned";
    --attribute foreign of CONV_INTEGER[SIGNED return INTEGER]:function is "ieee_std_logic_arith_conv_integer_signed";
    --attribute foreign of CONV_INTEGER[STD_ULOGIC return SMALL_INT]:function is "ieee_std_logic_arith_conv_integer_ulogic";

    --attribute foreign of CONV_UNSIGNED[INTEGER, INTEGER return UNSIGNED]:function is "ieee_std_logic_arith_conv_unsigned_integer";
    --attribute foreign of CONV_UNSIGNED[UNSIGNED, INTEGER return UNSIGNED]:function is "ieee_std_logic_arith_conv_unsigned_zeroext";
    --attribute foreign of CONV_UNSIGNED[SIGNED, INTEGER return UNSIGNED]:function is "ieee_std_logic_arith_conv_unsigned_signext";

    --attribute foreign of CONV_SIGNED[INTEGER, INTEGER return SIGNED]:function is "ieee_std_logic_arith_conv_signed_integer";
    --attribute foreign of CONV_SIGNED[UNSIGNED, INTEGER return SIGNED]:function is "ieee_std_logic_arith_conv_signed_zeroext";
    --attribute foreign of CONV_SIGNED[SIGNED, INTEGER return SIGNED]:function is "ieee_std_logic_arith_conv_signed_signext";
    
    --attribute foreign of "="[UNSIGNED, UNSIGNED return BOOLEAN]:function is "ieee_std_logic_arith_equal_unsigned_unsigned";
    --attribute foreign of ">"[UNSIGNED, UNSIGNED return BOOLEAN]:function is "ieee_std_logic_arith_greater_unsigned_unsigned";

    attribute foreign of plus[SIGNED, SIGNED return SIGNED]:function is "std_logic_arith_signed_plus";
    attribute foreign of unsigned_plus[UNSIGNED, UNSIGNED return UNSIGNED]:function is "std_logic_arith_unsigned_plus";

    attribute foreign of "+"[SIGNED, SIGNED return SIGNED]:function is "std_logic_arith_signed_signed_plus";
    attribute foreign of "+"[UNSIGNED, UNSIGNED return UNSIGNED]:function is "std_logic_arith_unsigned_unsigned_plus";
    attribute foreign of "+"[UNSIGNED, SIGNED return SIGNED]:function is "std_logic_arith_unsigned_signed_plus";
    attribute foreign of "+"[SIGNED, UNSIGNED return SIGNED]:function is "std_logic_arith_signed_unsigned_plus";
    attribute foreign of "+"[INTEGER, UNSIGNED return UNSIGNED]:function is "std_logic_arith_integer_unsigned_plus";
    attribute foreign of "+"[UNSIGNED, INTEGER return UNSIGNED]:function is "std_logic_arith_unsigned_integer_plus";
    attribute foreign of "+"[INTEGER, SIGNED return SIGNED]:function is "std_logic_arith_integer_signed_plus";
    attribute foreign of "+"[SIGNED, INTEGER return SIGNED]:function is "std_logic_arith_signed_integer_plus";
    attribute foreign of "+"[std_ulogic, unsigned return unsigned]:function is "std_logic_arith_ulogic_unsigned_plus";
    attribute foreign of "+"[unsigned, std_ulogic return unsigned]:function is "std_logic_arith_unsigned_ulogic_plus";
    attribute foreign of "+"[std_ulogic, signed return signed]:function is "std_logic_arith_ulogic_signed_plus";
    attribute foreign of "+"[signed, std_ulogic return signed]:function is "std_logic_arith_signed_ulogic_plus";

    attribute foreign of "+"[SIGNED, SIGNED return std_logic_vector]:function is "std_logic_arith_signed_signed_plus";
    attribute foreign of "+"[UNSIGNED, UNSIGNED return std_logic_vector]:function is "std_logic_arith_unsigned_unsigned_plus";
    attribute foreign of "+"[UNSIGNED, SIGNED return std_logic_vector]:function is "std_logic_arith_unsigned_signed_plus";
    attribute foreign of "+"[SIGNED, UNSIGNED return std_logic_vector]:function is "std_logic_arith_signed_unsigned_plus";
    attribute foreign of "+"[INTEGER, UNSIGNED return std_logic_vector]:function is "std_logic_arith_integer_unsigned_plus";
    attribute foreign of "+"[UNSIGNED, INTEGER return std_logic_vector]:function is "std_logic_arith_unsigned_integer_plus";
    attribute foreign of "+"[INTEGER, SIGNED return std_logic_vector]:function is "std_logic_arith_integer_signed_plus";
    attribute foreign of "+"[SIGNED, INTEGER return std_logic_vector]:function is "std_logic_arith_signed_integer_plus";
    attribute foreign of "+"[std_ulogic, unsigned return std_logic_vector]:function is "std_logic_arith_ulogic_unsigned_plus";
    attribute foreign of "+"[unsigned, std_ulogic return std_logic_vector]:function is "std_logic_arith_unsigned_ulogic_plus";
    attribute foreign of "+"[std_ulogic, signed return std_logic_vector]:function is "std_logic_arith_ulogic_signed_plus";
    attribute foreign of "+"[signed, std_ulogic return std_logic_vector]:function is "std_logic_arith_signed_ulogic_plus";


    attribute foreign of minus[SIGNED, SIGNED return SIGNED]:function is "std_logic_arith_signed_minus";
    attribute foreign of unsigned_minus[UNSIGNED, UNSIGNED return UNSIGNED]:function is "std_logic_arith_unsigned_minus";

    attribute foreign of "-"[SIGNED, SIGNED return SIGNED]:function is "std_logic_arith_signed_signed_minus";
    attribute foreign of "-"[UNSIGNED, UNSIGNED return UNSIGNED]:function is "std_logic_arith_unsigned_unsigned_minus";
    attribute foreign of "-"[UNSIGNED, SIGNED return SIGNED]:function is "std_logic_arith_unsigned_signed_minus";
    attribute foreign of "-"[SIGNED, UNSIGNED return SIGNED]:function is "std_logic_arith_signed_unsigned_minus";
    attribute foreign of "-"[INTEGER, UNSIGNED return UNSIGNED]:function is "std_logic_arith_integer_unsigned_minus";
    attribute foreign of "-"[UNSIGNED, INTEGER return UNSIGNED]:function is "std_logic_arith_unsigned_integer_minus";
    attribute foreign of "-"[INTEGER, SIGNED return SIGNED]:function is "std_logic_arith_integer_signed_minus";
    attribute foreign of "-"[SIGNED, INTEGER return SIGNED]:function is "std_logic_arith_signed_integer_minus";
    attribute foreign of "-"[std_ulogic, unsigned return unsigned]:function is "std_logic_arith_ulogic_unsigned_minus";
    attribute foreign of "-"[unsigned, std_ulogic return unsigned]:function is "std_logic_arith_unsigned_ulogic_minus";
    attribute foreign of "-"[std_ulogic, signed return signed]:function is "std_logic_arith_ulogic_signed_minus";
    attribute foreign of "-"[signed, std_ulogic return signed]:function is "std_logic_arith_signed_ulogic_minus";

    attribute foreign of "-"[SIGNED, SIGNED return std_logic_vector]:function is "std_logic_arith_signed_signed_minus";
    attribute foreign of "-"[UNSIGNED, UNSIGNED return std_logic_vector]:function is "std_logic_arith_unsigned_unsigned_minus";
    attribute foreign of "-"[UNSIGNED, SIGNED return std_logic_vector]:function is "std_logic_arith_unsigned_signed_minus";
    attribute foreign of "-"[SIGNED, UNSIGNED return std_logic_vector]:function is "std_logic_arith_signed_unsigned_minus";
    attribute foreign of "-"[INTEGER, UNSIGNED return std_logic_vector]:function is "std_logic_arith_integer_unsigned_minus";
    attribute foreign of "-"[UNSIGNED, INTEGER return std_logic_vector]:function is "std_logic_arith_unsigned_integer_minus";
    attribute foreign of "-"[INTEGER, SIGNED return std_logic_vector]:function is "std_logic_arith_integer_signed_minus";
    attribute foreign of "-"[SIGNED, INTEGER return std_logic_vector]:function is "std_logic_arith_signed_integer_minus";
    attribute foreign of "-"[std_ulogic, unsigned return std_logic_vector]:function is "std_logic_arith_ulogic_unsigned_minus";
    attribute foreign of "-"[unsigned, std_ulogic return std_logic_vector]:function is "std_logic_arith_unsigned_ulogic_minus";
    attribute foreign of "-"[std_ulogic, signed return std_logic_vector]:function is "std_logic_arith_ulogic_signed_minus";
    attribute foreign of "-"[signed, std_ulogic return std_logic_vector]:function is "std_logic_arith_signed_ulogic_minus";

    attribute foreign of mult[SIGNED, SIGNED return SIGNED]:function is "std_logic_arith_signed_mult";
    attribute foreign of mult[UNSIGNED, UNSIGNED return UNSIGNED]:function is "std_logic_arith_unsigned_mult";

    attribute foreign of "*"[SIGNED, SIGNED return SIGNED]:function is "std_logic_arith_signed_signed_mult";
    attribute foreign of "*"[UNSIGNED, UNSIGNED return UNSIGNED]:function is "std_logic_arith_unsigned_unsigned_mult";
    attribute foreign of "*"[UNSIGNED, SIGNED return SIGNED]:function is "std_logic_arith_unsigned_signed_mult";
    attribute foreign of "*"[SIGNED, UNSIGNED return SIGNED]:function is "std_logic_arith_signed_unsigned_mult";
    attribute foreign of "*"[SIGNED, SIGNED return std_logic_vector]:function is "std_logic_arith_signed_signed_mult";
    attribute foreign of "*"[UNSIGNED, UNSIGNED return std_logic_vector]:function is "std_logic_arith_unsigned_unsigned_mult";
    attribute foreign of "*"[UNSIGNED, SIGNED return std_logic_vector]:function is "std_logic_arith_unsigned_signed_mult";
    attribute foreign of "*"[SIGNED, UNSIGNED return std_logic_vector]:function is "std_logic_arith_signed_unsigned_mult";

    attribute foreign of "+"[UNSIGNED return UNSIGNED]:function is "std_logic_arith_unary_plus";
    attribute foreign of "+"[SIGNED return SIGNED]:function is "std_logic_arith_unary_plus";
    attribute foreign of "-"[SIGNED return SIGNED]:function is "std_logic_arith_signed_unary_minus";
    attribute foreign of "ABS"[SIGNED return SIGNED]:function is "std_logic_arith_signed_unary_abs";
    attribute foreign of "+"[UNSIGNED return std_logic_vector]:function is "std_logic_arith_unary_plus";
    attribute foreign of "+"[SIGNED return std_logic_vector]:function is "std_logic_arith_unary_plus";
    attribute foreign of "-"[SIGNED return std_logic_vector]:function is "std_logic_arith_signed_unary_minus";
    attribute foreign of "ABS"[SIGNED return std_logic_vector]:function is "std_logic_arith_signed_unary_abs";

    attribute foreign of is_less[SIGNED, SIGNED return BOOLEAN]:function is "std_logic_arith_signed_is_less";
    attribute foreign of is_less_or_equal[SIGNED, SIGNED return BOOLEAN]:function is "std_logic_arith_signed_is_less_or_equal";
    attribute foreign of unsigned_is_less[UNSIGNED, UNSIGNED return BOOLEAN]:function is "std_logic_arith_unsigned_is_less";
    attribute foreign of unsigned_is_less_or_equal[UNSIGNED, UNSIGNED return BOOLEAN]:function is "std_logic_arith_unsigned_is_less_or_equal";
    attribute foreign of "<"[UNSIGNED, UNSIGNED return BOOLEAN]:function is "std_logic_arith_unsigned_unsigned_is_less";
    attribute foreign of "<"[SIGNED, SIGNED return BOOLEAN]:function is "std_logic_arith_signed_signed_is_less";
    attribute foreign of "<"[UNSIGNED, SIGNED return BOOLEAN]:function is "std_logic_arith_unsigned_signed_is_less";
    attribute foreign of "<"[SIGNED, UNSIGNED return BOOLEAN]:function is "std_logic_arith_signed_unsigned_is_less";
    attribute foreign of "<"[UNSIGNED, INTEGER return BOOLEAN]:function is "std_logic_arith_unsigned_integer_is_less";
    attribute foreign of "<"[INTEGER, UNSIGNED return BOOLEAN]:function is "std_logic_arith_integer_unsigned_is_less";
    attribute foreign of "<"[SIGNED, INTEGER return BOOLEAN]:function is "std_logic_arith_signed_integer_is_less";
    attribute foreign of "<"[INTEGER, SIGNED return BOOLEAN]:function is "std_logic_arith_integer_signed_is_less";
    attribute foreign of "<="[UNSIGNED, UNSIGNED return BOOLEAN]:function is "std_logic_arith_unsigned_unsigned_is_less_or_equal";
    attribute foreign of "<="[SIGNED, SIGNED return BOOLEAN]:function is "std_logic_arith_signed_signed_is_less_or_equal";
    attribute foreign of "<="[UNSIGNED, SIGNED return BOOLEAN]:function is "std_logic_arith_unsigned_signed_is_less_or_equal";
    attribute foreign of "<="[SIGNED, UNSIGNED return BOOLEAN]:function is "std_logic_arith_signed_unsigned_is_less_or_equal";
    attribute foreign of "<="[UNSIGNED, INTEGER return BOOLEAN]:function is "std_logic_arith_unsigned_integer_is_less_or_equal";
    attribute foreign of "<="[INTEGER, UNSIGNED return BOOLEAN]:function is "std_logic_arith_integer_unsigned_is_less_or_equal";
    attribute foreign of "<="[SIGNED, INTEGER return BOOLEAN]:function is "std_logic_arith_signed_integer_is_less_or_equal";
    attribute foreign of "<="[INTEGER, SIGNED return BOOLEAN]:function is "std_logic_arith_integer_signed_is_less_or_equal";
    attribute foreign of ">"[UNSIGNED, UNSIGNED return BOOLEAN]:function is "std_logic_arith_unsigned_unsigned_is_greater";
    attribute foreign of ">"[SIGNED, SIGNED return BOOLEAN]:function is "std_logic_arith_signed_signed_is_greater";
    attribute foreign of ">"[UNSIGNED, SIGNED return BOOLEAN]:function is "std_logic_arith_unsigned_signed_is_greater";
    attribute foreign of ">"[SIGNED, UNSIGNED return BOOLEAN]:function is "std_logic_arith_signed_unsigned_is_greater";
    attribute foreign of ">"[UNSIGNED, INTEGER return BOOLEAN]:function is "std_logic_arith_unsigned_integer_is_greater";
    attribute foreign of ">"[INTEGER, UNSIGNED return BOOLEAN]:function is "std_logic_arith_integer_unsigned_is_greater";
    attribute foreign of ">"[SIGNED, INTEGER return BOOLEAN]:function is "std_logic_arith_signed_integer_is_greater";
    attribute foreign of ">"[INTEGER, SIGNED return BOOLEAN]:function is "std_logic_arith_integer_signed_is_greater";
    attribute foreign of ">="[UNSIGNED, UNSIGNED return BOOLEAN]:function is "std_logic_arith_unsigned_unsigned_is_greater_or_equal";
    attribute foreign of ">="[SIGNED, SIGNED return BOOLEAN]:function is "std_logic_arith_signed_signed_is_greater_or_equal";
    attribute foreign of ">="[UNSIGNED, SIGNED return BOOLEAN]:function is "std_logic_arith_unsigned_signed_is_greater_or_equal";
    attribute foreign of ">="[SIGNED, UNSIGNED return BOOLEAN]:function is "std_logic_arith_signed_unsigned_is_greater_or_equal";
    attribute foreign of ">="[UNSIGNED, INTEGER return BOOLEAN]:function is "std_logic_arith_unsigned_integer_is_greater_or_equal";
    attribute foreign of ">="[INTEGER, UNSIGNED return BOOLEAN]:function is "std_logic_arith_integer_unsigned_is_greater_or_equal";
    attribute foreign of ">="[SIGNED, INTEGER return BOOLEAN]:function is "std_logic_arith_signed_integer_is_greater_or_equal";
    attribute foreign of ">="[INTEGER, SIGNED return BOOLEAN]:function is "std_logic_arith_integer_signed_is_greater_or_equal";
    attribute foreign of "="[UNSIGNED, UNSIGNED return BOOLEAN]:function is "std_logic_arith_unsigned_unsigned_is_equal";
    attribute foreign of "="[SIGNED, SIGNED return BOOLEAN]:function is "std_logic_arith_signed_signed_is_equal";
    attribute foreign of "="[UNSIGNED, SIGNED return BOOLEAN]:function is "std_logic_arith_unsigned_signed_is_equal";
    attribute foreign of "="[SIGNED, UNSIGNED return BOOLEAN]:function is "std_logic_arith_signed_unsigned_is_equal";
    attribute foreign of "="[UNSIGNED, INTEGER return BOOLEAN]:function is "std_logic_arith_unsigned_integer_is_equal";
    attribute foreign of "="[INTEGER, UNSIGNED return BOOLEAN]:function is "std_logic_arith_integer_unsigned_is_equal";
    attribute foreign of "="[SIGNED, INTEGER return BOOLEAN]:function is "std_logic_arith_signed_integer_is_equal";
    attribute foreign of "="[INTEGER, SIGNED return BOOLEAN]:function is "std_logic_arith_integer_signed_is_equal";
    attribute foreign of "/="[UNSIGNED, UNSIGNED return BOOLEAN]:function is "std_logic_arith_unsigned_unsigned_is_not_equal";
    attribute foreign of "/="[SIGNED, SIGNED return BOOLEAN]:function is "std_logic_arith_signed_signed_is_not_equal";
    attribute foreign of "/="[UNSIGNED, SIGNED return BOOLEAN]:function is "std_logic_arith_unsigned_signed_is_not_equal";
    attribute foreign of "/="[SIGNED, UNSIGNED return BOOLEAN]:function is "std_logic_arith_signed_unsigned_is_not_equal";
    attribute foreign of "/="[UNSIGNED, INTEGER return BOOLEAN]:function is "std_logic_arith_unsigned_integer_is_not_equal";
    attribute foreign of "/="[INTEGER, UNSIGNED return BOOLEAN]:function is "std_logic_arith_integer_unsigned_is_not_equal";
    attribute foreign of "/="[SIGNED, INTEGER return BOOLEAN]:function is "std_logic_arith_signed_integer_is_not_equal";
    attribute foreign of "/="[INTEGER, SIGNED return BOOLEAN]:function is "std_logic_arith_integer_signed_is_not_equal";

    attribute foreign of SHL[unsigned, unsigned return unsigned]:function is "std_logic_arith_unsigned_shl";
    attribute foreign of SHL[signed, unsigned return signed]:function is "std_logic_arith_signed_shl";
    attribute foreign of SHR[unsigned, unsigned return unsigned]:function is "std_logic_arith_unsigned_shr";
    attribute foreign of SHR[signed, unsigned return signed]:function is "std_logic_arith_signed_shr";
                                                                             
    attribute foreign of conv_integer[integer return integer]:function is "std_logic_arith_conv_integer_to_integer";
    attribute foreign of conv_integer[unsigned return integer]:function is "std_logic_arith_conv_unsigned_to_integer";
    attribute foreign of conv_integer[signed return integer]:function is "std_logic_arith_conv_signed_to_integer";
    attribute foreign of conv_integer[std_ulogic return integer]:function is "std_logic_arith_conv_ulogic_to_integer";
                                                                           
    attribute foreign of conv_unsigned[integer, integer return unsigned]:function is "std_logic_arith_conv_integer_to_unsigned";
    attribute foreign of conv_unsigned[unsigned, integer return unsigned]:function is "std_logic_arith_conv_unsigned_to_unsigned";
    attribute foreign of conv_unsigned[signed, integer return unsigned]:function is "std_logic_arith_conv_signed_to_unsigned";
    attribute foreign of conv_unsigned[std_ulogic, integer return unsigned]:function is "std_logic_arith_conv_ulogic_to_unsigned";

    attribute foreign of conv_signed[integer, integer return signed]:function is "std_logic_arith_conv_integer_to_signed";
    attribute foreign of conv_signed[unsigned, integer return signed]:function is "std_logic_arith_conv_unsigned_to_signed";
    attribute foreign of conv_signed[signed, integer return signed]:function is "std_logic_arith_conv_signed_to_signed";
    attribute foreign of conv_signed[std_ulogic, integer return signed]:function is "std_logic_arith_conv_ulogic_to_signed";

    attribute foreign of conv_std_logic_vector[integer, integer return std_logic_vector]:function is "std_logic_arith_conv_integer_to_vector";
    attribute foreign of conv_std_logic_vector[unsigned, integer return std_logic_vector]:function is "std_logic_arith_conv_unsigned_to_vector";
    attribute foreign of conv_std_logic_vector[signed, integer return std_logic_vector]:function is "std_logic_arith_conv_signed_to_vector";
    attribute foreign of conv_std_logic_vector[std_ulogic, integer return std_logic_vector]:function is "std_logic_arith_conv_ulogic_to_vector";

    attribute foreign of ext[std_logic_vector, integer return std_logic_vector]:function is "std_logic_arith_ext";
    attribute foreign of sxt[std_logic_vector, integer return std_logic_vector]:function is "std_logic_arith_sxt";

    attribute foreign of Std_logic_arith: package is "copy extra C function";
-- Verific : attributes re-declaration causes use-clause inclusion conflicts if re-declared here.
    -- Exemplar Synthesis Directive Attributes
    attribute IS_SIGNED : BOOLEAN ;
    attribute SYNTHESIS_RETURN : STRING ;

end Std_logic_arith;


library IEEE;
use IEEE.std_logic_1164.all;

package body std_logic_arith is

    function has_x(s : unsigned) return boolean is
       constant len: integer:=s'length;
       alias sv: unsigned(1 to len) is s;
    begin
       for i in 1 to len loop
	  case sv(i) is
	  when '0'|'1'|'H'|'L' => null;
	  when others => return true;
	  end case;
       end loop;
       return false;
    end;

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
    type tbl_type is array (STD_ULOGIC) of STD_ULOGIC;
    constant tbl_BINARY : tbl_type :=
	('X', 'X', '0', '1', 'X', 'X', '0', '1', 'X');
    -- synopsys synthesis_on

    -- synopsys synthesis_off
    type tbl_mvl9_boolean is array (STD_ULOGIC) of boolean;
    constant IS_X : tbl_mvl9_boolean :=
        (true, true, false, false, true, true, false, false, true);
    -- synopsys synthesis_on



    function MAKE_BINARY(A : STD_ULOGIC) return STD_ULOGIC is
	-- synopsys built_in SYN_FEED_THRU
        variable result : STD_ULOGIC ;
        -- Add Exemplar synthesis attribute
        attribute SYNTHESIS_RETURN of result:variable is "FEED_THROUGH" ;
    begin
	-- synopsys synthesis_off
	    if (IS_X(A)) then
		assert false 
		report "There is an 'U'|'X'|'W'|'Z'|'-' in an arithmetic operand, the result will be 'X'(es)."
		severity warning;
	        result := ('X');
                return result ;
	    end if;
	    result := tbl_BINARY(A);
            return result ;
	-- synopsys synthesis_on
    end;

    function MAKE_BINARY(A : UNSIGNED) return UNSIGNED is
	-- synopsys built_in SYN_FEED_THRU
	-- variable one_bit : STD_ULOGIC;
	variable result : UNSIGNED (A'range);
        -- Add Exemplar synthesis attribute
        attribute SYNTHESIS_RETURN of result:variable is "FEED_THROUGH" ;
    begin
	-- synopsys synthesis_off
	    for i in A'range loop
	        if (IS_X(A(i))) then
		    assert false 
		    report "There is an 'U'|'X'|'W'|'Z'|'-' in an arithmetic operand, the result will be 'X'(es)."
		    severity warning;
		    result := (others => 'X');
	            return result;
	        end if;
		result(i) := tbl_BINARY(A(i));
	    end loop;
	    return result;
	-- synopsys synthesis_on
    end;

    function MAKE_BINARY(A : UNSIGNED) return SIGNED is
	-- synopsys built_in SYN_FEED_THRU
	-- variable one_bit : STD_ULOGIC;
	variable result : SIGNED (A'range);
        -- Add Exemplar synthesis attribute
        attribute SYNTHESIS_RETURN of result:variable is "FEED_THROUGH" ;
    begin
	-- synopsys synthesis_off
	    for i in A'range loop
	        if (IS_X(A(i))) then
		    assert false 
		    report "There is an 'U'|'X'|'W'|'Z'|'-' in an arithmetic operand, the result will be 'X'(es)."
		    severity warning;
		    result := (others => 'X');
	            return result;
	        end if;
		result(i) := tbl_BINARY(A(i));
	    end loop;
	    return result;
	-- synopsys synthesis_on
    end;

    function MAKE_BINARY(A : SIGNED) return UNSIGNED is
	-- synopsys built_in SYN_FEED_THRU
	-- variable one_bit : STD_ULOGIC;
	variable result : UNSIGNED (A'range);
        -- Add Exemplar synthesis attribute
        attribute SYNTHESIS_RETURN of result:variable is "FEED_THROUGH" ;
    begin
	-- synopsys synthesis_off
	    for i in A'range loop
	        if (IS_X(A(i))) then
		    assert false 
		    report "There is an 'U'|'X'|'W'|'Z'|'-' in an arithmetic operand, the result will be 'X'(es)."
		    severity warning;
		    result := (others => 'X');
	            return result;
	        end if;
		result(i) := tbl_BINARY(A(i));
	    end loop;
	    return result;
	-- synopsys synthesis_on
    end;

    function MAKE_BINARY(A : SIGNED) return SIGNED is
	-- synopsys built_in SYN_FEED_THRU
	-- variable one_bit : STD_ULOGIC;
	variable result : SIGNED (A'range);
        -- Add Exemplar synthesis attribute
        attribute SYNTHESIS_RETURN of result:variable is "FEED_THROUGH" ;
    begin
	-- synopsys synthesis_off
	    for i in A'range loop
	        if (IS_X(A(i))) then
		    assert false 
		    report "There is an 'U'|'X'|'W'|'Z'|'-' in an arithmetic operand, the result will be 'X'(es)."
		    severity warning;
		    result := (others => 'X');
	            return result;
	        end if;
		result(i) := tbl_BINARY(A(i));
	    end loop;
	    return result;
	-- synopsys synthesis_on
    end;

    function MAKE_BINARY(A : STD_LOGIC_VECTOR) return STD_LOGIC_VECTOR is
	-- synopsys built_in SYN_FEED_THRU
	-- variable one_bit : STD_ULOGIC;
	variable result : STD_LOGIC_VECTOR (A'range);
        -- Add Exemplar synthesis attribute
        attribute SYNTHESIS_RETURN of result:variable is "FEED_THROUGH" ;
    begin
	-- synopsys synthesis_off
	    for i in A'range loop
	        if (IS_X(A(i))) then
		    assert false 
		    report "There is an 'U'|'X'|'W'|'Z'|'-' in an arithmetic operand, the result will be 'X'(es)."
		    severity warning;
		    result := (others => 'X');
	            return result;
	        end if;
		result(i) := tbl_BINARY(A(i));
	    end loop;
	    return result;
	-- synopsys synthesis_on
    end;

    function MAKE_BINARY(A : UNSIGNED) return STD_LOGIC_VECTOR is
	-- synopsys built_in SYN_FEED_THRU
	-- variable one_bit : STD_ULOGIC;
	variable result : STD_LOGIC_VECTOR (A'range);
        -- Add Exemplar synthesis attribute
        attribute SYNTHESIS_RETURN of result:variable is "FEED_THROUGH" ;
    begin
	-- synopsys synthesis_off
	    for i in A'range loop
	        if (IS_X(A(i))) then
		    assert false 
		    report "There is an 'U'|'X'|'W'|'Z'|'-' in an arithmetic operand, the result will be 'X'(es)."
		    severity warning;
		    result := (others => 'X');
	            return result;
	        end if;
		result(i) := tbl_BINARY(A(i));
	    end loop;
	    return result;
	-- synopsys synthesis_on
    end;

    function MAKE_BINARY(A : SIGNED) return STD_LOGIC_VECTOR is
	-- synopsys built_in SYN_FEED_THRU
	-- variable one_bit : STD_ULOGIC;
	variable result : STD_LOGIC_VECTOR (A'range);
        -- Add Exemplar synthesis attribute
        attribute SYNTHESIS_RETURN of result:variable is "FEED_THROUGH" ;
    begin
	-- synopsys synthesis_off
	    for i in A'range loop
	        if (IS_X(A(i))) then
		    assert false 
		    report "There is an 'U'|'X'|'W'|'Z'|'-' in an arithmetic operand, the result will be 'X'(es)."
		    severity warning;
		    result := (others => 'X');
	            return result;
	        end if;
		result(i) := tbl_BINARY(A(i));
	    end loop;
	    return result;
	-- synopsys synthesis_on
    end;



    -- Type propagation function which returns a signed type with the
    -- size of the left arg.
    function LEFT_SIGNED_ARG(A,B: SIGNED) return SIGNED is
      variable Z: SIGNED (A'left downto 0) := (others=>'X') ;
      -- pragma return_port_name Z
    begin
      return(Z);
    end;
	
    -- Type propagation function which returns an unsigned type with the
    -- size of the left arg.
    function LEFT_UNSIGNED_ARG(A,B: UNSIGNED) return UNSIGNED is
      variable Z: UNSIGNED (A'left downto 0) := (others=>'X') ;
      -- pragma return_port_name Z
    begin
      return(Z);
    end;
	
    -- Type propagation function which returns a signed type with the
    -- size of the result of a signed multiplication
    function MULT_SIGNED_ARG(A,B: SIGNED) return SIGNED is
      variable Z: SIGNED ((A'length+B'length-1) downto 0) := (others=>'X') ;
      -- pragma return_port_name Z
    begin
      return(Z);
    end;
	
    -- Type propagation function which returns an unsigned type with the
    -- size of the result of a unsigned multiplication
    function MULT_UNSIGNED_ARG(A,B: UNSIGNED) return UNSIGNED is
      variable Z: UNSIGNED ((A'length+B'length-1) downto 0) := (others=>'X') ;
      -- pragma return_port_name Z
    begin
      return(Z);
    end;



    function mult(A,B: SIGNED) return SIGNED is

      variable BA: SIGNED((A'length+B'length-1) downto 0);
      variable PA: SIGNED((A'length+B'length-1) downto 0);
      variable AA: SIGNED(A'length downto 0);
      variable neg: STD_ULOGIC;
      constant one : UNSIGNED(1 downto 0) := "01";
      
      -- pragma map_to_operator MULT_TC_OP
      -- pragma type_function MULT_SIGNED_ARG
      -- pragma return_port_name Z

      	-- pragma label_applies_to mult

        -- Add Exemplar synthesis attributes
        attribute IS_SIGNED of A:constant is TRUE ;
        attribute IS_SIGNED of B:constant is TRUE ;
		attribute is_signed of PA:variable is TRUE ;
        attribute SYNTHESIS_RETURN of PA:variable is "MULT" ;
      begin
	if (A(A'left) = 'X' or B(B'left) = 'X') then
            PA := (others => 'X');
            return(PA);
	end if;
        PA := (others => '0');
        neg := B(B'left) xor A(A'left);
        BA := CONV_SIGNED(('0' & SIGNED'(ABS(B))),(A'length+B'length));
        AA := '0' & SIGNED'(ABS(A));
        for i in 0 to A'length-1 loop
          if AA(i) = '1' then
            PA := PA+BA;
          end if;
          BA := SHL(BA,one);
        end loop;
        if (neg= '1') then
          return(-PA);
        else 
          return(PA);
        end if;
      end;

-- this is the Xilinx customized 'mult(A,B: UNSIGNED) return UNSIGNED' version
-- I assume the deviation from standard version was to workaround legacy parser
-- issues.  Using the Xilinx one, verific one commented out below. -muggli

      function mult(A,B: UNSIGNED) return UNSIGNED is

        constant msb: integer:=A'length+B'length-1;
        variable BA: UNSIGNED(msb downto 0);
        variable PA: UNSIGNED(msb downto 0);
        
        -- pragma map_to_operator MULT_UNS_OP
        -- pragma type_function MULT_UNSIGNED_ARG
        -- pragma return_port_name Z

      begin
        if (A(A'left) = 'X' or B(B'left) = 'X') then
          PA := (others => 'X');
          return(PA);
        end if;
        PA := (others => '0');
        BA := CONV_UNSIGNED(B,(A'length+B'length));
        for i in 0 to A'length-1 loop
          if A(i) = '1' then
            PA := PA+BA;
          end if;
          for j in msb downto 1 loop
            BA(j):=BA(j-1);
          end loop;
          BA(0) := '0';
        end loop;
        return(PA);
      end;

    --function mult(A,B: UNSIGNED) return UNSIGNED is

    --  variable BA: UNSIGNED((A'length+B'length-1) downto 0);
    --  variable PA: UNSIGNED((A'length+B'length-1) downto 0);
    --  constant one : UNSIGNED(1 downto 0) := "01";
      
    --  -- pragma map_to_operator MULT_UNS_OP
    --  -- pragma type_function MULT_UNSIGNED_ARG
    --  -- pragma return_port_name Z

	---- pragma label_applies_to mult
      
    --    -- Add Exemplar synthesis attributes
    --    attribute SYNTHESIS_RETURN of PA:variable is "MULT" ;
    --  begin
	--if (A(A'left) = 'X' or B(B'left) = 'X') then
    --        PA := (others => 'X');
    --        return(PA);
	--end if;
    --    PA := (others => '0');
    --    BA := CONV_UNSIGNED(B,(A'length+B'length));
    --    for i in 0 to A'length-1 loop
    --      if A(i) = '1' then
    --        PA := PA+BA;
    --      end if;
    --      BA := SHL(BA,one);
    --    end loop;
    --    return(PA);
    --  end;

    -- subtract two signed numbers of the same length
    -- both arrays must have range (msb downto 0)
    function minus(A, B: SIGNED) return SIGNED is
	variable carry: STD_ULOGIC;
	variable BV: STD_ULOGIC_VECTOR (A'left downto 0);
	variable sum: SIGNED (A'left downto 0);

	-- pragma map_to_operator SUB_TC_OP

	-- pragma type_function LEFT_SIGNED_ARG
        -- pragma return_port_name Z
	-- pragma label_applies_to minus

        -- Add Exemplar synthesis attributes
        attribute IS_SIGNED of A:constant is TRUE ;
        attribute IS_SIGNED of B:constant is TRUE ;
		attribute is_signed of sum:variable is TRUE ;
        attribute SYNTHESIS_RETURN of sum:variable is "SUB" ;
    begin
	if (A(A'left) = 'X' or B(B'left) = 'X') then
            sum := (others => 'X');
            return(sum);
	end if;
	carry := '1';
	BV := not STD_ULOGIC_VECTOR(B);

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
	variable carry: STD_ULOGIC;
	variable BV, sum: SIGNED (A'left downto 0);

	-- pragma map_to_operator ADD_TC_OP
	-- pragma type_function LEFT_SIGNED_ARG
        -- pragma return_port_name Z
	-- pragma label_applies_to plus

        -- Add Exemplar synthesis attributes
        attribute IS_SIGNED of A:constant is TRUE ;
        attribute IS_SIGNED of B:constant is TRUE ;
		attribute is_signed of sum:variable is TRUE ;
        attribute SYNTHESIS_RETURN of sum:variable is "ADD" ;
    begin
	if (A(A'left) = 'X' or B(B'left) = 'X') then
            sum := (others => 'X');
            return(sum);
	end if;
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
	variable carry: STD_ULOGIC;
	variable BV: STD_ULOGIC_VECTOR (A'left downto 0);
	variable sum: UNSIGNED (A'left downto 0);

	-- pragma map_to_operator SUB_UNS_OP
	-- pragma type_function LEFT_UNSIGNED_ARG
        -- pragma return_port_name Z
	-- pragma label_applies_to minus

        -- Add Exemplar synthesis attributes
        attribute SYNTHESIS_RETURN of sum:variable is "SUB" ;
    begin
	if (A(A'left) = 'X' or B(B'left) = 'X') then
            sum := (others => 'X');
            return(sum);
	end if;
	carry := '1';
	BV := not STD_ULOGIC_VECTOR(B);

	for i in 0 to A'left loop
	    sum(i) := A(i) xor BV(i) xor carry;
	    carry := (A(i) and BV(i)) or
		    (A(i) and carry) or
		    (carry and BV(i));
	end loop;
	return sum;
    end;

-- this is the Xilinx customized 'unsigned_plus(A,B: UNSIGNED) return UNSIGNED' version
-- I assume the deviation from standard version was to workaround legacy parser
-- issues.  Using the Xilinx one, verific one commented out below. -muggli
    -- add two unsigned numbers of the same length
    -- both arrays must have range (msb downto 0)
    function unsigned_plus(A, B: UNSIGNED) return UNSIGNED is
      variable carry,x: STD_ULOGIC;
      constant msb: natural:=a'length-1;
      variable sum: UNSIGNED (msb downto 0);
      alias av: Unsigned(msb downto 0) is a;
      alias bv: Unsigned(msb downto 0) is B;

      -- pragma map_to_operator ADD_UNS_OP
      -- pragma type_function LEFT_UNSIGNED_ARG
      -- pragma return_port_name Z

    begin
      if (Av(msb) = 'X' or Bv(msb) = 'X') then
        sum := (others => 'X');
        return(sum);
      end if;

      sum(0) := Av(0) xor BV(0);
      carry := Av(0) and BV(0);
      for i in 1 to msb-1 loop
        x := Av(i) xor Bv(i);
        sum(i) := x xor carry;
        carry := (Av(i) and BV(i))
                 or (carry and x);
      end loop;
      if msb>0 then
        sum(msb) := Av(msb) xor BV(msb) xor carry;
      end if;
      return sum;
    end;

    
    -- add two unsigned numbers of the same length
    -- both arrays must have range (msb downto 0)
    --function unsigned_plus(A, B: UNSIGNED) return UNSIGNED is
	--variable carry: STD_ULOGIC;
	--variable BV, sum: UNSIGNED (A'left downto 0);

	---- pragma map_to_operator ADD_UNS_OP
	---- pragma type_function LEFT_UNSIGNED_ARG
    --    -- pragma return_port_name Z
	---- pragma label_applies_to plus

    --    -- Add Exemplar synthesis attributes
    --    attribute SYNTHESIS_RETURN of sum:variable is "ADD" ;
    --begin
	--if (A(A'left) = 'X' or B(B'left) = 'X') then
    --        sum := (others => 'X');
    --        return(sum);
	--end if;
	--carry := '0';
	--BV := B;

	--for i in 0 to A'left loop
	--    sum(i) := A(i) xor BV(i) xor carry;
	--    carry := (A(i) and BV(i)) or
	--	    (A(i) and carry) or
	--	    (carry and BV(i));
	--end loop;
	--return sum;
    --end;



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


    function "*"(L: SIGNED; R: SIGNED) return STD_LOGIC_VECTOR is
	-- pragma label_applies_to mult
    begin
          return STD_LOGIC_VECTOR (mult(CONV_SIGNED(L, L'length),
		          CONV_SIGNED(R, R'length))); -- pragma label mult 
    end;
      
    function "*"(L: UNSIGNED; R: UNSIGNED) return STD_LOGIC_VECTOR is
	-- pragma label_applies_to mult
    begin
          return STD_LOGIC_VECTOR (mult(CONV_UNSIGNED(L, L'length),
                        CONV_UNSIGNED(R, R'length))); -- pragma label mult 
    end;
        
    function "*"(L: UNSIGNED; R: SIGNED) return STD_LOGIC_VECTOR is
	-- pragma label_applies_to plus
    begin
 	return STD_LOGIC_VECTOR (mult(CONV_SIGNED(L, L'length+1),
		          CONV_SIGNED(R, R'length))); -- pragma label mult 
    end;

    function "*"(L: SIGNED; R: UNSIGNED) return STD_LOGIC_VECTOR is
	-- pragma label_applies_to plus
    begin
	return STD_LOGIC_VECTOR (mult(CONV_SIGNED(L, L'length),
		         CONV_SIGNED(R, R'length+1))); -- pragma label mult 
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
        -- adder. R will be interpreted as signed integer.
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
        -- adder. L will be interpreted as signed integer.
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


    function "+"(L: UNSIGNED; R: STD_ULOGIC) return UNSIGNED is
	-- pragma label_applies_to plus
	constant length: INTEGER := L'length;
    begin
	return unsigned_plus(CONV_UNSIGNED(L, length),
		     CONV_UNSIGNED(R, length)) ; -- pragma label plus
    end;


    function "+"(L: STD_ULOGIC; R: UNSIGNED) return UNSIGNED is
	-- pragma label_applies_to plus
	constant length: INTEGER := R'length;
    begin
	return unsigned_plus(CONV_UNSIGNED(L, length),
		     CONV_UNSIGNED(R, length)); -- pragma label plus
    end;


    function "+"(L: SIGNED; R: STD_ULOGIC) return SIGNED is
	-- pragma label_applies_to plus
	constant length: INTEGER := L'length;
    begin
	return plus(CONV_SIGNED(L, length),
		    CONV_SIGNED(R, length)); -- pragma label plus
    end;


    function "+"(L: STD_ULOGIC; R: SIGNED) return SIGNED is
	-- pragma label_applies_to plus
	constant length: INTEGER := R'length;
    begin
	return plus(CONV_SIGNED(L, length),
		    CONV_SIGNED(R, length)); -- pragma label plus
    end;



    function "+"(L: UNSIGNED; R: UNSIGNED) return STD_LOGIC_VECTOR is
	-- pragma label_applies_to plus
	constant length: INTEGER := max(L'length, R'length);
    begin
	return STD_LOGIC_VECTOR (unsigned_plus(CONV_UNSIGNED(L, length),
			     CONV_UNSIGNED(R, length))); -- pragma label plus
    end;


    function "+"(L: SIGNED; R: SIGNED) return STD_LOGIC_VECTOR is
	-- pragma label_applies_to plus
	constant length: INTEGER := max(L'length, R'length);
    begin
	return STD_LOGIC_VECTOR (plus(CONV_SIGNED(L, length),
		    CONV_SIGNED(R, length))); -- pragma label plus
    end;


    function "+"(L: UNSIGNED; R: SIGNED) return STD_LOGIC_VECTOR is
	-- pragma label_applies_to plus
	constant length: INTEGER := max(L'length + 1, R'length);
    begin
	return STD_LOGIC_VECTOR (plus(CONV_SIGNED(L, length),
		    CONV_SIGNED(R, length))); -- pragma label plus
    end;


    function "+"(L: SIGNED; R: UNSIGNED) return STD_LOGIC_VECTOR is
	-- pragma label_applies_to plus
	constant length: INTEGER := max(L'length, R'length + 1);
    begin
	return STD_LOGIC_VECTOR (plus(CONV_SIGNED(L, length),
		    CONV_SIGNED(R, length))); -- pragma label plus
    end;


    function "+"(L: UNSIGNED; R: INTEGER) return STD_LOGIC_VECTOR is
	-- pragma label_applies_to plus
	constant length: INTEGER := L'length + 1;
        -- It does not make sense to extend L one bit and eliminate 
        -- the MSB result bit. For Exemplar : build a length-1 
        -- adder. R will be interpreted as signed integer.
        variable result : STD_LOGIC_VECTOR(length-2 downto 0) ;
        attribute SYNTHESIS_RETURN of result:variable is "ADD" ;
    begin
	result := STD_LOGIC_VECTOR (CONV_UNSIGNED(
		plus( -- pragma label plus
		    CONV_SIGNED(L, length),
		    CONV_SIGNED(R, length)),
		length-1));
        return result ;
    end;


    function "+"(L: INTEGER; R: UNSIGNED) return STD_LOGIC_VECTOR is
	-- pragma label_applies_to plus
	constant length: INTEGER := R'length + 1;
        -- It does not make sense to extend R one bit and eliminate 
        -- the MSB result bit. For Exemplar : build a length-1 
        -- adder. L will be interpreted as signed integer.
        variable result : STD_LOGIC_VECTOR(length-2 downto 0) ;
        attribute SYNTHESIS_RETURN of result:variable is "ADD" ;
    begin
	result := STD_LOGIC_VECTOR (CONV_UNSIGNED(
		plus( -- pragma label plus
		    CONV_SIGNED(L, length),
		    CONV_SIGNED(R, length)),
		length-1));
        return result ;
    end;


    function "+"(L: SIGNED; R: INTEGER) return STD_LOGIC_VECTOR is
	-- pragma label_applies_to plus
	constant length: INTEGER := L'length;
    begin
	return STD_LOGIC_VECTOR (plus(CONV_SIGNED(L, length),
		    CONV_SIGNED(R, length))); -- pragma label plus
    end;


    function "+"(L: INTEGER; R: SIGNED) return STD_LOGIC_VECTOR is
	-- pragma label_applies_to plus
	constant length: INTEGER := R'length;
    begin
	return STD_LOGIC_VECTOR (plus(CONV_SIGNED(L, length),
		    CONV_SIGNED(R, length))); -- pragma label plus
    end;


    function "+"(L: UNSIGNED; R: STD_ULOGIC) return STD_LOGIC_VECTOR is
	-- pragma label_applies_to plus
	constant length: INTEGER := L'length;
    begin
	return STD_LOGIC_VECTOR (unsigned_plus(CONV_UNSIGNED(L, length),
		     CONV_UNSIGNED(R, length))) ; -- pragma label plus
    end;


    function "+"(L: STD_ULOGIC; R: UNSIGNED) return STD_LOGIC_VECTOR is
	-- pragma label_applies_to plus
	constant length: INTEGER := R'length;
    begin
	return STD_LOGIC_VECTOR (unsigned_plus(CONV_UNSIGNED(L, length),
		     CONV_UNSIGNED(R, length))); -- pragma label plus
    end;


    function "+"(L: SIGNED; R: STD_ULOGIC) return STD_LOGIC_VECTOR is
	-- pragma label_applies_to plus
	constant length: INTEGER := L'length;
    begin
	return STD_LOGIC_VECTOR (plus(CONV_SIGNED(L, length),
		    CONV_SIGNED(R, length))); -- pragma label plus
    end;


    function "+"(L: STD_ULOGIC; R: SIGNED) return STD_LOGIC_VECTOR is
	-- pragma label_applies_to plus
	constant length: INTEGER := R'length;
    begin
	return STD_LOGIC_VECTOR (plus(CONV_SIGNED(L, length),
		    CONV_SIGNED(R, length))); -- pragma label plus
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
        -- unsigned subtractor. R will be interpreted as signed integer.
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
        -- unsigned subtractor (L will be interpreted as (signed) integer).
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


    function "-"(L: UNSIGNED; R: STD_ULOGIC) return UNSIGNED is
	-- pragma label_applies_to minus
	constant length: INTEGER := L'length + 1;
        -- It does not make sense to extend L one bit and eliminate 
        -- the MSB result bit. For Exemplar : build a length-1 
        -- unsigned subtractor. R is unsigned since CONV_SIGNED on 
        -- std_ulogic does zero-extension.
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


    function "-"(L: STD_ULOGIC; R: UNSIGNED) return UNSIGNED is
	-- pragma label_applies_to minus
	constant length: INTEGER := R'length + 1;
        -- It does not make sense to extend R one bit and eliminate 
        -- the MSB result bit. For Exemplar : build a length-1 
        -- unsigned subtractor. L is unsigned since CONV_SIGNED on 
        -- std_ulogic does zero-extension.
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


    function "-"(L: SIGNED; R: STD_ULOGIC) return SIGNED is
	-- pragma label_applies_to minus
	constant length: INTEGER := L'length;
    begin
	return minus(CONV_SIGNED(L, length),
		     CONV_SIGNED(R, length)); -- pragma label minus
    end;


    function "-"(L: STD_ULOGIC; R: SIGNED) return SIGNED is
	-- pragma label_applies_to minus
	constant length: INTEGER := R'length;
    begin
	return minus(CONV_SIGNED(L, length),
		     CONV_SIGNED(R, length)); -- pragma label minus
    end;




    function "-"(L: UNSIGNED; R: UNSIGNED) return STD_LOGIC_VECTOR is
	-- pragma label_applies_to minus
	constant length: INTEGER := max(L'length, R'length);
    begin
	return STD_LOGIC_VECTOR (unsigned_minus(CONV_UNSIGNED(L, length),
		      	      CONV_UNSIGNED(R, length))); -- pragma label minus
    end;


    function "-"(L: SIGNED; R: SIGNED) return STD_LOGIC_VECTOR is
	-- pragma label_applies_to minus
	constant length: INTEGER := max(L'length, R'length);
    begin
	return STD_LOGIC_VECTOR (minus(CONV_SIGNED(L, length),
		     CONV_SIGNED(R, length))); -- pragma label minus
    end;


    function "-"(L: UNSIGNED; R: SIGNED) return STD_LOGIC_VECTOR is
	-- pragma label_applies_to minus
	constant length: INTEGER := max(L'length + 1, R'length);
    begin
	return STD_LOGIC_VECTOR (minus(CONV_SIGNED(L, length),
		     CONV_SIGNED(R, length))); -- pragma label minus
    end;


    function "-"(L: SIGNED; R: UNSIGNED) return STD_LOGIC_VECTOR is
	-- pragma label_applies_to minus
	constant length: INTEGER := max(L'length, R'length + 1);
    begin
	return STD_LOGIC_VECTOR (minus(CONV_SIGNED(L, length),
		     CONV_SIGNED(R, length))); -- pragma label minus
    end;


    function "-"(L: UNSIGNED; R: INTEGER) return STD_LOGIC_VECTOR is
	-- pragma label_applies_to minus
	constant length: INTEGER := L'length + 1;
        -- It does not make sense to extend L one bit and eliminate 
        -- the MSB result bit. For Exemplar : build a length-1 
        -- unsigned subtractor. R will be interpreted as signed or 
        -- unsigned, depending on its range.
        variable result : STD_LOGIC_VECTOR(length-2 downto 0) ;
        attribute SYNTHESIS_RETURN of result:variable is "SUB" ;
    begin
	result := STD_LOGIC_VECTOR (CONV_UNSIGNED(
		minus( -- pragma label minus
		    CONV_SIGNED(L, length),
		    CONV_SIGNED(R, length)),
		length-1));
        return result ;
    end;


    function "-"(L: INTEGER; R: UNSIGNED) return STD_LOGIC_VECTOR is
	-- pragma label_applies_to minus
	constant length: INTEGER := R'length + 1;
        -- It does not make sense to extend R one bit and eliminate 
        -- the MSB result bit. For Exemplar : build a length-1 
        -- unsigned subtractor. L will be interpreted as signed or 
        -- unsigned, depending on its range.
        variable result : STD_LOGIC_VECTOR(length-2 downto 0) ;
        attribute SYNTHESIS_RETURN of result:variable is "SUB" ;
    begin
	result := STD_LOGIC_VECTOR (CONV_UNSIGNED(
		minus( -- pragma label minus
		    CONV_SIGNED(L, length),
		    CONV_SIGNED(R, length)),
		length-1));
        return result ;
    end;


    function "-"(L: SIGNED; R: INTEGER) return STD_LOGIC_VECTOR is
	-- pragma label_applies_to minus
	constant length: INTEGER := L'length;
    begin
	return STD_LOGIC_VECTOR (minus(CONV_SIGNED(L, length),
		     CONV_SIGNED(R, length))); -- pragma label minus
    end;


    function "-"(L: INTEGER; R: SIGNED) return STD_LOGIC_VECTOR is
	-- pragma label_applies_to minus
	constant length: INTEGER := R'length;
    begin
	return STD_LOGIC_VECTOR (minus(CONV_SIGNED(L, length),
		     CONV_SIGNED(R, length))); -- pragma label minus
    end;


    function "-"(L: UNSIGNED; R: STD_ULOGIC) return STD_LOGIC_VECTOR is
	-- pragma label_applies_to minus
	constant length: INTEGER := L'length + 1;
        -- It does not make sense to extend L one bit and eliminate 
        -- the MSB result bit. For Exemplar : build a length-1 
        -- unsigned subtractor. R is unsigned since CONV_SIGNED does
        -- zero-extend on std_ulogic.
        variable result : STD_LOGIC_VECTOR(length-2 downto 0) ;
        attribute SYNTHESIS_RETURN of result:variable is "SUB" ;
    begin
	result := STD_LOGIC_VECTOR (CONV_UNSIGNED(
		minus( -- pragma label minus
		    CONV_SIGNED(L, length),
		    CONV_SIGNED(R, length)),
		length-1));
        return result ;
    end;


    function "-"(L: STD_ULOGIC; R: UNSIGNED) return STD_LOGIC_VECTOR is
	-- pragma label_applies_to minus
	constant length: INTEGER := R'length + 1;
        -- It does not make sense to extend R one bit and eliminate 
        -- the MSB result bit. For Exemplar : build a length-1 
        -- unsigned subtractor. L is unsigned since CONV_SIGNED does
        -- zero-extend on std_ulogic.
        variable result : STD_LOGIC_VECTOR(length-2 downto 0) ;
        attribute SYNTHESIS_RETURN of result:variable is "SUB" ;
    begin
	result := STD_LOGIC_VECTOR (CONV_UNSIGNED(
		minus( -- pragma label minus
		    CONV_SIGNED(L, length),
		    CONV_SIGNED(R, length)),
		length-1));
        return result ;
    end;


    function "-"(L: SIGNED; R: STD_ULOGIC) return STD_LOGIC_VECTOR is
	-- pragma label_applies_to minus
	constant length: INTEGER := L'length;
    begin
	return STD_LOGIC_VECTOR (minus(CONV_SIGNED(L, length),
		     CONV_SIGNED(R, length))); -- pragma label minus
    end;


    function "-"(L: STD_ULOGIC; R: SIGNED) return STD_LOGIC_VECTOR is
	-- pragma label_applies_to minus
	constant length: INTEGER := R'length;
    begin
	return STD_LOGIC_VECTOR (minus(CONV_SIGNED(L, length),
		     CONV_SIGNED(R, length))); -- pragma label minus
    end;




    function "+"(L: UNSIGNED) return UNSIGNED is
	-- pragma label_applies_to plus
    begin
	return L;
    end;


    function "+"(L: SIGNED) return SIGNED is
	-- pragma label_applies_to plus
    begin
	return L;
    end;


    function "-"(L: SIGNED) return SIGNED is
	-- pragma label_applies_to minus
        variable result : SIGNED(L'range) ;
        attribute IS_SIGNED of L:constant is TRUE ;
		attribute is_signed of result:variable is TRUE ;
        attribute SYNTHESIS_RETURN of result:variable is "UMINUS" ;
    begin
	result := 0 - L; -- pragma label minus
        return result ;
    end;


    function "ABS"(L: SIGNED) return SIGNED is
	-- pragma label_applies_to abs
      
        variable result : SIGNED(L'range) ;
        attribute IS_SIGNED of L:constant is TRUE ;
        attribute SYNTHESIS_RETURN of result:variable is "ABS" ;
    begin
	if (L(L'left) = '0' or L(L'left) = 'L') then
	    result := L;
	else
	    result := 0 - L;
	end if;
        return result ;
    end;


    function "+"(L: UNSIGNED) return STD_LOGIC_VECTOR is
	-- pragma label_applies_to plus
    begin
	return STD_LOGIC_VECTOR (L);
    end;


    function "+"(L: SIGNED) return STD_LOGIC_VECTOR is
	-- pragma label_applies_to plus
    begin
	return STD_LOGIC_VECTOR (L);
    end;


    function "-"(L: SIGNED) return STD_LOGIC_VECTOR is
	-- pragma label_applies_to minus
	variable tmp: SIGNED(L'length-1 downto 0);
        variable result : STD_LOGIC_VECTOR(tmp'range) ;
        attribute IS_SIGNED of L:constant is TRUE ;
		attribute is_signed of result:variable is TRUE ;
        attribute SYNTHESIS_RETURN of result:variable is "UMINUS" ;
    begin
	tmp := 0 - L;  -- pragma label minus
	result := STD_LOGIC_VECTOR (tmp); 
        return result ;
    end;


    function "ABS"(L: SIGNED) return STD_LOGIC_VECTOR is
	-- pragma label_applies_to abs
      
	variable tmp: SIGNED(L'length-1 downto 0);
        variable result : STD_LOGIC_VECTOR(tmp'range) ;
        attribute IS_SIGNED of L:constant is TRUE ;
        attribute SYNTHESIS_RETURN of result:variable is "ABS" ;
    begin
	if (L(L'left) = '0' or L(L'left) = 'L') then
	    result := STD_LOGIC_VECTOR (L);
	else
	    tmp := 0 - L;
	    result := STD_LOGIC_VECTOR (tmp);
	end if;
        return result ;
    end;


    -- Type propagation function which returns the type BOOLEAN
    function UNSIGNED_RETURN_BOOLEAN(A,B: UNSIGNED) return BOOLEAN is
      variable Z: BOOLEAN := FALSE ;
      -- pragma return_port_name Z
    begin
      return(Z);
    end;
	
    -- Type propagation function which returns the type BOOLEAN
    function SIGNED_RETURN_BOOLEAN(A,B: SIGNED) return BOOLEAN is
      variable Z: BOOLEAN := FALSE ;
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
	-- pragma label_applies_to lt

        -- Exemplar synthesis directives 
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
	-- pragma label_applies_to leq

        -- Exemplar synthesis directives 
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
	-- pragma label_applies_to leq

        -- Exemplar synthesis directives 
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
	-- pragma label_applies_to leq

        -- Exemplar synthesis directives 
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
    function bitwise_eql(L: STD_ULOGIC_VECTOR; R: STD_ULOGIC_VECTOR)
						return BOOLEAN is
	-- pragma label_applies_to eq
	-- pragma built_in SYN_EQL
        -- Exemplar synthesis directives 
        variable result : BOOLEAN ;
        attribute SYNTHESIS_RETURN of result:variable is "EQ" ;
    begin
	for i in L'range loop
	    if L(i) /= R(i) then
                result := FALSE ;
                return result ;
	    end if;
	end loop;
        result := TRUE ;
        return result ;
    end;

    -- for internal use only.  Assumes SIGNED arguments of equal length.
    function bitwise_neq(L: STD_ULOGIC_VECTOR; R: STD_ULOGIC_VECTOR)
						return BOOLEAN is
	-- pragma label_applies_to neq
	-- pragma built_in SYN_NEQ
        -- Exemplar synthesis directives 
        variable result : BOOLEAN ;
        attribute SYNTHESIS_RETURN of result:variable is "NEQ" ;
    begin
	for i in L'range loop
	    if L(i) /= R(i) then
                result := TRUE ;
		return result ;
	    end if;
	end loop;
	result := FALSE;
        return result ;
    end;


    function "="(L: UNSIGNED; R: UNSIGNED) return BOOLEAN is
	-- pragma label_applies_to eq
	constant length: INTEGER := max(L'length, R'length);
    begin
	return bitwise_eql( STD_ULOGIC_VECTOR( CONV_UNSIGNED(L, length) ),
		STD_ULOGIC_VECTOR( CONV_UNSIGNED(R, length) ) );
    end;


    function "="(L: SIGNED; R: SIGNED) return BOOLEAN is
	-- pragma label_applies_to eq
	constant length: INTEGER := max(L'length, R'length);
    begin
	return bitwise_eql( STD_ULOGIC_VECTOR( CONV_SIGNED(L, length) ),
		STD_ULOGIC_VECTOR( CONV_SIGNED(R, length) ) );
    end;


    function "="(L: UNSIGNED; R: SIGNED) return BOOLEAN is
	-- pragma label_applies_to eq
	constant length: INTEGER := max(L'length + 1, R'length);
    begin
	return bitwise_eql( STD_ULOGIC_VECTOR( CONV_SIGNED(L, length) ),
		STD_ULOGIC_VECTOR( CONV_SIGNED(R, length) ) );
    end;


    function "="(L: SIGNED; R: UNSIGNED) return BOOLEAN is
	-- pragma label_applies_to eq
	constant length: INTEGER := max(L'length, R'length + 1);
    begin
	return bitwise_eql( STD_ULOGIC_VECTOR( CONV_SIGNED(L, length) ),
		STD_ULOGIC_VECTOR( CONV_SIGNED(R, length) ) );
    end;


    function "="(L: UNSIGNED; R: INTEGER) return BOOLEAN is
	-- pragma label_applies_to eq
	constant length: INTEGER := L'length + 1;
    begin
	return bitwise_eql( STD_ULOGIC_VECTOR( CONV_SIGNED(L, length) ),
		STD_ULOGIC_VECTOR( CONV_SIGNED(R, length) ) );
    end;


    function "="(L: INTEGER; R: UNSIGNED) return BOOLEAN is
	-- pragma label_applies_to eq
	constant length: INTEGER := R'length + 1;
    begin
	return bitwise_eql( STD_ULOGIC_VECTOR( CONV_SIGNED(L, length) ),
		STD_ULOGIC_VECTOR( CONV_SIGNED(R, length) ) );
    end;


    function "="(L: SIGNED; R: INTEGER) return BOOLEAN is
	-- pragma label_applies_to eq
	constant length: INTEGER := L'length;
    begin
	return bitwise_eql( STD_ULOGIC_VECTOR( CONV_SIGNED(L, length) ),
		STD_ULOGIC_VECTOR( CONV_SIGNED(R, length) ) );
    end;


    function "="(L: INTEGER; R: SIGNED) return BOOLEAN is
	-- pragma label_applies_to eq
	constant length: INTEGER := R'length;
    begin
	return bitwise_eql( STD_ULOGIC_VECTOR( CONV_SIGNED(L, length) ),
		STD_ULOGIC_VECTOR( CONV_SIGNED(R, length) ) );
    end;




    function "/="(L: UNSIGNED; R: UNSIGNED) return BOOLEAN is
	-- pragma label_applies_to neq
	constant length: INTEGER := max(L'length, R'length);
    begin
	return bitwise_neq( STD_ULOGIC_VECTOR( CONV_UNSIGNED(L, length) ),
		STD_ULOGIC_VECTOR( CONV_UNSIGNED(R, length) ) );
    end;


    function "/="(L: SIGNED; R: SIGNED) return BOOLEAN is
	-- pragma label_applies_to neq
	constant length: INTEGER := max(L'length, R'length);
    begin
	return bitwise_neq( STD_ULOGIC_VECTOR( CONV_SIGNED(L, length) ),
		STD_ULOGIC_VECTOR( CONV_SIGNED(R, length) ) );
    end;


    function "/="(L: UNSIGNED; R: SIGNED) return BOOLEAN is
	-- pragma label_applies_to neq
	constant length: INTEGER := max(L'length + 1, R'length);
    begin
	return bitwise_neq( STD_ULOGIC_VECTOR( CONV_SIGNED(L, length) ),
		STD_ULOGIC_VECTOR( CONV_SIGNED(R, length) ) );
    end;


    function "/="(L: SIGNED; R: UNSIGNED) return BOOLEAN is
	-- pragma label_applies_to neq
	constant length: INTEGER := max(L'length, R'length + 1);
    begin
	return bitwise_neq( STD_ULOGIC_VECTOR( CONV_SIGNED(L, length) ),
		STD_ULOGIC_VECTOR( CONV_SIGNED(R, length) ) );
    end;


    function "/="(L: UNSIGNED; R: INTEGER) return BOOLEAN is
	-- pragma label_applies_to neq
	constant length: INTEGER := L'length + 1;
    begin
	return bitwise_neq( STD_ULOGIC_VECTOR( CONV_SIGNED(L, length) ),
		STD_ULOGIC_VECTOR( CONV_SIGNED(R, length) ) );
    end;


    function "/="(L: INTEGER; R: UNSIGNED) return BOOLEAN is
	-- pragma label_applies_to neq
	constant length: INTEGER := R'length + 1;
    begin
	return bitwise_neq( STD_ULOGIC_VECTOR( CONV_SIGNED(L, length) ),
		STD_ULOGIC_VECTOR( CONV_SIGNED(R, length) ) );
    end;


    function "/="(L: SIGNED; R: INTEGER) return BOOLEAN is
	-- pragma label_applies_to neq
	constant length: INTEGER := L'length;
    begin
	return bitwise_neq( STD_ULOGIC_VECTOR( CONV_SIGNED(L, length) ),
		STD_ULOGIC_VECTOR( CONV_SIGNED(R, length) ) );
    end;


    function "/="(L: INTEGER; R: SIGNED) return BOOLEAN is
	-- pragma label_applies_to neq
	constant length: INTEGER := R'length;
    begin
	return bitwise_neq( STD_ULOGIC_VECTOR( CONV_SIGNED(L, length) ),
		STD_ULOGIC_VECTOR( CONV_SIGNED(R, length) ) );
    end;

-- this is the Xilinx customized 'SHL(A,B: UNSIGNED) return UNSIGNED' version
-- I assume the deviation from standard version was to workaround legacy parser
-- issues. Using the Xilinx one, verific one commented out below. -muggli

    function SHL(ARG: UNSIGNED; COUNT: UNSIGNED) return UNSIGNED is
      -- synopsys subpgm_id 358
      variable shiftval: integer;
      constant result_msb: INTEGER := ARG'length-1;
      variable result: UNSIGNED (result_msb downto 0);
      alias aarg: unsigned(result_msb downto 0) is arg;
    begin
      -- synopsys synthesis_off
      if has_x(count) then
        result := (others => 'X');
        return result;
      end if;
      -- synopsys synthesis_on
      shiftval:=conv_integer(count);
      result := (others => '0');
      if shiftval <= result_msb then
        result(result_msb downto shiftval) := 
          aarg(result_msb - shiftval downto 0);
      end if;
      return result;
    end;

    

    --Function SHL(ARG: UNSIGNED; COUNT: UNSIGNED) return UNSIGNED is
	---- pragma label_applies_to shl
	--constant control_msb: INTEGER := COUNT'length - 1;
	--variable control: UNSIGNED (control_msb downto 0);
	--constant result_msb: INTEGER := ARG'length-1;
	--subtype rtype is UNSIGNED (result_msb downto 0);
	--variable result, temp: rtype;

    --    -- Exemplar Synthesis Directive Attributes 
    --    attribute SYNTHESIS_RETURN of result:variable is "SLL" ;
    --begin
	--control := MAKE_BINARY(COUNT);
	--if (control(0) = 'X') then
	--    result := rtype'(others => 'X');
	--    return result;
	--end if;
	--result := ARG;
	--for i in 0 to control_msb loop
	--    if control(i) = '1' then
	--	temp := rtype'(others => '0');
	--	if 2**i <= result_msb then
	--	    temp(result_msb downto 2**i) := 
	--			    result(result_msb - 2**i downto 0);
	--	end if;
	--	result := temp;
	--    end if;
	--end loop;
	--return result;
    --end;

    function SHL(ARG: SIGNED; COUNT: UNSIGNED) return SIGNED is
	-- pragma label_applies_to shl
	constant control_msb: INTEGER := COUNT'length - 1;
	variable control: UNSIGNED (control_msb downto 0);
	constant result_msb: INTEGER := ARG'length-1;
	subtype rtype is SIGNED (result_msb downto 0);
	variable result, temp: rtype;

        -- Exemplar Synthesis Directive Attributes 
        attribute SYNTHESIS_RETURN of result:variable is "SLL" ;
    begin
	control := MAKE_BINARY(COUNT);
	if (control(0) = 'X') then
	    result := rtype'(others => 'X');
	    return result;
	end if;
	result := ARG;
	for i in 0 to control_msb loop
	    if control(i) = '1' then
		temp := rtype'(others => '0');
		if 2**i <= result_msb then
		    temp(result_msb downto 2**i) := 
				    result(result_msb - 2**i downto 0);
		end if;
		result := temp;
	    end if;
	end loop;
	return result;
    end;


    function SHR(ARG: UNSIGNED; COUNT: UNSIGNED) return UNSIGNED is
	-- pragma label_applies_to shr
	constant control_msb: INTEGER := COUNT'length - 1;
	variable control: UNSIGNED (control_msb downto 0);
	constant result_msb: INTEGER := ARG'length-1;
	subtype rtype is UNSIGNED (result_msb downto 0);
	variable result, temp: rtype;

        -- Exemplar Synthesis Directive Attributes 
        attribute SYNTHESIS_RETURN of result:variable is "SRL" ;
    begin
	control := MAKE_BINARY(COUNT);
	if (control(0) = 'X') then
	    result := rtype'(others => 'X');
	    return result;
	end if;
	result := ARG;
	for i in 0 to control_msb loop
	    if control(i) = '1' then
		temp := rtype'(others => '0');
		if 2**i <= result_msb then
		    temp(result_msb - 2**i downto 0) := 
					result(result_msb downto 2**i);
		end if;
		result := temp;
	    end if;
	end loop;
	return result;
    end;

    function SHR(ARG: SIGNED; COUNT: UNSIGNED) return SIGNED is
	-- pragma label_applies_to shr
      
	constant control_msb: INTEGER := COUNT'length - 1;
	variable control: UNSIGNED (control_msb downto 0);
	constant result_msb: INTEGER := ARG'length-1;
	subtype rtype is SIGNED (result_msb downto 0);
	variable result, temp: rtype;
	variable sign_bit: STD_ULOGIC;
        -- Exemplar Synthesis Directive Attributes 
        attribute SYNTHESIS_RETURN of result:variable is "SRA" ;
    begin
	control := MAKE_BINARY(COUNT);
	if (control(0) = 'X') then
	    result := rtype'(others => 'X');
	    return result;
	end if;
	result := ARG;
	sign_bit := ARG(ARG'left);
	for i in 0 to control_msb loop
	    if control(i) = '1' then
		temp := rtype'(others => sign_bit);
		if 2**i <= result_msb then
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

-- this is the Xilinx customized 'CONV_INTEGER(ARG: UNSIGNED) return UNSIGNED' version
-- I assume the deviation from standard version was to workaround legacy parser
-- issues. Using the Xilinx one, verific one commented out below. -muggli

    function CONV_INTEGER(ARG: UNSIGNED) return INTEGER is
      variable result: INTEGER;
      variable tmp: STD_ULOGIC;
      -- synopsys built_in SYN_UNSIGNED_TO_INTEGER
      -- synopsys subpgm_id 366
    begin
      -- synopsys synthesis_off
      assert ARG'length <= 31
                           report "ARG is too large in CONV_INTEGER"
                           severity FAILURE;
      result := 0;
      for i in ARG'range loop
        result := result * 2;
        tmp := tbl_BINARY(ARG(i));
        if tmp = '1' then
          result := result + 1;
        elsif tmp = 'X' then
          assert false 
            report "There is an 'U'|'X'|'W'|'Z'|'-' in an arithmetic operand, the result will be 'X'(es)."
            severity warning;
          assert false
            report "CONV_INTEGER: There is an 'U'|'X'|'W'|'Z'|'-' in an arithmetic operand, and it has been converted to 0."
            severity WARNING;
          return 0;
        end if;
      end loop;
      return result;
      -- synopsys synthesis_on
    end;
    
    --function CONV_INTEGER(ARG: UNSIGNED) return INTEGER is
	--variable result: INTEGER;
	--variable tmp: STD_ULOGIC;
	---- synopsys built_in SYN_UNSIGNED_TO_INTEGER
    --    -- Exemplar synthesis directive :
    --    attribute SYNTHESIS_RETURN of result:variable is "FEED_THROUGH" ;
    --begin
	---- synopsys synthesis_off
	--assert ARG'length <= 31
	--    report "ARG is too large in CONV_INTEGER"
	--    severity FAILURE;
	--result := 0;
	--for i in ARG'range loop
	--    result := result * 2;
	--    tmp := tbl_BINARY(ARG(i));
	--    if tmp = '1' then
	--	result := result + 1;
	--    elsif tmp = 'X' then
	--	assert false
	--	report "CONV_INTEGER: There is an 'U'|'X'|'W'|'Z'|'-' in an arithmetic operand, and it has been converted to 0."
	--	severity WARNING;
	--    end if;
	--end loop;
	--return result;
	---- synopsys synthesis_on
    --end;

-- this is the Xilinx customized 'CONV_INTEGER(ARG: SIGNED) return UNSIGNED' version
-- I assume the deviation from standard version was to workaround legacy parser
-- issues. Using the Xilinx one, verific one commented out below. -muggli

    function CONV_INTEGER(ARG: SIGNED) return INTEGER is
      variable result: INTEGER;
      variable tmp: STD_ULOGIC;
      -- synopsys built_in SYN_SIGNED_TO_INTEGER
      -- synopsys subpgm_id 367
    begin
      -- synopsys synthesis_off
      assert ARG'length <= 32
                           report "ARG is too large in CONV_INTEGER"
                           severity FAILURE;
      result := 0;
      for i in ARG'range loop
        if i /= ARG'left then
          result := result * 2;
	        tmp := tbl_BINARY(ARG(i));
	        if tmp = '1' then
            result := result + 1;
	        elsif tmp = 'X' then
            assert false 
              report "There is an 'U'|'X'|'W'|'Z'|'-' in an arithmetic operand, the result will be 'X'(es)."
              severity warning;
            assert false
              report "CONV_INTEGER: There is an 'U'|'X'|'W'|'Z'|'-' in an arithmetic operand, and it has been converted to 0."
              severity WARNING;
            return 0;
	        end if;
        end if;
      end loop;
      tmp := MAKE_BINARY(ARG(ARG'left));
      if tmp = '1' then
        if ARG'length = 32 then
          result := (result - 2**30) - 2**30;
        else
          result := result - (2 ** (ARG'length-1));
        end if;
      end if;
      return result;
      -- synopsys synthesis_on
    end;


    
    --function CONV_INTEGER(ARG: SIGNED) return INTEGER is
	--variable result: INTEGER;
	--variable tmp: STD_ULOGIC;
	---- synopsys built_in SYN_SIGNED_TO_INTEGER
    --    -- Exemplar synthesis directives :
    --    attribute IS_SIGNED of ARG:constant is TRUE ;
    --    attribute SYNTHESIS_RETURN of result:variable is "FEED_THROUGH" ;
    --begin
	---- synopsys synthesis_off
	--assert ARG'length <= 32
	--    report "ARG is too large in CONV_INTEGER"
	--    severity FAILURE;
	--result := 0;
	--for i in ARG'range loop
	--    if i /= ARG'left then
	--	result := result * 2;
	--        tmp := tbl_BINARY(ARG(i));
	--        if tmp = '1' then
	--	    result := result + 1;
	--        elsif tmp = 'X' then
	--	    assert false
	--	    report "CONV_INTEGER: There is an 'U'|'X'|'W'|'Z'|'-' in an arithmetic operand, and it has been converted to 0."
	--	    severity WARNING;
	--        end if;
	--    end if;
	--end loop;
	--tmp := MAKE_BINARY(ARG(ARG'left));
	--if tmp = '1' then
	--    if ARG'length = 32 then
	--	result := (result - 2**30) - 2**30;
	--    else
	--	result := result - (2 ** (ARG'length-1));
	--    end if;
	--end if;
	--return result;
	---- synopsys synthesis_on
    --end;


    function CONV_INTEGER(ARG: STD_ULOGIC) return SMALL_INT is
	variable tmp: STD_ULOGIC;
	-- synopsys built_in SYN_FEED_THRU
        -- Exemplar synthesis directives :
        variable result : SMALL_INT ;
        attribute SYNTHESIS_RETURN of result:variable is "FEED_THROUGH" ;
    begin
	-- synopsys synthesis_off
	tmp := tbl_BINARY(ARG);
	if tmp = '1' then
	    result := 1;
	elsif tmp = 'X' then
	    assert false
	    report "CONV_INTEGER: There is an 'U'|'X'|'W'|'Z'|'-' in an arithmetic operand, and it has been converted to 0."
	    severity WARNING;
	    result := 0;
	else
	    result := 0;
	end if;
        return result ;
	-- synopsys synthesis_on
    end;


    -- convert an integer to a unsigned STD_ULOGIC_VECTOR
    function CONV_UNSIGNED(ARG: INTEGER; SIZE: INTEGER) return UNSIGNED is
	variable result: UNSIGNED(SIZE-1 downto 0);
	variable temp: integer;
	-- synopsys built_in SYN_INTEGER_TO_UNSIGNED
        --  Exemplar synthesis directives :
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

-- this is the Xilinx customized '' version
-- I assume the deviation from standard version was to workaround legacy parser
-- issues. Using the Xilinx one, verific one commented out below. -muggli
    function CONV_UNSIGNED(ARG: UNSIGNED; SIZE: INTEGER) return UNSIGNED is
      variable msb: INTEGER := SIZE - 1;
      constant rMsb: INTEGER := SIZE -1;
      variable result: UNSIGNED (rMsb downto 0);
      alias argDownto : UNSIGNED(ARG'length-1 downto 0) is arg;
      -- synopsys built_in SYN_ZERO_EXTEND
      -- synopsys subpgm_id 372
    begin
      -- synopsys synthesis_off
      if ARG'length = SIZE then
        -- can't just return arg.  Part of the job of this function is to 
        -- ensure that the index constraints are msb downto 0.
        result:=arg;
      elsif ARG'length > SIZE then
        result := argDownto(size-1 downto 0);
      else
        result(arg'length-1 downto 0) := arg;
        result(size-1 downto arg'length):=(others=>'0');
        msb:=arg'length-1;
      end if;
      for j in msb downto 0 loop
        case result(j) is
          when 'U'|'X'|'W'|'Z'|'-' =>
            assert false 
              report "There is an 'U'|'X'|'W'|'Z'|'-' in an arithmetic operand, the result will be 'X'(es)."
              severity warning;
            result := (others => 'X');
            return result;
          when 'L' =>
            result(j):='0';
          when 'H' =>
            result(j):='1';
          when '0' | '1' =>
            null;
        end case;
      end loop;
      return result;
      -- synopsys synthesis_on
    end;


    
    --function CONV_UNSIGNED(ARG: UNSIGNED; SIZE: INTEGER) return UNSIGNED is
	--constant msb: INTEGER := min(ARG'length, SIZE) - 1;
	--subtype rtype is UNSIGNED (SIZE-1 downto 0);
	--variable new_bounds: UNSIGNED (ARG'length-1 downto 0);
	--variable result: rtype;
	---- synopsys built_in SYN_ZERO_EXTEND
    --    --  Exemplar synthesis directives :
    --    attribute SYNTHESIS_RETURN of result:variable is "FEED_THROUGH" ;
    --begin
	---- synopsys synthesis_off
	--new_bounds := MAKE_BINARY(ARG);
	--if (new_bounds(0) = 'X') then
	--    result := rtype'(others => 'X');
	--    return result;
	--end if;
	--result := rtype'(others => '0');
	--result(msb downto 0) := new_bounds(msb downto 0);
	--return result;
	---- synopsys synthesis_on
    --end;


    function CONV_UNSIGNED(ARG: SIGNED; SIZE: INTEGER) return UNSIGNED is
	constant msb: INTEGER := min(ARG'length, SIZE) - 1;
	subtype rtype is UNSIGNED (SIZE-1 downto 0);
	variable new_bounds: UNSIGNED (ARG'length-1 downto 0);
	variable result: rtype;
	-- synopsys built_in SYN_SIGN_EXTEND
        --  Exemplar synthesis directives :
        attribute IS_SIGNED of ARG:constant is TRUE ;
        attribute SYNTHESIS_RETURN of result:variable is "FEED_THROUGH" ;
    begin
	-- synopsys synthesis_off
	new_bounds := MAKE_BINARY(ARG);
	if (new_bounds(0) = 'X') then
	    result := rtype'(others => 'X');
	    return result;
	end if;
	result := rtype'(others => new_bounds(new_bounds'left));
	result(msb downto 0) := new_bounds(msb downto 0);
	return result;
	-- synopsys synthesis_on
    end;


    function CONV_UNSIGNED(ARG: STD_ULOGIC; SIZE: INTEGER) return UNSIGNED is
	subtype rtype is UNSIGNED (SIZE-1 downto 0);
	variable result: rtype;
	-- synopsys built_in SYN_ZERO_EXTEND
        --  Exemplar synthesis directives :
        attribute SYNTHESIS_RETURN of result:variable is "FEED_THROUGH" ;
    begin
	-- synopsys synthesis_off
	result := rtype'(others => '0');
	result(0) := MAKE_BINARY(ARG);
	if (result(0) = 'X') then
	    result := rtype'(others => 'X');
	end if;
	return result;
	-- synopsys synthesis_on
    end;


    -- convert an integer to a 2's complement STD_ULOGIC_VECTOR
    function CONV_SIGNED(ARG: INTEGER; SIZE: INTEGER) return SIGNED is
	variable result: SIGNED (SIZE-1 downto 0);
	variable temp: integer;
	-- synopsys built_in SYN_INTEGER_TO_SIGNED
        --  Exemplar synthesis directives :
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
        --  Exemplar synthesis directives :
        attribute SYNTHESIS_RETURN of result:variable is "FEED_THROUGH" ;
    begin
	-- synopsys synthesis_off
	new_bounds := MAKE_BINARY(ARG);
	if (new_bounds(0) = 'X') then
	    result := rtype'(others => 'X');
	    return result;
	end if;
	result := rtype'(others => '0');
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
        --  Exemplar synthesis directives :
        attribute IS_SIGNED of ARG:constant is TRUE ;
        attribute SYNTHESIS_RETURN of result:variable is "FEED_THROUGH" ;
    begin
	-- synopsys synthesis_off
	new_bounds := MAKE_BINARY(ARG);
	if (new_bounds(0) = 'X') then
	    result := rtype'(others => 'X');
	    return result;
	end if;
	result := rtype'(others => new_bounds(new_bounds'left));
	result(msb downto 0) := new_bounds(msb downto 0);
	return result;
	-- synopsys synthesis_on
    end;


    function CONV_SIGNED(ARG: STD_ULOGIC; SIZE: INTEGER) return SIGNED is
	subtype rtype is SIGNED (SIZE-1 downto 0);
	variable result: rtype;
	-- synopsys built_in SYN_ZERO_EXTEND
        --  Exemplar synthesis directives :
        attribute SYNTHESIS_RETURN of result:variable is "FEED_THROUGH" ;
    begin
	-- synopsys synthesis_off
	result := rtype'(others => '0');
	result(0) := MAKE_BINARY(ARG);
	if (result(0) = 'X') then
	    result := rtype'(others => 'X');
	end if;
	return result;
	-- synopsys synthesis_on
    end;


    -- convert an integer to an STD_LOGIC_VECTOR
    function CONV_STD_LOGIC_VECTOR(ARG: INTEGER; SIZE: INTEGER) return STD_LOGIC_VECTOR is
	variable result: STD_LOGIC_VECTOR (SIZE-1 downto 0);
	variable temp: integer;
	-- synopsys built_in SYN_INTEGER_TO_SIGNED
        --  Exemplar synthesis directives :
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


    function CONV_STD_LOGIC_VECTOR(ARG: UNSIGNED; SIZE: INTEGER) return STD_LOGIC_VECTOR is
	constant msb: INTEGER := min(ARG'length, SIZE) - 1;
	subtype rtype is STD_LOGIC_VECTOR (SIZE-1 downto 0);
	variable new_bounds : STD_LOGIC_VECTOR (ARG'length-1 downto 0);
	variable result: rtype;
	-- synopsys built_in SYN_ZERO_EXTEND
        --  Exemplar synthesis directives :
        attribute SYNTHESIS_RETURN of result:variable is "FEED_THROUGH" ;
    begin
	-- synopsys synthesis_off
	new_bounds := MAKE_BINARY(ARG);
	if (new_bounds(0) = 'X') then
	    result := rtype'(others => 'X');
	    return result;
	end if;
	result := rtype'(others => '0');
	result(msb downto 0) := new_bounds(msb downto 0);
	return result;
	-- synopsys synthesis_on
    end;

    function CONV_STD_LOGIC_VECTOR(ARG: SIGNED; SIZE: INTEGER) return STD_LOGIC_VECTOR is
	constant msb: INTEGER := min(ARG'length, SIZE) - 1;
	subtype rtype is STD_LOGIC_VECTOR (SIZE-1 downto 0);
	variable new_bounds : STD_LOGIC_VECTOR (ARG'length-1 downto 0);
	variable result: rtype;
	-- synopsys built_in SYN_SIGN_EXTEND
        --  Exemplar synthesis directives :
        attribute IS_SIGNED of ARG:constant is TRUE ;
        attribute SYNTHESIS_RETURN of result:variable is "FEED_THROUGH" ;
    begin
	-- synopsys synthesis_off
	new_bounds := MAKE_BINARY(ARG);
	if (new_bounds(0) = 'X') then
	    result := rtype'(others => 'X');
	    return result;
	end if;
	result := rtype'(others => new_bounds(new_bounds'left));
	result(msb downto 0) := new_bounds(msb downto 0);
	return result;
	-- synopsys synthesis_on
    end;


    function CONV_STD_LOGIC_VECTOR(ARG: STD_ULOGIC; SIZE: INTEGER) return STD_LOGIC_VECTOR is
	subtype rtype is STD_LOGIC_VECTOR (SIZE-1 downto 0);
	variable result: rtype;
	-- synopsys built_in SYN_ZERO_EXTEND
        --  Exemplar synthesis directives :
        attribute SYNTHESIS_RETURN of result:variable is "FEED_THROUGH" ;
    begin
	-- synopsys synthesis_off
	result := rtype'(others => '0');
	result(0) := MAKE_BINARY(ARG);
	if (result(0) = 'X') then
	    result := rtype'(others => 'X');
	end if;
	return result;
	-- synopsys synthesis_on
    end;

    function EXT(ARG: STD_LOGIC_VECTOR; SIZE: INTEGER) 
						return STD_LOGIC_VECTOR is
	constant msb: INTEGER := min(ARG'length, SIZE) - 1;
	subtype rtype is STD_LOGIC_VECTOR (SIZE-1 downto 0);
	variable new_bounds: STD_LOGIC_VECTOR (ARG'length-1 downto 0);
	variable result: rtype;
	-- synopsys built_in SYN_ZERO_EXTEND
        --  Exemplar synthesis directives :
        attribute SYNTHESIS_RETURN of result:variable is "FEED_THROUGH" ;
    begin
	-- synopsys synthesis_off
	new_bounds := MAKE_BINARY(ARG);
	if (new_bounds(0) = 'X') then
	    result := rtype'(others => 'X');
	    return result;
	end if;
	result := rtype'(others => '0');
	result(msb downto 0) := new_bounds(msb downto 0);
	return result;
	-- synopsys synthesis_on
    end;


    function SXT(ARG: STD_LOGIC_VECTOR; SIZE: INTEGER) return STD_LOGIC_VECTOR is
	constant msb: INTEGER := min(ARG'length, SIZE) - 1;
	subtype rtype is STD_LOGIC_VECTOR (SIZE-1 downto 0);
	variable new_bounds : STD_LOGIC_VECTOR (ARG'length-1 downto 0);
	variable result: rtype;
	-- synopsys built_in SYN_SIGN_EXTEND
        --  Exemplar synthesis directives :
        attribute IS_SIGNED of ARG:constant is TRUE ;
        attribute SYNTHESIS_RETURN of result:variable is "FEED_THROUGH" ;
    begin
	-- synopsys synthesis_off
	new_bounds := MAKE_BINARY(ARG);
	if (new_bounds(0) = 'X') then
	    result := rtype'(others => 'X');
	    return result;
	end if;
	result := rtype'(others => new_bounds(new_bounds'left));
	result(msb downto 0) := new_bounds(msb downto 0);
	return result;
	-- synopsys synthesis_on
    end;


end std_logic_arith;
