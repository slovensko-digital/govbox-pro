import { Controller } from "@hotwired/stimulus"
import { get, patch } from '@rails/request.js'

export default class extends Controller {

  async sign(messageObjectId, messageId, that, batchId = null) {
    return new Promise((resolve, reject) => {
      get(`/messages/${messageId}/message_objects/${messageObjectId}/signing_data.json`)
        .then(function (response) {
          return response.json;
        })
        .then(async function (messageObjectData) {
          let payloadMimeType = `${messageObjectData.mime_type};base64`;
          let signatureLevel = "XAdES_BASELINE_B";
          let signatureContainer = "ASiC_E";

          let signedFileName = await that.setSignedFileName(messageObjectData);
          let signedFileMimeType = "application/vnd.etsi.asic-e+zip";

          switch(messageObjectData.mime_type) {
            case "application/pdf":
              signatureLevel = "PAdES_BASELINE_B";
              signatureContainer = null;

              signedFileName = messageObjectData.file_name;
              signedFileMimeType = messageObjectData.mime_type;
              break;
            // TODO check what in this case
            // case 'application/xml':
            //   break;
            case 'application/x-eform-xml':
              payloadMimeType = "application/xml;base64"
              break;
            case 'application/msword':
            case 'application/vnd.openxmlformats-officedocument.wordprocessingml.document':
              payloadMimeType = "application/vnd.openxmlformats-officedocument.wordprocessingml.document;base64"
              break;
            case 'image/jpeg':
            case 'image/tiff':
            case 'image/png':
              signatureLevel = "CAdES_BASELINE_B";
              break;
          }

          fetch("http://localhost:37200/sign", {
            method: "POST",
            headers: {'Content-Type': 'application/json'},
            body: JSON.stringify({
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
                transformation: messageObjectData.transformation
              },
              payloadMimeType: payloadMimeType
            })
          }).then(function (response) {
            return response.json();
          }).then(function (signedData) {
            that.updateObject(messageObjectId, messageId, signedFileName, signedFileMimeType, signedData.content);
          }).then(function () {
            resolve();
          }).catch(function (err) {
            if (err.message === "Failed to fetch") {
              alert("Spustite aplikáciu autogram.")
            }
          });
        })
    });
  }

  async updateObject(messageObjectId, messageId, signedFileName, signedFileMimeType, signedContent) {
    const authenticityToken = this.data.get("authenticityToken");

    return new Promise((resolve, reject) => {
      // request.js lib is used, responseKind: "turbo-stream" option is very important (be careful if case of changes)
      patch(`/messages/${messageId}/message_objects/${messageObjectId}`, {
        body: JSON.stringify({
          authenticity_token: authenticityToken,
          name: signedFileName,
          mimetype: signedFileMimeType,
          is_signed: true,
          content: signedContent
        }),
        responseKind: "turbo-stream"
      }).then(function () {
        resolve();
      })
    });
  }

  async setSignedFileName(messageObjectData) {
    return messageObjectData.file_name.substring(0, messageObjectData.file_name.lastIndexOf('.')).concat(".asice") || messageObjectData.file_name;
  }

  signMultipleFiles() {
    const objectsToBeSigned = JSON.parse(this.data.get("filesToBeSigned"));
    const that = this;

    fetch("http://localhost:37200/batch", {
      method: "POST",
      headers: {"Content-Type": "application/json"},
      body: JSON.stringify({
        "totalNumberOfDocuments": objectsToBeSigned.length
      })
    }).then(function (response) {
      return response.json();
    }).then(function (data) {
      return data.batchId;
    }).then(async function (batchId) {
      for(const object of objectsToBeSigned) {
        await that.sign(object.id, object.message_id, that, batchId);
      }
    }).catch(function (err) {
      if (err.message === "Failed to fetch") {
        alert("Spustite aplikáciu autogram.")
      }
    });
  }

  async signSingleFile() {
    const messageObjectId = this.data.get("objectId");
    const messageId = this.data.get("messageId");

    await this.sign(messageObjectId, messageId, this);
  }
}
