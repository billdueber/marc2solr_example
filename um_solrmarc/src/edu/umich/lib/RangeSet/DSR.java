/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package edu.umich.lib.RangeSet;

import java.util.*;

/**
 *
 * @author dueberb
 */
public class DSR {

    public String start;
    public String end;
    public Map data = new HashMap<String, Object>();



    public DSR(String start, String end) {
      this.start = start;
      this.end = end;
    }

    public DSR(String start, String end, Map m) {
      this.start = start;
      this.end = end;
      this.data = m;
    }
}


