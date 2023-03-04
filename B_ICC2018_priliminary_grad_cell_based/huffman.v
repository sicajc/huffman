module huffman(clk, reset, gray_valid, CNT_valid, CNT1, CNT2, CNT3, CNT4, CNT5, CNT6,
code_valid, HC1, HC2, HC3, HC4, HC5, HC6);

input clk;
input reset;
input gray_valid;
input [7:0] gray_data;
output reg CNT_valid;
output reg [7:0] CNT1, CNT2, CNT3, CNT4, CNT5, CNT6;
output reg code_valid;
output reg[7:0] HC1, HC2, HC3, HC4, HC5, HC6;
output reg[7:0] M1, M2, M3, M4, M5, M6;

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
parameter TABLE_SIZE = 12 ;
parameter CNT_WIDTH  = 8;
parameter C_TABLE_SIZE = 28;

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


//================================
//  TABLES
//================================
reg[11:0] a_sequence[0:5];
reg[19:0] c_sequence[0:4];

reg[7:0]  sequence_code[0:5];

//================================
//  COUNTERS
//================================
reg [CNT_WIDTH-1:0] a1_cnt,a2_cnt,a3_cnt,a4_cnt,a5_cnt;
reg [CNT_WIDTH-1:0] global_cnt;
reg [CNT_WIDTH-1:0] sort_cnt;
reg [CNT_WIDTH-1:0] c_cnt;

//=======================================
//  NODES INFO
//=======================================

//================================
//  CONTROL FLAGS
//================================
wire rd_data_done_f = global_cnt == 100;

wire sort_done_f = sort_cnt == 5;

wire allTableCombined_f = c_cnt == 4;

wire backTrackDone_f = c_cnt == 0;

reg bubble_sort_st;

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



//================================
//        SORT
//================================

always @(posedge clk or posedge reset) begin
    if(reset) bubble_sort_st <= 0;
    else if(l1_curState == SORT_FIND_ORDER) bubble_sort_st <= ~bubble_sort_st;
    else bubble_sort_st <= 0;
end

always@(*)
begin
    if(rd_data_done_f)
    begin
        CNT1 = a_sequence[0][7:0];
        CNT2 = a_sequence[1][7:0];
        CNT3 = a_sequence[2][7:0];
        CNT4 = a_sequence[3][7:0];
        CNT5 = a_sequence[4][7:0];
        CNT6 = a_sequence[5][7:0];
        CNT_valid = 1'b1;
    end
    else
        begin
        CNT1 = 0;
        CNT2 = 0;
        CNT3 = 0;
        CNT4 = 0;
        CNT5 = 0;
        CNT6 = 0;
        CNT_valid=1'b0;
    end
end

//================================
//        cnt
//================================
always@(posedge clk or posedge reset)
begin
    if(reset) sort_cnt <= 0;
    else if(l1_curState == SORT_FIND_ORDER) sort_cnt<=sort_cnt+1;
    else sort_cnt <= 0;
end

always@(posedge clk or posedge reset)
begin
    if(reset) c_cnt <= 0;
    else if(state_RD_DATA)   c_cnt <= 0;
    else if(state_COMBINE)   c_cnt<= allTableCombined_f ?  c_cnt : c_cnt+1;
    else if(state_BACKTRACK) c_cnt<= c_cnt-1;
    else c_cnt <= c_cnt ;
end

always@(posedge clk or posedge reset)
begin
    if(reset) global_cnt <= 0;
    else if(rd_data_done_f) global_cnt <= 0;
    else if(l1_curState == RD_DATA) global_cnt<=global_cnt+1;
    else global_cnt <= global_cnt;
end

//================================
//        TABLES
//================================
always @(posedge clk or posedge reset)
begin
    if(reset)
    begin
        for(i=0;i<6;i=i+1)
        begin
            a_sequence[i] <= {(TABLE_SIZE){1'b0}};
        end
    end
    else if(state_RD_DATA && gray_valid)
    begin
        a_sequence[0][7:0]<=  gray_data == 1 ?  a_sequence[0][7:0] + 1
        : a_sequence[0][7:0];

        a_sequence[1][7:0]<=  gray_data == 2 ?  a_sequence[1][7:0] + 1
        : a_sequence[1][7:0];

        a_sequence[2][7:0]<=  gray_data == 3 ?  a_sequence[2][7:0] + 1
        : a_sequence[2][7:0];

        a_sequence[3][7:0]<=  gray_data == 4 ?  a_sequence[3][7:0] + 1
        : a_sequence[3][7:0];

        a_sequence[4][7:0]<=  gray_data == 5 ?  a_sequence[4][7:0] + 1
        : a_sequence[4][7:0];

        a_sequence[5][7:0]<=  gray_data == 6 ?  a_sequence[5][7:0] + 1
        : a_sequence[5][7:0];
    end
    else if(state_SORT_FIND_ORDER)
    begin
        if(bubble_sort_st) begin
            for(i=0;i<6;i=i+2) begin
                a_sequence[i][7:0] <= a_sequence[i][7:0] > a_sequence[i+1][7:0] ? a_sequence[i][7:0] :
                a_sequence[i+1][7:0];
                a_sequence[i+1][7:0] <= a_sequence[i][7:0] < a_sequence[i+1][7:0] ? a_sequence[i][7:0] :
                a_sequence[i+1][7:0];
            end
        end
        else begin
            for(i=1;i<6;i=i+2) begin
                a_sequence[i][7:0] <= a_sequence[i][7:0] > a_sequence[i+1][7:0] ? a_sequence[i][7:0] :
                a_sequence[i+1][7:0];
                a_sequence[i+1][7:0] <= a_sequence[i][7:0] < a_sequence[i+1][7:0] ? a_sequence[i][7:0] :
                a_sequence[i+1][7:0];
            end
        end
    end
    else if(state_COMBINE)
    begin
        a_sequence[4][11:8] <= c_cnt + 6;
        a_sequence[4][7:0]  <= a_sequence[4][7:0] + a_sequence[5][7:0];
        a_sequence[5]       <= {TABLE_SIZE{1'b1}};
    end
end

always @(posedge clk or posedge reset)
begin
    if(reset)
    begin
        for(i=0;i<6;i=i+1)
        begin
            c_sequence[i] <= {(C_TABLE_SIZE){1'b0}};
        end
    end
    else if(state_COMBINE)
    begin
        //larger in index 0 of c element
        c_sequence[c_cnt][19:16] <= a_sequence[4][11:8];
        c_sequence[c_cnt][15:12] <= a_sequence[5][11:8];
    end
    else if(state_BACKTRACK)
    begin

    end
    else
    begin

    end
end

//================================
//        BACKTRACK
//================================
reg[7:0] code[0:10];

always @(posedge clk or posedge reset)
begin
    if(reset)
    begin
        for(i=0;i<11;i=i+1)
        begin
            code[i] <= {8{1'b0}};
        end
    end
    else if(state_BACKTRACK)
    begin
        code[c_sequence[c_cnt][19:16]][0] <= c_sequence[c_cnt][11:8]<<1
        + 1'b0;
        code[c_sequence[c_cnt][15:12]][0] <= c_sequence[c_cnt][11:8]<<1
        + 1'b1;
    end
    else
    begin
        for(i=0;i<11;i=i+1)
        begin
            code[i] <= code[i];
        end
    end
end

reg mask_ptr;

wire c_larger_index_lt  = c_sequence[c_cnt][19:16] > 5;
wire c_smaller_index_lt = c_sequence[c_cnt][15:12] > 5;

always@(posedge clk or posedge reset)
begin
    if(reset)
    begin
        mask_ptr <= 0;
    end
    else if(state_RD_DATA)
    begin
        mask_ptr <= 0;
    end
    else if(state_BACKTRACK && (c_larger_index_lt || c_smaller_index_lt))
    begin
        mask_ptr <= mask_ptr + 1;
    end
    else
    begin
        mask_ptr <= mask_ptr;
    end
end

reg[7:0] mask[0:5];

always@(posedge clk or posedge reset)
begin
    if(reset)
    begin
        for(i=0;i<6;i=i+1)
        begin
            mask[i] <= {8{1'b0}};
        end
    end
    else if(state_BACKTRACK)
    begin
        if(!c_larger_index_lt)
        begin
            case(mask_ptr)
                'd0: mask[c_sequence[c_cnt][19:16]] <= 8'b0000_0001;
                'd1: mask[c_sequence[c_cnt][19:16]] <= 8'b0000_0010;
                'd2: mask[c_sequence[c_cnt][19:16]] <= 8'b0000_0100;
                'd3: mask[c_sequence[c_cnt][19:16]] <= 8'b0000_1000;
                'd4: mask[c_sequence[c_cnt][19:16]] <= 8'b0001_0000;
                'd5: mask[c_sequence[c_cnt][19:16]] <= 8'b0010_0000;
                'd6: mask[c_sequence[c_cnt][19:16]] <= 8'b0100_0000;
                'd7: mask[c_sequence[c_cnt][19:16]] <= 8'b1000_0000;
            endcase
        end

        if(!c_smaller_index_lt)
        begin
            case(mask_ptr)
                'd0: mask[c_sequence[c_cnt][15:12]] <= 8'b0000_0001;
                'd1: mask[c_sequence[c_cnt][15:12]] <= 8'b0000_0010;
                'd2: mask[c_sequence[c_cnt][15:12]] <= 8'b0000_0100;
                'd3: mask[c_sequence[c_cnt][15:12]] <= 8'b0000_1000;
                'd4: mask[c_sequence[c_cnt][15:12]] <= 8'b0001_0000;
                'd5: mask[c_sequence[c_cnt][15:12]] <= 8'b0010_0000;
                'd6: mask[c_sequence[c_cnt][15:12]] <= 8'b0100_0000;
                'd7: mask[c_sequence[c_cnt][15:12]] <= 8'b1000_0000;
            endcase
        end
    end
    else
    begin
        for(i=0;i<6;i=i+1)
        begin
            mask[i] <= mask[i];
        end
    end
end
//================================
//        I/O
//================================
always@(posedge clk or posedge reset)
begin
    if(reset)
    begin
       {HC1, HC2, HC3, HC4, HC5, HC6} <= 'd0;
       {M1, M2, M3, M4, M5, M6} <= 'd0;
       code_valid   <= 1'b0;
    end
    else if(state_DONE)
    begin
        HC1 <= code[0];
        HC2 <= code[1];
        HC3 <= code[2];
        HC4 <= code[3];
        HC5 <= code[4];
        HC6 <= code[5];

        M1  <= mask[0];
        M2  <= mask[1];
        M3  <= mask[2];
        M4  <= mask[3];
        M5  <= mask[4];
        M6  <= mask[5];

        code_valid <= 1'b1;
    end
end

endmodule
