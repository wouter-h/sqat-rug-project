module sqat::series2::A2_CheckArch

import sqat::series2::Dicto;
import lang::java::jdt::m3::Core;
import Message;
import ParseTree;
import IO;
import String;
import Set;

/*

This assignment has two parts:
- write a dicto file (see example.dicto for an example)
  containing 3 or more architectural rules for Pacman
  
- write an evaluator for the Dicto language that checks for
  violations of these rules. 

Part 1  

An example is: ensure that the game logic component does not 
depend on the GUI subsystem. Another example could relate to
the proper use of factories.   

Make sure that at least one of them is violated (perhaps by
first introducing the violation).

Explain why your rule encodes "good" design.
  
Part 2:  
 
Complete the body of this function to check a Dicto rule
against the information on the M3 model (which will come
from the pacman project). 

A simple way to get started is to pattern match on variants
of the rules, like so:

switch (rule) {
  case (Rule)`<Entity e1> cannot depend <Entity e2>`: ...
  case (Rule)`<Entity e1> must invoke <Entity e2>`: ...
  ....
}

Implement each specific check for each case in a separate function.
If there's a violation, produce an error in the `msgs` set.  
Later on you can factor out commonality between rules if needed.

The messages you produce will be automatically marked in the Java
file editors of Eclipse (see Plugin.rsc for how it works).

Tip:
- for info on M3 see series2/A1a_StatCov.rsc.

Questions
- how would you test your evaluator of Dicto rules? (sketch a design)
- come up with 3 rule types that are not currently supported by this version
  of Dicto (and explain why you'd need them). 
*/


set[Message] eval(start[Dicto] dicto, M3 m3) = eval(dicto.top, m3);

set[Message] eval((Dicto)`<Rule* rules>`, M3 m3) 
  = ( {} | it + eval(r, m3) | r <- rules );
  
set[Message] eval(Rule rule, M3 m3) {
	set[Message] msgs = {};
  	println(rule);
  	switch (rule) {
		case (Rule)`<Entity e1> cannot depend <Entity e2>`: msgs += ruleCannotDepend(e1, e2, m3);
	  	case (Rule)`<Entity e1> cannot inherit <Entity e2>`: msgs += ruleCannotInherit(e1, e2, m3);
	  	case (Rule)`<Entity e1> must inherit <Entity e2>`: msgs += ruleMustInherit(e1, e2, m3);
	}
	return msgs;
}

set[Message] ruleCannotDepend(Entity e1, Entity e2, M3 m3){
	dependency = m3.typeDependency;
	stre1 = replaceAll("<e1>", ".", "/");
	stre2 = replaceAll("<e2>", ".", "/");
	return toSet([error("<stre1> has a violation: <stre1> dependends on <stre2>", l) | <l, dependentOn> <- dependency, contains(l.path, stre1), contains(dependentOn.path, stre2)]);
}

set[Message] ruleMustInherit(Entity e1, Entity e2, M3 m3){
	fromto transClosure = findTransClosureInherit(m3);
	stre1 = replaceAll("<e1>", ".", "/");
	stre2 = replaceAll("<e2>", ".", "/");
	for( ele <- transClosure){
		if(contains(ele.from.path, stre1) && contains(ele.to.path, stre2)) return {};
	}
	return {error("<e1> does not inherit <e2>", toLocation("<e1>"))};
}

set[Message] ruleCannotInherit(Entity e1, Entity e2, M3 m3){
	set[Message] msgs = {};
	fromto transClosure = findTransClosureInherit(m3);
	stre1 = replaceAll("<e1>", ".", "/");
	stre2 = replaceAll("<e2>", ".", "/");
	for( ele <- transClosure){
		if(contains(ele.from.path, stre1) && contains(ele.to.path, stre2)) msgs += {error("<ele.from> should not inherit <ele.to>", toLocation("<e1>"))};
	}
	return msgs;
}

rel[loc, loc] findTransClosureInherit(M3 m3){
	inherit = m3.extends + m3.implements;
	fromto transClosure = inherit;
	while(true){
		temp = transClosure;
		transClosure += transClosure o inherit;
		if(temp == transClosure)
    	   break;
	}
	return transClosure;
}

alias fromto = rel[loc from, loc to];