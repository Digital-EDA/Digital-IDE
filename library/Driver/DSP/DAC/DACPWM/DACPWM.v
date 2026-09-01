module DACPWM #(
        parameter MAIN_FRE    = 500,
        parameter SPWM_FRE    = 1000,
        parameter PHASE_WIDTH = 32
    ) (
        input                    clock,
        input                    reset,
        input  [PHASE_WIDTH-1:0] idata,
        output                   dacio
    );

    localparam [PHASE_WIDTH-1:0] DC_VALUE = (2**(PHASE_WIDTH-1)) - 1;
    localparam [PHASE_WIDTH-1:0] FRE_WORD = (2**PHASE_WIDTH)*SPWM_FRE/(MAIN_FRE*1000);

    wire [PHASE_WIDTH-1:0]	Q;

    PhaseAcc #(
        .WIDTH 		( PHASE_WIDTH ))
    u_PhaseAcc(
        //ports
        .clock   		( clock      ),
        .reset   		( reset      ),
        .clr     		( 1'b0       ),
        .add_sub 		( 1'b0       ),
        .D       		( FRE_WORD   ),
        .Q       		( Q          )
    );

    reg io;
    always @(posedge clock or posedge reset) begin
        if(reset) begin
            io <= 0;
        end
        else begin
            if (Q >= idata) begin
                io <= 1'b1;
            end
            else begin
                io <= 1'b0;
            end
        end
    end

endmodule