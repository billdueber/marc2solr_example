package org.solrmarc.index;

/**
 * Licensed to the Apache Software Foundation (ASF) under one or more
 * contributor license agreements.  See the NOTICE file distributed with
 * this work for additional information regarding copyright ownership.
 * The ASF licenses this file to You under the Apache License, Version 2.0
 * (the "License"); you may not use this file except in compliance with
 * the License.  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.StringWriter;
import java.text.ParseException;
import java.util.Iterator;
import java.util.LinkedHashSet;
import java.util.HashMap;
import java.util.List;
import java.util.Set;
import java.util.ArrayList;

import org.apache.log4j.Logger;
import org.marc4j.marc.ControlField;
import org.marc4j.marc.DataField;
import org.marc4j.marc.Record;
import org.marc4j.marc.Subfield;

/* added for umich */
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import edu.umich.lib.normalizers.LCCallNumberNormalizer;
import edu.umich.lib.hlb.HLB;
import org.codehaus.jackson.map.ObjectMapper;


/*  */
/**
 * 
 * @author Robert Haschart
 * @version $Id: VuFindIndexer.java 224 2008-11-05 19:33:21Z asnagy $
 *
 */
public class VuFindIndexer extends SolrIndexer {

  // Initialize logging category
  static Logger logger = Logger.getLogger(VuFindIndexer.class.getName());
  static private ObjectMapper mapper = new ObjectMapper();

  /**
   * Default constructor
   * @param propertiesMapFile
   * @throws Exception
   */
  /*
  public VuFindIndexer(final String propertiesMapFile) throws FileNotFoundException, IOException, ParseException
  {
  super(propertiesMapFile);
  }
   */
  public VuFindIndexer(final String propertiesMapFile, final String[] propertyDirs)
          throws FileNotFoundException, IOException, ParseException {
    super(propertiesMapFile, propertyDirs);
  }

  public Set<String> getHLB3(final Record record) {
    Set<String> callNums = getFieldList(record, "050ab:082a:090ab:099a:086a:086z:852hij");
    Iterator<String> callNumsIter = callNums.iterator();

    Set<String> hlb3components = new LinkedHashSet<String>();
    while (callNumsIter.hasNext()) {
	    String callNum = (String) callNumsIter.next();
	try{
	    hlb3components.addAll(HLB.components(callNum));
	} catch (java.lang.NullPointerException e) {
	    // logger.error("NullPointer in HLB3 on '" + callNum + "'");
	}
    }
    return hlb3components;
  }

  public Set<String> getHLB3Delimited(final Record record) {
    Set<String> callNums = getFieldList(record, "050ab:082a:090ab:099a:086a:086z:852hij");
    Iterator<String> callNumsIter = callNums.iterator();

    Set<String> hlb3cats = new LinkedHashSet<String>();
    while (callNumsIter.hasNext()) {
      String callNum = (String) callNumsIter.next();
      try {
	  hlb3cats.addAll(HLB.categories(callNum));
      } catch (java.lang.NullPointerException e) {
	  //	  logger.error("NullPointer in HLB3 on '" + callNum + "'");
      }
    }
    return hlb3cats;
  }
       


  /**
   * Determine Record Format(s)
   *
   * @param  Record          record
   * @return Set<String>     format of record
   */
  public Set<String> getFormat(final Record record) {
    Set<String> result = new LinkedHashSet<String>();
    String leader = record.getLeader().toString();
    char leaderBit;
    ControlField fixedField = (ControlField) record.getVariableField("008");
    DataField title = (DataField) record.getVariableField("245");
    char formatCode = ' ';

    // check if there's an h in the 245
    if (title != null) {
      if (title.getSubfield('h') != null) {
        if (title.getSubfield('h').getData().toLowerCase().contains("[electronic resource]")) {
          result.add("Electronic");
          return result;
        }
      }
    }

    // check the 007 - this is a repeating field
    List<ControlField> fields = record.getVariableFields("007");
    Iterator<ControlField> fieldsIter = fields.iterator();
    if (fields != null) {
      ControlField formatField;
      while (fieldsIter.hasNext()) {
        formatField = (ControlField) fieldsIter.next();
        formatCode = formatField.getData().toUpperCase().charAt(0);
        switch (formatCode) {
          case 'A':
            switch (formatField.getData().toUpperCase().charAt(1)) {
              case 'D':
                result.add("Atlas");
                break;
              default:
                result.add("Map");
                break;
            }
            break;
          case 'C':
            switch (formatField.getData().toUpperCase().charAt(1)) {
              case 'A':
                result.add("TapeCartridge");
                break;
              case 'B':
                result.add("ChipCartridge");
                break;
              case 'C':
                result.add("DiscCartridge");
                break;
              case 'F':
                result.add("TapeCassette");
                break;
              case 'H':
                result.add("TapeReel");
                break;
              case 'J':
                result.add("FloppyDisk");
                break;
              case 'M':
              case 'O':
                result.add("CDROM");
                break;
              case 'R':
                // Do not return - this will cause anything with an
                // 856 field to be labeled as "Electronic"
                break;
              default:
                result.add("Software");
                break;
            }
            break;
          case 'D':
            result.add("Globe");
            break;
          case 'F':
            result.add("Braille");
            break;
          case 'G':
            switch (formatField.getData().toUpperCase().charAt(1)) {
              case 'C':
              case 'D':
                result.add("Filmstrip");
                break;
              case 'T':
                result.add("Transparency");
                break;
              default:
                result.add("Slide");
                break;
            }
            break;
          case 'H':
            result.add("Microfilm");
            break;
          case 'K':
            switch (formatField.getData().toUpperCase().charAt(1)) {
              case 'C':
                result.add("Collage");
                break;
              case 'D':
                result.add("Drawing");
                break;
              case 'E':
                result.add("Painting");
                break;
              case 'F':
                result.add("Print");
                break;
              case 'G':
                result.add("Photonegative");
                break;
              case 'J':
                result.add("Print");
                break;
              case 'L':
                result.add("Drawing");
                break;
              case 'O':
                result.add("FlashCard");
                break;
              case 'N':
                result.add("Chart");
                break;
              default:
                result.add("Photo");
                break;
            }
            break;
          case 'M':
            switch (formatField.getData().toUpperCase().charAt(1)) {
              case 'F':
                result.add("VideoCassette");
                break;
              case 'R':
                result.add("Filmstrip");
                break;
              default:
                result.add("MotionPicture");
                break;
            }
            break;
          case 'O':
            result.add("Kit");
            break;
          case 'Q':
            result.add("MusicalScore");
            break;
          case 'R':
            result.add("SensorImage");
            break;
          case 'S':
            switch (formatField.getData().toUpperCase().charAt(1)) {
              case 'D':
                result.add("SoundDisc");
                break;
              case 'S':
                result.add("SoundCassette");
                break;
              default:
                result.add("SoundRecording");
                break;
            }
            break;
          case 'V':
            switch (formatField.getData().toUpperCase().charAt(1)) {
              case 'C':
                result.add("VideoCartridge");
                break;
              case 'D':
                result.add("VideoDisc");
                break;
              case 'F':
                result.add("VideoCassette");
                break;
              case 'R':
                result.add("VideoReel");
                break;
              default:
                result.add("Video");
                break;
            }
            break;
        }
      }
      if (!result.isEmpty()) {
        return result;
      }
    }

    // check the Leader at position 6
    leaderBit = leader.charAt(6);
    switch (Character.toUpperCase(leaderBit)) {
      case 'C':
      case 'D':
        result.add("MusicalScore");
        break;
      case 'E':
      case 'F':
        result.add("Map");
        break;
      case 'G':
        result.add("Slide");
        break;
      case 'I':
        result.add("SoundRecording");
        break;
      case 'J':
        result.add("MusicRecording");
        break;
      case 'K':
        result.add("Photo");
        break;
      case 'M':
        result.add("Electronic");
        break;
      case 'O':
      case 'P':
        result.add("Kit");
        break;
      case 'R':
        result.add("PhysicalObject");
        break;
      case 'T':
        result.add("Manuscript");
        break;
    }
    if (!result.isEmpty()) {
      return result;
    }

    // check the Leader at position 7
    leaderBit = leader.charAt(7);
    switch (Character.toUpperCase(leaderBit)) {
      // Monograph
      case 'M':
        if (formatCode == 'C') {
          result.add("eBook");
        } else {
          result.add("Book");
        }
        break;
      // Serial
      case 'S':
        // Look in 008 to determine what type of Continuing Resource
        formatCode = fixedField.getData().toUpperCase().charAt(21);
        switch (formatCode) {
          case 'N':
            result.add("Newspaper");
            break;
          case 'P':
            result.add("Journal");
            break;
          default:
            result.add("Serial");
            break;
        }
    }

    // Nothing worked!
    if (result.isEmpty()) {
      result.add("Unknown");
    }

    return result;
  }

  /**
   * Extract the call number label from a record
   * @param record
   * @return Call number label
   */
  public String getFullCallNumber(final Record record) {

    String val = getFirstFieldVal(record, "099ab:090ab:050ab");

    if (val != null) {
      return val.toUpperCase().replaceAll(" ","");
    } else {
      return val;
    }
  }

  /**
   * Extract the call number label from a record
   * @param record
   * @return Call number label
   */
  public String getCallNumberLabel(final Record record) {

    String val = getFirstFieldVal(record, "090a:050a");

    if (val != null) {
      int dotPos = val.indexOf(".");
      if (dotPos > 0) {
        val = val.substring(0, dotPos);
      }
      return val.toUpperCase();
    } else {
      return val;
    }
  }

  /**
   * Extract the subject component of the call number
   *
   * Can return null
   *
   * @param record
   * @return Call number label
   */
  public String getCallNumberSubject(final Record record) {

    String val = getFirstFieldVal(record, "090a:050a");

    if (val != null) {
      String[] callNumberSubject = val.toUpperCase().split("[^A-Z]+");
      if (callNumberSubject.length > 0) {
        return callNumberSubject[0];
      }
    }
    return (null);
  }

  /* umich local custom functions follow */
  /**
   * Get the date from a record
   * @param record
   * @return
   */
  public String getDate(Record record) {
    Pattern pattern = Pattern.compile("\\d{4}");
    Matcher matcher;

    String date = null;
    String date1;
    char datetype;
    String date260;

    ControlField fixedField = (ControlField) record.getVariableField("008");
    date1 = fixedField.getData().substring(7, 11).toLowerCase();
    datetype = fixedField.getData().charAt(6);
    date1 = date1.replace('u', '0');
    date1 = date1.replace('|', ' ');
    if (date1.compareTo("0000") == 0) {
      date1 = "";
    }
    if (datetype == 'u') {
      date1 = ""; 	// serial status unknown
    }
    if (datetype == 'n') {
      date1 = "";	// dates unknown
    }
    if (datetype == 'b') {
      date1 = "";	// no date given, BC
    }
    matcher = pattern.matcher(date1);
    if (matcher.find()) {
      date = matcher.group();
      //logger.info("getDate: date1 used for pub date: " + date + ", date1: " + date1);
      return (date);
    }
    date260 = getFieldVals(record, "260c", ", ");
    if (date260 != null) {
      matcher = pattern.matcher(date260);
      if (matcher.find()) {
        date = matcher.group();
        //logger.info("getDate: date260 used for pub date: " + date + ", date260: " + date260);
        return (date);
      }
    }
    logger.info("getDate: no date");
    return (date);
  }

  /**
   * translate pub date (from getDate, 008 or 260) to a date range
   *
   * @param record
   * @return
   */
  public String getPublishDateRange(Record record) {
    String pubDate = getDate(record);
    String pubDateRange = null;
    String century = null;
    String decade = null;
    if (pubDate == null) {
      return null;
    }
    if (pubDate.compareTo("1500") < 0) {
      pubDateRange = "Pre-1500";
    } else if (pubDate.compareTo("1800") < 0) {
      century = pubDate.substring(0, 2);
      pubDateRange = century + "00-" + century + "99";
    } else if (pubDate.compareTo("2100") < 0) {
      decade = pubDate.substring(0, 3);
      pubDateRange = decade + "0-" + decade + "9";
    } else {
      logger.info("getPublishDateRange: invalid date " + pubDate);
      return null;
    }
    //logger.info("getPublishDateRange: pubDate=" + pubDate + ", range=" + pubDateRange);
    return (pubDateRange);
  }

  /**
   * Get oclc numbers from 035 fields (subfield a)
   * @param   Record  record          The Record object to pull the data from
   * @return
   */
  public Set<String> getOclcNum(final Record record) {
    Set<String> result = new LinkedHashSet<String>();

    //Pattern pattern = Pattern.compile("(oclc|ocolc|ocm|ocn)(\\d+)", Pattern.CASE_INSENSITIVE);
    Pattern pattern = Pattern.compile("(oclc|ocolc|ocm|ocn).*?(\\d+)", Pattern.CASE_INSENSITIVE);
    Matcher matcher;

    List<DataField> fields = record.getVariableFields("035");
    Iterator<DataField> fieldsIter = fields.iterator();
    DataField field;

    String data;
    String oclcNum;

    // Loop through fields
    while (fieldsIter.hasNext()) {
      field = (DataField) fieldsIter.next();
      if (field.getSubfield('a') != null) {
        data = field.getSubfield('a').getData();
        matcher = pattern.matcher(data);
        if (matcher.find()) {
          oclcNum = matcher.group(2);
          result.add(oclcNum);
          //logger.info("getOclcNum: subfield is " + data + ", oclcnum is " + oclcNum);
        }
      }
    }
    return result;
  }

  /**
   * Get SDR numbers from 035 fields (subfield a)
   * @param   Record  record          The Record object to pull the data from
   * @return
   */
  public Set<String> getSDRNum(final Record record) {
    Set<String> result = new LinkedHashSet<String>();

    Pattern pattern = Pattern.compile("^sdr", Pattern.CASE_INSENSITIVE);
    Matcher matcher;

    List<DataField> fields = record.getVariableFields("035");
    Iterator<DataField> fieldsIter = fields.iterator();
    DataField field;

    String data;
    String sdrNum;

    // Loop through fields
    while (fieldsIter.hasNext()) {
      field = (DataField) fieldsIter.next();
      //data = field.getSubfield('a').getData().toLowerCase();
      if (field.getSubfield('a') != null) {
        data = field.getSubfield('a').getData();
        matcher = pattern.matcher(data);
        if (matcher.find()) {
          sdrNum = data;
          result.add(sdrNum);
          // logger.info("getSDRNum: subfield is " + data + ", sdrnum is " + sdrNum);
        }
      }
    }
    return result;
  }

  /**
   * Get dedupped list of namespaces from 974 fields.  Used to set HathiTrust source facet
   * @param   Record  record          The Record object to pull the data from
   * @return
   */
  public Set<String> getHTNameSpace(final Record record) {
    Set<String> result = new LinkedHashSet<String>();

    //Pattern pattern = Pattern.compile("^([a-z]+)\\..*", Pattern.CASE_INSENSITIVE);
    Pattern pattern = Pattern.compile("^([a-z0-9]+)\\..*", Pattern.CASE_INSENSITIVE);
    Matcher matcher;

    List<DataField> fields = record.getVariableFields("974");
    Iterator<DataField> fieldsIter = fields.iterator();
    DataField field;

    String data;
    String nameSpace;

    // Loop through fields
    while (fieldsIter.hasNext()) {
      field = (DataField) fieldsIter.next();
      if (field.getSubfield('u') != null) {
        data = field.getSubfield('u').getData();
        matcher = pattern.matcher(data);
        if (matcher.find()) {
          nameSpace = matcher.group(1);
          result.add(nameSpace);
        }
      }
    }
    // logger.info("getHTNameSpace: set is " + result.toString());
    return result;
  }

  /**
   * Get language code(s) from 008 and 041 fields
   * @param   Record  record          The Record object to pull the data from
   * @return
   */
  public Set<String> getLanguage(final Record record) {
    Set<String> result = new LinkedHashSet<String>();

    Pattern pattern = Pattern.compile("^[a-z]{3}$");
    Matcher matcher;

    String data;
    int dataLength;
    String lang;

    // 008 field
    ControlField f008 = (ControlField) record.getVariableField("008");
    if (f008 != null) {
      lang = f008.getData().substring(35, 38).toLowerCase();
      matcher = pattern.matcher(lang);
      if (matcher.matches()) {
        result.add(lang);
      } else {
        logger.info("getLanguage: invalid language in 008: " + lang);
      }
    }

    // 041 fields
    List<DataField> fields = record.getVariableFields("041");
    Iterator<DataField> fieldsIter = fields.iterator();
    DataField field;

    List<DataField> subfields;
    Iterator<DataField> subfieldsIter;
    Subfield subfield;

    while (fieldsIter.hasNext()) {
      field = (DataField) fieldsIter.next();
      // Loop through subfields
      subfields = field.getSubfields();
      subfieldsIter = subfields.iterator();
      while (subfieldsIter.hasNext()) {
        subfield = (Subfield) subfieldsIter.next();
        char code = subfield.getCode();
        if (code == 'a' || code == 'd' || code == 'e' || code == 'j') {
          data = subfield.getData();
          dataLength = data.length();
          if (dataLength % 3 == 0) {
            int offset = 0;
            while (offset < dataLength) {
              lang = data.substring(offset, offset + 3).toLowerCase();
              matcher = pattern.matcher(lang);
              if (matcher.matches()) {
                result.add(lang);
              } else {
                logger.info("getLanguage: invalid language in 041: " + lang + ", field data: " + data);
              }
              offset += 3;
            }
          } else {
            logger.info("getLanguage: 041 invalid length " + dataLength + ", field data: " + data);
          }
        }
      }
    }
    // logger.info("getLanguage: set is " + result.toString());
    return result;
  }


  /**
   * Get title, with and without leading article removed
   * @param   Record  record          The Record object to pull the data from
   * @param   String  subfields       The subfields from 245 field
   * @return
   */
  public Set<String> getTitle(final Record record, String subfields_wanted) {
    Set<String> result = new LinkedHashSet<String>();

    List<DataField> fields = record.getVariableFields("245");
    Iterator<DataField> fieldsIter = fields.iterator();
    DataField field;

    Iterator<DataField> subfieldsIter;
    List<DataField> subfields;
    Subfield subfield;

    // Loop through fields
    while (fieldsIter.hasNext()) {
      field = (DataField) fieldsIter.next();
      StringBuffer data = new StringBuffer("");
      // Loop through subfields
      subfields = field.getSubfields();
      subfieldsIter = subfields.iterator();
      while (subfieldsIter.hasNext()) {
        subfield = (Subfield) subfieldsIter.next();
        char code = subfield.getCode();
        if (subfields_wanted.indexOf(code) >= 0) {
          if (data.length() > 0) {
            data.append(" " + subfield.getData());
          } else {
            data.append(subfield.getData());
          }
        }
      }

      if (data.length() > 0 ) {
        result.add(data.toString()); 		// add the whole thing
        int i2 = charToInt(field.getIndicator2());
        if (i2 > 0 && i2 < data.length()) {	// if ind2 is set, add the substring minus the non-filing chars
          //logger.info("getTitle: non-filing indicator = " + i2);
          result.add(data.substring(i2));
        }
      }
    }
    //logger.info("getTitle: set is " + result.toString());
    return result;
  }

  /**
   * Get title for sorting, with leading article removed
   * @param   Record  record          The Record object to pull the data from
   * @return
   */
  public Set<String> getTitle_sort(final Record record) {
    Set<String> result = new LinkedHashSet<String>();

    //Pattern pattern = Pattern.compile("^[a-z]{3}$");
    //Matcher matcher;

    List<DataField> fields = record.getVariableFields("245");
    Iterator<DataField> fieldsIter = fields.iterator();
    DataField field;

    Iterator<DataField> subfieldsIter;
    List<DataField> subfields;
    Subfield subfield;


    // Loop through fields
    while (fieldsIter.hasNext()) {
      field = (DataField) fieldsIter.next();
      StringBuffer data = new StringBuffer("");
      String dataStr;

      // Loop through subfields
      subfields = field.getSubfields();
      subfieldsIter = subfields.iterator();
      while (subfieldsIter.hasNext()) {
        subfield = (Subfield) subfieldsIter.next();
        char code = subfield.getCode();
        //if (code >= 'a' && code <= 'z') {
        if (code == 'a' || code == 'b') {
          if (data.length() > 0) {
            data.append(" " + subfield.getData());
          } else {
            data.append(subfield.getData());
          }
        }
      }


      int i2 = charToInt(field.getIndicator2());
      if (i2 > 0 && i2 < data.length()) {
        dataStr = data.substring(i2);
      } else {
        dataStr = data.toString();
      }
      // strip punctuation
      dataStr = dataStr.replaceAll("\\p{Punct}", " ");
      dataStr = dataStr.replaceAll("\\s+", " ");
      dataStr = dataStr.trim();
      dataStr = dataStr.toLowerCase();
      //logger.info("getTitle: non-filing indicator = " + i2 + ", data: " + dataStr);
      result.add(dataStr);
      return result; 	// just return first
    }
    return result;
  }

  public int charToInt(char c) {
    if (!Character.isDigit(c)) {
      return 0;
    }
    return Integer.parseInt(String.valueOf(c));
  }

  /**
   * Get data from HathiTrust id field (974).  Used to build ht_id_display field
   * @param   Record  record          The Record object to pull the data from
   * @return
   */
  public Set<String> getHathiData(final Record record) {
    Set<String> result = new LinkedHashSet<String>();

    List<DataField> fields = record.getVariableFields("974");
    Iterator<DataField> fieldsIter = fields.iterator();
    DataField field;

    char sepChar = '|';
    String defaultDate = "00000000";
    StringBuffer buffer = new StringBuffer("");

    // Loop through fields
    while (fieldsIter.hasNext()) {
      buffer.setLength(0);
      field = (DataField) fieldsIter.next();
      if (field.getSubfield('u') != null) {
        buffer.append(field.getSubfield('u').getData());
      }
      buffer.append(sepChar);
      if (field.getSubfield('d') != null) {
        buffer.append(field.getSubfield('d').getData());
      } else {
        buffer.append(defaultDate);
      }
      buffer.append(sepChar);
      if (field.getSubfield('z') != null) {
        buffer.append(field.getSubfield('z').getData());
      }

      result.add(buffer.toString());
    }
    return result;
  }


  /**
   * Get data from HathiTrust id field (974).  Used to build ht_id_display_json field
   * @param   Record  record          The Record object to pull the data from
   * @return
   */
  public String getHathiDataJSON(final Record record) throws IOException {
    String result = "";

    List<DataField> fields = record.getVariableFields("974");
    Iterator<DataField> fieldsIter = fields.iterator();
    DataField field;

    char sepChar = '|';
    String defaultDate = "00000000";
    StringBuffer buffer = new StringBuffer("");
    
    ArrayList<HashMap> rvarray = new ArrayList();
    StringWriter rv = new StringWriter();

    // Loop through fields
    while (fieldsIter.hasNext()) {
 
      HashMap h = new HashMap();
      field = (DataField) fieldsIter.next();
      if (field.getSubfield('u') != null) {
	  h.put("htid",field.getSubfield('u').getData()); 
      }

      if (field.getSubfield('d') != null) {
	  h.put("ingest",field.getSubfield('d').getData()); 
      } else {
	  h.put("ingest",defaultDate);
      }

      if (field.getSubfield('z') != null) {
	  h.put("enumcron",field.getSubfield('z').getData()); 
      }


      if (field.getSubfield('r') != null) {
	  h.put("rights",field.getSubfield('r').getData()); 
      }

      rvarray.add(h);
    }
    mapper.writeValue(rv, rvarray);
    return rv.toString();
  }



  /**
   * Get update date from HathiTrust field (974|d).
   * write value of 0 if subfield d not present
   * @param   Record  record          The Record object to pull the data from
   * @return
   */
  public Set<String> getHathiUpdate(final Record record) {
    Set<String> result = new LinkedHashSet<String>();

    List<DataField> fields = record.getVariableFields("974");
    Iterator<DataField> fieldsIter = fields.iterator();
    DataField field;

    char sepChar = '|';
    String defaultDate = "00000000";
    String date;

    // Loop through fields
    while (fieldsIter.hasNext()) {
      field = (DataField) fieldsIter.next();
      if (field.getSubfield('d') != null) {
        result.add(field.getSubfield('d').getData());
      } else {
        result.add(defaultDate);
      }
    }
    return result;
  }

  /**
   * convert call number to an integer, will be indexed as a Trie value
   */
  public Set<String> getCallNumberNum(final Record record) {
    Set<String> result = new LinkedHashSet<String>();

    Set<String> callNums = getFieldList(record, "086a:086z:852hij");
    Iterator<String> callNumsIter = callNums.iterator();
    String callNum;
    String callNumNum;

    // Loop through call number
    while (callNumsIter.hasNext()) {
      callNum = (String) callNumsIter.next();
      //logger.info("getCAllNumberNum: callNum: " + callNum);
      callNumNum = LCCallNumberNormalizer.toLongInt(callNum);
      //logger.info("getCAllNumberNum: callNumNum: " + callNumNum);
      result.add(callNumNum);
    }
    return result;
  }

    /**
     * Get data specified by fieldSpec only if format matches
     * @param record marc record object
     * @param fieldSpec - the field/subfield to use for title
     * @return title(s)
     */
    public Set<String> getDataForFormat(Record record, String fieldSpec, String formatWanted)
    {
    if (!hasFormat(record, formatWanted)) return null;	// format not found in record
    return getFieldList(record, fieldSpec);
    }

    /**
     * Get title if the format (from local 970 field) is SE
     * @param record marc record object
     * @param subfields_wanted - the subfields from 245 to return
     * @return title(s) if format matches, otherwise null
     */
    public Set<String> getSerialTitle(Record record, String subfields_wanted)
    {

    if (!hasFormat(record, "SE")) return null;	// not a serial
 
    return getTitle(record, subfields_wanted);
  }

    /**
     * Check for format in record (970 subfield a) 
     * @param record marc record object
     * @return true if the formats is present, false otherwise
     */
    public boolean hasFormat(Record record, String formatWanted)
    {

    List<DataField> fields;
    Iterator<DataField> fieldsIter;
    DataField field;

    Iterator<DataField> subfieldsIter;
    List<DataField> subfields;
    Subfield subfield;

    // check 970 subfield a, see if wanted format is present
    Set<String> formats = getFieldList(record, "970a");
    Iterator<String> formatsIter = formats.iterator();
    String fmt = "";
    while (formatsIter.hasNext()) {
      fmt = (String) formatsIter.next();
      if (fmt.compareTo(formatWanted) == 0) return true;
    }

    return false;
  }

}
