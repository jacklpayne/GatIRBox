#include <stdio.h>
#include "pico/stdlib.h"
#include "ssd1309.h"
#include "hardware/adc.h"

#define PIN_ADC     26

int main()
{
    stdio_init_all();

    // Configure Feather ADC
    adc_init();
    // Make sure GPIO is high-impedance, no pullups etc
    adc_gpio_init(26);
    // Select ADC input 0 (GPIO26)
    adc_select_input(0);

    // Feather VCC and GND pins used for pot VCC and GND

    // initialise the interface and reset the display
    uint8_t height = 64;
    uint8_t width = 128;
    SSD1309 oled(height, width);

    if (!oled.init()) {
        printf("OLED init failed!!\n");
        return 1;
    }

    int previous_percentage = -1;

    while (true) {

        // Read pot value from ADC
        uint16_t result = adc_read();

        // Convert to percentage and store
        int percentage = (int)((result / 4095.0) * 100);

        // Avoid unnecessary SPI writes
        if (percentage != previous_percentage) {

            // Write percentage to OLED
            char buffer[5];
            snprintf(buffer, sizeof(buffer), "%3d%%", percentage);

            // Set cursor position and display percentage string
            bool success = oled.set_cursor_pos(4, 7);

            if (success) {
                success = oled.display_string(buffer);
            }

            if (success) {
                previous_percentage = percentage;
            } else {
                printf("OLED display operation failed!\n");
            }
        }   

        // Short delay to ensure smooth and complete transmission to OLED
        sleep_ms(20);
    }
}
