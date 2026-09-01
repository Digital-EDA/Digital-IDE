//      The frequency division parameters can be modified to generate the target frequency, and the minimum frequency division coefficient is 2;
//      CPOL and CPHA can be set to set the communication mode;
//      1-bit chip select signal, but the bit width can be simply modified to set multi-bit chip select signals

`default_nettype none                        // cancel implicit declaration of wire type

module spi #(   
        parameter         VALUE_DIVIDE = 2   // Frequency division coefficient (minimum is 2)
    ) (
        // -----------------internal interface------------------
        input   wire        clock,           // input clock
        input   wire        reset,           // reset

        input   wire        CPOL,            // clock polarity
        input   wire        CPHA,            // clock phase
        input   wire        CS_input,        // chip select signal

        input   wire        valid,          
        input   wire [7:0]  data_send,       

        output  reg         ready,           
        output  reg  [7:0]  data_receive,     
        // ------------------external interface------------------
        output  reg         spi_clk,         // output clock

        output  reg         spi_mosi,        // master output slave input
        input   wire        spi_miso,        // master input slave output

        output  wire        CS_output        // chip select signal output
    );
 
    reg         act_flag;                    // action flag register
    reg [9:0]   cnt_divide;                  // divide counter
    reg [7:0]   data_send_reg;               // data register to be sent
    reg [4:0]   cnt_pulse;                   // pulse counter
    
    always @(posedge clock or posedge reset) begin
        if(reset) begin
            act_flag        <= 0;
            ready           <= 0;
            data_send_reg   <= 0;
            cnt_divide      <= 0;
            cnt_pulse       <= 0;
            if(CPOL == 1) begin
                spi_clk     <= 1;
                spi_mosi    <= 1;
                data_receive <= 0;
            end else begin
                spi_clk     <= 0;
                spi_mosi    <= 1;
                data_receive <= 0;
            end
        end
    end

    always @(posedge clock) begin 
        if(valid == 1) begin
            act_flag <= 1;
        end else if(cnt_divide == VALUE_DIVIDE/2 - 1 & act_flag == 1 & cnt_pulse == 16) begin
            act_flag <= 0;
        end else begin
            act_flag <= act_flag;
        end
    end
    
    always @(posedge clock) begin
        if(cnt_divide == VALUE_DIVIDE/2 - 1 & act_flag == 1 & cnt_pulse == 16) begin
            ready <= 1;
        end else begin
            ready <= 0;
        end
    end
    
    always @(posedge clock) begin
        if(valid == 1) begin
            data_send_reg <= data_send;
        end else begin
            data_send_reg <= data_send_reg;
        end
    end
    
    always @(posedge clock) begin 
        if(cnt_divide == VALUE_DIVIDE/2 - 1 & act_flag == 1) begin
            cnt_divide <= 0;
        end else if(act_flag == 1) begin
            cnt_divide <= cnt_divide + 1'b1;
        end else begin
            cnt_divide <= 0;
        end
    end
     
    always @(posedge clock) begin // generate cnt_pulse at twice the frequency of the target clock
        if(cnt_divide == VALUE_DIVIDE/2 - 1 & act_flag == 1 & cnt_pulse == 16) begin
            cnt_pulse <= 0;
        end else if(cnt_divide == VALUE_DIVIDE/2 - 1 & act_flag == 1) begin
            cnt_pulse <= cnt_pulse + 1'b1;
        end else if(act_flag == 1) begin
            cnt_pulse <= cnt_pulse;
        end else begin
            cnt_pulse <= 0;
        end
    end
    
    always @(posedge clock) begin
        if(cnt_divide == VALUE_DIVIDE/2 - 1 & act_flag == 1) begin
            if(CPHA == 0) begin
                case(cnt_pulse)
                    0:begin  
                        spi_clk         <= spi_clk;
                        spi_mosi        <= data_send_reg[7];
                        data_receive    <= data_receive;
                    end
                    1:begin
                        spi_clk         <= ~spi_clk;
                        spi_mosi        <= spi_mosi;
                        data_receive[7] <= spi_miso;
                    end
                    2:begin          
                        spi_clk         <= ~spi_clk;            
                        spi_mosi        <= data_send_reg[6];  
                        data_receive    <= data_receive;    
                    end            
                    3:begin          
                        spi_clk         <= ~spi_clk;         
                        spi_mosi        <= spi_mosi;        
                        data_receive[6] <= spi_miso;  
                    end            
                    4:begin          
                        spi_clk         <= ~spi_clk;            
                        spi_mosi        <= data_send_reg[5];  
                        data_receive    <= data_receive;    
                    end            
                    5:begin          
                        spi_clk         <= ~spi_clk;         
                        spi_mosi        <= spi_mosi;        
                        data_receive[5] <= spi_miso;  
                    end            
                    6:begin          
                        spi_clk         <= ~spi_clk;            
                        spi_mosi        <= data_send_reg[4];  
                        data_receive    <= data_receive;    
                    end            
                    7:begin          
                        spi_clk         <= ~spi_clk;         
                        spi_mosi        <= spi_mosi;        
                        data_receive[4] <= spi_miso;  
                    end            
                    8:begin          
                        spi_clk         <= ~spi_clk;            
                        spi_mosi        <= data_send_reg[3];  
                        data_receive    <= data_receive;    
                    end            
                    9:begin          
                        spi_clk         <= ~spi_clk;         
                        spi_mosi        <= spi_mosi;        
                        data_receive[3] <= spi_miso;  
                    end            
                    10:begin          
                        spi_clk         <= ~spi_clk;           
                        spi_mosi        <= data_send_reg[2]; 
                        data_receive    <= data_receive;   
                    end            
                    11:begin          
                        spi_clk         <= ~spi_clk;         
                        spi_mosi        <= spi_mosi;        
                        data_receive[2] <= spi_miso;  
                    end            
                    12:begin          
                        spi_clk         <= ~spi_clk;            
                        spi_mosi        <= data_send_reg[1];  
                        data_receive    <= data_receive;    
                    end            
                    13:begin          
                        spi_clk         <= ~spi_clk;         
                        spi_mosi        <= spi_mosi;        
                        data_receive[1] <= spi_miso;  
                    end            
                    14:begin          
                        spi_clk         <= ~spi_clk;            
                        spi_mosi        <= data_send_reg[0];  
                        data_receive    <= data_receive;    
                    end            
                    15:begin          
                        spi_clk         <= ~spi_clk;         
                        spi_mosi        <= spi_mosi;        
                        data_receive[0] <= spi_miso;  
                    end
                    16:begin
                        spi_clk         <= ~spi_clk;       
                        spi_mosi        <= 1;      
                        data_receive    <= data_receive;
                    end
                    default:;
                endcase
            end else begin
                case(cnt_pulse)
                    0:begin  
                        spi_clk         <= ~spi_clk;
                        spi_mosi        <= data_send_reg[7];
                        data_receive    <= data_receive;
                    end
                    1:begin
                        spi_clk         <= ~spi_clk;
                        spi_mosi        <= spi_mosi;
                        data_receive[7] <= spi_miso;
                    end
                    2:begin          
                        spi_clk         <= ~spi_clk;         
                        spi_mosi        <= data_send_reg[6];
                        data_receive    <= data_receive;  
                    end            
                    3:begin
                        spi_clk         <= ~spi_clk;       
                        spi_mosi        <= spi_mosi;      
                        data_receive[6] <= spi_miso;
                    end            
                    4:begin          
                        spi_clk         <= ~spi_clk;         
                        spi_mosi        <= data_send_reg[5];
                        data_receive    <= data_receive;  
                    end            
                    5:begin          
                        spi_clk         <= ~spi_clk;       
                        spi_mosi        <= spi_mosi;      
                        data_receive[5] <= spi_miso;
                    end            
                    6:begin          
                        spi_clk         <= ~spi_clk;           
                        spi_mosi        <= data_send_reg[4];  
                        data_receive    <= data_receive;    
                    end            
                    7:begin          
                        spi_clk         <= ~spi_clk;         
                        spi_mosi        <= spi_mosi;        
                        data_receive[4] <= spi_miso;  
                    end            
                    8:begin          
                        spi_clk         <= ~spi_clk;         
                        spi_mosi        <= data_send_reg[3];
                        data_receive    <= data_receive;  
                    end            
                    9:begin          
                        spi_clk         <= ~spi_clk;         
                        spi_mosi        <= spi_mosi;        
                        data_receive[3] <= spi_miso; 
                    end            
                    10:begin          
                        spi_clk         <= ~spi_clk;         
                        spi_mosi        <= data_send_reg[2];
                        data_receive    <= data_receive;  
                    end            
                    11:begin          
                        spi_clk         <= ~spi_clk;       
                        spi_mosi        <= spi_mosi;      
                        data_receive[2] <= spi_miso;
                    end            
                    12:begin          
                        spi_clk         <= ~spi_clk;         
                        spi_mosi        <= data_send_reg[1];
                        data_receive    <= data_receive;  
                    end            
                    13:begin          
                        spi_clk         <= ~spi_clk;       
                        spi_mosi        <= spi_mosi;      
                        data_receive[1] <= spi_miso;
                    end            
                    14:begin          
                        spi_clk         <= ~spi_clk;         
                        spi_mosi        <= data_send_reg[0];
                        data_receive    <= data_receive;  
                    end            
                    15:begin          
                        spi_clk         <= ~spi_clk;       
                        spi_mosi        <= spi_mosi;      
                        data_receive[0] <= spi_miso;
                    end
                    16:begin                       
                        spi_clk         <= spi_clk;       
                        spi_mosi        <= 1;      
                        data_receive    <= data_receive;
                    end                          
                    default:;
                endcase     
            end   
        end
    end
    
    assign CS_output = CS_input;
    
endmodule
 