module CIC #(
        parameter CSTAGE = 3,
        parameter FWIDTH = 12,
        parameter IWIDTH = 12,
        parameter OSCALE = 1,
        parameter OWIDTH = 15
    ) (
        input   					 clock,
        input   					 reset,
 
        input		   [FWIDTH-1:0]  factor,
 
        input   					 ivalid,
        input   signed [IWIDTH-1:0]  filter_in,
 
        output  				     ovalid,
        output  signed [OWIDTH-1:0]  filter_out
    );

    localparam FILTER_WIDTH = IWIDTH * 2 + 1;
    localparam OUT_FILTER = FILTER_WIDTH - OSCALE;
    localparam MSB = (OUT_FILTER > 0) ? OUT_FILTER : OWIDTH-1;
    localparam LSB = ((OUT_FILTER + 1 - OWIDTH) > 0) ? (OUT_FILTER + 1 - OWIDTH) : 0;

    wire [FILTER_WIDTH-1:0] module_out;

    generate 
        if(CSTAGE == 2) begin : CIC_DOWN_S2        
            CIC_DOWN_S2 #(
                .FWIDTH 		( FWIDTH 		),
                .IWIDTH 		( IWIDTH 		))
            u_CIC_DOWN_S2(
                //ports
                .clock      	( clock      		),
                .reset      	( reset      		),

                .factor     	( factor     		),

                .ivalid     	( ivalid     		),
                .filter_in  	( filter_in  		),

                .ovalid     	( ovalid     		),
                .filter_out 	( module_out 		)
            );
        end
        else if(CSTAGE == 3) begin : CIC_DOWN_S2        
            CIC_DOWN_S3 #(
                .FWIDTH 		( FWIDTH 		),
                .IWIDTH 		( IWIDTH 		))
            u_CIC_DOWN_S3(
                //ports
                .clock      	( clock      		),
                .reset      	( reset      		),

                .factor     	( factor     		),

                .ivalid     	( ivalid     		),
                .filter_in  	( filter_in  		),

                .ovalid     	( ovalid     		),
                .filter_out 	( module_out 		)
            );
        end
    endgenerate

    assign filter_out = module_out[MSB:LSB];


endmodule