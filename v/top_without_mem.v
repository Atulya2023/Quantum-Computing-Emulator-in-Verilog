
//`include "defines.vh"
//---------------------------------------------------------------------------
// DUT 
//---------------------------------------------------------------------------
module MyDesign #(
  parameter Q_STATE_INPUT_SRAM_ADDRESS_UPPER_BOUND = 32,
  parameter Q_STATE_INPUT_SRAM_DATA_UPPER_BOUND = 128,
  parameter Q_STATE_OUTPUT_SRAM_ADDRESS_UPPER_BOUND = 32,
  parameter Q_STATE_OUTPUT_SRAM_DATA_UPPER_BOUND = 128,
  parameter Q_GATES_SRAM_ADDRESS_UPPER_BOUND = 32,
  parameter Q_GATES_SRAM_DATA_UPPER_BOUND = 128,
  parameter SCRATCHPAD_SRAM_ADDRESS_UPPER_BOUND = 32,
  parameter SCRATCHPAD_SRAM_DATA_UPPER_BOUND = 128
) (
//---------------------------------------------------------------------------
//System signals
  input wire reset_n                      ,  
  input wire clk                          ,

//---------------------------------------------------------------------------
//Control signals
  input wire dut_valid                    , 
  output reg dut_ready                   ,

//---------------------------------------------------------------------------
//q_state_input SRAM interface
  output wire                                               q_state_input_sram_write_enable  ,
  output wire [Q_STATE_INPUT_SRAM_ADDRESS_UPPER_BOUND-1:0] q_state_input_sram_write_address ,
  output wire [Q_STATE_INPUT_SRAM_DATA_UPPER_BOUND-1:0]    q_state_input_sram_write_data    ,
  output wire [Q_STATE_INPUT_SRAM_ADDRESS_UPPER_BOUND-1:0] q_state_input_sram_read_address  , 
  input  wire [Q_STATE_INPUT_SRAM_DATA_UPPER_BOUND-1:0]    q_state_input_sram_read_data     ,

//---------------------------------------------------------------------------
//q_state_output SRAM interface
  output wire                                                q_state_output_sram_write_enable  ,
  output wire [Q_STATE_OUTPUT_SRAM_ADDRESS_UPPER_BOUND-1:0] q_state_output_sram_write_address ,
  output wire [Q_STATE_OUTPUT_SRAM_DATA_UPPER_BOUND-1:0]    q_state_output_sram_write_data    ,
  output wire [Q_STATE_OUTPUT_SRAM_ADDRESS_UPPER_BOUND-1:0] q_state_output_sram_read_address  , 
  input  wire [Q_STATE_OUTPUT_SRAM_DATA_UPPER_BOUND-1:0]    q_state_output_sram_read_data     ,

//---------------------------------------------------------------------------
//scratchpad SRAM interface                                                       
  output wire                                                scratchpad_sram_write_enable        ,
  output wire [SCRATCHPAD_SRAM_ADDRESS_UPPER_BOUND-1:0]     scratchpad_sram_write_address       ,
  output wire [SCRATCHPAD_SRAM_DATA_UPPER_BOUND-1:0]        scratchpad_sram_write_data          ,
  output wire [SCRATCHPAD_SRAM_ADDRESS_UPPER_BOUND-1:0]     scratchpad_sram_read_address        , 
  input  wire [SCRATCHPAD_SRAM_DATA_UPPER_BOUND-1:0]        scratchpad_sram_read_data           ,

//---------------------------------------------------------------------------
//q_gates SRAM interface                                                       
  output wire                                                q_gates_sram_write_enable           ,
  output wire [Q_GATES_SRAM_ADDRESS_UPPER_BOUND-1:0]        q_gates_sram_write_address          ,
  output wire [Q_GATES_SRAM_DATA_UPPER_BOUND-1:0]           q_gates_sram_write_data             ,
  output wire [Q_GATES_SRAM_ADDRESS_UPPER_BOUND-1:0]        q_gates_sram_read_address           ,  
  input  wire [Q_GATES_SRAM_DATA_UPPER_BOUND-1:0]           q_gates_sram_read_data              
);

reg [Q_GATES_SRAM_DATA_UPPER_BOUND-1:0] output_data, a, b, c, result_next, scratch_write_data;
wire [Q_GATES_SRAM_DATA_UPPER_BOUND-1:0] input_data, gates_data;
wire [((Q_GATES_SRAM_DATA_UPPER_BOUND-1)/2):0] mac_real, mac_imag, a_real, a_imag, b_imag, b_real, c_real, c_imag, mac_real_a, mac_real_b, mac_real_c, mac_imag_a, mac_imag_b, mac_imag_c;
reg [((Q_GATES_SRAM_DATA_UPPER_BOUND-1)/2):0] result_real, result_imag;
wire [Q_GATES_SRAM_DATA_UPPER_BOUND-1:0] result;


reg [Q_GATES_SRAM_ADDRESS_UPPER_BOUND-1:0] input_address, gates_address, scratch_address, output_address;
reg [Q_GATES_SRAM_ADDRESS_UPPER_BOUND-1:0] next_input_address, next_gates_address, next_scratch_address, next_output_address;
reg [4:0] matrix_length, matrix_count, row;
reg [4:0] next_matrix_length, next_matrix_count, next_row;

reg [3:0] current_state;
reg [3:0] next_state;
reg [1:0] input_address_select, output_address_select, scratch_address_select, gates_address_select, matrix_count_select, matrix_length_select, row_select, a_select, b_select, c_select, matrixcheck, result_next_select;
reg output_write_enable, scratch_write_enable, negative;



  assign q_state_output_sram_write_enable = output_write_enable;
  assign q_state_output_sram_write_address = output_address;
  assign q_state_output_sram_read_address = output_address;
  assign q_state_output_sram_write_data = {mac_real,mac_imag};
  
  assign q_state_input_sram_write_enable = 0;
  assign q_state_input_sram_write_address = 0;
  assign q_state_input_sram_read_address = input_address;
  assign q_state_input_sram_write_data = 0;

  assign q_gates_sram_write_enable = 0;
  assign q_gates_sram_write_address = 0;
  assign q_gates_sram_read_address = gates_address;
  assign q_gates_sram_write_data = 0;

  assign scratchpad_sram_write_enable = scratch_write_enable;
  assign scratchpad_sram_write_address = scratch_address;
  assign scratchpad_sram_read_address = scratch_address;
  assign scratchpad_sram_write_data = q_state_output_sram_read_data;

  // This is test stub for passing input/outputs to a DP_fp_mac, there many
  // more DW macros that you can choose to use
  DW_fp_mac_inst FP_REAL ( 
    .inst_a(mac_real_a),//input_data[Q_GATES_SRAM_DATA_UPPER_BOUND-1:(Q_GATES_SRAM_DATA_UPPER_BOUND/2)]),
    .inst_b(mac_real_b),//gates_data[((Q_GATES_SRAM_DATA_UPPER_BOUND-1)/2):0]),
    .inst_c(mac_real_c),
    .inst_rnd(3'b0),
    .z_inst(mac_real),
    .status_inst()
  );

  DW_fp_mac_inst FP_IMAG ( 
    .inst_a(mac_imag_a),//input_data[Q_GATES_SRAM_DATA_UPPER_BOUND-1:(Q_GATES_SRAM_DATA_UPPER_BOUND/2)]),
    .inst_b(mac_imag_b),//gates_data[((Q_GATES_SRAM_DATA_UPPER_BOUND-1)/2):0]),
    .inst_c(mac_imag_c),
    .inst_rnd(3'b0),
    .z_inst(mac_imag),
    .status_inst()
  );
  /*DW_fp_mac_inst FP_IMAG ( 
    .inst_a(a_imag),//input_data[Q_GATES_SRAM_DATA_UPPER_BOUND-1:(Q_GATES_SRAM_DATA_UPPER_BOUND/2)]),
    .inst_b(b_imag),//gates_data[((Q_GATES_SRAM_DATA_UPPER_BOUND-1)/2):0]),
    .inst_c(c_imag),
    .inst_rnd(3'b0),
    .z_inst(mac_imag),
    .status_inst()
  );*/

  assign result = {result_real,result_imag};
  assign {a_real,a_imag} = a;
  assign {b_real,b_imag} = b;
  assign {c_real,c_imag} = c;

  assign mac_real_a = negative? a_real:a_imag;
  assign mac_real_b = negative? b_real:{!b_imag[63],b_imag[62:0]};
  assign mac_real_c = c_real;

  assign mac_imag_a = negative? a_real:a_imag;
  assign mac_imag_b = negative? b_imag:b_real;
  assign mac_imag_c = c_imag;

  always@(posedge clk)
  begin
    if(!reset_n)
    begin
      current_state <= 100'b0;
      {input_address, gates_address, scratch_address, output_address} <= 500'b0;
      result_real <= 100'b0;
      result_imag <= 100'b0;
    end
    else
    begin
      current_state <= next_state;
      input_address <= next_input_address;
      output_address <= next_output_address;
      scratch_address <= next_scratch_address;
      gates_address <= next_gates_address;
      matrix_length <= next_matrix_length;
      matrix_count <= next_matrix_count;
      row <= next_row;
      result_real <= result_next[127:64];
      result_imag <= result_next[63:0];
      matrixcheck <= matrix_count_select;
    end
  end

  always@(*)
  begin
    input_address_select = 10'd1;    
    output_address_select = 10'd1;    
    scratch_address_select = 10'd1;    
    gates_address_select = 10'd1;    
    row_select = 10'd1;
    matrix_count_select = 10'd1;
    matrix_length_select = 10'd1;
    a_select = 10'd1;
    b_select = 10'd1;
    c_select = 10'd1;
    negative = 10'd1;
    output_write_enable = 0;
    scratch_write_enable = 0;
    dut_ready = 0; 
    next_state = 0;
    result_next_select = 1;

    casex(current_state)
    10'd0:begin
            a_select = 10'd0;
            b_select = 10'd0;
            c_select = 10'd0;
            input_address_select = 10'd0;
            output_address_select = 10'd0;    
            scratch_address_select = 10'd0;    
            gates_address_select = 10'd0;    
            row_select = 10'd0;
            matrix_count_select = 10'd0;
            matrix_length_select = 10'd0;
            dut_ready = 1; 
            result_next_select = 0;
            if(dut_valid)
            begin
              next_state = 10'd1;
            end
          end

    10'd1:begin
            a_select = 10'd0;
            b_select = 10'd0;
            c_select = 10'd0;
            matrix_length_select = 10'd2;
            matrix_count_select = 10'd3;
            input_address_select = 2;
            result_next_select = 0;
            next_state = 15;
          end
    
    10'd15: begin
              c_select = 10'd0;
              next_state = 2;
              result_next_select = 0;
            end


    10'd2:begin
            //c_select = 10'd0;
            input_address_select = 10'd2;
            gates_address_select = 10'd2;
            next_state = 3;
            if(input_address == matrix_length)
            begin
             next_state = 4; 
             input_address_select = 10'd3;
            end
          end

    10'd3:begin
            negative = 0;
            c_select = 10'd1;
            next_state = 2; 
          end

    10'd4:begin
            negative = 0;
            c_select = 10'd1;
            result_next_select = 0;
            next_state = 2;
            output_write_enable = 1;
            output_address_select = 10'd2;
            gates_address_select = 10'd1;
            input_address_select = 10'd3;
            row_select = 10'd2;
            if(row == matrix_length - 1)
            begin
              next_state = 5;
              output_address_select = 10'd0;
              if(matrix_count == 1)
                next_state = 0;
            end
          end

    10'd5:begin
            next_state = 6;
            matrix_count_select = 10'd2;
            gates_address_select = 10'd1;
            output_address_select = 10'd0;
            scratch_address_select = 10'd0;
            row_select = 10'd0;
            a_select = 10'd2;
            result_next_select = 0;
            //c_select = 10'd0;
          end

    10'd6:begin
            a_select = 10'd2;
            output_address_select = 10'd2;
            gates_address_select = 10'd2;
            scratch_address_select = 10'd2;
            scratch_write_enable = 1;
            next_state = 7; 
            if(output_address == (matrix_length - 1))
            begin
              next_state = 8;
              output_address_select = 10'd0;
              scratch_address_select = 10'd0;
            end
          end
    
    10'd7:begin
            negative = 0;
            a_select = 10'd2;
            next_state = 10'd6;
          end

    10'd8:begin
            //c_select = 10'd0;
            negative = 0;
            a_select = 10'd2;
            output_address_select = 10'd2;
            //scratch_address_select = 10'd0;
            row_select = 10'd2;
            output_write_enable = 1;
            row_select = 10'd2;
            result_next_select = 0;

            next_state = 9;
            if(row == (matrix_length - 1))
              next_state = 5;
          end

    10'd9:begin            
            a_select = 10'd3;
            next_state = 10;
            scratch_address_select = 10'd2;
            gates_address_select = 10'd2;
            if(scratch_address == (matrix_length - 1))
            begin
              next_state = 11;
              scratch_address_select = 10'd0;
            end
          end

    10'd10: begin
              negative = 0;
              a_select = 10'd3;
              next_state = 9;
            end

    10'd11: begin
              //c_select = 10'd0;
              result_next_select = 0;
              negative = 0;
              a_select = 10'd3;
              output_write_enable = 1;
              output_address_select = 10'd2;
              scratch_address_select = 10'd0;
              row_select = 10'd2;
              next_state = 9;
              if(row == matrix_length - 1)
              begin
                next_state = 5;
                output_address_select = 10'd0;
                if(matrix_count == 1)
                  next_state = 0;
              end
            end

    endcase


  end




  always@(*)
  begin
    /*next_input_address = 0;
    next_output_address = 0;
    next_scratch_address = 0;
    next_gates_address = 0;
    matrix_count = */
    next_input_address = 0;
    next_output_address = 0;
    next_scratch_address = 0;
    next_gates_address = 0;
    a = 0;
    b = 0;
    c = 0;
    next_row = 0;
    next_matrix_length = 0;
    next_matrix_count = 0;
    result_next = 0;
   
    casex(result_next_select)
    10'd0: result_next = 0;
    10'd1: result_next = {mac_real,mac_imag};
    endcase
 

    casex(a_select)
    10'd0: a = 0;
    10'd1: a = q_state_input_sram_read_data;
    10'd2: a = q_state_output_sram_read_data;
    10'd3: a = scratchpad_sram_read_data;
    endcase

    casex(b_select)
    10'd0: b = 0;
    10'd1: b = q_gates_sram_read_data;
    endcase

    casex(c_select)
    10'd0: c = 0;
    10'd1: c = result;
    endcase
 
    casex(input_address_select) 
    10'd0: next_input_address = 0;
    10'd1: next_input_address = input_address;
    10'd2: next_input_address = input_address + 1;
    10'd3: next_input_address = 1;
    endcase

    casex(output_address_select)
    10'd0: next_output_address = 0;
    10'd1: next_output_address = output_address;
    10'd2: next_output_address = output_address + 1;
    endcase

    casex(gates_address_select)
    10'd0: next_gates_address = 0;
    10'd1: next_gates_address = gates_address;
    10'd2: next_gates_address = gates_address + 1;
    endcase

    casex(scratch_address_select)
    10'd0: next_scratch_address = 0;
    10'd1: next_scratch_address = scratch_address;
    10'd2: next_scratch_address = scratch_address + 1;
    endcase

    casex(matrix_count_select)
    10'd0: next_matrix_count = 0;
    10'd1: next_matrix_count = matrix_count;
    10'd2: next_matrix_count = matrix_count - 1;
    10'd3: next_matrix_count = q_state_input_sram_read_data[63:0];
    endcase

    casex(matrix_length_select)
    10'd0: next_matrix_length = 0;
    10'd1: next_matrix_length = matrix_length;
    10'd2: next_matrix_length = 1 << q_state_input_sram_read_data[127:64] ;
    endcase

    casex(row_select)
    10'd0: next_row = 0;
    10'd1: next_row = row;
    10'd2: next_row = row + 1;
    endcase
  end

endmodule


module DW_fp_mac_inst #(
  parameter inst_sig_width = 52,
  parameter inst_exp_width = 11,
  parameter inst_ieee_compliance = 1 // These need to be fixed to decrease error
) ( 
  input wire [inst_sig_width+inst_exp_width : 0] inst_a,
  input wire [inst_sig_width+inst_exp_width : 0] inst_b,
  input wire [inst_sig_width+inst_exp_width : 0] inst_c,
  input wire [2 : 0] inst_rnd,
  output wire [inst_sig_width+inst_exp_width : 0] z_inst,
  output wire [7 : 0] status_inst
);

  // Instance of DW_fp_mac
  DW_fp_mac #(inst_sig_width, inst_exp_width, inst_ieee_compliance) U1 (
    .a(inst_a),
    .b(inst_b),
    .c(inst_c),
    .rnd(inst_rnd),
    .z(z_inst),
    .status(status_inst) 
  );

endmodule

