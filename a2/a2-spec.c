long long factorial(long long n) {
	if (n == 1)
		return 1;

	return n * factorial(n - 1);
}

#include "stdio.h"

int main() {
	long long res = factorial(5);
	printf("%lld\n", res);
}
