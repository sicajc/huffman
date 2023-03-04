module huffman(clk, reset, gray_valid, CNT_valid, CNT1, CNT2, CNT3, CNT4, CNT5, CNT6,
    code_valid, HC1, HC2, HC3, HC4, HC5, HC6);

input clk;
input reset;
input gray_valid;
input [7:0] gray_data;
output CNT_valid;
output [7:0] CNT1, CNT2, CNT3, CNT4, CNT5, CNT6;
output code_valid;
output [7:0] HC1, HC2, HC3, HC4, HC5, HC6;
output [7:0] M1, M2, M3, M4, M5, M6;


//==================
//  Integers
//==================
integer i;
genvar idx;

//==================
//  PARAMETERS
//==================
parameter BYTE       = 8 ;
parameter DATA_WIDTH = 3  ;
parameter TABLE_SIZE = 21 ;
parameter CNT_WIDTH  = 8;

//==================
//  ASCII
//==================

//==================
//  stateS
//==================
//L1 FSM
localparam RD_DATA           = 5'b00001 ;
localparam SORT_FIND_ORDER   = 5'b00010 ;
localparam COMBINE           = 5'b00100 ;
localparam BACKTRACK         = 5'b01000 ;
localparam DONE              = 5'b10000 ;

//MODE
localparam A_TABLE           = 0 ;
localparam B_TABLE           = 1 ;
localparam C_TABLE           = 2 ;
localparam D_TABLE           = 3 ;
localparam E_TABLE           = 4 ;

//================================
//  MAIN CTR
//================================
reg [4:0] l1_curState,l1_nxtState;
reg [2:0] table_cnt;

wire state_RD_DATA          = l1_curState[0];
wire state_SORT_FIND_ORDER  = l1_curState[1];
wire state_COMBINE          = l1_curState[2];
wire state_BACKTRACK        = l1_curState[3];
wire state_DONE             = l1_curState[4];


wire cur_a_table                    = table_cnt == 0;
wire cur_b_table                    = table_cnt == 1;
wire cur_c_table                    = table_cnt == 2;
wire cur_d_table                    = table_cnt == 3;
wire cur_e_table                    = table_cnt == 4;

//================================
//  TABLES
//================================
reg[TABLE_SIZE-1+3:0] a_table[0:5];
reg[TABLE_SIZE-1:0]   b_table[0:4];
reg[TABLE_SIZE-1:0]   e_table[0:3];
reg[TABLE_SIZE-1:0]   d_table[0:2];
reg[TABLE_SIZE-1:0]   e_table[0:1];

//================================
//  COUNTERS
//================================
reg [CNT_WIDTH-1:0] a1_cnt,a2_cnt,a3_cnt,a4_cnt,a5_cnt;
reg [CNT_WIDTH-1:0] global_cnt;
reg [CNT_WIDTH-1:0] sort_cnt;

//=======================================
//  NODES INFO
//=======================================
wire[2:0] a_smaller_child[0:5];
wire[2:0] a_larger_child[0:5];
wire[7:0] a_probability[0:5];
wire[2:0] a_order[0:5];
wire[2:0] a_code[0:5];
wire      a_valid[0:5];
wire[7:0] a_mask[0:5];


generate
    for(idx = 0;idx<6;i=i+1)
    begin
        assign {a_smaller_child[idx],a_larger_child[idx],a_probability[idx],
        a_order[idx],a_code[idx],a_valid[idx],a_mask[idX]} = a_table[idx];
    end
endgenerate

wire[2:0] b_smaller_child[0:4];
wire[2:0] b_larger_child[0:4];
wire[7:0] b_probability[0:4];
wire[2:0] b_order[0:4];
wire[2:0] b_code[0:4];
wire      b_valid[0:4];

generate
    for(idx = 0;idx<5;i=i+1)
    begin
        assign {b_smaller_child[idx],b_larger_child[idx],b_probability[idx],
        b_order[idx],b_code[idx],b_valid[idx]} = b_table[idx];
    end
endgenerate


wire[2:0] e_smaller_child[0:3];
wire[2:0] e_larger_child[0:3];
wire[7:0] e_probability[0:3];
wire[2:0] e_order[0:3];
wire[2:0] e_code[0:3];
wire      e_valid[0:3];

generate
    for(idx = 0;idx<4;i=i+1)
    begin
        assign {e_smaller_child[idx],e_larger_child[idx],e_probability[idx],
        e_order[idx],e_code[idx],e_valid[idx]} = e_table[idx];
    end
endgenerate

wire[2:0] d_smaller_child[0:2];
wire[2:0] d_larger_child[0:2];
wire[7:0] d_probability[0:2];
wire[2:0] d_order[0:2];
wire[2:0] d_code[0:2];
wire      d_valid[0:2];

generate
    for(idx = 0;idx<3;i=i+1)
    begin
        assign {d_smaller_child[idx],d_larger_child[idx],d_probability[idx],
        d_order[idx],d_code[idx],d_valid[idx]} = d_table[idx];
    end
endgenerate


wire[2:0] e_smaller_child[0:1];
wire[2:0] e_larger_child[0:1];
wire[7:0] e_probability[0:1];
wire[2:0] e_order[0:1];
wire[2:0] e_code[0:1];
wire      e_valid[0:1];

generate
    for(idx = 0;idx<2;i=i+1)
    begin
        assign {e_smaller_child[idx],e_larger_child[idx],e_probability[idx],
        e_order[idx],e_code[idx],e_valid[idx]} = e_table[idx];
    end
endgenerate

//================================
//  CONTROL FLAGS
//================================
wire a_traversed =  a_valid[0] && a_valid[1] && a_valid[2]
&& a_valid[3] && a_valid[4] && a_valid[5];

wire b_traversed =  b_valid[0] && b_valid[1] && b_valid[2]
&& b_valid[3] && b_valid[4];

wire c_traversed =   c_valid[0] && c_valid[1] && c_valid[2]
&& c_valid[3];

wire d_traversed =   d_valid[0] && d_valid[1] && d_valid[2];

wire e_traversed =  e_valid[0] && e_valid[1];

wire rd_data_done_f = global_cnt == 100;

wire allTableCombined_f = a_traversed && b_traversed &&
 c_traversed && d_traversed && e_traversed && state_COMBINE;

wire backTrackDone_f = a_traversed && b_traversed &&
 c_traversed && d_traversed && e_traversed && state_BACKTRACK;

reg sort_done_f;

always @(*)
begin
    case({cur_a_table,cur_b_table,cur_c_table,cur_d_table,cur_e_table})
    5'b10000:begin
            sort_done_f = sort_cnt == 5;
        end
    5'b01000:begin
            sort_done_f = sort_cnt == 4;
        end
    5'b00100:begin
            sort_done_f = sort_cnt == 3;
        end
    5'b00010:begin
            sort_done_f = sort_cnt == 2;
        end
    5'b00001:begin
            sort_done_f = sort_cnt == 1;
        end
    default:begin
            sort_done_f = 'd0;
        end
    endcase
end

//================================================================
//  MAIN DESIGN
//================================================================
//================================
//  level 1 FSM
//================================
always @(posedge clk or posedge reset)
begin:L1_FSM
    if(reset)
    begin
        l1_curState <=  RD_DATA;
    end
    else
    begin
        l1_curState <=  l1_nxtState;
    end
end

always @(*)
begin:L1_FSM_NXT
    case(l1_curState)
        RD_DATA:
        begin
            l1_nxtState = rd_data_done_f ? SORT_FIND_ORDER : RD_DATA;
        end
        SORT_FIND_ORDER:
        begin
            l1_nxtState = COMBINE;
        end
        COMBINE:
        begin
            l1_nxtState = allTableCombined_f ? BACKTRACK : SORT_FIND_ORDER;
        end
        BACKTRACK:
        begin
            l1_nxtState = backTrackDone_f ? DONE : BACKTRACK;
        end
        default:
        begin
            l1_nxtState = RD_DATA;
        end
    endcase
end

always @(posedge clk or posedge reset)
begin:TABLE_CNT
    if(reset)
    begin
        table_cnt <=  A_TABLE;
    end
    else if(allTableCombined_f)
    begin
        table_cnt <= 0;
    end
    else if(sort_done_f && state_COMBINE)
    begin
        table_cnt <= table_cnt + 1;
    end
    else
    begin
        table_cnt <= table_cnt;
    end
end

//================================
//        CNTS
//================================
always @(posedge clk or posedge reset)
begin:
    if(reset)
    begin
        a1_cnt<=0;a2_cnt<=0;a3_cnt<=0;a4_cnt<=0;a5_cnt<=0;a5_cnt<=0;
    end
    else if(state_RD_DATA && gray_valid)
    begin
        a1_cnt<=  gray_data == 1 ?  a1_cnt + 1  : a1_cnt;
        a2_cnt<=  gray_data == 2 ?  a2_cnt + 1  : a2_cnt;
        a3_cnt<=  gray_data == 3 ?  a3_cnt + 1  : a3_cnt;
        a4_cnt<=  gray_data == 4 ?  a4_cnt + 1  : a4_cnt;
        a5_cnt<=  gray_data == 5 ?  a5_cnt + 1  : a5_cnt;
        a6_cnt<=  gray_data == 6 ?  a6_cnt + 1  : a6_cnt;
    end
    else
    begin

    end
end

//================================
//        SORT
//================================
always @(posedge clk or posedge reset)
begin
    if(reset)
    begin
        sort_cnt <= 0;
    end
    else if(sort_done_f)
    begin
        sort_cnt <= 0;
    end
    else if(l1_curState == SORT_FIND_ORDER)
    begin
        sort_cnt <= sort_cnt + 1;
    end
end



reg [7:0] a_sort_list[0:5];
reg bubble_sort_st;

always @(posedge clk or posedge reset) begin
    if(reset) bubble_sort_st <= 0;
    else if(l1_curState == SORT_FIND_ORDER) bubble_sort_st <= ~bubble_sort_st;
    else bubble_sort_st <= 0;
end

always @(posedge clk or posedge reset)
begin:
    if(reset)
    begin
        for(i=0;i<6;i=i+1)
        begin
            a_sort_list[i] <= 0;
        end
    end
    else if(l1_nxtState == SORT_FIND_ORDER) begin
        for(i=0;i<6;i=i+1) begin
            a_sort_list[i] <=
        end
    end
    else if(state_SORT_FIND_ORDER)
    begin
        if(bubble_sort_st) begin
            for(i=0;i<6;i=i+2) begin
                a_sort_list[i] <= a_sort_list[i] > a_sort_list[i+1] ? a_sort_list[i] :
                a_sort_list[i+1];
                a_sort_list[i+1] <= a_sort_list[i] < a_sort_list[i+1] ? a_sort_list[i] :
                a_sort_list[i+1];
            end
        end
        else begin
            for(i=1;i<6;i=i+2) begin
                a_sort_list[i] <= a_sort_list[i] > a_sort_list[i+1] ? a_sort_list[i] :
                a_sort_list[i+1];
                a_sort_list[i+1] <= a_sort_list[i] < a_sort_list[i+1] ? a_sort_list[i] :
                a_sort_list[i+1];
            end
        end
    end
    else
end


//================================
//        TABLES
//================================
always @(posedge clk or posedge reset)
begin:
    if(reset)
    begin
        for(i=0;i<6;i=i+1)
        begin
            a_table[i] <= {(TABLE_SIZE+3){1'b1}};
        end
    end
    else if(state_RD_DATA && rd_data_done_f)
    begin
        a_table[0][17:10] <= a1_cnt;
        a_table[1][17:10] <= a2_cnt;
        a_table[2][17:10] <= a3_cnt;
        a_table[3][17:10] <= a4_cnt;
        a_table[4][17:10] <= a5_cnt;
        a_table[5][17:10] <= a6_cnt;
    end
    else
end

always @(posedge clk or posedge reset)
begin:
    if(reset)
    begin
        for(i=0;i<5;i=i+1)
        begin
            b_table[i] <=  {TABLE_SIZE{1'b1}};
        end
    end
    else if(state_RD_DATA && rd_data_done_f)
    begin

    end
end

always @(posedge clk or posedge reset)
begin:
    if(reset)
    begin
        for(i=0;i<4;i=i+1)
        begin
            c_table[i] <=  {TABLE_SIZE{1'b1}};
        end
    end
    else if(state_DONE)
    begin

    end
    else if(state_RD_DATA && isstring)
    begin

    end
    else
    begin


    end
end

always @(posedge clk or posedge reset)
begin:
    if(reset)
    begin
        for(i=0;i<3;i=i+1)
        begin
            d_table[i] <=  {TABLE_SIZE{1'b1}};
        end
    end
    else if(state_DONE)
    begin

    end
    else if(state_RD_DATA && isstring)
    begin

    end
    else
    begin


    end
end


always @(posedge clk or posedge reset)
begin:
    if(reset)
    begin
        for(i=0;i<2;i=i+1)
        begin
            e_table[i] <=  {TABLE_SIZE{1'b1}};
        end
    end
    else if(state_DONE)
    begin

    end
    else if(state_RD_DATA && isstring)
    begin

    end
    else
    begin


    end
end






endmodule
