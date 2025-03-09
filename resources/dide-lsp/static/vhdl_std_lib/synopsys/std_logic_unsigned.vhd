--------------------------------------------------------------------------
--                                                                      --
-- Copyright (c) 1990, 1991, 1992 by Synopsys, Inc.                     --
--                                             All rights reserved.     --
--                                                                      --
-- This source file may be used and distributed without restriction     --
-- provided that this copyright statement is not removed from the file  --
-- and that any derivative work contains this copyright notice.         --
--                                                                      --
--	Package name: STD_LOGIC_UNSIGNED                                --
--                                 					--
--									--
--      Date:        	09/11/92	KN				--
--			10/08/92 	AMT				--
--									--
--	Purpose: 							--
--	 A set of unsigned arithemtic, conversion,                      --
--           and comparision functions for STD_LOGIC_VECTOR.            --
--									--
--	Note:  comparision of same length discrete arrays is defined	--
--		by the LRM.  This package will "overload" those 	--
--		definitions						--
--									--
--------------------------------------------------------------------------
-- Modifications :
-- Attributes added for Xilinx specific optimizations
--------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;

package STD_LOGIC_UNSIGNED is

    function "+"(L: STD_LOGIC_VECTOR; R: STD_LOGIC_VECTOR) return STD_LOGIC_VECTOR;
    function "+"(L: STD_LOGIC_VECTOR; R: INTEGER) return STD_LOGIC_VECTOR;
    function "+"(L: INTEGER; R: STD_LOGIC_VECTOR) return STD_LOGIC_VECTOR;
    function "+"(L: STD_LOGIC_VECTOR; R: STD_LOGIC) return STD_LOGIC_VECTOR;
    function "+"(L: STD_LOGIC; R: STD_LOGIC_VECTOR) return STD_LOGIC_VECTOR;

    function "-"(L: STD_LOGIC_VECTOR; R: STD_LOGIC_VECTOR) return STD_LOGIC_VECTOR;
    function "-"(L: STD_LOGIC_VECTOR; R: INTEGER) return STD_LOGIC_VECTOR;
    function "-"(L: INTEGER; R: STD_LOGIC_VECTOR) return STD_LOGIC_VECTOR;
    function "-"(L: STD_LOGIC_VECTOR; R: STD_LOGIC) return STD_LOGIC_VECTOR;
    function "-"(L: STD_LOGIC; R: STD_LOGIC_VECTOR) return STD_LOGIC_VECTOR;

    function "+"(L: STD_LOGIC_VECTOR) return STD_LOGIC_VECTOR;

    function "*"(L: STD_LOGIC_VECTOR; R: STD_LOGIC_VECTOR) return STD_LOGIC_VECTOR;

    function "<"(L: STD_LOGIC_VECTOR; R: STD_LOGIC_VECTOR) return BOOLEAN;
    function "<"(L: STD_LOGIC_VECTOR; R: INTEGER) return BOOLEAN;
    function "<"(L: INTEGER; R: STD_LOGIC_VECTOR) return BOOLEAN;

    function "<="(L: STD_LOGIC_VECTOR; R: STD_LOGIC_VECTOR) return BOOLEAN;
    function "<="(L: STD_LOGIC_VECTOR; R: INTEGER) return BOOLEAN;
    function "<="(L: INTEGER; R: STD_LOGIC_VECTOR) return BOOLEAN;

    function ">"(L: STD_LOGIC_VECTOR; R: STD_LOGIC_VECTOR) return BOOLEAN;
    function ">"(L: STD_LOGIC_VECTOR; R: INTEGER) return BOOLEAN;
    function ">"(L: INTEGER; R: STD_LOGIC_VECTOR) return BOOLEAN;

    function ">="(L: STD_LOGIC_VECTOR; R: STD_LOGIC_VECTOR) return BOOLEAN;
    function ">="(L: STD_LOGIC_VECTOR; R: INTEGER) return BOOLEAN;
    function ">="(L: INTEGER; R: STD_LOGIC_VECTOR) return BOOLEAN;

    function "="(L: STD_LOGIC_VECTOR; R: STD_LOGIC_VECTOR) return BOOLEAN;
    function "="(L: STD_LOGIC_VECTOR; R: INTEGER) return BOOLEAN;
    function "="(L: INTEGER; R: STD_LOGIC_VECTOR) return BOOLEAN;

    function "/="(L: STD_LOGIC_VECTOR; R: STD_LOGIC_VECTOR) return BOOLEAN;
    function "/="(L: STD_LOGIC_VECTOR; R: INTEGER) return BOOLEAN;
    function "/="(L: INTEGER; R: STD_LOGIC_VECTOR) return BOOLEAN;
    function SHL(ARG:STD_LOGIC_VECTOR;COUNT: STD_LOGIC_VECTOR) return STD_LOGIC_VECTOR;
    function SHR(ARG:STD_LOGIC_VECTOR;COUNT: STD_LOGIC_VECTOR) return STD_LOGIC_VECTOR;

    function CONV_INTEGER(ARG: STD_LOGIC_VECTOR) return INTEGER;

    --attribute foreign of ">"[STD_LOGIC_VECTOR, STD_LOGIC_VECTOR return BOOLEAN]:function is "ieee_std_logic_unsigned_greater_stdv_stdv"; 

    --attribute foreign of "="[STD_LOGIC_VECTOR, STD_LOGIC_VECTOR return BOOLEAN]:function is "ieee_std_logic_unsigned_equal_stdv_stdv";

    attribute foreign of "+"[STD_LOGIC_VECTOR, STD_LOGIC_VECTOR return STD_LOGIC_VECTOR]:function is "std_logic_arith_unsigned_unsigned_plus";
    attribute foreign of "+"[STD_LOGIC_VECTOR, INTEGER return STD_LOGIC_VECTOR]:function is "std_logic_arith_unsigned_integer_plus";
    attribute foreign of "+"[INTEGER, STD_LOGIC_VECTOR return STD_LOGIC_VECTOR]:function is "std_logic_arith_integer_unsigned_plus";
    attribute foreign of "+"[STD_LOGIC_VECTOR, std_logic return STD_LOGIC_VECTOR]:function is "std_logic_arith_unsigned_ulogic_plus";
    attribute foreign of "+"[std_logic, STD_LOGIC_VECTOR return STD_LOGIC_VECTOR]:function is "std_logic_arith_ulogic_unsigned_plus";

    attribute foreign of "-"[STD_LOGIC_VECTOR, STD_LOGIC_VECTOR return STD_LOGIC_VECTOR]:function is "std_logic_arith_unsigned_unsigned_minus";
    attribute foreign of "-"[STD_LOGIC_VECTOR, INTEGER return STD_LOGIC_VECTOR]:function is "std_logic_arith_unsigned_integer_minus";
    attribute foreign of "-"[INTEGER, STD_LOGIC_VECTOR return STD_LOGIC_VECTOR]:function is "std_logic_arith_integer_unsigned_minus";
    attribute foreign of "-"[STD_LOGIC_VECTOR, std_logic return STD_LOGIC_VECTOR]:function is "std_logic_arith_unsigned_ulogic_minus";
    attribute foreign of "-"[std_logic, STD_LOGIC_VECTOR return STD_LOGIC_VECTOR]:function is "std_logic_arith_ulogic_unsigned_minus";

    attribute foreign of "+"[STD_LOGIC_VECTOR return STD_LOGIC_VECTOR]:function is "std_logic_arith_unary_plus";

    attribute foreign of "*"[STD_LOGIC_VECTOR, STD_LOGIC_VECTOR return STD_LOGIC_VECTOR]:function is "std_logic_arith_unsigned_unsigned_mult";

    attribute foreign of "<"[STD_LOGIC_VECTOR, STD_LOGIC_VECTOR return BOOLEAN]:function is "std_logic_arith_unsigned_unsigned_is_less"; 
    attribute foreign of "<"[STD_LOGIC_VECTOR, integer return BOOLEAN]:function is "std_logic_arith_unsigned_integer_is_less";
    attribute foreign of "<"[integer, STD_LOGIC_VECTOR return BOOLEAN]:function is "std_logic_arith_integer_unsigned_is_less";

    attribute foreign of "<="[STD_LOGIC_VECTOR, STD_LOGIC_VECTOR return BOOLEAN]:function is "std_logic_arith_unsigned_unsigned_is_less_or_equal"; 
    attribute foreign of "<="[STD_LOGIC_VECTOR, integer return BOOLEAN]:function is "std_logic_arith_unsigned_integer_is_less_or_equal";
    attribute foreign of "<="[integer, STD_LOGIC_VECTOR return BOOLEAN]:function is "std_logic_arith_integer_unsigned_is_less_or_equal";

    attribute foreign of ">"[STD_LOGIC_VECTOR, STD_LOGIC_VECTOR return BOOLEAN]:function is "std_logic_arith_unsigned_unsigned_is_greater"; 
    attribute foreign of ">"[STD_LOGIC_VECTOR, integer return BOOLEAN]:function is "std_logic_arith_unsigned_integer_is_greater";
    attribute foreign of ">"[integer, STD_LOGIC_VECTOR return BOOLEAN]:function is "std_logic_arith_integer_unsigned_is_greater";

    attribute foreign of ">="[STD_LOGIC_VECTOR, STD_LOGIC_VECTOR return BOOLEAN]:function is "std_logic_arith_unsigned_unsigned_is_greater_or_equal"; 
    attribute foreign of ">="[STD_LOGIC_VECTOR, integer return BOOLEAN]:function is "std_logic_arith_unsigned_integer_is_greater_or_equal";
    attribute foreign of ">="[integer, STD_LOGIC_VECTOR return BOOLEAN]:function is "std_logic_arith_integer_unsigned_is_greater_or_equal";


    attribute foreign of "="[STD_LOGIC_VECTOR, STD_LOGIC_VECTOR return BOOLEAN]:function is "std_logic_arith_unsigned_unsigned_is_equal"; 
    attribute foreign of "="[STD_LOGIC_VECTOR, integer return BOOLEAN]:function is "std_logic_arith_unsigned_integer_is_equal";
    attribute foreign of "="[integer, STD_LOGIC_VECTOR return BOOLEAN]:function is "std_logic_arith_integer_unsigned_is_equal";

    attribute foreign of "/="[STD_LOGIC_VECTOR, STD_LOGIC_VECTOR return BOOLEAN]:function is "std_logic_arith_unsigned_unsigned_is_not_equal"; 
    attribute foreign of "/="[STD_LOGIC_VECTOR, integer return BOOLEAN]:function is "std_logic_arith_unsigned_integer_is_not_equal";
    attribute foreign of "/="[integer, STD_LOGIC_VECTOR return BOOLEAN]:function is "std_logic_arith_integer_unsigned_is_not_equal";

    attribute foreign of conv_integer[STD_LOGIC_VECTOR return integer]:function is "std_logic_arith_conv_unsigned_to_integer";

    attribute foreign of SHL[std_logic_vector, std_logic_vector return std_logic_vector]:function is "std_logic_arith_unsigned_shl";
    attribute foreign of SHR[std_logic_vector, std_logic_vector return std_logic_vector]:function is "std_logic_arith_unsigned_shr";
                                                                                            
-- remove this since it is already in std_logic_arith
--    function CONV_STD_LOGIC_VECTOR(ARG: INTEGER; SIZE: INTEGER) return STD_LOGIC_VECTOR;

end STD_LOGIC_UNSIGNED;



library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;

package body STD_LOGIC_UNSIGNED is


    function maximum(L, R: INTEGER) return INTEGER is
    begin
        if L > R then
            return L;
        else
            return R;
        end if;
    end;


    function "+"(L: STD_LOGIC_VECTOR; R: STD_LOGIC_VECTOR) return STD_LOGIC_VECTOR is
        -- pragma label_applies_to plus
        constant length: INTEGER := maximum(L'length, R'length);
        variable result  : STD_LOGIC_VECTOR (length-1 downto 0);
    begin
        result  := UNSIGNED(L) + UNSIGNED(R);-- pragma label plus
        return   std_logic_vector(result);
    end;

    function "+"(L: STD_LOGIC_VECTOR; R: INTEGER) return STD_LOGIC_VECTOR is
        -- pragma label_applies_to plus
        variable result  : STD_LOGIC_VECTOR (L'range);
    begin
        result  := UNSIGNED(L) + R;-- pragma label plus
        return   std_logic_vector(result);
    end;

    function "+"(L: INTEGER; R: STD_LOGIC_VECTOR) return STD_LOGIC_VECTOR is
        -- pragma label_applies_to plus
        variable result  : STD_LOGIC_VECTOR (R'range);
    begin
        result  := L + UNSIGNED(R);-- pragma label plus
        return   std_logic_vector(result);
    end;

    function "+"(L: STD_LOGIC_VECTOR; R: STD_LOGIC) return STD_LOGIC_VECTOR is
        -- pragma label_applies_to plus
        variable result  : STD_LOGIC_VECTOR (L'range);
    begin
        result  := UNSIGNED(L) + R;-- pragma label plus
        return   std_logic_vector(result);
    end;

    function "+"(L: STD_LOGIC; R: STD_LOGIC_VECTOR) return STD_LOGIC_VECTOR is
            -- pragma label_applies_to plus
    variable result  : STD_LOGIC_VECTOR (R'range);
    begin
        result  := L + UNSIGNED(R);-- pragma label plus
        return   std_logic_vector(result);
    end;

    function "-"(L: STD_LOGIC_VECTOR; R: STD_LOGIC_VECTOR) return STD_LOGIC_VECTOR is
        -- pragma label_applies_to minus
        constant length: INTEGER := maximum(L'length, R'length);
        variable result  : STD_LOGIC_VECTOR (length-1 downto 0);
    begin
        result  := UNSIGNED(L) - UNSIGNED(R); -- pragma label minus
        return   std_logic_vector(result);
    end;

    function "-"(L: STD_LOGIC_VECTOR; R: INTEGER) return STD_LOGIC_VECTOR is
        -- pragma label_applies_to minus
        variable result  : STD_LOGIC_VECTOR (L'range);
    begin
        result  := UNSIGNED(L) - R; -- pragma label minus
        return   std_logic_vector(result);
    end;

    function "-"(L: INTEGER; R: STD_LOGIC_VECTOR) return STD_LOGIC_VECTOR is
        -- pragma label_applies_to minus
        variable result  : STD_LOGIC_VECTOR (R'range);
    begin
        result  := L - UNSIGNED(R);  -- pragma label minus
        return   std_logic_vector(result);
    end;

    function "-"(L: STD_LOGIC_VECTOR; R: STD_LOGIC) return STD_LOGIC_VECTOR is
        variable result  : STD_LOGIC_VECTOR (L'range);
    begin
        result  := UNSIGNED(L) - R;
        return   std_logic_vector(result);
    end;

    function "-"(L: STD_LOGIC; R: STD_LOGIC_VECTOR) return STD_LOGIC_VECTOR is
        -- pragma label_applies_to minus
        variable result  : STD_LOGIC_VECTOR (R'range);
    begin
        result  := L - UNSIGNED(R);  -- pragma label minus
        return   std_logic_vector(result);
    end;

    function "+"(L: STD_LOGIC_VECTOR) return STD_LOGIC_VECTOR is
        variable result  : STD_LOGIC_VECTOR (L'range);
    begin
        result  := + UNSIGNED(L);
        return   std_logic_vector(result);
    end;

    function "*"(L: STD_LOGIC_VECTOR; R: STD_LOGIC_VECTOR) return STD_LOGIC_VECTOR is
        -- pragma label_applies_to mult
        constant length: INTEGER := maximum(L'length, R'length);
        variable result  : STD_LOGIC_VECTOR ((L'length+R'length-1) downto 0);
    begin
        result  := UNSIGNED(L) * UNSIGNED(R); -- pragma label mult
        return   std_logic_vector(result);
    end;
        
    function "<"(L: STD_LOGIC_VECTOR; R: STD_LOGIC_VECTOR) return BOOLEAN is
        -- pragma label_applies_to lt
        constant length: INTEGER := maximum(L'length, R'length);
    begin
        return   UNSIGNED(L) < UNSIGNED(R); -- pragma label lt
    end;

    function "<"(L: STD_LOGIC_VECTOR; R: INTEGER) return BOOLEAN is
        -- pragma label_applies_to lt
    begin
        return   UNSIGNED(L) < R; -- pragma label lt
    end;

    function "<"(L: INTEGER; R: STD_LOGIC_VECTOR) return BOOLEAN is
        -- pragma label_applies_to lt
    begin
        return   L < UNSIGNED(R); -- pragma label lt
    end;

    function "<="(L: STD_LOGIC_VECTOR; R: STD_LOGIC_VECTOR) return BOOLEAN is
       -- pragma label_applies_to leq
    begin
        return   UNSIGNED(L) <= UNSIGNED(R); -- pragma label leq
    end;

    function "<="(L: STD_LOGIC_VECTOR; R: INTEGER) return BOOLEAN is
       -- pragma label_applies_to leq
    begin
        return   UNSIGNED(L) <= R; -- pragma label leq
    end;

    function "<="(L: INTEGER; R: STD_LOGIC_VECTOR) return BOOLEAN is
       -- pragma label_applies_to leq
    begin
        return   L <= UNSIGNED(R); -- pragma label leq
    end;

    function ">"(L: STD_LOGIC_VECTOR; R: STD_LOGIC_VECTOR) return BOOLEAN is
        -- pragma label_applies_to gt
    begin
        return   UNSIGNED(L) > UNSIGNED(R); -- pragma label gt
    end;

    function ">"(L: STD_LOGIC_VECTOR; R: INTEGER) return BOOLEAN is
        -- pragma label_applies_to gt
    begin
        return   UNSIGNED(L) > R; -- pragma label gt
    end;

    function ">"(L: INTEGER; R: STD_LOGIC_VECTOR) return BOOLEAN is
        -- pragma label_applies_to gt
    begin
        return   L > UNSIGNED(R); -- pragma label gt
    end;

    function ">="(L: STD_LOGIC_VECTOR; R: STD_LOGIC_VECTOR) return BOOLEAN is
        -- pragma label_applies_to geq
    begin
        return   UNSIGNED(L) >= UNSIGNED(R);  -- pragma label geq
    end;

    function ">="(L: STD_LOGIC_VECTOR; R: INTEGER) return BOOLEAN is
        -- pragma label_applies_to geq
    begin
        return   UNSIGNED(L) >= R;  -- pragma label geq
    end;

    function ">="(L: INTEGER; R: STD_LOGIC_VECTOR) return BOOLEAN is
        -- pragma label_applies_to geq
    begin
        return   L >= UNSIGNED(R);  -- pragma label geq
    end;

    function "="(L: STD_LOGIC_VECTOR; R: STD_LOGIC_VECTOR) return BOOLEAN is
    begin
        return   UNSIGNED(L) = UNSIGNED(R);
    end;

    function "="(L: STD_LOGIC_VECTOR; R: INTEGER) return BOOLEAN is
    begin
        return   UNSIGNED(L) = R;
    end;

    function "="(L: INTEGER; R: STD_LOGIC_VECTOR) return BOOLEAN is
    begin
        return   L = UNSIGNED(R);
    end;

    function "/="(L: STD_LOGIC_VECTOR; R: STD_LOGIC_VECTOR) return BOOLEAN is
    begin
        return   UNSIGNED(L) /= UNSIGNED(R);
    end;

    function "/="(L: STD_LOGIC_VECTOR; R: INTEGER) return BOOLEAN is
    begin
        return   UNSIGNED(L) /= R;
    end;

    function "/="(L: INTEGER; R: STD_LOGIC_VECTOR) return BOOLEAN is
    begin
        return   L /= UNSIGNED(R);
    end;

    function CONV_INTEGER(ARG: STD_LOGIC_VECTOR) return INTEGER is
        variable result    : UNSIGNED(ARG'range);
    begin
        result    := UNSIGNED(ARG);
        return   CONV_INTEGER(result);
    end;
    function SHL(ARG:STD_LOGIC_VECTOR;COUNT: STD_LOGIC_VECTOR) return STD_LOGIC_VECTOR is
    begin
       return STD_LOGIC_VECTOR(SHL(UNSIGNED(ARG),UNSIGNED(COUNT)));
    end;
 
    function SHR(ARG:STD_LOGIC_VECTOR;COUNT: STD_LOGIC_VECTOR) return STD_LOGIC_VECTOR is
    begin
       return STD_LOGIC_VECTOR(SHR(UNSIGNED(ARG),UNSIGNED(COUNT)));
    end;


-- remove this since it is already in std_logic_arith
    --function CONV_STD_LOGIC_VECTOR(ARG: INTEGER; SIZE: INTEGER) return STD_LOGIC_VECTOR is
        --variable result1 : UNSIGNED (SIZE-1 downto 0);
        --variable result2 : STD_LOGIC_VECTOR (SIZE-1 downto 0);
    --begin
        --result1 := CONV_UNSIGNED(ARG,SIZE);
        --return   std_logic_vector(result1);
    --end;


end STD_LOGIC_UNSIGNED;


