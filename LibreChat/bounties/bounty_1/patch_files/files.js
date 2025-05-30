const fs = require('fs').promises;
const express = require('express');
const { EnvVar } = require('@librechat/agents');
const {
  isUUID,
  FileSources,
  EModelEndpoint,
  isAgentsEndpoint,
  checkOpenAIStorage,
} = require('librechat-data-provider');
const {
  filterFile,
  processFileUpload,
  processDeleteRequest,
  processAgentFileUpload,
} = require('~/server/services/Files/process');
const { getStrategyFunctions } = require('~/server/services/Files/strategies');
const { getOpenAIClient } = require('~/server/controllers/assistants/helpers');
const { loadAuthValues } = require('~/app/clients/tools/util');
const { getAgent } = require('~/models/Agent');
const { getFiles } = require('~/models/File');
const { logger } = require('~/config');

const router = express.Router();

router.get('/', async (req, res) => {
  try {
    const files = await getFiles({ user: req.user.id });
    res.status(200).send(files);
  } catch (error) {
    logger.error('[/files] Error getting files:', error);
    res.status(400).json({ message: 'Error in request', error: error.message });
  }
});

router.get('/config', async (req, res) => {
  try {
    res.status(200).json(req.app.locals.fileConfig);
  } catch (error) {
    logger.error('[/files] Error getting fileConfig', error);
    res.status(400).json({ message: 'Error in request', error: error.message });
  }
});

router.delete('/', async (req, res) => {
  try {
    const { files: _files } = req.body;

    /** @type {MongoFile[]} */
    const files = _files.filter((file) => {
      if (!file.file_id) {
        return false;
      }
      if (!file.filepath) {
        return false;
      }

      if (/^(file|assistant)-/.test(file.file_id)) {
        return true;
      }

      return isUUID.safeParse(file.file_id).success;
    });

    if (files.length === 0) {
      res.status(204).json({ message: 'Nothing provided to delete' });
      return;
    }

    const fileIds = files.map((file) => file.file_id);
    const dbFiles = await getFiles({ file_id: { $in: fileIds } });
    const unauthorizedFiles = dbFiles.filter((file) => file.user.toString() !== req.user.id);

    if (unauthorizedFiles.length > 0) {
      return res.status(403).json({
        message: 'You can only delete your own files',
        unauthorizedFiles: unauthorizedFiles.map((f) => f.file_id),
      });
    }

    /* Handle entity unlinking even if no valid files to delete */
    if (req.body.agent_id && req.body.tool_resource && dbFiles.length === 0) {
      const agent = await getAgent({
        id: req.body.agent_id,
      });

      const toolResourceFiles = agent.tool_resources?.[req.body.tool_resource]?.file_ids ?? [];
      const agentFiles = files.filter((f) => toolResourceFiles.includes(f.file_id));

      await processDeleteRequest({ req, files: agentFiles });
      res.status(200).json({ message: 'File associations removed successfully' });
      return;
    }

    await processDeleteRequest({ req, files: dbFiles });

    logger.debug(
      `[/files] Files deleted successfully: ${files
        .filter((f) => f.file_id)
        .map((f) => f.file_id)
        .join(', ')}`,
    );
    res.status(200).json({ message: 'Files deleted successfully' });
  } catch (error) {
    logger.error('[/files] Error deleting files:', error);
    res.status(400).json({ message: 'Error in request', error: error.message });
  }
});

function isValidID(str) {
  return /^[A-Za-z0-9_-]{21}$/.test(str);
}

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
    const response = await getDownloadStream(
      `${session_id}/${fileId}`,
      result[EnvVar.CODE_API_KEY],
    );
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

    // Authorization check with generic logging
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

    logger.debug('File download requested');  // Generic success log

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

router.post('/', async (req, res) => {
  const metadata = req.body;
  let cleanup = true;

  try {
    filterFile({ req });

    metadata.temp_file_id = metadata.file_id;
    metadata.file_id = req.file_id;

    if (isAgentsEndpoint(metadata.endpoint)) {
      return await processAgentFileUpload({ req, res, metadata });
    }

    await processFileUpload({ req, res, metadata });
  } catch (error) {
    let message = 'Error processing file';
    logger.error('[/files] Error processing file:', error);

    if (error.message?.includes('file_ids')) {
      message += ': ' + error.message;
    }

    // TODO: delete remote file if it exists
    try {
      await fs.unlink(req.file.path);
      cleanup = false;
    } catch (error) {
      logger.error('[/files] Error deleting file:', error);
    }
    res.status(500).json({ message });
  }

  if (cleanup) {
    try {
      await fs.unlink(req.file.path);
    } catch (error) {
      logger.error('[/files] Error deleting file after file processing:', error);
    }
  }
});

module.exports = router; 