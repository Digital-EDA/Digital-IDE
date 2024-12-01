----------------------------------------------------------------------------
-- 
-- Copyright (c) 1990, 1991, 1992 by Synopsys, Inc.  All rights reserved.
-- 
-- This source file may be used and distributed without restriction 
-- provided that this copyright statement is not removed from the file 
-- and that any derivative work contains this copyright notice.
--
--	Package name: ATTRIBUTES
--
--	Purpose: This package defines the attributes associated with
--		 the Synopsys VHDL System Simulator and the HDL compiler.
--		 The simulator specific attributes  are built into the
--		 the analyzer, so this source should not be analyzed on 
--		 the Synopsys VHDL System Simulator.  It is provided for 
--		 reference and portability to other systems.
--
--	Author: JT, PH, GWH, RV
--
--	Modified. Added translate_off and translate_on pairs because
--	HDL compiler does not use/support the simulator specific attributes 
--	in this package.
--
--      Modified: Apr 30, 1996, PZ: Moved the three BC attributes
--                (dont_unroll, variables, synthesis_type) to this package.
--      Modified: Nov 25, 1996, PZ: Removed the three BC attributes
--                (dont_unroll, variables, synthesis_type) from this package.
--                They are now in the behavioral package again.
--
----------------------------------------------------------------------------
-- Simulator specific attributes
-----------------------------------------------------------------------
--
--  attributes for type conversion functions, SDF backannotation and 
--  resolution functions
--
-----------------------------------------------------------------------

package ATTRIBUTES is
--synopsys translate_off
	attribute CLOSELY_RELATED_TCF: boolean;
	attribute PROPAGATE_VALUE: string;
	attribute SDT_CONDITION: string;
	attribute SDT_VALUE_NAME: string;
	attribute SDT_VALUE: string;
	attribute REFLEXIVE: boolean;
	attribute COMMUTATIVE: boolean;
	attribute ASSOCIATIVE: boolean;
	attribute RESULT_INITIAL_VALUE: integer;
	attribute TABLE_NAME: string;
	attribute REAL_NAME: string;

	attribute PRIVATE: boolean;
	attribute UNPRIVATE: boolean;
	attribute ASIC_CELL: boolean;
	attribute DIVERT_MESSAGES: boolean;

	-- Note:  type BUILTIN_TYPE and attributes BUILTIN and EXTRA_SPACE
	--        will be phased out after Elroy.  This is to move towards
	--        the upcoming '92 standard.

 	type BUILTIN_TYPE is (VHDL_SYSTEM_PRIMITIVE, LMSI, C_BEHAVIOR,
			      VHDL_SYSTEM_PRIMITIVE_STD_LOGIC);
 	attribute BUILTIN: BUILTIN_TYPE;
 	attribute EXTRA_SPACE: positive;

	-- Note:  ### For the '92 standard, attribute FOREIGN must be 
	--        moved to package STANDARD.

	attribute FOREIGN : STRING;

	-- CLI (C Language Interface) attributes

	type CLI_PIN_SENSITIVITY is (CLI_PASSIVE, CLI_EVENT, CLI_ACTIVE);

	attribute CLI_ELABORATE   : STRING;	-- components only
	attribute CLI_EVALUATE    : STRING;	-- components only
	attribute CLI_ERROR       : STRING;	-- components only
	attribute CLI_CLOSE       : STRING;	-- components only
	attribute CLI_PIN         : CLI_PIN_SENSITIVITY; -- components only

	attribute CLI_FUNCTION    : STRING;	-- functions only
	attribute CLI_PROCEDURE   : STRING;	-- procedures only

	attribute CLI_POSTPONED   : BOOLEAN;	-- components only

	-- Logic Modeling Corporation (LMC) interface attributes:

 	type LMSI_DELAY_TYPE_TYPE is (TYPICAL, MINIMUM, MAXIMUM);
	attribute LMSI_DELAY_TYPE : LMSI_DELAY_TYPE_TYPE;

 	type LMSI_TIMING_MEASUREMENT_TYPE is (DISABLED, ENABLED);
 	attribute LMSI_TIMING_MEASUREMENT: LMSI_TIMING_MEASUREMENT_TYPE;

	type LMSI_LOG_TYPE is (DISABLED, ENABLED);
	attribute LMSI_LOG: LMSI_LOG_TYPE;

	type LMSI_DELAY_ED_TYPE is (ENABLED, DISABLED);
	attribute LMSI_DELAY: LMSI_DELAY_ED_TYPE;

	type LMSI_TIMING_VIOLATIONS_TYPE is (ENABLED, DISABLED);
	attribute LMSI_TIMING_VIOLATIONS: LMSI_TIMING_VIOLATIONS_TYPE;

	type LMSI_XPROP_TYPE is (DISABLED, ENABLED);
	attribute LMSI_XPROP: LMSI_XPROP_TYPE;

	type LMSI_XPROP_METHOD_TYPE is (PREVIOUS, HIGH, LOW, FLOAT);
	attribute LMSI_XPROP_METHOD: LMSI_XPROP_METHOD_TYPE;

	-- Zycad XP interface attributes:

 	type BACKPLANE_TYPE is (XP, VERILOG, VIP);
 	attribute BACKPLANE: BACKPLANE_TYPE;

	-- Attribute to instantiate a Model Bank component in the Zycad
	-- XP box.

 	type ENCRYPTION_TYPE is (MODELBANK);
 	attribute ENCRYPTION: ENCRYPTION_TYPE;

	-- Attribute to specify the EDIF file for an architecture. This
	-- attribute can be specified in architecture(s) where the structural
	-- information is in EDIF and we want to use it. This should be used
	-- in conjunction with BACKPLANE attribute.
 	attribute EDIF_FILE_FOR_THIS_ARCHITECTURE: string;
	attribute VERILOG_FILES_FOR_THIS_ARCHITECTURE: string;

	-- The following two attributes are used to specify the physical
	-- filename of the EDIF file containing the definitions of cell(s) or
	-- entity(s) from a package and the EDIF library name used in the
	-- above EDIF file. 
 	attribute EDIF_LIBRARY_FILENAME: string;
 	attribute EDIF_LIBRARY_NAME: string;

        -- XPMSW 
  	-- XP attribute for a component which is described by a ZYCAD
  	-- CBMOD.
  	attribute ZYCAD_XP_CBMOD : BOOLEAN;

	-- This attribute is used to specify the initialization file for
	-- RAM(s) and ROM(s).
 	attribute MVL7_MEM_INITFILE: string;

	-- attributes for the function units bus (funbus)
	type FUNBUS_TYPE is (LAI,CBMOD);
	attribute FUNBUS : FUNBUS_TYPE;

        attribute CHANGE_SIMPLE_NAME : string;
        attribute CHECKOUT_LICENSE : string;
        attribute COMPILED_SYSTEM : boolean;
        attribute USE_FULL_NAME : boolean;
        attribute USE_SIMPLE_NAME : boolean;

--synopsys translate_on
--------------------------------------------------------------------
-- HDL compiler specific Attributes
        attribute async_set_reset : string;
        attribute sync_set_reset : string;
        attribute async_set_reset_local : string;
        attribute sync_set_reset_local : string;
        attribute async_set_reset_local_all : string;
        attribute sync_set_reset_local_all : string;

        attribute one_hot : string;
        attribute one_cold : string;
        attribute infer_mux : string;

--------------------------------------------------------------------
-- design compiler constraints and attributes
	attribute ARRIVAL : REAL;
	attribute DONT_TOUCH : BOOLEAN;
	attribute DONT_TOUCH_NETWORK : BOOLEAN;
	attribute DRIVE_STRENGTH : REAL;
	attribute EQUAL : BOOLEAN;
	attribute FALL_ARRIVAL : REAL;
	attribute FALL_DRIVE : REAL;
	attribute LOAD : REAL;
	attribute LOGIC_ONE : BOOLEAN;
	attribute LOGIC_ZERO : BOOLEAN;
	attribute MAX_AREA : REAL;
	attribute MAX_DELAY : REAL;
	attribute MAX_FALL_DELAY : REAL;
	attribute MAX_RISE_DELAY : REAL;
	attribute MAX_TRANSITION : REAL;
	attribute MIN_DELAY : REAL;
	attribute MIN_FALL_DELAY : REAL;
	attribute MIN_RISE_DELAY : REAL;
	attribute OPPOSITE : BOOLEAN;
	attribute RISE_ARRIVAL : REAL;
	attribute RISE_DRIVE : REAL;
	attribute UNCONNECTED : BOOLEAN;
	attribute INFER_MULTIBIT : STRING;

-- state machine attributes
	attribute STATE_VECTOR : STRING;

-- resource sharing attributes
	subtype resource is integer;
	attribute ADD_OPS : STRING;
	attribute DONT_MERGE_WITH : STRING;
	attribute MAP_TO_MODULE : STRING;
	attribute IMPLEMENTATION : STRING;
	attribute MAY_MERGE_WITH : STRING;
	attribute OPS : STRING;

-- general attributes
	attribute ENUM_ENCODING : STRING;

-- optimization attributes
	attribute TRANSFORM_CONST_MULT : boolean;

--
end ATTRIBUTES;
