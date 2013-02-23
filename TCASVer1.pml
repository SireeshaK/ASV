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

/*Channel declaration */
typedef msg {
        byte p_id;
	byte x,y,z
}; /* pid, Coordinate */

chan interrogation[N] = [100] of {byte};
chan reply[N] = [100] of {msg}; 


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

active [5] proctype airplane(){

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
	 	::(coordinate.x[ix].y[iy].z[iz] == 0) -> coordinate.x[ix].y[iy].z[iz]=_pid+1; /* _pid can possibly be zero so use _pid+1 */
		::else -> goto L1
	fi;
	printf("airplane position in airspace for pid %d : %d|%d|%d", _pid,ix,iy,iz );

/* Sending interrogation and receiving reply messages */
	
}


	
	



