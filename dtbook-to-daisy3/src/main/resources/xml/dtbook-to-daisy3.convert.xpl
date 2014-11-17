<?xml version="1.0" encoding="UTF-8"?>
<p:declare-step version="1.0" name="main" type="px:dtbook-to-daisy3-convert"
		xmlns:p="http://www.w3.org/ns/xproc"
		xmlns:px="http://www.daisy.org/ns/pipeline/xproc"
		xmlns:dc="http://purl.org/dc/elements/1.1/"
		xmlns:dtbook="http://www.daisy.org/z3986/2005/dtbook/"
		xmlns:d="http://www.daisy.org/ns/pipeline/data"
		exclude-inline-prefixes="#all">

  <p:documentation xmlns="http://www.w3.org/1999/xhtml">
    <h1 px:role="name">DTBook to DAISY 3</h1>
    <p px:role="desc">Converts a single dtbook to DAISY 3 format</p>
  </p:documentation>

  <p:input port="in-memory.in" primary="true" sequence="true">
    <p:documentation xmlns="http://www.w3.org/1999/xhtml">
      <h2 px:role="name">2005 DTBook file</h2>
      <p px:role="desc">It contains the DTBook file to be
      transformed. Any other document will be ignored.</p>
    </p:documentation>
  </p:input>

  <p:input port="config">
    <p:documentation xmlns="http://www.w3.org/1999/xhtml">
      <h2 px:role="name">Text-To-Speech configuration file</h2>
      <p px:role="desc">Configuration file that contains Text-To-Speech
      properties, links to aural CSS stylesheets and links to PLS
      lexicons.</p>
    </p:documentation>
  </p:input>

  <p:output port="in-memory.out" primary="true" sequence="true">
    <p:documentation xmlns="http://www.w3.org/1999/xhtml">
      <h2 px:role="name">Output documents</h2>
      <p px:role="desc">The SMIL files, the NCX file, the resource
      file, the OPF file and the input DTBook file updated in order to
      be linked with the SMIL files.</p>
    </p:documentation>
    <p:pipe port="in-memory.out" step="convert"/>
  </p:output>

  <p:input port="fileset.in">
    <p:documentation>
      A fileset containing references to all the DTBook files and any
      resources they reference (images etc.).  The xml:base is also
      set with an absolute URI for each file, and is intended to
      represent the "original file", while the href can change during
      conversions to reflect the path and filename of the resource in
      the output fileset.
    </p:documentation>
  </p:input>

  <p:output port="fileset.out">
    <p:documentation>
      A fileset containing references to the DTBook files and any
      resources it references (images etc.). For each file that is not
      stored in memory, the xml:base is set with an absolute URI
      pointing to the location on disk where it is stored. This lets
      the href reflect the path and filename of the resulting resource
      without having to store it. This is useful for chaining
      conversions.
    </p:documentation>
    <p:pipe port="fileset.out" step="convert"/>
  </p:output>

  <p:option name="publisher" required="false" select="''">
    <p:documentation xmlns="http://www.w3.org/1999/xhtml">
      <h2 px:role="name">Publisher</h2>
      <p px:role="desc">The agency responsible for making the Digital
      Talking Book available. If left blank, it will be retrieved from
      the DTBook meta-data.</p>
    </p:documentation>
  </p:option>

  <p:option name="output-fileset-base" required="true">
    <p:documentation xmlns="http://www.w3.org/1999/xhtml">
      <h2 px:role="name">Ouput fileset's base</h2>
      <p px:role="desc">fileset.out's base directory, which is the
      directory where the DAISY 3 publication will be stored if the
      user intends to store it with no further transformation.</p>
    </p:documentation>
  </p:option>

  <p:option name="audio" required="false" px:type="boolean" select="'true'">
    <p:documentation xmlns="http://www.w3.org/1999/xhtml">
      <h2 px:role="name">Enable Text-To-Speech</h2>
      <p px:role="desc">Whether to use a speech synthesizer to produce audio files.</p>
    </p:documentation>
  </p:option>

  <p:import href="http://www.daisy.org/pipeline/modules/common-utils/library.xpl"/>
  <p:import href="http://www.daisy.org/pipeline/modules/daisy3-utils/library.xpl"/>
  <p:import href="http://www.daisy.org/pipeline/modules/fileset-utils/library.xpl"/>
  <p:import href="http://www.daisy.org/pipeline/modules/dtbook-tts/library.xpl"/>
  <p:import href="http://www.daisy.org/pipeline/modules/tts-helpers/library.xpl"/>

  <!-- Find the first DTBook file within the input documents. -->
  <p:variable name="dtbook-uri"
	      select="resolve-uri(//*[@media-type='application/x-dtbook+xml'][1]/@href, base-uri(/*))">
    <p:pipe port="fileset.in" step="main"/>
  </p:variable>

  <p:split-sequence name="split">
    <p:input port="source">
      <p:pipe port="in-memory.in" step="main"/>
    </p:input>
    <!-- TODO: do the URI normalization somewhere else -->
    <p:with-option name="test" select="concat('replace(&quot;file:/&quot;, replace(base-uri(/*), &quot;///&quot;, &quot;/&quot;), &quot;&quot;)=&quot;',
				       replace('file:/', replace($dtbook-uri, '///', '/'), ''), '&quot;')"/>
  </p:split-sequence>
  <p:count/>
  <p:choose name="first-dtbook">
    <p:when test=". = 0">
      <p:output port="result"/>
      <p:error xmlns:err="http://www.w3.org/ns/xproc-error" code="PEZE00">
	<p:input port="source">
	  <p:inline>
	    <message>No DTBook document found.</message>
	  </p:inline>
	</p:input>
      </p:error>
    </p:when>
    <p:otherwise>
      <p:output port="result"/>
      <p:identity>
	<p:input port="source">
	  <p:pipe port="matched" step="split"/>
	</p:input>
      </p:identity>
    </p:otherwise>
  </p:choose>

  <px:tts-for-dtbook name="tts">
    <p:input port="content.in">
      <p:pipe port="result" step="first-dtbook"/>
    </p:input>
    <p:input port="fileset.in">
      <p:pipe port="fileset.in" step="main"/>
    </p:input>
    <p:input port="config">
      <p:pipe port="config" step="main"/>
    </p:input>
    <p:with-option name="audio" select="$audio"/>
    <p:with-option name="output-dir" select="$output-fileset-base"/>
  </px:tts-for-dtbook>

  <p:delete name="filtered-dtbook-fileset"
	match="d:file[not(@media-type=('image/gif','image/jpeg','image/png','image/svg+xml',
	       'application/pls+xml', 'audio/mpeg','audio/mp4', 'text/css'))]">
    <p:input port="source">
      <p:pipe port="fileset.in" step="main"/>
    </p:input>
  </p:delete>

  <px:fileset-move name="fileset.moved">
    <p:with-option name="new-base" select="$output-fileset-base"/>
  </px:fileset-move>

  <p:group name="convert">
    <p:output port="in-memory.out" sequence="true">
      <p:pipe port="result" step="memory.doc"/>
      <p:pipe port="result" step="create-opf"/>
      <p:pipe port="result" step="create-ncx"/>
      <p:pipe port="result" step="create-resources"/>
      <p:pipe port="smil.out" step="create-mo"/>
    </p:output>
    <p:output port="fileset.out">
      <p:pipe port="result" step="fileset.with-opf"/>
    </p:output>

    <p:variable name="output-name" select="replace(base-uri(/),'^.*/([^/]+)$','$1')">
      <p:pipe port="content.out" step="tts"/>
    </p:variable>
    <p:variable name="daisy3-dtbook-uri" select="concat($output-fileset-base, $output-name)"/>
    <p:variable name="opf-uri" select="concat($output-fileset-base, 'book.opf')"/>
    <!-- Those variables could be used for structuring the output
         package but some DAISY players can only read flat
         package. -->
    <!-- <p:variable name="audio-dir" select="concat($output-fileset-base, 'audio/')"/> -->
    <!-- <p:variable name="smil-dir" select="concat($output-fileset-base, 'mo/')"/> -->
    <p:variable name="audio-relative-dir" select="''"/> <!-- i.e. same directory -->
    <p:variable name="audio-dir" select="concat($output-fileset-base, $audio-relative-dir)"/>
    <p:variable name="smil-dir" select="$output-fileset-base"/>
    <p:variable name="uid" select="concat((//dtbook:meta[@name='dtb:uid'])[1]/@content, '-packaged')">
      <p:pipe port="result" step="first-dtbook"/>
    </p:variable>
    <p:variable name="title" select="normalize-space((//dtbook:meta[@name='dc:Title'])[1]/@content)">
      <p:pipe port="result" step="first-dtbook"/>
    </p:variable>
    <p:variable name="dtd-version" select="(//dtbook:dtbook)[1]/@version">
      <p:pipe port="result" step="first-dtbook"/>
    </p:variable>
    <p:variable name="dclang" select="(//dtbook:meta[@name='dc:Language'])[1]/@content">
      <p:pipe port="result" step="first-dtbook"/>
    </p:variable>
    <p:variable name="lang" select="if ($dclang) then $dclang else //@*[name()='xml:lang'][1]">
      <p:pipe port="result" step="first-dtbook"/>
    </p:variable>
    <p:variable name="dcpublisher" select="(//dtbook:meta[@name='dc:Publisher'])[1]/@content">
      <p:pipe port="result" step="first-dtbook"/>
    </p:variable>
    <p:variable name="publisher" select="if ($publisher) then $publisher
					 else (if ($dcpublisher) then $dcpublisher else 'unknown')"/>


    <!-- TODO: automatic upgrade? -->
    <!-- TODO: it could be moved or copied to dtbook-to-daisy3.xpl -->
    <p:choose>
      <p:when test="not(starts-with($dtd-version, '2005'))">
	<!-- TODO: correct error code. -->
	 <p:error xmlns:err="http://www.w3.org/ns/xproc-error" code="C0051">
	   <p:input port="source">
	     <p:inline>
	       <message>Other versions than DTBook-2005 are not supported.</message>
	     </p:inline>
	   </p:input>
	 </p:error>
	 <p:sink/>
      </p:when>
      <p:otherwise>
	<p:sink/>
      </p:otherwise>
    </p:choose>

    <!-- ===== ADD WHAT IS MAYBE MISSING IN THE DTBOOK ===== -->
    <px:fix-dtbook-structure>
      <p:input port="source">
    	<p:pipe port="content.out" step="tts"/>
      </p:input>
    </px:fix-dtbook-structure>

    <!-- ===== SMIL FILES AND THEIR FILESET ENTRIES ===== -->
    <px:message message="Generating SMIL files..."/>
    <px:create-daisy3-smils name="create-mo">
      <p:input port="audio-map">
	<p:pipe port="audio-map" step="tts"/>
      </p:input>
      <p:with-option name="root-dir" select="$output-fileset-base"/>
      <p:with-option name="daisy3-dtbook-uri" select="$daisy3-dtbook-uri"/>
      <p:with-option name="audio-dir" select="$audio-dir"/>
      <p:with-option name="smil-dir" select="$smil-dir"/>
      <p:with-option name="uid" select="$uid"/>
    </px:create-daisy3-smils>

    <!-- ===== CONTENT DOCUMENT FILE AND ITS FILESET ENTRY ==== -->
    <p:add-attribute match="/*" attribute-name="xml:base">
      <p:input port="source">
	<p:pipe port="updated-content" step="create-mo"/>
      </p:input>
      <p:with-option name="attribute-value" select="$daisy3-dtbook-uri"/>
    </p:add-attribute>
    <p:add-attribute match="//dtbook:meta[@name='dtb:uid']" attribute-name="content">
      <p:with-option name="attribute-value" select="$uid"/>
    </p:add-attribute>
    <p:add-attribute match="//dtbook:meta[@name='dc:Identifier' and count(@*)=2]"
		     name="memory.doc" attribute-name="content">
      <p:with-option name="attribute-value" select="$uid"/>
    </p:add-attribute>
    <px:fileset-create>
      <p:with-option name="base" select="$output-fileset-base"/>
    </px:fileset-create>
    <px:fileset-add-entry name="fileset.doc" media-type="application/x-dtbook+xml">
      <p:with-option name="href" select="$daisy3-dtbook-uri"/>
    </px:fileset-add-entry>

    <!-- ===== NCX FILE AND ITS FILESET ENTRY ==== -->
    <px:create-ncx name="create-ncx">
      <p:input port="content">
	<p:pipe port="updated-content" step="create-mo"/>
      </p:input>
      <p:input port="audio-map">
	<p:pipe port="audio-map" step="tts"/>
      </p:input>
      <p:with-option name="ncx-dir" select="$output-fileset-base"/>
      <p:with-option name="audio-dir" select="$audio-dir"/>
      <p:with-option name="smil-dir" select="$smil-dir"/>
      <p:with-option name="uid" select="$uid"/>
    </px:create-ncx>
    <px:fileset-create>
      <p:with-option name="base" select="$output-fileset-base"/>
    </px:fileset-create>
    <px:fileset-add-entry name="fileset.ncx" media-type='application/x-dtbncx+xml'>
      <p:with-option name="href" select="base-uri(/*)">
	<p:pipe port="result" step="create-ncx"/>
      </p:with-option>
    </px:fileset-add-entry>

    <!-- ===== MP3/OGG FILESET ENTRIES (THE FILES ARE ALREADY STORED) ==== -->
    <px:create-audio-fileset name="fileset.audio">
      <p:input port="source">
	<p:pipe port="audio-map" step="tts"/>
      </p:input>
      <p:with-option name="output-dir" select="$output-fileset-base"/>
      <p:with-option name="audio-relative-dir" select="$audio-relative-dir"/>
    </px:create-audio-fileset>

    <!-- ===== RESOURCE FILE AND ITS FILESET ENTRIES ==== -->
    <px:create-res-file name="create-resources">
      <p:with-option name="output-dir" select="$output-fileset-base"/>
      <p:with-option name="lang" select="$lang"/>
    </px:create-res-file>
    <px:fileset-create>
      <p:with-option name="base" select="$output-fileset-base"/>
    </px:fileset-create>
    <px:fileset-add-entry name="fileset.res" media-type='application/x-dtbresource+xml'>
      <p:with-option name="href" select="base-uri(/*)">
	<p:pipe port="result" step="create-resources"/>
      </p:with-option>
    </px:fileset-add-entry>

    <!-- ===== OPF FILE AND ITS FILESET ENTRY ==== -->
    <px:fileset-join>
      <p:input port="source">
	<p:pipe port="fileset.out" step="create-mo"/>
	<p:pipe port="fileset.out" step="fileset.audio"/>
	<p:pipe port="fileset.out" step="fileset.moved"/>
	<p:pipe port="result" step="fileset.ncx"/>
	<p:pipe port="result" step="fileset.doc"/>
	<p:pipe port="result" step="fileset.res"/>
      </p:input>
    </px:fileset-join>
    <px:fileset-add-entry media-type="text/xml">
      <p:with-option name="href" select="$opf-uri"/>
    </px:fileset-add-entry>
    <p:viewport match="d:file" name="fileset.with-opf">
      <p:choose>
    	<p:when test="contains(/*/@media-type, 'smil')">
    	  <p:add-attribute match="/*" attribute-name="doctype-public"
    			   attribute-value="-//NISO//DTD dtbsmil 2005-2//EN"/>
    	  <p:add-attribute match="/*" attribute-name="doctype-system"
    			   attribute-value="http://www.daisy.org/z3986/2005/dtbsmil-2005-2.dtd"/>
    	  <p:add-attribute match="/*" attribute-name="indent" attribute-value="true"/>
    	</p:when>
    	<p:when test="contains(/*/@media-type, 'dtbook')">
    	  <p:add-attribute match="/*" attribute-name="doctype-public">
    	    <p:with-option name="attribute-value" select="concat('-//NISO//DTD dtbook ', $dtd-version, '//EN')"/>
    	  </p:add-attribute>
    	  <p:add-attribute match="/*" attribute-name="doctype-system">
    	    <p:with-option name="attribute-value" select="concat('http://www.daisy.org/z3986/2005/dtbook-', $dtd-version, '.dtd')"/>
    	  </p:add-attribute>
    	</p:when>
	<p:when test="contains(/*/@media-type, 'ncx')">
	  <p:add-attribute match="/*" attribute-name="doctype-public"
    			   attribute-value="-//NISO//DTD ncx 2005-1//EN"/>
    	  <p:add-attribute match="/*" attribute-name="doctype-system"
    			   attribute-value="http://www.daisy.org/z3986/2005/ncx-2005-1.dtd"/>
    	  <p:add-attribute match="/*" attribute-name="indent" attribute-value="true"/>
    	</p:when>
	<p:when test="contains(/*/@media-type, 'res')">
	  <p:add-attribute match="/*" attribute-name="doctype-public"
    			   attribute-value="-//NISO//DTD resource 2005-1//EN"/>
    	  <p:add-attribute match="/*" attribute-name="doctype-system"
    			   attribute-value="http://www.daisy.org/z3986/2005/resource-2005-1.dtd"/>
    	  <p:add-attribute match="/*" attribute-name="indent" attribute-value="true"/>
    	</p:when>
    	<p:when test="ends-with(/*/@href, '.opf')">
    	  <p:add-attribute match="/*" attribute-name="doctype-public"
    			   attribute-value="+//ISBN 0-9673008-1-9//DTD OEB 1.2 Package//EN"/>
    	  <p:add-attribute match="/*" attribute-name="doctype-system"
    			   attribute-value="http://openebook.org/dtds/oeb-1.2/oebpkg12.dtd"/>
    	  <p:add-attribute match="/*" attribute-name="indent" attribute-value="true"/>
    	</p:when>
    	<p:otherwise>
    	  <p:identity/>
    	</p:otherwise>
      </p:choose>
    </p:viewport>
    <px:create-daisy3-opf name="create-opf">
      <p:with-option name="output-dir" select="$output-fileset-base"/>
      <p:with-option name="uid" select="$uid"/>
      <p:with-option name="title" select="$title"/>
      <p:with-option name="opf-uri" select="$opf-uri"/>
      <p:with-option name="lang" select="$lang"/>
      <p:with-option name="publisher" select="$publisher"/>
      <p:with-option name="total-time" select="//*[@duration]/@duration">
      	<p:pipe port="duration" step="create-mo"/>
      </p:with-option>
    </px:create-daisy3-opf>
  </p:group>
</p:declare-step>
