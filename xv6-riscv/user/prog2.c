#include "kernel/types.h" 
#include "kernel/stat.h" 
#include "user/user.h" 

int FUNCTION_SETS_NUMBER_OF_TICKETS(int a)
{
	return a;
}
int main(int argc, char *argv[]) 
{ 
    int n = FUNCTION_SETS_NUMBER_OF_TICKETS(20);    // write your own function here
	settickets(n);
    int i,k; 
    const int loop=50000; // adjust this parameter depending on your system speed 
    for(i=0;i<loop;i++) 
    { 
        asm("nop");  // to prevent the compiler from optimizing the for-loop 
        for(k=0;k<loop;k++) 
        { 
           asm("nop"); 
        } 
    } 
    //sched_statistics(); // your syscall 
	schedstatistics(n,2);
    exit(0); 
} 