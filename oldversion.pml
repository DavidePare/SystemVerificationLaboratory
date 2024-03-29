#define FLOOR 3
chan c = [FLOOR] of {byte};
bool state[FLOOR];
bool opendoor=false; // door close
short elevator=1;
active proctype floor1()
{
	state[0]=false;
	do
	::if
	::(state[0]==false)->
		atomic{c!1;
		state[0]=true;
	}
	::(state[0]==true)->
		skip;
	fi
	od
}
active proctype floor2()
{

	state[1]=false;
	do
	::if
	::(state[1]==false)->
		atomic{c!2;
		state[1]=true;}
	::(state[1]==true)->
		skip;
	fi
	od
}
active proctype floor3()
{

	state[2]=false;
	do
	::if
		::(state[2]==false)->
			atomic{c!3;
			state[2]=true;}
		::(state[2]==true)->
			skip;
	fi
	od
}



active proctype controller()
{
	short piano;
	do
	::c?piano;
		movelevator:
		do
			::if
			::atomic{(piano==elevator)-> 
				dooropened:
				opendoor=true;
				doorclosed:
				opendoor=false;
				state[piano-1]=false;
				break;
			} //here open and close door
			::atomic { (piano<elevator)->
				ismoving:
				elevator--};
			::atomic{ (piano>elevator)->
				ismoving:
				elevator++};
			fi
		od
	// ::skip
	od
}

/*init
{
	atomic{
		int i;
		for (i : 0 .. FLOOR) {
			state[i]==false;
		}
	}
	
	run floor1();run floor2(); run floor3();run controller();
}*/

	
/* Whenever the door is open the cabin must be standing */
ltl p1 {[] (opendoor -> !controller@ismoving)}
/*Whenever the cabin is moving the door must be closed.*/
ltl p2 {[]( (controller@ismoving -> opendoor))}
//3. A button cannot remain pressed forever.
ltl p3{<>[]state[0]==true || <>[]state[1]==true || <>[]state[2]==true}
/*4. The door cannot remain open forever. -- door can remain open forever stands for -> door is infinitely many times open (it indicates that from a point door is 
always open)*/
ltl p4{![]<>opendoor}
ltl p41{[]<>! controller@doorclosed}
//5. The door cannot remain closed forever.
ltl p5{[]<>!opendoor}
ltl p51{[]<>! controller@dooropened}

// Whenever the button at floor x (x=1,2,3) becomes pressed then the cabin will eventually be at the fllor x with the door open
//ltl p6{[]controller@piano ==elevator -> controller@dooropened}
