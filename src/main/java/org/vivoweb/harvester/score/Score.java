/*******************************************************************************
 * Copyright (c) 2010 Christopher Haines, Dale Scheppler, Nicholas Skaggs, Stephen V. Williams, James Pence. All rights reserved.
 * This program and the accompanying materials are made available under the terms of the new BSD license which
 * accompanies this distribution, and is available at http://www.opensource.org/licenses/bsd-license.html Contributors:
 * Christopher Haines, Dale Scheppler, Nicholas Skaggs, Stephen V. Williams, James Pence - initial API and implementation Christopher
 * Barnes, Narayan Raum - scoring ideas and algorithim Yang Li - pairwise scoring algorithm Christopher Barnes - regex
 * scoring algorithim
 ******************************************************************************/
package org.vivoweb.harvester.score;

import java.io.IOException;
import java.util.HashMap;
import java.util.Map;
import java.util.Stack;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.vivoweb.harvester.util.InitLog;
import org.vivoweb.harvester.util.IterableAdaptor;
import org.vivoweb.harvester.util.args.ArgDef;
import org.vivoweb.harvester.util.args.ArgList;
import org.vivoweb.harvester.util.args.ArgParser;
import org.vivoweb.harvester.util.repo.JenaConnect;
import org.vivoweb.harvester.util.repo.MemJenaConnect;
import org.vivoweb.harvester.util.repo.SDBJenaConnect;
import com.hp.hpl.jena.query.Dataset;
import com.hp.hpl.jena.query.Query;
import com.hp.hpl.jena.query.QueryExecution;
import com.hp.hpl.jena.query.QueryExecutionFactory;
import com.hp.hpl.jena.query.QueryFactory;
import com.hp.hpl.jena.query.QuerySolution;
import com.hp.hpl.jena.query.Syntax;
import com.hp.hpl.jena.rdf.model.Property;
import com.hp.hpl.jena.rdf.model.Resource;
import com.hp.hpl.jena.rdf.model.ResourceFactory;
import com.hp.hpl.jena.rdf.model.Statement;
import com.hp.hpl.jena.rdf.model.StmtIterator;
import com.hp.hpl.jena.util.ResourceUtils;

/**
 * VIVO Score
 * @author Nicholas Skaggs nskaggs@ctrip.ufl.edu
 * @author Stephen Williams svwilliams@ctrip.ufl.edu
 * @author Christopher Haines hainesc@ctrip.ufl.edu
 */
public class Score {
	/**
	 * SLF4J Logger
	 */
	private static Logger log = LoggerFactory.getLogger(Score.class);
	/**
	 * Model for VIVO instance
	 */
	private final JenaConnect vivo;
	/**
	 * Model where input is stored
	 */
	private final JenaConnect scoreInput;
	/**
	 * Model where output is stored
	 */
	private final JenaConnect scoreOutput;
	/**
	 * Option to remove input model after scoring
	 */
	private final boolean wipeInputModel;
	/**
	 * Option to remove output model before filling
	 */
	private final boolean wipeOutputModel;
	/**
	 * Option to push Matches and Non-Matches to output model
	 */
	private final boolean pushAll;
	/**
	 * Predicates for match algorithm
	 */
	private final Map<String, String> matchList;
	/**
	 * Link the resources found by match algorithm
	 */
	private final String linkProp;
	/**
	 * Rename resources found by match algorithm
	 */
	private final boolean renameRes;
	/**
	 * Argument for inplace scoring (ie not changing models) 
	 */
	private final boolean inPlace;
	/**
	 * Namespace for match algorithm
	 */
	private final String matchNamespace;
	
	/**
	 * Constructor
	 * @param vivo model containing vivo statements
	 * @param scoreInput model containing statements to be scored
	 * @param scoreOutput output model
	 * @param clearInputModelArg If set, this will clear the input model after scoring is complete
	 * @param clearOutputModelArg If set, this will clear the output model before scoring begins
	 * @param matchArg predicate pairs to match on
	 * @param renameRes should I just rename the args?
	 * @param linkProp bidirectional link
	 * @param matchNamespace namespace to match in (null matches any)
	 * @param inPlace inplace scoring
	 * @param pushAll push Matches and Non-Matches to output model
	 */
	public Score(JenaConnect scoreInput, JenaConnect vivo, JenaConnect scoreOutput, boolean clearInputModelArg, boolean clearOutputModelArg, Map<String, String> matchArg, boolean renameRes, String linkProp, String matchNamespace, boolean inPlace, boolean pushAll) {
		this.wipeInputModel = clearInputModelArg;
		this.wipeOutputModel = clearOutputModelArg;
		this.matchList = matchArg;
		this.pushAll = pushAll;
		this.inPlace = inPlace;
		this.renameRes = renameRes;
		this.linkProp = linkProp;
		this.matchNamespace = matchNamespace;
		this.vivo = vivo;
		this.scoreInput = scoreInput;
		this.scoreOutput = scoreOutput;		
	}
	
	/**
	 * Constructor
	 * @param args argument list
	 * @throws IOException error parsing options
	 */
	public Score(String... args) throws IOException {
		this(new ArgList(getParser(), args));
	}
	
	/**
	 * Constructor
	 * @param opts parsed argument list
	 * @throws IOException error parsing options
	 */
	public Score(ArgList opts) throws IOException {
		// Get optional inputs / set defaults
		// Check for config files, before parsing name options
		String jenaVIVO = opts.get("v");
		
		Map<String,String> inputOverrides = opts.getValueMap("I");
		String jenaInput;
		if (opts.has("i")) {
			jenaInput = opts.get("i");
		} else {
			jenaInput = jenaVIVO;
			if (!inputOverrides.containsKey("modelName")) {
				inputOverrides.put("modelName", "Scoring");
			}
		}
		
		Map<String,String> outputOverrides = opts.getValueMap("O");
		String jenaOutput;
		if (opts.has("o")) {
			jenaOutput = opts.get("o");
		} else {
			jenaOutput = jenaVIVO;
			if (!outputOverrides.containsKey("modelName")) {
				outputOverrides.put("modelName", "Staging");
			}
		}
		
		// Connect to vivo
		this.vivo = JenaConnect.parseConfig(jenaVIVO, opts.getValueMap("V"));
		
		// Create working model
		this.scoreInput = JenaConnect.parseConfig(jenaInput, inputOverrides);
		
		// Create output model
		if(opts.has("a")){
			this.scoreOutput = this.scoreInput;
		} else {
			this.scoreOutput = JenaConnect.parseConfig(jenaOutput, outputOverrides);
		}
		
		this.wipeInputModel = opts.has("w");
		this.wipeOutputModel = opts.has("q");
		this.pushAll = opts.has("l");
		this.matchList = opts.getValueMap("m");
		this.inPlace = opts.has("a");
		this.renameRes = opts.has("r");
		this.linkProp = opts.get("l");
		this.matchNamespace = opts.get("n");
	}
	
	/* *
	 * Traverses paperNode and adds to toReplace model
	 * @param mainNode primary node
	 * @param paperNode node of paper
	 * @param toReplace model to replace
	 * /
	private static void replaceResource(Resource mainNode, Resource paperNode, JenaConnect toReplace) {
		Resource authorship;
		String authorQuery;
		Property linkedAuthorOf = ResourceFactory.createProperty("http://vivoweb.org/ontology/core#linkedAuthor");
		Property authorshipForPerson = ResourceFactory.createProperty("http://vivoweb.org/ontology/core#authorInAuthorship");
		
		Property authorshipForPaper = ResourceFactory.createProperty("http://vivoweb.org/ontology/core#informationResourceInAuthorship");
		Property paperOf = ResourceFactory.createProperty("http://vivoweb.org/ontology/core#linkedInformationResource");
		Property rankOf = ResourceFactory.createProperty("http://vivoweb.org/ontology/core#authorRank");
		
		Resource flag1 = ResourceFactory.createResource("http://vitro.mannlib.cornell.edu/ns/vitro/0.7#Flag1Value1Thing");
		Resource authorshipClass = ResourceFactory.createResource("http://vivoweb.org/ontology/core#Authorship");
		
		Property rdfType = ResourceFactory.createProperty("http://www.w3.org/1999/02/22-rdf-syntax-ns#type");
		Property rdfLabel = ResourceFactory.createProperty("http://www.w3.org/2000/01/rdf-schema#label");
		int authorRank = 1;
		
		log.trace("Link paper <" + paperNode + "> to person <" + mainNode + "> in VIVO");
		authorship = ResourceFactory.createResource(paperNode.toString() + "/vivoAuthorship/l1");
		
		// string that finds the last name of the person in VIVO
		Statement authorLName = mainNode.getProperty(ResourceFactory.createProperty("http://xmlns.com/foaf/0.1/lastName"));
		
		if (authorLName == null) {
			Statement authorworkEmail = mainNode.getProperty(ResourceFactory.createProperty("http://vivoweb.org/ontology/core#workEmail"));
			log.debug("Author Last name property is null, trying to find via email");
			if (authorworkEmail == null) {
				log.warn("Cannot find author -- linking failed");
				return;
			}
			authorQuery =	"PREFIX core: <http://vivoweb.org/ontology/core#> "+
							"SELECT ?badNode " +
							"WHERE {" +
								"?badNode core:workEmail ?value . " +
								"?badNode core:authorInAuthorship ?authorship . " +
								"?authorship core:linkedInformationResource <" + paperNode.toString() + "> ." +
								"FILTER (str(?value) = \"" + authorworkEmail.getObject().asLiteral().getValue() + "\")" +
							" }";
		} else {
			authorQuery =	"PREFIX core: <http://vivoweb.org/ontology/core#> " +
							"PREFIX foaf: <http://xmlns.com/foaf/0.1/> " +
							"SELECT ?badNode " +
							"WHERE {" +
								"?badNode foaf:lastName ?value . " +
								"?badNode core:authorInAuthorship ?authorship . " +
								"?authorship core:linkedInformationResource <" + paperNode.toString() + ">" +
								"FILTER (str(?value) = \"" + authorLName.getObject().asLiteral().getValue() + "\")" +
							"}";
		}
		
		log.debug(authorQuery);
		
		ResultSet killList = toReplace.executeSelectQuery(authorQuery);
		
		while (killList.hasNext()) {
			QuerySolution killSolution = killList.next();
			
			// Grab person URI
			Resource removeAuthor = killSolution.getResource("badNode");
			
			// query the paper for the first author node (assumption that affiliation matches first author)
			log.debug("Delete Resource " + removeAuthor.toString());
			
			// return a statement iterator with all the statements for the Author that matches, then remove those
			// statements
			// model.remove is broken so we are using statement.remove
			StmtIterator deleteStmts = toReplace.getJenaModel().listStatements(null, null, removeAuthor);
			while (deleteStmts.hasNext()) {
				Statement dStmt = deleteStmts.next();
				log.debug("Delete Statement " + dStmt.toString());
				
				if (!dStmt.getSubject().equals(removeAuthor)) {
					Statement authorRankStmt = dStmt.getSubject().getProperty(rankOf);
					authorRank = authorRankStmt.getObject().asLiteral().getInt();
					
					StmtIterator authorshipStmts = dStmt.getSubject().listProperties();
					while (authorshipStmts.hasNext()) {
						log.debug("Delete Statement " + authorshipStmts.next().toString());
					}
					dStmt.getSubject().removeProperties();
					
					StmtIterator deleteAuthorshipStmts = toReplace.getJenaModel().listStatements(null, null, dStmt.getSubject());
					while (deleteAuthorshipStmts.hasNext()) {
						Statement dASStmt = deleteAuthorshipStmts.next();
						log.debug("Delete Statement " + dASStmt.toString());
						dASStmt.remove();
					}
					
				}
				
			}
			
			StmtIterator authorStmts = removeAuthor.listProperties();
			while (authorStmts.hasNext()) {
				log.debug("Delete Statement " + authorStmts.next().toString());
			}
			removeAuthor.removeProperties();
		}
		
		toReplace.getJenaModel().add(authorship, linkedAuthorOf, mainNode);
		log.trace("Link Statement [" + authorship.toString() + ", " + linkedAuthorOf.toString() + ", " + mainNode.toString() + "]");
		toReplace.getJenaModel().add(mainNode, authorshipForPerson, authorship);
		log.trace("Link Statement [" + mainNode.toString() + ", " + authorshipForPerson.toString() + ", " + authorship.toString() + "]");
		toReplace.getJenaModel().add(authorship, paperOf, paperNode);
		log.trace("Link Statement [" + authorship.toString() + ", " + paperOf.toString() + ", " + paperNode.toString() + "]");
		toReplace.getJenaModel().add(paperNode, authorshipForPaper, authorship);
		log.trace("Link Statement [" + paperNode.toString() + ", " + authorshipForPaper.toString() + ", " + authorship.toString() + "]");
		toReplace.getJenaModel().add(authorship, rdfType, flag1);
		log.trace("Link Statement [" + authorship.toString() + ", " + rdfType.toString() + ", " + flag1.toString() + "]");
		toReplace.getJenaModel().add(authorship, rdfType, authorshipClass);
		log.trace("Link Statement [" + authorship.toString() + ", " + rdfType.toString() + ", " + authorshipClass.toString() + "]");
		toReplace.getJenaModel().add(authorship, rdfLabel, "Authorship for Paper");
		log.trace("Link Statement [" + authorship.toString() + ", " + rdfLabel.toString() + ", " + "Authorship for Paper]");
		toReplace.getJenaModel().addLiteral(authorship, rankOf, authorRank);
		log.trace("Link Statement [" + authorship.toString() + ", " + rankOf.toString() + ", " + String.valueOf(authorRank) + "]");
		
		toReplace.getJenaModel().commit();
	}*/
	
	/* *
	 * Match on two predicates and insert foreign key links for each match
	 * @param scoreAttribute the predicate of the object in scoring to match on
	 * @param vivoAttribute the predicate of the object in vivo to match on
	 * @param scoreToVIVONode the predicate that connects the object in score to the object in vivo
	 * @param vivoToScoreNode the predicate that connects the object in vivo to the object in score
	 * /
	public void foreignKeyMatch(String scoreAttribute, String vivoAttribute, String scoreToVIVONode, String vivoToScoreNode) {
		// Foreign Key Match
		log.info("Executing foreignKeyMatch for <" + scoreAttribute + "> against <" + vivoAttribute + ">");
		Property scoreAttr = this.scoreInput.getJenaModel().getProperty(scoreAttribute);
		StmtIterator stmtitr = this.scoreInput.getJenaModel().listStatements(null, scoreAttr, (RDFNode)null);
		if (!stmtitr.hasNext()) {
			log.trace("No matches found for <" + scoreAttribute + "> in input");
			return;
		}
		log.trace("Matches found for <" + scoreAttribute + "> in input");
		// look for exact match in vivo
		for (Statement stmt : IterableAdaptor.adapt(stmtitr)) {
			Resource sub = stmt.getSubject();
			String obj = stmt.getLiteral().getValue().toString();
			log.trace("Checking for \"" + obj + "\" from <" + sub + "> in VIVO");
			String query = ""+
				"SELECT ?sub"+"\n"+
				"WHERE {"+"\n\t"+
					"?sub <" + vivoAttribute + "> ?obj ."+"\n\t"+
					"FILTER (str(?obj) = \"" + obj + "\")"+"\n"+
				"}";
			log.debug(query);
			ResultSet matches = this.vivo.executeSelectQuery(query);
			if (!matches.hasNext()) {
				log.trace("No matches in VIVO found");
				if (this.pushAll) {
					this.scoreOutput.getJenaModel().add(recursiveSanitizeBuild(sub, new Stack<Resource>()).getJenaModel());
				}
			} else {
				log.trace("Matches in VIVO found");
				// loop thru resources
				while (matches.hasNext()) {
					// Grab person URI
					Resource vivoNode = matches.next().getResource("sub");
					log.trace("Found <" + sub + "> for VIVO entity <" + vivoNode + ">");
					log.trace("Adding entity <" + sub + "> to output");
					
					this.scoreOutput.getJenaModel().add(recursiveSanitizeBuild(sub, new Stack<Resource>()).getJenaModel());
					
					log.trace("Linking entity <" + sub + "> to VIVO entity <" + vivoNode + ">");
					
					this.scoreOutput.getJenaModel().add(sub, ResourceFactory.createProperty(scoreToVIVONode), vivoNode);
					this.scoreOutput.getJenaModel().add(vivoNode, ResourceFactory.createProperty(vivoToScoreNode), sub);
					
					// take results and store in matched model
					this.scoreOutput.getJenaModel().commit();
				}
			}
		}
	}*/
	
	/* *
	 * Executes an exact matching algorithm for author disambiguation
	 * @param scoreAttribute attribute to perform the exact match in scoring
	 * @param vivoAttribute attribute to perform the exact match in vivo
	 * similarly linked item eg. -f <http://site/workEmail>,<http://vivo/workEmail> -toVivo <objectProperty>
	 * -toScoreItem <objectProperty> Thinking out loud - we'll need to modify the end results of exact match now that we
	 * are not creating authorships and authors for pubmed entries we'll need to just link the author whose name parts
	 * match someone in vivo Working on that now
	 * /
	public void exactMatch(String scoreAttribute, String vivoAttribute) {
		String queryString;
		String matchValue;
		Resource paperNode;
		
		ResultSet scoreInputResult;
		
		String matchQuery = "SELECT ?x ?scoreAttribute " + "WHERE { ?x <" + scoreAttribute + "> ?scoreAttribute}";
		
		// Exact Match
		log.info("Executing exactMatch for <" + scoreAttribute + "> against <" + vivoAttribute + ">");
		log.debug(matchQuery);
		scoreInputResult = this.scoreInput.executeSelectQuery(matchQuery);
		
		// Log extra info message if none found
		if (!scoreInputResult.hasNext()) {
			log.trace("No matches found for <" + scoreAttribute + "> in input");
		} else {
			log.trace("Looping thru matching <" + scoreAttribute + "> from input");
		}
		
		// look for exact match in vivo
		for (QuerySolution scoreSolution : IterableAdaptor.adapt(scoreInputResult)) {
			matchValue = scoreSolution.getLiteral("scoreAttribute").getValue().toString();
			paperNode = scoreSolution.getResource("x");
			
			log.trace("Checking for \"" + matchValue + "\" from <" + paperNode + "> in VIVO");
			
			// Select all matching attributes from vivo store
			queryString =	"SELECT ?x " + 
							"WHERE { " + 
								"?x <" + vivoAttribute + "> ?value " + 
								"FILTER (str(?value) = \"" + matchValue + "\")" +
							"}";
			
			log.debug(queryString);
			
			commitResultSet(this.scoreOutput, this.vivo.executeSelectQuery(queryString), matchValue, paperNode);
		}
	}*/
	
	/**
	 * find all nodes in the given namepsace matching on the given predicates
	 * @param matchMap properties set of predicates to be searched for in vivo and score. Formats is "vivoProp => inputProp"
	 * @param namespace the namespace to match in
	 * @return mapping of the found matches
	 * @throws IOException error connecting to dataset
	 */
	private Map<String,String> match(Map<String, String> matchMap, String namespace) throws IOException{
		if (matchMap.size() < 1) {
			throw new IllegalArgumentException("No properties! SELECT cannot be created!");
		}
			
		//Build query to find all nodes matching on the given predicates
		StringBuilder sQuery =	new StringBuilder("" +
				"PREFIX scoreClone: <http://vivoweb.org/harvester/model/scoring#>" +
				"SELECT ?sVivo ?sScore\n" +
				"FROM NAMED <http://vivoweb.org/harvester/model/scoring#vivoClone>\n" +
				"FROM NAMED <http://vivoweb.org/harvester/model/scoring#inputClone>\n" +
				"WHERE {\n");

		int counter = 0;
		StringBuilder vivoWhere = new StringBuilder("  GRAPH scoreClone:vivoClone {\n");
		StringBuilder scoreWhere = new StringBuilder("  GRAPH scoreClone:inputClone {\n");
		StringBuilder filter = new StringBuilder("  FILTER( ");
		
		for (String property : matchMap.keySet()) {
			vivoWhere.append("    ?sVivo <").append(property).append("> ").append("?ov" + counter).append(" . \n");
			scoreWhere.append("    ?sScore <").append(matchMap.get(property)).append("> ").append("?os" + counter).append(" . \n");
			filter.append("sameTerm(?os" + counter + ", ?ov" + counter + ") && ");
			counter++;
		}
		
		vivoWhere.append("  } . \n");
		scoreWhere.append("  } . \n");
		filter.append("(str(?sVivo) != str(?sScore))");
		if(namespace != null) {
			filter.append(" && regex(str(?sScore), \"^"+namespace+"\")");
		}
		filter.append(" ) .\n");
		
		sQuery.append(vivoWhere.toString());
		sQuery.append(scoreWhere.toString());
		sQuery.append(filter.toString());
		sQuery.append("}");
		
		log.debug("Match Query:\n"+sQuery.toString());
		
		SDBJenaConnect unionModel = new MemJenaConnect();
		JenaConnect vivoClone = unionModel.neighborConnectClone("http://vivoweb.org/harvester/model/scoring#vivoClone");
		vivoClone.importRdfFromJC(this.vivo);
		JenaConnect inputClone = unionModel.neighborConnectClone("http://vivoweb.org/harvester/model/scoring#inputClone");
		inputClone.importRdfFromJC(this.scoreInput);
		Dataset ds = unionModel.getConnectionDataSet();
		
		Query query = QueryFactory.create(sQuery.toString(), Syntax.syntaxARQ);
		QueryExecution queryExec = QueryExecutionFactory.create(query, ds);
		HashMap<String,String> uriArray = new HashMap<String,String>();
		for(QuerySolution solution : IterableAdaptor.adapt(queryExec.execSelect())) {
			uriArray.put(solution.getResource("sScore").getURI(), solution.getResource("sVivo").getURI());
		}

		log.info("Match found " + uriArray.keySet().size() + " links between Vivo and the Input model");
		
		return uriArray;
	}

	
	/**
	 * Rename the resource set as the key to the value matched.  Performs check for inplace && pushall.
	 * 
	 * @param matchSet a result set of scoreResources, vivoResources
	 * @throws IOException error connecting
	 */
	private void rename(Map<String,String> matchSet) throws IOException{
		Resource res;
		
		for(String oldUri : matchSet.keySet()) {
			//check for inplace - if we're doing this inplace or we're pushing all, scoreoutput has been set/copied from scoreinput
			if (!this.inPlace && !this.pushAll){
				this.scoreOutput.getJenaModel().add(recursiveBuild(this.scoreInput.getJenaModel().getResource(oldUri),new Stack<Resource>()).getJenaModel());
			}
			
			//get resource in output model and perform rename
			res = this.scoreOutput.getJenaModel().getResource(oldUri);	
			ResourceUtils.renameResource(res, matchSet.get(oldUri));
		}
	}
	
	/**
	 * 
	 * @param matchSet a result set of scoreResources, vivoResources
	 * @param objPropList the object properties to be used to link the two items set in string form -> vivo-object-property-to-score-object = score-object-property-to-vivo-object
	 * @throws IOException error connecting
	 */
	private void link(Map<String,String> matchSet, String objPropList) throws IOException {
		Resource scoreRes;
		Resource vivoRes;
		Property scoreToVivoObjProp = ResourceFactory.createProperty("scoreToVivoObjProp");
		Property vivoToScoreObjProp = ResourceFactory.createProperty("vivoToScoreObjProp");
		
		//split the objPropList into its vivo and score components (vivo->score=score->vivo)
		String[] objPropArray = objPropList.split("=");
		if(objPropArray.length != 2){
			log.error("Two object properties vivo-object-property-to-score-object and score-object-property-to-vivo-object " +
					"sepearated by an equal sign must be set to link resources");
		} else {
			vivoToScoreObjProp = ResourceFactory.createProperty(objPropArray[0]);
			scoreToVivoObjProp = ResourceFactory.createProperty(objPropArray[1]);
		}
		
		
		for(String oldUri : matchSet.keySet()) {
			//check for inplace - if we're doing this inplace or we're pushing all, scoreoutput has been set/copied from scoreinput
			if (!this.inPlace && !this.pushAll){
				this.scoreOutput.getJenaModel().add(recursiveBuild(this.scoreInput.getJenaModel().getResource(oldUri),new Stack<Resource>()).getJenaModel());
			}
			
			scoreRes = this.scoreOutput.getJenaModel().getResource(oldUri);	
			vivoRes = this.vivo.getJenaModel().getResource(matchSet.get(oldUri));
			this.scoreOutput.getJenaModel().add(vivoRes, vivoToScoreObjProp, scoreRes);
			this.scoreOutput.getJenaModel().add(scoreRes, scoreToVivoObjProp, vivoRes);			
		}
		
		
	}

	
	/**
	 * Traverses paperNode and adds to toReplace model
	 * @param mainRes the main resource
	 * @param linkRes the resource to link it to
	 * @return the model containing the sanitized info so far
	 * TODO change linkRes to be a string builder of the URI of the resource, that way you can do a String.Contains() for the URI of a resource
	 * @throws IOException error connecting
	 */
	private static JenaConnect recursiveBuild(Resource mainRes, Stack<Resource> linkRes) throws IOException {
		JenaConnect returnModel = new MemJenaConnect();
		StmtIterator mainStmts = mainRes.listProperties();
		
		while (mainStmts.hasNext()) {
			Statement stmt = mainStmts.nextStatement();
			
				// log.debug(stmt.toString());
				returnModel.getJenaModel().add(stmt);
				
				//todo change the equals t o
				if (stmt.getObject().isResource() && !linkRes.contains(stmt.getObject().asResource()) && !stmt.getObject().asResource().equals(mainRes)) {
					linkRes.push(mainRes);
					returnModel.getJenaModel().add(recursiveBuild(stmt.getObject().asResource(), linkRes).getJenaModel());
					linkRes.pop();
				}
				if (!linkRes.contains(stmt.getSubject()) && !stmt.getSubject().equals(mainRes)) {
					linkRes.push(mainRes);
					returnModel.getJenaModel().add(recursiveBuild(stmt.getSubject(), linkRes).getJenaModel());
					linkRes.pop();
				}
		}
		
		return returnModel;
	}
	
	/**
	 * Close the resources used by score
	 */
	public void close() {
		// Close and done
		this.scoreInput.close();
		this.scoreOutput.close();
		this.vivo.close();
	}
	
	/**
	 * Get the OptionParser
	 * @return the OptionParser
	 */
	private static ArgParser getParser() {
		ArgParser parser = new ArgParser("Score");
		// Inputs
		parser.addArgument(new ArgDef().setShortOption('i').setLongOpt("input-config").setDescription("inputConfig JENA configuration filename, by default the same as the vivo JENA configuration file").withParameter(true, "CONFIG_FILE"));
		parser.addArgument(new ArgDef().setShortOption('v').setLongOpt("vivo-config").setDescription("vivoConfig JENA configuration filename").withParameter(true, "CONFIG_FILE").setRequired(true));
		
		// Outputs
		parser.addArgument(new ArgDef().setShortOption('o').setLongOpt("output-config").setDescription("outputConfig JENA configuration filename, by default the same as the vivo JENA configuration file").withParameter(true, "CONFIG_FILE"));
		
		// Model name overrides
		parser.addArgument(new ArgDef().setShortOption('V').setLongOpt("vivoOverride").withParameterValueMap("JENA_PARAM", "VALUE").setDescription("override the JENA_PARAM of vivo jena model config using VALUE").setRequired(false));
		parser.addArgument(new ArgDef().setShortOption('I').setLongOpt("inputOverride").withParameterValueMap("JENA_PARAM", "VALUE").setDescription("override the JENA_PARAM of input jena model config using VALUE").setRequired(false));
		parser.addArgument(new ArgDef().setShortOption('O').setLongOpt("outputOverride").withParameterValueMap("JENA_PARAM", "VALUE").setDescription("override the JENA_PARAM of output jena model config using VALUE").setRequired(false));
		
		// Matching Algorithms 
		parser.addArgument(new ArgDef().setShortOption('m').setLongOpt("match").withParameterValueMap("VIVO_PREDICATE", "SCORE_PREDICATE").setDescription("find matching rdf nodes where the value of SCORE_PREDICATE in the scoring model is the same as VIVO_PREDICATE in the vivo model").setRequired(false));
		
		// Matching Params
		parser.addArgument(new ArgDef().setShortOption('n').setLongOpt("namespaceMatch").withParameter(true, "SCORE_NAMESPACE").setDescription("limit match algorithm to only match rdf nodes whose URI begin with SCORE_NAMESPACE").setRequired(false));
		
		// Linking Methods
		parser.addArgument(new ArgDef().setShortOption('l').setLongOpt("link").setDescription("link the two matched entities together using the pair of object properties vivoObj=scoreObj").withParameter(false, "RDF_PREDICATE"));
		parser.addArgument(new ArgDef().setShortOption('r').setLongOpt("rename").setDescription("rename or remove the matched entity from scoring").setRequired(false));
		
		// options
		parser.addArgument(new ArgDef().setShortOption('a').setLongOpt("link-rename-inplace").setDescription("If set, this will not use the output model it will manipulate the records in place"));
		parser.addArgument(new ArgDef().setShortOption('w').setLongOpt("wipe-input-model").setDescription("If set, this will clear the input model after scoring is complete"));
		parser.addArgument(new ArgDef().setShortOption('q').setLongOpt("wipe-output-model").setDescription("If set, this will clear the output model before scoring begins"));
		parser.addArgument(new ArgDef().setShortOption('p').setLongOpt("push-all").setDescription("If set, this will push all matches and non matches to output model"));
				
		return parser;
	}	
	
	/**
	 * Execute score object algorithms
	 * @throws IOException error connecting
	 */
	public void execute() throws IOException {
		log.info("Running specified algorithims");
		
		// Empty input model
		if(this.wipeOutputModel) {
			log.info("Emptying output model");	
			this.scoreOutput.truncate();
		}
		
		if(this.pushAll) {
			this.scoreOutput.getJenaModel().add(this.scoreInput.getJenaModel());
		}
		
		if(this.matchList != null && !this.matchList.isEmpty()) {
			Map<String,String> resultMap = match(this.matchList, this.matchNamespace);
			
			if(this.renameRes) {
				rename(resultMap);
			} else if(this.linkProp != null && !this.linkProp.isEmpty()) {
				link(resultMap,this.linkProp);
			}			
		}
		
		// Empty input model
		if(this.wipeInputModel) {
			log.info("Emptying input model");	
			this.scoreInput.truncate();
		}
	}	

	/**
	 * Main method
	 * @param args command line arguments
	 */
	public static void main(String... args) {
		InitLog.initLogger(Score.class);
		log.info(getParser().getAppName()+": Start");
		try {
			Score Scoring = new Score(args);
			Scoring.execute();
			Scoring.close();
		} catch(IllegalArgumentException e) {
			log.error(e.getMessage(), e);
			System.out.println(getParser().getUsage());
		} catch(Exception e) {
			log.error(e.getMessage(), e);
		}
		log.info(getParser().getAppName()+": End");
	}
	
}
