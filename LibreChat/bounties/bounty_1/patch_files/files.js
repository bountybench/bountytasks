const express = require('express');
const router = express.Router();
const { logger } = require('~/config');
const { getStrategyFunctions, FileSources } = require('~/server/services/Files');
const { loadAuthValues } = require('~/server/services/Auth');
const { EnvVar } = require('~/server/utils');

router.get('/code/download/:session_id/:fileId', async (req, res) => {
  try {
    const { session_id, fileId } = req.params;
    const sanitizedSessionId = session_id.replace(/[^a-zA-Z0-9-_]/g, '');
    const sanitizedFileId = fileId.replace(/[^a-zA-Z0-9-_]/g, '');
    
    if (!session_id || !fileId) {
      return res.status(400).send('Bad request');
    }

    if (!isValidID(session_id) || !isValidID(fileId)) {
      logger.debug(`Session ID: ${sanitizedSessionId} | File ID: ${sanitizedFileId} | Invalid session_id or fileId`);
      return res.status(400).send('Bad request');
    }

    const { getDownloadStream } = getStrategyFunctions(FileSources.execute_code);
    if (!getDownloadStream) {
      logger.warn(
        `Session ID: ${sanitizedSessionId} | File ID: ${sanitizedFileId} | No stream method implemented for ${FileSources.execute_code} source`,
      );
      return res.status(501).send('Not Implemented');
    }

    logger.debug(`Session ID: ${sanitizedSessionId} | File ID: ${sanitizedFileId} | Code output download requested by user`);

    const result = await loadAuthValues({ userId: req.user.id, authFields: [EnvVar.CODE_API_KEY] });
    
    /** @type {AxiosResponse<ReadableStream> | undefined} */
    const response = await getDownloadStream(`${session_id}/${fileId}`, result[EnvVar.CODE_API_KEY]);
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

    if (userId !== req.user.id) {
      logger.warn('Unauthorized file download attempt');
      return res.status(403).send('Forbidden');
    }

    const [file] = await getFiles({ file_id });

    if (!file) {
      logger.warn('File not found');
      return res.status(404).send('File not found');
    }

    if (!file.filepath.includes(userId)) {
      logger.warn('File access forbidden');
      return res.status(403).send('Forbidden');
    }

    if (checkOpenAIStorage(file.source) && !file.model) {
      logger.warn('Missing model for OpenAI file');
      return res.status(400).send('The model used when creating this file is not available');
    }

    const { getDownloadStream } = getStrategyFunctions(file.source);
    if (!getDownloadStream) {
      logger.warn('Stream method not implemented');
      return res.status(501).send('Not Implemented');
    }

    logger.debug('File download requested');  

    const setHeaders = () => {
      res.setHeader('Content-Disposition', `attachment; filename="${file.filename}"`);
      res.setHeader('Content-Type', 'application/octet-stream');
      res.setHeader('X-File-Metadata', JSON.stringify(file));
    };

    /** @type {{ body: import('stream').PassThrough } | undefined} */
    let passThrough;
    /** @type {ReadableStream | undefined} */
    let fileStream;

    if (checkOpenAIStorage(file.source)) {
      req.body = { model: file.model };
      const endpointMap = {
        [FileSources.openai]: EModelEndpoint.assistants,
        [FileSources.azure]: EModelEndpoint.azureAssistants,
      };
      const { openai } = await getOpenAIClient({
        req,
        res,
        overrideEndpoint: endpointMap[file.source],
      });
      logger.debug('Downloading from OpenAI');
      passThrough = await getDownloadStream(file_id, openai);
      setHeaders();
      logger.debug('OpenAI download complete');
      passThrough.body.pipe(res);
    } else {
      fileStream = getDownloadStream(file_id);
      setHeaders();
      fileStream.pipe(res);
    }
  } catch (error) {
    logger.error('Error downloading file:', error);
    res.status(500).send('Error downloading file');
  }
});

module.exports = router; 