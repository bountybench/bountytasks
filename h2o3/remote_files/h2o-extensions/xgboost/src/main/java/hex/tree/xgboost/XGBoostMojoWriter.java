package hex.tree.xgboost;

import hex.Model;
import hex.ModelMojoWriter;
import hex.glm.GLMModel;
import hex.isotonic.IsotonicRegressionModel;
import hex.tree.CalibrationHelper;

import java.io.IOException;
import java.nio.charset.Charset;

/**
 * MOJO support for XGBoost model.
 */
public class XGBoostMojoWriter extends ModelMojoWriter<XGBoostModel, XGBoostModel.XGBoostParameters, XGBoostOutput> {

  @SuppressWarnings("unused")  // Called through reflection in ModelBuildersHandler
  public XGBoostMojoWriter() {}

  public XGBoostMojoWriter(XGBoostModel model) {
    super(model);
  }

  @Override public String mojoVersion() {
    return "1.10";
  }

  @Override
  protected void writeModelData() throws IOException {
    writeblob("boosterBytes", this.model.model_info()._boosterBytes);
    byte[] auxNodeWeightBytes = this.model.model_info().auxNodeWeightBytes();
    if (auxNodeWeightBytes != null) {
      writeblob("auxNodeWeights", auxNodeWeightBytes);
    }
    writekv("nums", model._output._nums);
    writekv("cats", model._output._cats);
    writekv("cat_offsets", model._output._catOffsets);
    writekv("use_all_factor_levels", model._output._useAllFactorLevels);
    writekv("sparse", model._output._sparse);
    writekv("booster", model._parms._booster.toString());
    writekv("ntrees", model._output._ntrees);
    writeblob("feature_map", model.model_info().getFeatureMap().getBytes(Charset.forName("UTF-8")));
    writekv("use_java_scoring_by_default", true);
    if (model._output.isCalibrated()) {
      final CalibrationHelper.CalibrationMethod calibMethod = model._output.getCalibrationMethod();
      final Model<?, ?, ?> calibModel = model._output.calibrationModel();
      writekv("calib_method", calibMethod.getId());
      switch (calibMethod) {
        case PlattScaling:
          double[] beta = ((GLMModel) calibModel).beta();
          assert beta.length == model._output.nclasses(); // n-1 coefficients + 1 intercept
          writekv("calib_glm_beta", beta);
          break;
        case IsotonicRegression:
          IsotonicRegressionModel isotonic = (IsotonicRegressionModel) calibModel;
          write(isotonic.toIsotonicCalibrator());
          break;
        default:
          throw new UnsupportedOperationException("MOJO is not (yet) support for calibration model " + calibMethod);
      }
    }
    writekv("has_offset", model._output.hasOffset());
  }
}
