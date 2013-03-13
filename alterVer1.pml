#define x_bound 6
#define y_bound 6
#define z_bound 6
#define NoOfAirplanes 3
#define kCells 3		/*No of cells to define RA & TA */

/* Airspace declartion */	/*A co-ordinate in the airspace can be accessed like x[1].y[0].z[4]*/
	typedef y_array {
		byte z[z_bound]
	};

	typedef x_array {
		y_array y[y_bound]
	};

	typedef position  {
	  x_array x[x_bound]  					
	};
	position coordinate;	

/* Direction declaration*/
	mtype = {increment, decrement, none, Climb, Maintain, Decend, Collision, Traffic};

/* Airplane attributes*/
	typedef location { int x;int y;int z};
	typedef direction {mtype x;mtype y;mtype z};
	typedef airplane_data { location loc; direction dir ; byte speed; byte id};
	byte it;

/* Channel declaration*/
	chan query = [1000] of {byte};
	chan reply[NoOfAirplanes] = [100] of {airplane_data}; 			/* Each airplane has its own receive channel */
	chan RAmessage[NoOfAirplanes] = [0] of {mtype};				/*synchronous channel for RA messages */
	chan TAmessage[NoOfAirplanes] = [0] of {mtype};				/*synchronous channel for TA messages */

/*Global variable to check if the other plane is dead*/
	bit dead[NoOfAirplanes];

/* To generate random number between 0- 255 to assing initial position of airplane */
	
	inline randnum()
	{
		do
		:: randNo++		
		:: (randNo>0) -> randNo--
		:: break	
		od;
	}	

/* Movement of airplane in airspace based on direction*/
	inline move_plane()
	{
	terminate_counter++;
	timer++;
	timer=timer%myPlane.speed;
	if
	:: (timer==0)->
		atomic {
		coordinate.x[myPlane.loc.x].y[myPlane.loc.y].z[myPlane.loc.z] = 0; /*clearing current position in airspace*/
		if
		::myPlane.dir.x == increment && myPlane.loc.x == (x_bound-1) -> myPlane.loc.x = 0
		::myPlane.dir.x == increment && myPlane.loc.x == (x_bound-1) -> myPlane.dir.x = decrement; myPlane.loc.x--		
		::myPlane.dir.x == decrement && myPlane.loc.x == 0 -> myPlane.loc.x = (x_bound-1)
		::myPlane.dir.x == decrement && myPlane.loc.x == 0 -> myPlane.dir.x = increment; myPlane.loc.x++
		::myPlane.dir.x == increment && myPlane.loc.x < (x_bound-1) -> myPlane.loc.x++ 
		::myPlane.dir.x == decrement && myPlane.loc.x > 0 -> myPlane.loc.x--
		::else -> skip
		fi;

		if
		::myPlane.dir.y == increment && myPlane.loc.y == (y_bound-1) -> myPlane.loc.y = 0
		::myPlane.dir.y == increment && myPlane.loc.y == (y_bound-1) -> myPlane.dir.y = decrement; myPlane.loc.y--		
		::myPlane.dir.y == decrement && myPlane.loc.y == 0 -> myPlane.loc.y = (y_bound-1)
		::myPlane.dir.y == decrement && myPlane.loc.y == 0 -> myPlane.dir.y = increment; myPlane.loc.y++
		::myPlane.dir.y == increment && myPlane.loc.y < (y_bound-1) -> myPlane.loc.y++ 
		::myPlane.dir.y == decrement && myPlane.loc.y > 0 -> myPlane.loc.y--
		::else -> skip
		fi;	

		if
		::myPlane.dir.z == increment && myPlane.loc.z == (z_bound-1) -> myPlane.loc.z = 0
		::myPlane.dir.z == increment && myPlane.loc.z == (z_bound-1) -> myPlane.dir.z = decrement; myPlane.loc.z--		
		::myPlane.dir.z == decrement && myPlane.loc.z == 0 -> myPlane.loc.z = (z_bound-1)
		::myPlane.dir.z == decrement && myPlane.loc.z == 0 -> myPlane.dir.z = increment; myPlane.loc.z++
		::myPlane.dir.z == increment && myPlane.loc.z < (z_bound-1) -> myPlane.loc.z++ 
		::myPlane.dir.z == decrement && myPlane.loc.z > 0 -> myPlane.loc.z--
		::else -> skip
		fi;

		if
		:: (coordinate.x[myPlane.loc.x].y[myPlane.loc.y].z[myPlane.loc.z] == 0) ->
			coordinate.x[myPlane.loc.x].y[myPlane.loc.y].z[myPlane.loc.z] = _pid; 	/*updating new position in airspace*/
		:: else -> /*If there is already a plane in the region when moved then planes collied */ 
			dead[_pid-1]=1;
		 	collidedPid = coordinate.x[myPlane.loc.x].y[myPlane.loc.y].z[myPlane.loc.z];
			RAmessage[collidedPid - 1]!Collision;
			break;
		fi;
		}
	::else->skip;
	fi;
	}



proctype airplane(chan receiveChan; chan RAmsg; chan TAmsg){ 	
byte terminate_counter;   /*Counter to terminate the process to make verification of model easier, as the airplanes are keep on moving infinitely */
terminate_counter = 0;
byte randNo;
airplane_data myPlane;
byte collidedPid;

	myPlane.id=_pid;

/* Identifying the speed for airplane to move*/
	byte i;
	//select (i : 1..3);
	myPlane.speed=3;

/* Identifying the direction for airplane to move */
L1 :	if
	::myPlane.dir.x=increment
	::myPlane.dir.x=decrement
	::myPlane.dir.x=none
	fi;

	if
	::myPlane.dir.y=increment
	::myPlane.dir.y=decrement
	::myPlane.dir.y=none
	fi;

	if
	::myPlane.dir.z=increment
	::myPlane.dir.z=decrement
	::myPlane.dir.z=none
	fi;

	if
 	::(myPlane.dir.x==none) && (myPlane.dir.y==none) && (myPlane.dir.z==none)-> goto L1
	::else -> skip
	fi;			

/* Initialising the position of airplane in airspace, provided there should not be any airplane assigned to that position already*/
L2 :	randnum();
	myPlane.loc.x=randNo%x_bound;
	randnum();
	myPlane.loc.y=randNo%y_bound;
	randnum();
	myPlane.loc.z=randNo%z_bound;

	if
 	::(coordinate.x[myPlane.loc.x].y[myPlane.loc.y].z[myPlane.loc.z] == 0) -> coordinate.x[myPlane.loc.x].y[myPlane.loc.y].z[myPlane.loc.z]=_pid; 
	::else -> goto L2
	fi;

/* Identifying the TA and RA region around the airplane based on the speed*/
	int RA,TA;
	RA=kCells/myPlane.speed;
	TA=(2*kCells)/myPlane.speed;	
	
/* Send query and receive reply */
	byte query_id, timer;
	airplane_data receivedPlane;
	mtype decision;
	location RA1_start,RA1_end,RA2_start,RA2_end;
	location TA1_start,TA1_end,TA2_start,TA2_end;
	bit xRA, yRA, zRA, xTA, yTA, zTA, receivedPlaneRA, receivedPlaneTA;

L3:	do												 
	::query!_pid;					 /*Send the query message through query channel*/
	  move_plane();	
									 
	::query?query_id;		  			 /*Read the query message from query channel*/
	  if
	  ::query_id!=_pid -> reply[query_id-1]!myPlane;
	  ::else					      				 /*send a reply message via reply channel*/
	  fi;	  
	  move_plane();

	::receiveChan?receivedPlane;			 /*read a reply message via reply channel*/

	/*Identifying RA1 region around my plane. RA1 and RA2 'start and end' represents the boundaries of RA region on either side of my plane*/
	  
		RA1_start.x =myPlane.loc.x+1;
		RA1_end.x = myPlane.loc.x+RA;
		RA1_start.y =myPlane.loc.y+1;
		RA1_end.y = myPlane.loc.y+RA;
		RA1_start.z =myPlane.loc.z+1;
		RA1_end.z = myPlane.loc.z+RA;
		do
		::RA1_start.x >= x_bound -> RA1_start.x = RA1_start.x - x_bound;
		::RA1_start.y >= y_bound -> RA1_start.y = RA1_start.y - y_bound;
		::RA1_start.z >= z_bound -> RA1_start.z = RA1_start.z - z_bound;
		::RA1_end.x >= x_bound -> RA1_end.x = RA1_end.x - x_bound;
		::RA1_end.y >= y_bound -> RA1_end.y = RA1_end.y - y_bound;
		::RA1_end.z >= z_bound -> RA1_end.z = RA1_end.z - z_bound;
		::RA1_start.x<x_bound && RA1_start.y<y_bound && RA1_start.z<z_bound && RA1_end.x<x_bound && RA1_end.y<y_bound && RA1_end.z<z_bound -> break
		od;
	
	  /* Identifying RA2 region around the plane*/
		RA2_start.x =(myPlane.loc.x-1);
		RA2_end.x = (myPlane.loc.x-RA);
		RA2_start.y =(myPlane.loc.y-1);
		RA2_end.y = (myPlane.loc.y-RA);
		RA2_start.z =(myPlane.loc.z-1);
		RA2_end.z = (myPlane.loc.z-RA);
		do
		::RA2_start.x < 0 -> RA2_start.x = RA2_start.x + x_bound;
		::RA2_start.y < 0 -> RA2_start.y = RA2_start.y + y_bound;
		::RA2_start.z < 0 -> RA2_start.z = RA2_start.z + z_bound;
		::RA2_end.x < 0 -> RA2_end.x = RA2_end.x + x_bound;
		::RA2_end.y < 0 -> RA2_end.y = RA2_end.y + y_bound;
		::RA2_end.z < 0 -> RA2_end.z = RA2_end.z + z_bound;
		::RA2_start.x>=0 && RA2_start.y>=0 && RA2_start.z>=0 && RA2_end.x>=0 && RA2_end.y>=0 && RA2_end.z>=0 -> break
		od;
	
	/* Identifying TA1 region around the plane*/
	
		TA1_start.x=RA1_end.x+1;
		TA1_end.x=RA1_end.x+(TA-RA);
		TA1_start.y=RA1_end.y+1;
		TA1_end.y=RA1_end.y+(TA-RA);
		TA1_start.z=RA1_end.z+1;
		TA1_end.z=RA1_end.z+(TA-RA);
		do
		::TA1_start.x >= x_bound -> TA1_start.x = TA1_start.x - x_bound;
		::TA1_start.y >= y_bound -> TA1_start.y = TA1_start.y - y_bound;
		::TA1_start.z >= z_bound -> TA1_start.z = TA1_start.z - z_bound;
		::TA1_end.x >= x_bound -> TA1_end.x = TA1_end.x - x_bound;
		::TA1_end.y >= y_bound -> TA1_end.y = TA1_end.y - y_bound;
		::TA1_end.z >= z_bound -> TA1_end.z = TA1_end.z - z_bound;
		::TA1_start.x<x_bound && TA1_start.y<y_bound && TA1_start.z<z_bound && TA1_end.x<x_bound && TA1_end.y<y_bound && TA1_end.z<z_bound -> break
		od;
		
		
	/* Identifying TA2 region around the plane*/
		TA2_start.x=RA2_end.x-1;
		TA2_end.x=RA2_end.x-(TA-RA);
		TA2_start.y=RA2_end.y-1;
		TA2_end.y=RA2_end.y-(TA-RA);
		TA2_start.z=RA2_end.z-1;
		TA2_end.z=RA2_end.z-(TA-RA);
		do
		::TA2_start.x < 0 -> TA2_start.x = TA2_start.x + x_bound;
		::TA2_start.y < 0 -> TA2_start.y = TA2_start.y + y_bound;
		::TA2_start.z < 0 -> TA2_start.z = TA2_start.z + z_bound;
		::TA2_end.x < 0 -> TA2_end.x = TA2_end.x + x_bound;
		::TA2_end.y < 0 -> TA2_end.y = TA2_end.y + y_bound;
		::TA2_end.z < 0 -> TA2_end.z = TA2_end.z + z_bound;
		::TA2_start.x>=0 && TA2_start.y>=0 && TA2_start.z>=0 && TA2_end.x>=0 && TA2_end.y>=0 && TA2_end.z>=0 -> break
		od;
		
	/*Identifying if the reply message from received plane is in RA region*/

		
		int RArecvlocx= ((receivedPlane.loc.x < RA2_end.x) -> (receivedPlane.loc.x + x_bound) : (receivedPlane.loc.x));
		int RArecvlocy= ((receivedPlane.loc.y < RA2_end.y) -> (receivedPlane.loc.y + y_bound) : (receivedPlane.loc.y));
		int RArecvlocz= ((receivedPlane.loc.z < RA2_end.z) -> (receivedPlane.loc.z + z_bound) : (receivedPlane.loc.z));
		if
		::((RA2_end.x > RA1_end.x) && (RA2_end.x <= RArecvlocx) && (RArecvlocx <= RA1_end.x + x_bound)) -> xRA = 1;
		::((RA2_end.x < RA1_end.x) && (RA2_end.x <= receivedPlane.loc.x) && (receivedPlane.loc.x <= RA1_end.x)) -> xRA = 1;		
		::((RA2_end.x == RA1_end.x) && (RA2_end.x == receivedPlane.loc.x)) -> xRA = 1;
		::else -> xRA = 0;
		fi;

		if
		::((RA2_end.y > RA1_end.y) && (RA2_end.y <= RArecvlocy) && (RArecvlocy <= RA1_end.y + y_bound)) -> yRA = 1;
		::((RA2_end.y < RA1_end.y) && (RA2_end.y <= receivedPlane.loc.y) && (receivedPlane.loc.y <= RA1_end.y)) -> yRA = 1;		
		::((RA2_end.y == RA1_end.y) && (RA2_end.y == receivedPlane.loc.y)) -> yRA = 1;
		::else -> yRA = 0;
		fi;
		
		if
		::((RA2_end.z > RA1_end.z) && (RA2_end.z <= RArecvlocz) && (RArecvlocz <= RA1_end.z + z_bound)) -> zRA = 1;
		::((RA2_end.z < RA1_end.z) && (RA2_end.z <= receivedPlane.loc.z) && (receivedPlane.loc.z <= RA1_end.z)) -> zRA = 1;		
		::((RA2_end.z == RA1_end.z) && (RA2_end.z == receivedPlane.loc.z)) -> zRA = 1;
		::else -> zRA = 0;
		fi;

		receivedPlaneRA = 0;
		receivedPlaneTA = 0;
		decision = 0;
		if
		::xRA == 1 && yRA == 1 && zRA == 1 -> decision = Climb;
		  receivedPlaneRA = 1;
		::xRA == 1 && yRA == 1 && zRA == 1 -> decision = Decend;
		  receivedPlaneRA = 1;
		::xRA == 1 && yRA == 1 && zRA == 1 -> decision = Maintain;
		  receivedPlaneRA = 1;
		    
		:: else -> 
			/*Identifying if the reply message received plane is in TA region*/
			int TArecvlocx= ((receivedPlane.loc.x < TA2_end.x) -> (receivedPlane.loc.x + x_bound) : (receivedPlane.loc.x));
			int TArecvlocy= ((receivedPlane.loc.y < TA2_end.y) -> (receivedPlane.loc.y + y_bound) : (receivedPlane.loc.y));
			int TArecvlocz= ((receivedPlane.loc.z < TA2_end.z) -> (receivedPlane.loc.z + z_bound) : (receivedPlane.loc.z));
			if
			::((TA2_end.x > TA1_end.x) && (TA2_end.x <= TArecvlocx) && (TArecvlocx <= TA1_end.x + x_bound)) -> xTA = 1;
			::((TA2_end.x < TA1_end.x) && (TA2_end.x <= receivedPlane.loc.x) && (receivedPlane.loc.x <= TA1_end.x)) -> xTA = 1;		
			::((TA2_end.x == TA1_end.x) && (TA2_end.x == receivedPlane.loc.x)) -> xTA = 1;
			::else -> xTA = 0;
			fi;

			if
			::((TA2_end.y > TA1_end.y) && (TA2_end.y <= TArecvlocy) && (TArecvlocy <= TA1_end.y + y_bound)) -> yTA = 1;
			::((TA2_end.y < TA1_end.y) && (TA2_end.y <= receivedPlane.loc.y) && (receivedPlane.loc.y <= TA1_end.y)) -> yTA = 1;		
			::((TA2_end.y == TA1_end.y) && (TA2_end.y == receivedPlane.loc.y)) -> yTA = 1;
			::else -> yTA = 0;
			fi;
		
			if
			::((TA2_end.z > TA1_end.z) && (TA2_end.z <= TArecvlocz) && (TArecvlocz <= TA1_end.z + z_bound)) -> zTA = 1;
			::((TA2_end.z < TA1_end.z) && (TA2_end.z <= receivedPlane.loc.z) && (receivedPlane.loc.z <= TA1_end.z)) -> zTA = 1;		
			::((TA2_end.z == TA1_end.z) && (TA2_end.z == receivedPlane.loc.z)) -> zTA = 1;
			::else -> zTA = 0;
			fi;

			if
			::(xTA == 1 && yTA == 1 && zTA == 1) -> receivedPlaneTA = 1;
			::else -> receivedPlaneTA = 0;
			fi;
		fi;
		move_plane();
			
	od unless{
		if	/*Send RA and TA msg only if the otherplane is alive*/
		:: (receivedPlaneRA == 1 && dead[receivedPlane.id-1]==0) -> RAmessage[receivedPlane.id-1]!decision;
		   if
			::decision == Climb -> myPlane.dir.z=increment;
			::decision == Decend -> myPlane.dir.z=decrement;
			::else
		   fi;
		   receivedPlaneRA = 0;
		   move_plane();
		   goto L3
		   
		:: (receivedPlaneTA == 1 && dead[receivedPlane.id-1]==0) -> TAmessage[receivedPlane.id-1]!Traffic;
		   receivedPlaneTA = 0;
		   move_plane();
		   goto L3
	
		::RAmsg?Climb;
		  myPlane.dir.z=decrement;
		  move_plane();
		  goto L3

		::RAmsg?Decend;
		  myPlane.dir.z=increment;
		  move_plane();
		  goto L3

		::RAmsg?Maintain;
		  move_plane();
		  goto L3

		::TAmsg?Traffic;
		  move_plane();
		  goto L3

		::RAmsg?Collision;
		  coordinate.x[myPlane.loc.x].y[myPlane.loc.y].z[myPlane.loc.z]=0;
		  dead[_pid-1]=1;

		::(terminate_counter >= (2*(x_bound + y_bound + z_bound))) -> skip;
		  dead[_pid-1]=1;

		fi;

		};

}

init {
byte i;
	atomic {
		for(i : 0..(NoOfAirplanes-1)) {
			run airplane(reply[i], RAmessage[i], TAmessage[i]);
		}
	}
}


	
	



