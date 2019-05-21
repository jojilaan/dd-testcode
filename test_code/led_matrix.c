#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <stdint.h>
#include <string.h>
#include <linux/fb.h>
#include <sys/ioctl.h>


/**
 * DEFINES
 */
#define FILEPATH "/dev/fb1"
#define NUM_WORDS 64
#define FILESIZE (NUM_WORDS * sizeof(uint16_t))

/**
 * Color is defined as RGB565
 */
#define COLOR 0xFFE0

/**
 * init custom sleep function
 */
void custom_sleep(int);

int main(void)
{
    /**
     * initialise variables
     * int i: iterator
     * int fbfd: framebuffer file descriptor
     * uint16_t *map: unsigned 16 bit int for map pointer
     * uint16_t *p: pointer to the map for writing to the led matrix
     * struct fb_fix_screeninfo fix_info: struct for framebuffer
     */
    int i;
    int fbfd;
    uint16_t *map;
    uint16_t *p;
    struct fb_fix_screeninfo fix_info;

    /**
     * open the led frame buffer device, if returned -1, then exit with error
     */
    fbfd = open(FILEPATH, O_RDWR);
    if (fbfd == -1) {
        perror("Error (call to 'open')");
        exit(EXIT_FAILURE);
    }

    /**
     * read fixed screen info for the open device, this is the fixed screen info of the RPI-sense hat
    */
    if (ioctl(fbfd, FBIOGET_FSCREENINFO, &fix_info) == -1) {
        printf("%s\n", "Error: call to 'ioctl'");
        close(fbfd);
        exit(EXIT_FAILURE);
    }

    /* now check the correct device has been found */
    if (strcmp(fix_info.id, "RPi-Sense FB") != 0) {
        printf("%s\n", "Error: RPI-SENSE FB NOT FOUND");
        close(fbfd);
        exit(EXIT_FAILURE);
    }

    /**
     * map the led frame buffer device into memory using mmap
     */
    map =
	mmap(NULL, FILESIZE, PROT_READ | PROT_WRITE, MAP_SHARED, fbfd, 0);
    if (map == MAP_FAILED) {
        close(fbfd);
        printf("%s\n", "Error: something went wrong with mmapping the file...");
        exit(EXIT_FAILURE);
    }

    /**
     *  set a pointer to the start of the memory area,
     *  this is used for looping through all the leds on the matrix
     */
    p = map;
    /**
     * clear matrix by writing 0 directly to map
     */
    memset(map, 0, FILESIZE);

    /**
     * light up everything in a row by writing the color 
     * to each value within *map starting with *p, going from 0 -> 63 
     */
    for (i = 0; i < NUM_WORDS; i++) {
        *(p + i) = COLOR;
        custom_sleep(25);
    }

    /**
     * flash white twice times after all the leds have been lit up
     */
    for (i = 0; i < 2; i++) {
        custom_sleep(250);
        memset(map, 0xFF, FILESIZE);
        custom_sleep(250);
        memset(map, 0, FILESIZE);
    }
    custom_sleep(250);

    memset(map, 0, FILESIZE);

    /**
     * un-map and close the connection
     * no need to close the connection twice if munmap returns -1 
     */
    if (munmap(map, FILESIZE) == -1) {
        printf("%s\n", "Error: something wrong happened with un-mmapping the file");
    }
    close(fbfd);

    return 0;
}

void custom_sleep(int t)
{
    usleep(t * 1000);
}
