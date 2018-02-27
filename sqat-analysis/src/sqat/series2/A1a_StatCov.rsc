module sqat::series2::A1a_StatCov

import lang::java::jdt::m3::Core;
import lang::java::jdt::m3::AST;

import IO;
import ParseTree;
import String;
import util::FileSystem;
import Type;

/*

Implement static code coverage metrics by Alves & Visser 
(https://www.sig.eu/en/about-sig/publications/static-estimation-test-coverage)


The relevant base data types provided by M3 can be found here:

- module analysis::m3::Core:

rel[loc name, loc src]        M3.declarations;            // maps declarations to where they are declared. contains any kind of data or type or code declaration (classes, fields, methods, variables, etc. etc.)
rel[loc name, TypeSymbol typ] M3.types;                   // assigns types to declared source code artifacts
rel[loc src, loc name]        M3.uses;                    // maps source locations of usages to the respective declarations
rel[loc from, loc to]         M3.containment;             // what is logically contained in what else (not necessarily physically, but usually also)
list[Message]                 M3.messages;                // error messages and warnings produced while constructing a single m3 model
rel[str simpleName, loc qualifiedName]  M3.names;         // convenience mapping from logical names to end-user readable (GUI) names, and vice versa
rel[loc definition, loc comments]       M3.documentation; // comments and javadoc attached to declared things
rel[loc definition, Modifier modifier] M3.modifiers;     // modifiers associated with declared things

- module  lang::java::m3::Core:

rel[loc from, loc to] M3.extends;            // classes extending classes and interfaces extending interfaces
rel[loc from, loc to] M3.implements;         // classes implementing interfaces
rel[loc from, loc to] M3.methodInvocation;   // methods calling each other (including constructors)
rel[loc from, loc to] M3.fieldAccess;        // code using data (like fields)
rel[loc from, loc to] M3.typeDependency;     // using a type literal in some code (types of variables, annotations)
rel[loc from, loc to] M3.methodOverrides;    // which method override which other methods
rel[loc declaration, loc annotation] M3.annotations;

Tips
- encode (labeled) graphs as ternary relations: rel[Node,Label,Node]
- define a data type for node types and edge types (labels) 
- use the solve statement to implement your own (custom) transitive closure for reachability.

Questions:
- what methods are not covered at all?
	>Methods that are not tested: [|java+constructor:///nl/tudelft/jpacman/board/Direction/Direction(int,int)|,|java+method:///nl/tudelft/jpacman/board/OccupantTest/testReoccupy()|,|java+method:///nl/tudelft/jpacman/sprite/ImageSprite/draw(java.awt.Graphics,int,int,int,int)|,|java+method:///nl/tudelft/jpacman/board/BoardFactoryTest/connectedNorth()|,|java+method:///nl/tudelft/jpacman/board/BoardTest/verifyHeight()|,|java+method:///nl/tudelft/jpacman/npc/ghost/Ghost/getInterval()|,|java+method:///nl/tudelft/jpacman/board/BoardTest/verifyWidth()|,|java+method:///nl/tudelft/jpacman/npc/ghost/Ghost/getSprite()|,|java+method:///nl/tudelft/jpacman/ui/BoardPanel/paint(java.awt.Graphics)|,|java+method:///nl/tudelft/jpacman/board/BasicSquare/getSprite()|,|java+method:///nl/tudelft/jpacman/npc/ghost/NavigationTest/setUp()|,|java+method:///nl/tudelft/jpacman/ui/PacManUiBuilder/addStartButton(nl/tudelft/jpacman/game/Game)/$anonymous1/doAction()|,|java+method:///nl/tudelft/jpacman/level/CollisionInteractionMap/collide(C1,C2)|,|java+method:///nl/tudelft/jpacman/sprite/SpriteTest/setUp()|,|java+method:///nl/tudelft/jpacman/ui/PacKeyListener/keyPressed(java.awt.event.KeyEvent)|,|java+method:///nl/tudelft/jpacman/sprite/ImageSprite/getHeight()|,|java+method:///nl/tudelft/jpacman/Launcher/addSinglePlayerKeys(nl/tudelft/jpacman/ui/PacManUiBuilder,nl/tudelft/jpacman/game/Game)/$anonymous4/doAction()|,|java+method:///nl/tudelft/jpacman/game/SinglePlayerGame/getLevel()|,|java+method:///nl/tudelft/jpacman/board/SquareTest/testOrder()|,|java+method:///nl/tudelft/jpacman/board/OccupantTest/setUp()|,|java+method:///nl/tudelft/jpacman/board/SquareTest/setUp()|,|java+method:///nl/tudelft/jpacman/npc/ghost/Inky/nextMove()|,|java+method:///nl/tudelft/jpacman/Launcher/addSinglePlayerKeys(nl/tudelft/jpacman/ui/PacManUiBuilder,nl/tudelft/jpacman/game/Game)/$anonymous3/doAction()|,|java+method:///nl/tudelft/jpacman/level/LevelTest/stop()|,|java+method:///nl/tudelft/jpacman/ui/PacManUiBuilder/addButton(java.lang.String,nl.tudelft.jpacman.ui.Action)|,|java+method:///nl/tudelft/jpacman/board/OccupantTest/noStartSquare()|,|java+method:///nl/tudelft/jpacman/Launcher/addSinglePlayerKeys(nl/tudelft/jpacman/ui/PacManUiBuilder,nl/tudelft/jpacman/game/Game)/$anonymous2/doAction()|,|java+method:///nl/tudelft/jpacman/sprite/SpriteTest/splitHeight()|,|java+method:///nl/tudelft/jpacman/LauncherSmokeTest/smokeTest()|,|java+method:///nl/tudelft/jpacman/sprite/SpriteTest/spriteWidth()|,|java+method:///nl/tudelft/jpacman/board/BoardFactoryTest/connectedSouth()|,|java+method:///nl/tudelft/jpacman/board/BoardFactoryTest/connectedWest()|,|java+method:///nl/tudelft/jpacman/board/BoardTest/verifyX0Y0()|,|java+method:///nl/tudelft/jpacman/Launcher/addSinglePlayerKeys(nl/tudelft/jpacman/ui/PacManUiBuilder,nl/tudelft/jpacman/game/Game)/$anonymous1/doAction()|,|java+method:///nl/tudelft/jpacman/level/DefaultPlayerInteractionMap/defaultCollisions()|,|java+method:///nl/tudelft/jpacman/level/LevelTest/registerPlayer()|,|java+method:///nl/tudelft/jpacman/board/BoardTest/verifyX0Y1()|,|java+method:///nl/tudelft/jpacman/board/BoardFactory/Ground/getSprite()|,|java+method:///nl/tudelft/jpacman/board/BasicUnit/getSprite()|,|java+method:///nl/tudelft/jpacman/ui/PacManUiBuilder/addStopButton(nl/tudelft/jpacman/game/Game)/$anonymous1/doAction()|,|java+method:///nl/tudelft/jpacman/board/BoardTest/verifyX1Y2()|,|java+method:///nl/tudelft/jpacman/ui/PacManUiBuilder/withScoreFormatter(nl.tudelft.jpacman.ui.ScorePanel.ScoreFormatter)|,|java+method:///nl/tudelft/jpacman/LauncherSmokeTest/setUpPacman()|,|java+method:///nl/tudelft/jpacman/sprite/EmptySprite/getWidth()|,|java+method:///nl/tudelft/jpacman/sprite/ImageSprite/split(int,int,int,int)|,|java+method:///nl/tudelft/jpacman/board/BoardFactory/Wall/getSprite()|,|java+method:///nl/tudelft/jpacman/board/OccupantTest/testOccupy()|,|java+method:///nl/tudelft/jpacman/board/SquareTest/testOccupy()|,|java+method:///nl/tudelft/jpacman/level/Level/removeObserver(nl.tudelft.jpacman.level.Level.LevelObserver)|,|java+method:///nl/tudelft/jpacman/level/LevelTest/setUp()|,|java+method:///nl/tudelft/jpacman/board/BoardFactoryTest/setUp()|,|java+method:///nl/tudelft/jpacman/board/SquareTest/testLeave()|,|java+method:///nl/tudelft/jpacman/board/BasicSquare/isAccessibleTo(nl.tudelft.jpacman.board.Unit)|,|java+method:///nl/tudelft/jpacman/sprite/SpriteTest/splitOutOfBounds()|,|java+method:///nl/tudelft/jpacman/sprite/AnimatedSprite/draw(java.awt.Graphics,int,int,int,int)|,|java+method:///nl/tudelft/jpacman/cucumber/StateNavigationSteps/theGameShouldStart()|,|java+method:///nl/tudelft/jpacman/npc/ghost/Clyde/nextMove()|,|java+method:///nl/tudelft/jpacman/level/DefaultPlayerInteractionMap/collide(nl.tudelft.jpacman.board.Unit,nl.tudelft.jpacman.board.Unit)|,|java+method:///nl/tudelft/jpacman/sprite/SpriteTest/animationWidth()|,|java+method:///nl/tudelft/jpacman/npc/ghost/NavigationTest/testFullSizedLevel()|,|java+method:///nl/tudelft/jpacman/level/LevelTest/noStart()|,|java+method:///nl/tudelft/jpacman/board/BoardTest/setUp()|,|java+method:///nl/tudelft/jpacman/npc/ghost/NavigationTest/testNoTraveller()|,|java+method:///nl/tudelft/jpacman/level/Level/NpcMoveTask/run()|,|java+method:///nl/tudelft/jpacman/npc/ghost/NavigationTest/testShortestPathEmpty()|,|java+method:///nl/tudelft/jpacman/sprite/SpriteTest/animationHeight()|,|java+method:///nl/tudelft/jpacman/npc/ghost/NavigationTest/testNoShortestPath()|,|java+method:///nl/tudelft/jpacman/level/LevelTest/start()|,|java+method:///nl/tudelft/jpacman/sprite/EmptySprite/draw(java.awt.Graphics,int,int,int,int)|,|java+method:///nl/tudelft/jpacman/LauncherSmokeTest/tearDown()|,|java+method:///nl/tudelft/jpacman/game/Game/levelWon()|,|java+method:///nl/tudelft/jpacman/game/SinglePlayerGame/getPlayers()|,|java+method:///nl/tudelft/jpacman/ui/PacManUI/start()/$anonymous1/run()|,|java+method:///nl/tudelft/jpacman/npc/ghost/NavigationTest/testNoNearestUnit()|,|java+method:///nl/tudelft/jpacman/level/LevelTest/startStop()|,|java+method:///nl/tudelft/jpacman/level/LevelTest/registerPlayerTwice()|,|java+method:///nl/tudelft/jpacman/npc/ghost/NavigationTest/testNearestUnit()|,|java+method:///nl/tudelft/jpacman/level/DefaultPlayerInteractionMap/defaultCollisions()/$anonymous2/handleCollision(nl.tudelft.jpacman.level.Player,nl.tudelft.jpacman.level.Pellet)|,|java+method:///nl/tudelft/jpacman/level/LevelTest/registerThirdPlayer()|,|java+method:///nl/tudelft/jpacman/Launcher/main(java.lang.String%5B%5D)|,|java+method:///nl/tudelft/jpacman/board/BoardFactory/Ground/isAccessibleTo(nl.tudelft.jpacman.board.Unit)|,|java+method:///nl/tudelft/jpacman/board/BoardFactoryTest/worldIsRound()|,|java+method:///nl/tudelft/jpacman/board/BoardFactoryTest/connectedEast()|,|java+method:///nl/tudelft/jpacman/sprite/EmptySprite/getHeight()|,|java+method:///nl/tudelft/jpacman/ui/ScorePanel/$anonymous1/format(nl.tudelft.jpacman.level.Player)|,|java+method:///nl/tudelft/jpacman/level/PlayerCollisions/collide(nl.tudelft.jpacman.board.Unit,nl.tudelft.jpacman.board.Unit)|,|java+method:///nl/tudelft/jpacman/board/BoardFactory/Wall/isAccessibleTo(nl.tudelft.jpacman.board.Unit)|,|java+method:///nl/tudelft/jpacman/level/Player/getSprite()|,|java+method:///nl/tudelft/jpacman/npc/ghost/NavigationTest/testSimplePath()|,|java+method:///nl/tudelft/jpacman/sprite/EmptySprite/split(int,int,int,int)|,|java+method:///nl/tudelft/jpacman/level/LevelFactory/RandomGhost/nextMove()|,|java+constructor:///nl/tudelft/jpacman/game/Game/Game()|,|java+method:///nl/tudelft/jpacman/cucumber/StateNavigationSteps/theUserHasLaunchedTheJPacmanGUI()|,|java+method:///nl/tudelft/jpacman/sprite/SpriteTest/splitWidth()|,|java+method:///nl/tudelft/jpacman/sprite/SpriteTest/spriteHeight()|,|java+method:///nl/tudelft/jpacman/level/Pellet/getSprite()|,|java+method:///nl/tudelft/jpacman/npc/ghost/NavigationTest/testCornerPath()|,|java+method:///nl/tudelft/jpacman/ui/PacKeyListener/keyTyped(java.awt.event.KeyEvent)|,|java+method:///nl/tudelft/jpacman/sprite/AnimatedSprite/split(int,int,int,int)|,|java+method:///nl/tudelft/jpacman/game/GameFactory/getPlayerFactory()|,|java+method:///nl/tudelft/jpacman/level/LevelTest/registerSecondPlayer()|,|java+method:///nl/tudelft/jpacman/cucumber/StateNavigationSteps/tearDownUI()|,|java+method:///nl/tudelft/jpacman/ui/PacKeyListener/keyReleased(java.awt.event.KeyEvent)|,|java+method:///nl/tudelft/jpacman/game/Game/levelLost()|,|java+method:///nl/tudelft/jpacman/npc/ghost/Blinky/nextMove()|,|java+constructor:///nl/tudelft/jpacman/npc/ghost/Navigation/Navigation()|,|java+method:///nl/tudelft/jpacman/sprite/ImageSprite/getWidth()|,|java+method:///nl/tudelft/jpacman/cucumber/StateNavigationSteps/theUserPressesStart()|,|java+method:///nl/tudelft/jpacman/level/DefaultPlayerInteractionMap/defaultCollisions()/$anonymous1/handleCollision(nl.tudelft.jpacman.level.Player,nl.tudelft.jpacman.npc.ghost.Ghost)|,|java+method:///nl/tudelft/jpacman/ui/ButtonPanel/ButtonPanel(java/util/Map,javax/swing/JFrame)/$anonymous1/actionPerformed(java.awt.event.ActionEvent)|,|java+method:///nl/tudelft/jpacman/level/CollisionInteractionMap/InverseCollisionHandler/handleCollision(C1,C2)|,|java+initializer:///nl/tudelft/jpacman/npc/ghost/Clyde$initializer1|,|java+method:///nl/tudelft/jpacman/npc/ghost/Pinky/nextMove()|,|java+method:///nl/tudelft/jpacman/Launcher/withMapFile(java.lang.String)|,|java+method:///nl/tudelft/jpacman/sprite/SpriteTest/resourceMissing()|]

- how do your results compare to the jpacman results in the paper? Has jpacman improved?
	>Jpacman in the paper has 88.06% for static and 93.53% for clover (in paper). Our result is 61.4%, so our coverage is way worse.

- use a third-party coverage tool (e.g. Clover) to compare your results to (explain differences)
	>clover shows a coverage of 75%. This might be because 4 tests are skipped. Thus not a higher coverage.
	And the difference with out implementation is probably because some methods might indirectly test other methods (or overrides, inheritance, abstract methods) or because of method declarations in interfaces and such. Which we think are a method that should be tested, but clover doesnt think that. 

*/
public void solve1(){		
	Relation declsProgram = programJpacmanM3().declarations;
	declarations = dup([decl |decl <- declsProgram.first, isMethod(decl)]);
	
	Relation testDecls = testJpacmanM3().declarations;
	
	testMethods = [decl.first | decl <- testDecls, isMethod(decl.first)];
	
	Relation allInvocations = wholeJpacmanM3().methodInvocation;
	testMethodInvocations = [decl.second |decl <- allInvocations, decl.first in testMethods , isMethod(decl.second)];
	nonTestMethods = [decl.first| decl <- declsProgram, isMethod(decl.first)];
	isCalledByTest = [m| m <- testMethodInvocations, m in nonTestMethods];
	
	sizeTestmethodInvocations = size(dup(testMethodInvocations));
	sizeNonTestMethods = size(dup(nonTestMethods));
	isCalledByTestMethodInvocationSize = size(dup(isCalledByTest));
	testedPercentage = ((isCalledByTestMethodInvocationSize * 1.0) / (sizeNonTestMethods * 1.0)) * 100.0;
	println("Percentage called: <testedPercentage>");
	print("Methods that are not tested: "); println(nonTestMethods - isCalledByTest);
}

M3 programJpacmanM3() = createM3FromEclipseProject(|project://jpacman-framework/src/main/java/nl/tudelft/jpacman/|);
M3 testJpacmanM3() = createM3FromEclipseProject(|project://jpacman-framework/src/test/java/nl/tudelft/jpacman/|); 
M3 wholeJpacmanM3() = createM3FromEclipseProject(|project://jpacman-framework/src/|);

alias Relation = rel[Node first, Node second];

alias Node = loc;

