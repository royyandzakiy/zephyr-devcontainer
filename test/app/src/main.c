/*
 * Emulator smoke test. test/emu-smoke.sh greps for the banner and for
 * "tick 3": the ticks come from k_sleep, so they prove the timer, the
 * scheduler and the UART all keep running -- not just that the first printk
 * got out.
 */
#include <zephyr/kernel.h>

int main(void)
{
	printk("emu-smoke: boot ok on %s\n", CONFIG_BOARD_TARGET);

	for (int n = 1;; n++) {
		k_sleep(K_SECONDS(1));
		printk("emu-smoke: tick %d\n", n);
	}

	return 0;
}
