#define x_bound 4
#define y_bound 4
#define z_bound 4
#define N 5


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

/*Airplane attributes*/
	typedef location { byte ix;byte iy;byte iz};
	typedef direction {mtype x;mtype y;mtype z};
	typedef airplane_motion { location loc; direction dir};

/* Channel declaration*/
	chan query = [100] of {byte};
	chan reply[N] = [100] of {byte,location}; 	/* Each airplane has its own receive channel */

/*direction declaration*/
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


proctype airplane(chan receiveChan){ 	
airplane_motion plane_motion;
/*Identifying the direction for airplane to move */
	L1 :	if
		::plane_motion.dir.x=increment
		::plane_motion.dir.x=decrement
		::plane_motion.dir.x=none
		fi;

		if
		::plane_motion.dir.y=increment
		::plane_motion.dir.y=decrement
		::plane_motion.dir.y=none
		fi;

		if
		::plane_motion.dir.z=increment
		::plane_motion.dir.z=decrement
		::plane_motion.dir.z=none
		fi;

	if
	 	::(plane_motion.dir.x==none) && (plane_motion.dir.y==none) && (plane_motion.dir.z==none)-> goto L1
		::else -> skip
	fi;			

/*Initilising the position of airplane in airspace, provided there should not be any airplane assigned to that position already*/
	L2 :	randnum();
		plane_motion.loc.ix=randNo%x_bound;
		randnum();
		plane_motion.loc.iy=randNo%y_bound;
		randnum();
		plane_motion.loc.iz=randNo%z_bound;

	if
	 	::(coordinate.x[plane_motion.loc.ix].y[plane_motion.loc.iy].z[plane_motion.loc.iz] == 0) -> coordinate.x[plane_motion.loc.ix].y[plane_motion.loc.iy].z[plane_motion.loc.iz]=_pid; 
		::else -> goto L2
	fi;
	
/* Sending query and receive reply messages */
	byte query_id,received_id;
        location receivedPlane_loc;
	
	do
	:: 										 /*Movement of airplane in airspace based on direction*/
	:: query!_pid;									 /*Send the query message through query channel*/
	:: query?query_id;		 			 			 /*Read the query message from query channel*/
	:: (query_id!=0) && (query_id!=_pid) ->	reply[query_id-1]!_pid,plane_motion.loc  /*send a message containing pid, position of airplane via reply channel*/
	:: receiveChan?received_id,receivedPlane_loc;
	od;
	
}

init {
byte i;
	atomic {
		for(i : 0..(N-1)) {
			run airplane(reply[i]);
		}
	}
}


	
	



