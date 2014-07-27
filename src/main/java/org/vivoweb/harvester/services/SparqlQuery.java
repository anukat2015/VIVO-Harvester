/*******************************************************************************
 * Copyright (c) 2010-2011 VIVO Harvester Team. For full list of contributors, please see the AUTHORS file provided.
 * All rights reserved.
 * This program and the accompanying materials are made available under the terms of the new BSD license which accompanies this distribution, and is available at http://www.opensource.org/licenses/bsd-license.html
 ******************************************************************************/
package org.vivoweb.harvester.services;

import java.io.IOException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.vivoweb.harvester.util.InitLog;
import org.vivoweb.harvester.util.args.ArgDef;
import org.vivoweb.harvester.util.args.ArgList;
import org.vivoweb.harvester.util.args.ArgParser;
import org.vivoweb.harvester.util.args.UsageException;
import org.vivoweb.harvester.util.repo.JenaConnect;
import org.vivoweb.harvester.util.repo.MemJenaConnect;
import org.vivoweb.harvester.util.repo.RecordHandler;

/**
 * Execute Sparql update in Jena model in an instance of VIVO
 * using SparqlQuery web service
 * @author John Fereira (jaf30@cornell.edu) 
 */
public class SparqlQuery {
	/**
	 * SLF4J Logger
	 */
	private static Logger log = LoggerFactory.getLogger(SparqlQuery.class);
	/**
	 * Model to write to
	 */
	private String model;	 
	 
	/**
	 * sparql query
	 */
	private String query;
	
	/*
	 * VIVO admin user name
	 */
	private String username;
	
	/*
	 * VIVO admin password
	 */
	private String password; 
	
	/*
	 * Sparql update URL
	 */
	private String url;
	 
	
	/**
	 * Constructor
	 * @param args commandline arguments
	 * @throws IOException error parsing options
	 * @throws UsageException user requested usage message
	 */
	private SparqlQuery(String... args) throws IOException, UsageException {
		this(getParser().parse(args));
	}
	
	/**
	 * Constructor
	 * @param argList parsed argument list
	 * @throws IOException error creating task
	 */
	private SparqlQuery(ArgList argList) throws IOException {
		 
		// setup output
		this.model = argList.get("m");
		
		// load sparql query
		this.query = argList.get("q"); ;		
		 
		// get username
		this.username = argList.get("u");
		
		// get password
		this.password = argList.get("p"); 
		
		// get sparql url
		this.url = argList.get("U");
		
		// Require model args
		if(this.model == null) {
			throw new IllegalArgumentException("Must provide an output model");
		}
		
		// Require sparql
		if (this.query == null) {
			throw new IllegalArgumentException("Must provide a sparql query");
		}
		
		// Require user name 
		if (this.username == null) {
			throw new IllegalArgumentException("Must provide a VIVO admin username");
		}
		
		// Require password
		if (this.password == null) {
			throw new IllegalArgumentException("Must provide a VIVO admin password");
		}
		
		// Require sparql query url
		if (this.url == null) {
			throw new IllegalArgumentException("Must provide a Sparql Query URL");
		}
		
		 
	}
	
	/**
	 * Copy data from input to output
	 * @throws IOException error
	 */
	private void execute() throws IOException {
	   System.out.println("To be implemented");	 
	}
	
	/**
	 * Get the ArgParser for this task
	 * @return the ArgParser
	 */
	private static ArgParser getParser() {
		ArgParser parser = new ArgParser("SparqlQuery");
		// Inputs
		
		parser.addArgument(new ArgDef().setShortOption('q').setLongOpt("query").withParameter(true, "QUERY").setDescription("the sparql query to be executed").setRequired(true));
		parser.addArgument(new ArgDef().setShortOption('u').setLongOpt("username").withParameter(true, "USERNAME").setDescription("vivo admin user name").setRequired(true)); 
		parser.addArgument(new ArgDef().setShortOption('p').setLongOpt("password").withParameter(true, "PASSWORD").setDescription("vivo admin password").setRequired(true)); 
		parser.addArgument(new ArgDef().setShortOption('U').setLongOpt("url").withParameter(true, "URL").setDescription("sparql update url").setRequired(true)); 
		// Outputs
		parser.addArgument(new ArgDef().setShortOption('m').setLongOpt("model").withParameter(true, "MODEL").setDescription("name of jena model").setRequired(true)); 
		return parser;
	}
	
	/**
	 * Main method
	 * @param args commandline arguments
	 */
	public static void main(String... args) {
		Exception error = null;
		try {
			InitLog.initLogger(args, getParser());
			log.info(getParser().getAppName() + ": Start");
			new SparqlQuery(args).execute();
		} catch(IllegalArgumentException e) {
			log.error(e.getMessage());
			log.debug("Stacktrace:",e);
			System.out.println(getParser().getUsage());
			error = e;
		} catch(UsageException e) {
			log.info("Printing Usage:");
			System.out.println(getParser().getUsage());
			error = e;
		} catch(Exception e) {
			log.error(e.getMessage());
			log.debug("Stacktrace:",e);
			error = e;
		} finally {
			log.info(getParser().getAppName() + ": End");
			if(error != null) {
				System.exit(1);
			}
		}
	}
}
