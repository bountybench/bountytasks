setwd(normalizePath(dirname(R.utils::commandArgs(asValues=TRUE)$"f")))
source("../../../scripts/h2o-r-test-setup.R")

test.model.generic.predict <- function(encoding) {
    # Train a model
    airlines <- h2o.importFile(path = locate('smalldata/testng/airlines_train.csv'))
    airlines_test <- h2o.importFile(path = locate('smalldata/testng/airlines_test.csv'))
    cols <- c("Origin", "Distance")
    model <- h2o.gbm(x=cols, y = "IsDepDelayed", ntrees = 10,
                     training_frame = airlines,
                     categorical_encoding = encoding)
    predictions <- as.data.frame(h2o.predict(model, airlines_test))
    contributions <- as.data.frame(h2o.predict_contributions(model, airlines_test))

    # Download MOJO representation
    mojo_name <- h2o.download_mojo(model = model, path = sandbox())
    mojo_path <- file.path(sandbox(), mojo_name)
    
    # Import MOJO
    mojo_model <- h2o.import_mojo(mojo_path)

    # Test scoring is available on the model
    if (encoding == "AUTO") {
        mojo_predictions  <- as.data.frame(h2o.predict(mojo_model, airlines_test))
        expect_equal(mojo_predictions, predictions)
    } else {
        print("Prediction test will be skipped - see PUBDEV-8230")
    }

    # Test predict contributions is available on the model
    mojo_contributions  <- as.data.frame(h2o.predict_contributions(mojo_model, airlines_test))
    expect_equal(mojo_contributions, contributions)    
}

make.model.generic.predict.test.suite <- function() {
    test.model.generic.predict.auto <- function() {
       test.model.generic.predict("AUTO")
    }
    test.model.generic.predict.binary <- function() {
       test.model.generic.predict("Binary")
    }
    test.model.generic.predict.1hot <- function() {
       test.model.generic.predict("OneHotExplicit")
    }
    makeSuite(
        test.model.generic.predict.auto,
        test.model.generic.predict.binary,
        test.model.generic.predict.1hot,
    )
}

doSuite("Generic model from GBM MOJO", make.model.generic.predict.test.suite())
