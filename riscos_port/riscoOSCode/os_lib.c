#include <stdio.h>
#include "swis.h"
#include "kernel.h"

#define OS_READSYSINFO 0x58

void set_register(_kernel_swi_regs *r, int reg_place, int reg_val);

int main()
{
	_kernel_swi_regs r;

	printf("Set register...\n");
	set_register(&r, 0, 0x0E);

	if(!_kernel_swi(OS_READSYSINFO, &r, &r)){
		printf("ERR: failed to call _kernel_swi\n");
	}
}


void set_register(_kernel_swi_regs *r, int reg_place, int reg_val){
	r->r[reg_place] = reg_val;
}
