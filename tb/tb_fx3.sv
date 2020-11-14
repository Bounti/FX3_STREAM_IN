`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Company:  Eurecom 
// Engineer: Nassim Corteggiani
// 
// Create Date:    07/22/2019 01:37:46 PM
// Design Name:    ReAct
// Module Name:    tb_react
// Project Name:   ReAct
// Target Devices: ZedBoard
// Tool Versions:  0.1
// Description: 
// 
// Dependencies:   usb3_stream_in
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module tb_fx3();

reg aclk = 0;
reg aresetn = 0;

wire clk_out;  //-output clk 100 Mhz and 180 phase shift
wire [31:0] data;
wire fx3_data_available;
wire overflow;

reg fx3_resetn;
reg [31:0] word_counter;

reg fx3_read_ready_d;

reg DATA_COUNTER_ARMED = 1'b0;
wire DATA_CNT_HIT = (word_counter == 32'D4091)? 1'b1: 1'b0;
reg DMA_RDY = 1'b1;

reg [3:0] fx3_state_d;
reg [3:0] fx3_state;
parameter [3:0] START = 3'b000,
  TH0_WAIT = 3'b001,
  TH0_REQUEST = 3'b010,
  TH0_READ = 3'b011,
  TH1_WAIT = 3'b100,
  TH1_REQUEST = 3'b101,
  TH1_READ = 3'b110;

reg fx3_read_ready = 1'b0;

top_wrapper DUT
(.aclk(aclk),
  .aresetn(aresetn),
  .clk_out(clk_out),
  .data(data),
  .fx3_data_available(fx3_data_available),
  .fx3_resetn(fx3_resetn),
  .fx3_read_ready(fx3_read_ready),
  .overflow(overflow)
);

always #1ns aclk = ~aclk;

initial begin

  fx3_resetn = 0;
  aresetn = 0;
  #10ns
  aresetn = 1;
  #100ns
  fx3_resetn = 1;
  
  DMA_RDY = 1'b0;
  #100us
  DMA_RDY = 1'b1;

end

always @(fx3_state_d) begin
  if(fx3_state_d == TH0_REQUEST || fx3_state_d == TH1_REQUEST) begin
    DATA_COUNTER_ARMED = 1'b1;
  end else if(fx3_state_d == TH0_WAIT || fx3_state_d == TH1_WAIT) begin
    DATA_COUNTER_ARMED = 1'b0;
  end
end

always @(posedge clk_out) begin
  if(aresetn == 1'b0 || fx3_resetn == 1'b0) begin
    word_counter <= 32'b0;
  end else begin
    if(DATA_COUNTER_ARMED == 1'b1) begin
      word_counter <= word_counter +1; 
    end
  end
end

always @(posedge clk_out) begin
  if(aresetn == 1'b0 || fx3_resetn == 1'b0) begin
    fx3_state <= START;
    fx3_read_ready <= 1'b0;
  end else begin
    fx3_state <= fx3_state_d;
    fx3_read_ready <= fx3_read_ready_d;
  end
end

always @(fx3_state_d, fx3_data_available, DATA_CNT_HIT, DMA_RDY) begin
  case (fx3_state_d)
    START: begin 
    fx3_state_d <= TH0_WAIT;
    fx3_read_ready_d <= 1'b0;
  end
  TH0_WAIT: begin
    if(DMA_RDY == 1'b1 && fx3_data_available == 1'b1) begin
      fx3_state_d <= TH0_REQUEST;
      fx3_read_ready_d <= 1'b0;
    end else begin
      fx3_state_d <= TH0_WAIT;
      fx3_read_ready_d <= 1'b0;
    end
  end
  TH0_REQUEST: begin
    fx3_state_d <= TH0_READ;
    fx3_read_ready_d <= 1'b1;
  end
  TH0_READ: begin
    if(DATA_CNT_HIT == 1'b1) begin
      fx3_state_d <= TH1_WAIT;
      fx3_read_ready_d <= 1'b1;
    end else begin
      fx3_state_d <= TH0_READ;
      fx3_read_ready_d <= 1'b1;
    end
  end
  TH1_WAIT: begin
    if(DMA_RDY == 1'b1 && fx3_data_available == 1'b1) begin
      fx3_state_d <= TH1_REQUEST;
      fx3_read_ready_d <= 1'b1;
    end else begin
      fx3_state_d <= TH1_WAIT;
      fx3_read_ready_d <= 1'b1;
    end
  end
  TH1_REQUEST: begin
    fx3_state_d <= TH1_READ;
    fx3_read_ready_d <= 1'b0;
  end
  TH1_READ: begin
    if(DATA_CNT_HIT == 1'b1) begin
      fx3_state_d <= TH0_WAIT;
      fx3_read_ready_d <= 1'b0;
    end else begin
      fx3_state_d <= TH1_READ;
      fx3_read_ready_d <= 1'b0;
    end
  end
  default: begin
    fx3_state_d <= START;
    fx3_read_ready_d <= 1'b0;
   end
endcase;
end

endmodule


