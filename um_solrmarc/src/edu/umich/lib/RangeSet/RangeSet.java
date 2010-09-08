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
public class RangeSet {

  RangeList byStart = new RangeList(new DSRstartComparator());
  RangeList byEnd;
  Boolean isDirty = false;
  public static int totalCompares;


  public int add(DSR dsr) {
    byStart.add(dsr);
    isDirty = true;
    return byStart.size();
  }

  public int size() {
    return byStart.size();
  }

  public Set<DSR> containers(String s) {
    Set<DSR> rv = new HashSet<DSR>();
    int lastStartIndex;
    int lastEndIndex;

    if (isDirty) {
      sort();
    }
    try {
      lastStartIndex = byStart.lte(s);
      totalCompares += byStart.compares;
      lastEndIndex = byEnd.lte(s);
      totalCompares += byEnd.compares;
    } catch (NoSuchElementException e) {
      return rv;
    }


    for (int i = 0; i <= lastEndIndex; i++) {
//      totalCompares++;
      if ((Integer) (byEnd.get(i).data.get("byStartIndex")) <= lastStartIndex) {
        rv.add(byEnd.get(i));
//        System.out.println(s + " included in " + byEnd.get(i).start + "-" + byEnd.get(i).end);
      }
    }
    return rv;
  }

  /**
   * Sort the byStart array in range-start order; duplicate
   * it into byEnd and sort into reversed range-end order
   */
  public void sort() {
    if (!isDirty) {
      return;
    }
    Collections.sort(byStart, byStart.comparator);

    for (int i = 0; i < byStart.size(); i++) {
      DSR d = (DSR) byStart.get(i);
      d.data.put("byStartIndex", i);
    }

    byEnd = (RangeList) byStart.clone();
    byEnd.comparator = new DSRendComparator();
    Collections.sort(byEnd, byEnd.comparator);
    isDirty = false;
  }

  class RangeList extends ArrayList<DSR> {

    DSRStringComparator comparator;
    public int compares = 0;

    public RangeList(DSRStringComparator c) {
      comparator = c;
    }

    /**
     * Binary search to find the lowest index whose value is
     * less than or equal to the given value, according to
     * the comparator's compareToString(s) method.
     *
     * Note that in the case of the "end" elements, the logic is
     * all reversed consistantly enough that we can use this method
     * to find all elements whose range end value is greater than
     * or equal to the given string.
     *
     * The perl code is as follows:
     *
     * Return the index I such that this(i) <= a for i <= I
     *
     * @param s
     * @return index
     */
    public int lte(String s) throws NoSuchElementException {
      compares = 0;
      // If it's empty, return nothing
      if (this.size() == 0) {
        throw new NoSuchElementException("Empty set");
      }

      int lastindex = this.size() - 1;
      int high = lastindex;
      int low = 0;

      // Is the last element <= s? Then all of them are.
//      int vsLast = comparator.compareToString(get(lastindex), s);
//      if (vsLast <= 0) {
//        System.out.println("ShortCircuit");
//        return lastindex;
//      }


      // Is the first element > s? Then none of the
      // items are greater than or equal to s
      int vsFirst = comparator.compareToString(get(0), s);
      compares++;
      totalCompares++;
      if (vsFirst > 0) {
        throw new NoSuchElementException("Less than the first element");
      }

      int mid = 0;
      while (high - low > 1) {
        mid = low + ((high - low) / 2);
//        System.out.println("HML: " + high + " / " + mid + " / " + low);
        if (comparator.compareToString(get(mid), s) > 0) {
          high = mid;
        } else {
          low = mid;
        }
        compares++;


//        System.out.println("HML now: " + high + " / " + mid + " / " + low);

      }

      if (comparator.compareToString(get(high), s) <= 0) {
        compares++;
        return high;
      } else {
        compares++;
        return low;
      }
    }
  }

  /**
   * A simple interface extension to allow comparison to a string.
   */
  public interface DSRStringComparator extends Comparator {

    public int compareToString(DSR d, String s);
  }

  /**
   * DSRStringComparator focusing on the "start" element
   *
   */
  class DSRstartComparator implements DSRStringComparator {

    public int compare(Object dsr1, Object dsr2) {
      DSR d1 = (DSR) dsr1;
      DSR d2 = (DSR) dsr2;
      return d1.start.compareTo(d2.start);
    }

    public int compareToString(DSR d, String s) {
      return d.start.compareTo(s);
    }
  }

  /**
   * DSRStringComparator focusing on the "end" element, and sorting
   * in reverse order (so the largest elements are at the front
   * of the array
   *
   */
  class DSRendComparator implements DSRStringComparator {

    public int compare(Object dsr1, Object dsr2) {
      DSR d1 = (DSR) dsr1;
      DSR d2 = (DSR) dsr2;
      return -(d1.end.compareTo(d2.end));
    }

    public int compareToString(DSR d, String s) {
      return -(d.end.compareTo(s));
    }
  }
}
