#include <stdio.h>
#include <stdint.h>
#include <unistd.h>
#include <linux/i2c-dev.h>
#include <stdlib.h>
#include <fcntl.h>

/**
 * defines addresses of the pressure sensor
 */
#define DEV_ID          0x5c
#define WHO_AM_I        0x0F
#define CTRL_REG1       0x20
#define CTRL_REG2       0x21
#define PRESS_OUT_XL    0x28
#define PRESS_OUT_L     0x29
#define PRESS_OUT_H     0x2A
#define TEMP_OUT_L      0x2B
#define TEMP_OUT_H      0x2C

/**
 * defines different modes of the  
 */
#define POWER_DOWN      0x00
#define EN_ONE_SHOT     0x84
#define MESSURE         0x01

/**
 * define device path
 */
#define DEV_PATH "/dev/i2c-1"

void delay(int);
void get_pressure_temp(void);

int main()
{
    while(1){
        get_pressure_temp();
        custom_sleep(1000);
    }
    return 0;
}

void get_pressure_temp(void)
{
    int fd = 0;
    uint8_t temp_out_l = 0, temp_out_h = 0;
    int16_t temp_out = 0;
    double t_c = 0.0;

    uint8_t press_out_xl    = 0;
    uint8_t press_out_l     = 0;
    uint8_t press_out_h     = 0;

    int32_t press_out = 0;
    double pressure = 0.0;

    uint8_t status = 0;

    /**
     * open i2c communication
     */
    if ((fd = open(DEV_PATH, O_RDWR)) < 0) {
        printf("%s\n", "Unable to open i2c device");
        exit(1);
    }

    /**
     * configure i2c slave 
     */
    if (ioctl(fd, I2C_SLAVE, DEV_ID) < 0) {
        printf("%s\n", "Unable to configure i2c slave device");
        close(fd);
        exit(1);
    }

    /**
     * check if WHO_AM_I value is correct and well 
     */
    if (i2c_smbus_read_byte_data(fd, WHO_AM_I) != 0xBD) {
        printf("%s\n", "WHO_AM_I error");
        close(fd);
        exit(1);
    }

    /* Power down the device (clean start) */
    i2c_smbus_write_byte_data(fd, CTRL_REG1, POWER_DOWN);

    /* Turn on the pressure sensor analog front end in single shot mode  */
    i2c_smbus_write_byte_data(fd, CTRL_REG1, EN_ONE_SHOT);

    /* Run one-shot measurement (temperature and pressure), the set bit will be reset by the
     * sensor itself after execution (self-clearing bit) */
    i2c_smbus_write_byte_data(fd, CTRL_REG2, MESSURE);

    /**
     * Wait until the measurement is complete by checking the status
     */
    do {
        custom_sleep(25);		/* 25 milliseconds */
        status = i2c_smbus_read_byte_data(fd, CTRL_REG2);
    }
    while (status != 0);

    /**
     *  Read the temperature and pressure measurements
     * */
    temp_out_l      = i2c_smbus_read_byte_data(fd, TEMP_OUT_L);
    temp_out_h      = i2c_smbus_read_byte_data(fd, TEMP_OUT_H);
    press_out_xl    = i2c_smbus_read_byte_data(fd, PRESS_OUT_XL);
    press_out_l     = i2c_smbus_read_byte_data(fd, PRESS_OUT_L);
    press_out_h     = i2c_smbus_read_byte_data(fd, PRESS_OUT_H);

    /**
     * Bitshift to get the correct value
     */
    temp_out        = temp_out_h    << 8 | temp_out_l;
    press_out       = press_out_h   << 16| press_out_l << 8 | press_out_xl;

    /**
     *  calculate the output values
     * */
    t_c = 42.5 + (temp_out / 480.0);
    pressure = press_out / 4096.0;

    printf("Temp (from press) = %.2f°C\n", t_c);
    printf("Pressure = %.0f hPa\n", pressure);

    /* Power down the device */
    i2c_smbus_write_byte_data(fd, CTRL_REG1, POWER_DOWN);

    close(fd);

    return (0);
}

void custom_sleep(int t)
{
    usleep(t * 1000);
}
