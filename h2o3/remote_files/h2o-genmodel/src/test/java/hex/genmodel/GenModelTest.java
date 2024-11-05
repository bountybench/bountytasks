package hex.genmodel;

import hex.ModelCategory;
import org.junit.Test;

import java.io.IOException;
import java.net.URL;

import static org.junit.Assert.*;

public class GenModelTest {

  @Test
  public void testKMeansDistance() {
    double[] center = new double[]{1.2, 0.8, 1.0};
    double[] point = new double[]{1.0, Double.NaN, 1.8};
    double dist = GenModel.KMeans_distance(center, point, new String[center.length][]);
    assertEquals(3.0*((0.2*0.2)+(0.8*0.8))/2.0, dist, 1e-10);
  }

  @Test
  public void testKMeansDistanceExtended() {
    double[] center = new double[]{1.2, 0.8, 1.0};
    float[] point = new float[]{1.0f, Float.NaN, 1.8f};
    double dist = GenModel.KMeans_distance(center, point, new int[]{-1,-1,-1}, new double[3], new double[3]);
    assertEquals(3.0*(((1.2-1.0f)*(1.2-1.0f))+((1.0-1.8f)*(1.0-1.8f)))/2.0f, dist, 1e-10);
  }

  @Test
  public void testSetInputDouble() { // Deep Learning Version
    double[] row = {0, 7, 3, 42};
    int[] catOffsets = {1, 3, 8, 15};

    double[] nums = new double[1];
    int[] cats = new int[3];
    GenModel.setCats(row, nums, cats, 3, catOffsets, null, null, false);
    assertArrayEquals(new double[]{42}, nums, 0);
    assertArrayEquals(new int[]{-1, 7, 10}, cats);

    double[] to = new double[16];
    double[] numsInput = new double[1];
    int[] catsInput = new int[3];
    GenModel.setInput(row, to, numsInput, catsInput, numsInput.length, catsInput.length, catOffsets, null, null, false, false);
    assertArrayEquals(new double[]{0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 42}, to, 0);
  }

  @Test
  public void testSetInputFloat() { // DeepWater and XGBoost Native
    double[] row = {0, 7, 3, 42};
    int[] catOffsets = {1, 3, 8, 15};

    float[] to = new float[16];
    GenModel.setInput(row, to, 1, 3, catOffsets, null, null, false, false);
    assertArrayEquals(new float[]{0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 42}, to, 0);
  }

  @Test
  public void testGetOutputDomains() throws IOException {
    URL mojoSource = getClass().getResource("/hex/genmodel/algos/gbm/gbm_variable_importance.zip");
    assertNotNull(mojoSource);
    MojoReaderBackend r = MojoReaderBackendFactory.createReaderBackend(mojoSource, MojoReaderBackendFactory.CachingStrategy.MEMORY);
    MojoModel mojo = MojoModel.load(r);

    final String[][] outputDomains = mojo.getOutputDomains();
    assertEquals(3, outputDomains.length);
    assertArrayEquals(new String[]{"0", "1"}, outputDomains[0]);
    assertNull(outputDomains[1]);
    assertNull(outputDomains[2]);

    final String[] outputNames = mojo.getOutputNames();
    assertArrayEquals(new String[]{"predict", "p0", "p1"}, outputNames);
  }

  @Test
  public void testGetOutputDomainsSmoke() {
    for (final ModelCategory mc : ModelCategory.values()) {
      if (mc.equals(ModelCategory.Unknown))
        continue;
      GenModel model = new GenModel(new String[]{"c1", "c2", "c3"}, new String[][]{null, null, new String[]{"a", "b"}}, "c3") {
        @Override
        public ModelCategory getModelCategory() {
          return mc;
        }

        @Override
        public String getUUID() {
          throw new UnsupportedOperationException();
        }

        @Override
        public double[] score0(double[] row, double[] preds) {
          throw new UnsupportedOperationException();
        }

        @Override
        public boolean isSupervised() {
          return true;
        }

        @Override
        public String[] getOutputNames() {
          return new String[]{"predict", "p0", "p1"};
        }
      };
      assertNotNull(model.getOutputDomains());
    }
  }

}
