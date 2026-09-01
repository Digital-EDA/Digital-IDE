`timescale 1ns/100ps

module FFT_IFFT #( 
        parameter FFT_IFFT   = 0, 
        parameter ORDERING   = 1,
        parameter SCALE_KCOE = 1,
        parameter TOTAL_STEP = 11,
        parameter BUFLY_MODE = 1,
        parameter TWIDD_MODE = 0,
        parameter DATA_WIDTH = 12 
    ) (
        input iclk, 
        input rstn,
        
        input ien,
        input [DATA_WIDTH-1:0]  iReal,
        input [DATA_WIDTH-1:0]  iImag,

        output oen,
        output osync,
        output [DATA_WIDTH-1:0]  oReal,
        output [DATA_WIDTH-1:0]  oImag
    );
    // localparam DIV_EXP = TOTAL_STEP;
	localparam CPLX_WIDTH = 2*DATA_WIDTH;
    localparam FFT_LENGTH = 1<<TOTAL_STEP;
	localparam INTER_MODU_WIRE_NUM = ((TOTAL_STEP-1)/2);

    reg  [TOTAL_STEP-1:0] iaddr;

    wire                  men;
    wire [TOTAL_STEP-1:0] maddr;
    wire [DATA_WIDTH-1:0] mReal;
    wire [DATA_WIDTH-1:0] mImag;

    always @(posedge iclk or negedge rstn) begin
        if(!rstn) begin
            iaddr <= 0;
        end
        else begin
            if (ien) begin
                iaddr <= iaddr + 1;
            end
            else begin
                iaddr <= 0;
            end
        end
    end
	
	generate
		if(FFT_IFFT == 1) begin : FFT_INST
            fft #( 
                .SCALE_KCOE(SCALE_KCOE),
                .BUFLY_MODE(BUFLY_MODE),
                .TWIDD_MODE(TWIDD_MODE),
                .TOTAL_STEP(TOTAL_STEP),
                .DATA_WIDTH(DATA_WIDTH))  
            fft_ins (
				.iclk(iclk),
				.rstn(rstn),
				.ien(ien),
				.iaddr(iaddr),
				.iReal(iReal),
				.iImag(iImag),
				.oen(men),
				.oaddr(maddr),
				.oReal(mReal),
				.oImag(mImag)
			);
        end
		else begin : IFFT_INST
            ifft #( 
                .SCALE_KCOE(SCALE_KCOE),
                .BUFLY_MODE(BUFLY_MODE),
                .TWIDD_MODE(TWIDD_MODE),
                .TOTAL_STEP(TOTAL_STEP),
                .DATA_WIDTH(DATA_WIDTH)) 
            fft_ins (
				.iclk(iclk),
				.rstn(rstn),
				.ien(ien),
				.iaddr(iaddr),
				.iReal(iReal),
				.iImag(iImag),
				.oen(men),
				.oaddr(maddr),
				.oReal(mReal),
				.oImag(mImag)
			);
        end
	endgenerate

    generate
        if(ORDERING) begin : natural

            reg  state;
            reg  [TOTAL_STEP-1:0] raddr;
            reg  [TOTAL_STEP-1:0] oaddr;  
            reg [FFT_LENGTH+1:0] roen;
            wire [TOTAL_STEP-1:0] waddr = maddr;

            integer i;
            always @(posedge iclk or negedge rstn) begin
                if(!rstn) begin
                    raddr <= 0;
                    oaddr <= 0;
                    state <= 0;
                end
                else begin
                    raddr <= 0;
                    if(roen[FFT_LENGTH]) begin
                        raddr <= raddr + 1;
                    end
                    if (men) begin    
                        // for (i=0; i<TOTAL_STEP; i=i+1) begin
                        //     raddr[i] <= waddr[TOTAL_STEP-1-i];
                        // end

                        if (waddr == (FFT_LENGTH-1)) begin
                            state <= ~state;
                        end
                    end
                    else begin
                        state <= state;
                    end
                    
                    oaddr <= raddr; // raddr delay 1 Cyc for oaddr
                end
            end

            SDPRAM #(
                .DEPTH 		( 1<<(TOTAL_STEP+1)),
                .WIDTH 		( CPLX_WIDTH      ))
            u_SDPRAM(
                //ports
                .clock   	( iclk   		  ),
                .reset  	( ~rstn  		  ),
                .wen   		( 1'b1   		  ),
                .ren   		( 1'b1   		  ),
                .waddr 		( {state, waddr}  ),
                .din   		( {mReal, mImag}  ),
                .raddr 		( {~state, raddr} ),
                .dout  		( {oReal, oImag}  )
            );

            always @(posedge iclk or negedge rstn) begin
                if (!rstn) begin
                    roen <= 0;
                end 
                else begin    
                    roen <= {roen[FFT_LENGTH:0], men};
                end
            end
            assign osync = oaddr ? 0 : 1;
            assign oen = roen[FFT_LENGTH+1];
        end
        else begin : reversed
            assign oen = men;
            assign osync = maddr ? 0 : 1;
            assign oReal = mReal;
            assign oImag = mImag;
        end
    endgenerate

endmodule
