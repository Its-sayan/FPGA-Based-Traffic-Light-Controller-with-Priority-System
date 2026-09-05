// File: traffic_light_tb.v
`timescale 1ns/1ps

module traffic_light_tb;

// Testbench signals
reg clk;
reg reset;
reg emergency_ns;
reg emergency_ew;
reg sensor_ns;
reg sensor_ew;

// Outputs
wire [2:0] north_light;
wire [2:0] south_light;
wire [2:0] east_light;
wire [2:0] west_light;
wire [3:0] current_state;
wire emergency_mode;

// Instantiate the controller
traffic_light_controller_sim uut (
    .clk(clk),
    .reset(reset),
    .emergency_ns(emergency_ns),
    .emergency_ew(emergency_ew),
    .sensor_ns(sensor_ns),
    .sensor_ew(sensor_ew),
    .north_light(north_light),
    .south_light(south_light),
    .east_light(east_light),
    .west_light(west_light),
    .current_state(current_state),
    .emergency_mode(emergency_mode)
);

// Clock generation - 100MHz (10ns period)
initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

// Task to display state as text
task display_state;
    input [3:0] state_val;
    begin
        case (state_val)
            4'b0000: $write("IDLE         ");
            4'b0001: $write("NS_GREEN     ");
            4'b0010: $write("NS_YELLOW    ");
            4'b0011: $write("EW_GREEN     ");
            4'b0100: $write("EW_YELLOW    ");
            4'b0101: $write("EMERGENCY_NS ");
            4'b0110: $write("EMERGENCY_EW ");
            default: $write("UNKNOWN      ");
        endcase
    end
endtask

// Task to display light as text
task display_light;
    input [2:0] light_val;
    begin
        case (light_val)
            3'b100: $write("RED   ");
            3'b010: $write("YELLOW");
            3'b001: $write("GREEN ");
            3'b000: $write("OFF   ");
            default: $write("ERROR ");
        endcase
    end
endtask

// Task to display full status
task display_status;
    begin
        $write("Time=%0t | State=", $time);
        display_state(current_state);
        $write(" | N=");
        display_light(north_light);
        $write(" | S=");
        display_light(south_light);
        $write(" | E=");
        display_light(east_light);
        $write(" | W=");
        display_light(west_light);
        $write(" | EMG=%b | Sensors: NS=%b EW=%b\n", emergency_mode, sensor_ns, sensor_ew);
    end
endtask

// Main test sequence
initial begin
    $display("===========================================");
    $display("  Traffic Light Controller Test Started");
    $display("===========================================\n");
    
    // Initialize inputs
    reset = 1;
    emergency_ns = 0;
    emergency_ew = 0;
    sensor_ns = 0;
    sensor_ew = 0;
    
    // Hold reset for 3 clock cycles
    repeat(3) @(posedge clk);
    reset = 0;
    $display("\n[INFO] Reset released\n");
    
    // Test 1: No traffic (should stay in IDLE)
    $display("--- Test 1: No Traffic (IDLE state) ---");
    repeat(5) @(posedge clk);
    display_status();
    
    // Test 2: NS traffic only
    $display("\n--- Test 2: NS Traffic Only ---");
    sensor_ns = 1;
    sensor_ew = 0;
    
    // Wait for full NS green + yellow cycle
    repeat(15) @(posedge clk);
    display_status();
    
    // Test 3: Emergency on EW during NS green
    $display("\n--- Test 3: Emergency Vehicle on EW ---");
    emergency_ew = 1;
    repeat(2) @(posedge clk);
    emergency_ew = 0;
    
    // Wait for emergency handling
    repeat(12) @(posedge clk);
    display_status();
    
    // Test 4: EW traffic
    $display("\n--- Test 4: EW Traffic Only ---");
    sensor_ns = 0;
    sensor_ew = 1;
    repeat(15) @(posedge clk);
    display_status();
    
    // Test 5: Emergency on NS
    $display("\n--- Test 5: Emergency Vehicle on NS ---");
    emergency_ns = 1;
    repeat(2) @(posedge clk);
    emergency_ns = 0;
    repeat(12) @(posedge clk);
    display_status();
    
    // Test 6: Both sensors active
    $display("\n--- Test 6: Both Directions Active ---");
    sensor_ns = 1;
    sensor_ew = 1;
    repeat(30) @(posedge clk);
    display_status();
    
    // Test 7: Multiple emergency vehicles
    $display("\n--- Test 7: Multiple Emergency Vehicles ---");
    emergency_ns = 1;
    repeat(2) @(posedge clk);
    emergency_ns = 0;
    repeat(5) @(posedge clk);
    emergency_ew = 1;
    repeat(2) @(posedge clk);
    emergency_ew = 0;
    repeat(20) @(posedge clk);
    display_status();
    
    $display("\n===========================================");
    $display("  Simulation Completed Successfully!");
    $display("===========================================");
    
    $finish;
end

// Waveform dumping
initial begin
    $dumpfile("traffic_light.vcd");
    $dumpvars(0, traffic_light_tb);
end

// Timeout protection (10000ns = 10us)
initial begin
    #10000;
    $display("\n[ERROR] Simulation timeout at %0t ns!", $time);
    $finish;
end

endmodule