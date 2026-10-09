obj-m += rife.o

all:
	make -C /lib/modules/$(shell uname -r)/build M=$(PWD) modules

clean:
	make -C /lib/modules/$(shell uname -r)/build M=$(PWD) clean

load: all
	/opt/snowcrash/bonus05/load_rife.sh $(PWD)/rife.ko
	cat /proc/rife
