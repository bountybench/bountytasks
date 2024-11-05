package water;

import water.util.ReflectionUtils;
import water.util.StringUtils;
import water.util.UnsafeUtils;
import water.fvec.*;

import java.util.Arrays;
import java.util.UUID;
import java.util.concurrent.atomic.AtomicLongFieldUpdater;

/**
 * Keys!  H2O supports a distributed Key/Value store, with exact Java Memory
 * Model consistency.  Keys are a means to find a {@link Value} somewhere in
 * the Cloud, to cache it locally, to allow globally consistent updates to a
 * {@link Value}.  Keys have a *home*, a specific Node in the Cloud, which is
 * computable from the Key itself.  The Key's home node breaks ties on racing
 * updates, and tracks caching copies (via a hardware-like MESI protocol), but
 * otherwise is not involved in the DKV.  All operations on the DKV, including
 * Gets and Puts, are found in {@link DKV}.
 * <p>
 * Keys are defined as a simple byte-array, plus a hashCode and a small cache
 * of Cloud-specific information.  The first byte of the byte-array determines
 * if this is a user-visible Key or an internal system Key; an initial byte of
 * &lt;32 is a system Key.  User keys are generally externally visible, system
 * keys are generally limited to things kept internal to the H2O Cloud.  Keys
 * might be a high-count item, hence we care about the size.
 * <p>
 * System keys for {@link Job}, {@link Vec}, {@link Chunk} and {@link
 * water.fvec.Vec.VectorGroup} have special initial bytes; Keys for these classes can be
 * determined without loading the underlying Value.  Layout for {@link Vec} and
 * {@link Chunk} is further restricted, so there is an efficient mapping
 * between a numbered Chunk and it's associated Vec.
 * <p>
 * System keys (other than the restricted Vec and Chunk keys) can have their
 * home node forced, by setting the desired home node in the first few Key
 * bytes.  Otherwise home nodes are selected by pseudo-random hash.  Selecting
 * a home node is sometimes useful for Keys with very high update rates coming
 * from a specific Node.
 * <p>
 * @author <a href="mailto:cliffc@h2o.ai"></a>
 * @version 1.0
 */
final public class Key<T extends Keyed> extends Iced<Key<T>> implements Comparable {
  // The Key!!!
  public final byte[] _kb;      // Key bytes, wire-line protocol
  transient final int _hash;    // Hash on key alone (and not value)

  // The user keys must be ASCII, so the values 0..31 are reserved for system
  // keys. When you create a system key, please do add its number to this list
  static final byte BUILT_IN_KEY = 2;
  public static final byte JOB = 3;
  public static final byte VEC = 4; // Vec
  public static final byte CHK = 5; // Chunk
  public static final byte GRP = 6; // Vec.VectorGroup

  public static final byte HIDDEN_USER_KEY = 31;
  public static final byte USER_KEY = 32;

  // Indices into key header structure (key bytes)
  private static final int KEY_HEADER_TYPE = 0;
  private static final int KEY_HEADER_CUSTOM_HOMED = 1;
  
  // For Fluid Vectors, we have a special Key layout.
  // 0 - key type byte, one of VEC, CHK or GRP
  // 1 - homing byte, always -1/0xFF as these keys use the hash to figure their home out
  // 4 - Vector Group
  // 4 - Chunk # for CHK, or 0xFFFFFFFF for VEC
  static final int VEC_PREFIX_LEN = 1+1+4+4;

  /** True is this is a {@link Vec} Key.
   *  @return True is this is a {@link Vec} Key */
  public final boolean isVec() { return _kb.length > 0 && _kb[KEY_HEADER_TYPE] == VEC; }

  /** True is this is a {@link Chunk} Key.
   *  @return True is this is a {@link Chunk} Key */
  public final boolean isChunkKey() { return _kb.length > 0 && _kb[KEY_HEADER_TYPE] == CHK; }

  /** Returns the {@link Vec} Key from a {@link Chunk} Key.
   *  @return Returns the {@link Vec} Key from a {@link Chunk} Key. */
  public final Key getVecKey() { assert isChunkKey(); return water.fvec.Vec.getVecKey(this); }

  /** Convenience function to fetch key contents from the DKV.
   * @return null if the Key is not mapped, or an instance of {@link Keyed} */
  public final T get() {
    Value val = DKV.get(this);
    return val == null ? null : (T)val.get();
  }

  // *Desired* distribution function on keys
  int D() {
    int hsz = H2O.CLOUD.size();

    if (0 == hsz) return -1;    // Clients starting up find no cloud, be unable to home keys

    // See if this is a specifically homed Key
    if (!user_allowed() && custom_homed()) {
      assert _kb[KEY_HEADER_TYPE] != Key.CHK; // Chunks cannot be custom-homed
      H2ONode h2o = H2ONode.intern(_kb,2);
      // Reverse the home to the index
      int idx = h2o.index();
      if( idx >= 0 ) return idx;
      // Else homed to a node which is no longer in the cloud!
      // Fall back to the normal home mode
    }

    // Distribution of Fluid Vectors is a special case.
    // Fluid Vectors are grouped into vector groups, each of which must have
    // the same distribution of chunks so that MRTask run over group of
    // vectors will keep data-locality.  The fluid vecs from the same group
    // share the same key pattern + each has 4 bytes identifying particular
    // vector in the group.  Since we need the same chunks end up on the same
    // node in the group, we need to skip the 4 bytes containing vec# from the
    // hash.  Apart from that, we keep the previous mode of operation, so that
    // ByteVec would have first 64MB distributed around cloud randomly and then
    // go round-robin in 64MB chunks.
    if( _kb[KEY_HEADER_TYPE] == CHK ) {
      // Homed Chunk?
      if( _kb[KEY_HEADER_CUSTOM_HOMED] != -1 ) throw H2O.fail();
      // For round-robin on Chunks in the following pattern:
      // 1 Chunk-per-node, until all nodes have 1 chunk (max parallelism).
      // Then 2 chunks-per-node, once around, then 4, then 8, then 16.
      // Getting several chunks-in-a-row on a single Node means that stencil
      // calculations that step off the end of one chunk into the next won't
      // force a chunk local - replicating the data.  If all chunks round robin
      // exactly, then any stencil calc will double the cached volume of data
      // (every node will have it's own chunk, plus a cached next-chunk).
      // Above 16-chunks-in-a-row we hit diminishing returns.
      int cidx = UnsafeUtils.get4(_kb, 1 + 1 + 4); // Chunk index
      int x = cidx/hsz; // Multiples of cluster size
      // 0 -> 1st trip around the cluster;            nidx= (cidx- 0*hsz)>>0
      // 1,2 -> 2nd & 3rd trip; allocate in pairs:    nidx= (cidx- 1*hsz)>>1
      // 3,4,5,6 -> next 4 rounds; allocate in quads: nidx= (cidx- 3*hsz)>>2
      // 7-14 -> next 8 rounds in octets:             nidx= (cidx- 7*hsz)>>3
      // 15+ -> remaining rounds in groups of 16:     nidx= (cidx-15*hsz)>>4
      int z = x==0 ? 0 : (x<=2 ? 1 : (x<=6 ? 2 : (x<=14 ? 3 : 4)));
      int nidx = (cidx-((1<<z)-1)*hsz)>>z;
      return (nidx&0x7FFFFFFF) % hsz;
    }

    // Easy Cheesy Stupid:
    return (_hash&0x7FFFFFFF) % hsz;
  }


  /** List of illegal characters which are not allowed in user keys. */
  static final CharSequence ILLEGAL_USER_KEY_CHARS = " !@#$%^&*()+={}[]|\\;:\"'<>,/?";

  // 64 bits of Cloud-specific cached stuff. It is changed atomically by any
  // thread that visits it and has the wrong Cloud. It has to be read *in the
  // context of a specific Cloud*, since a re-read may be for another Cloud.
  private transient volatile long _cache;
  private static final AtomicLongFieldUpdater<Key> _cacheUpdater =
    AtomicLongFieldUpdater.newUpdater(Key.class, "_cache");


  // Accessors and updaters for the Cloud-specific cached stuff.
  // The Cloud index, a byte uniquely identifying the last 256 Clouds. It
  // changes atomically with the _cache word, so we can tell which Cloud this
  // data is a cache of.
  static int cloud( long cache ) { return (int)(cache>>> 0)&0x00FF; }
  // Shortcut node index for Home.
  // 'char' because I want an unsigned 16bit thing, limit of 65534 Cloud members.
  // -1 is reserved for a bare-key
  static int home ( long cache ) { return (int)(cache>>> 8)&0xFFFF; }

  static long build_cache(int cidx, int home) {
    return // Build the new cache word
        ((long) (cidx & 0xFF)) |
        ((long) (home & 0xFFFF) << 8);
  }

  int home ( H2O cloud ) { return home (cloud_info(cloud)); }

  /** True if the {@link #home_node} is the current node.
   *  @return True if the {@link #home_node} is the current node */
  public boolean home() { return home_node()==H2O.SELF; }
  /** The home node for this Key.
   *  @return The home node for this Key. */
  public H2ONode home_node( ) {
    H2O cloud = H2O.CLOUD;
    return cloud._memary[home(cloud)];
  }

  // Update the cache, but only to strictly newer Clouds
  private boolean set_cache( long cache ) {
    while( true ) { // Spin till get it
      long old = _cache; // Read once at the start
      if( !H2O.larger(cloud(cache),cloud(old)) ) // Rolling backwards?
        // Attempt to set for an older Cloud. Blow out with a failure; caller
        // should retry on a new Cloud.
        return false;
      assert cloud(cache) != cloud(old) || cache == old;
      if( old == cache ) return true; // Fast-path cutout
      if( _cacheUpdater.compareAndSet(this,old,cache) ) return true;
      // Can fail if the cache is really old, and just got updated to a version
      // which is still not the latest, and we are trying to update it again.
    }
  }
  // Return the info word for this Cloud. Use the cache if possible
  long cloud_info( H2O cloud ) {
    long x = _cache;
    // See if cached for this Cloud. This should be the 99% fast case.
    if( cloud(x) == cloud._idx ) return x;

    // Cache missed! Probably it just needs (atomic) updating.
    // But we might be holding the stale cloud...
    // Figure out home Node in this Cloud
    char home = (char)D();
    long cache = build_cache(cloud._idx,home);
    set_cache(cache); // Attempt to upgrade cache, but ignore failure
    return cache; // Return the magic word for this Cloud
  }

  // Construct a new Key.
  private Key(byte[] kb) {
    _kb = kb;
    // Quicky hash: http://en.wikipedia.org/wiki/Jenkins_hash_function
    int hash = 0;
    for( byte b : kb ) {
      hash += b;
      hash += (hash << 10);
      hash ^= (hash >> 6);
    }
    hash += (hash << 3);
    hash ^= (hash >> 11);
    hash += (hash << 15);
    _hash = hash;
  }

  // Make new Keys.  Optimistically attempt interning, but no guarantee.
  public static <P extends Keyed> Key<P> make(byte[] kb) {
    Key key = new Key(kb);
    Key key2 = H2O.getk(key); // Get the interned version, if any
    if( key2 != null ) // There is one! Return it instead
      return key2;
    
    H2O cloud = H2O.CLOUD; // Read once
    key._cache = build_cache(cloud._idx-1,0); // Build a dummy cache with a fake cloud index
    key.cloud_info(cloud); // Now force compute & cache the real data
    return key;
  }

  /** A random string, useful as a Key name or partial Key suffix.
   *  @return A random short string */
  public static String rand() {
    UUID uid = UUID.randomUUID();
    long l1 = uid.getLeastSignificantBits();
    long l2 = uid. getMostSignificantBits();
    return "_"+Long.toHexString(l1)+Long.toHexString(l2);
  }

  /** Factory making a Key from a String
   *  @return Desired Key */
  public static <P extends Keyed> Key<P> make(String s) {
    return make(decodeKeyName(s != null? s : rand()));
  }

  public static <P extends Keyed> Key<P> makeSystem(String s) {
    return make(s,BUILT_IN_KEY);
  }
  public static <P extends Keyed> Key<P> makeUserHidden(String s) {
    return make(s,HIDDEN_USER_KEY);
  }

  /**
   * Make a random key, homed to a given node.
   * @param node a node at which the new key is homed.
   * @return the new key
   */
  public static <P extends Keyed> Key<P> make(H2ONode node) {
    return make(decodeKeyName(rand()),BUILT_IN_KEY,false,node);
  }
  public static <P extends Keyed> Key<P> make() { return make(rand()); }

  /** Factory making a homed system Key.  Requires the initial system byte but
   *  then allows a String for the remaining bytes. 
   *
   *  Requires specifying the home node of the key. The required specifies 
   *  if it is an error to name an H2ONode that is NOT in the Cloud, or if 
   *  some other H2ONode can be substituted.
   *  @return the desired Key   */
  public static <P extends Keyed> Key<P> make(String s, byte systemType, boolean required, H2ONode home) {
    return make(decodeKeyName(s),systemType,required,home);
  }
  /** Factory making a system Key.  Requires the initial system byte but
   *  then allows a String for the remaining bytes.
   *  @return the desired Key   */
  public static <P extends Keyed> Key<P> make(String s, byte systemType) {
    return make(decodeKeyName(s),systemType,false,null);
  }
  /** Factory making a homed system Key.  Requires the initial system byte and
   *  uses {@link #rand} for the remaining bytes.
   *  
   *  Requires specifying the home node of the key. The required specifies 
   *  if it is an error to name an H2ONode that is NOT in the Cloud, or if 
   *  some other H2ONode can be substituted.
   *  @return the desired Key   */
  public static <P extends Keyed> Key<P> make(byte systemType, boolean required, H2ONode home) {
    return make(rand(),systemType,required,home);
  }


  // Make a Key which is homed to specific nodes.
  private static <P extends Keyed> Key<P> make(byte[] kb, byte systemType, boolean required, H2ONode home) {
    assert systemType < 32; // only system keys allowed
    home = home != null && H2O.CLOUD.contains(home) ? home : null;
    assert !required || home != null; // If homing is not required and home is not in cloud (or null), then ignore

    // Key byte layout is:
    // 0 - systemType, from 0-31
    // 1 - is the key homed to a specific node? (0 or 1)
    // 2-n - if homed then IP4 (4+2 bytes) or IP6 (16+2 bytes) address
    // 2-5- 4 bytes of chunk#, or -1 for masters
    // n+ - repeat of the original kb
    AutoBuffer ab = new AutoBuffer();
    ab.put1(systemType);
    ab.putZ(home != null);
    if (home != null) {
      home.write(ab);
    }
    ab.put4(-1);
    ab.putA1(kb, kb.length);
    return make(Arrays.copyOf(ab.buf(),ab.position()));
  }

  /**
   * Remove a Key from the DKV, including any embedded Keys.
   * @deprecated use {@link Keyed#remove(Key)} instead. Will be removed from version 3.30.
   */
  public void remove() { Keyed.remove(this); }

  /**
   * @deprecated use {@link Keyed#remove(Futures)} instead. Will be removed from version 3.30.
   */
  public Futures remove(Futures fs) {
    return Keyed.remove(this, fs, true);
  }

  /** True if a {@link #USER_KEY} and not a system key.
   * @return True if a {@link #USER_KEY} and not a system key */
  public boolean user_allowed() { return type()==USER_KEY; }

  boolean custom_homed() {
    return _kb[KEY_HEADER_CUSTOM_HOMED] == 1;
  }

  /** System type/byte of a Key, or the constant {@link #USER_KEY}
   *  @return Key type */
  // Returns the type of the key.
  public int type() { return ((_kb[KEY_HEADER_TYPE]&0xff)>=32) ? USER_KEY : (_kb[KEY_HEADER_TYPE]&0xff); }

  /** Return the classname for the Value that this Key points to, if any (e.g., "water.fvec.Frame"). */
  public String valueClass() {
    // Because Key<Keyed> doesn't have concrete parameterized subclasses (e.g.
    // class FrameKey extends Key<Frame>) we can't get the type parameter at
    // runtime.  See:
    // http://www.javacodegeeks.com/2013/12/advanced-java-generics-retreiving-generic-type-arguments.html
    //
    // Therefore, we have to fetch the type of the item the Key is pointing to at runtime.
    Value v = DKV.get(this);
    if (null == v)
      return null;
    else
      return v.className();
  }

  /** Return the base classname (not including the package) for the Value that this Key points to, if any (e.g., "Frame"). */
  public String valueClassSimple() {
    String vc = this.valueClass();

    if (null == vc) return null;

    String[] elements = vc.split("\\.");
    return elements[elements.length - 1];
  }

  static final char MAGIC_CHAR = '$'; // Used to hexalate displayed keys
  private static final char[] HEX = "0123456789abcdef".toCharArray();

  /** Converts the key to HTML displayable string.
   *
   * For user keys returns the key itself, for system keys returns their
   * hexadecimal values.
   *
   * @return key as a printable string
   */
  @Override public String toString() {
    int len = _kb.length;
    while( --len >= 0 ) {
      char a = (char) _kb[len];
      if (' ' <= a && a <= '#') continue;
      // then we have $ which is not allowed
      if ('%' <= a && a <= '~') continue;
      // already in the one above
      //if( 'a' <= a && a <= 'z' ) continue;
      //if( 'A' <= a && a <= 'Z' ) continue;
      //if( '0' <= a && a <= '9' ) continue;
      break;
    }
    if (len>=0) {
      StringBuilder sb = new StringBuilder();
      sb.append(MAGIC_CHAR);
      for( int i = 0; i <= len; ++i ) {
        byte a = _kb[i];
        sb.append(HEX[(a >> 4) & 0x0F]);
        sb.append(HEX[(a >> 0) & 0x0F]);
      }
      sb.append(MAGIC_CHAR);
      for( int i = len + 1; i < _kb.length; ++i ) sb.append((char)_kb[i]);
      return sb.toString();
    } else {
      return new String(_kb);
    }
  }

  private static byte[] decodeKeyName(String what) {
    if( what==null ) return null;
    if( what.length()==0 ) return null;
    if (what.charAt(0) == MAGIC_CHAR) {
      int len = what.indexOf(MAGIC_CHAR,1);
      if( len < 0 ) throw new IllegalArgumentException("No matching magic '"+MAGIC_CHAR+"', key name is not legal");
      String tail = what.substring(len+1);
      byte[] res = new byte[(len-1)/2 + tail.length()];
      int r = 0;
      for( int i = 1; i < len; i+=2 ) {
        char h = what.charAt(i);
        char l = what.charAt(i+1);
        h -= Character.isDigit(h) ? '0' : ('a' - 10);
        l -= Character.isDigit(l) ? '0' : ('a' - 10);
        res[r++] = (byte)(h << 4 | l);
      }
      System.arraycopy(StringUtils.bytesOf(tail), 0, res, r, tail.length());
      return res;
    } else {
      byte[] res = new byte[what.length()];
      for( int i=0; i<res.length; i++ ) res[i] = (byte)what.charAt(i);
      return res;
    }
  }

  @Override public int hashCode() { return _hash; }
  @Override public boolean equals( Object o ) {
    if( this == o ) return true;
    if( o == null ) return false;
    Key k = (Key)o;
    if( _hash != k._hash ) return false;
    return Arrays.equals(k._kb,_kb);
  }

  /** Lexically ordered Key comparison, so Keys can be sorted.  Modestly expensive. */
  @Override public int compareTo(Object o) {
    assert (o instanceof Key);
    return this.toString().compareTo(o.toString());
  }

  public static final AutoBuffer write_impl(Key k, AutoBuffer ab) {return ab.putA1(k._kb);}
  public static final Key read_impl(Key k, AutoBuffer ab) {return make(ab.getA1());}

  public static final AutoBuffer writeJSON_impl( Key k, AutoBuffer ab ) {
    ab.putJSONStr("name",k.toString());
    ab.put1(',');
    ab.putJSONStr("type", ReflectionUtils.findActualClassParameter(k.getClass(), 0).getSimpleName());
    return ab;
  }
}
