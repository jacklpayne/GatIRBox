// main.cpp - Pico 2 drives four GPIO lines into the Zybo's Pmod JE
//
//   bit  Pico pin  GPIO   Zybo
//   0    pin 22    GP17   JE1
//   1    pin 25    GP19   JE2
//   2    pin 21    GP16   JE3
//   3    pin 24    GP18   JE4
//        pin 23    GND    JE5
//
// USB serial console:
//   0-9, a-f   set the four outputs to that hex value
//   n          auto-increment on/off (every 500 ms)

#include <cstdio>
#include "pico/stdlib.h"

constexpr uint kPins[4] = {17, 19, 16, 18};   // bit 0..3

static uint8_t value = 0;

static void set_value(uint8_t v) {
    value = v & 0xF;
    for (int i = 0; i < 4; i++) gpio_put(kPins[i], (value >> i) & 1);
    printf("0x%X\n", value);
}

static int hex_value(int c) {
    if (c >= '0' && c <= '9') return c - '0';
    if (c >= 'a' && c <= 'f') return c - 'a' + 10;
    if (c >= 'A' && c <= 'F') return c - 'A' + 10;
    return -1;
}

int main() {
    stdio_init_all();

    for (uint pin : kPins) {
        gpio_init(pin);
        gpio_set_dir(pin, GPIO_OUT);
    }
    set_value(0);

    bool counting = false;
    absolute_time_t next = get_absolute_time();

    while (true) {
        int c = getchar_timeout_us(0);
        int h = hex_value(c);

        if (h >= 0) {
            counting = false;
            set_value(h);
        } else if (c == 'n') {
            counting = !counting;
            printf(counting ? "auto-increment on\n" : "auto-increment off\n");
        }

        if (counting && time_reached(next)) {
            set_value(value + 1);
            next = make_timeout_time_ms(500);
        }
    }
}
