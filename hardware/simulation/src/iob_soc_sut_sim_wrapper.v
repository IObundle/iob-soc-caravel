`timescale 1ns / 1ps

`include "bsp.vh"
`include "iob_soc_sut_conf.vh"

//Peripherals _swreg_def.vh file includes.
`include "iob_soc_sut_periphs_swreg_def.vs"

`ifndef IOB_UART_SWREG_ADDR_W
`define IOB_UART_SWREG_ADDR_W 16
`endif
`ifndef IOB_SOC_SUT_DATA_W
`define IOB_SOC_SUT_DATA_W 32
`endif

module iob_soc_sut_sim_wrapper (
   output trap_o,
   //IOb-SoC uart
   input uart_avalid,
   input [`IOB_UART_SWREG_ADDR_W-1:0] uart_addr,
   input [`IOB_SOC_SUT_DATA_W-1:0] uart_wdata,
   input [3:0] uart_wstrb,
   output [`IOB_SOC_SUT_DATA_W-1:0] uart_rdata,
   output uart_ready,
   output uart_rvalid,
   input [1-1:0] clk_i,  //V2TEX_IO System clock input.
   input [1-1:0] rst_i  //V2TEX_IO System reset, asynchronous and active high.
);

   localparam AXI_ID_W = 4;
   localparam AXI_LEN_W = 8;
   localparam AXI_ADDR_W = `DDR_ADDR_W;
   localparam AXI_DATA_W = `DDR_DATA_W;

   wire clk = clk_i;
   wire cke = 1'b1;
   wire arst = rst_i;

   `include "iob_soc_sut_wrapper_pwires.vs"

   assign GPIO0_input_ports = `IOB_SOC_SUT_GPIO0_GPIO_W'h0;
   assign AXISTREAMIN0_axis_clk_i = clk;
   assign AXISTREAMIN0_axis_cke_i = cke;
   assign AXISTREAMIN0_axis_arst_i = arst;
   assign AXISTREAMIN0_axis_tvalid_i = 1'b0;
   assign AXISTREAMIN0_axis_tdata_i = {`IOB_SOC_SUT_AXISTREAMIN0_TDATA_W{1'b0}};
   assign AXISTREAMIN0_axis_tlast_i = 1'b0;

   assign AXISTREAMOUT0_axis_clk_i = clk;
   assign AXISTREAMOUT0_axis_cke_i = cke;
   assign AXISTREAMOUT0_axis_arst_i = arst;
   assign AXISTREAMOUT0_axis_tready_i = 1'b0;


   wire [1-1:0] iob_avalid_i = 1'b0;
   wire [`IOB_SOC_SUT_REGFILEIF0_ADDR_W-1:0] iob_addr_i = `IOB_SOC_SUT_REGFILEIF0_ADDR_W'h0;
   wire [`IOB_SOC_SUT_REGFILEIF0_DATA_W-1:0] iob_wdata_i = `IOB_SOC_SUT_REGFILEIF0_DATA_W'h0;
   wire [(`IOB_SOC_SUT_REGFILEIF0_DATA_W/8)-1:0] iob_wstrb_i = `IOB_SOC_SUT_REGFILEIF0_DATA_W / 8'h0;

   /////////////////////////////////////////////
   // TEST PROCEDURE
   //
   initial begin
`ifdef VCD
      $dumpfile("uut.vcd");
      $dumpvars();
`endif
   end

   //
   // INSTANTIATE COMPONENTS
   //

   //
   // UNIT UNDER TEST
   //
   iob_soc_sut #(
      .AXI_ID_W  (AXI_ID_W),
      .AXI_LEN_W (AXI_LEN_W),
      .AXI_ADDR_W(AXI_ADDR_W),
      .AXI_DATA_W(AXI_DATA_W)
   ) iob_soc_sut0 (
      .iob_avalid_i(iob_avalid_i),
      .iob_addr_i  (iob_addr_i),
      .iob_wdata_i (iob_wdata_i),
      .iob_wstrb_i (iob_wstrb_i),
      `include "iob_soc_sut_pportmaps.vs"
      .clk_i       (clk),
      .cke_i       (cke),
      .arst_i      (arst),
      .trap_o      (trap_o)
   );

   `include "iob_soc_sut_interconnect.vs"

`ifdef IOB_SOC_SUT_USE_EXTMEM
   //instantiate the axi memory
   //IOb-SoC and SUT access the same memory.
   axi_ram #(
`ifdef IOB_SOC_SUT_INIT_MEM
      .FILE      ("init_ddr_contents.hex"),  //This file contains firmware for both systems
      .FILE_SIZE (2 ** (AXI_ADDR_W - 2)),
`endif
      .ID_WIDTH  (AXI_ID_W),
      .DATA_WIDTH(AXI_DATA_W),
      .ADDR_WIDTH(AXI_ADDR_W)
   ) ddr_model_mem (
      `include "iob_memory_axi_s_portmap.vs"

      .clk_i(clk),
      .rst_i(arst)
   );
`endif

   //finish simulation on trap
   /* //Sut
always @(posedge trap[0]) begin
      #10 $display("Found SUT CPU trap condition");
      $finish;
   end
//IOb-SoC
always @(posedge trap[1]) begin
      #10 $display("Found iob_soc_sut CPU trap condition");
      $finish;
   end */

   //sram monitor - use for debugging programs
   /*
    wire [`IOB_SOC_SUT_SRAM_ADDR_W-1:0] sram_daddr = uut.int_mem0.int_sram.d_addr;
    wire sram_dwstrb = |uut.int_mem0.int_sram.d_wstrb & uut.int_mem0.int_sram.d_valid;
    wire sram_drdstrb = !uut.int_mem0.int_sram.d_wstrb & uut.int_mem0.int_sram.d_valid;
    wire [`IOB_SOC_SUT_DATA_W-1:0] sram_dwdata = uut.int_mem0.int_sram.d_wdata;


    wire sram_iwstrb = |uut.int_mem0.int_sram.i_wstrb & uut.int_mem0.int_sram.i_valid;
    wire sram_irdstrb = !uut.int_mem0.int_sram.i_wstrb & uut.int_mem0.int_sram.i_valid;
    wire [`IOB_SOC_SUT_SRAM_ADDR_W-1:0] sram_iaddr = uut.int_mem0.int_sram.i_addr;
    wire [`IOB_SOC_SUT_DATA_W-1:0] sram_irdata = uut.int_mem0.int_sram.i_rdata;

    
    always @(posedge sram_dwstrb)
    if(sram_daddr == 13'h090d)  begin
    #10 $display("Found CPU memory condition at %f : %x : %x", $time, sram_daddr, sram_dwdata );
    //$finish;
      end
    */
   //Manually added testbench uart core. RS232 pins attached to the same pins
   //of the iob_soc_sut UART0 instance to communicate with it
   // The interface of iob_soc_sut UART0 is assumed to be the first portmapped interface (UART_*)
   iob_uart uart_tb (
      .clk_i (clk),
      .cke_i (cke),
      .arst_i(arst),

      .iob_avalid_i(uart_avalid),
      .iob_addr_i  (uart_addr),
      .iob_wdata_i (uart_wdata),
      .iob_wstrb_i (uart_wstrb),
      .iob_rdata_o (uart_rdata),
      .iob_rvalid_o(uart_rvalid),
      .iob_ready_o (uart_ready),

      .txd_o(uart_rxd_i),
      .rxd_i(uart_txd_o),
      .rts_o(uart_cts_i),
      .cts_i(uart_rts_o)
   );

   //Ethernet
`ifdef IOB_SOC_SUT_USE_ETHERNET
   //ethernet clock: 4x slower than system clock
   reg [1:0] eth_cnt = 2'b0;
   reg       eth_clk;

   always @(posedge clk) begin
      eth_cnt <= eth_cnt + 1'b1;
      eth_clk <= eth_cnt[1];
   end

   // Ethernet Interface signals
   assign ETHERNET0_MRxClk     = eth_clk;
   assign ETHERNET0_MTxClk     = eth_clk;

   //add core test module in testbench
   iob_eth_tb_gen eth_tb (
      .clk  (clk),
      .reset(arst),

      // This module acts like a loopback
      .MRxClk (ETHERNET0_MTxClk),
      .MRxD   (ETHERNET0_MTxD),
      .MRxDv  (ETHERNET0_MTxEn),
      .MRxErr (ETHERNET0_MTxErr),

      // The wires are thus reversed
      .MTxClk (ETHERNET0_MRxClk),
      .MTxD   (ETHERNET0_MRxD),
      .MTxEn  (ETHERNET0_MRxDv),
      .MTxErr (ETHERNET0_MRxErr),

      .MColl(1'b0),
      .MCrS(1'b0),

      .MDC(),
      .MDIO(),
   );
`endif

endmodule
