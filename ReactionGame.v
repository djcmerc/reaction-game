`timescale 1ns / 1ps
// Module to control the functionality of the game
module ReactionGame(input CLOCK, playButton, startButton, output reg [7:0] LED, output reg [3:0] Level);

parameter Level1 = 4'b0000, Level2 = 4'b0001, Level3 = 4'b0010, Level4 = 4'b0011, Level5 = 4'b0100, 
			 Level6 = 4'b0101, Level7 = 4'b0110, Level8 = 4'b0111, Level9 = 4'b1000, LevelWin = 4'b1001;
parameter Idle = 3'b000, Idle2 = 3'b001, Start = 3'b010, Right = 3'b011, Left = 3'b100, Win = 3'b101;

reg [31:0] LEDClkCounter, CurrentSpeed = 8000000;
reg LEDClk = 0;
reg [2:0] LEDState = 0;
		
	// Initializes the Level to the first level
	initial begin
		Level = Level1;
	end
	
	// Controls push button and level changing
	always @(posedge CLOCK) begin
		LEDClkCounter <= LEDClkCounter + 1;
		if (LEDClkCounter == CurrentSpeed) begin
			LEDClkCounter <= 0;
			LEDClk <= ~LEDClk;
		end
	end
	
	// Controls the speed at each level
	always @(Level) begin
		case (Level)
			Level1: CurrentSpeed <= 5000000;
			Level2: CurrentSpeed <= 4500000;
			Level3: CurrentSpeed <= 4000000;
			Level4: CurrentSpeed <= 3500000;
			Level5: CurrentSpeed <= 3000000;
			Level6: CurrentSpeed <= 2500000;
			Level7: CurrentSpeed <= 2000000;
			Level8: CurrentSpeed <= 1500000;
			Level9: CurrentSpeed <= 1000000;
			default: CurrentSpeed <= 0;
		endcase
	end
	
	// Controls the state of the LED light
	always @(posedge LEDClk) begin
		
		// Checks if the button was pressed on the middle two LED lights
		if (playButton == 0 && (LED == 8'b00010000 || LED == 8'b00001000) && LEDState != Win) begin
			// If all levels are passed, then player wins
			if (Level > Level8) begin
				Level = LevelWin;
				LEDState = Win;
			end
			// Increments the level for a successful attempt
			else begin
				Level = Level + 1;
				LEDState = Idle;
			end
		end
		
		// Checks if button was pressed on wrong LED lights
		else if (playButton == 0 && (LED != 8'b00010000 || LED != 8'b00001000) && (LEDState != Idle && LEDState != Idle2 && LEDState != Win)) begin
		
			// If wrong on Level 1, stays on Level 1
			if (Level == Level1) Level = Level1;
			// Decrements level on unsuccessful attempts
			else Level = Level - 1;
			LEDState = Idle;
		end
		
		// Controls the bouncing and lighting up of the LEDs
		case (LEDState)
			// Idle, Idle2: States in which the game waits for the user to start the game 
			Idle: begin
				LED = 8'b11111111;
				LEDState = Idle2;
				if (startButton == 0) LEDState = Start;
			end
			Idle2: begin
				LED = 8'b00000000;
				LEDState = Idle;
				if (startButton == 0) LEDState = Start;
			end
			// Start, Right, Left: Control the bouncing of the LED
			Start: begin
				LED = 8'b10000000;
				LEDState = Right;
			end
			Right: begin
				LED = LED >> 1;
				if (LED == 8'b00000001) LEDState = Left;
			end
			Left: begin
				LED = LED << 1;
				if (LED == 8'b10000000) LEDState = Right;
			end
			// Win: User wins, LEDs turn off and game waits for user to push start again
			Win: begin
				LED = 8'b00000000;
				if (startButton == 0) begin
					Level = Level1;
					LEDState = Idle;
				end
			end
			default: LEDState = Idle;
		endcase
	end
endmodule

// Module to control the seven segment displays
module LevelDisplay (input CLOCK, input [3:0] Level, output COL, segdp, output reg [6:0] segs, output reg [3:0] DIG);
reg [31:0] CLK2, CLK3;
reg segmentCLK, WinCLK;
reg [1:0] digSel = 0;
reg [6:0] LevelSeg, WinSegs;

	assign COL = 1;
	assign segdp = 1;
	
	always @(posedge CLOCK) begin
		CLK2 = CLK2 + 1;
		CLK3 = CLK3 + 1;
		// Multiplexes the digits at a rate of 5ms per digit
		if (CLK2 == 20000) begin
			CLK2 = 0;
			segmentCLK = ~segmentCLK;
			if (segmentCLK == 1)
				digSel = digSel + 1;
		end
		// Controls the speed at which the segments will rotate during Win State
		if (CLK3 == 2000000) begin
			CLK3 = 0;
			WinCLK = ~WinCLK;
		end
	end

	// Multiplexes the digits to display the current level
	always @(posedge segmentCLK) begin
		// Displays the current level during the game
		if (Level != 4'b1001) begin
			case(digSel)
				0: begin
					DIG <= 4'b0111;
					segs <= 7'b0111111;
				end
				1: begin
					DIG <= 4'b1011;
					segs <= 7'b1000111;
				end
				2: begin
					DIG <= 4'b1101;
					segs <= LevelSeg;
				end
				3: begin
					DIG <= 4'b1110;
					segs <= 7'b0111111;
				end
				default: segs <= 7'b1111111;
			endcase
		end
		// Changes the seven segment display to show a pattern when a win occurs
		else if (Level == 4'b1001) begin
			DIG <= 4'b0000;
			segs <= WinSegs;
		end
	end
	
	// Rotates the segments to indicate a win
	always @(posedge WinCLK) begin
		if (Level != 4'b1001) WinSegs <= 7'b1111110;
		else begin
			WinSegs <= (WinSegs << 1)| 1;
			if (WinSegs == 7'b1011111) WinSegs <= 7'b1111110;
		end
	end
	
	// Displays the level number on the seven segment display
	always @* begin
		case(Level)
			0: LevelSeg = 7'b1111001; // Level 1
			1: LevelSeg = 7'b0100100; // Level 2
			2: LevelSeg = 7'b0110000; // Level 3
			3: LevelSeg = 7'b0011001; // Level 4
			4: LevelSeg = 7'b0010010; // Level 5
			5: LevelSeg = 7'b0000010; // Level 6
			6: LevelSeg = 7'b1111000; // Level 7
			7: LevelSeg = 7'b0000000; // Level 8
			8: LevelSeg = 7'b0010000; // Level 9
			default: LevelSeg = 7'b1111111;
		endcase
	end
endmodule

// Top Module
module topModule(input CLOCK, input [3:0] PB, output [7:0] LED, output COL, segdp, output [3:0] DIG, output [6:0] segs);

wire [3:0] Level;

	ReactionGame U0 (CLOCK, PB[0], PB[1], LED, Level);
	LevelDisplay U1 (CLOCK, Level, COL, segdp, segs, DIG);

endmodule
