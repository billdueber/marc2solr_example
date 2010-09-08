/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package edu.umich.lib.hlb;

import edu.umich.lib.RangeSet.*;
import edu.umich.lib.normalizers.*;
import java.net.*;
import java.util.*;
import java.io.*;
import org.codehaus.jackson.map.ObjectMapper;
import java.text.SimpleDateFormat;

/**
 *
 * @author dueberb
 */
public class HLB {

  static private Boolean gotTheFile = false;
  static private Map<String, Object> map;
  static private ObjectMapper mapper = new ObjectMapper();
  static private HashMap<String,RangeSet> lcranges = new HashMap<String,RangeSet>();
  static private HashMap<String, ArrayList<ArrayList>> cats = new HashMap<String, ArrayList<ArrayList>>();

  static {
    try {
      getAndParseJSON();
    } catch (IOException e) {
      throw new RuntimeException("Can't get hlb3.json: " + e.getMessage());
    }
  }


  

  public static Set<String> components(String s) {
    Set<String> rv = new HashSet<String>();
    Set<DSR> dsrs;

    try {
      String n = LCCallNumberNormalizer.normalize(s, false, false);
      String firstLetter = n.substring(0,1);
      dsrs = lcranges.get(firstLetter).containers(n);
    } catch (MalformedCallNumberException e) {
      return rv;
    }

    for (DSR d : dsrs) {
      ArrayList<ArrayList> categories = cats.get((String) d.data.get("hlbcat"));
      for (ArrayList a : categories) {
        rv.addAll(a);
      }
    }
    return rv;
  }

  public static Set<String> categories(String s) {
    Set<String> rv = new HashSet<String>();
    Set<DSR> dsrs;

    try {
      String n = LCCallNumberNormalizer.normalize(s, false, false);
      String firstLetter = n.substring(0,1);
      dsrs = lcranges.get(firstLetter).containers(n);
    } catch (MalformedCallNumberException e) {
      return rv;
    }

    for (DSR d : dsrs) {
      ArrayList<ArrayList> categories = cats.get((String) d.data.get("hlbcat"));
      for (ArrayList a : categories) {
        if (a.size() == 2) {
          rv.add(a.get(0) + " | " + a.get(1));
        } else {
          rv.add(a.get(0) + " | " + a.get(1) + " | " + a.get(2));
        }
      }
    }
    return rv;
  }

  private static void getAndParseJSON() throws IOException {
    URL url = new URL("http://mirlyn.lib.umich.edu/static/hlb3/hlb3.json");
    BufferedReader in = new BufferedReader(new InputStreamReader(url.openStream()));
    map = mapper.readValue(in, Map.class);
//    map = mapper.readValue(new File("/tmp/hlb3.json"), Map.class);

    // Get the LC ranges
    ArrayList<ArrayList> lc = (ArrayList) map.get("lcranges");
    for (ArrayList rng : lc) {
      String rstart = LCCallNumberNormalizer.rangeStart((String) rng.get(1));
      String rend   = LCCallNumberNormalizer.rangeEnd((String) rng.get(2));
      DSR d = new DSR(rstart, rend);
      d.data.put("hlbcat", rng.get(0));

     
      String firstLetter = rstart.substring(0,1);
      if (!lcranges.containsKey(firstLetter)) {
//        System.out.println("Created new RangeSet for " + firstLetter);
        lcranges.put(firstLetter, new RangeSet());
      }

      lcranges.get(firstLetter).add(d);
//    System.out.println(d.data.get("hlbcat") + ": " + d.start + "-" + d.end);
    }

    // Sort them now instead of later
    for (String key : lcranges.keySet()) {
      lcranges.get(key).sort();
    }

    // Get the categories
    cats = (HashMap<String, ArrayList<ArrayList>>) map.get("topics");



  }
}
