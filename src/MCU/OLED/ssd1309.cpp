// Referenced ssd1309_spi example code from pico-examples repo (most functions are copied from this repo code):
// https://github.com/raspberrypi/pico-examples/tree/master/spi/ssd1309_spi

#include "ssd1309.h"
#include "pico/stdlib.h"
#include "hardware/spi.h"
#include "ctype.h"
#include "ssd1309_font.h"

// GPIO Pins
#define SPI_DEVICE      spi0
#define PIN_CS          1           // chip select (active low)
#define PIN_SCK         18          // SPI clock
#define PIN_MOSI        19          // SPI data transmit (MOSI)
#define PIN_DC          10          // data/command mode (low for command)
#define PIN_R           11          // reset (active low)

// ssd1309 accepts a maximum SPI clock rate of 10 Mbit/sec
#define SPI_BITRATE     1 * 1000 * 1000

// modes for the data/command pin
#define DC_COMMAND_MODE 0
#define DC_DATA_MODE    1

SSD1309::SSD1309(uint8_t height, uint8_t width) {
    this->height = height;
    this->width = width;
}

void SSD1309::send_command(uint8_t cmd_byte) {
    gpio_put(PIN_DC, DC_COMMAND_MODE);
    spi_write_blocking(SPI_DEVICE, &cmd_byte, 1);
}

void SSD1309::send_data(uint8_t data_byte) {
    gpio_put(PIN_DC, DC_DATA_MODE);
    spi_write_blocking(SPI_DEVICE, &data_byte, 1);
}

void SSD1309::set_cursor_pos(unsigned int text_row, unsigned int text_col) {
    send_command(0xb0 + (text_row & 0x07));     // set the text row ('page') start address
    uint col = text_col * 8;
    send_command(col & 0x0f);                   // set the column start address (low nibble)
    send_command(0x10 + ((col & 0xf0) >> 4));   // set the column start address (high nibble)
}

void SSD1309::display_char(char c) {
    uint font_index = FONT_INDEX_SPACE;             // default (space)
    c = toupper(c);
    if (isalpha(c)) {
        font_index = c - 'A' + FONT_INDEX_A;        // a-z and A-Z
    } else if (isdigit(c)) {
        font_index = c - '0' + FONT_INDEX_0;        // 0-9
    }
    else if (c == '%') {                            
        font_index = FONT_INDEX_PERCENT;            // %
    }
    gpio_put(PIN_DC, DC_DATA_MODE);
    spi_write_blocking(SPI_DEVICE, &(font[font_index * 8]), 8);
}

void SSD1309::display_string(const char *str) {
    while(*str) {
        display_char(*str);
        str += 1;
    }
}

void SSD1309::clear(void) {
    for (int text_row = 0; text_row < (this->height / 8); text_row += 1) {
        set_cursor_pos(text_row, 0);
        for (int col = 0; col < this->width; col += 1) {
            send_data(0x00);
        }
    }
    set_cursor_pos(0, 0);
}

void SSD1309::init(void) {
    // ssd1309 communicates using Motorola SPI mode 0
    spi_init(SPI_DEVICE, SPI_BITRATE);
    spi_set_format(SPI_DEVICE, 8, SPI_CPOL_0, SPI_CPHA_0, SPI_MSB_FIRST); // mode 0

    // configure and initialise our interface pins
    gpio_set_function(PIN_CS,   GPIO_FUNC_SPI);
    gpio_set_function(PIN_SCK,  GPIO_FUNC_SPI);
    gpio_set_function(PIN_MOSI, GPIO_FUNC_SPI);
    gpio_init(PIN_R);
    gpio_set_dir(PIN_R, GPIO_OUT);
    gpio_init(PIN_DC);
    gpio_set_dir(PIN_DC, GPIO_OUT);

    // send an active-low reset pulse to the display
    gpio_put(PIN_R, 0);
    sleep_ms(1);
    gpio_put(PIN_R, 1);

    // after a short pause, send the 'display on' command
    sleep_ms(1);
    send_command(0xaf);
    clear();
}