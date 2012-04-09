-- Project 1
-- Create two points on a 100x100 grid and have one (UAV) home in on the other
-- (target)

--FIXME: this is a work in progress, it doesn't compile currently
-- It's my first Ada program, I'm working on it

with Ada.Text_IO;
use Ada.Text_IO;
with ada.numerics.discrete_random;
use ada.numerics.discrete_random;

procedure project2 is

begin

-- define area as 100 x 100 y
   limit_x : constant Integer := 100;
   limit_y : constant Integer := 100;

-- uav and target location will always be within that area
   uav_x    : Integer range 0 .. limit_x;
   uav_y    : Integer range 0 .. limit_y;
   target_x : Integer range 0 .. limit_x;
   target_y : Integer range 0 .. limit_y;

-- as will be the difference between the points
   x_diff : Integer range 0 .. limit_x;
   y_diff : Integer range 0 .. limit_y;

-- then place the entities on the map
   uav_x    := place_entity( limit_x );
   uav_y    := place_entity( limit_y );
   target_x := place_entity( limit_x );
   target_y := place_entity( limit_y );

Move_Loop :
   -- exit when the positions are identical
   while uav_x /= target_x and then uav_y /= target_y loop
  
   -- Move the UAV one coordinate closer to the target
   -- check difference of x and y values from uav to target
   x_diff := abs uav_x - target_x;
   y_diff := abs uav_y - target_y;

   -- is x or y difference largest?
   difference := x_diff - y_diff;
   
   -- make the largest number one number less (move closer)
   if ( x_diff > y_diff ) then
       -- x value difference is larger
       uav_x := move_closer( uav_x, target_x );
   else
       -- y value difference is larger
       uav_y := move_closer( uav_y, target_y );
   end if;

   -- print the position of the uav
   -- print the position of the target
   Put_Line ("Uav is at uav_x,uav_y Target is at target_x,target_y");
   
   end loop Move_Loop;
 
Put_Line ("FINISH: UAV at uav_x,uav_y Target at target_x,target_y");


-- functions
function place_entity ( limit : in Integer ) return integer is
    -- Create a pseudo random starting position within the limits provided
    subtype position is Integer;

    begin
    position := ( rand() % ( limit - 0 + 1) + 0) ;
    return position ;
end place_entity;

function move_closer( ) return integer is
   -- Return UAV coordinates closer to the target
   
   -- If the Absolute Value (abs) of the result of one coordinate minus the
   -- other is the same as the result by itself, we know the answer is
   -- positive, which means the UAV is at a higher coordinate number and needs
   -- to be reduce to move closer.

   -- Conversely if this is not true then the UAV is at a lower coordinate
   -- number which needs to be raised to move closer.
    
    type result is Integer;
    result := location - target;

    if ( result = abs( result ) ) then
        location--;
    else
        location++;
    end if;

    return location ;

end move_closer;

end project2;
