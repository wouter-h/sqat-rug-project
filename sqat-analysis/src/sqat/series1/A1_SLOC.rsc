module sqat::series1::A1_SLOC

import IO;
import ParseTree;
import String;
import util::FileSystem;
import Type;

/* 

Count Source Lines of Code (SLOC) per file:
- ignore comments
- ignore empty lines

Tips
- use locations with the project scheme: e.g. |project:///jpacman/...|
- functions to crawl directories can be found in util::FileSystem
- use the functions in IO to read source files

Answer the following questions:
- what is the biggest file in JPacman?
Level.java
- what is the total size of JPacman?
1901 (src/main), 557(src/test)
- is JPacman large according to SIG maintainability?
No, because a good project has between 0 and 66k lines of code (https://www.sig.eu/wp-content/uploads/2016/10/APracticalModelForMeasuringMaintainability.pdf). Pacman has 1901. 
- what is the ratio between actual code and test code size?
1901:557

Sanity checks:
- write tests to ensure you are correctly skipping multi-line comments
- and to ensure that consecutive newlines are counted as one.
- compare you results to external tools sloc and/or cloc.pl

Bonus:
- write a hierarchical tree map visualization using vis::Figure and 
  vis::Render quickly see where the large files are. 
  (https://en.wikipedia.org/wiki/Treemapping) 

*/

/**
*@match: the match that has to be checked whether it is a string or a comment
* checks whether a match is a string constant or a comment
*@return returns an empty string if it is a comment, otherwise it returns the input
*/
str returnReplacement(str match){
	if(charAt(match, 0) != charAt("\"", 0)){		//checks if it isn't a string constant
		return "";
	} else {
		return match;
	}
}

/**
*deletes all comments from a given content, and ignores string constants
*
* @param content The content from which you want to filter comments
* @return The content without comments 
*/
str deleteComments(str content)
	= visit(content) {
		case /<match:("([^"]|(\"))")|(\/\/.*)|(\/\*[^*]*\*+([^\/*][^*]*\*+)*\/)>/ => returnReplacement(match)
	};

/**
* deletes all the empty lines from the given content
*
*@param content  The content from which you want to remove the empty lines
*@return a list of strings in which the non-empty line from content are stored
*/
list[str] deleteEmptyLines(str content){
	lineList = split("\n", content);
	nonEmptyLines = [trim(line) | line <- lineList, trim(line) != ""];
	return nonEmptyLines;
}

/*
* return the number of source lines of code without comments and empty lines
*
*@param file the source location of the file of which you want to know the SLOC of
*@return the number of SLOC in the file without comments and empty lines
*/
int sizeOfFile(loc file) {
  fileContents = readFile(file);
  lines = deleteComments(fileContents);
  finalList= deleteEmptyLines(lines);
  return size(finalList);
}

/**
*	prints the answers to the questions and also calculates the total number of lines
*	 in jpacman and also determines the largest file.
*/
public void SLOC(loc project){
	largestFileName="";
	largestFileSize=0;
	totalNumberOfLinesInProject = 0;
	lst = [project];
	while(!isEmpty(lst)){
		<location, lst> = takeOneFrom(lst);
		for (str file <- listEntries(location)){
			if (endsWith(file, ".java")){
				loc temp = location+file;
				nrLines = sizeOfFile(temp);
				if(nrLines>largestFileSize){
					largestFileName=file;
					largestFileSize=nrLines;
				}
				totalNumberOfLinesInProject += nrLines;
			 	print("file: " + file + " loc: "); println(nrLines);
			}
			elseif (isDirectory(location+file)){
				lst = push(location+file, lst);
			}
		}
	}
	println("The largest file:<largestFileName> with size: <largestFileSize>");
	print("total size pacman: "); println(totalNumberOfLinesInProject);
}

/*only test cases below this*/
test bool testMultiLineComment1() 
  = deleteComments("/**/") == "";
  
test bool testMultiLineComment2() 
  = deleteComments("/*some text*/") == "";

test bool testMultiLineComment3() 
  = deleteComments("/*
  					`some text()sagk;a;
  					`*/") == "";
  					
test bool testMultiLineComment4() 
  = deleteComments("/**
  					`some text()sagk;a;
  					`*/") == "";
  					
test bool testMultiLineComment5() 
  = deleteComments("/*
  					`*some text()sagk;a;
  					`sdkh;s*/") == "";
  					
test bool testMultiLineComment6() 
  = deleteComments("/*****************
  					`*******************some text()sagk;a;
  					`***************/") == "";
  					
test bool testMultiLineComment7() 
  = deleteComments("a") == "a";
  
test bool testMultiLineComment8() 
  = deleteComments("a
  					`/*a comment
  					`*/
  					`some code
  					`/*
  					`another comment
  					`*/") ==
  					"a
  					`
  					`some code
  					`";
  					
 test bool testSingleLineComment1()
 	= deleteComments("//a comment") == "";
 	
test bool testSingleLineComment2()
	= deleteComments("//a comment\n//a comment") == "\n";
					
test bool testSingleLineComment3()
	= deleteComments("//a comment\n//a comment\n") == "\n\n";
					
test bool testSingleLineComment4()
	= deleteComments("//a comment\nsome text\n//a comment\nsome text") == "\nsome text\n\nsome text";
					
test bool testSingleLineComment5()
	= deleteComments("////a comment\n///a comment") == "\n";

test bool mixedComments1()
	= deleteComments("/*look at //this*/") == "";
	
test bool mixedComments2()
	= deleteComments("//look /*at this*/") == "";
	
test bool mixedComments3()
	= deleteComments("/*look at //\nthis\n*/") == "";

test bool returnReplacement1()
	= returnReplacement("\"a string\"") == "\"a string\"";
	
test bool returnReplacement1()
	= returnReplacement("/*a comment*/") == "";
