module sqat::series2::A1b_DynCov

import IO;
import lang::csv::IO;
import String;
import Type;
import List;
import Java17ish;
import ParseTree;
import util::FileSystem;
import lang::java::jdt::m3::Core;
import lang::java::jdt::m3::AST;
/*

Assignment: instrument (non-test) code to collect dynamic coverage data.

- Write a little Java class that contains an API for collecting coverage information
  and writing it to a file. NB: if you write out CSV, it will be easy to read into Rascal
  for further processing and analysis (see here: lang::csv::IO)

- Write two transformations:
  1. to obtain method coverage statistics
     (at the beginning of each method M in class C, insert statement `hit("C", "M")`
  2. to obtain line-coverage
     (insert hit("C", "M", "<line>"); after every statement.)

The idea is that running the test-suite on the transformed program will produce dynamic
coverage information through the insert calls to your little API.

Questions
- use a third-party coverage tool (e.g. Clover) to compare your results to (explain differences)
	>our coverage is 75%.
	>clover has a coverage of 75%.
	>So we have exactly the same coverage!
	
- which methods have full line coverage?
	>
- which methods are not covered at all, and why does it matter (if so)?
	>["withMapFile","doAction","main","PacmanConfigurationException","levelWon","actionPerformed","ButtonPanel","PacKeyListener","keyPressed","keyTyped","keyReleased","PacManUI","addButton","withScoreFormatter","ScorePanel","setScoreFormatter","Blinky","Clyde","Ghost","Inky","Navigation","addNewTargets","findNearest","findUnit","Pinky","CollisionInteractionMap","onCollision","addHandler","getMostSpecificClass","getInheritance","InverseCollisionHandler","handleCollision","defaultCollisions","Level","removeObserver","createLevel","RandomGhost","makeGrid","addSquare","makeGhostSquare","checkMapFormat","Player","pelletColliding"]
	>Methods that are not covered are mostly UI methods, constructors. UI is more java dependent, you are normally not going to check if a java library method is correct, you kind of assume they are.
	>Constructors is mostly testing getters and setters because a constructor often initializes itself.
- what are the drawbacks of source-based instrumentation?
	>Is slower because you have to run it and can create giant files, if there are certificates than you might not be allowed to dynamically test it.
Tips:
- create a shadow JPacman project (e.g. jpacman-instrumented) to write out the transformed source files.
  Then run the tests there. You can update source locations l = |project://jpacman/....| to point to the 
  same location in a different project by updating its authority: l.authority = "jpacman-instrumented"; 

- to insert statements in a list, you have to match the list itself in its context, e.g. in visit:
     case (Block)`{<BlockStm* stms>}` => (Block)`{<BlockStm insertedStm> <BlockStm* stms>}` 
  
- or (easier) use the helper function provide below to insert stuff after every
  statement in a statement list.

- to parse ordinary values (int/str etc.) into Java15 syntax trees, use the notation
   [NT]"...", where NT represents the desired non-terminal (e.g. Expr, IntLiteral etc.).  

*/

str dyncovfile = "package nl.tudelft.jpacman;\n\nimport java.io.*;\n\npublic class DynCov{\n\npublic void hit(String x, String y){\ntry\n{\nString filename = \"dyncov.txt\";\nFileWriter fw = new FileWriter(filename,true);\nfw.write(x + \",\" + y + \"\\n\");\nfw.close();\n}\ncatch(IOException ioe)\n{\nSystem.err.println(\"IOException: \" + ioe.getMessage());\n}\n}\npublic void hit(String x, String y, int z){\n\ntry\n{\nString filename= \"dyncov.txt\";\nFileWriter fw = new FileWriter(filename,true);\nfw.write(x + \",\" + y + \",\" + z + \"\\n\");\nfw.close();\n}\ncatch(IOException ioe)\n{\nSystem.err.println(\"IOException: \" + ioe.getMessage());\n}\n}}";

str methodName = "";

int lineNumber = 1;
	
int countNewLines(str match)
	= size(findAll(match, "\n"));

str constructLineStatement(str className, str methodName, int lineNumber)
	= "new nl.tudelft.jpacman.DynCov().hit(\"<className>\", \"<methodName>\", <lineNumber>);";

str constructMethodStatement(str className, str string){
	if(isClassDeclaration(string)) return "";
	str localMethodName = getMethodName(string);
	return "new nl.tudelft.jpacman.DynCov().hit(\"<className>\", \"<localMethodName>\");";
}

str getMethodName(str string)
	= visit(string){
		case /<match:[a-zA-Z0-9_]+>/: return match;
	};

str getClassName(str string){
	str temp = "";
	visit(string){
		case /<match:(class[\s\t\n ]+[a-zA-Z0-9_]+[\s\t\n ]*\{)|(class[\s\t\n ]+[a-zA-Z0-9_]+[\s\t\n ]+extends)|(class[\s\t\n ]+[a-zA-Z0-9_]+[\s\t\n ]+implements)>/ : temp = match;
	};
	if(temp == "") return "UNKNOWNCLASSNAME";
	str beginOfName = substring(temp, 6, size(temp));
	visit(beginOfName){
		case /<match:[a-zA-Z0-9_]+>/ : return match;
	}
}

str constructStatement(str string, str class, str method){
	lineNumber += countNewLines(string);
	if(string == "\n") return "";
	if(string != ";"){
		return constructMethodStatement(class, string);
	}
	if(method == "") return "";
	return constructLineStatement(class, method, lineNumber);
}

str insertImport(str contents, str importPath){
	visit(contents){
		case /<match:([\t\n\s \/]?package[\t\s\n ]+[a-zA-Z0-9_.]+;\n?)|(^.)>/ : return replaceFirst(contents, match, match + "\n" + importPath + "\n");
	};
}
	
str insertStatement(str string, str className){
	if(string == "\n"){
		lineNumber += 1;
		return "";
	}
	return constructLineStatement(className, methodName, lineNumber);
}

bool isClassDeclaration(str string){
	str temp = trim(string);
	if(size(string) < 4) return false;
	temp = substring(string, 0, 4);
	if((substring(temp, 0, 3) == "new") && (substring(temp, 3, 4) == " " || substring(temp, 3, 4) == "\t" || substring(temp, 3, 4) == "\n")) return true;
	return false;
}

str filterOutThrowNewExceptions(str string)
	= visit(string){
		case /<match:[ \t\s\n;\)\}\]]throw[\s\t\n ]+new[\s\t\n ]+[a-zA-Z0-9_]+[ \s\t\n]*\([a-zA-Z0-9 \s\n\t",\._\+\:\-\/\*\\]*\)\;>new nl\.tudelft\.jpacman\.DynCov\(\)\.hit\(\"[a-zA-Z0-9_]*\", \"[a-zA-Z0-9_]*\", [0-9]+\);/ => match 
	};

str filterOutReturnExceptions(str string)
	= visit(string){
	case /<match:([ \t\s\n;\)\}\]]return;)|([ \t\s\n;\)\}\]]return[\s\t\n ][^\;]*;)>new nl\.tudelft\.jpacman\.DynCov\(\)\.hit\(\"[a-zA-Z0-9_]*\", \"[a-zA-Z0-9_]*\", [0-9]+\);/ => match
};

str filterOutUnreachableCode(str string){
	str temp = string;
	temp = filterOutThrowNewExceptions(temp);
	temp = filterOutReturnExceptions(temp);
	return temp;
}

str filterOutCodePlacedOutsideMethods(str string)
	= visit(string){
		case /<match:[\s\t\n ;\)\(\{\}\],]new[\s\t\n ]+[a-zA-Z0-9_]+[\s\t\n ]*\([\s\t\n a-zA-Z0-9_,\[\]\.\"]*\)[\s\t\n ]*\{>new nl\.tudelft\.jpacman\.DynCov\(\)\.hit\(\"[a-zA-Z0-9_]*\", \"[a-zA-Z0-9_]*\"\);/ => match
	};

str filterOutCodeInFrontOfSuper(str string)
	= visit(string){
		case /<match1:\{>new nl\.tudelft\.jpacman\.DynCov\(\)\.hit\(\"[a-zA-Z0-9_]*", \"[a-zA-Z0-9_]*\"\);<match2:[ \t\s\n]*super\(>/ => match1 + match2
	};
	

str filterOutCodeInFrontOfSuperThis(str string)
	= visit(string){
		case /<match1:\{>new nl\.tudelft\.jpacman\.DynCov\(\)\.hit\(\"[a-zA-Z0-9_]*", \"[a-zA-Z0-9_]*\"\);<match2:[ \t\s\n]*this\(>/ => match1 + match2
	};

str filterOutCodeAfterSwitch(str string)
	= visit(string){
		case /<match:[\{\s\t\n ;\)\}]switch[\t\s\n ]*\([a-zA-Z0-9_]*\)[ \s\t\n]*\{>new nl\.tudelft\.jpacman\.DynCov\(\)\.hit\(\"[a-zA-Z0-9_]*\", \"[a-zA-Z0-9_]*\"\);/ => match
	};

str filterOutCodeAfterBreak(str string)
	= visit(string){
		case /<match:[\{\s\t\n \)\}]break[ \s\t\n]*;>new nl\.tudelft\.jpacman\.DynCov\(\)\.hit\(\"[a-zA-Z0-9_]*\", \"[a-zA-Z0-9_]*\", [0-9]+\);/ => match
	};

str filterOutCodeInForLoops(str string)
	= visit(string){
		case /<match1:for[\t\s\n ]*\([^;]*;>new nl\.tudelft\.jpacman\.DynCov\(\)\.hit\(\"[a-zA-Z0-9_]*\", \"[a-zA-Z0-9_]*\", [0-9]+\);<match2:[^;]*;>new nl\.tudelft\.jpacman\.DynCov\(\)\.hit\(\"[a-zA-Z0-9_]*\", \"[a-zA-Z0-9_]*\", [0-9]+\);/ => match1 + match2
	};

str insertStatements(str string, str className){
	if(string == "\n"){
		lineNumber += 1;
		return string;
	}
	
	if(isClassDeclaration(string)) return string;

	methodName = getMethodName(string);
	
	str toRet = visit(string){
		case /<match:;|\n>/ => match + insertStatement(match, className)
	};
	toRet = visit(toRet){
		case /<match:([\s\t\n \(\{\}\);\[\]]new[\s\t\n ]+)?([a-zA-Z0-9_]+[\s\t\n ]*\([a-zA-Z0-9_\[\] \s\t\n,]*\)([\s\t\n ]*throws[\s\t\n ]+[a-zA-Z0-9_]+([\s\t\n ]*,[\s\t\n ]*[a-zA-Z0-9_]+)*)?[\s\t\n ]*\{)>/ => match + constructMethodStatement(className, match)
	};
	return toRet;
}

list[str] returnMethodsInFile(Declaration decls) {
  	list[str] methods = [];
	for(decl <- decls){
		visit(decl){
		  	case \method(Type \return, str name, list[Declaration] parameters, list[Expression] exceptions, Statement impl): methods = methods + name;
			case \constructor(str name, list[Declaration] parameters, list[Expression] exceptions, Statement impl) : methods = methods + name;
		};
	}
	return methods;
}

list[str] findAllMethods(loc project){
	list[loc] lst = [] + project;
	list[str] methods1 = [];
	while(!isEmpty(lst)){
		<a, lst> = takeOneFrom(lst);
		for (str entry <- listEntries(a)){
			if (endsWith(entry, ".java")){
				loc temp = a+entry;
				methods1 = methods1 + returnMethodsInFile(createAstFromFile(temp, true));
			 }
			elseif (isDirectory(a+entry)){
				lst = push(a+entry, lst);
			}
		}
	}
	return methods1;
}

void findNonCoverage(){
	loc dynCovLocation = |project://jpacman-framework/dyncov.txt|;
	list[str] entries = [entry | entry <- split("\n", readFile(dynCovLocation))];
	list[str] methodCov = [entry | entry <- entries, size(split(",", entry)) == 2];
	list[str] lineCov = [entry | entry <- entries, size(split(",", entry)) == 3];
	
	list[str] methods1 = [head(tail(split(",", m))) | m <- methodCov];
	list[str] methods2 = [head(tail(split(",", m))) | m <- lineCov];
	list[str] methodsCovered = dup(methods1 + methods2);
	methodsCovered = dup(methodsCovered);
	
	methodsInProject = dup(findAllMethods(|project://jpacman-framework/src/main/|));
	
	nonCovMethods = dup([m | m <- methodsInProject, m notin methodsCovered]);
	
	println(nonCovMethods);
	result = 1.0 - (size(nonCovMethods) * 1.0 /size(methodsInProject) * 1.0);
	println(result);
}

void insertChecks(loc project){
	list[loc] lst = [] + project;
	while(!isEmpty(lst)){
		<a, lst> = takeOneFrom(lst);	
		for (str entry <- listEntries(a)){
			if (endsWith(entry, ".java")){
				lineNumber = 1;
				println(a+entry);
				loc location = a+entry;
				str fileContents = readFile(location);
				str temp = fileContents;
	
				temp = insertImport(temp, "import nl.tudelft.jpacman.DynCov;");
				
				str className = getClassName(temp);
					
				temp = visit(temp){		//matches a complete head + body of a method or class
					case /<match:([\s\t\n \(\{\}\);\[\]]new[\s\t\n ]+)?([a-zA-Z0-9_]+[\s\t\n ]*\([a-zA-Z0-9_\[\] \s\t\n,]*\)([\s\t\n ]*throws[\s\t\n ]+[a-zA-Z0-9_]+([\s\t\n ]*,[\s\t\n ]*[a-zA-Z0-9_]+)*)?[\s\t\n ]*(\{(([^{}])(\{[^{}]*\}))*[^}]*\}))|\n>/ => insertStatements(match, className)
				};
				
				temp = filterOutUnreachableCode(temp);
				temp = filterOutCodePlacedOutsideMethods(temp);
				temp = filterOutCodeAfterSwitch(temp);
				temp = filterOutCodeAfterBreak(temp);
				temp = filterOutCodeInFrontOfSuper(temp);
				temp = filterOutCodeInFrontOfSuperThis(temp);
				temp = filterOutCodeInForLoops(temp);
				
				writeFile(location, temp);
			}
			elseif (isDirectory(a+entry)){
				println(a+entry);
				lst = push(a+entry, lst);
			}
		}
	}
	writeFile(|project://jpacman-framework/src/main/java/nl/tudelft/jpacman/DynCov.java|, dyncovfile);
}

test bool testGetClassName1()
	= getClassName("/*a comment*/\npackage example.com.org.google;\n\nimport lal.lol.lel;\npublic class ExampleClass extends Unit") == "ExampleClass";

test bool testGetClassName2()
	= getClassName("/*a comment*/\npackage example.com.org.google;\n\nimport lal.lol.lel;\npublic class ExampleClass implements Interface") == "ExampleClass";

test bool testGetClassName3()
	= getClassName("/*a comment*/\npackage example.com.org.google;\n\nimport lal.lol.lel;\npublic class ExampleClass extends Unit implements Interface1, Interface2") == "ExampleClass";

test bool testFilterOutReturnExceptions()
	= filterOutReturnExceptions("\nreturn;new nl.tudelft.jpacman.DynCov().hit(\"ClassName\", \"methodName\", 100);") == "\nreturn;";

test bool testFilterOutThrowNewExceptions()
	= filterOutThrowNewExceptions("\nthrow new ExceptionExample(\"An error message\\n\");new nl.tudelft.jpacman.DynCov().hit(\"ClassName\", \"methodName\", 100);") == "\nthrow new ExceptionExample(\"An error message\\n\");";

test bool testFilterOutUnreachableCode()
	= filterOutUnreachableCode("if(true){\n\t\nreturn;new nl.tudelft.jpacman.DynCov().hit(\"ClassName\", \"methodName\", 100);\n}\nthrow new ExceptionExample(\"An error message\\n\");new nl.tudelft.jpacman.DynCov().hit(\"ClassName\", \"methodName\", 100);") == "if(true){\n\t\nreturn;\n}\nthrow new ExceptionExample(\"An error message\\n\");";
	
test bool testFilterOutCodePlacedOutsideMethods()
	= filterOutCodePlacedOutsideMethods(" new ActionListenerOrWhatever(){new nl.tudelft.jpacman.DynCov().hit(\"ClassName\", \"methodName\");\n") == " new ActionListenerOrWhatever(){\n";

test bool testFilterOutCodeAfterSwitch()
	= filterOutCodeAfterSwitch("\nswitch(case){new nl.tudelft.jpacman.DynCov().hit(\"ClassName\", \"methodName\");\n") == "\nswitch(case){\n";
	
test bool testFilterOutCodeAfterBreak()
	= filterOutCodeAfterBreak("\nbreak;new nl.tudelft.jpacman.DynCov().hit(\"ClassName\", \"methodName\", 100);") == "\nbreak;";
	
test bool testFilterOutCodeInFrontOfSuper()
	= filterOutCodeInFrontOfSuper("{new nl.tudelft.jpacman.DynCov().hit(\"ClassName\", \"methodName\");super();") == "{super();";
	
test bool testFilterOutCodeInFrontOfSuperThis()
	= filterOutCodeInFrontOfSuperThis("{new nl.tudelft.jpacman.DynCov().hit(\"ClassName\", \"methodName\");this();") == "{this();";
	
test bool testFilterOutCodeInForLoops()
	= filterOutCodeInForLoops("\nfor(int i = 0;new nl.tudelft.jpacman.DynCov().hit(\"ClassName\", \"methodName\", 100); i \< 10;new nl.tudelft.jpacman.DynCov().hit(\"ClassName\", \"methodName\", 100); ++i){\n") == "\nfor(int i = 0; i \< 10; ++i){\n";