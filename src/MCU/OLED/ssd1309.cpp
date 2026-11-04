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

bool SSD1309::send_command(uint8_t cmd_byte) {
    gpio_put(PIN_DC, DC_COMMAND_MODE);

    int bytes_written = spi_write_blocking(SPI_DEVICE, &cmd_byte, 1);

    return bytes_written == 1;
}

bool SSD1309::send_data(uint8_t data_byte) {
    gpio_put(PIN_DC, DC_DATA_MODE);

    int result = spi_write_blocking(SPI_DEVICE, &data_byte, 1);

    return result == 1;
}

bool SSD1309::set_cursor_pos(unsigned int text_row, unsigned int text_col) {  
    // Make sure requested values are within bounds
    if (text_row >= height / 8 ||
        text_col >= width / 8) {
        return false;
    }

    uint col = text_col * 8;

    if (!send_command(0xb0 + (text_row & 0x07))) {      // set the text row ('page') start address
        return false;
    }

    if (!send_command(col & 0x0f)) {                    // set the column start address (low nibble)
        return false;
    }

    if (!send_command(0x10 + ((col & 0xf0) >> 4))) {    // set the column start address (high nibble)
        return false;
    }

    return true;
}

bool SSD1309::display_char(char c) {
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

    int result = spi_write_blocking(SPI_DEVICE, &(font[font_index * 8]), 8);

    return result == 8;
}

bool SSD1309::display_string(const char *str) {
    if (str == nullptr) {
        return false;
    }

    while (*str) {
        if (!display_char(*str)) {
            return false;
        }
        str++;
    }

    return true;
}

bool SSD1309::clear(void) {
    const uint8_t buffer[128] = {}; // Empty buffer used to clear rows

    // Iterate through rows
    for (int text_row = 0; text_row < (this->height / 8); text_row += 1) {
        if (!set_cursor_pos(text_row, 0)) {
            return false;
        }
        
        // Clear row
        gpio_put(PIN_DC, DC_DATA_MODE);
        int result = spi_write_blocking(SPI_DEVICE, buffer, sizeof(buffer));
        if (result != static_cast<int>(sizeof(buffer))) {
            return false;
        }
    }

    // Reset cursor back to origin
    if (!set_cursor_pos(0, 0)) {
        return false;
    }

    return true;
}

bool SSD1309::init(void) {
    // Initialize SPI and check configured baud rate
    uint actual_baudrate = spi_init(SPI_DEVICE, SPI_BITRATE);

    if (actual_baudrate == 0 || actual_baudrate > SPI_BITRATE) {
        return false;
    }

    // Configure SPI mode 0, 8-bit data, MSB first
    spi_set_format(SPI_DEVICE, 8, SPI_CPOL_0, SPI_CPHA_0, SPI_MSB_FIRST); // mode 0

    // Configure and initialise our interface pins
    gpio_set_function(PIN_CS,   GPIO_FUNC_SPI);
    gpio_set_function(PIN_SCK,  GPIO_FUNC_SPI);
    gpio_set_function(PIN_MOSI, GPIO_FUNC_SPI);
    gpio_init(PIN_R);
    gpio_set_dir(PIN_R, GPIO_OUT);
    gpio_init(PIN_DC);
    gpio_set_dir(PIN_DC, GPIO_OUT);

    // Send an active-low reset pulse to the display
    gpio_put(PIN_R, 0);
    sleep_ms(1);
    gpio_put(PIN_R, 1);

    // Allow time for the OLED to recover from reset
    sleep_ms(1);

    // Display OFF (sleep mode) (RESET)
    if (!send_command(0xAE)) {
        return false;
    }

    // Clear display memory
    if (!clear()) {
        return false;
    }

    // Display ON in normal mode 
    if (!send_command(0xAF)) {
        return false;
    }

    return true;
}