package mantra;

import org.antlr.v4.runtime.*;
import org.antlr.v4.runtime.tree.ParseTree;
import org.antlr.v4.tool.Grammar;

import java.io.IOException;

public class Parse {
	public static final String MantraGrammar =
		"/Users/parrt/mantra/code/grammar/src/grammar/mantra/Mantra.g4";

	public static void main(String[] args) throws Exception {
        for (int i = 0; i < args.length; i++) {
            String fileName = args[i];
            ParseTree t = parse(fileName, MantraGrammar, "compilationUnit");
        }
	}
	public static ParseTree parse(String fileName,
								  String combinedGrammarFileName,
								  String startRule)
		throws IOException
	{
		final Grammar g = Grammar.load(combinedGrammarFileName);
		LexerInterpreter lexEngine = g.createLexerInterpreter(new ANTLRFileStream(fileName));
		CommonTokenStream tokens = new CommonTokenStream(lexEngine);
		ParserInterpreter parser = g.createParserInterpreter(tokens);
		try {
            ParseTree t = parser.parse(g.getRule(startRule).index);
            System.out.println("parse tree: " + t.toStringTree(parser));
            ((ParserRuleContext)t).inspect(parser);
            return t;
        }
        catch (RecognitionException re) {
            DefaultErrorStrategy strat = new DefaultErrorStrategy();
            strat.reportError(parser, re);
        }
        return null;
	}

/*
	public static ParseTree parse(String fileNameToParse,
								  String lexerGrammarFileName,
								  String parserGrammarFileName,
								  String startRule)
		throws IOException
	{
		Tool antlr = new Tool();

		final LexerGrammar lg = (LexerGrammar)antlr.loadGrammar(lexerGrammarFileName);
		final Grammar pg = loadGrammar(antlr, parserGrammarFileName, lg);

		ANTLRFileStream input = new ANTLRFileStream(fileNameToParse);
		LexerInterpreter lexEngine = lg.createLexerInterpreter(input);
		CommonTokenStream tokens = new CommonTokenStream(lexEngine);
		ParserInterpreter parser = pg.createParserInterpreter(tokens);
        try {
            ParseTree t = parser.parse(pg.getRule(startRule).index);
            System.out.println("parse tree: "+t.toStringTree(parser));
            return t;
        }
        catch (RecognitionException re) {
            DefaultErrorStrategy strat = new DefaultErrorStrategy();
            strat.reportError(parser, re);
        }
        return null;
	}

	// Same as loadGrammar(fileName) except import vocab from existing lexer
	public static Grammar loadGrammar(Tool tool, String fileName, LexerGrammar lexerGrammar) {
		GrammarRootAST grammarRootAST = tool.parseGrammar(fileName);
		final Grammar g = tool.createGrammar(grammarRootAST);
		g.fileName = fileName;
		g.importVocab(lexerGrammar);
		tool.process(g, false);
		return g;
	}
*/
}
