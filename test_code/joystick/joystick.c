#define _GNU_SOURCE
#define DEV_INPUT_EVENT "/dev/input"
#define EVENT_DEV_NAME "event"
#define DEV_FB "/dev"
#define FB_DEV_NAME "fb"

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <fcntl.h>
#include <linux/fb.h>
#include <sys/mman.h>
#include <sys/ioctl.h>
#include <time.h>
#include <poll.h>
#include <dirent.h>
#include <string.h>

#include <linux/input.h>
#include <linux/fb.h>

static int is_event_device(const struct dirent *dir)
{
	return strncmp(EVENT_DEV_NAME, dir->d_name,
		       strlen(EVENT_DEV_NAME)-1) == 0;
}

void change_dir(unsigned int code)
{
    switch (code) {
        case KEY_ENTER:
            fprintf(stdout, "Key event: ENTER\n");
            break;
        case KEY_UP:
            fprintf(stdout, "Key event: UP\n");
            break;
        case KEY_RIGHT:
            fprintf(stdout, "Key event: RIGHT\n");
            break;
        case KEY_DOWN:
            fprintf(stdout, "Key event: DOWN\n");
            break;
        case KEY_LEFT:
            fprintf(stdout, "Key event: LEFT\n");
            break;
    }
}

static int open_evdev(const char *dev_name)
{
    struct dirent **namelist;
    int i, ndev;
    int fd = -1;
    ndev = scandir(DEV_INPUT_EVENT, &namelist, is_event_device, versionsort);
    if (ndev <= 0)
        return ndev;
    
    for (i = 0; i < ndev; i++) {
        char fname[64];
        char name[256];
        
        snprintf(fname, sizeof(fname),
            "%s/%s", DEV_INPUT_EVENT, namelist[i]->d_name);
        fd = open(fname, O_RDONLY);
        
        if (fd < 0)
            continue;
        
        ioctl(fd, EVIOCGNAME(sizeof(name)), name);
        
        if (strcmp(dev_name, name) == 0)
            break;
        close(fd);
    }
    for (i = 0; i < ndev; i++)
        free(namelist[i]);
    return fd;
}

void handle_events(int evfd)
{
    struct input_event ev[64];
    int i, rd;
    rd = read(evfd, ev, sizeof(struct input_event) * 64);
    if (rd < (int) sizeof(struct input_event)) {
        fprintf(stderr, "expected %d bytes, got %d\n",
        (int) sizeof(struct input_event), rd);
        return;
    }
    change_dir(ev -> code);
}

int main()
{
    struct pollfd evpoll = {
		.events = POLLIN,
	};

	evpoll.fd = open_evdev("Raspberry Pi Sense HAT Joystick");
	if (evpoll.fd < 0) {
		fprintf(stderr, "Event device not found.\n");
		return evpoll.fd;
	}

    while(1){
        while (poll(&evpoll, 1, 0) > 0)
            handle_events(evpoll.fd);
        usleep (300000);
    }
}