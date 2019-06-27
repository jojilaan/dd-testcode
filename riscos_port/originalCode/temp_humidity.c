/**
 * TODO comment everything, but it works  
 */
#include <stdio.h>
#include <stdint.h>
#include <unistd.h>
#include <stdlib.h>
#include <fcntl.h>
#include <linux/i2c-dev.h>

#define DEV_PATH "/dev/i2c-1"
#define DEV_ID 0x5F
#define WHO_AM_I 0x0F

#define CTRL_REG1 0x20
#define CTRL_REG2 0x21

#define T0_OUT_L 0x3C
#define T0_OUT_H 0x3D
#define T1_OUT_L 0x3E
#define T1_OUT_H 0x3F
#define T0_degC_x8 0x32
#define T1_degC_x8 0x33
#define T1_T0_MSB 0x35

#define TEMP_OUT_L 0x2A
#define TEMP_OUT_H 0x2B

#define H0_T0_OUT_L 0x36
#define H0_T0_OUT_H 0x37
#define H1_T0_OUT_L 0x3A
#define H1_T0_OUT_H 0x3B
#define H0_rH_x2 0x30
#define H1_rH_x2 0x31

#define H_T_OUT_L 0x28
#define H_T_OUT_H 0x29

void delay(int);
void get_temp_humidity();

int main(void)
{
    while(1)
    {
    	get_temp_humidity();
        usleep(1000000);
    }
    return 0;
}

void delay(int t)
{
    usleep(t * 1000);
}

void get_temp_humidity()
{

    int fd = 0;
    uint8_t status = 0;


    if ((fd = open(DEV_PATH, O_RDWR)) < 0) {
        printf("%s\n","Unable to open i2c device");
        exit(1);
    }

    if (ioctl(fd, I2C_SLAVE, DEV_ID) < 0) {
        printf("%s\n","Unable to configure i2c slave device");
        close(fd);
        exit(1);
    }

    if (i2c_smbus_read_byte_data(fd, WHO_AM_I) != 0xBC) {
        printf("%s\n", "who_am_i error");
        close(fd);
        exit(1);
    }

    i2c_smbus_write_byte_data(fd, CTRL_REG1, 0x00);
    i2c_smbus_write_byte_data(fd, CTRL_REG1, 0x84);
    i2c_smbus_write_byte_data(fd, CTRL_REG2, 0x01);

    do {
        delay(25);		
        status = i2c_smbus_read_byte_data(fd, CTRL_REG2);
    }
    while (status != 0);

    uint8_t t0_out_l = i2c_smbus_read_byte_data(fd, T0_OUT_L);
    uint8_t t0_out_h = i2c_smbus_read_byte_data(fd, T0_OUT_H);
    uint8_t t1_out_l = i2c_smbus_read_byte_data(fd, T1_OUT_L);
    uint8_t t1_out_h = i2c_smbus_read_byte_data(fd, T1_OUT_H);

    uint8_t t0_degC_x8 = i2c_smbus_read_byte_data(fd, T0_degC_x8);
    uint8_t t1_degC_x8 = i2c_smbus_read_byte_data(fd, T1_degC_x8);
    uint8_t t1_t0_msb = i2c_smbus_read_byte_data(fd, T1_T0_MSB);

    uint8_t h0_out_l = i2c_smbus_read_byte_data(fd, H0_T0_OUT_L);
    uint8_t h0_out_h = i2c_smbus_read_byte_data(fd, H0_T0_OUT_H);
    uint8_t h1_out_l = i2c_smbus_read_byte_data(fd, H1_T0_OUT_L);
    uint8_t h1_out_h = i2c_smbus_read_byte_data(fd, H1_T0_OUT_H);

    uint8_t h0_rh_x2 = i2c_smbus_read_byte_data(fd, H0_rH_x2);
    uint8_t h1_rh_x2 = i2c_smbus_read_byte_data(fd, H1_rH_x2);

    int16_t T0_OUT = t0_out_h << 8 | t0_out_l;
    int16_t T1_OUT = t1_out_h << 8 | t1_out_l;

    int16_t H0_T0_OUT = h0_out_h << 8 | h0_out_l;
    int16_t H1_T0_OUT = h1_out_h << 8 | h1_out_l;

    uint16_t T0_DegC_x8 = (t1_t0_msb & 3) << 8 | t0_degC_x8;
    uint16_t T1_DegC_x8 = ((t1_t0_msb & 12) >> 2) << 8 | t1_degC_x8;

    double T0_DegC = T0_DegC_x8 / 8.0;
    double T1_DegC = T1_DegC_x8 / 8.0;

    double H0_rH = h0_rh_x2 / 2.0;
    double H1_rH = h1_rh_x2 / 2.0;

    double t_gradient_m = (T1_DegC - T0_DegC) / (T1_OUT - T0_OUT);
    double t_intercept_c = T1_DegC - (t_gradient_m * T1_OUT);

    double h_gradient_m = (H1_rH - H0_rH) / (H1_T0_OUT - H0_T0_OUT);
    double h_intercept_c = H1_rH - (h_gradient_m * H1_T0_OUT);

    uint8_t t_out_l = i2c_smbus_read_byte_data(fd, TEMP_OUT_L);
    uint8_t t_out_h = i2c_smbus_read_byte_data(fd, TEMP_OUT_H);

    int16_t T_OUT = t_out_h << 8 | t_out_l;

    uint8_t h_t_out_l = i2c_smbus_read_byte_data(fd, H_T_OUT_L);
    uint8_t h_t_out_h = i2c_smbus_read_byte_data(fd, H_T_OUT_H);

    int16_t H_T_OUT = h_t_out_h << 8 | h_t_out_l;

    double T_DegC = (t_gradient_m * T_OUT) + t_intercept_c;

    double H_rH = (h_gradient_m * H_T_OUT) + h_intercept_c;

    printf("Temp (from humid) = %.1f°C\n", T_DegC);
    printf("Humidity = %.0f%% rH\n", H_rH);

    i2c_smbus_write_byte_data(fd, CTRL_REG1, 0x00);
    close(fd);
}
