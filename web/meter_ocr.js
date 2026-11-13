// อ่านเลขมิเตอร์จากรูปบนเว็บด้วย Tesseract.js (ทำงานในเบราว์เซอร์ ไม่ส่งรูปออกไปที่ไหน)
// เรียกจาก Dart: lib/services/web_ocr_web.dart -> window.stayeaseMeterOcr(dataUrl)
// คืนค่าเป็นข้อความที่อ่านได้ (เฉพาะตัวเลข) หรือสตริงว่างถ้าอ่านไม่ได้
(function () {
  var worker = null;
  var workerPromise = null;

  function getWorker() {
    if (worker) return Promise.resolve(worker);
    if (!workerPromise) {
      workerPromise = Tesseract.createWorker('eng').then(function (w) {
        return w
          .setParameters({
            // อ่านเฉพาะตัวเลข และปล่อยให้หาข้อความกระจายอยู่ในรูป (มิเตอร์มักมีตัวเลขเล็ก ๆ ปนกัน)
            tessedit_char_whitelist: '0123456789',
            tessedit_pageseg_mode: Tesseract.PSM.SPARSE_TEXT,
          })
          .then(function () {
            worker = w;
            return w;
          });
      });
    }
    return workerPromise;
  }

  // ย่อรูปใหญ่ + แปลงเป็นขาวดำ + ยืดคอนทราสต์ เพื่อให้อ่านตัวเลขแม่นขึ้น
  function preprocess(dataUrl) {
    return new Promise(function (resolve, reject) {
      var img = new Image();
      img.onload = function () {
        var maxSide = 1600;
        var scale = Math.min(1, maxSide / Math.max(img.width, img.height));
        var w = Math.max(1, Math.round(img.width * scale));
        var h = Math.max(1, Math.round(img.height * scale));
        var canvas = document.createElement('canvas');
        canvas.width = w;
        canvas.height = h;
        var ctx = canvas.getContext('2d');
        ctx.drawImage(img, 0, 0, w, h);
        var imageData = ctx.getImageData(0, 0, w, h);
        var d = imageData.data;
        var min = 255;
        var max = 0;
        var i;
        for (i = 0; i < d.length; i += 4) {
          var g = 0.299 * d[i] + 0.587 * d[i + 1] + 0.114 * d[i + 2];
          d[i] = d[i + 1] = d[i + 2] = g;
          if (g < min) min = g;
          if (g > max) max = g;
        }
        var range = Math.max(1, max - min);
        for (i = 0; i < d.length; i += 4) {
          var v = ((d[i] - min) * 255) / range;
          d[i] = d[i + 1] = d[i + 2] = v;
        }
        ctx.putImageData(imageData, 0, 0);
        resolve(canvas);
      };
      img.onerror = function () {
        reject(new Error('โหลดรูปไม่สำเร็จ'));
      };
      img.src = dataUrl;
    });
  }

  window.stayeaseMeterOcr = function (dataUrl) {
    return preprocess(dataUrl)
      .then(function (canvas) {
        return getWorker().then(function (w) {
          return w.recognize(canvas);
        });
      })
      .then(function (result) {
        return (result && result.data && result.data.text) || '';
      });
  };
})();

// ── ถ่ายรูปด้วยเว็บแคมบนเบราว์เซอร์คอมพิวเตอร์ ──
// image_picker บนเว็บใช้แอตทริบิวต์ capture ซึ่งทำงานเฉพาะเบราว์เซอร์มือถือ
// (บน Chrome ของ Mac ไม่เปิดกล้อง) จึงมีหน้าต่างถ่ายรูปของเราเอง
(function () {
  window.stayeaseIsDesktopBrowser = function () {
    var ua = navigator.userAgent || '';
    var mobileUa = /Android|iPhone|iPad|iPod|Mobile/i.test(ua);
    var ipadOs = navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1;
    return !(mobileUa || ipadOs);
  };

  // คืน data URL (JPEG) ของรูปที่ถ่าย, คืนสตริงว่างถ้าผู้ใช้กดยกเลิก,
  // และ reject ถ้าเปิดกล้องไม่ได้ (ไม่มีกล้อง/ไม่อนุญาต/ไม่ใช่ https หรือ localhost)
  window.stayeaseCaptureWebcam = function () {
    return new Promise(function (resolve, reject) {
      if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
        reject(new Error('เบราว์เซอร์นี้เปิดกล้องไม่ได้ (ต้องใช้ https หรือ localhost)'));
        return;
      }
      navigator.mediaDevices
        .getUserMedia({
          video: { facingMode: 'environment', width: { ideal: 1920 }, height: { ideal: 1080 } },
          audio: false,
        })
        .then(function (stream) {
          var overlay = document.createElement('div');
          overlay.id = 'stayease-webcam-overlay';
          overlay.style.cssText =
            'position:fixed;inset:0;z-index:2147483647;background:#000;display:flex;' +
            'flex-direction:column;align-items:center;justify-content:center;gap:16px;';
          var video = document.createElement('video');
          video.setAttribute('playsinline', '');
          video.autoplay = true;
          video.muted = true;
          video.srcObject = stream;
          video.style.cssText = 'max-width:92vw;max-height:76vh;border-radius:12px;background:#111;';
          var row = document.createElement('div');
          row.style.cssText = 'display:flex;gap:12px;';
          function mkBtn(id, label, bg) {
            var b = document.createElement('button');
            b.id = id;
            b.textContent = label;
            b.style.cssText =
              'padding:12px 28px;border:0;border-radius:14px;font-size:16px;color:#fff;cursor:pointer;background:' + bg;
            return b;
          }
          var shoot = mkBtn('stayease-webcam-shoot', 'ถ่ายรูป', '#4F8FDB');
          var cancel = mkBtn('stayease-webcam-cancel', 'ยกเลิก', '#777');
          row.appendChild(shoot);
          row.appendChild(cancel);
          overlay.appendChild(video);
          overlay.appendChild(row);
          document.body.appendChild(overlay);

          function close() {
            stream.getTracks().forEach(function (t) { t.stop(); });
            if (overlay.parentNode) overlay.parentNode.removeChild(overlay);
          }
          cancel.onclick = function () { close(); resolve(''); };
          shoot.onclick = function () {
            var w = video.videoWidth || 1280;
            var h = video.videoHeight || 720;
            var canvas = document.createElement('canvas');
            canvas.width = w;
            canvas.height = h;
            canvas.getContext('2d').drawImage(video, 0, 0, w, h);
            var url = canvas.toDataURL('image/jpeg', 0.92);
            close();
            resolve(url);
          };
        })
        .catch(function (e) { reject(e); });
    });
  };
})();
