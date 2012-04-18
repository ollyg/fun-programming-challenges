#include <stdio.h>
#include <stdlib.h> 
#include <math.h>

/* Project 1 */
/* Create two points on a 100x100 grid and have one (UAV) home in on the other
 * (target) */

int place_entity(int limit);
int move_closer(int location, int target);

int main() {

 int range_x = 100;
 int range_y = 100;

 printf("STARTING: Map is %d by %d\n",range_x,range_y);
 
 int uav_x = place_entity( range_x );
 int uav_y = place_entity( range_y );
 int target_x = place_entity( range_x );
 int target_y = place_entity( range_y );

 printf("STARTING: UAV starts at %d,%d \n", uav_x, uav_y);
 printf("STARTING: target starts at %d,%d \n", target_x, target_y );

 while ( uav_x != target_x || uav_y != target_y ) {
    int x_diff = abs( uav_x - target_x );
    int y_diff = abs( uav_y - target_y );

    if ( x_diff > y_diff ) {
        uav_x = move_closer( uav_x, target_x );
    }
    else {
        uav_y = move_closer( uav_y, target_y );
    }
    printf( "MOVE: UAV moves to %d,%d \n", uav_x, uav_y );
 
 }

 printf( "FINISH: UAV at %d,%d target at %d,%d \n", uav_x,uav_y,target_x,target_y );

 return( 0 );
}



/* FUNCTIONS */
int place_entity(int limit) {
    /* Create a pseudo random starting position within the limits provided */
    int position = ( rand() % ( limit - 0 + 1) + 0) ;

    return( position );
}

int move_closer(int location, int target){
   /* Return UAV coordinates closer to the target */

   /* If the Absolute Value (abs) of the result of one coordinate minus the other is
      the same as the result by itself, we know the answer is positive, which means
      the UAV is at a higher coordinate number and needs to be reduce to move
      closer. */

   /* Conversely if this is not true then the UAV is at a lower coordinate number
      which needs to be raised to move closer. */

    int result = location - target;

    if ( result == abs( result ) ) {
        location--;
    }
    else {
        location++;
    }

    return( location );
}

