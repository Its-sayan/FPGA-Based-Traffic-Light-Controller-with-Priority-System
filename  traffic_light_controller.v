
module traffic_light_controller_sim (
    input wire clk,
    input wire reset,
    input wire emergency_ns,
    input wire emergency_ew,
    input wire sensor_ns,
    input wire sensor_ew,
    output reg [2:0] north_light,
    output reg [2:0] south_light,
    output reg [2:0] east_light,
    output reg [2:0] west_light,
    output reg [3:0] current_state,
    output reg emergency_mode
);

// State encoding
localparam [3:0]
    IDLE         = 4'b0000,
    NS_GREEN     = 4'b0001,
    NS_YELLOW    = 4'b0010,
    EW_GREEN     = 4'b0011,
    EW_YELLOW    = 4'b0100,
    EMERGENCY_NS = 4'b0101,
    EMERGENCY_EW = 4'b0110;

// Simulation-friendly timing (smaller values)
parameter [31:0]
    GREEN_TIME  = 10,  // 10 clock cycles for simulation
    YELLOW_TIME = 3;   // 3 clock cycles for simulation

// Internal signals
reg [3:0] state, next_state;
reg [31:0] counter;
reg emergency_latched_ns, emergency_latched_ew;

// State register with counter
always @(posedge clk or posedge reset) begin
    if (reset) begin
        state <= IDLE;
        counter <= 32'd0;
        emergency_latched_ns <= 1'b0;
        emergency_latched_ew <= 1'b0;
    end else begin
        state <= next_state;
        
        // Counter logic - reset when state changes
        if (next_state != state) begin
            counter <= 32'd0;
        end else begin
            counter <= counter + 1;
        end
        
        // Latch emergency signals
        if (emergency_ns) 
            emergency_latched_ns <= 1'b1;
        if (emergency_ew) 
            emergency_latched_ew <= 1'b1;
        
        // Clear latched signals after emergency handled
        if (state == EMERGENCY_NS && counter >= GREEN_TIME - 1)
            emergency_latched_ns <= 1'b0;
        if (state == EMERGENCY_EW && counter >= GREEN_TIME - 1)
            emergency_latched_ew <= 1'b0;
    end
end

// Next state logic
always @(*) begin
    case (state)
        IDLE: begin
            if (emergency_ns || emergency_latched_ns)
                next_state = EMERGENCY_NS;
            else if (emergency_ew || emergency_latched_ew)
                next_state = EMERGENCY_EW;
            else if (sensor_ns)
                next_state = NS_GREEN;
            else if (sensor_ew)
                next_state = EW_GREEN;
            else
                next_state = IDLE;
        end
        
        NS_GREEN: begin
            if (emergency_ns || emergency_latched_ns)
                next_state = EMERGENCY_NS;
            else if (emergency_ew || emergency_latched_ew)
                next_state = EMERGENCY_EW;
            else if (counter >= GREEN_TIME - 1)
                next_state = NS_YELLOW;
            else
                next_state = NS_GREEN;
        end
        
        NS_YELLOW: begin
            if (emergency_ns || emergency_latched_ns)
                next_state = EMERGENCY_NS;
            else if (emergency_ew || emergency_latched_ew)
                next_state = EMERGENCY_EW;
            else if (counter >= YELLOW_TIME - 1)
                next_state = EW_GREEN;
            else
                next_state = NS_YELLOW;
        end
        
        EW_GREEN: begin
            if (emergency_ew || emergency_latched_ew)
                next_state = EMERGENCY_EW;
            else if (emergency_ns || emergency_latched_ns)
                next_state = EMERGENCY_NS;
            else if (counter >= GREEN_TIME - 1)
                next_state = EW_YELLOW;
            else
                next_state = EW_GREEN;
        end
        
        EW_YELLOW: begin
            if (emergency_ns || emergency_latched_ns)
                next_state = EMERGENCY_NS;
            else if (emergency_ew || emergency_latched_ew)
                next_state = EMERGENCY_EW;
            else if (counter >= YELLOW_TIME - 1)
                next_state = NS_GREEN;
            else
                next_state = EW_YELLOW;
        end
        
        EMERGENCY_NS: begin
            if (counter >= GREEN_TIME - 1)
                next_state = IDLE;
            else
                next_state = EMERGENCY_NS;
        end
        
        EMERGENCY_EW: begin
            if (counter >= GREEN_TIME - 1)
                next_state = IDLE;
            else
                next_state = EMERGENCY_EW;
        end
        
        default: next_state = IDLE;
    endcase
end

// Output logic
always @(*) begin
    // Default all lights to red
    north_light = 3'b100;
    south_light = 3'b100;
    east_light = 3'b100;
    west_light = 3'b100;
    emergency_mode = 1'b0;
    current_state = state;
    
    case (state)
        NS_GREEN, EMERGENCY_NS: begin
            north_light = 3'b001;  // Green
            south_light = 3'b001;
            east_light = 3'b100;   // Red
            west_light = 3'b100;
            if (state == EMERGENCY_NS)
                emergency_mode = 1'b1;
        end
        
        NS_YELLOW: begin
            north_light = 3'b010;  // Yellow
            south_light = 3'b010;
            east_light = 3'b100;
            west_light = 3'b100;
        end
        
        EW_GREEN, EMERGENCY_EW: begin
            east_light = 3'b001;   // Green
            west_light = 3'b001;
            north_light = 3'b100;
            south_light = 3'b100;
            if (state == EMERGENCY_EW)
                emergency_mode = 1'b1;
        end
        
        EW_YELLOW: begin
            east_light = 3'b010;   // Yellow
            west_light = 3'b010;
            north_light = 3'b100;
            south_light = 3'b100;
        end
    endcase
end

endmodule
