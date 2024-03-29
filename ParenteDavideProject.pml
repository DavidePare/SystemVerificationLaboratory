#define FLOOR 3

chan c = [FLOOR] of {byte};
bool state[FLOOR];
bool opendoor=false; // door close
short elevator=1;
bool standing=false;
short piano;

active proctype floorButtons()
{
	state[0]=false; //button one is unpressed
	state[1]=false; //button two is unpressed
	state[2]=false; //button three is unpressed
	do
		::if
			::(state[0]==false)->
				buttonOnePressed:
					atomic{c!1;state[0]=true;}
			::(state[1]==false)->
				buttonTwoPressed:
					atomic{c!2; state[1]=true;}
			::(state[2]==false)->
				buttonThreePressed:
					atomic{c!3; state[2]=true};
		fi
	od
}




active proctype controller()
{
	
	do
	::c?piano;
		movelevator:
		do
			::if
			::(piano==elevator)->  //case the elevator is in the same floor read from the channel c
				standing=true;
				dooropened:
					opendoor=true;
				doorclosed:
					atomic{ opendoor=false;
					state[piano-1]=false;
					break;} //here open and close door
			::(piano<elevator)->  //case the elevator is in an upper floor different to the variable piano read from the channel c
				standing=false;
				down: 
					elevator--;
			::(piano>elevator)->  //case the elevator is in an under floor different to the variable piano read from the channel c
				standing=false;
				up:
					elevator++;
			fi
		od
	od
}

	
/* Whenever the door is open the cabin must be standing */
ltl p1 {[] (opendoor -> standing)}
/*Whenever the cabin is moving the door must be closed.*/
ltl p2 {[]((controller@down || controller@up) -> !opendoor)}
//3. A button cannot remain pressed forever. [](state[0] -> <>state[0]
ltl p3 {[](state[0]-> <> !state[0]) &&[](state[1]-> <> !state[1]) && [](state[2]-> <> !state[2]) }
/*4. The door cannot remain open forever.*/
ltl p4 {[](opendoor -> <> !opendoor)}
//5. The door cannot remain closed forever.
ltl p5 {[](!opendoor -> <> opendoor)}

// Whenever the button at floor x (x=1,2,3) becomes pressed then the cabin will eventually be at the fllor x with the door open
ltl p6 {[](state[piano-1] ->  <>(elevator==piano && opendoor))}
/* Whenever no button is currently pressed and the button at floor x (x = 1, 2, 3) becomes pressed and, afterwards, also the button at floor y (y =! x and y = 1, 2, 3) becomes pressed and, in the meanwhile, no other button becomes pressed then the cabin will be standing at floor x with the door open and, afterwards,  the cabin will be standing at floor y with the door open and in the meanwhile the cabin will not be standing at any other floor different from y with the door open.*/
ltl p7{[](
((((!state[0] && !state[1] && !state[2])U floorButtons@buttonOnePressed) U (!state[2] && floorButtons@buttonTwoPressed)) -> <>(((standing && opendoor)-> elevator==1) U (standing && opendoor)-> elevator==2)) &&
((((!state[0] && !state[1] && !state[2])U floorButtons@buttonOnePressed) U (!state[1] && floorButtons@buttonThreePressed)) -> <>(((standing && opendoor)-> elevator==1) U (standing && opendoor)-> elevator==3)) &&
((((!state[0] && !state[1] && !state[2])U floorButtons@buttonTwoPressed) U (!state[2] && floorButtons@buttonOnePressed)) -> <>(((standing && opendoor)-> elevator==2) U (standing && opendoor)-> elevator==1)) &&
((((!state[0] && !state[1] && !state[2])U floorButtons@buttonTwoPressed) U (!state[0] && floorButtons@buttonThreePressed)) -> <>(((standing && opendoor)-> elevator==2) U (standing && opendoor)-> elevator==3)) &&
((((!state[0] && !state[1] && !state[2])U floorButtons@buttonThreePressed) U (!state[1] && floorButtons@buttonOnePressed)) -> <>(((standing && opendoor)-> elevator==3) U (standing && opendoor)-> elevator==1)) &&
((((!state[0] && !state[1] && !state[2])U floorButtons@buttonThreePressed) U (!state[0] && floorButtons@buttonTwoPressed)) -> <>(((standing && opendoor)-> elevator==3) U (standing && opendoor)-> elevator==2)) 
)}
