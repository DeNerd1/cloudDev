#docker pull elestio/nextcloud

from flask import Flask, request, send_from_directory, render_template_string
import os

app = Flask(__name__)
UPLOAD_FOLDER = 'uploads'
os.makedirs(UPLOAD_FOLDER, exist_ok=True)

HTML_PAGE = '''
<!doctype html>
<title>Upload/Download</title>
<h1>Upload a file</h1>
<form id="upload-form" method="POST" enctype="multipart/form-data">
  <input type="file" name="file">
  <input type="submit" value="Upload">
</form>
<progress id="upload-progress" value="0" max="100" style="width:300px;"></progress>

<h1>Files</h1>
<ul>
  {% for filename in files %}
    <li><a href="/download/{{ filename }}">{{ filename }}</a></li>
  {% endfor %}
</ul>

<script>
document.getElementById('upload-form').addEventListener('submit', function(e) {
  e.preventDefault();
  let formData = new FormData(this);
  let xhr = new XMLHttpRequest();
  xhr.open('POST', '/', true);

  xhr.upload.onprogress = function(e) {
    if (e.lengthComputable) {
      let percent = Math.round((e.loaded / e.total) * 100);
      document.getElementById('upload-progress').value = percent;
    }
  };

  xhr.onload = function() {
    if (xhr.status == 200) {
      location.reload();
    }
  };

  xhr.send(formData);
});
</script>
'''

@app.route('/', methods=['GET', 'POST'])
def index():
    if request.method == 'POST':
        f = request.files['file']
        if f.filename:
            f.save(os.path.join(UPLOAD_FOLDER, f.filename))
    files = os.listdir(UPLOAD_FOLDER)
    return render_template_string(HTML_PAGE, files=files)

@app.route('/download/<filename>')
def download(filename):
    return send_from_directory(UPLOAD_FOLDER, filename, as_attachment=True)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8000)