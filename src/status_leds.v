module status_leds
(
    input link_up,

    output[2:0] leds
);

assign leds = {link_up? 3'b010:3'b100};


endmodule