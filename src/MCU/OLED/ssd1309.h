// Referenced ssd1309_spi example code from pico-examples repo:
// https://github.com/raspberrypi/pico-examples/tree/master/spi/ssd1309_spi

#include <stdint.h>
#include <cstdint>

#ifndef SSD1309_H
#define SSD1309_H

class SSD1309 {

    private:

        // Display dimensions (For our OLED, 128x64)
        uint8_t height, width;

    public:

        // Constructor
        SSD1309(uint8_t height, uint8_t width);

        // initialise the SPI interface and reset the display
        void init(void);

        // clear the display
        void clear(void);

        // display a single text character at the cursor position
        void display_char(char c);

        // display a null-terminated string at the cursor position
        void display_string(const char *str);

        // set the text cursor position (row, col)
        //
        // `row` is the text row, from 0 (top) to (this->height / 8) - 1
        // `col` is the text column, from 0 (left) to (this->width / 8) - 1
        void set_cursor_pos(unsigned int text_row, unsigned int text_col);

        // send a data byte to the display
        void send_data(uint8_t data_byte);

        // send a command byte to the display
        void send_command(uint8_t cmd_byte);
};

#endif