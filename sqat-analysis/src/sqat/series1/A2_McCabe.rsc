module sqat::series1::A2_McCabe

import analysis::statistics::Correlation;
import sqat::series1::A1_SLOC;
import lang::java::jdt::m3::AST;
import IO;
import ParseTree;
import String;
import util::FileSystem;
import Type;
/*

Construct a distribution of method cylcomatic complexity. 
(that is: a map[int, int] where the key is the McCabe complexity, and the value the frequency it occurs)


Questions:
- which method has the highest complexity (use the @src annotation to get a method's location)
Inky.java -> nextMove (without /srs/test/)

- how does pacman fare w.r.t. the SIG maintainability McCabe thresholds?
The highest method has 7 (in src/main/) Inky.java -> nextMove , in src/test/ the highest method has 2, LauncherSmokeTest -> move
This is good according to the SIG maintainability model where they describe 1-10 as good. (https://www.sig.eu/wp-content/uploads/2016/10/APracticalModelForMeasuringMaintainability.pdf)

- is code size correlated with McCabe in this case (use functions in analysis::statistics::Correlation to find out)? 
  (Background: Davy Landman, Alexander Serebrenik, Eric Bouwers and Jurgen J. Vinju. Empirical analysis 
  of the relationship between CC and SLOC in a large corpus of Java methods 
  and C functions Journal of Software: Evolution and Process. 2016. 
  http://homepages.cwi.nl/~jurgenv/papers/JSEP-2015.pdf)
  
  With test sources and main =
  pearson: 0.9060945176134495
  spearman: 0.8965005438952282
  which is relatively well positively correlated.
  
  
- what if you separate out the test sources?
only main:
pearson: 0.9598913695647171
spearman: 0.9343792996452494
which is even higher, so also positively correlated.

Tips: 
- the AST data type can be found in module lang::java::m3::AST
- use visit to quickly find methods in Declaration ASTs
- compute McCabe by matching on AST nodes

Sanity checks
- write tests to check your implementation of McCabe

Bonus
- write visualization using vis::Figure and vis::Render to render a histogram.

*/

/**
*	calculates the number of conditions in an expression, it does so by using recursion
*	@condition the expression of which the number of conditions should be determined
*	@return: the number of conditions in the expression
*/

int countNumberOfConditions(Expression condition){
	switch(condition){
		case \infix(Expression lhs, "&&" , Expression rhs): {return countNumberOfConditions(lhs) + countNumberOfConditions(rhs);}
		case \infix(Expression lhs, "||" , Expression rhs): {return countNumberOfConditions(lhs) + countNumberOfConditions(rhs);}
		case \postfix(Expression operand, str operator): {return countNumberOfConditions(operand);}
    	case \prefix(str operator, Expression operand): {return countNumberOfConditions(operand);}
		default: return 1;
	}
}

/**
*	calculates the cc of a method
*	@branch: the method statement
*	@return: the cc of the method
*/
int ccMethod(Statement branch){
	int sum = 1;
	visit(branch){
		case \if(Expression condition, Statement thenBranch) : {sum += countNumberOfConditions(condition);}
		case \if(Expression condition, Statement thenBranch, Statement elseBranch): {sum += countNumberOfConditions(condition);} 
		case \for(list[Expression] initializers, Expression condition, list[Expression] updaters, Statement body): sum += countNumberOfConditions(condition);
    	case \while(Expression condition, Statement body):{sum += countNumberOfConditions(condition);}
    	case \case(Expression expression): {sum += countNumberOfConditions(expression);}
    	case \defaultCase(): sum += 0;
    	case \try(Statement body, list[Statement] catchClauses):{sum += size(catchClauses);}
    	case \try(Statement body, list[Statement] catchClauses, Statement \finally) : {sum += size(catchClauses);}
    	case \assert(Expression expression): sum += 1;
    	case \assert(Expression expression, Expression message): sum += 1;
    };
	return sum;
}

/**
*	calculates the cyclomatic complexity of a file
*	@decls: input Declaration of a file
*	@return: returns the sum of all cc of the methods in a file
*/
int cc(Declaration decls) {
	fileCC = 0;
	for(decl <- decls){
	  	visit(decl){
	  		case \method(Type \return, str name, list[Declaration] parameters, list[Expression] exceptions, Statement impl):{print(name); methodCC = ccMethod(impl); print(" "); println(methodCC); fileCC += methodCC;}
	  		case \constructor(str name, list[Declaration] parameters, list[Expression] exceptions, Statement impl) : {print(name); methodCC = ccMethod(impl);  print(" "); println(methodCC); fileCC += methodCC;}
	  	};
  	}
  	return fileCC;
}

public void walk(loc project){
	lst = [project];
	while(!isEmpty(lst)){
		<location, lst> = takeOneFrom(lst);
		for (str file <- listEntries(location)){
			if (endsWith(file, ".java")){
				loc temp = location+file;
				ccdegree = cc(createAstFromFile(temp, true));
			 	println("file: <location> <file> ccdegree: <ccdegree>");
			}
			elseif (isDirectory(location+file)){
				lst = push(location+file, lst);
			}
		}
	}
}

void correlationOfCCvsSLOC(loc project){
	lrel[int first, int second] values = [];
	lst = [project];
	while(!isEmpty(lst)){
		<location, lst> = takeOneFrom(lst);
		for (str file <- listEntries(location)){
			if (endsWith(file, ".java")){
				loc temp = location+file;
				ccdegree = cc(createAstFromFile(temp, true));
				fileSize = sizeOfFile(temp);
				
				values = values + <ccdegree, fileSize>;
			}
			elseif (isDirectory(location+file)){
				lst = push(location+file, lst);
			}
		}
	}
	pearson = PearsonsCorrelation(values);
	spearman = SpearmansCorrelation(values);
	print("pearson: "); println(pearson);
	print("spearman: "); println(spearman);
}

test bool testFile1() =
	 cc(createAstFromFile(|project://jpacman-framework/src/main/java/nl/tudelft/jpacman/npc/ghost/Clyde.java|, true)) == 6;

test bool testFile2() =
	cc(createAstFromFile(|project://jpacman-framework/src/main/java/nl/tudelft/jpacman/npc/ghost/package-info.java|, true)) == 0;

test bool testFile3() =
	cc(createAstFromFile(|project://jpacman-framework/src/main/java/nl/tudelft/jpacman/level/DefaultPlayerInteractionMap.java|, true)) == 4;
	