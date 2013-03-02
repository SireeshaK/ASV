#define x_bound 15
#define y_bound 15
#define z_bound 15
#define NoOfAirplanes 5
#define kCells 3	


/* Airspace declartion */
	typedef y_array {
		byte z[z_bound]
	};

	typedef x_array {
		y_array y[y_bound]
	};

	typedef position  {
	  x_array x[x_bound]  					/*A co-ordinate in the airspace can be accessed like x[1].y[0].z[4]*/
	};
	position coordinate;

/* Airplane attributes*/
	typedef location { int x;int y;int z};
	typedef direction {mtype x;mtype y;mtype z};
	typedef airplane_motion { location loc; direction dir};

/* Channel declaration*/
	chan query = [100] of {byte};
	chan reply[NoOfAirplanes] = [100] of {byte,location}; 		/* Each airplane has its own receive channel */

/* Direction declaration*/
	mtype = {increment,decrement, none}
	
/* To generate random number between 0- 255 */
	byte randNo;
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
	 timer++;
	   timer=timer%airplane_speed;
	   if
	   :: (timer==0)->
		coordinate.x[myPlane.loc.x].y[myPlane.loc.y].z[myPlane.loc.z] = 0; /*clearing current position in airspace*/
		atomic{
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
		:: (coordinate.x[myPlane.loc.x].y[myPlane.loc.y].z[myPlane.loc.z]==0) ->
		coordinate.x[myPlane.loc.x].y[myPlane.loc.y].z[myPlane.loc.z] = _pid; /*updating new position in airspace*/
		:: else -> collisionOccured = 1;
		fi;
		}
	::else->skip;
	fi;
	}

proctype airplane(chan receiveChan){ 	
airplane_motion myPlane;
bit collisionOccured = 0;
/* Identifying the speed for airplane to move*/
	int airplane_speed;
	select(airplane_speed : 1..3);

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

/* Initilising the position of airplane in airspace, provided there should not be any airplane assigned to that position already*/
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
	RA=kCells/airplane_speed;
	TA=(2*kCells)/airplane_speed;	
	
/* Sending query and receive reply messages */
	byte query_id,received_id;
        location receivedPlane_loc;
	byte timer;
	
	do												 
	:: query!_pid;									 /*Send the query message through query channel*/
	   move_plane();										 
	:: query?query_id;		 			 			 /*Read the query message from query channel*/
	   move_plane();
	:: (query_id!=0) && (query_id!=_pid) ->	reply[query_id-1]!_pid,myPlane.loc;      /*send a reply message via reply channel*/
	   move_plane();
	:: receiveChan?received_id,receivedPlane_loc;					 /*read a reply message via reply channel*/

		
/* Identifying RA1 region around the plane*/
	location RA1_start,RA1_end,RA2_start,RA2_end;
		if
		::(myPlane.loc.x+RA > x_bound-1) ->
			if
			::(myPlane.loc.x == x_bound-1) ->
				RA1_start.x =((myPlane.loc.x+RA)%(x_bound-1)) - RA;
				RA1_end.x = ((myPlane.loc.x+RA)%(x_bound-1)) - 1;
			::else ->
				RA1_start.x = myPlane.loc.x +1;
				RA1_end.x = ((myPlane.loc.x+RA)%(x_bound-1)) - 1;
			fi;
		:: else ->
				RA1_start.x = myPlane.loc.x +1;
				RA1_end.x = myPlane.loc.x +RA;
		fi;

		if
		::(myPlane.loc.y+RA > y_bound-1) ->
			if
			::(myPlane.loc.y == y_bound-1) ->
				RA1_start.y = ((myPlane.loc.y+RA)%(y_bound-1)) - RA;
				RA1_end.y = ((myPlane.loc.y+RA)%(y_bound-1)) - 1;
			::else ->
				RA1_start.y = myPlane.loc.y +1;
				RA1_end.y = ((myPlane.loc.y+RA)%(y_bound-1)) - 1;
			fi;
		:: else ->
				RA1_start.y = myPlane.loc.y +1;
				RA1_end.y = myPlane.loc.y +RA;
		fi;

		if
		::(myPlane.loc.z+RA > z_bound-1) ->
			if
			::(myPlane.loc.z == z_bound-1) ->
				RA1_start.z = ((myPlane.loc.z+RA)%(z_bound-1)) - RA;
				RA1_end.z = ((myPlane.loc.z+RA)%(z_bound-1)) - 1;
			::else ->
				RA1_start.z = myPlane.loc.z +1;
				RA1_end.z = ((myPlane.loc.z+RA)%(z_bound-1)) - 1;
			fi;
		:: else ->
				RA1_start.z = myPlane.loc.z +1;
				RA1_end.z = myPlane.loc.z +RA;
		fi;

/* Identifying RA2 region around the plane*/
		if
		::(myPlane.loc.x-RA < 0 ) ->
			if
			::(myPlane.loc.x == 0) ->
				RA2_start.x = myPlane.loc.x+(x_bound-1);
				RA2_end.x = (myPlane.loc.x+(x_bound-1))-(RA-1);
			::else ->
				RA2_start.x = myPlane.loc.x -1;
				RA2_end.x = (myPlane.loc.x+(x_bound-1))-(RA-1);
			fi;
		:: else ->
				RA2_start.x = myPlane.loc.x -1;
				RA2_end.x = myPlane.loc.x -RA;
		fi;

		if
		::(myPlane.loc.y-RA < 0 ) ->
			if
			::(myPlane.loc.y == 0) ->
				RA2_start.y = myPlane.loc.y+(y_bound-1);
				RA2_end.y = (myPlane.loc.y+(y_bound-1))-(RA-1);
			::else ->
				RA2_start.y = myPlane.loc.y -1;
				RA2_end.y = (myPlane.loc.y+(y_bound-1))-(RA-1);
			fi;
		:: else ->
				RA2_start.y = myPlane.loc.y -1;
				RA2_end.y = myPlane.loc.y -RA;
		fi;

		if
		::(myPlane.loc.z-RA < 0 ) ->
			if
			::(myPlane.loc.z == 0) ->
				RA2_start.z = myPlane.loc.z+(z_bound-1);
				RA2_end.z = (myPlane.loc.z+(z_bound-1))-(RA-1);
			::else ->
				RA2_start.z = myPlane.loc.z -1;
				RA2_end.z = (myPlane.loc.z+(z_bound-1))-(RA-1);
			fi;
		:: else ->
				RA2_start.z = myPlane.loc.z -1;
				RA2_end.z = myPlane.loc.z -RA;
		fi;

	
		
/* Identifying TA1 region around the plane*/
	location TA1_start,TA1_end,TA2_start,TA2_end;
		
		TA1_start.x=(RA1_end.x+1);
		TA1_end.x=(RA1_end.x+(TA-RA));
		if
		:: (TA1_start.x>x_bound-1) -> TA1_start.x=(TA1_start.x-x_bound);
		:: else-> 	skip;
		fi;
		if
		:: (TA1_end.x>x_bound-1) -> TA1_end.x=(TA1_end.x-x_bound);
		:: else -> skip;
		fi;

		TA1_start.y=(RA1_end.y+1);
		TA1_end.y=(RA1_end.y+(TA-RA));
		if
		:: (TA1_start.y>y_bound-1) -> TA1_start.y=(TA1_start.y-y_bound);
		:: else-> 	skip;
		fi;
		if
		:: (TA1_end.y>y_bound-1) -> TA1_end.y=(TA1_end.y-y_bound);
		:: else -> skip;
		fi;

		TA1_start.z=(RA1_end.z+1);
		TA1_end.z=(RA1_end.z+(TA-RA));
		if
		:: (TA1_start.z>z_bound-1) -> TA1_start.z=(TA1_start.z-z_bound);
		:: else-> 	skip;
		fi;
		if
		:: (TA1_end.z>z_bound-1) -> TA1_end.z=(TA1_end.z-z_bound);
		:: else -> skip;
		fi;
		
/* Identifying TA2 region around the plane*/

		TA2_start.x=(RA2_end.x-1);
		TA2_end.x=(RA2_end.x-(TA-RA));
		if
		:: (TA2_start.x<0) -> TA2_start.x=(TA2_start.x+x_bound);
		:: else-> 	skip;
		fi;
		if
		:: (TA2_end.x<0) -> TA2_end.x=(TA2_end.x+x_bound);
		:: else -> skip;
		fi;

		TA2_start.y=(RA2_end.y-1);
		TA2_end.y=(RA2_end.y-(TA-RA));
		if
		:: (TA2_start.y<0) -> TA2_start.y=(TA2_start.y+y_bound);
		:: else-> 	skip;
		fi;
		if
		:: (TA2_end.y<0) -> TA2_end.y=(TA2_end.y+y_bound);
		:: else -> skip;
		fi;

		TA2_start.z=(RA2_end.z-1);
		TA2_end.z=(RA2_end.z-(TA-RA));
		if
		:: (TA2_start.z<0) -> TA2_start.z=(TA2_start.z+z_bound);
		:: else-> skip;
		fi;
		if
		:: (TA2_end.z<0) -> TA2_end.z=(TA2_end.z+z_bound);
		:: else -> skip;
		fi;
		
/*Identifying if the reply message received plane is in RA region*/
/*Identifying if the reply message received plane is in TA region*/

		bit xRA, yRA, zRA, xTA, yTA, zTA, receivedPlaneRA, receivedPlaneTA;
		int RArecvlocx= ((receivedPlane_loc.x < RA2_end.x) -> (receivedPlane_loc.x + x_bound) : (receivedPlane_loc.x));
		int RArecvlocy= ((receivedPlane_loc.y < RA2_end.y) -> (receivedPlane_loc.y + y_bound) : (receivedPlane_loc.y));
		int RArecvlocz= ((receivedPlane_loc.z < RA2_end.z) -> (receivedPlane_loc.z + z_bound) : (receivedPlane_loc.z));
		if
		::((RA2_end.x > RA1_end.x) && (RA2_end.x <= RArecvlocx) && (RArecvlocx <= RA1_end.x + x_bound)) -> xRA = 1;
		::((RA2_end.x < RA1_end.x) && (RA2_end.x <= receivedPlane_loc.x) && (receivedPlane_loc.x <= RA1_end.x)) -> xRA = 1;		
		::((RA2_end.x == RA1_end.x) && (RA2_end.x == receivedPlane_loc.x)) -> xRA = 1;
		::else -> xRA = 0;
		fi;

		if
		::((RA2_end.y > RA1_end.y) && (RA2_end.y <= RArecvlocy) && (RArecvlocy <= RA1_end.y + y_bound)) -> yRA = 1;
		::((RA2_end.y < RA1_end.y) && (RA2_end.y <= receivedPlane_loc.y) && (receivedPlane_loc.y <= RA1_end.y)) -> yRA = 1;		
		::((RA2_end.y == RA1_end.y) && (RA2_end.y == receivedPlane_loc.y)) -> yRA = 1;
		::else -> yRA = 0;
		fi;
		
		if
		::((RA2_end.z > RA1_end.z) && (RA2_end.z <= RArecvlocz) && (RArecvlocz <= RA1_end.z + z_bound)) -> zRA = 1;
		::((RA2_end.z < RA1_end.z) && (RA2_end.z <= receivedPlane_loc.z) && (receivedPlane_loc.z <= RA1_end.z)) -> zRA = 1;		
		::((RA2_end.z == RA1_end.z) && (RA2_end.z == receivedPlane_loc.z)) -> zRA = 1;
		::else -> zRA = 0;
		fi;

		if
		::xRA == 1 && yRA == 1 && zRA == 1 -> receivedPlaneRA = 1;
		:: else -> 
			int TArecvlocx= ((receivedPlane_loc.x < TA2_end.x) -> (receivedPlane_loc.x + x_bound) : (receivedPlane_loc.x));
			int TArecvlocy= ((receivedPlane_loc.y < TA2_end.y) -> (receivedPlane_loc.y + y_bound) : (receivedPlane_loc.y));
			int TArecvlocz= ((receivedPlane_loc.z < TA2_end.z) -> (receivedPlane_loc.z + z_bound) : (receivedPlane_loc.z));
			if
			::((TA2_end.x > TA1_end.x) && (TA2_end.x <= TArecvlocx) && (TArecvlocx <= TA1_end.x + x_bound)) -> xTA = 1;
			::((TA2_end.x < TA1_end.x) && (TA2_end.x <= receivedPlane_loc.x) && (receivedPlane_loc.x <= TA1_end.x)) -> xTA = 1;		
			::((TA2_end.x == TA1_end.x) && (TA2_end.x == receivedPlane_loc.x)) -> xTA = 1;
			::else -> xTA = 0;
			fi;

			if
			::((TA2_end.y > TA1_end.y) && (TA2_end.y <= TArecvlocy) && (TArecvlocy <= TA1_end.y + y_bound)) -> yTA = 1;
			::((TA2_end.y < TA1_end.y) && (TA2_end.y <= receivedPlane_loc.y) && (receivedPlane_loc.y <= TA1_end.y)) -> yTA = 1;		
			::((TA2_end.y == TA1_end.y) && (TA2_end.y == receivedPlane_loc.y)) -> yTA = 1;
			::else -> yTA = 0;
			fi;
		
			if
			::((TA2_end.z > TA1_end.z) && (TA2_end.z <= TArecvlocz) && (TArecvlocz <= TA1_end.z + z_bound)) -> zTA = 1;
			::((TA2_end.z < TA1_end.z) && (TA2_end.z <= receivedPlane_loc.z) && (receivedPlane_loc.z <= TA1_end.z)) -> zTA = 1;		
			::((TA2_end.z == TA1_end.z) && (TA2_end.z == receivedPlane_loc.z)) -> zTA = 1;
			::else -> zTA = 0;
			fi;


			xTA == 1 && yTA == 1 && zTA == 1 -> receivedPlaneTA = 1;
		fi;
		move_plane();
				
	od unless {collisionOccured == 1 -> skip};
	
}

init {
byte i;
	atomic {
		for(i : 0..(NoOfAirplanes-1)) {
			run airplane(reply[i]);
		}
	}
}


	
	



