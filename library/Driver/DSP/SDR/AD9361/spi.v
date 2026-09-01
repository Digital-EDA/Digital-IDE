`timescale 1ns/100ps
module spi (
        input             clk,
        input             rst_n,

        input             wr_req,
        output            wr_end,
        input  [9:0]      wr_addr,
        input  [7:0]      wr_data,

        input             rd_req,
        output            rd_end,
        input      [9:0]  rd_addr,
        output reg [7:0]  rd_data,

        output reg        spi_clk,
        output reg        spi_enb,
        input             spi_do,
        output reg        spi_di
    );
    //divide clk
    reg [4:0]         div_cnt;

    always @(posedge clk or negedge rst_n) begin        
        if(!rst_n) begin
            div_cnt <= 5'd0;
        end
        else begin
            div_cnt <= div_cnt + 5'd1;
        end
    end

    wire div_hit = &div_cnt[4:0];
    wire div_clk = !div_cnt[4];
    wire [4:0] div_half = 5'd16;

    //spi write control
    reg               wr_state;
    reg [4:0]         wr_cnt;
    reg               wr_en;
    reg [23:0]        wr_shift;

    assign wr_end = div_hit && wr_state && wr_cnt==5'd25;

    always @(posedge clk or negedge rst_n) begin        
        if(!rst_n) begin
            wr_state <= 1'b0;
        end
        else if(wr_req) begin
            wr_state <= 1'b1;
        end
        else if(wr_end) begin
            wr_state <= 1'b0;
        end
    end

    always @(posedge clk or negedge rst_n) begin        
        if(!rst_n) begin
            wr_cnt <= 5'd0;
        end
        else if(wr_end) begin
            wr_cnt <= 5'd0;
        end
        else if(wr_state) begin
            wr_cnt <= wr_cnt + div_hit;
        end
    end

    always @(posedge clk or negedge rst_n) begin        
        if(!rst_n) begin
            wr_en <= 1'b0;
        end
        else if(wr_state && div_hit && wr_cnt==5'd0) begin
            wr_en <= 1'b1;
        end
        else if(wr_state && div_hit && wr_cnt==5'd24) begin
            wr_en <= 1'b0;
        end
    end

    always @(posedge clk or negedge rst_n) begin        
        if(!rst_n) begin
            wr_shift <=24'd0;
        end
        else if(wr_req) begin
            wr_shift <={6'b100000,wr_addr,wr_data};
        end
        else if(wr_en && div_hit) begin
            wr_shift <={wr_shift[22:0],1'b0};
        end
    end

    //spi read control
    reg               rd_state;
    reg [4:0]         rd_cnt;
    reg               rd_en;
    reg [15:0]        rd_shift;

    assign rd_end = div_hit && rd_state && rd_cnt==5'd25;

    always @(posedge clk or negedge rst_n) begin        
        if(!rst_n) begin
            rd_state <= 1'b0;
        end
        else if(rd_req) begin
            rd_state <= 1'b1;
        end
        else if(rd_end) begin
            rd_state <= 1'b0;
        end
    end

    always @(posedge clk or negedge rst_n) begin        
        if(!rst_n) begin
            rd_cnt <= 5'd0;
        end
        else if(rd_end) begin
            rd_cnt <= 5'd0;
        end
        else if(rd_state) begin
            rd_cnt <= rd_cnt + div_hit;
        end
    end

    always @(posedge clk or negedge rst_n) begin        
        if(!rst_n) begin
            rd_en <= 1'b0;
        end
        else if(rd_state && div_hit && rd_cnt==5'd0) begin
            rd_en <= 1'b1;
        end
        else if(rd_state && div_hit && rd_cnt==5'd24) begin
            rd_en <= 1'b0;
        end
    end

    wire rd_cfg     = rd_en && rd_cnt<=5'd16;
    wire rd_out_vld = rd_en && rd_cnt>=5'd17;

    always @(posedge clk or negedge rst_n) begin        
        if(!rst_n) begin
            rd_shift <=16'd0;
        end
        else if(rd_req) begin
            rd_shift <={6'b000000,rd_addr};
        end
        else if(rd_cfg && div_hit) begin
            rd_shift <={rd_shift[14:0],1'b0};
        end
    end

    always @(posedge clk or negedge rst_n) begin        
        if(!rst_n) begin
            rd_data <=8'd0;
        end
        else if(rd_out_vld && div_cnt==div_half) begin
            rd_data <= {rd_data[6:0],spi_do};
        end
    end

    wire spi_clk_wire = div_clk && (wr_en || rd_en);
    wire spi_enb_wire = !(wr_state || rd_state);
    wire spi_di_wire  = (wr_en && wr_shift[23]) || (rd_cfg && rd_shift[15]);

    always @(posedge clk or negedge rst_n) begin        
        if(!rst_n) begin
            spi_clk <= 1'b0;
        end
        else begin
            spi_clk <= spi_clk_wire;
        end
    end

    always @(posedge clk or negedge rst_n) begin        
        if(!rst_n) begin
            spi_enb <= 1'b0;
        end
        else begin
            spi_enb <= spi_enb_wire;
        end
    end

    always @(posedge clk or negedge rst_n) begin        
        if(!rst_n) begin
            spi_di <= 1'b0;
        end
        else begin
            spi_di <= spi_di_wire;
        end
    end

endmodule
