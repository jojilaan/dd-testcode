#include <stdio.h>
#include <unistd.h>
#include "swis.h"
#include "kernel.h"

/**
 * OS_READSYSINFO to check OS system info
 */
#define IIC_READ			0x1		// IIC read
#define IIC_WRITE			0x0		// IIC write
#define IIC_RETRY_YES		0x1		// IIC risc os retry yes
#define IIC_RETRY_NO		0x0		// IIC risc OS retry no
#define IIC_CHECKSUM_YES	0x1		// IIC checksum flag set
#define IIC_CHECKSUM_NO		0x0		// IIC checksum flag not set
#define IIC_NOSTART_YES		0x1		// IIC nostart flag set
#define IIC_NOSTART_NO		0x0		// IIC nostart flag not set

/**
 * IIC register definitions
 */
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

/**
 * defines different modes of the  
 */
#define POWER_DOWN      0x00		// value for CTRL_REG1 to powerdown
#define EN_ONE_SHOT     0x84		// value for CTRL_REG1 to enable one shot meassurement
#define MEASURE         0x01		// value for CTRL_REG2 to do the measurement

/**
 * struct for IIC_transfers
 */
typedef struct iic_transfer
{
  unsigned mode:1;					// mode for IIC transfer
  unsigned addr:7;					// address to read/write
  unsigned :21;						// 
  unsigned riscos_retry:1;			// retry flag
  unsigned checksumonly:1;			// checksum flag
  unsigned nostart:1;				// no start flag
  union
  {   unsigned checksum;			// checksum
      void *data;					// pointer data
  } d;
  unsigned len;						// length of data to send/receive in bytes
} iic_transfer;

/**
 * struct for IIC_transfers_information to the SWI
 */
typedef struct iic_transfer_info
{
	unsigned amount_structures:24;	// amount of iic_tranfer packets
	unsigned bus_num:8;				// IIC bus number
} iic_transfer_info;


void delay(int t);
void get_temp_humidity(void);
void set_register(_kernel_swi_regs *r, int reg_place, int reg_val); 			// set registers for SWI call
void set_iic_transfer(iic_transfer *t, int mode, int addr, \					// set IIC Transferpacket
		int retry, int sum, int nostart, int len);								// 
void set_iic_transfer_info(iic_transfer_info *t, unsigned int amount, unsigned int bus_num);
void set_iic_registers(_kernel_swi_regs *r, iic_transfer t, iic_transfer_info t_i);
int iic_read_value(int dev_addr, int reg_addr, _kernel_swi_error *error);				// IIC Read function
int iic_write_value(int dev_addr, int reg_addr, int value, _kernel_swi_error *error);	// IIC Write function

int main(void) {
    get_temp_humidity();
    return 0;
}

void delay(int t) {
    usleep(t * 1000);
}

void get_temp_humidity() {

    int fd = 0;
    uint8_t status = 0;

    /**
     *  1. check IIC WHO_AM_I DEVICE
     */
    if (iic_read_value(DEV_ID) != 0xBC) {
        printf("%s\n", "who_am_i error");
        close(fd);
        exit(1);
    }
    
    /**
     * 2. write to control registers
     */
    iic_write_value(DEV_ID, CTRL_REG1, POWER_DOWN);
    iic_write_value(DEV_ID, CTRL_REG1, EN_ONE_SHOT);
    iic_write_value(DEV_ID, CTRL_REG2, MEASURE);
    
    /**
     * 3. check if measurement is done
     */
    do {
        delay(25);		
        status = iic_read_value(DEV_ID, CTRL_REG2);
    }
    while (status != 0);

    /**
     * 4. make 13(!) read values for the humidaty and temperature
     */
    uint8_t t0_out_l = iic_read_value(DEV_ID, T0_OUT_L);
    uint8_t t0_out_h = iic_read_value(DEV_ID, T0_OUT_H);
    uint8_t t1_out_l = iic_read_value(DEV_ID, T1_OUT_L);
    uint8_t t1_out_h = iic_read_value(DEV_ID, T1_OUT_H);

    uint8_t t0_degC_x8 = iic_read_value(DEV_ID, T0_degC_x8);
    uint8_t t1_degC_x8 = iic_read_value(DEV_ID, 1_degC_x8);
    uint8_t t1_t0_msb = iic_read_value(DEV_ID, T1_T0_MSB);

    uint8_t h0_out_l = iic_read_value(DEV_ID, H0_T0_OUT_L);
    uint8_t h0_out_h = iic_read_value(DEV_ID, H0_T0_OUT_H);
    uint8_t h1_out_l = iic_read_value(DEV_ID, H1_T0_OUT_L);
    uint8_t h1_out_h = iic_read_value(DEV_ID, H1_T0_OUT_H);

    uint8_t h0_rh_x2 = iic_read_value(DEV_ID, H0_rH_x2);
    uint8_t h1_rh_x2 = iic_read_value(DEV_ID, H1_rH_x2);

    /**
     * 5. bitshift vairables and calculate the gradient and intercept
     */
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

    /**
     * 6. Make IIC call to get T_out
     */
    uint8_t t_out_l = iic_read_value(DEV_ID, TEMP_OUT_L);
    uint8_t t_out_h = iic_read_value(DEV_ID, TEMP_OUT_H);


    int16_t T_OUT = t_out_h << 8 | t_out_l;

    /**
     * 7. Make IIC call to get H_T_OUT
     */
    uint8_t h_t_out_l = iic_read_value(DEV_ID, H_T_OUT_L);
    uint8_t h_t_out_h = iic_read_value(DEV_ID, H_T_OUT_H);


    int16_t H_T_OUT = h_t_out_h << 8 | h_t_out_l;

    /**
     * 8. calculate the end result
     */
    double T_DegC = (t_gradient_m * T_OUT) + t_intercept_c;

    double H_rH = (h_gradient_m * H_T_OUT) + h_intercept_c;
    /**
     * 
     * 10. print the result
     */
    printf("Temp (from humid) = %.1f°C\n", T_DegC);
    printf("Humidity = %.0f%% rH\n", H_rH);

    /**
     * 11. close device
     */
    iic_write_value(DEV_ID, CTRL_REG1, POWER_DOWN);
}

void set_iic_registers(_kernel_swi_regs *r, iic_transfer t, iic_transfer_info t_i)  {
	r->r[0] = t;
	r->r[1] = t_i;
}
void set_iic_transfer_info(iic_transfer_info *t, unsigned int amount, unsigned int bus_num) {
	t->amount_structures = amount;
	t->bus_num = bus_num;
}
/**
 * set_iic_tranfer:
 * @Description: Insert the variables in the iic_transfer packet
 * @Input:
 *		iic_transfer *t: iic_transfer packet to fill
 * 		int mode: READ or WRITE
 *		int addr: Address of the device to write to
 *		int retry: retry bit
 *		int sum: checksum bit
 *		int nostart: nostart bit
 *		int len: len in amount of bytes to send/receive
 * @Output:
 * 		void
 */
void set_iic_transfer(*t, mode, addr, retry, sum, nostart, len, data) 
iic_transfer *t; 
int mode;
int addr;
int retry; 
int sum; 
int nostart;
int len;
int data;
{
	t->mode			= mode;
	t->addr			= addr;
	t->riscos_retry = retry;
	t->checksumonly = sum;
	t->nostart		= nostart;
	t->len			= len;
	t->d->data		= (void)data;
}

/**
 * iic_read function
 * Description: Handle the iic read function
 * @input: 
 * 		- int dev_addr: device address to read from
 * 		- int reg_addr: register address if the device to read from
 * @output: 
 * 		- return value
 * 		- by reference _kernel_swi_error
 */
int iic_read_value(int dev_addr, int reg_addr) {
	iic_transfer write_addres, read_value;
	iic_transfer transfer_packets[2];
	iic_transfer_info transfer_info;
	_kernel_swi_registers r;
	int value;

	// Set transfer registers
	set_iic_transfer(&write_addres, WRITE, dev_addr, IIC_RETRY_NO, IIC_CHECKSUM_NO, IIC_NOSTART_NO, 2, reg_addr);
	set_iic_transfer(&write_value, READ, dev_addr, IIC_RETRY_NO, IIC_CHECKSUM_NO, IIC_NOSTART_NO, 2, null);
	set_iic_transfer_info(&transfer_info, 2, 1);
	
	tranfer_packets[0] = write_address;
	tranfer_packets[1] = read_value;

	// set register for SWI kernel call
	// TODO: set list of thinny to array of iic_transfer_packets
	set_iic_registers(&r, transfer_packets, transfer_info);
	error = _kernel_swi(OS_IICOP, &r, &r);
	if (err != NULL) {
		printf(“%s %x\n”, err→errmess, err→errnum);
		exit(1);
	}
	value = r[0][1].d.data;
	return value;
}

/**
 * iic_write function
 * Description: Handle the iic write function
 * @input: 
 * 		- int dev_addr: device address to write to
 * 		- int reg_addr: register address if the device to write to
 * 		- int value:	Value to write to the register
 * @output: return int success
 */
void iic_write_value(int dev_addr, int reg_addr, int value) {
	iic_transfer write_addres, write_value;
	iic_transfer transfer_packets[2];
	iic_transfer_info transfer_info;
	_kernel_swi_registers r;

	// Set transfer registers
	set_iic_transfer(&write_addres, WRITE, dev_addr, IIC_RETRY_NO, IIC_CHECKSUM_NO, IIC_NOSTART_NO, 2, reg_addr);
	set_iic_transfer(&write_value, WRITE, dev_addr, IIC_RETRY_NO, IIC_CHECKSUM_NO, IIC_NOSTART_NO, 2, value);
	set_iic_transfer_info(&transfer_info, 2, 1);
	
	tranfer_packets[0] = write_address;
	tranfer_packets[1] = write_value;

	// set register for SWI kernel call
	// TODO: set list of thinny to array of iic_transfer_packets
	set_iic_registers(&r, transfer_packets, transfer_info);
	error = _kernel_swi(OS_IICOP, &r, &r);
	if (err != NULL) {
		printf(“%s %x\n”, err→errmess, err→errnum);
		exit(1);
	}
	return 1;
}