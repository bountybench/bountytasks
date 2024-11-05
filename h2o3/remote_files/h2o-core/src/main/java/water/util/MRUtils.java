package water.util;

import water.H2O;
import water.Key;
import water.MRTask;
import water.fvec.*;
import water.parser.BufferedString;

import java.util.Arrays;
import java.util.Random;

import static water.util.RandomUtils.getRNG;

public class MRUtils {


  /**
   * Sample rows from a frame.
   * Can be unlucky for small sampling fractions - will continue calling itself until at least 1 row is returned.
   * @param fr Input frame
   * @param rows Approximate number of rows to sample (across all chunks)
   * @param seed Seed for RNG
   * @return Sampled frame
   */
  public static Frame sampleFrame(Frame fr, final long rows, final long seed) {
    return sampleFrame(fr, rows, null, seed);
  }

  /**
   * Row-wise shuffle of a frame (only shuffles rows inside of each chunk)
   * @param fr Input frame
   * @return Shuffled frame
   */
  public static Frame shuffleFramePerChunk(Frame fr, final long seed) {
    return new MRTask() {
      @Override
      public void map(Chunk[] cs, NewChunk[] ncs) {
        int[] idx = new int[cs[0]._len];
        for (int r=0; r<idx.length; ++r) idx[r] = r;
        ArrayUtils.shuffleArray(idx, getRNG(seed));
        for (long anIdx : idx) {
          for (int i = 0; i < ncs.length; i++) {
            if (cs[i] instanceof CStrChunk) {
              ncs[i].addStr(cs[i],cs[i].start()+anIdx);
            } else {
              ncs[i].addNum(cs[i].atd((int) anIdx));
            }
          }
        }
      }
    }.doAll(fr.types(), fr).outputFrame(fr.names(), fr.domains());
  }

  /**
   * Compute the class distribution from a class label vector
   * (not counting missing values)
   *
   * Usage 1: Label vector is categorical
   * ------------------------------------
   * Vec label = ...;
   * assert(label.isCategorical());
   * double[] dist = new ClassDist(label).doAll(label).dist();
   *
   * Usage 2: Label vector is numerical
   * ----------------------------------
   * Vec label = ...;
   * int num_classes = ...;
   * assert(label.isInt());
   * double[] dist = new ClassDist(num_classes).doAll(label).dist();
   *
   */
  public static class ClassDist extends MRTask<ClassDist> {
    final int _nclass;
    protected double[] _ys;
    public ClassDist(final Vec label) { _nclass = label.domain().length; }
    public ClassDist(int n) { _nclass = n; }

    public final double[] dist() { return _ys; }
    public final double[] relDist() {
      final double sum = ArrayUtils.sum(_ys);
      // due to CV and weights there can be sum == 0
      return sum == 0 ? _ys : ArrayUtils.div(Arrays.copyOf(_ys, _ys.length), sum);
    }
    
    @Override public void map(Chunk ys) {
      _ys = new double[_nclass];
      for( int i=0; i<ys._len; i++ )
        if (!ys.isNA(i))
          _ys[(int) ys.at8(i)]++;
    }
    
    @Override public void map(Chunk ys, Chunk ws) {
      _ys = new double[_nclass];
      for( int i=0; i<ys._len; i++ )
        if (!ys.isNA(i))
          _ys[(int) ys.at8(i)] += ws.atd(i);
    }
    
    @Override public void reduce( ClassDist that ) { ArrayUtils.add(_ys,that._ys); }
  }

  /**
   * Compute the class distribution for qusibinomial distribution from a class label vector
   * (not counting missing values)
   */
  public static class ClassDistQuasibinomial extends MRTask<ClassDistQuasibinomial> {
    final int _nclass;
    private double[] _ys;
    private String[] _domain;
    private double _firstDoubleDomain;


    public ClassDistQuasibinomial(String[] domain) {
      _nclass = 2;
      _domain = domain;
      _firstDoubleDomain = Double.valueOf(domain[0]);
    }
    
    public final double[] dist() {
      return _ys; 
    }
    
    public final double[] relDist() {
      final double sum = ArrayUtils.sum(_ys);
      // due to CV and weights there can be sum == 0
      return sum == 0 ? _ys : ArrayUtils.div(Arrays.copyOf(_ys, _ys.length), sum);
    }
    
    public final String[] domains(){
      return _domain;
    }
    
    @Override public void map(Chunk ys) {
      _ys = new double[_nclass];
      for( int i=0; i<ys._len; i++ )
        if (!ys.isNA(i)) {
          int index = ys.atd(i) == _firstDoubleDomain ? 0 : 1;
          _ys[index]++;
        }
    }
    
    @Override public void map(Chunk ys, Chunk ws) {
      _ys = new double[_nclass];
      for( int i=0; i<ys._len; i++ )
        if (!ys.isNA(i)) {
          int index = ys.atd(i) == _firstDoubleDomain? 0 : 1;
          _ys[index] += ws.atd(i);
        }
    }
    
    @Override public void reduce(ClassDistQuasibinomial that) { 
      ArrayUtils.add(_ys,that._ys);
    }
  }

  public static class Dist extends MRTask<Dist> {
    private IcedHashMap<IcedDouble,IcedAtomicInt> _dist;
    @Override public void map(Chunk ys) {
      _dist = new IcedHashMap<>();
      IcedDouble d = new IcedDouble(0);
      for( int row=0; row< ys._len; row++ )
        if( !ys.isNA(row) ) {
          d._val = ys.atd(row);
          IcedAtomicInt oldV = _dist.get(d);
          if(oldV == null)
            oldV = _dist.putIfAbsent(new IcedDouble(d._val), new IcedAtomicInt(1));
          if(oldV != null)
            oldV.incrementAndGet();
        }
    }

    @Override public void reduce(Dist mrt) {
      if( _dist != mrt._dist ) {
        IcedHashMap<IcedDouble,IcedAtomicInt> l = _dist;
        IcedHashMap<IcedDouble,IcedAtomicInt> r = mrt._dist;
        if( l.size() < r.size() ) { l=r; r=_dist; }
        for( IcedDouble v: r.keySet() ) {
          IcedAtomicInt oldVal = l.putIfAbsent(v, r.get(v));
          if( oldVal!=null ) oldVal.addAndGet(r.get(v).get());
        }
        _dist=l;
        mrt._dist=null;
      }
    }
    public double[] dist() {
      int i=0;
      double[] dist = new double[_dist.size()];
      for( IcedAtomicInt v: _dist.values() ) dist[i++] = v.get();
      return dist;
    }
    public double[] keys() {
      int i=0;
      double[] keys = new double[_dist.size()];
      for( IcedDouble k: _dist.keySet() ) keys[i++] = k._val;
      return keys;
    }
  }

  /**
   * Stratified sampling for classifiers - FIXME: For weights, this is not accurate, as the sampling is done with uniform weights
   * @param fr Input frame
   * @param label Label vector (must be categorical)
   * @param weights Weights vector, can be null
   * @param sampling_ratios Optional: array containing the requested sampling ratios per class (in order of domains), will be overwritten if it contains all 0s
   * @param maxrows Maximum number of rows in the returned frame
   * @param seed RNG seed for sampling
   * @param allowOversampling Allow oversampling of minority classes
   * @param verbose Whether to print verbose info
   * @return Sampled frame, with approximately the same number of samples from each class (or given by the requested sampling ratios)
   */
  public static Frame sampleFrameStratified(final Frame fr, Vec label, Vec weights, float[] sampling_ratios, long maxrows, final long seed, final boolean allowOversampling, final boolean verbose) {
    return sampleFrameStratified(fr, label, weights, sampling_ratios, maxrows, seed, allowOversampling, verbose, null);
  }
  
  
  /**
   * Stratified sampling for classifiers - FIXME: For weights, this is not accurate, as the sampling is done with uniform weights
   * @param fr Input frame
   * @param label Label vector (must be categorical)
   * @param weights Weights vector, can be null
   * @param sampling_ratios Optional: array containing the requested sampling ratios per class (in order of domains), will be overwritten if it contains all 0s
   * @param maxrows Maximum number of rows in the returned frame
   * @param seed RNG seed for sampling
   * @param allowOversampling Allow oversampling of minority classes
   * @param verbose Whether to print verbose info
   * @param quasibinomialDomain quasibinomial domain      
   * @return Sampled frame, with approximately the same number of samples from each class (or given by the requested sampling ratios)
   */
  public static Frame sampleFrameStratified(final Frame fr, Vec label, Vec weights, float[] sampling_ratios, long maxrows, final long seed, final boolean allowOversampling, final boolean verbose, String[] quasibinomialDomain) {
    if (fr == null) return null;
    assert(label.isCategorical());
    if (maxrows < label.domain().length) {
      Log.warn("Attempting to do stratified sampling to fewer samples than there are class labels - automatically increasing to #rows == #labels (" + label.domain().length + ").");
      maxrows = label.domain().length;
    }

    double[] dist;
    if(quasibinomialDomain != null){
      dist = weights != null ? new ClassDistQuasibinomial(quasibinomialDomain).doAll(label, weights).dist() : new ClassDistQuasibinomial(quasibinomialDomain).doAll(label).dist();
    } else {
      dist = weights != null ? new ClassDist(label).doAll(label, weights).dist() : new ClassDist(label).doAll(label).dist();
    }
    
    assert(dist.length > 0);
    Log.info("Doing stratified sampling for data set containing " + fr.numRows() + " rows from " + dist.length + " classes. Oversampling: " + (allowOversampling ? "on" : "off"));
    if (verbose)
      for (int i=0; i<dist.length;++i)
        Log.info("Class " + label.factor(i) + ": count: " + dist[i] + " prior: " + (float)dist[i]/fr.numRows());

    // create sampling_ratios for class balance with max. maxrows rows (fill
    // existing array if not null).  Make a defensive copy.
    sampling_ratios = sampling_ratios == null ? new float[dist.length] : sampling_ratios.clone();
    assert sampling_ratios.length == dist.length;
    if( ArrayUtils.minValue(sampling_ratios) == 0 && ArrayUtils.maxValue(sampling_ratios) == 0 ) {
      // compute sampling ratios to achieve class balance
      for (int i=0; i<dist.length;++i)
        sampling_ratios[i] = ((float)fr.numRows() / label.domain().length) / (float)dist[i]; // prior^-1 / num_classes
      final float inv_scale = ArrayUtils.minValue(sampling_ratios); //majority class has lowest required oversampling factor to achieve balance
      if (!Float.isNaN(inv_scale) && !Float.isInfinite(inv_scale))
        ArrayUtils.div(sampling_ratios, inv_scale); //want sampling_ratio 1.0 for majority class (no downsampling)
    }

    if (!allowOversampling)
      for (int i=0; i<sampling_ratios.length; ++i)
        sampling_ratios[i] = Math.min(1.0f, sampling_ratios[i]);

    // given these sampling ratios, and the original class distribution, this is the expected number of resulting rows
    float numrows = 0;
    for (int i=0; i<sampling_ratios.length; ++i) {
      numrows += sampling_ratios[i] * dist[i];
    }
    if (Float.isNaN(numrows)) {
      Log.err("Total number of sampled rows was NaN. " +
              "Sampling ratios: " + Arrays.toString(sampling_ratios) + 
              "; Dist: " + Arrays.toString(dist));
      throw new IllegalArgumentException("Error during sampling - too few points?");
    }

    final long actualnumrows = Math.min(maxrows, Math.round(numrows)); //cap #rows at maxrows
    assert(actualnumrows >= 0); //can have no matching rows in case of sparse data where we had to fill in a makeZero() vector
    Log.info("Stratified sampling to a total of " + String.format("%,d", actualnumrows) + " rows" + (actualnumrows < numrows ? " (limited by max_after_balance_size).":"."));

    if (actualnumrows != numrows) {
      ArrayUtils.mult(sampling_ratios, (float)actualnumrows/numrows); //adjust the sampling_ratios by the global rescaling factor
      if (verbose)
        Log.info("Downsampling majority class by " + (float)actualnumrows/numrows
                + " to limit number of rows to " + String.format("%,d", maxrows));
    }
    for (int i=0;i<label.domain().length;++i) {
      Log.info("Class '" + label.domain()[i] + "' sampling ratio: " + sampling_ratios[i]);
    }

    return sampleFrameStratified(fr, label, weights, sampling_ratios, seed, verbose, quasibinomialDomain);
  }

  /**
   * Stratified sampling
   * @param fr Input frame
   * @param label Label vector (from the input frame)
   * @param weights Weight vector (from the input frame), can be null
   * @param sampling_ratios Given sampling ratios for each class, in order of domains
   * @param seed RNG seed
   * @param debug Whether to print debug info
   * @param quasibinomialDomain quasibinomial domain
   * @return Stratified frame
   */
  public static Frame sampleFrameStratified(final Frame fr, Vec label, Vec weights, final float[] sampling_ratios, final long seed, final boolean debug, String[] quasibinomialDomain) {
    return sampleFrameStratified(fr, label, weights, sampling_ratios, seed, debug, 0, quasibinomialDomain);
  }

  // internal version with repeat counter
  // currently hardcoded to do up to 10 tries to get a row from each class, which can be impossible for certain wrong sampling ratios
  private static Frame sampleFrameStratified(final Frame fr, Vec label, Vec weights, final float[] sampling_ratios, final long seed, final boolean debug, int count, String[] quasibinomialDomain) {
    if (fr == null) return null;
    assert(label.isCategorical());
    assert(sampling_ratios != null && sampling_ratios.length == label.domain().length);
    final int labelidx = fr.find(label); //which column is the label?
    assert(labelidx >= 0);
    final int weightsidx = fr.find(weights); //which column is the weight?

    final boolean poisson = false; //beta feature

    //FIXME - this is doing uniform sampling, even if the weights are given
    Frame r = new MRTask() {
      @Override
      public void map(Chunk[] cs, NewChunk[] ncs) {
        final Random rng = getRNG(seed);
        for (int r = 0; r < cs[0]._len; r++) {
          if (cs[labelidx].isNA(r)) continue; //skip missing labels
          rng.setSeed(cs[0].start()+r+seed);
          final int label = (int)cs[labelidx].at8(r);
          assert(sampling_ratios.length > label && label >= 0);
          int sampling_reps;
          if (poisson) {
            throw H2O.unimpl();
//            sampling_reps = ArrayUtils.getPoisson(sampling_ratios[label], rng);
          } else {
            final float remainder = sampling_ratios[label] - (int)sampling_ratios[label];
            sampling_reps = (int)sampling_ratios[label] + (rng.nextFloat() < remainder ? 1 : 0);
          }
          for (int i = 0; i < ncs.length; i++) {
            if (cs[i] instanceof CStrChunk) {
              for (int j = 0; j < sampling_reps; ++j) {
                ncs[i].addStr(cs[i],cs[0].start()+r);
              }
            } else {
              for (int j = 0; j < sampling_reps; ++j) {
                ncs[i].addNum(cs[i].atd(r));
              }
            }
          }
        }
      }
    }.doAll(fr.types(), fr).outputFrame(fr.names(), fr.domains());

    // Confirm the validity of the distribution
    Vec lab = r.vecs()[labelidx];
    Vec wei = weightsidx != -1 ? r.vecs()[weightsidx] : null;
    double[] dist;
    if(quasibinomialDomain != null){
      dist = wei != null ? new ClassDistQuasibinomial(quasibinomialDomain).doAll(lab, wei).dist() : new ClassDistQuasibinomial(quasibinomialDomain).doAll(lab).dist();
    } else {
      dist = wei != null ? new ClassDist(lab).doAll(lab, wei).dist() : new ClassDist(lab).doAll(lab).dist();
    }

    // if there are no training labels in the test set, then there is no point in sampling the test set
    if (dist == null) return fr;

    if (debug) {
      double sumdist = ArrayUtils.sum(dist);
      Log.info("After stratified sampling: " + sumdist + " rows.");
      for (int i=0; i<dist.length;++i) {
        Log.info("Class " + r.vecs()[labelidx].factor(i) + ": count: " + dist[i]
                + " sampling ratio: " + sampling_ratios[i] + " actual relative frequency: " + (float)dist[i] / sumdist * dist.length);
      }
    }

    // Re-try if we didn't get at least one example from each class
    if (ArrayUtils.minValue(dist) == 0 && count < 10) {
      Log.info("Re-doing stratified sampling because not all classes were represented (unlucky draw).");
      r.remove();
      return sampleFrameStratified(fr, label, weights, sampling_ratios, seed+1, debug, ++count, quasibinomialDomain);
    }

    // shuffle intra-chunk
    Frame shuffled = shuffleFramePerChunk(r, seed+0x580FF13);
    r.remove();

    return shuffled;
  }


  /**
   * Sample rows from a frame with weight column.
   * Weights are used in the following manner: a row that has n-times higher weight should be n-times more likely to be picked.
   * Can be unlucky for small sampling fractions - will continue calling itself until at least 1 row is returned.
   * @param fr Input frame
   * @param rows Approximate number of rows to sample (across all chunks)
   * @param weightColumn Weight column name
   * @param seed Seed for RNG
   * @return Sampled frame
   */
  public static Frame sampleFrame(Frame fr, final long rows, final String weightColumn, final long seed) {
    if (fr == null) return null;
    final int weightIdx = fr.find(weightColumn);
    final double fractionOfWeights;
    if (weightIdx < 0) {
      fractionOfWeights = rows > 0 ? (double)rows / fr.numRows(): 1.f;
    } else {
      final double meanWeight = fr.vec(weightIdx).mean();
      fractionOfWeights = rows > 0 ? (double)rows / (fr.numRows() * meanWeight): 1.f;
    }
    if (fractionOfWeights >= 1.f) return fr;
    Key newKey = fr._key != null ? Key.make(fr._key.toString() + (fr._key.toString().contains("temporary") ? ".sample." : ".temporary.sample.") + PrettyPrint.formatPct(fractionOfWeights).replace(" ","")) : null;

    Frame r = new MRTask() {
      @Override
      public void map(Chunk[] cs, NewChunk[] ncs) {
        final Random rng = getRNG(0);
        final BufferedString bStr = new BufferedString();
        int count = 0;
        for (int r = 0; r < cs[0]._len; r++) {
          rng.setSeed(seed+r+cs[0].start());
          final double threshold = weightIdx < 0 ? fractionOfWeights : (fractionOfWeights * cs[weightIdx].atd(r));
          // A row with n-times higher weight should be n-times more likely to be picked
          if (rng.nextFloat() < threshold || (count == 0 && r == cs[0]._len-1) ) {
            count++;
            for (int i = 0; i < ncs.length; i++) {
              if (cs[i].isNA(r)) ncs[i].addNA();
              else if (cs[i] instanceof CStrChunk)
                ncs[i].addStr(cs[i].atStr(bStr,r));
              else if (cs[i] instanceof C16Chunk)
                ncs[i].addUUID(cs[i].at16l(r),cs[i].at16h(r));
              else
                ncs[i].addNum(cs[i].atd(r));
            }
          }
        }
      }
    }.doAll(fr.types(), fr).outputFrame(newKey, fr.names(), fr.domains());
    if (r.numRows() == 0) {
      Log.warn("You asked for " + rows + " rows (out of " + fr.numRows() + "), but you got none (seed=" + seed + ").");
      Log.warn("Let's try again. You've gotta ask yourself a question: \"Do I feel lucky?\"");
      return sampleFrame(fr, rows, seed+1);
    }
    return r;
  }

  /**
   * Sample small number of rows from a frame. Doesn't support weights.
   * 
   * Meaning of "small" is relative, it shouldn't be more that 10k of rows.
   * 
   * @param fr Input frame
   * @param rows Exact number of rows to sample
   * @param seed Seed for RNG
   * @return Sampled frame, guaranteed to have exactly specified #rows (as long as the frame is large enough)
   */
  public static Frame sampleFrameSmall(Frame fr, final int rows, final long seed) {
    return sampleFrameSmall(fr, rows, getRNG(seed));
  }

  /**
   * Sample small number of rows from a frame. Doesn't support weights.
   *
   * Meaning of "small" is relative, it shouldn't be more that 10k of rows.
   *
   * @param fr Input frame
   * @param rows Exact number of rows to sample
   * @param rand Random Generator
   * @return Sampled frame, guaranteed to have exactly specified #rows (as long as the frame is large enough)
   */
  public static Frame sampleFrameSmall(Frame fr, final int rows, final Random rand) {
    if (rows >= fr.numRows())
      return fr;
    return fr.deepSlice(ArrayUtils.distinctLongs(rows, fr.numRows(), rand), null);
  }

}
