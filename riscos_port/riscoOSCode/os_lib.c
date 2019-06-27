#include <stdio.h>
#include "swis.h"
#include "kernel.h"

#define OS_READSYSINFO 0x58

void set_register(_kernel_swi_regs *r, int reg_place, int reg_val);

int main()
{
	_kernel_swi_regs r;
	_kernel_swi_error *error;

	printf("Set register...\n");
	set_register(&r, 0, 0x0E);

	error  = _kernel_swi(OS_READSYSINFO, &r, &r);
	if (err != NULL) {
		printf(“%s %x\n”, err→errmess, err→errnum);
		exit(1);
	}
	printf("number of IIC Busses: %i", r[0]);
}


void set_register(_kernel_swi_regs *r, int reg_place, int reg_val){
	r->r[reg_place] = reg_val;
}
