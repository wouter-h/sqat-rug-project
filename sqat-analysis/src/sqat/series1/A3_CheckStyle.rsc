module sqat::series1::A3_CheckStyle

import Boolean;
import IO;
import String;
import Java17ish;
import Message;
import List;
/*

Assignment: detect style violations in Java source code.
Select 3 checks out of this list:  http://checkstyle.sourceforge.net/checks.html
Compute a set[Message] (see module Message) containing 
check-style-warnings + location of  the offending source fragment. 

Plus: invent your own style violation or code smell and write a checker.

Note: since concrete matching in Rascal is "modulo Layout", you cannot
do checks of layout or comments (or, at least, this will be very hard).

JPacman has a list of enabled checks in checkstyle.xml.
If you're checking for those, introduce them first to see your implementation
finds them.

Questions
- for each violation: look at the code and describe what is going on? 
  Is it a "valid" violation, or a false positive?
  	>ending empty line: 		  this does not result in any violation since the files in JPacman never ends in a
  								  empty line however when adding one ourself the code does find it.
  	
  	>complex boolean expressions: as in the empty line check , the code in JPacman does not contain any "complex" boolean expressions
  							      but when we add one ourselves we can find it, we however also found that our code does give false positives
  							      whenever we use boolean expressions of the form: (a+b==2)&&c==3, since it isn't build for expressions with operators
  	
  	>fileSize: 						  this check works depending on how you set the treshhold, according to:
  								  http://checkstyle.sourceforge.net/checks.html this treshhold is 1500 fileSize, however since none of
  								  the files in JPacman is that large we decided to take 10% of this and check for 150 fileSize
  								  this does result in some files that are bigger than this threshhold as can be checked by assignment 1
  								  of this series.
  				

Tips 

- use the grammar in lang::java::\syntax::Java15 to parse source files
  (using parse(#start[CompilationUnit], aLoc), in ParseTree)
  now you can use concrete syntax matching (as in Series 0)

- alternatively: some checks can be based on the M3 ASTs.

- use the functionality defined in util::ResourceMarkers to decorate Java 
  source editors with line decorations to indicate the smell/style violation
  (e.g., addMessageMarkers(set[Message]))

  
Bonus:
- write simple "refactorings" to fix one or more classes of violations 

*/
/**
*checks if the line is empty
*@param string the string that's being checked
*
*@return a the boolean result of the check if the string is empty
*/
bool isEmptyLine(str string){
	return /^\s*$/:=string; 
}

/**
*checks if there are complex booleans(boolean expressions with a depth>3) in a string
*
*@param string the string to be checked
*
*@return a bool depending on if there is a complex boolean in the string
*/
bool boolComplex(str string){
	match = true;
	matchFirst=/[a-zA-Z0-9]+(\<|\<\=|\=\=|\!\=|\>\=|\>)[0-9]+/:=string;
	if(matchFirst){
		match = /[\(,\=]+([a-zA-Z0-9]+(\<|\<\=|\=\=|\!\=|\>\=|\>)[0-9]+[\&\|]{1,2}){0,3}[a-zA-Z0-9]+(\<|\<\=|\=\=|\!\=|\>\=|\>)[0-9]+[\)\,;]+/:=string; 
	}
	else{
		match = false;
	}
	return match;
}

/**
*compares the size of file including coments and empty lines with a set threshhold
*
*@param project the location of the file to be measured
*
*@result boolean: if below threshhold true, else false 
**/
bool fileSize(loc project) {
 	fileContents = readFile(project);
	splitFileContents = split("\n", fileContents);
	if(size(splitFileContents)<150){
		return true;
	}else{
		return false;
	}
}

/**
* checks filesize,complex Booleans and Empty lines at EOF
*
* @param project location of the project that is being checked
* @return returns a set with messages
*/
set[Message] checkStyle(loc project) {
 	set[Message] result ={};
	lst = [project];
	while(!isEmpty(lst)){
		<location, lst> = takeOneFrom(lst);
		for (str file <- listEntries(location)){
			if (endsWith(file, ".java")){
				loc temp = location+file;
				if(!fileSize(temp)){				//file size check
					result = result+info("file too large:", temp);
				}
				fileContents = readFile(temp);
				splitFileContents = split("\n",fileContents);
				lineCount = 0;
				while(!isEmpty(splitFileContents)){
					<line, restOfFile> = pop(splitFileContents); 
					if(!boolComplex(line)){			//complex boolean checks
						result = result+info("complex boolean  on line: <lineCount>",temp);
					}
					lineCount = lineCount + 1;
					splitFileContents = restOfFile;
				}	
				<lastLine, empty> = pop(tail(split("\n",fileContents),1));
				if(isEmptyLine(lastLine)){			//eof empty line check
					result=result+info("file ends with an empty line", temp);
				}
			}
			elseif (isDirectory(location+file)){
					lst = push(location+file, lst);
			}
		}
	}
	return result;
}

test bool emptyLine()
	= isEmptyLine("")==true;
	
	
test bool emptyLine2()
	= isEmptyLine("                    							                                   ")==true;
	
	
test bool emptyLine3()
	= isEmptyLine("\n")==true;
	
	
test bool emptyLine4()
	= isEmptyLine("this is not empty")==false;
	

test bool complexBool()
	= boolComplex("var=variable==1;")==true;
	
	
test bool complexBool2()
	= boolComplex("(variable==1||variable2!=2);")==true;
	
	
test bool complexBool3()
	= boolComplex("var=(variable==1||variable2!=2&&variable3\>3);")==true;
	
test bool complexBool4()
	= boolComplex("var==(variable==1||variable2!=2&&variable3\>3&variable4\>=4);")==true;
	
test bool complexBool5()
	= boolComplex("var!=(variable\<1|variable2!=2&&variable3\>3&variable4\<=4);")==true;
	
	
test bool complexBool6()
	= boolComplex("if(variable\<1|variable2!=2&&variable3\>3&variable4\<=4)")==true;
	
test bool complexBool7()
	= boolComplex("while(variable\<1|variable2!=2&&variable3\>3&variable4\<=4)")==true;
	
	
test bool complexBool8()
	= boolComplex("function(variable\<1|variable2!=2&&variable3\>3&variable4\<=4),otherParameter;")==true;
	
test bool complexBool9()
	= boolComplex("var=(variable\<1|variable2!=2&&variable3\>3&variable4\<=4&& variable5==5);")==false;
	
test bool fileSize()
	=fileSize(|project://sqat-analysis/src/sqat/series1/A3_CheckStyle.rsc|)==false;
	
test bool fileSize2()
	=fileSize(|project://sqat-analysis/src/sqat/series2/A2_CheckArch.rsc|)==true;