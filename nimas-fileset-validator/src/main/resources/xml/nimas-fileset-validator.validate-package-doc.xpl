<?xml version="1.0" encoding="UTF-8"?>
<p:declare-step version="1.0" name="nimas-fileset-validator.validate-package-doc" type="px:nimas-fileset-validator.validate-package-doc"
    xmlns:p="http://www.w3.org/ns/xproc" 
    xmlns:c="http://www.w3.org/ns/xproc-step"
    xmlns:cx="http://xmlcalabash.com/ns/extensions"
    xmlns:px="http://www.daisy.org/ns/pipeline/xproc"
    xmlns:pxi="http://www.daisy.org/ns/pipeline/xproc/internal"
    xmlns:tmp="http://www.daisy.org/ns/pipeline/tmp" 
    xmlns:d="http://www.daisy.org/ns/pipeline/data"
    xmlns:l="http://xproc.org/library" 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    exclude-inline-prefixes="#all">
    
    <p:documentation xmlns="http://www.w3.org/1999/xhtml">
        <h1 px:role="name">NIMAS Fileset Validator Helper: Validate package documents</h1>
        <p px:role="desc">Validates package documents (*.opf).</p>
    </p:documentation>
    
    <!-- ***************************************************** -->
    <!-- INPUTS / OUTPUTS / OPTIONS -->
    <!-- ***************************************************** -->
    <p:input port="source" primary="true">
        <p:documentation xmlns="http://www.w3.org/1999/xhtml">
            <h1 px:role="name">source</h1>
            <p px:role="desc">A package document (.opf).</p>
        </p:documentation>
    </p:input>
    
    <p:output port="result" primary="true">
        <p:documentation xmlns="http://www.w3.org/1999/xhtml">
            <h1 px:role="name">result</h1>
            <p px:role="desc">A copy of the input document; may include PSVI annotations.</p>
        </p:documentation>
        <p:pipe port="result" step="validate-against-relaxng"/>
    </p:output>
    
    <p:output port="report">
        <p:documentation xmlns="http://www.w3.org/1999/xhtml">
            <h1 px:role="name">relaxng-report</h1>
            <p px:role="desc">Raw output from the RelaxNG validation.</p>
        </p:documentation>
        <p:pipe port="result" step="wrap-reports"/>
    </p:output>
    
    <p:option name="math" required="false" select="'false'">
        <p:documentation xmlns="http://www.w3.org/1999/xhtml">
            <h1 px:role="name">math</h1>
            <p px:role="desc">Indicates the presence of MathML in the book. 
                When set to true, the validator checks that the correct metadata is present in the package document.</p>
        </p:documentation>
    </p:option>
    
    <p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl">
        <p:documentation>Calabash extension steps.</p:documentation>
    </p:import>
    
    <p:import
        href="http://www.daisy.org/pipeline/modules/validation-utils/validation-utils-library.xpl">
        <p:documentation>Collection of utilities for validation and reporting. </p:documentation>
    </p:import>
    
    <p:import href="nimas-fileset-validator.check-pdfs.xpl"/>
    
    <p:variable name="base-uri" select="base-uri()">
        <p:pipe port="source" step="nimas-fileset-validator.validate-package-doc"/>
    </p:variable>
    <p:variable name="filename" 
        select="tokenize($base-uri, '/')[count(tokenize($base-uri, '/'))]"/>
    
    <!-- ***************************************************** -->
    <!-- VALIDATION STEPS -->
    <!-- ***************************************************** -->
    <!-- validate with RNG -->
    <l:relax-ng-report name="validate-against-relaxng" assert-valid="false">
        <p:input port="schema">
            <p:document href="./schema/rng/package-doc-1.2.rng"/>
        </p:input>
        <p:input port="source">
            <p:pipe port="source" step="nimas-fileset-validator.validate-package-doc"/>
        </p:input>
    </l:relax-ng-report>
    
    <!-- see if there was a report generated -->
    <p:count name="count-relaxng-report" limit="1">
        <p:documentation>RelaxNG validation doesn't always produce a report, so this serves as a
            test to see if there was a document produced.</p:documentation>
        <p:input port="source">
            <p:pipe port="report" step="validate-against-relaxng"/>
        </p:input>
    </p:count>
    
    <!-- if there were no errors, relaxng validation comes up empty. we need to have something to pass around, hence this step -->
    <p:choose name="get-relaxng-report">
        <p:xpath-context>
            <p:pipe port="result" step="count-relaxng-report"/>
        </p:xpath-context>
        <!-- if there was no relaxng report, then put an empty errors list document as output -->
        <p:when test="/c:result = '0'">
            <p:output port="result">
                <p:inline>
                    <c:errors/>
                </p:inline>
            </p:output>
            <p:identity/>
            <p:sink/>
        </p:when>
        <p:otherwise>
            <p:output port="result">
                <p:pipe port="report" step="validate-against-relaxng"/>
            </p:output>
            <p:identity/>
            <p:sink/>
        </p:otherwise>
    </p:choose>
    
    <!-- based on the $math option, choose a schematron file -->
    <p:choose name="choose-schematron-file">
        <p:when test="$math eq 'true'">
            <p:output port="result"/>
            <p:identity>
                <p:input port="source">
                    <p:document href="./schema/sch/package-doc-mathml.sch"/>
                </p:input>
            </p:identity>
        </p:when>
        <p:otherwise>
            <p:output port="result"/>
            <p:identity>
                <p:input port="source">
                    <p:document href="./schema/sch/package-doc-no-mathml.sch"/>
                </p:input>
            </p:identity>
        </p:otherwise>
    </p:choose>
    
    <!-- validate with schematron -->
    <p:validate-with-schematron assert-valid="false" name="validate-against-schematron">
        <p:input port="schema">
            <p:pipe port="result" step="choose-schematron-file"/>
        </p:input>
        <p:input port="source">
            <p:pipe port="source" step="nimas-fileset-validator.validate-package-doc"/>
        </p:input>
        <p:input port="parameters">
            <p:empty/>
        </p:input>
    </p:validate-with-schematron>
    <p:sink/>
    
    <!-- check that any referenced PDFs exist on disk -->
    <px:nimas-fileset-validator.check-pdfs name="check-pdfs-exist">
        <p:input port="source">
            <p:pipe port="source" step="nimas-fileset-validator.validate-package-doc"/>
        </p:input>
    </px:nimas-fileset-validator.check-pdfs>    
    <p:sink/>
    
    <px:create-validation-report-wrapper name="wrap-reports">
        <p:with-option name="document-name" select="$filename"/>
        <p:with-option name="document-type" select="'OPF 1.2'"/>
        <p:with-option name="document-path" select="$base-uri"/>
        
        <p:input port="source">
            <!-- a sequence of reports -->
            <p:pipe port="result" step="get-relaxng-report"/>
            <p:pipe port="report" step="validate-against-schematron"/>
            <p:pipe port="result" step="check-pdfs-exist"/>
        </p:input>
    </px:create-validation-report-wrapper>
    
</p:declare-step>