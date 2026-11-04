#include <stdio.h>
//
#include "f_util.h"
#include "ff.h"
#include "pico/stdlib.h"
#include "rtc.h"
//
#include "hw_config.h"

int main() {
    stdio_init_all();

    // while (!stdio_usb_connected()) {  // need to comment out when running uart or just without pUTTY in general
    //     sleep_ms(100);
    // }
    // sleep_ms(500);

    time_init();


    uart_init(uart0, 115200);
    gpio_set_function(0, GPIO_FUNC_UART);
    

    sd_card_t *pSD = sd_get_by_num(0);
    FRESULT fr = f_mount(&pSD->fatfs, pSD->pcName, 1);
    if (FR_OK != fr) panic("f_mount error: %s (%d)\n", FRESULT_str(fr), fr);;

    DIR dir;
    FILINFO info;

    fr = f_opendir(&dir, "/"); //TODO: save dir/file objects to vector or arrayto be able to load them without going back to dir when rereading files
    if (fr != FR_OK) {
        printf("f_opendir error: %s (%d)\n", FRESULT_str(fr), fr);
    } else {
        fr = f_readdir(&dir, &info);
        while (true) {
            fr = f_readdir(&dir, &info);
            if (fr != FR_OK || info.fname[0] == 0) break;
            // for(int i = 0; i < len(info.fname); i++){ //debug for info
            //     printf(info.fname[i]);
            }
        }
        f_closedir(&dir);
    }

    FIL fil;
    uint8_t buf[info.fsize];
    UINT bytes_read = 0;
    fr = f_open(&fil, "simpleIR.wav", FA_READ); // TODO: find a way to pass in a var for the name of the file
    if (fr != FR_OK) {
        printf("f_open error: %s (%d)\n", FRESULT_str(fr), fr);
    }
    else {
        fr = f_read(&fil, buf, info.fsize, &bytes_read);
        for (UINT i = 0; i < bytes_read; i++) {
            //printf("%02X ", buf[i]);  // dont need to print when not using any kind of serial monitor
            //if ((i + 1) % 16 == 0) printf("\n");
        }
    }
    uart_write_blocking(uart0, buf, bytes_read);

    f_close(&fil);
    f_unmount(pSD->pcName);
}
//TODO: may need to make new inst of spi_t struct to have spi0 and spi1 need to figure out how to actually send the info over spi
