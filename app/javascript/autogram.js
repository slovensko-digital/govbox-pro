import { patch } from '@rails/request.js'

export const isAutogramRunning = async () => {
  const response = await fetch(`http://localhost:37200/info`).catch(err => {
    // maybe the 'Failed to fetch' is enough?
    if (["Failed to fetch", "NetworkError when attempting to fetch resource.", "Load failed"].includes(err.message)) {
      return false
    }

    throw err
  })

  return response && response.ok
}

export const startBatch = async (numberOfDocuments) => {
  const result = await fetch("http://localhost:37200/batch", {
    method: "POST",
    headers: {"Content-Type": "application/json"},
    body: JSON.stringify({
      "totalNumberOfDocuments": numberOfDocuments
    })
  })

  return (await result.json()).batchId
}

export const endBatch = async (batchId) => {
  await fetch("http://localhost:37200/batch", {
    method: "DELETE",
    headers: {"Content-Type": "application/json"},
    body: JSON.stringify({
      "batchId": batchId
    })
  })
}

export const signMessageObject = async (messageObjectPath, batchId = null, authenticityToken) => {
  const signingData = await loadSigningData(messageObjectPath)
  const signedData = await makeSignRequest(prepareSingingRequestBody(signingData, batchId))
  const signedFile = signedFileData(signingData)

  return await updateObject(messageObjectPath, signedFile.name, signedFile.mineType, signedData.content, authenticityToken)
}

const signedFileName = (fileName) => {
  return fileName.substring(0, fileName.lastIndexOf('.')).concat(".asice") || fileName
}

const signedFileData = (messageObjectData) => {
  let name = signedFileName(messageObjectData.file_name)
  let mineType = "application/vnd.etsi.asic-e+zip"

  if (messageObjectData.mime_type === "application/pdf") {
    name = messageObjectData.file_name
    mineType = messageObjectData.mime_type
  }

  return {
    name,
    mineType
  }
}

const prepareSingingRequestBody = (messageObjectData, batchId = null) => {
  if (!messageObjectData) {
    return
  }
  let payloadMimeType = `${messageObjectData.mime_type};base64`
  let signatureLevel = "XAdES_BASELINE_B"
  let signatureContainer = "ASiC_E"
  let autoLoadEform = false

  switch (messageObjectData.mime_type) {
    case "application/pdf":
      signatureLevel = "PAdES_BASELINE_B"
      signatureContainer = null
      break
    case 'application/xml':
      payloadMimeType = "application/xml;base64"
      autoLoadEform = !messageObjectData.is_form
      break
    case 'application/x-eform-xml':
      payloadMimeType = "application/xml;base64"
      break
    case 'application/msword':
    case 'application/vnd.openxmlformats-officedocument.wordprocessingml.document':
      payloadMimeType = "application/vnd.openxmlformats-officedocument.wordprocessingml.document;base64"
      break
  }

  return {
    batchId: batchId,
    document: {
      filename: messageObjectData.file_name,
      content: messageObjectData.content
    },
    parameters: {
      level: signatureLevel,
      container: signatureContainer,
      identifier: messageObjectData.identifier,
      schema: messageObjectData.schema,
      containerXmlns: messageObjectData.container_xmlns,
      transformation: messageObjectData.transformation,
      autoLoadEform: autoLoadEform,
    },
    payloadMimeType: payloadMimeType
  }
}

const updateObject = async (messageObjectPath, signedFileName, signedFileMimeType, signedContent, authenticityToken) => {
  return await patch(messageObjectPath, {
    body: JSON.stringify({
      authenticity_token: authenticityToken,
      name: signedFileName,
      mimetype: signedFileMimeType,
      content: signedContent
    }),
    // request.js lib is used, responseKind: "turbo-stream" option is very important (be careful if case of changes)
    responseKind: "turbo-stream"
  })
}

const loadSigningData = async (messageObjectPath) => {
  const response = await fetch(`${messageObjectPath}/signing_data.json`)

  if (response.status === 204) {
    throw new Error("Vyplňte text správy")
  }

  if (response.ok) {
    return await response.json()
  }

  throw new Error('cannot load signing data')
}

const makeSignRequest = async (requestBody) => {
  const response = await fetch("http://localhost:37200/sign", {
    method: "POST",
    headers: {'Content-Type': 'application/json'},
    body: JSON.stringify(requestBody)
  })

  if (response.ok) {
    return await response.json()
  }

  throw new Error('signing request to autogram failed')
}
