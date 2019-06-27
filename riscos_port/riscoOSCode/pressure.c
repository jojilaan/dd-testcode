#include <stdio.h>
#include <stdint.h>
#include <unistd.h>
#include <stdlib.h>
#include <fcntl.h>
#include "swis.h"
#include "kernel.h"

/**
 * OS_READSYSINFO to check OS system info
 */
#define OS_IICOP			0x7B	// OS_IICOp	address

#define IIC_READ			0x1		// IIC read
#define IIC_WRITE			0x0		// IIC write
#define IIC_RETRY_YES		0x1		// IIC risc os retry yes
#define IIC_RETRY_NO		0x0		// IIC risc OS retry no
#define IIC_CHECKSUM_YES	0x1		// IIC checksum flag set
#define IIC_CHECKSUM_NO		0x0		// IIC checksum flag not set
#define IIC_NOSTART_YES		0x1		// IIC nostart flag set
#define IIC_NOSTART_NO		0x0		// IIC nostart flag not set

/**
 * defines addresses of the pressure sensor
 */
#define DEV_ID        		0x5C	// Device ID of Pressure sensor
#define WHO_AM_I      		0x0F	// Address of WHO AM I register
#define CTRL_REG1     		0x20	// Control register 1
#define CTRL_REG2     		0x21	// Control register 1
#define PRESS_OUT_XL  		0x28	// Pressure value out
#define PRESS_OUT_L   		0x29	// Pressure value out low
#define PRESS_OUT_H   		0x2A	// Pressure value out high
#define TEMP_OUT_L    		0x2B	// Temperature value out low
#define TEMP_OUT_H    		0x2C	// Temperature value out high

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

/*
 * Function definitions 
 */
void do_meassurement(void);
void set_register(_kernel_swi_regs *r, int reg_place, int reg_val); 			// set registers for SWI call
void set_iic_transfer(iic_transfer *t, int mode, int addr, \					// set IIC Transferpacket
		int retry, int sum, int nostart, int len);								// 
void set_iic_transfer_info(iic_transfer_info *t, unsigned int amount, unsigned int bus_num);
void set_iic_registers(_kernel_swi_regs *r, iic_transfer t, iic_transfer_info t_i);
int iic_read_value(int dev_addr, int reg_addr, _kernel_swi_error *error);				// IIC Read function
int iic_write_value(int dev_addr, int reg_addr, int value, _kernel_swi_error *error);	// IIC Write function
void custom_sleep(int t);

int main()
{
	do_meassurement();
	return 0;
}

void do_meassurement(void) {
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
	 * 3. check IIC device with WHO_AM_I
	 * 	- read byte
	 * 	- check value
	 * 	- exit if not same
	 */
	if (iic_read_value(DEV_ID, WHO_AM_I) != 0xBD) {
		printf("%s\n", "WHO_AM_I Error, closing executable.\n");
		exit(1);
	}
	/**
	 * 4. Power down device 
	 * 	- write byte to device with
	 * 		* address CTRL_REG1
	 * 		* value POWER_DOWN
	 */
	iic_write_value(DEV_ID, CTRL_REG1, POWER_DOWN);

	/**
	 * 5. Enable one-shot 
	 * 	- write byte to device with
	 * 		* address CTRL_REG1
	 * 		* value EN_ONE_SHOT
	 */
	iic_write_value(DEV_ID, CTRL_REG1, EN_ONE_SHOT);

	/**
	 * 6. Run one-shot measurement
	 * 	- write byte to device with
	 * 		* address CTRL_REG2
	 * 		* value MEASSURE
	 */
	iic_write_value(DEV_ID,CTRL_REG2, MEASURE);
	/**
	 * 7. check if measurement is done
	 *  - do while
	 *  - status <- read byte CTRL_REG2
	 */
	do {
		custom_sleep(25);
		status = iic_read_value(DEV_ID, CTRL_REG2);
	}
	while (status != 0);

	/**
	 * 8. read registers
	 *  - temp_out_l 	<- iic_read(registers, TEMP_OUT_L)
	 *  - temp_out_h  	<- iic_read(registers, TEMP_OUT_H)
	 *  - press_out_xl	<- iic_read(registers, PRESS_OUT_XL)
	 *  - press_out_l 	<- iic_read(registers, PRESS_OUT_L)
	 *  - press_out_h 	<- iic_read(registers, PRESS_OUT_H)
	 */
	temp_out_l 		= iic_read_value(DEV_ID, TEMP_OUT_L);
	temp_out_h 		= iic_read_value(DEV_ID, TEMP_OUT_H);
	press_out_xl 	= iic_read_value(DEV_ID, PRESS_OUT_XL);
	press_out_l		= iic_read_value(DEV_ID, PRESS_OUT_L);
	press_out_h		= iic_read_value(DEV_ID, PRESS_OUT_H);

	/**
	 * 9. bitshift to the correct output value
	 */
    temp_out        = temp_out_h    << 8 | temp_out_l;
    press_out       = press_out_h   << 16| press_out_l << 8 | press_out_xl;

	/**
	 * 10. calculate output values
	 */
	t_c = 42.5 + (temp_out / 480.0);
    pressure = press_out / 4096.0;

    printf("Temp (from press) = %.2f°C\n", t_c);
    printf("Pressure = %.0f hPa\n", pressure);

	/**
	 * 11. powerdown device
	 *  - write -> CTRL_REG1 with POWER_DOWN 
	 */
	iic_write_value(DEV_ID, CTRL_REG1, POWER_DOWN);
}

void set_register(_kernel_swi_regs *r, int reg_place, int reg_val){
	r->r[reg_place] = reg_val;
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

/**
 * custom sleep that 
 */
void custom_sleep(int t) {
    usleep(t * 1000);
}
