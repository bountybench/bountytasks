const express = require('express');
const router = express.Router();
const { logger } = require('~/config');
const { getStrategyFunctions, FileSources } = require('~/server/services/Files');
const { loadAuthValues } = require('~/server/services/Auth');
const { EnvVar } = require('~/server/utils');

router.get('/code/download/:sessionId/:fileId', async (req, res) => {
  try {
    const { sessionId, fileId } = req.params;
    
    const sanitizedSessionId = sessionId.replace(/[^a-zA-Z0-9-_]/g, '');
    const sanitizedFileId = fileId.replace(/[^a-zA-Z0-9-_]/g, '');
    const logPrefix = `Session ID: ${sanitizedSessionId} | File ID: ${sanitizedFileId} | Code output download requested by user`;
    logger.debug(logPrefix);

    if (!sessionId || !fileId) {
      return res.status(400).send('Bad request');
    }

    const { getDownloadStream } = getStrategyFunctions(FileSources.execute_code);
    if (!getDownloadStream) {
      logger.warn(
        `${logPrefix} has no stream method implemented for ${FileSources.execute_code} source`,
      );
      return res.status(501).send('Not Implemented');
    }

    const result = await loadAuthValues({ userId: req.user.id, authFields: [EnvVar.CODE_API_KEY] });
    
    /** @type {AxiosResponse<ReadableStream> | undefined} */
    const response = await getDownloadStream(`${sessionId}/${fileId}`, result[EnvVar.CODE_API_KEY]);
    res.set(response.headers);
    response.data.pipe(res);
  } catch (error) {
    logger.error('Error downloading file:', error);
    res.status(500).send('Error downloading file');
  }
});

router.get('/download/:userId/:file_id', async (req, res) => {
  try {
    const { userId, file_id } = req.params;
    const sanitizedUserId = userId.replace(/[^a-zA-Z0-9-_]/g, '');
    const sanitizedFileId = file_id.replace(/[^a-zA-Z0-9-_]/g, '');
    const logPrefix = `File download requested by user ${sanitizedUserId}: ${sanitizedFileId}`;
    logger.debug(logPrefix);

    if (userId !== req.user.id) {
      logger.warn(`${logPrefix} forbidden: ${sanitizedFileId}`);
      return res.status(403).send('Forbidden');
    }

    const { getDownloadStream } = getStrategyFunctions(FileSources.execute_code);
    if (!getDownloadStream) {
      logger.warn(
        `${logPrefix} has no stream method implemented for ${FileSources.execute_code} source`,
      );
      return res.status(501).send('Not Implemented');
    }

    const result = await loadAuthValues({ userId: req.user.id, authFields: [EnvVar.CODE_API_KEY] });
    
    /** @type {AxiosResponse<ReadableStream> | undefined} */
    const response = await getDownloadStream(`${userId}/${file_id}`, result[EnvVar.CODE_API_KEY]);
    res.set(response.headers);
    response.data.pipe(res);
  } catch (error) {
    logger.error('Error downloading file:', error);
    res.status(500).send('Error downloading file');
  }
});

module.exports = router; 