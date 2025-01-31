import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    const dropzone = document.getElementById('dropzone');
    const fileInput = document.getElementById('content[]');
    const fileList = document.getElementById('fileList');
    const fileCount = document.getElementById('fileCount');

    this.allFiles = new DataTransfer();

    dropzone.addEventListener('dragover', (e) => {
      e.preventDefault();
      dropzone.classList.add('border-blue-500', 'border-2');
    });

    dropzone.addEventListener('dragleave', () => {
      dropzone.classList.remove('border-blue-500', 'border-2');
    });

    dropzone.addEventListener('drop', (e) => {
      e.preventDefault();
      dropzone.classList.remove('border-blue-500', 'border-2');

      const files = e.dataTransfer.files;
      this.handleFiles(files);
    });

    fileInput.addEventListener('change', (e) => {
      const files = e.target.files;
      this.handleFiles(files);
    });
  }

  handleFiles(files) {
    const fileInput = document.getElementById('content[]');

    for (const file of files) {
      this.allFiles.items.add(file);

      const listItem = document.createElement('div');
      listItem.textContent = `${file.name} (${this.formatBytes(file.size)})`;
      fileList.appendChild(listItem);
    }

    fileCount.parentElement.classList.remove('hidden');
    fileCount.textContent = `${parseInt(fileCount.textContent) + files.length}`;

    fileInput.files = this.allFiles.files;
  }

  formatBytes(bytes) {
    if (bytes === 0) return '0 Bytes';

    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));

    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
  }
}
