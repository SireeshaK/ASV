#define x_bound 4
#define y_bound 4
#define z_bound 4
#define N 5


/* Airspace declartion. A co-ordinate in the airspace can be accessed like x[1].y[0].z[4] */
typedef y_array {
	byte z[z_bound]
};

typedef x_array {
	y_array y[y_bound]
};

typedef position  {
  x_array x[x_bound]  /*x, y, z */
};

chan query = [100] of {byte};
chan reply[N] = [100] of {byte,byte,byte,byte}; 


/* To generate random number between 0- 255 */
inline randnum()
	{
	do
	:: randNo++		
	:: (randNo>0) -> randNo--
	:: break	
	od;
	}	
position coordinate;

proctype airplane(chan receiveChan){ 	/* Each airplane has its own receive channel */

/*Initilising the position of airplane in airspace, provided there should not be any airplane assigned to that position already*/
	byte ix,iy,iz;
	byte randNo;	
	L1 :	randnum();
		ix=randNo%x_bound;
		randnum();
		iy=randNo%y_bound;
		randnum();
		iz=randNo%z_bound;

	if
	 	::(coordinate.x[ix].y[iy].z[iz] == 0) -> coordinate.x[ix].y[iy].z[iz]=_pid; 
		::else -> goto L1
	fi;
	
/* Sending query and receive reply messages */
	byte query_id,receive_id,receive_x,receive_y,receive_z;
	
	do
	:: query!_pid;								 /*Send the query message through query channel*/
	:: query?query_id;		 			 		 /*Read the query message from query channel*/
	:: (query_id!=0) && (query_id!=_pid) ->	reply[query_id-1]!_pid,ix,iy,iz  /*send a message containing pid, position of aircraft via reply channel*/
	:: receiveChan?receive_id,receive_x,receive_y,receive_z;
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


	
	



