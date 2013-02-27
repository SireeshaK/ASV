#define x_bound 10
#define y_bound 10
#define z_bound 10
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
	typedef location { byte ix;byte iy;byte iz};
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
		coordinate.x[myPlane.loc.ix].y[myPlane.loc.iy].z[myPlane.loc.iz] = 0; /*clearing current position in airspace*/
		atomic{
		if
		::myPlane.dir.x == increment && myPlane.loc.ix == (x_bound-1) -> myPlane.loc.ix = 0
		::myPlane.dir.x == increment && myPlane.loc.ix == (x_bound-1) -> myPlane.dir.x = decrement; myPlane.loc.ix--		
		::myPlane.dir.x == decrement && myPlane.loc.ix == 0 -> myPlane.loc.ix = (x_bound-1)
		::myPlane.dir.x == decrement && myPlane.loc.ix == 0 -> myPlane.dir.x = increment; myPlane.loc.ix++
		::myPlane.dir.x == increment && myPlane.loc.ix < (x_bound-1) -> myPlane.loc.ix++ 
		::myPlane.dir.x == decrement && myPlane.loc.ix > 0 -> myPlane.loc.ix--
		::else -> skip
		fi;

		if
		::myPlane.dir.y == increment && myPlane.loc.iy == (y_bound-1) -> myPlane.loc.iy = 0
		::myPlane.dir.y == increment && myPlane.loc.iy == (y_bound-1) -> myPlane.dir.y = decrement; myPlane.loc.iy--		
		::myPlane.dir.y == decrement && myPlane.loc.iy == 0 -> myPlane.loc.iy = (y_bound-1)
		::myPlane.dir.y == decrement && myPlane.loc.iy == 0 -> myPlane.dir.y = increment; myPlane.loc.iy++
		::myPlane.dir.y == increment && myPlane.loc.iy < (y_bound-1) -> myPlane.loc.iy++ 
		::myPlane.dir.y == decrement && myPlane.loc.iy > 0 -> myPlane.loc.iy--
		::else -> skip
		fi;	

		if
		::myPlane.dir.z == increment && myPlane.loc.iz == (z_bound-1) -> myPlane.loc.iz = 0
		::myPlane.dir.z == increment && myPlane.loc.iz == (z_bound-1) -> myPlane.dir.z = decrement; myPlane.loc.iz--		
		::myPlane.dir.z == decrement && myPlane.loc.iz == 0 -> myPlane.loc.iz = (z_bound-1)
		::myPlane.dir.z == decrement && myPlane.loc.iz == 0 -> myPlane.dir.z = increment; myPlane.loc.iz++
		::myPlane.dir.z == increment && myPlane.loc.iz < (z_bound-1) -> myPlane.loc.iz++ 
		::myPlane.dir.z == decrement && myPlane.loc.iz > 0 -> myPlane.loc.iz--
		::else -> skip
		fi;	
		coordinate.x[myPlane.loc.ix].y[myPlane.loc.iy].z[myPlane.loc.iz] = _pid; /*updating new position in airspace*/
		}
	::else->skip;
	fi;
	}

proctype airplane(chan receiveChan){ 	
airplane_motion myPlane;
/* Identifying the speed for airplane to move*/
	byte airplane_speed;
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
		myPlane.loc.ix=randNo%x_bound;
		randnum();
		myPlane.loc.iy=randNo%y_bound;
		randnum();
		myPlane.loc.iz=randNo%z_bound;

	if
	 	::(coordinate.x[myPlane.loc.ix].y[myPlane.loc.iy].z[myPlane.loc.iz] == 0) -> coordinate.x[myPlane.loc.ix].y[myPlane.loc.iy].z[myPlane.loc.iz]=_pid; 
		::else -> goto L2
	fi;
/* Identifying the TA and RA region around the airplane based on the speed*/
	byte RA,TA;
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
	   move_plane();
	od;
	
}

init {
byte i;
	atomic {
		for(i : 0..(NoOfAirplanes-1)) {
			run airplane(reply[i]);
		}
	}
}


	
	



