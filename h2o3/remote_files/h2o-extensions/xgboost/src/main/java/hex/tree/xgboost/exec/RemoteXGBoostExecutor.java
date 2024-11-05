package hex.tree.xgboost.exec;

import hex.DataInfo;
import hex.schemas.XGBoostExecRespV3;
import hex.tree.xgboost.BoosterParms;
import hex.tree.xgboost.EvalMetric;
import hex.tree.xgboost.XGBoostModel;
import hex.tree.xgboost.remote.RemoteXGBoostHandler;
import hex.tree.xgboost.task.XGBoostUploadMatrixTask;
import hex.tree.xgboost.task.XGBoostSetupTask;
import org.apache.log4j.Logger;
import water.H2O;
import water.Key;
import water.Keyed;
import water.TypeMap;
import water.fvec.Frame;
import water.util.Log;

import java.util.Arrays;

public class RemoteXGBoostExecutor implements XGBoostExecutor {
    
    private static final Logger LOG = Logger.getLogger(RemoteXGBoostExecutor.class);

    public final XGBoostHttpClient http;
    public final Key modelKey;
    
    public RemoteXGBoostExecutor(XGBoostModel model, Frame train, Frame valid,
                                 String remoteUri, String userName, String password) {
        final boolean https = H2O.ARGS.jks != null;
        http = new XGBoostHttpClient(remoteUri, https, userName, password);
        modelKey = model._key;
        XGBoostExecReq.Init req = new XGBoostExecReq.Init();
        XGBoostSetupTask.FrameNodes trainFrameNodes = XGBoostSetupTask.findFrameNodes(train);
        req.num_nodes = trainFrameNodes.getNumNodes();
        DataInfo dataInfo = model.model_info().dataInfo();
        req.setParms(XGBoostModel.createParamsMap(model._parms, model._output.nclasses(), dataInfo.coefNames()));
        model._output._native_parameters = BoosterParms.fromMap(req.parms).toTwoDimTable();
        req.save_matrix_path = model._parms._save_matrix_directory;
        req.nodes = collectNodes(trainFrameNodes);
        LOG.info("Initializing remote executor.");
        XGBoostExecRespV3 resp = http.postJson(modelKey, "init", req);
        RemoteXGBoostHandler.RemoteExecutors executors = resp.readData();
        if (! Arrays.equals(executors._typeMap, TypeMap.bootstrapClasses())) {
            LOG.error("TypeMap differs: " +
                    "H2O=" + Arrays.toString(TypeMap.bootstrapClasses()) + ";" + 
                    "XGB=" + Arrays.toString(executors._typeMap)
            );
            throw new IllegalStateException("H2O Cluster and XGBoost external cluster do not have identical TypeMap.");
        }
        assert modelKey.equals(resp.key.key());
        uploadCheckpointBooster(model);
        uploadMatrix(model, train, true, trainFrameNodes, executors._nodes, https, remoteUri, userName, password);
        if (valid != null) {
            XGBoostSetupTask.FrameNodes validFrameNodes = XGBoostSetupTask.findFrameNodes(valid);
            Key<Frame> toCleanUp = null;
            if (!validFrameNodes.isSubsetOf(trainFrameNodes)) {
                Log.info("Validation Frame will be re-distributed to be collocated with remote nodes of the " +
                        "training matrix.");
                toCleanUp = Key.make();
                valid = train.makeSimilarlyDistributed(valid, toCleanUp);
            }

            uploadMatrix(model, valid, false, validFrameNodes, executors._nodes, https, remoteUri, userName, password);
            if (toCleanUp != null) {
                Keyed.remove(toCleanUp);
            }
        }
        LOG.info("Remote executor init complete.");
    }

    private void uploadMatrix(
        XGBoostModel model, Frame train, boolean isTrain,
        XGBoostSetupTask.FrameNodes trainFrameNodes, String[] remoteNodes,
        boolean https, String leaderUri, String userName, String password
    ) {
        LOG.info("Starting matrix data upload.");
        new XGBoostUploadMatrixTask(
                model, train, isTrain, trainFrameNodes._nodes, remoteNodes,
                https, parseContextPath(leaderUri), userName, password
        ).run();
    }

    private String parseContextPath(String leaderUri) {
        int slashIndex = leaderUri.indexOf("/");
        if (slashIndex > 0) {
            return leaderUri.substring(slashIndex);
        } else {
            return "";
        }
    }

    private void uploadCheckpointBooster(XGBoostModel model) {
        if (!model._parms.hasCheckpoint()) {
            return;
        }
        LOG.info("Uploading booster checkpoint.");
        http.uploadCheckpointBytes(modelKey, model.model_info()._boosterBytes);
    }

    private String[] collectNodes(XGBoostSetupTask.FrameNodes nodes) {
        String[] res = new String[H2O.CLOUD.size()];
        for (int i = 0; i < nodes._nodes.length; i++) {
            if (nodes._nodes[i]) {
                res[i] = H2O.CLOUD.members()[i].getIpPortString();
            }
        }
        return res;
    }

    @Override
    public byte[] setup() {
        XGBoostExecReq req = new XGBoostExecReq(); // no req params
        return http.downloadBytes(modelKey, "setup", req);
    }

    @Override
    public void update(int treeId) {
        XGBoostExecReq.Update req = new XGBoostExecReq.Update();
        req.treeId = treeId;
        XGBoostExecRespV3 resp = http.postJson(modelKey, "update", req);
        assert resp.key.key().equals(modelKey);
    }

    @Override
    public byte[] updateBooster() {
        XGBoostExecReq req = new XGBoostExecReq(); // no req params
        return http.downloadBytes(modelKey, "getBooster", req);
    }

    @Override
    public EvalMetric getEvalMetric() {
        XGBoostExecReq.GetEvalMetric req = new XGBoostExecReq.GetEvalMetric();
        XGBoostExecRespV3 resp = http.postJson(modelKey, "getEvalMetric", req);
        assert resp.key.key().equals(modelKey);
        return resp.readData();
    }

    @Override
    public void close() {
        XGBoostExecReq req = new XGBoostExecReq(); // no req params
        XGBoostExecRespV3 resp = http.postJson(modelKey, "cleanup", req);
        assert resp.key.key().equals(modelKey);
    }
}
